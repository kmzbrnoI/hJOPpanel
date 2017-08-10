unit PanelPainterVyhybka;

interface

uses Panel, Generics.Collections, Graphics, DXDraws;

procedure ShowVyhybky(vyhybky:TList<TPVyhybka>; blik:boolean;
  useky:TList<TPReliefUsk>; obj:TDXDraw);

implementation

uses PanelPainter, Symbols, RPConst;

procedure ShowVyhybky(vyhybky:TList<TPVyhybka>; blik:boolean;
  useky:TList<TPReliefUsk>; obj:TDXDraw);
var fg:Integer;
    bkcol:TColor;
    vyh:TPVyhybka;
begin
 //vyhybky
 for vyh in vyhybky do
  begin
   if ((vyh.PanelProp.blikani) and (blik) and (vyh.visible)) then
     fg := clBlack
   else begin
     if ((vyh.visible) or (vyh.PanelProp.Symbol = clAqua)) then
      fg := vyh.PanelProp.Symbol
     else
      fg := useky[vyh.obj].PanelProp.nebarVetve;
   end;

   if (vyh.PanelProp.Pozadi = clBlack) then
     bkcol := useky[vyh.obj].PanelProp.Pozadi
   else
     bkcol := vyh.PanelProp.Pozadi;

   if (vyh.Blok = -2) then
    begin
     // blok zamerne neprirazen
     PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
               vyh.SymbolID, fg, bkcol, obj);
    end else begin
     case (vyh.PanelProp.Poloha) of
      TVyhPoloha.disabled:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
                 vyh.SymbolID, useky[vyh.obj].PanelProp.Pozadi, clFuchsia, obj);
      end;
      TVyhPoloha.none:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position, vyh.SymbolID,
                 bkcol, fg, obj);
      end;
      TVyhPoloha.plus:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
                 (vyh.SymbolID)+4+(4*(vyh.PolohaPlus xor 0)),
                 fg, bkcol, obj);
      end;
      TVyhPoloha.minus:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
                 (vyh.SymbolID)+8-(4*(vyh.PolohaPlus xor 0)),
                 fg, bkcol, obj);
      end;
      TVyhPoloha.both:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position, vyh.SymbolID,
                 bkcol, clBlue, obj);
      end;
     end;//case
    end;//else blok zamerne neprirazn
  end;//for i
end;//procedure

end.
