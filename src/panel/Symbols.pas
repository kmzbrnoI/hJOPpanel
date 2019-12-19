unit Symbols;

{
  Zakladni operace se symboly, definice pozic symbolu v souboru.
}

interface

uses SysUtils, Controls, Graphics, Classes, RPConst, Windows, Forms;

const
   _Symbols_DefColor = clBlack; //barva pro nacitani souboru

  //barvy symbolu
  //zde jsou definovany jednotlive barvy
  _Symbol_Colors: array [0..13] of TColor =
    ($FF00FF,$A0A0A0,$0000FF,$00FF00,$FFFFFF,$FFFF00,$FF0000,$00FFFF,$000000,
     $808000,$008080,clPurple,clMaroon,$707070);

  _Usek_Start      = 12;
  _Usek_End        = 23;
  _Vyhybka_End     = 3;
  _SCom_Start      = 24;
  _SCom_End        = 29;
  _Plny_Symbol     = 37;
  _Prj_Start       = 40;
  _Hvezdicka       = 41;
  _Kolecko         = 42;
  _Uvazka_Start    = 43;
  _Spr_Sipka_Start = 46;
  _Zamek           = 48;
  _Vykol_Start     = 49;
  _Vykol_End       = 54;
  _Rozp_Start      = 55;
  _DKS_Top         = 58;
  _DKS_Bot         = 59;

  // tady je jen napsano, kolikrat se nasobi puvodni rozmery = kolik symbol zabira poli
  _Trat_Sirka = 2;
  _Trat_Vyska = 1;

  _DK_Sirka = 5;
  _DK_Vyska = 3;

type
  TSymbolSetType = (normal = 0, bigger = 1);

  TOneSymbolSet = record
    Names : record
      Symbols, Text, DK, Trat:string;
    end;
    symbol_width, symbol_height:Integer;
  end;

  // 1 bitmapovy symbol na reliefu (ze symbolu se skladaji useky)
  TReliefSym=record
   Position:TPoint;
   SymbolID:Integer;
  end;

  TSymbolSet = class
    private const
      // tady jsou nadefinovane Resource nazvy ImageListu jendotlivych setu a rozmery jejich symbolu
      Sets : array [0..1] of TOneSymbolSet = (
       // normal
       (
        Names:
         (
          Symbols: 'symbols8';
          Text: 'text8';
          DK: 'dk8';
          Trat: 'trat8';
         );
        symbol_width: 8;
        symbol_height: 12;
       ),

       // bigger
       (
        Names:
         (
          Symbols: 'symbols16';
          Text: 'text16';
          DK: 'dk16';
          Trat: 'trat16';
         );
        symbol_width: 16;
        symbol_height: 24;
       )
      );

    private

      procedure LoadIL(var IL:TImageList; ResourceName:string; PartWidth,PartHeight:Byte; MaskColor:TColor = clPurple);
      procedure ReplaceColor(ABitmap: Graphics.TBitmap; ASource, ATarget: TColor; Rect:TRect);

    public

     IL_Symbols:TImageList;
     IL_Text:TImageList;
     IL_DK:TImageList;
     IL_Trat:TImageList;

     _Symbol_Sirka:Integer;
     _Symbol_Vyska:Integer;

      constructor Create(typ:TSymbolSetType = normal);
      destructor Destroy(); override;

      procedure LoadSet(typ:TSymbolSetType);
  end;

function GetColorIndex(Color:TColor):integer;
function GetSymbolIndex(SymbolID:Integer; Color:TColor):integer;

var
  SymbolSet:TSymbolSet;

implementation
{$R Resource.res}

uses fSplash;

////////////////////////////////////////////////////////////////////////////////

constructor TSymbolSet.Create(typ:TSymbolSetType = normal);
begin
 inherited Create();

 Self.IL_Symbols := TImageList.Create(nil);
 Self.IL_Text    := TImageList.Create(nil);
 Self.IL_DK      := TImageList.Create(nil);
 Self.IL_Trat    := TImageList.Create(nil);

 Self.LoadSet(typ);
end;//ctor

destructor TSymbolSet.Destroy();
begin
 FreeAndNil(Self.IL_Symbols);
 FreeAndNil(Self.IL_Text);
 FreeAndNil(Self.IL_DK);
 FreeAndNil(Self.IL_Trat);

 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.LoadSet(typ:TSymbolSetType);
begin
 Self._Symbol_Sirka := Self.Sets[Integer(typ)].symbol_width;
 Self._Symbol_Vyska := Self.Sets[Integer(typ)].symbol_height;

 F_splash.AddStav('Načítám symboly "symbols" ...');
 Self.LoadIL(Self.IL_Symbols, Self.Sets[Integer(typ)].Names.Symbols, Self._Symbol_Sirka, Self._Symbol_Vyska);
 F_splash.AddStav('Načítám symboly "text" ...');
 Self.LoadIL(Self.IL_Text, Self.Sets[Integer(typ)].Names.Text, Self._Symbol_Sirka, Self._Symbol_Vyska);
 F_splash.AddStav('Načítám symboly "DK" ...');
 Self.LoadIL(Self.IL_DK, Self.Sets[Integer(typ)].Names.DK, Self._Symbol_Sirka*_DK_Sirka, Self._Symbol_Vyska*_DK_Vyska);
 F_splash.AddStav('Načítám symboly "trat" ...');
 Self.LoadIL(Self.IL_Trat, Self.Sets[Integer(typ)].Names.Trat, Self._Symbol_Sirka*_Trat_Sirka, Self._Symbol_Vyska*_Trat_Vyska);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.LoadIL(var IL:TImageList; ResourceName:string; PartWidth,PartHeight:Byte; MaskColor:TColor = clPurple);
var AllImages,ColouredImages:Graphics.TBitmap;
    i,symbol:byte;
begin
 IL := TImageList.Create(nil);

 AllImages := Graphics.TBitmap.Create;
 try
   AllImages.LoadFromResourceName(HInstance, ResourceName);
 except
   raise Exception.Create('Nelze načíst symboly '+ResourceName+#13#10+'Zdroj neexistuje');
   Exit();
 end;

 ColouredImages := Graphics.TBitmap.Create;
 ColouredImages.PixelFormat := pf32Bit;

 IL.SetSize(PartWidth,PartHeight);
 ColouredImages.SetSize(PartWidth*Length(_Symbol_Colors),PartHeight);

 for symbol := 0 to (AllImages.Width div PartWidth)-1 do
  begin
   for i := 0 to Length(_Symbol_Colors)-1 do
    begin
     ColouredImages.Canvas.CopyRect(Rect(i*PartWidth, 0, (i*PartWidth)+PartWidth,PartHeight), AllImages.Canvas, Rect(symbol*PartWidth, 0, (symbol*PartWidth)+PartWidth,PartHeight));
     Self.ReplaceColor(ColouredImages, _Symbols_DefColor, _Symbol_Colors[i], Rect(i*PartWidth, 0, (i*PartWidth)+PartWidth, PartHeight));
    end;//for i

   IL.AddMasked(ColouredImages, MaskColor);
  end;//for symbol

 ColouredImages.Free;
 AllImages.Free;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.ReplaceColor(ABitmap: Graphics.TBitmap; ASource, ATarget: TColor; Rect:TRect);
type
  TRGBBytes = array[0..2] of Byte;
var
  I: Integer;
  X: Integer;
  Y: Integer;
  Size: Integer;
  Pixels: PByteArray;
  SourceColor: TRGBBytes;
  TargetColor: TRGBBytes;
const
  TripleSize = SizeOf(TRGBBytes);
begin
  case ABitmap.PixelFormat of
    pf24bit: Size := TripleSize;
    pf32bit: Size := SizeOf(TRGBQuad);
  else
    raise Exception.Create('Bitmap must be 24-bit or 32-bit format!');
  end;

  for I := 0 to TripleSize - 1 do
  begin
    // fill the array of bytes with color channel values in BGR order,
    // the same would do for the SourceColor from ASource parameter:
    // SourceColor[0] := GetBValue(ASource);
    // SourceColor[1] := GetGValue(ASource);
    // SourceColor[2] := GetRValue(ASource);
    // but this is (just badly readable) one liner
    SourceColor[I] := Byte(ASource shr (16 - (I * 8)));
    // the same do for the TargetColor array from the ATarget parameter
    TargetColor[I] := Byte(ATarget shr (16 - (I * 8)));
  end;

  for Y := Rect.Top to Rect.Bottom - 1 do
  begin
    // get a pointer to the currently iterated row pixel byte array
    Pixels := ABitmap.ScanLine[Y];
    // iterate the row horizontally pixel by pixel
    for X := Rect.Left to Rect.Right - 1 do
    begin
      // now imagine, that you have an array of bytes in which the groups of
      // bytes represent a single pixel - e.g. the used Pixels array for the
      // first 2 pixels might look like this for 24-bit and 32-bit bitmaps:

      // Pixels   [0][1][2]     [3][4][5]
      // 24-bit    B  G  R       B  G  R
      // Pixels   [0][1][2][3]  [4][5][6][7]
      // 32-bit    B  G  R  A    B  G  R  A

      // from the above you can see that you'll need to multiply the current
      // pixel iterator by the count of color channels to point to the first
      // (blue) color channel in that array; and that's what that (X * Size)
      // is for here; X is a pixel iterator, Size is size of a single pixel:

      // X * 3    (0 * 3)       (1 * 3)
      //           ⇓             ⇓
      // Pixels   [0][1][2]     [3][4][5]
      // 24-bit    B  G  R       B  G  R

      // X * 4    (0 * 4)       (1 * 4)
      //           ⇓             ⇓
      // Pixels   [0][1][2][3]  [4][5][6][7]
      // 32-bit    B  G  R  A    B  G  R  A

      // so let's compare a BGR value starting at the (X * Size) position of
      // the Pixels array with the SourceColor array and if it matches we've
      // found the same colored pixel, if so then...
      if CompareMem(@Pixels[(X * Size)], @SourceColor, TripleSize) then
        // copy the TargetColor color byte array values to that BGR position
        // (in other words, replace the color channel bytes there)
        Move(TargetColor, Pixels[(X * Size)], TripleSize);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//                           GLOBALNI FUNKCE                                  //
////////////////////////////////////////////////////////////////////////////////

//TColor -> color index
function GetColorIndex(Color:TColor):integer;
var i:Integer;
begin
 Result := 0;
 for i := 0 to Length(_Symbol_Colors)-1 do
  begin
   if (_Symbol_Colors[i] = Color) then
    begin
     Result := i;
     Break;
    end;
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

function GetSymbolIndex(SymbolID:Integer; Color:TColor):integer;
begin
 Result := (SymbolID * Length(_Symbol_Colors)) + GetColorIndex(Color);
end;

////////////////////////////////////////////////////////////////////////////////

initialization

finalization
  if Assigned(SymbolSet) then
    FreeAndNil(SymbolSet);

end.//unit
