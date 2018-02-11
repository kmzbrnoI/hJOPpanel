unit BlokPopisek;

{
  Definice bloku popisek a jeho vlastnosti.
  Definice databaze popisku.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
     BlokPrejezd;

type
 TPopisekPanelProp = record
  Symbol, Pozadi: TColor;
  left, right: TColor;
  blikani:boolean;
 end;

 TPPopisek = record
  Text:string;
  Position:TPoint;
  Color:Integer;
  Blok:Integer;

  PanelProp: TPopisekPanelProp;
 end;


 TPPopisky = class
   data:TList<TPPopisek>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile; prejezdy:TPPrejezdy);
   procedure Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
   function GetIndex(Pos:TPoint):Integer;
 end;

const
  _Def_Popisek_Prop:TPopisekPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      left: clFuchsia;
      right: clFuchsia;
      blikani: false
  );

implementation

uses PanelPainter, Symbols;

////////////////////////////////////////////////////////////////////////////////

constructor TPPopisky.Create();
begin
 inherited;
 Self.data := TList<TPPopisek>.Create();
end;

destructor TPPopisky.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPopisky.Load(ini:TMemIniFile; prejezdy:TPPrejezdy);
var i, count: Integer;
    popisek:TPPopisek;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'T',   0);
 for i := 0 to count-1 do
  begin
   popisek.Text        := ini.ReadString('T'+IntToStr(i),'T','0');
   popisek.Position.X  := ini.ReadInteger('T'+IntToStr(i),'X',0);
   popisek.Position.Y  := ini.ReadInteger('T'+IntToStr(i),'Y',0);
   popisek.Color       := ini.ReadInteger('T'+IntToStr(i),'C',0);
   popisek.Blok        := ini.ReadInteger('T'+IntToStr(i),'B', -1);

   popisek.PanelProp := _Def_Popisek_Prop;

   Self.data.Add(popisek);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPopisky.Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
var popisek:TPPopisek;
begin
 for popisek in Self.data do
  begin
   if (popisek.Blok > -1) then
    begin
     // popisek ma referenci na souctovou hlasku

     obj.Surface.Canvas.Brush.Color := popisek.PanelProp.left;
     obj.Surface.Canvas.Pen.Color := obj.Surface.Canvas.Brush.Color;
     obj.Surface.Canvas.Rectangle((popisek.Position.X-1)*SymbolSet._Symbol_Sirka,
       popisek.Position.Y*SymbolSet._Symbol_Vyska, (popisek.Position.X)*SymbolSet._Symbol_Sirka,
       (popisek.Position.Y+1)*SymbolSet._Symbol_Vyska);

     obj.Surface.Canvas.Brush.Color := popisek.PanelProp.right;
     obj.Surface.Canvas.Pen.Color   := obj.Surface.Canvas.Brush.Color;
     obj.Surface.Canvas.Rectangle((popisek.Position.X+1)*SymbolSet._Symbol_Sirka,
       popisek.Position.Y*SymbolSet._Symbol_Vyska, (popisek.Position.X+2)*SymbolSet._Symbol_Sirka,
       (popisek.Position.Y+1)*SymbolSet._Symbol_Vyska);

     PanelPainter.TextOutput(popisek.Position, popisek.Text,
        popisek.PanelProp.Symbol, popisek.PanelProp.Pozadi, obj);
    end else begin
     PanelPainter.TextOutput(popisek.Position, popisek.Text,
        _Symbol_Colors[popisek.Color], clBlack, obj);
    end;
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

function TPPopisky.GetIndex(Pos:TPoint):Integer;
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
  begin
   if ((Pos.X >= Self.data[i].Position.X-1) and (Pos.X <= Self.data[i].Position.X+1) and
       (Pos.Y = Self.data[i].Position.Y)) then
     Exit(i);
  end;

 Result := -1;
end;

////////////////////////////////////////////////////////////////////////////////

end.

