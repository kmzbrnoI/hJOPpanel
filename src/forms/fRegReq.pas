unit fRegReq;

{
  Okno potvrzovani zadost o loko z rucniho regulatoru.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, HVDb, ExtCtrls, uLIClient;

type
  TF_RegReq = class(TForm)
    GB_User: TGroupBox;
    Label1: TLabel;
    L_Username: TLabel;
    Label2: TLabel;
    L_Name: TLabel;
    Label3: TLabel;
    M_Note: TMemo;
    GB_Lokos: TGroupBox;
    LV_Lokos: TListView;
    B_Remote: TButton;
    B_Local: TButton;
    L_Stav: TLabel;
    P_MausSlot: TPanel;
    L_Slot: TLabel;
    procedure B_RemoteClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure B_LocalClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    or_id:string;
    HVDb:THVDb;
    destroy_hvdb:boolean;
    maus:boolean;
    B_Slots: array [1..TBridgeClient._SLOTS_CNT] of TButton;

    procedure FillHVs(HVDb:THVDb; all_selected:boolean);
    procedure CreateSlotsButtons();

  public

   token_req_sent:boolean;


    procedure Open(HVDb:THVDb; or_id:string; username,firstname,lastname,comment:string; remote:boolean; destroy_hvdb, all_selected, maus:boolean);
    procedure ServerResponseOK();
    procedure ServerResponseErr(err:string);
    procedure ServerCanceled();

    procedure RepaintSlots();

  end;

var
  F_RegReq: TF_RegReq;

implementation

{$R *.dfm}

uses ORList, TCPClientPanel, LokTokens;

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.Open(HVDb:THVDb;or_id:string;username,firstname,lastname,comment:string; remote:boolean; destroy_hvdb, all_selected, maus:boolean);
var i:Integer;
begin
 Self.or_id := or_id;
 Self.HVDb  := HVDb;
 Self.destroy_hvdb := destroy_hvdb;
 Self.maus := maus;

 Self.L_Username.Caption := username;
 Self.L_Name.Caption     := firstname + ' ' + lastname;
 Self.M_Note.Text        := comment;

 Self.B_Remote.Enabled := true;

 Self.B_Remote.Enabled := remote;
 if (Self.B_Remote.Enabled) then Self.B_Remote.Default := true else Self.B_Local.Default := true;

 Self.FillHVs(HVDb, all_selected);

 Self.L_Stav.Caption    := 'Vyberte lokomotivy';
 Self.L_Stav.Font.Color := clBlack;

 Self.P_MausSlot.Visible := maus;
 Self.B_Remote.Visible   := not maus;
 Self.B_Local.Visible    := not maus;
 if (maus) then
  begin
   Self.L_Stav.Top := Self.P_MausSlot.Top + Self.P_MausSlot.Height + 5;
   Self.RepaintSlots();

   for i := 1 to TBridgeClient._SLOTS_CNT do
    begin
     if ((self.B_Slots[i].Visible) and (Self.B_Slots[i].Enabled)) then
      begin
       Self.B_Slots[i].Default := true;
       break;
      end;
    end;
  end else begin
   Self.L_Stav.Top := Self.B_Remote.Top + Self.B_Remote.Height + 5;
  end;
 Self.ClientHeight := Self.L_Stav.Top + Self.L_Stav.Height + 5;

 Self.Show();
 Self.LV_Lokos.SetFocus();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.FillHVs(HVDb:THVDb; all_selected:boolean);
var LI:TListItem;
    HV:THV;
begin
 Self.LV_Lokos.Clear();
 for HV in HVDb.HVs do
  begin
   LI := Self.LV_Lokos.Items.Add;
   LI.Caption := IntToStr(HV.Adresa);
   LI.SubItems.Add(HV.Nazev + ' (' + HV.Oznaceni + ')');
   LI.Checked := all_selected;
  end;//for i
end;

procedure TF_RegReq.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if ((Self.HVDb <> nil) and (Self.destroy_hvdb)) then Self.HVDb.Free();
 Self.HVDb := nil;
 Self.token_req_sent := false;
end;

procedure TF_RegReq.FormCreate(Sender: TObject);
begin
 Self.CreateSlotsButtons();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.B_LocalClick(Sender: TObject);
var lokos:array of Word;
    LI:TListItem;
    cnt, j:Integer;
begin
 cnt := 0;
 for LI in Self.LV_Lokos.Items do
   if (LI.Checked) then inc(cnt);

 if (cnt = 0) then
  begin
   Application.MessageBox('Vyberte alespoò jedno hnací vozidlo', 'Nelze pokraèovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 SetLength(lokos, cnt);
 j := 0;
 for LI in Self.LV_Lokos.Items do
  begin
   if (LI.Checked) then
    begin
     lokos[j] := StrToInt(LI.Caption);
     Inc(j);
    end;
  end;

 if (Self.maus) then
   tokens.LokosToMaus(Self.or_id, lokos, TButton(Sender).Tag, false)
 else
   tokens.LokosToReg(Self.or_id, lokos);

 Self.L_Stav.Caption := 'Odeslána žádost o vydání tokenù...';
 Self.token_req_sent := true;
end;

procedure TF_RegReq.B_RemoteClick(Sender: TObject);
var str:string;
    LI:TListItem;
    one:boolean;
begin
 str := '';
 one := false;

 for LI in Self.LV_Lokos.Items do
   if (LI.Checked) then
    begin
     str := str + LI.Caption + '|';
     one := true;
    end;

 if (not one) then
  begin
   Application.MessageBox('Vyberte alespoò jedno hnací vozidlo', 'Nelze pokraèovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 PanelTCPClient.SendLn(Self.or_id+';LOK-REQ;LOK;'+str);

 Self.L_Stav.Caption := 'Odesílám seznam lokomotiv na server...';
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.ServerResponseOK();
begin
 Self.token_req_sent := false;
 Self.Close();
end;

procedure TF_RegReq.ServerResponseErr(err:string);
begin
 Self.token_req_sent := false;
 Self.L_Stav.Font.Color := clRed;
 Self.L_Stav.Caption := err;
end;

procedure TF_RegReq.ServerCanceled();
begin
 Self.B_Remote.Enabled := false;
 Self.B_Local.Default := true;

 Self.L_Stav.Font.Color := clRed;
 Self.L_Stav.Caption := 'Regulátor zrušil žádost';
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.CreateSlotsButtons();
var i:Integer;
begin
 for i := 1 to TBridgeClient._SLOTS_CNT do
  begin
   Self.B_Slots[i] := TButton.Create(Self.P_MausSlot);
   with (Self.B_Slots[i]) do
    begin
     Parent := Self.P_MausSlot;
     Top := 25;
     Tag := i;
     Width := 70;
     OnClick := Self.B_LocalClick;
     Caption := IntToStr(i);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.RepaintSlots();
var cnt, i, j:Integer;
    partWidth:Integer;
begin
 cnt := BridgeClient.activeSlotsCount;

 if (cnt = 0) then
   Self.L_Slot.Caption := 'Do slotu: (žádný slot není k dispozici)'
 else
   Self.L_Slot.Caption := 'Do slotu:';

 j := 0;
 if (cnt > 0) then
   partWidth := ((P_MausSlot.Width-20) div cnt)
 else
   partWidth := 0;

 for i := 1 to TBridgeClient._SLOTS_CNT do
  begin
   with (Self.B_Slots[i]) do
    begin
     Visible := ((BridgeClient.sloty[i] = ssAvailable) or (BridgeClient.sloty[i] = ssFull));
     Enabled := (BridgeClient.sloty[i] = ssAvailable);

     if (Visible) then
      begin
       Self.B_Slots[i].Left := (partWidth*j + (partWidth div 2) - (Self.B_Slots[i].Width div 2)) + 10;
       Inc(j);
      end;

    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

end.
