unit GlobalConfig;

{
  Global SW configuration.
}

interface

uses IniFiles, SysUtils, Types, Generics.Collections, Classes, PanelOR, Symbols;

const
  _MOUSE_PANEL = 0;
  _MOUSE_OS = 1;

type
  TSoundsConfig = record
    sndRizikovaFce: string;
    sndTratSouhlas: string;
    sndChyba: string;
    sndPretizeni: string;
    sndPrichoziZprava: string;
    sndPrivolavacka: string;
    sndTimeout: string;
    sndStaveniVyzva: string;
    sndNeniJC: string;
  end;

  TServerConfig = record
    host: string;
    port: Word;
    autoconnect: boolean;
  end;

  TAuthConfig = record
    autoauth: boolean;
    username, password: string;
    ORs: TDictionary<string, TAreaControlRights>;
    forgot: boolean; // smazat autorizacni udaje po odpojeni ze serveru
    auth_default_level: Integer;

    ipc_send, ipc_receive: boolean;
  end;

  TGuestConfig = record
    allow: boolean;
    username, password: string; // heslo je uchovavano jako hash
  end;

  TRegConfig = record
    reg_fn: string;
    reg_user: boolean;
  end;

  TuLIConfig = record
    path: string;
    use: boolean;
  end;

  TFormConfig = record
    fMainPos: TPoint;
    fMainMaximized: Boolean;
    fMainFullScreen: Boolean;
    fMainShowSB: Boolean;
    fPotvrSekv: TPoint;
  end;

  TGlobConfigData = record
    panel_fn: string;
    panel_mouse: Integer;
    sounds: TSoundsConfig;
    symbolSet: TSymbolSetType;
    server: TServerConfig;
    auth: TAuthConfig;
    guest: TGuestConfig;
    reg: TRegConfig;
    vysv_fn: string;
    resuscitation: boolean;
    uLI: TuLIConfig;
    forms: TFormConfig;
  end;

  TGlobConfig = class
  public const
    _DEFAULT_FN = 'config.ini';

  private
    filename: string;

     function GetPanelName(): string;

  public
    data: TGlobConfigData;

     constructor Create();
     destructor Destroy(); override;

     procedure LoadFile(const filename: string = _DEFAULT_FN);
     procedure SaveFile(const filename: string); overload;
     procedure SaveFile(); overload;

     function GetAuthNonNullORSCnt(): Cardinal;

     property fn: string read filename;
     property panelName: string read GetPanelName;
  end;

var
  GlobConfig: TGlobConfig;

implementation

uses TCPClientPanel, fMain, fSprHelp, fHVEdit;

/// /////////////////////////////////////////////////////////////////////////////

constructor TGlobConfig.Create();
begin
  inherited;
  Self.data.auth.ORs := TDictionary<string, TAreaControlRights>.Create();
end;

destructor TGlobConfig.Destroy();
begin
  Self.data.auth.ORs.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TGlobConfig.LoadFile(const filename: string = _DEFAULT_FN);
begin
  var ini := TMemIniFile.Create(filename, TEncoding.UTF8);
  try
    Self.filename := filename;

    Self.data.panel_fn := ini.ReadString('global', 'panel', 'panel.opnl');
    Self.data.vysv_fn := ini.ReadString('global', 'vysv', 'vysv.csv');
    Self.data.panel_mouse := ini.ReadInteger('global', 'panel_mouse', 0);
    Self.data.resuscitation := ini.ReadBool('global', 'resuscitation', false);

    Self.data.sounds.sndRizikovaFce := ini.ReadString('sounds', 'rizikova-funkce', '');
    Self.data.sounds.sndTratSouhlas := ini.ReadString('sounds', 'tratovy-souhlas', '');
    Self.data.sounds.sndChyba := ini.ReadString('sounds', 'chyba', '');
    Self.data.sounds.sndPretizeni := ini.ReadString('sounds', 'pretizeni', '');
    Self.data.sounds.sndPrichoziZprava := ini.ReadString('sounds', 'prichozi-zprava', '');
    Self.data.sounds.sndPrivolavacka := ini.ReadString('sounds', 'privolavacka', '');
    Self.data.sounds.sndTimeout := ini.ReadString('sounds', 'timeout', '');
    Self.data.sounds.sndStaveniVyzva := ini.ReadString('sounds', 'staveniVyzva', '');
    Self.data.sounds.sndNeniJC := ini.ReadString('sounds', 'neniJC', '');

    Self.data.symbolSet := TSymbolSetType(ini.ReadInteger('global', 'symbolset', 0));

    Self.data.reg.reg_user := ini.ReadBool('reg', 'auth', true);
    Self.data.reg.reg_fn := ini.ReadString('reg', 'fn', 'regulator.exe');

    Self.data.server.host := ini.ReadString('server', 'host', 'localhost');
    Self.data.server.port := ini.ReadInteger('server', 'port', _DEFAULT_PORT);
    Self.data.server.autoconnect := ini.ReadBool('server', 'autoconnect', false);

    Self.data.auth.autoauth := ini.ReadBool('auth', 'autoauth', false);
    Self.data.auth.username := ini.ReadString('auth', 'username', '');
    Self.data.auth.password := ini.ReadString('auth', 'password', '');
    Self.data.auth.forgot := false;
    Self.data.auth.auth_default_level := ini.ReadInteger('auth', 'auth_default_level', 1);

    Self.data.auth.ipc_send := ini.ReadBool('auth', 'ipc_send', true);
    Self.data.auth.ipc_receive := ini.ReadBool('auth', 'ipc_received', true);

    var str := TStringList.Create();
    try
      ExtractStrings(['(', ')', ',', ';'], [], PChar(ini.ReadString('auth', 'ORs', '')), str);

      Self.data.auth.ORs.Clear();
      for var i := 0 to (str.Count div 2) - 1 do
      begin
        try
          Self.data.auth.ORs.Add(str[i * 2], TAreaControlRights(StrToInt(str[i * 2 + 1])));
        except

        end;
      end;
    finally
      str.Free();
    end;

    Self.data.guest.allow := ini.ReadBool('guest', 'allow', false);
    Self.data.guest.username := ini.ReadString('guest', 'username', '');
    Self.data.guest.password := ini.ReadString('guest', 'password', '');

    Self.data.uLI.path := ini.ReadString('uLI-daemon', 'path', '');
    Self.data.uLI.use := ini.ReadBool('uli-daemon', 'connect', false);

    Self.data.forms.fMainPos.X := ini.ReadInteger('F_Main', 'X', 0);
    Self.data.forms.fMainPos.Y := ini.ReadInteger('F_Main', 'Y', 0);
    Self.data.forms.fMainMaximized := ini.ReadBool('F_Main', 'maximized', False);
    Self.data.forms.fMainShowSB := ini.ReadBool('F_Main', 'showStatusBar', True);
    Self.data.forms.fMainFullScreen := ini.ReadBool('F_Main', 'fullScreen', False);

    Self.data.forms.fPotvrSekv.X := ini.ReadInteger('F_PotvrSekv', 'X', 0);
    Self.data.forms.fPotvrSekv.Y := ini.ReadInteger('F_PotvrSekv', 'Y', 0);

    F_Main.T_Main.Interval := ini.ReadInteger('global', 'timer', 200);

    F_SprHelp.LoadData(ini);
    F_HVEdit.LoadPrechodnost(ini);
  finally
    ini.Free();
  end;
end;

procedure TGlobConfig.SaveFile(const filename: string);
begin
  var ini := TMemIniFile.Create(filename, TEncoding.UTF8);

  try
    ini.WriteString('global', 'panel', Self.data.panel_fn);
    ini.WriteString('global', 'vysv', Self.data.vysv_fn);
    ini.WriteInteger('global', 'panel_mouse', Self.data.panel_mouse);
    ini.WriteBool('global', 'resuscitation', Self.data.resuscitation);

    ini.WriteBool('reg', 'auth', Self.data.reg.reg_user);
    ini.WriteString('reg', 'fn', Self.data.reg.reg_fn);

    ini.WriteString('sounds', 'rizikova-funkce', Self.data.sounds.sndRizikovaFce);
    ini.WriteString('sounds', 'tratovy-souhlas', Self.data.sounds.sndTratSouhlas);
    ini.WriteString('sounds', 'chyba', Self.data.sounds.sndChyba);
    ini.WriteString('sounds', 'pretizeni', Self.data.sounds.sndPretizeni);
    ini.WriteString('sounds', 'prichozi-zprava', Self.data.sounds.sndPrichoziZprava);
    ini.WriteString('sounds', 'privolavacka', Self.data.sounds.sndPrivolavacka);
    ini.WriteString('sounds', 'timeout', Self.data.sounds.sndTimeout);
    ini.WriteString('sounds', 'staveniVyzva', Self.data.sounds.sndStaveniVyzva);
    ini.WriteString('sounds', 'neniJC', Self.data.sounds.sndNeniJC);

    ini.WriteInteger('global', 'symbolset', Integer(Self.data.symbolSet));

    ini.WriteString('server', 'host', Self.data.server.host);
    ini.WriteInteger('server', 'port', Self.data.server.port);
    ini.WriteBool('server', 'autoconnect', Self.data.server.autoconnect);

    ini.WriteBool('auth', 'autoauth', Self.data.auth.autoauth);
    ini.WriteString('auth', 'username', Self.data.auth.username);
    ini.WriteString('auth', 'password', Self.data.auth.password);
    ini.WriteInteger('auth', 'auth_default_level', Self.data.auth.auth_default_level);

    ini.WriteBool('auth', 'ipc_send', Self.data.auth.ipc_send);
    ini.WriteBool('auth', 'ipc_received', Self.data.auth.ipc_receive);

    var str := '';
    var rights: TAreaControlRights;
    for var i := 0 to Relief.pareas.Count - 1 do
      if (Self.data.auth.ORs.TryGetValue(Relief.pareas[i].id, rights)) then
        str := str + '(' + Relief.pareas[i].id + ';' + IntToStr(Integer(rights)) + ')';
    ini.WriteString('auth', 'ORs', str);

    ini.WriteBool('guest', 'allow', Self.data.guest.allow);
    ini.WriteString('guest', 'username', Self.data.guest.username);
    ini.WriteString('guest', 'password', Self.data.guest.password);

    ini.WriteString('uLI-daemon', 'path', Self.data.uLI.path);
    ini.WriteBool('uli-daemon', 'connect', Self.data.uLI.use);

    ini.WriteInteger('F_Main', 'X', Self.data.forms.fMainPos.X);
    ini.WriteInteger('F_Main', 'Y', Self.data.forms.fMainPos.Y);
    ini.WriteBool('F_Main', 'maximized', Self.data.forms.fMainMaximized);
    ini.WriteBool('F_Main', 'showStatusBar', Self.data.forms.fMainShowSB);
    ini.WriteBool('F_Main', 'fullScreen', Self.data.forms.fMainFullScreen);

    ini.WriteInteger('F_PotvrSekv', 'X', Self.data.forms.fPotvrSekv.X);
    ini.WriteInteger('F_PotvrSekv', 'Y', Self.data.forms.fPotvrSekv.Y);

    ini.WriteInteger('global', 'timer', F_Main.T_Main.Interval);

    ini.UpdateFile();
  finally
    ini.Free();
  end;
end;

procedure TGlobConfig.SaveFile();
begin
  Self.SaveFile(Self.filename);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TGlobConfig.GetAuthNonNullORSCnt(): Cardinal;
begin
  Result := 0;
  for var item in Self.data.auth.ORs do
    if (item.Value > TAreaControlRights.null) then
      Inc(Result);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TGlobConfig.GetPanelName(): string;
begin
  Result := ChangeFileExt(ExtractFileName(ExpandFileName(Self.data.panel_fn)), '');
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

GlobConfig := TGlobConfig.Create();

finalization

FreeAndNil(GlobConfig);

end.// unit
