unit BlokPopisek;

{
  Definition of "text" block. Text block represents any text. Text block
  could be connected to technological block (and thus clickable).
  Definition of a databse of text blocks.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
  UITypes;

type
  TTextPanelProp = record
    symbol, bg: TColor;
    left, right: TColor;
    flash: boolean;

    procedure Change(parsed: TStrings);
    procedure Reset();
  end;

  TPText = class
    text: string;
    position: TPoint;
    color: Integer;
    block: Integer;
    area: Integer;
    panelProp: TTextPanelProp;

    procedure Reset();
    procedure Show(obj: TDXDraw);
  end;

  TPTexts = class
  private
    function GetItem(index: Integer): TPText;
    function GetCount(): Integer;

  public
    data: TObjectList<TPText>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini: TMemIniFile; key: string; version: Word);
    procedure Show(obj: TDXDraw);
    function GetIndex(Pos: TPoint): Integer;
    procedure Reset(orindex: Integer = -1);

    property Items[index: Integer]: TPText read GetItem; default;
    property Count: Integer read GetCount;
  end;

const
  _Def_Text_Prop: TTextPanelProp = (Symbol: $A0A0A0; bg: clBlack; left: clFuchsia; right: clFuchsia;
    flash: false);

implementation

uses Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPText.Reset();
begin
  Self.PanelProp.Reset();
end;

procedure TPText.Show(obj: TDXDraw);
begin
  if (Self.block > -1) then
  begin
    obj.Surface.Canvas.Brush.Color := Self.PanelProp.left;
    obj.Surface.Canvas.Pen.Color := obj.Surface.Canvas.Brush.Color;
    obj.Surface.Canvas.Rectangle((Self.Position.X - 1) * SymbolSet.symbWidth,
      Self.Position.Y * SymbolSet.symbHeight, (Self.Position.X) * SymbolSet.symbWidth,
      (Self.Position.Y + 1) * SymbolSet.symbHeight);

    obj.Surface.Canvas.Brush.Color := Self.PanelProp.right;
    obj.Surface.Canvas.Pen.Color := obj.Surface.Canvas.Brush.Color;
    obj.Surface.Canvas.Rectangle((Self.Position.X + 1) * SymbolSet.symbWidth,
      Self.Position.Y * SymbolSet.symbHeight, (Self.Position.X + 2) * SymbolSet.symbWidth,
      (Self.Position.Y + 1) * SymbolSet.symbHeight);

    Symbols.TextOutput(Self.Position, Self.Text, Self.PanelProp.Symbol, Self.PanelProp.bg, obj, false, true);
  end else begin
    Symbols.TextOutput(Self.Position, Self.Text, _Symbol_Colors[Self.Color], clBlack, obj, false, true);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPTexts.Create();
begin
  inherited;
  Self.data := TObjectList<TPText>.Create();
end;

destructor TPTexts.Destroy();
begin
  Self.data.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTexts.Load(ini: TMemIniFile; key: string; version: Word);
begin
  Self.data.Clear();

  var count := ini.ReadInteger('P', key, 0);
  for var i := 0 to count - 1 do
  begin
    var text: TPText := TPText.Create();

    text.text := ini.ReadString(key + IntToStr(i), 'T', '0');
    text.position.X := ini.ReadInteger(key + IntToStr(i), 'X', 0);
    text.position.Y := ini.ReadInteger(key + IntToStr(i), 'Y', 0);
    text.color := ini.ReadInteger(key + IntToStr(i), 'C', 0);
    text.block := ini.ReadInteger(key + IntToStr(i), 'B', -1);
    text.area := ini.ReadInteger(key + IntToStr(i), 'OR', -1);

    text.panelProp := _Def_Text_Prop;

    Self.data.Add(text);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTexts.Reset(orindex: Integer = -1);
begin
  for var text in Self.data do
    if ((orindex < 0) or (text.area = orindex)) then
      text.Reset();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTexts.GetItem(index: Integer): TPText;
begin
  Result := Self.data[index];
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTexts.GetCount(): Integer;
begin
  Result := Self.data.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPTexts.Show(obj: TDXDraw);
begin
  for var text in Self.data do
    text.Show(obj);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPTexts.GetIndex(Pos: TPoint): Integer;
begin
  for var i := 0 to Self.data.Count - 1 do
  begin
    if ((Pos.X >= Self.data[i].Position.X - 1) and (Pos.X <= Self.data[i].Position.X + 1) and
      (Pos.Y = Self.data[i].Position.Y)) then
      Exit(i);
  end;

  Result := -1;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TTextPanelProp.Change(parsed: TStrings);
begin
  Self.symbol := StrToColor(parsed[4]);
  Self.bg := StrToColor(parsed[5]);
  Self.flash := (parsed[6] = '1');
  Self.left := StrToColor(parsed[7]);
  Self.right := StrToColor(parsed[8]);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TTextPanelProp.Reset();
begin
  Self := _Def_Text_Prop;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
