unit DCC_Icons;

{
  Udrzovani stavu DCC a zobrazovani tlacitek dle aktualniho stavu.
}

interface

uses Classes, SysUtils;

type
  TDCCStatus = (disabled, stopped, running);

  TDCC = class
  private
    fstatus: TDCCStatus;

    procedure Show();
    procedure SetStatus(new: TDCCStatus);

  public

    constructor Create();

    procedure Parse(data: TStrings);

    procedure Go();
    procedure Stop();

    property status: TDCCStatus read fstatus write SetStatus;

  end;

var
  DCC: TDCC;

implementation

uses fMain, TCPClientPanel;

/// /////////////////////////////////////////////////////////////////////////////

constructor TDCC.Create();
begin
  inherited Create();
  Self.status := TDCCStatus.disabled;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TDCC.Show();
begin
  case (Self.status) of
    TDCCStatus.disabled:
      begin
        F_Main.SB_DCC_Go.Enabled := false;
        F_Main.SB_DCC_Stop.Enabled := false;
      end;

    TDCCStatus.stopped:
      begin
        F_Main.SB_DCC_Go.Enabled := true;
        F_Main.SB_DCC_Stop.Enabled := false;
      end;

    TDCCStatus.running:
      begin
        F_Main.SB_DCC_Go.Enabled := false;
        F_Main.SB_DCC_Stop.Enabled := true;
      end;
  end; // case
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TDCC.SetStatus(new: TDCCStatus);
begin
  if (new <> Self.fstatus) then
  begin
    Self.fstatus := new;
    Self.Show();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

// -;DCC;GO                                - DCC zapnuto
// -;DCC;STOP                              - DCC vypnuto
// -;DCC;DISABLED                          - neni mozno zmenit stav DCC z tohoto klienta
procedure TDCC.Parse(data: TStrings);
begin
  if (data[2] = 'GO') then
    Self.status := TDCCStatus.running
  else if (data[2] = 'STOP') then
    Self.status := TDCCStatus.stopped
  else
    Self.status := TDCCStatus.disabled;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TDCC.Go();
begin
  PanelTCPClient.SendLn('-;DCC;GO');
end;

procedure TDCC.Stop();
begin
  PanelTCPClient.SendLn('-;DCC;STOP');
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

finalization

FreeAndNil(DCC);

end.// unit
