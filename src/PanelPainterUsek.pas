unit PanelPainterUsek;

interface

uses Panel, Symbols, Types, Graphics, Generics.Collections, DXDraws, IBUtils;

procedure ShowUseky(useky:TList<TPReliefUsk>; myORs:TList<TORPanel>; blik:boolean;
    startJC:TList<TStartJC>; obj:TDXDraw; var vyhybky:TList<TPVyhybka>);
procedure PaintSouprava(pos:TPoint; const usek:TPReliefUsk; spri:Integer;
    myORs:TList<TORPanel>; obj:TDXDraw; blik:boolean; bgZaver:boolean = false);
procedure ShowUsekSoupravy(const usek:TPReliefUsk; obj:TDXDraw; blik:boolean; myORs:TList<TORPanel>);
procedure PaintCisloKoleje(pos:TPoint; const usek:TPReliefUsk; obj:TDXDraw);
procedure ShowUsekVetve(usek:TPReliefUsk; vetevI:Integer; visible:boolean;
    var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
    startJC:TList<TStartJC>; var vyhybky:TList<TPVyhybka>);
procedure ShowDKSVetve(usek:TPReliefUsk; visible:boolean;
    var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
    startJC:TList<TStartJC>; var vyhybky:TList<TPVyhybka>);

implementation

uses PanelPainter, RPConst;

////////////////////////////////////////////////////////////////////////////////

// zobrazeni vsech useku na panelu
procedure ShowUseky(useky:TList<TPReliefUsk>; myORs:TList<TORPanel>;
    blik:boolean; startJC:TList<TStartJC>; obj:TDXDraw; var vyhybky:TList<TPVyhybka>);
var i,j,k:integer;
    showed:array of boolean;
    fg, bg:TColor;
    sjc:TStartJC;
    sym:TReliefSym;
    p:TPoint;
begin
 for i := 0 to Useky.Count-1 do
  begin
   // vykresleni symbolu useku
   // tady se resi vetve
   if ((Useky[i].Vetve.Count = 0) or (Useky[i].PanelProp.Symbol = clFuchsia)) then
    begin
     // pokud nejsou vetve, nebo je usek disabled, vykresim ho cely (bez ohledu na vetve)
     if (((Useky[i].PanelProp.blikani) or ((Useky[i].PanelProp.soupravy.Count > 0) and
        (myORs[Useky[i].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
         and (blik)) then
       fg := clBlack
     else
       fg := Useky[i].PanelProp.Symbol;

     for sym in Useky[i].Symbols do
      begin
       bg := Useky[i].PanelProp.Pozadi;

       for sjc in startJC do
         if ((sjc.Pos.X = sym.Position.X) and (sjc.Pos.Y = sym.Position.Y)) then
           bg := sjc.Color;

       for k := 0 to Useky[i].JCClick.Count-1 do
        if ((Useky[i].JCClick[k].X = sym.Position.X) and (Useky[i].JCClick[k].Y = sym.Position.Y)) then
         if (Integer(Useky[i].PanelProp.KonecJC) > 0) then bg := _Konec_JC[Integer(Useky[i].PanelProp.KonecJC)];

       PanelPainter.Draw(SymbolSet.IL_Symbols, sym.Position, sym.SymbolID, fg, bg, obj);
      end;//for j

    end else begin

     SetLength(showed, Useky[i].Vetve.Count);
     for j := 0 to Useky[i].Vetve.Count-1 do
       showed[j] := false;

     // pokud jsou vetve a usek neni disabled, kreslim vetve
     if (Useky[i].DKStype <> dksNone) then
       ShowDKSVetve(Useky[i], true, showed, myORs, blik, obj, startJC, vyhybky)
     else
       ShowUsekVetve(Useky[i], 0, true, showed, myORs, blik, obj, startJC, vyhybky);
    end;

   // vykresleni cisla koleje
   for p in useky[i].KPopisek do
     PaintCisloKoleje(Point(p.X - (Length(Useky[i].KpopisekStr) div 2), p.Y), useky[i], obj);

   // vykresleni souprav
   ShowUsekSoupravy(useky[i], obj, blik, myORs);
  end;//for i
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// vykresleni soupravy na dane pozici
procedure PaintSouprava(pos:TPoint; const usek:TPReliefUsk; spri:Integer;
    myORs:TList<TORPanel>; obj:TDXDraw; blik:boolean; bgZaver:boolean = false);
var bg: TColor;
    sipkaLeft, sipkaRight: boolean;
    souprava:TUsekSouprava;
begin
 souprava := usek.PanelProp.soupravy[spri];
 pos := Point(pos.X - (Length(souprava.nazev) div 2), pos.Y);

 // urceni barvy
 if (myORs[usek.OblRizeni].RegPlease.status = TORRegPleaseStatus.selected) then
  begin
   bg := clYellow;
   if (blik) then Exit();
  end else if ((bgZaver) and (usek.PanelProp.KonecJC > TJCType.no)) then
   bg := _Konec_JC[Integer(usek.PanelProp.KonecJC)]
  else
   bg := souprava.bg;

 PanelPainter.TextOutput(pos, souprava.nazev, souprava.fg, bg, obj, true);

 // Lichy : 0 = zleva doprava ->, 1 = zprava doleva <-
 sipkaLeft := (((souprava.sipkaL) and (myORs[usek.OblRizeni].Lichy = 1)) or
              ((souprava.sipkaS) and (myORs[usek.OblRizeni].Lichy = 0)));

 sipkaRight := (((souprava.sipkaS) and (myORs[usek.OblRizeni].Lichy = 1)) or
              ((souprava.sipkaL) and (myORs[usek.OblRizeni].Lichy = 0)));

 // vykresleni ramecku kolem cisla soupravy
 if (souprava.ramecek <> clBlack) then
  begin
   obj.Surface.Canvas.Pen.Mode    := pmMerge;
   obj.Surface.Canvas.Pen.Color   := souprava.ramecek;
   obj.Surface.Canvas.Brush.Color := clBlack;
   obj.Surface.Canvas.Rectangle(pos.X*SymbolSet._Symbol_Sirka,
                                            pos.Y*SymbolSet._Symbol_Vyska,
                                            (pos.X+Length(souprava.nazev))*SymbolSet._Symbol_Sirka,
                                            (pos.Y+1)*SymbolSet._Symbol_Vyska);
   obj.Surface.Canvas.Pen.Mode := pmCopy;
  end;

 if (sipkaLeft) then
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y-1), _Spr_Sipka_Start+1,
             souprava.fg, clNone, obj, true);
 if (sipkaRight) then
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(pos.X+Length(souprava.nazev)-1, pos.Y-1),
             _Spr_Sipka_Start, souprava.fg, clNone, obj, true);

 if ((sipkaLeft) or (sipkaRight)) then
  begin
   // vykresleni sipky
   obj.Surface.Canvas.Pen.Color := souprava.fg;
   obj.Surface.Canvas.MoveTo(pos.X*SymbolSet._Symbol_Sirka, pos.Y*SymbolSet._Symbol_Vyska-1);
   obj.Surface.Canvas.LineTo((pos.X+Length(souprava.nazev))*SymbolSet._Symbol_Sirka,
                                         pos.Y*SymbolSet._Symbol_Vyska-1);
  end;//if sipkaLeft or sipkaRight
end;

////////////////////////////////////////////////////////////////////////////////
// zobrazi soupravy na celem useku

procedure ShowUsekSoupravy(const usek:TPReliefUsk; obj:TDXDraw; blik:boolean; myORs:TList<TORPanel>);
var i, step, index:Integer;
begin
 if ((usek.PanelProp.soupravy.Count = 0) or (usek.Soupravy.Count = 0)) then
   Exit()
 else if (usek.PanelProp.soupravy.Count = 1) then begin
   PaintSouprava(usek.Soupravy[usek.Soupravy.Count div 2], usek, 0, myORs, obj, blik);
 end else begin
   // vsechny soupravy, ktere se vejdou, krome posledni
   index := 0;
   step := Max(usek.Soupravy.Count div usek.PanelProp.soupravy.Count, 1);
   for i := 0 to Min(usek.Soupravy.Count, usek.PanelProp.soupravy.Count)-2 do
    begin
     PaintSouprava(usek.Soupravy[index], usek, i, myORs, obj, blik);
     index := index + step;
    end;

   // posledni souprava na posledni pozici
   if (usek.Soupravy.Count > 0) then
     PaintSouprava(usek.Soupravy[usek.Soupravy.Count-1], usek,
        usek.PanelProp.Soupravy.Count-1, myORs, obj, blik);
 end;
end;

////////////////////////////////////////////////////////////////////////////////

// vykresleni cisla koleje
procedure PaintCisloKoleje(pos:TPoint; const usek:TPReliefUsk; obj:TDXDraw);
var left:TPoint;
begin
 left := Point(pos.X - Length(usek.KpopisekStr) div 2, pos.Y);

 if (usek.PanelProp.KonecJC = TJCType.no) then
   PanelPainter.TextOutput(left, usek.KpopisekStr,
      usek.PanelProp.Symbol, usek.PanelProp.Pozadi, obj)
 else
   PanelPainter.TextOutput(left, usek.KpopisekStr,
      usek.PanelProp.Symbol, _Konec_JC[Integer(usek.PanelProp.KonecJC)], obj);
end;

////////////////////////////////////////////////////////////////////////////////

// Rekurzivne kresli vetve bezneho bloku
procedure ShowUsekVetve(usek:TPReliefUsk; vetevI:Integer; visible:boolean;
    var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
    startJC:TList<TStartJC>; var vyhybky:TList<TPVyhybka>);
var i:Integer;
    fg, bg:TColor;
    vetev:TVetev;
    sjc:TStartJC;
    p:TPoint;
    vyh:TPVyhybka;
begin
 if (vetevI < 0) then Exit();
 if (showed[vetevI]) then Exit();
 showed[vetevI] := true;
 vetev := usek.Vetve[vetevI];

 vetev.visible := visible;
 usek.Vetve[vetevI] := vetev;

 if (((usek.PanelProp.blikani) or ((usek.PanelProp.soupravy.Count > 0) and
    (myORs[usek.OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
    and (blik) and (visible)) then
   fg := clBlack
  else begin
   if (visible) then
     fg := usek.PanelProp.Symbol
    else
     fg := usek.PanelProp.nebarVetve;
  end;

 bg := usek.PanelProp.Pozadi;

 for i := 0 to Length(vetev.Symbols)-1 do
  begin
   if ((vetev.Symbols[i].SymbolID < _Usek_Start) and (vetev.Symbols[i].SymbolID > _Usek_End)) then continue;    // tato situace nastava v pripade vykolejek

   bg := usek.PanelProp.Pozadi;

   for sjc in startJC do     
     if ((sjc.Pos.X = vetev.Symbols[i].Position.X) and (sjc.Pos.Y = vetev.Symbols[i].Position.Y)) then
       bg := sjc.Color;

   for p in usek.JCClick do
     if ((p.X = vetev.Symbols[i].Position.X) and (p.Y = vetev.Symbols[i].Position.Y)) then
       if (Integer(usek.PanelProp.KonecJC) > 0) then bg := _Konec_JC[Integer(usek.PanelProp.KonecJC)];

   PanelPainter.Draw(SymbolSet.IL_Symbols, vetev.Symbols[i].Position, vetev.Symbols[i].SymbolID, fg, bg, obj);
  end;//for i


 if (vetev.node1.vyh > -1) then
  begin
   vyh := vyhybky[vetev.node1.vyh];
   vyh.visible := visible;

   // nastaveni barvy neprirazene vyhybky
   if (vyh.Blok = -2) then
    begin
     vyh.PanelProp.Symbol := fg;
     vyh.PanelProp.Pozadi := bg;
    end;

   vyhybky[vetev.node1.vyh] := vyh;
    
   case (vyh.PanelProp.Poloha) of
    TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:begin
       ShowUsekVetve(usek, vetev.node1.ref_plus, visible, showed, myORs, blik, obj, startJC, vyhybky);
       ShowUsekVetve(usek, vetev.node1.ref_minus, visible, showed, myORs, blik, obj, startJC, vyhybky);
     end;//case disable, both, none

    TVyhPoloha.plus, TVyhPoloha.minus:begin
       if ((Integer(vyh.PanelProp.Poloha) xor vyh.PolohaPlus) = 0) then
        begin
         ShowUsekVetve(usek, vetev.node1.ref_plus, visible, showed, myORs, blik, obj, startJC, vyhybky);
         ShowUsekVetve(usek, vetev.node1.ref_minus, false, showed, myORs, blik, obj, startJC, vyhybky);
        end else begin
         ShowUsekVetve(usek, vetev.node1.ref_plus, false, showed, myORs, blik, obj, startJC, vyhybky);
         ShowUsekVetve(usek, vetev.node1.ref_minus, visible, showed, myORs, blik, obj, startJC, vyhybky);
        end;
     end;//case disable, both, none
   end;//case
  end;

 if (vetev.node2.vyh > -1) then
  begin
   vyh := vyhybky[vetev.node2.vyh];
   vyh.visible := visible;  

   // nastaveni barvy neprirazene vyhybky
   if (vyh.Blok = -2) then
    begin
     vyh.PanelProp.Symbol := fg;
     vyh.PanelProp.Pozadi := bg;
    end;

   vyhybky[vetev.node2.vyh] := vyh;
    
   case (vyh.PanelProp.Poloha) of
    TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:begin
       ShowUsekVetve(usek, vetev.node2.ref_plus, visible, showed, myORs, blik, obj, startJC, vyhybky);
       ShowUsekVetve(usek, vetev.node2.ref_minus, visible, showed, myORs, blik, obj, startJC, vyhybky);
     end;//case disable, both, none

    TVyhPoloha.plus, TVyhPoloha.minus:begin
       if ((Integer(vyh.PanelProp.Poloha) xor vyh.PolohaPlus) = 0) then
        begin
         ShowUsekVetve(usek, vetev.node2.ref_plus, visible, showed, myORs, blik, obj, startJC, vyhybky);
         ShowUsekVetve(usek, vetev.node2.ref_minus, false, showed, myORs, blik, obj, startJC, vyhybky);
        end else begin
         ShowUsekVetve(usek, vetev.node2.ref_plus, false, showed, myORs, blik, obj, startJC, vyhybky);
         ShowUsekVetve(usek, vetev.node2.ref_minus, visible, showed, myORs, blik, obj, startJC, vyhybky);
        end;
     end;//case disable, both, none
   end;//case
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// Zobrazuje vetve bloku, ktery je dvojita kolejova spojka.
procedure ShowDKSVetve(usek:TPReliefUsk; visible:boolean;
    var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
    startJC:TList<TStartJC>; var vyhybky:TList<TPVyhybka>);
var polLeft, polRight: TVyhPoloha;
    leftHidden, rightHidden: boolean;
    leftCross, rightCross: boolean;
    fg: TColor;
    vyh:TPVyhybka;
begin
 if (usek.Vetve.Count < 3) then Exit();
 if (usek.Vetve[0].node1.vyh < 0) then Exit();
 if (usek.Vetve[1].node1.vyh < 0) then Exit();

 // 1) zjistime si polohy vyhybek
 polLeft := vyhybky[usek.Vetve[0].node1.vyh].PanelProp.Poloha;
 polRight := vyhybky[usek.Vetve[1].node1.vyh].PanelProp.Poloha;

 // 2) rozhodneme o tom co barvit
 leftHidden := ((polLeft = TVyhPoloha.plus) and (polRight = TVyhPoloha.minus));
 rightHidden := ((polLeft = TVyhPoloha.minus) and (polRight = TVyhPoloha.plus));

 leftCross := (polLeft <> TVyhPoloha.plus) and (not leftHidden);
 rightCross := (polRight <> TVyhPoloha.plus) and (not rightHidden);

 ShowUsekVetve(usek, 0, leftCross, showed, myORs, blik, obj, startJC, vyhybky);
 ShowUsekVetve(usek, 1, rightCross, showed, myORs, blik, obj, startJC, vyhybky);
 ShowUsekVetve(usek, 2,
    not (leftHidden or rightHidden or ((polLeft = TVyhPoloha.minus) and (polRight = TVyhPoloha.minus))), showed,
    myORs, blik, obj, startJC, vyhybky);
 if (usek.Vetve.Count > 3) then ShowUsekVetve(usek, 3, not leftHidden, showed, myORs, blik, obj, startJC, vyhybky);
 if (usek.Vetve.Count > 4) then ShowUsekVetve(usek, 4, not rightHidden, showed, myORs, blik, obj, startJC, vyhybky);

 vyh := vyhybky[usek.Vetve[0].node1.vyh];
 vyh.visible := not leftHidden;
 vyhybky[usek.Vetve[0].node1.vyh] := vyh;

 vyh := vyhybky[usek.Vetve[1].node1.vyh];
 vyh.visible := not rightHidden;
 vyhybky[usek.Vetve[1].node1.vyh] := vyh;
  
 // 3) vykreslime stredovy kriz
 if (((usek.PanelProp.blikani) or ((usek.PanelProp.soupravy.Count > 0) and
    (myORs[usek.OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
    and (blik) and (visible)) then
   fg := clBlack
  else begin
   if (visible) then
     fg := usek.PanelProp.Symbol
    else
     fg := usek.PanelProp.nebarVetve;
  end;

 if (usek.DKStype = dksTop) then
  begin
   if ((leftCross) and (rightCross)) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Top, fg, usek.PanelProp.Pozadi, obj)
   else if (leftCross) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 4, fg, usek.PanelProp.Pozadi, obj)
   else if (rightCross) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 2, fg, usek.PanelProp.Pozadi, obj)
   else
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Top, usek.PanelProp.nebarVetve, usek.PanelProp.Pozadi, obj)
  end else begin
   if ((leftCross) and (rightCross)) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Bot, fg, usek.PanelProp.Pozadi, obj)
   else if (leftCross) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 3, fg, usek.PanelProp.Pozadi, obj)
   else if (rightCross) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 5, fg, usek.PanelProp.Pozadi, obj)
   else
     PanelPainter.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Bot, usek.PanelProp.nebarVetve, usek.PanelProp.Pozadi, obj)
  end;

end;

end.
