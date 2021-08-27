unit BlokyVyhybka;

{
  Databse of turnouts.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  BlokUsek, BlokVyhybka;

type
  TPTurnouts = class
  private
    function GetItem(index: Integer): TPTurnout;
    function GetCount(): Integer;

  public
    data: TObjectList<TPTurnout>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPTurnout read GetItem; default;
    property Count: Integer read GetCount;
  end;

implementation

uses Symbols;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPTurnouts.Create();
begin
  inherited;
  Self.data := TObjectList<TPTurnout>.Create();
end;

destructor TPTurnouts.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTurnouts.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'V', 0);
  for var i := 0 to count - 1 do
  begin
    var turnout := TPTurnout.Create();

    turnout.block := ini.ReadInteger('V' + IntToStr(i), 'B', -1);
    turnout.symbolID := ini.ReadInteger('V' + IntToStr(i), 'S', 0);
    turnout.orientationPlus := ini.ReadInteger('V' + IntToStr(i), 'P', 0);
    turnout.position.X := ini.ReadInteger('V' + IntToStr(i), 'X', 0);
    turnout.position.Y := ini.ReadInteger('V' + IntToStr(i), 'Y', 0);
    turnout.obj := ini.ReadInteger('V' + IntToStr(i), 'O', -1);

    // OR
    turnout.area := ini.ReadInteger('V' + IntToStr(i), 'OR', -1);

    // default settings:
    turnout.visible := true;
    if (turnout.block = -2) then
      turnout.panelProp := _UA_TURNOUT_PROP
    else
      turnout.panelProp := _DEF_TURNOUT_PROP;

    Self.data.Add(turnout);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTurnouts.Show(obj: TDXDraw; blik: boolean; useky: TList<TPTrack>);
begin
  for var turnout in Self.data do
    turnout.Show(obj, blik, useky);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTurnouts.GetIndex(Pos: TPoint): Integer;
begin
  Result := -1;

  for var i := 0 to Self.data.Count - 1 do
    if ((Pos.X = Self.data[i].position.X) and (Pos.Y = Self.data[i].position.Y)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTurnouts.Reset(orindex: Integer = -1);
begin
  for var turnout in Self.data do
    if (((orindex < 0) or (turnout.area = orindex))) then
      turnout.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTurnouts.GetItem(index: Integer): TPTurnout;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTurnouts.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
