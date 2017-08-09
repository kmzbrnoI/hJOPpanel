unit Panel;

interface

uses DXDraws, ImgList, Controls, Windows, SysUtils, Graphics, Classes,
     Forms, StdCtrls, ExtCtrls, Menus, AppEvnts, inifiles, Messages, RPConst,
     fPotvrSekv, MenuPanel, StrUtils, PGraphics, HVDb, Generics.Collections,
     Zasobnik, UPO, IBUtils, Hash, PngImage, DirectX;

const
  //limity poli
  _MAX_USK      = 256;
  _MAX_NAV      = 256;
  _MAX_POM      = 256;
  _MAX_VYH      = 256;
  _MAX_SYMBOLS  = 256;
  _MAX_POPISKY  = 64;
  _MAX_PRJ      = 16;
  _MAX_PRJ_LEN  = 10;
  _MAX_UVAZKY   = 256;
  _MAX_UVAZKY_SPR = 256;
  _MAX_ZAMKY    = 256;

  _INFOTIMER_WIDTH      = 30;
  _INFOTIMER_TEXT_WIDTH = 22;

  _FileVersion = '1.1';

const
    _Konec_JC: array [0..3] of TColor = (clBlack, clGreen, clWhite, clTeal);  //zadna, vlakova, posunova, nouzova (privolavaci)

type

 ///////////////////////////////////////////////////////////////////////////////
 // globalni datove struktury:

 TArSmallI=array of Smallint;

 TSpecialMenu = (none, dk, osv, loko, reg_please, hlaseni);

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
 TLoginChangeEvent = procedure(Sender:TObject; str:string) of object;

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

  username:string;
  login:string;

  NUZ_status:TNUZstatus;
  RegPlease:TORRegPlease;

  HVs:THVDb;

  hlaseni:boolean;
 end;

 // prehlasovani pomoci Ctrl+R (reader vs. normalni uzivatel)
 TReAuth = record
  old_login:string;                                                             // guest -> username
  old_ors:TList<Integer>;                                                       // (guest -> username) seznam indexu oblati rizeni k autorizaci
 end;

 ///////////////////////////////////////////////////////////////////////////////
 // blok usek:

 // 1 bitmapovy symbol na reliefu (ze symbolu se skladaji useky)
 TReliefSym=record
  Position:TPoint;
  SymbolID:Integer;
 end;

 TUsekSouprava=record
  nazev:string;
  sipkaL,sipkaS:boolean;
  fg, bg, ramecek:TColor;
 end;

 // data o useku pro spravne vykreslovani
 TUsekPanelProp=record
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
 TPReliefUsk=record
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
    _Plny_Symbol     = 37;
    _Prj_Start       = 40;
    _Hvezdicka       = 41;
    _Kolecko         = 42;
    _Uvazka_Start    = 43;
    _Spr_Sipka_Start = 46;
    _Zamek           = 48;
    _Vykol_Start     = 49;
    _Vykol_End       = 54;
    _Rozp_Start      = 55;
    _DKS_Top         = 58;
    _DKS_Bot         = 59;

    _msg_width = 30;

    _DblClick_Timeout_Ms = 250;

    //defaultni chovani bloku:
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


    _Def_Vyh_Prop:TVyhPanelProp = (
        blikani: false;
        Symbol: clBlack;
        Pozadi: clFuchsia;
        Poloha: TVyhPoloha.disabled);

    _UA_Vyh_Prop:TVyhPanelProp = (
        blikani: false;
        Symbol: $A0A0A0;
        Pozadi: clBlack;
        Poloha: TVyhPoloha.both);


    _Def_Nav_Prop:TNavPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        AB: false;
        blikani: false);

    _UA_Nav_Prop:TNavPanelProp = (
        Symbol: $A0A0A0;
        Pozadi: clBlack;
        AB: false;
        blikani: false);


    _Def_Prj_Prop:TPrjPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        stav: otevreno);

    _UA_Prj_Prop:TPrjPanelProp = (
        Symbol: $A0A0A0;
        Pozadi: clBlack;
        stav: otevreno);


    _Def_Uvazka_Prop:TUvazkaPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        blik: false;
        smer: disabled;
        );

    _UA_Uvazka_Prop:TUvazkaPanelProp = (
        Symbol: $A0A0A0;
        Pozadi: clBlack;
        blik: false;
        smer: zadny;
        );


    _Def_UvazkaSpr_Prop:TUvazkaSprPanelProp = (
        );


    _Def_Zamek_Prop:TZamekPanelProp = (
        Symbol: clBlack;
        Pozadi: clFuchsia;
        blik: false;
        );

    _UA_Zamek_Prop:TZamekPanelProp = (
        Symbol: $A0A0A0;
        Pozadi: clBlack;
        blik: false;
        );


    _Def_Rozp_Prop:TRozpPanelProp = (
        Symbol: clFuchsia;
        Pozadi: clBlack;
        blik: false;
        );

    _UA_Rozp_Prop:TRozpPanelProp = (
        Symbol: $A0A0A0;
        Pozadi: clBlack;
        blik: false;
        );

    //zde je definovano, jaky specialni symbol se ma vykreslovat jakou barvou (mimo separatoru)
    _SpecS_DrawColors:array [0..60] of TColor =
      ($A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
      $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
      $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
      $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,clBlue,clBlue,clBlue,$A0A0A0,
      $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
      $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
      $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0);

  private
   DrawObject:TDXDraw;
   ParentForm:TForm;
   AE:TApplicationEvents;
   PM_Properties:TPopupMenu;
   T_SystemOK:TTimer; //timer na SystemOK na 500ms - nevykresluje
   Graphics:TPanelGraphics;


   mouseClick:TDateTime;
   mouseTimer:TTimer;
   mouseLastBtn:TMouseButton;

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

  reAuth : TReAuth;

  FOnMove  : TMoveEvent;
  FOnLoginChange : TLoginChangeEvent;

   procedure PaintKurzor();
   procedure PaintKurzorBg(Pos:TPoint);

   procedure DXDMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure DXDMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);

   procedure T_SystemOKOnTimer(Sender:TObject);

   procedure ObjectMouseUp(Position:TPoint; Button:TPanelButton);

   function FLoad(aFile:string):Byte;

   procedure ShowUseky;
   procedure ShowUsekVetve(usek:TPReliefUsk; vetevI:Integer; visible:boolean; var showed:array of boolean);
   procedure ShowDKSVetve(usek:TPReliefUsk; visible:boolean; var showed:array of boolean);
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

   procedure PaintSouprava(pos:TPoint; useki:Integer; spri:Integer; bgZaver:boolean = false);
   procedure ShowUsekSoupravy(useki:Integer);
   procedure PaintCisloKoleje(pos:TPoint; useki:Integer);

   procedure Draw(IL:TImageList; pos:TPoint; symbol:Integer; fg:TColor; bg:TColor; transparent:boolean = false);

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
   function GetVykol(Pos:TPoint):Integer;

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
   procedure DKMenuClickINFO(Sender:Integer; item:string);
   procedure DKMenuClickHLASENI(Sender:Integer; item:string);

   procedure DKMenuClickSUPERUSER_AuthCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);

   procedure OSVMenuClick(Sender:Integer; item:string);

   procedure ParseLOKOMenuClick(item:string; obl_r:Integer);
   procedure ParseDKMenuClick(item:string; obl_r:Integer);
   procedure ParseRegMenuClick(item:string; obl_r:Integer);
   procedure ParseHlaseniMenuClick(item:string; obl_r:Integer);

   procedure MenuOnClick(Sender:TObject; item:string; obl_r:Integer; itemindex:Integer);

   function GetPanelWidth():SmallInt;
   function GetPanelHeight():SmallInt;

   class function GetTechBlk(typ:Integer; symbol_index:Integer):TTechBlokToSymbol;
   procedure AddToTechBlk(typ:Integer; blok_id:Integer; symbol_index:Integer);

   procedure UpdateLoginString();
   function GetLoginString():string;

   // procedure prehlasovani (Ctrl+R)
   function AnyORWritable():boolean;
   procedure AuthReadCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);
   procedure AuthWriteCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);

   procedure OnMouseTimer(Sender:TObject);

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

   procedure ORDisconnect(orindex:Integer = -1);
   procedure Escape(send:boolean = true);

   procedure UpdateSymbolSet();

   procedure ReAuthorize();
   procedure IPAAuth();

   property PozadiColor:TColor read Colors.Pozadi write Colors.Pozadi;
   property KurzorRamecek:TColor read CursorDraw.KurzorRamecek write CursorDraw.KurzorRamecek;
   property KurzorObsah:TColor read CursorDraw.KurzorObsah write CursorDraw.KurzorObsah;

   property PanelWidth:SmallInt read GetPanelWidth;
   property PanelHeight:SmallInt read GetPanelHeight;
   property StIndex: integer read StaniceIndex;
   property ORs:TList<TORPanel> read myORs;

   //events
   property OnMove: TMoveEvent read FOnMove write FOnMove;
   property OnLoginUserChange:TLoginChangeEvent read FOnLoginChange write FOnLoginChange;

   //komunikace se serverem
   // sender = id oblasti rizeni

   procedure ORAuthoriseResponse(Sender:string; Rights:TORControlRights; comment:string=''; username:string='');
   procedure ORInfoMsg(msg:string);
   procedure ORShowMenu(items:string);
   procedure ORNUZ(Sender:string; status:TNUZstatus);
   procedure ORConnectionOpenned();
   procedure ORConnectionOpenned_AuthCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);

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
   procedure ORHlaseniMsg(Sender:string; data:TStrings);

 end;

implementation

uses fStitVyl, TCPClientPanel, Symbols, fMain, BottomErrors, GlobalConfig, fZpravy,
     fSprEdit, fSettings, fHVMoveSt, fAuth, fHVEdit, fHVDelete, ModelovyCas,
     fNastaveni_casu, LokoRuc, Sounds, fRegReq, fHVSearch, uLIclient, InterProcessCom,
     parseHelper;

constructor TRelief.Create(aParentForm:TForm);
begin
 inherited Create;

 Self.Useky := TList<TPReliefUsk>.Create();
 Self.Vykol := TList<TPVykol>.Create();
 Self.Rozp  := TList<TPRozp>.Create();
 Self.ParentForm := aParentForm;
 Self.myORs := TList<TORPanel>.Create();
 Self.reAuth.old_ors := TList<Integer>.Create();

 Self.mouseTimer := TTimer.Create(nil);
 Self.mouseTimer.Interval := _DblClick_Timeout_Ms + 20;
 Self.mouseTimer.OnTimer := Self.OnMouseTimer;
 Self.mouseTimer.Enabled := false;
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
 Self.mouseTimer.Free();

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
   Self.Useky[i].PanelProp.soupravy.Free();
   Self.Useky[i].Symbols.Free();
   Self.Useky[i].JCClick.Free();
   Self.Useky[i].KPopisek.Free();
   Self.Useky[i].Soupravy.Free();
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
 if (Assigned(Self.reAuth.old_ors)) then FreeAndNil(Self.reAuth.old_ors);

 for i in Self.Tech_blok.Keys do
   Self.Tech_blok[i].Free();
 Self.Tech_blok.Free();

 Self.CursorDraw.Pozadi.Free();

 inherited Destroy;
end;//destructor

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.Draw(IL:TImageList; pos:TPoint; symbol:Integer; fg:TColor; bg:TColor; transparent:boolean = false);
begin
 if (transparent) then
   IL.DrawingStyle := TDrawingStyle.dsTransparent
 else begin
   IL.DrawingStyle := TDrawingStyle.dsNormal;
   IL.BkColor := bg;
 end;

 IL.Draw(Self.DrawObject.Surface.Canvas, pos.X * SymbolSet._Symbol_Sirka,
         pos.Y * SymbolSet._Symbol_Vyska, Self.Graphics.GetSymbolIndex(symbol, fg));

 IL.DrawingStyle := TDrawingStyle.dsNormal;
end;

////////////////////////////////////////////////////////////////////////////////

// vykresleni soupravy na dane pozici
procedure TRelief.PaintSouprava(pos:TPoint; useki:Integer; spri:Integer; bgZaver:boolean = false);
var bg: TColor;
    sipkaLeft, sipkaRight: boolean;
    souprava:TUsekSouprava;
begin
 souprava := Self.Useky[useki].PanelProp.soupravy[spri];
 pos := Point(pos.X - (Length(souprava.nazev) div 2), pos.Y);

 // urceni barvy
 if (Self.myORs[Self.Useky[useki].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected) then
  begin
   bg := clYellow;
   if (Self.Graphics.blik) then Exit();
  end else if ((bgZaver) and (Self.Useky[useki].PanelProp.KonecJC > TJCType.no)) then
   bg := _Konec_JC[Integer(Self.Useky[useki].PanelProp.KonecJC)]
  else
   bg := souprava.bg;

 Self.Graphics.TextOutput(pos, souprava.nazev, souprava.fg, bg, true);

 // Lichy : 0 = zleva doprava ->, 1 = zprava doleva <-
 sipkaLeft := (((souprava.sipkaL) and (Self.myORs[Self.Useky[useki].OblRizeni].Lichy = 1)) or
              ((souprava.sipkaS) and (Self.myORs[Self.Useky[useki].OblRizeni].Lichy = 0)));

 sipkaRight := (((souprava.sipkaS) and (Self.myORs[Self.Useky[useki].OblRizeni].Lichy = 1)) or
              ((souprava.sipkaL) and (Self.myORs[Self.Useky[useki].OblRizeni].Lichy = 0)));

 // vykresleni ramecku kolem cisla soupravy
 if (souprava.ramecek <> clBlack) then
  begin
   Self.DrawObject.Surface.Canvas.Pen.Mode    := pmMerge;
   Self.DrawObject.Surface.Canvas.Pen.Color   := souprava.ramecek;
   Self.DrawObject.Surface.Canvas.Brush.Color := clBlack;
   Self.DrawObject.Surface.Canvas.Rectangle(pos.X*SymbolSet._Symbol_Sirka,
                                            pos.Y*SymbolSet._Symbol_Vyska,
                                            (pos.X+Length(souprava.nazev))*SymbolSet._Symbol_Sirka,
                                            (pos.Y+1)*SymbolSet._Symbol_Vyska);
   Self.DrawObject.Surface.Canvas.Pen.Mode := pmCopy;
  end;

 if (sipkaLeft) then
   Self.Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y-1), _Spr_Sipka_Start+1,
             souprava.fg, clNone, true);
 if (sipkaRight) then
   Self.Draw(SymbolSet.IL_Symbols, Point(pos.X+Length(souprava.nazev)-1, pos.Y-1),
             _Spr_Sipka_Start, souprava.fg, clNone, true);

 if ((sipkaLeft) or (sipkaRight)) then
  begin
   // vykresleni sipky
   Self.DrawObject.Surface.Canvas.Pen.Color := souprava.fg;
   Self.DrawObject.Surface.Canvas.MoveTo(pos.X*SymbolSet._Symbol_Sirka, pos.Y*SymbolSet._Symbol_Vyska-1);
   Self.DrawObject.Surface.Canvas.LineTo((pos.X+Length(souprava.nazev))*SymbolSet._Symbol_Sirka,
                                         pos.Y*SymbolSet._Symbol_Vyska-1);
  end;//if sipkaLeft or sipkaRight
end;

////////////////////////////////////////////////////////////////////////////////
// zobrazi soupravy na celem useku

procedure TRelief.ShowUsekSoupravy(useki:Integer);
var i:Integer;
begin
 // vsechny soupravy, ktere se vejdou, krome posledni
 for i := 0 to Min(Self.Useky[useki].Soupravy.Count, Self.Useky[useki].PanelProp.soupravy.Count)-2 do
   Self.PaintSouprava(Self.Useky[useki].Soupravy[i], useki, i);

 // posledni souprava
 if (Self.Useky[useki].PanelProp.soupravy.Count >= 1) then
   Self.PaintSouprava(Self.Useky[useki].Soupravy[Self.Useky[useki].Soupravy.Count-1],
      useki, Self.Useky[useki].PanelProp.Soupravy.Count-1);
end;

////////////////////////////////////////////////////////////////////////////////

// vykresleni cisla koleje
procedure TRelief.PaintCisloKoleje(pos:TPoint; useki:Integer);
var left:TPoint;
begin
 left := Point(pos.X - Length(Self.Useky[useki].KpopisekStr) div 2, pos.Y);

 if (Self.Useky[useki].PanelProp.KonecJC = TJCType.no) then
   Self.Graphics.TextOutput(left, Self.Useky[useki].KpopisekStr,
      Self.Useky[useki].PanelProp.Symbol, Self.Useky[useki].PanelProp.Pozadi)
 else
   Self.Graphics.TextOutput(left, Self.Useky[useki].KpopisekStr,
      Self.Useky[useki].PanelProp.Symbol, _Konec_JC[Integer(Self.Useky[useki].PanelProp.KonecJC)]);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowUseky();
var i,j,k:integer;
    pa:TPointArray;
    showed:array of boolean;
    fg, bg:TColor;
begin
 for i := 0 to Self.Useky.Count-1 do
  begin
   // vykresleni symbolu useku
   // tady se resi vetve
   if ((Self.Useky[i].Vetve.Count = 0) or (Self.Useky[i].PanelProp.Symbol = clFuchsia)) then
    begin
     // pokud nejsou vetve, nebo je usek disabled, vykresim ho cely (bez ohledu na vetve)
     if (((Self.Useky[i].PanelProp.blikani) or ((Self.Useky[i].PanelProp.soupravy.Count > 0) and
        (Self.myORs[Self.Useky[i].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
         and (Self.Graphics.blik)) then
       fg := clBlack
     else
       fg := Self.Useky[i].PanelProp.Symbol;

     for j := 0 to Self.Useky[i].Symbols.Count-1 do
      begin
       bg := Self.Useky[i].PanelProp.Pozadi;

       for k := 0 to Self.StartJC.count-1 do
        if ((Self.StartJC.Data[k].Pos.X = Self.Useky[i].Symbols[j].Position.X) and (Self.StartJC.Data[k].Pos.Y = Self.Useky[i].Symbols[j].Position.Y)) then
         bg := Self.StartJC.Data[k].Color;

       for k := 0 to Self.Useky[i].JCClick.Count-1 do
        if ((Self.Useky[i].JCClick[k].X = Self.Useky[i].Symbols[j].Position.X) and (Self.Useky[i].JCClick[k].Y = Self.Useky[i].Symbols[j].Position.Y)) then
         if (Integer(Self.Useky[i].PanelProp.KonecJC) > 0) then bg := _Konec_JC[Integer(Self.Useky[i].PanelProp.KonecJC)];

       Self.Draw(SymbolSet.IL_Symbols, Self.Useky[i].Symbols[j].Position, Self.Useky[i].Symbols[j].SymbolID,
                 fg, bg);
      end;//for j

    end else begin

     SetLength(showed, Self.Useky[i].Vetve.Count);
     for j := 0 to Self.Useky[i].Vetve.Count-1 do
       showed[j] := false;

     // pokud jsou vetve a usek neni disabled, kreslim vetve
     if (Self.Useky[i].DKStype <> dksNone) then
       Self.ShowDKSVetve(Self.Useky[i], true, showed)
     else
       Self.ShowUsekVetve(Self.Useky[i], 0, true, showed);
    end;

   // vykresleni cisla koleje
   pa := Self.GetSprPaintPos(i, Length(Self.Useky[i].KpopisekStr));
   for j := 0 to pa.count-1 do
     Self.PaintCisloKoleje(pa.Data[j], i);

   // vykresleni souprav
   Self.ShowUsekSoupravy(i);
  end;//for i
end;//procedure

// Rekurzivne kresli vetve bezneho bloku
procedure TRelief.ShowUsekVetve(usek:TPReliefUsk; vetevI:Integer; visible:boolean; var showed:array of boolean);
var i,k:Integer;
    fg, bg:TColor;
    vetev:TVetev;
begin
 if (vetevI < 0) then Exit(); 
 if (showed[vetevI]) then Exit();
 showed[vetevI] := true;
 vetev := usek.Vetve[vetevI];

 vetev.visible := visible;
 usek.Vetve[vetevI] := vetev;

 if (((usek.PanelProp.blikani) or ((usek.PanelProp.soupravy.Count > 0) and
    (Self.myORs[usek.OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
    and (Self.Graphics.blik) and (visible)) then
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

   for k := 0 to Self.StartJC.count-1 do
    if ((Self.StartJC.Data[k].Pos.X = vetev.Symbols[i].Position.X) and (Self.StartJC.Data[k].Pos.Y = vetev.Symbols[i].Position.Y)) then
     bg := Self.StartJC.Data[k].Color;

   for k := 0 to usek.JCClick.Count-1 do
    if ((usek.JCClick[k].X = vetev.Symbols[i].Position.X) and (usek.JCClick[k].Y = vetev.Symbols[i].Position.Y)) then
     if (Integer(usek.PanelProp.KonecJC) > 0) then bg := _Konec_JC[Integer(usek.PanelProp.KonecJC)];

   Self.Draw(SymbolSet.IL_Symbols, vetev.Symbols[i].Position, vetev.Symbols[i].SymbolID, fg, bg);
  end;//for i


 if (vetev.node1.vyh > -1) then
  begin
   Self.Vyhybky.Data[vetev.node1.vyh].visible := visible;

   // nastaveni barvy neprirazene vyhybky
   if (Self.Vyhybky.Data[vetev.node1.vyh].Blok = -2) then
    begin
     Self.Vyhybky.Data[vetev.node1.vyh].PanelProp.Symbol := fg;
     Self.Vyhybky.Data[vetev.node1.vyh].PanelProp.Pozadi := bg;
    end;

   case (Self.Vyhybky.Data[vetev.node1.vyh].PanelProp.Poloha) of
    TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:begin
       Self.ShowUsekVetve(usek, vetev.node1.ref_plus, visible, showed);
       Self.ShowUsekVetve(usek, vetev.node1.ref_minus, visible, showed);
     end;//case disable, both, none

    TVyhPoloha.plus, TVyhPoloha.minus:begin
       if ((Integer(Self.Vyhybky.Data[vetev.node1.vyh].PanelProp.Poloha) xor Self.Vyhybky.Data[vetev.node1.vyh].PolohaPlus) = 0) then
        begin
         Self.ShowUsekVetve(usek, vetev.node1.ref_plus, visible, showed);
         Self.ShowUsekVetve(usek, vetev.node1.ref_minus, false, showed);
        end else begin
         Self.ShowUsekVetve(usek, vetev.node1.ref_plus, false, showed);
         Self.ShowUsekVetve(usek, vetev.node1.ref_minus, visible, showed);
        end;
     end;//case disable, both, none
   end;//case
  end;

 if (vetev.node2.vyh > -1) then
  begin
   Self.Vyhybky.Data[vetev.node2.vyh].visible := visible;

   // nastaveni barvy neprirazene vyhybky
   if (Self.Vyhybky.Data[vetev.node2.vyh].Blok = -2) then
    begin
     Self.Vyhybky.Data[vetev.node2.vyh].PanelProp.Symbol := fg;
     Self.Vyhybky.Data[vetev.node2.vyh].PanelProp.Pozadi := bg;
    end;

   case (Self.Vyhybky.Data[vetev.node2.vyh].PanelProp.Poloha) of
    TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:begin
       Self.ShowUsekVetve(usek, vetev.node2.ref_plus, visible, showed);
       Self.ShowUsekVetve(usek, vetev.node2.ref_minus, visible, showed);
     end;//case disable, both, none

    TVyhPoloha.plus, TVyhPoloha.minus:begin
       if ((Integer(Self.Vyhybky.Data[vetev.node2.vyh].PanelProp.Poloha) xor Self.Vyhybky.Data[vetev.node2.vyh].PolohaPlus) = 0) then
        begin
         Self.ShowUsekVetve(usek, vetev.node2.ref_plus, visible, showed);
         Self.ShowUsekVetve(usek, vetev.node2.ref_minus, false, showed);
        end else begin
         Self.ShowUsekVetve(usek, vetev.node2.ref_plus, false, showed);
         Self.ShowUsekVetve(usek, vetev.node2.ref_minus, visible, showed);
        end;
     end;//case disable, both, none
   end;//case
  end;
end;//procedure

// Zobrazuje vetve bloku, ktery je dvojita kolejova spojka.
procedure TRelief.ShowDKSVetve(usek:TPReliefUsk; visible:boolean; var showed:array of boolean);
var polLeft, polRight: TVyhPoloha;
    leftHidden, rightHidden: boolean;
    leftCross, rightCross: boolean;
    fg: TColor;
begin
 if (usek.Vetve.Count < 3) then Exit();
 if (usek.Vetve[0].node1.vyh < 0) then Exit();
 if (usek.Vetve[1].node1.vyh < 0) then Exit();

 // 1) zjistime si polohy vyhybek
 polLeft := Self.Vyhybky.Data[usek.Vetve[0].node1.vyh].PanelProp.Poloha;
 polRight := Self.Vyhybky.Data[usek.Vetve[1].node1.vyh].PanelProp.Poloha;

 // 2) rozhodneme o tom co barvit
 leftHidden := ((polLeft = TVyhPoloha.plus) and (polRight = TVyhPoloha.minus));
 rightHidden := ((polLeft = TVyhPoloha.minus) and (polRight = TVyhPoloha.plus));

 leftCross := (polLeft <> TVyhPoloha.plus) and (not leftHidden);
 rightCross := (polRight <> TVyhPoloha.plus) and (not rightHidden);

 Self.ShowUsekVetve(usek, 0, leftCross, showed);
 Self.ShowUsekVetve(usek, 1, rightCross, showed);
 Self.ShowUsekVetve(usek, 2,
    not (leftHidden or rightHidden or ((polLeft = TVyhPoloha.minus) and (polRight = TVyhPoloha.minus))), showed);
 if (usek.Vetve.Count > 3) then Self.ShowUsekVetve(usek, 3, not leftHidden, showed);
 if (usek.Vetve.Count > 4) then Self.ShowUsekVetve(usek, 4, not rightHidden, showed);

 Self.Vyhybky.Data[usek.Vetve[0].node1.vyh].visible := not leftHidden;
 Self.Vyhybky.Data[usek.Vetve[1].node1.vyh].visible := not rightHidden;

 // 3) vykreslime stredovy kriz
 if (((usek.PanelProp.blikani) or ((usek.PanelProp.soupravy.Count > 0) and
    (Self.myORs[usek.OblRizeni].RegPlease.status = TORRegPleaseStatus.selected)))
    and (Self.Graphics.blik) and (visible)) then
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
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Top, fg, usek.PanelProp.Pozadi)
   else if (leftCross) then
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 4, fg, usek.PanelProp.Pozadi)
   else if (rightCross) then
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 2, fg, usek.PanelProp.Pozadi)
   else
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Top, usek.PanelProp.nebarVetve, usek.PanelProp.Pozadi)
  end else begin
   if ((leftCross) and (rightCross)) then
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Bot, fg, usek.PanelProp.Pozadi)
   else if (leftCross) then
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 3, fg, usek.PanelProp.Pozadi)
   else if (rightCross) then
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _Usek_Start + 5, fg, usek.PanelProp.Pozadi)
   else
     Self.Draw(SymbolSet.IL_Symbols, usek.root, _DKS_Bot, usek.PanelProp.nebarVetve, usek.PanelProp.Pozadi)
  end;

end;

procedure TRelief.ShowNavestidla();
var i:Integer;
    fg:TColor;
begin
 Self.StartJC.count := 0;

 for i := 0 to Self.Navestidla.Count-1 do
  begin
   if ((Self.Navestidla.Data[i].PanelProp.blikani) and (Self.Graphics.blik)) then
     fg := clBlack
   else
     fg := Self.Navestidla.Data[i].PanelProp.Symbol;

   if (Self.Navestidla.Data[i].PanelProp.AB) then
    begin
     Self.Draw(SymbolSet.IL_Symbols, Self.Navestidla.Data[i].Position, _SCom_Start+Self.Navestidla.Data[i].SymbolID+2,
               fg, Self.Navestidla.Data[i].PanelProp.Pozadi);
    end else begin
     Self.Draw(SymbolSet.IL_Symbols, Self.Navestidla.Data[i].Position, _SCom_Start+Self.Navestidla.Data[i].SymbolID,
               fg, Self.Navestidla.Data[i].PanelProp.Pozadi);
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
 for i := 0 to Self.PomocneObj.Count-1 do
   for j := 0 to Self.PomocneObj.Data[i].Positions.Count-1 do
     Self.Draw(SymbolSet.IL_Symbols, Self.PomocneObj.Data[i].Positions.Data[j], Self.PomocneObj.Data[i].Symbol, _SpecS_DrawColors[Self.PomocneObj.Data[i].Symbol], clBlack);
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
    fg:Integer;
    bkcol:TColor;
begin
 //vyhybky
 for i := 0 to Self.Vyhybky.Count-1 do
  begin
   if ((Self.Vyhybky.Data[i].PanelProp.blikani) and (Self.Graphics.blik) and (Self.Vyhybky.Data[i].visible)) then
     fg := clBlack
   else begin
     if ((Self.Vyhybky.Data[i].visible) or (Self.Vyhybky.Data[i].PanelProp.Symbol = clAqua)) then
      fg := Self.Vyhybky.Data[i].PanelProp.Symbol
     else
      fg := Self.Useky[Self.Vyhybky.Data[i].obj].PanelProp.nebarVetve;
   end;

   if (Self.Vyhybky.Data[i].PanelProp.Pozadi = clBlack) then
     bkcol := Self.Useky[Self.Vyhybky.Data[i].obj].PanelProp.Pozadi
   else
     bkcol := Self.Vyhybky.Data[i].PanelProp.Pozadi;

   if (Self.Vyhybky.Data[i].Blok = -2) then
    begin
     // blok zamerne neprirazen
     Self.Draw(SymbolSet.IL_Symbols, Self.Vyhybky.Data[i].Position,
               Self.Vyhybky.Data[i].SymbolID, fg, bkcol);
    end else begin
     case (Self.Vyhybky.Data[i].PanelProp.Poloha) of
      TVyhPoloha.disabled:begin
       Self.Draw(SymbolSet.IL_Symbols, Self.Vyhybky.Data[i].Position,
                 Self.Vyhybky.Data[i].SymbolID, Self.Useky[Self.Vyhybky.Data[i].obj].PanelProp.Pozadi, clFuchsia);
      end;
      TVyhPoloha.none:begin
       Self.Draw(SymbolSet.IL_Symbols, Self.Vyhybky.Data[i].Position, Self.Vyhybky.Data[i].SymbolID,
                 bkcol, fg);
      end;
      TVyhPoloha.plus:begin
       Self.Draw(SymbolSet.IL_Symbols, Self.Vyhybky.Data[i].Position,
                 (Self.Vyhybky.Data[i].SymbolID)+4+(4*(Self.Vyhybky.Data[i].PolohaPlus xor 0)),
                 fg, bkcol);
      end;
      TVyhPoloha.minus:begin
       Self.Draw(SymbolSet.IL_Symbols, Self.Vyhybky.Data[i].Position,
                 (Self.Vyhybky.Data[i].SymbolID)+8-(4*(Self.Vyhybky.Data[i].PolohaPlus xor 0)),
                 fg, bkcol);
      end;
      TVyhPoloha.both:begin
       Self.Draw(SymbolSet.IL_Symbols, Self.Vyhybky.Data[i].Position, Self.Vyhybky.Data[i].SymbolID,
                 bkcol, clBlue);
      end;
     end;//case
    end;//else blok zamerne neprirazn
  end;//for i
end;//procedure

//zobrazi vsechny dopravni kancelare
procedure TRelief.ShowDK();
var fg:TColor;
    OblR:TORPanel;
begin
 //projedeme vsechny OR
 for OblR in Self.myORs do
  begin
   if (((OblR.dk_blik) or (OblR.RegPlease.status = TORRegPleaseStatus.selected)) and (Self.Graphics.blik)) then
     fg := clBlack
   else begin
     case (OblR.tech_rights) of
      read      : fg := clWhite;
      write     : fg := $A0A0A0;
      superuser : fg := clYellow;
     else//case rights
       fg := clFuchsia;
     end;

     if (OblR.RegPlease.status = TORRegPleaseStatus.selected) then
       fg := clYellow;
   end;

   Self.Draw(SymbolSet.IL_DK, OblR.Poss.DK, OblR.Poss.DKOr, fg, clBlack);

   // symbol osvetleni se vykresluje vlevo
   if (OblR.dk_osv) then
     Self.Draw(SymbolSet.IL_Symbols, Point(OblR.Poss.DK.X-2, OblR.Poss.DK.Y+1), _Hvezdicka, clYellow, clBlack);

   // symbol zadosti o loko se vykresluje vpravo
   if (((OblR.RegPlease.status = TORRegPleaseStatus.request) or (OblR.RegPlease.status = TORRegPleaseStatus.selected)) and (not Self.Graphics.blik)) then
     Self.Draw(SymbolSet.IL_Symbols, Point(OblR.Poss.DK.X+6, OblR.Poss.DK.Y+1), _Kolecko, clYellow, clBlack);

  end;//for i
end;//procedure

//zobrazeni SystemOK + opravneni
procedure TRelief.ShowOpravneni();
var Pos:TPoint;
    c1, c2, c3: TColor;
begin
 Pos.X := 1;
 Pos.Y := Self.Graphics.PanelHeight-3;

 if (PanelTCPClient.status = TPanelConnectionStatus.opened) then
  begin
   c1 := clLime;
   c2 := clRed;
   c3 := clBlue;
  end else begin
   c1 := clPurple;
   c2 := clFuchsia;
   c3 := clPurple;
  end;

 if (Self.SystemOK.Poloha) then
  begin
   // vodorovne

   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y), _Plny_Symbol+1, clBlack, c1);
   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y), _Plny_Symbol+1, clBlack, c1);
   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y), _Plny_Symbol+1, clBlack, c1);

   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y+1), _Plny_Symbol+1, c2, c3);
   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y+1), _Plny_Symbol+1, c2, c3);
   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y+1), _Plny_Symbol+1, c2, c3);
  end else begin
   // svisle

   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y), _Plny_Symbol+1, clBlack, c1);
   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y+1), _Plny_Symbol, c1, c1);

   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y), _Plny_Symbol+2, c2, clBlack);
   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y+1), _Plny_Symbol, c2, clBlack);

   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y), _Plny_Symbol+1, clBlack, c3);
   Self.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y+1), _Plny_Symbol, c3, c3);
  end;

 case (PanelTCPClient.status) of
  TPanelConnectionStatus.closed    : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Odpojeno od serveru', clFuchsia, clBlack);
  TPanelConnectionStatus.opening   : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Otevírám spojení...', clFuchsia, clBlack);
  TPanelConnectionStatus.handshake : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Probíhá handshake...', clFuchsia, clBlack);
  TPanelConnectionStatus.opened    : Self.Graphics.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Pøipojeno k serveru', $A0A0A0, clBlack);
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
   for j := 0 to Self.Prejezdy.Data[i].StaticPositions.Count-1 do
     Self.Draw(SymbolSet.IL_Symbols, Self.Prejezdy.Data[i].StaticPositions.data[j], _Prj_Start, Self.Prejezdy.Data[i].PanelProp.Symbol, Self.Prejezdy.Data[i].PanelProp.Pozadi);

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

         Self.Draw(SymbolSet.IL_Symbols, Self.Prejezdy.Data[i].BlikPositions.data[j].Pos, _Prj_Start, Self.Prejezdy.Data[i].PanelProp.Symbol, Self.Prejezdy.Data[i].PanelProp.Pozadi);
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
    fg:TColor;
begin
 for i := 0 to Self.Uvazky.count-1 do
  begin
   if ((Self.Uvazky.Data[i].PanelProp.blik) and (Self.Graphics.blik)) then
     fg := clBlack
   else
     fg := Self.Uvazky.Data[i].PanelProp.Symbol;

   case (Self.Uvazky.Data[i].PanelProp.smer) of
    TUvazkaSmer.disabled, TUvazkaSmer.zadny:begin
     Self.Draw(SymbolSet.IL_Symbols, Self.Uvazky.Data[i].Pos,
               _Uvazka_Start, fg, Self.Uvazky.Data[i].PanelProp.Pozadi);
     Self.Draw(SymbolSet.IL_Symbols, Point(Self.Uvazky.Data[i].Pos.X+1, Self.Uvazky.Data[i].Pos.Y),
               _Uvazka_Start+1, fg, Self.Uvazky.Data[i].PanelProp.Pozadi);
    end;

    TUvazkaSmer.zakladni, TUvazkaSmer.opacny:begin
     if (((Self.Uvazky.Data[i].PanelProp.smer = zakladni) and (Self.Uvazky.Data[i].defalt_dir = 0)) or
        ((Self.Uvazky.Data[i].PanelProp.smer = opacny) and (Self.Uvazky.Data[i].defalt_dir = 1))) then
      begin
       // sipka zleva doprava
       Self.Draw(SymbolSet.IL_Symbols, Self.Uvazky.Data[i].Pos,
                 _Usek_Start, fg, Self.Uvazky.Data[i].PanelProp.Pozadi);
       Self.Draw(SymbolSet.IL_Symbols, Point(Self.Uvazky.Data[i].Pos.X+1, Self.Uvazky.Data[i].Pos.Y),
                 _Uvazka_Start+1, fg, Self.Uvazky.Data[i].PanelProp.Pozadi);
      end else begin
       // sipka zprava doleva
       Self.Draw(SymbolSet.IL_Symbols, Self.Uvazky.Data[i].Pos,
                 _Uvazka_Start, fg, Self.Uvazky.Data[i].PanelProp.Pozadi);
       Self.Draw(SymbolSet.IL_Symbols, Point(Self.Uvazky.Data[i].Pos.X+1, Self.Uvazky.Data[i].Pos.Y),
                 _Usek_Start, fg, Self.Uvazky.Data[i].PanelProp.Pozadi);
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
      Self.Draw(SymbolSet.IL_Symbols, Point(Self.myORs[j].Poss.Time.X+8+i, Self.myORs[j].Poss.Time.Y+k), _Plny_Symbol, clRed, clBlack);

     for i := (Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2) to (_delka div 2)-1 do
      Self.Draw(SymbolSet.IL_Symbols, Point(Self.myORs[j].Poss.Time.X+8+i, Self.myORs[j].Poss.Time.Y+k), _Plny_Symbol, clWhite, clBlack);

     //vykresleni poloviny symbolu
     SymbolSet.IL_Symbols.BkColor := clWhite;
     if ((Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) mod 2) = 1) then
       Self.Draw(SymbolSet.IL_Symbols, Point(Self.myORs[j].Poss.Time.X+8+(Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2),
                 Self.myORs[j].Poss.Time.Y+k), _Plny_Symbol+1, clRed, clWhite);

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
   if (not Self.DrawObject.CanDraw) then Exit;
   Self.DrawObject.Surface.Canvas.Lock();

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
   Self.DrawObject.Flip();
 finally
   try
     Self.DrawObject.Surface.Canvas.UnLock();
   except

   end;
 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//vykresluje kurzor
procedure TRelief.PaintKurzor();
begin
 if ((Self.CursorDraw.Pos.X < 0) or (Self.CursorDraw.Pos.Y < 0)) then Exit;
 if (GlobConfig.data.panel_mouse <> _MOUSE_PANEL) then Exit();

 // zkopirujeme si obrazek pod kurzorem jeste pred tim, nez se pres nej prekresli mys
 Self.CursorDraw.Pozadi.Canvas.CopyRect(
    Rect(0, 0, SymbolSet._Symbol_Sirka+2, SymbolSet._Symbol_Vyska+2),
    Self.DrawObject.Surface.Canvas,
    Rect( Self.CursorDraw.Pos.X * SymbolSet._Symbol_Sirka - 1,
          Self.CursorDraw.Pos.Y * SymbolSet._Symbol_Vyska - 1,
          (Self.CursorDraw.Pos.X+1) * SymbolSet._Symbol_Sirka + 1,
          (Self.CursorDraw.Pos.Y+1) * SymbolSet._Symbol_Vyska + 1));

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
  mbLeft   : Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.ENTER);
  mbRight  : Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.ESCAPE);
  mbMiddle : begin
    if ((Self.mouseLastBtn = mbMiddle) and (Now - Self.mouseClick < EncodeTime(0, 0, 0, _DblClick_Timeout_Ms))) then
     begin
      Self.mouseTimer.Enabled := false;
      Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.F2);
     end else
      Self.mouseTimer.Enabled := true;
  end;
 end;

 Self.mouseClick := Now;
 Self.mouseLastBtn := Button;

 Self.Show();
end;//procedure

procedure TRelief.OnMouseTimer(Sender:TObject);
begin
 if ((Self.mouseLastBtn = mbMiddle) and (Now - Self.mouseClick > EncodeTime(0, 0, 0, _DblClick_Timeout_Ms))) then
  begin
   Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.F1);
   Self.mouseTimer.Enabled := false;
   Self.Show();
  end;
end;

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
   try
     Self.DrawObject.Surface.Canvas.Lock();
     if (not Assigned(Self.DrawObject)) then Exit;
     if (not Self.DrawObject.CanDraw) then Exit;

     if (Self.Menu.showing) then
       Self.Menu.PaintMenu(Self.DrawObject.Surface.Canvas, Self.CursorDraw.Pos)
     else begin
       Self.PaintKurzorBg(old);
       Self.PaintKurzor();
     end;

     // prekreslime si platno
     Self.DrawObject.Surface.Canvas.Release();
     Self.DrawObject.Flip();
   finally
     try
       if (Self.DrawObject.Surface.Canvas.LockCount > 0) then
         Self.DrawObject.Surface.Canvas.UnLock();
     except

     end;
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

function TRelief.GetVykol(Pos:TPoint):Integer;
var i:Integer;
begin
 for i := 0 to Self.Vykol.Count-1 do
   if ((pos.X = Self.Vykol[i].Pos.X) and (pos.Y = Self.Vykol[i].Pos.Y)) then
     Exit(i);
 Result := -1;
end;//function

////////////////////////////////////////////////////////////////////////////////

//vyvolano pri kliku na relief
procedure TRelief.ObjectMouseUp(Position:TPoint; Button:TPanelButton);
var i, index:Integer;
    handled:boolean;
label
    EscCheck;
begin
 if (Self.Menu.showing) then
  begin
   if (button = TPanelButton.ENTER) then Self.Menu.Click()
     else if (Button = TPanelButton.ESCAPE) then Self.Escape();
   Exit;
  end;

 // nabidka regulatoru u dopravni kancelare
 handled := false;
 for i := 0 to Self.myORs.Count-1 do
  begin
   if (Self.myORs[i].tech_rights < TORControlRights.write) then continue;
   if ((Self.myORs[i].RegPlease.status > TORRegPleaseStatus.null) and (Position.X = Self.myORs[i].Poss.DK.X+6) and (Position.Y = Self.myORs[i].Poss.DK.Y+1)) then
    begin
     if (Button = ENTER) then
      begin
       case (Self.myORs[i].RegPlease.status) of
         TORRegPleaseStatus.request  : Self.myORs[i].RegPlease.status := TORRegPleaseStatus.selected;
         TORRegPleaseStatus.selected : Self.myORs[i].RegPlease.status := TORRegPleaseStatus.request;
       end;//case
     end else
       if (Button = F2) then
         Self.ShowRegMenu(i);

     goto EscCheck;
    end;
  end;//for OblR

 // zasobniky
 handled := false;
 for i := 0 to Self.myORs.Count-1 do
  begin
   if (Self.myORs[i].tech_rights = TORControlRights.null) then continue;
   Self.myORs[i].stack.MouseClick(Position, Button, handled);
   if (handled) then goto EscCheck;
  end;

 //prejezd
 index := Self.GetPrj(Position);
 if (index <> -1) then
  begin
   if (Self.Prejezdy.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Prejezdy.Data[index].OblRizeni].id, Button, Self.Prejezdy.Data[index].Blok);
   goto EscCheck;
  end;

 //rozpojovac
 index := Self.GetRozp(Position);
 if (index <> -1) then
  begin
   if (Self.Rozp[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Rozp[index].OblRizeni].id, Button, Self.Rozp[index].Blok);
   goto EscCheck;
  end;

 //vykolejka
 index := Self.GetVykol(Position);
 if (index <> -1) then
  begin
   if (Self.Vykol[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Vykol[index].OblRizeni].id, Button, Self.Vykol[index].Blok);
   goto EscCheck;
  end;

 //usek
 index := Self.GetUsek(Position);
 if (index <> -1) then
  begin
   if (Self.Useky[index].Blok < 0) then goto EscCheck;

   // kliknutim na usek pri zadani o lokomotivu vybereme hnaciho vozidla na souprave v tomto useku
   if ((Self.myORs[Self.Useky[index].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected) and (Button = ENTER)) then
     //  or;LOK-REQ;U-PLEASE;blk_id              - zadost o vydani seznamu hnacich vozidel na danem useku
     PanelTCPClient.SendLn(Self.myORs[Self.Useky[index].OblRizeni].id + ';LOK-REQ;U-PLEASE;' + IntToStr(Self.Useky[index].Blok))
   else
     PanelTCPClient.PanelClick(Self.myORs[Self.Useky[index].OblRizeni].id, Button, Self.Useky[index].Blok);
   goto EscCheck;
  end;

 //navestidlo
 index := Self.GetNav(Position);
 if (index <> -1) then
  begin
   if (Self.Navestidla.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Navestidla.Data[index].OblRizeni].id, Button, Self.Navestidla.Data[index].Blok);
   goto EscCheck;
  end;

 //vyhybka
 index := Self.GetVyh(Position);
 if (index <> -1) then
  begin
   if (Self.Vyhybky.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Vyhybky.Data[index].OblRizeni].id, Button, Self.Vyhybky.Data[index].Blok);
   goto EscCheck;
  end;

 //DK
 index := Self.GetDK(Position);
 if (index <> -1) then
  begin
   if (Self.myORs[index].dk_click_server) then
    begin
     PanelTCPClient.SendLn(Self.myORs[index].id+';DK-CLICK;'+IntToStr(Integer(Button)));
    end else if (Button <> TPanelButton.ESCAPE) then
     Self.ShowDKMenu(index);
   goto EscCheck;
  end;

 //uvazka
 index := Self.GetUvazka(Position);
 if (index <> -1) then
  begin
   if (Self.Uvazky.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Uvazky.Data[index].OblRizeni].id, Button, Self.Uvazky.Data[index].Blok);
   goto EscCheck;
  end;

 //zamek
 index := Self.GetZamek(Position);
 if (index <> -1) then
  begin
   if (Self.Zamky.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Zamky.Data[index].OblRizeni].id, Button, Self.Zamky.Data[index].Blok);
   goto EscCheck;
  end;

 if (Button = TPanelButton.ESCAPE) then
  begin
   Self.Escape();
   Exit();
  end;

EscCheck:
 // Na bloku byl zavolan escape -> volame interni escape, ale neposilame jej
 // ne server (uz byl poslan).
 if (Button = TPanelButton.ESCAPE) then
  Self.Escape(false);
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
   inifile := TMemIniFile.Create(aFile, TEncoding.UTF8);
 except
  Exit(3);
 end;

 Self.Graphics.PanelWidth := inifile.ReadInteger('P','W',0);
 Self.Graphics.PanelHeight := inifile.ReadInteger('P','H',0);

 //kontrola verze
 ver := inifile.ReadString('G','ver',_FileVersion);
 if (_FileVersion <> ver) then
  begin
   if (Application.MessageBox(PChar('Naèítáte soubor s verzí '+ver+#13#10+'Aplikace momentálnì podporuje verzi '+_FileVersion+#13#10+'Chcete pokraèovat?'), 'Varování', MB_YESNO OR MB_ICONQUESTION) = mrNo) then
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
   usek.root      := GetPos(inifile.ReadString('U'+IntToStr(i), 'R', '-1;-1'));
   usek.DKStype := TDKSType(inifile.ReadInteger('U'+IntToStr(i), 'DKS', Integer(dksNone)));

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

   //Soupravy
   obj := inifile.ReadString('U'+IntToStr(i),'Spr','');
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
   if (Self.myORs[usek.OblRizeni].Lichy = 1) then
     usek.Soupravy.Reverse();

   // pokud nejsou pozice na soupravu, kreslime soupravu na cisle koleje
   if ((usek.Soupravy.Count = 0) and (usek.KpopisekStr <> '') and (usek.KPopisek.Count <> 0)) then
     usek.Soupravy.Add(usek.KPopisek[0]);

   //nacitani vetvi:
   usek.Vetve := TList<TVetev>.Create();
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
   if (usek.Blok = -2) then
     usek.PanelProp := _UA_Usek_Prop
   else
     usek.PanelProp := _Def_Usek_Prop;

   usek.PanelProp.soupravy := TList<TUsekSouprava>.Create();

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
   if (usek.Blok = -2) then
     Self.Navestidla.Data[i].PanelProp := _UA_Nav_Prop
   else
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
   if (Self.Vyhybky.Data[i].Blok = -2) then
     Self.Vyhybky.Data[i].PanelProp := _UA_Vyh_Prop
   else
     Self.Vyhybky.Data[i].PanelProp := _Def_Vyh_Prop;

   Self.AddToTechBlk(_BLK_VYH, Self.Vyhybky.Data[i].Blok, i);
  end;

 //prejezdy
 for i := 0 to Self.Prejezdy.count-1 do
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
   if (Self.Prejezdy.Data[i].Blok = -2) then
     Self.Prejezdy.Data[i].PanelProp := _UA_Prj_Prop
   else
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

   //default settings:
   if (Self.Uvazky.Data[i].Blok = -2) then
     Self.Uvazky.Data[i].PanelProp := _UA_Uvazka_Prop
   else
     Self.Uvazky.Data[i].PanelProp := _Def_Uvazka_Prop;

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

   //default settings:
   if (Self.Zamky.Data[i].Blok = -2) then
     Self.Zamky.Data[i].PanelProp := _UA_Zamek_Prop
   else
     Self.Zamky.Data[i].PanelProp := _Def_Zamek_Prop;

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

   //default settings:
   if (vykol.Blok = -2) then
     vykol.PanelProp := Self._UA_Vyh_Prop
   else
     vykol.PanelProp := Self._Def_Vyh_Prop;

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

   //default settings:
   if (rozp.Blok = -2) then
     rozp.PanelProp := Self._UA_Rozp_Prop
   else
     rozp.PanelProp := Self._Def_Rozp_Prop;

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
   Self.Useky[i].Soupravy.Count := 0;
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
     VK_F1 : Self.ObjectMouseUp(Self.CursorDraw.Pos, F1);
     VK_F2 : Self.ObjectMouseUp(Self.CursorDraw.Pos, F2);
     VK_ESCAPE: Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.ESCAPE);
     VK_RETURN: Self.ObjectMouseUp(Self.CursorDraw.Pos, ENTER);
     VK_BACK: Errors.removeerror();

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

procedure TRelief.Escape(send:boolean = true);
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

 if (send) then
   PanelTCPClient.PanelClick('-', TPanelButton.ESCAPE);
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
procedure TRelief.ORAuthoriseResponse(Sender:string; Rights:TORControlRights; comment:string=''; username:string='');
var i,orindex:Integer;
    tmp:TORControlRights;
begin
 orindex := -1;
 for i := 0 to Self.myORs.Count-1 do
  if (Self.myORs[i].id = Sender) then orindex := i;

 if (orindex = -1) then Exit;

 tmp := Self.myORs[orindex].tech_rights;
 Self.myORs[orindex].tech_rights := Rights;
 Self.myORs[orindex].username    := username;
 Self.UpdateLoginString();

 if ((Rights < tmp) and (Rights < write)) then
  begin
   Self.myORs[orindex].MereniCasu.Clear();
   while (SoundsPlay.IsPlaying(_SND_TRAT_ZADOST)) do
     SoundsPlay.DeleteSound(_SND_TRAT_ZADOST);
  end;

 if ((tmp = TORControlRights.null) and (Rights > tmp)) then
   PanelTCPClient.PanelFirstGet(Sender);

 if (Rights = TORControlRights.null) then
   Self.OrDisconnect(orindex);

 if ((Rights > TORControlRights.null) and (tmp = TORControlRights.null)) then
   Self.myORs[orindex].stack.enabled := true;

 if ((Rights >= TORControlRights.write) and (BridgeClient.authStatus = TuLIAuthStatus.no) and (BridgeClient.toLogin.password <> '')) then
   BridgeClient.Auth();

 if (Rights >= TORControlRights.read) then
   IPC.CheckAuth();

 if (F_Auth.listening) then
  begin
   if (Rights = TORControlRights.null) then
     F_Auth.AuthError(orindex, comment)
   else
     F_Auth.AuthOK(orindex);
  end;

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
var i, j, cnt:Integer;
    ors:TIntAr;
    rights:TOrControlRights;
begin
 // zjistime pocet OR s zadanym opravnenim > null
 cnt := GlobConfig.GetAuthNonNullORSCnt();
 if (cnt = 0) then Exit();

 // do \ors si priradime vsechna or s zadanym opravnenim > null
 SetLength(ors, cnt);
 j := 0;
 for i := 0 to Self.ORs.Count-1 do
   if ((GlobConfig.data.auth.ORs.TryGetValue(Self.myORs[i].id, rights)) and (rights > TORControlRights.null)) then
    begin
     ors[j] := i;
     Inc(j);
    end;

 if (GlobConfig.data.auth.autoauth) then
  begin
   F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.auth.username, 2, Self.ORConnectionOpenned_AuthCallback, ors, true);
   Self.ORConnectionOpenned_AuthCallback(Self, GlobConfig.data.auth.username, GlobConfig.data.auth.password, ors, false);

   if ((GlobConfig.data.uLI.use) and (BridgeClient.authStatus = TuLiAuthStatus.no) and (not PanelTCPClient.openned_by_ipc)) then
    begin
     BridgeClient.toLogin.username := GlobConfig.data.auth.username;
     BridgeClient.toLogin.password := GlobConfig.data.auth.password;
    end;

  end else begin
   F_Auth.OpenForm('Vyžadována autorizace', Self.ORConnectionOpenned_AuthCallback, ors, true);
  end;
end;//procedure

procedure TRelief.ORConnectionOpenned_AuthCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);
var i:Integer;
    rights:TOrControlRights;
begin
 for i := 0 to Self.myORs.Count-1 do
  begin
   if (GlobConfig.data.auth.ORs.TryGetValue(Self.myORs[i].id, rights)) then begin
     if (rights > TORControlRights.null) then
      begin
       if ((rights > TORControlRights.read) and (guest)) then rights := TORControlRights.read;
       Self.myORs[i].login := username;
       PanelTCPClient.PanelAuthorise(Self.myORs[i].id, rights, username, password)
      end;
   end else begin
     Self.myORs[i].login := username;
     PanelTCPClient.PanelAuthorise(Self.myORs[i].id, read, username, password);
   end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//komunikace s oblastmi rizeni:
//change blok stav:

procedure TRelief.ORUsekChange(Sender:string; BlokID:integer; UsekPanelProp:TUsekPanelProp);
var i:Integer;
    usk:TPReliefUsk;
    symbols:TList<TTechBlokToSymbol>;
    t:TList<TUsekSouprava>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
   if ((symbols[i].blk_type = _BLK_USEK) and (Sender = Self.myORs[Self.Useky[symbols[i].symbol_index].OblRizeni].id)) then
    begin
     usk := Self.Useky[symbols[i].symbol_index];

     // zkopirujeme seznam souprav
     t := usk.PanelProp.soupravy;
     usk.PanelProp := UsekPanelProp;
     t.Clear();
     t.AddRange(UsekPanelProp.soupravy);
     usk.PanelProp.soupravy := t;

     Self.Useky[symbols[i].symbol_index] := usk;
    end;

 UsekPanelProp.soupravy.Free();
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
       Self.ORInfoMsg('Nejsou volné loko');

     Exit();
    end;
end;//procedure

procedure TRelief.ORSprEdit(Sender:string; parsed:TStrings);
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   if (Sender = Self.myORs[i].id) then
    begin
     F_SoupravaEdit.EditSpr(parsed, Self.myORs[i].HVs, Self.myORs[i].id, Self.myORs[i].Name);
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
begin
 Self.menu_lastpos := Self.CursorDraw.Pos;
 Self.special_menu := TSpecialMenu.none;
 Self.Menu.ShowMenu(items, -1, Self.DrawObject.ClientToScreen(Point(0,0)));
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.HideMenu();
var bPos:TPoint;
begin
 Self.Menu.showing := false;
 Self.special_menu := TSpecialMenu.none;
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 SetCursorPos(Self.menu_lastpos.X*SymbolSet._Symbol_Sirka + bPos.X, Self.menu_lastpos.Y*SymbolSet._Symbol_Vyska + bPos.Y);
 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////
//DKMenu popup:

procedure TRelief.ShowDKMenu(obl_rizeni:Integer);
var menu_str:string;
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

   if (Self.myORs[obl_rizeni].hlaseni) then
    menu_str := menu_str + 'HLÁŠENÍ,';
  end;

 menu_str := menu_str + 'INFO,';

 Self.special_menu := dk;
 Self.menu_lastpos := Self.CursorDraw.Pos;

 Self.Menu.ShowMenu(menu_str, obl_rizeni, Self.DrawObject.ClientToScreen(Point(0,0)));
end;//procedure

////////////////////////////////////////////////////////////////////////////////
//DKMenu clicks:

procedure TRelief.DKMenuClickMP(Sender:Integer; item:string);
var ors:TIntAr;
begin
 SetLength(ors, 1);
 ors[0] := Sender;

 if ((GlobConfig.data.auth.autoauth) and (Self.myORs[Sender].tech_rights < TORCOntrolRights.superuser)) then
  begin
   if (item = 'MP') then begin
     F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.auth.username, 2, Self.AuthWriteCallback, ors, false);
     Self.AuthWriteCallback(Self, GlobConfig.data.auth.username, GlobConfig.data.auth.password, ors, false);
   end else begin
     F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.auth.username, 2, Self.AuthReadCallback, ors, true);
     Self.AuthReadCallback(Self, GlobConfig.data.auth.username, GlobConfig.data.auth.password, ors, false);
   end;
  end else begin
   if (item = 'MP') then
     F_Auth.OpenForm('Vyžadována autorizace', Self.AuthWriteCallback, ors, false)
   else
     F_Auth.OpenForm('Vyžadována autorizace', Self.AuthReadCallback, ors, true)
  end;
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
begin
 menu_str := '$'+Self.myORs[Sender].Name+',$Osvìtlení,-,';

 for i := 0 to Self.myORs[Sender].Osvetleni.Count-1 do
  begin
   case (Self.myORs[Sender].Osvetleni[i].state) of
    false : menu_str := menu_str + Self.myORs[Sender].Osvetleni[i].name + '>,';
    true  : menu_str := menu_str + Self.myORs[Sender].Osvetleni[i].name + '<,';
   end;//case
  end;

 Self.special_menu := osv;
 Self.Menu.ShowMenu(menu_str, Sender, Self.DrawObject.ClientToScreen(Point(0,0)));
end;//procedure

procedure TRelief.DKMenuClickLOKO(Sender:Integer; item:string);
var menu_str:string;
begin
 // nejdøív aktualizuji seznam LOKO
 PanelTCPClient.PanelLokList(Self.myORs[Sender].id);

 menu_str := '$'+Self.myORs[Sender].Name+',$LOKO,-,NOVÁ loko,EDIT loko,SMAZAT loko,PØEDAT loko,HLEDAT loko,RUÈ loko';
 if (BridgeClient.authStatus = TuLIAuthStatus.yes) then menu_str := menu_str + ',MAUS loko';

 Self.special_menu := loko;
 Self.Menu.ShowMenu(menu_str, Sender, Self.DrawObject.ClientToScreen(Point(0,0)));
end;//procedure

procedure TRelief.DKMenuClickSUPERUSER(Sender:Integer; item:string);
var ors: TIntAr;
begin
 SetLength(ors, 1);
 ors[0] := Sender;
 F_Auth.OpenForm('Vyžadována autorizace', Self.DKMenuClickSUPERUSER_AuthCallback, ors, false);
end;//procedure

procedure TRelief.DKMenuClickSUPERUSER_AuthCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);
begin
 Self.myORs[ors[0]].login := username;
 PanelTCPClient.PanelAuthorise(Self.myORs[ors[0]].id, superuser, username, password);
 Self.root_menu := false;
end;

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

procedure TRelief.DKMenuClickINFO(Sender:Integer; item:string);
var lichy, rs:string;
begin
 if (Self.myORs[Sender].Lichy = 0) then
  lichy := 'zleva doprava'
 else if (Self.myORs[Sender].Lichy = 1) then
  lichy := 'zprava doleva'
 else lichy := 'nedefinován';

 case (Self.myORs[Sender].tech_rights) of
  TORControlRights.read      : rs := 'ke ètení';
  TORControlRights.write     : rs := 'k zápisu';
  TORControlRights.superuser : rs := 'superuser';
 else
  rs := 'nedefinováno';
 end;

 Application.MessageBox(PChar('Oblast øízení : ' + Self.myORs[Sender].Name + #13#10 +
                              'ID : ' + Self.myORs[Sender].id + #13#10 +
                              'Pøihlášen : ' + Self.myORs[Sender].username + #13#10 +
                              'Lichý smìr : ' + lichy + #13#10 +
                              'Oprávnìní : ' + rs),
      PChar(Self.myORs[Sender].Name), MB_OK OR MB_ICONINFORMATION);
end;

procedure TRelief.DKMenuClickHLASENI(Sender:Integer; item:string);
var menu_str:string;
begin
 menu_str := '$'+Self.myORs[Sender].Name+',$STANIÈNÍ HLÁŠENÍ,-,POSUN,NESAHAT,INTRO,SPEC1,SPEC2,SPEC3';
 Self.special_menu := hlaseni;
 Self.Menu.ShowMenu(menu_str, Sender, Self.DrawObject.ClientToScreen(Point(0,0)));
end;

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
begin
 if ((PanelTCPClient.status <> TPanelConnectionStatus.opened) or
     (Self.myORs[obl_rizeni].RegPlease.status = TORRegPleaseStatus.null)) then Exit();

 menu_str := '$' + Self.myORs[obl_rizeni].Name + ',$Žádost o loko,-,INFO,ODMÍTNI';

 Self.myORs[obl_rizeni].RegPlease.status := TORRegPleaseStatus.request;

 Self.special_menu := reg_please;
 Self.menu_lastpos := Self.CursorDraw.Pos;

 Self.Menu.ShowMenu(menu_str, obl_rizeni, Self.DrawObject.ClientToScreen(Point(0,0)));

 PanelTCPClient.PanelLokList(Self.myORs[obl_rizeni].id);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.MenuOnClick(Sender:TObject; item:string; obl_r:Integer; itemindex:Integer);
var sp_menu:TSpecialMenu;
begin
 sp_menu := Self.special_menu;
 Self.HideMenu();

 case (sp_menu) of
  none       : PanelTCPClient.PanelMenuClick(item, itemindex);
  dk         : Self.ParseDKMenuClick(item, obl_r);
  osv        : Self.OSVMenuClick(obl_r, item);
  loko       : Self.ParseLOKOMenuClick(item, obl_r);
  reg_please : Self.ParseRegMenuClick(item, obl_r);
  hlaseni    : Self.ParseHlaseniMenuClick(item, obl_r);
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
 else if (item = 'CAS') then Self.DKMenuClickSetCAS(obl_r, item)
 else if (item = 'INFO') then Self.DKMenuClickINFO(obl_r, item)
 else if (item = 'HLÁŠENÍ') then Self.DKMenuClickHLASENI(obl_r, item);           
end;//procedure

procedure TRelief.ParseLOKOMenuClick(item:string; obl_r:Integer);
begin
 if (item = 'NOVÁ loko')   then F_HVEdit.HVAdd(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'EDIT loko')   then F_HVEdit.HVEdit(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'SMAZAT loko') then F_HVDelete.OpenForm(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'PØEDAT loko') then F_HV_Move.Open(Self.myORs[obl_r].id, Self.myORs[obl_r].HVs)
 else if (item = 'HLEDAT loko') then F_HVSearch.Show()
 else if ((item = 'RUÈ loko') or (item = 'MAUS loko')) then
   F_RegReq.Open(
      Self.myORs[obl_r].HVs,
      Self.myORs[obl_r].id,
      Self.myORs[obl_r].RegPlease.user,
      Self.myORs[obl_r].RegPlease.firstname,
      Self.myORs[obl_r].RegPlease.lastname,
      Self.myORs[obl_r].RegPlease.comment,
      (Self.myORs[obl_r].RegPlease.status <> TORRegPleaseStatus.null),
      false, false, (item = 'MAUS loko'));
end;//procedure

procedure TRelief.ParseRegMenuClick(item:string; obl_r:Integer);
begin
 if (item = 'ODMÍTNI') then PanelTCPClient.SendLn(Self.myORs[obl_r].id+';LOK-REQ;DENY')
 else if (item = 'INFO') then
  begin
   F_RegReq.Open(
      Self.myORs[obl_r].HVs,
      Self.myORs[obl_r].id,
      Self.myORs[obl_r].RegPlease.user,
      Self.myORs[obl_r].RegPlease.firstname,
      Self.myORs[obl_r].RegPlease.lastname,
      Self.myORs[obl_r].RegPlease.comment,
      true, false, false, false);
  end;
end;//procedure

procedure TRelief.ParseHlaseniMenuClick(item:string; obl_r:Integer);
begin
 PanelTCPClient.SendLn(Self.ORs[obl_r].id + ';SHP;SPEC;' + item);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.OrDisconnect(orindex:Integer = -1);
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
  if (((orindex < 0) or (Self.Useky[i].OblRizeni = orindex)) and
      (Self.Useky[i].Blok > -2)) then
   begin
    usk := Self.Useky[i];
    usk.PanelProp.soupravy.Free();
    usk.PanelProp := _Def_Usek_Prop;
    usk.PanelProp.soupravy := TList<TUsekSouprava>.Create();
    Self.Useky[i] := usk;
   end;

 for i := 0 to Self.Vyhybky.Count-1 do
  if (((orindex < 0) or (Self.Vyhybky.Data[i].OblRizeni = orindex)) and
      (Self.Vyhybky.Data[i].Blok > -2)) then
    Self.Vyhybky.Data[i].PanelProp := _Def_Vyh_Prop;

 for i := 0 to Self.Navestidla.Count-1 do
  if (((orindex < 0) or (Self.Navestidla.Data[i].OblRizeni = orindex)) and
      (Self.Navestidla.Data[i].Blok > -2)) then
    Self.Navestidla.Data[i].PanelProp := _Def_Nav_Prop;

 for i := 0 to Self.Prejezdy.Count-1 do
  if (((orindex < 0) or (Self.Prejezdy.Data[i].OblRizeni = orindex)) and
      (Self.Prejezdy.Data[i].Blok > -2)) then
    Self.Prejezdy.Data[i].PanelProp := _Def_Prj_Prop;

 for i := 0 to Self.Uvazky.Count-1 do
  if (((orindex < 0) or (Self.Uvazky.Data[i].OblRizeni = orindex)) and
      (Self.Uvazky.Data[i].Blok > -2)) then
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
  if (((orindex < 0) or (Self.Zamky.Data[i].OblRizeni = orindex)) and
      (Self.Zamky.Data[i].Blok > -2)) then
    Self.Zamky.Data[i].PanelProp := _Def_Zamek_Prop;

 for i := 0 to Self.Vykol.Count-1 do
  if (((orindex < 0) or (Self.Vykol[i].OblRizeni = orindex)) and
      (Self.Vykol[i].Blok > -2)) then
   begin
    vykol := Self.Vykol[i];
    vykol.PanelProp := _Def_Vyh_Prop;
    Self.Vykol[i] := vykol;
   end;

 for i := 0 to Self.Rozp.Count-1 do
  if (((orindex < 0) or (Self.Rozp[i].OblRizeni = orindex)) and
      (Self.Rozp[i].Blok > -2)) then
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
     Self.myORs[i].hlaseni          := false;
     Self.myORs[i].login            := '';
     Self.myORs[i].username         := '';
    end;
  end;

 Self.Show();
 Self.UpdateLoginString();
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
    fg:TColor;
begin
 for i := 0 to Self.Zamky.Count-1 do
  begin
   if ((Self.Zamky.Data[i].PanelProp.blik) and (Self.Graphics.blik)) then
     fg := clBlack
   else
     fg := Self.Zamky.Data[i].PanelProp.Symbol;

   Self.Draw(SymbolSet.IL_Symbols, Self.Zamky.Data[i].Pos, _Zamek,
             fg, Self.Zamky.Data[i].PanelProp.Pozadi);
  end;//for i
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// vykreslit rozpojovace
procedure TRelief.ShowRozp;
var i:Integer;
begin
 for i := 0 to Self.Rozp.Count-1 do
   Self.Draw(SymbolSet.IL_Symbols, Self.Rozp[i].Pos, _Rozp_Start+1, Self.Rozp[i].PanelProp.Symbol, clBlack, true);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// vykreslit vykolejky
procedure TRelief.ShowVykol;
var i:Integer;
    fg, bkcol:TColor;
    visible:boolean;
begin
 for i := 0 to Self.Vykol.Count-1 do
  begin
   visible := ((Self.Vykol[i].PanelProp.Poloha = TVyhPoloha.disabled) or (Self.Vykol[i].vetev < 0) or
     (Self.Vykol[i].vetev >= Self.Useky[Self.Vykol[i].usek].Vetve.Count) or
     (Self.Useky[Self.Vykol[i].usek].Vetve[Self.Vykol[i].vetev].visible));

   if ((Self.Vykol[i].PanelProp.blikani) and (Self.Graphics.blik) and (visible)) then
     fg := clBlack
   else begin
     if ((visible) or (Self.Vykol[i].PanelProp.Symbol = clAqua)) then
      fg := Self.Vykol[i].PanelProp.Symbol
     else
      fg := Self.Useky[Self.Vykol[i].usek].PanelProp.nebarVetve;
   end;

   if (Self.Vykol[i].PanelProp.Pozadi = clBlack) then
     bkcol := Self.Useky[Self.Vykol[i].usek].PanelProp.Pozadi
   else
     bkcol := Self.Vykol[i].PanelProp.Pozadi;

   case (Self.Vykol[i].PanelProp.Poloha) of
    TVyhPoloha.disabled : Self.Draw(SymbolSet.IL_Symbols, Self.Vykol[i].Pos,
        _Vykol_Start+Self.Vykol[i].symbol, Self.Useky[Self.Vykol[i].usek].PanelProp.Pozadi, clFuchsia);
    TVyhPoloha.none     : Self.Draw(SymbolSet.IL_Symbols, Self.Vykol[i].Pos,
        _Vykol_Start+Self.Vykol[i].symbol, bkcol, fg);
    TVyhPoloha.plus     : Self.Draw(SymbolSet.IL_Symbols, Self.Vykol[i].Pos,
        _Vykol_Start+Self.Vykol[i].symbol, fg, bkcol);
    TVyhPoloha.minus    : Self.Draw(SymbolSet.IL_Symbols, Self.Vykol[i].Pos,
        _Vykol_Start+Self.Vykol[i].symbol+2, fg, bkcol);
    TVyhPoloha.both     : Self.Draw(SymbolSet.IL_Symbols, Self.Vykol[i].Pos,
        _Vykol_Start+Self.Vykol[i].symbol, bkcol, clBlue);
   end;
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
      true, true, true, false);
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

procedure TRelief.UpdateLoginString();
begin
 if (Assigned(Self.OnLoginUserChange)) then
   Self.OnLoginUserChange(Self, Self.GetLoginString());
end;

function TRelief.GetLoginString():string;
var i:Integer;
    res:string;
begin
 if (Self.myORs.Count = 0) then Exit('-');

 if (Self.myORs[0].username = '') then
  res := ''
 else
  res := Self.myORs[0].username;

 for i := 1 to Self.myORs.Count-1 do
   if (res = '-') then
     res := Self.myORs[i].username
   else
     if (Self.myORs[i].username <> res) then Exit('více uživatelù');

 if (res = '') then
   res := '-';

 Result := res;
end;

////////////////////////////////////////////////////////////////////////////////

function TRelief.AnyORWritable():boolean;
var OblR:TORPanel;
begin
 for OblR in Self.ORs do
   if (OblR.tech_rights > TORControlRights.read) then Exit(true);
 Result := false;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ReAuthorize();
var fors:TIntAr;
    i, j, cnt:Integer;
    rights:TORControlRights;
begin
 // pokud je alespon jedno OR pro zapis, odhlasujeme vsechny OR, na kterych je prihlsen uzivatel z prvni OR
 // ciste teoreticky tedy muzeme postupne odhlasovat ruzne uzivatele z jednotlivych OR
 // Tato situace by ale nemela nastavat, k jednomu panelu by mel byt prihlaseny vzdy jen jeden uzivatel,
 // popr. uzivatel v nekolika OR a guest v nekolika dalsich OR.

 if ((PanelTCPClient.status <> TPanelCOnnectionStatus.opened) or (F_Auth.Showing)) then Exit();

 if (Self.AnyORWritable()) then
  begin
   if (not GlobConfig.data.guest.allow) then
    begin
     // ucet hosta neni povoleny -> odhlasime uzivatele a zobrazime vyzvu k prihlaseni noveho
     GlobConfig.data.auth.autoauth := false;
     GlobConfig.data.auth.username := '';
     GlobConfig.data.auth.password := '';

     SetLength(fors, Self.ORs.Count);
     for i := 0 to Self.ORs.Count-1 do
      begin
       fors[i] := i;
       Self.myORs[i].login := '';
       PanelTCPClient.PanelAuthorise(Self.myORs[i].id, TORControlRights.null, '', '');
      end;

     F_Auth.OpenForm('Vyžadována autorizace', Self.ORConnectionOpenned_AuthCallback, fors, true);
     Exit();
    end;

   // jdeme prihlasit readera vsude
   Self.reAuth.old_ors.Clear();

   // zjistime si aktualne prihlasene uzivatele a ke kterym OR je prihlasen
   Self.reAuth.old_login := '';
   for i := 0 to Self.ORs.Count-1 do
    begin
     if ((Self.ORs[i].login <> '') and (Self.ORs[i].login <> GlobConfig.data.guest.username) and (Self.reAuth.old_login = '')) then
       Self.reAuth.old_login := Self.ORs[i].login;
     if ((Self.reAuth.old_login <> '') and (Self.reAuth.old_login = Self.ORs[i].login) and (Self.ORs[i].tech_rights >= TORControlRights.write)) then
       Self.reAuth.old_ors.Add(i);
    end;

   // vytvorime pole indexu oblasti rizeni pro autorizacni proces
   SetLength(fors, Self.reAuth.old_ors.Count);
   for i := 0 to Self.reAuth.old_ors.Count-1 do fors[i] := Self.reAuth.old_ors[i];

   // zapomeneme ulozeneho uzivatele
   if ((GlobConfig.data.auth.autoauth) and (GlobConfig.data.auth.username = Self.reAuth.old_login)) then
    begin
     GlobConfig.data.auth.autoauth := false;
     GlobConfig.data.auth.username := '';
     GlobConfig.data.auth.password := '';
    end;

   // na OR v seznamu 'Self.reAuth.old_ors' prihlasime hosta
   F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.guest.username, 0, Self.AuthReadCallback, fors, true);
   Self.AuthReadCallback(Self, GlobConfig.data.guest.username, GlobConfig.data.guest.password, fors, false);

   // v pripade povolene IPC odhlasime i zbyle panely
   if (GlobConfig.data.auth.ipc_send) then
    begin
     IPC.username := GlobConfig.data.guest.username;
     IPC.password := GlobConfig.data.guest.password;
    end;
  end else begin

   if (Self.reAuth.old_ors.Count = 0) then
    begin
     // zadne OR nezapamatovany -> prihlasujeme uzivatele na vsechny OR
     cnt := GlobConfig.GetAuthNonNullORSCnt();
     if (cnt = 0) then Exit();

     // do \ors si priradime vsechna or s zadanym opravnenim > null
     SetLength(fors, cnt);
     j := 0;
     for i := 0 to Self.ORs.Count-1 do
       if ((GlobConfig.data.auth.ORs.TryGetValue(Self.ORs[i].id, rights)) and (rights > TORControlRights.null)) then
        begin
         fors[j] := i;
         Inc(j);
        end;

     F_Auth.OpenForm('Vyžadována autorizace', Self.ORConnectionOpenned_AuthCallback, fors, true)
    end else begin
     // OR zapamatovany -> prihlasujeme uzivatele jen na tyto OR

     // vytvorime pole indexu oblasti rizeni pro autorizacni proces
     SetLength(fors, Self.reAuth.old_ors.Count);
     for i := 0 to Self.reAuth.old_ors.Count-1 do fors[i] := Self.reAuth.old_ors[i];

     // na OR v seznamu 'Self.reAuth.old_ors' prihlasime skutecneho uzivatele
     F_Auth.OpenForm('Vyžadována autorizace', Self.AuthWriteCallback, fors, false, Self.reAuth.old_login);

     Self.reAuth.old_login := '';
     Self.reAuth.old_ors.Clear();
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.IPAAuth();
var i, j, cnt:Integer;
    ors:TIntAr;
    rights:TOrControlRights;
begin
 if (PanelTCPClient.status = TPanelConnectionStatus.opened) then
  begin
   // existujici spojeni -> autorizovat

   // zjistime pocet OR s (zadanym opravnenim > null) nebo (prave autorizovanych)
   cnt := 0;
   for i := 0 to Self.ORs.Count-1 do
     if ((not GlobConfig.data.auth.ORs.TryGetValue(Self.myORs[i].id, rights)) or (rights > TORControlRights.null) or
         (Self.ORs[i].tech_rights > TORControlRights.null)) then Inc(cnt);

   // do \ors si priradime vsechna or s (zadanym opravennim > null) nebo (prave autorizovanych)
   SetLength(ors, cnt);
   j := 0;
   for i := 0 to Self.ORs.Count-1 do
     if ((not GlobConfig.data.auth.ORs.TryGetValue(Self.myORs[i].id, rights)) or (rights > TORControlRights.null) or
         (Self.ORs[i].tech_rights > TORControlRights.null)) then
      begin
       ors[j] := i;
       Inc(j);
      end;

   Self.ORConnectionOpenned_AuthCallback(Self, GlobConfig.data.auth.username, GlobConfig.data.auth.password, ors, false);
  end else begin
   // nove spojeni -> pripojit
   try
    PanelTCPClient.Connect(GlobConfig.data.server.host, GlobConfig.data.server.port);
    PanelTCPClient.openned_by_ipc := true;
   except

   end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.AuthReadCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);
var i:Integer;
begin
 for i := 0 to Length(ors)-1 do
  begin
   Self.myORs[ors[i]].login := username;
   PanelTCPClient.PanelAuthorise(Self.myORs[ors[i]].id, read, username, password);
  end;
end;

procedure TRelief.AuthWriteCallback(Sender:TObject; username:string; password:string; ors:TIntAr; guest:boolean);
var i:Integer;
begin
 for i := 0 to Length(ors)-1 do
  begin
   Self.myORs[ors[i]].login := username;
   PanelTCPClient.PanelAuthorise(Self.myORs[ors[i]].id, write, username, password);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORHlaseniMsg(Sender:string; data:TStrings);
var i:Integer;
    orindex:Integer;
begin
 orindex := -1;
 for i := 0 to Self.ORs.Count-1 do
  if (Self.ORs[i].id = Sender) then
   begin
    orindex := i;
    break;
   end;

 if (orindex = -1) then Exit();
 if (data.Count < 3) then Exit();

 data[2] := UpperCase(data[2]);
 if ((data[2] = 'AVAILABLE') and (data.Count > 3)) then
  begin
   Self.ORs[i].hlaseni := (data[3] = '1');

   if (Self.special_menu = dk) then
     Self.ShowDKMenu(orindex);
   if ((Self.special_menu = hlaseni) and (not Self.ORs[i].hlaseni)) then
     Self.HideMenu();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit

