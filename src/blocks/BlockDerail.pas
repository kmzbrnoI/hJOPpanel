unit BlockDerail;

{
  Definition of a "derial" block.
  Definition of a databse of derails.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  BlockTurnout, BlockTrack;

type
  TPDerail = class
    block: Integer;
    pos: TPoint;
    area: Integer;
    panelProp: TTurnoutPanelProp;

    symbol: Integer;
    track: Integer; // index useku, na kterem je vykolejka
    branch: Integer; // cislo vetve, ve kterem je vykolejka
  end;

  TPDerails = class
  private
    function GetItem(index: Integer): TPDerail;
    function GetCount(): Integer;

  public
    data: TObjectList<TPDerail>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(area: Integer = -1);

    property Items[index: Integer]: TPDerail read GetItem; default;
    property Count: Integer read GetCount;
  end;

implementation

uses Symbols;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPDerails.Create();
begin
  inherited;
  Self.data := TObjectList<TPDerail>.Create();
end;

destructor TPDerails.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPDerails.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'Vyk', 0);
  for var i := 0 to count - 1 do
  begin
    var derail := TPDerail.Create();

    derail.block := ini.ReadInteger('Vyk' + IntToStr(i), 'B', -1);
    derail.area := ini.ReadInteger('Vyk' + IntToStr(i), 'OR', -1);
    derail.pos.X := ini.ReadInteger('Vyk' + IntToStr(i), 'X', 0);
    derail.pos.Y := ini.ReadInteger('Vyk' + IntToStr(i), 'Y', 0);
    derail.track := ini.ReadInteger('Vyk' + IntToStr(i), 'O', -1);
    derail.branch := ini.ReadInteger('Vyk' + IntToStr(i), 'V', -1);
    derail.symbol := ini.ReadInteger('Vyk' + IntToStr(i), 'T', 0);

    // default settings:
    if (derail.block = -2) then
      derail.panelProp := _UA_TURNOUT_PROP
    else
      derail.panelProp := _DEF_TURNOUT_PROP;

    Self.data.Add(derail);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPDerails.Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
begin
  for var derail in Self.data do
  begin
    var visible := ((derail.PanelProp.position = TVyhPoloha.disabled) or (derail.branch < 0) or (derail.track < 0) or (derail.track >= useky.Count) or
      (derail.branch >= useky[derail.track].branches.Count) or (useky[derail.track].branches[derail.branch].visible));

    var fg: TColor;
    if ((derail.PanelProp.flash) and (blik) and (visible)) then
      fg := clBlack
    else
    begin
      if ((visible) or (derail.PanelProp.fg = clAqua) or (derail.track < 0) or (derail.track >= useky.Count)) then
        fg := derail.PanelProp.fg
      else
        fg := useky[derail.track].panelProp.notColorBranches;
    end;

    var bkcol: TColor;
    if ((derail.PanelProp.bg = clBlack) and (derail.track > -1) and (derail.track < useky.Count)) then
      bkcol := useky[derail.track].panelProp.bg
    else
      bkcol := derail.PanelProp.bg;

    case (derail.PanelProp.position) of
      TVyhPoloha.disabled:
        if ((derail.track > -1) and (derail.track < useky.Count)) then
          Symbols.Draw(SymbolSet.IL_Symbols, derail.Pos, _S_DERAIL_B + derail.symbol,
            useky[derail.track].panelProp.bg, clFuchsia, obj);
      TVyhPoloha.none:
        Symbols.Draw(SymbolSet.IL_Symbols, derail.Pos, _S_DERAIL_B + derail.symbol, bkcol, fg, obj);
      TVyhPoloha.plus:
        Symbols.Draw(SymbolSet.IL_Symbols, derail.Pos, _S_DERAIL_B + derail.symbol, fg, bkcol, obj);
      TVyhPoloha.minus:
        Symbols.Draw(SymbolSet.IL_Symbols, derail.Pos, _S_DERAIL_B + derail.symbol + 2, fg, bkcol, obj);
      TVyhPoloha.both:
        Symbols.Draw(SymbolSet.IL_Symbols, derail.Pos, _S_DERAIL_B + derail.symbol, bkcol, clBlue, obj);
    end;
  end; // for i
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPDerails.GetIndex(Pos: TPoint): Integer;
var i: Integer;
begin
  for i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].Pos.X) and (Pos.Y = Self.data[i].Pos.Y)) then
      Exit(i);

  Result := -1;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPDerails.Reset(area: Integer = -1);
begin
  for var derail in Self.data do
  begin
    if ((area < 0) or (derail.area = area)) then
    begin
      if (derail.block > -2) then
        derail.panelProp := _DEF_TURNOUT_PROP
      else
        derail.panelProp := _UA_TURNOUT_PROP;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPDerails.GetItem(index: Integer): TPDerail;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPDerails.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
