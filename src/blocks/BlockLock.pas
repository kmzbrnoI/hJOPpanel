unit BlockLock;

{
  Definition of lock block.
  Definition of lock blocks database.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  BlockTypes;

type
  TPLock = class
    block: Integer;
    pos: TPoint;
    area: Integer;
    panelProp: TGeneralPanelProp;

    procedure Reset();
  end;

  TPLocks = class
  private
    function GetItem(index: Integer): TPLock;
    function GetCount(): Integer;

  public
    data: TObjectList<TPLock>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPLock read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _DEF_LOCK_PROP: TGeneralPanelProp = (fg: clBlack; bg: clFuchsia; flash: false;);
  _UA_LOCK_PROP: TGeneralPanelProp = (fg: $A0A0A0; bg: clBlack; flash: false;);

implementation

uses Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLock.Reset();
begin
  if (Self.block > -2) then
    Self.panelProp := _DEF_LOCK_PROP
  else
    Self.panelProp := _UA_LOCK_PROP;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPLocks.Create();
begin
  inherited;
  Self.data := TObjectList<TPLock>.Create();
end;

destructor TPLocks.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLocks.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'Z', 0);
  for var i := 0 to Count - 1 do
  begin
    var lock := TPLock.Create();

    lock.block := ini.ReadInteger('Z' + IntToStr(i), 'B', -1);
    lock.area := ini.ReadInteger('Z' + IntToStr(i), 'OR', -1);
    lock.pos.X := ini.ReadInteger('Z' + IntToStr(i), 'X', 0);
    lock.pos.Y := ini.ReadInteger('Z' + IntToStr(i), 'Y', 0);

    // default settings:
    if (lock.block = -2) then
      lock.panelProp := _UA_LOCK_PROP
    else
      lock.panelProp := _DEF_LOCK_PROP;

    Self.data.Add(lock);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLocks.Show(obj: TDXDraw; blik: boolean);
begin
  for var lock in Self.data do
  begin
    var fg: TColor;
    if ((lock.panelProp.flash) and (blik)) then
      fg := clBlack
    else
      fg := lock.panelProp.fg;

    Symbols.Draw(SymbolSet.IL_Symbols, lock.pos, _S_LOCK, fg, lock.panelProp.bg, obj);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLocks.GetIndex(Pos: TPoint): Integer;
begin
  Result := -1;

  for var i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].pos.X) and (Pos.Y = Self.data[i].pos.Y)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLocks.Reset(orindex: Integer = -1);
begin
  for var lock in Self.data do
    if ((orindex < 0) or (lock.area = orindex)) then
      lock.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLocks.GetItem(index: Integer): TPLock;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLocks.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
