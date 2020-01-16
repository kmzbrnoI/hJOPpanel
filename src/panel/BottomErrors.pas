unit BottomErrors;

{
  Sprava vypisovani technologickych chyb do spodni casti panelu.
}

interface

uses SysUtils, Graphics, PGraphics, IBUtils, Classes, StrUtils, DXDraws,
     Generics.Collections;

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
      errors: TObjectList<TError>;
      Graphics:TPanelGraphics;

       function GetCount():Cardinal;

    public

       constructor Create(Graphics:TPanelGraphics);
       destructor Destroy(); override;

       procedure Show(obj:TDXDraw);

       procedure WriteError(error:string;system:string;Stanice:string);
       procedure RemoveVisibleErrors();
       procedure RemoveAllErrors();

       property Count:Cardinal read GetCount;
  end;

var
  Errors:TErrors;

implementation

uses fMain, Sounds, PanelPainter;

////////////////////////////////////////////////////////////////////////////////

constructor TErrors.Create(Graphics:TPanelGraphics);
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

////////////////////////////////////////////////////////////////////////////////

function TErrors.GetCount():Cardinal;
begin
 Result := Self.errors.Count;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TErrors.WriteError(error:string; system:string; Stanice:string);
var len:Integer;
    msg:string;
    err:TError;
begin
 if (Self.errors.Count > _MAX_ERR) then Exit();

 err         := TError.Create();
 err.err     := error;
 err.tech    := system;
 err.stanice := stanice;

 system := '! '+system+' !';
 if (Length(system) > _TECH_WIDTH) then
   system := LeftStr(system, _TECH_WIDTH);

 len := (_TECH_WIDTH - Length(system)) div 2;
 msg := Format('%*s%s', [len, ' ', system + Format('%-*s', [len, ' '])]);
 if (Length(msg) < _TECH_WIDTH) then msg := msg + ' ';
 err.techStr := msg;

 Self.errors.Add(err);
 Relief.UpdateEnabled();
 SoundsPlay.Play(_SND_CHYBA);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TErrors.RemoveVisibleErrors();
var i:Integer;
begin
 for i := 0 to _ERR_SHOW_CNT-1 do
   if (Self.errors.Count > 0) then
     Self.errors.Delete(0);

 if (Self.errors.Count = 0) then
   Relief.UpdateEnabled();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TErrors.RemoveAllErrors();
begin
 Self.errors.Clear();
 Relief.UpdateEnabled();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TErrors.Show(obj:TDXDraw);
var i, top, left, len:Integer;
    msg:string;
begin
 if (Self.errors.Count = 0) then Exit();

 // vypsani zdroje chyby (napr. "TECHNOLOGIE")
 if (Self.Graphics.blik) then
  msg := Self.errors[0].techStr
 else
  msg := StringOfChar(' ', _TECH_WIDTH);

 PanelPainter.TextOutput(Point(_TECH_LEFT, Relief.PanelHeight - 1), msg, clRed, clWhite, obj);

 // vypsani poctu chyb
 msg := Format('%2d', [Self.errors.Count]);
 PanelPainter.TextOutput(Point(_TECH_LEFT+_TECH_WIDTH, Relief.PanelHeight - 1), msg, clBlack, clSilver, obj);

 // vypsani samotnych chyb
 len := Min(_ERR_SHOW_CNT, Self.errors.Count);
 top  := Relief.PanelHeight - 1;
 left := (Relief.PanelWidth div 2) - (_ERR_WIDTH div 2) + 10;

 for i := 0 to len-1 do
  begin
   msg := ' '+Self.errors[i].stanice + ' : ' + Self.errors[i].err;
   msg := Format('%-'+IntToStr(_ERR_WIDTH)+'s', [msg]);

   PanelPainter.TextOutput(Point(left, top), msg, clRed, clWhite, obj);

   top := top - 1;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

initialization

finalization
  FreeAndNil(Errors);

end.//unit
