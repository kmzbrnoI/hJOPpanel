unit BlokPomocny;

{
  "Other" block definition.
  Definition of database of "other" blocks.
  "Other" blocks are blocks showed in pane which are not any other blocks.
  These are usually platforms etc. "Other" block could be connected to technological
  blocks in server.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
  TPOtherPanelProp = record
    symbol, bg: TColor;
    flash: boolean;

    procedure Change(parsed: TStrings);
  end;

  TPObjOther = class
    block: Integer;
    area: Integer;
    positions: TList<TPoint>;
    symbol: Integer;
    panelProp: TPOtherPanelProp;

    constructor Create();
    destructor Destroy(); override;
    procedure Show(obj: TDXDraw; blik: boolean);
    procedure Reset();
  end;

  TPObjOthers = class
  private
    function GetItem(index: Integer): TPObjOther;
    function GetCount(): Integer;

  public
    data: TObjectList<TPObjOther>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPObjOther read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Helper_Prop: TPOtherPanelProp = (Symbol: $A0A0A0; bg: clBlack; flash: false;);
  _Assigned_Helper_Prop: TPOtherPanelProp = (Symbol: clFuchsia; bg: clBlack; flash: false;);

implementation

uses Symbols, parseHelper, Panel;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPObjOther.Create();
begin
  inherited;
  Self.positions := TList<TPoint>.Create();
end;

destructor TPObjOther.Destroy();
begin
  Self.positions.Free();
  inherited;
end;

procedure TPObjOther.Show(obj: TDXDraw; blik: boolean);
var color: TColor;
begin
  if (Self.block > -1) then
    color := Self.PanelProp.Symbol
  else
    color := SymbolDefaultColor(Self.Symbol);

  if ((Self.PanelProp.flash) and (blik)) then
    color := clBlack;

  for var pos in Self.Positions do
    Symbols.Draw(SymbolSet.IL_Symbols, pos, Self.Symbol, color, Self.PanelProp.bg, obj);
end;

procedure TPObjOther.Reset();
begin
  if (Self.block > -1) then
    Self.PanelProp := _Assigned_Helper_Prop
  else
    Self.PanelProp := _Def_Helper_Prop;
end;

procedure TPOtherPanelProp.Change(parsed: TStrings);
begin
  symbol := StrToColor(parsed[4]);
  bg := StrToColor(parsed[5]);
  flash := StrToBool(parsed[6]);
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPObjOthers.Create();
begin
  inherited;
  Self.data := TObjectList<TPObjOther>.Create();
end;

destructor TPObjOthers.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPObjOthers.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'P', 0);
  for var i := 0 to Count - 1 do
  begin
    var po := TPObjOther.Create();

    po.block := ini.ReadInteger('P' + IntToStr(i), 'B', -1);
    po.area := ini.ReadInteger('P' + IntToStr(i), 'OR', -1);
    po.Symbol := ini.ReadInteger('P' + IntToStr(i), 'S', 0);
    if (version < _FILEVERSION_20) then
      po.Symbol := TranscodeSymbolFromBpnlV3(po.Symbol);

    po.Positions := TList<TPoint>.Create();

    var obj := ini.ReadString('P' + IntToStr(i), 'P', '');
    var count2 := (Length(obj) div 6);
    for var j := 0 to count2 - 1 do
      po.Positions.Add(Point(StrToIntDef(copy(obj, j * 6 + 1, 3), 0), StrToIntDef(copy(obj, j * 6 + 4, 3), 0)));
    po.Reset();

    Self.data.Add(po);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPObjOthers.Show(obj: TDXDraw; blik: boolean);
begin
  for var po in Self.data do
    po.Show(obj, blik);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPObjOthers.Reset(orindex: Integer = -1);
begin
  for var pomocny in Self.data do
    if ((orindex < 0) or (pomocny.area = orindex)) then
      pomocny.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPObjOthers.GetItem(index: Integer): TPObjOther;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPObjOthers.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPObjOthers.GetIndex(pos: TPoint): Integer;
begin
  Result := -1;

  for var i := 0 to Self.data.Count - 1 do
  begin
    if (Self[i].block > -1) then
      for var helperPos in Self[i].Positions do
        if ((pos.X = helperPos.X) and (pos.Y = helperPos.Y)) then
          Exit(i);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
