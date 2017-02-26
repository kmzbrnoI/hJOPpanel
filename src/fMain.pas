unit fMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DXDraws, ComCtrls, ExtCtrls, ImgList, Panel, AppEvnts, ActnList,
  Buttons, StdCtrls, GlobalConfig, StrUtils, Resuscitation, ShellApi, RPConst;

const
  _open_file_errors: array [1..3] of string =
    ('Soubor panelu neexistuje',
     'Verze souboru panelu není podporována',
     'Soubor panelu se nepodaøilo otevøít');

  _MUTE_MIN = 3;    // ztisit zvuky je mozne maximalne na 3 minuty, pak se znovu zapnou
  _ULIAUTH_TIMEOUT_SEC = 5;

type
  TF_Main = class(TForm)
    P_Header: TPanel;
    SB_Main: TStatusBar;
    IL_Ostatni: TImageList;
    T_Main: TTimer;
    AE_Main: TApplicationEvents;
    P_Connection: TPanel;
    SB_SystemStart: TSpeedButton;
    SB_SystemStop: TSpeedButton;
    AL_Main: TActionList;
    A_Connect: TAction;
    A_Disconnect: TAction;
    IL_Menu: TImageList;
    P_Settings: TPanel;
    SB_Mute: TSpeedButton;
    SB_Settings: TSpeedButton;
    P_Time: TPanel;
    P_Date: TPanel;
    A_Print: TAction;
    SD_Image: TSaveDialog;
    P_Time_modelovy: TPanel;
    P_Zrychleni: TPanel;
    P_DCC: TPanel;
    SB_DCC_Go: TSpeedButton;
    SB_DCC_Stop: TSpeedButton;
    Panel2: TPanel;
    SB_Soupravy: TSpeedButton;
    A_Settings: TAction;
    A_Mute: TAction;
    P_Login: TPanel;
    L_Login: TLabel;
    A_ReAuth: TAction;
    SB_Logout: TSpeedButton;
    SB_PrintScreen: TSpeedButton;
    SB_uLIdaemon: TSpeedButton;
    procedure FormDestroy(Sender: TObject);
    procedure T_MainTimer(Sender: TObject);
    procedure AE_MainMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure A_ConnectExecute(Sender: TObject);
    procedure A_DisconnectExecute(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure A_PrintExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SB_DCC_GoClick(Sender: TObject);
    procedure SB_DCC_StopClick(Sender: TObject);
    procedure SB_SoupravyClick(Sender: TObject);
    procedure SB_MuteClick(Sender: TObject);
    procedure SB_SettingsClick(Sender: TObject);
    procedure A_SettingsExecute(Sender: TObject);
    procedure A_MuteExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure A_ReAuthExecute(Sender: TObject);
    procedure SB_uLIdaemonClick(Sender: TObject);
  private

   mute_time:TDateTime;
   uliauth_time:TDateTime;
   uliauth_enabled:boolean;

    procedure OnReliefMove(Sender:TObject; Position:TPoint);
    procedure ShowAboutDialog();
    procedure RunuLIDaemon();
    procedure OnuLIAuthStatusChanged(Sender:TObject);
    procedure uLILoginFilled(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);

  public
    DXD_Main:TDXDraw;
    close_app: boolean;

     procedure OnReliefLoginChange(Sender:TObject; user:string);

     procedure Init(const config_fn:string = TGlobConfig._DEFAULT_FN);          // konfiguracni soubor se cte z argumentu programu
     procedure SetPanelSize(width,height:Integer);
     procedure UpdateuLIIcon();
     procedure uLIAuthUpdate();
  end;

var
  F_Main: TF_Main;
  Relief:TRelief;

implementation

uses Symbols, Debug, TCPCLientPanel, BottomErrors, Verze, Sounds, fAuth,
  fSettings, fSplash, ModelovyCas, DCC_Icons, fSoupravy, uLIclient;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

// application events message
procedure TF_Main.AE_MainMessage(var Msg: tagMSG; var Handled: Boolean);
begin
 if (msg.message = WM_KeyDown) then
  begin
   case  msg.wParam of
     VK_F4 : F_Debug.Show();
     VK_F1 : Self.ShowAboutDialog();
   end;//case
  end else if (msg.message = WM_MOUSELEAVE) then begin
    if (msg.hwnd = Self.DXD_Main.Handle) then
     begin
      Relief.HideCursor();
      Self.SB_Main.Panels.Items[0].Text := '---;---';
     end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.A_ConnectExecute(Sender: TObject);
begin
 Screen.Cursor := crHourGlass;

 try
  PanelTCPClient.Connect(GlobConfig.data.server.host, GlobConfig.data.server.port);
 except
  on E : Exception do
    Application.MessageBox(PChar('Pøipojení se nezdaøilo'+#13#10+E.Message), 'Nepøipojeno', MB_OK OR MB_ICONWARNING);
 end;

 Screen.Cursor := crDefault;
end;

procedure TF_Main.A_DisconnectExecute(Sender: TObject);
begin
 Screen.Cursor := crHourGlass;
 PanelTCPClient.Disconnect();
 Screen.Cursor := crDefault;
end;

procedure TF_Main.A_MuteExecute(Sender: TObject);
begin
 Self.SB_MuteClick(Self.SB_Mute);
end;

procedure TF_Main.A_PrintExecute(Sender: TObject);
var fn:string;
begin
 Self.SD_Image.InitialDir := ExtractFilePath(Application.ExeName);
 if (Self.SD_Image.Execute(Self.Handle)) then
  begin
   fn := Self.SD_Image.FileName;

   case (Self.SD_Image.FilterIndex) of
    1: if (RightStr(fn, 4) <> '.png') then fn := fn + '.png';
    2: if (RightStr(fn, 4) <> '.bmp') then fn := fn + '.bmp';
   end;

   if (FileExists(fn)) then
     if (Application.MessageBox(PChar('Soubor ' +fn + ' již existuje, pøejete si ho nahradit?'),
         'Nahradit soubor?', MB_YESNO OR MB_ICONQUESTION) = mrNo) then
       Exit();

   Screen.Cursor := crHourGlass;
   Relief.Image(fn);
   Screen.Cursor := crDefault;
  end;
end;

procedure TF_Main.A_ReAuthExecute(Sender: TObject);
begin
 if (Assigned(Relief)) then Relief.ReAuthorize();
end;

procedure TF_Main.A_SettingsExecute(Sender: TObject);
begin
 Self.SB_SettingsClick(Self.SB_Settings);
end;

procedure TF_Main.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 if ((PanelTCPClient.status <> TPanelConnectionStatus.closed) and (not Self.close_app)) then
  begin
   Self.close_app := true;  // informujeme OnDisconnect, ze ma zavrit okno
   PanelTCPClient.Disconnect();
   CanClose := false;       // okno zatim nezavirame, zavre se az pri OnDisconnect
  end;
end;

procedure TF_Main.FormCreate(Sender: TObject);
begin
 Self.close_app := false;
 Self.uliauth_enabled := false;

 BridgeClient.OnAuthStatushanged := Self.OnuLIAuthStatusChanged;

 ModCas.Reset();
 DCC := TDCC.Create();
end;

procedure TF_Main.FormDestroy(Sender: TObject);
var data:TGlobConfigData;
begin
 BridgeClient.OnAuthStatushanged := nil;

 Screen.Cursor := crHourGlass;

 if (Assigned(GlobConfig)) then
  begin
   data := GlobConfig.data;
   data.frmPos := Point(Self.Left, Self.Top);
   GlobConfig.data := data;
   GlobConfig.SaveFile();
  end;

 if (Assigned(Relief)) then
  FreeAndNil(Relief);
 if (Assigned(Self.DXD_Main)) then
  FreeAndNil(Self.DXD_Main);
end;

procedure TF_Main.FormResize(Sender: TObject);
begin
 Self.P_Zrychleni.Left     := Self.P_Header.Width - Self.P_Zrychleni.Width - 5;
 Self.P_Time_modelovy.Left := Self.P_Zrychleni.Left - Self.P_Time_modelovy.Width - 5;

 Self.P_Time.Left := Self.P_Time_modelovy.Left - Self.P_Time.Width - 5;
 Self.P_Date.Left := Self.P_Time.Left - Self.P_Date.Width - 5;

 Self.P_Login.Visible := ((Self.P_Login.Left+Self.P_Login.Width) < Self.P_Time_modelovy.Left);
 Self.P_Date.Visible := (Self.P_Date.Left > (Self.P_Login.Left+Self.P_Login.Width));
 Self.P_Time.Visible := (Self.P_Time.Left > (Self.P_Login.Left+Self.P_Login.Width));

 Self.P_Settings.BringToFront();
 Self.P_Connection.BringToFront();
end;

procedure TF_Main.Init(const config_fn:string);
var return:Integer;
begin
 F_splash.AddStav('Naèítám konfiguraci...');

 GlobConfig.LoadFile(config_fn);

 Self.Caption := ChangeFileExt(ExtractFileName(ExpandFileName(GlobConfig.data.panel_fn)), '')+' - hJOPpanel - v'+NactiVerzi(Application.ExeName)+' (build '+GetLastBuildDate+')';

 F_splash.AddStav('Vytváøím plátno...');

 try
   Self.DXD_main := TDXDraw.Create(Self);
   Self.DXD_main.Parent  := Self;
   Self.DXD_main.Align   := alClient;
   Self.DXD_Main.Options := [doAllowReboot, doSelectDriver, doHardware];
   Self.DXD_main.Initialize;
 except
   on E : Exception do
    begin
     Application.MessageBox(PChar('Nepodaøilo se inicializovat plátno, aplikace bude ukonèena'+#13#10+E.Message), 'Chyba', MB_OK OR MB_ICONERROR);
     Self.Close();
     Exit();
    end;
 end;

 if (GlobConfig.data.panel_mouse = _MOUSE_PANEL) then
  begin
   F_Main.DXD_Main.Cursor := crNone;
  end else begin
   F_Main.DXD_Main.Cursor := crDefault;
  end;

 F_splash.AddStav('Naèítám symboly...');

 try
   SymbolSet := TSymbolSet.Create(GlobConfig.data.symbolSet);
 except
   on e:Exception do
    begin
     Application.MessageBox(PChar('Nepodaøilo se naèíst symboly, aplikace bude ukonèena'+#13#10+e.Message), 'Chyba', MB_OK OR MB_ICONERROR);
     Self.Close();
     Exit();
    end;
 end;

 F_splash.AddStav('Vytváøím panel...');

 Relief := TRelief.Create(Self);
 Relief.OnMove := Self.OnReliefMove;
 Relief.OnLoginUserChange := Self.OnReliefLoginChange;
 return := Relief.Initialize(Self.DXD_Main, GlobConfig.data.panel_fn, GlobConfig.data.vysv_fn);

 if (return <> 0) then
  begin
   Application.MessageBox(PChar('Pøi inicializaci reliéfu došlo k chybì:'+#13#10+_open_file_errors[return]), 'Chyba', MB_OK OR MB_ICONWARNING);
   Self.DXD_Main.Enabled := false;
   Self.P_Connection.Enabled := false;
  end;

 if ((GlobConfig.data.frmPos.X >= 0) and (GlobConfig.data.frmPos.Y >= 0) and
   (GlobConfig.data.frmPos.X+100 < Screen.Width) and (GlobConfig.data.frmPos.Y+100 < Screen.Height)) then
  begin
   Self.Left := GlobConfig.data.frmPos.X;
   Self.Top := GlobConfig.data.frmPos.Y;
  end;

 // do prvniho pripojeni jsou tu default hodnoty
 BridgeClient.toLogin.server := GlobConfig.data.server.host;
 BridgeClient.toLogin.port := GlobConfig.data.server.port;

 if (GlobConfig.data.uLI.path <> '') then
  begin
   F_splash.AddStav('Spouštím uLI-daemon...');
   Self.RunuLIDaemon();
  end;

 if (GlobConfig.data.uLI.use) then
  begin
   F_splash.AddStav('Aktivuji spojení s uLI-daemon...');
   BridgeClient.enabled := true;
  end;

 F_splash.AddStav('Hotovo');

 Self.UpdateuLIIcon();
 F_splash.Close();
 Self.Show();

 if (GlobConfig.data.server.autoconnect) then
  Self.A_ConnectExecute(Self);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.SB_DCC_GoClick(Sender: TObject);
begin
 DCC.Go();
end;

procedure TF_Main.SB_DCC_StopClick(Sender: TObject);
begin
 DCC.Stop();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.SB_MuteClick(Sender: TObject);
begin
 Self.SB_Mute.AllowAllUp := not Self.SB_Mute.AllowAllUp;
 Self.SB_Mute.Down := not Self.SB_Mute.Down;

 if (Self.SB_Mute.Down) then
 begin
  Self.mute_time := Now;
  SoundsPlay.muted := true
 end else
  SoundsPlay.muted := false;
end;

procedure TF_Main.SB_SettingsClick(Sender: TObject);
begin
 F_Settings.OpenForm();
end;

procedure TF_Main.SB_SoupravyClick(Sender: TObject);
begin
 F_SprList.Show();
end;

procedure TF_Main.SB_uLIdaemonClick(Sender: TObject);
begin
 BridgeClient.toLogin.username := GlobConfig.data.auth.username;
 BridgeClient.toLogin.password := GlobConfig.data.auth.password;

 Self.uliauth_time := Now + EncodeTime(0, 0, _ULIAUTH_TIMEOUT_SEC, 0);
 Self.uliauth_enabled := true;

 if (not BridgeClient.opened) then
   Self.RunuLIDaemon()
 else begin
   if (GlobConfig.data.auth.password = '') then
     F_Auth.OpenForm('uLI-daemon vyžaduje autentizaci', Self.uLILoginFilled, nil, false)
   else
     BridgeClient.Auth();
 end;

 Self.UpdateuLIIcon();
end;

procedure TF_Main.SetPanelSize(width,height:Integer);
begin
 Self.ClientWidth  := width;
 Self.ClientHeight := height + Self.P_Header.Height + Self.SB_Main.Height;
end;

procedure TF_Main.T_MainTimer(Sender: TObject);
begin
 if (Assigned(Relief)) then Relief.Show();

 Self.P_Time.Caption := FormatDateTime('hh:mm:ss', Now);
 Self.P_Date.Caption := FormatDateTime('d.m.yyyy', Now);

 PanelTCPClient.Update();
 BridgeClient.Update();
 Self.uLIAuthUpdate();

 if ((SoundsPlay.muted) and (Self.mute_time + EncodeTime(0, _MUTE_MIN, 0, 0) <= Now)) then
  begin
   Self.SB_Mute.AllowAllUp := not Self.SB_Mute.AllowAllUp;
   Self.SB_Mute.Down := not Self.SB_Mute.Down;
   SoundsPlay.muted := false;
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnReliefMove(Sender:TObject;Position:TPoint);
begin
 Self.SB_Main.Panels.Items[0].Text := Format('%.3d;%.3d', [Position.X, Position.Y]);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.ShowAboutDialog();
begin
 Application.MessageBox(PChar('hJOPpanel v'+NactiVerzi(Application.ExeName)+#13#10+
  'build '+GetLastBuildDate()+' '+GetLastBuildTime()+#13#10+
  'Vytvoøil Jan Horáèek (c) 2014-2016 pro KMŽ Brno I'), 'Info', MB_OK OR MB_ICONINFORMATION);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnReliefLoginChange(Sender:TObject; user:string);
begin
 Self.L_Login.Caption := user;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.RunuLIDaemon();
var f:string;
    return:Cardinal;
begin
 f := ExpandFileName(GlobConfig.data.uLI.path);
 return := ShellExecute(Self.Handle, 'open', PChar(f), '', PChar(ExtractFilePath(GlobConfig.data.uLI.path)), SW_SHOWNOACTIVATE);
 if (return < 32) then
   Application.MessageBox(PChar('Nelze spustit uLI-daemon, chyba'+IntToStr(return)+#13#10+f), 'uLI-daemon', MB_OK OR MB_ICONWARNING);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.UpdateuLIIcon();
begin
 Self.SB_uLIdaemon.Enabled := (GlobConfig.data.uLI.path <> '') and
    (BridgeClient.authStatus <> TuLIAuthStatus.yes) and (not Self.uliauth_enabled);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.uLIAuthUpdate();
begin
 if (not Self.uliauth_enabled) then Exit();

 if (Now > Self.uliauth_time) then
  begin
   BridgeClient.toLogin.username := '';
   BridgeClient.toLogin.password := '';
   Self.uliauth_enabled := false;
   Self.UpdateuLIIcon();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnuLIAuthStatusChanged(Sender:TObject);
begin
 if (BridgeClient.authStatus = TuLIAuthStatus.yes) then
   Self.uliauth_enabled := false;

 if ((BridgeClient.authStatus = TuLIAuthStatus.no) and (Self.uliauth_enabled)) then
  begin
   Self.uliauth_enabled := false;
   if (GlobConfig.data.auth.password = '') then
     F_Auth.OpenForm('uLI-daemon vyžaduje autentizaci', Self.uLILoginFilled, nil, false);
  end;

 F_Main.UpdateuLIIcon();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.uLILoginFilled(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);
begin
 if (BridgeClient.toLogin.password = '') then
   F_Auth.AuthError(0, 'Je tøeba povolit autorizaci uLI-daemon!')
 else begin
   F_Auth.AuthOK(0);
   BridgeClient.Auth();
 end;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit

