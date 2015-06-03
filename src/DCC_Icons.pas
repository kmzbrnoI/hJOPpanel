unit DCC_Icons;

interface

uses Classes, Types, SysUtils;

type
  TDCCStatus = (disabled, stopped, running);
  TDCC = class
   private
    fstatus:TDCCStatus;

    procedure Show();
    procedure SetStatus(new:tDCCStatus);

   public

    constructor Create();

    procedure Parse(data:TStrings);

    procedure Go();
    procedure Stop();

    property status:TDCCStatus read fstatus write SetStatus;

  end;

var
  DCC:TDCC;

implementation

uses Main, TCPClientPanel;

////////////////////////////////////////////////////////////////////////////////

constructor TDCC.Create();
begin
 inherited Create();
 Self.status := TDCCStatus.disabled;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TDCC.Show();
begin
 case (Self.status) of
  TDCCStatus.disabled:begin
   F_Main.SB_DCC_Go.Enabled   := false;
   F_Main.SB_DCC_Stop.Enabled := false;
  end;

  TDCCStatus.stopped:begin
   F_Main.SB_DCC_Go.Enabled   := true;
   F_Main.SB_DCC_Stop.Enabled := false;
  end;

  TDCCStatus.running:begin
   F_Main.SB_DCC_Go.Enabled   := false;
   F_Main.SB_DCC_Stop.Enabled := true;
  end;
 end;//case
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TDCC.SetStatus(new:tDCCStatus);
begin
 if (new <> Self.fstatus) then
  begin
   Self.fstatus := new;
   Self.Show();
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//  -;DCC;GO                                - DCC zapnuto
//  -;DCC;STOP                              - DCC vypnuto
//  -;DCC;DISABLED                          - neni mozno zmenit stav DCC z tohoto klienta
procedure TDCC.Parse(data:TStrings);
begin
 if (data[2] = 'GO') then
  Self.status := TDCCStatus.running
 else if (data[2] = 'STOP') then
  Self.status := TDCCStatus.stopped
 else
  Self.status := TDCCStatus.disabled;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TDCC.Go();
begin
 PanelTCPClient.SendLn('-;DCC;GO');
end;//procedure

procedure TDCC.Stop();
begin
 PanelTCPClient.SendLn('-;DCC;STOP');
end;//procedure

////////////////////////////////////////////////////////////////////////////////

initialization

finalization
  FreeAndNil(DCC);

end.//unit
