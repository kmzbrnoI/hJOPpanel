unit Panel;

{
  Hlavni logika celeho panelu.
}

interface

uses DXDraws, Controls, Windows, SysUtils, Graphics, Classes, Forms, StdCtrls,
     ExtCtrls, AppEvnts, inifiles, Messages, RPConst, fPotvrSekv, MenuPanel,
     StrUtils, PGraphics, HVDb, Generics.Collections, Zasobnik, UPO, IBUtils,
     Hash, PngImage, DirectX, PanelOR, BlokTypes,
     BlokUvazka, BlokUvazkaSpr, BlokZamek, BlokPrejezd, BlokyUsek, BlokyVyhybka,
     BlokNavestidlo, BlokVyhybka, BlokUsek, BlokVykolejka, BlokRozp, BlokPopisek,
     BlokPomocny;

const
  _INFOTIMER_WIDTH      = 30;
  _INFOTIMER_TEXT_WIDTH = 22;

  _FileVersion_accept : array[0..1] of string = (
     '1.1', '1.2'
  );

type
 ///////////////////////////////////////////////////////////////////////////////

 TSpecialMenu = (none, dk, osv, loko, reg_please, hlaseni);

 ///////////////////////////////////////////////////////////////////////////////
 // eventy:

 TMoveEvent = procedure(Sender:TObject;Position:TPoint) of object;
 TLoginChangeEvent = procedure(Sender:TObject; str:string) of object;

 ///////////////////////////////////////////////////////////////////////////////

 // prehlasovani pomoci Ctrl+R (reader vs. normalni uzivatel)
 TReAuth = record
  old_login:string;                                                             // guest -> username
  old_ors:TList<Integer>;                                                       // (guest -> username) seznam indexu oblati rizeni k autorizaci
 end;

 ///////////////////////////////////////////////////////////////////////////////

 // data kurzoru
 TCursorDraw=record
   KurzorRamecek,KurzorObsah:TColor;
   Pos:TPoint;
   Pozadi:TBitmap;
 end;

 ///////////////////////////////////////////////////////////////////////////////

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
 TRelief = class
  private const
    _Def_Color_Pozadi = clBlack;
    _Def_Color_Kurzor_Ramecek = clYellow;
    _Def_Color_Kurzor_Obsah   = clMaroon;

    _msg_width = 30;

    _DblClick_Timeout_Ms = 250;

  private
   DrawObject:TDXDraw;
   ParentForm:TForm;
   AE:TApplicationEvents;
   T_SystemOK:TTimer; //timer na SystemOK na 500ms - nevykresluje
   Graphics:TPanelGraphics;


   mouseClick:TDateTime;
   mouseTimer:TTimer;
   mouseLastBtn:TMouseButton;
   mouseClickPos:TPoint;

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

   Tech_blok:TDictionary<Integer, TList<TTechBlokToSymbol>>;   // mapuje id technologickeho bloku na

   Useky : TPUseky;
   Vyhybky : TPVyhybky;
   Navestidla : TPNavestidla;
   Uvazky : TPUvazky;
   UvazkySpr : TPUvazkySpr;
   Zamky : TPZamky;
   Prejezdy : TPPrejezdy;
   Vykol : TPVykolejky;
   Rozp : TPRozpojovace;
   Texty : TPTexty;
   PopiskyBloku : TPTexty;
   PomocneObj : TPPomocneObj;

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
  fShowDetails : boolean;

   procedure PaintKurzor();
   procedure PaintKurzorBg(Pos:TPoint);

   procedure DXDMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure DXDMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure DXDMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);

   procedure T_SystemOKOnTimer(Sender:TObject);

   procedure ObjectMouseClick(Position:TPoint; Button:TPanelButton);
   procedure ObjectMouseUp(Position:TPoint; Button:TPanelButton);
   procedure ObjectMouseDown(Position:TPoint; Button:TPanelButton);

   procedure FLoad(aFile:string);

   procedure ShowDK;
   procedure ShowOpravneni;
   procedure ShowMereniCasu;
   procedure ShowMsg;
   procedure ShowZasobniky;
   procedure ShowInfoTimers;

   function GetDK(Pos:TPoint):Integer;

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
   procedure SetShowDetails(show:boolean);

  public

   UPO:TPanelUPO;       // upozorneni v leve dolni oblasti

   constructor Create(aParentForm:TForm);
   destructor Destroy; override;

   procedure Initialize(var DrawObject:TDXDraw; aFile:string; hints_file:string);
   procedure Show();

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
   property ShowDetails:boolean read fShowDetails write SetShowDetails;

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
   procedure ORBlkChange(Sender:string; BlokID:integer; BlokTyp:Integer; parsed:TStrings);

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

   class function FileSupportedVersionsStr():string;

 end;

implementation

uses fStitVyl, TCPClientPanel, Symbols, fMain, BottomErrors, GlobalConfig, fZpravy,
     fSprEdit, fSettings, fHVMoveSt, fAuth, fHVEdit, fHVDelete, ModelovyCas,
     fNastaveni_casu, LokoRuc, Sounds, fRegReq, fHVSearch, uLIclient, InterProcessCom,
     parseHelper, PanelPainter;

constructor TRelief.Create(aParentForm:TForm);
begin
 inherited Create;

 Self.Useky := TPUseky.Create();
 Self.Vyhybky := TPVyhybky.Create();
 Self.Navestidla := TPNavestidla.Create();
 Self.Vykol := TPVykolejky.Create();
 Self.Rozp  := TPRozpojovace.Create();
 Self.Prejezdy := TPPrejezdy.Create();
 Self.Texty := TPTexty.Create();
 Self.PopiskyBloku := TPTexty.Create();
 Self.Uvazky := TPUvazky.Create();
 Self.UvazkySpr := TPUvazkySpr.Create();
 Self.Zamky := TPZamky.Create();
 Self.PomocneObj := TPPomocneObj.Create();

 Self.ParentForm := aParentForm;
 Self.myORs := TList<TORPanel>.Create();
 Self.reAuth.old_ors := TList<Integer>.Create();

 Self.mouseTimer := TTimer.Create(nil);
 Self.mouseTimer.Interval := _DblClick_Timeout_Ms + 20;
 Self.mouseTimer.OnTimer := Self.OnMouseTimer;
 Self.mouseTimer.Enabled := false;
end;//contructor

procedure TRelief.Initialize(var DrawObject:TDXDraw; aFile:string; hints_file:string);
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
 Self.DrawObject.OnMouseDown := Self.DXDMouseDown;
 Self.DrawObject.OnMouseMove := Self.DXDMouseMove;

 Self.CursorDraw.Pos.X := -2;
 Self.CursorDraw.Pozadi        := TBitmap.Create();
 Self.CursorDraw.Pozadi.Width  := SymbolSet._Symbol_Sirka+2;    // +2 kvuli okrajum kurzoru
 Self.CursorDraw.Pozadi.Height := SymbolSet._Symbol_Vyska+2;

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

 Self.FLoad(aFile);

 (Self.ParentForm as TF_Main).SetPanelSize(Self.Graphics.PanelWidth*SymbolSet._Symbol_Sirka, Self.Graphics.PanelHeight*SymbolSet._Symbol_Vyska);

 Self.Show();
end;

destructor TRelief.Destroy();
var i:Integer;
begin
 Self.mouseTimer.Free();

 for i := Self.myORs.Count-1 downto 0 do
   Self.myORs[i].Free();
 Self.myORs.Free();

 Self.Vyhybky.Free();
 Self.Useky.Free();
 Self.Navestidla.Free();
 Self.Vykol.Free();
 Self.Rozp.Free();
 Self.Prejezdy.Free();
 Self.Uvazky.Free();
 Self.UvazkySpr.Free();
 Self.Zamky.Free();
 Self.Texty.Free();
 Self.PopiskyBloku.Free();
 Self.PomocneObj.Free();

 if (Assigned(Self.infoTimers)) then FreeAndNil(Self.infoTimers);
 if (Assigned(Self.UPO)) then FreeAndNil(Self.UPO);
 if (Assigned(Self.T_SystemOK)) then FreeAndNil(Self.T_SystemOK);
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

   PanelPainter.Draw(SymbolSet.IL_DK, OblR.Poss.DK, OblR.Poss.DKOr, fg, clBlack, Self.DrawObject);

   // symbol osvetleni se vykresluje vlevo
   if (OblR.dk_osv) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, Point(OblR.Poss.DK.X-2, OblR.Poss.DK.Y+1),
        _Hvezdicka, clYellow, clBlack, Self.DrawObject);

   // symbol zadosti o loko se vykresluje vpravo
   if (((OblR.RegPlease.status = TORRegPleaseStatus.request) or (OblR.RegPlease.status = TORRegPleaseStatus.selected)) and (not Self.Graphics.blik)) then
     PanelPainter.Draw(SymbolSet.IL_Symbols, Point(OblR.Poss.DK.X+6, OblR.Poss.DK.Y+1),
        _Kolecko, clYellow, clBlack, Self.DrawObject);

  end;//for i
end;

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

   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y), _Plny_Symbol+1, clBlack, c1, Self.DrawObject);
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y), _Plny_Symbol+1, clBlack, c1, Self.DrawObject);
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y), _Plny_Symbol+1, clBlack, c1, Self.DrawObject);

   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y+1), _Plny_Symbol+1, c2, c3, Self.DrawObject);
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y+1), _Plny_Symbol+1, c2, c3, Self.DrawObject);
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y+1), _Plny_Symbol+1, c2, c3, Self.DrawObject);
  end else begin
   // svisle

   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y), _Plny_Symbol+1, clBlack, c1, Self.DrawObject);
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X, Pos.Y+1), _Plny_Symbol, c1, c1, Self.DrawObject);

   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y), _Plny_Symbol+2, c2, clBlack, Self.DrawObject);
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+1, Pos.Y+1), _Plny_Symbol, c2, clBlack, Self.DrawObject);

   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y), _Plny_Symbol+1, clBlack, c3, Self.DrawObject);
   PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Pos.X+2, Pos.Y+1), _Plny_Symbol, c3, c3, Self.DrawObject);
  end;

 case (PanelTCPClient.status) of
  TPanelConnectionStatus.closed    :
    PanelPainter.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Odpojeno od serveru', clFuchsia, clBlack, Self.DrawObject);
  TPanelConnectionStatus.opening   :
    PanelPainter.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Otevírám spojení...', clFuchsia, clBlack, Self.DrawObject);
  TPanelConnectionStatus.handshake :
    PanelPainter.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Probíhá handshake...', clFuchsia, clBlack, Self.DrawObject);
  TPanelConnectionStatus.opened    :
    PanelPainter.TextOutput(Point(Pos.X+5, Pos.Y+1), 'Pøipojeno k serveru', $A0A0A0, clBlack, Self.DrawObject);
 end;
end;

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
     PanelPainter.TextOutput(Point(Self.myORs[j].Poss.Time.X, Self.myORs[j].Poss.Time.Y+k),
       'MER.CASU', clRed, clWhite, Self.DrawObject);

     DateTimeToString(Time1, 'ss', Now-Self.myORs[j].MereniCasu[k].Start);
     DateTimeToString(Time2, 'ss', Self.myORs[j].MereniCasu[k].Length);

     for i := 0 to (Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2)-1 do
      PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Self.myORs[j].Poss.Time.X+8+i, Self.myORs[j].Poss.Time.Y+k),
        _Plny_Symbol, clRed, clBlack, Self.DrawObject);

     for i := (Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2) to (_delka div 2)-1 do
      PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Self.myORs[j].Poss.Time.X+8+i, Self.myORs[j].Poss.Time.Y+k),
        _Plny_Symbol, clWhite, clBlack, Self.DrawObject);

     //vykresleni poloviny symbolu
     SymbolSet.IL_Symbols.BkColor := clWhite;
     if ((Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) mod 2) = 1) then
       PanelPainter.Draw(SymbolSet.IL_Symbols, Point(Self.myORs[j].Poss.Time.X+8+(Round((StrToIntDef(Time1,0)/StrToIntDef(Time2,0))*_delka) div 2),
                 Self.myORs[j].Poss.Time.Y+k), _Plny_Symbol+1, clRed, clWhite, Self.DrawObject);

    end;//for i

   // detekce konce mereni casu
   for k := Self.myORs[j].MereniCasu.Count-1 downto 0 do
    begin
     if (Now >= Self.myORs[j].MereniCasu[k].Length + Self.myORs[j].MereniCasu[k].Start) then
      Self.myORs[j].MereniCasu.Delete(k);
    end;
  end;//for j
end;

procedure TRelief.ShowMsg();
begin
 if (Self.msg.show) then
   PanelPainter.TextOutput(Point(0, Self.Graphics.PanelHeight-1), Self.msg.msg,
     clRed, clWhite, Self.DrawObject);
end;

////////////////////////////////////////////////////////////////////////////////

//hlavni zobrazeni celeho reliefu
procedure TRelief.Show();
begin
 try
   if (not Assigned(Self.DrawObject)) then Exit;
   if (not Self.DrawObject.CanDraw) then Exit;
   Self.DrawObject.Surface.Canvas.Lock();

   Self.DrawObject.Surface.Fill(Self.Colors.Pozadi);

   if (Self.ShowDetails) then
     Self.PopiskyBloku.Show(Self.DrawObject);
   Self.Texty.Show(Self.DrawObject);
   Self.UvazkySpr.Show(Self.DrawObject);
   Self.Uvazky.Show(Self.DrawObject, Self.Graphics.blik);
   Self.Navestidla.Show(Self.DrawObject, Self.Graphics.blik);
   Self.Prejezdy.Show(Self.DrawObject, Self.Graphics.blik, Self.Useky.data);
   Self.PomocneObj.Show(Self.DrawObject);
   Self.Useky.Show(Self.DrawObject, Self.Graphics.blik, Self.myORs, Navestidla.startJC, Self.Vyhybky.data);
   Self.Vyhybky.Show(Self.DrawObject, Self.Graphics.blik, Self.Useky.data);
   Self.Zamky.Show(Self.DrawObject, Self.Graphics.blik);
   Self.Rozp.Show(Self.DrawObject);
   Self.Vykol.Show(Self.DrawObject, Self.Graphics.blik, Self.Useky.data);

   Self.ShowDK();
   Self.ShowOpravneni();
   Self.ShowZasobniky();
   Self.ShowMereniCasu();
   RucList.Show(Self.DrawObject);
   Self.ShowMsg();
   Self.ShowInfoTimers();
   Errors.Show(Self.DrawObject);

   if (Self.UPO.showing) then Self.UPO.Show(Self.DrawObject);

   if (Self.Menu.showing) then
    begin
     Self.Menu.PaintMenu(Self.DrawObject, Self.CursorDraw.Pos)
    end else begin
     if (GlobConfig.data.panel_mouse = _MOUSE_PANEL) then Self.PaintKurzor();
    end;

   Self.DrawObject.Surface.Canvas.Release();
   Self.DrawObject.Flip();
 except

 end;

 try
   if (Self.DrawObject.Surface.Canvas.LockCount > 0) then
     Self.DrawObject.Surface.Canvas.UnLock();
 except

 end;
end;

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
end;

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
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.DXDMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 Self.CursorDraw.Pos.X := X div SymbolSet._Symbol_Sirka;
 Self.CursorDraw.Pos.Y := Y div SymbolSet._Symbol_Vyska;

 case (Button) of
  mbLeft   : begin
    Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.ENTER);
    Self.ObjectMouseClick(Self.CursorDraw.Pos, TPanelButton.ENTER);
  end;
  mbRight  : begin
    Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.ESCAPE);
    Self.ObjectMouseClick(Self.CursorDraw.Pos, TPanelButton.ESCAPE);
  end;
  mbMiddle : begin
    Self.ObjectMouseUp(Self.CursorDraw.Pos, TPanelButton.F1);

    if ((Self.mouseLastBtn = mbMiddle) and (Now - Self.mouseClick < EncodeTime(0, 0, 0, _DblClick_Timeout_Ms))) then
     begin
      Self.mouseTimer.Enabled := false;
      Self.ObjectMouseClick(Self.mouseClickPos, TPanelButton.F2);
     end else begin
      Self.mouseTimer.Enabled := true;
      Self.mouseClickPos := Self.CursorDraw.Pos;
     end;
  end;
 end;

 Self.mouseClick := Now;
 Self.mouseLastBtn := Button;

 Self.Show();
end;

// Tato funkce neni skoro vubec vyuzivana, je pouze na specialni veci.
// Vsechny kliky mysi se resi pomoci MouseUp
procedure TRelief.DXDMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var myBut:TPanelButton;
begin
 case (Button) of
  mbLeft   : myBut := TPanelButton.ENTER;
  mbRight  : myBut := TPanelButton.ESCAPE;
  mbMiddle : myBut := TPanelButton.F1;
 else
  Exit();
 end;

 Self.ObjectMouseDown(Point(X div SymbolSet._Symbol_Sirka, Y div SymbolSet._Symbol_Vyska), myBut);
end;

procedure TRelief.OnMouseTimer(Sender:TObject);
begin
 if ((Self.mouseLastBtn = mbMiddle) and (Now - Self.mouseClick > EncodeTime(0, 0, 0, _DblClick_Timeout_Ms))) then
  begin
   Self.ObjectMouseClick(Self.mouseClickPos, TPanelButton.F1);
   Self.mouseTimer.Enabled := false;
   Self.Show();
  end;
end;

procedure TRelief.DXDMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
var old:TPoint;
    i:Integer;
    stackDragged:boolean;
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

 // potencialni prekresleni zasobniku pri presunu povelu
 stackDragged := false;
 for i := 0 to Self.myORs.Count-1 do
   if (Self.myORs[i].stack.IsDragged()) then
     stackDragged := true;

 // panel prekreslujeme jen kdyz je nutne vykreslovat mys na panelu
 // pokud se vykresluje mys operacniho systemu, panel neni prekreslovan
 if ((GlobConfig.data.panel_mouse = _MOUSE_PANEL) or (Self.Menu.showing) or
     (stackDragged)) then
  begin
   // neprekreslujeme cely panel, ale pouze policko, na kterem byla mys v minule pozici
   //  obsah tohoto policka je ulozen v Self.CursorDraw.History
   try
     Self.DrawObject.Surface.Canvas.Lock();
     if (not Assigned(Self.DrawObject)) then Exit;
     if (not Self.DrawObject.CanDraw) then Exit;

     if (Self.Menu.showing) then
       Self.Menu.PaintMenu(Self.DrawObject, Self.CursorDraw.Pos)
     else begin
       Self.PaintKurzorBg(old);

       for i := 0 to Self.myORs.Count-1 do
         if (Self.myORs[i].stack.IsDragged()) then
           Self.myORs[i].stack.Show(Self.DrawObject, Self.CursorDraw.Pos);

       Self.PaintKurzor();
     end;

     // prekreslime si platno
     Self.DrawObject.Surface.Canvas.Release();
     Self.DrawObject.Flip();
   except

   end;

   try
     if (Self.DrawObject.Surface.Canvas.LockCount > 0) then
       Self.DrawObject.Surface.Canvas.UnLock();
   except

   end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

//vyvolano pri kliku na relief
procedure TRelief.ObjectMouseClick(Position:TPoint; Button:TPanelButton);
var i, index:Integer;
    handled:boolean;
    uid:TPUsekID;
    uvid:TPUvazkaID;
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
   if ((Self.myORs[i].RegPlease.status > TORRegPleaseStatus.none) and (Position.X = Self.myORs[i].Poss.DK.X+6) and (Position.Y = Self.myORs[i].Poss.DK.Y+1)) then
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
 index := Self.Prejezdy.GetIndex(Position);
 if (index <> -1) then
  begin
   if (Self.Prejezdy.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Prejezdy.Data[index].OblRizeni].id, Button, Self.Prejezdy.Data[index].Blok);
   goto EscCheck;
  end;

 //souctova hlaska
 index := Self.Texty.GetIndex(Position);
 if (index <> -1) then
  begin
   if (Self.Texty.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Texty.Data[index].OblRizeni].id, Button, Self.Texty.Data[index].Blok);
   goto EscCheck;
  end;

 //rozpojovac
 index := Self.Rozp.GetIndex(Position);
 if (index <> -1) then
  begin
   if (Self.Rozp[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Rozp[index].OblRizeni].id, Button, Self.Rozp[index].Blok);
   goto EscCheck;
  end;

 //vykolejka
 index := Self.Vykol.GetIndex(Position);
 if (index <> -1) then
  begin
   if (Self.Vykol[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Vykol[index].OblRizeni].id, Button, Self.Vykol[index].Blok);
   goto EscCheck;
  end;

 //usek
 uid := Self.Useky.GetIndex(Position);
 if (uid.index <> -1) then
  begin
   if (Self.Useky.data[uid.index].Blok < 0) then goto EscCheck;

   // kliknutim na usek pri zadani o lokomotivu vybereme hnaci vozidla na souprave v tomto useku
   if ((Self.myORs[Self.Useky[uid.index].OblRizeni].RegPlease.status = TORRegPleaseStatus.selected) and
       (Button = ENTER)) then
     //  zadost o vydani seznamu hnacich vozidel na danem useku
     PanelTCPClient.SendLn(Self.myORs[Self.Useky[uid.index].OblRizeni].id +
       ';LOK-REQ;U-PLEASE;' + IntToStr(Self.Useky[uid.index].Blok) + ';' + IntToStr(uid.soupravaI))
   else
     PanelTCPClient.PanelClick(Self.myORs[Self.Useky[uid.index].OblRizeni].id,
       Button, Self.Useky[uid.index].Blok, IntToStr(uid.soupravaI));

   goto EscCheck;
  end;

 //navestidlo
 index := Self.Navestidla.GetIndex(Position);
 if (index <> -1) then
  begin
   if (Self.Navestidla[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Navestidla[index].OblRizeni].id, Button, Self.Navestidla[index].Blok);
   goto EscCheck;
  end;

 //vyhybka
 index := Self.Vyhybky.GetIndex(Position);
 if (index <> -1) then
  begin
   if (Vyhybky.data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Vyhybky.data[index].OblRizeni].id, Button, Vyhybky.data[index].Blok);
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
 index := Self.Uvazky.GetIndex(Position);
 if (index <> -1) then
  begin
   if (Self.Uvazky.Data[index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.Uvazky.Data[index].OblRizeni].id, Button, Self.Uvazky.Data[index].Blok);
   goto EscCheck;
  end;

 //uvazka soupravy
 uvid := Self.UvazkySpr.GetIndex(Position);
 if (uvid.index <> -1) then
  begin
   if (Self.UvazkySpr.Data[uvid.index].Blok < 0) then goto EscCheck;
   PanelTCPClient.PanelClick(Self.myORs[Self.UvazkySpr.Data[uvid.index].OblRizeni].id, Button,
                             Self.UvazkySpr.Data[uvid.index].Blok, IntToStr(uvid.soupravaI));
   goto EscCheck;
  end;

 //zamek
 index := Self.Zamky.GetIndex(Position);
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
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ObjectMouseUp(Position:TPoint; Button:TPanelButton);
var handled:boolean;
    i:Integer;
begin
 handled := false;

 // zasobniky
 handled := false;
 for i := 0 to Self.myORs.Count-1 do
  begin
   if (Self.myORs[i].tech_rights = TORControlRights.null) then continue;
   Self.myORs[i].stack.MouseUp(Position, Button, handled);
   if (handled) then Exit();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ObjectMouseDown(Position:TPoint; Button:TPanelButton);
var handled:boolean;
    i:Integer;
begin
 handled := false;

 // zasobniky
 handled := false;
 for i := 0 to Self.myORs.Count-1 do
  begin
   if (Self.myORs[i].tech_rights = TORControlRights.null) then continue;
   Self.myORs[i].stack.MouseDown(Position, Button, handled);
   if (handled) then Exit();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.FLoad(aFile:string);
var i:Integer;
    inifile:TMemIniFile;
    sect_str:TStrings;
    ver:string;
    versionOk:boolean;
begin
 if (not FileExists(aFile)) then
   raise Exception.Create('Soubor panelu ' + aFile + ' neexistuje!');

 inifile := TMemIniFile.Create(aFile, TEncoding.UTF8);

 try
   Self.Graphics.PanelWidth := inifile.ReadInteger('P', 'W', 100);
   Self.Graphics.PanelHeight := inifile.ReadInteger('P', 'H', 20);

   //kontrola verze
   ver := inifile.ReadString('G', 'ver', 'invalid');
   versionOk := false;
   for i := 0 to Length(_FileVersion_accept)-1 do
    begin
     if (ver = _FileVersion_accept[i]) then
      begin
       versionOk := true;
       Break;
      end;
    end;

   if (not versionOk) then
    begin
     if (Application.MessageBox(PChar('Naèítáte soubor s verzí '+ver+#13#10+
         'Aplikace momentálnì podporuje verze '+Self.FileSupportedVersionsStr()+#13#10+'Chcete pokraèovat?'),
         'Varování', MB_YESNO OR MB_ICONQUESTION) = mrNo) then
       Exit();
    end;

   // Oblasti rizeni
   sect_str := TStringList.Create();
   try
     inifile.ReadSection('OR', sect_str);
     Self.myORs.Clear();
     for i := 0 to sect_str.Count-1 do
       Self.myORs.Add(TORPanel.Create(inifile.ReadString('OR', sect_str[i], ''), Self.Graphics));
   finally
     sect_str.Free();
   end;

   // vytvorime okynka zprav
   TF_Messages.frm_cnt := Self.myORs.Count;
   for i := 0 to Self.myORs.Count-1 do
     TF_Messages.frm_db[i] := TF_Messages.Create(Self.myORs[i].Name, Self.myORs[i].id);

   Self.Useky.Load(inifile, Self.myORs);
   Self.Navestidla.Load(inifile);
   Self.Vyhybky.Load(inifile);
   Self.Vykol.Load(inifile);
   Self.Prejezdy.Load(inifile, Self.Useky);
   Self.Uvazky.Load(inifile);
   Self.UvazkySpr.Load(inifile);
   Self.Zamky.Load(inifile);
   Self.Rozp.Load(inifile);
   Self.Texty.Load(inifile, 'T');
   Self.PopiskyBloku.Load(inifile, 'TP');
   Self.PomocneObj.Load(inifile);

   Self.Tech_blok.Clear();

   for i := 0 to Self.Useky.data.Count-1 do
     Self.AddToTechBlk(_BLK_USEK, Self.Useky.data[i].Blok, i);

   for i := 0 to Self.Vyhybky.data.Count-1 do
     Self.AddToTechBlk(_BLK_VYH, Self.Vyhybky.data[i].Blok, i);

   for i := 0 to Self.Uvazky.data.Count-1 do
     Self.AddToTechBlk(_BLK_UVAZKA, Self.Uvazky.data[i].Blok, i);

   for i := 0 to Self.UvazkySpr.data.Count-1 do
     Self.AddToTechBlk(_BLK_UVAZKA_SPR, Self.UvazkySpr.data[i].Blok, i);

   for i := 0 to Self.Zamky.data.Count-1 do
     Self.AddToTechBlk(_BLK_ZAMEK, Self.Zamky.data[i].Blok, i);

   for i := 0 to Self.Prejezdy.data.Count-1 do
     Self.AddToTechBlk(_BLK_PREJEZD, Self.Prejezdy.data[i].Blok, i);

   for i := 0 to Self.Navestidla.data.Count-1 do
     Self.AddToTechBlk(_BLK_SCOM, Self.Navestidla.data[i].Blok, i);

   for i := 0 to Self.Vykol.data.Count-1 do
     Self.AddToTechBlk(_BLK_VYKOL, Self.Vykol.data[i].Blok, i);

   for i := 0 to Self.Rozp.data.Count-1 do
     Self.AddToTechBlk(_BLK_ROZP, Self.Rozp.data[i].Blok, i);

   for i := 0 to Self.Texty.Count-1 do
     if (Self.Texty[i].Blok > -1) then
       Self.AddToTechBlk(_BLK_SH, Self.Texty[i].Blok, i);

 finally
   inifile.Free;
 end;
end;

function TRelief.GetDK(Pos:TPoint):Integer;
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   if ((Pos.X >= Self.myORs[i].Poss.DK.X) and (Pos.Y >= Self.myORs[i].Poss.DK.Y) and (Pos.X <= Self.myORs[i].Poss.DK.X+(((_DK_Sirka*SymbolSet._Symbol_Sirka)-1) div SymbolSet._Symbol_Sirka)) and (Pos.Y <= Self.myORs[i].Poss.DK.Y+(((_DK_Vyska*SymbolSet._Symbol_Vyska)-1) div SymbolSet._Symbol_Vyska))) then
     Exit(i);

 Result := -1;
end;

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
       VK_BACK, VK_RETURN: Errors.RemoveVisibleErrors();
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
     VK_F1 : Self.ObjectMouseClick(Self.CursorDraw.Pos, F1);
     VK_F2 : Self.ObjectMouseClick(Self.CursorDraw.Pos, F2);
     VK_ESCAPE: Self.ObjectMouseClick(Self.CursorDraw.Pos, TPanelButton.ESCAPE);
     VK_RETURN: Self.ObjectMouseClick(Self.CursorDraw.Pos, ENTER);
     VK_BACK: Errors.RemoveVisibleErrors();

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
end;

procedure TRelief.T_SystemOKOnTimer(Sender:TObject);
begin
 Self.SystemOK.Poloha := not Self.SystemOK.Poloha;
 Self.Graphics.blik   := not Self.Graphics.blik;
end;

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
end;

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
end;

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
end;

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
end;

procedure TRelief.HideCursor();
begin
 if (self.CursorDraw.Pos.X >= 0) then
  begin
   Self.CursorDraw.Pos.X := -2;
   Self.Show();
  end;
end;

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
end;

procedure TRelief.ORInfoMsg(msg:string);
begin
 Self.msg.msg := msg + StringOfChar(' ', Max(Self._msg_width - Length(msg), 0));
 Self.msg.show := true;
end;

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
end;

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
end;

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

procedure TRelief.ORBlkChange(Sender:string; BlokID:integer; BlokTyp:Integer;
                              parsed:TStrings);
var i:Integer;
    symbols:TList<TTechBlokToSymbol>;
begin
 // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
 if (not Self.Tech_blok.ContainsKey(BlokID)) then Exit();
 symbols := Self.Tech_blok[BlokID];

 for i := 0 to symbols.Count-1 do
  begin
   case (BlokTyp) of
     _BLK_USEK: begin
       if ((symbols[i].blk_type = _BLK_USEK) and
           (Sender = Self.myORs[Self.Useky[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Useky[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

     _BLK_VYH: begin
       if ((symbols[i].blk_type = _BLK_VYH) and
           (Sender = Self.myORs[Vyhybky.data[symbols[i].symbol_index].OblRizeni].id)) then
        Self.Vyhybky[symbols[i].symbol_index].PanelProp.Change(parsed);

      if ((symbols[i].blk_type = _BLK_VYKOL) and
          (Sender = Self.myORs[Self.Vykol[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Vykol[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

     _BLK_SCOM: begin
       if ((symbols[i].blk_type = _BLK_SCOM) and
           (Sender = Self.myORs[Self.Navestidla[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Navestidla[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

     _BLK_PREJEZD: begin
       if ((symbols[i].blk_type = _BLK_PREJEZD) and
           (Sender = Self.myORs[Self.Prejezdy[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Prejezdy[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

     _BLK_ZAMEK: begin
       if ((symbols[i].blk_type = _BLK_ZAMEK) and
           (Sender = Self.myORs[Self.Zamky[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Zamky[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

     _BLK_ROZP: begin
       if ((symbols[i].blk_type = _BLK_ROZP) and
           (Sender = Self.myORs[Self.Rozp[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Rozp[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

     _BLK_UVAZKA: begin
       if ((symbols[i].blk_type = _BLK_UVAZKA) and
           (Sender = Self.myORs[Self.Uvazky.Data[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Uvazky[symbols[i].symbol_index].PanelProp.Change(parsed);

       if ((symbols[i].blk_type = _BLK_UVAZKA_SPR) and
           (Sender = Self.myORs[Self.UvazkySpr.Data[symbols[i].symbol_index].OblRizeni].id)) then
         Self.UvazkySpr[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

     _BLK_SH: begin
       if ((symbols[i].blk_type = _BLK_SH) and
           (Sender = Self.myORs[Self.Texty[symbols[i].symbol_index].OblRizeni].id)) then
         Self.Texty[symbols[i].symbol_index].PanelProp.Change(parsed);
     end;

   end;//case
  end;//for

 if (BlokTyp = _BLK_SCOM) then
   Self.Navestidla.UpdateStartJC();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORHVList(Sender:string; data:string);
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   if (Sender = Self.myORs[i].id) then
    begin
     Self.myORs[i].HVs.ParseHVs(data);
     Self.myORs[i].HVs.HVs.Sort();
     Exit();
    end;
end;

procedure TRelief.ORSprNew(Sender:string);
var i:Integer;
    HV:THV;
    available:boolean;
begin
 for i := 0 to Self.myORs.Count-1 do
   if (Sender = Self.myORs[i].id) then
    begin
     available := false;
     for HV in Self.myORs[i].HVs.HVs do
       if (HV.Souprava = '-') then
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
end;

procedure TRelief.ORSprEdit(Sender:string; parsed:TStrings);
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   if (Sender = Self.myORs[i].id) then
    begin
     F_SoupravaEdit.EditSpr(parsed, Self.myORs[i].HVs, Self.myORs[i].id, Self.myORs[i].Name);
     Exit();
    end;
end;

////////////////////////////////////////////////////////////////////////////////

//technologie posle nejake menu a my ho zobrazime:
procedure TRelief.ORShowMenu(items:string);
begin
 Self.menu_lastpos := Self.CursorDraw.Pos;
 Self.special_menu := TSpecialMenu.none;
 Self.Menu.ShowMenu(items, -1, Self.DrawObject.ClientToScreen(Point(0,0)));
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.HideMenu();
var bPos:TPoint;
begin
 Self.Menu.showing := false;
 Self.special_menu := TSpecialMenu.none;
 bPos := Self.DrawObject.ClientToScreen(Point(0,0));
 SetCursorPos(Self.menu_lastpos.X*SymbolSet._Symbol_Sirka + bPos.X, Self.menu_lastpos.Y*SymbolSet._Symbol_Vyska + bPos.Y);
 Self.Show();
end;

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

   if (ModCas.used) then
    begin
     if (ModCas.started) then
      begin
       if (Self.myORs[obl_rizeni].Rights.ModCasStop) then
        menu_str := menu_str + 'CAS<,';
      end else begin
       if (Self.myORs[obl_rizeni].Rights.ModCasStart) then
        menu_str := menu_str + 'CAS>,';
      end;
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
end;

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
end;

procedure TRelief.DKMenuClickNUZ(Sender:Integer; item:string);
begin
 if (item = 'NUZ>') then
   PanelTCPClient.PanelNUZ(Self.myORs[Sender].id)
 else
   PanelTCPClient.PanelNUZCancel(Self.myORs[Sender].id);
end;

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
end;

procedure TRelief.DKMenuClickLOKO(Sender:Integer; item:string);
var menu_str:string;
begin
 // nejdøív aktualizuji seznam LOKO
 PanelTCPClient.PanelLokList(Self.myORs[Sender].id);

 menu_str := '$'+Self.myORs[Sender].Name+',$LOKO,-,NOVÁ loko,EDIT loko,SMAZAT loko,PØEDAT loko,HLEDAT loko,RUÈ loko';
 if (BridgeClient.authStatus = TuLIAuthStatus.yes) then menu_str := menu_str + ',MAUS loko';

 Self.special_menu := loko;
 Self.Menu.ShowMenu(menu_str, Sender, Self.DrawObject.ClientToScreen(Point(0,0)));
end;

procedure TRelief.DKMenuClickSUPERUSER(Sender:Integer; item:string);
var ors: TIntAr;
begin
 SetLength(ors, 1);
 ors[0] := Sender;
 F_Auth.OpenForm('Vyžadována autorizace', Self.DKMenuClickSUPERUSER_AuthCallback, ors, false);
end;

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
end;

procedure TRelief.DKMenuClickSetCAS(Sender:Integer; item:string);
begin
 F_ModCasSet.OpenForm();
end;

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
end;

procedure TRelief.DKMenuClickMSG(Sender:Integer; item:string);
begin
 TF_Messages.frm_db[Sender].Show();
 TF_Messages.frm_db[Sender].SetFocus();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowRegMenu(obl_rizeni:Integer);
var menu_str:string;
begin
 if ((PanelTCPClient.status <> TPanelConnectionStatus.opened) or
     (Self.myORs[obl_rizeni].RegPlease.status = TORRegPleaseStatus.none)) then Exit();

 menu_str := '$' + Self.myORs[obl_rizeni].Name + ',$Žádost o loko,-,INFO,ODMÍTNI';

 Self.myORs[obl_rizeni].RegPlease.status := TORRegPleaseStatus.request;

 Self.special_menu := reg_please;
 Self.menu_lastpos := Self.CursorDraw.Pos;

 Self.Menu.ShowMenu(menu_str, obl_rizeni, Self.DrawObject.ClientToScreen(Point(0,0)));

 PanelTCPClient.PanelLokList(Self.myORs[obl_rizeni].id);
end;

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
end;

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
end;

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
      (Self.myORs[obl_r].RegPlease.status <> TORRegPleaseStatus.none),
      false, false, (item = 'MAUS loko'));
end;

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
end;

procedure TRelief.ParseHlaseniMenuClick(item:string; obl_r:Integer);
begin
 PanelTCPClient.SendLn(Self.ORs[obl_r].id + ';SHP;SPEC;' + item);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.OrDisconnect(orindex:Integer = -1);
var i:Integer;
begin
 if (orindex = -1) then
  begin
   Self.Menu.showing := false;
   Self.UPO.showing  := false;
   Self.infoTimers.Clear();
   Self.Graphics.DrawObject.Enabled := true;
  end;

 Self.Useky.Reset(orindex);
 Self.Vyhybky.Reset(orindex);
 Self.Navestidla.Reset(orindex);
 Self.Prejezdy.Reset(orindex);
 Self.Uvazky.Reset(orindex);
 Self.UvazkySpr.Reset(orindex);
 Self.Zamky.Reset(orindex);
 Self.Vykol.Reset(orindex);
 Self.Rozp.Reset(orindex);
 Self.Texty.Reset(orindex);
 Self.PopiskyBloku.Reset(orindex);

 for i := 0 to Self.myORs.Count-1 do
  begin
   if ((orindex < 0) or (i = orindex)) then
    begin
     Self.myORs[i].tech_rights      := TORControlRights.null;
     Self.myORs[i].dk_blik          := false;
     Self.myORs[i].dk_osv           := false;
     Self.myORs[i].stack.enabled    := false;
     Self.myORs[i].dk_click_server  := false;
     Self.myORs[i].RegPlease.status := TORRegPleaseStatus.none;
     Self.myORs[i].hlaseni          := false;
     Self.myORs[i].login            := '';
     Self.myORs[i].username         := '';
    end;
  end;

 Self.Show();
 Self.UpdateLoginString();
end;

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
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowZasobniky();
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
   Self.myORs[i].stack.Show(Self.DrawObject, Self.CursorDraw.Pos);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORStackMsg(Sender:string; data:TStrings);
var i:Integer;
begin
 for i := 0 to Self.ORs.Count-1 do
  if (Self.ORs[i].id = Sender) then
    Self.ORs[i].stack.ParseCommand(data);
end;

////////////////////////////////////////////////////////////////////////////////

function TRelief.GetPanelWidth():SmallInt;
begin
 Result := Self.Graphics.PanelWidth;
end;

function TRelief.GetPanelHeight():SmallInt;
begin
 Result := Self.Graphics.PanelHeight;
end;

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
   PanelPainter.TextOutput(Point(Self.PanelWidth-_INFOTIMER_WIDTH, Self.PanelHeight-i-1),
     str, clRed, clWhite, Self.DrawObject);
  end;//for i
end;

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
end;

procedure TRelief.ORInfoTimerRemove(id:Integer);
var i:Integer;
begin
 for i := 0 to Self.infoTimers.Count-1 do
  if (Self.infoTimers[i].id = id) then
   begin
    Self.infoTimers.Delete(i);
    Exit();
   end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORDKClickServer(Sender:string; enable:boolean);
var i:Integer;
begin
 for i := 0 to Self.myORs.Count-1 do
  if (Self.myORs[i].id = Sender) then
    Self.myORs[i].dk_click_server := enable;
end;

////////////////////////////////////////////////////////////////////////////////

class function TRelief.GetTechBlk(typ:Integer; symbol_index:Integer):TTechBlokToSymbol;
begin
 Result.blk_type      := typ;
 Result.symbol_index  := symbol_index;
end;

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
end;

////////////////////////////////////////////////////////////////////////////////

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
   OblR.RegPlease.status  := TORRegPleaseStatus.none;
  end

 else if (parsed[2] = 'ERR') then
  begin
   F_RegReq.ServerResponseErr(parsed[3]);
   OblR.RegPlease.status  := TORRegPleaseStatus.nOne;
  end

 else if (parsed[2] = 'CANCEL') then
  begin
   F_RegReq.ServerCanceled();
   OblR.RegPlease.status  := TORRegPleaseStatus.none;
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
end;

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

procedure TRelief.SetShowDetails(show:boolean);
begin
 if (Self.fShowDetails = show) then
   Exit();
 Self.fShowDetails := show;
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

class function TRelief.FileSupportedVersionsStr():string;
var i: Integer;
begin
 Result := '';
 for i := 0 to Length(_FileVersion_accept)-1 do
   Result := Result + _FileVersion_accept[i] + ', ';
 Result := LeftStr(Result, Length(Result)-2);
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit

