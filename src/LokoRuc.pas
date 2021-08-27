unit LokoRuc;

{
  Tato unita zobrazuje do panelu seznam lokomotiv v rucnim rizeni.
}

interface

uses Generics.Collections, Classes, SysUtils, PGraphics, Graphics, Math,
  Windows, DXDraws, Types;

type
  TORStackVolba = (PV = 0, VZ = 1);
  TOREZVolba = (closed = 0, please = 1, openned = 2);

  TRucLoko = record
    addr: Word;
    str: string;
    OblR: string;
  end;

  TRucList = class
  private const
    _RL_TEXT_WIDTH = 20;

  private
    lokos: TList<TRucLoko>;

    Graphics: TPanelGraphics;

  public

    constructor Create(Graphics: TPanelGraphics);
    destructor Destroy(); override;

    procedure Show(obj: TDXDraw);
    procedure ParseCommand(data: TStrings);
    procedure Clear();

  end; // TORStack

var
  RucList: TRucList;

implementation

uses TCPCLientPanel, Symbols, BottomErrors;

/// /////////////////////////////////////////////////////////////////////////////

constructor TRucList.Create(Graphics: TPanelGraphics);
begin
  inherited Create();

  Self.lokos := TList<TRucLoko>.Create();
  Self.Graphics := Graphics;
end; // ctor

destructor TRucList.Destroy();
begin
  Self.lokos.Free();
  inherited Destroy();
end; // dtor

/// /////////////////////////////////////////////////////////////////////////////

procedure TRucList.ParseCommand(data: TStrings);
var rl: TRucLoko;
  i: Integer;
begin
  try
    if (data[1] = 'RUC') then
    begin
      for i := 0 to Self.lokos.Count - 1 do
        if ((Self.lokos[i].addr = StrToInt(data[2])) and (Self.lokos[i].OblR = data[0])) then
        begin
          // aktualizace existujiciho zaznamu
          rl := Self.lokos[i];
          rl.str := data[3];
          while (Length(rl.str) < _RL_TEXT_WIDTH) do
            rl.str := rl.str + ' ';
          Self.lokos[i] := rl;
          Exit();
        end;

      // vytvoreni noveho zaznamu
      rl.OblR := data[0];
      rl.addr := StrToInt(data[2]);
      rl.str := data[3];
      while (Length(rl.str) < _RL_TEXT_WIDTH) do
        rl.str := rl.str + ' ';
      Self.lokos.Add(rl);

    end else if (data[1] = 'RUC-RM') then
    begin
      for i := 0 to Self.lokos.Count - 1 do
        if ((Self.lokos[i].addr = StrToInt(data[2])) and (Self.lokos[i].OblR = data[0])) then
        begin
          Self.lokos.Delete(i);
          Exit();
        end;
    end;

  except

  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRucList.Show(obj: TDXDraw);
var left, top: Integer;
begin
  left := (Self.Graphics.PanelWidth div 2) - 5;
  top := Self.Graphics.PanelHeight - 1;

  for var i := 0 to Min(Self.lokos.Count, Errors.ErrorShowCount) - 1 do
  begin
    Symbols.TextOutput(Point(left, top), Self.lokos[i].str, clBlack, clWhite, obj);
    Dec(top);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TRucList.Clear();
begin
  Self.lokos.Clear();
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

finalization

RucList.Free();

end.// unit
