﻿unit fMain;

{
  Main window.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DXDraws, ComCtrls, ExtCtrls, ImgList, Panel, AppEvnts, ActnList,
  Buttons, StdCtrls, GlobalConfig, StrUtils, ShellApi, RPConst, System.Actions,
  System.ImageList, Types, Generics.Collections;

const
  _MUTE_MIN = 3; // maximum mute time of sounds
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
    P_Settings: TPanel;
    SB_Mute: TSpeedButton;
    SB_Settings: TSpeedButton;
    P_Time: TPanel;
    P_Date: TPanel;
    A_Print: TAction;
    SD_Image: TSaveDialog;
    P_DCC: TPanel;
    SB_DCC_Go: TSpeedButton;
    SB_DCC_Stop: TSpeedButton;
    P_Other: TPanel;
    SB_Soupravy: TSpeedButton;
    A_Settings: TAction;
    A_Mute: TAction;
    P_Login: TPanel;
    L_Login: TLabel;
    A_ReAuth: TAction;
    SB_Logout: TSpeedButton;
    SB_PrintScreen: TSpeedButton;
    SB_uLIdaemon: TSpeedButton;
    P_Time_modelovy: TPanel;
    P_Zrychleni: TPanel;
    SB_Details: TSpeedButton;
    P_Form: TPanel;
    SB_HideStatusBar: TSpeedButton;
    SB_FullScreen: TSpeedButton;
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
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SB_DetailsClick(Sender: TObject);
    procedure SB_HideStatusBarClick(Sender: TObject);
    procedure SB_FullScreenClick(Sender: TObject);
  private

    mute_time: TDateTime;
    uliauth_time: TDateTime;
    uliauth_enabled: Boolean;

    procedure OnReliefMove(Sender: TObject; Position: TPoint);
    procedure ShowAboutDialog();
    procedure RunuLIDaemon();
    procedure OnuLIAuthStatusChanged(Sender: TObject);
    procedure uLILoginFilled(Sender: TObject; username: string; password: string; ors: TList<Integer>; guest: Boolean);
    procedure UpdateFormConstraints();

  protected
    procedure WndProc(var Message: TMessage); override;

  public
    DXD_Main: TDXDraw;
    close_app: Boolean;

    procedure OnReliefLoginChange(Sender: TObject; user: string);

    procedure Init(config_fn: string = TGlobConfig._DEFAULT_FN);
    // configuration file path = 1st program argument
    procedure SetPanelSize(width, height: Integer);
    procedure UpdateuLIIcon();
    procedure uLIAuthUpdate();

    procedure OnModTimeChanged();
    procedure CheckTimeSpeedWidth();
    function LargeSSFitsScreen(): Boolean;
  end;

var
  F_Main: TF_Main;
  Relief: TRelief;

implementation

uses Symbols, fDebug, TCPCLientPanel, BottomErrors, Verze, Sounds, fAuth,
  fSettings, fSplash, ModelovyCas, DCC_Icons, fSoupravy, uLIclient,
  InterProcessCom, JclAppInst, fPotvrSekv;

{$R *.dfm}
/// /////////////////////////////////////////////////////////////////////////////

// application events message
procedure TF_Main.AE_MainMessage(var Msg: tagMSG; var Handled: Boolean);
begin
  if (Msg.Message = WM_KeyDown) then
  begin
    if (F_PotvrSekv.running) then
      F_PotvrSekv.OnKeyUp(Msg.wParam, Handled);
    if (Handled) then
      Exit();

    case Msg.wParam of
      VK_F4:
        F_Debug.Show();
      VK_F3:
        Self.ShowAboutDialog();
      VK_F11: begin
        Self.SB_FullScreen.Down := not Self.SB_FullScreen.Down;
        Self.SB_FullScreenClick(Self.SB_FullScreen);
      end;
    end; // case
  end else if (Msg.Message = WM_MOUSELEAVE) then
  begin
    if (Msg.hwnd = Self.DXD_Main.Handle) then
    begin
      Relief.HideCursor();
      Self.SB_Main.Panels.Items[0].Text := '---;---';
    end;
  end;

  if (Msg.hwnd = 0) and (Msg.Message = JclAppInstances.MessageID) then
  begin
    case Msg.wParam of
      AI_INSTANCECREATED, AI_INSTANCEDESTROYED:
        if ((Assigned(F_Auth)) and (F_Auth.Showing)) then
          F_Auth.UpdateIPCcheckbox();
    end;
    Handled := True;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.A_ConnectExecute(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;

  try
    PanelTCPClient.Connect(GlobConfig.data.server.host, GlobConfig.data.server.port);
  except
    on E: Exception do
      Application.MessageBox(PChar('Připojení se nezdařilo' + #13#10 + E.Message), 'Nepřipojeno',
        MB_OK OR MB_ICONWARNING);
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
begin
  Self.SD_Image.InitialDir := ExtractFilePath(Application.ExeName);
  if (Self.SD_Image.Execute(Self.Handle)) then
  begin
    var fn := Self.SD_Image.FileName;

    case (Self.SD_Image.FilterIndex) of
      1:
        if (RightStr(fn, 4) <> '.png') then
          fn := fn + '.png';
      2:
        if (RightStr(fn, 4) <> '.bmp') then
          fn := fn + '.bmp';
    end;

    if (FileExists(fn)) then
      if (Application.MessageBox(PChar('Soubor ' + fn + ' již existuje, přejete si ho nahradit?'), 'Nahradit soubor?',
        MB_YESNO OR MB_ICONQUESTION) = mrNo) then
        Exit();

    Screen.Cursor := crHourGlass;
    Relief.Image(fn);
    Screen.Cursor := crDefault;
  end;
end;

procedure TF_Main.A_ReAuthExecute(Sender: TObject);
begin
  if (Assigned(Relief)) then
    Relief.ReAuthorize();
end;

procedure TF_Main.A_SettingsExecute(Sender: TObject);
begin
  Self.SB_SettingsClick(Self.SB_Settings);
end;

procedure TF_Main.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Self.T_Main.Enabled := false;
end;

procedure TF_Main.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if ((PanelTCPClient.status <> TPanelConnectionStatus.closed) and (not Self.close_app)) then
  begin
    Self.close_app := True; // OnDisconnect will close application
    PanelTCPClient.Disconnect();
    CanClose := false; // not closing form yet
  end;
end;

procedure TF_Main.FormCreate(Sender: TObject);
begin
  Self.DXD_Main := nil;
  Self.close_app := false;
  Self.uliauth_enabled := false;

  BridgeClient.OnAuthStatushanged := Self.OnuLIAuthStatusChanged;

  ModelTime.Reset();
  DCC := TDCC.Create();

  JclAppInstances.CheckInstance(0);
end;

procedure TF_Main.FormDestroy(Sender: TObject);
begin
  BridgeClient.OnAuthStatushanged := nil;
  Screen.Cursor := crHourGlass;

  if (Assigned(GlobConfig)) then
  begin
    GlobConfig.data.forms.fMainFullScreen := (Self.BorderStyle = TFormBorderStyle.bsNone);
    GlobConfig.data.forms.fMainShowSB := Self.SB_Main.Visible;
    GlobConfig.data.forms.fMainMaximized := (Self.WindowState = TWindowState.wsMaximized);
    GlobConfig.data.forms.fMainPos := Point(Self.Left, Self.Top);

    try
      GlobConfig.SaveFile();
    except
      on E: Exception do
        Application.MessageBox(PChar('Nepodařilo se uložit konfigurační soubor:' + #13#10 + E.Message), 'Chyba',
          MB_OK OR MB_ICONWARNING);
    end;
  end;

  if (Assigned(Relief)) then
    FreeAndNil(Relief);
  if (Assigned(Self.DXD_Main)) then
    FreeAndNil(Self.DXD_Main);
end;

procedure TF_Main.FormResize(Sender: TObject);
begin
  Self.P_Time_modelovy.Visible := ModelTime.used;
  Self.P_Zrychleni.Visible := ModelTime.used;

  if (ModelTime.used) then
  begin
    Self.P_Zrychleni.Left := Self.P_Header.width - Self.P_Zrychleni.width - 5;
    Self.P_Time_modelovy.Left := Self.P_Zrychleni.Left - Self.P_Time_modelovy.width - 5;
    Self.P_Time.Left := Self.P_Time_modelovy.Left - Self.P_Time.width - 5;
  end else begin
    Self.P_Time.Left := Self.P_Header.width - Self.P_Time.width - 5;
  end;

  Self.P_Date.Left := Self.P_Time.Left - Self.P_Date.width - 5;

  Self.P_Login.Visible := ((Self.P_Login.Left + Self.P_Login.width) < Self.P_Time_modelovy.Left);
  Self.P_Date.Visible := (Self.P_Date.Left > (Self.P_Login.Left + Self.P_Login.width));
  Self.P_Time.Visible := (Self.P_Time.Left > (Self.P_Login.Left + Self.P_Login.width));

  if (Assigned(Self.DXD_Main)) then
  begin
    var heightForPanel: Integer := Self.ClientHeight-Self.P_Header.Height;
    if (Self.SB_Main.Visible) then
      heightForPanel := heightForPanel - Self.SB_Main.Height;
    Self.DXD_Main.Left := (Self.ClientWidth div 2) - (Self.DXD_Main.Width div 2);
    Self.DXD_Main.Top := (heightForPanel div 2) - (Self.DXD_Main.Height div 2) + Self.P_Header.Height;
  end;

  Self.P_Settings.BringToFront();
  Self.P_Connection.BringToFront();
end;

procedure TF_Main.Init(config_fn: string);
begin
  var paramOpnl: string := '';
  F_splash.ShowState('Načítám konfiguraci...');

  if (config_fn.EndsWith('.opnl')) then
  begin
    paramOpnl := config_fn;
    config_fn := ExtractFilePath(Application.ExeName) + '\' + TGlobConfig._DEFAULT_FN;
  end;

  try
    GlobConfig.LoadFile(config_fn);
  except
    on E: Exception do
      Application.MessageBox(PChar('Nepodařilo se načíst konfigurační soubor ' + config_fn + ':' + #13#10 + E.Message),
        'Chyba', MB_OK OR MB_ICONWARNING);
  end;

  if (paramOpnl <> '') then
    GlobConfig.data.panel_fn := paramOpnl;

  Self.Caption := GlobConfig.panelName + ' – hJOPpanel – v' +
    VersionStr(Application.ExeName) + ' (build ' + FormatDateTime('dd.mm.yyyy', BuildDateTime()) + ')';

  Self.SB_Main.Visible := GlobConfig.data.forms.fMainShowSB;
  Self.SB_HideStatusBar.Down := not GlobConfig.data.forms.fMainShowSB;

  F_splash.ShowState('Vytvářím plátno...');

  try
    Self.DXD_Main := TDXDraw.Create(Self);
    Self.DXD_Main.Parent := Self;
    Self.DXD_Main.Options := [doAllowReboot, doSelectDriver, doHardware];
    Self.DXD_Main.Initialize();
  except
    on E: Exception do
    begin
      Application.MessageBox(PChar('Nepodařilo se inicializovat plátno, aplikace bude ukončena' + #13#10 + E.Message),
        'Chyba', MB_OK OR MB_ICONERROR);
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

  F_splash.ShowState('Načítám symboly...');

  try
    SymbolSet := TSymbolSet.Create(GlobConfig.data.SymbolSet);
  except
    on E: Exception do
    begin
      Application.MessageBox(PChar('Nepodařilo se načíst symboly, aplikace bude ukončena' + #13#10 + E.Message),
        'Chyba', MB_OK OR MB_ICONERROR);
      Self.Close();
      Exit();
    end;
  end;

  F_splash.ShowState('Vytvářím panel...');

  Relief := TRelief.Create(Self);
  Relief.OnMove := Self.OnReliefMove;
  Relief.OnLoginUserChange := Self.OnReliefLoginChange;

  try
    Relief.Initialize(Self.DXD_Main, GlobConfig.data.panel_fn, GlobConfig.data.vysv_fn);
  except
    on E: Exception do
    begin
      Application.MessageBox(PChar('Při inicializaci reliéfu došlo k chybě:' + #13#10 + E.Message), 'Chyba',
        MB_OK OR MB_ICONWARNING);
      Relief.Enabled := false;
      Self.P_Connection.Enabled := false;
    end;
  end;

  if ((GlobConfig.data.SymbolSet = TSymbolSetType.bigger) and (not Self.LargeSSFitsScreen())) then
  begin
    GlobConfig.data.SymbolSet := TSymbolSetType.normal;

    try
      var ss := TSymbolSet.Create(GlobConfig.data.SymbolSet);
      var ss2 := SymbolSet;
      SymbolSet := ss;
      Relief.UpdateSymbolSet();
      ss2.Free();
    except
      on E: Exception do
        Application.MessageBox(PChar('Změna velikosti symbolů se nezdařila+' + #13#10 + E.Message), 'Chyba',
          MB_OK OR MB_ICONWARNING);
    end;
  end;

  // do prvniho pripojeni jsou tu default hodnoty
  BridgeClient.toLogin.server := GlobConfig.data.server.host;
  BridgeClient.toLogin.port := GlobConfig.data.server.port;

  F_splash.ShowState('Načítám zvuky...');
  SoundsPlay.PreloadSounds();

  if (GlobConfig.data.uLI.path <> '') then
  begin
    F_splash.ShowState('Spouštím uLI-daemon...');
    Self.RunuLIDaemon();
  end;

  if (GlobConfig.data.uLI.use) then
  begin
    F_splash.ShowState('Aktivuji spojení s uLI-daemon...');
    BridgeClient.Enabled := True;
  end;

  F_splash.ShowState('Hotovo');

  Self.SB_FullScreen.Down := GlobConfig.data.forms.fMainFullScreen;
  if (GlobConfig.data.forms.fMainFullScreen) then
    Self.BorderStyle := TFormBorderStyle.bsNone;

  Self.UpdateuLIIcon();
  F_splash.Close();
  Self.Show();

  // Must be after Show() because of multiple monitors
  if (((GlobConfig.data.forms.fMainPos.X > (Screen.DesktopLeft-10)) and (GlobConfig.data.forms.fMainPos.Y > (Screen.DesktopTop-10))) and
      (Abs(GlobConfig.data.forms.fMainPos.X) < Screen.DesktopWidth) and (Abs(GlobConfig.data.forms.fMainPos.Y) < Screen.DesktopHeight)) then
  begin
    // Allow negative coordinates for multiple monitors
    // This if must be entered also if in maximized state - restore the monitor it was maximized on
    Self.Left := GlobConfig.data.forms.fMainPos.X;
    Self.Top := GlobConfig.data.forms.fMainPos.Y;
  end;

  if ((GlobConfig.data.forms.fMainMaximized) or (GlobConfig.data.forms.fMainFullScreen)) then
    Self.WindowState := TWindowState.wsMaximized;

  F_PotvrSekv.SetPosFromConfig();

  if (GlobConfig.data.server.autoconnect) then
    Self.A_ConnectExecute(Self);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.SB_DCC_GoClick(Sender: TObject);
begin
  DCC.Go();
end;

procedure TF_Main.SB_DCC_StopClick(Sender: TObject);
begin
  DCC.Stop();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.SB_DetailsClick(Sender: TObject);
begin
  Relief.ShowDetails := Self.SB_Details.Down;
end;

procedure TF_Main.SB_FullScreenClick(Sender: TObject);
begin
  if (Self.SB_FullScreen.Down) then
  begin
    Self.WindowState := TWindowState.wsMaximized;
    Self.BorderStyle := TFormBorderStyle.bsNone;
    Self.Align := alClient;
  end else begin
    Self.BorderStyle := TFormBorderStyle.bsSizeable;
    Self.Align := alNone;
  end;
end;

procedure TF_Main.SB_HideStatusBarClick(Sender: TObject);
begin
  Self.SB_Main.Visible := not Self.SB_HideStatusBar.Down;
  Self.UpdateFormConstraints();
  Self.Resize();
end;

procedure TF_Main.SB_MuteClick(Sender: TObject);
begin
  if (Self.SB_Mute.Down) then
  begin
    Self.mute_time := Now;
    SoundsPlay.muted := True
  end
  else
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
  Self.uliauth_enabled := True;

  var areas := TList<Integer>.Create();
  try
    if (not BridgeClient.opened) then
      Self.RunuLIDaemon()
    else
    begin
      if (GlobConfig.data.auth.password = '') then
        F_Auth.OpenForm('uLI-daemon vyžaduje autentizaci', Self.uLILoginFilled, areas, false)
      else
        BridgeClient.auth();
    end;
  finally
    areas.Free();
  end;

  Self.UpdateuLIIcon();
end;

procedure TF_Main.SetPanelSize(width, height: Integer);
begin
  Self.WindowState := TWindowState.wsNormal;
  Self.UpdateFormConstraints();

  Self.Width := Self.Constraints.MinWidth;
  Self.Height := Self.Constraints.MinHeight;
end;

procedure TF_Main.T_MainTimer(Sender: TObject);
begin
  if (Assigned(Relief)) then
    Relief.Show();

  Self.P_Time.Caption := FormatDateTime('hh:mm:ss', Now);
  Self.P_Date.Caption := FormatDateTime('d. m. yyyy', Now);

  PanelTCPClient.Update();
  BridgeClient.Update();
  Self.uLIAuthUpdate();
  IPC.Update();

  if ((SoundsPlay.muted) and (Self.mute_time + EncodeTime(0, _MUTE_MIN, 0, 0) <= Now)) then
  begin
    Self.SB_Mute.Down := False;
    SoundsPlay.muted := False;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnReliefMove(Sender: TObject; Position: TPoint);
begin
  Self.SB_Main.Panels.Items[0].Text := Format('%.3d;%.3d', [Position.X, Position.Y]);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.ShowAboutDialog();
begin
  Application.MessageBox(PChar('hJOPpanel v' + VersionStr(Application.ExeName) + #13#10 + 'build ' + FormatDateTime('dd.mm.yyyy', BuildDateTime())
     + #13#10 + 'Vytvořil Jan Malina (Horáček) (c) 2014–2025 v KMŽ Brno I'), 'Info',
    MB_OK OR MB_ICONINFORMATION);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnReliefLoginChange(Sender: TObject; user: string);
begin
  Self.L_Login.Caption := user;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.RunuLIDaemon();
var f: string;
  return: Cardinal;
begin
  f := ExpandFileName(GlobConfig.data.uLI.path);
  return := ShellExecute(Self.Handle, 'open', PChar(f), '', PChar(ExtractFilePath(GlobConfig.data.uLI.path)),
    SW_SHOWNOACTIVATE);
  if (return < 32) then
    Application.MessageBox(PChar('Nelze spustit uLI-daemon, chyba' + IntToStr(return) + #13#10 + f), 'uLI-daemon',
      MB_OK OR MB_ICONWARNING);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.UpdateuLIIcon();
begin
  Self.SB_uLIdaemon.Enabled := (((GlobConfig.data.uLI.path <> '') and (not BridgeClient.opened)) or
    (BridgeClient.authStatus = TuLIAuthStatus.no)) and (not Self.uliauth_enabled);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.uLIAuthUpdate();
begin
  if (not Self.uliauth_enabled) then
    Exit();

  if (Now > Self.uliauth_time) then
  begin
    BridgeClient.toLogin.username := '';
    BridgeClient.toLogin.password := '';
    Self.uliauth_enabled := false;
    Self.UpdateuLIIcon();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnuLIAuthStatusChanged(Sender: TObject);
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

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.uLILoginFilled(Sender: TObject; username: string; password: string; ors: TList<Integer>; guest: Boolean);
begin
  if (BridgeClient.toLogin.password = '') then
    F_Auth.AuthError(0, 'Je třeba povolit autorizaci uLI-daemon!')
  else
  begin
    F_Auth.AuthOK(0);
    BridgeClient.auth();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.WndProc(var Message: TMessage);
var received: string;
begin
  // Interprocess communication handler.

  // First check whether we can safely read TForm.Handle property ...
  if HandleAllocated and not(csDestroying in ComponentState) then
  begin
    // ... then whether it is our message. The last paramter tells to ignore the
    // message sent from window of this instance

    case ReadMessageCheck(Message, Handle) of
      _IPC_MYID: // It is our data
        begin
          try
            // Read String from the message
            ReadMessageString(Message, received);
            IPC.ParseData(received);
          finally

          end;
        end;
    else
      inherited;
    end;
  end
  else
    inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnModTimeChanged();
begin
  if (ModelTime.started) then
  begin
    F_Main.P_Time_modelovy.Font.Color := clBlack;
    F_Main.P_Zrychleni.Font.Color := clBlack;
  end else begin
    F_Main.P_Time_modelovy.Font.Color := clRed;
    F_Main.P_Zrychleni.Font.Color := clRed;
  end;

  F_Main.P_Zrychleni.Caption := ModelTime.strSpeed + '×';
  F_Main.P_Time_modelovy.Caption := FormatDateTime('hh:nn:ss', ModelTime.time);

  Self.CheckTimeSpeedWidth();
  Self.FormResize(Self);
end;

procedure TF_Main.CheckTimeSpeedWidth();
const _SMALL = 33;
  _LARGE = 50;
begin
  if ((Length(Self.P_Zrychleni.Caption) > 2) and (Self.P_Zrychleni.width <= _SMALL)) then
    Self.P_Zrychleni.width := _LARGE
  else if ((Length(Self.P_Zrychleni.Caption) = 2) and (Self.P_Zrychleni.width = _LARGE)) then
    Self.P_Zrychleni.width := _SMALL;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TF_Main.LargeSSFitsScreen(): Boolean;
begin
  if (Relief = nil) then
    Exit(True);
  Result := ((Relief.width * SymbolSet.sets[1].symbolWidth <= Screen.DesktopWidth) and
    (Relief.height * SymbolSet.sets[1].symbolHeight <= Screen.DesktopHeight));
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Main.UpdateFormConstraints();
begin
  Self.Constraints.MinWidth := Self.DXD_Main.Width + (Self.Width-Self.ClientWidth);
  Self.Constraints.MinHeight := Self.DXD_Main.Height + Self.P_Header.Height + (Self.Height-Self.ClientHeight);
  if (Self.SB_Main.Visible) then
    Self.Constraints.MinHeight := Self.Constraints.MinHeight + Self.SB_Main.Height;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
