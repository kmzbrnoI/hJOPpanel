unit RVDb;

{
  Sprava seznamu hnacich vozidel, ktere nam posle server.
  (napr. pri prilezitosti editace vlaku)
}

interface

uses Classes, SysUtils, StdCtrls, RPConst, ShellApi, Dialogs, Windows,
  Generics.Collections, Generics.Defaults, Math;

const
  _MAX_FUNC = 28;
  _DEFAULT_MAX_SPEED = 120; // [km/h]

type
  TRVType = (other = -1, steam = 0, diesel = 1, motor = 2, electro = 3, car = 4);
  TRVFunkce = array [0 .. _MAX_FUNC] of boolean;
  TRVSite = (odd = 0, even = 1);
  TPomStatus = (manual = 0, automat = 1);

  // mod posilani dat hnaciho vozidla klientovi
  // full: s POM
  TLokStringMode = (normal = 0, full = 1);

  TRVPomCV = record // jeden zaznam POM se sklada z:
    cv: Word; // cislo CV
    value: Byte; // data, ktera se maji do CV zapsat
  end;

  TRVFuncType = (permanent = 0, momentary = 1);

  TRV = class
  private
    procedure DefaultData();

  public
    name: string;
    owner: string;
    designation: string;
    note: string;
    addr: Cardinal;
    typ: TRVType;
    train: string;
    siteA: TRVSite;
    functions: TRVFunkce;
    speedSteps: Cardinal;
    speedKmph: Cardinal;
    direction: Integer;
    token: string;
    orid: string; // id oblasti rizeni, ve ktere se nachazi loko
    maxSpeed: Cardinal;
    transience: Cardinal;
    multitrackCapable: Boolean;

    POMautomat: TList<TRVPomCV>; // seznam POM pri prevzeti do automatickeho rizeni
    POMmanual: TList<TRVPomCV>; // seznam POM pri prevzeti do rucniho rizeni
    POMrelease: TPomStatus;

    funcDesc: array [0 .. _MAX_FUNC] of string; // seznam popisu funkci hnaciho vozidla
    funcType: array [0 .. _MAX_FUNC] of TRVFuncType; // typy funkci hnaciho vozidla

    procedure ParseFromToken(data: string);
    procedure ParseData(data: string);
    constructor Create(data: string); overload;
    constructor Create(); overload;
    constructor CreateFromToken(data: string);
    destructor Destroy(); override;

    function GetPanelLokString(mode: TLokStringMode = normal): string;
    function NameStr(): string;

    class function CharToRVFuncType(c: char): TRVFuncType;
    class function RVFuncTypeToChar(t: TRVFuncType): char;
    class function AddrComparer(): IComparer<TRV>;
  end;

  TRVDb = class
  private
    RVs: TObjectList<TRV>;

    function GetItem(index: Integer): TRV;
    function GetCnt(): Integer;

  public

    constructor Create();
    destructor Destroy(); override;

    procedure ParseRVs(data: string);
    procedure ParseRVsFromToken(data: string);
    procedure Add(vehicle: TRV);
    procedure Delete(index: Integer);

    procedure Fill(var CB: TComboBox; var Indexes: TWordAr; addr: Integer = -1; special: TRV = nil;
      with_spr: boolean = false);
    procedure OpenJerry();

    procedure Sort();
    function GetEnumerator(): TEnumerator<TRV>;
    property Items[index: Integer]: TRV read GetItem; default;
    property Count: Integer read GetCnt;

  end;

implementation

uses GlobalConfig, fMain, TCPClientPanel, parseHelper, IfThenElse;

/// /////////////////////////////////////////////////////////////////////////////

constructor TRVDb.Create();
begin
  inherited;
  Self.RVs := TObjectList<TRV>.Create(TRV.AddrComparer);
end;

destructor TRVDb.Destroy();
begin
  Self.RVs.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRVDb.ParseRVs(data: string);
var str: TStrings;
begin
  str := TStringList.Create();
  try
    ExtractStringsEx([']'], ['['], data, str);
    Self.RVs.Clear();
    for var vehicle: string in str do
      Self.RVs.Add(TRV.Create(vehicle));
  finally
    str.Free();
  end;
end;

procedure TRVDb.ParseRVsFromToken(data: string);
var str: TStrings;
begin
  str := TStringList.Create();
  try
    ExtractStringsEx([']'], ['['], data, str);
    Self.RVs.Clear();
    for var vehicle: string in str do
      Self.RVs.Add(TRV.CreateFromToken(vehicle));
  finally
    str.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRVDb.Fill(var CB: TComboBox; var Indexes: TWordAr; addr: Integer = -1; special: TRV = nil;
  with_spr: boolean = false);
var index: Integer;
begin
  CB.Clear();

  if (Assigned(special)) then
  begin
    SetLength(Indexes, Self.RVs.Count + 1);
    CB.Items.Add(special.NameStr());
    Indexes[0] := special.addr;
    if (Integer(special.addr) = addr) then
      CB.ItemIndex := 0;
    index := 1;
  end else begin
    SetLength(Indexes, Self.RVs.Count);
    index := 0;
  end;

  for var i := 0 to Self.RVs.Count - 1 do
  begin
    if ((Self.RVs[i].train = '-') or (with_spr)) then
    begin
      CB.Items.Add(Self.RVs[i].NameStr());
      Indexes[index] := Self.RVs[i].addr;
      if (Integer(Self.RVs[i].addr) = addr) then
        CB.ItemIndex := i;
      index := index + 1;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TRV.Create(data: string);
begin
  inherited Create();
  Self.POMautomat := TList<TRVPomCV>.Create();
  Self.POMmanual := TList<TRVPomCV>.Create();
  Self.ParseData(data);
end;

constructor TRV.Create();
begin
  inherited;
  Self.POMautomat := TList<TRVPomCV>.Create();
  Self.POMmanual := TList<TRVPomCV>.Create();
end;

constructor TRV.CreateFromToken(data: string);
begin
  inherited Create();
  Self.ParseFromToken(data);
end;

destructor TRV.Destroy();
begin
  Self.POMautomat.Free();
  Self.POMmanual.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRV.ParseData(data: string);
var str, str2, str3: TStrings;
begin
  // format zapisu: nazev|majitel|oznaceni|poznamka|adresa|Typ|vlak|stanovisteA|funkce|rychlost_stupne|
  // rychlost_kmph|smer|or_id{[{cv1take|cv1take-value}][{...}]...}|{[{cv1release|cv1release-value}][{...}]...}|
  // {vyznam-F0;vyznam-F1;...}|typy_funkci|max rychlost

  // vlak je bud cislo vlaku, nebo znak '-'
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
    Self.typ := TRVType(StrToInt(str[5]));
    Self.train := str[6];
    Self.siteA := TRVSite(StrToInt(str[7]));

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
        var pomCv: TRVPomCV;
        pomCv.cv := StrToInt(str3[0]);
        pomCv.value := StrToInt(str3[1]);
        Self.POMautomat.Add(pomCv);
      end;

      // pom-release
      str2.Clear();
      ExtractStringsEx([']'], ['['], str[14], str2);
      for var tmp in str2 do
      begin
        str3.Clear();
        ExtractStringsEx(['|'], [], tmp, str3);
        var pomCv: TRVPomCV;
        pomCv.cv := StrToInt(str3[0]);
        pomCv.value := StrToInt(str3[1]);
        Self.POMmanual.Add(pomCv);
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
          Self.funcType[i] := CharToRVFuncType(str[16][i + 1])
        else
          Self.funcType[i] := TRVFuncType.permanent;
    end else begin
      for var i := 0 to _MAX_FUNC do
        Self.funcType[i] := TRVFuncType.permanent;
    end;

    if (str.Count > 17) then
      Self.maxSpeed := StrToInt(str[17]);

    if (str.Count > 18) then
      Self.transience := StrToInt(str[18]);

    if (str.Count > 19) then
    begin
      if (str[19] = 'automat') then
        Self.POMrelease := TPomStatus.automat
      else
        Self.POMrelease := TPomStatus.manual;
    end;

    if (str.Count > 20) then
      Self.multitrackCapable := StrToBool(str[20]);

  except

  end;

  str.Free();
  str2.Free();
  str3.Free();
end;

procedure TRV.ParseFromToken(data: string);
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

procedure TRV.DefaultData();
begin
  Self.name := '';
  Self.owner := '';
  Self.designation := '';
  Self.note := '';
  Self.addr := 0;
  Self.typ := TRVType.other;
  Self.train := '-';
  Self.maxSpeed := _DEFAULT_MAX_SPEED;
  Self.transience := 0;
  Self.multitrackCapable := True;
  Self.POMrelease := TPomStatus.manual;

  for var i := 0 to _MAX_FUNC do
    Self.functions[i] := false;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TRV.GetPanelLokString(mode: TLokStringMode = normal): string;
begin
  Result := Self.name + '|' + Self.owner + '|' + Self.designation + '|{' + Self.note + '}|' + IntToStr(Self.addr)
    + '|' + IntToStr(Integer(Self.typ)) + '|' + Self.train + '|' + IntToStr(Integer(Self.siteA)) + '|';

  for var i := 0 to _MAX_FUNC do
    Result := Result + BoolToStr10(Self.functions[i]);

  Result := Result + '||||' + Self.orid + '|';

  if (mode = full) then
  begin
    // cv-take
    Result := Result + '{';
    for var pomCv in Self.POMautomat do
      Result := Result + '[{' + IntToStr(pomCv.cv) + '|' + IntToStr(pomCv.value) + '}]';
    Result := Result + '}|{';

    // cv-release
    for var pomCv in Self.POMmanual do
      Result := Result + '[{' + IntToStr(pomCv.cv) + '|' + IntToStr(pomCv.value) + '}]';
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
    Result := Result + RVFuncTypeToChar(Self.funcType[i]);
  Result := Result + '|';

  Result := Result + IntToStr(Self.maxSpeed) + '|';
  Result := Result + IntToStr(Self.transience) + '|';
  Result := Result + ite(Self.POMrelease = TPomStatus.manual, 'manual', 'automat') + '|';
  Result := Result + BoolToStr10(Self.multitrackCapable) + '|';
end;

/// /////////////////////////////////////////////////////////////////////////////

// Otevreni regulatoru Jerry pro vsechna loko v seznamu
procedure TRVDb.OpenJerry();
var args: string;
begin
  // predame autoconnect, server a port
  args := '-a -s "' + GlobConfig.data.server.host + '" -pt ' + IntToStr(GlobConfig.data.server.port) + ' ';

  // predat uzivatele ?
  if ((GlobConfig.data.reg.reg_user) and (GlobConfig.data.auth.username <> '')) then
    args := args + '-u "' + GlobConfig.data.auth.username + '" -p "' + GlobConfig.data.auth.password + '" ';

  // kontrola tokenu
  for var vehicle in Self.RVs do
    if (vehicle.token = '') then
      raise Exception.Create('Vozidlo ' + IntToStr(vehicle.addr) + ' nema token');

  // predat vozidla
  for var vehicle in Self.RVs do
    args := args + IntToStr(vehicle.addr) + ':' + vehicle.token + ' ';

  // spustit regulator
  var f := ExpandFileName(GlobConfig.data.reg.reg_fn);
  var res := ShellExecute(F_Main.Handle, 'open', PChar(f), PChar(args), PChar(ExtractFilePath(GlobConfig.data.reg.reg_fn)),
    SW_SHOWNORMAL);
  if (res < 32) then
    raise Exception.Create('Nelze spustit regulator - chyba ' + IntToStr(res));
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRVDb.Add(vehicle: TRV);
begin
  Self.RVs.Add(vehicle);
  Self.RVs.Sort();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRVDb.Delete(index: Integer);
begin
  Self.RVs.Delete(index);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TRVDb.GetItem(index: Integer): TRV;
begin
  Result := Self.RVs[index];
end;

function TRVDb.GetEnumerator(): TEnumerator<TRV>;
begin
  Result := Self.RVs.GetEnumerator();
end;

function TRVDb.GetCnt(): Integer;
begin
  Result := Self.RVs.Count;
end;

procedure TRVDb.Sort();
begin
  Self.RVs.Sort();
end;

/// /////////////////////////////////////////////////////////////////////////////

class function TRV.CharToRVFuncType(c: char): TRVFuncType;
begin
  if (UpperCase(c) = 'M') then
    Result := TRVFuncType.momentary
  else
    Result := TRVFuncType.permanent;
end;

class function TRV.RVFuncTypeToChar(t: TRVFuncType): char;
begin
  if (t = TRVFuncType.momentary) then
    Result := 'M'
  else
    Result := 'P';
end;

/// /////////////////////////////////////////////////////////////////////////////

class function TRV.AddrComparer(): IComparer<TRV>;
begin
  Result := TComparer<TRV>.Construct(
    function(const Left, Right: TRV): Integer
    begin
      Result := CompareValue(Left.addr, Right.addr);
    end);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TRV.NameStr(): string;
begin
  Result := IntToStr(Self.addr) + ' : ' + Self.name;
  if (Self.designation <> '') then
    Result := Result + ' (' + Self.designation + ')';
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
