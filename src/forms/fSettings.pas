unit fSettings;

{
  Okynko nastaveni.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, Spin, Hash;

type
  TF_Settings = class(TForm)
    B_Apply: TButton;
    B_Storno: TButton;
    Label4: TLabel;
    PC_Main: TPageControl;
    TS_Server: TTabSheet;
    TS_Sounds: TTabSheet;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    E_Snd_Trat: TEdit;
    B_Proch1: TButton;
    CHB_Relative: TCheckBox;
    E_Snd_Error: TEdit;
    B_Proch2: TButton;
    E_Snd_PS: TEdit;
    B_Proch3: TButton;
    E_Snd_Pretizeni: TEdit;
    B_Proch4: TButton;
    E_Snd_Zprava: TEdit;
    B_Proch5: TButton;
    TS_Symbols: TTabSheet;
    Label9: TLabel;
    LB_Symbols: TListBox;
    TS_Vysvetlivky: TTabSheet;
    CHB_Vysv_Rel: TCheckBox;
    Label11: TLabel;
    E_Vysv: TEdit;
    B_Proch_Vysv: TButton;
    E_Host: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    CHB_Autoconnect: TCheckBox;
    TS_Panel: TTabSheet;
    Label12: TLabel;
    E_Panel: TEdit;
    B_Panel_Proch: TButton;
    CHB_Panel_Rel: TCheckBox;
    SE_Port: TSpinEdit;
    OD_Snd: TOpenDialog;
    OD_Vysv: TOpenDialog;
    OD_Panel: TOpenDialog;
    TS_Timer: TTabSheet;
    Label13: TLabel;
    LB_Timer: TListBox;
    TS_Rights: TTabSheet;
    GB_Auth: TGroupBox;
    CHB_RememberAuth: TCheckBox;
    Label14: TLabel;
    E_username: TEdit;
    Label15: TLabel;
    E_Password: TEdit;
    CHB_ShowPassword: TCheckBox;
    RG_Mouse: TRadioGroup;
    StaticText1: TStaticText;
    CHB_Resuscitation: TCheckBox;
    CHB_Forgot: TCheckBox;
    TS_Regulator: TTabSheet;
    CHB_Jerry_username: TCheckBox;
    Label17: TLabel;
    E_Regulator: TEdit;
    B_Reg_Proch: TButton;
    CHB_Reg_Rel: TCheckBox;
    OD_Reg: TOpenDialog;
    TS_ORAuth: TTabSheet;
    GroupBox1: TGroupBox;
    Label16: TLabel;
    LB_AutoAuthOR: TListBox;
    CB_ORRights: TComboBox;
    GroupBox2: TGroupBox;
    TB_Remeber: TTrackBar;
    ST_Rem1: TStaticText;
    ST_Rem2: TStaticText;
    ST_Rem3: TStaticText;
    ST_Rem4: TStaticText;
    TS_Guest: TTabSheet;
    Label10: TLabel;
    E_Guest_Username: TEdit;
    Label18: TLabel;
    E_Guest_Password: TEdit;
    CHB_Guest_Enable: TCheckBox;
    TS_uLIdaemon: TTabSheet;
    GB_uLI_Run: TGroupBox;
    CHB_uLI_Run: TCheckBox;
    Label19: TLabel;
    E_uLI_Path: TEdit;
    B_uLI_Search: TButton;
    CHB_uLI_Rel: TCheckBox;
    GB_uLI_Connect: TGroupBox;
    CHB_uLI_Login: TCheckBox;
    OD_uLI: TOpenDialog;
    TS_IPC: TTabSheet;
    CHB_IPC_Send: TCheckBox;
    CHB_IPC_Receive: TCheckBox;
    E_Snd_Privolavacka: TEdit;
    B_Proch6: TButton;
    B_Proch7: TButton;
    E_Snd_Timeout: TEdit;
    Label20: TLabel;
    Label21: TLabel;
    TS_Sounds2: TTabSheet;
    Label22: TLabel;
    Label23: TLabel;
    E_Snd_NeniJC: TEdit;
    E_Snd_StaveniVyzva: TEdit;
    B_Proch8: TButton;
    B_Proch9: TButton;
    CHB_Relative2: TCheckBox;
    procedure B_StornoClick(Sender: TObject);
    procedure B_ApplyClick(Sender: TObject);
    procedure B_Proch1Click(Sender: TObject);
    procedure B_Proch_VysvClick(Sender: TObject);
    procedure B_Panel_ProchClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CHB_RememberAuthClick(Sender: TObject);
    procedure LB_AutoAuthORClick(Sender: TObject);
    procedure CB_ORRightsChange(Sender: TObject);
    procedure CHB_ShowPasswordClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure E_usernameKeyPress(Sender: TObject; var Key: Char);
    procedure B_Reg_ProchClick(Sender: TObject);
    procedure E_PasswordChange(Sender: TObject);
    procedure TB_RemeberChange(Sender: TObject);
    procedure LB_SymbolsDblClick(Sender: TObject);
    procedure LB_TimerDblClick(Sender: TObject);
    procedure E_Guest_PasswordChange(Sender: TObject);
    procedure CHB_Guest_EnableClick(Sender: TObject);
    procedure B_uLI_SearchClick(Sender: TObject);
    procedure CHB_uLI_RunClick(Sender: TObject);
  private
    passwdChanged: boolean;
    guestPasswdChanged: boolean;
  public
    procedure OpenForm();
  end;

var
  F_Settings: TF_Settings;

implementation

uses GlobalConfig, Symbols, fMain, Resuscitation, fAuth, TCPClientPanel,
     uLIclient, PanelOR;

////////////////////////////////////////////////////////////////////////////////

{$R *.dfm}

procedure TF_Settings.B_ApplyClick(Sender: TObject);
var ss, ss2:TSymbolSet;
    oldss:TSymbolSetType;
begin
 Screen.Cursor := crHourGlass;

 GlobConfig.data.panel_fn                  := Self.E_Panel.Text;
 GlobConfig.data.vysv_fn                   := Self.E_Vysv.Text;
 GlobConfig.data.panel_mouse               := Self.RG_Mouse.ItemIndex;
 GlobConfig.data.resuscitation             := Self.CHB_Resuscitation.Checked;

 GlobConfig.data.reg.reg_user              := Self.CHB_Jerry_username.Checked;
 GlobConfig.data.reg.reg_fn                := Self.E_Regulator.Text;

 GlobConfig.data.server.host               := Self.E_Host.Text;
 GlobConfig.data.server.port               := Self.SE_Port.Value;
 GlobConfig.data.server.autoconnect        := Self.CHB_Autoconnect.Checked;

 GlobConfig.data.auth.autoauth             := Self.CHB_RememberAuth.Checked;
 if (Self.passwdChanged) then
  begin
   if (GlobConfig.data.auth.autoauth) then
    begin
     GlobConfig.data.auth.username           := Self.E_username.Text;
     GlobConfig.data.auth.password           := GenerateHash(AnsiString(Self.E_Password.Text));
    end else begin
     GlobConfig.data.auth.username           := '';
     GlobConfig.data.auth.password           := '';
    end;
  end;//if Self.passwdChanged
 GlobConfig.data.auth.forgot               := Self.CHB_Forgot.Checked;
 GlobConfig.data.auth.auth_default_level   := Self.TB_Remeber.Position;

 GlobConfig.data.auth.ipc_send             := Self.CHB_IPC_Send.Checked;
 GlobConfig.data.auth.ipc_receive          := Self.CHB_IPC_Receive.Checked;

 GlobConfig.data.sounds.sndTratSouhlas     := Self.E_Snd_Trat.Text;
 GlobConfig.data.sounds.sndChyba           := Self.E_Snd_Error.Text;
 GlobConfig.data.sounds.sndRizikovaFce     := Self.E_Snd_PS.Text;
 GlobConfig.data.sounds.sndPretizeni       := Self.E_Snd_Pretizeni.Text;
 GlobConfig.data.sounds.sndPrichoziZprava  := Self.E_Snd_Zprava.Text;
 GlobConfig.data.sounds.sndPrivolavacka    := Self.E_Snd_Privolavacka.Text;
 GlobConfig.data.sounds.sndTimeout         := Self.E_Snd_Timeout.Text;
 GlobConfig.data.sounds.sndStaveniVyzva    := Self.E_Snd_StaveniVyzva.Text;
 GlobConfig.data.sounds.sndNeniJC          := Self.E_Snd_NeniJC.Text;

 GlobConfig.data.guest.allow := Self.CHB_Guest_Enable.Checked;
 if (Self.CHB_Guest_Enable.Checked) then
  begin
   GlobConfig.data.guest.username := Self.E_Guest_Username.Text;
   if (Self.guestPasswdChanged) then GlobConfig.data.guest.password := GenerateHash(AnsiString(Self.E_Guest_Password.Text));
  end else begin
    GlobConfig.data.guest.username := '';
    GlobConfig.data.guest.password := '';
  end;

 if (Self.CHB_uLI_Run.Checked) then
   GlobConfig.data.uLI.path := Self.E_uLI_Path.Text
 else
   GlobConfig.data.uLI.path := '';
 GlobConfig.data.uLI.use  := Self.CHB_uLI_Login.Checked;
 F_Main.UpdateuLIIcon();

 BridgeClient.enabled := GlobConfig.data.uLI.use;

 if (Self.LB_Timer.ItemIndex > -1) then
   F_Main.T_Main.Interval       := StrToInt(Self.LB_Timer.Items.Strings[Self.LB_Timer.ItemIndex]);

 oldss := GlobConfig.data.symbolSet;
 case (Self.LB_Symbols.ItemIndex) of
  1: GlobConfig.data.symbolSet := TSymbolSetType.bigger;
 else
  GlobConfig.data.symbolSet := TSymbolSetType.normal;
 end;

 if (GlobConfig.data.panel_mouse = _MOUSE_PANEL) then
  begin
   F_Main.DXD_Main.Cursor := crNone;
  end else begin
   F_Main.DXD_Main.Cursor := crDefault;
  end;

 if (Assigned(PanelTCPClient.resusct)) then
  begin
   PanelTCPClient.Resusct.server_ip   := GlobConfig.data.server.host;
   PanelTCPClient.Resusct.server_port := GlobConfig.data.server.port;
  end;

 if (oldss <> GlobConfig.data.symbolSet) then
  begin
   try
     ss := TSymbolSet.Create(GlobConfig.data.symbolSet);
     ss2 := SymbolSet;
     SymbolSet := ss;
     Relief.UpdateSymbolSet();
     ss2.Free();
   except
     on E:Exception do
      begin
       GlobConfig.data.symbolSet := oldss;
       Application.MessageBox(PChar('Změna velikosti symbolů se nezdařila'+#13#10+E.ToString), 'Chyba', MB_OK OR MB_ICONWARNING);
      end;
   end;
  end;

 Screen.Cursor := crDefault;
 Self.Close();
end;

procedure TF_Settings.B_Panel_ProchClick(Sender: TObject);
var fn:string;
begin
 Self.OD_Panel.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Panel.Text));
 if (Self.OD_Panel.Execute(Self.Handle)) then
  begin
   if (Self.CHB_Panel_Rel.Checked) then
    fn := ExtractRelativePath(ExtractFilePath(Application.ExeName), Self.OD_Panel.FileName)
   else
    fn := Self.OD_Panel.FileName;

   Self.E_Panel.Text := fn;
  end;
end;

procedure TF_Settings.B_Proch1Click(Sender: TObject);
var fn:string;
begin
 case (Sender as TButton).Tag of
  1: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_Trat.Text));
  2: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_Error.Text));
  3: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_PS.Text));
  4: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_Pretizeni.Text));
  5: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_Zprava.Text));
  6: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_Privolavacka.Text));
  7: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_Timeout.Text));
  8: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_StaveniVyzva.Text));
  9: Self.OD_Snd.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Snd_NeniJC.Text));
 end;

 if (Self.OD_Snd.Execute(Self.Handle)) then
  begin
   if ((Sender as TButton).Tag < 8) then
    begin
     if (Self.CHB_Relative.Checked) then
      fn := ExtractRelativePath(ExtractFilePath(Application.ExeName), Self.OD_Snd.FileName)
     else
      fn := Self.OD_Snd.FileName;
    end else begin
     if (Self.CHB_Relative2.Checked) then
      fn := ExtractRelativePath(ExtractFilePath(Application.ExeName), Self.OD_Snd.FileName)
     else
      fn := Self.OD_Snd.FileName;
    end;

   case (Sender as TButton).Tag of
    1: Self.E_Snd_Trat.Text         := fn;
    2: Self.E_Snd_Error.Text        := fn;
    3: Self.E_Snd_PS.Text           := fn;
    4: Self.E_Snd_Pretizeni.Text    := fn;
    5: Self.E_Snd_Zprava.Text       := fn;
    6: Self.E_Snd_Privolavacka.Text := fn;
    7: Self.E_Snd_Timeout.Text      := fn;
    8: Self.E_Snd_StaveniVyzva.Text := fn;
    9: Self.E_Snd_NeniJC.Text       := fn;
   end;
  end;
end;

procedure TF_Settings.B_Proch_VysvClick(Sender: TObject);
var fn:string;
begin
 Self.OD_Vysv.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Vysv.Text));
 if (Self.OD_Vysv.Execute(Self.Handle)) then
  begin
   if (Self.CHB_Vysv_Rel.Checked) then
    fn := ExtractRelativePath(ExtractFilePath(Application.ExeName), Self.OD_Vysv.FileName)
   else
    fn := Self.OD_Vysv.FileName;

   Self.E_Vysv.Text := fn;
  end;
end;

procedure TF_Settings.B_Reg_ProchClick(Sender: TObject);
var fn:string;
begin
 Self.OD_Reg.InitialDir := ExtractFileDir(ExpandFileName(Self.E_Regulator.Text));
 if (Self.OD_Reg.Execute(Self.Handle)) then
  begin
   if (Self.CHB_Reg_Rel.Checked) then
    fn := ExtractRelativePath(ExtractFilePath(Application.ExeName), Self.OD_Reg.FileName)
   else
    fn := Self.OD_Reg.FileName;

   Self.E_Regulator.Text := fn;
  end;
end;

procedure TF_Settings.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_Settings.B_uLI_SearchClick(Sender: TObject);
var fn:string;
begin
 Self.OD_uLI.InitialDir := ExtractFileDir(ExpandFileName(Self.E_uLI_Path.Text));
 if (Self.OD_uLI.Execute(Self.Handle)) then
  begin
   if (Self.CHB_uLI_Rel.Checked) then
    fn := ExtractRelativePath(ExtractFilePath(Application.ExeName), Self.OD_uLI.FileName)
   else
    fn := Self.OD_uLI.FileName;

   Self.E_uLI_Path.Text := fn;
  end;
end;

procedure TF_Settings.CB_ORRightsChange(Sender: TObject);
var i:Integer;
begin
 for i := 0 to Self.LB_AutoAuthOR.Items.Count-1 do
   if (Self.LB_AutoAuthOR.Selected[i]) then
     GlobConfig.data.auth.ORs.AddOrSetValue(Self.LB_AutoAuthOR.Items[i], TORControlRights(Self.CB_ORRights.ItemIndex));
end;

procedure TF_Settings.CHB_Guest_EnableClick(Sender: TObject);
begin
 Self.E_Guest_Username.Enabled := Self.CHB_Guest_Enable.Checked;
 Self.E_Guest_Password.Enabled := Self.CHB_Guest_Enable.Checked;

 if (Self.CHB_Guest_Enable.Checked) then
  begin
   Self.E_Guest_Username.Text := GlobConfig.data.guest.username;
   if (GlobConfig.data.guest.allow) then
     Self.E_Guest_Password.Text := 'heslo'
   else
     Self.E_Guest_Password.Text := '';
  end else begin
   Self.E_Guest_Username.Text := '';
   Self.E_Guest_Password.Text := '';
  end;
end;

procedure TF_Settings.CHB_RememberAuthClick(Sender: TObject);
begin
 Self.E_username.Enabled := Self.CHB_RememberAuth.Checked;
 Self.E_Password.Enabled := Self.CHB_RememberAuth.Checked;
 Self.CHB_Forgot.Enabled := Self.CHB_RememberAuth.Checked;

 if (not Self.CHB_RememberAuth.Checked) then
  begin
   Self.E_username.Text := '';
   Self.E_Password.Text := '';
   Self.CHB_Forgot.Checked := false;
  end;
end;

procedure TF_Settings.CHB_ShowPasswordClick(Sender: TObject);
begin
 if (Self.CHB_ShowPassword.Checked) then
  Self.E_Password.PasswordChar := #0
 else
  Self.E_Password.PasswordChar := '*';
end;

procedure TF_Settings.CHB_uLI_RunClick(Sender: TObject);
begin
 Self.E_uLI_Path.Enabled   := Self.CHB_uLI_Run.Checked;
 Self.B_uLI_Search.Enabled := Self.CHB_uLI_Run.Checked;
 Self.CHB_uLI_Rel.Enabled  := Self.CHB_uLI_Run.Checked;
end;

procedure TF_Settings.E_Guest_PasswordChange(Sender: TObject);
begin
 Self.guestPasswdChanged := true;
end;

procedure TF_Settings.E_PasswordChange(Sender: TObject);
begin
 Self.passwdChanged := true;
 if (Self.E_Password.Text = '') then
  begin
   Self.CHB_ShowPassword.Enabled := true;
   Self.CHB_Forgot.Enabled       := true;
  end;
end;

procedure TF_Settings.E_usernameKeyPress(Sender: TObject; var Key: Char);
begin
 if ((Key = ';') or (Key = ',')) then Key := #0;
end;



procedure TF_Settings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Self.CHB_ShowPassword.Checked := false;
 Self.E_Password.PasswordChar  := '*';
end;

procedure TF_Settings.FormCreate(Sender: TObject);
begin
 Self.PC_Main.ActivePageIndex := 0;
end;

procedure TF_Settings.LB_AutoAuthORClick(Sender: TObject);
var rights, rights2:TORControlRights;
    i:Integer;
begin
 if (Self.LB_AutoAuthOR.SelCount = 0) then
  begin
   // 0 vybranych polozek
   Self.CB_ORRights.ItemIndex := -1;
   Self.CB_ORRights.Enabled   := false;
  end else begin
   Self.CB_ORRights.Enabled := true;
   if (Self.LB_AutoAuthOR.SelCount = 1) then
    begin
     // 1 vybrana polozka
     if (GlobConfig.data.auth.ORs.TryGetValue(Self.LB_AutoAuthOR.Items[Self.LB_AutoAuthOR.ItemIndex], rights)) then
      Self.CB_ORRights.ItemIndex := Integer(rights)
     else
      Self.CB_ORRights.ItemIndex := -1;
    end else begin
     // vic vybranych polozek -> pokud jsou opravenni stejna, vyplnime, jinak -1

     for i := 0 to Self.LB_AutoAuthOR.Items.Count-1 do
       if (Self.LB_AutoAuthOR.Selected[i]) then
         GlobConfig.data.auth.ORs.TryGetValue(Self.LB_AutoAuthOR.Items[i], rights);

     for i := 0 to Self.LB_AutoAuthOR.Items.Count-1 do
       if (Self.LB_AutoAuthOR.Selected[i]) then
        begin
         GlobConfig.data.auth.ORs.TryGetValue(Self.LB_AutoAuthOR.Items[i], rights2);
         if (rights2 <> rights) then
          begin
           Self.CB_ORRights.ItemIndex := -1;
           Exit();
          end;
        end;

     Self.CB_ORRights.ItemHeight := Integer(rights);
    end;// else SelCount > 1
  end;//else Selected = nil
end;

procedure TF_Settings.LB_SymbolsDblClick(Sender: TObject);
begin
 if (Self.LB_Symbols.ItemIndex > -1) then Self.B_ApplyClick(B_Apply); 
end;

procedure TF_Settings.LB_TimerDblClick(Sender: TObject);
begin
 if (Self.LB_Timer.ItemIndex > -1) then Self.B_ApplyClick(B_Apply);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Settings.OpenForm();
var data:TGlobConfigData;
    i:Integer;
begin
 data := GlobConfig.data;

 Self.E_Panel.Text          := data.panel_fn;
 Self.E_Vysv.Text           := data.vysv_fn;
 Self.RG_Mouse.ItemIndex    := data.panel_mouse;

 Self.CHB_Resuscitation.Checked  := data.resuscitation;

 Self.CHB_Jerry_username.Checked  := GlobConfig.data.reg.reg_user;
 Self.E_Regulator.Text            := GlobConfig.data.reg.reg_fn;

 Self.E_Host.Text             := data.server.host;
 Self.SE_Port.Value           := data.server.port;
 Self.CHB_Autoconnect.Checked := data.server.autoconnect;

 Self.CHB_RememberAuth.Checked := data.auth.autoauth;
 Self.CHB_RememberAuthClick(Self.CHB_RememberAuth);
 Self.E_username.Text          := data.auth.username;
 if (data.auth.password = '') then
   Self.E_Password.Text        := ''
 else
   Self.E_Password.Text        := 'heslo';

 Self.CHB_Forgot.Checked       := ((data.auth.forgot) and (data.auth.autoauth));
 if (Self.CHB_Forgot.Checked) then Self.CHB_Forgot.Enabled := false;
 Self.CHB_ShowPassword.Enabled := (data.auth.password = '');
 Self.TB_Remeber.Position      := GlobConfig.data.auth.auth_default_level;
 Self.TB_RemeberChange(Self.TB_Remeber);

 Self.CHB_IPC_Send.Checked    := data.auth.ipc_send;
 Self.CHB_IPC_Receive.Checked := data.auth.ipc_receive;

 Self.E_Snd_Trat.Text         := data.sounds.sndTratSouhlas;
 Self.E_Snd_Error.Text        := data.sounds.sndChyba;
 Self.E_Snd_PS.Text           := data.sounds.sndRizikovaFce;
 Self.E_Snd_Pretizeni.Text    := data.sounds.sndPretizeni;
 Self.E_Snd_Zprava.Text       := data.sounds.sndPrichoziZprava;
 Self.E_Snd_Privolavacka.Text := data.sounds.sndPrivolavacka;
 Self.E_Snd_Timeout.Text      := data.sounds.sndTimeout;
 Self.E_Snd_StaveniVyzva.Text := data.sounds.sndStaveniVyzva;
 Self.E_Snd_NeniJC.Text       := data.sounds.sndNeniJC;

 Self.CHB_Guest_Enable.Checked := data.guest.allow;
 Self.CHB_Guest_EnableClick(Self.CHB_Guest_Enable);

 Self.E_uLI_Path.Text       := data.uLI.path;
 Self.CHB_uLI_Run.Checked   := (data.uLI.path <> '');
 Self.CHB_uLI_Run.OnClick(Self);
 Self.CHB_uLI_Login.Checked := data.uLI.use;

 Self.CB_ORRights.Enabled := false;
 Self.LB_AutoAuthOR.Clear();
 for i := 0 to Relief.ORs.Count-1 do
   Self.LB_AutoAuthOR.Items.Add(Relief.ORs[i].id);

 Self.LB_Timer.ItemIndex := -1;
 for i := 0 to Self.LB_Timer.Items.Count-1 do
  if (Self.LB_Timer.Items.Strings[i] = IntToStr(F_Main.T_Main.Interval)) then
   Self.LB_Timer.ItemIndex := i;

 case (data.symbolSet) of
  bigger: Self.LB_Symbols.ItemIndex := 1;
 else
  Self.LB_Symbols.ItemIndex := 0;
 end;

 Self.passwdChanged := false;
 Self.guestPasswdChanged := false;
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Settings.TB_RemeberChange(Sender: TObject);
begin
 Self.ST_Rem1.Caption := _AUTH_DESC[Self.TB_Remeber.Position].short;
 Self.ST_Rem2.Caption := _AUTH_DESC[Self.TB_Remeber.Position].save;
 Self.ST_Rem3.Caption := _AUTH_DESC[Self.TB_Remeber.Position].use;
 Self.ST_Rem4.Caption := _AUTH_DESC[Self.TB_Remeber.Position].save_hint;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
