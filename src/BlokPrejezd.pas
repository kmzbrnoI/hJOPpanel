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

  StaticPositions: record
   data:array [0.._MAX_PRJ_LEN] of TPoint;
   Count:Byte;
  end;

  BlikPositions: record
   data:array [0.._MAX_PRJ_LEN] of TBlikPoint;
   Count:Byte;
  end;

  OblRizeni:Integer;
  PanelProp:TPrjPanelProp;

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

   procedure Load(ini:TMemIniFile; useky:TPUseky);
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

uses Symbols, PanelPainter, Panel, parseHelper;

////////////////////////////////////////////////////////////////////////////////

procedure TPPrejezd.Reset();
begin
 if (Self.Blok > -2) then
   Self.PanelProp := _Def_Prj_Prop
 else
   Self.PanelProp := _UA_Prj_Prop;
end;

procedure TPPrejezd.Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
var j:Integer;
    usek:Integer;
    sym:TReliefSym;
begin
 // vykreslit staticke pozice:
 for j := 0 to Self.StaticPositions.Count-1 do
   PanelPainter.Draw(SymbolSet.IL_Symbols, Self.StaticPositions.data[j], _Prj_Start,
     Self.PanelProp.Symbol, Self.PanelProp.Pozadi, obj);

 // vykreslit blikajici pozice podle stavu prejezdu:
 if ((Self.PanelProp.stav = TBlkPrjPanelStav.disabled) or
    (Self.PanelProp.stav = TBlkPrjPanelStav.otevreno) or
    (Self.PanelProp.stav = TBlkPrjPanelStav.anulace) or
    (Self.PanelProp.stav = TBlkPrjPanelStav.err) or
    ((Self.PanelProp.stav = TBlkPrjPanelStav.vystraha) and (blik))) then
  begin
   // nestaticke pozice proste vykreslime:
   for j := 0 to Self.BlikPositions.Count-1 do
    begin
     // musime smazat pripadne useky navic:

     if (Self.BlikPositions.data[j].PanelUsek > -1) then
      begin
       // porovname, pokud tam uz nahodou neni
       usek := Self.BlikPositions.data[j].PanelUsek;
       if (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.X = Self.BlikPositions.data[j].Pos.X)
       and (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.Y = Self.BlikPositions.data[j].Pos.Y) then
        begin
         // pokud je, odebereme
         Useky[usek].Symbols.Count := Useky[usek].Symbols.Count - 1;
        end;
      end;

     PanelPainter.Draw(SymbolSet.IL_Symbols, Self.BlikPositions.data[j].Pos,
       _Prj_Start, Self.PanelProp.Symbol, Self.PanelProp.Pozadi, obj);
    end;
  end else begin
   // na nestatickych pozicich vykreslime usek
   // provedeme fintu: pridame pozici prostred prejezdu k useku, ktery tam patri

   if (Self.PanelProp.stav = TBlkPrjPanelStav.vystraha) then Exit();

   for j := 0 to Self.BlikPositions.Count-1 do
    begin
     if (Self.BlikPositions.data[j].PanelUsek > -1) then
      begin
       // porovname, pokud tam uz nahodou neni
       usek := Self.BlikPositions.data[j].PanelUsek;
       if (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.X <> Self.BlikPositions.data[j].Pos.X)
          or (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.Y <> Self.BlikPositions.data[j].Pos.Y) then
        begin
         // pokud neni, pridame:
         sym.Position := Self.BlikPositions.data[j].Pos;
         sym.SymbolID := 12;
         Useky[usek].Symbols.Add(sym);
        end;
      end;

    end;// for j
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

procedure TPPrejezdy.Load(ini:TMemIniFile; useky:TPUseky);
var i, j, count:Integer;
    prj:TPPrejezd;
    obj:string;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'PRJ', 0);
 for i := 0 to count-1 do
  begin
   prj := TPPrejezd.Create();

   prj.Blok        := ini.ReadInteger('PRJ'+IntToStr(i), 'B', -1);
   prj.OblRizeni   := ini.ReadInteger('PRJ'+IntToStr(i), 'OR', -1);

   obj := ini.ReadString('PRJ'+IntToStr(i), 'BP', '');
   prj.BlikPositions.Count := (Length(obj) div 9);
   for j := 0 to prj.BlikPositions.Count-1 do
    begin
     prj.BlikPositions.Data[j].Pos.X := StrToIntDef(copy(obj, j*9+1, 3), 0);
     prj.BlikPositions.Data[j].Pos.Y := StrToIntDef(copy(obj, j*9+4, 3), 0);
     prj.BlikPositions.Data[j].PanelUsek := useky.GetUsek(StrToIntDef(copy(obj, j*9+7, 3), 0));
    end;//for j

   obj := ini.ReadString('PRJ'+IntToStr(i), 'SP', '');
   prj.StaticPositions.Count := (Length(obj) div 6);
   for j := 0 to prj.StaticPositions.Count-1 do
    begin
     prj.StaticPositions.Data[j].X := StrToIntDef(copy(obj, j*6+1, 3), 0);
     prj.StaticPositions.Data[j].Y := StrToIntDef(copy(obj, j*6+4, 3), 0);
    end;//for j

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
var i, j:Integer;
begin
 Result := -1;

 // kontrola prejezdu:
 for i := 0 to Self.data.Count-1 do
  begin
   for j := 0 to Self.data[i].StaticPositions.Count-1 do
     if ((Pos.X = Self.data[i].StaticPositions.data[j].X) and (Pos.Y = Self.data[i].StaticPositions.data[j].Y)) then
       Exit(i);

   for j := 0 to Self.data[i].BlikPositions.Count-1 do
     if ((Pos.X = Self.data[i].BlikPositions.data[j].Pos.X) and (Pos.Y = Self.data[i].BlikPositions.data[j].Pos.Y)) then
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

end.

