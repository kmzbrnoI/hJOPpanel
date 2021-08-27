unit Symbols;

{
  Zakladni operace se symboly, definice pozic symbolu v souboru.
}

interface

uses SysUtils, Controls, Graphics, Classes, Windows, Forms;

const
  _Symbols_DefColor = clBlack; // barva pro nacitani souboru

  // barvy symbolu
  // zde jsou definovany jednotlive barvy
  _SYMBOL_COLORS: array [0 .. 14] of TColor = (
    clFuchsia, // fuchsia
    $A0A0A0, // gray
    clRed,
    clLime,
    clWhite,
    clAqua,
    clBlue,
    clYellow, // yellow
    clBlack,
    clTeal,
    clOlive,
    clPurple,
    clMaroon,
    $707070,
    clGreen
  );

  _S_TURNOUT_B = 0;
  _S_TURNOUT_E = 3;

  _S_DERAIL_B = 12;
  _S_DERAIL_E = 23;

  _S_TRACK_DET_B = 24;
  _S_DKS_DET_TOP = 30;
  _S_DKS_DET_BOT = 31;
  _S_DKS_DET_R = 32;
  _S_DKS_DET_L = 33;
  _S_TRACK_DET_E = 33;

  _S_TRACK_NODET_B = 34;
  _S_DKS_NODET_TOP = 40;
  _S_DKS_NODET_BOT = 41;
  _S_DKS_NODET_R = 42;
  _S_DKS_NODET_L = 43;
  _S_TRACK_NODET_E = 43;

  _S_BUMPER_R = 44;
  _S_BUMPER_L = 45;

  _S_SIGNAL_B = 46;
  _S_SIGNAL_E = 51;

  _S_CROSSING = 52;
  _S_RAILWAY_LEFT = 53;
  _S_RAILWAY_RIGHT = 53;
  _S_LINKER_TRAIN = 55;
  _S_LOCK = 56;
  _S_DISC_TRACK = 57;
  _S_DISC_ALONE = 58;
  _S_PLATFORM_B = 59;
  _S_PLATFORM_E = 61;

  _S_PST_TOP = 62;
  _S_PST_BOT = 63;

  _S_SEPAR_VERT = 71;
  _S_SEPAR_HOR = 72;

  _S_KC = 64;
  _S_FULL = 65;
  _S_HALF_TOP = 66;
  _S_HALF_BOT = 67;
  _S_CIRCLE = 68;
  _S_TRAIN_ARROW_R = 69;
  _S_TRAIN_ARROW_L = 70;

  _RAILWAY_WIDTH_MULT = 2;
  _RAILWAY_HEIGHT_MULT = 1;

  _DK_WIDTH_MULT = 5;
  _DK_HEIGHT_MULT = 3;

type
  TSymbolSetType = (normal = 0, bigger = 1);

  SymbolColor = (
    scFuchsia = 0,
    scGray = 1,
    scRed = 2,
    scLime = 3,
    scWhite = 4,
    scAqua = 5,
    scBlue = 6,
    scYellow = 7,
    scBlack = 8,
    scTeal = 9,
    scOlive = 10,
    scPurple = 11,
    scMaroon = 12,
    scLightGray = 13,
    scGreen = 14
  );

  TOneSymbolSet = record
    Names: record
      Symbols, Text, DK, Trat: string;
    end;

    symbol_width, symbol_height: Integer;
  end;

  // 1 bitmapovy symbol na reliefu (ze symbolu se skladaji useky)
  TReliefSym = record
    Position: TPoint;
    SymbolID: Integer;
  end;

  TSymbolSet = class
  public const
    // tady jsou nadefinovane Resource nazvy ImageListu jendotlivych setu a rozmery jejich symbolu
    Sets: array [0 .. 1] of TOneSymbolSet = (
      // normal
      (Names: (Symbols: 'symbols8'; Text: 'text8'; DK: 'dk8'; Trat: 'trat8';); symbol_width: 8; symbol_height: 12;),

      // bigger
      (Names: (Symbols: 'symbols16'; Text: 'text16'; DK: 'dk16'; Trat: 'trat16';); symbol_width: 16;
      symbol_height: 24;));

  private

    procedure LoadIL(var IL: TImageList; ResourceName: string; PartWidth, PartHeight: Byte;
      MaskColor: TColor = clPurple);
    procedure ReplaceColor(ABitmap: Graphics.TBitmap; ASource, ATarget: TColor; Rect: TRect);

  public

    IL_Symbols: TImageList;
    IL_Text: TImageList;
    IL_DK: TImageList;
    IL_Trat: TImageList;

    symbWidth: Integer;
    symbHeight: Integer;

    constructor Create(typ: TSymbolSetType = normal);
    destructor Destroy(); override;

    procedure LoadSet(typ: TSymbolSetType);
  end;

function ColorToSymbolColor(color: TColor): SymbolColor;
function SymbolIndex(symbol: Integer; color: SymbolColor): Integer; overload;
function SymbolIndex(symbol: Integer; color: TColor): Integer; overload;
function SymbolDrawColor(symbol: Integer): SymbolColor;
function SymbolDefaultColor(symbol: Integer): TColor;
function TranscodeSymbolFromBpnlV3(symbol: Integer): Integer;

var
  SymbolSet: TSymbolSet;

implementation

{$R Resource.res}

uses fSplash;

/// /////////////////////////////////////////////////////////////////////////////

constructor TSymbolSet.Create(typ: TSymbolSetType = normal);
begin
  inherited Create();

  Self.IL_Symbols := TImageList.Create(nil);
  Self.IL_Text := TImageList.Create(nil);
  Self.IL_DK := TImageList.Create(nil);
  Self.IL_Trat := TImageList.Create(nil);

  Self.LoadSet(typ);
end; // ctor

destructor TSymbolSet.Destroy();
begin
  FreeAndNil(Self.IL_Symbols);
  FreeAndNil(Self.IL_Text);
  FreeAndNil(Self.IL_DK);
  FreeAndNil(Self.IL_Trat);

  inherited Destroy();
end; // dtor

/// /////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.LoadSet(typ: TSymbolSetType);
begin
  Self.symbWidth := Self.Sets[Integer(typ)].symbol_width;
  Self.symbHeight := Self.Sets[Integer(typ)].symbol_height;

  F_splash.AddStav('Načítám symboly "symbols" ...');
  Self.LoadIL(Self.IL_Symbols, Self.Sets[Integer(typ)].Names.Symbols, Self.symbWidth, Self.symbHeight);
  F_splash.AddStav('Načítám symboly "text" ...');
  Self.LoadIL(Self.IL_Text, Self.Sets[Integer(typ)].Names.Text, Self.symbWidth, Self.symbHeight);
  F_splash.AddStav('Načítám symboly "DK" ...');
  Self.LoadIL(Self.IL_DK, Self.Sets[Integer(typ)].Names.DK, Self.symbWidth * _DK_WIDTH_MULT,
    Self.symbHeight * _DK_HEIGHT_MULT);
  F_splash.AddStav('Načítám symboly "trat" ...');
  Self.LoadIL(Self.IL_Trat, Self.Sets[Integer(typ)].Names.Trat, Self.symbWidth * _RAILWAY_WIDTH_MULT,
    Self.symbHeight * _RAILWAY_HEIGHT_MULT);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.LoadIL(var IL: TImageList; ResourceName: string; PartWidth, PartHeight: Byte;
  MaskColor: TColor = clPurple);
var AllImages, ColouredImages: Graphics.TBitmap;
  i, symbol: Byte;
begin
  IL := TImageList.Create(nil);

  AllImages := Graphics.TBitmap.Create;
  try
    AllImages.LoadFromResourceName(HInstance, ResourceName);
  except
    raise Exception.Create('Nelze načíst symboly ' + ResourceName + #13#10 + 'Zdroj neexistuje');
    Exit();
  end;

  ColouredImages := Graphics.TBitmap.Create;
  ColouredImages.PixelFormat := pf32Bit;

  IL.SetSize(PartWidth, PartHeight);
  ColouredImages.SetSize(PartWidth * Length(_Symbol_Colors), PartHeight);

  for symbol := 0 to (AllImages.Width div PartWidth) - 1 do
  begin
    for i := 0 to Length(_Symbol_Colors) - 1 do
    begin
      ColouredImages.Canvas.CopyRect(Rect(i * PartWidth, 0, (i * PartWidth) + PartWidth, PartHeight), AllImages.Canvas,
        Rect(symbol * PartWidth, 0, (symbol * PartWidth) + PartWidth, PartHeight));
      Self.ReplaceColor(ColouredImages, _Symbols_DefColor, _Symbol_Colors[i],
        Rect(i * PartWidth, 0, (i * PartWidth) + PartWidth, PartHeight));
    end; // for i

    IL.AddMasked(ColouredImages, MaskColor);
  end; // for symbol

  ColouredImages.Free;
  AllImages.Free;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.ReplaceColor(ABitmap: Graphics.TBitmap; ASource, ATarget: TColor; Rect: TRect);
type
  TRGBBytes = array [0 .. 2] of Byte;
var
  i: Integer;
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
    pf24bit:
      Size := TripleSize;
    pf32Bit:
      Size := SizeOf(TRGBQuad);
  else
    raise Exception.Create('Bitmap must be 24-bit or 32-bit format!');
  end;

  for i := 0 to TripleSize - 1 do
  begin
    // fill the array of bytes with color channel values in BGR order,
    // the same would do for the SourceColor from ASource parameter:
    // SourceColor[0] := GetBValue(ASource);
    // SourceColor[1] := GetGValue(ASource);
    // SourceColor[2] := GetRValue(ASource);
    // but this is (just badly readable) one liner
    SourceColor[i] := Byte(ASource shr (16 - (i * 8)));
    // the same do for the TargetColor array from the ATarget parameter
    TargetColor[i] := Byte(ATarget shr (16 - (i * 8)));
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
      // ⇓             ⇓
      // Pixels   [0][1][2]     [3][4][5]
      // 24-bit    B  G  R       B  G  R

      // X * 4    (0 * 4)       (1 * 4)
      // ⇓             ⇓
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

/// /////////////////////////////////////////////////////////////////////////////
// GLOBALNI FUNKCE                                  //
/// /////////////////////////////////////////////////////////////////////////////

function ColorToSymbolColor(color: TColor): SymbolColor;
begin
  for var i: Integer := 0 to Length(_SYMBOL_COLORS)-1 do
    if (_SYMBOL_COLORS[i] = color) then
      Exit(SymbolColor(i));
  Result := scFuchsia;
end;


/// /////////////////////////////////////////////////////////////////////////////

function SymbolIndex(symbol: Integer; color: SymbolColor): Integer;
begin
  Result := symbol*Length(_SYMBOL_COLORS) + Integer(color);
end;

function SymbolIndex(symbol: Integer; color: TColor): Integer;
begin
  Result := SymbolIndex(symbol, ColorToSymbolColor(color));
end;

/// /////////////////////////////////////////////////////////////////////////////

function TranscodeSymbolFromBpnlV3(symbol: Integer): Integer;
begin
 if ((symbol >= 12) and (symbol <= 17)) then
   Result := symbol-12 + _S_TRACK_DET_B
 else if ((symbol >= 18) and (symbol <= 23)) then
   Result := symbol-18 + _S_TRACK_NODET_B
 else if ((symbol >= 24) and (symbol <= 29)) then
   Result := symbol-24 + _S_SIGNAL_B
 else if (symbol = 30) then
   Result := _S_BUMPER_R
 else if (symbol = 31) then
   Result := _S_BUMPER_L
 else if ((symbol >= 32) and (symbol <= 34)) then
   Result := symbol-32 + _S_PLATFORM_B
 else if (symbol = 40) then
   Result := _S_CROSSING
 else if (symbol = 42) then
   Result := _S_CIRCLE
 else if ((symbol >= 43) and (symbol <= 45)) then
   Result := symbol-43 + _S_RAILWAY_LEFT
 else if ((symbol >= 49) and (symbol <= 54)) then
   Result := symbol-49 + _S_DERAIL_B
 else if ((symbol >= 55) and (symbol <= 56)) then
   Result := symbol-55 + _S_DISC_TRACK
 else if ((symbol >= 58) and (symbol <= 59)) then
   Result := symbol-58 + _S_DKS_DET_TOP
 else
   Result := symbol;
end;

/// /////////////////////////////////////////////////////////////////////////////

function SymbolDrawColor(symbol: Integer): SymbolColor;
begin
  if ((symbol >= _S_PLATFORM_B) and (symbol <= _S_PLATFORM_E)) then
    Result := scBlue
  else if (symbol = _S_LINKER_TRAIN) then
    Result := scYellow
  else
    Result := scGray;
end;

function SymbolDefaultColor(symbol: Integer): TColor;
begin
  Result := _SYMBOL_COLORS[Integer(SymbolDrawColor(symbol))];
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

finalization

if Assigned(SymbolSet) then
  FreeAndNil(SymbolSet);

end.// unit
