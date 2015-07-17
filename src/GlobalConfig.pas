unit GlobalConfig;

// globalni konfigurace SW

interface

uses IniFiles, SysUtils, RPConst, Types, Generics.Collections, Classes;

type
  TSoundsConfig = record
    sndRizikovaFce:string;
    sndTratSouhlas:string;
    sndChyba:string;
    sndPretizeni:string;
    sndPrichoziZprava:string;
  end;

  TServerConfig = record
    host:string;
    port:Word;
    autoconnect:boolean;
  end;

  TAuthConfig = record
    autoauth:boolean;
    username,password:string;
    ORs:TDictionary<string, TORControlRights>;
    forgot:boolean;     // smazat autorizacni udaje po odpojeni ze serveru
    auth_chb_remember:boolean;
  end;

  TRegConfig = record
    reg_fn:string;
    reg_user:boolean;
  end;

  TGlobConfigData = record
    panel_fn:string;
    panel_mouse:Integer;
    sounds:TSoundsConfig;
    symbolSet:TSymbolSetType;
    server:TServerConfig;
    auth:TAuthConfig;
    reg:TRegConfig;
    vysv_fn:string;
    frmPos:TPoint;
    resuscitation:boolean;
  end;

  TGlobConfig = class
    public const
      _DEFAULT_FN = 'config.ini';

    private
      filename:string;

    public

      data:TGlobConfigData;

      constructor Create();
      destructor Destroy(); override;

      function LoadFile(const filename:string = _DEFAULT_FN):Integer;
      function SaveFile(const filename:string):Integer; overload;
      function SaveFile():Integer; overload;

      property fn:string read filename;
  end;

var
  GlobConfig:TGlobConfig;

implementation

uses TCPClientPanel, fMain;

////////////////////////////////////////////////////////////////////////////////

constructor TGlobConfig.Create();
begin
 inherited Create();
 Self.data.auth.ORs := TDictionary<string, TORControlRights>.Create();
end;//ctor

destructor TGlobConfig.Destroy();
begin
 Self.data.auth.ORs.Free();
 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

function TGlobConfig.LoadFile(const filename:string = _DEFAULT_FN):Integer;
var ini:TMemIniFile;
    str:TStrings;
    i:Integer;
begin
 try
   ini := TMemIniFile.Create(filename);
 except
   Exit(1);
 end;

 Self.filename := filename;

 Self.data.panel_fn := ini.ReadString('global', 'panel', 'panel.opnl');
 Self.data.vysv_fn  := ini.ReadString('global', 'vysv', 'vysv.csv');
 Self.data.panel_mouse := ini.ReadInteger('global', 'panel_mouse', 0);
 Self.data.resuscitation := ini.ReadBool('global', 'resuscitation', false);

 Self.data.sounds.sndRizikovaFce    := ini.ReadString('sounds', 'rizikova-funkce', '');
 Self.data.sounds.sndTratSouhlas    := ini.ReadString('sounds', 'tratovy-souhlas', '');
 Self.data.sounds.sndChyba          := ini.ReadString('sounds', 'chyba', '');
 Self.data.sounds.sndPretizeni      := ini.ReadString('sounds', 'pretizeni', '');
 Self.data.sounds.sndPrichoziZprava := ini.ReadString('sounds', 'prichozi-zprava', '');

 Self.data.symbolSet := TSymbolSetType(ini.ReadInteger('global', 'symbolset', 0));

 Self.data.reg.reg_user := ini.ReadBool('reg', 'auth', true);
 Self.data.reg.reg_fn   := ini.ReadString('reg', 'fn', 'regulator.exe');

 Self.data.server.host        := ini.ReadString('server', 'host', 'localhost');
 Self.data.server.port        := ini.ReadInteger('server', 'port', _DEFAULT_PORT);
 Self.data.server.autoconnect := ini.ReadBool('server', 'autoconnect', false);

 Self.data.auth.autoauth      := ini.ReadBool('auth', 'autoauth', false);
 Self.data.auth.username      := ini.ReadString('auth', 'username', '');
 Self.data.auth.password      := ini.ReadString('auth', 'password', '');
 Self.data.auth.forgot        := false;
 Self.data.auth.auth_chb_remember := ini.ReadBool('auth', 'F_auth_chb_remember', true);

 str := TStringList.Create();
 ExtractStrings(['(', ')', ',', ';'], [], PChar(ini.ReadString('auth', 'ORs', '')), str);

 Self.data.auth.ORs.Clear();
 for i := 0 to (str.Count div 2)-1 do
  begin
   try
    Self.data.auth.ORs.Add(str[i*2], TORControlRights(StrToInt(str[i*2 + 1])));
   except

   end;
  end;//for i

 str.Free();


 Self.data.frmPos.X := ini.ReadInteger('F_Main', 'X', 0);
 Self.data.frmPos.Y := ini.ReadInteger('F_Main', 'Y', 0);

 F_Main.T_Main.Interval := ini.ReadInteger('global', 'timer', 200);

 Result := 1;
end;//function

function TGlobConfig.SaveFile(const filename:string):Integer;
var ini:TMemIniFile;
    i:Integer;
    str:string;
    rights:TORControlRights;
begin
 try
   ini := TMemIniFile.Create(filename);
 except
   Exit(1);
 end;

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

 ini.WriteInteger('global', 'symbolset', Integer(Self.data.symbolSet));

 ini.WriteString('server', 'host', Self.data.server.host);
 ini.WriteInteger('server', 'port', Self.data.server.port);
 ini.WriteBool('server', 'autoconnect', Self.data.server.autoconnect);

 ini.WriteBool('auth', 'autoauth', Self.data.auth.autoauth);
 ini.WriteString('auth', 'username', Self.data.auth.username);
 ini.WriteString('auth', 'password', Self.data.auth.password);
 ini.WriteBool('auth', 'F_auth_chb_remember', Self.data.auth.auth_chb_remember);

 str := '';
 for i := 0 to Relief.ORs.Count-1 do
   if (Self.data.auth.ORs.TryGetValue(Relief.ORs[i].id, rights)) then
     str := str + '(' + Relief.ORs[i].id + ';' + IntToStr(Integer(rights)) + ')';
 ini.WriteString('auth', 'ORs', str);

 ini.WriteInteger('F_Main', 'X', Self.data.frmPos.X);
 ini.WriteInteger('F_Main', 'Y', Self.data.frmPos.Y);

 ini.WriteInteger('global', 'timer', F_Main.T_Main.Interval);

 ini.UpdateFile();

 Result := 0;
end;//function

function TGlobConfig.SaveFile():Integer;
begin
 Result := Self.SaveFile(Self.filename);
end;//function

////////////////////////////////////////////////////////////////////////////////

initialization
  GlobConfig := TGlobConfig.Create();

finalization
  FreeAndNil(GlobConfig);

end.//unit
