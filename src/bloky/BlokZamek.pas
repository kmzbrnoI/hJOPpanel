unit BlokZamek;

{
  Definice bloku usek, jeho vlastnosti a stavu v panelu.
  Definice databaze bloku typu zamek.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
  TZamekPanelProp = record
    Symbol, Pozadi: TColor;
    blik: boolean;

    procedure Change(parsed: TStrings);
  end;

  TPZamek = class
    Blok: Integer;
    Pos: TPoint;
    OblRizeni: Integer;
    PanelProp: TZamekPanelProp;

    procedure Reset();
  end;

  TPZamky = class
  private
    function GetItem(index: Integer): TPZamek;
    function GetCount(): Integer;

  public
    data: TObjectList<TPZamek>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile);
    procedure Show(obj: TDXDraw; blik: boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPZamek read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Zamek_Prop: TZamekPanelProp = (Symbol: clBlack; Pozadi: clFuchsia; blik: false;);

  _UA_Zamek_Prop: TZamekPanelProp = (Symbol: $A0A0A0; Pozadi: clBlack; blik: false;);

implementation

uses PanelPainter, Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPZamek.Reset();
begin
  if (Self.Blok > -2) then
    Self.PanelProp := _Def_Zamek_Prop
  else
    Self.PanelProp := _UA_Zamek_Prop;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPZamky.Create();
begin
  inherited;
  Self.data := TObjectList<TPZamek>.Create();
end;

destructor TPZamky.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPZamky.Load(ini: TMemIniFile);
var i, Count: Integer;
  zam: TPZamek;
begin
  Self.data.Clear();

  Count := ini.ReadInteger('P', 'Z', 0);
  for i := 0 to Count - 1 do
  begin
    zam := TPZamek.Create();

    zam.Blok := ini.ReadInteger('Z' + IntToStr(i), 'B', -1);
    zam.OblRizeni := ini.ReadInteger('Z' + IntToStr(i), 'OR', -1);
    zam.Pos.X := ini.ReadInteger('Z' + IntToStr(i), 'X', 0);
    zam.Pos.Y := ini.ReadInteger('Z' + IntToStr(i), 'Y', 0);

    // default settings:
    if (zam.Blok = -2) then
      zam.PanelProp := _UA_Zamek_Prop
    else
      zam.PanelProp := _Def_Zamek_Prop;

    Self.data.Add(zam);
  end; // for i
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPZamky.Show(obj: TDXDraw; blik: boolean);
var fg: TColor;
  zam: TPZamek;
begin
  for zam in Self.data do
  begin
    if ((zam.PanelProp.blik) and (blik)) then
      fg := clBlack
    else
      fg := zam.PanelProp.Symbol;

    PanelPainter.Draw(SymbolSet.IL_Symbols, zam.Pos, _S_LOCK, fg, zam.PanelProp.Pozadi, obj);
  end; // for i
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPZamky.GetIndex(Pos: TPoint): Integer;
var i: Integer;
begin
  Result := -1;

  for i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].Pos.X) and (Pos.Y = Self.data[i].Pos.Y)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPZamky.Reset(orindex: Integer = -1);
var zamek: TPZamek;
begin
  for zamek in Self.data do
    if ((orindex < 0) or (zamek.OblRizeni = orindex)) then
      zamek.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPZamky.GetItem(index: Integer): TPZamek;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPZamky.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TZamekPanelProp.Change(parsed: TStrings);
begin
  Symbol := StrToColor(parsed[4]);
  Pozadi := StrToColor(parsed[5]);
  blik := StrToBool(parsed[6]);
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
