unit Symbols;

{
  Basic operations with relief symbols, definition of symbols colors, symbol
  positions etc.
}

interface

uses SysUtils, Controls, Graphics, Classes, Windows, Forms, DXDraws, ImgList;

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
  _S_RAILWAY_RIGHT = 54;
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
    names: record
      symbols, text, area, railway: string;
    end;

    symbolWidth, symbolHeight: Integer;
  end;

  // 1 bitmapovy symbol na reliefu (ze symbolu se skladaji useky)
  TReliefSym = record
    Position: TPoint;
    SymbolID: Integer;
  end;

  TSymbolSet = class
  public const
    // tady jsou nadefinovane Resource nazvy ImageListu jendotlivych setu a rozmery jejich symbolu
    sets: array [0 .. 1] of TOneSymbolSet = (
      // normal
      (names: (symbols: 'symbols8'; text: 'text8'; area: 'dk8'; railway: 'trat8';); symbolWidth: 8; symbolHeight: 12;),

      // bigger
      (names: (symbols: 'symbols16'; text: 'text16'; area: 'dk16'; railway: 'trat16';); symbolWidth: 16;
      symbolHeight: 24;));

  private

    procedure LoadIL(var IL: TImageList; ResourceName: string; PartWidth, PartHeight: Cardinal;
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

procedure Draw(IL: TImageList; pos: TPoint; symbol: Integer; fg: TColor; bg: TColor; obj: TDXDraw;
  transparent: boolean = false);
procedure TextOutput(pos: TPoint; Text: string; fg, bg: TColor; obj: TDXDraw; underline: boolean = false;
  transparent: boolean = false);

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
end;

destructor TSymbolSet.Destroy();
begin
  FreeAndNil(Self.IL_Symbols);
  FreeAndNil(Self.IL_Text);
  FreeAndNil(Self.IL_DK);
  FreeAndNil(Self.IL_Trat);

  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.LoadSet(typ: TSymbolSetType);
begin
  Self.symbWidth := Self.sets[Integer(typ)].symbolWidth;
  Self.symbHeight := Self.sets[Integer(typ)].symbolHeight;

  F_splash.ShowState('Načítám symboly "symbols" ...');
  Self.LoadIL(Self.IL_Symbols, Self.sets[Integer(typ)].Names.Symbols, Self.symbWidth, Self.symbHeight);
  F_splash.ShowState('Načítám symboly "text" ...');
  Self.LoadIL(Self.IL_Text, Self.sets[Integer(typ)].Names.Text, Self.symbWidth, Self.symbHeight);
  F_splash.ShowState('Načítám symboly "DK" ...');
  Self.LoadIL(Self.IL_DK, Self.sets[Integer(typ)].Names.area, Self.symbWidth * _DK_WIDTH_MULT,
    Self.symbHeight * _DK_HEIGHT_MULT);
  F_splash.ShowState('Načítám symboly "trat" ...');
  Self.LoadIL(Self.IL_Trat, Self.sets[Integer(typ)].Names.railway, Self.symbWidth * _RAILWAY_WIDTH_MULT,
    Self.symbHeight * _RAILWAY_HEIGHT_MULT);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.LoadIL(var IL: TImageList; ResourceName: string; PartWidth, PartHeight: Cardinal;
  MaskColor: TColor = clPurple);
var AllImages, ColouredImages: Graphics.TBitmap;
begin
  IL := TImageList.Create(nil);
  AllImages := Graphics.TBitmap.Create();
  ColouredImages := Graphics.TBitmap.Create();

  try
    try
      AllImages.LoadFromResourceName(HInstance, ResourceName);
    except
      raise Exception.Create('Nelze načíst symboly ' + ResourceName + #13#10 + 'Zdroj neexistuje');
      Exit();
    end;

    ColouredImages.PixelFormat := pf32Bit;
    IL.SetSize(PartWidth, PartHeight);
    ColouredImages.SetSize(PartWidth * Length(_SYMBOL_COLORS), PartHeight);

    for var symbol: Cardinal := 0 to (AllImages.Width div PartWidth) - 1 do
    begin
      for var i: Cardinal := 0 to Length(_Symbol_Colors) - 1 do
      begin
        ColouredImages.Canvas.CopyRect(Rect(i * PartWidth, 0, (i * PartWidth) + PartWidth, PartHeight), AllImages.Canvas,
          Rect(symbol * PartWidth, 0, (symbol * PartWidth) + PartWidth, PartHeight));
        Self.ReplaceColor(ColouredImages, _Symbols_DefColor, _Symbol_Colors[i],
          Rect(i * PartWidth, 0, (i * PartWidth) + PartWidth, PartHeight));
      end; // for i

      IL.AddMasked(ColouredImages, MaskColor);
    end;
  finally
    ColouredImages.Free();
    AllImages.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSymbolSet.ReplaceColor(ABitmap: Graphics.TBitmap; ASource, ATarget: TColor; Rect: TRect);
type
  TRGBBytes = array [0 .. 2] of Byte;
var
  Size: Integer;
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

  for var i := 0 to TripleSize - 1 do
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

  for var Y := Rect.Top to Rect.Bottom - 1 do
  begin
    // get a pointer to the currently iterated row pixel byte array
    var Pixels: PByteArray := ABitmap.ScanLine[Y];
    // iterate the row horizontally pixel by pixel
    for var X := Rect.Left to Rect.Right - 1 do
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

procedure Draw(IL: TImageList; pos: TPoint; symbol: Integer; fg: TColor; bg: TColor; obj: TDXDraw;
  transparent: boolean = false);
var item: Integer;
begin
  // transparent is faster

  if (transparent) then
    IL.DrawingStyle := TDrawingStyle.dsTransparent
  else
    IL.DrawingStyle := TDrawingStyle.dsNormal;

  if ((bg <> clBlack) and (not transparent)) then
  begin
    // black is default
    obj.Surface.Canvas.Pen.Color := bg;
    obj.Surface.Canvas.Brush.Color := bg;
    obj.Surface.Canvas.Rectangle(pos.X * SymbolSet.symbWidth, pos.Y * SymbolSet.symbHeight,
      (pos.X + 1) * SymbolSet.symbWidth, (pos.Y + 1) * SymbolSet.symbHeight);
  end;

  item := SymbolIndex(symbol, fg);
  IL.Draw(obj.Surface.Canvas, pos.X * SymbolSet.symbWidth, pos.Y * SymbolSet.symbHeight, item);
  IL.DrawingStyle := TDrawingStyle.dsNormal;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TextOutput(pos: TPoint; Text: string; fg, bg: TColor; obj: TDXDraw; underline: boolean = false;
  transparent: boolean = false);
var TextIndex: Integer;
begin
  // transparent is faster

  if (not transparent) then
  begin
    obj.Surface.Canvas.Pen.Color := bg;
    obj.Surface.Canvas.Brush.Color := bg;
    obj.Surface.Canvas.Rectangle(pos.X * SymbolSet.symbWidth, pos.Y * SymbolSet.symbHeight,
      (pos.X + Length(Text)) * SymbolSet.symbWidth, (pos.Y + 1) * SymbolSet.symbHeight);
  end;

  for var j := 0 to Length(Text) - 1 do
  begin
    case (Text[j + 1]) of
      #32 .. #90:
        TextIndex := ord(Text[j + 1]) - 32;
      #97 .. #122:
        TextIndex := ord(Text[j + 1]) - 97 + 59;
      'š':
        TextIndex := 90;
      'ť':
        TextIndex := 91;
      'ž':
        TextIndex := 92;
      'á':
        TextIndex := 93;
      'č':
        TextIndex := 94;
      'é':
        TextIndex := 95;
      'ě':
        TextIndex := 96;
      'í':
        TextIndex := 97;
      'ď':
        TextIndex := 98;
      'ň':
        TextIndex := 99;
      'ó':
        TextIndex := 100;
      'ř':
        TextIndex := 101;
      'ů':
        TextIndex := 102;
      'ú':
        TextIndex := 103;
      'ý':
        TextIndex := 104;

      'Š':
        TextIndex := 105;
      'Ť':
        TextIndex := 106;
      'Ž':
        TextIndex := 107;
      'Á':
        TextIndex := 108;
      'Č':
        TextIndex := 109;
      'É':
        TextIndex := 110;
      'Ě':
        TextIndex := 111;
      'Í':
        TextIndex := 112;
      'Ď':
        TextIndex := 113;
      'Ň':
        TextIndex := 114;
      'Ó':
        TextIndex := 115;
      'Ř':
        TextIndex := 116;
      'Ů':
        TextIndex := 117;
      'Ú':
        TextIndex := 118;
      'Ý':
        TextIndex := 119;
    else
      TextIndex := 0;
    end;

    SymbolSet.IL_Text.Draw(obj.Surface.Canvas, pos.X * SymbolSet.symbWidth + (j * SymbolSet.symbWidth),
      pos.Y * SymbolSet.symbHeight, SymbolIndex(TextIndex, fg));
  end; // for j

  if (underline) then
  begin
    obj.Surface.Canvas.Pen.Color := fg;
    obj.Surface.Canvas.Rectangle(pos.X * SymbolSet.symbWidth, (pos.Y + 1) * SymbolSet.symbHeight - 1,
      (pos.X + Length(Text)) * SymbolSet.symbWidth, (pos.Y + 1) * SymbolSet.symbHeight);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

finalization

if (Assigned(SymbolSet)) then
  FreeAndNil(SymbolSet);

end.
