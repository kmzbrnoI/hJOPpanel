unit Panel;

{
  Main panel logic.
}

interface

uses DXDraws, Controls, Windows, SysUtils, Graphics, Classes, Forms, Math,
  ExtCtrls, AppEvnts, inifiles, Messages, RPConst, fPotvrSekv, MenuPanel,
  StrUtils, PGraphics, HVDb, Generics.Collections, Zasobnik, UPO,
  PngImage, DirectX, PanelOR, BlockTypes, Types, BlockPst,
  BlockLinker, BlockLinkerTrain, BlockLock, BlockCrossing, BlocksTrack, BlocksTurnout,
  BlockSignal, BlockTurnout, BlockTrack, BlockDerail, BlockDisconnector, BlockText,
  BlockOther;

const
  _INFOTIMER_WIDTH = 30;
  _INFOTIMER_TEXT_WIDTH = 22;

  _FILEVERSION_10 = $0100;
  _FILEVERSION_11 = $0101;
  _FILEVERSION_12 = $0102;
  _FILEVERSION_13 = $0103;
  _FILEVERSION_20 = $0200;

  _FileVersion_accept: array [0 .. 3] of string = ('1.1', '1.2', '1.3', '2.0');

type
  /// ////////////////////////////////////////////////////////////////////////////
  // eventy:

  TMoveEvent = procedure(Sender: TObject; Position: TPoint) of object;
  TLoginChangeEvent = procedure(Sender: TObject; str: string) of object;

  /// ////////////////////////////////////////////////////////////////////////////

  // prehlasovani pomoci Ctrl+R (reader vs. normalni uzivatel)
  TReAuth = record
    old_login: string; // guest -> username
    old_ors: TList<Integer>; // (guest -> username) seznam indexu oblati rizeni k autorizaci
  end;

  /// ////////////////////////////////////////////////////////////////////////////

  // data kurzoru
  TCursorDraw = record
    border, fill: TColor;
    pos: TPoint;
    bg: TBitmap;
  end;

  /// ////////////////////////////////////////////////////////////////////////////

  TInfoTimer = record
    finish: TDateTime;
    str: string;
    id: Integer;
  end;

  /// ////////////////////////////////////////////////////////////////////////////

  // odkaz technologickeho id na index v prislusnem seznamu symbolu
  // slouzi pro rychly pristup k symbolum pri CHANGE
  TTechBlokToSymbol = record
    blk_type: TBlkType;
    symbol_index: Integer;
  end;

  /// ////////////////////////////////////////////////////////////////////////////
  TRelief = class
  private const
    _DEF_COLOR_BG = clBlack;
    _DEF_COLOR_CURSOR_BORDER = clYellow;
    _DEF_COLOR_CURSOR_FILL = clMaroon;
    _MSG_WIDTH = 30;
    _DBLCLICK_TIMEOUT_MS = 250;

  private
    drawObject: TDXDraw;
    parentForm: TForm;
    AE: TApplicationEvents;
    T_SystemOK: TTimer; // timer na SystemOK na 500ms - nevykresluje
    Graphics: TPanelGraphics;

    mouseClick: TDateTime;
    mouseTimer: TTimer;
    mouseLastBtn: TMouseButton;
    mouseClickPos: TPoint;

    colors: record
      bg: TColor;
    end;

    cursorDraw: TCursorDraw;
    areaIndex: Integer;
    areas: TObjectList<TAreaPanel>;

    menu: TPanelMenu;
    dkRootMenuItem: string;
    menuLastpos: TPoint; // pozice, na ktere se mys nachazela pred otevrenim menu
    rootMenu: boolean;
    infoTimers: TList<TInfoTimer>;

    techBlok: TDictionary<Integer, TList<TTechBlokToSymbol>>; // mapuje id technologickeho bloku na

    tracks: TPTracks;
    turnouts: TPTurnouts;
    signals: TPSignals;
    linkers: TPLinkers;
    linkersTrains: TPLinkersTrain;
    locks: TPLocks;
    crossings: TPCrossings;
    derails: TPDerails;
    disconnectors: TPDisconnectors;
    texts: TPTexts;
    blockLabels: TPTexts;
    psts: TPPsts;
    otherObj: TPObjOthers;

    systemOK: record
      position: boolean;
    end;

    msg: record
      show: boolean;
      msg: string;
    end;

    reAuth: TReAuth;

    FOnMove: TMoveEvent;
    FOnLoginChange: TLoginChangeEvent;
    fShowDetails: boolean;

    procedure PaintKurzor();
    procedure PaintKurzorBg(Pos: TPoint);

    procedure DXDMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DXDMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DXDMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

    procedure T_SystemOKOnTimer(Sender: TObject);

    procedure ObjectMouseClick(Position: TPoint; Button: TPanelButton);
    procedure ObjectMouseUp(Position: TPoint; Button: TPanelButton);
    procedure ObjectMouseDown(Position: TPoint; Button: TPanelButton);

    procedure FLoad(aFile: string);

    procedure ShowAreas();
    procedure ShowRights();
    procedure ShowCountdown();
    procedure ShowMsg();
    procedure ShowStacks();
    procedure ShowInfoTimers();

    function GetDK(Pos: TPoint): Integer;
    function GetArea(id: string): TAreaPanel;
    function GetAreaIndex(id: string): Integer;

    procedure AEMessage(var msg: tagMSG; var Handled: boolean);

    // DK menu popup
    procedure ShowDKMenu(obl_rizeni: Integer);
    procedure ShowRegMenu(obl_rizeni: Integer);

    // DK menu clicks:
    procedure DKMenuClickMP(Sender: Integer; item: string);
    procedure DKMenuClickMSG(Sender: Integer; item: string);
    procedure DKMenuClickSUPERUSER(Sender: Integer; item: string);
    procedure DKMenuClickCAS(Sender: Integer; item: string);
    procedure DKMenuClickSetCAS(Sender: Integer; item: string);
    procedure DKMenuClickINFO(Sender: Integer; item: string);
    procedure DKMenuClickHLASENI(Sender: Integer; item: string);

    procedure DKMenuClickSUPERUSER_AuthCallback(Sender: TObject; username: string; password: string; ors: TIntAr;
      guest: boolean);

    function DKMenuLOKOItems(Sender: TAreaPanel): string;

    function ParseLOKOMenuClick(item: string; obl_r: Integer): boolean;
    procedure ParseDKMenuClick(item: string; obl_r: Integer);
    procedure ParseRegMenuClick(item: string; obl_r: Integer);
    procedure ParseHlaseniMenuClick(item: string; obl_r: Integer);

    procedure MenuOnClick(Sender: TObject; item: string; obl_r: Integer; itemindex: Integer);

    function GetPanelWidth(): SmallInt;
    function GetPanelHeight(): SmallInt;

    class function GetTechBlk(typ: TBlkType; symbol_index: Integer): TTechBlokToSymbol;
    procedure AddToTechBlk(typ: TBlkType; blok_id: Integer; symbol_index: Integer);

    procedure UpdateLoginString();
    function GetLoginString(): string;

    // procedure prehlasovani (Ctrl+R)
    function AnyORWritable(): boolean;
    procedure AuthReadCallback(Sender: TObject; username: string; password: string; ors: TIntAr; guest: boolean);
    procedure AuthWriteCallback(Sender: TObject; username: string; password: string; ors: TIntAr; guest: boolean);

    procedure OnMouseTimer(Sender: TObject);
    procedure SetShowDetails(show: boolean);

  public

    UPO: TPanelUPO; // upozorneni v leve dolni oblasti
    Enabled: boolean;

    constructor Create(aParentForm: TForm);
    destructor Destroy; override;

    procedure Initialize(var DrawObject: TDXDraw; aFile: string; hints_file: string);
    procedure show();

    procedure AddCountdown(Sender: string; length: TDateTime; id: Integer);
    procedure RemoveCountdown(Sender: string; id: Integer);

    procedure Image(filename: string);

    procedure HideCursor();
    procedure HideMenu();

    procedure ORDisconnect(areai: Integer = -1);
    procedure Escape(send: boolean = true);

    procedure UpdateSymbolSet();

    procedure ReAuthorize();
    procedure IPAAuth();
    procedure UpdateEnabled();

    property bgColor: TColor read colors.bg write colors.bg;
    property cursorBorder: TColor read cursorDraw.border write cursorDraw.border;
    property cursorFill: TColor read cursorDraw.fill write cursorDraw.fill;
    property showDetails: boolean read fShowDetails write SetShowDetails;

    property width: SmallInt read GetPanelWidth;
    property height: SmallInt read GetPanelHeight;
    property areai: Integer read areaIndex;
    property pareas: TObjectList<TAreaPanel> read areas;

    // events
    property OnMove: TMoveEvent read FOnMove write FOnMove;
    property OnLoginUserChange: TLoginChangeEvent read FOnLoginChange write FOnLoginChange;

    // komunikace se serverem
    // sender = id oblasti rizeni

    procedure ORAuthoriseResponse(Sender: string; Rights: TAreaControlRights; comment: string = '';
      username: string = '');
    procedure ORInfoMsg(msg: string);
    procedure ORShowMenu(items: string);
    procedure ORDkShowMenu(Sender: string; rootItem, menuItems: string);
    procedure ORNUZ(Sender: string; status: TNUZstatus);
    procedure ORConnectionOpenned();
    procedure ORConnectionOpenned_AuthCallback(Sender: TObject; username: string; password: string; ors: TIntAr;
      guest: boolean);

    // Change blok
    procedure ORBlkChange(Sender: string; BlokID: Integer; blockType: TBlkType; parsed: TStrings);

    procedure ORInfoTimer(id: Integer; time_min: Integer; time_sec: Integer; str: string);
    procedure ORInfoTimerRemove(id: Integer);
    procedure ORDKClickServer(Sender: string; enable: boolean);
    procedure ORLokReq(Sender: string; parsed: TStrings);

    procedure ORHVList(Sender: string; data: string);
    procedure ORSprNew(Sender: string);
    procedure ORSprEdit(Sender: string; parsed: TStrings);
    procedure OROsvChange(Sender: string; code: string; state: boolean);
    procedure ORStackMsg(Sender: string; data: TStrings);
    procedure ORHlaseniMsg(Sender: string; data: TStrings);

    class function FileSupportedVersionsStr(): string;

  end;

implementation

uses fStitVyl, TCPClientPanel, Symbols, fMain, BottomErrors, GlobalConfig, fZpravy,
  fSprEdit, fSettings, fHVMoveSt, fAuth, fHVEdit, fHVDelete, ModelovyCas,
  fNastaveni_casu, LokoRuc, Sounds, fRegReq, fHVSearch, uLIclient, InterProcessCom,
  parseHelper;

constructor TRelief.Create(aParentForm: TForm);
begin
  inherited Create;

  Self.tracks := TPTracks.Create();
  Self.turnouts := TPTurnouts.Create();
  Self.signals := TPSignals.Create();
  Self.derails := TPDerails.Create();
  Self.disconnectors := TPDisconnectors.Create();
  Self.crossings := TPCrossings.Create();
  Self.texts := TPTexts.Create();
  Self.blockLabels := TPTexts.Create();
  Self.linkers := TPLinkers.Create();
  Self.linkersTrains := TPLinkersTrain.Create();
  Self.locks := TPLocks.Create();
  Self.psts := TPPsts.Create();
  Self.otherObj := TPObjOthers.Create();

  Self.parentForm := aParentForm;
  Self.areas := TObjectList<TAreaPanel>.Create();
  Self.reAuth.old_ors := TList<Integer>.Create();

  Self.Enabled := true;

  Self.mouseTimer := TTimer.Create(nil);
  Self.mouseTimer.Interval := _DblClick_Timeout_Ms + 20;
  Self.mouseTimer.OnTimer := Self.OnMouseTimer;
  Self.mouseTimer.Enabled := false;
end;

procedure TRelief.Initialize(var DrawObject: TDXDraw; aFile: string; hints_file: string);
begin
  Self.graphics := TPanelGraphics.Create(DrawObject);

  Self.menu := TPanelMenu.Create(Self.Graphics);
  Self.menu.OnClick := Self.MenuOnClick;
  Self.menu.LoadHints(hints_file);

  Errors := TErrors.Create(Self.Graphics);
  Self.UPO := TPanelUPO.Create(Self.Graphics);
  RucList := TRucList.Create(Self.Graphics);
  Self.techBlok := TDictionary < Integer, TList < TTechBlokToSymbol >>.Create();

  Self.infoTimers := TList<TInfoTimer>.Create();

  Self.drawObject := DrawObject;

  Self.drawObject.OnMouseUp := Self.DXDMouseUp;
  Self.drawObject.OnMouseDown := Self.DXDMouseDown;
  Self.drawObject.OnMouseMove := Self.DXDMouseMove;

  Self.cursorDraw.pos.X := -2;
  Self.cursorDraw.bg := TBitmap.Create();
  Self.cursorDraw.bg.Width := SymbolSet.symbWidth + 2; // +2 kvuli okrajum kurzoru
  Self.cursorDraw.bg.Height := SymbolSet.symbHeight + 2;

  Self.AE := TApplicationEvents.Create(Self.parentForm);
  Self.AE.OnMessage := Self.AEMessage;

  Self.T_SystemOK := TTimer.Create(Self.parentForm);
  Self.T_SystemOK.Interval := 500;
  Self.T_SystemOK.Enabled := true;
  Self.T_SystemOK.OnTimer := Self.T_SystemOKOnTimer;

  Self.colors.bg := _DEF_COLOR_BG;
  Self.cursorDraw.border := _DEF_COLOR_CURSOR_BORDER;
  Self.cursorDraw.fill := _DEF_COLOR_CURSOR_FILL;

  Self.areaIndex := areaIndex;

  Self.FLoad(aFile);

  (Self.parentForm as TF_Main).SetPanelSize(Self.Graphics.pWidth * SymbolSet.symbWidth,
    Self.Graphics.pHeight * SymbolSet.symbHeight);

  Self.show();
end;

destructor TRelief.Destroy();
begin
  Self.mouseTimer.Free();

  Self.areas.Free();
  Self.turnouts.Free();
  Self.tracks.Free();
  Self.signals.Free();
  Self.derails.Free();
  Self.disconnectors.Free();
  Self.crossings.Free();
  Self.linkers.Free();
  Self.linkersTrains.Free();
  Self.locks.Free();
  Self.texts.Free();
  Self.blockLabels.Free();
  Self.Psts.Free();
  Self.otherObj.Free();

  if (Assigned(Self.infoTimers)) then
    FreeAndNil(Self.infoTimers);
  if (Assigned(Self.UPO)) then
    FreeAndNil(Self.UPO);
  if (Assigned(Self.T_SystemOK)) then
    FreeAndNil(Self.T_SystemOK);
  if (Assigned(Self.menu)) then
    FreeAndNil(Self.menu);
  if (Assigned(Self.Graphics)) then
    FreeAndNil(Self.Graphics);
  if (Assigned(Self.reAuth.old_ors)) then
    FreeAndNil(Self.reAuth.old_ors);

  for var i in Self.techBlok.Keys do
    Self.techBlok[i].Free();
  Self.techBlok.Free();

  Self.cursorDraw.bg.Free();

  inherited Destroy;
end; // destructor

/// /////////////////////////////////////////////////////////////////////////////

// zobrazi vsechny dopravni kancelare
procedure TRelief.ShowAreas();
begin
  for var area in Self.areas do
  begin
    var fg: TColor;
    if (((area.dk_blik) or (area.RegPlease.status = TAreaRegPleaseStatus.selected)) and (Self.Graphics.flash)) then
      fg := clBlack
    else
    begin
      case (area.tech_rights) of
        read:
          fg := clWhite;
        write:
          fg := $A0A0A0;
        superuser:
          fg := clYellow;
      else
        fg := clFuchsia;
      end;

      if (area.RegPlease.status = TAreaRegPleaseStatus.selected) then
        fg := clYellow;
    end;

    Symbols.Draw(SymbolSet.IL_DK, area.positions.dk, Integer(area.positions.dkOrentation), fg, clBlack, Self.drawObject);

    // symbol zadosti o loko se vykresluje vpravo
    if (((area.RegPlease.status = TAreaRegPleaseStatus.request) or (area.RegPlease.status = TAreaRegPleaseStatus.selected))
      and (not Self.Graphics.flash)) then
      Symbols.Draw(SymbolSet.IL_Symbols, Point(area.positions.dk.X + 6, area.positions.dk.Y + 1), _S_CIRCLE, clYellow,
        clBlack, Self.drawObject);
  end;
end;

// zobrazeni SystemOK + opravneni
procedure TRelief.ShowRights();
var pos: TPoint;
  c1, c2, c3: TColor;
begin
  pos.X := 1;
  pos.Y := Self.Graphics.pHeight - 3;

  if (PanelTCPClient.status = TPanelConnectionStatus.opened) then
  begin
    c1 := IfThen(Self.systemOK.position, clRed, clLime);
    c2 := IfThen(Self.systemOK.position, clLime, clRed);
    c3 := clBlue;
  end else begin
    c1 := clPurple;
    c2 := clFuchsia;
    c3 := clPurple;
  end;

  if (Self.systemOK.position) then
  begin
    // horizontal

    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y), _S_FULL + 1, clBlack, c1, Self.drawObject);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 1, pos.Y), _S_HALF_TOP, clBlack, c1, Self.drawObject);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 2, pos.Y), _S_HALF_TOP, clBlack, c1, Self.drawObject);

    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y + 1), _S_HALF_TOP, c2, c3, Self.drawObject);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 1, pos.Y + 1), _S_HALF_TOP, c2, c3, Self.drawObject);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 2, pos.Y + 1), _S_HALF_TOP, c2, c3, Self.drawObject);
  end else begin
    // vertical

    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y), _S_HALF_TOP, clBlack, c1, Self.drawObject);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y + 1), _S_FULL, c1, c1, Self.drawObject);

    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 1, pos.Y), _S_HALF_BOT, c2, clBlack, Self.drawObject);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 1, pos.Y + 1), _S_FULL, c2, clBlack, Self.drawObject);

    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 2, pos.Y), _S_HALF_TOP, clBlack, c3, Self.drawObject);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pos.X + 2, pos.Y + 1), _S_FULL, c3, c3, Self.drawObject);
  end;

  case (PanelTCPClient.status) of
    TPanelConnectionStatus.closed:
      Symbols.TextOutput(Point(pos.X + 5, pos.Y + 1), 'Odpojeno od serveru', clFuchsia, clBlack, Self.drawObject);
    TPanelConnectionStatus.opening:
      Symbols.TextOutput(Point(pos.X + 5, pos.Y + 1), 'Otevírám spojení...', clFuchsia, clBlack, Self.drawObject);
    TPanelConnectionStatus.handshake:
      Symbols.TextOutput(Point(pos.X + 5, pos.Y + 1), 'Probíhá handshake...', clFuchsia, clBlack, Self.drawObject);
    TPanelConnectionStatus.opened:
      Symbols.TextOutput(Point(pos.X + 5, pos.Y + 1), 'Připojeno k serveru', $A0A0A0, clBlack, Self.drawObject);
  end;
end;

procedure TRelief.ShowCountdown();
const _LENGTH = 16;
begin
  for var area in Self.areas do
  begin
    for var k := 0 to area.countdown.Count - 1 do
    begin
      Symbols.TextOutput(Point(area.positions.time.X, area.positions.time.Y + k), 'MER.CASU', clRed,
        clWhite, Self.drawObject);

      var time1, time2: string;
      DateTimeToString(time1, 'ss', Now - area.countdown[k].Start);
      DateTimeToString(time2, 'ss', area.countdown[k].Length);

      for var i := 0 to (Round((StrToIntDef(Time1, 0) / StrToIntDef(Time2, 0)) * _LENGTH) div 2) - 1 do
        Symbols.Draw(SymbolSet.IL_Symbols, Point(area.positions.Time.X + 8 + i, area.positions.Time.Y + k),
          _S_FULL, clRed, clBlack, Self.drawObject);

      for var i := (Round((StrToIntDef(time1, 0) / StrToIntDef(time2, 0)) * _LENGTH) div 2) to (_LENGTH div 2) - 1 do
        Symbols.Draw(SymbolSet.IL_Symbols, Point(area.positions.Time.X + 8 + i, area.positions.Time.Y + k),
          _S_FULL, clWhite, clBlack, Self.drawObject);

      // vykresleni poloviny symbolu
      if ((Round((StrToIntDef(Time1, 0) / StrToIntDef(time2, 0)) * _LENGTH) mod 2) = 1) then
        Symbols.Draw(SymbolSet.IL_Symbols,
          Point(area.positions.Time.X + 8 + (Round((StrToIntDef(Time1, 0) / StrToIntDef(Time2, 0)) * _LENGTH) div 2),
          area.positions.Time.Y + k), _S_HALF_TOP, clRed, clWhite, Self.drawObject);
    end;

    // detekce konce mereni casu
    for var k := area.countdown.Count - 1 downto 0 do
    begin
      if (Now >= area.countdown[k].Length + area.countdown[k].Start) then
        area.countdown.Delete(k);
    end;
  end;
end;

procedure TRelief.ShowMsg();
begin
  if (Self.msg.show) then
    Symbols.TextOutput(Point(0, Self.Graphics.pHeight - 1), Self.msg.msg, clRed, clWhite, Self.drawObject);
end;

/// /////////////////////////////////////////////////////////////////////////////

// hlavni zobrazeni celeho reliefu
procedure TRelief.show();
begin
  try
    if (not Assigned(Self.drawObject)) then
      Exit;
    if (not Self.drawObject.CanDraw) then
      Exit;
    Self.drawObject.Surface.Canvas.Lock();

    Self.drawObject.Surface.Fill(Self.colors.bg);

    if (Self.showDetails) then
      Self.blockLabels.show(Self.drawObject);
    Self.texts.show(Self.drawObject);
    Self.linkersTrains.show(Self.drawObject);
    Self.linkers.show(Self.drawObject, Self.Graphics.flash);
    Self.signals.show(Self.drawObject, Self.Graphics.flash);
    Self.crossings.show(Self.drawObject, Self.Graphics.flash, Self.tracks.data);
    Self.otherObj.show(Self.drawObject, Self.Graphics.flash);
    Self.disconnectors.ShowBg(Self.drawObject, Self.Graphics.flash);
    Self.tracks.show(Self.drawObject, Self.Graphics.flash, Self.areas, signals.startJC, Self.turnouts.data);
    Self.turnouts.show(Self.drawObject, Self.Graphics.flash, Self.tracks.data);
    Self.locks.show(Self.drawObject, Self.Graphics.flash);
    Self.disconnectors.show(Self.drawObject, Self.Graphics.flash);
    Self.derails.show(Self.drawObject, Self.Graphics.flash, Self.tracks.data);
    Self.psts.show(Self.drawObject, Self.Graphics.flash);

    Self.ShowAreas();
    Self.ShowRights();
    Self.ShowStacks();
    Self.ShowCountdown();
    RucList.show(Self.drawObject);
    Self.ShowMsg();
    Self.ShowInfoTimers();
    Errors.show(Self.drawObject);

    if (Self.UPO.showing) then
      Self.UPO.show(Self.drawObject);

    if (Self.menu.showing) then
    begin
      Self.menu.PaintMenu(Self.drawObject, Self.cursorDraw.pos)
    end else begin
      if (GlobConfig.data.panel_mouse = _MOUSE_PANEL) then
        Self.PaintKurzor();
    end;

    Self.drawObject.Surface.Canvas.Release();
    Self.drawObject.Flip();
  except

  end;

  try
    if (Self.drawObject.Surface.Canvas.LockCount > 0) then
      Self.drawObject.Surface.Canvas.UnLock();
  except

  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

// vykresluje kurzor
procedure TRelief.PaintKurzor();
begin
  if ((Self.cursorDraw.pos.X < 0) or (Self.cursorDraw.pos.Y < 0)) then
    Exit;
  if (GlobConfig.data.panel_mouse <> _MOUSE_PANEL) then
    Exit();

  // zkopirujeme si obrazek pod kurzorem jeste pred tim, nez se pres nej prekresli mys
  Self.cursorDraw.bg.Canvas.CopyRect(Rect(0, 0, SymbolSet.symbWidth + 2, SymbolSet.symbHeight + 2),
    Self.drawObject.Surface.Canvas, Rect(Self.cursorDraw.pos.X * SymbolSet.symbWidth - 1,
    Self.cursorDraw.pos.Y * SymbolSet.symbHeight - 1, (Self.cursorDraw.pos.X + 1) * SymbolSet.symbWidth + 1,
    (Self.cursorDraw.pos.Y + 1) * SymbolSet.symbHeight + 1));

  // vykresleni kurzoru
  Self.drawObject.Surface.Canvas.Pen.Color := Self.cursorDraw.border;
  Self.drawObject.Surface.Canvas.Brush.Color := Self.cursorDraw.fill;
  Self.drawObject.Surface.Canvas.Pen.Mode := pmMerge;
  Self.drawObject.Surface.Canvas.Rectangle((Self.cursorDraw.pos.X * SymbolSet.symbWidth) - 1,
    (Self.cursorDraw.pos.Y * SymbolSet.symbHeight) - 1,
    ((Self.cursorDraw.pos.X * SymbolSet.symbWidth) + SymbolSet.symbWidth) + 1,
    ((Self.cursorDraw.pos.Y * SymbolSet.symbHeight) + SymbolSet.symbHeight) + 1);
  Self.drawObject.Surface.Canvas.Pen.Mode := pmCopy;
end;

// vykresli pozadi pod kurzorem, ktere je ulozeno v Self.CursorDraw.Pozadi
// na zadane souradnice (v polickach).
procedure TRelief.PaintKurzorBg(Pos: TPoint);
begin
  Self.drawObject.Surface.Canvas.CopyRect(Rect(Pos.X * SymbolSet.symbWidth - 1, Pos.Y * SymbolSet.symbHeight - 1,
    (Pos.X + 1) * SymbolSet.symbWidth + 1, (Pos.Y + 1) * SymbolSet.symbHeight + 1),

    Self.cursorDraw.bg.Canvas,

    Rect(0, 0, SymbolSet.symbWidth + 2, SymbolSet.symbHeight + 2));
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.DXDMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Handled: boolean;
begin
  // UPO i kdyz je panel disabled
  Handled := false;
  if ((Self.UPO.showing) and (Button = TMouseButton.mbRight)) then
    Self.UPO.KeyPress(VK_ESCAPE, Handled);

  if ((not Self.Enabled) or (Handled)) then
    Exit();

  Self.cursorDraw.pos.X := X div SymbolSet.symbWidth;
  Self.cursorDraw.pos.Y := Y div SymbolSet.symbHeight;

  case (Button) of
    mbLeft:
      begin
        Self.ObjectMouseUp(Self.cursorDraw.pos, TPanelButton.ENTER);
        Self.ObjectMouseClick(Self.cursorDraw.pos, TPanelButton.ENTER);
      end;
    mbRight:
      begin
        Self.ObjectMouseUp(Self.cursorDraw.pos, TPanelButton.Escape);
        Self.ObjectMouseClick(Self.cursorDraw.pos, TPanelButton.Escape);
      end;
    mbMiddle:
      begin
        Self.ObjectMouseUp(Self.cursorDraw.pos, TPanelButton.F1);

        if ((Self.mouseLastBtn = mbMiddle) and (Now - Self.mouseClick < EncodeTime(0, 0, 0, _DblClick_Timeout_Ms))) then
        begin
          Self.mouseTimer.Enabled := false;
          Self.ObjectMouseClick(Self.mouseClickPos, TPanelButton.F2);
        end else begin
          Self.mouseTimer.Enabled := true;
          Self.mouseClickPos := Self.cursorDraw.pos;
        end;
      end;
  end;

  Self.mouseClick := Now;
  Self.mouseLastBtn := Button;

  Self.show();
end;

// Tato funkce neni skoro vubec vyuzivana, je pouze na specialni veci.
// Vsechny kliky mysi se resi pomoci MouseUp
procedure TRelief.DXDMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var myBut: TPanelButton;
begin
  if (not Self.Enabled) then
    Exit();

  case (Button) of
    mbLeft:
      myBut := TPanelButton.ENTER;
    mbRight:
      myBut := TPanelButton.Escape;
    mbMiddle:
      myBut := TPanelButton.F1;
  else
    Exit();
  end;

  Self.ObjectMouseDown(Point(X div SymbolSet.symbWidth, Y div SymbolSet.symbHeight), myBut);
end;

procedure TRelief.OnMouseTimer(Sender: TObject);
begin
  if ((Self.mouseLastBtn = mbMiddle) and (Now - Self.mouseClick > EncodeTime(0, 0, 0, _DblClick_Timeout_Ms))) then
  begin
    Self.ObjectMouseClick(Self.mouseClickPos, TPanelButton.F1);
    Self.mouseTimer.Enabled := false;
    Self.show();
  end;
end;

procedure TRelief.DXDMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var old: TPoint;
begin
  if (not Self.Enabled) then
    Exit();

  // pokud se nemeni pozice kurzoru -- ramecku, neni potreba prekreslovat
  if ((X div SymbolSet.symbWidth = Self.cursorDraw.pos.X) and
    (Y div SymbolSet.symbHeight = Self.cursorDraw.pos.Y)) then
    Exit;

  // vytvorime novou pozici a ulozime ji
  old := Self.cursorDraw.pos;
  Self.cursorDraw.pos.X := X div SymbolSet.symbWidth;
  Self.cursorDraw.pos.Y := Y div SymbolSet.symbHeight;

  // skryjeme informacni zpravu vlevo dole
  Self.msg.show := false;

  // pokud je zobrazeno menu, prekreslime pouze menu
  if ((Self.menu.showing) and (Self.menu.CheckCursorPos(Self.cursorDraw.pos))) then
    Exit();

  // zavolame vnejsi event
  if (Assigned(Self.FOnMove)) then
    Self.FOnMove(Self, Self.cursorDraw.pos);

  // potencialni prekresleni zasobniku pri presunu povelu
  var stackDragged := false;
  for var i := 0 to Self.areas.Count - 1 do
    if (Self.areas[i].stack.IsDragged()) then
      stackDragged := true;

  // panel prekreslujeme jen kdyz je nutne vykreslovat mys na panelu
  // pokud se vykresluje mys operacniho systemu, panel neni prekreslovan
  if ((GlobConfig.data.panel_mouse = _MOUSE_PANEL) or (Self.menu.showing) or (stackDragged)) then
  begin
    // neprekreslujeme cely panel, ale pouze policko, na kterem byla mys v minule pozici
    // obsah tohoto policka je ulozen v Self.CursorDraw.History
    try
      Self.drawObject.Surface.Canvas.Lock();
      if (not Assigned(Self.drawObject)) then
        Exit;
      if (not Self.drawObject.CanDraw) then
        Exit;

      if (Self.menu.showing) then
        Self.menu.PaintMenu(Self.drawObject, Self.cursorDraw.pos)
      else
      begin
        Self.PaintKurzorBg(old);

        for var i := 0 to Self.areas.Count - 1 do
          if (Self.areas[i].stack.IsDragged()) then
            Self.areas[i].stack.show(Self.drawObject, Self.cursorDraw.pos);

        Self.PaintKurzor();
      end;

      // prekreslime si platno
      Self.drawObject.Surface.Canvas.Release();
      Self.drawObject.Flip();
    except

    end;

    try
      if (Self.drawObject.Surface.Canvas.LockCount > 0) then
        Self.drawObject.Surface.Canvas.UnLock();
    except

    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

// vyvolano pri kliku na relief
procedure TRelief.ObjectMouseClick(Position: TPoint; Button: TPanelButton);
var index: Integer;
label
  EscCheck;
begin
  if (Self.menu.showing) then
  begin
    if (Button = TPanelButton.ENTER) then
      Self.menu.Click()
    else if (Button = TPanelButton.Escape) then
      Self.Escape();
    Exit;
  end;

  // nabidka regulatoru u dopravni kancelare
  var Handled := false;
  for var i := 0 to Self.areas.Count - 1 do
  begin
    if (Self.areas[i].tech_rights < TAreaControlRights.write) then
      continue;
    if ((Self.areas[i].RegPlease.status > TAreaRegPleaseStatus.none) and (Position.X = Self.areas[i].positions.DK.X + 6) and
      (Position.Y = Self.areas[i].positions.DK.Y + 1)) then
    begin
      if (Button = ENTER) then
      begin
        case (Self.areas[i].RegPlease.status) of
          TAreaRegPleaseStatus.request:
            Self.areas[i].RegPlease.status := TAreaRegPleaseStatus.selected;
          TAreaRegPleaseStatus.selected:
            Self.areas[i].RegPlease.status := TAreaRegPleaseStatus.request;
        end; // case
      end else if (Button = F2) then
        Self.ShowRegMenu(i);

      goto EscCheck;
    end;
  end;

  // zasobniky
  Handled := false;
  for var i := 0 to Self.areas.Count - 1 do
  begin
    if (Self.areas[i].tech_rights = TAreaControlRights.null) then
      continue;
    Self.areas[i].stack.mouseClick(Position, Button, Handled);
    if (Handled) then
      goto EscCheck;
  end;

  index := Self.crossings.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.crossings[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.crossings[index].area].id, Button, Self.crossings[index].block);
    goto EscCheck;
  end;

  index := Self.texts.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.texts[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.texts[index].area].id, Button, Self.texts[index].block);
    goto EscCheck;
  end;

  index := Self.disconnectors.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.disconnectors[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.disconnectors[index].area].id, Button, Self.disconnectors[index].block);
    goto EscCheck;
  end;

  index := Self.derails.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.derails[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.derails[index].area].id, Button, Self.derails[index].block);
    goto EscCheck;
  end;

  var uid := Self.tracks.GetIndex(Position);
  if (uid.index <> -1) then
  begin
    if (Self.tracks[uid.index].block < 0) then
      goto EscCheck;

    // kliknutim na usek pri zadani o lokomotivu vybereme hnaci vozidla na souprave v tomto useku
    if ((Self.areas[Self.tracks[uid.index].area].RegPlease.status = TAreaRegPleaseStatus.selected) and
      (Button = ENTER)) then
      // zadost o vydani seznamu hnacich vozidel na danem useku
      PanelTCPClient.SendLn(Self.areas[Self.tracks[uid.index].area].id + ';LOK-REQ;U-PLEASE;' +
        IntToStr(Self.tracks[uid.index].block) + ';' + IntToStr(uid.traini))
    else
      PanelTCPClient.PanelClick(Self.areas[Self.tracks[uid.index].area].id, Button, Self.tracks[uid.index].block,
        IntToStr(uid.traini));

    goto EscCheck;
  end;

  index := Self.signals.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.signals[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.signals[index].area].id, Button, Self.signals[index].block);
    goto EscCheck;
  end;

  index := Self.turnouts.GetIndex(Position);
  if (index <> -1) then
  begin
    if (turnouts[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[turnouts[index].area].id, Button, turnouts[index].block);
    goto EscCheck;
  end;

  index := Self.GetDK(Position);
  if (index <> -1) then
  begin
    if (Self.areas[index].dk_click_server) then
    begin
      PanelTCPClient.SendLn(Self.areas[index].id + ';DK-CLICK;' + IntToStr(Integer(Button)));
    end else if (Button <> TPanelButton.Escape) then
      Self.ShowDKMenu(index);
    goto EscCheck;
  end;

  index := Self.linkers.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.linkers[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.linkers[index].area].id, Button, Self.linkers[index].block);
    goto EscCheck;
  end;

  var uvid := Self.linkersTrains.GetIndex(Position);
  if (uvid.index <> -1) then
  begin
    if (Self.linkersTrains[uvid.index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.linkersTrains[uvid.index].area].id, Button,
      Self.linkersTrains[uvid.index].block, IntToStr(uvid.traini));
    goto EscCheck;
  end;

  index := Self.locks.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.locks[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.locks[index].area].id, Button, Self.locks[index].block);
    goto EscCheck;
  end;

  index := Self.psts.GetIndex(Position);
  if (index <> -1) then
  begin
    if (psts[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[psts[index].area].id, Button, psts[index].block);
    goto EscCheck;
  end;

  index := Self.otherObj.GetIndex(Position);
  if (index <> -1) then
  begin
    if (Self.otherObj[index].block < 0) then
      goto EscCheck;
    PanelTCPClient.PanelClick(Self.areas[Self.otherObj[index].area].id, Button, Self.otherObj[index].block);
    goto EscCheck;
  end;

  if (Button = TPanelButton.Escape) then
  begin
    Self.Escape();
    Exit();
  end;

EscCheck:
  // Na bloku byl zavolan escape -> volame interni escape, ale neposilame jej
  // ne server (uz byl poslan).
  if (Button = TPanelButton.Escape) then
    Self.Escape(false);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ObjectMouseUp(Position: TPoint; Button: TPanelButton);
var Handled: boolean;
begin
  Handled := false;
  for var i := 0 to Self.areas.Count - 1 do
  begin
    if (Self.areas[i].tech_rights = TAreaControlRights.null) then
      continue;
    Self.areas[i].stack.MouseUp(Position, Button, Handled);
    if (Handled) then
      Exit();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ObjectMouseDown(Position: TPoint; Button: TPanelButton);
var Handled: boolean;
begin
  Handled := false;
  for var i := 0 to Self.areas.Count - 1 do
  begin
    if (Self.areas[i].tech_rights = TAreaControlRights.null) then
      continue;
    Self.areas[i].stack.MouseDown(Position, Button, Handled);
    if (Handled) then
      Exit();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.FLoad(aFile: string);
var inifile: TMemIniFile;
  sect_str: TStrings;
  ver: string;
  verWord: Word;
  versionOk: boolean;
  strs: TStrings;
begin
  if (not FileExists(aFile)) then
    raise Exception.Create('Soubor panelu ' + aFile + ' neexistuje!');

  inifile := TMemIniFile.Create(aFile, TEncoding.UTF8);

  try
    Self.Graphics.pWidth := inifile.ReadInteger('P', 'W', 100);
    Self.Graphics.pHeight := inifile.ReadInteger('P', 'H', 20);

    // kontrola verze
    ver := inifile.ReadString('G', 'ver', 'invalid');
    versionOk := false;
    for var i := 0 to Length(_FileVersion_accept) - 1 do
    begin
      if (ver = _FileVersion_accept[i]) then
      begin
        versionOk := true;
        Break;
      end;
    end;

    if (not versionOk) then
    begin
      if (Application.MessageBox(PChar('Načítáte soubor s verzí ' + ver + #13#10 +
        'Aplikace momentálně podporuje verze ' + Self.FileSupportedVersionsStr() + #13#10 + 'Chcete pokračovat?'),
        'Varování', MB_YESNO OR MB_ICONQUESTION) = mrNo) then
        Exit();
    end;

    strs := TStringList.Create();
    try
      ExtractStringsEx(['.'], [], ver, strs);
      verWord := (StrToInt(strs[0]) shl 8) + StrToInt(strs[1]);
    finally
      strs.Free();
    end;

    // Oblasti rizeni
    sect_str := TStringList.Create();
    try
      inifile.ReadSection('OR', sect_str);
      Self.areas.Clear();
      for var i := 0 to sect_str.Count - 1 do
        Self.areas.Add(TAreaPanel.Create(inifile.ReadString('OR', sect_str[i], ''), Self.Graphics));
    finally
      sect_str.Free();
    end;

    // vytvorime okynka zprav
    TF_Messages.frm_cnt := Self.areas.Count;
    for var i := 0 to Self.areas.Count - 1 do
      TF_Messages.frm_db[i] := TF_Messages.Create(Self.areas[i].Name, Self.areas[i].id);

    Self.tracks.Load(inifile, Self.areas, verWord);
    Self.signals.Load(inifile, verWord);
    Self.turnouts.Load(inifile, verWord);
    Self.derails.Load(inifile, verWord);
    Self.crossings.Load(inifile, Self.tracks, verWord);
    Self.linkers.Load(inifile, verWord);
    Self.linkersTrains.Load(inifile, verWord);
    Self.locks.Load(inifile, verWord);
    Self.disconnectors.Load(inifile, verWord);
    Self.texts.Load(inifile, 'T', verWord);
    Self.blockLabels.Load(inifile, 'TP', verWord);
    Self.psts.Load(inifile, verWord);
    Self.otherObj.Load(inifile, verWord);

    Self.techBlok.Clear();

    for var i := 0 to Self.tracks.data.Count - 1 do
      Self.AddToTechBlk(btTrack, Self.tracks[i].block, i);

    for var i := 0 to Self.turnouts.data.Count - 1 do
      Self.AddToTechBlk(btTurnout, Self.turnouts[i].block, i);

    for var i := 0 to Self.linkers.data.Count - 1 do
      Self.AddToTechBlk(btLinker, Self.linkers[i].block, i);

    for var i := 0 to Self.linkersTrains.data.Count - 1 do
      Self.AddToTechBlk(btLinkerSpr, Self.linkersTrains[i].block, i);

    for var i := 0 to Self.locks.data.Count - 1 do
      Self.AddToTechBlk(btLock, Self.locks[i].block, i);

    for var i := 0 to Self.crossings.data.Count - 1 do
      Self.AddToTechBlk(btCrossing, Self.crossings[i].block, i);

    for var i := 0 to Self.signals.data.Count - 1 do
      Self.AddToTechBlk(btSignal, Self.signals[i].block, i);

    for var i := 0 to Self.derails.data.Count - 1 do
      Self.AddToTechBlk(btDerail, Self.derails[i].block, i);

    for var i := 0 to Self.disconnectors.data.Count - 1 do
      Self.AddToTechBlk(btDisconnector, Self.disconnectors[i].block, i);

    for var i := 0 to Self.psts.data.Count - 1 do
      Self.AddToTechBlk(btPst, Self.psts[i].block, i);

    for var i := 0 to Self.otherObj.data.Count - 1 do
      Self.AddToTechBlk(btOther, Self.otherObj[i].block, i);

    for var i := 0 to Self.texts.Count - 1 do
      if (Self.texts[i].block > -1) then
        Self.AddToTechBlk(btSummary, Self.texts[i].block, i);

  finally
    inifile.Free();
  end;
end;

function TRelief.GetDK(Pos: TPoint): Integer;
begin
  for var i := 0 to Self.areas.Count - 1 do
    if ((Pos.X >= Self.areas[i].positions.DK.X) and (Pos.Y >= Self.areas[i].positions.DK.Y) and
      (Pos.X <= Self.areas[i].positions.DK.X + (((_DK_WIDTH_MULT * SymbolSet.symbWidth) - 1) div SymbolSet.symbWidth)) and
      (Pos.Y <= Self.areas[i].positions.DK.Y + (((_DK_HEIGHT_MULT * SymbolSet.symbHeight) - 1) div SymbolSet.symbHeight)))
    then
      Exit(i);

  Result := -1;
end;

procedure TRelief.AEMessage(var msg: tagMSG; var Handled: boolean);
begin
  if ((msg.message = WM_KeyDown) and (Self.ParentForm.Active)) then // pokud je stisknuta klavesa
  begin
    if (Errors.Count > 0) then
    begin
      case (msg.wParam) of
        VK_BACK, VK_RETURN:
          Errors.RemoveVisibleErrors();
      end; // case msg.wParam
      Exit();
    end;

    var ahandled := false;
    if (Self.Menu.showing) then
      Self.Menu.KeyPress(msg.wParam, ahandled);
    if (ahandled) then
      Exit();

    if (Self.UPO.showing) then
      Self.UPO.KeyPress(msg.wParam, ahandled);
    if (ahandled) then
    begin
      Self.show();
      Exit();
    end;

    ahandled := false;
    for var i := 0 to Self.areas.Count - 1 do
    begin
      Self.areas[i].stack.KeyPress(msg.wParam, ahandled);
      if (ahandled) then
        Exit();
    end; // for i

    case (msg.wParam) of // case moznosti stisknutych klaves
      VK_F1:
        Self.ObjectMouseClick(Self.CursorDraw.Pos, F1);
      VK_F2:
        Self.ObjectMouseClick(Self.CursorDraw.Pos, F2);
      VK_ESCAPE:
        Self.ObjectMouseClick(Self.CursorDraw.Pos, TPanelButton.Escape);
      VK_RETURN:
        Self.ObjectMouseClick(Self.CursorDraw.Pos, ENTER);
      VK_BACK:
        Errors.RemoveVisibleErrors();

      VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT:
        begin
          var mouse: TPoint;
          GetCursorPos(mouse);

          case (msg.wParam) of
            VK_LEFT:
              mouse.X := mouse.X - SymbolSet.symbWidth;
            VK_RIGHT:
              mouse.X := mouse.X + SymbolSet.symbWidth;
            VK_UP:
              mouse.Y := mouse.Y - SymbolSet.symbHeight;
            VK_DOWN:
              mouse.Y := mouse.Y + SymbolSet.symbHeight;
          end;

          SetCursorPos(mouse.X, mouse.Y);
        end;

      VK_F9:
        begin
          Self.rootMenu := not Self.rootMenu;
          if (Self.rootMenu) then
            Self.ORInfoMsg('Root menu on')
          else
            Self.ORInfoMsg('Root menu off');
        end;
    end; // case
  end; // if
end;

procedure TRelief.T_SystemOKOnTimer(Sender: TObject);
begin
  Self.systemOK.position := not Self.systemOK.position;
  Self.graphics.flash := not Self.graphics.flash;
end;

procedure TRelief.Escape(send: boolean = true);
begin
  if (Self.Menu.showing) then
    Self.HideMenu();
  if (F_StitVyl.showing) then
    F_StitVyl.Close();
  if (F_SoupravaEdit.showing) then
    F_SoupravaEdit.Close;
  if (F_Settings.showing) then
    F_Settings.Close();
  if (F_PotvrSekv.running) then
    F_PotvrSekv.Stop('escape');

  for var area in Self.areas do
    if (area.RegPlease.status = TAreaRegPleaseStatus.selected) then
      area.RegPlease.status := TAreaRegPleaseStatus.request;

  if (send) then
    PanelTCPClient.PanelClick('-', TPanelButton.Escape);
end;

procedure TRelief.AddCountdown(Sender: string; length: TDateTime; id: Integer);
begin
  var area := Self.GetArea(Sender);
  if (area <> nil) then
  begin
    var mc: TCountdown;
    mc.Start := Now;
    mc.Length := length;
    mc.id := id;
    area.countdown.Add(mc);
  end;
end;

procedure TRelief.RemoveCountdown(Sender: string; id: Integer);
begin
  var area := Self.GetArea(Sender);
  if (area = nil) then
    Exit();

  for var i := 0 to area.countdown.Count - 1 do
  begin
    if (area.countdown[i].id = id) then
    begin
      area.countdown.Delete(i);
      Break;
    end;
  end;
end;

procedure TRelief.Image(filename: string);
var PR, PG, PB: ^byte;
begin
  Self.CursorDraw.Pos.X := -2;

  Self.show();

  var Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.Width := Self.DrawObject.Width;
    Bmp.Height := Self.DrawObject.Height;
    Bmp.Canvas.CopyRect(Rect(0, 0, Self.DrawObject.Width, Self.DrawObject.Height), Self.DrawObject.Surface.Canvas,
      Rect(0, 0, Self.DrawObject.Width, Self.DrawObject.Height));

    // change colors
    for var Y := 0 to Bmp.Height - 1 do
    begin
      var PYStart := Cardinal(Bmp.ScanLine[Y]);
      for var X := 0 to Bmp.Width - 1 do
      begin
        PB := Pointer(PYStart + 3 * X);
        PG := Pointer(PYStart + 3 * X + 1);
        PR := Pointer(PYStart + 3 * X + 2);

        var aColor := PR^ + (PG^ shl 8) + (PB^ shl 16);
        if (aColor = clBlack) then
        begin
          PR^ := 255;
          PG^ := 255;
          PB^ := 255;
        end else begin
          if ((aColor = clWhite) or (aColor = clGray) or (aColor = clSilver) or (aColor = $A0A0A0)) then
          begin
            PR^ := 0;
            PG^ := 0;
            PB^ := 0;
          end;
        end;
      end; // for x
    end; // for y

    if (RightStr(filename, 3) = 'bmp') then
      Bmp.SaveToFile(filename)
    else
    begin
      var png := TPngImage.Create;
      try
        png.Assign(Bmp);
        png.SaveToFile(filename);
      finally
        FreeAndNil(png);
      end;
    end;
  finally
    FreeAndNil(Bmp);
  end;
end;

procedure TRelief.HideCursor();
begin
  if (Self.CursorDraw.Pos.X >= 0) then
  begin
    Self.CursorDraw.Pos.X := -2;
    Self.show();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////
// komunikace s oblastmi rizeni:

// odpoved na autorizaci:
procedure TRelief.ORAuthoriseResponse(Sender: string; Rights: TAreaControlRights; comment: string = '';
  username: string = '');
begin
  var areai := Self.GetAreaIndex(Sender);
  if (areai = -1) then
    Exit;

  var tmp := Self.areas[areai].tech_rights;
  Self.areas[areai].tech_rights := Rights;
  Self.areas[areai].username := username;
  Self.UpdateLoginString();

  if ((Rights < tmp) and (Rights < write)) then
  begin
    Self.areas[areai].countdown.Clear();
    while (SoundsPlay.IsPlaying(_SND_TRAT_ZADOST)) do
      SoundsPlay.DeleteSound(_SND_TRAT_ZADOST);
  end;

  if ((tmp = TAreaControlRights.null) and (Rights > tmp)) then
    PanelTCPClient.PanelFirstGet(Sender);

  if (Rights = TAreaControlRights.null) then
    Self.ORDisconnect(areai);

  if ((Rights > TAreaControlRights.null) and (tmp = TAreaControlRights.null)) then
    Self.areas[areai].stack.Enabled := true;

  if ((Rights >= TAreaControlRights.write) and (BridgeClient.authStatus = TuLIAuthStatus.no) and
    (BridgeClient.toLogin.password <> '')) then
    BridgeClient.Auth();

  if (Rights >= TAreaControlRights.read) then
    IPC.CheckAuth();

  if (F_Auth.listening) then
  begin
    if (Rights = TAreaControlRights.null) then
      F_Auth.AuthError(areai, comment)
    else
      F_Auth.AuthOK(areai);
  end;

  if (comment <> '') then
    Self.ORInfoMsg(comment);
end;

procedure TRelief.ORInfoMsg(msg: string);
begin
  Self.msg.msg := msg + StringOfChar(' ', Max(Self._msg_width - Length(msg), 0));
  Self.msg.show := true;
end;

procedure TRelief.ORNUZ(Sender: string; status: TNUZstatus);
begin
  var area := Self.GetArea(Sender);
  if (area = nil) then
    Exit;

  area.NUZ_status := status;

  case (status) of
    no_nuz, nuzing:
      area.dk_blik := false;
    blk_in_nuz:
      area.dk_blik := true;
  end;
end;

procedure TRelief.ORConnectionOpenned();
begin
  // zjistime pocet OR s zadanym opravnenim > null
  var cnt := GlobConfig.GetAuthNonNullORSCnt();
  if (cnt = 0) then
    Exit();

  // do \ors si priradime vsechna or s zadanym opravnenim > null
  var ors: TIntAr;
  SetLength(ors, cnt);
  var j := 0;
  var rights: TAreaControlRights;
  for var i := 0 to Self.areas.Count - 1 do
    if ((GlobConfig.data.Auth.ors.TryGetValue(Self.areas[i].id, rights)) and (rights > TAreaControlRights.null)) then
    begin
      ors[j] := i;
      Inc(j);
    end;

  if (GlobConfig.data.Auth.autoauth) then
  begin
    F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.Auth.username, 2, Self.ORConnectionOpenned_AuthCallback,
      ors, true);
    Self.ORConnectionOpenned_AuthCallback(Self, GlobConfig.data.Auth.username, GlobConfig.data.Auth.password,
      ors, false);

    if ((GlobConfig.data.uLI.use) and (BridgeClient.authStatus = TuLIAuthStatus.no) and
      (not PanelTCPClient.openned_by_ipc)) then
    begin
      BridgeClient.toLogin.username := GlobConfig.data.Auth.username;
      BridgeClient.toLogin.password := GlobConfig.data.Auth.password;
    end;

  end else begin
    F_Auth.OpenForm('Vyžadována autorizace', Self.ORConnectionOpenned_AuthCallback, ors, true);
  end;
end;

procedure TRelief.ORConnectionOpenned_AuthCallback(Sender: TObject; username: string; password: string; ors: TIntAr;
  guest: boolean);
var rights: TAreaControlRights;
begin
  for var i := 0 to Self.areas.Count - 1 do
  begin
    if (GlobConfig.data.Auth.ors.TryGetValue(Self.areas[i].id, rights)) then
    begin
      if (rights > TAreaControlRights.null) then
      begin
        if ((rights > TAreaControlRights.read) and (guest)) then
          rights := TAreaControlRights.read;
        Self.areas[i].login := username;
        PanelTCPClient.PanelAuthorise(Self.areas[i].id, rights, username, password)
      end;
    end else begin
      Self.areas[i].login := username;
      PanelTCPClient.PanelAuthorise(Self.areas[i].id, read, username, password);
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////
// -- Communication with areas --

procedure TRelief.ORBlkChange(Sender: string; BlokID: Integer; blockType: TBlkType; parsed: TStrings);
begin
  // ziskame vsechny bloky na panelu, ktere navazuji na dane technologicke ID:
  if (not Self.techBlok.ContainsKey(BlokID)) then
    Exit();
  var symbols := Self.techBlok[BlokID];

  for var i := 0 to Symbols.Count - 1 do
  begin
    case (blockType) of
      btTrack:
        begin
          if ((Symbols[i].blk_type = btTrack) and
            (Sender = Self.areas[Self.tracks[Symbols[i].symbol_index].area].id)) then
            Self.tracks[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btTurnout:
        begin
          if ((Symbols[i].blk_type = btTurnout) and (Sender = Self.areas[turnouts[Symbols[i].symbol_index].area].id))
          then
            Self.turnouts[Symbols[i].symbol_index].PanelProp.Change(parsed);

          if ((Symbols[i].blk_type = btDerail) and
            (Sender = Self.areas[Self.derails[Symbols[i].symbol_index].area].id)) then
            Self.derails[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btSignal:
        begin
          if ((Symbols[i].blk_type = btSignal) and
            (Sender = Self.areas[Self.signals[Symbols[i].symbol_index].area].id)) then
            Self.signals[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btCrossing:
        begin
          if ((Symbols[i].blk_type = btCrossing) and
            (Sender = Self.areas[Self.crossings[Symbols[i].symbol_index].area].id)) then
            Self.crossings[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btLock:
        begin
          if ((Symbols[i].blk_type = btLock) and
            (Sender = Self.areas[Self.locks[Symbols[i].symbol_index].area].id)) then
            Self.locks[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btDisconnector:
        begin
          if ((Symbols[i].blk_type = btDisconnector) and
            (Sender = Self.areas[Self.disconnectors[Symbols[i].symbol_index].area].id)) then
            Self.disconnectors[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btPst:
        begin
          if ((Symbols[i].blk_type = btPst) and
            (Sender = Self.areas[Self.psts[Symbols[i].symbol_index].area].id)) then
            Self.psts[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btLinker:
        begin
          if ((Symbols[i].blk_type = btLinker) and
            (Sender = Self.areas[Self.linkers[Symbols[i].symbol_index].area].id)) then
            Self.linkers[Symbols[i].symbol_index].PanelProp.Change(parsed);

          if ((Symbols[i].blk_type = btLinkerSpr) and
            (Sender = Self.areas[Self.linkersTrains[Symbols[i].symbol_index].area].id)) then
            Self.linkersTrains[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

      btSummary:
        begin
          if ((Symbols[i].blk_type = btSummary) and
            (Sender = Self.areas[Self.texts[Symbols[i].symbol_index].area].id)) then
            Self.texts[Symbols[i].symbol_index].PanelProp.Change(parsed);
        end;

    end; // case

    if ((Symbols[i].blk_type = btOther) and
      (Sender = Self.areas[Self.otherObj[Symbols[i].symbol_index].area].id)) then
      Self.otherObj[Symbols[i].symbol_index].PanelProp.Change(parsed);
  end;

  if (blockType = btSignal) then
    Self.signals.UpdateStartJC();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORHVList(Sender: string; data: string);
begin
  for var i := 0 to Self.areas.Count - 1 do
    if (Sender = Self.areas[i].id) then
    begin
      Self.areas[i].HVs.ParseHVs(data);
      Self.areas[i].HVs.HVs.Sort();
      Exit();
    end;
end;

procedure TRelief.ORSprNew(Sender: string);
begin
  for var i := 0 to Self.areas.Count - 1 do
    if (Sender = Self.areas[i].id) then
    begin
      var available := false;
      for var HV in Self.areas[i].HVs.HVs do
        if (HV.train = '-') then
        begin
          available := true;
          Break;
        end;

      if (available) then
        F_SoupravaEdit.NewSpr(Self.areas[i].HVs, Self.areas[i].id)
      else
        Self.ORInfoMsg('Nejsou volné loko');

      Exit();
    end;
end;

procedure TRelief.ORSprEdit(Sender: string; parsed: TStrings);
begin
  for var i := 0 to Self.areas.Count - 1 do
    if (Sender = Self.areas[i].id) then
    begin
      F_SoupravaEdit.EditSpr(parsed, Self.areas[i].HVs, Self.areas[i].id, Self.areas[i].Name);
      Exit();
    end;
end;

/// /////////////////////////////////////////////////////////////////////////////

// technologie posle nejake menu a my ho zobrazime:
procedure TRelief.ORShowMenu(items: string);
begin
  Self.menuLastpos := Self.CursorDraw.Pos;
  Self.dkRootMenuItem := '';
  Self.Menu.ShowMenu(items, -1, Self.DrawObject.ClientToScreen(Point(0, 0)));
end;

procedure TRelief.ORDkShowMenu(Sender: string; rootItem, menuItems: string);
begin
  var area := Self.GetArea(Sender);
  if (area = nil) then
    Exit();

  Self.menuLastpos := Self.CursorDraw.Pos;
  Self.dkRootMenuItem := rootItem;

  if (rootItem = 'LOKO') then
    menuItems := Self.DKMenuLOKOItems(area) + ',' + menuItems;

  Self.Menu.ShowMenu(menuItems, Self.GetAreaIndex(Sender), Self.DrawObject.ClientToScreen(Point(0, 0)));
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.HideMenu();
begin
  Self.Menu.showing := false;
  Self.dkRootMenuItem := '';
  var bPos := Self.DrawObject.ClientToScreen(Point(0, 0));
  SetCursorPos(Self.menuLastpos.X * SymbolSet.symbWidth + bPos.X, Self.menuLastpos.Y * SymbolSet.symbHeight
    + bPos.Y);
  Self.show();
end;

/// /////////////////////////////////////////////////////////////////////////////
// DKMenu popup:

procedure TRelief.ShowDKMenu(obl_rizeni: Integer);
var menu_str: string;
begin
  if (PanelTCPClient.status <> TPanelConnectionStatus.opened) then
    Exit();

  menu_str := '$' + Self.areas[obl_rizeni].Name + ',-,';

  case (Self.areas[obl_rizeni].tech_rights) of
    TAreaControlRights.null, TAreaControlRights.read, TAreaControlRights.superuser:
      menu_str := menu_str + 'MP,';
    TAreaControlRights.write:
      menu_str := menu_str + 'DP,';
  end; // case

  if (Self.rootMenu) then
    menu_str := menu_str + '!SUPERUSER,';

  if (Integer(Self.areas[obl_rizeni].tech_rights) >= 2) then
  begin
    // mame pravo zapisovat

    PanelTCPClient.PanelUpdateOsv(Self.areas[obl_rizeni].id);

    // LOKO
    menu_str := menu_str + 'LOKO,';

    // OSV
    if (Self.areas[obl_rizeni].lights.Count > 0) then
      menu_str := menu_str + 'OSV,';

    // NUZ
    case (Self.areas[obl_rizeni].NUZ_status) of
      TNUZstatus.blk_in_nuz:
        menu_str := menu_str + '!NUZ>,';
      TNUZstatus.nuzing:
        menu_str := menu_str + 'NUZ<,';
    end;

    menu_str := menu_str + 'MSG,';

    if (ModelTime.used) then
    begin
      if (ModelTime.started) then
      begin
        if (Self.areas[obl_rizeni].Rights.ModelTimeStop) then
          menu_str := menu_str + 'CAS<,';
      end else begin
        if (Self.areas[obl_rizeni].Rights.ModelTimeStart) then
          menu_str := menu_str + 'CAS>,';
      end;
    end;

    if ((Self.areas[obl_rizeni].Rights.ModelTimeSet) and (not ModelTime.started)) then
      menu_str := menu_str + 'CAS,';

    if (Self.areas[obl_rizeni].announcement) then
      menu_str := menu_str + 'HLÁŠENÍ,';
  end;

  menu_str := menu_str + 'INFO,';

  Self.dkRootMenuItem := 'DK';
  Self.menuLastpos := Self.CursorDraw.Pos;

  Self.Menu.ShowMenu(menu_str, obl_rizeni, Self.DrawObject.ClientToScreen(Point(0, 0)));
end;

/// /////////////////////////////////////////////////////////////////////////////
// DKMenu clicks:

procedure TRelief.DKMenuClickMP(Sender: Integer; item: string);
var ors: TIntAr;
begin
  SetLength(ors, 1);
  ors[0] := Sender;

  if ((GlobConfig.data.Auth.autoauth) and (Self.areas[Sender].tech_rights < TAreaControlRights.superuser)) then
  begin
    if (item = 'MP') then
    begin
      F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.Auth.username, 2, Self.AuthWriteCallback, ors, false);
      Self.AuthWriteCallback(Self, GlobConfig.data.Auth.username, GlobConfig.data.Auth.password, ors, false);
    end else begin
      F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.Auth.username, 2, Self.AuthReadCallback, ors, true);
      Self.AuthReadCallback(Self, GlobConfig.data.Auth.username, GlobConfig.data.Auth.password, ors, false);
    end;
  end else begin
    if (item = 'MP') then
      F_Auth.OpenForm('Vyžadována autorizace', Self.AuthWriteCallback, ors, false)
    else
      F_Auth.OpenForm('Vyžadována autorizace', Self.AuthReadCallback, ors, true)
  end;
end;

function TRelief.DKMenuLOKOItems(Sender: TAreaPanel): string;
begin
  Result := '$' + Sender.Name + ',$LOKO,-,NOVÁ loko,EDIT loko,SMAZAT loko,PŘEDAT loko,HLEDAT loko,RUČ loko';
  if (BridgeClient.authStatus = TuLIAuthStatus.yes) then
    Result := Result + ',MAUS loko';
end;

procedure TRelief.DKMenuClickSUPERUSER(Sender: Integer; item: string);
var ors: TIntAr;
begin
  SetLength(ors, 1);
  ors[0] := Sender;
  F_Auth.OpenForm('Vyžadována autorizace', Self.DKMenuClickSUPERUSER_AuthCallback, ors, false);
end;

procedure TRelief.DKMenuClickSUPERUSER_AuthCallback(Sender: TObject; username: string; password: string; ors: TIntAr;
  guest: boolean);
begin
  Self.areas[ors[0]].login := username;
  PanelTCPClient.PanelAuthorise(Self.areas[ors[0]].id, superuser, username, password);
  Self.rootMenu := false;
end;

procedure TRelief.DKMenuClickCAS(Sender: Integer; item: string);
begin
  if (item = 'CAS>') then
    PanelTCPClient.SendLn('-;MOD-CAS;START;')
  else
    PanelTCPClient.SendLn('-;MOD-CAS;STOP;');
end;

procedure TRelief.DKMenuClickSetCAS(Sender: Integer; item: string);
begin
  F_ModelTime.OpenForm();
end;

procedure TRelief.DKMenuClickINFO(Sender: Integer; item: string);
var lichy, rs: string;
begin
  if (Self.areas[Sender].orientation = aoOddLeftToRight) then
    lichy := 'zleva doprava'
  else if (Self.areas[Sender].orientation = aoOddRightToLeft) then
    lichy := 'zprava doleva'
  else
    lichy := 'nedefinován';

  case (Self.areas[Sender].tech_rights) of
    TAreaControlRights.read:
      rs := 'ke čtení';
    TAreaControlRights.write:
      rs := 'k zápisu';
    TAreaControlRights.superuser:
      rs := 'superuser';
  else
    rs := 'nedefinováno';
  end;

  Application.MessageBox(PChar('Oblast řízení : ' + Self.areas[Sender].Name + #13#10 + 'ID : ' + Self.areas[Sender].id +
    #13#10 + 'Přihlášen : ' + Self.areas[Sender].username + #13#10 + 'Lichý směr : ' + lichy + #13#10 + 'Oprávnění : ' +
    rs), PChar(Self.areas[Sender].Name), MB_OK OR MB_ICONINFORMATION);
end;

procedure TRelief.DKMenuClickHLASENI(Sender: Integer; item: string);
var menu_str: string;
begin
  menu_str := '$' + Self.areas[Sender].Name + ',$STANIČNÍ HLÁŠENÍ,-,POSUN,NESAHAT,INTRO,SPEC1,SPEC2,SPEC3';
  Self.dkRootMenuItem := 'HLASENI';
  Self.Menu.ShowMenu(menu_str, Sender, Self.DrawObject.ClientToScreen(Point(0, 0)));
end;

procedure TRelief.DKMenuClickMSG(Sender: Integer; item: string);
begin
  TF_Messages.frm_db[Sender].show();
  TF_Messages.frm_db[Sender].SetFocus();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowRegMenu(obl_rizeni: Integer);
var menu_str: string;
begin
  if ((PanelTCPClient.status <> TPanelConnectionStatus.opened) or
    (Self.areas[obl_rizeni].RegPlease.status = TAreaRegPleaseStatus.none)) then
    Exit();

  menu_str := '$' + Self.areas[obl_rizeni].Name + ',$Žádost o loko,-,INFO,ODMÍTNI';

  Self.areas[obl_rizeni].RegPlease.status := TAreaRegPleaseStatus.request;

  Self.dkRootMenuItem := 'REG-PLEASE';
  Self.menuLastpos := Self.CursorDraw.Pos;

  Self.Menu.ShowMenu(menu_str, obl_rizeni, Self.DrawObject.ClientToScreen(Point(0, 0)));

  PanelTCPClient.PanelLokList(Self.areas[obl_rizeni].id);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.MenuOnClick(Sender: TObject; item: string; obl_r: Integer; itemindex: Integer);
var sp_menu: string;
begin
  sp_menu := Self.dkRootMenuItem;
  Self.HideMenu();

  if (sp_menu = '') then
    PanelTCPClient.PanelMenuClick(item, itemindex)
  else if (sp_menu = 'DK') then
    Self.ParseDKMenuClick(item, obl_r)
  else if (sp_menu = 'REG-PLEASE') then
    Self.ParseRegMenuClick(item, obl_r)
  else if (sp_menu = 'HLASENI') then
    Self.ParseHlaseniMenuClick(item, obl_r)
  else if (sp_menu = 'LOKO') then
  begin
    if (not Self.ParseLOKOMenuClick(item, obl_r)) then // not handled
      PanelTCPClient.PanelDkMenuClick(Self.areas[obl_r].id, sp_menu, item);
  end
  else
    PanelTCPClient.PanelDkMenuClick(Self.areas[obl_r].id, sp_menu, item);
end;

procedure TRelief.ParseDKMenuClick(item: string; obl_r: Integer);
begin
  if ((item = 'MP') or (item = 'DP')) then
    Self.DKMenuClickMP(obl_r, item)
  else if (item = 'MSG') then
    Self.DKMenuClickMSG(obl_r, item)
  else if (item = 'SUPERUSER') then
    Self.DKMenuClickSUPERUSER(obl_r, item)
  else if ((item = 'CAS>') or (item = 'CAS<')) then
    Self.DKMenuClickCAS(obl_r, item)
  else if (item = 'CAS') then
    Self.DKMenuClickSetCAS(obl_r, item)
  else if (item = 'INFO') then
    Self.DKMenuClickINFO(obl_r, item)
  else if (item = 'HLÁŠENÍ') then
    Self.DKMenuClickHLASENI(obl_r, item)
  else
    PanelTCPClient.PanelDkMenuClick(Self.areas[obl_r].id, item); // no special menu -> send click to server

  if (item = 'LOKO') then
    PanelTCPClient.PanelLokList(Self.areas[obl_r].id);
end;

function TRelief.ParseLOKOMenuClick(item: string; obl_r: Integer): boolean;
begin
  Result := true;

  if (item = 'NOVÁ loko') then
    F_HVEdit.HVAdd(Self.areas[obl_r].id, Self.areas[obl_r].HVs)
  else if (item = 'EDIT loko') then
    F_HVEdit.HVEdit(Self.areas[obl_r].id, Self.areas[obl_r].HVs)
  else if (item = 'SMAZAT loko') then
    F_HVDelete.OpenForm(Self.areas[obl_r].id, Self.areas[obl_r].HVs)
  else if (item = 'PŘEDAT loko') then
    F_HV_Move.Open(Self.areas[obl_r].id, Self.areas[obl_r].HVs)
  else if (item = 'HLEDAT loko') then
    F_HVSearch.show()
  else if ((item = 'RUČ loko') or (item = 'MAUS loko')) then
    F_RegReq.Open(Self.areas[obl_r].HVs, Self.areas[obl_r].id, Self.areas[obl_r].RegPlease.user,
      Self.areas[obl_r].RegPlease.firstname, Self.areas[obl_r].RegPlease.lastname, Self.areas[obl_r].RegPlease.comment,
      (Self.areas[obl_r].RegPlease.status <> TAreaRegPleaseStatus.none), false, false, (item = 'MAUS loko'))
  else
    Result := false;
end;

procedure TRelief.ParseRegMenuClick(item: string; obl_r: Integer);
begin
  if (item = 'ODMÍTNI') then
    PanelTCPClient.SendLn(Self.areas[obl_r].id + ';LOK-REQ;DENY')
  else if (item = 'INFO') then
  begin
    F_RegReq.Open(Self.areas[obl_r].HVs, Self.areas[obl_r].id, Self.areas[obl_r].RegPlease.user,
      Self.areas[obl_r].RegPlease.firstname, Self.areas[obl_r].RegPlease.lastname, Self.areas[obl_r].RegPlease.comment,
      true, false, false, false);
  end;
end;

procedure TRelief.ParseHlaseniMenuClick(item: string; obl_r: Integer);
begin
  PanelTCPClient.SendLn(Self.areas[obl_r].id + ';SHP;SPEC;' + item);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORDisconnect(areai: Integer = -1);
begin
  if (areai = -1) then
  begin
    Self.Menu.showing := false;
    Self.UPO.showing := false;
    Self.infoTimers.Clear();
    Self.Graphics.dxd.Enabled := true;
  end;

  Self.tracks.Reset(areai);
  Self.turnouts.Reset(areai);
  Self.signals.Reset(areai);
  Self.crossings.Reset(areai);
  Self.linkers.Reset(areai);
  Self.linkersTrains.Reset(areai);
  Self.locks.Reset(areai);
  Self.derails.Reset(areai);
  Self.disconnectors.Reset(areai);
  Self.texts.Reset(areai);
  Self.blockLabels.Reset(areai);
  Self.psts.Reset(areai);
  Self.otherObj.Reset(areai);

  for var i := 0 to Self.areas.Count - 1 do
  begin
    if ((areai < 0) or (i = areai)) then
    begin
      Self.areas[i].tech_rights := TAreaControlRights.null;
      Self.areas[i].dk_blik := false;
      Self.areas[i].stack.Enabled := false;
      Self.areas[i].dk_click_server := false;
      Self.areas[i].RegPlease.status := TAreaRegPleaseStatus.none;
      Self.areas[i].announcement := false;
      Self.areas[i].login := '';
      Self.areas[i].username := '';
    end;
  end;

  Self.show();
  Self.UpdateLoginString();
end;

procedure TRelief.OROsvChange(Sender: string; code: string; state: boolean);
begin
  for var i := 0 to Self.areas.Count - 1 do
    if (Self.areas[i].id = Sender) then
    begin
      for var j := 0 to Self.areas[i].lights.Count - 1 do
        if (Self.areas[i].lights[j].Name = code) then
        begin
          var osv := Self.areas[i].lights.items[j];
          osv.state := state;
          Self.areas[i].lights.items[j] := osv;
        end;
      Exit();
    end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowStacks();
begin
  for var i := 0 to Self.areas.Count - 1 do
    Self.areas[i].stack.show(Self.DrawObject, Self.CursorDraw.Pos);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORStackMsg(Sender: string; data: TStrings);
begin
  for var i := 0 to Self.areas.Count - 1 do
    if (Self.areas[i].id = Sender) then
      Self.areas[i].stack.ParseCommand(data);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TRelief.GetPanelWidth(): SmallInt;
begin
  Result := Self.Graphics.pWidth;
end;

function TRelief.GetPanelHeight(): SmallInt;
begin
  Result := Self.Graphics.pHeight;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ShowInfoTimers();
begin
  for var i := Self.infoTimers.Count - 1 downto 0 do
    if (Self.infoTimers[i].finish < Now) then
      Self.infoTimers.Delete(i);

  for var i := 0 to Min(Self.infoTimers.Count, 2) - 1 do
  begin
    var str := Self.infoTimers[i].str + '  ' + FormatDateTime('nn:ss', Self.infoTimers[i].finish - Now) + ' ';
    Symbols.TextOutput(Point(Self.width - _INFOTIMER_WIDTH, Self.height - i - 1), str, clRed, clWhite,
      Self.DrawObject);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORInfoTimer(id: Integer; time_min: Integer; time_sec: Integer; str: string);
var tmr: TInfoTimer;
begin
  tmr.finish := Now + EncodeTime(0, time_min, time_sec, 0);
  if (Length(str) > _INFOTIMER_TEXT_WIDTH) then
    tmr.str := LeftStr(str, _INFOTIMER_TEXT_WIDTH)
  else
    tmr.str := str;

  // zarovname na pevnou sirku radku
  while (Length(tmr.str) < _INFOTIMER_TEXT_WIDTH) do
    tmr.str := ' ' + tmr.str;

  tmr.id := id;

  Self.infoTimers.Add(tmr);
end;

procedure TRelief.ORInfoTimerRemove(id: Integer);
begin
  for var i := 0 to Self.infoTimers.Count - 1 do
    if (Self.infoTimers[i].id = id) then
    begin
      Self.infoTimers.Delete(i);
      Exit();
    end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORDKClickServer(Sender: string; enable: boolean);
begin
  for var i := 0 to Self.areas.Count - 1 do
    if (Self.areas[i].id = Sender) then
      Self.areas[i].dk_click_server := enable;
end;

/// /////////////////////////////////////////////////////////////////////////////

class function TRelief.GetTechBlk(typ: TBlkType; symbol_index: Integer): TTechBlokToSymbol;
begin
  Result.blk_type := typ;
  Result.symbol_index := symbol_index;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.AddToTechBlk(typ: TBlkType; blok_id: Integer; symbol_index: Integer);
var Symbols: TList<TTechBlokToSymbol>;
begin
  if (blok_id = -1) then
    Exit();

  if (Self.techBlok.ContainsKey(blok_id)) then
    Symbols := Self.techBlok[blok_id]
  else
    Symbols := TList<TTechBlokToSymbol>.Create();

  var val := GetTechBlk(typ, symbol_index);
  if (not Symbols.Contains(val)) then
    Symbols.Add(val);

  Self.techBlok.AddOrSetValue(blok_id, Symbols);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORLokReq(Sender: string; parsed: TStrings);
var area: TAreaPanel;
begin
  area := nil;
  for var i := 0 to Self.areas.Count - 1 do
    if (Self.areas[i].id = Sender) then
    begin
      area := Self.areas[i];
      Break;
    end;
  if (area = nil) then
    Exit();

  parsed[2] := UpperCase(parsed[2]);

  if (parsed[2] = 'REQ') then
  begin
    area.RegPlease.status := TAreaRegPleaseStatus.request;

    // vychozi hodnoty
    area.RegPlease.firstname := '';
    area.RegPlease.lastname := '';
    area.RegPlease.comment := '';

    area.RegPlease.user := parsed[3];
    if (parsed.Count > 4) then
      area.RegPlease.firstname := parsed[4];
    if (parsed.Count > 5) then
      area.RegPlease.lastname := parsed[5];
    if (parsed.Count > 6) then
      area.RegPlease.comment := parsed[6];
  end

  else if (parsed[2] = 'OK') then
  begin
    F_RegReq.ServerResponseOK();
    area.RegPlease.status := TAreaRegPleaseStatus.none;
  end

  else if (parsed[2] = 'ERR') then
  begin
    F_RegReq.ServerResponseErr(parsed[3]);
    area.RegPlease.status := TAreaRegPleaseStatus.none;
  end

  else if (parsed[2] = 'CANCEL') then
  begin
    F_RegReq.ServerCanceled();
    area.RegPlease.status := TAreaRegPleaseStatus.none;
  end

  else if (parsed[2] = 'U-OK') then
  begin
    var HVDb := THVDb.Create;
    HVDb.ParseHVs(parsed[3]);

    F_RegReq.Open(HVDb, area.id, area.RegPlease.user, area.RegPlease.firstname, area.RegPlease.lastname,
      area.RegPlease.comment, true, true, true, false);
  end

  else if (parsed[2] = 'U-ERR') then
  begin
    Self.ORInfoMsg(parsed[3]);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.UpdateSymbolSet();
begin
  Self.CursorDraw.bg := TBitmap.Create();
  Self.CursorDraw.bg.Width := SymbolSet.symbWidth + 2; // +2 kvuli okrajum kurzoru
  Self.CursorDraw.bg.Height := SymbolSet.symbHeight + 2;
  (Self.ParentForm as TF_Main).SetPanelSize(Self.Graphics.pWidth * SymbolSet.symbWidth,
    Self.Graphics.pHeight * SymbolSet.symbHeight);
  Self.show();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.UpdateLoginString();
begin
  if (Assigned(Self.OnLoginUserChange)) then
    Self.OnLoginUserChange(Self, Self.GetLoginString());
end;

function TRelief.GetLoginString(): string;
var res: string;
begin
  if (Self.areas.Count = 0) then
    Exit('-');

  if (Self.areas[0].username = '') then
    res := ''
  else
    res := Self.areas[0].username;

  for var i := 1 to Self.areas.Count - 1 do
    if (res = '-') then
      res := Self.areas[i].username
    else if (Self.areas[i].username <> res) then
      Exit('více uživatelů');

  if (res = '') then
    res := '-';

  Result := res;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TRelief.AnyORWritable(): boolean;
begin
  for var area in Self.areas do
    if (area.tech_rights > TAreaControlRights.read) then
      Exit(true);
  Result := false;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ReAuthorize();
begin
  // pokud je alespon jedno OR pro zapis, odhlasujeme vsechny OR, na kterych je prihlsen uzivatel z prvni OR
  // ciste teoreticky tedy muzeme postupne odhlasovat ruzne uzivatele z jednotlivych OR
  // Tato situace by ale nemela nastavat, k jednomu panelu by mel byt prihlaseny vzdy jen jeden uzivatel,
  // popr. uzivatel v nekolika OR a guest v nekolika dalsich OR.

  if ((PanelTCPClient.status <> TPanelConnectionStatus.opened) or (F_Auth.showing)) then
    Exit();

  if (Self.AnyORWritable()) then
  begin
    if (not GlobConfig.data.guest.allow) then
    begin
      // ucet hosta neni povoleny -> odhlasime uzivatele a zobrazime vyzvu k prihlaseni noveho
      GlobConfig.data.Auth.autoauth := false;
      GlobConfig.data.Auth.username := '';
      GlobConfig.data.Auth.password := '';

      var fors: TIntAr;
      SetLength(fors, Self.areas.Count);
      for var i := 0 to Self.areas.Count - 1 do
      begin
        fors[i] := i;
        Self.areas[i].login := '';
        PanelTCPClient.PanelAuthorise(Self.areas[i].id, TAreaControlRights.null, '', '');
      end;

      F_Auth.OpenForm('Vyžadována autorizace', Self.ORConnectionOpenned_AuthCallback, fors, true);
      Exit();
    end;

    // jdeme prihlasit readera vsude
    Self.reAuth.old_ors.Clear();

    // zjistime si aktualne prihlasene uzivatele a ke kterym OR je prihlasen
    Self.reAuth.old_login := '';
    for var i := 0 to Self.areas.Count - 1 do
    begin
      if ((Self.areas[i].login <> '') and (Self.areas[i].login <> GlobConfig.data.guest.username) and
        (Self.reAuth.old_login = '')) then
        Self.reAuth.old_login := Self.areas[i].login;
      if ((Self.reAuth.old_login <> '') and (Self.reAuth.old_login = Self.areas[i].login) and
        (Self.areas[i].tech_rights >= TAreaControlRights.write)) then
        Self.reAuth.old_ors.Add(i);
    end;

    // vytvorime pole indexu oblasti rizeni pro autorizacni proces
    var fors: TIntAr;
    SetLength(fors, Self.reAuth.old_ors.Count);
    for var i := 0 to Self.reAuth.old_ors.Count - 1 do
      fors[i] := Self.reAuth.old_ors[i];

    // zapomeneme ulozeneho uzivatele
    if ((GlobConfig.data.Auth.autoauth) and (GlobConfig.data.Auth.username = Self.reAuth.old_login)) then
    begin
      GlobConfig.data.Auth.autoauth := false;
      GlobConfig.data.Auth.username := '';
      GlobConfig.data.Auth.password := '';
    end;

    // na OR v seznamu 'Self.reAuth.old_ors' prihlasime hosta
    F_Auth.Listen('Vyžadována autorizace', GlobConfig.data.guest.username, 0, Self.AuthReadCallback, fors, true);
    Self.AuthReadCallback(Self, GlobConfig.data.guest.username, GlobConfig.data.guest.password, fors, false);

    // v pripade povolene IPC odhlasime i zbyle panely
    if (GlobConfig.data.Auth.ipc_send) then
    begin
      IPC.username := GlobConfig.data.guest.username;
      IPC.password := GlobConfig.data.guest.password;
    end;
  end else begin

    if (Self.reAuth.old_ors.Count = 0) then
    begin
      // zadne OR nezapamatovany -> prihlasujeme uzivatele na vsechny OR
      var cnt := GlobConfig.GetAuthNonNullORSCnt();
      if (cnt = 0) then
        Exit();

      // do \ors si priradime vsechna or s zadanym opravnenim > null
      var fors: TIntAr;
      SetLength(fors, cnt);
      var j := 0;
      var rights: TAreaControlRights;
      for var i := 0 to Self.areas.Count - 1 do
        if ((GlobConfig.data.Auth.ors.TryGetValue(Self.areas[i].id, Rights)) and (Rights > TAreaControlRights.null)) then
        begin
          fors[j] := i;
          Inc(j);
        end;

      F_Auth.OpenForm('Vyžadována autorizace', Self.ORConnectionOpenned_AuthCallback, fors, true)
    end else begin
      // OR zapamatovany -> prihlasujeme uzivatele jen na tyto OR

      // vytvorime pole indexu oblasti rizeni pro autorizacni proces
      var fors: TIntAr;
      SetLength(fors, Self.reAuth.old_ors.Count);
      for var i := 0 to Self.reAuth.old_ors.Count - 1 do
        fors[i] := Self.reAuth.old_ors[i];

      // na OR v seznamu 'Self.reAuth.old_ors' prihlasime skutecneho uzivatele
      F_Auth.OpenForm('Vyžadována autorizace', Self.AuthWriteCallback, fors, false, Self.reAuth.old_login);

      Self.reAuth.old_login := '';
      Self.reAuth.old_ors.Clear();
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.IPAAuth();
var rights: TAreaControlRights;
begin
  if (PanelTCPClient.status = TPanelConnectionStatus.opened) then
  begin
    // existujici spojeni -> autorizovat

    // zjistime pocet OR s (zadanym opravnenim > null) nebo (prave autorizovanych)
    var cnt := 0;
    for var i := 0 to Self.areas.Count - 1 do
      if ((not GlobConfig.data.Auth.ors.TryGetValue(Self.areas[i].id, Rights)) or (Rights > TAreaControlRights.null) or
        (Self.areas[i].tech_rights > TAreaControlRights.null)) then
        Inc(cnt);

    // do \ors si priradime vsechna or s (zadanym opravennim > null) nebo (prave autorizovanych)
    var ors: TIntAr;
    SetLength(ors, cnt);
    var j := 0;
    for var i := 0 to Self.areas.Count - 1 do
      if ((not GlobConfig.data.Auth.ors.TryGetValue(Self.areas[i].id, Rights)) or (Rights > TAreaControlRights.null) or
        (Self.areas[i].tech_rights > TAreaControlRights.null)) then
      begin
        ors[j] := i;
        Inc(j);
      end;

    Self.ORConnectionOpenned_AuthCallback(Self, GlobConfig.data.Auth.username, GlobConfig.data.Auth.password,
      ors, false);
  end else begin
    // nove spojeni -> pripojit
    try
      PanelTCPClient.Connect(GlobConfig.data.server.host, GlobConfig.data.server.port);
      PanelTCPClient.openned_by_ipc := true;
    except

    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.AuthReadCallback(Sender: TObject; username: string; password: string; ors: TIntAr; guest: boolean);
begin
  for var i := 0 to Length(ors) - 1 do
  begin
    Self.areas[ors[i]].login := username;
    PanelTCPClient.PanelAuthorise(Self.areas[ors[i]].id, read, username, password);
  end;
end;

procedure TRelief.AuthWriteCallback(Sender: TObject; username: string; password: string; ors: TIntAr; guest: boolean);
begin
  for var i := 0 to Length(ors) - 1 do
  begin
    Self.areas[ors[i]].login := username;
    PanelTCPClient.PanelAuthorise(Self.areas[ors[i]].id, write, username, password);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.ORHlaseniMsg(Sender: string; data: TStrings);
var areai: Integer;
begin
  areai := -1;
  for var i := 0 to Self.areas.Count - 1 do
    if (Self.areas[i].id = Sender) then
    begin
      areai := i;
      Break;
    end;

  if (areai = -1) then
    Exit();
  if (data.Count < 3) then
    Exit();

  data[2] := UpperCase(data[2]);
  if ((data[2] = 'AVAILABLE') and (data.Count > 3)) then
  begin
    Self.areas[areai].announcement := (data[3] = '1');

    if (Self.dkRootMenuItem = 'DK') then
      Self.ShowDKMenu(areai);
    if ((Self.dkRootMenuItem = 'HLASENI') and (not Self.areas[areai].announcement)) then
      Self.HideMenu();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.SetShowDetails(show: boolean);
begin
  if (Self.fShowDetails = show) then
    Exit();
  Self.fShowDetails := show;
  Self.show();
end;

/// /////////////////////////////////////////////////////////////////////////////

class function TRelief.FileSupportedVersionsStr(): string;
begin
  Result := '';
  for var i := 0 to Length(_FileVersion_accept) - 1 do
    Result := Result + _FileVersion_accept[i] + ', ';
  Result := LeftStr(Result, Length(Result) - 2);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRelief.UpdateEnabled();
begin
  Self.Enabled := ((Errors.Count = 0) and (not Self.UPO.showing) and (F_PotvrSekv.EndReason <> TPSEnd.prubeh));
end;

/// /////////////////////////////////////////////////////////////////////////////

function TRelief.GetArea(id: string): TAreaPanel;
var i: Integer;
begin
  i := Self.GetAreaIndex(id);
  if (i = -1) then
    Exit(nil);
  Result := Self.areas[i];
end;

function TRelief.GetAreaIndex(id: string): Integer;
begin
  for var i := 0 to Self.areas.Count - 1 do
    if (Self.areas[i].id = id) then
      Exit(i);
  Result := -1;
end;

end.// unit
