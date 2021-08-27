unit BlokUvazkaSpr;

{
  Definice bloku uvazka-spr, jeho vlastnosti a stavu v panelu.
  Definice databaze bloku typu uvazka-spr.
  Uvazka-spr je seznam souprav u uvazky.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
  TPUvazkaID = record
    index: Integer;
    soupravaI: Integer;
  end;

  TUvazkaSpr = class
    strings: TStrings;
    show_index: Integer;
    time: string;
    time_color: TColor;
    color: TColor;

    constructor Create();
    destructor Destroy(); override;
  end;

  TUvazkaSprPanelProp = class
    spr: TObjectList<TUvazkaSpr>;

    constructor Create();
    destructor Destroy(); override;
    procedure Change(parsed: TStrings);
  end;

  TUvazkaSprVertDir = (top = 0, bottom = 1);

  TPUvazkaSpr = class
    Blok: Integer;
    Pos: TPoint;
    vertical_dir: TUvazkaSprVertDir;
    spr_cnt: Integer;
    OblRizeni: Integer;
    PanelProp: TUvazkaSprPanelProp;

    constructor Create();
    destructor Destroy(); override;
  end;

  TPUvazkySpr = class
  private
    change_time: TDateTime;

    function GetItem(index: Integer): TPUvazkaSpr;
    function GetCount(): Integer;

  public
    data: TObjectList<TPUvazkaSpr>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw);
    function GetIndex(Pos: TPoint): TPUvazkaID;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPUvazkaSpr read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _UVAZKY_BLIK_PERIOD = 1500; // perioda blikani soupravy u uvazky v ms
  _UVAZKY_WIDTH = 9;

implementation

uses Symbols, parseHelper, StrUtils, TCPClientPanel;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPUvazkaSpr.Create();
begin
  inherited;
  Self.PanelProp := TUvazkaSprPanelProp.Create();
end;

destructor TPUvazkaSpr.Destroy();
begin
  Self.PanelProp.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TUvazkaSprPanelProp.Create();
begin
  inherited;
  Self.spr := TObjectList<TUvazkaSpr>.Create();
end;

destructor TUvazkaSprPanelProp.Destroy();
begin
  Self.spr.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TUvazkaSpr.Create();
begin
  inherited;
  Self.strings := TStringList.Create();
end;

destructor TUvazkaSpr.Destroy();
begin
  Self.strings.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPUvazkySpr.Create();
begin
  inherited;
  Self.data := TObjectList<TPUvazkaSpr>.Create();
  Self.change_time := Now;
end;

destructor TPUvazkySpr.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Load(ini: TMemIniFile; version: Word);
var i, Count: Integer;
  uvs: TPUvazkaSpr;
begin
  Self.data.Clear();

  Count := ini.ReadInteger('P', 'UvS', 0);
  for i := 0 to Count - 1 do
  begin
    uvs := TPUvazkaSpr.Create();

    uvs.Blok := ini.ReadInteger('UvS' + IntToStr(i), 'B', -1);
    uvs.OblRizeni := ini.ReadInteger('UvS' + IntToStr(i), 'OR', -1);
    uvs.Pos.X := ini.ReadInteger('UvS' + IntToStr(i), 'X', 0);
    uvs.Pos.Y := ini.ReadInteger('UvS' + IntToStr(i), 'Y', 0);
    uvs.vertical_dir := TUvazkaSprVertDir(ini.ReadInteger('UvS' + IntToStr(i), 'VD', 0));
    uvs.spr_cnt := ini.ReadInteger('UvS' + IntToStr(i), 'C', 1);
    uvs.PanelProp := TUvazkaSprPanelProp.Create();
    uvs.PanelProp.spr := TObjectList<TUvazkaSpr>.Create();

    Self.data.Add(uvs);
  end; // for i
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Show(obj: TDXDraw);
var top, incr: Integer;
  Change: boolean;
  UvazkaSpr: TUvazkaSpr;
  uvs: TPUvazkaSpr;
begin
  if (Now > change_time) then
  begin
    change_time := Now + EncodeTime(0, 0, _UVAZKY_BLIK_PERIOD div 1000, _UVAZKY_BLIK_PERIOD mod 1000);
    Change := true;
  end
  else
    Change := false;

  for uvs in Self.data do
  begin
    if (not Assigned(uvs.PanelProp.spr)) then
      continue;

    top := uvs.Pos.Y;
    if (uvs.vertical_dir = TUvazkaSprVertDir.top) then
      incr := -1
    else
      incr := 1;

    for UvazkaSpr in uvs.PanelProp.spr do
    begin
      if (not Assigned(UvazkaSpr.strings)) then
        continue;

      // kontrola preblikavani
      if ((Change) and (UvazkaSpr.strings.Count > 1)) then
        Inc(UvazkaSpr.show_index);
      if (UvazkaSpr.show_index >= UvazkaSpr.strings.Count) then // tato podminka musi byt vne predchozi podminky
        UvazkaSpr.show_index := 0;

      Symbols.TextOutput(Point(uvs.Pos.X, top), UvazkaSpr.strings[UvazkaSpr.show_index], UvazkaSpr.color, clBlack,
        obj, UvazkaSpr.show_index = 0);

      if (UvazkaSpr.show_index = 0) then
        Symbols.TextOutput(Point(uvs.Pos.X + 7, top), UvazkaSpr.time, UvazkaSpr.time_color, clBlack, obj);

      top := top + incr;
    end; // for j
  end; // for i
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Reset(orindex: Integer = -1);
var uvs: TPUvazkaSpr;
begin
  for uvs in Self.data do
    if (((orindex < 0) or (uvs.OblRizeni = orindex)) and (uvs.Blok > -2)) then
      uvs.PanelProp.spr.Clear();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPUvazkySpr.GetItem(index: Integer): TPUvazkaSpr;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPUvazkySpr.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPUvazkySpr.GetIndex(Pos: TPoint): TPUvazkaID;
var i, spr_index, incr, top: Integer;
  uvs: TPUvazkaSpr;
begin
  Result.index := -1;

  for i := 0 to Self.data.Count - 1 do
  begin
    uvs := Self.data[i];

    if ((Pos.X < uvs.Pos.X) or (Pos.X >= uvs.Pos.X + _UVAZKY_WIDTH)) then
      continue;

    top := uvs.Pos.Y;
    if (uvs.vertical_dir = TUvazkaSprVertDir.top) then
      incr := -1
    else
      incr := 1;

    for spr_index := 0 to uvs.PanelProp.spr.Count - 1 do
    begin
      if (Pos.Y = top) then
      begin
        Result.index := i;
        Result.soupravaI := spr_index;
        Exit();
      end;
      top := top + incr;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TUvazkaSprPanelProp.Change(parsed: TStrings);
var j: Integer;
  sprs_data: TStrings;
  str: string;
  UvazkaSpr: TUvazkaSpr;
  new_version: boolean;
begin
  if (parsed.Count < 9) then
    Exit();

  new_version := PanelTCPClient.IsServerVersionAtLeast('1.1');
  Self.spr.Clear();
  sprs_data := TStringList.Create();

  try
    ExtractStringsEx([','], [], parsed[8], sprs_data);

    for str in sprs_data do
    begin
      UvazkaSpr := TUvazkaSpr.Create();

      ExtractStringsEx(['|'], [], str, UvazkaSpr.strings);
      if (LeftStr(str, 1) = '$') then
      begin
        UvazkaSpr.strings[0] := RightStr(UvazkaSpr.strings[0], Length(UvazkaSpr.strings[0]) - 1);
        UvazkaSpr.color := clYellow;
      end else begin
        if (new_version) then
        begin
          UvazkaSpr.color := StrToColor(UvazkaSpr.strings[1]);
          UvazkaSpr.strings.Delete(1);
        end
        else
          UvazkaSpr.color := clWhite;
      end;

      if (LeftStr(UvazkaSpr.strings[1], 1) = '$') then
      begin
        UvazkaSpr.time := RightStr(UvazkaSpr.strings[1], Length(UvazkaSpr.strings[1]) - 1);
        UvazkaSpr.time_color := clYellow;
      end else begin
        UvazkaSpr.time := UvazkaSpr.strings[1];
        if (new_version) then
        begin
          UvazkaSpr.time_color := StrToColor(UvazkaSpr.strings[2]);
          UvazkaSpr.strings.Delete(2);
        end
        else
          UvazkaSpr.time_color := clAqua;
      end;

      UvazkaSpr.strings.Delete(1);

      // kontrola preteceni textu
      for j := 0 to UvazkaSpr.strings.Count - 1 do
        if (Length(UvazkaSpr.strings[j]) > _UVAZKY_WIDTH) then
          UvazkaSpr.strings[j] := LeftStr(UvazkaSpr.strings[j], 8) + '.';

      Self.spr.Add(UvazkaSpr);
    end;
  finally
    sprs_data.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
