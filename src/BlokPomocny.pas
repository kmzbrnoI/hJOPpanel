unit BlokPomocny;

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TPPomocnyObj = record
  Positions:TList<TPoint>;
  Symbol:Integer;
 end;

 TPPomocneObj = class
   data:TList<TPPomocnyObj>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw);
 end;

const
  //zde je definovano, jaky specialni symbol se ma vykreslovat jakou barvou (mimo separatoru)
  _SpecS_DrawColors:array [0..60] of TColor =
    ($A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
    $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
    $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
    $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,clBlue,clBlue,clBlue,$A0A0A0,
    $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
    $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,
    $A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0,$A0A0A0);

implementation

uses PanelPainter, Symbols;

////////////////////////////////////////////////////////////////////////////////

constructor TPPomocneObj.Create();
begin
 inherited;
 Self.data := TList<TPPomocnyObj>.Create();
end;

destructor TPPomocneObj.Destroy();
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
   Self.data[i].Positions.Free();

 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPomocneObj.Load(ini:TMemIniFile);
var i, j, count, count2:Integer;
    po:TPPomocnyObj;
    obj:string;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'P', 0);
 for i := 0 to count-1 do
  begin
   po.Symbol := ini.ReadInteger('P'+IntToStr(i),'S',0);
   po.Positions := TList<TPoint>.Create();

   obj := ini.ReadString('P'+IntToStr(i),'P', '');
   count2 := (Length(obj) div 6);
   for j := 0 to count2 -1 do
     po.Positions.Add( Point( StrToIntDef(copy(obj,j*6+1,3),0), StrToIntDef(copy(obj,j*6+4,3),0) ) );

   Self.data.Add(po);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPomocneObj.Show(obj:TDXDraw);
var po:TPPomocnyObj;
    p:TPoint;
begin
 for po in Self.data do
   for p in po.Positions do
     PanelPainter.Draw(SymbolSet.IL_Symbols, p, po.Symbol, _SpecS_DrawColors[po.Symbol], clBlack, obj);
end;

////////////////////////////////////////////////////////////////////////////////

end.

