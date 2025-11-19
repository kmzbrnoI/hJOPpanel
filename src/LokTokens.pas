unit LokTokens;

{
  Database of authorization token for manual control of engines.
}

interface

uses SysUtils, Generics.Collections, Classes;

type
  TTokenPurpose = record
    slot: Integer;
    ruc: boolean;
  end;

  TTokens = class
  private
    tokenPurpose: TDictionary<Word, TTokenPurpose>; // mapa adresa -> maus slot

    class function Purpose(slot: Integer; ruc: boolean): TTokenPurpose;

  public

    constructor Create();
    destructor Destroy(); override;

    procedure ParseData(var parsed: TStrings);
    procedure LokosToReg(orId: string; lokos: array of Word); // lokos: 1234|1235| ....
    procedure LokosToMaus(orId: string; lokos: array of Word; slot: Integer; ruc: boolean);
    procedure ResetMausTokens();

  end;

var
  tokens: TTokens;

implementation

uses TCPClientPanel, RVDb, fRegReq, BottomErrors, uLIClient, fTrainToSlot,
  parseHelper, GlobalConfig;

/// /////////////////////////////////////////////////////////////////////////////

constructor TTokens.Create();
begin
  inherited;
  tokenPurpose := TDictionary<Word, TTokenPurpose>.Create();
end;

destructor TTokens.Destroy();
begin
  Self.tokenPurpose.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TTokens.ParseData(var parsed: TStrings);
var purpose, gpurpose: TTokenPurpose;
  splitted: TStrings;
begin
  if (parsed[2] = 'OK') then
  begin
    if (F_RegReq.token_req_sent) then
      F_RegReq.ServerResponseOK();
    if (F_TrainToSlot.token_req_sent) then
      F_TrainToSlot.ServerResponseOK();

    var vehicles := TRVDb.Create();
    try
      vehicles.ParseRVsFromToken(parsed[3]);

      gpurpose.slot := 0;
      for var vehicle in vehicles do
      begin
        if ((gpurpose.slot = 0) and (Self.tokenPurpose.TryGetValue(vehicle.addr, Purpose))) then
          gpurpose := Purpose
        else if ((gpurpose.slot > 0) and ((not Self.tokenPurpose.TryGetValue(vehicle.addr, Purpose)) or
          (Purpose.slot <> gpurpose.slot))) then
        begin
          gpurpose.slot := 0;
          break;
        end;
      end;

      case (gpurpose.slot) of
        0:
          begin
            if ((GlobConfig.data.reg.reg_fn <> '') and (FileExists(GlobConfig.data.reg.reg_fn))) then
            begin
              try
                vehicles.OpenJerry();
              except
                on E: Exception do
                  Errors.writeerror(E.Message, 'Regulátor', '');
              end;
            end
            else
              Errors.writeerror('Nevyplnìna cesta k regulátoru v nastavení!', 'Regulátor', '');
          end;

        1 .. TBridgeClient._SLOTS_CNT:
          begin
            if (BridgeClient.opened) then
              BridgeClient.LoksToSlot(vehicles, gpurpose.slot, gpurpose.ruc);
          end;

      end; // case

      for var vehicle in vehicles do
        Self.tokenPurpose.Remove(vehicle.addr);
    finally
      vehicles.Free();
    end;
  end

  else if (parsed[2] = 'ERR') then
  begin
    if (F_RegReq.token_req_sent) then
      F_RegReq.ServerResponseErr(parsed[4]);
    if (F_TrainToSlot.token_req_sent) then
      F_TrainToSlot.ServerResponseErr(parsed[4]);

    try
      splitted := TStringList.Create();
      ExtractStringsEx(['|'], [], parsed[3], splitted);
      for var i := 0 to splitted.Count - 1 do
      begin
        try
          Self.tokenPurpose.Remove(StrToInt(splitted[i]));
        finally

        end;
      end;
    finally
      splitted.Free();
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TTokens.LokosToReg(orId: string; lokos: array of Word);
var str: string;
begin
  str := '';
  for var i := 0 to Length(lokos) - 1 do
  begin
    str := str + IntToStr(lokos[i]) + '|';
    Self.tokenPurpose.Remove(lokos[i]);
  end;

  PanelTCPClient.SendLn(orId + ';LOK-REQ;PLEASE;' + str);
end;

procedure TTokens.LokosToMaus(orId: string; lokos: array of Word; slot: Integer; ruc: boolean);
var str: string;
begin
  str := '';
  for var i := 0 to Length(lokos) - 1 do
  begin
    str := str + IntToStr(lokos[i]) + '|';
    Self.tokenPurpose.AddOrSetValue(lokos[i], Purpose(slot, ruc));
  end;

  PanelTCPClient.SendLn(orId + ';LOK-REQ;PLEASE;' + str);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TTokens.ResetMausTokens();
begin
  Self.tokenPurpose.Clear();
end;

/// /////////////////////////////////////////////////////////////////////////////

class function TTokens.Purpose(slot: Integer; ruc: boolean): TTokenPurpose;
begin
  Result.slot := slot;
  Result.ruc := ruc;
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

tokens := TTokens.Create();

finalization

FreeAndNil(tokens);

end.
