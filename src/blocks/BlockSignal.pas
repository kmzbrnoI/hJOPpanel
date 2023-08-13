unit BlockSignal;

{
  Definition of "signal" block. Definition of a database of signals.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  Symbols;

type
  TSignalPanelProp = record
    symbol, bg, surr: TColor;
    AB: Boolean;
    flash: Boolean;

    procedure Change(data: TStrings);
  end;

  TPSignal = class
    block: Integer;
    position: TPoint;
    symbolID: Integer;

    area: Integer;
    panelProp: TSignalPanelProp;

    procedure Reset();
    procedure Show(obj: TDXDraw; blik: Boolean);
  end;

  TStartJC = record
    pos: TPoint;
    color: TColor;
  end;

  TPSignals = class
  private
    function GetItem(index: Integer): TPSignal;
    function GetCount(): Integer;

  public
    data: TObjectList<TPSignal>;
    startJC: TList<TStartJC>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: Boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    procedure UpdateStartJC();

    property Items[index: Integer]: TPSignal read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _DEF_SIGNAL_PROP: TSignalPanelProp = (symbol: TJopColor.black; bg: clFuchsia; surr: clBlack; AB: false; flash: false);
  _UA_SIGNAL_PROP: TSignalPanelProp = (symbol: TJopColor.grayDark; bg: clBlack; surr: clBlack; AB: false; flash: false);

implementation

uses parseHelper, Panel;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPSignal.Reset();
begin
  if (Self.block > -2) then
    Self.panelProp := _DEF_SIGNAL_PROP
  else
    Self.panelProp := _UA_SIGNAL_PROP;
end;

procedure TPSignal.Show(obj: TDXDraw; blik: Boolean);
var fg: TColor;
begin
  if ((Self.panelProp.flash) and (blik)) then
    fg := clBlack
  else
    fg := Self.panelProp.symbol;

  if (Self.panelProp.AB) then
    Symbols.Draw(SymbolSet.IL_Symbols, Self.Position, _S_SIGNAL_B + Self.SymbolID + 2, fg, Self.panelProp.bg, obj)
  else
    Symbols.Draw(SymbolSet.IL_Symbols, Self.Position, _S_SIGNAL_B + Self.SymbolID, fg, Self.panelProp.bg, obj);
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPSignals.Create();
begin
  inherited;
  Self.data := TObjectList<TPSignal>.Create();
  Self.startJC := TList<TStartJC>.Create();
end;

destructor TPSignals.Destroy();
begin
  Self.data.Free();
  Self.startJC.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPSignals.Load(ini: TMemIniFile; version: Word);
var count: Integer;
begin
  Self.data.Clear();

  count := ini.ReadInteger('P', 'N', 0);
  for var i := 0 to count-1 do
  begin
    var signal: TPSignal := TPSignal.Create();

    signal.block := ini.ReadInteger('N' + IntToStr(i), 'B', -1);
    signal.Position.X := ini.ReadInteger('N' + IntToStr(i), 'X', 0);
    signal.Position.Y := ini.ReadInteger('N' + IntToStr(i), 'Y', 0);
    signal.SymbolID := ini.ReadInteger('N' + IntToStr(i), 'S', 0);
    if (version < _FILEVERSION_20) then
      signal.SymbolID := TranscodeSymbolFromBpnlV3(signal.SymbolID);

    signal.area := ini.ReadInteger('N' + IntToStr(i), 'OR', -1);

    if (signal.block = -2) then
      signal.panelProp := _UA_SIGNAL_PROP
    else
      signal.panelProp := _DEF_SIGNAL_PROP;

    Self.data.Add(signal);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPSignals.Show(obj: TDXDraw; blik: Boolean);
begin
  for var nav: TPSignal in Self.data do
    nav.Show(obj, blik);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPSignals.GetIndex(Pos: TPoint): Integer;
begin
  Result := -1;

  for var i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].Position.X) and (Pos.Y = Self.data[i].Position.Y)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPSignals.Reset(orindex: Integer = -1);
begin
  for var nav: TPSignal in Self.data do
    if ((orindex < 0) or (nav.area = orindex)) then
      nav.Reset();

  Self.startJC.Clear();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPSignals.GetItem(index: Integer): TPSignal;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPSignals.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPSignals.UpdateStartJC();
begin
  Self.startJC.Clear();

  for var nav: TPSignal in Self.data do
  begin
    if (nav.panelProp.surr <> clBlack) then
    begin
      begin
        var sjc: TStartJC;
        sjc.Color := nav.panelProp.surr;
        sjc.Pos := Point(nav.Position.X - 1, nav.Position.Y);
        Self.startJC.Add(sjc);
      end;

      begin
        var sjc: TStartJC;
        sjc.Color := nav.panelProp.surr;
        sjc.Pos := Point(nav.Position.X + 1, nav.Position.Y);
        Self.startJC.Add(sjc);
      end;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSignalPanelProp.Change(data: TStrings);
begin
  symbol := StrToColor(data[4]);
  bg := StrToColor(data[5]);
  flash := StrToBool(data[6]);
  AB := StrToBool(data[7]);
  if (data.Count >= 9) then
    surr := StrToColor(data[8])
  else
    surr := clBlack;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
