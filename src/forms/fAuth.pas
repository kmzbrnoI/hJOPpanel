unit fAuth;

{
  Autorizacni okno.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Hash, ComCtrls, ExtCtrls, Generics.Collections, RPConst;

type
  TAuthLevelDesc = record
   short, save, use, save_hint:string;
  end;

const
  _AUTH_DESC : array [0..2] of TAuthLevelDesc =
  (
    (
      short:     'Paranoidní';
      save:      'Heslo nebude uloženo.';
      use:       'Pøi zmìnì oprávnìní oblasti øízení, otevøení regulátoru apod. budete vždy vyzvání k zadání uživatelského jména a hesla.';
      save_hint: '';
    ),

    (
      short:     'Výchozí';
      save:      'Heslo bude uloženo pouze pro toto spojení, po odpojení od serveru bude heslo smazáno.';
      use:       'Pøi zmìnì oprávnìní oblasti øízení, otevøení regulátoru apod. bude použito toto heslo, nemusíte jej tedy znovu zadávat.';
      save_hint: 'Heslo je uloženo pouze v pamìti programu, žádný jiný program k nìmu nemá pøístup, ve formì hashe SHA 256.';
    ),

    (
      short:     'Uložit heslo dlouhodobì';
      save:      'Heslo bude uloženo, dokud uložení v oknì Nastavení nezrušíte.';
      use:       'Pøi jakémkoliv budoucím požadavku o autorizaci, dokonce i po restartování programu, bude použito toto heslo.';
      save_hint: '';
    )
  );


type
  TAuthFilledCallback = procedure (Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean) of object;

  TF_Auth = class(TForm)
    P_Message: TPanel;
    P_Body: TPanel;
    TB_Remeber: TTrackBar;
    GB_RemberDesc: TGroupBox;
    ST_Rem2: TStaticText;
    ST_Rem4: TStaticText;
    ST_Rem1: TStaticText;
    ST_Rem3: TStaticText;
    Label1: TLabel;
    E_Password: TEdit;
    Label15: TLabel;
    E_username: TEdit;
    Label14: TLabel;
    ST_Error: TStaticText;
    CHB_uLI_Daemon: TCheckBox;
    CHB_IPC_auth: TCheckBox;
    P_Buttons: TPanel;
    B_Guest: TButton;
    B_Cancel: TButton;
    B_Apply: TButton;
    procedure B_CancelClick(Sender: TObject);
    procedure B_ApplyClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure TB_RemeberChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    callback:TAuthFilledCallback;                                               // callback volany pri vyplneni udaju
    auth_errors:TDictionary<Integer, string>;                                   // chyby autorizace or ve formatu id_or:error
    auth_remaining:TList<Integer>;                                              // OR_id, u kterych cekame na odpoved autorizace (pri prijimani odpovedi postupne mazeme prvky ze seznamu)
    auth_ors:TIntAr;                                                            // OR k autorizaci (toto pole se nemeni)
    flistening: boolean;                                                        // jestli poslouchame prichozi zpravy o (ne)uspesne autorizaci

    procedure RefreshErrorMessage();

    procedure ShowErrorMessage();
    procedure HideErrorMessage();

    procedure ShowLogging();
    procedure ShowEnter();
    procedure ShowRelogin();

    procedure UpdateCheckboxLayout();

  public
    procedure OpenForm(caption:string; callback:TAuthFilledCallback; or_ids:TIntAr; allow_guest:boolean; username:string = '');
    procedure Listen(caption:string; username:string; remember_level:Integer; callback:TAuthFilledCallback; or_ids:TIntAr; allow_guest:boolean); // neotvirat okno, ale pokud dojde k chybe, zobrazit okno a chybu a umoznit zaadt login znovu

    procedure AuthError(or_index:Integer; error:string);                        // zavolat pri prichodu chyby autorizace
    procedure AuthOK(or_index:Integer);                                         // zavolat pri uspesne autorizaci

    procedure UpdateULIcheckbox();
    procedure UpdateIPCcheckbox();

    property listening:boolean read flistening;                                 // jestli poslouchame na odpovedi o autorizaci

  end;

var
  F_Auth: TF_Auth;

implementation

uses GlobalConfig, fMain, TCPClientPanel, uLIclient, InterProcessCom;

{$R *.dfm}

procedure TF_Auth.B_ApplyClick(Sender: TObject);
var i:Integer;
    hashed:string;
begin
 Self.auth_remaining.Clear();
 for i := 0 to Length(Self.auth_ors)-1 do Self.auth_remaining.Add(Self.auth_ors[i]);
 Self.flistening := true;

 if (Sender = Self.B_Guest) then
  begin
   Self.E_username.Text := GlobConfig.data.guest.username;
   Self.E_Password.Text := 'heslo';
  end;

 Self.auth_errors.Clear();
 Self.HideErrorMessage();
 Self.ShowLogging();

 hashed := GenerateHash(AnsiString(Self.E_Password.Text));

 if ((Self.TB_Remeber.Position > 0) and (Sender = Self.B_Apply) and
     (PanelTCPClient.status = TPanelConnectionStatus.opened)) then
  begin
   GlobConfig.data.auth.autoauth := true;
   GlobConfig.data.auth.username := Self.E_username.Text;
   GlobConfig.data.auth.password := hashed;
   GlobConfig.data.auth.forgot   := (Self.TB_Remeber.Position = 1);
  end;

 if ((Self.CHB_uLI_Daemon.Visible) and (Sender = Self.B_Apply) and
     (Self.CHB_uLI_Daemon.Enabled) and (Self.CHB_uLI_Daemon.Checked)) then
  begin
   BridgeClient.toLogin.username := Self.E_username.Text;
   BridgeClient.toLogin.password := hashed;
  end;

 if ((Self.CHB_IPC_auth.Checked) and (Self.CHB_IPC_auth.Visible)) then
  begin
   if (Sender = Self.B_Guest) then
    begin
     IPC.username := GlobConfig.data.guest.username;
     IPC.password := GlobConfig.data.guest.password;
    end else begin
     IPC.username := Self.E_username.Text;
     IPC.password := hashed;
    end;
  end;

 if (Sender = Self.B_Apply) then
   Self.callback(Self, Self.E_username.Text, hashed, Self.auth_ors, false)
 else
   Self.callback(Self, GlobConfig.data.guest.username, GlobConfig.data.guest.password, Self.auth_ors, true);
end;

procedure TF_Auth.B_CancelClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_Auth.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Self.E_username.Text := '';
 Self.E_Password.Text := '';

 Self.auth_errors.Clear();
 Self.auth_remaining.Clear();
 Self.flistening := false;
 if (PanelTCPClient.status = TPanelConnectionStatus.opened) then F_Main.A_ReAuth.Enabled := true;
end;

procedure TF_Auth.FormCreate(Sender: TObject);
begin
 Self.auth_errors := TDictionary<Integer, string>.Create();
 Self.auth_remaining := TList<Integer>.Create();
 Self.flistening := false;
end;

procedure TF_Auth.FormDestroy(Sender: TObject);
begin
 Self.auth_errors.Free();
 Self.auth_remaining.Free();
end;

procedure TF_Auth.FormKeyPress(Sender: TObject; var Key: Char);
begin
 if (Key = #$1B) then
  Self.B_CancelClick(Self.B_Cancel);
 if ((Key = ';') or (Key = ',')) then Key := #0;
end;

procedure TF_Auth.FormShow(Sender: TObject);
begin
 F_Main.A_ReAuth.Enabled := false;
end;

procedure TF_Auth.OpenForm(caption:string; callback:TAuthFilledCallback; or_ids:TIntAr; allow_guest:boolean; username:string = '');
begin
 Self.flistening := false;
 Self.callback := callback;

 Self.auth_ors := or_ids;
 Self.auth_errors.Clear();

 Self.RefreshErrorMessage();
 Self.ShowEnter();

 Self.E_username.Text := username;
 Self.E_Password.Text := '';
 Self.TB_Remeber.Position := GlobConfig.data.auth.auth_default_level;
 Self.TB_RemeberChange(Self.TB_Remeber);
 if (username = '') then
   Self.ActiveControl := Self.E_username
 else
   Self.ActiveControl := Self.E_Password;
 Self.Caption := caption;

 Self.B_Guest.Visible := allow_guest and GlobConfig.data.guest.allow;

 Self.UpdateULIcheckbox();
 Self.CHB_uLI_Daemon.Checked := Self.CHB_uLI_Daemon.Visible and Self.CHB_uLI_Daemon.Enabled;
 Self.UpdateIPCcheckbox();
 Self.CHB_IPC_auth.Checked := true;

 Self.Show();
end;

procedure TF_Auth.Listen(caption:string; username:string; remember_level:Integer; callback:TAuthFilledCallback; or_ids:TIntAr; allow_guest:boolean);
var i:Integer;
begin
 Self.flistening := true;
 Self.callback := callback;

 Self.auth_ors := or_ids;
 Self.auth_errors.Clear();

 Self.auth_remaining.Clear();
 for i := 0 to Length(Self.auth_ors)-1 do Self.auth_remaining.Add(Self.auth_ors[i]);

 Self.E_username.Text := username;
 Self.E_Password.Text := '';
 Self.TB_Remeber.Position := remember_level;
 Self.Caption := caption;
 Self.B_Guest.Visible := allow_guest and GlobConfig.data.guest.allow;

 Self.UpdateULIcheckbox();
 Self.CHB_uLI_Daemon.Checked := Self.CHB_uLI_Daemon.Visible and Self.CHB_uLI_Daemon.Enabled;
 Self.UpdateIPCcheckbox();
 Self.CHB_IPC_auth.Checked := true;
end;

procedure TF_Auth.TB_RemeberChange(Sender: TObject);
begin
 Self.ST_Rem1.Caption := _AUTH_DESC[Self.TB_Remeber.Position].short;
 Self.ST_Rem2.Caption := _AUTH_DESC[Self.TB_Remeber.Position].save;
 Self.ST_Rem3.Caption := _AUTH_DESC[Self.TB_Remeber.Position].use;
 Self.ST_Rem4.Caption := _AUTH_DESC[Self.TB_Remeber.Position].save_hint;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Auth.RefreshErrorMessage();
var same:boolean;
    Item: TPair<Integer, string>;
    val, valDiff:string;
begin
 if (Self.auth_errors.Count = 0) then
  begin
   Self.HideErrorMessage();
   Exit();
  end;

 // zkontrolujeme jestli jsou ve slovniku stejne hodnoty
 same := true;
 valDiff := '';
 for val in Self.auth_errors.Values do
  begin
   if (valDiff = '') then valDiff := val;
   
   if (val <> valDiff) then
    begin
     same := false;
     break;
    end;
  end;//for

 if (same) then
  begin
   // zobrazime jen jednu chybu
   Self.ST_Error.Caption := val;
  end else begin
   // zobrazime chybu pro kazdou oblast rizeni
   Self.ST_Error.Caption := '';
   for Item in Self.auth_errors do
    begin
     if (Assigned(Self.auth_ors)) then
       Self.ST_Error.Caption := Self.ST_Error.Caption + relief.ORs[Item.Key].Name + ': ' + Item.Value + #13#10
     else
       Self.ST_Error.Caption := Self.ST_Error.Caption + Item.Value + #13#10;
    end;
  end;

 Self.ShowErrorMessage();
end;

procedure TF_Auth.AuthError(or_index:Integer; error:string);
begin
 if (not Self.listening) then Exit();
 
 Self.auth_errors.AddOrSetValue(or_index, error);
 if (Self.auth_remaining.Contains(or_index)) then Self.auth_remaining.Remove(or_index);

 if (not Self.Showing) then Self.Show();
 Self.RefreshErrorMessage();

 // po neuspesnem pokusu o prihlaseni povolime prihlaseni jako host
 Self.B_Guest.Visible := GlobConfig.data.guest.allow;

 // znovu zobrazime prihlasovaci dialog
 if (Self.auth_remaining.Count = 0) then Self.ShowRelogin();
end;

procedure TF_Auth.AuthOK(or_index:Integer);
begin
 if (not Assigned(Self.auth_ors)) then
  begin
   Self.Close();
   Exit();
  end;

 if (not Self.auth_remaining.Contains(or_index) or (not Self.listening)) then Exit();

 Self.auth_remaining.Remove(or_index);
 Self.RefreshErrorMessage();

 // necessary
 if ((Self.auth_errors.Count = 0) and (Self.auth_remaining.Count = 0)) then Self.flistening := false;

 if ((Self.auth_errors.Count = 0) and (Self.Showing)) then
  begin
   if (Self.auth_remaining.Count = 0) then
    Self.Close()
   else
    Self.ShowRelogin();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Auth.ShowErrorMessage();
begin
 Self.P_Message.Visible := true;
 Self.P_Body.Top := 110;
 Self.Height := P_Body.Top + P_Body.Height + 30;

 Self.ST_Error.Visible      := true;
 Self.P_Message.Color       := $DEDEF2;
 Self.P_Message.ShowCaption := false;
end;

procedure TF_Auth.HideErrorMessage();
begin
 Self.Height := P_Body.Top + P_Body.Height + 30;
 Self.P_Message.Visible := false;
 Self.P_Body.Top := 8;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Auth.ShowLogging();
begin
 Self.E_username.Enabled := false;
 Self.E_Password.Enabled := false;
 Self.TB_Remeber.Enabled := false;
 Self.B_Apply.Enabled    := false;

 Self.ST_Error.Visible      := false;
 Self.P_Message.Color       := $F7EDD9;
 Self.P_Message.ShowCaption := true;
 Self.P_Message.Visible     := true;
 Self.P_Message.BringToFront();
end;

procedure TF_Auth.ShowEnter();
begin
 Self.E_username.Enabled := true;
 Self.E_Password.Enabled := true;
 Self.TB_Remeber.Enabled := true;
 Self.B_Apply.Enabled    := true;
end;

procedure TF_Auth.ShowRelogin();
begin
 Self.ShowEnter();
 Self.E_Password.Text := '';
 Self.E_username.SetFocus();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Auth.UpdateULIcheckbox();
begin
 Self.CHB_uLI_Daemon.Visible := (BridgeClient.opened) and
  ((BridgeClient.authStatus = no) or (BridgeClient.authStatus = cannot));

 if (Self.CHB_uLI_Daemon.Visible) then
  begin
   Self.CHB_uLI_Daemon.Enabled := (BridgeClient.authStatus = no);
   if (not Self.CHB_uLI_Daemon.Enabled) then Self.CHB_uLI_Daemon.Checked := false;
  end;

 Self.UpdateCheckboxLayout();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Auth.UpdateIPCcheckbox();
var old:boolean;
begin
 old := Self.CHB_IPC_auth.Visible;
 Self.CHB_IPC_auth.Visible := (IPC.InstanceCnt > 1) and (GlobConfig.data.auth.ipc_send) and (Self.auth_ors <> nil);

 // pokud je okno otevrene, nezaskrtavame (aby uzivatel omylem nepotrvdit neco, co nechce)
 if ((not old) and (Self.CHB_IPC_auth.Visible)) then
   Self.CHB_IPC_auth.Checked := false;

 Self.UpdateCheckboxLayout();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Auth.UpdateCheckboxLayout();
var top:Integer;
begin
 top := 327;

 if (Self.CHB_IPC_auth.Visible) then
  begin
   Self.CHB_IPC_auth.Top := top;
   top := top + 20;
  end;

 if (Self.CHB_uLI_Daemon.Visible) then
  begin
   Self.CHB_uLI_Daemon.Top := top;
   top := top + 20;
  end;

 Self.P_Body.Height := top + P_Buttons.Height;
 Self.Height := P_Body.Top + P_Body.Height + 30;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
