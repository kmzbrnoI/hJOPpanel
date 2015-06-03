unit fRegReq;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, HVDb;

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
    procedure B_RemoteClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure B_LocalClick(Sender: TObject);
  private
    or_id:string;
    HVDb:THVDb;
    destroy_hvdb:boolean;

    procedure FillHVs(HVDb:THVDb; all_selected:boolean);

  public

   token_req_sent:boolean;


    procedure Open(HVDb:THVDb;or_id:string;username,firstname,lastname,comment:string; remote:boolean; destroy_hvdb, all_selected:boolean);
    procedure ServerResponseOK();
    procedure ServerResponseErr(err:string);
    procedure ServerCanceled();
  end;

var
  F_RegReq: TF_RegReq;

implementation

{$R *.dfm}

uses ORList, TCPClientPanel;

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.Open(HVDb:THVDb;or_id:string;username,firstname,lastname,comment:string; remote:boolean; destroy_hvdb, all_selected:boolean);
begin
 Self.or_id := or_id;
 Self.HVDb  := HVDb;
 Self.destroy_hvdb := destroy_hvdb;

 Self.L_Username.Caption := username;
 Self.L_Name.Caption     := firstname + ' ' + lastname;
 Self.M_Note.Text        := comment;

 Self.B_Remote.Enabled := true;

 Self.B_Remote.Enabled := remote;
 if (Self.B_Remote.Enabled) then Self.B_Remote.Default := true else Self.B_Local.Default := true;

 Self.FillHVs(HVDb, all_selected);

 Self.L_Stav.Caption    := 'Vyberte lokomotivy';
 Self.L_Stav.Font.Color := clBlack;

 Self.Show();
 Self.LV_Lokos.SetFocus();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.FillHVs(HVDb:THVDb; all_selected:boolean);
var LI:TListItem;
    i:Integer;
begin
 Self.LV_Lokos.Clear();
 for i := 0 to HVDb.count-1 do
  begin
   LI := Self.LV_Lokos.Items.Add;
   LI.Caption := IntToStr(HVDb.HVs[i].Adresa);
   LI.SubItems.Add(HVDb.HVs[i].Nazev + ' (' + HVDb.HVs[i].Oznaceni + ')');
   LI.Checked := all_selected;
  end;//for i
end;

procedure TF_RegReq.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if ((Self.HVDb <> nil) and (Self.destroy_hvdb)) then Self.HVDb.Free();
 Self.HVDb := nil;
 Self.token_req_sent := false;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_RegReq.B_LocalClick(Sender: TObject);
var str:string;
    LI:TListItem;
    one:boolean;
begin
 str := '';
 one := false;

 for LI in Self.LV_Lokos.Items do
   if (LI.Checked) then
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

 PanelTCPClient.SendLn(Self.or_id+';LOK-REQ;PLEASE;'+str);

 Self.L_Stav.Caption := 'Odeslána žádost o vydání tokenù...';
 Self.token_req_sent := true;
end;//procedure

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
 Self.Close();
end;//procedure

procedure TF_RegReq.ServerResponseErr(err:string);
begin
 Self.L_Stav.Font.Color := clRed;
 Self.L_Stav.Caption := err;
end;//procedure

procedure TF_RegReq.ServerCanceled();
begin
 Self.B_Remote.Enabled := false;
 Self.B_Local.Default := true;

 Self.L_Stav.Font.Color := clRed;
 Self.L_Stav.Caption := 'Regulátor zrušil žádost';
end;//procedure

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

end.//procedure
