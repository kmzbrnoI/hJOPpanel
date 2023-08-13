unit BlockCrossing;

{
  Definition of "crossing" blocks.
  Definition of a databse of crossings.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  BlockTrack, BlocksTrack, Symbols;

type
  TBlkCrossingPanelState = (disabled = -5, err = -1, otevreno = 0, vystraha = 1, uzavreno = 2, anulace = 3);

  TCrossingPanelProp = record
    fg, bg: TColor;
    state: TBlkCrossingPanelState;

    procedure Change(data: TStrings);
  end;

  // A flashing position of a crossing
  TCrosFlashPoint = record
    pos: TPoint;
    panelTrack: Integer; // pozor, tady je usek panelu!, toto je zmena oproti editoru a mergeru !
  end;

  TPCrossing = class
    block: Integer;

    staticPoss: TList<TPoint>;
    flashPoss: TList<TCrosFlashPoint>;
    flashPossAlreadyInTrack: TList<Boolean>;

    area: Integer;
    panelProp: TCrossingPanelProp;

    constructor Create();
    destructor Destroy(); override;

    procedure Reset();
    procedure Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
    procedure UpdateFlashPossAlreadyInTrack(const useky: TList<TPTrack>);
  end;

  TPCrossings = class
  private
    function GetItem(index: Integer): TPCrossing;
    function GetCount(): Integer;

  public

    data: TObjectList<TPCrossing>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; useky: TPTracks; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);
    function GetCros(tech_id: Integer): Integer;

    property Items[index: Integer]: TPCrossing read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Cros_Prop: TCrossingPanelProp = (fg: TJopColor.black; bg: clFuchsia; state: otevreno);
  _UA_Cros_Prop: TCrossingPanelProp = (fg: TJopColor.grayDark; bg: clBlack; state: otevreno);

implementation

uses parseHelper, Panel;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPCrossing.Reset();
begin
  if (Self.block > -2) then
    Self.PanelProp := _Def_Cros_Prop
  else
    Self.PanelProp := _UA_Cros_Prop;
end;

procedure TPCrossing.Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
begin
  if ((Self.flashPossAlreadyInTrack.Count = 0) and (Self.flashPoss.Count > 0)) then
    Self.UpdateFlashPossAlreadyInTrack(useky); // initial update

  // vykreslit staticke pozice:
  for var pos in Self.staticPoss do
    Symbols.Draw(SymbolSet.IL_Symbols, Pos, _S_CROSSING, Self.PanelProp.fg, Self.PanelProp.bg, obj);

  if (Self.PanelProp.state <> TBlkCrossingPanelState.uzavreno) then
    for var i: Integer := 0 to Self.flashPoss.Count-1 do
      if (flashPossAlreadyInTrack[i]) then
          Symbols.DrawRectangle(Self.flashPoss[i].pos, clBlack, obj);

  // vykreslit blikajici pozice podle stavu prejezdu:
  if (Self.PanelProp.state = TBlkCrossingPanelState.uzavreno) then
  begin
    // na nestatickych pozicich vykreslime usek
    // provedeme fintu: pridame pozici prostred prejezdu k useku, ktery tam patri
    // V modernich opnl souborech toto pridavani neni treba, protoze usek je pod prejezdem
    // u z zeditoru. Stare verze opnl souboru symbol neobsahovaly.

    for var i: Integer := 0 to Self.flashPoss.Count-1 do
    begin
      var flashPoint: TCrosFlashPoint := Self.flashPoss[i];
      if ((not flashPossAlreadyInTrack[i]) and (flashPoint.panelTrack > -1) and (flashPoint.panelTrack < useky.Count)) then
        useky[flashPoint.panelTrack].AddSymbolFromCrossing(flashPoint.Pos);
    end;
  end else if ((Self.PanelProp.state <> TBlkCrossingPanelState.vystraha) or (blik)) then
  begin
    // na nestatickych pozicich vykreslime prejezd
    for var i: Integer := 0 to Self.flashPoss.Count-1 do
    begin
      var flashPoint: TCrosFlashPoint := Self.flashPoss[i];
      if ((not flashPossAlreadyInTrack[i]) and (flashPoint.panelTrack > -1) and (flashPoint.panelTrack < useky.Count)) then
        useky[flashPoint.panelTrack].RemoveSymbolFromCrossing(flashPoint.Pos);

      Symbols.Draw(SymbolSet.IL_Symbols, flashPoint.Pos, _S_CROSSING, Self.PanelProp.fg,
        Self.PanelProp.bg, obj);
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPCrossings.Create();
begin
  inherited;
  Self.data := TObjectList<TPCrossing>.Create();
end;

destructor TPCrossings.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPCrossings.Load(ini: TMemIniFile; useky: TPTracks; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'PRJ', 0);
  for var i := 0 to Count - 1 do
  begin
    var crossing := TPCrossing.Create();

    crossing.block := ini.ReadInteger('PRJ' + IntToStr(i), 'B', -1);
    crossing.area := ini.ReadInteger('PRJ' + IntToStr(i), 'OR', -1);

    var obj := ini.ReadString('PRJ' + IntToStr(i), 'BP', '');
    var posCount := (Length(obj) div 9);
    for var j := 0 to posCount - 1 do
    begin
      var flashPoint: TCrosFlashPoint;
      flashPoint.Pos.X := StrToIntDef(copy(obj, j * 9 + 1, 3), 0);
      flashPoint.Pos.Y := StrToIntDef(copy(obj, j * 9 + 4, 3), 0);
      if (version >= _FILEVERSION_13) then
        flashPoint.panelTrack := StrToIntDef(copy(obj, j * 9 + 7, 3), 0)
      else
        flashPoint.panelTrack := useky.GetTrack(StrToIntDef(copy(obj, j * 9 + 7, 3), 0));
      crossing.flashPoss.Add(flashPoint);
    end;

    obj := ini.ReadString('PRJ' + IntToStr(i), 'SP', '');
    posCount := (Length(obj) div 6);
    for var j := 0 to posCount - 1 do
      crossing.staticPoss.Add(Point(StrToIntDef(copy(obj, j * 6 + 1, 3), 0), StrToIntDef(copy(obj, j * 6 + 4, 3), 0)));

    // default settings:
    if (crossing.block = -2) then
      crossing.PanelProp := _UA_Cros_Prop
    else
      crossing.PanelProp := _Def_Cros_Prop;

    Self.data.Add(crossing);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPCrossings.Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
begin
  for var prj in Self.data do
    prj.Show(obj, blik, useky);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPCrossings.GetIndex(Pos: TPoint): Integer;
begin
  Result := -1;

  // kontrola prejezdu:
  for var i := 0 to Self.data.Count - 1 do
  begin
    for var askPos in Self.data[i].staticPoss do
      if ((Pos.X = askPos.X) and (Pos.Y = askPos.Y)) then
        Exit(i);

    for var flashPos in Self.data[i].flashPoss do
      if ((Pos.X = flashPos.Pos.X) and (Pos.Y = flashPos.Pos.Y)) then
        Exit(i);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPCrossings.Reset(orindex: Integer = -1);
begin
  for var crossing in Self.data do
    if ((orindex < 0) or (crossing.area = orindex)) then
      crossing.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPCrossings.GetItem(index: Integer): TPCrossing;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPCrossings.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPCrossings.GetCros(tech_id: Integer): Integer;
begin
  for var i := 0 to Self.data.Count - 1 do
    if (tech_id = Self.data[i].block) then
      Exit(i);

  Result := -1;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TCrossingPanelProp.Change(data: TStrings);
begin
  fg := StrToColor(data[4]);
  bg := StrToColor(data[5]);
  state := TBlkCrossingPanelState(StrToInt(data[7]));
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPCrossing.Create();
begin
  inherited;
  Self.staticPoss := TList<TPoint>.Create();
  Self.flashPoss := TList<TCrosFlashPoint>.Create();
  Self.flashPossAlreadyInTrack := TList<Boolean>.Create();
end;

destructor TPCrossing.Destroy();
begin
  Self.staticPoss.Free();
  Self.flashPoss.Free();
  Self.flashPossAlreadyInTrack.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPCrossing.UpdateFlashPossAlreadyInTrack(const useky: TList<TPTrack>);
begin
  Self.flashPossAlreadyInTrack.Clear();

  for var flashPoint in Self.flashPoss do
    Self.flashPossAlreadyInTrack.Add(
      (flashPoint.panelTrack > -1) and (flashPoint.panelTrack < useky.Count) and (useky[flashPoint.panelTrack].IsPos(flashPoint.Pos))
    );
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
