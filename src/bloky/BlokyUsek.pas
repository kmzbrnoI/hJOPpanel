unit BlokyUsek;

{
  Definice databaze useku.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
     Symbols, PanelOR, StrUtils, BlokNavestidlo, BlokVyhybka, IBUtils,
     BlokUsek;

const
  _Konec_JC: array [0..3] of TColor = (clBlack, clGreen, clWhite, clTeal);  //zadna, vlakova, posunova, nouzova (privolavaci)

type
 TPUsekID = record
  index:Integer;
  soupravaI:Integer;
 end;

 TPUseky = class
  private
   function GetItem(index:Integer):TPUsek;
   function GetCount():Integer;

   procedure ShowUsekVetve(usek:TPUsek; vetevI:Integer; visible:boolean;
       var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
       startJC:TList<TStartJC>; vyhybky:TList<TPVyhybka>);
   procedure ShowDKSVetve(usek:TPUsek; visible:boolean;
       var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
       startJC:TList<TStartJC>; vyhybky:TList<TPVyhybka>);

  public

   data:TObjectList<TPUsek>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile; myORs:TList<TORPanel>);
   procedure Show(obj:TDXDraw; blik:boolean; myORs:TList<TORPanel>;
      startJC:TList<TStartJC>; vyhybky:TList<TPVyhybka>);
   function GetIndex(Pos:TPoint):TPUsekID;
   procedure Reset(orindex:Integer = -1);
   function GetUsek(tech_id:Integer):Integer;

   property Items[index : integer] : TPUsek read GetItem; default;
   property Count : integer read GetCount;
 end;

implementation

uses ParseHelper, PanelPainter;

////////////////////////////////////////////////////////////////////////////////

constructor TPUseky.Create();
begin
 inherited;
 Self.data := TObjectList<TPUsek>.Create();
end;

destructor TPUseky.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUseky.Load(ini:TMemIniFile; myORs:TList<TORPanel>);
var i, j, k, count, count2:Integer;
    usek:TPUsek;
    obj:string;
    symbol:TReliefSym;
    pos:TPoint;
    Vetev:TVetev;
begin
 count := ini.ReadInteger('P', 'U', 0);
 for i := 0 to count-1 do
  begin
   usek := TPUsek.Create();

   usek.Blok      := ini.ReadInteger('U'+IntToStr(i),'B',-1);
   usek.OblRizeni := ini.ReadInteger('U'+IntToStr(i),'OR',-1);
   usek.root      := GetPos(ini.ReadString('U'+IntToStr(i), 'R', '-1;-1'));
   usek.DKStype := TDKSType(ini.ReadInteger('U'+IntToStr(i), 'DKS', Integer(dksNone)));

   //Symbols
   usek.Symbols := TList<TReliefSym>.Create();
   obj := ini.ReadString('U'+IntToStr(i),'S', '');
   for j := 0 to (Length(obj) div 8)-1 do
    begin
     try
       symbol.Position.X := StrToInt(copy(obj,j*8+1,3));
       symbol.Position.Y := StrToInt(copy(obj,j*8+4,3));
       symbol.SymbolID   := StrToInt(copy(obj,j*8+7,2));
     except
       continue;
     end;
     usek.Symbols.Add(symbol);
    end;//for j

   //JCClick
   usek.JCClick := TList<TPoint>.Create();
   obj := ini.ReadString('U'+IntToStr(i),'C','');
   for j := 0 to (Length(obj) div 6)-1 do
    begin
     try
       pos.X := StrToInt(copy(obj,j*6+1,3));
       pos.Y := StrToInt(copy(obj,j*6+4,3));
     except
      continue;
     end;
     usek.JCClick.Add(pos);
    end;//for j

   //KPopisek
   obj := ini.ReadString('U'+IntToStr(i),'P','');
   usek.KPopisek := TList<TPoint>.Create();
   for j := 0 to (Length(obj) div 6)-1 do
    begin
     try
       pos.X := StrToIntDef(copy(obj,j*6+1,3),0);
       pos.Y := StrToIntDef(copy(obj,j*6+4,3),0);
     except
       continue;
     end;
     usek.KPopisek.Add(pos);
    end;//for j

   //Nazev
   usek.KpopisekStr := ini.ReadString('U'+IntToStr(i),'N','');

   //Soupravy
   obj := ini.ReadString('U'+IntToStr(i),'Spr','');
   usek.Soupravy := TList<TPoint>.Create();
   for j := 0 to (Length(obj) div 6)-1 do
    begin
     try
       pos.X := StrToIntDef(copy(obj,j*6+1,3),0);
       pos.Y := StrToIntDef(copy(obj,j*6+4,3),0);
     except
       continue;
     end;
     usek.Soupravy.Add(pos);
    end;//for j

   // usporadame seznam souprav podle licheho smeru
   if (myORs[usek.OblRizeni].Lichy = 1) then
     usek.Soupravy.Reverse();

   // pokud nejsou pozice na soupravu, kreslime soupravu na cislo koleje
   if ((usek.Soupravy.Count = 0) and (usek.KpopisekStr <> '') and (usek.KPopisek.Count <> 0)) then
     usek.Soupravy.Add(usek.KPopisek[0]);

   //nacitani vetvi:
   usek.Vetve := TList<TVetev>.Create();
   count2 := ini.ReadInteger('U'+IntToStr(i), 'VC', 0);
   for j := 0 to count2-1 do
    begin
     obj := ini.ReadString('U'+IntToStr(i), 'V'+IntToStr(j), '');

     vetev.node1.vyh        := StrToIntDef(copy(obj, 0, 3), 0);
     vetev.node1.ref_plus   := StrToIntDef(copy(obj, 4, 2), 0);
     vetev.node1.ref_minus  := StrToIntDef(copy(obj, 6, 2), 0);

     vetev.node2.vyh        := StrToIntDef(copy(obj, 8, 3), 0);
     vetev.node2.ref_plus   := StrToIntDef(copy(obj, 11, 2), 0);
     vetev.node2.ref_minus  := StrToIntDef(copy(obj, 13, 2), 0);

     obj := RightStr(obj, Length(obj)-14);

     SetLength(vetev.Symbols, Length(obj) div 9);

     for k := 0 to Length(vetev.Symbols)-1 do
      begin
       vetev.Symbols[k].Position.X := StrToIntDef(copy(obj, 9*k + 1, 3), 0);
       vetev.Symbols[k].Position.Y := StrToIntDef(copy(obj, (9*k + 4), 3), 0);
       vetev.Symbols[k].SymbolID   := StrToIntDef(copy(obj, (9*k + 7), 3), 0);
      end;

     usek.Vetve.Add(vetev);
    end;//for j

   //default settings:
   if (usek.Blok = -2) then
     usek.PanelProp.InitUA()
   else
     usek.PanelProp.InitDefault();

   usek.PanelProp.soupravy := TList<TUsekSouprava>.Create();

   Self.data.Add(usek);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TPUseky.GetIndex(Pos:TPoint):TPUsekID;
var i,j:Integer;
    us:TUsekSouprava;
begin
 Result.index := -1;

 for i := 0 to Self.data.Count-1 do
   for j := 0 to Self.data[i].Symbols.Count-1 do
     if ((Pos.X = Self.data[i].Symbols[j].Position.X) and (Pos.Y = Self.data[i].Symbols[j].Position.Y)) then
      begin
       Result.index := i;
       Break;
      end;

 if (Result.index = -1) then Exit();
 Result.soupravaI := -1;

 // zjisteni indexu soupravy
 for i := 0 to Self.data[Result.index].PanelProp.soupravy.Count-1 do
  begin
   us := Self.data[Result.index].PanelProp.soupravy[i];

   if (us.posindex < 0) then continue;

   if ((Pos.X >= Self.data[Result.index].Soupravy[us.posindex].X - (Length(us.nazev) div 2)) and
       (Pos.X < Self.data[Result.index].Soupravy[us.posindex].X + (Length(us.nazev) div 2) + (Length(us.nazev) mod 2))) then
    begin
     Result.soupravaI := i;
     Exit();
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUseky.Reset(orindex:Integer = -1);
var usek:TPUsek;
begin
 for usek in Self.data do
   if ((orindex < 0) or (usek.OblRizeni = orindex)) then
     usek.Reset();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUseky.Show(obj:TDXDraw; blik:boolean; myORs:TList<TORPanel>;
      startJC:TList<TStartJC>; vyhybky:TList<TPVyhybka>);
var j,k:integer;
    showed:array of boolean;
    fg, bg:TColor;
    sjc:TStartJC;
    sym:TReliefSym;
    p:TPoint;
    usek:TPUsek;
begin
 for usek in Self.data do
  begin
   // vykresleni symbolu useku

   if (((usek.PanelProp.blikani) or ((usek.PanelProp.soupravy.Count > 0) and
      (myORs[usek.OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
       and (blik)) then
     fg := clBlack
   else
     fg := usek.PanelProp.Symbol;

   if ((usek.Vetve.Count = 0) or (usek.PanelProp.Symbol = clFuchsia)) then
    begin
     // pokud nejsou vetve, nebo je usek disabled, vykresim ho cely (bez ohledu na vetve)
     for sym in usek.Symbols do
      begin
       bg := usek.PanelProp.Pozadi;

       for sjc in startJC do
         if ((sjc.Pos.X = sym.Position.X) and (sjc.Pos.Y = sym.Position.Y)) then
           bg := sjc.Color;

       for k := 0 to usek.JCClick.Count-1 do
        if ((usek.JCClick[k].X = sym.Position.X) and (usek.JCClick[k].Y = sym.Position.Y)) then
         if (Integer(usek.PanelProp.KonecJC) > 0) then bg := _Konec_JC[Integer(usek.PanelProp.KonecJC)];

       PanelPainter.Draw(SymbolSet.IL_Symbols, sym.Position, sym.SymbolID, fg, bg, obj);
      end;//for j

    end else begin

     SetLength(showed, usek.Vetve.Count);
     for j := 0 to usek.Vetve.Count-1 do
       showed[j] := false;

     // pokud jsou vetve a usek neni disabled, kreslim vetve
     if (usek.DKStype <> dksNone) then
       ShowDKSVetve(usek, true, showed, myORs, blik, obj, startJC, vyhybky)
     else
       ShowUsekVetve(usek, 0, true, showed, myORs, blik, obj, startJC, vyhybky);
    end;

   // vykresleni cisla koleje
   // kdyz by mela cislo koleje prekryt souprava, nevykreslovat cislo koleje
   // (cislo soupravy muze byt kratsi nez cislo koleje)
   if ((usek.Soupravy.Count > 0) and (usek.KPopisek.Count > 0)) then
    begin
     if (usek.SprPaintsOnRailNum() and (usek.PanelProp.soupravy.Count > 0)) then
      begin
       for j := 1 to usek.KPopisek.Count-1 do // na nulte pozici je cislo soupravy
         usek.PaintCisloKoleje(usek.KPopisek[j], obj, fg = clBlack);
      end else begin
       for p in usek.KPopisek do
         usek.PaintCisloKoleje(p, obj, fg = clBlack);
      end;
    end;

   // vykresleni souprav
   usek.ShowSoupravy(obj, blik, myORs);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

// Rekurzivne kresli vetve bezneho bloku
procedure TPUseky.ShowUsekVetve(usek:TPUsek; vetevI:Integer; visible:boolean;
    var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
    startJC:TList<TStartJC>; vyhybky:TList<TPVyhybka>);
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
end;

////////////////////////////////////////////////////////////////////////////////

// Zobrazuje vetve bloku, ktery je dvojita kolejova spojka.
procedure TPUseky.ShowDKSVetve(usek:TPUsek; visible:boolean;
    var showed:array of boolean; myORs:TList<TORPanel>; blik:boolean; obj:TDXDraw;
    startJC:TList<TStartJC>; vyhybky:TList<TPVyhybka>);
var polLeft, polRight: TVyhPoloha;
    leftHidden, rightHidden: boolean;
    leftCross, rightCross: boolean;
    fg: TColor;
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

 vyhybky[usek.Vetve[0].node1.vyh].visible := not leftHidden;
 vyhybky[usek.Vetve[1].node1.vyh].visible := not rightHidden;

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

////////////////////////////////////////////////////////////////////////////////

function TPUseky.GetItem(index:Integer):TPUsek;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPUseky.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

function TPUseky.GetUsek(tech_id:Integer):Integer;
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
   if (tech_id = Self.data[i].Blok) then
     Exit(i);

 Result := -1;
end;

////////////////////////////////////////////////////////////////////////////////

end.

