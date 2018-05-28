unit BlokUsek;

{
  Definice bloku usek.
  Sem patri pouze definice bloku, nikoliv definice databaze useku
  (kvuli pouzivani v jinych unitach).
}

interface

uses Classes, Graphics, Types, Generics.Collections, RPConst, Symbols, SysUtils,
     BlokTypes;

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
 end;

implementation

uses parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor TPUsek.Create();
begin
 inherited;
 Self.PanelProp := TUsekPanelProp.Create();
end;

destructor TPUsek.Destroy();
begin
 Self.PanelProp.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

function TPUsek.SprPaintsOnRailNum():boolean;
begin
 Result := (Self.Soupravy.Count = 1) and (Self.KPopisek.Count > 0) and
           ((Self.Soupravy[0].X = Self.KPopisek[0].X) and (Self.Soupravy[0].Y = Self.KPopisek[0].Y));
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

