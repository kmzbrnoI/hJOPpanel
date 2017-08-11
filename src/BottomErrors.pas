unit BottomErrors;

{
  Sprava vypisovani technologickych chyb do spodni casti panelu.
}

interface

uses SysUtils, StdCtrls, Graphics, PGraphics, IBUtils, Classes, StrUtils, DXDraws;

const
  _MAX_ERR = 128;
  _ERR_WIDTH = 50;   // symbols
  _TECH_WIDTH = 20;
  _TECH_LEFT  = 2;
  _ERR_SHOW_CNT = 2;

type
  TError = class
   err:string;
   tech:string;
   stanice:string;
   cas:TDateTime;
   techStr:string;
  end;

  TErrors = class
    private
      buf:array [0.._MAX_ERR] of TError;
      buf_len:Integer;

      Graphics:TPanelGraphics;

    public

       constructor Create(Graphics:TPanelGraphics);
       destructor Destroy(); override;

       procedure Show(obj:TDXDraw);

       procedure writeerror(error:string;system:string;Stanice:string);
       procedure removeerror();

       property Count:Integer read buf_len;
  end;

var
  Errors:TErrors;

implementation

uses fMain, Sounds, PanelPainter;

////////////////////////////////////////////////////////////////////////////////

constructor TErrors.Create(Graphics:TPanelGraphics);
var i:Integer;
begin
 inherited Create();

 Self.buf_len := 0;
 Self.Graphics := Graphics;

 for i := 0 to _MAX_ERR do
  Self.buf[i] := nil;

end;//ctor

destructor TErrors.Destroy();
var i:Integer;
begin
 for i := 0 to _MAX_ERR do
  if Assigned(Self.buf[i]) then FreeAndNil(Self.buf[i]);

 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure TErrors.writeerror(error:string; system:string; Stanice:string);
var len:Integer;
    msg:string;
begin
 if (Self.buf_len > _MAX_ERR) then Exit();

 Self.buf[Self.buf_len]         := TError.Create();
 Self.buf[Self.buf_len].err     := error;
 Self.buf[Self.buf_len].tech    := system;
 Self.buf[Self.buf_len].stanice := stanice;

 system := '! '+system+' !';
 if (Length(system) > _TECH_WIDTH) then
   system := LeftStr(system, _TECH_WIDTH);

 len := (_TECH_WIDTH - Length(system)) div 2;
 msg := Format('%*s%s', [len, ' ', system + Format('%-*s', [len, ' '])]);
 if (Length(msg) < _TECH_WIDTH) then msg := msg + ' ';
 Self.buf[Self.buf_len].techStr := msg;

 Self.buf_len := Self.buf_len + 1;

 Self.Graphics.DrawObject.Enabled := false;

 SoundsPlay.Play(_SND_CHYBA);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TErrors.removeerror();
var i:Integer;
begin
 if (Self.buf_len <= 0) then Exit();

 for i := 0 to Self.buf_len-2 do
  Self.buf[i] := Self.buf[i+1];
 Self.buf[Self.buf_len-1] := nil;
 Self.buf_len := Self.buf_len - 1;

 if (Self.buf_len = 0) then
  Self.Graphics.DrawObject.Enabled := true;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TErrors.Show(obj:TDXDraw);
var i, top, left, len:Integer;
    msg:string;
begin
 if (Self.buf_len <= 0) then Exit();

 // vypsani zdroje chyby (napr. "TECHNOLOGIE")
 if (Self.Graphics.blik) then
  msg := Self.buf[0].techStr
 else
  msg := StringOfChar(' ', _TECH_WIDTH);

 PanelPainter.TextOutput(Point(_TECH_LEFT, Relief.PanelHeight - 1), msg, clRed, clWhite, obj);

 // vypsani poctu chyb
 msg := Format('%2d', [Self.buf_len]);
 PanelPainter.TextOutput(Point(_TECH_LEFT+_TECH_WIDTH, Relief.PanelHeight - 1), msg, clBlack, clSilver, obj);

 // vypsani samotnych chyb
 len := Min(_ERR_SHOW_CNT, Self.buf_len);
 top  := Relief.PanelHeight - 1;
 left := (Relief.PanelWidth div 2) - (_ERR_WIDTH div 2) + 10;

 for i := 0 to len-1 do
  begin
   msg := ' '+Self.buf[i].stanice + ' : ' + Self.buf[i].err;
   msg := Format('%-'+IntToStr(_ERR_WIDTH)+'s', [msg]);

   PanelPainter.TextOutput(Point(left, top), msg, clRed, clWhite, obj);

   top := top - 1;
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

initialization

finalization
  FreeAndNil(Errors);

end.//unit
