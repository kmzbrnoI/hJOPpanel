unit PGraphics;

{
  Panel graphics je trida, ktera obsahuje vykreslovaci nastroje dostupne pro
  vsechny podtridy panelu.
}

interface

uses DXDraws, Graphics, Classes;

type
  TPanelGraphics = class
    blik: boolean; // pokud neco ma blikat, tady je globalne ulozen jeho stav
    // true = sviti, false = zhasnuto
    // obsluhu promenne zajistuje timer

    DrawObject: TDXDraw;
    PanelWidth, PanelHeight: SmallInt;

    constructor Create(DrawObject: TDXDraw);
  end;

implementation

uses Symbols;

/// /////////////////////////////////////////////////////////////////////////////

constructor TPanelGraphics.Create(DrawObject: TDXDraw);
begin
  inherited Create();
  Self.DrawObject := DrawObject;
end; // ctor

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
