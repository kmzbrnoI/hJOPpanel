unit BlokUsek;

{
  Definice bloku usek.
  Sem patri pouze definice bloku, nikoliv definice databaze useku
  (kvuli pouzivani v jinych unitach).
}

interface

uses Classes, Graphics, Types, Generics.Collections, Symbols, SysUtils,
     BlokTypes, PanelOR, DXDraws, IBUtils;

const
  _Konec_JC: array [0..3] of TColor = (clBlack, clGreen, clWhite, clTeal);  //zadna, vlakova, posunova, nouzova (privolavaci)

type
 TUsekSouprava = record
  nazev:string;
  sipkaL,sipkaS:boolean;
  fg, bg, ramecek:TColor;
  posindex:Integer;               // index pozice, na ktere je umistena tato konkretni souprava
 end;

 TUsekPanelProp = class
  blikani:boolean;
  Symbol,Pozadi,nebarVetve:TColor;
  KonecJC:TJCType;
  soupravy:TList<TUsekSouprava>;

   constructor Create();
   destructor Destroy(); override;
   procedure Change(parsed:TStrings);
   procedure InitDefault();
   procedure InitUA();
 end;

 // useku rozdeleny na vetve je reprezentovan takto:

 // ukoncovaci element vetve = vyhybka
 TVetevEnd = record
  vyh:Integer;                     // pokud usek nema vyhybky -> vyh1 = -1, vyh2 = -1 (nastava u useku bez vyhybky a u koncovych vetvi)
                                   // referuje na index v poli vyhybek (nikoliv na technologicke ID vyhybky!)
                                   // kazda vetev je ukoncena maximalne 2-ma vyhybkama - koren muze byt ukoncen 2-ma vyhybkama, pak jen jedna
  ref_plus,ref_minus:Integer;      // reference  na vetev, kterou se pokracuje, pokud je vyh v poloze + resp. poloze -
                                   // posledni vetev resp. usek bez vyhybky ma obe reference = -1
 end;

 //vetev useku
 TVetev = record             //vetev useku

  node1:TVetevEnd;           // reference na 1. vyhybku, ktera ukoncuje tuto vetev
  node2:TVetevEnd;           // reference na 2. vyhybku, ktera ukoncuje tuto vetev
  visible:boolean;           // pokud je vetve viditelna, je zde true; jinak false



  Symbols:array of TReliefSym;
                            // s timto dynamicky alokovanym polem je potreba zachazet opradu opatrne
                            // realokace trva strasne dlouho !
                            // presto si myslim, ze se jedna o vyhodne reseni: pole se bude plnit jen jednou
 end;

 TDKSType = (dksNone = 0, dksTop = 1, dksBottom = 2);

 // 1 usek na reliefu
 TPUsek = class
  Blok:Integer;

  OblRizeni:Integer;
  PanelProp:TUsekPanelProp;
  root:TPoint;
  DKStype:TDKSType;

  Symbols:TList<TReliefSym>;
  JCClick:TList<TPoint>;
  KPopisek:TList<TPoint>;
  Soupravy:TList<TPoint>; // je zaruceno, ze tento seznam je usporadany v lichem smeru (resi se pri nacitani souboru)
  KpopisekStr:string;

  Vetve:TList<TVetev>;               // vetve useku
   //vetev 0 je vzdy koren
   //zde je ulozen binarni strom v pseudo-forme
     //na 0. indexu je koren, kazdy vrchol pak obsahuje referenci na jeho deti


 // program si duplikuje ulozena data - po rozdeleni useku na vetve uklada usek jak nerozdeleny tak rozdeleny

   constructor Create();
   destructor Destroy(); override;

   function SprPaintsOnRailNum():boolean;
   procedure Reset();

   procedure PaintSouprava(pos:TPoint; spri:Integer; myORs:TList<TORPanel>;
                           obj:TDXDraw; blik:boolean; bgZaver:boolean = false);
   procedure ShowSoupravy(obj:TDXDraw; blik:boolean; myORs:TList<TORPanel>);
   procedure PaintCisloKoleje(pos:TPoint; obj:TDXDraw; hidden:boolean);
 end;

implementation

uses parseHelper, PanelPainter;

////////////////////////////////////////////////////////////////////////////////

constructor TPUsek.Create();
begin
 inherited;
 Self.PanelProp := TUsekPanelProp.Create();
end;

destructor TPUsek.Destroy();
begin
 Self.PanelProp.Free();
 Self.Symbols.Free();
 Self.JCClick.Free();
 Self.KPopisek.Free();
 Self.Soupravy.Free();
 Self.Vetve.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

function TPUsek.SprPaintsOnRailNum():boolean;
begin
 Result := (Self.Soupravy.Count = 1) and (Self.KPopisek.Count > 0) and
           ((Self.Soupravy[0].X = Self.KPopisek[0].X) and (Self.Soupravy[0].Y = Self.KPopisek[0].Y));
end;

procedure TPUsek.Reset();
begin
 Self.PanelProp.soupravy.Clear();
 if (Self.Blok > -2) then
   Self.PanelProp.InitDefault()
 else
   Self.PanelProp.InitUA();
end;

////////////////////////////////////////////////////////////////////////////////

// vykresleni soupravy na dane pozici
procedure TPUsek.PaintSouprava(pos:TPoint; spri:Integer; myORs:TList<TORPanel>;
                               obj:TDXDraw; blik:boolean; bgZaver:boolean = false);
var fg, bg: TColor;
    sipkaLeft, sipkaRight: boolean;
    souprava:TUsekSouprava;
begin
 souprava := Self.PanelProp.soupravy[spri];
 pos := Point(pos.X - (Length(souprava.nazev) div 2), pos.Y);

 fg := souprava.fg;

 // urceni barvy
 if (myORs[Self.OblRizeni].RegPlease.status = TORRegPleaseStatus.selected) then
  begin
   if (blik) then
    begin
     fg := clBlack;
     bg := Self.PanelProp.Pozadi;
    end else
     bg := clYellow;
  end else if ((bgZaver) and (Self.PanelProp.KonecJC > TJCType.no)) then
   bg := _Konec_JC[Integer(Self.PanelProp.KonecJC)]
  else
   bg := souprava.bg;

 PanelPainter.TextOutput(pos, souprava.nazev, fg, bg, obj, true);

 // Lichy : 0 = zleva doprava ->, 1 = zprava doleva <-
 sipkaLeft := (((souprava.sipkaL) and (myORs[Self.OblRizeni].Lichy = 1)) or
              ((souprava.sipkaS) and (myORs[Self.OblRizeni].Lichy = 0)));

 sipkaRight := (((souprava.sipkaS) and (myORs[Self.OblRizeni].Lichy = 1)) or
              ((souprava.sipkaL) and (myORs[Self.OblRizeni].Lichy = 0)));

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

 if (fg = clBlack) then
   fg := bg;

 if (sipkaLeft) then
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y-1), _Spr_Sipka_Start+1,
             fg, clNone, obj, true);
 if (sipkaRight) then
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(pos.X+Length(souprava.nazev)-1, pos.Y-1),
             _Spr_Sipka_Start, fg, clNone, obj, true);

 if ((sipkaLeft) or (sipkaRight)) then
  begin
   // vykresleni sipky
   obj.Surface.Canvas.Pen.Color := fg;
   obj.Surface.Canvas.MoveTo(pos.X*SymbolSet._Symbol_Sirka, pos.Y*SymbolSet._Symbol_Vyska-1);
   obj.Surface.Canvas.LineTo((pos.X+Length(souprava.nazev))*SymbolSet._Symbol_Sirka,
                                         pos.Y*SymbolSet._Symbol_Vyska-1);
  end;//if sipkaLeft or sipkaRight
end;

////////////////////////////////////////////////////////////////////////////////

// vykresleni cisla koleje
procedure TPUsek.PaintCisloKoleje(pos:TPoint; obj:TDXDraw; hidden:boolean);
var left:TPoint;
    fg:TColor;
begin
 left := Point(pos.X - (Length(Self.KpopisekStr) div 2), pos.Y);

 if (hidden) then
   fg := clBlack
 else
   fg := Self.PanelProp.Symbol;

 if (Self.PanelProp.KonecJC = TJCType.no) then
   PanelPainter.TextOutput(left, Self.KpopisekStr,
      fg, Self.PanelProp.Pozadi, obj)
 else
   PanelPainter.TextOutput(left, Self.KpopisekStr,
      fg, _Konec_JC[Integer(Self.PanelProp.KonecJC)], obj);
end;

////////////////////////////////////////////////////////////////////////////////
// zobrazi soupravy na celem useku

procedure TPUsek.ShowSoupravy(obj:TDXDraw; blik:boolean; myORs:TList<TORPanel>);
var i, step, index:Integer;
    s:TUsekSouprava;
begin
 // Posindex neni potreba mazat, protoze se vzdy se zmenou stavu bloku
 // prepisuje automaticky na -1.

 if ((Self.PanelProp.soupravy.Count = 0) or (Self.Soupravy.Count = 0)) then
   Exit()

 else if (Self.PanelProp.soupravy.Count = 1) then begin
   Self.PaintSouprava(Self.Soupravy[Self.Soupravy.Count div 2], 0, myORs, obj, blik, Self.SprPaintsOnRailNum());

   if (Self.PanelProp.soupravy[0].posindex <> 0) then
    begin
     s := Self.PanelProp.soupravy[0];
     s.posindex := Self.Soupravy.Count div 2;
     Self.PanelProp.soupravy[0] := s;
    end;

 end else begin
   // vsechny soupravy, ktere se vejdou, krome posledni
   index := 0;
   step := Max(Self.Soupravy.Count div Self.PanelProp.soupravy.Count, 1);
   for i := 0 to Min(Self.Soupravy.Count, Self.PanelProp.soupravy.Count)-2 do
    begin
     Self.PaintSouprava(Self.Soupravy[index], i, myORs, obj, blik);

     if (Self.PanelProp.soupravy[i].posindex <> index) then
      begin
       s := Self.PanelProp.soupravy[i];
       s.posindex := index;
       Self.PanelProp.soupravy[i] := s;
      end;

     index := index + step;
    end;

   // posledni souprava na posledni pozici
   if (Self.Soupravy.Count > 0) then
    begin
     Self.PaintSouprava(Self.Soupravy[Self.Soupravy.Count-1], Self.PanelProp.Soupravy.Count-1, myORs, obj, blik);

     if (Self.PanelProp.soupravy[Self.PanelProp.Soupravy.Count-1].posindex <> Self.Soupravy.Count-1) then
      begin
       s := Self.PanelProp.soupravy[Self.PanelProp.Soupravy.Count-1];
       s.posindex := Self.Soupravy.Count-1;
       Self.PanelProp.soupravy[Self.PanelProp.Soupravy.Count-1] := s;
      end;
    end;
 end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TUsekPanelProp.Create();
begin
 inherited;
 Self.InitDefault();
 Self.soupravy := TList<TUsekSouprava>.Create();
end;

destructor TUsekPanelProp.Destroy();
begin
 Self.soupravy.Free();
 inherited;
end;

procedure TUsekPanelProp.InitDefault();
begin
 Self.blikani := false;
 Self.Symbol := clFuchsia;
 Self.Pozadi := clBlack;
 Self.nebarVetve := $A0A0A0;
 Self.KonecJC := no;
end;

procedure TUsekPanelProp.InitUA();
begin
 Self.blikani := false;
 Self.Symbol := $A0A0A0;
 Self.Pozadi := clBlack;
 Self.nebarVetve := $A0A0A0;
 Self.KonecJC := no;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TUsekPanelProp.Change(parsed:TStrings);
var soupravy, souprava:TStrings;
    i: Integer;
    us:TUsekSouprava;
begin
  Symbol  := StrToColor(parsed[4]);
  Pozadi  := StrToColor(parsed[5]);
  blikani := StrToBool(parsed[6]);
  KonecJC := TJCType(StrToInt(parsed[7]));
  nebarVetve := strToColor(parsed[8]);

  Self.soupravy.Clear();

  if (parsed.Count > 9) then
   begin
    soupravy := TStringList.Create();
    souprava := TStringList.Create();

    try
      ExtractStringsEx([')'], ['('], parsed[9], soupravy);

      for i := 0 to soupravy.Count-1 do
       begin
        souprava.Clear();
        ExtractStringsEx([';'], [], soupravy[i], souprava);

        us.nazev := souprava[0];
        us.sipkaL := ((souprava[1] <> '') and (souprava[1][1] = '1'));
        us.sipkaS := ((souprava[1] <> '') and (souprava[1][2] = '1'));
        us.fg := strToColor(souprava[2]);
        us.bg := strToColor(souprava[3]);
        us.posindex := -1;

        if (souprava.Count > 4) then
          us.ramecek := strToColor(souprava[4])
        else
          us.ramecek := clBlack;

        Self.soupravy.Add(us);
       end;

    finally
      soupravy.Free();
      souprava.Free();
    end;
   end;
end;

////////////////////////////////////////////////////////////////////////////////

end.

