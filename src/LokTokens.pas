unit LokTokens;

interface

uses SysUtils, Generics.Collections, Classes;

type
  TTokenPurpose = (tpReg, tpMaus);

  TTokens = class
    private
      tokenPurpose:TDictionary<Word, Integer>;                                  // mapa adresa -> maus slot

    public

       constructor Create();
       destructor Destroy(); override;

       procedure ParseData(var parsed:TStrings);
       procedure LokosToReg(orId:string; lokos:array of Word);                         // lokos: 1234|1235| ....
       procedure LokosToMaus(orId:string; lokos:array of Word; slot:Integer);
       procedure ResetMausTokens();

  end;

var
  tokens : TTokens;

implementation

uses TCPClientPanel, HVDb, fRegReq, BottomErrors, uLIClient;

////////////////////////////////////////////////////////////////////////////////

constructor TTokens.Create();
begin
 inherited;
 tokenPurpose := TDictionary<Word, Integer>.Create();
end;

destructor TTokens.Destroy();
begin
 Self.tokenPurpose.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTokens.ParseData(var parsed:TStrings);
var HVs:THVDb;
    i:Integer;
    slot, gslot: Integer;
begin
 if (parsed[2] = 'OK') then
  begin
   if (F_RegReq.token_req_sent) then F_RegReq.ServerResponseOK();

   HVs := THVDb.Create();
   HVs.ParseHVsFromToken(parsed[3]);

   gslot := 0;
   for i := 0 to HVs.count-1 do
    begin
     if ((gslot = 0) and (Self.tokenPurpose.TryGetValue(HVs.HVs[i].Adresa, slot))) then gslot := slot
     else if ((gslot > 0) and ((not Self.tokenPurpose.TryGetValue(HVs.HVs[i].Adresa, slot)) or (slot <> gslot))) then
      begin
       gslot := 0;
       break;
      end;
    end;

   case (gslot) of
     0: begin
         try
           HVs.OpenJerry();
         except
           on E:Exception do
             Errors.writeerror(E.Message, 'Jerry', '');
         end;
     end;

     1..TBridgeClient._SLOTS_CNT: begin
         if (BridgeClient.opened) then BridgeClient.LoksToSlot(HVs, gslot);
     end;

   end;//case

   for i := 0 to HVs.count-1 do
     Self.tokenPurpose.Remove(HVs.HVs[i].Adresa);

   HVs.Free();
  end

 else if (parsed[2] = 'ERR') then
   if (F_RegReq.token_req_sent) then F_RegReq.ServerResponseErr(parsed[3]);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTokens.LokosToReg(orId:string; lokos:array of Word);
var i:Integer;
    str:string;
begin
 str := '';
 for i := 0 to Length(lokos)-1 do
  begin
   str := str + IntToStr(lokos[i]) + '|';
   Self.tokenPurpose.Remove(lokos[i]);
  end;

 PanelTCPClient.SendLn(orId+';LOK-REQ;PLEASE;'+str);
end;

procedure TTokens.LokosToMaus(orId:string; lokos:array of Word; slot:Integer);
var i:Integer;
    str:string;
begin
 str := '';
 for i := 0 to Length(lokos)-1 do
  begin
   str := str + IntToStr(lokos[i]) + '|';
   Self.tokenPurpose.AddOrSetValue(lokos[i], slot);
  end;

 PanelTCPClient.SendLn(orId+';LOK-REQ;PLEASE;'+str);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTokens.ResetMausTokens();
begin
 Self.tokenPurpose.Clear();
end;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

initialization
  tokens := TTokens.Create();

finalization
  FreeAndNil(tokens);
end.
