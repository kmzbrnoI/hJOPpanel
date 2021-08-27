unit HVDb;

{
  Sprava seznamu hnacich vozidel, ktere nam posle server.
  (napr. pri prilezitosti editace soupravy)
}

interface

uses Classes, SysUtils, StdCtrls, RPConst, ShellApi, Dialogs, Windows,
  Generics.Collections, Generics.Defaults, Math;

const
  _MAX_FUNC = 28;
  _DEFAULT_MAX_SPEED = 120;

type
  THVType = (other = -1, steam = 0, diesel = 1, motor = 2, electro = 3, car = 4);
  TFunkce = array [0 .. _MAX_FUNC] of boolean;
  THVSite = (odd = 0, even = 1);

  // mod posilani dat hnaciho vozidla klientovi
  // full: s POM
  TLokStringMode = (normal = 0, full = 1);

  THVPomCV = record // jeden zaznam POM se sklada z
    cv: Word; // oznaceni CV a
    data: Byte; // dat, ktera se maji do CV zapsat.
  end;

  THVFuncType = (permanent = 0, momentary = 1);

  THV = class
  private
    procedure DefaultData();

  public
    name: string;
    owner: string;
    designation: string;
    note: string;
    addr: Cardinal;
    typ: THVType;
    train: string;
    siteA: THVSite;
    functions: TFunkce;
    speedSteps: Cardinal;
    speedKmph: Cardinal;
    direction: Integer;
    token: string;
    orid: string; // id oblasti rizeni, ve ktere se nachazi loko
    maxSpeed: Cardinal;
    transience: Cardinal;

    POMtake: TList<THVPomCV>; // seznam POM pri prevzeti do automatu
    POMrelease: TList<THVPomCV>; // seznam POM pri uvolneni to rucniho rizeni

    funcDesc: array [0 .. _MAX_FUNC] of string; // seznam popisu funkci hnaciho vozidla
    funcType: array [0 .. _MAX_FUNC] of THVFuncType; // typy funkci hnaciho vozidla

    procedure ParseFromToken(data: string);
    procedure ParseData(data: string);
    constructor Create(data: string); overload;
    constructor Create(); overload;
    constructor CreateFromToken(data: string);
    destructor Destroy(); override;

    function GetPanelLokString(mode: TLokStringMode = normal): string;

    class function CharToHVFuncType(c: char): THVFuncType;
    class function HVFuncTypeToChar(t: THVFuncType): char;
    class function AddrComparer(): IComparer<THV>;
  end;

  THVDb = class
  public
    HVs: TObjectList<THV>;

    constructor Create();
    destructor Destroy(); override;

    procedure ParseHVs(data: string);
    procedure ParseHVsFromToken(data: string);
    procedure Add(HV: THV);
    procedure Delete(index: Integer);

    procedure FillHVs(var CB: TComboBox; var Indexes: TWordAr; addr: Integer = -1; special: THV = nil;
      with_spr: boolean = false);
    procedure OpenJerry();

  end;

implementation

uses GlobalConfig, fMain, TCPClientPanel, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

constructor THVDb.Create();
begin
  inherited;
  Self.HVs := TObjectList<THV>.Create(THV.AddrComparer);
end;

destructor THVDb.Destroy();
begin
  Self.HVs.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure THVDb.ParseHVs(data: string);
var str: TStrings;
begin
  str := TStringList.Create();
  try
    ExtractStringsEx([']'], ['['], data, str);
    Self.HVs.Clear();
    for var HV in str do
      Self.HVs.Add(THV.Create(HV));
  finally
    str.Free();
  end;
end;

procedure THVDb.ParseHVsFromToken(data: string);
var str: TStrings;
begin
  str := TStringList.Create();
  try
    ExtractStringsEx([']'], ['['], data, str);
    Self.HVs.Clear();
    for var HV in str do
      Self.HVs.Add(THV.CreateFromToken(HV));
  finally
    str.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure THVDb.FillHVs(var CB: TComboBox; var Indexes: TWordAr; addr: Integer = -1; special: THV = nil;
  with_spr: boolean = false);
var index: Integer;
begin
  CB.Clear();

  if (Assigned(special)) then
  begin
    SetLength(Indexes, Self.HVs.Count + 1);
    CB.Items.Add(IntToStr(special.addr) + ' : ' + special.name + ' (' + special.designation + ')');
    Indexes[0] := special.addr;
    if (special.addr = addr) then
      CB.ItemIndex := 0;
    index := 1;
  end else begin
    SetLength(Indexes, Self.HVs.Count);
    index := 0;
  end;

  for var i := 0 to Self.HVs.Count - 1 do
  begin
    if ((Self.HVs[i].train = '-') or (with_spr)) then
    begin
      CB.Items.Add(IntToStr(Self.HVs[i].addr) + ' : ' + Self.HVs[i].name + ' (' + Self.HVs[i].designation + ')');
      Indexes[index] := Self.HVs[i].addr;
      if (Self.HVs[i].addr = addr) then
        CB.ItemIndex := i;
      index := index + 1;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor THV.Create(data: string);
begin
  inherited Create();
  Self.POMtake := TList<THVPomCV>.Create();
  Self.POMrelease := TList<THVPomCV>.Create();
  Self.ParseData(data);
end;

constructor THV.Create();
begin
  inherited;
  Self.POMtake := TList<THVPomCV>.Create();
  Self.POMrelease := TList<THVPomCV>.Create();
end;

constructor THV.CreateFromToken(data: string);
begin
  inherited Create();
  Self.ParseFromToken(data);
end;

destructor THV.Destroy();
begin
  Self.POMtake.Free();
  Self.POMrelease.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure THV.ParseData(data: string);
var str, str2, str3: TStrings;
begin
  // format zapisu: nazev|majitel|oznaceni|poznamka|adresa|Typ|souprava|stanovisteA|funkce|rychlost_stupne|
  // rychlost_kmph|smer|or_id{[{cv1take|cv1take-value}][{...}]...}|{[{cv1release|cv1release-value}][{...}]...}|
  // {vyznam-F0;vyznam-F1;...}|typy_funkci|max rychlost

  // souprava je bud cislo soupravy, nebo znak '-'
  str := TStringList.Create();
  str2 := TStringList.Create();
  str3 := TStringList.Create();
  ExtractStringsEx(['|'], [], data, str);

  Self.DefaultData();

  try
    Self.name := str[0];
    Self.owner := str[1];
    Self.designation := str[2];
    Self.note := str[3];
    Self.addr := StrToInt(str[4]);
    Self.typ := THVType(StrToInt(str[5]));
    Self.train := str[6];
    Self.siteA := THVSite(StrToInt(str[7]));

    for var i := 0 to _MAX_FUNC do
    begin
      if (i < Length(str[8])) then
        if (str[8][i + 1] = '1') then
          Self.functions[i] := true
        else
          Self.functions[i] := false;
    end;

    Self.speedSteps := StrToInt(str[9]);
    Self.speedKmph := StrToInt(str[10]);
    Self.direction := StrToInt(str[11]);
    Self.orid := str[12];

    if (str.Count > 13) then
    begin
      // pom-take
      ExtractStringsEx([']'], ['['], str[13], str2);
      for var tmp in str2 do
      begin
        str3.Clear();
        ExtractStringsEx(['|'], [], tmp, str3);
        var pomCv: THVPomCV;
        pomCv.cv := StrToInt(str3[0]);
        pomCv.data := StrToInt(str3[1]);
        Self.POMtake.Add(pomCv);
      end;

      // pom-release
      str2.Clear();
      ExtractStringsEx([']'], ['['], str[14], str2);
      for var tmp in str2 do
      begin
        str3.Clear();
        ExtractStringsEx(['|'], [], tmp, str3);
        var pomCv: THVPomCV;
        pomCv.cv := StrToInt(str3[0]);
        pomCv.data := StrToInt(str3[1]);
        Self.POMrelease.Add(pomCv);
      end;
    end;

    // func-description
    if (str.Count > 15) then
    begin
      str2.Clear();
      ExtractStringsEx([';'], [], str[15], str2);
      for var i := 0 to _MAX_FUNC do
        if (i < str2.Count) then
          Self.funcDesc[i] := str2[i]
        else
          Self.funcDesc[i] := '';
    end else begin
      for var i := 0 to _MAX_FUNC do
        Self.funcDesc[i] := '';
    end;

    // function types
    if (str.Count > 16) then
    begin
      for var i := 0 to _MAX_FUNC do
        if (i < Length(str[16])) then
          Self.funcType[i] := CharToHVFuncType(str[16][i + 1])
        else
          Self.funcType[i] := THVFuncType.permanent;
    end else begin
      for var i := 0 to _MAX_FUNC do
        Self.funcType[i] := THVFuncType.permanent;
    end;

    if (str.Count > 17) then
      Self.maxSpeed := StrToInt(str[17]);

    if (str.Count > 18) then
      Self.transience := StrToInt(str[18]);

  except

  end;

  str.Free();
  str2.Free();
  str3.Free();
end;

procedure THV.ParseFromToken(data: string);
var str: TStrings;
  // format zapisu: addr|token
begin
  str := TStringList.Create();
  ExtractStringsEx(['|'], [], data, str);

  Self.DefaultData();

  try
    Self.addr := StrToInt(str[0]);
    Self.token := str[1];
  except

  end;

  str.Free();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure THV.DefaultData();
begin
  Self.name := '';
  Self.owner := '';
  Self.designation := '';
  Self.note := '';
  Self.addr := 0;
  Self.typ := THVType.other;
  Self.train := '-';
  Self.maxSpeed := _DEFAULT_MAX_SPEED;
  Self.transience := 0;

  for var i := 0 to _MAX_FUNC do
    Self.functions[i] := false;
end;

/// /////////////////////////////////////////////////////////////////////////////

function THV.GetPanelLokString(mode: TLokStringMode = normal): string;
begin
  Result := Self.name + '|' + Self.owner + '|' + Self.designation + '|{' + Self.note + '}|' + IntToStr(Self.addr)
    + '|' + IntToStr(Integer(Self.typ)) + '|' + Self.train + '|' + IntToStr(Integer(Self.siteA)) + '|';

  for var i := 0 to _MAX_FUNC do
  begin
    if (Self.functions[i]) then
      Result := Result + '1'
    else
      Result := Result + '0';
  end;

  Result := Result + '||||' + Self.orid + '|';

  if (mode = full) then
  begin
    // cv-take
    Result := Result + '{';
    for var pomCv in Self.POMtake do
      Result := Result + '[{' + IntToStr(pomCv.cv) + '|' + IntToStr(pomCv.data) + '}]';
    Result := Result + '}|{';

    // cv-release
    for var pomCv in Self.POMrelease do
      Result := Result + '[{' + IntToStr(pomCv.cv) + '|' + IntToStr(pomCv.data) + '}]';
    Result := Result + '}|';
  end; // if pom

  // vyznam funkci
  Result := Result + '{';
  for var i := 0 to _MAX_FUNC do
  begin
    if (Self.funcDesc[i] <> '') then
      Result := Result + '{' + Self.funcDesc[i] + '};'
    else
      Result := Result + ';';
  end;
  Result := Result + '}|';

  // typy funkci
  for var i := 0 to _MAX_FUNC do
    Result := Result + HVFuncTypeToChar(Self.funcType[i]);
  Result := Result + '|';

  Result := Result + IntToStr(Self.maxSpeed) + '|';
  Result := Result + IntToStr(Self.transience) + '|';
end;

/// /////////////////////////////////////////////////////////////////////////////

// Otevreni regulatoru Jerry pro vsechna loko v seznamu
procedure THVDb.OpenJerry();
var args: string;
begin
  // predame autoconnect, server a port
  args := '-a -s "' + GlobConfig.data.server.host + '" -pt ' + IntToStr(GlobConfig.data.server.port) + ' ';

  // predat uzivatele ?
  if ((GlobConfig.data.reg.reg_user) and (GlobConfig.data.auth.username <> '')) then
    args := args + '-u "' + GlobConfig.data.auth.username + '" -p "' + GlobConfig.data.auth.password + '" ';

  // kontrola tokenu
  for var HV in Self.HVs do
    if (HV.token = '') then
      raise Exception.Create('Hnaci vozidlo ' + IntToStr(HV.addr) + ' nema token');

  // predat vozidla
  for var HV in Self.HVs do
    args := args + IntToStr(HV.addr) + ':' + HV.token + ' ';

  // spustit regulator
  var f := ExpandFileName(GlobConfig.data.reg.reg_fn);
  var res := ShellExecute(F_Main.Handle, 'open', PChar(f), PChar(args), PChar(ExtractFilePath(GlobConfig.data.reg.reg_fn)),
    SW_SHOWNORMAL);
  if (res < 32) then
    raise Exception.Create('Nelze spustit regulator - chyba ' + IntToStr(res));
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure THVDb.Add(HV: THV);
begin
  Self.HVs.Add(HV);
  Self.HVs.Sort();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure THVDb.Delete(index: Integer);
begin
  Self.HVs.Delete(index);
end;

/// /////////////////////////////////////////////////////////////////////////////

class function THV.CharToHVFuncType(c: char): THVFuncType;
begin
  if (UpperCase(c) = 'M') then
    Result := THVFuncType.momentary
  else
    Result := THVFuncType.permanent;
end;

class function THV.HVFuncTypeToChar(t: THVFuncType): char;
begin
  if (t = THVFuncType.momentary) then
    Result := 'M'
  else
    Result := 'P';
end;

/// /////////////////////////////////////////////////////////////////////////////

class function THV.AddrComparer(): IComparer<THV>;
begin
  Result := TComparer<THV>.Construct(
    function(const Left, Right: THV): Integer
    begin
      Result := CompareValue(Left.addr, Right.addr);
    end);
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
