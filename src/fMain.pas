unit fMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DXDraws, ComCtrls, ExtCtrls, ImgList, Panel, AppEvnts, ActnList,
  Buttons, StdCtrls, GlobalConfig, StrUtils, Resuscitation, ShellApi;

const
  _open_file_errors: array [1..3] of string =
    ('Soubor panelu neexistuje',
     'Verze souboru panelu nen� podporov�na',
     'Soubor panelu se nepoda�ilo otev��t');

  _MUTE_MIN = 3;    // ztisit zvuky je mozne maximalne na 3 minuty, pak se znovu zapnou

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
    Panel1: TPanel;
    SB_PrintScreen: TSpeedButton;
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
  private

   mute_time:TDateTime;

    procedure OnReliefMove(Sender:TObject; Position:TPoint);
    procedure ShowAboutDialog();

  public
    DXD_Main:TDXDraw;
    close_app: boolean;

     procedure OnReliefLoginChange(Sender:TObject; user:string);

     procedure Init(const config_fn:string = TGlobConfig._DEFAULT_FN);          // konfiguracni soubor se cte z argumentu programu
     procedure SetPanelSize(width,height:Integer);
  end;

var
  F_Main: TF_Main;
  Relief:TRelief;

implementation

uses Symbols, Debug, TCPCLientPanel, BottomErrors, Verze, Sounds,
  fSettings, fSplash, ModelovyCas, DCC_Icons, fSoupravy, RPConst, uLIclient;

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
    Application.MessageBox(PChar('P�ipojen� se nezda�ilo'+#13#10+E.Message), 'Nep�ipojeno', MB_OK OR MB_ICONWARNING);
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
     if (Application.MessageBox(PChar('Soubor ' +fn + ' ji� existuje, p�ejete si ho nahradit?'),
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

 ModCas.Reset();
 DCC := TDCC.Create();
end;

procedure TF_Main.FormDestroy(Sender: TObject);
var data:TGlobConfigData;
begin
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
    f:string;
begin
 F_splash.AddStav('Na��t�m konfiguraci...');

 GlobConfig.LoadFile(config_fn);

 Self.Caption := ChangeFileExt(ExtractFileName(ExpandFileName(GlobConfig.data.panel_fn)), '')+' - hJOPpanel - v'+NactiVerzi(Application.ExeName)+' (build '+GetLastBuildDate+')';

 F_splash.AddStav('Vytv���m pl�tno...');

 try
   Self.DXD_main := TDXDraw.Create(Self);
   Self.DXD_main.Parent  := Self;
   Self.DXD_main.Align   := alClient;
   Self.DXD_Main.Options := [doAllowReboot, doSelectDriver, doHardware];
   Self.DXD_main.Initialize;
 except
   on E : Exception do
    begin
     Application.MessageBox(PChar('Nepoda�ilo se inicializovat pl�tno, aplikace bude ukon�ena'+#13#10+E.Message), 'Chyba', MB_OK OR MB_ICONERROR);
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

 F_splash.AddStav('Na��t�m symboly...');

 try
   SymbolSet := TSymbolSet.Create(GlobConfig.data.symbolSet);
 except
   on e:Exception do
    begin
     Application.MessageBox(PChar('Nepoda�ilo se na��st symboly, aplikace bude ukon�ena'+#13#10+e.Message), 'Chyba', MB_OK OR MB_ICONERROR);
     Self.Close();
     Exit();
    end;
 end;

 F_splash.AddStav('Vytv���m panel...');

 Relief := TRelief.Create(Self);
 Relief.OnMove := Self.OnReliefMove;
 Relief.OnLoginUserChange := Self.OnReliefLoginChange;
 return := Relief.Initialize(Self.DXD_Main, GlobConfig.data.panel_fn, GlobConfig.data.vysv_fn);

 if (return <> 0) then
  begin
   Application.MessageBox(PChar('P�i inicializaci reli�fu do�lo k chyb�:'+#13#10+_open_file_errors[return]), 'Chyba', MB_OK OR MB_ICONWARNING);
   Self.DXD_Main.Enabled := false;
   Self.P_Connection.Enabled := false;
  end;

 if ((GlobConfig.data.frmPos.X >= 0) and (GlobConfig.data.frmPos.Y >= 0) and
   (GlobConfig.data.frmPos.X+100 < Screen.Width) and (GlobConfig.data.frmPos.Y+100 < Screen.Height)) then
  begin
   Self.Left := GlobConfig.data.frmPos.X;
   Self.Top := GlobConfig.data.frmPos.Y;
  end;

 if (GlobConfig.data.uLI.path <> '') then
  begin
   F_splash.AddStav('Spou�t�m uLI-daemon...');
   f := ExpandFileName(GlobConfig.data.uLI.path);
   return := ShellExecute(Self.Handle, 'open', PChar(f), '', PChar(ExtractFilePath(GlobConfig.data.uLI.path)), SW_SHOWNOACTIVATE);
   if (return < 32) then
     Application.MessageBox(PChar('Nelze spustit uLI-daemon, chyba'+IntToStr(return)+#13#10+f), 'uLI-daemon', MB_OK OR MB_ICONWARNING);
  end;

 if (GlobConfig.data.uLI.use) then
  begin
   F_splash.AddStav('Aktivuji spojen� s uLI-daemon...');
   BridgeClient.enabled := true;
  end;

 F_splash.AddStav('Hotovo');

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
  'Vytvo�il Jan Hor��ek (c) 2014-2016 pro KM� Brno I'), 'Info', MB_OK OR MB_ICONINFORMATION);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_Main.OnReliefLoginChange(Sender:TObject; user:string);
begin
 Self.L_Login.Caption := user;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit

