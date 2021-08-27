unit BlockPst;

{
  Definition of pst block.
  Definition of pst blocks database.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  BlockTypes;

type
  TPPst = class
    block: Integer;
    pos: TPoint;
    area: Integer;
    panelProp: TGeneralPanelProp;

    procedure Reset();
  end;

  TPPsts = class
  private
    function GetItem(index: Integer): TPPst;
    function GetCount(): Integer;

  public
    data: TObjectList<TPPst>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPPst read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _DEF_PST_PROP: TGeneralPanelProp = (fg: clBlack; bg: clFuchsia; flash: false;);
  _UA_PST_PROP: TGeneralPanelProp = (fg: $A0A0A0; bg: clBlack; flash: false;);

implementation

uses Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPPst.Reset();
begin
  if (Self.block > -2) then
    Self.panelProp := _DEF_PST_PROP
  else
    Self.panelProp := _UA_PST_PROP;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPPsts.Create();
begin
  inherited;
  Self.data := TObjectList<TPPst>.Create();
end;

destructor TPPsts.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPPsts.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'Pst', 0);
  for var i := 0 to Count - 1 do
  begin
    var pst := TPPst.Create();

    pst.block := ini.ReadInteger('Pst' + IntToStr(i), 'B', -1);
    pst.area := ini.ReadInteger('Pst' + IntToStr(i), 'OR', -1);
    pst.pos.X := ini.ReadInteger('Pst' + IntToStr(i), 'X', 0);
    pst.pos.Y := ini.ReadInteger('Pst' + IntToStr(i), 'Y', 0);

    // default settings:
    if (pst.block = -2) then
      pst.panelProp := _UA_PST_PROP
    else
      pst.panelProp := _DEF_PST_PROP;

    Self.data.Add(pst);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPPsts.Show(obj: TDXDraw; blik: boolean);
begin
  for var pst in Self.data do
  begin
    var fg: TColor;
    if ((pst.panelProp.flash) and (blik)) then
      fg := clBlack
    else
      fg := pst.panelProp.fg;

    Symbols.Draw(SymbolSet.IL_Symbols, pst.pos, _S_PST_TOP, fg, pst.panelProp.bg, obj);
    Symbols.Draw(SymbolSet.IL_Symbols, Point(pst.pos.X, pst.pos.Y+1), _S_PST_BOT, fg, pst.panelProp.bg, obj);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPPsts.GetIndex(Pos: TPoint): Integer;
begin
  Result := -1;

  for var i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].pos.X) and ((Pos.Y = Self.data[i].pos.Y) or (Pos.Y = Self.data[i].pos.Y+1))) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPPsts.Reset(orindex: Integer = -1);
begin
  for var pst in Self.data do
    if ((orindex < 0) or (pst.area = orindex)) then
      pst.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPPsts.GetItem(index: Integer): TPPst;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPPsts.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
