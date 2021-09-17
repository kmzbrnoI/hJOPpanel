unit BlocksTrack;

{
  Definition of a databse of tracks.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  Symbols, PanelOR, StrUtils, BlockSignal, BlockTurnout, BlockTrack;

type
  TPTrackId = record
    index: Integer;
    traini: Integer;
  end;

  TPTracks = class
  private
    function GetItem(index: Integer): TPTrack;
    function GetCount(): Integer;

    procedure ShowBranches(track: TPTrack; vetevI: Integer; visible: boolean; var showed: array of boolean;
      myORs: TList<TAreaPanel>; flash: boolean; obj: TDXDraw; startJC: TList<TStartJC>; turnouts: TList<TPTurnout>);
    procedure ShowDKSBranches(track: TPTrack; visible: boolean; var showed: array of boolean; myORs: TList<TAreaPanel>;
      flash: boolean; obj: TDXDraw; startJC: TList<TStartJC>; turnouts: TList<TPTurnout>);

  public

    data: TObjectList<TPTrack>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; myORs: TList<TAreaPanel>; version: Word);
    procedure Show(obj: TDXDraw; flash: boolean; myORs: TList<TAreaPanel>; startJC: TList<TStartJC>;
      turnouts: TList<TPTurnout>);
    function GetIndex(pos: TPoint): TPTrackId;
    procedure Reset(orindex: Integer = -1);
    function GetTrack(tech_id: Integer): Integer;

    property Items[index: Integer]: TPTrack read GetItem; default;
    property Count: Integer read GetCount;
  end;

implementation

uses ParseHelper, Panel;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPTracks.Create();
begin
  inherited;
  Self.data := TObjectList<TPTrack>.Create();
end;

destructor TPTracks.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTracks.Load(ini: TMemIniFile; myORs: TList<TAreaPanel>; version: Word);
begin
  var count := ini.ReadInteger('P', 'U', 0);
  for var i := 0 to count - 1 do
  begin
    var track := TPTrack.Create();

    track.block := ini.ReadInteger('U' + IntToStr(i), 'B', -1);
    track.area := ini.ReadInteger('U' + IntToStr(i), 'OR', -1);
    track.root := GetPos(ini.ReadString('U' + IntToStr(i), 'R', '-1;-1'));
    track.dksType := TDKSType(ini.ReadInteger('U' + IntToStr(i), 'DKS', Integer(dksNone)));

    track.symbols := TList<TReliefSym>.Create();
    var obj := ini.ReadString('U' + IntToStr(i), 'S', '');
    for var j := 0 to (Length(obj) div 8) - 1 do
    begin
      try
        var symbol: TReliefSym;
        symbol.Position.X := StrToInt(copy(obj, j * 8 + 1, 3));
        symbol.Position.Y := StrToInt(copy(obj, j * 8 + 4, 3));
        symbol.SymbolID := StrToInt(copy(obj, j * 8 + 7, 2));
        if (version < _FILEVERSION_20) then
          symbol.SymbolID := TranscodeSymbolFromBpnlV3(symbol.SymbolID);
        track.symbols.Add(symbol);
      except
        continue;
      end;
    end;

    track.JCClick := TList<TPoint>.Create();
    obj := ini.ReadString('U' + IntToStr(i), 'C', '');
    for var j := 0 to (Length(obj) div 6) - 1 do
    begin
      try
        var pos: TPoint;
        pos.X := StrToInt(copy(obj, j * 6 + 1, 3));
        pos.Y := StrToInt(copy(obj, j * 6 + 4, 3));
        track.JCClick.Add(pos);
      except
        continue;
      end;
    end;

    obj := ini.ReadString('U' + IntToStr(i), 'P', '');
    track.labels := TList<TPoint>.Create();
    for var j := 0 to (Length(obj) div 6) - 1 do
    begin
      try
        var pos: TPoint;
        pos.X := StrToIntDef(copy(obj, j * 6 + 1, 3), 0);
        pos.Y := StrToIntDef(copy(obj, j * 6 + 4, 3), 0);
        track.labels.Add(pos);
      except
        continue;
      end;
    end;

    track.name := ini.ReadString('U' + IntToStr(i), 'N', '');

    obj := ini.ReadString('U' + IntToStr(i), 'Spr', '');
    track.trains := TList<TPoint>.Create();
    for var j := 0 to (Length(obj) div 6) - 1 do
    begin
      try
        var pos: TPoint;
        pos.X := StrToIntDef(copy(obj, j * 6 + 1, 3), 0);
        pos.Y := StrToIntDef(copy(obj, j * 6 + 4, 3), 0);
        track.trains.Add(pos);
      except
        continue;
      end;
    end;

    // usporadame seznam souprav podle licheho smeru
    if (myORs[track.area].orientation = aoOddRightToLeft) then
      track.trains.Reverse();

    // pokud nejsou pozice na soupravu, kreslime soupravu na cislo koleje
    if ((track.trains.Count = 0) and (track.name <> '') and (track.labels.Count <> 0)) then
      track.trains.Add(track.labels[0]);

    // nacitani vetvi:
    track.branches := TList<TTrackBranch>.Create();
    var count2 := ini.ReadInteger('U' + IntToStr(i), 'VC', 0);
    for var j := 0 to count2 - 1 do
    begin
      var branch: TTrackBranch;
      obj := ini.ReadString('U' + IntToStr(i), 'V' + IntToStr(j), '');

      branch.Symbols := TList<TReliefSym>.Create();
      branch.node1.turnout := StrToIntDef(copy(obj, 0, 3), 0);
      branch.node1.ref_plus := StrToIntDef(copy(obj, 4, 2), 0);
      branch.node1.ref_minus := StrToIntDef(copy(obj, 6, 2), 0);

      branch.node2.turnout := StrToIntDef(copy(obj, 8, 3), 0);
      branch.node2.ref_plus := StrToIntDef(copy(obj, 11, 2), 0);
      branch.node2.ref_minus := StrToIntDef(copy(obj, 13, 2), 0);

      obj := RightStr(obj, Length(obj) - 14);
      var count3 := Length(obj) div 9;
      for var k := 0 to count3 - 1 do
      begin
        var symbol: TReliefSym;
        symbol.Position.X := StrToIntDef(copy(obj, 9 * k + 1, 3), 0);
        symbol.Position.Y := StrToIntDef(copy(obj, (9 * k + 4), 3), 0);
        symbol.SymbolID := StrToIntDef(copy(obj, (9 * k + 7), 3), 0);
        if (version < _FILEVERSION_20) then
          symbol.SymbolID := TranscodeSymbolFromBpnlV3(symbol.SymbolID);
        branch.symbols.Add(symbol);
      end;

      track.branches.Add(branch);
    end;

    // default settings:
    if (track.block = -2) then
      track.panelProp.InitUA()
    else
      track.panelProp.InitDefault();

    track.panelProp.trains := TList<TTrackTrain>.Create();

    Self.data.Add(track);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTracks.GetIndex(pos: TPoint): TPTrackId;
begin
  Result.index := -1;

  for var i := 0 to Self.data.Count - 1 do
    for var j := 0 to Self.data[i].symbols.Count - 1 do
      if ((pos.X = Self.data[i].symbols[j].Position.X) and (pos.Y = Self.data[i].symbols[j].Position.Y)) then
      begin
        Result.index := i;
        Break;
      end;

  if (Result.index = -1) then
    Exit();
  Result.traini := -1;

  // zjisteni indexu soupravy
  for var i := 0 to Self.data[Result.index].panelProp.trains.Count - 1 do
  begin
    var us := Self.data[Result.index].panelProp.trains[i];

    if (us.posindex < 0) then
      continue;

    if ((pos.X >= Self.data[Result.index].trains[us.posindex].X - (Length(us.name) div 2)) and
      (pos.X < Self.data[Result.index].trains[us.posindex].X + (Length(us.name) div 2) + (Length(us.name) mod 2)))
    then
    begin
      Result.traini := i;
      Exit();
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTracks.Reset(orindex: Integer = -1);
begin
  for var track in Self.data do
    if ((orindex < 0) or (track.area = orindex)) then
      track.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTracks.Show(obj: TDXDraw; flash: boolean; myORs: TList<TAreaPanel>; startJC: TList<TStartJC>;
  turnouts: TList<TPTurnout>);
var fg: TColor;
    showed: array of Boolean;
begin
  for var track in Self.data do
  begin
    // vykresleni symbolu useku

    if (((track.panelProp.flash) or ((track.panelProp.trains.Count > 0) and
      (myORs[track.area].RegPlease.status = TAreaRegPleaseStatus.selected))) and (flash)) then
      fg := clBlack
    else
      fg := track.panelProp.fg;

    if ((track.branches.Count = 0) or (track.panelProp.fg = clFuchsia)) then
    begin
      // pokud nejsou vetve, nebo je usek disabled, vykresim ho cely (bez ohledu na vetve)
      for var sym in track.symbols do
      begin
        var bg := track.panelProp.bg;

        for var sjc in startJC do
          if ((sjc.pos.X = sym.Position.X) and (sjc.pos.Y = sym.Position.Y)) then
            bg := sjc.Color;

        for var k := 0 to track.JCClick.Count - 1 do
          if ((track.JCClick[k].X = sym.Position.X) and (track.JCClick[k].Y = sym.Position.Y)) then
            if (Integer(track.panelProp.jcend) > 0) then
              bg := _JC_END[Integer(track.panelProp.jcend)];

        Symbols.Draw(SymbolSet.IL_Symbols, sym.Position, sym.SymbolID, fg, bg, obj);
      end;

    end else begin
      SetLength(showed, track.branches.Count);
      for var j := 0 to track.branches.Count - 1 do
        showed[j] := false;

      // pokud jsou vetve a usek neni disabled, kreslim vetve
      if (track.dksType <> dksNone) then
        ShowDKSBranches(track, true, showed, myORs, flash, obj, startJC, turnouts)
      else
        ShowBranches(track, 0, true, showed, myORs, flash, obj, startJC, turnouts);
    end;

    // vykresleni cisla koleje
    // kdyz by mela cislo koleje prekryt souprava, nevykreslovat cislo koleje
    // (cislo soupravy muze byt kratsi nez cislo koleje)
    if ((track.trains.Count > 0) and (track.labels.Count > 0)) then
    begin
      if (track.TrainPaintsOnRailNum() and (track.panelProp.trains.Count > 0)) then
      begin
        for var j := 1 to track.labels.Count - 1 do // na nulte pozici je cislo soupravy
          track.PaintTrackName(track.labels[j], obj, fg = clBlack);
      end else begin
        for var p in track.labels do
          track.PaintTrackName(p, obj, fg = clBlack);
      end;
    end;

    track.ShowTrains(obj, flash, myORs);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

// Rekurzivne kresli vetve bezneho bloku
procedure TPTracks.ShowBranches(track: TPTrack; vetevI: Integer; visible: boolean; var showed: array of boolean;
  myORs: TList<TAreaPanel>; flash: boolean; obj: TDXDraw; startJC: TList<TStartJC>; turnouts: TList<TPTurnout>);
var fg: TColor;
begin
  if (vetevI < 0) then
    Exit();
  if (showed[vetevI]) then
    Exit();
  showed[vetevI] := true;
  var branch := track.branches[vetevI];

  branch.visible := visible;
  track.branches[vetevI] := branch;

  if (((track.panelProp.flash) or ((track.panelProp.trains.Count > 0) and
    (myORs[track.area].RegPlease.status = TAreaRegPleaseStatus.selected))) and (flash) and (visible)) then
    fg := clBlack
  else
  begin
    if (visible) then
      fg := track.panelProp.fg
    else
      fg := track.panelProp.notColorBranches;
  end;

  var bg := track.panelProp.bg;

  for var symbol in branch.Symbols do
  begin
    if ((symbol.SymbolID < _S_TRACK_DET_B) and (symbol.SymbolID > _S_TRACK_NODET_E)) then
      continue; // tato situace nastava v pripade vykolejek

    bg := track.panelProp.bg;

    for var sjc in startJC do
      if ((sjc.pos.X = symbol.Position.X) and (sjc.pos.Y = symbol.Position.Y)) then
        bg := sjc.Color;

    for var p in track.JCClick do
      if ((p.X = symbol.Position.X) and (p.Y = symbol.Position.Y)) then
        if (Integer(track.panelProp.jcend) > 0) then
          bg := _JC_END[Integer(track.panelProp.jcend)];

    Symbols.Draw(SymbolSet.IL_Symbols, symbol.Position, symbol.SymbolID, fg, bg, obj);
  end;

  if (branch.node1.turnout > -1) then
  begin
    var turnout := turnouts[branch.node1.turnout];
    turnout.visible := visible;

    // nastaveni barvy neprirazene turnoutybky
    if (turnout.block = -2) then
    begin
      turnout.panelProp.fg := fg;
      turnout.panelProp.bg := bg;
    end;

    case (turnout.panelProp.position) of
      TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:
        begin
          ShowBranches(track, branch.node1.ref_plus, visible, showed, myORs, flash, obj, startJC, turnouts);
          ShowBranches(track, branch.node1.ref_minus, visible, showed, myORs, flash, obj, startJC, turnouts);
        end; // case disable, both, none

      TVyhPoloha.plus, TVyhPoloha.minus:
        begin
          if ((Integer(turnout.panelProp.position) xor turnout.orientationPlus) = 0) then
          begin
            ShowBranches(track, branch.node1.ref_plus, visible, showed, myORs, flash, obj, startJC, turnouts);
            ShowBranches(track, branch.node1.ref_minus, false, showed, myORs, flash, obj, startJC, turnouts);
          end else begin
            ShowBranches(track, branch.node1.ref_plus, false, showed, myORs, flash, obj, startJC, turnouts);
            ShowBranches(track, branch.node1.ref_minus, visible, showed, myORs, flash, obj, startJC, turnouts);
          end;
        end; // case disable, both, none
    end; // case
  end;

  if (branch.node2.turnout > -1) then
  begin
    var turnout := turnouts[branch.node2.turnout];
    turnout.visible := visible;

    // nastaveni barvy neprirazene vyhybky
    if (turnout.block = -2) then
    begin
      turnout.panelProp.fg := fg;
      turnout.panelProp.bg := bg;
    end;

    case (turnout.panelProp.position) of
      TVyhPoloha.disabled, TVyhPoloha.both, TVyhPoloha.none:
        begin
          ShowBranches(track, branch.node2.ref_plus, visible, showed, myORs, flash, obj, startJC, turnouts);
          ShowBranches(track, branch.node2.ref_minus, visible, showed, myORs, flash, obj, startJC, turnouts);
        end; // case disable, both, none

      TVyhPoloha.plus, TVyhPoloha.minus:
        begin
          if ((Integer(turnout.panelProp.position) xor turnout.orientationPlus) = 0) then
          begin
            ShowBranches(track, branch.node2.ref_plus, visible, showed, myORs, flash, obj, startJC, turnouts);
            ShowBranches(track, branch.node2.ref_minus, false, showed, myORs, flash, obj, startJC, turnouts);
          end else begin
            ShowBranches(track, branch.node2.ref_plus, false, showed, myORs, flash, obj, startJC, turnouts);
            ShowBranches(track, branch.node2.ref_minus, visible, showed, myORs, flash, obj, startJC, turnouts);
          end;
        end; // case disable, both, none
    end; // case
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

// Zobrazuje vetve bloku, ktery je dvojita kolejova spojka.
procedure TPTracks.ShowDKSBranches(track: TPTrack; visible: boolean; var showed: array of boolean; myORs: TList<TAreaPanel>;
  flash: boolean; obj: TDXDraw; startJC: TList<TStartJC>; turnouts: TList<TPTurnout>);
begin
  if (track.branches.Count < 3) then
    Exit();
  if (track.branches[0].node1.turnout < 0) then
    Exit();
  if (track.branches[1].node1.turnout < 0) then
    Exit();

  // 1) zjistime si polohy vyhybek
  var polLeft := turnouts[track.branches[0].node1.turnout].panelProp.position;
  var polRight := turnouts[track.branches[1].node1.turnout].panelProp.position;

  // 2) rozhodneme o tom co barvit
  var leftHidden := ((polLeft = TVyhPoloha.plus) and (polRight = TVyhPoloha.minus));
  var rightHidden := ((polLeft = TVyhPoloha.minus) and (polRight = TVyhPoloha.plus));

  var leftCross := (polLeft <> TVyhPoloha.plus) and (not leftHidden);
  var rightCross := (polRight <> TVyhPoloha.plus) and (not rightHidden);

  ShowBranches(track, 0, leftCross, showed, myORs, flash, obj, startJC, turnouts);
  ShowBranches(track, 1, rightCross, showed, myORs, flash, obj, startJC, turnouts);
  ShowBranches(track, 2, not(leftHidden or rightHidden or ((polLeft = TVyhPoloha.minus) and
    (polRight = TVyhPoloha.minus))), showed, myORs, flash, obj, startJC, turnouts);
  if (track.branches.Count > 3) then
    ShowBranches(track, 3, not leftHidden, showed, myORs, flash, obj, startJC, turnouts);
  if (track.branches.Count > 4) then
    ShowBranches(track, 4, not rightHidden, showed, myORs, flash, obj, startJC, turnouts);

  turnouts[track.branches[0].node1.turnout].visible := not leftHidden;
  turnouts[track.branches[1].node1.turnout].visible := not rightHidden;

  // 3) vykreslime stredovy kriz
  var fg: TColor;
  if (((track.panelProp.flash) or ((track.panelProp.trains.Count > 0) and
    (myORs[track.area].RegPlease.status = TAreaRegPleaseStatus.selected))) and (flash) and (visible)) then
    fg := clBlack
  else
  begin
    if (visible) then
      fg := track.panelProp.fg
    else
      fg := track.panelProp.notColorBranches;
  end;

  track.ShowDKSCross(track.root, obj, leftCross, rightCross, track.dksType, fg, track);
  if (track.IsSecondCross()) then
    track.ShowDKSCross(track.SecondCrossPos(), obj, rightCross, leftCross, InvDKSType(track.dksType), fg, track);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTracks.GetItem(index: Integer): TPTrack;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTracks.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTracks.GetTrack(tech_id: Integer): Integer;
begin
  for var i := 0 to Self.data.Count - 1 do
    if (tech_id = Self.data[i].block) then
      Exit(i);

  Result := -1;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
