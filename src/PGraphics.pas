unit PGraphics;

// panel graphics
//  je trida, ktera obsahuje vykreslovaci nastroje dostupne pro vsechny podtridy panelu

interface

uses DXDraws, Graphics, Classes, Types, SysUtils, StrUtils;

type
  TPanelGraphics = class
    private

    public

     blik:boolean;                          // pokud neco ma blikat, tady je globalne ulozen jeho stav
                                            // true = sviti, false = zhasnuto
                                            // obsluhu promenne zajistuje timer

      DrawObject:TDXDraw;
      PanelWidth,PanelHeight:SmallInt;

      constructor Create(drawObject:TDXDraw);

      procedure TextOutput(Pos:TPoint;Text:string;Popredi,Pozadi:TColor; underline:boolean = false);
      function GetColorIndex(Color:TColor):integer;
      function GetSymbolIndex(SymbolID:Integer; Color:TColor):integer;
  end;

implementation

uses Symbols;

////////////////////////////////////////////////////////////////////////////////

constructor TPanelGraphics.Create(drawObject:TDXDraw);
begin
 inherited Create();
 Self.DrawObject := drawObject;
end;//ctor

////////////////////////////////////////////////////////////////////////////////

procedure TPanelGraphics.TextOutput(Pos:TPoint;Text:string;Popredi,Pozadi:TColor; underline:boolean = false);
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
    '�' : TextIndex := 90;
    '�' : TextIndex := 91;
    '�' : TextIndex := 92;
    '�' : TextIndex := 93;
    '�' : TextIndex := 94;
    '�' : TextIndex := 95;
    '�' : TextIndex := 96;
    '�' : TextIndex := 97;
    '�' : TextIndex := 98;
    '�' : TextIndex := 99;
    '�' : TextIndex := 100;
    '�' : TextIndex := 101;
    '�' : TextIndex := 102;
    '�' : TextIndex := 103;
    '�' : TextIndex := 104;

    '�' : TextIndex := 105;
    '�' : TextIndex := 106;
    '�' : TextIndex := 107;
    '�' : TextIndex := 108;
    '�' : TextIndex := 109;
    '�' : TextIndex := 110;
    '�' : TextIndex := 111;
    '�' : TextIndex := 112;
    '�' : TextIndex := 113;
    '�' : TextIndex := 114;
    '�' : TextIndex := 115;
    '�' : TextIndex := 116;
    '�' : TextIndex := 117;
    '�' : TextIndex := 118;
    '�' : TextIndex := 119;
   else
    TextIndex := 0;
   end;

   SymbolSet.IL_Text.BkColor := Pozadi;
   SymbolSet.IL_Text.Draw(Self.DrawObject.Surface.Canvas, Pos.X*SymbolSet._Symbol_Sirka+(j*SymbolSet._Symbol_Sirka),
                          Pos.Y*SymbolSet._Symbol_Vyska,(TextIndex*_Symbol_ColorsCount)+Self.GetColorIndex(Popredi));
  end;//for j

 if (underline) then
  begin
   Self.DrawObject.Surface.Canvas.Pen.Color := Popredi;
   Self.DrawObject.Surface.Canvas.Rectangle(Pos.X*SymbolSet._Symbol_Sirka, (Pos.Y+1)*SymbolSet._Symbol_Vyska-1,
                                            (Pos.X+Length(Text))*SymbolSet._Symbol_Sirka, (Pos.Y+1)*SymbolSet._Symbol_Vyska);
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//TColor -> color index
function TPanelGraphics.GetColorIndex(Color:TColor):integer;
var i:Integer;
begin
 Result := 0;
 for i := 0 to _Symbol_ColorsCount-1 do
  begin
   if (_Symbol_Colors[i] = Color) then
    begin
     Result := i;
     Break;
    end;
  end;//for i
end;//function

////////////////////////////////////////////////////////////////////////////////

function TPanelGraphics.GetSymbolIndex(SymbolID:Integer; Color:TColor):integer;
begin
 Result := (SymbolID * _Symbol_ColorsCount) + Self.GetColorIndex(Color);
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
