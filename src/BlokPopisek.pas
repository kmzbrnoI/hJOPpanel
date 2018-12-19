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

  procedure Change(parsed:TStrings);
  procedure Reset();
 end;

 TPPopisek = class
  Text:string;
  Position:TPoint;
  Color:Integer;
  Blok:Integer;
  OblRizeni:Integer;
  PanelProp: TPopisekPanelProp;

  procedure Reset();
  procedure Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
 end;


 TPPopisky = class
  private
    function GetItem(index:Integer):TPPopisek;
    function GetCount():Integer;

  public
   data:TObjectList<TPPopisek>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini:TMemIniFile; prejezdy:TPPrejezdy);
    procedure Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
    function GetIndex(Pos:TPoint):Integer;
    procedure Reset(orindex:Integer = -1);

    property Items[index : integer] : TPPopisek read GetItem; default;
    property Count : integer read GetCount;
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

uses PanelPainter, Symbols, parseHelper;

////////////////////////////////////////////////////////////////////////////////

procedure TPPopisek.Reset();
begin
 Self.PanelProp.Reset();
end;

procedure TPPopisek.Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
begin
 if (Self.Blok > -1) then
  begin
   // popisek ma referenci na souctovou hlasku

   obj.Surface.Canvas.Brush.Color := Self.PanelProp.left;
   obj.Surface.Canvas.Pen.Color := obj.Surface.Canvas.Brush.Color;
   obj.Surface.Canvas.Rectangle((Self.Position.X-1)*SymbolSet._Symbol_Sirka,
     Self.Position.Y*SymbolSet._Symbol_Vyska, (Self.Position.X)*SymbolSet._Symbol_Sirka,
     (Self.Position.Y+1)*SymbolSet._Symbol_Vyska);

   obj.Surface.Canvas.Brush.Color := Self.PanelProp.right;
   obj.Surface.Canvas.Pen.Color   := obj.Surface.Canvas.Brush.Color;
   obj.Surface.Canvas.Rectangle((Self.Position.X+1)*SymbolSet._Symbol_Sirka,
     Self.Position.Y*SymbolSet._Symbol_Vyska, (Self.Position.X+2)*SymbolSet._Symbol_Sirka,
     (Self.Position.Y+1)*SymbolSet._Symbol_Vyska);

   PanelPainter.TextOutput(Self.Position, Self.Text,
      Self.PanelProp.Symbol, Self.PanelProp.Pozadi, obj);
  end else begin
   PanelPainter.TextOutput(Self.Position, Self.Text,
      _Symbol_Colors[Self.Color], clBlack, obj);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPPopisky.Create();
begin
 inherited;
 Self.data := TObjectList<TPPopisek>.Create();
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
   popisek := TPPopisek.Create();

   popisek.Text        := ini.ReadString('T'+IntToStr(i),'T','0');
   popisek.Position.X  := ini.ReadInteger('T'+IntToStr(i),'X',0);
   popisek.Position.Y  := ini.ReadInteger('T'+IntToStr(i),'Y',0);
   popisek.Color       := ini.ReadInteger('T'+IntToStr(i),'C',0);
   popisek.Blok        := ini.ReadInteger('T'+IntToStr(i),'B', -1);
   popisek.OblRizeni   := ini.ReadInteger('V'+IntToStr(i),'OR',-1);

   popisek.PanelProp := _Def_Popisek_Prop;

   Self.data.Add(popisek);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPopisky.Reset(orindex:Integer = -1);
var popisek:TPPopisek;
begin
 for popisek in Self.data do
   if ((orindex < 0) or (popisek.OblRizeni = orindex)) then
     popisek.Reset();
end;

////////////////////////////////////////////////////////////////////////////////

function TPPopisky.GetItem(index:Integer):TPPopisek;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPPopisky.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPopisky.Show(obj:TDXDraw; prejezdy:TList<TPPrejezd>);
var popisek:TPPopisek;
begin
 for popisek in Self.data do
   popisek.Show(obj, prejezdy);
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

procedure TPopisekPanelProp.Change(parsed:TStrings);
begin
 Self.Symbol := StrToColor(parsed[4]);
 Self.Pozadi := StrToColor(parsed[5]);
 Self.blikani := (parsed[6] = '1');
 Self.left := StrToColor(parsed[7]);
 Self.right := StrToColor(parsed[8]);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPopisekPanelProp.Reset();
begin
 Self := _Def_Popisek_Prop;
end;

////////////////////////////////////////////////////////////////////////////////

end.

