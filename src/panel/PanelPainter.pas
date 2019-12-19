unit PanelPainter;

{
  Zakldni vykreslovaci funkce pro interakci s platnem.
}

interface

uses Controls, Types, Graphics, ImgList, DXDraws;

procedure Draw(IL:TImageList; pos:TPoint; symbol:Integer; fg:TColor; bg:TColor; obj:TDXDraw; transparent:boolean = false);
procedure TextOutput(Pos:TPoint; Text:string; fg, bg:TColor; obj:TDXDraw; underline:boolean = false);

implementation

uses Symbols;

////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////

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
    'š' : TextIndex := 90;
    'ť' : TextIndex := 91;
    'ž' : TextIndex := 92;
    'á' : TextIndex := 93;
    'č' : TextIndex := 94;
    'é' : TextIndex := 95;
    'ě' : TextIndex := 96;
    'í' : TextIndex := 97;
    'ď' : TextIndex := 98;
    'ň' : TextIndex := 99;
    'ó' : TextIndex := 100;
    'ř' : TextIndex := 101;
    'ů' : TextIndex := 102;
    'ú' : TextIndex := 103;
    'ý' : TextIndex := 104;

    'Š' : TextIndex := 105;
    'Ť' : TextIndex := 106;
    'Ž' : TextIndex := 107;
    'Á' : TextIndex := 108;
    'Č' : TextIndex := 109;
    'É' : TextIndex := 110;
    'Ě' : TextIndex := 111;
    'Í' : TextIndex := 112;
    'Ď' : TextIndex := 113;
    'Ň' : TextIndex := 114;
    'Ó' : TextIndex := 115;
    'Ř' : TextIndex := 116;
    'Ů' : TextIndex := 117;
    'Ú' : TextIndex := 118;
    'Ý' : TextIndex := 119;
   else
    TextIndex := 0;
   end;

   SymbolSet.IL_Text.BkColor := bg;
   SymbolSet.IL_Text.Draw(obj.Surface.Canvas, Pos.X*SymbolSet._Symbol_Sirka+(j*SymbolSet._Symbol_Sirka),
                          Pos.Y*SymbolSet._Symbol_Vyska,(TextIndex*Length(_Symbol_Colors))+GetColorIndex(fg));
  end;//for j

 if (underline) then
  begin
   obj.Surface.Canvas.Pen.Color := fg;
   obj.Surface.Canvas.Rectangle(Pos.X*SymbolSet._Symbol_Sirka, (Pos.Y+1)*SymbolSet._Symbol_Vyska-1,
                                (Pos.X+Length(Text))*SymbolSet._Symbol_Sirka, (Pos.Y+1)*SymbolSet._Symbol_Vyska);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//                    VYKRESLOVANI KONKRETNICH OBJEKTU                        //
////////////////////////////////////////////////////////////////////////////////

end.
