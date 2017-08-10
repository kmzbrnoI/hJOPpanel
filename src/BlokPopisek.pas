unit BlokPopisek;

{
  Definice bloku popisek a jeho vlastnosti.
  Definice databaze popisku.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
     BlokPrejezd;

type
 TPPopisek = record
  Text:string;
  Position:TPoint;
  Color:Integer;
  prejezd_ref:Integer;
 end;


 TPPopisky = class
   data:TList<TPPopisek>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile; prejezdy:TPPrejezdy);
   procedure Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
   function GetIndex(Pos:TPoint):Integer;
 end;

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
   popisek.prejezd_ref := Prejezdy.GetPrj(ini.ReadInteger('T'+IntToStr(i),'B', -1));

   Self.data.Add(popisek);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPopisky.Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
var popisek:TPPopisek;
begin
 for popisek in Self.data do
  begin
   if (popisek.prejezd_ref > -1) then
    begin
     // popisek ma referenci na prejezd
     if ((prejezdy[popisek.prejezd_ref].PanelProp.Pozadi = clBlack) or
         (prejezdy[popisek.prejezd_ref].PanelProp.Pozadi = clTeal)) then
      begin
       obj.Surface.Canvas.Brush.Color := clGreen;
      end else begin
       obj.Surface.Canvas.Brush.Color := prejezdy[popisek.prejezd_ref].PanelProp.Pozadi;
      end;

     obj.Surface.Canvas.Pen.Color   := obj.Surface.Canvas.Brush.Color;
     obj.Surface.Canvas.Rectangle((popisek.Position.X-1)*SymbolSet._Symbol_Sirka,
       popisek.Position.Y*SymbolSet._Symbol_Vyska, (popisek.Position.X)*SymbolSet._Symbol_Sirka,
       (popisek.Position.Y+1)*SymbolSet._Symbol_Vyska);

     case (prejezdy[popisek.prejezd_ref].PanelProp.stav) of
       TBlkPrjPanelStav.anulace: begin
        obj.Surface.Canvas.Brush.Color := clWhite;
        obj.Surface.Canvas.Pen.Color   := clWhite;
        obj.Surface.Canvas.Rectangle((popisek.Position.X+1)*SymbolSet._Symbol_Sirka,
          popisek.Position.Y*SymbolSet._Symbol_Vyska, (popisek.Position.X+2)*SymbolSet._Symbol_Sirka,
          (popisek.Position.Y+1)*SymbolSet._Symbol_Vyska);
       end;
      end;//case

    end;//if

   PanelPainter.TextOutput(popisek.Position, popisek.Text,
      _Symbol_Colors[popisek.Color], clBlack, obj);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

function TPPopisky.GetIndex(Pos:TPoint):Integer;
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
  begin
   if (Self.data[i].prejezd_ref < 0) then continue;

   if ((Pos.X >= Self.data[i].Position.X-1) and (Pos.X <= Self.data[i].Position.X+1) and
       (Pos.Y = Self.data[i].Position.Y)) then
     Exit(Self.data[i].prejezd_ref);
  end;

 Result := -1;
end;

////////////////////////////////////////////////////////////////////////////////

end.

