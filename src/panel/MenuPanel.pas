unit MenuPanel;

{
  TPanelMenu
  Zobrazovani menu na panelu.
}

interface

uses SysUtils, Classes, StrUtils, Graphics, Types, PGraphics,
  Generics.Collections, Windows, DXDraws;

const
  _PNL_MENU_ITEMS_MAX = 32;
  _PNL_MENU_ITEM_LEFT_OFFSET = 2;
  _HINT_WIDTH = 40;

type
  TPanelMenuClickEvent = procedure(Sender: TObject; item: string; obl_r: Integer; itemindex: Integer) of object;

  TPanelMenuItem = record
    plain_text: string; // tento text je puvodni od serveru
    show_text: string; // tento text je zkraceny na sirku menu
    disabled: boolean;
    header: boolean;
    important: boolean;
    admin: boolean;
  end;

  TPanelMenuItems = record
    data: array [0 .. _PNL_MENU_ITEMS_MAX] of TPanelMenuItem;
    cnt: Integer;
  end;

  TPanelMenu = class
  private const
    _MENU_BACKGROUND = clSIlver;
    _MENU_WIDTH = 20; // sirka = 10 symbolu

  private
    fshowing: boolean;
    fselected: Integer;
    Items: TPanelMenuItems;
    fobl_r: Integer;

    Graphics: TPanelGraphics;

    Hints: TDictionary<string, string>;

    PanelMenuClickEvent: TPanelMenuClickEvent;

    procedure ParseMenuItems(Items: string);
    function GetFirstItemIndex(): Integer;
    function GetLastItemIndex(): Integer;
    function GetItemIndex(starting: char): Integer;

  public

    constructor Create(Graphics: TPanelGraphics);
    destructor Destroy(); override;

    procedure ShowMenu(Items: string; obl_r: Integer; absoluteLeftTop: TPoint); // vraci pozici, na kterou ma jit kurzor
    procedure PaintMenu(obj: TDXDraw; mouse_pos: TPoint);
    procedure Click();
    procedure KeyPress(key: Integer; var handled: boolean);
    function CheckCursorPos(Pos: TPoint): boolean;

    procedure LoadHints(fn: string);

    property showing: boolean read fshowing write fshowing;

    property OnClick: TPanelMenuClickEvent read PanelMenuClickEvent write PanelMenuClickEvent;
  end;

implementation

uses Symbols, parseHelper, PanelPainter;

{ format souboru hintu:
  csv soubor, kde na kazdem radku je jeden hint
  prvni je vzdy zkratka v menu, druha je vysvetlivka
  napr. V+;Přestavit výhybku do polohy plus
  soubor je v UTF8
}

/// /////////////////////////////////////////////////////////////////////////////

constructor TPanelMenu.Create(Graphics: TPanelGraphics);
begin
  inherited Create();

  Self.Graphics := Graphics;
  Self.Hints := TDictionary<string, string>.Create();
end; // ctor

destructor TPanelMenu.Destroy();
begin
  if (Assigned(Self.Hints)) then
    FreeAndNil(Self.Hints);

  inherited;
end; // dtor

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelMenu.ShowMenu(Items: string; obl_r: Integer; absoluteLeftTop: TPoint);
var i: Integer;
begin
  Self.ParseMenuItems(Items);
  Self.fselected := -1;

  for i := 0 to Self.Items.cnt - 1 do
    if (not Self.Items.data[i].header) and (Self.Items.data[i].plain_text <> '-') then
      break;

  Self.fobl_r := obl_r;

  SetCursorPos(absoluteLeftTop.X + (SymbolSet._Symbol_Sirka * 3), absoluteLeftTop.Y + (SymbolSet._Symbol_Vyska * (i + 1)
    ) + SymbolSet._Symbol_Vyska + (SymbolSet._Symbol_Vyska div 2));

  Self.fshowing := true;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelMenu.PaintMenu(obj: TDXDraw; mouse_pos: TPoint);
var i: Integer;
  Pos: TPoint;
  foreground, background: TColor;
  str: string;
  Canvas: TCanvas;
begin
  if (not showing) then
    Exit();

  Canvas := obj.Surface.Canvas;

  // pozadi menu
  Canvas.Brush.Color := Self._MENU_BACKGROUND;
  Canvas.Pen.Color := Self._MENU_BACKGROUND;
  Canvas.Rectangle(SymbolSet._Symbol_Sirka, SymbolSet._Symbol_Vyska, SymbolSet._Symbol_Sirka * (Self._MENU_WIDTH + 1),
    SymbolSet._Symbol_Vyska * (Self.Items.cnt + 3));

  // ramecek
  Canvas.Pen.Color := clBlack;
  Canvas.Rectangle(Round(SymbolSet._Symbol_Sirka * 1.5), Round(SymbolSet._Symbol_Vyska * 1.5),
    (SymbolSet._Symbol_Sirka * (Self._MENU_WIDTH + 1)) - Round(SymbolSet._Symbol_Sirka / 2),
    (SymbolSet._Symbol_Vyska * (Self.Items.cnt + 3)) - Round(SymbolSet._Symbol_Vyska / 2));

  // damotne polozky menu
  Pos.X := _PNL_MENU_ITEM_LEFT_OFFSET;
  Pos.Y := 2;

  Self.fselected := -1;

  for i := 0 to Self.Items.cnt - 1 do
  begin
    background := clSIlver;

    if (Self.Items.data[i].header) then
    begin
      // hlavicka
      foreground := $FF0000;
      Pos.X := Round(((_MENU_WIDTH - 2) / 2) - (Length(Self.Items.data[i].show_text) / 2)) + 2;
      str := Self.Items.data[i].show_text;
    end else begin
      // doplnime text mezerami
      str := Format('%-' + IntToStr(Self._MENU_WIDTH - 2) + 's', [Self.Items.data[i].show_text]);
      Pos.X := _PNL_MENU_ITEM_LEFT_OFFSET;

      if (Self.Items.data[i].disabled) then
      begin
        // disabled
        foreground := $A0A0A0;
      end else begin
        // normalni text
        Pos.X := _PNL_MENU_ITEM_LEFT_OFFSET;
        foreground := clBlack;
        if (Self.Items.data[i].admin) then
          background := clTeal;
      end;
    end;

    if (Self.Items.data[i].important) then
      foreground := clRed;

    if (mouse_pos.Y = Pos.Y) then
    begin
      if ((Self.Items.data[i].show_text = '-') or (Self.Items.data[i].disabled) or (Self.Items.data[i].header)) then
        Self.fselected := -1
      else
      begin
        if (background = clTeal) then
          foreground := clYellow;
        background := $5555CC;
        Self.fselected := i;
        if (foreground = clRed) then
          foreground := clYellow;
      end;
    end;

    if (Self.Items.data[i].show_text = '-') then
    begin
      Canvas.Pen.Color := clBlack;
      Canvas.MoveTo(Round((_PNL_MENU_ITEM_LEFT_OFFSET * SymbolSet._Symbol_Sirka) - (SymbolSet._Symbol_Sirka / 2)),
        (Pos.Y * SymbolSet._Symbol_Vyska) + Round(SymbolSet._Symbol_Vyska / 2));
      Canvas.LineTo(Round(((_PNL_MENU_ITEM_LEFT_OFFSET + _MENU_WIDTH - 2) * SymbolSet._Symbol_Sirka) +
        (SymbolSet._Symbol_Sirka / 2)), (Pos.Y * SymbolSet._Symbol_Vyska) + Round(SymbolSet._Symbol_Vyska / 2));
    end
    else
      PanelPainter.TextOutput(Pos, str, foreground, background, obj);

    Pos.Y := Pos.Y + 1;
  end; // for i

  // vypsani hintu:
  if (Self.fselected > -1) and (Self.Hints.TryGetValue(Self.Items.data[Self.fselected].show_text, str)) then
  begin
    str := Format(' %-' + IntToStr(_HINT_WIDTH) + 's', [str]);
    PanelPainter.TextOutput(Point(1, 0), str, clYellow, clTeal, obj);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelMenu.ParseMenuItems(Items: string);
var sl: TStrings;
  i: Integer;
begin
  sl := TStringList.Create();
  ExtractStringsEx([',', ';'], [], Items, sl);

  Self.Items.cnt := sl.Count;

  for i := 0 to sl.Count - 1 do
  begin
    Self.Items.data[i].disabled := false;
    Self.Items.data[i].header := false;
    Self.Items.data[i].important := false;
    Self.Items.data[i].admin := false;

    case (sl[i][1]) of
      '#':
        begin
          Self.Items.data[i].disabled := true;
          Self.Items.data[i].plain_text := RightStr(sl[i], Length(sl[i]) - 1);
        end;
      '$':
        begin
          Self.Items.data[i].header := true;
          Self.Items.data[i].plain_text := RightStr(sl[i], Length(sl[i]) - 1);
        end;
      '!':
        begin
          Self.Items.data[i].important := true;
          Self.Items.data[i].plain_text := RightStr(sl[i], Length(sl[i]) - 1);
        end;
      '*':
        begin
          Self.Items.data[i].admin := true;
          Self.Items.data[i].plain_text := RightStr(sl[i], Length(sl[i]) - 1);
        end
    else
      Self.Items.data[i].plain_text := sl[i];
    end;

    if (Length(Self.Items.data[i].plain_text) > _MENU_WIDTH - 2) then
      Self.Items.data[i].show_text := LeftStr(Self.Items.data[i].plain_text, _MENU_WIDTH - 3) + '.'
    else
      Self.Items.data[i].show_text := Self.Items.data[i].plain_text;

  end; // for i

  sl.Free;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelMenu.Click();
begin
  if (Self.fselected = -1) then
    Exit;

  Self.showing := false;
  if (Assigned(Self.OnClick)) then
    Self.OnClick(Self, Self.Items.data[Self.fselected].plain_text, Self.fobl_r, Self.fselected);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelMenu.LoadHints(fn: string);
var parsed: TStrings;
  f: TextFile;
  line: string;
begin
  Self.Hints.Clear();

  try
    AssignFile(f, fn);
    Reset(f);
  except
    Exit();
  end;

  parsed := TStringList.Create();

  while (not eof(f)) do
  begin
    ReadLn(f, line);
    parsed.Clear();
    ExtractStringsEx([',', ';'], [], line, parsed);

    try
      if (parsed.Count >= 2) then
        Self.Hints.Add(UTF8ToString(RawByteString(parsed[0])), UTF8ToString(RawByteString(parsed[1])));
    except
      Self.Hints.Clear;
      Exit();
    end;
  end; // while

  parsed.Free();
  CloseFile(f);
end;

procedure TPanelMenu.KeyPress(key: Integer; var handled: boolean);
var mouse: TPoint;
  i: Integer;
begin
  handled := true;

  case (key) of
    VK_RETURN:
      Self.Click();

    VK_UP:
      begin
        GetCursorPos(mouse);
        if (Self.fselected > Self.GetFirstItemIndex()) then
        begin
          for i := Self.fselected - 1 downto 0 do
            if ((not Self.Items.data[i].disabled) and (not Self.Items.data[i].header) and
              (Self.Items.data[i].show_text <> '-')) then
              break;
          mouse.Y := mouse.Y + ((i - Self.fselected) * SymbolSet._Symbol_Vyska);
        end;
        if (Self.fselected = -1) then
        begin
          mouse := Self.Graphics.DrawObject.ClientToScreen(Point(0, 0));
          mouse.X := mouse.X + (3 * SymbolSet._Symbol_Sirka);
          mouse.Y := mouse.Y + Round((2.5 + Self.GetLastItemIndex()) * SymbolSet._Symbol_Vyska);
        end;
        SetCursorPos(mouse.X, mouse.Y);
      end;

    VK_DOWN:
      begin
        GetCursorPos(mouse);
        if ((Self.fselected < Self.GetLastItemIndex()) and (Self.fselected <> -1)) then
        begin
          for i := Self.fselected + 1 to Self.Items.cnt - 1 do
            if ((not Self.Items.data[i].disabled) and (not Self.Items.data[i].header) and
              (Self.Items.data[i].show_text <> '-')) then
              break;

          mouse.Y := mouse.Y + ((i - Self.fselected) * SymbolSet._Symbol_Vyska);
        end;
        if (Self.fselected = -1) then
        begin
          mouse := Self.Graphics.DrawObject.ClientToScreen(Point(0, 0));
          mouse.X := mouse.X + (3 * SymbolSet._Symbol_Sirka);
          mouse.Y := mouse.Y + Round((2.5 + Self.GetFirstItemIndex()) * SymbolSet._Symbol_Vyska);
        end;
        SetCursorPos(mouse.X, mouse.Y);
      end;

    48 .. 57, 65 .. 90:
      begin
        mouse := Self.Graphics.DrawObject.ClientToScreen(Point(0, 0));
        mouse.X := mouse.X + (3 * SymbolSet._Symbol_Sirka);
        mouse.Y := mouse.Y + Round((2.5 + Self.GetItemIndex(chr(key))) * SymbolSet._Symbol_Vyska);
        SetCursorPos(mouse.X, mouse.Y);
      end;

    // numpad keys
    96 .. 105:
      begin
        mouse := Self.Graphics.DrawObject.ClientToScreen(Point(0, 0));
        mouse.X := mouse.X + (3 * SymbolSet._Symbol_Sirka);
        mouse.Y := mouse.Y + Round((2.5 + Self.GetItemIndex(chr(key - VK_NUMPAD0 + ord('0')))) *
          SymbolSet._Symbol_Vyska);
        SetCursorPos(mouse.X, mouse.Y);
      end;

  else
    handled := false;
  end;
end;

function TPanelMenu.GetFirstItemIndex(): Integer;
var i: Integer;
begin
  for i := 0 to Self.Items.cnt - 1 do
    if ((not Self.Items.data[i].disabled) and (not Self.Items.data[i].header) and (Self.Items.data[i].show_text <> '-'))
    then
      Exit(i);
  Exit(0);
end;

function TPanelMenu.GetLastItemIndex(): Integer;
var i: Integer;
begin
  for i := Self.Items.cnt - 1 downto 0 do
    if ((not Self.Items.data[i].disabled) and (not Self.Items.data[i].header) and (Self.Items.data[i].show_text <> '-'))
    then
      Exit(i);
  Exit(0);
end;

function TPanelMenu.GetItemIndex(starting: char): Integer;
var i: Integer;
  start: Integer;
begin
  if (Self.fselected > -1) then
  begin
    if (Self.Items.data[Self.fselected].show_text[1] = starting) then
      start := Self.fselected + 1
    else
      start := 0;
  end else begin
    start := 0;
  end;

  for i := start to Self.Items.cnt - 1 do
    if ((not Self.Items.data[i].disabled) and (not Self.Items.data[i].header) and (Self.Items.data[i].show_text <> '-')
      and (Self.Items.data[i].show_text[1] = starting)) then
      Exit(i);

  for i := 0 to start - 1 do
    if ((not Self.Items.data[i].disabled) and (not Self.Items.data[i].header) and (Self.Items.data[i].show_text <> '-')
      and (Self.Items.data[i].show_text[1] = starting)) then
      Exit(i);

  Exit(0);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TPanelMenu.CheckCursorPos(Pos: TPoint): boolean;
var handled: boolean;
begin
  Self.fselected := Pos.Y div (SymbolSet._Symbol_Vyska) - 2;
  if ((Self.fselected < 0) or (Self.fselected >= Self.Items.cnt)) then
    Self.fselected := -1;

  if (Pos.Y < GetFirstItemIndex() + 2) then
  begin
    Self.KeyPress(VK_DOWN, handled);
    Exit(true);
  end;
  if (Pos.Y > GetLastItemIndex() + 2) then
  begin
    Self.KeyPress(VK_UP, handled);
    Exit(true);
  end;

  Result := false;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
