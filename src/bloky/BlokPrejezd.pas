unit BlokPrejezd;

{
  Definice bloku prejezd, jeho vlastnosti a stavu v panelu.
  Definice databaze bloku typu prejezd.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
     BlokUsek, BlokyUsek;

const
 _MAX_PRJ_LEN = 64;

type
 TBlkPrjPanelStav = (disabled = -5, err = -1, otevreno = 0, vystraha = 1, uzavreno = 2, anulace = 3);

 // data pro vykreslovani
 TPrjPanelProp = record
  Symbol,Pozadi:TColor;
  stav:TBlkPrjPanelStav;

  procedure Change(data:TStrings);
 end;

 // jeden blikajici blok prejezdu
 // je potreba v nem take ulozit, jaky technologicky blok se ma vykreslit, pokud je prejezd uzavren
 TBlikPoint = record
  Pos:TPoint;
  PanelUsek:Integer;       // pozor, tady je usek panelu!, toto je zmena oproti editoru a mergeru !
 end;

 // 1 blok prejezdu na reliefu:
 TPPrejezd = class
  Blok:Integer;

  StaticPositions: TList<TPoint>;
  BlikPositions: TList<TBlikPoint>;

  OblRizeni:Integer;
  PanelProp:TPrjPanelProp;

  constructor Create();
  destructor Destroy(); override;

  procedure Reset();
  procedure Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
 end;

 TPPrejezdy = class
  private
   function GetItem(index:Integer):TPPrejezd;
   function GetCount():Integer;

  public

   data:TObjectList<TPPrejezd>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile; useky:TPUseky; version: Word);
   procedure Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
   function GetIndex(Pos:TPoint):Integer;
   procedure Reset(orindex:Integer = -1);
   function GetPrj(tech_id:Integer):Integer;

   property Items[index : integer] : TPPrejezd read GetItem; default;
   property Count : integer read GetCount;
 end;

const
  _Def_Prj_Prop:TPrjPanelProp = (
      Symbol: clBlack;
      Pozadi: clFuchsia;
      stav: otevreno);

  _UA_Prj_Prop:TPrjPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      stav: otevreno);

implementation

uses Symbols, PanelPainter, parseHelper, Panel;

////////////////////////////////////////////////////////////////////////////////

procedure TPPrejezd.Reset();
begin
 if (Self.Blok > -2) then
   Self.PanelProp := _Def_Prj_Prop
 else
   Self.PanelProp := _UA_Prj_Prop;
end;

procedure TPPrejezd.Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
var pos:TPoint;
    blikPoint:TBlikPoint;
begin
 // vykreslit staticke pozice:
 for pos in Self.StaticPositions do
   PanelPainter.Draw(SymbolSet.IL_Symbols, pos, _Prj_Start,
     Self.PanelProp.Symbol, Self.PanelProp.Pozadi, obj);

 // vykreslit blikajici pozice podle stavu prejezdu:
 if ((Self.PanelProp.stav = TBlkPrjPanelStav.disabled) or
    (Self.PanelProp.stav = TBlkPrjPanelStav.otevreno) or
    (Self.PanelProp.stav = TBlkPrjPanelStav.anulace) or
    (Self.PanelProp.stav = TBlkPrjPanelStav.err) or
    ((Self.PanelProp.stav = TBlkPrjPanelStav.vystraha) and (blik))) then
  begin
   // nestaticke pozice proste vykreslime:
   for blikPoint in Self.BlikPositions do
    begin
     if (blikPoint.PanelUsek > -1) then
       Useky[blikPoint.PanelUsek].RemoveSymbolFromPrejezd(blikPoint.Pos);

     PanelPainter.Draw(SymbolSet.IL_Symbols, blikPoint.Pos,
       _Prj_Start, Self.PanelProp.Symbol, Self.PanelProp.Pozadi, obj);
    end;
  end else begin
   // na nestatickych pozicich vykreslime usek
   // provedeme fintu: pridame pozici prostred prejezdu k useku, ktery tam patri

   if (Self.PanelProp.stav = TBlkPrjPanelStav.vystraha) then Exit();

   for blikPoint in Self.BlikPositions do
     if (blikPoint.PanelUsek > -1) then
       Useky[blikPoint.PanelUsek].AddSymbolFromPrejezd(blikPoint.Pos);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPPrejezdy.Create();
begin
 inherited;
 Self.data := TObjectList<TPPrejezd>.Create();
end;

destructor TPPrejezdy.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPrejezdy.Load(ini:TMemIniFile; useky:TPUseky; version: Word);
var i, j, count:Integer;
    prj:TPPrejezd;
    obj:string;
    posCount: Integer;
    blikPoint: TBlikPoint;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'PRJ', 0);
 for i := 0 to count-1 do
  begin
   prj := TPPrejezd.Create();

   prj.Blok        := ini.ReadInteger('PRJ'+IntToStr(i), 'B', -1);
   prj.OblRizeni   := ini.ReadInteger('PRJ'+IntToStr(i), 'OR', -1);

   obj := ini.ReadString('PRJ'+IntToStr(i), 'BP', '');
   posCount := (Length(obj) div 9);
   for j := 0 to posCount-1 do
    begin
     blikPoint.Pos.X := StrToIntDef(copy(obj, j*9+1, 3), 0);
     blikPoint.Pos.Y := StrToIntDef(copy(obj, j*9+4, 3), 0);
     if (version >= _FILEVERSION_13) then
       blikPoint.PanelUsek := StrToIntDef(copy(obj, j*9+7, 3), 0)
     else
       blikPoint.PanelUsek := useky.GetUsek(StrToIntDef(copy(obj, j*9+7, 3), 0));
     prj.BlikPositions.Add(blikPoint);
    end;//for j

   obj := ini.ReadString('PRJ'+IntToStr(i), 'SP', '');
   posCount := (Length(obj) div 6);
   for j := 0 to posCount-1 do
     prj.StaticPositions.Add(Point(
       StrToIntDef(copy(obj, j*6+1, 3), 0),
       StrToIntDef(copy(obj, j*6+4, 3), 0)
     ));

   //default settings:
   if (prj.Blok = -2) then
     prj.PanelProp := _UA_Prj_Prop
   else
     prj.PanelProp := _Def_Prj_Prop;

   Self.data.Add(prj);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPrejezdy.Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
var prj:TPPrejezd;
begin
 for prj in Self.data do
   prj.Show(obj, blik, useky);
end;

////////////////////////////////////////////////////////////////////////////////

function TPPrejezdy.GetIndex(Pos:TPoint):Integer;
var i:Integer;
    askPos: TPoint;
    blikPoint: TBlikPoint;
begin
 Result := -1;

 // kontrola prejezdu:
 for i := 0 to Self.data.Count-1 do
  begin
   for askPos in Self.data[i].StaticPositions do
     if ((Pos.X = askPos.X) and (Pos.Y = askPos.Y)) then
       Exit(i);

   for blikPoint in Self.data[i].BlikPositions do
     if ((Pos.X = blikPoint.Pos.X) and (Pos.Y = blikPoint.Pos.Y)) then
       Exit(i);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPrejezdy.Reset(orindex:Integer = -1);
var prj:TPPrejezd;
begin
 for prj in Self.data do
   if ((orindex < 0) or (prj.OblRizeni = orindex)) then
     prj.Reset();
end;

////////////////////////////////////////////////////////////////////////////////

function TPPrejezdy.GetItem(index:Integer):TPPrejezd;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPPrejezdy.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

function TPPrejezdy.GetPrj(tech_id:Integer):Integer;
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
   if (tech_id = Self.data[i].Blok) then
     Exit(i);

 Result := -1;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPrjPanelProp.Change(data:TStrings);
begin
 Symbol := StrToColor(data[4]);
 Pozadi := StrToColor(data[5]);
 stav   := TBlkPrjPanelStav(StrToInt(data[7]));
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPPrejezd.Create();
begin
 inherited;
 Self.StaticPositions := TList<TPoint>.Create();
 Self.BlikPositions := TList<TBlikPoint>.Create();
end;

destructor TPPrejezd.Destroy();
begin
 Self.StaticPositions.Free();
 Self.BlikPositions.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

end.

