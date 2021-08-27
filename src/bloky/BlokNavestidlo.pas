unit BlokNavestidlo;

{
  Definice bloku navestidla, jeho vlastnosti a stavu v panelu.
  Definice databaze navestidel.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
  TNavPanelProp = record
    Symbol, Pozadi, Okoli: TColor;
    AB: Boolean;
    blikani: Boolean;

    procedure Change(data: TStrings);
  end;

  TPNavestidlo = class
    Blok: Integer;
    Position: TPoint;
    SymbolID: Integer;

    OblRizeni: Integer;
    PanelProp: TNavPanelProp;

    procedure Reset();
    procedure Show(obj: TDXDraw; blik: Boolean);
  end;

  TStartJC = record
    Pos: TPoint;
    Color: TColor;
  end;

  TPNavestidla = class
  private
    function GetItem(index: Integer): TPNavestidlo;
    function GetCount(): Integer;

  public
    data: TObjectList<TPNavestidlo>;
    startJC: TList<TStartJC>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile);
    procedure Show(obj: TDXDraw; blik: Boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    procedure UpdateStartJC();

    property Items[index: Integer]: TPNavestidlo read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Nav_Prop: TNavPanelProp = (Symbol: clBlack; Pozadi: clFuchsia; Okoli: clBlack; AB: false; blikani: false);

  _UA_Nav_Prop: TNavPanelProp = (Symbol: $A0A0A0; Pozadi: clBlack; Okoli: clBlack; AB: false; blikani: false);

implementation

uses PanelPainter, Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPNavestidlo.Reset();
begin
  if (Self.Blok > -2) then
    Self.PanelProp := _Def_Nav_Prop
  else
    Self.PanelProp := _UA_Nav_Prop;
end;

procedure TPNavestidlo.Show(obj: TDXDraw; blik: Boolean);
var fg: TColor;
begin
  if ((Self.PanelProp.blikani) and (blik)) then
    fg := clBlack
  else
    fg := Self.PanelProp.Symbol;

  if (Self.PanelProp.AB) then
  begin
    PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Position, _S_SIGNAL_B + Self.SymbolID + 2, fg,
      Self.PanelProp.Pozadi, obj);
  end else begin
    PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Position, _S_SIGNAL_B + Self.SymbolID, fg, Self.PanelProp.Pozadi, obj);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPNavestidla.Create();
begin
  inherited;
  Self.data := TObjectList<TPNavestidlo>.Create();
  Self.startJC := TList<TStartJC>.Create();
end;

destructor TPNavestidla.Destroy();
begin
  Self.data.Free();
  Self.startJC.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.Load(ini: TMemIniFile);
var i, Count: Integer;
  nav: TPNavestidlo;
begin
  Self.data.Clear();

  Count := ini.ReadInteger('P', 'N', 0);
  for i := 0 to Count - 1 do
  begin
    nav := TPNavestidlo.Create();

    nav.Blok := ini.ReadInteger('N' + IntToStr(i), 'B', -1);
    nav.Position.X := ini.ReadInteger('N' + IntToStr(i), 'X', 0);
    nav.Position.Y := ini.ReadInteger('N' + IntToStr(i), 'Y', 0);
    nav.SymbolID := ini.ReadInteger('N' + IntToStr(i), 'S', 0);

    // OR
    nav.OblRizeni := ini.ReadInteger('N' + IntToStr(i), 'OR', -1);

    // default settings:
    if (nav.Blok = -2) then
      nav.PanelProp := _UA_Nav_Prop
    else
      nav.PanelProp := _Def_Nav_Prop;

    Self.data.Add(nav);
  end; // for i
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.Show(obj: TDXDraw; blik: Boolean);
var nav: TPNavestidlo;
begin
  for nav in Self.data do
    nav.Show(obj, blik);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPNavestidla.GetIndex(Pos: TPoint): Integer;
var i: Integer;
begin
  Result := -1;

  for i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].Position.X) and (Pos.Y = Self.data[i].Position.Y)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.Reset(orindex: Integer = -1);
var nav: TPNavestidlo;
begin
  for nav in Self.data do
    if ((orindex < 0) or (nav.OblRizeni = orindex)) then
      nav.Reset();

  Self.startJC.Clear();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPNavestidla.GetItem(index: Integer): TPNavestidlo;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPNavestidla.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.UpdateStartJC();
var nav: TPNavestidlo;
  sjc: TStartJC;
begin
  Self.startJC.Clear();

  for nav in Self.data do
  begin
    if (nav.PanelProp.Okoli <> clBlack) then
    begin
      sjc.Color := nav.PanelProp.Okoli;
      sjc.Pos := Point(nav.Position.X - 1, nav.Position.Y);
      Self.startJC.Add(sjc);

      sjc.Color := nav.PanelProp.Okoli;
      sjc.Pos := Point(nav.Position.X + 1, nav.Position.Y);
      Self.startJC.Add(sjc);
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TNavPanelProp.Change(data: TStrings);
begin
  Symbol := StrToColor(data[4]);
  Pozadi := StrToColor(data[5]);
  blikani := StrToBool(data[6]);
  AB := StrToBool(data[7]);
  if (data.Count >= 9) then
    Okoli := StrToColor(data[8])
  else
    Okoli := clBlack;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
