unit BlockDisconnector;

{
  Definition of a disconnector block.
  Definition of a disconnector blocks database.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  BlockTypes;

type
  TPDisconnector = class
    block: Integer;
    pos: TPoint;
    area: Integer;
    panelProp: TGeneralPanelProp;

    procedure Show(obj: TDXDraw; blik: boolean);
    procedure ShowBg(obj: TDXDraw; blik: boolean);
    procedure Reset();
  end;

  TPDisconnectors = class
  private
    function GetItem(index: Integer): TPDisconnector;
    function GetCount(): Integer;

  public
    data: TObjectList<TPDisconnector>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean);
    procedure ShowBg(obj: TDXDraw; blik: boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPDisconnector read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Disc_Prop: TGeneralPanelProp = (fg: clFuchsia; bg: clBlack; flash: false;);
  _UA_Disc_Prop: TGeneralPanelProp = (fg: $A0A0A0; bg: clBlack; flash: false;);

implementation

uses Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPDisconnector.ShowBg(obj: TDXDraw; blik: boolean);
begin
  if (Self.PanelProp.bg <> clBlack) then
  begin
    obj.Surface.Canvas.Pen.Color := Self.PanelProp.bg;
    obj.Surface.Canvas.Brush.Color := Self.PanelProp.bg;
    obj.Surface.Canvas.Rectangle(Self.Pos.X * SymbolSet.symbWidth, Self.Pos.Y * SymbolSet.symbHeight,
      (Self.Pos.X + 1) * SymbolSet.symbWidth, (Self.Pos.Y + 1) * SymbolSet.symbHeight);
  end;
end;

procedure TPDisconnector.Show(obj: TDXDraw; blik: boolean);
var fg: TColor;
begin
  if ((Self.PanelProp.flash) and (blik)) then
    fg := clBlack
  else
    fg := Self.PanelProp.fg;

  Symbols.Draw(SymbolSet.IL_Symbols, Self.Pos, _S_DISC_ALONE, fg, Self.PanelProp.bg, obj, true);
end;

procedure TPDisconnector.Reset();
begin
  if (Self.block > -2) then
    Self.panelProp := _Def_Disc_Prop
  else
    Self.panelProp := _UA_Disc_Prop;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPDisconnectors.Create();
begin
  inherited;
  Self.data := TObjectList<TPDisconnector>.Create();
end;

destructor TPDisconnectors.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPDisconnectors.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'R', 0);
  for var i := 0 to Count - 1 do
  begin
    var disc := TPDisconnector.Create();

    disc.block := ini.ReadInteger('R' + IntToStr(i), 'B', -1);
    disc.area := ini.ReadInteger('R' + IntToStr(i), 'OR', -1);
    disc.pos.X := ini.ReadInteger('R' + IntToStr(i), 'X', 0);
    disc.pos.Y := ini.ReadInteger('R' + IntToStr(i), 'Y', 0);

    if (disc.block = -2) then
      disc.panelProp := _UA_Disc_Prop
    else
      disc.panelProp := _Def_Disc_Prop;

    Self.data.Add(disc);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPDisconnectors.Show(obj: TDXDraw; blik: boolean);
begin
  for var disc in Self.data do
    disc.Show(obj, blik);
end;

procedure TPDisconnectors.ShowBg(obj: TDXDraw; blik: boolean);
begin
  for var disc in Self.data do
    disc.ShowBg(obj, blik);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPDisconnectors.GetIndex(Pos: TPoint): Integer;
begin
  Result := -1;

  for var i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].Pos.X) and (Pos.Y = Self.data[i].Pos.Y)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPDisconnectors.Reset(orindex: Integer = -1);
begin
  for var disc in Self.data do
    if ((orindex < 0) or (disc.area = orindex)) then
      disc.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPDisconnectors.GetItem(index: Integer): TPDisconnector;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPDisconnectors.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
