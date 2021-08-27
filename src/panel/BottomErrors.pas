unit BottomErrors;

{
  Printing of error messages in bottom part of panel.
}

interface

uses SysUtils, Graphics, PGraphics, Classes, StrUtils, DXDraws, Math,
  Generics.Collections, Types;

const
  _MAX_ERR = 128;
  _ERR_WIDTH = 50; // symbols
  _TECH_WIDTH = 20;
  _TECH_LEFT = 2;

type
  TError = class
    err: string;
    tech: string;
    stanice: string;
    cas: TDateTime;
    techStr: string;
  end;

  TErrors = class
  private
    errors: TObjectList<TError>;
    Graphics: TPanelGraphics;

    function GetCount(): Cardinal;
    function GetErrorShowCount(): Cardinal;

  public

    constructor Create(Graphics: TPanelGraphics);
    destructor Destroy(); override;

    procedure Show(obj: TDXDraw);

    procedure WriteError(error: string; system: string; stanice: string);
    procedure RemoveVisibleErrors();
    procedure RemoveAllErrors();

    property Count: Cardinal read GetCount;
    property ErrorShowCount: Cardinal read GetErrorShowCount;
  end;

var
  errors: TErrors;

implementation

uses fMain, Sounds, Symbols;

/// /////////////////////////////////////////////////////////////////////////////

constructor TErrors.Create(Graphics: TPanelGraphics);
begin
  inherited Create();

  Self.Graphics := Graphics;
  Self.errors := TObjectList<TError>.Create();
end;

destructor TErrors.Destroy();
begin
  Self.errors.Free(); // will destroy all error automatically

  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TErrors.GetCount(): Cardinal;
begin
  Result := Self.errors.Count;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TErrors.WriteError(error: string; system: string; stanice: string);
begin
  if (Self.errors.Count > _MAX_ERR) then
    Exit();

  var err := TError.Create();
  err.err := error;
  err.tech := system;
  err.stanice := stanice;

  system := '! ' + system + ' !';
  if (Length(system) > _TECH_WIDTH) then
    system := LeftStr(system, _TECH_WIDTH);

  var len := (_TECH_WIDTH - Length(system)) div 2;
  var msg := Format('%*s%s', [len, ' ', system + Format('%-*s', [len, ' '])]);
  if (Length(msg) < _TECH_WIDTH) then
    msg := msg + ' ';
  err.techStr := msg;

  Self.errors.Add(err);
  Relief.UpdateEnabled();
  SoundsPlay.Play(_SND_CHYBA);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TErrors.RemoveVisibleErrors();
begin
  for var i := 0 to Self.ErrorShowCount - 1 do
    if (Self.errors.Count > 0) then
      Self.errors.Delete(0);

  if (Self.errors.Count = 0) then
    Relief.UpdateEnabled();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TErrors.RemoveAllErrors();
begin
  Self.errors.Clear();
  Relief.UpdateEnabled();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TErrors.Show(obj: TDXDraw);
var msg: string;
begin
  if (Self.errors.Count = 0) then
    Exit();

  // vypsani zdroje chyby (napr. "TECHNOLOGIE")
  if (Self.Graphics.flash) then
    msg := Self.errors[0].techStr
  else
    msg := StringOfChar(' ', _TECH_WIDTH);

  Symbols.TextOutput(Point(_TECH_LEFT, Relief.height - 1), msg, clRed, clWhite, obj);

  // vypsani poctu chyb
  msg := Format('%2d', [Self.errors.Count]);
  Symbols.TextOutput(Point(_TECH_LEFT + _TECH_WIDTH, Relief.height - 1), msg, clBlack, clSilver, obj);

  // vypsani samotnych chyb
  var len := Min(Self.ErrorShowCount, Self.errors.Count);
  var top := Relief.height - 1;
  var left := (Relief.width div 2) - (_ERR_WIDTH div 2) + 10;

  for var i := 0 to len - 1 do
  begin
    msg := ' ' + Self.errors[i].stanice + ' : ' + Self.errors[i].err;
    msg := Format('%-' + IntToStr(_ERR_WIDTH) + 's', [msg]);

    Symbols.TextOutput(Point(left, top), msg, clRed, clWhite, obj);

    top := top - 1;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TErrors.GetErrorShowCount(): Cardinal;
begin
  if (Self.Graphics.pHeight > 25) then
    Result := 4
  else
    Result := 2;
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

finalization

FreeAndNil(errors);

end.// unit
