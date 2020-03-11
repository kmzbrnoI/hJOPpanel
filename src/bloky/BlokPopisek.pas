unit BlokPopisek;

{
  Definice bloku popisek a jeho vlastnosti.
  Definice databaze popisku.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TTextPanelProp = record
  Symbol, Pozadi: TColor;
  left, right: TColor;
  blikani:boolean;

  procedure Change(parsed:TStrings);
  procedure Reset();
 end;

 TPText = class
  Text:string;
  Position:TPoint;
  Color:Integer;
  Blok:Integer;
  OblRizeni:Integer;
  PanelProp: TTextPanelProp;

  procedure Reset();
  procedure Show(obj:TDXDraw);
 end;


 TPTexty = class
  private
    function GetItem(index:Integer):TPText;
    function GetCount():Integer;

  public
   data:TObjectList<TPText>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini:TMemIniFile; key:string);
    procedure Show(obj:TDXDraw);
    function GetIndex(Pos:TPoint):Integer;
    procedure Reset(orindex:Integer = -1);

    property Items[index : integer] : TPText read GetItem; default;
    property Count : integer read GetCount;
 end;

const
  _Def_Popisek_Prop:TTextPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      left: clFuchsia;
      right: clFuchsia;
      blikani: false
  );

implementation

uses PanelPainter, Symbols, parseHelper;

////////////////////////////////////////////////////////////////////////////////

procedure TPText.Reset();
begin
 Self.PanelProp.Reset();
end;

procedure TPText.Show(obj:TDXDraw);
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
      Self.PanelProp.Symbol, Self.PanelProp.Pozadi, obj, false, true);
  end else begin
   PanelPainter.TextOutput(Self.Position, Self.Text,
      _Symbol_Colors[Self.Color], clBlack, obj, false, true);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPTexty.Create();
begin
 inherited;
 Self.data := TObjectList<TPText>.Create();
end;

destructor TPTexty.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPTexty.Load(ini:TMemIniFile; key:string);
var i, count: Integer;
    popisek:TPText;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', key, 0);
 for i := 0 to count-1 do
  begin
   popisek := TPText.Create();

   popisek.Text        := ini.ReadString(key+IntToStr(i),'T','0');
   popisek.Position.X  := ini.ReadInteger(key+IntToStr(i),'X',0);
   popisek.Position.Y  := ini.ReadInteger(key+IntToStr(i),'Y',0);
   popisek.Color       := ini.ReadInteger(key+IntToStr(i),'C',0);
   popisek.Blok        := ini.ReadInteger(key+IntToStr(i),'B', -1);
   popisek.OblRizeni   := ini.ReadInteger(key+IntToStr(i),'OR',-1);

   popisek.PanelProp := _Def_Popisek_Prop;

   Self.data.Add(popisek);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPTexty.Reset(orindex:Integer = -1);
var popisek:TPText;
begin
 for popisek in Self.data do
   if ((orindex < 0) or (popisek.OblRizeni = orindex)) then
     popisek.Reset();
end;

////////////////////////////////////////////////////////////////////////////////

function TPTexty.GetItem(index:Integer):TPText;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPTexty.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPTexty.Show(obj:TDXDraw);
var popisek:TPText;
begin
 for popisek in Self.data do
   popisek.Show(obj);
end;

////////////////////////////////////////////////////////////////////////////////

function TPTexty.GetIndex(Pos:TPoint):Integer;
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

procedure TTextPanelProp.Change(parsed:TStrings);
begin
 Self.Symbol := StrToColor(parsed[4]);
 Self.Pozadi := StrToColor(parsed[5]);
 Self.blikani := (parsed[6] = '1');
 Self.left := StrToColor(parsed[7]);
 Self.right := StrToColor(parsed[8]);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTextPanelProp.Reset();
begin
 Self := _Def_Popisek_Prop;
end;

////////////////////////////////////////////////////////////////////////////////

end.

