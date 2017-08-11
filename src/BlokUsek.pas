unit BlokUsek;

{
  Definice bloku usek.
  Sem patri pouze definice bloku, nikoliv definice databaze useku
  (kvuli pouzivani v jinych unitach).
}

interface

uses Classes, Graphics, Types, Generics.Collections, RPConst, Symbols;

const
  _Konec_JC: array [0..3] of TColor = (clBlack, clGreen, clWhite, clTeal);  //zadna, vlakova, posunova, nouzova (privolavaci)

type
 TUsekSouprava = record
  nazev:string;
  sipkaL,sipkaS:boolean;
  fg, bg, ramecek:TColor;
  posindex:Integer;               // index pozice, na ktere je umistena tato konkretni souprava
 end;

 TUsekPanelProp = record
  blikani:boolean;
  Symbol,Pozadi,nebarVetve:TColor;
  KonecJC:TJCType;
  soupravy:TList<TUsekSouprava>;
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
 TVetev=record             //vetev useku

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
 TPUsek=record
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
 end;

const
  _Def_Usek_Prop:TUsekPanelProp = (
      blikani: false;
      Symbol: clFuchsia;
      Pozadi: clBlack;
      nebarVetve: $A0A0A0;
      KonecJC: no);

  _UA_Usek_Prop:TUsekPanelProp = (
      blikani: false;
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      nebarVetve: $A0A0A0;
      KonecJC: no);

implementation

end.

