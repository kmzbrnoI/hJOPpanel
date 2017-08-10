unit BlokZamek;

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TZamekPanelProp = record
  Symbol,Pozadi:TColor;
  blik:boolean;
 end;

 TPZamek=record
  Blok:Integer;
  Pos:TPoint;
  OblRizeni:Integer;
  PanelProp:TZamekPanelProp;
 end;


 TPZamky = class
   data:TList<TPZamek>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw; blik:boolean);
   function GetIndex(Pos:TPoint):Integer;
   procedure Reset();
 end;

const
  _Def_Zamek_Prop:TZamekPanelProp = (
      Symbol: clBlack;
      Pozadi: clFuchsia;
      blik: false;
      );

  _UA_Zamek_Prop:TZamekPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      blik: false;
      );

implementation

uses PanelPainter, Symbols;

////////////////////////////////////////////////////////////////////////////////

constructor TPZamky.Create();
begin
 inherited;
 Self.data := TList<TPZamek>.Create();
end;

destructor TPZamky.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPZamky.Load(ini:TMemIniFile);
var i, count:Integer;
    zam:TPZamek;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'Z',   0);
 for i := 0 to count-1 do
  begin
   zam.Blok         := ini.ReadInteger('Z'+IntToStr(i), 'B', -1);
   zam.OblRizeni    := ini.ReadInteger('Z'+IntToStr(i), 'OR', -1);
   zam.Pos.X        := ini.ReadInteger('Z'+IntToStr(i), 'X', 0);
   zam.Pos.Y        := ini.ReadInteger('Z'+IntToStr(i), 'Y', 0);

   //default settings:
   if (zam.Blok = -2) then
     zam.PanelProp := _UA_Zamek_Prop
   else
     zam.PanelProp := _Def_Zamek_Prop;

   Self.data.Add(zam);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPZamky.Show(obj:TDXDraw; blik:boolean);
var fg:TColor;
    zam:TPZamek;
begin
 for zam in Self.data do
  begin
   if ((zam.PanelProp.blik) and (blik)) then
     fg := clBlack
   else
     fg := zam.PanelProp.Symbol;

   PanelPainter.Draw(SymbolSet.IL_Symbols, zam.Pos, _Zamek,
             fg, zam.PanelProp.Pozadi, obj);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

function TPZamky.GetIndex(Pos:TPoint):Integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.data.Count-1 do
   if ((pos.X = Self.data[i].Pos.X) and (pos.Y = Self.data[i].Pos.Y)) then
     Exit(i);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPZamky.Reset();
var i:Integer;
    zam:TPZamek;
begin
 for i := 0 to Self.data.Count-1 do
  begin
   zam := Self.data[i];
   zam.PanelProp := _Def_Zamek_Prop;
   Self.data[i] := zam;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

end.

