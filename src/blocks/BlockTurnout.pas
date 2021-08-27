unit BlockTurnout;

{
  Turnout block definition.
}

interface

uses Classes, Graphics, Types, SysUtils, DXDraws, Generics.Collections, BlockTrack;

type
  TVyhPoloha = (disabled = -5, none = -1, plus = 0, minus = 1, both = 2);

  TTurnoutPanelProp = record
    flash: boolean;
    fg, bg: TColor;
    position: TVyhPoloha;

    procedure Change(parsed: TStrings);
  end;

  TPTurnout = class
    block: Integer;
    orientationPlus: Cardinal;
    position: TPoint;
    symbolID: Integer;
    obj: Integer;

    area: Integer;
    panelProp: TTurnoutPanelProp;
    visible: boolean; // na zaklade viditelnosti ve vetvich je rekonstruovana viditelnost vyhybky

    procedure Reset();
    procedure Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
  end;

const
  _DEF_TURNOUT_PROP: TTurnoutPanelProp = (flash: false; fg: clFuchsia; bg: clBlack; position: TVyhPoloha.disabled);
  _UA_TURNOUT_PROP: TTurnoutPanelProp = (flash: false; fg: $A0A0A0; bg: clBlack; position: TVyhPoloha.both);

implementation

uses parseHelper, Symbols;

/// /////////////////////////////////////////////////////////////////////////////

procedure TTurnoutPanelProp.Change(parsed: TStrings);
begin
  fg := StrToColor(parsed[4]);
  bg := StrToColor(parsed[5]);
  flash := StrToBool(parsed[6]);
  position := TVyhPoloha(StrToInt(parsed[7]));
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTurnout.Reset();
begin
  if (Self.block > -2) then
    Self.panelProp := _DEF_TURNOUT_PROP
  else
    Self.panelProp := _UA_TURNOUT_PROP;

  Self.visible := true;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTurnout.Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
var fg: Integer;
  bkcol: TColor;
begin
  if ((Self.panelProp.flash) and (blik) and (Self.visible)) then
    fg := clBlack
  else
  begin
    if ((Self.visible) or (Self.panelProp.fg = clAqua) or (Self.panelProp.fg = clFuchsia)) then
      fg := Self.panelProp.fg
    else
      fg := useky[Self.obj].panelProp.notColorBranches;
  end;

  if (Self.panelProp.bg = clBlack) then
    bkcol := useky[Self.obj].panelProp.bg
  else
    bkcol := Self.panelProp.bg;

  if (Self.block = -2) then
  begin
    Symbols.Draw(SymbolSet.IL_Symbols, Self.position, Self.symbolID, fg, bkcol, obj);
  end else begin
    case (Self.panelProp.position) of
      TVyhPoloha.disabled, TVyhPoloha.none:
        begin
          Symbols.Draw(SymbolSet.IL_Symbols, Self.position, Self.symbolID, bkcol, fg, obj);
        end;
      TVyhPoloha.plus:
        begin
          Symbols.Draw(SymbolSet.IL_Symbols, Self.position, (Self.symbolID) + 4 + (4 * Self.orientationPlus), fg,
            bkcol, obj);
        end;
      TVyhPoloha.minus:
        begin
          Symbols.Draw(SymbolSet.IL_Symbols, Self.position, (Self.symbolID) + 8 - (4 * Self.orientationPlus), fg,
            bkcol, obj);
        end;
      TVyhPoloha.both:
        begin
          Symbols.Draw(SymbolSet.IL_Symbols, Self.position, Self.symbolID, bkcol, clBlue, obj);
        end;
    end;
  end;

end;

/// /////////////////////////////////////////////////////////////////////////////

end.
