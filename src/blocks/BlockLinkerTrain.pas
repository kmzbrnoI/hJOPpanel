unit BlockLinkerTrain;

{
  Definice bloku uvazka-spr, jeho vlastnosti a stavu v panelu.
  Definice databaze bloku typu uvazka-spr.
  Uvazka-spr je seznam souprav u uvazky.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
  TPLinkerId = record
    index: Integer;
    traini: Integer;
  end;

  TLinkerTrain = class
    strings: TStrings;
    show_index: Integer;
    time: string;
    time_color: TColor;
    color: TColor;

    constructor Create();
    destructor Destroy(); override;
  end;

  TLinkerTrainPanelProp = class
    train: TObjectList<TLinkerTrain>;

    constructor Create();
    destructor Destroy(); override;
    procedure Change(parsed: TStrings);
  end;

  TUvazkaSprVertDir = (top = 0, bottom = 1);

  TPLinkerTrain = class
    block: Integer;
    pos: TPoint;
    vertical_dir: TUvazkaSprVertDir;
    spr_cnt: Integer;
    area: Integer;
    panelProp: TLinkerTrainPanelProp;

    constructor Create();
    destructor Destroy(); override;
  end;

  TPLinkersTrain = class
  private
    change_time: TDateTime;

    function GetItem(index: Integer): TPLinkerTrain;
    function GetCount(): Integer;

  public
    data: TObjectList<TPLinkerTrain>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw);
    function GetIndex(Pos: TPoint): TPLinkerId;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPLinkerTrain read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _LINKER_FLASH_PERIOD = 1500; // perioda blikani soupravy u uvazky v ms
  _LINKER_WIDTH = 9;

implementation

uses Symbols, parseHelper, StrUtils, TCPClientPanel;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPLinkerTrain.Create();
begin
  inherited;
  Self.panelProp := TLinkerTrainPanelProp.Create();
end;

destructor TPLinkerTrain.Destroy();
begin
  Self.panelProp.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TLinkerTrainPanelProp.Create();
begin
  inherited;
  Self.train := TObjectList<TLinkerTrain>.Create();
end;

destructor TLinkerTrainPanelProp.Destroy();
begin
  Self.train.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TLinkerTrain.Create();
begin
  inherited;
  Self.strings := TStringList.Create();
end;

destructor TLinkerTrain.Destroy();
begin
  Self.strings.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPLinkersTrain.Create();
begin
  inherited;
  Self.data := TObjectList<TPLinkerTrain>.Create();
  Self.change_time := Now;
end;

destructor TPLinkersTrain.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLinkersTrain.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'UvS', 0);
  for var i := 0 to count - 1 do
  begin
    var lt := TPLinkerTrain.Create();

    lt.block := ini.ReadInteger('UvS' + IntToStr(i), 'B', -1);
    lt.area := ini.ReadInteger('UvS' + IntToStr(i), 'OR', -1);
    lt.pos.X := ini.ReadInteger('UvS' + IntToStr(i), 'X', 0);
    lt.pos.Y := ini.ReadInteger('UvS' + IntToStr(i), 'Y', 0);
    lt.vertical_dir := TUvazkaSprVertDir(ini.ReadInteger('UvS' + IntToStr(i), 'VD', 0));
    lt.spr_cnt := ini.ReadInteger('UvS' + IntToStr(i), 'C', 1);
    lt.panelProp := TLinkerTrainPanelProp.Create();
    lt.panelProp.train := TObjectList<TLinkerTrain>.Create();

    Self.data.Add(lt);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLinkersTrain.Show(obj: TDXDraw);
var change: Boolean;
begin
  if (Now > change_time) then
  begin
    change_time := Now + EncodeTime(0, 0, _LINKER_FLASH_PERIOD div 1000, _LINKER_FLASH_PERIOD mod 1000);
    change := true;
  end
  else
    change := false;

  for var uvs in Self.data do
  begin
    if (not Assigned(uvs.panelProp.train)) then
      continue;

    var top := uvs.pos.Y;
    var incr: Integer;
    if (uvs.vertical_dir = TUvazkaSprVertDir.top) then
      incr := -1
    else
      incr := 1;

    for var linkerTrain in uvs.panelProp.train do
    begin
      if (not Assigned(linkerTrain.strings)) then
        continue;

      // kontrola preblikavani
      if ((Change) and (linkerTrain.strings.Count > 1)) then
        Inc(linkerTrain.show_index);
      if (linkerTrain.show_index >= linkerTrain.strings.Count) then // tato podminka musi byt vne predchozi podminky
        linkerTrain.show_index := 0;

      Symbols.TextOutput(Point(uvs.pos.X, top), linkerTrain.strings[linkerTrain.show_index], linkerTrain.color, clBlack,
        obj, linkerTrain.show_index = 0);

      if (linkerTrain.show_index = 0) then
        Symbols.TextOutput(Point(uvs.pos.X + 7, top), linkerTrain.time, linkerTrain.time_color, clBlack, obj);

      top := top + incr;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLinkersTrain.Reset(orindex: Integer = -1);
begin
  for var lt in Self.data do
    if (((orindex < 0) or (lt.area = orindex)) and (lt.block > -2)) then
      lt.panelProp.train.Clear();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLinkersTrain.GetItem(index: Integer): TPLinkerTrain;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLinkersTrain.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLinkersTrain.GetIndex(Pos: TPoint): TPLinkerId;
begin
  Result.index := -1;

  for var i := 0 to Self.data.Count - 1 do
  begin
    var lt := Self.data[i];

    if ((Pos.X < lt.pos.X) or (Pos.X >= lt.pos.X + _LINKER_WIDTH)) then
      continue;

    var incr: Integer;
    var top := lt.pos.Y;
    if (lt.vertical_dir = TUvazkaSprVertDir.top) then
      incr := -1
    else
      incr := 1;

    for var spr_index := 0 to lt.panelProp.train.Count - 1 do
    begin
      if (Pos.Y = top) then
      begin
        Result.index := i;
        Result.traini := spr_index;
        Exit();
      end;
      top := top + incr;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TLinkerTrainPanelProp.Change(parsed: TStrings);
begin
  if (parsed.Count < 9) then
    Exit();

  var new_version := PanelTCPClient.IsServerVersionAtLeast('1.1');
  Self.train.Clear();
  var sprs_data: TStrings := TStringList.Create();

  try
    ExtractStringsEx([','], [], parsed[8], sprs_data);

    for var str in sprs_data do
    begin
      var lt := TLinkerTrain.Create();

      ExtractStringsEx(['|'], [], str, lt.strings);
      if (LeftStr(str, 1) = '$') then
      begin
        lt.strings[0] := RightStr(lt.strings[0], Length(lt.strings[0]) - 1);
        lt.color := clYellow;
      end else begin
        if (new_version) then
        begin
          lt.color := StrToColor(lt.strings[1]);
          lt.strings.Delete(1);
        end
        else
          lt.color := clWhite;
      end;

      if (LeftStr(lt.strings[1], 1) = '$') then
      begin
        lt.time := RightStr(lt.strings[1], Length(lt.strings[1]) - 1);
        lt.time_color := clYellow;
      end else begin
        lt.time := lt.strings[1];
        if (new_version) then
        begin
          lt.time_color := StrToColor(lt.strings[2]);
          lt.strings.Delete(2);
        end
        else
          lt.time_color := clAqua;
      end;

      lt.strings.Delete(1);

      // kontrola preteceni textu
      for var j := 0 to lt.strings.Count - 1 do
        if (Length(lt.strings[j]) > _LINKER_WIDTH) then
          lt.strings[j] := LeftStr(lt.strings[j], 8) + '.';

      Self.train.Add(lt);
    end;
  finally
    sprs_data.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
