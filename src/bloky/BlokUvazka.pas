unit BlokUvazka;

{
  Linker block definition.
  Databse of linkers definition.
}

interface

uses Graphics, Types, Generics.Collections, IniFiles, SysUtils, DXDraws, Classes;

type
  TLinkerDir = (disabled = -1, zadny = 0, zakladni = 1, opacny = 2);

  TLinkerPanelProp = record
    fg, bg: TColor;
    flash: boolean;
    dir: TLinkerDir;

    procedure Change(parsed: TStrings);
  end;

  TPLinker = class
    block: Integer;
    pos: TPoint;
    defaltDir: Integer;
    area: Integer;
    panelProp: TLinkerPanelProp;
  end;

  TPLinkers = class
  private
    function GetItem(index: Integer): TPLinker;
    function GetCount(): Integer;

  public
    data: TObjectList<TPLinker>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; version: Word);
    procedure Show(obj: TDXDraw; blik: boolean);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPLinker read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Linker_Prop: TLinkerPanelProp = (fg: clBlack; bg: clFuchsia; flash: false; dir: disabled;);
  _UA_Linker_Prop: TLinkerPanelProp = (fg: $A0A0A0; bg: clBlack; flash: false; dir: zadny;);

implementation

uses Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPLinkers.Create();
begin
  inherited;
  Self.data := TObjectList<TPLinker>.Create();
end;

destructor TPLinkers.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLinkers.Load(ini: TMemIniFile; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', 'Uv', 0);
  for var i := 0 to Count - 1 do
  begin
    var linker := TPLinker.Create();

    linker.block := ini.ReadInteger('Uv' + IntToStr(i), 'B', -1);
    linker.area := ini.ReadInteger('Uv' + IntToStr(i), 'OR', -1);
    linker.pos.X := ini.ReadInteger('Uv' + IntToStr(i), 'X', 0);
    linker.pos.Y := ini.ReadInteger('Uv' + IntToStr(i), 'Y', 0);
    linker.defaltDir := ini.ReadInteger('Uv' + IntToStr(i), 'D', 0);

    // default settings:
    if (linker.block = -2) then
      linker.panelProp := _UA_Linker_Prop
    else
      linker.panelProp := _Def_Linker_Prop;

    Self.data.Add(linker);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLinkers.Show(obj: TDXDraw; blik: boolean);
var fg: TColor;
begin
  for var linker in Self.data do
  begin
    if ((linker.panelProp.flash) and (blik)) then
      fg := clBlack
    else
      fg := linker.panelProp.fg;

    case (linker.panelProp.dir) of
      TLinkerDir.disabled, TLinkerDir.zadny:
        begin
          Symbols.Draw(SymbolSet.IL_Symbols, linker.pos, _S_RAILWAY_LEFT, fg, linker.panelProp.bg, obj);
          Symbols.Draw(SymbolSet.IL_Symbols, Point(linker.pos.X + 1, linker.pos.Y), _S_RAILWAY_RIGHT, fg,
            linker.panelProp.bg, obj);
        end;

      TLinkerDir.zakladni, TLinkerDir.opacny:
        begin
          if (((linker.panelProp.dir = zakladni) and (linker.defaltDir = 0)) or
            ((linker.panelProp.dir = opacny) and (linker.defaltDir = 1))) then
          begin
            // sipka zleva doprava
            Symbols.Draw(SymbolSet.IL_Symbols, linker.pos, _S_TRACK_DET_B, fg, linker.panelProp.bg, obj);
            Symbols.Draw(SymbolSet.IL_Symbols, Point(linker.pos.X + 1, linker.pos.Y), _S_RAILWAY_RIGHT, fg,
              linker.panelProp.bg, obj);
          end else begin
            // sipka zprava doleva
            Symbols.Draw(SymbolSet.IL_Symbols, linker.pos, _S_RAILWAY_LEFT, fg, linker.panelProp.bg, obj);
            Symbols.Draw(SymbolSet.IL_Symbols, Point(linker.pos.X + 1, linker.pos.Y), _S_TRACK_DET_B, fg,
              linker.panelProp.bg, obj);
          end;
        end;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLinkers.GetIndex(Pos: TPoint): Integer;
begin
  Result := -1;

  for var i := 0 to Self.data.Count - 1 do
    if ((Pos.X >= Self.data[i].pos.X) and (Pos.Y = Self.data[i].pos.Y) and (Pos.X <= Self.data[i].pos.X + 1)) then
      Exit(i);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPLinkers.Reset(orindex: Integer = -1);
begin
  for var linker in Self.data do
  begin
    if ((orindex < 0) or (linker.area = orindex)) then
    begin
      if (linker.block > -2) then
        linker.panelProp := _Def_Linker_Prop
      else
        linker.panelProp := _UA_Linker_Prop;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLinkers.GetItem(index: Integer): TPLinker;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPLinkers.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TLinkerPanelProp.Change(parsed: TStrings);
begin
  fg := StrToColor(parsed[4]);
  bg := StrToColor(parsed[5]);
  flash := StrToBool(parsed[6]);
  dir := TLinkerDir(StrToInt(parsed[7]));
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
