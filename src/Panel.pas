unit Panel;

interface

uses DXDraws, ImgList, Controls, Windows, SysUtils, Graphics, Classes,
     Forms, StdCtrls, ExtCtrls, Menus, AppEvnts, inifiles, Messages, RPConst,
     fPotvrSekv, MenuPanel, StrUtils, PGraphics, HVDb, Generics.Collections,
     Zasobnik, UPO, IBUtils, Hash, PngImage;

const
  //limity poli
  _MAX_USK      = 256;
  _MAX_NAV      = 256;
  _MAX_POM      = 256;
  _MAX_VYH      = 256;
  _MAX_TRT      = 16;
  _MAX_SPR      = 8;
  _MAX_SYMBOLS  = 256;
  _MAX_JCCLICK  = 16;
  _MAX_KPOPISEK = 16;
  _MAX_POPISKY  = 64;
  _MAX_JC       = 16;
  _MAX_PRJ      = 16;
  _MAX_PRJ_LEN  = 10;
  _MAX_UV_SPR   = 16;
  _MAX_UVAZKY   = 256;
  _MAX_UVAZKY_SPR = 256;
  _MAX_ZAMKY    = 256;

  _INFOTIMER_WIDTH      = 30;
  _INFOTIMER_TEXT_WIDTH = 22;

  _FileVersion = '1.1';

const
    _Konec_JC: array [0..3] of TColor = (clBlack, clGreen, clWhite, clTeal);  //zadna, vlakova, posunova, nouzova (privolavaci)

//Format objektoveho souboru reliefu:
//ini soubor
//
//'G'-globalni vlastnost
//    ver: verze souboru
//
//'P'-Panel: zakladni udaje
//    W:Width
//    H:Height
//    U:pocet Useku
//    N:pocet Navestidel
//    T:pocet Textu
//    P:pocet pomocnych objektu
//    V:pocet vyhybek
//    Uv:pocet uvazek
//    UvS: pocet textovych poli souprav k uvazkam
//    Z:pocet vyhybkovych zamku
//    Vyk: pocet vykolejek
//    R:pocet rozpojovacu
//    vc: [0,1] 1 pokud jsou vetve spocitane, 0 pokud nejsou
//'U1'..'Un' - sekce useku
//  B= [blok technologie, jemuz je symbol prirazen]
//  S= [symboly] ulozeno textove
//    pevne delky: 0-2..souradnice X
//                 3-5..souradnice Y
//                 6-7..symbol
//  nasledujici data jsou v souboru ulzoena jen, pokud jsou k dispozici vetve:
//    VC= vetve count = [pocet vetvi]
//    V0...V(N-1)= [vetve] ulozeno textove
//      pevne delky: 0-2..1. vyhybka - index v poli vyhybek (nikoliv technologicky blok!)
//                   3-4..1. vyhybka : index dalsi vetve pro polohu "vodorovne"
//                   5-6..1. vyhybka: index dalsi vetve pro polohu "sikmo"

//                   7-9..2. vyhybka - index v poli vyhybek (nikoliv technologicky blok!)
//                 10-11..2. vyhybka : index dalsi vetve pro polohu "vodorovne"
//                 12-13..2. vyhybka: index dalsi vetve pro polohu "sikmo"
//
//      [-           7-9..souradnice X
//                 10-12..souradnice Y
//                 13-15..symbol  -]  <- tato cast se opakuje
//  C= [JCClick] ulozeno textove
//    pevne delky: 0-2..souradnice X
//                 3-5..souradnice Y
//  P= [KPopisek] ulozeno textove
//    pevne delky: 0-2..souradnice X
//                 3-5..souradnice Y
//  N= [nazev koleje] ulozeno textove
//  OR= [oblast rizeni] integer 0-n
//  R= [root, koren] 0-2..souradnice X
//                   3-5..souradnice Y
//
//'N1'..'Nn' - sekce navestidel
//  B= [asociovany blok technologie]
//  X= [pozice X]
//  Y= [pozice Y]
//  S= [symbol]
//     0..3 (4 typy navestidel)
//  OR= [oblast rizeni] integer 0-n
//
//'P0'..'Pn' - sekce pomocnych bloku
//  1 blok vzdy v 1 objektu
//  P= [pozice] - 3*X;3*Y;... (bez stredniku - pevne delky)
//  S= [symbol]
//
//'T1'..'Tn' - sekce textu
//  T= [text]
//  X= [pozice X]
//  Y= [pozice Y]
//  C= [barva]
//  B= [blok]
//  OR= [oblast rizeni] integer 0-n
//
//'V0'..'Vn' - sekce vyhybek
//  B= [asociovany blok technologie]
//  S= [symbol]
//  P= [poloha plus]
//  X= [pozice X]
//  Y= [pozice Y]
//  O= [objekt, kteremu vyhybka patri]
//  OR= [oblast rizeni] integer 0-n

//'PRJ0'..'PRJn' - sekce prejezdu
//  B= [asociovany blok technologie]
//  BP= [blik_pozice] - 3*X;3*Y;3*U... = X,T, tech_usek (bez stredniku - pevne delky)
//  SP= [static_pozice] - 3*X;3*Y;... (bez stredniku - pevne delky)
//  OR= [oblast rizeni] integer 0-n
//  U= [technologicky usek] - blok typu usek, ktery prejezd zobrazuje (prostredni usek prejezdu)

// 'Uv0'..'Uvn' - sekce uvazek
//  B= [asociovany blok technologie]
//  D= [zakladni smer]
//  X= [pozice X]
//  Y= [pozice Y]
//  OR= [oblast rizeni] integer 0-n

// 'UvS0'..'UvSn' - sekce seznamu souprav uvazek
//  B= [asociovany blok technologie]
//  VD= [vertikalni smer]
//  X= [pozice X]
//  Y= [pozice Y]
//  C= [pocet souprav]
//  OR= [oblast rizeni] integer 0-n

// 'Z0'..'Zn' - sekce vyhybkovych zamku
//  B= [asociovany blok technologie]
//  X= [pozice X]
//  Y= [pozice Y]
//  OR= [oblast rizeni] integer 0-n

// 'Vyk0'..'Vykn' - sekce vykolejek
//  B= [asociovany blok technologie]
//  X= [pozice X]
//  Y= [pozice Y]
//  T= typ vykolejky (otoceni symbolu)
//  OR= [oblast rizeni] integer 0-n
//  O= [objekt, kteremu vykolejka patri]
//  V= [vetev] vislo vetve, ve kterem je vykolejka (v useku pod ni)

// 'R0'..'Rn' - sekce rozpojovacu
//  B= [asociovany blok technologie]
//  X= [pozice X]
//  Y= [pozice Y]
//  OR= [oblast rizeni] integer 0-n

type

 ///////////////////////////////////////////////////////////////////////////////
 // globalni datove struktury:

 TArSmallI=array of Smallint;

 TSpecialMenu = (none, dk, osv, loko, reg_please);

 TBoolArray=record
  count:integer;
  Data:array [-1..255] of boolean;
 end;

 TPointArray=record
  count:integer;
  Data:array [0..255] of TPoint;
 end;

 ///////////////////////////////////////////////////////////////////////////////
 // eventy:

 TMoveEvent = procedure(Sender:TObject;Position:TPoint) of object;

 ///////////////////////////////////////////////////////////////////////////////
 // data k oblastem rizeni:

 // 1 element osvetleni oblasti rizeni
 TOsv = record
  board:Byte;
  port:Byte;
  name:string;  //max 5 znaku
  state:boolean;
 end;

 // prava oblasti rizeni
 TORRights=record
  ModCasStart:Boolean;
  ModCasStop:Boolean;
  ModCasSet:Boolean;
 end;

 // pozice symbolu OR
 TPoss=record
  DK:TPoint;
  DKOr:byte;  //orientace DK (0,1)
  Time:TPoint;
 end;

 // fronta JC
 TPanelQ = record
  data:array [0..15] of string;
  cnt:Integer;
 end;

 TMereniCasu = record
   Start:TDateTime;
   Length:TDateTime;
   id:Integer;
  end;

 TORRegPleaseStatus = (null = 0, request = 1, selected = 2);

 TORRegPlease = record
  status:TORRegPleaseStatus;
  user,firstname, lastname, comment:string;
 end;

 // 1 oblast rizeni
 TORPanel=class
  str:string;
  Name:string;
  ShortName:string;
  id:string;
  Lichy:Byte;     // 0 = zleva doprava ->, 1 = zprava doleva <-
  Rights:TORRights;
  Poss:TPoss;
  Osvetleni:TList<TOsv>;
  MereniCasu:TList<TMereniCasu>;

  tech_rights:TORControlRights;
  dk_osv:Boolean;
  dk_blik:Boolean;
  dk_click_server:boolean;
  stack:TORStack;

  NUZ_status:TNUZstatus;
  RegPlease:TORRegPlease;

  HVs:THVDb;
 end;

 ///////////////////////////////////////////////////////////////////////////////
 // blok usek:

 // 1 bitmapovy symbol na reliefu (ze symbolu se skladaji useky)
 TReliefSym=record
  Position:TPoint;
  SymbolID:Integer;
 end;

 // data o useku pro spravne vykreslovani
 TUsekPanelProp=record
  blikani:boolean;
  Symbol,Pozadi,SprC:TColor;
  spr:string;
  KonecJC:TJCType;
  sipkaL,sipkaS:boolean;
  ramecekColor:TColor;
  sprPozadi:TColor;
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

 // 1 usek na reliefu
 TPReliefUsk=record
  Blok:Integer;

  OblRizeni:Integer;
  PanelProp:TUsekPanelProp;

  Symbols:TList<TReliefSym>;
  JCClick:TList<TPoint>;
  KPopisek:TList<TPoint>;
  KpopisekStr:string;

  Vetve:TList<TVetev>;               // vetve useku
   //vetev 0 je vzdy koren
   //zde je ulozen binarni strom v pseudo-forme
     //na 0. indexu je koren, kazdy vrchol pak obsahuje referenci na jeho deti


 // program si duplikuje ulozena data - po rozdeleni useku na vetve uklada usek jak nerozdeleny tak rozdeleny
 end;

 ///////////////////////////////////////////////////////////////////////////////
 // blok vyhybka:

 // data pro vykreslovani
 TVyhPanelProp = record
  blikani:boolean;
  Symbol,Pozadi:TColor;
  Poloha:TVyhPoloha;
 end;

 // 1 vyhybka na reliefu
 TPVyhybka=record
  Blok:Integer;
  PolohaPlus:Byte;
  Position:TPoint;
  SymbolID:Integer;
  obj:integer;

  OblRizeni:Integer;
  PanelProp:TVyhPanelProp;
  visible:boolean;      // na zaklade viditelnosti ve vetvich je rekonstruovana viditelnost vyhybky
 end;//Navestidlo

 ///////////////////////////////////////////////////////////////////////////////
 // blok popisek:

 // 1 blok na reliefu:
 TPPopisek=record
  Text:string;
  Position:TPoint;
  Color:Integer;
  prejezd_ref:Integer;
 end;//Text

 ///////////////////////////////////////////////////////////////////////////////
 // blok navestidlo:

 // data pro vykreslovani
 TNavPanelProp = record
  Symbol,Pozadi:TColor;
  AB:Boolean;
  blikani:boolean;
 end;

 // 1 blok na reliefu
 TPNavestidlo=record
  Blok:Integer;
  Position:TPoint;
  SymbolID:Integer;

  OblRizeni:Integer;
  PanelProp:TNavPanelProp;
 end;//Navestidlo

 ///////////////////////////////////////////////////////////////////////////////
 // blok pomocny objekt:

 // 1 blok na reliefu:
 TPPomocnyObj=record
  Positions:record
    Data:array[0.._MAX_SYMBOLS] of TPoint;
    Count:Byte;
   end;//Symbols
  Symbol:Integer;
 end;//PomocnyObj

 ///////////////////////////////////////////////////////////////////////////////

 TBlkPrjPanelStav = (err = -1, otevreno = 0, vystraha = 1, uzavreno = 2, anulace = 3);

 // data pro vykreslovani
 TPrjPanelProp = record
  Symbol,Pozadi:TColor;
  stav:TBlkPrjPanelStav;
 end;

 // jeden blikajici blok prejezdu
 // je potreba v nem take ulozit, jaky technologicky blok se ma vykreslit, pokud je prejezd uzavren
 TBlikPoint = record
  Pos:TPoint;
  PanelUsek:Integer;       // pozor, tady je usek panelu!, toto je zmena oproti editoru a mergeru !
 end;

 // 1 blok prejezdu na reliefu:
 TPPrejezd=record
  Blok:Integer;

  StaticPositions: record
   data:array [0.._MAX_PRJ_LEN] of TPoint;
   Count:Byte;
  end;

  BlikPositions: record
   data:array [0.._MAX_PRJ_LEN] of TBlikPoint;
   Count:Byte;
  end;

  OblRizeni:Integer;
  PanelProp:TPrjPanelProp;
 end;

 TUvazkaSmer = (disabled = -1, zadny = 0, zakladni = 1, opacny = 2);

 // data pro vykreslovani uvazky
 TUvazkaPanelProp = record
  Symbol,Pozadi:TColor;
  blik:boolean;
  smer:TUvazkaSmer;
 end;

 TPUvazka=record
  Blok:Integer;
  Pos:TPoint;
  defalt_dir:Integer;
  OblRizeni:Integer;
  PanelProp:TUvazkaPanelProp;
 end;

 ///////////////////////////////////////////////////////////////////////////////

 TUvazkaSpr = record
  strings:TStrings;
  show_index:Integer;
  time:string;
  color:TColor;
 end;

 // data pro vykreslovani uvazky spr
 TUvazkaSprPanelProp = record
  spr:TList<TUvazkaSpr>;
 end;

 TUvazkaSprVertDir = (top = 0, bottom = 1);

 TPUvazkaSpr=record
  Blok:Integer;
  Pos:TPoint;
  vertical_dir:TUvazkaSprVertDir;
  spr_cnt:Integer;
  OblRizeni:Integer;
  PanelProp:TUvazkaSprPanelProp;
 end;

 ///////////////////////////////////////////////////////////////////////////////

 // data pro vykreslovani uvazky spr
 TZamekPanelProp = record
  Symbol,Pozadi:TColor;
  blik:boolean;
 end;

 TPZamek=record
  Blok:Integer;
  Pos:TPoint;
  OblRizeni:Integer;
  PanelProp:TZamekPanelProp;
 end;

 ///////////////////////////////////////////////////////////////////////////////

 // data pro vykreslovani rozpojovace
 TRozpPanelProp = record
  Symbol,Pozadi:TColor;
  blik:boolean;
 end;

 TPRozp=record
  Blok:Integer;
  Pos:TPoint;
  OblRizeni:Integer;
  PanelProp:TRozpPanelProp;
 end;

 ///////////////////////////////////////////////////////////////////////////////

 // data pro vykreslovani vykolejek
 TPVykol=record
  Blok:Integer;
  Pos:TPoint;
  OblRizeni:Integer;
  PanelProp:TVyhPanelProp;

  symbol:Integer;
  usek:integer;              // index useku, na kterem je vykolejka
  vetev:integer;             // cislo vetve, ve kterem je vykolejka
 end;

 ///////////////////////////////////////////////////////////////////////////////

 // data kurzoru
 TCursorDraw=record
   KurzorRamecek,KurzorObsah:TColor;
   Pos:TPoint;
   Pozadi:TBitmap;
 end;

 ///////////////////////////////////////////////////////////////////////////////

 TStartJC=record
  Pos:TPoint;
  Color:TColor;
 end;

 TPJC=record
  text:string;
  index:integer;
 end;

 TGetVyhybky=record
  Count:Integer;
  Data:array [0..32] of integer;
 end;

 //////////////////////////////////////////////////////////////////////////////

 TInfoTimer = record
  konec:TDateTime;
  str:string;
  id:Integer;
 end;

 ///////////////////////////////////////////////////////////////////////////////

 // odkaz technologickeho id na index v prislusnem seznamu symbolu
 // slouzi pro rychly pristup k symbolum pri CHANGE
 TTechBlokToSymbol = record
  blk_type:Integer;
  symbol_index:Integer;
 end;

 ///////////////////////////////////////////////////////////////////////////////
 ///
 PTRelief = ^TRelief;
 TRelief=class
  private const
    //vychozi data
    _Def_Color_Pozadi = clBlack;
    _Def_Color_Mrizka = clGray;
    _Def_Color_Kurzor_Ramecek = clYellow;
    _Def_Color_Kurzor_Obsah   = clMaroon;

    _JCPopisek_Index = 360;

    _Usek_Start      = 12;
    _Usek_End        = 23;
    _Vyhybka_End     = 3;
    _SCom_Start      = 24;
    _SCom_End        = 29;
    _Prj_Start       = 40;
    _Kolecko         = 42;
    _Uvazka_Start    = 43;
    _Spr_Sipka_Start = 46;
    _Zamek           = 48;
    _Vykol_Start     = 49;
    _Vykol_End       = 54;
    _Rozp_Start      = 55;

    _Hvezdicka = 417;

    _msg_width = 30;

    //defaultni chovani bloku:
    _Def_Usek_Prop:TUsekPanelProp = (
        blikani: false;
        Symbol: clFuchsia;
        Pozadi: clBlack;
        SprC: clFuchsia;
        spr: '';
        KonecJC: no);

    _Def_Vyh_Prop:TVyhPanelProp = (
        blikani: false;
        Symbol: clBlack;
        Pozadi: clFuchsia;
        Poloha: TVyhPoloha.disabled);

    _Def_Nav_Prop:TNavPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        AB: false;
        blikani: false);

    _Def_Prj_Prop:TPrjPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        stav: otevreno);

    _Def_Uvazka_Prop:TUvazkaPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        blik: false;
        smer: disabled;
        );

    _Def_UvazkaSpr_Prop:TUvazkaSprPanelProp = (
        );

    _Def_Zamek_Prop:TZamekPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        blik: false;
        );

    _Def_Rozp_Prop:TRozpPanelProp = (
        Symbol: clFuchsia;
        Pozadi: clBlack;
        blik: false;
        );

    //zde je definovano, jaky specialni symbol se ma vykreslovat jakou barvou (mimo separatoru)
    _SpecS_DrawColors:array [0..35] of Byte = (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,6,6,6,1);

  private
   DrawObject:TDXDraw;
   ParentForm:TForm;
   AE:TApplicationEvents;
   PM_Properties:TPopupMenu;
   T_SystemOK:TTimer; //timer na SystemOK na 500ms - nevykresluje
   Graphics:TPanelGraphics;

   Colors:record
    Pozadi:TColor;
   end;

   CursorDraw:TCursorDraw;

   StaniceIndex:Integer;

   myORs:TList<TORPanel>;

   Menu:TPanelMenu;
   special_menu: TSpecialMenu;
   menu_lastpos: TPoint;                 // pozice, na ktere se mys nachazela pred otevrenim menu
   root_menu:boolean;
   infoTimers:TList<TInfoTimer>;

   uvazky_change_time:TDateTime;    // cas, kdy ma prebliknout text vsech uvazek

   Tech_blok:TDictionary<Integer, TList<TTechBlokToSymbol>>;   // mapuje id technologickeho bloku na

   //zde jsou ulozeny vsechny bloky
   Useky:TList<TPReliefUsk>;
   Navestidla:record
    Data:array [0.._MAX_NAV] of TPNavestidlo;
    Count:Integer;
   end;
   Popisky:record
    Data:array [0.._MAX_POPISKY] of TPPopisek;
    Count:Integer;
   end;//Popisky
   PomocneObj:record
    Data:array [0.._MAX_POM] of TPPomocnyObj;
    Count:Integer;
   end;//Popisky
   Vyhybky:record
    Data:array [0.._MAX_VYH] of TPVyhybka;
    count:Integer;
   end;//Vyhybky
   StartJC:record                    // vykresleni 1 symbolu okolo navestidla v usekove funkci
    Data:array [0..255] of TStartJC;
    count:Integer;
   end;
   Prejezdy:record
    Data:array[0.._MAX_PRJ] of TPPrejezd;
    count:Integer;
   end;
   Uvazky:record
    Data:array[0.._MAX_UVAZKY] of TPUvazka;
    count:Integer;
   end;
   UvazkySpr:record
    Data:array[0.._MAX_UVAZKY_SPR] of TPUvazkaSpr;
    count:Integer;
   end;
   Zamky:record
    Data:array[0.._MAX_ZAMKY] of TPZamek;
    count:Integer;
   end;

   Vykol : TList<TPVykol>;
   Rozp  : TList<TPRozp>;

  SystemOK:record
   Poloha:boolean;
  end;

  msg:record
   show:boolean;
   msg:string;
  end;

  FOnMove  : TMoveEvent;

   procedure PaintKurzor();
   procedure PaintKurzorBg(Pos:TPoint);

   procedure DXDMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure DXDMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);

   procedure T_SystemOKOnTimer(Sender:TObject);

   procedure ObjectMouseUp(Position:TPoint;Button:TPanelButton);

   function FLoad(aFile:string):Byte;

   procedure ShowUseky;
   procedure ShowUsekVetve(usek:TPReliefUsk; vetev:TVetev; var NotSymbol:TList<TPoint>; visible:boolean);
   procedure ShowNavestidla;
   procedure ShowPomocneSymboly;
   procedure ShowPopisky;
   procedure ShowVyhybky;
   procedure ShowDK;
   procedure ShowOpravneni;
   procedure ShowPrj;
   procedure ShowMereniCasu;
   procedure ShowMsg;
   procedure ShowUvazky;
   procedure ShowUvazkySpr;
   procedure ShowZasobniky;
   procedure ShowInfoTimers;
   procedure ShowZamky;
   procedure ShowRozp;
   procedure ShowVykol;

   procedure ResetData;

   function GetSprPaintPos(usek:integer;sprlength:integer):TPointArray;

   function ORLoad(const ORs:TStrings):Byte;

   function GetUsek(Pos:TPoint):Integer; overload;
   function GetNav(Pos:TPoint):Integer;
   function GetVyh(Pos:TPoint):Integer;
   function GetPrj(Pos:TPoint):Integer; overload;
   function GetRozp(Pos:TPoint):Integer;
   function GetDK(Pos:TPoint):Integer;
   function GetUvazka(Pos:TPoint):integer;
   function GetZamek(Pos:TPoint):Integer;

   function GetUsek(tech_id:Integer):Integer; overload;   // pozor: vraci jen prvni vyskyt !
   function GetPrj(tech_id:Integer):Integer; overload;

   procedure AEMessage(var Msg: tagMSG; var Handled: Boolean);

   //DK menu popup
   procedure ShowDKMenu(obl_rizeni:Integer);
   procedure ShowRegMenu(obl_rizeni:Integer);

   //DK menu clicks:
   procedure DKMenuClickMP(Sender:Integer; item:string);
   procedure DKMenuClickMSG(Sender:Integer; item:string);
   procedure DKMenuClickNUZ(Sender:Integer; item:string);
   procedure DKMenuClickOSV(Sender:Integer; item:string);
   procedure DKMenuClickLOKO(Sender:Integer; item:string);
   procedure DKMenuClickSUPERUSER(Sender:Integer; item:string);
   procedure DKMenuClickCAS(Sender:Integer; item:string);
   procedure DKMenuClickSetCAS(Sender:Integer; item:string);

   procedure OSVMenuClick(Sender:Integer; item:string);

   procedure ParseLOKOMenuClick(item:string; obl_r:Integer);
   procedure ParseDKMenuClick(item:string; obl_r:Integer);
   procedure ParseRegMenuClick(item:string; obl_r:Integer);

   procedure MenuOnClick(Sender:TObject; item:string; obl_r:Integer);

   function GetPanelWidth():SmallInt;
   function GetPanelHeight():SmallInt;

   class function GetTechBlk(typ:Integer; symbol_index:Integer):TTechBlokToSymbol;
   procedure AddToTechBlk(typ:Integer; blok_id:Integer; symbol_index:Integer);

  public

   UPO:TPanelUPO;       // upozorneni v leve dolni oblasti

   constructor Create(aParentForm:TForm);
   destructor Destroy; override;

   function Initialize(var DrawObject:TDXDraw; aFile:string; hints_file:string):Byte;
   procedure Show();

   function GetUsekVyhybky(usekid:integer):TGetVyhybky;
   function GetUsekID(BlokTechnolgie:integer):TArSmallI;

   function AddMereniCasu(Sender:string; Delka:TDateTime; id:Integer):byte;
   procedure StopMereniCasu(Sender:string; id:Integer);

   procedure Image(filename:string);

   procedure HideCursor();
   procedure HideMenu();

   procedure DisableElements(orindex:Integer = -1);
   procedure Escape();

   procedure UpdateSymbolSet();

   property PozadiColor:TColor read Colors.Pozadi write Colors.Pozadi;
   property KurzorRamecek:TColor read CursorDraw.KurzorRamecek write CursorDraw.KurzorRamecek;
   property KurzorObsah:TColor read CursorDraw.KurzorObsah write CursorDraw.KurzorObsah;

   property PanelWidth:SmallInt read GetPanelWidth;
   property PanelHeight:SmallInt read GetPanelHeight;
   property StIndex: integer read StaniceIndex;
   property ORs:TList<TORPanel> read myORs;

   //events
   property OnMove: TMoveEvent read FOnMove write FOnMove;

   //komunikace se serverem
   // sender = id oblasti rizeni

   procedure ORAuthoriseResponse(Sender:string; Rights:TORControlRights; comment:string='');
   procedure ORInfoMsg(msg:string);
   procedure ORShowMenu(items:string);
   procedure ORNUZ(Sender:string; status:TNUZstatus);
   procedure ORConnectionOpenned();

   //Change blok
   procedure ORUsekChange(Sender:string; BlokID:integer; UsekPanelProp:TUsekPanelProp);
   procedure ORVyhChange(Sender:string; BlokID:integer; VyhPanelProp:TVyhPanelProp);
   procedure ORNavChange(Sender:string; BlokID:integer; NavPanelProp:TNavPanelProp);
   procedure ORPrjChange(Sender:string; BlokID:integer; PrjPanelProp:TPrjPanelProp);
   procedure ORUvazkaChange(Sender:string; BlokID:integer; UvazkaPanelProp:TUvazkaPanelProp; UvazkaSprPanelProp:TUvazkaSprPanelProp);
   procedure ORZamekChange(Sender:string; BlokID:integer; ZamekPanelProp:TZamekPanelProp);
   procedure ORRozpChange(Sender:string; BlokID:integer; RozpPanelProp:TRozpPanelProp);
   procedure ORInfoTimer(id:Integer; time_min:Integer; time_sec:Integer; str:string);
   procedure ORInfoTimerRemove(id:Integer);
   procedure ORDKClickServer(Sender:string; enable:boolean);
   procedure ORLokReq(Sender:string; parsed:TStrings);

   procedure ORHVList(Sender:string; data:string);
   procedure ORSprNew(Sender:string);
   procedure ORSprEdit(Sender:string; parsed:TStrings);
   procedure OROsvChange(Sender:string; code:string; state:boolean);
   procedure ORStackMsg(Sender:string; data:TStrings);

 end;

implementation

uses fStitVyl, TCPClientPanel, Symbols, fMain, BottomErrors, GlobalConfig, fZpravy,
     fSprEdit, fSettings, fHVMoveSt, fAuth, fHVEdit, fHVDelete, ModelovyCas,
     fNastaveni_casu, LokoRuc, Sounds, fRegReq;

constructor TRelief.Create(aParentForm:TForm);
begin
 inherited Create;

 Self.Useky := TList<TPReliefUsk>.Create();
 Self.Vykol := TList<TPVykol>.Create();
 Self.Rozp  := TList<TPRozp>.Create();
 Self.ParentForm := aParentForm;
 Self.myORs := TList<TORPanel>.Create();
end;//contructor

function TRelief.Initialize(var DrawObject:TDXDraw; aFile:string; hints_file:string):Byte;
var return:Integer;
begin
 Self.Graphics := TPanelGraphics.Create(DrawObject);

 Self.Menu := TPanelMenu.Create(Self.Graphics);
 Self.Menu.OnClick := Self.MenuOnClick;
 Self.Menu.LoadHints(hints_file);

 Errors   := TErrors.Create(Self.Graphics);
 Self.UPO := TPanelUPO.Create(Self.Graphics);
 RucList  := TRucList.Create(Self.Graphics);
 Self.Tech_blok := TDictionary<Integer, TList<TTechBlokToSymbol>>.Create();

 Self.infoTimers := TList<TInfoTimer>.Create();

 Self.DrawObject := DrawObject;

 Self.DrawObject.OnMouseUp   := Self.DXDMouseUp;
 Self.DrawObject.OnMouseMove := Self.DXDMouseMove;

 Self.CursorDraw.Pos.X := -2;
 Self.CursorDraw.Pozadi        := TBitmap.Create();
 Self.CursorDraw.Pozadi.Width  := SymbolSet._Symbol_Sirka+2;    // +2 kvuli okrajum kurzoru
 Self.CursorDraw.Pozadi.Height := SymbolSet._Symbol_Vyska+2;

 Self.PM_Properties := TPopupMenu.Create(Self.ParentForm);

 Self.AE := TApplicationEvents.Create(Self.ParentForm);
 Self.AE.OnMessage := Self.AEMessage;

 Self.T_SystemOK          := TTimer.Create(Self.ParentForm);
 Self.T_SystemOK.Interval := 500;
 Self.T_SystemOK.Enabled  := true;
 Self.T_SystemOK.OnTimer  := Self.T_SystemOKOnTimer;

 Self.Colors.Pozadi            := _Def_Color_Pozadi;
 Self.CursorDraw.KurzorRamecek := _Def_Color_Kurzor_Ramecek;
 Self.CursorDraw.KurzorObsah   := _Def_Color_Kurzor_Obsah;

 Self.StaniceIndex := StIndex;

 return := Self.FLoad(aFile);
 if (return <> 0) then
   Exit(return);

 (Self.ParentForm as TF_Main).SetPanelSize(Self.Graphics.PanelWidth*SymbolSet._Symbol_Sirka, Self.Graphics.PanelHeight*SymbolSet._Symbol_Vyska);

 Self.Show();

 Result := 0;
end;//function

destructor TRelief.Destroy();
var i:Integer;
begin
 for i := Self.myORs.Count-1 downto 0 do
  begin
   Self.myORs[i].stack.Free();
   Self.myORs[i].Osvetleni.Free();
   if (Assigned(Self.myORs[i].HVs)) then
     FreeAndNil(Self.myORs[i].HVs);
   Self.myORs[i].MereniCasu.Free();
   Self.myORs[i].Free();
  end;
 Self.myORs.Free();

 for i := 0 to Self.Useky.Count-1 do
  begin
   Self.Useky[i].Symbols.Free();
   Self.Useky[i].JCClick.Free();
   Self.Useky[i].KPopisek.Free();
   Self.Useky[i].Vetve.Free();
  end;
 Self.Useky.Free();
 Self.Vykol.Free();
 Self.Rozp.Free();

 if (Assigned(Self.infoTimers)) then FreeAndNil(Self.infoTimers);
 if (Assigned(Self.UPO)) then FreeAndNil(Self.UPO);
 if (Assigned(Self.T_SystemOK)) then FreeAndNil(Self.T_SystemOK);
 if (Assigned(Self.PM_Properties)) then FreeAndNil(Self.PM_Properties);
 if (Assigned(Self.Menu)) then FreeAndNil(Self.Menu);
 if (Assigned(Self.Graphics)) then FreeAndNil(Self.Graphics);

 for i in Self.Tech_blok.Keys do
   Self.Tech_blok[i].Free();
 Self.Tech_blok.Free();

 Self.CursorDraw.Pozadi.Free();

 inherited Destroy;
end;//destructor

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowUseky();
var i,j,k:integer;
    sprpaintpos:TPointArray;
    NotSymbol:TList<TPoint>; //symboly na techto pozicich nebudou zobrazovany, protoze je prekryje text (cislo koleje, souprava)
    sipkaLeft,sipkaRight:boolean;
    col:TColor;
begin
 NotSymbol := TList<TPoint>.Create();

 //useky
 for i := 0 to Self.Useky.Count-1 do
  begin
   if (Self.Useky[i].PanelProp.spr = '') then
    begin
     //zadna souprava

     //cislo koleje
     sprpaintpos := Self.GetSprPaintPos(i, Length(Self.Useky[i].KpopisekStr)); //stejny algoritmus, na nazev nehled
     for j := 0 to sprpaintpos.count-1 do
      begin
       for k := 0 to Length(Self.Useky[i].KpopisekStr)-1 do
          NotSymbol.Add(Point(sprpaintpos.Data[j].X+k,sprpaintpos.Data[j].Y));

       //vykresleni cisla koleje
       if (Self.Useky[i].PanelProp.KonecJC = no) then
         Self.Graphics.TextOutput(sprpaintpos.Data[j],Self.Useky[i].KpopisekStr, Self.Useky[i].PanelProp.Symbol,Self.Useky[i].PanelProp.Pozadi) else
          Self.Graphics.TextOutput(sprpaintpos.Data[j],Self.Useky[i].KpopisekStr, Self.Useky[i].PanelProp.Symbol, _Konec_JC[Integer(Self.Useky[i].PanelProp.KonecJC)]);

       // vykresleni ramecku kolem cisla koleje
       if (Self.Useky[i].PanelProp.ramecekColor <> clBlack) then
        begin
         Self.DrawObject.Surface.Canvas.Pen.Mode    := pmMerge;
         Self.DrawObject.Surface.Canvas.Pen.Color   := Self.Useky[i].PanelProp.ramecekColor;
         Self.DrawObject.Surface.Canvas.Brush.Color := clBlack;
         Self.DrawObject.Surface.Canvas.Rectangle(sprpaintpos.Data[j].X*SymbolSet._Symbol_Sirka,
                                                  sprpaintpos.Data[j].Y*SymbolSet._Symbol_Vyska,
                                                  (sprpaintpos.Data[j].X+Length(Self.Useky[i].KpopisekStr))*SymbolSet._Symbol_Sirka,
                                                  (sprpaintpos.Data[j].Y+1)*SymbolSet._Symbol_Vyska);
         Self.DrawObject.Surface.Canvas.Pen.Mode := pmCopy;
        end;

      end;
    end else begin
     //vykresleni cisla soupravy
     sprpaintpos := Self.GetSprPaintPos(i,Length(Self.Useky[i].PanelProp.spr));
     for j := 0 to sprpaintpos.count-1 do
      begin
       for k := 0 to Length(Self.Useky[i].PanelProp.spr)-1 do
        NotSymbol.Add(Point(sprpaintpos.Data[j].X+k,sprpaintpos.Data[j].Y));

       //vykresleni soupravy

       // urceni barvy
       if (Self.myORs[Self.Useky[i].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected) then
        begin
         col := clYellow;
         if (Self.Graphics.blik) then continue;
        end else if (Self.Useky[i].PanelProp.KonecJC > TJCType.no) then
         col := _Konec_JC[Integer(Self.Useky[i].PanelProp.KonecJC)]
        else
         col := Self.Useky[i].PanelProp.sprPozadi;

       Self.Graphics.TextOutput(sprpaintpos.Data[j], Self.Useky[i].PanelProp.spr, Self.Useky[i].PanelProp.SprC, col, true);

       // Lichy : 0 = zleva doprava ->, 1 = zprava doleva <-
       sipkaLeft := (((Self.Useky[i].PanelProp.sipkaL) and (Self.myORs[Self.Useky[i].OblRizeni].Lichy = 1)) or
                    ((Self.Useky[i].PanelProp.sipkaS) and (Self.myORs[Self.Useky[i].OblRizeni].Lichy = 0)));

       sipkaRight := (((Self.Useky[i].PanelProp.sipkaS) and (Self.myORs[Self.Useky[i].OblRizeni].Lichy = 1)) or
                    ((Self.Useky[i].PanelProp.sipkaL) and (Self.myORs[Self.Useky[i].OblRizeni].Lichy = 0)));

       // vykersleni ramecku kolem cisla soupravy
       if (Self.Useky[i].PanelProp.ramecekColor <> clBlack) then
        begin
         Self.DrawObject.Surface.Canvas.Pen.Mode    := pmMerge;
         Self.DrawObject.Surface.Canvas.Pen.Color   := Self.Useky[i].PanelProp.ramecekColor;
         Self.DrawObject.Surface.Canvas.Brush.Color := clBlack;
         Self.DrawObject.Surface.Canvas.Rectangle(sprpaintpos.Data[j].X*SymbolSet._Symbol_Sirka,
                                                  sprpaintpos.Data[j].Y*SymbolSet._Symbol_Vyska,
                                                  (sprpaintpos.Data[j].X+Length(Self.Useky[i].PanelProp.spr))*SymbolSet._Symbol_Sirka,
                                                  (sprpaintpos.Data[j].Y+1)*SymbolSet._Symbol_Vyska);
         Self.DrawObject.Surface.Canvas.Pen.Mode := pmCopy;
        end;

       if (sipkaLeft) then
        begin
         SymbolSet.IL_Symbols.DrawingStyle := TDrawingStyle.dsTransparent;
         SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, sprpaintpos.Data[j].X*SymbolSet._Symbol_Sirka, (sprpaintpos.Data[j].Y-1)*SymbolSet._Symbol_Vyska,
            ((_Spr_Sipka_Start+1)*10)+Self.Graphics.GetColorIndex(Self.Useky[i].PanelProp.SprC));
         SymbolSet.IL_Symbols.DrawingStyle := TDrawingStyle.dsNormal;
        end;
       if (sipkaRight) then
        begin
         SymbolSet.IL_Symbols.DrawingStyle := TDrawingStyle.dsTransparent;
         SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, (sprpaintpos.Data[j].X+Length(Self.Useky[i].PanelProp.spr)-1)*SymbolSet._Symbol_Sirka, (sprpaintpos.Data[j].Y-1)*SymbolSet._Symbol_Vyska,
            ((_Spr_Sipka_Start)*10)+Self.Graphics.GetColorIndex(Self.Useky[i].PanelProp.SprC));
         SymbolSet.IL_Symbols.DrawingStyle := TDrawingStyle.dsNormal;
        end;

       if ((sipkaLeft) or (sipkaRight)) then
        begin
         // vykresleni sipky
         Self.DrawObject.Surface.Canvas.Pen.Color := Self.Useky[i].PanelProp.SprC;
         Self.DrawObject.Surface.Canvas.MoveTo(sprpaintpos.Data[j].X*SymbolSet._Symbol_Sirka, sprpaintpos.Data[j].Y*SymbolSet._Symbol_Vyska-1);
         Self.DrawObject.Surface.Canvas.LineTo((sprpaintpos.Data[j].X+Length(Self.Useky[i].PanelProp.spr))*SymbolSet._Symbol_Sirka, sprpaintpos.Data[j].Y*SymbolSet._Symbol_Vyska-1);
        end;//if sipkaLeft or sipkaRight
      end;
    end;//else spr = ''

   // vykresleni symbolu useku
   // tady se resi vetve

   if ((Self.Useky[i].Vetve.Count = 0) or (Self.Useky[i].PanelProp.Symbol = clFuchsia)) then
    begin
     // pokud nejsou vetve, nebo je usek disabled, vykresim ho cely (bez ohledu na vetve)
     if (((Self.Useky[i].PanelProp.blikani) or ((Self.Useky[i].PanelProp.spr <> '') and
        (Self.myORs[Self.Useky[i].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
         and (Self.Graphics.blik)) then continue;

     for j := 0 to Self.Useky[i].Symbols.Count-1 do
      begin
       if (NotSymbol.Contains(Self.Useky[i].Symbols[j].Position)) then continue;

       SymbolSet.IL_Symbols.BkColor := Self.Useky[i].PanelProp.Pozadi;

       for k := 0 to Self.StartJC.count-1 do
        if ((Self.StartJC.Data[k].Pos.X = Self.Useky[i].Symbols[j].Position.X) and (Self.StartJC.Data[k].Pos.Y = Self.Useky[i].Symbols[j].Position.Y)) then
         SymbolSet.IL_Symbols.BkColor := Self.StartJC.Data[k].Color;

       for k := 0 to Self.Useky[i].JCClick.Count-1 do
        if ((Self.Useky[i].JCClick[k].X = Self.Useky[i].Symbols[j].Position.X) and (Self.Useky[i].JCClick[k].Y = Self.Useky[i].Symbols[j].Position.Y)) then
         if (Integer(Self.Useky[i].PanelProp.KonecJC) > 0) then SymbolSet.IL_Symbols.BkColor := _Konec_JC[Integer(Self.Useky[i].PanelProp.KonecJC)];

       SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Useky[i].Symbols[j].Position.X*SymbolSet._Symbol_Sirka,Self.Useky[i].Symbols[j].Position.Y*SymbolSet._Symbol_Vyska,(Self.Useky[i].Symbols[j].SymbolID*10)+Self.Graphics.GetColorIndex(Self.Useky[i].PanelProp.Symbol));
      end;//for j

    end else begin

     // pokud jsou vetve a usek neni disabled, kreslim vetve
     Self.ShowUsekVetve(Self.Useky[i], Self.Useky[i].Vetve[0], NotSymbol, true);
    end;
  end;//for i

 NotSymbol.Free();
end;//procedure

// tato funkce rekurzivne kresli vetve
procedure TRelief.ShowUsekVetve(usek:TPReliefUsk; vetev:TVetev; var NotSymbol:TList<TPoint>; visible:boolean);
var i,k:Integer;
    fg:TColor;
begin
 vetev.visible := visible;

 if (((not usek.PanelProp.blikani) and ((usek.PanelProp.spr = '') or
    (Self.myORs[usek.OblRizeni].RegPlease.status <> TORRegPleaseStatus.selected)))
    or (not Self.Graphics.blik) or (not visible)) then
  begin
   for i := 0 to Length(vetev.Symbols)-1 do
    begin
     if (NotSymbol.Contains(vetev.Symbols[i].Position)) then continue;
     if ((vetev.Symbols[i].SymbolID < _Usek_Start) and (vetev.Symbols[i].SymbolID > _Usek_End)) then continue;    // tato situace nastava v pripade vykolejek

     if (visible) then
       fg := (vetev.Symbols[i].SymbolID*10)+Self.Graphics.GetColorIndex(usek.PanelProp.Symbol)
      else
       fg := (vetev.Symbols[i].SymbolID*10)+1;

     SymbolSet.IL_Symbols.BkColor := usek.PanelProp.Pozadi;

     for k := 0 to Self.StartJC.count-1 do
      if ((Self.StartJC.Data[k].Pos.X = vetev.Symbols[i].Position.X) and (Self.StartJC.Data[k].Pos.Y = vetev.Symbols[i].Position.Y)) then
       SymbolSet.IL_Symbols.BkColor := Self.StartJC.Data[k].Color;

     for k := 0 to usek.JCClick.Count-1 do
      if ((usek.JCClick[k].X = vetev.Symbols[i].Position.X) and (usek.JCClick[k].Y = vetev.Symbols[i].Position.Y)) then
       if (Integer(usek.PanelProp.KonecJC) > 0) then SymbolSet.IL_Symbols.BkColor := _Konec_JC[Integer(usek.PanelProp.KonecJC)];

     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,
                               vetev.Symbols[i].Position.X*SymbolSet._Symbol_Sirka,
                               vetev.Symbols[i].Position.Y*SymbolSet._Symbol_Vyska,
                               fg);
    end;//for i
  end;//if not blikani


 if (vetev.node1.vyh > -1) then
  begin
   Self.Vyhybky.Data[vetev.node1.vyh].visible := visible;

   case (Self.Vyhybky.Data[vetev.node1.vyh].PanelProp.Poloha) of
    TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:begin
       Self.ShowUsekVetve(usek, usek.Vetve[vetev.node1.ref_plus], NotSymbol, visible);
       Self.ShowUsekVetve(usek, usek.Vetve[vetev.node1.ref_minus], NotSymbol, visible);
     end;//case disable, both, none

    TVyhPoloha.plus, TVyhPoloha.minus:begin
       if ((Integer(Self.Vyhybky.Data[vetev.node1.vyh].PanelProp.Poloha) xor Self.Vyhybky.Data[vetev.node1.vyh].PolohaPlus) = 0) then
        begin
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node1.ref_plus], NotSymbol, visible);
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node1.ref_minus], NotSymbol, false);
        end else begin
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node1.ref_plus], NotSymbol, false);
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node1.ref_minus], NotSymbol, visible);
        end;
     end;//case disable, both, none
   end;//case
  end;

 if (vetev.node2.vyh > -1) then
  begin
   Self.Vyhybky.Data[vetev.node2.vyh].visible := visible;

   case (Self.Vyhybky.Data[vetev.node2.vyh].PanelProp.Poloha) of
    TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:begin
       Self.ShowUsekVetve(usek, usek.Vetve[vetev.node2.ref_plus], NotSymbol, visible);
       Self.ShowUsekVetve(usek, usek.Vetve[vetev.node2.ref_minus], NotSymbol, visible);
     end;//case disable, both, none

    TVyhPoloha.plus, TVyhPoloha.minus:begin
       if ((Integer(Self.Vyhybky.Data[vetev.node2.vyh].PanelProp.Poloha) xor Self.Vyhybky.Data[vetev.node2.vyh].PolohaPlus) = 0) then
        begin
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node2.ref_plus], NotSymbol, visible);
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node2.ref_minus], NotSymbol, false);
        end else begin
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node2.ref_plus], NotSymbol, false);
         Self.ShowUsekVetve(usek, usek.Vetve[vetev.node2.ref_minus], NotSymbol, visible);
        end;
     end;//case disable, both, none
   end;//case
  end;
end;//procedure

procedure TRelief.ShowNavestidla();
var i:Integer;
begin
 Self.StartJC.count := 0;

 for i := 0 to Self.Navestidla.Count-1 do
  begin
   if ((Self.Navestidla.Data[i].PanelProp.blikani) and (Self.Graphics.blik)) then continue;

   SymbolSet.IL_Symbols.BkColor := Self.Navestidla.Data[i].PanelProp.Pozadi;
   if (Self.Navestidla.Data[i].PanelProp.AB) then
    begin
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Navestidla.Data[i].Position.X*SymbolSet._Symbol_Sirka,Self.Navestidla.Data[i].Position.Y*SymbolSet._Symbol_Vyska,((_SCom_Start+Self.Navestidla.Data[i].SymbolID)*10)+Self.Graphics.GetColorIndex(Self.Navestidla.Data[i].PanelProp.Symbol)+20);
    end else begin
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Navestidla.Data[i].Position.X*SymbolSet._Symbol_Sirka,Self.Navestidla.Data[i].Position.Y*SymbolSet._Symbol_Vyska,((_SCom_Start+Self.Navestidla.Data[i].SymbolID)*10)+Self.Graphics.GetColorIndex(Self.Navestidla.Data[i].PanelProp.Symbol));
    end;

   if ((Self.Navestidla.Data[i].PanelProp.Pozadi = clGreen) or (Self.Navestidla.Data[i].PanelProp.Pozadi = clWhite) or (Self.Navestidla.Data[i].PanelProp.Pozadi = clTeal)) then
    begin
     //pridani StartJC
     Self.StartJC.count := Self.StartJC.count + 1;
     Self.StartJC.Data[Self.StartJC.count-1].Color := Self.Navestidla.Data[i].PanelProp.Pozadi;
     Self.StartJC.Data[Self.StartJC.count-1].Pos   := Point(Self.Navestidla.Data[i].Position.X-1,Self.Navestidla.Data[i].Position.Y);

     Self.StartJC.count := Self.StartJC.count + 1;
     Self.StartJC.Data[Self.StartJC.count-1].Color := Self.Navestidla.Data[i].PanelProp.Pozadi;
     Self.StartJC.Data[Self.StartJC.count-1].Pos   := Point(Self.Navestidla.Data[i].Position.X+1,Self.Navestidla.Data[i].Position.Y);
    end;
  end;//for i
end;//procedure

procedure TRelief.ShowPomocneSymboly();
var i,j:Integer;
begin
 //pomocne symboly
 SymbolSet.IL_Symbols.BkColor := clBlack;
 for i := 0 to Self.PomocneObj.Count-1 do
   for j := 0 to Self.PomocneObj.Data[i].Positions.Count-1 do
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.PomocneObj.Data[i].Positions.Data[j].X*SymbolSet._Symbol_Sirka,Self.PomocneObj.Data[i].Positions.Data[j].Y*SymbolSet._Symbol_Vyska,(Self.PomocneObj.Data[i].Symbol*10)+_SpecS_DrawColors[Self.PomocneObj.Data[i].Symbol]);
end;//procedure

procedure TRelief.ShowPopisky();
var i:Integer;
begin
 //popisky
 for i := 0 to Self.Popisky.Count-1 do
  begin
   if (Self.Popisky.Data[i].prejezd_ref > -1) then
    begin
     // popisek ma referenci na prejezd
     if ((Self.Prejezdy.Data[Self.Popisky.Data[i].prejezd_ref].PanelProp.Pozadi = clBlack) or (Self.Prejezdy.Data[Self.Popisky.Data[i].prejezd_ref].PanelProp.Pozadi = clTeal)) then
      begin
       Self.DrawObject.Surface.Canvas.Brush.Color := clGreen;
      end else begin
       Self.DrawObject.Surface.Canvas.Brush.Color := Self.Prejezdy.Data[Self.Popisky.Data[i].prejezd_ref].PanelProp.Pozadi;
      end;

     Self.DrawObject.Surface.Canvas.Pen.Color   := Self.DrawObject.Surface.Canvas.Brush.Color;
     Self.DrawObject.Surface.Canvas.Rectangle((Self.Popisky.Data[i].Position.X-1)*SymbolSet._Symbol_Sirka, Self.Popisky.Data[i].Position.Y*SymbolSet._Symbol_Vyska, (Self.Popisky.Data[i].Position.X)*SymbolSet._Symbol_Sirka, (Self.Popisky.Data[i].Position.Y+1)*SymbolSet._Symbol_Vyska);

     case (Self.Prejezdy.Data[Self.Popisky.Data[i].prejezd_ref].PanelProp.stav) of
       TBlkPrjPanelStav.anulace: begin
        Self.DrawObject.Surface.Canvas.Brush.Color := clWhite;
        Self.DrawObject.Surface.Canvas.Pen.Color   := clWhite;
        Self.DrawObject.Surface.Canvas.Rectangle((Self.Popisky.Data[i].Position.X+1)*SymbolSet._Symbol_Sirka, Self.Popisky.Data[i].Position.Y*SymbolSet._Symbol_Vyska, (Self.Popisky.Data[i].Position.X+2)*SymbolSet._Symbol_Sirka, (Self.Popisky.Data[i].Position.Y+1)*SymbolSet._Symbol_Vyska);
       end;
      end;//case

    end;//if

   Self.Graphics.TextOutput(Self.Popisky.Data[i].Position, Self.Popisky.Data[i].Text, _Symbol_Colors[Self.Popisky.Data[i].Color], clBlack);
  end;//for i
end;//procedure

procedure TRelief.ShowVyhybky();
var i:Integer;
    col:Integer;
begin
 //vyhybky
 for i := 0 to Self.Vyhybky.Count-1 do
  begin
   if ((Self.Vyhybky.Data[i].PanelProp.blikani) and (Self.Graphics.blik) and (Self.Vyhybky.Data[i].visible)) then continue;

   if ((Self.Vyhybky.Data[i].visible) or (Self.Vyhybky.Data[i].PanelProp.Symbol = clAqua)) then
    col := Self.Vyhybky.Data[i].PanelProp.Symbol
   else
    col := $A0A0A0;

   case (Self.Vyhybky.Data[i].PanelProp.Poloha) of
    TVyhPoloha.disabled:begin
     SymbolSet.IL_Symbols.BkColor := clFuchsia;
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Vyhybky.Data[i].Position.X*SymbolSet._Symbol_Sirka,Self.Vyhybky.Data[i].Position.Y*SymbolSet._Symbol_Vyska,((Self.Vyhybky.Data[i].SymbolID)*10)+Self.Graphics.GetColorIndex(clBlack));
    end;
    TVyhPoloha.none:begin
     SymbolSet.IL_Symbols.BkColor := col;
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Vyhybky.Data[i].Position.X*SymbolSet._Symbol_Sirka,Self.Vyhybky.Data[i].Position.Y*SymbolSet._Symbol_Vyska,((Self.Vyhybky.Data[i].SymbolID)*10)+Self.Graphics.GetColorIndex(clBlack));
    end;
    TVyhPoloha.plus:begin
     if (Self.Vyhybky.Data[i].PanelProp.Pozadi = clBlack) then
       SymbolSet.IL_Symbols.BkColor := Self.Useky[Self.Vyhybky.Data[i].obj].PanelProp.Pozadi
     else
       SymbolSet.IL_Symbols.BkColor := Self.Vyhybky.Data[i].PanelProp.Pozadi;
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Vyhybky.Data[i].Position.X*SymbolSet._Symbol_Sirka,Self.Vyhybky.Data[i].Position.Y*SymbolSet._Symbol_Vyska,((Self.Vyhybky.Data[i].SymbolID)*10)+40+(40*(Self.Vyhybky.Data[i].PolohaPlus xor 0))+Self.Graphics.GetColorIndex(col));
    end;
    TVyhPoloha.minus:begin
     if (Self.Vyhybky.Data[i].PanelProp.Pozadi = clBlack) then
       SymbolSet.IL_Symbols.BkColor := Self.Useky[Self.Vyhybky.Data[i].obj].PanelProp.Pozadi
     else
       SymbolSet.IL_Symbols.BkColor := Self.Vyhybky.Data[i].PanelProp.Pozadi;
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Vyhybky.Data[i].Position.X*SymbolSet._Symbol_Sirka,Self.Vyhybky.Data[i].Position.Y*SymbolSet._Symbol_Vyska,((Self.Vyhybky.Data[i].SymbolID)*10)+80-(40*(Self.Vyhybky.Data[i].PolohaPlus xor 0))+Self.Graphics.GetColorIndex(col));
    end;
    TVyhPoloha.both:begin
     SymbolSet.IL_Symbols.BkColor := clYellow;
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Self.Vyhybky.Data[i].Position.X*SymbolSet._Symbol_Sirka,Self.Vyhybky.Data[i].Position.Y*SymbolSet._Symbol_Vyska,((Self.Vyhybky.Data[i].SymbolID)*10)+Self.Graphics.GetColorIndex(clBlack));
    end;
   end;//case
  end;//for i
end;//procedure

//zobrazi vsechny dopravni kancelare
procedure TRelief.ShowDK();
var Color:TColor;
   OblR:TORPanel;
begin
 //projedeme vsechny OR
 for OblR in Self.myORs do
  begin
   if (((OblR.dk_blik) or (OblR.RegPlease.status = TORRegPleaseStatus.selected)) and (Self.Graphics.blik)) then continue;

   case (OblR.tech_rights) of
    read      : Color := clWhite;
    write     : Color := $A0A0A0;
    superuser : Color := clYellow;
   else//case rights
     Color := clFuchsia;
   end;

   if (OblR.RegPlease.status = TORRegPleaseStatus.selected) then
     Color := clYellow;

   SymbolSet.IL_DK.BkColor := clBlack;
   SymbolSet.IL_DK.Draw(Self.DrawObject.Surface.Canvas,OblR.Poss.DK.X*SymbolSet._Symbol_Sirka,OblR.Poss.DK.Y*SymbolSet._Symbol_Vyska,(OblR.Poss.DKOr*10)+Self.Graphics.GetColorIndex(Color));

   // symbol osvetleni se vykresluje vlevo
   if (OblR.dk_osv) then
    SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(OblR.Poss.DK.X*SymbolSet._Symbol_Sirka)-(SymbolSet._Symbol_Sirka*2),(OblR.Poss.DK.Y*SymbolSet._Symbol_Vyska)+SymbolSet._Symbol_Vyska, _Hvezdicka);

   // symbol zadosti o loko se vykresluje vpravo
   if (((OblR.RegPlease.status = TORRegPleaseStatus.request) or (OblR.RegPlease.status = TORRegPleaseStatus.selected)) and (not Self.Graphics.blik)) then
    SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,((OblR.Poss.DK.X+6)*SymbolSet._Symbol_Sirka),((OblR.Poss.DK.Y+1)*SymbolSet._Symbol_Vyska), (_Kolecko*10)+7);

  end;//for i
end;//procedure

//zobrazeni SystemOK + opravneni
procedure TRelief.ShowOpravneni();
var Pos:TPoint;
begin
 Pos.X := 1;
 Pos.Y := Self.Graphics.PanelHeight-3;

 //37, 38, 39
 if (Self.SystemOK.Poloha) then
  begin
   //tady ty silene finty s pozadim uz nikdy nikdo nepochopi...

   SymbolSet.IL_Symbols.BkColor := clPurple;

   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Pos.X*SymbolSet._Symbol_Sirka,(Pos.Y)*SymbolSet._Symbol_Vyska,389);
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+1)*SymbolSet._Symbol_Sirka,(Pos.Y)*SymbolSet._Symbol_Vyska,389);
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+2)*SymbolSet._Symbol_Sirka,(Pos.Y)*SymbolSet._Symbol_Vyska,389);

   SymbolSet.IL_Symbols.BkColor := clPurple;

   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Pos.X*SymbolSet._Symbol_Sirka,(Pos.Y+1)*SymbolSet._Symbol_Vyska,380);
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+1)*SymbolSet._Symbol_Sirka,(Pos.Y+1)*SymbolSet._Symbol_Vyska,380);
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+2)*SymbolSet._Symbol_Sirka,(Pos.Y+1)*SymbolSet._Symbol_Vyska,380);
  end else begin
   SymbolSet.IL_Symbols.BkColor := clPurple;

   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Pos.X*SymbolSet._Symbol_Sirka,(Pos.Y+1)*SymbolSet._Symbol_Vyska,378);
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,Pos.X*SymbolSet._Symbol_Sirka,(Pos.Y)*SymbolSet._Symbol_Vyska,389);

   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+2)*SymbolSet._Symbol_Sirka,(Pos.Y+1)*SymbolSet._Symbol_Vyska,378);
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+2)*SymbolSet._Symbol_Sirka,(Pos.Y)*SymbolSet._Symbol_Vyska,389);

   SymbolSet.IL_Symbols.BkColor := clBlack;

   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+1)*SymbolSet._Symbol_Sirka,(Pos.Y+1)*SymbolSet._Symbol_Vyska,370);
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Pos.X+1)*SymbolSet._Symbol_Sirka,(Pos.Y)*SymbolSet._Symbol_Vyska,390);
  end;

 case (PanelTCPClient.status) of
  TPanelConnectionStatus.closed    : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Spojen� uzav�eno', clFuchsia, clBlack);
  TPanelConnectionStatus.opening   : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Otev�r�m spojen�...', clFuchsia, clBlack);
  TPanelConnectionStatus.handshake : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Prob�h� handshake...', clFuchsia, clBlack);
  TPanelConnectionStatus.opened    : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'P�ipojeno k serveru', clFuchsia, clBlack);
 end;
end;//procedure

procedure TRelief.ShowPrj();
var i,j:Integer;
    usek:Integer;
    sym:TReliefSym;
begin
 for i := 0 to Self.Prejezdy.count-1 do
  begin
   // vykreslit staticke pozice:
   SymbolSet.IL_Symbols.BkColor := Self.Prejezdy.Data[i].PanelProp.Pozadi;
   for j := 0 to Self.Prejezdy.Data[i].StaticPositions.Count-1 do
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, Self.Prejezdy.Data[i].StaticPositions.data[j].X*SymbolSet._Symbol_Sirka, Self.Prejezdy.Data[i].StaticPositions.data[j].Y*SymbolSet._Symbol_Vyska, (_Prj_Start*10)+Self.Graphics.GetColorIndex(Self.Prejezdy.Data[i].PanelProp.Symbol));

   // vykreslit blikajici pozice podle stavu prejezdu:
   if ((Self.Prejezdy.Data[i].PanelProp.stav = TBlkPrjPanelStav.otevreno) or
      (Self.Prejezdy.Data[i].PanelProp.stav = TBlkPrjPanelStav.anulace) or
      (Self.Prejezdy.Data[i].PanelProp.stav = TBlkPrjPanelStav.err) or
      ((Self.Prejezdy.Data[i].PanelProp.stav = TBlkPrjPanelStav.vystraha) and (Self.Graphics.blik))) then
    begin
       // nestaticke pozice proste vykreslime:
       for j := 0 to Self.Prejezdy.Data[i].BlikPositions.Count-1 do
        begin
         // musime smazat pripadne useky navic:

         if (Self.Prejezdy.Data[i].BlikPositions.data[j].PanelUsek > -1) then
          begin
           // porovname, pokud tam uz nahodou neni
           usek := Self.Prejezdy.Data[i].BlikPositions.data[j].PanelUsek;
           if (Self.Useky[usek].Symbols[Self.Useky[usek].Symbols.Count-1].Position.X = Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.X)
           and (Self.Useky[usek].Symbols[Self.Useky[usek].Symbols.Count-1].Position.Y = Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.Y) then
            begin
             // pokud je, odebereme
             Self.Useky[usek].Symbols.Count := Self.Useky[usek].Symbols.Count - 1;
            end;
          end;

         SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.X*SymbolSet._Symbol_Sirka, Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.Y*SymbolSet._Symbol_Vyska, (_Prj_Start*10)+Self.Graphics.GetColorIndex(Self.Prejezdy.Data[i].PanelProp.Symbol));

        end;
    end else begin

       // na nestatickych pozicich vykreslime usek
       // provedeme fintu: pridame pozici prostred prejezdu k useku, ktery tam patri

       if (Self.Prejezdy.Data[i].PanelProp.stav = TBlkPrjPanelStav.vystraha) then continue;       

       for j := 0 to Self.Prejezdy.Data[i].BlikPositions.Count-1 do
        begin
         if (Self.Prejezdy.Data[i].BlikPositions.data[j].PanelUsek > -1) then
          begin
           // porovname, pokud tam uz nahodou neni
           usek := Self.Prejezdy.Data[i].BlikPositions.data[j].PanelUsek;
           if (Self.Useky[usek].Symbols[Self.Useky[usek].Symbols.Count-1].Position.X <> Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.X)
           or (Self.Useky[usek].Symbols[Self.Useky[usek].Symbols.Count-1].Position.Y <> Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.Y) then
            begin
             // pokud neni, pridame:
             sym.Position := Self.Prejezdy.Data[i].BlikPositions.data[j].Pos;
             sym.SymbolID := 12;
             Self.Useky[usek].Symbols.Add(sym);
            end;
          end;

        end;// for j
    end;

  end;//for i
end;//procedure

procedure TRelief.ShowUvazky;
var i:Integer;
begin
 for i := 0 to Self.Uvazky.count-1 do
  begin
   if ((Self.Uvazky.Data[i].PanelProp.blik) and (Self.Graphics.blik)) then
     continue;

   SymbolSet.IL_Symbols.BkColor := Self.Uvazky.Data[i].PanelProp.Pozadi;

   case (Self.Uvazky.Data[i].PanelProp.smer) of
    TUvazkaSmer.disabled, TUvazkaSmer.zadny:begin
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, Self.Uvazky.Data[i].Pos.X*SymbolSet._Symbol_Sirka, Self.Uvazky.Data[i].Pos.Y*SymbolSet._Symbol_Vyska, (_Uvazka_Start*10)+Self.Graphics.GetColorIndex(Self.Uvazky.Data[i].PanelProp.Symbol));
     SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, (Self.Uvazky.Data[i].Pos.X+1)*SymbolSet._Symbol_Sirka, Self.Uvazky.Data[i].Pos.Y*SymbolSet._Symbol_Vyska, ((_Uvazka_Start+1)*10)+Self.Graphics.GetColorIndex(Self.Uvazky.Data[i].PanelProp.Symbol));
    end;

    TUvazkaSmer.zakladni, TUvazkaSmer.opacny:begin
     if (((Self.Uvazky.Data[i].PanelProp.smer = zakladni) and (Self.Uvazky.Data[i].defalt_dir = 0)) or
        ((Self.Uvazky.Data[i].PanelProp.smer = opacny) and (Self.Uvazky.Data[i].defalt_dir = 1))) then
      begin
       // sipka zleva doprava
       SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, Self.Uvazky.Data[i].Pos.X*SymbolSet._Symbol_Sirka, Self.Uvazky.Data[i].Pos.Y*SymbolSet._Symbol_Vyska, (12*10)+Self.Graphics.GetColorIndex(Self.Uvazky.Data[i].PanelProp.Symbol));
       SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, (Self.Uvazky.Data[i].Pos.X+1)*SymbolSet._Symbol_Sirka, Self.Uvazky.Data[i].Pos.Y*SymbolSet._Symbol_Vyska, ((_Uvazka_Start+1)*10)+Self.Graphics.GetColorIndex(Self.Uvazky.Data[i].PanelProp.Symbol));
      end else begin
       // sipka zprava doleva
       SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, Self.Uvazky.Data[i].Pos.X*SymbolSet._Symbol_Sirka, Self.Uvazky.Data[i].Pos.Y*SymbolSet._Symbol_Vyska, ((_Uvazka_Start)*10)+Self.Graphics.GetColorIndex(Self.Uvazky.Data[i].PanelProp.Symbol));
       SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, (Self.Uvazky.Data[i].Pos.X+1)*SymbolSet._Symbol_Sirka, Self.Uvazky.Data[i].Pos.Y*SymbolSet._Symbol_Vyska, (12*10)+Self.Graphics.GetColorIndex(Self.Uvazky.Data[i].PanelProp.Symbol));
      end;
    end;
   end;
  end;
end;//procedure

procedure TRelief.ShowUvazkySpr();
var i, j:Integer;
    top,incr:Integer;
    change:boolean;
    UvazkaSpr:TUvazkaSpr;
begin
 if (Now > Self.uvazky_change_time) then
  begin
   Self.uvazky_change_time := Now + EncodeTime(0, 0, _UVAZKY_BLIK_PERIOD div 1000, _UVAZKY_BLIK_PERIOD mod 1000);
   change := true;
  end else
   change := false;

 // projedeme vsechny uvazky
 for i := 0 to Self.UvazkySpr.count-1 do
  begin
   if (not Assigned(Self.UvazkySpr.Data[i].PanelProp.spr)) then continue;

   top  := Self.UvazkySpr.Data[i].Pos.Y;
   if (Self.UvazkySpr.Data[i].vertical_dir = TUvazkaSprVertDir.top) then
     incr := -1
    else
     incr := 1;

   for j := 0 to Self.UvazkySpr.Data[i].PanelProp.spr.Count-1 do
    begin
     UvazkaSpr := Self.UvazkySpr.Data[i].PanelProp.spr[j];

     if (not Assigned(Self.UvazkySpr.Data[i].PanelProp.spr[j].strings)) then continue;

     // kontrola preblikavani
     if ((change) and (UvazkaSpr.strings.Count > 1)) then
       Inc(UvazkaSpr.show_index);
     if (UvazkaSpr.show_index >= UvazkaSpr.strings.Count) then // tato podminka musi byt vne predchozi podminky
       UvazkaSpr.show_index := 0;

     Self.Graphics.TextOutput(Point(Self.UvazkySpr.Data[i].Pos.X, top),
          Self.UvazkySpr.Data[i].PanelProp.spr[j].strings[UvazkaSpr.show_index],
          Self.UvazkySpr.Data[i].PanelProp.spr[j].color, clBlack, UvazkaSpr.show_index = 0);
     top := top + incr;

     Self.UvazkySpr.Data[i].PanelProp.spr[j] := UvazkaSpr;
    end;//for j
  end;//for i
end;//procedure

//vykresleni pasku mereni casu
procedure TRelief.ShowMereniCasu();
var Time1,Time2:string;
    i, j, k:Integer;
const _delka = 16;
begin
 for j := 0 to Self.myORs.Count-1 do
  begin
   for k := 0 to Self.myORs[j].MereniCasu.Count-1 do
    begin
     Self.Graphics.TextOutput(Point(Self.myORs[j].Poss.Time.X, Self.myORs[j].Poss.Time.Y+k), 'MER.CASU', clRed, clWhite);

     DateTimeToString(Time1, 'ss', Now-Self.myORs[j].MereniCasu[k].Start);
     DateTimeToString(Time2, 'ss', Self.myORs[j].MereniCasu[k].Length);

     for i := 0 to (Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2)-1 do
      SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, (Self.myORs[j].Poss.Time.X+8+i)*SymbolSet._Symbol_Sirka,(Self.myORs[j].Poss.Time.Y+k)*SymbolSet._Symbol_Vyska,372);

     for i := (Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2) to (_delka div 2)-1 do
      SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Self.myORs[j].Poss.Time.X+8+i)*SymbolSet._Symbol_Sirka,(Self.myORs[j].Poss.Time.Y+k)*SymbolSet._Symbol_Vyska,374);

     //vykresleni poloviny symbolu
     SymbolSet.IL_Symbols.BkColor := clWhite;
     if ((Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) mod 2) = 1) then SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,(Self.myORs[j].Poss.Time.X+8+(Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2))*SymbolSet._Symbol_Sirka,(Self.myORs[j].Poss.Time.Y+k)*SymbolSet._Symbol_Vyska,382);

    end;//for i

   // detekce konce mereni casu
   for k := Self.myORs[j].MereniCasu.Count-1 downto 0 do
    begin
     if (Now >= Self.myORs[j].MereniCasu[k].Length + Self.myORs[j].MereniCasu[k].Start) then
      Self.myORs[j].MereniCasu.Delete(k);
    end;
  end;//for j
end;//procedure

procedure TRelief.ShowMsg();
begin
 if (Self.msg.show) then
   Self.Graphics.TextOutput(Point(0, Self.Graphics.PanelHeight-1), Self.msg.msg, clRed, clWhite);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//hlavni zobrazeni celeho reliefu
procedure TRelief.Show();
begin
 try
   if (not Assigned(Self.DrawObject)) then Exit;

   Self.DrawObject.Surface.Canvas.Release();

   Self.DrawObject.Surface.Fill(Self.Colors.Pozadi);

   Self.ShowUvazkySpr();
   Self.ShowUvazky();
   Self.ShowNavestidla();
   Self.ShowPrj();
   Self.ShowPomocneSymboly();
   Self.ShowUseky();
   Self.ShowPopisky();
   Self.ShowVyhybky();
   Self.ShowZamky();
   Self.ShowRozp();
   Self.ShowVykol();
   Self.ShowDK();
   Self.ShowOpravneni();
   Self.ShowZasobniky();
   Self.ShowMereniCasu();
   RucList.Show();
   Self.ShowMsg();
   Self.ShowInfoTimers();
   Errors.Show();

   if (Self.UPO.showing) then Self.UPO.Show();

   if (Self.Menu.showing) then
    begin
     Self.Menu.PaintMenu(Self.DrawObject.Surface.Canvas, Self.CursorDraw.Pos)
    end else begin
     if (GlobConfig.data.panel_mouse = _MOUSE_PANEL) then Self.PaintKurzor();
    end;

   Self.DrawObject.Surface.Canvas.Release();
   Self.DrawObject.Flip;
 except
   Exit();
 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//vykresluje kurzor
procedure TRelief.PaintKurzor();
var  BlendFunc: TBlendFunction;
begin
 if ((Self.CursorDraw.Pos.X < 0) or (Self.CursorDraw.Pos.Y < 0)) then Exit;

 // zkopirujeme si obrazek pod kurzorem jeste pred tim, nez se pres nej prekresli mys
 if (GlobConfig.data.panel_mouse = _MOUSE_PANEL) then
   Self.CursorDraw.Pozadi.Canvas.CopyRect(
      Rect(0, 0, SymbolSet._Symbol_Sirka+2, SymbolSet._Symbol_Vyska+2),
      Self.DrawObject.Surface.Canvas,
      Rect( Self.CursorDraw.Pos.X * SymbolSet._Symbol_Sirka - 1,
            Self.CursorDraw.Pos.Y * SymbolSet._Symbol_Vyska - 1,
            (Self.CursorDraw.Pos.X+1) * SymbolSet._Symbol_Sirka + 1,
            (Self.CursorDraw.Pos.Y+1) * SymbolSet._Symbol_Vyska + 1));

 // nastavime pruhlednost kurzoru
 BlendFunc.BlendOp := AC_SRC_OVER;
 BlendFunc.BlendFlags := 0;
 BlendFunc.SourceConstantAlpha := 100;

 //vykresleni kurzoru
 Self.DrawObject.Surface.Canvas.Pen.Color   := Self.CursorDraw.KurzorRamecek;
 Self.DrawObject.Surface.Canvas.Brush.Color := Self.CursorDraw.KurzorObsah;
 Self.DrawObject.Surface.Canvas.Pen.Mode    := pmMerge;
 Self.DrawObject.Surface.Canvas.Rectangle((Self.CursorDraw.Pos.X*SymbolSet._Symbol_Sirka)-1,(Self.CursorDraw.Pos.Y*SymbolSet._Symbol_Vyska)-1,((Self.CursorDraw.Pos.X*SymbolSet._Symbol_Sirka)+SymbolSet._Symbol_Sirka)+1,((Self.CursorDraw.Pos.Y*SymbolSet._Symbol_Vyska)+SymbolSet._Symbol_Vyska)+1);
 Self.DrawObject.Surface.Canvas.Pen.Mode    := pmCopy;
end;//procedure

// vykresli pozadi pod kurzorem, ktere je ulozeno v Self.CursorDraw.Pozadi
//     na zadane souradnice (v polickach).
procedure TRelief.PaintKurzorBg(Pos:TPoint);
begin
 Self.DrawObject.Surface.Canvas.CopyRect(
      Rect(
          Pos.X * SymbolSet._Symbol_Sirka - 1,
          Pos.Y * SymbolSet._Symbol_Vyska - 1,
          (Pos.X+1) * SymbolSet._Symbol_Sirka + 1,
          (Pos.Y+1) * SymbolSet._Symbol_Vyska + 1),

      Self.CursorDraw.Pozadi.Canvas,

      Rect(0, 0, SymbolSet._Symbol_Sirka+2, SymbolSet._Symbol_Vyska+2)
  );
end;//procedure

procedure TRelief.DXDMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 Self.CursorDraw.Pos.X := X div SymbolSet._Symbol_Sirka;
 Self.CursorDraw.Pos.Y := Y div SymbolSet._Symbol_Vyska;

 case (Button) of
  mbLeft   : Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.left);
  mbMiddle : Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.middle);
  mbRight  : Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.right);
 end;

 Self.Show();
end;//procedure

procedure TRelief.DXDMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
var old:TPoint;
begin
 // pokud se nemeni pozice kurzoru -- ramecku, neni potreba prekreslovat
 if ((X div SymbolSet._Symbol_Sirka = Self.CursorDraw.Pos.X) and (Y div SymbolSet._Symbol_Vyska = Self.CursorDraw.Pos.Y)) then Exit;

 // vytvorime novou pozici a ulozime ji
 old  := Self.CursorDraw.Pos;
 Self.CursorDraw.Pos.X := X div SymbolSet._Symbol_Sirka;
 Self.CursorDraw.Pos.Y := Y div SymbolSet._Symbol_Vyska;

 // skryjeme informacni zpravu vlevo dole
 Self.msg.show := false;

 // pokud je zobrazeno menu, prekreslime pouze menu
 if ((Self.Menu.showing) and (Self.Menu.CheckCursorPos(Self.CursorDraw.Pos))) then Exit();

 // zavolame vnejsi event
 if (Assigned(Self.FOnMove)) then Self.FOnMove(Self, Self.CursorDraw.Pos);

 // panel prekreslujeme jen kdyz je nutne vykreslovat mys na panelu
 // pokud se vyjresluje mys operacniho systemu, panel neni prekreslovan
 if ((GlobConfig.data.panel_mouse = _MOUSE_PANEL) or (Self.Menu.showing)) then
  begin
   // neprekreslujeme cely panel, ale pouze policko, na kterem byla mys v minule pozici
   //  obsah tohoto policka je ulozen v Self.CursorDraw.History
   if (Self.Menu.showing) then
     Self.Menu.PaintMenu(Self.DrawObject.Surface.Canvas, Self.CursorDraw.Pos)
   else begin
     Self.PaintKurzorBg(old);
     Self.PaintKurzor();
   end;

   // prekreslime si platno
   try
     Self.DrawObject.Surface.Canvas.Release();
     Self.DrawObject.Flip();
   except

   end;
  end;
end;//procedure

function TRelief.GetUsek(Pos:TPoint):Integer;
var i,j:Integer;
begin
 Result := -1;

 for i := 0 to Self.Useky.Count-1 do
   for j := 0 to Self.Useky[i].Symbols.Count-1 do
     if ((Pos.X = Self.Useky[i].Symbols[j].Position.X) and (Pos.Y = Self.Useky[i].Symbols[j].Position.Y)) then
       Exit(i);
end;//function

function TRelief.GetNav(Pos:TPoint):Integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.Navestidla.Count-1 do
   if ((Pos.X = Self.Navestidla.Data[i].Position.X) and (Pos.Y = Self.Navestidla.Data[i].Position.Y)) then
     Exit(i);
end;//function

function TRelief.GetVyh(Pos:TPoint):Integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.Vyhybky.Count-1 do
   if ((Pos.X = Self.Vyhybky.Data[i].Position.X) and (Pos.Y = Self.Vyhybky.Data[i].Position.Y)) then
     Exit(i);
end;//function

function TRelief.GetRozp(Pos:TPoint):Integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.Rozp.Count-1 do
   if ((Pos.X = Self.Rozp[i].Pos.X) and (Pos.Y = Self.Rozp[i].Pos.Y)) then
     Exit(i);
end;//function

function TRelief.GetPrj(Pos:TPoint):Integer;
var i, j:Integer;
begin
 Result := -1;

 // kontrola prejezdu:
 for i := 0 to Self.Prejezdy.Count-1 do
  begin
   for j := 0 to Self.Prejezdy.Data[i].StaticPositions.Count-1 do
     if ((Pos.X = Self.Prejezdy.Data[i].StaticPositions.data[j].X) and (Pos.Y = Self.Prejezdy.Data[i].StaticPositions.data[j].Y)) then
       Exit(i);

   for j := 0 to Self.Prejezdy.Data[i].BlikPositions.Count-1 do
     if ((Pos.X = Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.X) and (Pos.Y = Self.Prejezdy.Data[i].BlikPositions.data[j].Pos.Y)) then
       Exit(i);

  end;//for i

 // dale je take zapotrebi zkontrolovat popisky:
 for i := 0 to Self.Popisky.Count-1 do
  begin
   if (Self.Popisky.Data[i].prejezd_ref < 0) then continue;

   if ((Pos.X >= Self.Popisky.Data[i].Position.X-1) and (Pos.X <= Self.Popisky.Data[i].Position.X+1) and (Pos.Y = Self.Popisky.Data[i].Position.Y)) then
     Exit(Self.Popisky.Data[i].prejezd_ref);
  end;//for i
end;//function

//vraci index ve svem poli symbolu
function TRelief.GetUsek(tech_id:Integer):Integer;
var i:Integer;
begin
 for i := 0 to Self.Useky.Count-1 do
   if (tech_id = Self.Useky[i].Blok) then
     Exit(i);

 Result := -1;
end;//function

function TRelief.GetPrj(tech_id:Integer):Integer;
var i:Integer;
begin
 for i := 0 to Self.Prejezdy.Count-1 do
   if (tech_id = Self.Prejezdy.Data[i].Blok) then
     Exit(i);

 Result := -1;
end;//function

function TRelief.GetZamek(Pos:TPoint):Integer;
var i:Integer;
begin
 for i := 0 to Self.Zamky.Count-1 do
   if ((pos.X = Self.Zamky.Data[i].Pos.X) and (pos.Y = Self.Zamky.Data[i].Pos.Y)) then
     Exit(i);
 Result := -1;
end;//function

////////////////////////////////////////////////////////////////////////////////

//vyvolano pri kliku na relief
procedure TRelief.ObjectMouseUp(Position:TPoint; Button:TPanelButton);
var i, index:Integer;
    handled:boolean;
begin
 if (Self.Menu.showing) then
  begin
   if (Button = TPanelButton.left) then Self.Menu.Click()
     else if (Button = TPanelButton.right) then Self.Escape();
   Exit;
  end;

 // nabidka regulatoru u dopravni kancelare
 handled := false;
 for i := 0 to Self.myORs.Count-1 do
  begin
   if (Self.myORs[i].tech_rights < TORControlRights.write) then continue;
   if ((Self.myORs[i].RegPlease.status > TORRegPleaseStatus.null) and (Position.X = Self.myORs[i].Poss.DK.X+6) and (Position.Y = Self.myORs[i].Poss.DK.Y+1)) then
    begin
     if ((Button = F2) or (Button = left)) then
      begin
       case (Self.myORs[i].RegPlease.status) of
         TORRegPleaseStatus.request  : Self.myORs[i].RegPlease.status := TORRegPleaseStatus.selected;
         TORRegPleaseStatus.selected : Self.myORs[i].RegPlease.status := TORRegPleaseStatus.request;
       end;//case
     end else
       if (Button = right) then
         Self.ShowRegMenu(i);

     Exit();
    end;
  end;//for OblR

 // zasobniky
 handled := false;
 for i := 0 to Self.myORs.Count-1 do
  begin
   if (Self.myORs[i].tech_rights = TORControlRights.null) then continue;
   Self.myORs[i].stack.MouseClick(Position, Button, handled);
   if (handled) then Exit();
  end;

 //prejezd
 index := Self.GetPrj(Position);
 if (index <> -1) then
  begin
   PanelTCPClient.PanelClick(Self.myORs[Self.Prejezdy.Data[index].OblRizeni].id, Self.Prejezdy.Data[index].Blok, Button);
   Exit;
  end;

 //rozpojovac
 index := Self.GetRozp(Position);
 if (index <> -1) then
  begin
   PanelTCPClient.PanelClick(Self.myORs[Self.Rozp[index].OblRizeni].id, Self.Rozp[index].Blok, Button);
   Exit;
  end;

 //usek
 index := Self.GetUsek(Position);
 if (index <> -1) then
  begin
   // kliknutim na usek pri zadani o lokomotivu vybereme hnaciho vozidla na souprave v tomto useku
   if ((Self.myORs[Self.Useky[index].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected) and (Button = left)) then
     //  or;LOK-REQ;U-PLEASE;blk_id              - zadost o vydani seznamu hnacich vozidel na danem useku
     PanelTCPClient.SendLn(Self.myORs[Self.Useky[index].OblRizeni].id + ';LOK-REQ;U-PLEASE;' + IntToStr(Self.Useky[index].Blok))
   else
     PanelTCPClient.PanelClick(Self.myORs[Self.Useky[index].OblRizeni].id, Self.Useky[index].Blok, Button);
   Exit;
  end;

 //navestidlo
 index := Self.GetNav(Position);
 if (index <> -1) then
  begin
   PanelTCPClient.PanelClick(Self.myORs[Self.Navestidla.Data[index].OblRizeni].id, Self.Navestidla.Data[index].Blok, Button);
   Exit;
  end;

 //vyhybka
 index := Self.GetVyh(Position);
 if (index <> -1) then
  begin
   PanelTCPClient.PanelClick(Self.myORs[Self.Vyhybky.Data[index].OblRizeni].id, Self.Vyhybky.Data[index].Blok, Button);
   Exit;
  end;

 //DK
 index := Self.GetDK(Position);
 if (index <> -1) then
  begin
   if (Self.myORs[index].dk_click_server) then
    begin
     PanelTCPClient.SendLn(Self.myORs[index].id+';DK-CLICK;'+IntToStr(Integer(Button)));
    end else
     Self.ShowDKMenu(index);
   Exit();
  end;

 //uvazka
 index := Self.GetUvazka(Position);
 if (index <> -1) then
  begin
   PanelTCPClient.PanelClick(Self.myORs[Self.Uvazky.Data[index].OblRizeni].id, Self.Uvazky.Data[index].Blok, Button);
   Exit;
  end;

 //zamek
 index := Self.GetZamek(Position);
 if (index <> -1) then
  begin
   PanelTCPClient.PanelClick(Self.myORs[Self.Zamky.Data[index].OblRizeni].id, Self.Zamky.Data[index].Blok, Button);
   Exit;
  end;

 if (Button = right) then
  Self.Escape();
end;//procedure

function TRelief.FLoad(aFile:string):Byte;
var i,j,k:Integer;
    inifile:TMemIniFile;
    BlkNazvy,sect_str,obl_rizeni:TStrings;
    Obj:string;
    return:Integer;
    ver:string;

    symbol:TReliefSym;
    pos:TPoint;
    count, count2:Integer;
    Vetev:TVetev;
    Usek:TPReliefUsk;
    vykol:TPVykol;
    rozp:TPRozp;
begin
 Self.ResetData();

 //kontrola existence
 if (not FileExists(aFile)) then Exit(1);

 //samotne nacitani dat
 try
   inifile := TMemIniFile.Create(aFile);
 except
  Exit(3);
 end;

 Self.Graphics.PanelWidth := inifile.ReadInteger('P','W',0);
 Self.Graphics.PanelHeight := inifile.ReadInteger('P','H',0);

 //kontrola verze
 ver := inifile.ReadString('G','ver',_FileVersion);
 if (_FileVersion <> ver) then
  begin
   if (Application.MessageBox(PChar('Na��t�te soubor s verz� '+ver+#13#10+'Aplikace moment�ln� podporuje verzi '+_FileVersion+#13#10+'Chcete pokra�ovat?'), 'Varov�n�', MB_YESNO OR MB_ICONQUESTION) = mrNo) then
    begin
     Result := 2;
     Exit;
    end;
  end;

 //oblasti rizeni
 sect_str := TStringList.Create();
 obl_rizeni := TStringList.Create();
 inifile.ReadSection('OR',sect_str);
 for i := 0 to sect_str.Count-1 do
    obl_rizeni.Add(inifile.ReadString('OR',sect_str[i],''));

 return := Self.ORLoad(obl_rizeni);
 if (return <> 0) then
  begin
   Result := return+8;
   Exit;
  end;

 sect_str.Free();
 obl_rizeni.Free();


 BlkNazvy := TStringList.Create;

 Self.Navestidla.Count  := inifile.ReadInteger('P', 'N',   0);
 Self.PomocneObj.Count  := inifile.ReadInteger('P', 'P',   0);
 Self.Popisky.Count     := inifile.ReadInteger('P', 'T',   0);
 Self.Vyhybky.count     := inifile.ReadInteger('P', 'V',   0);
 Self.Prejezdy.count    := inifile.ReadInteger('P', 'PRJ', 0);
 Self.Uvazky.count      := inifile.ReadInteger('P', 'Uv',  0);
 Self.UvazkySpr.count   := inifile.ReadInteger('P', 'UvS', 0);
 Self.Zamky.count       := inifile.ReadInteger('P', 'Z',   0);
 BlkNazvy.Free;

 //useky
 count := inifile.ReadInteger('P', 'U', 0);
 for i := 0 to count-1 do
  begin
   usek.Blok      := inifile.ReadInteger('U'+IntToStr(i),'B',-1);
   usek.OblRizeni := inifile.ReadInteger('U'+IntToStr(i),'OR',-1);

   //Symbols
   usek.Symbols := TList<TReliefSym>.Create();
   obj := inifile.ReadString('U'+IntToStr(i),'S', '');
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
   obj := inifile.ReadString('U'+IntToStr(i),'C','');
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
   obj := inifile.ReadString('U'+IntToStr(i),'P','');
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
   usek.KpopisekStr := inifile.ReadString('U'+IntToStr(i),'N','');
   usek.Vetve := TList<TVetev>.Create();

   //nacitani vetvi:
   count2 := inifile.ReadInteger('U'+IntToStr(i), 'VC', 0);
   for j := 0 to count2-1 do
    begin
     obj := inifile.ReadString('U'+IntToStr(i), 'V'+IntToStr(j), '');

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
   usek.PanelProp := _Def_Usek_Prop;

   Self.Useky.Add(usek);
   Self.AddToTechBlk(_BLK_USEK, usek.Blok, Self.Useky.Count-1);
  end;//for i

 //navestidla
 for i := 0 to Self.Navestidla.Count-1 do
  begin
   Self.Navestidla.Data[i].Blok       := inifile.ReadInteger('N'+IntToStr(i),'B',-1);
   Self.Navestidla.Data[i].Position.X := inifile.ReadInteger('N'+IntToStr(i),'X',0);
   Self.Navestidla.Data[i].Position.Y := inifile.ReadInteger('N'+IntToStr(i),'Y',0);
   Self.Navestidla.Data[i].SymbolID   := inifile.ReadInteger('N'+IntToStr(i),'S',0);

   //OR
   Self.Navestidla.Data[i].OblRizeni := inifile.ReadInteger('N'+IntToStr(i),'OR',-1);

   //default settings:
   Self.Navestidla.Data[i].PanelProp := _Def_Nav_Prop;

   Self.AddToTechBlk(_BLK_SCOM, Self.Navestidla.Data[i].Blok, i);
  end;//for i

 //pomocne symboly
 for i := 0 to Self.PomocneObj.Count-1 do
  begin
   Self.PomocneObj.Data[i].Symbol :=  inifile.ReadInteger('P'+IntToStr(i),'S',0);

   obj := inifile.ReadString('P'+IntToStr(i),'P','');
   Self.PomocneObj.Data[i].Positions.Count := (Length(obj) div 6);
   for j := 0 to Self.PomocneObj.Data[i].Positions.Count-1 do
    begin
     Self.PomocneObj.Data[i].Positions.Data[j].X := StrToIntDef(copy(obj,j*6+1,3),0);
     Self.PomocneObj.Data[i].Positions.Data[j].Y := StrToIntDef(copy(obj,j*6+4,3),0);
    end;//for j
  end;//for i

 //vyhybky
 for i := 0 to Self.Vyhybky.count-1 do
  begin
   Self.Vyhybky.Data[i].Blok        := inifile.ReadInteger('V'+IntToStr(i),'B',-1);
   Self.Vyhybky.Data[i].SymbolID    := inifile.ReadInteger('V'+IntToStr(i),'S',0);
   Self.Vyhybky.Data[i].PolohaPlus  := inifile.ReadInteger('V'+IntToStr(i),'P',0);
   Self.Vyhybky.Data[i].Position.X  := inifile.ReadInteger('V'+IntToStr(i),'X',0);
   Self.Vyhybky.Data[i].Position.Y  := inifile.ReadInteger('V'+IntToStr(i),'Y',0);
   Self.Vyhybky.Data[i].obj         := inifile.ReadInteger('V'+IntToStr(i),'O',-1);

   //OR
   Self.Vyhybky.Data[i].OblRizeni := inifile.ReadInteger('V'+IntToStr(i),'OR',-1);

   //default settings:
   Self.Vyhybky.Data[i].visible   := true;
   Self.Vyhybky.Data[i].PanelProp := _Def_Vyh_Prop;

   Self.AddToTechBlk(_BLK_VYH, Self.Vyhybky.Data[i].Blok, i);
  end;

 //prejezdy
 for i := 0 to Self.Vyhybky.count-1 do
  begin
   Self.Prejezdy.Data[i].Blok        := inifile.ReadInteger('PRJ'+IntToStr(i), 'B', -1);
   Self.Prejezdy.Data[i].OblRizeni   := inifile.ReadInteger('PRJ'+IntToStr(i), 'OR', -1);

   obj := inifile.ReadString('PRJ'+IntToStr(i), 'BP', '');
   Self.Prejezdy.Data[i].BlikPositions.Count := (Length(obj) div 9);
   for j := 0 to Self.Prejezdy.Data[i].BlikPositions.Count-1 do
    begin
     Self.Prejezdy.Data[i].BlikPositions.Data[j].Pos.X := StrToIntDef(copy(obj, j*9+1, 3), 0);
     Self.Prejezdy.Data[i].BlikPositions.Data[j].Pos.Y := StrToIntDef(copy(obj, j*9+4, 3), 0);
     Self.Prejezdy.Data[i].BlikPositions.Data[j].PanelUsek := Self.GetUsek(StrToIntDef(copy(obj, j*9+7, 3), 0));
    end;//for j

   obj := inifile.ReadString('PRJ'+IntToStr(i), 'SP', '');
   Self.Prejezdy.Data[i].StaticPositions.Count := (Length(obj) div 6);
   for j := 0 to Self.Prejezdy.Data[i].StaticPositions.Count-1 do
    begin
     Self.Prejezdy.Data[i].StaticPositions.Data[j].X := StrToIntDef(copy(obj, j*6+1, 3), 0);
     Self.Prejezdy.Data[i].StaticPositions.Data[j].Y := StrToIntDef(copy(obj, j*6+4, 3), 0);
    end;//for j

   //default settings:
   Self.Prejezdy.Data[i].PanelProp := _Def_Prj_Prop;

   Self.AddToTechBlk(_BLK_PREJEZD, Self.Prejezdy.Data[i].Blok, i);
  end;

 //popisky
 for i := 0 to Self.Popisky.Count - 1 do
  begin
   Self.Popisky.Data[i].Text        := inifile.ReadString('T'+IntToStr(i),'T','0');
   Self.Popisky.Data[i].Position.X  := inifile.ReadInteger('T'+IntToStr(i),'X',0);
   Self.Popisky.Data[i].Position.Y  := inifile.ReadInteger('T'+IntToStr(i),'Y',0);
   Self.Popisky.Data[i].Color       := inifile.ReadInteger('T'+IntToStr(i),'C',0);
   Self.Popisky.Data[i].prejezd_ref := Self.GetPrj(inifile.ReadInteger('T'+IntToStr(i),'B', -1));
  end;//for i

 // uvazky
 for i := 0 to Self.Uvazky.Count-1 do
  begin
   Self.Uvazky.Data[i].Blok        := inifile.ReadInteger('Uv'+IntToStr(i), 'B', -1);
   Self.Uvazky.Data[i].OblRizeni   := inifile.ReadInteger('Uv'+IntToStr(i), 'OR', -1);
   Self.Uvazky.Data[i].Pos.X       := inifile.ReadInteger('Uv'+IntToStr(i), 'X', 0);
   Self.Uvazky.Data[i].Pos.Y       := inifile.ReadInteger('Uv'+IntToStr(i), 'Y', 0);
   Self.Uvazky.Data[i].defalt_dir  := inifile.ReadInteger('Uv'+IntToStr(i), 'D', 0);
   Self.Uvazky.Data[i].PanelProp   := Self._Def_Uvazka_Prop;

   Self.AddToTechBlk(_BLK_UVAZKA, Self.Uvazky.Data[i].Blok, i);
  end;//for i

 // uvazky soupravy
 for i := 0 to Self.UvazkySpr.count-1 do
  begin
   Self.UvazkySpr.Data[i].Blok         := inifile.ReadInteger('UvS'+IntToStr(i), 'B', -1);
   Self.UvazkySpr.Data[i].OblRizeni    := inifile.ReadInteger('UvS'+IntToStr(i), 'OR', -1);
   Self.UvazkySpr.Data[i].Pos.X        := inifile.ReadInteger('UvS'+IntToStr(i), 'X', 0);
   Self.UvazkySpr.Data[i].Pos.Y        := inifile.ReadInteger('UvS'+IntToStr(i), 'Y', 0);
   Self.UvazkySpr.Data[i].vertical_dir := TUvazkaSprVertDir(inifile.ReadInteger('UvS'+IntToStr(i), 'VD', 0));
   Self.UvazkySpr.Data[i].spr_cnt      := inifile.ReadInteger('UvS'+IntToStr(i), 'C', 1);
   Self.UvazkySpr.Data[i].PanelProp    := Self._Def_UvazkaSpr_Prop;
   Self.UvazkySpr.Data[i].PanelProp.spr := TList<TUvazkaSpr>.Create();

   Self.AddToTechBlk(_BLK_UVAZKA_SPR, Self.UvazkySpr.Data[i].Blok, i);
  end;//for i

 // zamky
 for i := 0 to Self.Zamky.count-1 do
  begin
   Self.Zamky.Data[i].Blok         := inifile.ReadInteger('Z'+IntToStr(i), 'B', -1);
   Self.Zamky.Data[i].OblRizeni    := inifile.ReadInteger('Z'+IntToStr(i), 'OR', -1);
   Self.Zamky.Data[i].Pos.X        := inifile.ReadInteger('Z'+IntToStr(i), 'X', 0);
   Self.Zamky.Data[i].Pos.Y        := inifile.ReadInteger('Z'+IntToStr(i), 'Y', 0);
   Self.Zamky.Data[i].PanelProp    := Self._Def_Zamek_Prop;

   Self.AddToTechBlk(_BLK_ZAMEK, Self.Zamky.Data[i].Blok, i);
  end;//for i

 // vykolejky
 Self.Vykol.Clear();
 count := inifile.ReadInteger('P', 'Vyk', 0);
 for i := 0 to count-1 do
  begin
   vykol.Blok                      := inifile.ReadInteger('Vyk'+IntToStr(i), 'B', -1);
   vykol.OblRizeni                 := inifile.ReadInteger('Vyk'+IntToStr(i), 'OR', -1);
   vykol.Pos.X                     := inifile.ReadInteger('Vyk'+IntToStr(i), 'X', 0);
   vykol.Pos.Y                     := inifile.ReadInteger('Vyk'+IntToStr(i), 'Y', 0);
   vykol.usek                      := inifile.ReadInteger('Vyk'+IntToStr(i), 'O', -1);
   vykol.vetev                     := inifile.ReadInteger('Vyk'+IntToStr(i), 'V', -1);
   vykol.symbol                    := inifile.ReadInteger('Vyk'+IntToStr(i), 'T', 0);
   vykol.PanelProp                 := Self._Def_Vyh_Prop;
   Self.Vykol.Add(vykol);

   Self.AddToTechBlk(_BLK_VYKOL, vykol.Blok, i);
  end;//for i

 // rozpojovace
 Self.Rozp.Clear();
 count := inifile.ReadInteger('P', 'R', 0);
 for i := 0 to count-1 do
  begin
   rozp.Blok                      := inifile.ReadInteger('R'+IntToStr(i), 'B', -1);
   rozp.OblRizeni                 := inifile.ReadInteger('R'+IntToStr(i), 'OR', -1);
   rozp.Pos.X                     := inifile.ReadInteger('R'+IntToStr(i), 'X', 0);
   rozp.Pos.Y                     := inifile.ReadInteger('R'+IntToStr(i), 'Y', 0);
   rozp.PanelProp                 := Self._Def_Rozp_Prop;
   Self.Rozp.Add(rozp);

   Self.AddToTechBlk(_BLK_ROZP, rozp.Blok, i);
  end;//for i

 inifile.Free;
 Result := 0;
end;//procedure LoadFile

//vrati pozice, kde se ma zacit vypisovat text soupravy
function TRelief.GetSprPaintPos(usek:integer;sprlength:integer):TPointArray;
var i:Integer;
    length:integer;
begin
 if (usek >= Self.Useky.Count) then Exit;

 Result.count := Self.Useky[usek].KPopisek.Count;

 for i := 0 to Self.Useky[usek].KPopisek.Count-1 do
  begin
   length := 1;
   Result.Data[i] := Self.Useky[usek].KPopisek[i]; //y zustava konstantni - text jde jen vertikalne, X jen vychozi hodnota

   while (true) do //zde se opakuje pridani policka doprava, doleva, doprava, doleva,... tim je definovano, ze se text rozsiruje primarne doprava
    begin
     //doprava
     length := length + 1;
     if (length >= sprlength) then Exit;

     //doleva
     Result.Data[i].X := Result.Data[i].X - 1;
     length := length + 1;
     if (length >= sprlength) then Exit;
    end;//while
  end;//for i
end;//function

function TRelief.GetDK(Pos:TPoint):Integer;
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   if ((Pos.X >= Self.myORs[i].Poss.DK.X) and (Pos.Y >= Self.myORs[i].Poss.DK.Y) and (Pos.X <= Self.myORs[i].Poss.DK.X+(((_DK_Sirka*SymbolSet._Symbol_Sirka)-1) div SymbolSet._Symbol_Sirka)) and (Pos.Y <= Self.myORs[i].Poss.DK.Y+(((_DK_Vyska*SymbolSet._Symbol_Vyska)-1) div SymbolSet._Symbol_Vyska))) then
     Exit(i);

 Result := -1;
end;//function

function TRelief.GetUvazka(Pos:TPoint):integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.Uvazky.count-1 do
   if ((Pos.X >= Self.Uvazky.Data[i].Pos.X) and (Pos.Y = Self.Uvazky.Data[i].Pos.Y) and (Pos.X <= Self.Uvazky.Data[i].Pos.X+1)) then
     Exit(i);
end;//function

//reset dat
procedure TRelief.ResetData;
var i:Integer;
begin
 //vymazani dat
 for i := 0 to Self.Useky.Count-1 do
  begin
   Self.Useky[i].Symbols.Count  := 0;
   Self.Useky[i].JCClick.Count  := 0;
   Self.Useky[i].KPopisek.Count := 0;
  end;//for i

 Self.Useky.Count      := 0;
 Self.Popisky.Count    := 0;
 Self.Navestidla.Count := 0;
 Self.Vyhybky.count    := 0;

 Self.Tech_blok.Clear();

 for i := 0 to Self.PomocneObj.Count-1 do Self.PomocneObj.Data[i].Positions.Count := 0;
 Self.PomocneObj.Count := 0;
end;//procedure NewFile

procedure TRelief.AEMessage(var Msg: tagMSG;var Handled: Boolean);
var mouse:TPoint;
    ahandled:boolean;
    i:Integer;
begin
 if ((msg.message = WM_KeyDown) and (Self.ParentForm.Active)) then //pokud je stisknuta klavesa
  begin
   if (Errors.Count > 0) then
    begin
     case  (msg.wParam) of
       VK_BACK, VK_RETURN: Errors.removeerror();
     end;// case msg.wParam
     Exit();
    end;

   ahandled := false;
   if (Self.Menu.showing) then Self.Menu.KeyPress(msg.wParam, ahandled);
   if (ahandled) then Exit();

   if (Self.UPO.showing) then Self.UPO.KeyPress(msg.wParam, ahandled);
   if (ahandled) then
    begin
     Self.Show();
     Exit();
    end;

   ahandled := false;
   for i := 0 to Self.myORs.Count-1 do
    begin
     Self.myORs[i].stack.KeyPress(msg.wParam, ahandled);
     if (ahandled) then Exit();
    end;//for i

   case  (msg.wParam) of                                     //case moznosti stisknutych klaves
     VK_F2 : Self.ObjectMouseUp(Self.CursorDraw.Pos, F2);
     VK_F3 : Self.ObjectMouseUp(Self.CursorDraw.Pos, F3);
     VK_ESCAPE:begin
      Self.Escape();
     end;

     VK_BACK: Errors.removeerror();

     VK_RETURN:begin
       Self.DXDMouseUp(Self.DrawObject, mbLeft, [], Self.CursorDraw.Pos.X * SymbolSet._Symbol_Sirka, Self.CursorDraw.Pos.Y * SymbolSet._Symbol_Vyska);
     end;

     VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT:begin
      GetCursorPos(mouse);

      case (msg.wParam) of
       VK_LEFT  : mouse.X := mouse.X - SymbolSet._Symbol_Sirka;
       VK_RIGHT : mouse.X := mouse.X + SymbolSet._Symbol_Sirka;
       VK_UP    : mouse.Y := mouse.Y - SymbolSet._Symbol_Vyska;
       VK_DOWN  : mouse.Y := mouse.Y + SymbolSet._Symbol_Vyska;
      end;

      SetCursorPos(mouse.X, mouse.Y);
     end;

     VK_F9: begin
      Self.root_menu := not Self.root_menu;
      if (Self.root_menu) then Self.ORInfoMsg('Root menu on')
      else Self.ORInfoMsg('Root menu off');
     end;
   end;//case
  end;//if
end;//procedure

procedure TRelief.T_SystemOKOnTimer(Sender:TObject);
begin
 Self.SystemOK.Poloha := not Self.SystemOK.Poloha;
 Self.Graphics.blik   := not Self.Graphics.blik;
end;//procedure

procedure TRelief.Escape();
var OblR:TORPanel;
begin
 if (Self.Menu.showing) then Self.HideMenu();
 if (F_StitVyl.Showing) then F_StitVyl.Close();
 if (F_SoupravaEdit.Showing) then F_SoupravaEdit.Close;
 if (F_Settings.Showing) then F_Settings.Close();
 if (F_PotvrSekv.Showing) then PotvrSek.Stop('escape');

 for OblR in Self.myORs do
   if (OblR.RegPlease.status = TORRegPleaseStatus.selected) then
      OblR.RegPlease.status := TORRegPleaseStatus.request;

 PanelTCPClient.PanelEscape();
end;//procedure

//ziskani vyhybke, ktere jsou navazany na usek v parametru
function TRelief.GetUsekVyhybky(usekid:integer):TGetVyhybky;
var i:Integer;
begin
 Result.Count := 0;

 for i := 0 to Self.Vyhybky.count-1 do
  begin
   if (Self.Useky[Self.Vyhybky.Data[i].obj].Blok = usekid) then
    begin
     Result.Data[Result.Count] := Self.Vyhybky.Data[i].Blok;
     Result.Count := Result.Count + 1;
    end;
  end;
end;//function

function TRelief.GetUsekID(BlokTechnolgie:integer):TArSmallI;
var i:Integer;
begin
 SetLength(Result,0);

 for i := 0 to Self.Vyhybky.Count-1 do
  begin
   if (Self.Vyhybky.Data[i].Blok = BlokTechnolgie) then
    begin
     SetLength(Result,Length(Result)+1);
     Result[Length(Result)-1] := Self.Useky[Self.Vyhybky.Data[i].obj].Blok;
    end;
  end;//for i
end;//function

function TRelief.AddMereniCasu(Sender:string; Delka:TDateTime; id:Integer):byte;
var orindex:Integer;
    mc:TMereniCasu;
begin
 for orindex := 0 to Self.myORs.Count-1 do
  if (Self.myORs[orindex].id = Sender) then
    break;
 if (orindex = Self.myORs.Count) then Exit(2);

 mc.Start    := Now;
 mc.Length   := Delka;
 mc.id       := id;
 Self.myORs[orindex].MereniCasu.Add(mc);

 Result := 0;
end;//function

procedure TRelief.StopMereniCasu(Sender:string; id:Integer);
var orindex, i:Integer;
begin
 for orindex := 0 to Self.myORs.Count-1 do
  if (Self.myORs[orindex].id = Sender) then
    break;
 if (orindex = Self.myORs.Count) then Exit;

 for i := 0 to Self.myORs[orindex].MereniCasu.Count-1 do
   if (Self.myORs[orindex].MereniCasu[i].id = id) then
    begin
     Self.myORs[orindex].MereniCasu.Delete(i);
     break;
    end;
end;//procedure

procedure TRelief.Image(filename:string);
var Bmp:TBitmap;
    x,y:Cardinal;
    PR,PG,PB:^Byte;
    PYStart:Cardinal;
    aColor:TColor;
    png: TPngImage;
begin
 Self.CursorDraw.Pos.X := -2;

 Self.Show();

 Bmp := TBitmap.Create;
 Bmp.PixelFormat  := pf24bit;
 Bmp.Width  := Self.DrawObject.Width;
 Bmp.Height := Self.DrawObject.Height;
 Bmp.Canvas.CopyRect(Rect(0,0,Self.DrawObject.Width,Self.DrawObject.Height),Self.DrawObject.Surface.Canvas,Rect(0,0,Self.DrawObject.Width,Self.DrawObject.Height));

 //zmena barev
 for y := 0 to Bmp.Height-1 do
  begin
   PYStart := Cardinal(Bmp.ScanLine[y]);
   for x := 0 to Bmp.Width-1 do
    begin
     PB := Pointer(PYStart + 3*x);
     PG := Pointer(PYStart + 3*x + 1);
     PR := Pointer(PYStart + 3*x + 2);

     aColor := PR^ + (PG^ shl 8) + (PB^ shl 16);
     if (aColor = clBlack) then
      begin
       PR^ := 255;
       PG^ := 255;
       PB^ := 255;
      end else begin
      if ((aColor = clWhite) or (aColor = clGray)
        or (aColor = clSilver) or (aColor = $A0A0A0)) then
        begin
         PR^ := 0;
         PG^ := 0;
         PB^ := 0;
        end;
      end;
    end;//for x
  end;//for y


 if (RightStr(filename, 3) = 'bmp') then
   Bmp.SaveToFile(filename)
 else begin
   png := TPngImage.Create;
   png.Assign(bmp);
   png.SaveToFile(filename);
   FreeAndNil(png);
 end;

 FreeAndNil(Bmp);
end;//procedure

procedure TRelief.HideCursor();
begin
 if (self.CursorDraw.Pos.X >= 0) then
  begin
   Self.CursorDraw.Pos.X := -2;
   Self.Show();
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////
//komunikace s oblastmi rizeni:

//odpoved na autorizaci:
procedure TRelief.ORAuthoriseResponse(Sender:string; Rights:TORControlRights; comment:string='');
var i,orindex:Integer;
    tmp:TORControlRights;
begin
 orindex := -1;
 for i := 0 to Self.myORs.Count-1 do
  if (Self.myORs[i].id = Sender) then orindex := i;

 if (orindex = -1) then Exit;

 tmp := Self.myORs[orindex].tech_rights;
 Self.myORs[orindex].tech_rights := Rights;

 if ((Rights < tmp) and (Rights < write)) then
  begin
   Self.myORs[orindex].MereniCasu.Clear();
   while (SoundsPlay.IsPlaying(_SND_TRAT_ZADOST)) do
     SoundsPlay.DeleteSound(_SND_TRAT_ZADOST);
  end;

 if ((tmp = TORControlRights.null) and (Rights > tmp)) then
   PanelTCPClient.PanelFirstGet(Sender);

 if (Rights = TORControlRights.null) then
  Self.DisableElements(orindex);

 if ((Rights > TORControlRights.null) and (tmp = TORControlRights.null)) then
   Self.myORs[orindex].stack.enabled := true;

 if (comment <> '') then
  Self.ORInfoMsg(comment);
end;//procedure

//chyba komunikace
procedure TRelief.ORInfoMsg(msg:string);
begin
 Self.msg.msg  := msg;
 while (Length(Self.msg.msg) < Self._msg_width) do Self.msg.msg := Self.msg.msg + ' ';
 Self.msg.show := true;
end;//procedure

procedure TRelief.ORNUZ(Sender:string; status:TNUZstatus);
var i,orindex:Integer;
begin
 orindex := -1;
 for i := 0 to Self.myORs.Count-1 do
  if (Self.myORs[i].id = Sender) then orindex := i;
 if (orindex = -1) then Exit;

 Self.myORs[orindex].NUZ_status := status;

 case (status) of
  no_nuz, nuzing: Self.myORs[orindex].dk_blik := false;
  blk_in_nuz: Self.myORs[orindex].dk_blik := true;
 end;
end;//procedure

procedure TRelief.ORConnectionOpenned();
var i:Integer;
    rights:TOrControlRights;
    username,password:string;
begin
 if (GlobConfig.data.auth.autoauth) then
  begin
   username := GlobConfig.data.auth.username;
   password := GlobConfig.data.auth.password;
  end else begin
   F_Auth.OpenForm('Vy�adov�na autorizace');
   username := F_Auth.E_username.Text;
   password := GenerateHash(AnsiString(F_Auth.E_Password.Text));
  end;

 for i := 0 to Self.myORs.Count-1 do
  begin
   if (GlobConfig.data.auth.ORs.TryGetValue(Self.myORs[i].id, rights)) then
     PanelTCPClient.PanelAuthorise(Self.myORs[i].id, rights, username, password)
   else
     PanelTCPClient.PanelAuthorise(Self.myORs[i].id, read, username, password);
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////
//komunikace s oblastmi rizeni:
//change blok stav:

procedure TRelief.ORUsekChange(Sender:string; BlokID:integer; UsekPanelProp:TUsekPanelProp);
var i:Integer;
    usk:TPReliefUsk;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
   if ((symbols[i].blk_type = _BLK_USEK) and (Sender = Self.myORs[Self.Useky[symbols[i].symbol_index].OblRizeni].id)) then
    begin
     usk := Self.Useky[symbols[i].symbol_index];
     usk.PanelProp := UsekPanelProp;
     Self.Useky[symbols[i].symbol_index] := usk;
    end;
end;//procedure

procedure TRelief.ORVyhChange(Sender:string; BlokID:integer; VyhPanelProp:TVyhPanelProp);
var i:Integer;
    vykol:TPVykol;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
  begin
   case (symbols[i].blk_type) of
      _BLK_VYH: begin
        if (Sender = Self.myORs[Self.Vyhybky.Data[symbols[i].symbol_index].OblRizeni].id) then
            Self.Vyhybky.Data[symbols[i].symbol_index].PanelProp := VyhPanelProp;
      end;

      _BLK_VYKOL: begin
       if (Sender = Self.myORs[Self.Vykol[symbols[i].symbol_index].OblRizeni].id) then
        begin
         vykol := Self.Vykol[symbols[i].symbol_index];
         vykol.PanelProp := VyhPanelProp;
         Self.Vykol[symbols[i].symbol_index] := vykol;
        end;

      end;
   end;//case
  end;//for i
end;//procedure

procedure TRelief.ORNavChange(Sender:string; BlokID:integer; NavPanelProp:TNavPanelProp);
var i:Integer;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
   if ((symbols[i].blk_type = _BLK_SCOM) and (Sender = Self.myORs[Self.Navestidla.Data[symbols[i].symbol_index].OblRizeni].id)) then
    Self.Navestidla.Data[symbols[i].symbol_index].PanelProp := NavPanelProp;
end;//procedure

procedure TRelief.ORPrjChange(Sender:string; BlokID:integer; PrjPanelProp:TPrjPanelProp);
var i:Integer;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
   if ((symbols[i].blk_type = _BLK_PREJEZD) and (Sender = Self.myORs[Self.Prejezdy.Data[symbols[i].symbol_index].OblRizeni].id)) then
    Self.Prejezdy.Data[symbols[i].symbol_index].PanelProp := PrjPanelProp;
end;//procedure

procedure TRelief.ORUvazkaChange(Sender:string; BlokID:integer; UvazkaPanelProp:TUvazkaPanelProp; UvazkaSprPanelProp:TUvazkaSprPanelProp);
var i, j:Integer;
    tmp:TUvazkaSprPanelProp;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
  begin
   case (symbols[i].blk_type) of
     _BLK_UVAZKA: begin
       if (Sender = Self.myORs[Self.Uvazky.Data[symbols[i].symbol_index].OblRizeni].id) then
        Self.Uvazky.Data[symbols[i].symbol_index].PanelProp := UvazkaPanelProp;
     end;

     _BLK_UVAZKA_SPR: begin
       if (Sender = Self.myORs[Self.UvazkySpr.Data[symbols[i].symbol_index].OblRizeni].id) then
        begin
         tmp := Self.UvazkySpr.Data[symbols[i].symbol_index].PanelProp;
         Self.UvazkySpr.Data[symbols[i].symbol_index].PanelProp := UvazkaSprPanelProp;

         // uvolnime pamet
         for j := 0 to tmp.spr.Count-1 do
           tmp.spr[j].strings.Free();
         tmp.spr.Free();
        end;
     end;
   end;//case
  end;//for i
end;//procedure

procedure TRelief.ORZamekChange(Sender:string; BlokID:integer; ZamekPanelProp:TZamekPanelProp);
var i:Integer;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
   if ((symbols[i].blk_type = _BLK_ZAMEK) and (Sender = Self.myORs[Self.Zamky.Data[symbols[i].symbol_index].OblRizeni].id)) then
    Self.Zamky.Data[symbols[i].symbol_index].PanelProp := ZamekPanelProp;
end;//procedure

procedure TRelief.ORRozpChange(Sender:string; BlokID:integer; RozpPanelProp:TRozpPanelProp);
var i:Integer;
    rozp:TPRozp;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
   if ((symbols[i].blk_type = _BLK_ROZP) and (Sender = Self.myORs[Self.Rozp[symbols[i].symbol_index].OblRizeni].id)) then
    begin
     rozp := Self.Rozp[symbols[i].symbol_index];
     rozp.PanelProp := RozpPanelProp;
     Self.Rozp[symbols[i].symbol_index] := rozp;
    end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORHVList(Sender:string; data:string);
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   if (Sender = Self.myORs[i].id) then
    begin
     Self.myORs[i].HVs.ParseHVs(data);
     Exit();
    end;
end;//procedure

procedure TRelief.ORSprNew(Sender:string);
var i, j:Integer;
    available:boolean;
begin
 for i := 0 to Self.myORs.Count-1 do
   if (Sender = Self.myORs[i].id) then
    begin
     available := false;
     for j := 0 to Self.myORs[i].HVs.count-1 do
       if (Self.myORs[i].HVs.HVs[j].Souprava = '-') then
        begin
         available := true;
         break;
        end;

     if (available) then
       F_SoupravaEdit.NewSpr(Self.myORs[i].HVs, Self.myORs[i].id)
     else
       Self.ORInfoMsg('Nejsou voln� loko');

     Exit();
    end;
end;//procedure

procedure TRelief.ORSprEdit(Sender:string; parsed:TStrings);
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   if (Sender = Self.myORs[i].id) then
    begin
     F_SoupravaEdit.EditSpr(parsed, Self.myORs[i].HVs, Self.myORs[i].id);
     Exit();
    end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//na kazdem radku je ulozena jedna oblast rizeni ve formatu:
//  nazev;nazev_zkratka;id;lichy_smer(0,1);orientace_DK(0,1);ModCasStart(0,1);ModCasStop(0,1);ModCasSet(0,1);dkposx;dkposy;qposx;qposy;timeposx;timeposy;osv_mtb|osv_port|osv_name;
function TRelief.ORLoad(const ORs:TStrings):Byte;
var data_main,data_osv,data_osv2:TStrings;
    i,j:Integer;
    Osv:TOsv;
    Pos:TPoint;
    OblR:TORPanel;
begin
 data_main := TStringList.Create();
 data_osv  := TStringList.Create();
 data_osv2 := TStringList.Create();

 Self.myORs.Clear();

 for i := 0 to ORs.Count-1 do
  begin
   data_main.Clear();
   ExtractStrings([';'],[],PChar(ORs[i]),data_main);

   if (data_main.Count < 14) then
    begin
     Result := 2;
     Exit;
    end;

   OblR := TORPanel.Create();

   OblR.str := ORs[i];

   OblR.Name       := data_main[0];
   OblR.ShortName  := data_main[1];
   OblR.id         := data_main[2];
   OblR.Lichy      := StrToInt(data_main[3]);
   OblR.Poss.DKOr  := StrToInt(data_main[4]);

   OblR.Rights.ModCasStart := StrToBool(data_main[5]);
   OblR.Rights.ModCasStop  := StrToBool(data_main[6]);
   OblR.Rights.ModCasSet   := StrToBool(data_main[7]);

   OblR.Poss.DK.X := StrToInt(data_main[8]);
   OblR.Poss.DK.Y := StrToInt(data_main[9]);

   Pos.X := StrToInt(data_main[10]);
   Pos.Y := StrToInt(data_main[11]);
   OblR.stack := TORStack.Create(Self.Graphics, OblR.id, Pos);

   OblR.Poss.Time.X := StrToInt(data_main[12]);
   OblR.Poss.Time.Y := StrToInt(data_main[13]);

   OblR.Osvetleni := TList<TOsv>.Create();
   OblR.MereniCasu := TList<TMereniCasu>.Create();

   data_osv.Clear();
   if (data_main.Count >= 15) then
    begin
     ExtractStrings(['|'],[],PChar(data_main[14]),data_osv);
     for j := 0 to data_osv.Count-1 do
      begin
       data_osv2.Clear();
       ExtractStrings(['#'],[],PChar(data_osv[j]),data_osv2);

       if (data_osv2.Count < 2) then
        begin
         Result := 3;
         Exit;
        end;

       Osv.board := StrToInt(data_osv2[0]);
       Osv.port  := StrToInt(data_osv2[1]);
       if (data_osv2.Count > 2) then Osv.name := data_osv2[2] else Osv.name := '';
       OblR.Osvetleni.Add(Osv);
      end;//for j
     end;//.Count >= 15

   OblR.HVs := THVDb.Create();

   Self.myORs.Add(OblR);
  end;//for i

 FreeAndNil(data_main);
 FreeAndNil(data_osv);
 FreeAndNil(data_osv2);

 // vytvorime okynka zprav
 TF_Messages.frm_cnt := Self.myORs.Count;
 for i := 0 to Self.myORs.Count-1 do
   TF_Messages.frm_db[i] := TF_Messages.Create(Self.myORs[i].Name, Self.myORs[i].id);

 Result := 0;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//technologie posle nejake menu a my ho zobrazime:
procedure TRelief.ORShowMenu(items:string);
var aPos, bPos:TPoint;
begin
 Self.menu_lastpos := Self.CursorDraw.Pos;
 Self.special_menu := TSpecialMenu.none;

 // show vraci pozici, na kterou je potreba dat kurzor
 aPos := Self.Menu.ShowMenu(items, -1);
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 aPos := Point(aPos.X + bPos.X, aPos.Y + bPos.Y);
 SetCursorPos(aPos.X, aPos.Y);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.HideMenu();
var bPos:TPoint;
begin
 Self.Menu.showing := false;
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 SetCursorPos(Self.menu_lastpos.X*SymbolSet._Symbol_Sirka + bPos.X, Self.menu_lastpos.Y*SymbolSet._Symbol_Vyska + bPos.Y);
 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////
//DKMenu popup:

procedure TRelief.ShowDKMenu(obl_rizeni:Integer);
var menu_str:string;
    aPos,bPos:TPoint;
begin
 if (PanelTCPClient.status <> TPanelConnectionStatus.opened) then Exit();

 menu_str := '$' + Self.myORs[obl_rizeni].Name + ',-,';

 case (Self.myORs[obl_rizeni].tech_rights) of
  TORControlRights.null, TORControlRights.read, TORControlRights.superuser :
                           menu_str := menu_str + 'MP,';
  TORControlRights.write : menu_str := menu_str + 'DP,';
 end;//case

 if (Self.root_menu) then
  menu_str := menu_str + '!SUPERUSER,';

 if (Integer(Self.myORs[obl_rizeni].tech_rights) >= 2) then
  begin
   // mame pravo zapisovat

   PanelTCPClient.PanelUpdateOsv(Self.myORs[obl_rizeni].id);

   // LOKO
   menu_str := menu_str + 'LOKO,';

   // OSV
   if (Self.myORs[obl_rizeni].Osvetleni.Count > 0) then
     menu_str := menu_str + 'OSV,';

   // NUZ
   case (Self.myORs[obl_rizeni].NUZ_status) of
    TNUZStatus.blk_in_nuz: menu_str := menu_str + '!NUZ>,';
    TNUZStatus.nuzing: menu_str := menu_str + 'NUZ<,';
   end;

   menu_str := menu_str + 'MSG,';

   if (ModCas.started) then
    begin
     if (Self.myORs[obl_rizeni].Rights.ModCasStop) then
      menu_str := menu_str + 'CAS<,';
    end else begin
     if (Self.myORs[obl_rizeni].Rights.ModCasStart) then
      menu_str := menu_str + 'CAS>,';
    end;

   if ((Self.myORs[obl_rizeni].Rights.ModCasSet) and (not ModCas.started)) then
    menu_str := menu_str + 'CAS,';
  end;


 Self.special_menu := dk;
 Self.menu_lastpos := Self.CursorDraw.Pos;

 aPos := Self.Menu.ShowMenu(menu_str, obl_rizeni);
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 aPos := Point(aPos.X + bPos.X, aPos.Y + bPos.Y);
 SetCursorPos(aPos.X, aPos.Y);

 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////
//DKMenu clicks:

procedure TRelief.DKMenuClickMP(Sender:Integer; item:string);
var username,password:string;
begin
 if ((GlobConfig.data.auth.autoauth) and (Self.myORs[Sender].tech_rights < TORCOntrolRights.superuser)) then
  begin
   username := GlobConfig.data.auth.username;
   password := GlobConfig.data.auth.password;
  end else begin
   F_Auth.OpenForm('Vy�adov�na autorizace');
   username := F_Auth.E_username.Text;
   password := F_Auth.E_Password.Text;
  end;

 if (item = 'MP') then
  begin
   //>
   PanelTCPClient.PanelAuthorise(Self.myORs[Sender].id, write, username, password);
  end else
 ////////////////////////////
  begin
   //<
   PanelTCPClient.PanelAuthorise(Self.myORs[Sender].id, read, username, password);
  end;//<
end;//procedure

procedure TRelief.DKMenuClickNUZ(Sender:Integer; item:string);
begin
 if (item = 'NUZ>') then
   PanelTCPClient.PanelNUZ(Self.myORs[Sender].id)
 else
   PanelTCPClient.PanelNUZCancel(Self.myORs[Sender].id);
end;//procedure

procedure TRelief.DKMenuClickOSV(Sender:Integer; item:string);
var menu_str:string;
    i:Integer;
    aPos,bPos:TPoint;
begin
 menu_str := '$'+Self.myORs[Sender].Name+',$Osv�tlen�,-,';

 for i := 0 to Self.myORs[Sender].Osvetleni.Count-1 do
  begin
   case (Self.myORs[Sender].Osvetleni[i].state) of
    false : menu_str := menu_str + Self.myORs[Sender].Osvetleni[i].name + '>,';
    true  : menu_str := menu_str + Self.myORs[Sender].Osvetleni[i].name + '<,';
   end;//case
  end;

 Self.special_menu := osv;
 aPos := Self.Menu.ShowMenu(menu_str, Sender);
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 aPos := Point(aPos.X + bPos.X, aPos.Y + bPos.Y);
 SetCursorPos(aPos.X, aPos.Y);
end;//procedure

procedure TRelief.DKMenuClickLOKO(Sender:Integer; item:string);
var menu_str:string;
    aPos,bPos:TPoint;
begin
 // nejd��v aktualizuji seznam LOKO
 PanelTCPClient.PanelLokList(Self.myORs[Sender].id);

 menu_str := '$'+Self.myORs[Sender].Name+',$LOKO,-,NOV� loko,EDIT loko,SMAZAT loko,P�EDAT loko,RU� loko';

 Self.special_menu := loko;
 aPos := Self.Menu.ShowMenu(menu_str, Sender);
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 aPos := Point(aPos.X + bPos.X, aPos.Y + bPos.Y);
 SetCursorPos(aPos.X, aPos.Y);
end;//procedure

procedure TRelief.DKMenuClickSUPERUSER(Sender:Integer; item:string);
begin
 F_Auth.OpenForm('Vy�adov�na autorizace');
 PanelTCPClient.PanelAuthorise(Self.myORs[Sender].id, superuser, F_Auth.E_username.Text, F_Auth.E_Password.Text);
 Self.root_menu := false;
end;//procedure

procedure TRelief.DKMenuClickCAS(Sender:Integer; item:string);
begin
 if (item = 'CAS>') then
  begin
   PanelTCPClient.SendLn('-;MOD-CAS;START;');
  end else begin
   PanelTCPClient.SendLn('-;MOD-CAS;STOP;');
  end;
end;//procedure

procedure TRelief.DKMenuClickSetCAS(Sender:Integer; item:string);
begin
 F_ModCasSet.OpenForm();
end;//procedure

procedure TRelief.OSVMenuClick(Sender:Integer; item:string);
begin
 case (RightStr(item, 1))[1] of
  '>' : PanelTCPClient.PanelSetOsv(Self.ORs[Sender].id, LeftStr(item, Length(item)-1), 1);
  '<' : PanelTCPClient.PanelSetOsv(Self.ORs[Sender].id, LeftStr(item, Length(item)-1), 0);
 end;//case
end;//procedure

procedure TRelief.DKMenuClickMSG(Sender:Integer; item:string);
begin
 TF_Messages.frm_db[Sender].Show();
 TF_Messages.frm_db[Sender].SetFocus();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowRegMenu(obl_rizeni:Integer);
var menu_str:string;
    aPos,bPos:TPoint;
begin
 if ((PanelTCPClient.status <> TPanelConnectionStatus.opened) or
     (Self.myORs[obl_rizeni].RegPlease.status = TORRegPleaseStatus.null)) then Exit();

 menu_str := '$' + Self.myORs[obl_rizeni].Name + ',$��dost o loko,-,INFO,ODM�TNI';

 Self.myORs[obl_rizeni].RegPlease.status := TORRegPleaseStatus.request;

 Self.special_menu := reg_please;
 Self.menu_lastpos := Self.CursorDraw.Pos;

 aPos := Self.Menu.ShowMenu(menu_str, obl_rizeni);
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 aPos := Point(aPos.X + bPos.X, aPos.Y + bPos.Y);
 SetCursorPos(aPos.X, aPos.Y);

 PanelTCPClient.PanelLokList(Self.myORs[obl_rizeni].id);

 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.MenuOnClick(Sender:TObject; item:string; obl_r:Integer);
var sp_menu:TSpecialMenu;
begin
 Self.HideMenu();

 sp_menu := Self.special_menu;
 Self.special_menu := none;

 case (sp_menu) of
  none       : PanelTCPClient.PanelMenuClick(item);
  dk         : Self.ParseDKMenuClick(item, obl_r);
  osv        : Self.OSVMenuClick(obl_r, item);
  loko       : Self.ParseLOKOMenuClick(item, obl_r);
  reg_please : Self.ParseRegMenuClick(item, obl_r);
 end;
end;//procedure

procedure TRelief.ParseDKMenuClick(item:string; obl_r:Integer);
begin
 if ((item = 'MP') or (item = 'DP')) then Self.DKMenuClickMP(obl_r, item)
 else if ((item = 'NUZ>') or (item = 'NUZ<')) then Self.DKMenuClickNUZ(obl_r, item)
 else if (item = 'OSV') then Self.DKMenuClickOSV(obl_r, item)
 else if (item = 'LOKO') then Self.DKMenuClickLOKO(obl_r, item)
 else if (item = 'MSG') then Self.DKMenuClickMSG(obl_r, item)
 else if (item = 'SUPERUSER') then Self.DKMenuClickSUPERUSER(obl_r, item)
 else if ((item = 'CAS>') or (item = 'CAS<')) then Self.DKMenuClickCAS(obl_r, item)
 else if (item = 'CAS') then Self.DKMenuClickSetCAS(obl_r, item);
end;//procedure

procedure TRelief.ParseLOKOMenuClick(item:string; obl_r:Integer);
begin
 if (item = 'NOV� loko')   then F_HVEdit.HVAdd(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'EDIT loko')   then F_HVEdit.HVEdit(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'SMAZAT loko') then F_HVDelete.OpenForm(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'P�EDAT loko') then F_HV_Move.Open(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'RU� loko')    then
   F_RegReq.Open(
      Self.myORs[obl_r].HVs,
      Self.myORs[obl_r].id,
      Self.myORs[obl_r].RegPlease.user,
      Self.myORs[obl_r].RegPlease.firstname,
      Self.myORs[obl_r].RegPlease.lastname,
      Self.myORs[obl_r].RegPlease.comment,
      (Self.myORs[obl_r].RegPlease.status <> TORRegPleaseStatus.null),
      false, false);
end;//procedure

procedure TRelief.ParseRegMenuClick(item:string; obl_r:Integer);
begin
 if (item = 'ODM�TNI') then PanelTCPClient.SendLn(Self.myORs[obl_r].id+';LOK-REQ;DENY')
 else if (item = 'INFO') then
  begin
   F_RegReq.Open(
      Self.myORs[obl_r].HVs,
      Self.myORs[obl_r].id,
      Self.myORs[obl_r].RegPlease.user,
      Self.myORs[obl_r].RegPlease.firstname,
      Self.myORs[obl_r].RegPlease.lastname,
      Self.myORs[obl_r].RegPlease.comment,
      true, false, false);
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.DisableElements(orindex:Integer = -1);
var i, j:Integer;
    usk:TPreliefUsk;
    vykol:TPVykol;
    rozp:TPRozp;
begin
 if (orindex = -1) then
  begin
   Self.Menu.showing := false;
   Self.UPO.showing  := false;
   Self.infoTimers.Clear();
   Self.Graphics.DrawObject.Enabled := true;
  end;

 for i := 0 to Self.Useky.Count-1 do
  if ((orindex < 0) or (Self.Useky[i].OblRizeni = orindex)) then
   begin
    usk := Self.Useky[i];
    usk.PanelProp := _Def_Usek_Prop;
    Self.Useky[i] := usk;
   end;
 for i := 0 to Self.Vyhybky.Count-1 do
  if ((orindex < 0) or (Self.Vyhybky.Data[i].OblRizeni = orindex)) then
    Self.Vyhybky.Data[i].PanelProp := _Def_Vyh_Prop;
 for i := 0 to Self.Navestidla.Count-1 do
  if ((orindex < 0) or (Self.Navestidla.Data[i].OblRizeni = orindex)) then
    Self.Navestidla.Data[i].PanelProp := _Def_Nav_Prop;
 for i := 0 to Self.Prejezdy.Count-1 do
  if ((orindex < 0) or (Self.Prejezdy.Data[i].OblRizeni = orindex)) then
    Self.Prejezdy.Data[i].PanelProp := _Def_Prj_Prop;
 for i := 0 to Self.Uvazky.Count-1 do
  if ((orindex < 0) or (Self.Uvazky.Data[i].OblRizeni = orindex)) then
    Self.Uvazky.Data[i].PanelProp := _Def_Uvazka_Prop;
 for i := 0 to Self.UvazkySpr.Count-1 do
  if ((orindex < 0) or (Self.UvazkySpr.Data[i].OblRizeni = orindex)) then
   begin
    for j := 0 to Self.UvazkySpr.Data[i].PanelProp.spr.Count-1 do
      Self.UvazkySpr.Data[i].PanelProp.spr[j].strings.Free();
    Self.UvazkySpr.Data[i].PanelProp.spr.Free();

    Self.UvazkySpr.Data[i].PanelProp     := _Def_UvazkaSpr_Prop;
    Self.UvazkySpr.Data[i].PanelProp.spr := TList<TUvazkaSpr>.Create();
   end;
 for i := 0 to Self.Zamky.Count-1 do
  if ((orindex < 0) or (Self.Zamky.Data[i].OblRizeni = orindex)) then
    Self.Zamky.Data[i].PanelProp := _Def_Zamek_Prop;
 for i := 0 to Self.Vykol.Count-1 do
  if ((orindex < 0) or (Self.Vykol[i].OblRizeni = orindex)) then
   begin
    vykol := Self.Vykol[i];
    vykol.PanelProp := _Def_Vyh_Prop;
    Self.Vykol[i] := vykol;
   end;
 for i := 0 to Self.Rozp.Count-1 do
  if ((orindex < 0) or (Self.Rozp[i].OblRizeni = orindex)) then
   begin
    rozp := Self.Rozp[i];
    rozp.PanelProp := _Def_Rozp_Prop;
    Self.Rozp[i] := rozp;
   end;

 for i := 0 to Self.myORs.Count-1 do
  begin
   if ((orindex < 0) or (i = orindex)) then
    begin
     Self.myORs[i].tech_rights      := TORControlRights.null;
     Self.myORs[i].dk_blik          := false;
     Self.myORs[i].dk_osv           := false;
     Self.myORs[i].stack.enabled    := false;
     Self.myORs[i].dk_click_server  := false;
     Self.myORs[i].RegPlease.status := TORRegPleaseStatus.null;
    end;
  end;


 Self.Show();
end;//procedure

procedure TRelief.OROsvChange(Sender:string; code:string; state:boolean);
var i, j:Integer;
    Osv:TOsv;
begin
 for i := 0 to Self.ORs.Count-1 do
  if (Self.ORs[i].id = Sender) then
   begin
    for j := 0 to Self.ORs[i].Osvetleni.Count-1 do
      if (Self.ORs[i].Osvetleni[j].name = code) then
       begin
        Osv := Self.ORs[i].Osvetleni.Items[j];
        Osv.state := state;
        Self.ORs[i].Osvetleni.Items[j] := Osv;
       end;
    Exit();
   end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowZasobniky();
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   Self.myORs[i].stack.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORStackMsg(Sender:string; data:TStrings);
var i:Integer;
begin
 for i := 0 to Self.ORs.Count-1 do
  if (Self.ORs[i].id = Sender) then
    Self.ORs[i].stack.ParseCommand(data);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

function TRelief.GetPanelWidth():SmallInt;
begin
 Result := Self.Graphics.PanelWidth;
end;//function

function TRelief.GetPanelHeight():SmallInt;
begin
 Result := Self.Graphics.PanelHeight;
end;//function

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowInfoTimers();
var i:Integer;
    str:string;
begin
 for i := Self.infoTimers.Count-1 downto 0 do
   if (Self.infoTimers[i].konec < Now) then
    Self.infoTimers.Delete(i);

 for i := 0 to Min(Self.infoTimers.Count, 2)-1 do
  begin
   str := Self.infoTimers[i].str + '  ' + FormatDateTime('nn:ss', Self.infoTimers[i].konec-Now) + ' ';
   Self.Graphics.TextOutput(Point(Self.PanelWidth-_INFOTIMER_WIDTH, Self.PanelHeight-i-1), str, clRed, clWhite);
  end;//for i
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowZamky();
var i:Integer;
begin
 for i := 0 to Self.Zamky.Count-1 do
  begin
   if ((Self.Zamky.Data[i].PanelProp.blik) and (Self.Graphics.blik)) then continue;

   SymbolSet.IL_Symbols.BkColor := Self.Zamky.Data[i].PanelProp.Pozadi;
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas,
                            Self.Zamky.Data[i].Pos.X*SymbolSet._Symbol_Sirka,
                            Self.Zamky.Data[i].Pos.Y*SymbolSet._Symbol_Vyska,
                            (_Zamek*10)+Self.Graphics.GetColorIndex(Self.Zamky.Data[i].PanelProp.Symbol));
  end;//for i
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// vykreslit rozpojovace
procedure TRelief.ShowRozp;
var i:Integer;
begin
 SymbolSet.IL_Symbols.DrawingStyle := TDrawingStyle.dsTransparent;
 SymbolSet.IL_Symbols.BkColor      := clBlack;

 for i := 0 to Self.Rozp.Count-1 do
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, (Self.Rozp[i].Pos.X)*SymbolSet._Symbol_Sirka, (Self.Rozp[i].Pos.Y)*SymbolSet._Symbol_Vyska,
      ((_Rozp_Start+1)*10)+Self.Graphics.GetColorIndex(Self.Rozp[i].PanelProp.Symbol));

 SymbolSet.IL_Symbols.DrawingStyle := TDrawingStyle.dsNormal;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// vykreslit vykolejky
procedure TRelief.ShowVykol;
var i, symindex:Integer;
    col:TColor;
begin
 for i := 0 to Self.Vykol.Count-1 do
  begin
   if ((Self.Useky[Self.Vykol[i].usek].Vetve[Self.Vykol[i].vetev].visible) or (Self.Vykol[i].PanelProp.Symbol = clAqua)) then
    col := Self.Vykol[i].PanelProp.Symbol
   else
    col := $A0A0A0;

   if (Self.Vykol[i].PanelProp.Poloha = TVyhPoloha.disabled) then
    begin
     symindex := 4 + Self.Vykol[i].symbol;
    end else begin
     case (Self.Vykol[i].PanelProp.Poloha) of
        TVYhPoloha.plus  : symindex := Self.Vykol[i].symbol;
        TVYhPoloha.minus : symindex := 2 + Self.Vykol[i].symbol;
        TVYhPoloha.both  : symindex := 4 + Self.Vykol[i].symbol;
      else
       symindex := 4 + Self.Vykol[i].symbol;
     end;
    end;

   SymbolSet.IL_Symbols.BkColor := Self.Vykol[i].PanelProp.Pozadi;
   SymbolSet.IL_Symbols.Draw(Self.DrawObject.Surface.Canvas, (Self.Vykol[i].Pos.X)*SymbolSet._Symbol_Sirka, (Self.Vykol[i].Pos.Y)*SymbolSet._Symbol_Vyska,
      ((_Vykol_Start+symindex)*10)+Self.Graphics.GetColorIndex(col));
  end;//for i
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORInfoTimer(id:Integer; time_min:Integer; time_sec:Integer; str:string);
var tmr:TInfoTimer;
begin
 tmr.konec := Now + EncodeTime(0, time_min, time_sec, 0);
 if (Length(str) > _INFOTIMER_TEXT_WIDTH) then
  tmr.str := LeftStr(str, _INFOTIMER_TEXT_WIDTH)
 else
  tmr.str := str;

 //zarovname na pevnou sirku radku
 while (Length(tmr.str) < _INFOTIMER_TEXT_WIDTH) do
  tmr.str := ' ' + tmr.str;

 tmr.id := id;

 Self.infoTimers.Add(tmr);
end;//procedure

procedure TRelief.ORInfoTimerRemove(id:Integer);
var i:Integer;
begin
 for i := 0 to Self.infoTimers.Count-1 do
  if (Self.infoTimers[i].id = id) then
   begin
    Self.infoTimers.Delete(i);
    Exit();
   end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORDKClickServer(Sender:string; enable:boolean);
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
  if (Self.myORs[i].id = Sender) then
    Self.myORs[i].dk_click_server := enable;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

class function TRelief.GetTechBlk(typ:Integer; symbol_index:Integer):TTechBlokToSymbol;
begin
 Result.blk_type      := typ;
 Result.symbol_index  := symbol_index;
end;//function

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.AddToTechBlk(typ:Integer; blok_id:Integer; symbol_index:Integer);
var symbols:TList<TTechBlokToSymbol>;
    val:TTechBLokToSymbol;
begin
 if (Self.Tech_blok.ContainsKey(blok_id)) then
   symbols := Self.Tech_blok[blok_id]
 else
   symbols := TList<TTechBlokToSymbol>.Create();

 val := GetTechBlk(typ, symbol_index);
 if (not symbols.Contains(val)) then
   symbols.Add(val);

 Self.Tech_blok.AddOrSetValue(blok_id, symbols);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//  or;LOK-REQ;REQ;username;firstname;lastname;comment
//                                          - pozadavek na prevzeti loko na rucni rizeni
//  or;LOK-REQ;OK                           - seznam loko na rucni rizeni schvalen serverem
//  or;LOK-REQ;ERR;comment                  - seznam loko na rucni rizeni odmitnut serverem
//  or;LOK-REQ;CANCEL;                      - zruseni pozadavku na prevzeti loko na rucni rizeni
procedure TRelief.ORLokReq(Sender:string; parsed:TStrings);
var i:Integer;
    OblR:TORPanel;
    HVDb:THVDb;
begin
 OblR := nil;
 for i := 0 to Self.myORs.Count-1 do
  if (Self.myORs[i].id = Sender) then
   begin
    OblR := Self.myORs[i];
    break;
   end;
 if (OblR = nil) then Exit();

 parsed[2] := UpperCase(parsed[2]);

 if (parsed[2] = 'REQ') then
  begin
   OblR.RegPlease.status  := TORRegPleaseStatus.request;

   // vychozi hodnoty
   OblR.RegPlease.firstname := '';
   OblR.RegPlease.lastname  := '';
   OblR.RegPlease.comment   := '';

   OblR.RegPlease.user      := parsed[3];
   if (parsed.Count > 4) then OblR.RegPlease.firstname := parsed[4];
   if (parsed.Count > 5) then OblR.RegPlease.lastname  := parsed[5];
   if (parsed.Count > 6) then OblR.RegPlease.comment   := parsed[6];
  end

 else if (parsed[2] = 'OK') then
  begin
   F_RegReq.ServerResponseOK();
   OblR.RegPlease.status  := TORRegPleaseStatus.null;
  end

 else if (parsed[2] = 'ERR') then
  begin
   F_RegReq.ServerResponseErr(parsed[3]);
   OblR.RegPlease.status  := TORRegPleaseStatus.null;
  end

 else if (parsed[2] = 'CANCEL') then
  begin
   F_RegReq.ServerCanceled();
   OblR.RegPlease.status  := TORRegPleaseStatus.null;
  end

 else if (parsed[2] = 'U-OK') then
  begin
   HVDb := THVDb.Create;
   HVDb.ParseHVs(parsed[3]);

   F_RegReq.Open(
      HVDb,
      OblR.id,
      OblR.RegPlease.user,
      OblR.RegPlease.firstname,
      OblR.RegPlease.lastname,
      OblR.RegPlease.comment,
      true, true, true);
  end

 else if (parsed[2] = 'U-ERR') then
  begin
   Self.ORInfoMsg(parsed[3]);
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.UpdateSymbolSet();
begin
 Self.CursorDraw.Pozadi        := TBitmap.Create();
 Self.CursorDraw.Pozadi.Width  := SymbolSet._Symbol_Sirka+2;    // +2 kvuli okrajum kurzoru
 Self.CursorDraw.Pozadi.Height := SymbolSet._Symbol_Vyska+2;
 (Self.ParentForm as TF_Main).SetPanelSize(Self.Graphics.PanelWidth*SymbolSet._Symbol_Sirka, Self.Graphics.PanelHeight*SymbolSet._Symbol_Vyska);
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit

