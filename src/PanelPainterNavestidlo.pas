unit PanelPainterNavestidlo;

interface

uses Panel, DXDraws, Generics.Collections, Graphics;

procedure ShowNavestidla(navs:TList<TPNavestidlo>; blik:boolean; StartJC:TList<TStartJC>; obj:TDXDraw);

implementation

uses PanelPainter, Symbols, Classes;

procedure ShowNavestidla(navs:TList<TPNavestidlo>; blik:boolean; StartJC:TList<TStartJC>; obj:TDXDraw);
var fg:TColor;
    sjc:TStartJC;
    nav:TPNavestidlo;
begin
 StartJC.Clear();

 for nav in navs do
  begin
   if ((nav.PanelProp.blikani) and (blik)) then
     fg := clBlack
   else
     fg := nav.PanelProp.Symbol;

   if (nav.PanelProp.AB) then
    begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, nav.Position, _SCom_Start+nav.SymbolID+2,
               fg, nav.PanelProp.Pozadi, obj);
    end else begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, nav.Position, _SCom_Start+nav.SymbolID,
               fg, nav.PanelProp.Pozadi, obj);
    end;

   if ((nav.PanelProp.Pozadi = clGreen) or
       (nav.PanelProp.Pozadi = clWhite) or
       (nav.PanelProp.Pozadi = clTeal)) then
    begin
     //pridani StartJC
     sjc.Color := nav.PanelProp.Pozadi;
     sjc.Pos   := Point(nav.Position.X-1,nav.Position.Y);
     StartJC.Add(sjc);

     sjc.Color := nav.PanelProp.Pozadi;
     sjc.Pos   := Point(nav.Position.X+1,nav.Position.Y);
     StartJC.Add(sjc);
    end;
  end;//for i
end;//procedure

end.
