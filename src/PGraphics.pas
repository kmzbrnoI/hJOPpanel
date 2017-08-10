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


////////////////////////////////////////////////////////////////////////////////

end.//unit
