unit BlokPomocny;

{
  Definice pomocneho bloku.
  Definice databaze pomocnych bloku.
  Pomocne bloky jsou dalsi symboly zobrazene na reliefu, typicky nemaji zadnou
  funkci: perony atp. Pomocny blok je ale pripraven na to, ze nejakou funkci mit
  muze.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TPPomocnyPanelProp = record
  Symbol,Pozadi:TColor;
  blik:boolean;

  procedure Change(parsed:TStrings);
 end;

 TPPomocnyObj = class
  Blok:Integer;
  OblRizeni:Integer;
  Positions:TList<TPoint>;
  Symbol:Integer;
  PanelProp:TPPomocnyPanelProp;

  constructor Create();
  destructor Destroy(); override;
  procedure Show(obj:TDXDraw; blik:boolean);
  procedure Reset();
 end;

 TPPomocneObj = class
   data:TObjectList<TPPomocnyObj>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw; blik:boolean);
   procedure Reset(orindex:Integer = -1);
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

  _Def_Pomocny_Prop:TPPomocnyPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      blik: false;
  );

  _Assigned_Pomocny_Prop:TPPomocnyPanelProp = (
      Symbol: clFuchsia;
      Pozadi: clBlack;
      blik: false;
  );


implementation

uses PanelPainter, Symbols, parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor TPPomocnyObj.Create();
begin
 inherited;
 Self.Positions := TList<TPoint>.Create();
end;

destructor TPPomocnyObj.Destroy();
begin
 Self.Positions.Free();
 inherited;
end;

procedure TPPomocnyObj.Show(obj:TDXDraw; blik:boolean);
var p:TPoint;
    color:TColor;
begin
 if (Self.Blok > -1) then
  begin
   color := Self.PanelProp.Symbol;
  end else
   color := _SpecS_DrawColors[Self.Symbol];

 if ((Self.PanelProp.blik) and (blik)) then
   color := clBlack;

 for p in Self.Positions do
   PanelPainter.Draw(SymbolSet.IL_Symbols, p, Self.Symbol, color, Self.PanelProp.Pozadi, obj);
end;

procedure TPPomocnyObj.Reset();
begin
 if (Self.Blok > -1) then
   Self.PanelProp := _Assigned_Pomocny_Prop
 else
   Self.PanelProp := _Def_Pomocny_Prop;
end;

procedure TPPomocnyPanelProp.Change(parsed:TStrings);
begin
 Symbol := StrToColor(parsed[4]);
 Pozadi := StrToColor(parsed[5]);
 blik   := StrToBool(parsed[6]);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPPomocneObj.Create();
begin
 inherited;
 Self.data := TObjectList<TPPomocnyObj>.Create();
end;

destructor TPPomocneObj.Destroy();
begin
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
   po := TPPomocnyObj.Create();

   po.Blok := ini.ReadInteger('P'+IntToStr(i), 'B', -1);
   po.OblRizeni := ini.ReadInteger('P'+IntToStr(i), 'OR', -1);
   po.Symbol := ini.ReadInteger('P'+IntToStr(i),'S',0);
   po.Positions := TList<TPoint>.Create();

   obj := ini.ReadString('P'+IntToStr(i),'P', '');
   count2 := (Length(obj) div 6);
   for j := 0 to count2 -1 do
     po.Positions.Add( Point( StrToIntDef(copy(obj,j*6+1,3),0), StrToIntDef(copy(obj,j*6+4,3),0) ) );
   po.Reset();

   Self.data.Add(po);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPomocneObj.Show(obj:TDXDraw; blik:boolean);
var po:TPPomocnyObj;
begin
 for po in Self.data do
   po.Show(obj, blik);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPomocneObj.Reset(orindex:Integer = -1);
var pomocny: TPPomocnyObj;
begin
 for pomocny in Self.data do
   if ((orindex < 0) or (pomocny.OblRizeni = orindex)) then
     pomocny.Reset();
end;

////////////////////////////////////////////////////////////////////////////////

end.

