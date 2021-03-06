unit BlokRozp;

{
  Definice bloku rozpojovac, jeho vlastnosti a stavu v panelu.
  Definice databaze rozpojovacu.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
  TRozpPanelProp = record
    Symbol, Pozadi: TColor;
    blik: boolean;

    procedure Change(parsed: TStrings);
  end;

  TPRozp = class
    Blok: Integer;
    Pos: TPoint;
    OblRizeni: Integer;
    PanelProp: TRozpPanelProp;

    procedure Show(obj: TDXDraw; blik: boolean);
    procedure ShowBg(obj: TDXDraw; blik: boolean);
    procedure Reset();
  end;

  TPRozpojovace = class
  private
    function GetItem(index: Integer): TPRozp;
    function GetCount(): Integer;

  public
    data: TObjectList<TPRozp>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile);
    procedure Show(obj: TDXDraw; blik: boolean);
    procedure ShowBg(obj: TDXDraw; blik: boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPRozp read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Rozp_Prop: TRozpPanelProp = (Symbol: clFuchsia; Pozadi: clBlack; blik: false;);

  _UA_Rozp_Prop: TRozpPanelProp = (Symbol: $A0A0A0; Pozadi: clBlack; blik: false;);

implementation

uses Symbols, PanelPainter, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPRozp.ShowBg(obj: TDXDraw; blik: boolean);
begin
  if (Self.PanelProp.Pozadi <> clBlack) then
  begin
    obj.Surface.Canvas.Pen.Color := Self.PanelProp.Pozadi;
    obj.Surface.Canvas.Brush.Color := Self.PanelProp.Pozadi;
    obj.Surface.Canvas.Rectangle(Self.Pos.X * SymbolSet._Symbol_Sirka, Self.Pos.Y * SymbolSet._Symbol_Vyska,
      (Self.Pos.X + 1) * SymbolSet._Symbol_Sirka, (Self.Pos.Y + 1) * SymbolSet._Symbol_Vyska);
  end;
end;

procedure TPRozp.Show(obj: TDXDraw; blik: boolean);
var fg: TColor;
begin
  if ((Self.PanelProp.blik) and (blik)) then
    fg := clBlack
  else
    fg := Self.PanelProp.Symbol;

  PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Pos, _Rozp_Start + 1, fg, Self.PanelProp.Pozadi, obj, true);
end;

procedure TPRozp.Reset();
begin
  if (Self.Blok > -2) then
    Self.PanelProp := _Def_Rozp_Prop
  else
    Self.PanelProp := _UA_Rozp_Prop;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPRozpojovace.Create();
begin
  inherited;
  Self.data := TObjectList<TPRozp>.Create();
end;

destructor TPRozpojovace.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPRozpojovace.Load(ini: TMemIniFile);
var Count, i: Integer;
  rozp: TPRozp;
begin
  Self.data.Clear();

  Count := ini.ReadInteger('P', 'R', 0);
  for i := 0 to Count - 1 do
  begin
    rozp := TPRozp.Create();

    rozp.Blok := ini.ReadInteger('R' + IntToStr(i), 'B', -1);
    rozp.OblRizeni := ini.ReadInteger('R' + IntToStr(i), 'OR', -1);
    rozp.Pos.X := ini.ReadInteger('R' + IntToStr(i), 'X', 0);
    rozp.Pos.Y := ini.ReadInteger('R' + IntToStr(i), 'Y', 0);

    // default settings:
    if (rozp.Blok = -2) then
      rozp.PanelProp := _UA_Rozp_Prop
    else
      rozp.PanelProp := _Def_Rozp_Prop;

    Self.data.Add(rozp);
  end; // for i
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPRozpojovace.Show(obj: TDXDraw; blik: boolean);
var rozp: TPRozp;
begin
  for rozp in Self.data do
    rozp.Show(obj, blik);
end;

procedure TPRozpojovace.ShowBg(obj: TDXDraw; blik: boolean);
var rozp: TPRozp;
begin
  for rozp in Self.data do
    rozp.ShowBg(obj, blik);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPRozpojovace.GetIndex(Pos: TPoint): Integer;
var i: Integer;
begin
  Result := -1;

  for i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].Pos.X) and (Pos.Y = Self.data[i].Pos.Y)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPRozpojovace.Reset(orindex: Integer = -1);
var rozp: TPRozp;
begin
  for rozp in Self.data do
    if ((orindex < 0) or (rozp.OblRizeni = orindex)) then
      rozp.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPRozpojovace.GetItem(index: Integer): TPRozp;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPRozpojovace.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRozpPanelProp.Change(parsed: TStrings);
begin
  Symbol := StrToColor(parsed[4]);
  Pozadi := StrToColor(parsed[5]);
  blik := StrToBool(parsed[6]);
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
