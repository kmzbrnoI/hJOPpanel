﻿unit UPO;

{
  Unita resici vykreslovani upozorneni v leve dolni casti reliefu.
  Jedna se napriklad o upozorneni pri staveni jizdnich cest (napr. "kolejovy usek zapevnen").
}

interface

uses PGraphics, Classes, Graphics, Generics.Collections, StrUtils, Windows,
  DXDraws, Types;

const
  _UPO_WIDTH = 36;
  _UPO_HEIGHT = 4;

type
  TPanelUPOLine = record
    str: string;
    fg: TColor;
    bg: TColor;
    align: TAlignment;
  end;

  TPanelUPOItem = record
    lines: array [0 .. _UPO_HEIGHT - 2] of TPanelUPOLine;
  end;

  TPanelUPO = class
  private
    fshowing: boolean;
    Graphics: TPanelGraphics;
    items: TList<TPanelUPOItem>;
    critical: boolean;
    current: Integer; // aktualni index v poli Items

    procedure SetShowing(showing: boolean);

  public

    constructor Create(Graphics: TPanelGraphics);
    destructor Destroy(); override;

    procedure Show(obj: TDXDraw);
    procedure ParseCommand(data: string; critical: boolean);
    procedure KeyPress(key: Integer; var handled: boolean);

    property showing: boolean read fshowing write SetShowing;

  end; // TORStack

implementation

uses TCPClientPanel, fMain, parseHelper, Symbols;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPanelUPO.Create(Graphics: TPanelGraphics);
begin
  inherited Create();
  Self.critical := false;
  Self.fshowing := false;
  Self.Graphics := Graphics;
  Self.items := TList<TPanelUPOItem>.Create();
end;

destructor TPanelUPO.Destroy();
begin
  Self.items.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelUPO.Show(obj: TDXDraw);
var str: string;
begin
  if (not Self.showing) then
    Exit();

  if (Self.current >= Self.items.Count) then
  begin
    Self.fshowing := false;
    Exit();
  end;

  // show items
  for var i := 0 to 2 do
  begin
    if (Length(Self.items[Self.current].lines[i].str) > _UPO_WIDTH) then
      str := LeftStr(Self.items[Self.current].lines[i].str, _UPO_WIDTH);

    case (Self.items[Self.current].lines[i].align) of
      taCenter:
        begin
          str := '';
          for var j := 0 to ((_UPO_WIDTH - Length(Self.items[Self.current].lines[i].str)) div 2) - 1 do
            str := str + ' ';
          str := str + Self.items[Self.current].lines[i].str;
          while (Length(str) < _UPO_WIDTH) do
            str := str + ' ';
        end; // taCenter

      taLeftJustify:
        begin
          str := Self.items[Self.current].lines[i].str;
          while (Length(str) < _UPO_WIDTH) do
            str := str + ' ';
        end; // taLeftJustify

      taRightJustify:
        begin
          for var j := 0 to (_UPO_WIDTH - Length(Self.items[Self.current].lines[i].str)) - 1 do
            str := str + ' ';
          str := str + Self.items[Self.current].lines[i].str;
        end; // taRightJustify
    end; // case

    Symbols.TextOutput(Point(0, Self.Graphics.pHeight - _UPO_HEIGHT + i), str,
      Self.items[Self.current].lines[i].fg, Self.items[Self.current].lines[i].bg, obj);
  end; // for i

  // vykresleni informaceo pokracovani
  if ((Self.critical) and (Self.current = Self.items.Count - 1)) then
    Symbols.TextOutput(Point(0, Self.Graphics.pHeight - 1), '          Ukončení: ESCAPE          ', clBlack,
      TJopColor.turqDark, obj)
  else
    Symbols.TextOutput(Point(0, Self.Graphics.pHeight - 1), '  Pokračovat: ENTER, konec: ESCAPE  ', clBlack,
      TJopColor.turqDark, obj);
end;

/// /////////////////////////////////////////////////////////////////////////////

// -;UPO;[item1][item2]                    - upozorneni
// -;UPO-CRIT;[item1][item2]               - kriticke upozorneni - nelze porkacovat dale
// format [item_x]:
// (radek1)(radek2)(radek3)
// radek_x: fg|bg|text         barvy na dalsich radcich nemusi byt vyplnene, pak prebiraji tu barvu, jako radek predchozi
procedure TPanelUPO.ParseCommand(data: string; critical: boolean);
var items, lines, line: TStrings;

begin
  items := TStringList.Create();
  lines := TStringList.Create();
  line := TStringList.Create();

  try
    Self.critical := critical;

    Self.items.Clear();
    ExtractStringsEx([']'], ['['], data, items);

    for var i := 0 to items.Count - 1 do
    begin
      var item: TPanelUPOItem;

      lines.Clear();
      ExtractStringsEx([']'], ['['], items[i], lines);

      if (lines.Count = 0) then
        continue;

      for var j := 0 to lines.Count - 1 do
      begin
        if (j > _UPO_HEIGHT - 2) then
          break;

        line.Clear();
        ExtractStringsEx(['|'], [], lines[j], line);

        // parsovani zarovnani
        if (line.Count > 1) then
        begin
          case (line[0][1]) of
            'L':
              item.lines[j].align := taLeftJustify;
            'R':
              item.lines[j].align := taRightJustify;
            'M':
              item.lines[j].align := taCenter;
          end; // case
        end else begin
          item.lines[j].align := taCenter;
        end;

        // parsvani barvy popredi
        if (line.Count > 2) then
          item.lines[j].fg := PanelTCPClient.StrToColor(line[1])
        else
        begin
          if (j > 0) then
            item.lines[j].fg := item.lines[j - 1].fg
          else
            item.lines[j].fg := TJopColor.red;
        end;

        // parsovani barvy pozadi
        if (line.Count > 3) then
          item.lines[j].bg := PanelTCPClient.StrToColor(line[2])
        else
        begin
          if (j > 0) then
            item.lines[j].bg := item.lines[j - 1].bg
          else
            item.lines[j].bg := TJopColor.white;
        end;

        item.lines[j].str := line[line.Count - 1];
      end; // for j

      if (lines.Count < _UPO_HEIGHT - 1) then
      begin
        for var j := lines.Count to _UPO_HEIGHT - 2 do
        begin
          item.lines[j].str := '';
          item.lines[j].fg := item.lines[j - 1].fg;
          item.lines[j].bg := item.lines[j - 1].bg;
          item.lines[j].align := taLeftJustify;
        end;
      end; // if

      Self.items.Add(item);
    end; // for i

    Self.showing := true;
    Self.current := 0;
  finally
    items.Free();
    lines.Free();
    line.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelUPO.KeyPress(key: Integer; var handled: boolean);
begin
  if (not Self.showing) then
    Exit();

  case (key) of
    VK_RETURN:
      begin
        if (Self.current < Self.items.Count - 1) then
          Inc(Self.current)
        else
        begin
          if (Self.critical) then
            Exit();
          PanelTCPClient.SendLn('-;UPO;OK');
          Self.showing := false;
        end;

        handled := true;
      end;

    VK_ESCAPE:
      begin
        PanelTCPClient.SendLn('-;UPO;ESC');
        Self.showing := false;
        handled := true;
      end;
  end; // case
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TPanelUPO.SetShowing(showing: boolean);
var changed: boolean;
begin
  changed := (showing <> Self.fshowing);
  Self.fshowing := showing;
  if (changed) then
    Relief.UpdateEnabled();
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
