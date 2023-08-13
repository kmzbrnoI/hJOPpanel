unit BlockTrack;

{
  Definice bloku usek.
  Sem patri pouze definice bloku, nikoliv definice databaze useku
  (kvuli pouzivani v jinych unitach).
}

interface

uses Classes, Graphics, Types, Generics.Collections, Symbols, SysUtils,
  BlockTypes, PanelOR, DXDraws, Math;

const
  _JC_END: array [0 .. 3] of TColor = (TJopColor.black, TJopColor.greenDark, TJopColor.white, TJopColor.turqDark);

type
  TTrackTrain = record
    name: string;
    arrowL, arrowS: boolean;
    fg, bg, border: TColor;
    posindex: Integer; // index pozice, na ktere je umistena tato konkretni souprava
    flash: Boolean;
  end;

  TTrackPanelProp = class
    flash: boolean;
    fg, bg, notColorBranches: TColor;
    jcend: TJCType;
    trains: TList<TTrackTrain>;

    constructor Create();
    destructor Destroy(); override;
    procedure Change(parsed: TStrings);
    procedure InitDefault();
    procedure InitUA();
  end;

  // usek rozdeleny na vetve je reprezentovan takto:

  // ukoncovaci element vetve = vyhybka
  TBranchEnd = record
    turnout: Integer; // pokud usek nema vyhybky -> vyh1 = -1, vyh2 = -1 (nastava u useku bez vyhybky a u koncovych vetvi)
    // referuje na index v poli vyhybek (nikoliv na technologicke ID vyhybky!)
    // kazda vetev je ukoncena maximalne 2-ma vyhybkama - koren muze byt ukoncen 2-ma vyhybkama, pak jen jedna
    ref_plus, ref_minus: Integer; // reference  na vetev, kterou se pokracuje, pokud je vyh v poloze + resp. poloze -
    // posledni vetev resp. usek bez vyhybky ma obe reference = -1
  end;

  TTrackBranch = record // vetev useku

    node1: TBranchEnd; // reference na 1. vyhybku, ktera ukoncuje tuto vetev
    node2: TBranchEnd; // reference na 2. vyhybku, ktera ukoncuje tuto vetev
    visible: boolean; // pokud je vetve viditelna, je zde true; jinak false

    symbols: TList<TReliefSym>;
  end;

  TDKSType = (dksNone = 0, dksTop = 1, dksBottom = 2);

  // 1 usek na reliefu
  TPTrack = class
    block: Integer;

    area: Integer;
    panelProp: TTrackPanelProp;
    root: TPoint;
    DKStype: TDKSType;

    symbols: TList<TReliefSym>;
    JCClick: TList<TPoint>;
    labels: TList<TPoint>;
    trains: TList<TPoint>; // je zaruceno, ze tento seznam je usporadany v lichem smeru (resi se pri nacitani souboru)
    name: string;

    branches: TList<TTrackBranch>; // vetve useku
    // vetev 0 je vzdy koren
    // zde je ulozen binarni strom v pseudo-forme
    // na 0. indexu je koren, kazdy vrchol pak obsahuje referenci na jeho deti


    // program si duplikuje ulozena data - po rozdeleni useku na vetve uklada usek jak nerozdeleny tak rozdeleny

    constructor Create();
    destructor Destroy(); override;

    function TrainPaintsOnRailNum(): boolean;
    procedure Reset();

    procedure PaintTrain(pos: TPoint; spri: Integer; myORs: TList<TAreaPanel>; obj: TDXDraw; blik: boolean;
      bgZaver: boolean = false);
    procedure ShowTrains(obj: TDXDraw; blik: boolean; myORs: TList<TAreaPanel>);
    procedure PaintTrackName(pos: TPoint; obj: TDXDraw; hidden: boolean);
    procedure AddSymbolFromCrossing(pos: TPoint);
    procedure RemoveSymbolFromCrossing(pos: TPoint);

    function IsSecondCross(): boolean;
    function SecondCrossPos(): TPoint;
    function GetBranch(pos: TPoint): Integer;
    function Detected(): boolean;
    class function SymbolIndex(pos: TPoint; Symbols: TList<TReliefSym>): Integer;
    procedure DrawTrackSymbol(pos: TPoint; symbol: Integer; fg: TColor; bg: TColor; obj: TDXDraw);
    procedure ShowDKSCross(pos: TPoint; obj: TDXDraw; leftCross, rightCross: boolean; dksType: TDKSType; fg: TColor;
      usek: TPTrack);
    function IsPos(pos: TPoint): Boolean;

  end;

function InvDKSType(dks: TDKSType): TDKSType;

implementation

uses parseHelper, RPConst;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPTrack.Create();
begin
  inherited;
  Self.panelProp := TTrackPanelProp.Create();
end;

destructor TPTrack.Destroy();
begin
  for var branch in Self.branches do
    branch.Symbols.Free();

  Self.panelProp.Free();
  Self.symbols.Free();
  Self.JCClick.Free();
  Self.labels.Free();
  Self.trains.Free();
  Self.branches.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTrack.TrainPaintsOnRailNum(): boolean;
begin
  Result := (Self.trains.Count = 1) and (Self.labels.Count > 0) and
    ((Self.trains[0].X = Self.labels[0].X) and (Self.trains[0].Y = Self.labels[0].Y));
end;

procedure TPTrack.Reset();
begin
  Self.panelProp.trains.Clear();
  if (Self.block > -2) then
    Self.panelProp.InitDefault()
  else
    Self.panelProp.InitUA();
end;

/// /////////////////////////////////////////////////////////////////////////////

// vykresleni soupravy na dane pozici
procedure TPTrack.PaintTrain(pos: TPoint; spri: Integer; myORs: TList<TAreaPanel>; obj: TDXDraw; blik: boolean;
  bgZaver: boolean = false);
var fg, bg: TColor;
  arrowLeft, arrowRight: boolean;
  train: TTrackTrain;
begin
  train := Self.panelProp.trains[spri];
  pos := Point(pos.X - (Length(train.name) div 2), pos.Y);

  fg := train.fg;

  // urceni barvy
  if (myORs[Self.area].RegPlease.status = TAreaRegPleaseStatus.selected) then
  begin
    if (blik) then
    begin
      fg := clBlack;
      bg := Self.panelProp.bg;
    end else
      bg := TJopColor.yellow;
  end else if ((bgZaver) and (Self.panelProp.jcend > TJCType.no)) then
    bg := _JC_END[Integer(Self.panelProp.jcend)]
  else
    bg := train.bg;

  if ((train.flash) and (blik)) then
    Exit();

  TextOutput(pos, train.name, fg, bg, obj, true);

  arrowLeft := (((train.arrowL) and (myORs[Self.area].orientation = aoOddRightToLeft)) or
    ((train.arrowS) and (myORs[Self.area].orientation = aoOddLeftToRight)));

  arrowRight := (((train.arrowS) and (myORs[Self.area].orientation = aoOddRightToLeft)) or
    ((train.arrowL) and (myORs[Self.area].orientation = aoOddLeftToRight)));

  // show border around train number
  if (train.border <> clBlack) then
  begin
    obj.Surface.Canvas.Pen.Mode := pmMerge;
    obj.Surface.Canvas.Pen.Color := train.border;
    obj.Surface.Canvas.Brush.Color := clBlack;
    obj.Surface.Canvas.Rectangle(pos.X * SymbolSet.symbWidth, pos.Y * SymbolSet.symbHeight,
      (pos.X + Length(train.name)) * SymbolSet.symbWidth, (pos.Y + 1) * SymbolSet.symbHeight);
    obj.Surface.Canvas.Pen.Mode := pmCopy;
  end;

  if (fg = clBlack) then
    fg := bg;

  if (arrowLeft) then
    Draw(SymbolSet.IL_Symbols, Point(pos.X, pos.Y - 1), _S_TRAIN_ARROW_L, fg, clNone, obj, true);
  if (arrowRight) then
    Draw(SymbolSet.IL_Symbols, Point(pos.X + Length(train.name) - 1, pos.Y - 1), _S_TRAIN_ARROW_R, fg,
      clNone, obj, true);

  if ((arrowLeft) or (arrowRight)) then
  begin
    // vykresleni sipky
    obj.Surface.Canvas.Pen.Color := fg;
    obj.Surface.Canvas.MoveTo(pos.X * SymbolSet.symbWidth, pos.Y * SymbolSet.symbHeight - 1);
    obj.Surface.Canvas.LineTo((pos.X + Length(train.name)) * SymbolSet.symbWidth,
      pos.Y * SymbolSet.symbHeight - 1);
  end; // if sipkaLeft or sipkaRight
end;

/// /////////////////////////////////////////////////////////////////////////////

// vykresleni cisla koleje
procedure TPTrack.PaintTrackName(pos: TPoint; obj: TDXDraw; hidden: boolean);
var left: TPoint;
  fg: TColor;
begin
  left := Point(pos.X - (Length(Self.name) div 2), pos.Y);

  if (hidden) then
    fg := clBlack
  else
    fg := Self.panelProp.fg;

  if (Self.panelProp.jcend = TJCType.no) then
    TextOutput(left, Self.name, fg, Self.panelProp.bg, obj)
  else
    TextOutput(left, Self.name, fg, _JC_END[Integer(Self.panelProp.jcend)], obj);
end;

/// /////////////////////////////////////////////////////////////////////////////
// zobrazi soupravy na celem useku

procedure TPTrack.ShowTrains(obj: TDXDraw; blik: boolean; myORs: TList<TAreaPanel>);
begin
  // Posindex neni potreba mazat, protoze se vzdy se zmenou stavu bloku
  // prepisuje automaticky na -1.

  if ((Self.panelProp.trains.Count = 0) or (Self.trains.Count = 0)) then
    Exit()

  else if (Self.panelProp.trains.Count = 1) then
  begin
    Self.PaintTrain(Self.trains[Self.trains.Count div 2], 0, myORs, obj, blik, Self.TrainPaintsOnRailNum());

    if (Self.panelProp.trains[0].posindex <> 0) then
    begin
      var s := Self.panelProp.trains[0];
      s.posindex := Self.trains.Count div 2;
      Self.panelProp.trains[0] := s;
    end;

  end else begin
    // vsechny soupravy, ktere se vejdou, krome posledni
    var index: Integer := 0;
    var step: Integer := Max(Self.trains.Count div Self.panelProp.trains.Count, 1);
    for var i := 0 to Min(Self.trains.Count, Self.panelProp.trains.Count) - 2 do
    begin
      Self.PaintTrain(Self.trains[index], i, myORs, obj, blik);

      if (Self.panelProp.trains[i].posindex <> index) then
      begin
        var s := Self.panelProp.trains[i];
        s.posindex := index;
        Self.panelProp.trains[i] := s;
      end;

      index := index + step;
    end;

    // posledni souprava na posledni pozici
    if (Self.trains.Count > 0) then
    begin
      Self.PaintTrain(Self.trains[Self.trains.Count - 1], Self.panelProp.trains.Count - 1, myORs, obj, blik);

      if (Self.panelProp.trains[Self.panelProp.trains.Count - 1].posindex <> Self.trains.Count - 1) then
      begin
        var s := Self.panelProp.trains[Self.panelProp.trains.Count - 1];
        s.posindex := Self.trains.Count - 1;
        Self.panelProp.trains[Self.panelProp.trains.Count - 1] := s;
      end;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TTrackPanelProp.Create();
begin
  inherited;
  Self.InitDefault();
  Self.trains := TList<TTrackTrain>.Create();
end;

destructor TTrackPanelProp.Destroy();
begin
  Self.trains.Free();
  inherited;
end;

procedure TTrackPanelProp.InitDefault();
begin
  Self.flash := false;
  Self.fg := clFuchsia;
  Self.bg := clBlack;
  Self.notColorBranches := TJopColor.grayDark;
  Self.jcend := no;
end;

procedure TTrackPanelProp.InitUA();
begin
  Self.flash := false;
  Self.fg := TJopColor.grayDark;
  Self.bg := clBlack;
  Self.notColorBranches := TJopColor.grayDark;
  Self.jcend := no;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TTrackPanelProp.Change(parsed: TStrings);
begin
  fg := StrToColor(parsed[4]);
  bg := StrToColor(parsed[5]);
  flash := StrToBool(parsed[6]);
  jcend := TJCType(StrToInt(parsed[7]));
  notColorBranches := StrToColor(parsed[8]);

  Self.trains.Clear();

  if (parsed.Count > 9) then
  begin
    var trains: TStrings := TStringList.Create();
    var train: TStrings := TStringList.Create();

    try
      ExtractStringsEx([')'], ['('], parsed[9], trains);

      for var i := 0 to trains.Count - 1 do
      begin
        train.Clear();
        ExtractStringsEx([';'], [], trains[i], train);

        var us: TTrackTrain;
        us.name := train[0];
        us.arrowL := ((train[1] <> '') and (train[1][1] = '1'));
        us.arrowS := ((train[1] <> '') and (train[1][2] = '1'));
        us.fg := StrToColor(train[2]);
        us.bg := StrToColor(train[3]);
        us.posindex := -1;

        if ((train.Count > 4) and (train[4] <> '-')) then
          us.border := StrToColor(train[4])
        else
          us.border := clBlack;

        if (train.Count > 5) then
          us.flash := RPConst.StrToBool(train[5])
        else
          us.flash := false;

        Self.trains.Add(us);
      end;

    finally
      trains.Free();
      train.Free();
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTrack.IsSecondCross(): boolean;
begin
  Result := (Self.branches[0].node1.ref_minus <> -1) or (Self.branches[1].node1.ref_minus <> -1);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTrack.SecondCrossPos(): TPoint;
begin
  if (Self.DKStype = dksTop) then
    Result := Point(Self.root.X, Self.root.Y + 1)
  else if (Self.DKStype = dksBottom) then
    Result := Point(Self.root.X, Self.root.Y - 1)
  else
    raise Exception.Create('No DKS -> no second cross pos!');
end;

/// /////////////////////////////////////////////////////////////////////////////

function InvDKSType(dks: TDKSType): TDKSType;
begin
  case (dks) of
    TDKSType.dksTop:
      Result := dksBottom;
    TDKSType.dksBottom:
      Result := dksTop;
  else
    Result := dksNone;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTrack.AddSymbolFromCrossing(pos: TPoint);
var sym: TReliefSym;
begin
  sym.Position := pos;
  sym.SymbolID := _S_TRACK_DET_B;

  if (Self.branches.Count > 0) then
  begin
    var branchi := Self.GetBranch(Point(pos.X - 1, pos.Y));
    if (branchi > -1) then
      if (SymbolIndex(pos, Self.branches[branchi].Symbols) = -1) then
        Self.branches[branchi].Symbols.Add(sym);

  end else begin
    if (Self.SymbolIndex(pos, Self.symbols) = -1) then
      Self.symbols.Add(sym);
  end;
end;

procedure TPTrack.RemoveSymbolFromCrossing(pos: TPoint);
begin
  if (Self.branches.Count > 0) then
  begin
    var branchi := Self.GetBranch(Point(pos.X - 1, pos.Y));
    if (branchi > -1) then
    begin
      var symboli := SymbolIndex(pos, Self.branches[branchi].Symbols);
      if (symboli > -1) then
        Self.branches[branchi].Symbols.Delete(symboli);
    end;
  end else begin
    var symboli := Self.SymbolIndex(pos, Self.symbols);
    if (symboli > -1) then
      Self.symbols.Delete(symboli);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTrack.GetBranch(pos: TPoint): Integer;
begin
  for var branchi := 0 to Self.branches.Count - 1 do
  begin
    for var i := 0 to Self.branches[branchi].Symbols.Count - 1 do
      if ((Self.branches[branchi].Symbols[i].Position.X = pos.X) and (Self.branches[branchi].Symbols[i].Position.Y = pos.Y))
      then
        Exit(branchi);
  end;
  Result := -1;
end;

/// /////////////////////////////////////////////////////////////////////////////

class function TPTrack.SymbolIndex(pos: TPoint; Symbols: TList<TReliefSym>): Integer;
begin
  for var i := 0 to Symbols.Count - 1 do
    if ((Symbols[i].Position.X = pos.X) and (Symbols[i].Position.Y = pos.Y)) then
      Exit(i);
  Result := -1;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTrack.Detected(): boolean;
begin
  if (Self.symbols.Count < 1) then
    Exit(false);
  Result := (Self.symbols[0].SymbolID >= _S_TRACK_DET_B) and (Self.symbols[0].SymbolID <= _S_TRACK_DET_E);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTrack.DrawTrackSymbol(pos: TPoint; symbol: Integer; fg: TColor; bg: TColor; obj: TDXDraw);
begin
  if ((symbol >= _S_TRACK_DET_B) and (symbol <= _S_TRACK_DET_E)) then
    symbol := symbol - _S_TRACK_DET_B;
  if ((symbol >= _S_TRACK_NODET_B) and (symbol <= _S_TRACK_NODET_E)) then
    symbol := symbol - _S_TRACK_NODET_B;

  if (Self.Detected()) then
    symbol := symbol + _S_TRACK_DET_B
  else
    symbol := symbol + _S_TRACK_NODET_B;

  Draw(SymbolSet.IL_Symbols, pos, symbol,fg, bg, obj);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTrack.ShowDKSCross(pos: TPoint; obj: TDXDraw; leftCross, rightCross: boolean; dksType: TDKSType; fg: TColor;
  usek: TPTrack);
begin
  if (dksType = dksTop) then
  begin
    if ((leftCross) and (rightCross)) then
      Self.DrawTrackSymbol(pos, _S_DKS_DET_TOP, fg, usek.panelProp.bg, obj)
    else if (leftCross) then
      Self.DrawTrackSymbol(pos, _S_TRACK_DET_B + 4, fg, usek.panelProp.bg, obj)
    else if (rightCross) then
      Self.DrawTrackSymbol(pos, _S_TRACK_DET_B + 2, fg, usek.panelProp.bg, obj)
    else
      Self.DrawTrackSymbol(pos, _S_DKS_DET_TOP, usek.panelProp.notColorBranches, usek.panelProp.bg, obj)
  end else begin
    if ((leftCross) and (rightCross)) then
      Self.DrawTrackSymbol(pos, _S_DKS_DET_BOT, fg, usek.panelProp.bg, obj)
    else if (leftCross) then
      Self.DrawTrackSymbol(pos, _S_TRACK_DET_B + 3, fg, usek.panelProp.bg, obj)
    else if (rightCross) then
      Self.DrawTrackSymbol(pos, _S_TRACK_DET_B + 5, fg, usek.panelProp.bg, obj)
    else
      Self.DrawTrackSymbol(pos, _S_DKS_DET_BOT, usek.panelProp.notColorBranches, usek.panelProp.bg, obj)
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTrack.IsPos(pos: TPoint): Boolean;
begin
  for var branch: TTrackBranch in Self.branches do
    for var sym: TReliefSym in branch.symbols do
      if (sym.Position = pos) then
        Exit(True);

  for var sym: TReliefSym in Self.symbols do
    if (sym.Position = pos) then
      Exit(True);

  Result := False;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
