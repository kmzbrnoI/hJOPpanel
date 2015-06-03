unit BottomErrors;

interface

uses SysUtils, StdCtrls, Graphics, PGraphics, IBUtils, Classes, StrUtils;

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
  end;

  TErrors = class
    private
      buf:array [0.._MAX_ERR] of TError;
      buf_len:Integer;

      Graphics:TPanelGraphics;

    public

       constructor Create(Graphics:TPanelGraphics);
       destructor Destroy(); override;

       procedure Show();

       procedure writeerror(error:string;system:string;Stanice:string);
       procedure removeerror();

       property Count:Integer read buf_len;
  end;

var
  Errors:TErrors;

implementation

uses Main, Sounds;

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
begin
 if (Self.buf_len > _MAX_ERR) then Exit();

 Self.buf[Self.buf_len]         := TError.Create();
 Self.buf[Self.buf_len].err     := error;
 Self.buf[Self.buf_len].tech    := system;
 Self.buf[Self.buf_len].stanice := stanice;
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

procedure TErrors.Show();
var i, top, left, len:Integer;
    msg:string;
begin
 if (Self.buf_len <= 0) then Exit();

 if (Self.Graphics.blik) then
  msg := '! '+Self.buf[0].tech+' !'
 else
  msg := '';

 if (Length(msg) > _TECH_WIDTH) then
  msg := LeftStr(msg, _TECH_WIDTH);

 len := (_TECH_WIDTH - Length(msg)) div 2;
 msg := Format('%*s%s', [len, ' ', msg + Format('%-*s', [len, ' '])]);
 if (Length(msg) < _TECH_WIDTH) then msg := msg + ' ';
 Self.Graphics.TextOutput(Point(_TECH_LEFT, Relief.PanelHeight - 1), msg, clRed, clWhite);

 msg := Format('%2d', [Self.buf_len]);
 Self.Graphics.TextOutput(Point(_TECH_LEFT+_TECH_WIDTH, Relief.PanelHeight - 1), msg, clBlack, clSilver);

 len := Min(_ERR_SHOW_CNT, Self.buf_len);

 top  := Relief.PanelHeight - 1;
 left := (Relief.PanelWidth div 2) - (_ERR_WIDTH div 2) + 10;

 for i := 0 to len-1 do
  begin
   msg := ' '+Self.buf[i].stanice + ' : ' + Self.buf[i].err;
   msg := Format('%-'+IntToStr(_ERR_WIDTH)+'s', [msg]);

   Self.Graphics.TextOutput(Point(left, top), msg, clRed, clWhite);

   top := top - 1;
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

initialization

finalization
  FreeAndNil(Errors);

end.//unit
