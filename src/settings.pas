unit settings;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, Spin, RPConst;

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
    Label10: TLabel;
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
    GroupBox1: TGroupBox;
    Label16: TLabel;
    LB_AutoAuthOR: TListBox;
    CB_ORRights: TComboBox;
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
  private
    { Private declarations }
  public
    procedure OpenForm();
  end;

var
  F_Settings: TF_Settings;

implementation

uses GlobalConfig, Symbols, Main, Resuscitation;

////////////////////////////////////////////////////////////////////////////////

{$R *.dfm}

procedure TF_Settings.B_ApplyClick(Sender: TObject);
begin
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
 if (GlobConfig.data.auth.autoauth) then
  begin
   GlobConfig.data.auth.username           := Self.E_username.Text;
   GlobConfig.data.auth.password           := Self.E_Password.Text;
  end else begin
   GlobConfig.data.auth.username           := '';
   GlobConfig.data.auth.password           := '';
  end;
 GlobConfig.data.auth.forgot               := Self.CHB_Forgot.Checked;

 GlobConfig.data.sounds.sndTratSouhlas     := Self.E_Snd_Trat.Text;
 GlobConfig.data.sounds.sndChyba           := Self.E_Snd_Error.Text;
 GlobConfig.data.sounds.sndRizikovaFce     := Self.E_Snd_PS.Text;
 GlobConfig.data.sounds.sndPretizeni       := Self.E_Snd_Pretizeni.Text;
 GlobConfig.data.sounds.sndPrichoziZprava  := Self.E_Snd_Zprava.Text;

 if (Self.LB_Timer.ItemIndex > -1) then
   F_Main.T_Main.Interval       := StrToInt(Self.LB_Timer.Items.Strings[Self.LB_Timer.ItemIndex]);

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

 if (Assigned(Resusct)) then
  begin
   Resusct.server_ip   := GlobConfig.data.server.host;
   Resusct.server_port := GlobConfig.data.server.port;
  end;

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
 end;

 if (Self.OD_Snd.Execute(Self.Handle)) then
  begin
   if (Self.CHB_Relative.Checked) then
    fn := ExtractRelativePath(ExtractFilePath(Application.ExeName), Self.OD_Snd.FileName)
   else
    fn := Self.OD_Snd.FileName;

   case (Sender as TButton).Tag of
    1: Self.E_Snd_Trat.Text       := fn;
    2: Self.E_Snd_Error.Text      := fn;
    3: Self.E_Snd_PS.Text         := fn;
    4: Self.E_Snd_Pretizeni.Text  := fn;
    5: Self.E_Snd_Zprava.Text     := fn;
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
end;//procedure

procedure TF_Settings.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_Settings.CB_ORRightsChange(Sender: TObject);
begin
 if (Self.LB_AutoAuthOR.ItemIndex < 0) then Exit();
 GlobConfig.data.auth.ORs.AddOrSetValue(Self.LB_AutoAuthOR.Items.Strings[Self.LB_AutoAuthOR.ItemIndex], TORControlRights(Self.CB_ORRights.ItemIndex));
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

procedure TF_Settings.E_usernameKeyPress(Sender: TObject; var Key: Char);
begin
 if ((Key = ';') or (Key = ',')) then Key := #0;
end;

//procedure

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
var rights:TORControlRights;
begin
 if (Self.LB_AutoAuthOR.ItemIndex > -1) then
  begin
   Self.CB_ORRights.Enabled := true;
   if (GlobConfig.data.auth.ORs.TryGetValue(Self.LB_AutoAuthOR.Items.Strings[Self.LB_AutoAuthOR.ItemIndex], rights)) then
     Self.CB_ORRights.ItemIndex := Integer(rights)
   else
     Self.CB_ORRights.ItemIndex := 0;
  end else begin
   Self.CB_ORRights.Enabled := false;
  end;
end;//procedure

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
 Self.E_Password.Text          := data.auth.password;
 Self.CHB_Forgot.Checked       := ((data.auth.forgot) and (data.auth.autoauth));
 Self.CHB_ShowPassword.Enabled := not CHB_Forgot.Checked;

 Self.E_Snd_Trat.Text       := data.sounds.sndTratSouhlas;
 Self.E_Snd_Error.Text      := data.sounds.sndChyba;
 Self.E_Snd_PS.Text         := data.sounds.sndRizikovaFce;
 Self.E_Snd_Pretizeni.Text  := data.sounds.sndPretizeni;
 Self.E_Snd_Zprava.Text     := data.sounds.sndPrichoziZprava;

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

 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

end.//unit
