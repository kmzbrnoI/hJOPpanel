unit PanelPainter;

interface

uses Controls, Types, Graphics, ImgList, DXDraws;

procedure Draw(IL:TImageList; pos:TPoint; symbol:Integer; fg:TColor; bg:TColor; obj:TDXDraw; transparent:boolean = false);
procedure TextOutput(Pos:TPoint; Text:string; fg, bg:TColor; obj:TDXDraw; underline:boolean = false);

implementation

uses Symbols;

procedure Draw(IL:TImageList; pos:TPoint; symbol:Integer; fg:TColor; bg:TColor; obj:TDXDraw; transparent:boolean = false);
begin
 if (transparent) then
   IL.DrawingStyle := TDrawingStyle.dsTransparent
 else begin
   IL.DrawingStyle := TDrawingStyle.dsNormal;
   IL.BkColor := bg;
 end;

 IL.Draw(obj.Surface.Canvas, pos.X * SymbolSet._Symbol_Sirka,
         pos.Y * SymbolSet._Symbol_Vyska, GetSymbolIndex(symbol, fg));

 IL.DrawingStyle := TDrawingStyle.dsNormal;
end;

procedure TextOutput(Pos:TPoint; Text:string; fg, bg:TColor; obj:TDXDraw; underline:boolean = false);
var j:Integer;
    TextIndex:Integer;
begin
 for j := 0 to Length(Text)-1 do
  begin
   //prevedeni textu na indexy v ImageListu
   //texty v image listu jsou ilozeny v ASCII, coz tyto Delphi evidentne neumi zchroustat
   // proto tato silenost....
   case (Text[j+1]) of
    #32..#90:  TextIndex := ord(Text[j+1])-32;
    #97..#122: TextIndex := ord(Text[j+1])-97+59;
    'ö' : TextIndex := 90;
    'ù' : TextIndex := 91;
    'û' : TextIndex := 92;
    '·' : TextIndex := 93;
    'Ë' : TextIndex := 94;
    'È' : TextIndex := 95;
    'Ï' : TextIndex := 96;
    'Ì' : TextIndex := 97;
    'Ô' : TextIndex := 98;
    'Ú' : TextIndex := 99;
    'Û' : TextIndex := 100;
    '¯' : TextIndex := 101;
    '˘' : TextIndex := 102;
    '˙' : TextIndex := 103;
    '˝' : TextIndex := 104;

    'ä' : TextIndex := 105;
    'ç' : TextIndex := 106;
    'é' : TextIndex := 107;
    '¡' : TextIndex := 108;
    '»' : TextIndex := 109;
    '…' : TextIndex := 110;
    'Ã' : TextIndex := 111;
    'Õ' : TextIndex := 112;
    'œ' : TextIndex := 113;
    '“' : TextIndex := 114;
    '”' : TextIndex := 115;
    'ÿ' : TextIndex := 116;
    'Ÿ' : TextIndex := 117;
    '⁄' : TextIndex := 118;
    '›' : TextIndex := 119;
   else
    TextIndex := 0;
   end;

   SymbolSet.IL_Text.BkColor := bg;
   SymbolSet.IL_Text.Draw(obj.Surface.Canvas, Pos.X*SymbolSet._Symbol_Sirka+(j*SymbolSet._Symbol_Sirka),
                          Pos.Y*SymbolSet._Symbol_Vyska,(TextIndex*_Symbol_ColorsCount)+GetColorIndex(fg));
  end;//for j

 if (underline) then
  begin
   obj.Surface.Canvas.Pen.Color := fg;
   obj.Surface.Canvas.Rectangle(Pos.X*SymbolSet._Symbol_Sirka, (Pos.Y+1)*SymbolSet._Symbol_Vyska-1,
                                (Pos.X+Length(Text))*SymbolSet._Symbol_Sirka, (Pos.Y+1)*SymbolSet._Symbol_Vyska);
  end;
end;//procedure

end.
