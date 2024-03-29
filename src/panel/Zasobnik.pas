unit Zasobnik;

{
  Tato unita resi zasobnik jizdnich cest jedne oblasti rizeni.
}

interface

uses Generics.Collections, Types, Classes, SysUtils, PGraphics, Graphics,
  StrUtils, RPConst, Windows, DXDraws;

type
  TORStackVolba = (PV = 0, VZ = 1);
  TOREZVolba = (closed = 0, please = 1, openned = 2);

  TORStackCmd = record
    JC: string;
    id: Integer;
  end;

  TORStack = class
  private const
    _JC_TEXT_WIDTH = 25;

  private
    index: Integer; // index zasobniku
    stack: TList<TORStackCmd>; // povely
    volba: TORStackVolba; // aktualni volba
    hint: string; // upozorneni vpravo nahore
    fEZ: TOREZVolba; // stav EZ
    pos: TPoint; // pozice leveho horniho rohu zasobniku
    parent: string; // id materske oblasti rizeni
    fenabled: boolean; // jestli je na zasobnik mozo klikat
    selected: Integer; // index aktualne vybrane polozky (-1 default)
    dragged: Integer; // index aktualne presouvane polozky (-1 default)
    dirty: Integer; // index nepotvrzene polozky (-1 default)
    first_enabled: boolean; // jestli je prvni povel mozno editovat (presouvat, mazat)
    UPOenabled: boolean; // jestli je mozno kliknout na UPO (zlute UPO)

    Graphics: TPanelGraphics;

    procedure SetEnabled(new: boolean);
    procedure ParseList(list: string);

    procedure AddJC(data: string);
    procedure RemoveJC(id: Integer);

    procedure ShowStackCMD(ypos: Integer; text: string; first: boolean; selected: boolean; available: boolean;
      dirty: boolean; obj: TDXDraw);

    procedure SetEZ(new: TOREZVolba);

    property EZ: TOREZVolba read fEZ write SetEZ;

  public

    constructor Create(Graphics: TPanelGraphics; parent: string; pos: TPoint);
    destructor Destroy(); override;

    procedure Show(obj: TDXDraw; mousePos: TPoint);

    procedure ParseCommand(data: TStrings);

    procedure MouseClick(Position: TPoint; Button: TPanelButton; var handled: boolean);
    procedure MouseUp(Position: TPoint; Button: TPanelButton; var handled: boolean);
    procedure MouseDown(Position: TPoint; Button: TPanelButton; var handled: boolean);
    procedure KeyPress(key: Integer; var handled: boolean);
    function IsDragged(): boolean;

    property enabled: boolean read fenabled write SetEnabled;

  end; // TORStack

implementation

uses TCPCLientPanel, Symbols, parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

constructor TORStack.Create(Graphics: TPanelGraphics; parent: string; pos: TPoint);
begin
  inherited Create();

  Self.index := 0;
  Self.stack := TList<TORStackCmd>.Create();
  Self.volba := PV;
  Self.hint := '';
  Self.EZ := closed;
  Self.pos := pos;
  Self.parent := parent;
  Self.fenabled := false;
  Self.selected := -1;
  Self.dragged := -1;
  Self.dirty := -1;
  Self.first_enabled := true;

  Self.Graphics := Graphics;
end; // ctor

destructor TORStack.Destroy();
begin
  Self.stack.Free();
  inherited Destroy();
end; // dtor

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.ParseCommand(data: TStrings);
begin
  try
    if (data[2] = 'VZ') then
      Self.volba := VZ
    else if (data[2] = 'PV') then
      Self.volba := PV
    else if (data[2] = 'LIST') then
    begin
      Self.dirty := -1;
      if (data.Count > 4) then
        Self.ParseList(data[4])
      else
        Self.stack.Clear();
      if (Self.EZ = TOREZVolba.please) then
        Self.EZ := TOREZVolba.openned;
    end else if (data[2] = 'FIRST') then
    begin
      if (data[3] = '1') then
        Self.first_enabled := true
      else
        Self.first_enabled := false;
      if (Self.selected = 0) then
        Self.selected := 1;
      if (Self.dragged = 0) then
        Self.dragged := -1;
    end else if (data[2] = 'INDEX') then
      Self.index := StrToInt(data[3])
    else if (data[2] = 'RM') then
      Self.RemoveJC(StrToInt(data[3]))
    else if (data[2] = 'ADD') then
      Self.AddJC(data[3])
    else if (data[2] = 'HINT') then
    begin
      if (data.Count > 3) then
      begin
        if (Length(data[3]) > 8) then
          Self.hint := LeftStr(data[3], 7) + '.'
        else
          Self.hint := data[3]
      end
      else
        Self.hint := '';
    end else if (data[2] = 'UPO') then
    begin
      if (data[3] = '1') then
        Self.UPOenabled := true
      else
        Self.UPOenabled := false;
    end;
  except

  end;

end;

procedure TORStack.SetEnabled(new: boolean);
begin
  if ((not new) and (Self.enabled)) then
  begin
    Self.stack.Clear();
    Self.hint := '';
    Self.EZ := closed;
    Self.volba := PV;
    Self.selected := -1;
    Self.dragged := -1;
    Self.first_enabled := true;
  end;

  Self.fenabled := new;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.ParseList(list: string);
var str1, str2: TStrings;
  i: Integer;
  stack_jc: TORStackCmd;
begin
  str1 := TStringList.Create();
  str2 := TStringList.Create();
  ExtractStringsEx([']'], ['['], list, str1);

  Self.stack.Clear();
  for i := 0 to str1.Count - 1 do
  begin
    str2.Clear();
    ExtractStringsEx(['|'], [], str1[i], str2);

    try
      stack_jc.id := StrToInt(str2[0]);
      stack_jc.JC := str2[1];
      Self.stack.Add(stack_jc);
    except

    end;
  end; // for i

  if (Self.EZ = TOREZVolba.please) then
    Self.EZ := TOREZVolba.openned;

  str2.Free();
  str1.Free();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.RemoveJC(id: Integer);
var i: Integer;
begin
  for i := 0 to Self.stack.Count - 1 do
    if (Self.stack[i].id = id) then
    begin
      if (Self.selected = i) then
        Self.selected := -1;
      if (Self.dragged = i) then
        Self.dragged := -1;
      Self.stack.Delete(i);
      if ((Self.stack.Count = 0) and (Self.EZ <> TOREZVolba.closed)) then
        Self.EZ := TOREZVolba.closed;
      if (i = 0) then
      begin
        if (not Self.first_enabled) then
          Self.first_enabled := true;
        Self.UPOenabled := false;
      end;
      Exit();
    end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.AddJC(data: string);
var str: TStrings;
  stack_jc: TORStackCmd;
begin
  str := TStringList.Create();
  ExtractStringsEx(['|'], [], data, str);

  try
    stack_jc.id := StrToInt(str[0]);
    stack_jc.JC := str[1];
    Self.stack.Add(stack_jc);
  except

  end;

  str.Free();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.Show(obj: TDXDraw; mousePos: TPoint);
var JC, y, jcpos: Integer;
begin
  // zasobnik Disabled
  if (not Self.fenabled) then
  begin
    Symbols.TextOutput(Self.pos, Format('%.2d', [Self.index]), clFuchsia, clBlack, obj);
    Symbols.TextOutput(Point(Self.pos.X + 3, Self.pos.y), 'VZ', clFuchsia, clBlack, obj);
    Symbols.TextOutput(Point(Self.pos.X + 6, Self.pos.y), 'PV', clFuchsia, clBlack, obj);
    Symbols.TextOutput(Point(Self.pos.X + 9, Self.pos.y), 'EZ', clFuchsia, clBlack, obj);
    Symbols.TextOutput(Point(Self.pos.X + 12, Self.pos.y), Format('%.2d', [Self.stack.Count]), clFuchsia,
      clBlack, obj);
    Exit();
  end;

  Symbols.TextOutput(Self.pos, Format('%.2d', [Self.index]), TJopColor.grayDark, clBlack, obj);

  case (Self.EZ) of
    TOREZVolba.closed:
      Symbols.TextOutput(Point(Self.pos.X + 9, Self.pos.y), 'EZ', TJopColor.grayDark, clBlack, obj);
    TOREZVolba.please:
      Symbols.TextOutput(Point(Self.pos.X + 9, Self.pos.y), 'EZ', TJopColor.yellow, clBlack, obj);
    TOREZVolba.openned:
      Symbols.TextOutput(Point(Self.pos.X + 9, Self.pos.y), 'EZ', TJopColor.white, clBlack, obj);
  end; // case

  if (Self.EZ = TOREZVolba.openned) then
  begin
    Symbols.TextOutput(Point(Self.pos.X + 3, Self.pos.y), 'VZ', TJopColor.grayDark, clBlack, obj);
    Symbols.TextOutput(Point(Self.pos.X + 6, Self.pos.y), 'PV', TJopColor.grayDark, clBlack, obj);

    jcpos := mousePos.y - Self.pos.y - 1;
    if ((Self.dragged > -1) and ((jcpos < 0) or (jcpos >= Self.stack.Count))) then
      Self.dragged := -1;
    if ((not Self.first_enabled) and (jcpos = 0)) then
      jcpos := 1;

    // vypsani jizdnich cest v zasobniku
    JC := 0;
    for y := 0 to Self.stack.Count - 1 do
    begin
      if ((Self.dragged > -1) and (y = jcpos)) then
        Self.ShowStackCMD(y, Self.stack[Self.dragged].JC, false, true, true, false, obj)
      else
      begin
        if (JC = Self.dragged) then
          Inc(JC);

        Self.ShowStackCMD(y, Self.stack[JC].JC, ((y = 0) and (y <> dragged)), JC = selected,
          (JC <> 0) or (Self.first_enabled), y = Self.dirty, obj);
        Inc(JC);
      end;
    end;

  end else begin
    // pokud neni EZ
    if (Self.volba = VZ) then
    begin
      Symbols.TextOutput(Point(Self.pos.X + 3, Self.pos.y), 'VZ', TJopColor.white, clBlack, obj);
      Symbols.TextOutput(Point(Self.pos.X + 6, Self.pos.y), 'PV', TJopColor.grayDark, clBlack, obj);
    end else begin
      Symbols.TextOutput(Point(Self.pos.X + 3, Self.pos.y), 'VZ', TJopColor.grayDark, clBlack, obj);
      Symbols.TextOutput(Point(Self.pos.X + 6, Self.pos.y), 'PV', TJopColor.white, clBlack, obj);
    end;

    // pokud je alespon jedna cesta v zasobniku, vypiseme ji
    if (Self.stack.Count > 0) then
      Self.ShowStackCMD(0, Self.stack[0].JC, true, false, Self.first_enabled, false, obj);

    Symbols.TextOutput(Point(Self.pos.X + 12, Self.pos.y), Format('%.2d', [Self.stack.Count]), TJopColor.grayDark,
      clBlack, obj);

    if ((Self.hint <> '') or (Self.UPOenabled)) then
    begin
      if (Self.UPOenabled) then
      begin
        Symbols.TextOutput(Point(Self.pos.X + 15, Self.pos.y), 'UPO', TJopColor.yellow, clBlack, obj);
        Symbols.TextOutput(Point(Self.pos.X + 19, Self.pos.y), Self.hint, TJopColor.yellow, clBlack, obj);
      end else begin
        Symbols.TextOutput(Point(Self.pos.X + 15, Self.pos.y), 'UPO', TJopColor.grayDark, clBlack, obj);
        Symbols.TextOutput(Point(Self.pos.X + 19, Self.pos.y), Self.hint, TJopColor.grayDark, clBlack, obj);
      end;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.ShowStackCMD(ypos: Integer; text: string; first: boolean; selected: boolean; available: boolean;
  dirty: boolean; obj: TDXDraw);
var bk, fg: TColor;
begin
  bk := TJopColor.grayDark;
  fg := TJopColor.black;

  if (first) then
  begin
    bk := clTeal;
    if (available) then
      fg := TJopColor.white
    else
      fg := TJopColor.black;
  end;

  if (selected) then
  begin
    bk := TJopColor.brown;
    fg := TJopColor.white;
  end;

  if (dirty) then
  begin
    fg := TJopColor.black;
    bk := TJopColor.yellow;
  end;

  if (Length(text) > _JC_TEXT_WIDTH) then
    text := LeftStr(text, _JC_TEXT_WIDTH)
  else
  begin
    for var j := 0 to _JC_TEXT_WIDTH - Length(text) do
      text := text + ' ';
  end;

  Symbols.TextOutput(Point(Self.pos.X, Self.pos.y + ypos + 1), ' ' + text, fg, bk, obj);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.MouseClick(Position: TPoint; Button: TPanelButton; var handled: boolean);
var cmdi: Integer;
begin
  // klik na horni symboly
  if ((Position.y = Self.pos.y) and (Button <> TPanelButton.ESCAPE)) then
  begin
    if (Self.EZ = TOREZVolba.closed) then
    begin
      if ((Position.X >= Self.pos.X + 3) and (Position.X <= Self.pos.X + 4)) then
        // VZ
        PanelTCPClient.SendLn(Self.parent + ';ZAS;VZ;')
      else if ((Position.X >= Self.pos.X + 6) and (Position.X <= Self.pos.X + 7)) then
        // PV
        PanelTCPClient.SendLn(Self.parent + ';ZAS;PV;')
    end;

    if ((Position.X >= Self.pos.X + 9) and (Position.X <= Self.pos.X + 10)) then
    // EZ
    begin
      case (Self.EZ) of
        TOREZVolba.closed:
          begin
            if (Self.stack.Count = 0) then
              Exit();
            Self.EZ := please;
            PanelTCPClient.SendLn(Self.parent + ';ZAS;EZ;1');
          end;
        TOREZVolba.openned, TOREZVolba.please:
          begin
            Self.EZ := closed;
            PanelTCPClient.SendLn(Self.parent + ';ZAS;EZ;0;');
          end;
      end; // case
    end;

    // UPO
    if ((Position.X >= Self.pos.X + 15) and (Position.X <= Self.pos.X + 17 + 1 + Length(Self.hint)) and
      (Self.UPOenabled)) then
      PanelTCPClient.SendLn(Self.parent + ';ZAS;UPO;');

    Exit();
  end; // if Position.Y = Self.pos.Y

  // klik na cestu v zasobniku
  if ((Self.EZ = TOREZVolba.openned) and (Position.X >= Self.pos.X) and (Position.X <= Self.pos.X + _JC_TEXT_WIDTH) and
    (Position.y > Self.pos.y) and (Position.y <= Self.pos.y + Self.stack.Count)) then
  begin
    // inside
    if (Button = TPanelButton.ESCAPE) then
    begin
      if (Self.dragged > -1) then
      begin
        Self.selected := -1;
        Self.dragged := -1;
        handled := true;
        Exit();
      end;

      if (Self.selected > -1) then
      begin
        Self.selected := -1;
        handled := true;
        Exit();
      end;

      if (Self.EZ <> TOREZVolba.closed) then
      begin
        Self.EZ := TOREZVolba.closed;
        handled := true;
        Exit();
      end;

    end else begin
      // not escape
      cmdi := Position.y - Self.pos.y - 1;

      if ((Self.dragged = -1) and ((cmdi <> 0) or (Self.first_enabled))) then
      begin
        // select
        Self.selected := cmdi;
        handled := true;
        Exit();
      end;
    end;

  end else begin
    // outside
    if (Self.dragged > -1) then
      Self.dragged := -1;
    if (Self.selected > -1) then
      Self.selected := -1;
    if (Self.EZ <> TOREZVolba.closed) then
      Self.EZ := TOREZVolba.closed;
  end;
end;

procedure TORStack.MouseUp(Position: TPoint; Button: TPanelButton; var handled: boolean);
var cmdi: Integer;
  cmd: TORStackCmd;
begin
  if ((Self.EZ = TOREZVolba.openned) and (Position.X >= Self.pos.X) and (Position.X <= Self.pos.X + _JC_TEXT_WIDTH) and
    (Position.y > Self.pos.y) and (Position.y <= Self.pos.y + Self.stack.Count) and (Button = TPanelButton.F1) and
    (Self.dragged <> -1)) then
  begin
    // drop

    cmdi := Position.y - Self.pos.y - 1;
    try
      if ((cmdi = 0) and (not Self.first_enabled)) then
        cmdi := 1;

      if (cmdi = Self.stack.Count - 1) then
      begin
        PanelTCPClient.SendLn(Self.parent + ';ZAS;SWITCH;' + IntToStr(Self.stack[Self.dragged].id) + ';END');

        cmd := Self.stack[Self.dragged];
        Self.stack.Delete(Self.dragged);
        Self.stack.Add(cmd);
        Self.selected := Self.stack.Count - 1;
      end else begin
        if (cmdi > Self.dragged) then
          PanelTCPClient.SendLn(Self.parent + ';ZAS;SWITCH;' + IntToStr(Self.stack[Self.dragged].id) + ';' +
            IntToStr(Self.stack[cmdi + 1].id))
        else
          PanelTCPClient.SendLn(Self.parent + ';ZAS;SWITCH;' + IntToStr(Self.stack[Self.dragged].id) + ';' +
            IntToStr(Self.stack[cmdi].id));

        cmd := Self.stack[Self.dragged];
        Self.stack.Delete(Self.dragged);
        Self.stack.Insert(cmdi, cmd);
        Self.selected := cmdi;
      end;

      Self.dirty := Self.selected;
    except
      Self.selected := -1;
    end;

    Self.dragged := -1;
    handled := true;
  end;
end;

procedure TORStack.MouseDown(Position: TPoint; Button: TPanelButton; var handled: boolean);
begin
  // klik na cestu v zasobniku
  if ((Self.EZ = TOREZVolba.openned) and (Position.X >= Self.pos.X) and (Position.X <= Self.pos.X + _JC_TEXT_WIDTH) and
    (Position.y > Self.pos.y) and (Position.y <= Self.pos.y + Self.stack.Count) and (Button = TPanelButton.F1) and
    (Self.dirty = -1)) then
  begin
    if (((Position.y - Self.pos.y - 1) <> 0) or (Self.first_enabled)) then
    begin
      Self.dragged := Position.y - Self.pos.y - 1;
      Self.selected := Self.dragged;
      handled := true;
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.KeyPress(key: Integer; var handled: boolean);
begin
  if (Self.EZ = TOREZVolba.openned) then
  begin
    case (key) of
      VK_DELETE:
        begin
          if (Self.selected = 0) and (not Self.first_enabled) then
            Exit();
          if ((Self.selected >= Self.stack.Count) or (Self.selected < 0)) then
            Exit();

          PanelTCPClient.SendLn(Self.parent + ';ZAS;RM;' + IntToStr(Self.stack[Self.selected].id));
          handled := true;
        end;
    end; // case
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TORStack.IsDragged(): boolean;
begin
  Result := (Self.dragged <> -1);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TORStack.SetEZ(new: TOREZVolba);
begin
  if (Self.fEZ = new) then
    Exit();

  Self.fEZ := new;
  if (new = TOREZVolba.closed) then
  begin
    Self.selected := -1;
    Self.dragged := -1;
    Self.dirty := -1;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
