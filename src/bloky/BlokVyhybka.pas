unit BlokVyhybka;

{
  Definice bloku vyhybka.
  Sem patri pouze definice bloku, nikoliv definice databaze vyhybek
  (kvuli pouzivani v jinych unitach).
}

interface

uses Classes, Graphics, Types, SysUtils, DXDraws, Generics.Collections, BlokUsek;

type
 TVyhPoloha  = (disabled = -5, none = -1, plus = 0, minus = 1, both = 2);

 // data pro vykreslovani
 TVyhPanelProp = record
  blikani:boolean;
  Symbol,Pozadi:TColor;
  Poloha:TVyhPoloha;

  procedure Change(parsed:TStrings);
 end;

 // 1 vyhybka na reliefu
 TPVyhybka = class
  Blok:Integer;
  PolohaPlus:Byte;
  Position:TPoint;
  SymbolID:Integer;
  obj:integer;

  OblRizeni:Integer;
  PanelProp:TVyhPanelProp;
  visible:boolean;      // na zaklade viditelnosti ve vetvich je rekonstruovana viditelnost vyhybky

  procedure Reset();
  procedure Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
 end;//Navestidlo

const
  _Def_Vyh_Prop:TVyhPanelProp = (
      blikani: false;
      Symbol: clFuchsia;
      Pozadi: clBlack;
      Poloha: TVyhPoloha.disabled);

  _UA_Vyh_Prop:TVyhPanelProp = (
      blikani: false;
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      Poloha: TVyhPoloha.both);

implementation

uses parseHelper, PanelPainter, Symbols;

////////////////////////////////////////////////////////////////////////////////

procedure TVyhPanelProp.Change(parsed:TStrings);
begin
 Symbol  := StrToColor(parsed[4]);
 Pozadi  := StrToColor(parsed[5]);
 blikani := StrToBool(parsed[6]);
 Poloha  := TVyhPoloha(StrToInt(parsed[7]));
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVyhybka.Reset();
begin
 if (Self.Blok > -2) then
   Self.PanelProp := _Def_Vyh_Prop
 else
   Self.PanelProp := _UA_Vyh_Prop;

 Self.visible := true;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVyhybka.Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
var fg:Integer;
    bkcol:TColor;
begin
 if ((Self.PanelProp.blikani) and (blik) and (Self.visible)) then
   fg := clBlack
 else begin
   if ((Self.visible) or (Self.PanelProp.Symbol = clAqua)) then
    fg := Self.PanelProp.Symbol
   else
    fg := useky[Self.obj].PanelProp.nebarVetve;
 end;

 if (Self.PanelProp.Pozadi = clBlack) then
   bkcol := useky[Self.obj].PanelProp.Pozadi
 else
   bkcol := Self.PanelProp.Pozadi;

 if (Self.Blok = -2) then
  begin
   // blok zamerne neprirazen
   PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Position,
             Self.SymbolID, fg, bkcol, obj);
  end else begin
   case (Self.PanelProp.Poloha) of
    TVyhPoloha.disabled, TVyhPoloha.none:begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Position, Self.SymbolID,
               bkcol, fg, obj);
    end;
    TVyhPoloha.plus:begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Position,
               (Self.SymbolID)+4+(4*Self.PolohaPlus),
               fg, bkcol, obj);
    end;
    TVyhPoloha.minus:begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Position,
               (Self.SymbolID)+8-(4*Self.PolohaPlus),
               fg, bkcol, obj);
    end;
    TVyhPoloha.both:begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, Self.Position, Self.SymbolID,
               bkcol, clBlue, obj);
    end;
   end;//case
  end;//else blok zamerne neprirazn

end;

////////////////////////////////////////////////////////////////////////////////

end.

