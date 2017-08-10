unit BlokPrejezd;

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
     BlokUsek;

const
 _MAX_PRJ_LEN = 64;

type
 TBlkPrjPanelStav = (err = -1, otevreno = 0, vystraha = 1, uzavreno = 2, anulace = 3);

 // data pro vykreslovani
 TPrjPanelProp = record
  Symbol,Pozadi:TColor;
  stav:TBlkPrjPanelStav;
 end;

 // jeden blikajici blok prejezdu
 // je potreba v nem take ulozit, jaky technologicky blok se ma vykreslit, pokud je prejezd uzavren
 TBlikPoint = record
  Pos:TPoint;
  PanelUsek:Integer;       // pozor, tady je usek panelu!, toto je zmena oproti editoru a mergeru !
 end;

 // 1 blok prejezdu na reliefu:
 TPPrejezd=record
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
 end;

 TPPrejezdy = class
   data:TList<TPPrejezd>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
   function GetIndex(Pos:TPoint):Integer;
   procedure Reset();
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

uses Symbols, PanelPainter, Panel;

////////////////////////////////////////////////////////////////////////////////

constructor TPPrejezdy.Create();
begin
 inherited;
 Self.data := TList<TPPrejezd>.Create();
end;

destructor TPPrejezdy.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPrejezdy.Load(ini:TMemIniFile);
var i, j, count:Integer;
    prj:TPPrejezd;
    obj:string;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'PRJ', 0);
 for i := 0 to count-1 do
  begin
   prj.Blok        := ini.ReadInteger('PRJ'+IntToStr(i), 'B', -1);
   prj.OblRizeni   := ini.ReadInteger('PRJ'+IntToStr(i), 'OR', -1);

   obj := ini.ReadString('PRJ'+IntToStr(i), 'BP', '');
   prj.BlikPositions.Count := (Length(obj) div 9);
   for j := 0 to prj.BlikPositions.Count-1 do
    begin
     prj.BlikPositions.Data[j].Pos.X := StrToIntDef(copy(obj, j*9+1, 3), 0);
     prj.BlikPositions.Data[j].Pos.Y := StrToIntDef(copy(obj, j*9+4, 3), 0);
//     prj.BlikPositions.Data[j].PanelUsek := Self.GetUsek(StrToIntDef(copy(obj, j*9+7, 3), 0));
     // TODO
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

procedure TPPrejezdy.Show(obj:TDXDraw; blik:boolean; useky:TList<TPReliefUsk>);
var i,j:Integer;
    usek:Integer;
    sym:TReliefSym;
    prj:TPPrejezd;
begin
 for prj in Self.data do
  begin
   // vykreslit staticke pozice:
   for j := 0 to prj.StaticPositions.Count-1 do
     PanelPainter.Draw(SymbolSet.IL_Symbols, prj.StaticPositions.data[j], _Prj_Start,
       prj.PanelProp.Symbol, prj.PanelProp.Pozadi, obj);

   // vykreslit blikajici pozice podle stavu prejezdu:
   if ((prj.PanelProp.stav = TBlkPrjPanelStav.otevreno) or
      (prj.PanelProp.stav = TBlkPrjPanelStav.anulace) or
      (prj.PanelProp.stav = TBlkPrjPanelStav.err) or
      ((prj.PanelProp.stav = TBlkPrjPanelStav.vystraha) and (blik))) then
    begin
       // nestaticke pozice proste vykreslime:
       for j := 0 to prj.BlikPositions.Count-1 do
        begin
         // musime smazat pripadne useky navic:

         if (prj.BlikPositions.data[j].PanelUsek > -1) then
          begin
           // porovname, pokud tam uz nahodou neni
           usek := prj.BlikPositions.data[j].PanelUsek;
           if (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.X = prj.BlikPositions.data[j].Pos.X)
           and (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.Y = prj.BlikPositions.data[j].Pos.Y) then
            begin
             // pokud je, odebereme
             Useky[usek].Symbols.Count := Self.Useky[usek].Symbols.Count - 1;
            end;
          end;

         PanelPainter.Draw(SymbolSet.IL_Symbols, prj.BlikPositions.data[j].Pos,
           _Prj_Start, prj.PanelProp.Symbol, prj.PanelProp.Pozadi, obj);
        end;
    end else begin

       // na nestatickych pozicich vykreslime usek
       // provedeme fintu: pridame pozici prostred prejezdu k useku, ktery tam patri

       if (prj.PanelProp.stav = TBlkPrjPanelStav.vystraha) then continue;

       for j := 0 to prj.BlikPositions.Count-1 do
        begin
         if (prj.BlikPositions.data[j].PanelUsek > -1) then
          begin
           // porovname, pokud tam uz nahodou neni
           usek := prj.BlikPositions.data[j].PanelUsek;
           if (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.X <> prj.BlikPositions.data[j].Pos.X)
           or (Useky[usek].Symbols[Useky[usek].Symbols.Count-1].Position.Y <> prj.BlikPositions.data[j].Pos.Y) then
            begin
             // pokud neni, pridame:
             sym.Position := prj.BlikPositions.data[j].Pos;
             sym.SymbolID := 12;
             Useky[usek].Symbols.Add(sym);
            end;
          end;

        end;// for j
    end;
  end;//for i
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

  end;//for i

 // dale je take zapotrebi zkontrolovat popisky:
 for i := 0 to Self.Popisky.Count-1 do
  begin
   if (Self.Popisky.Data[i].prejezd_ref < 0) then continue;

   if ((Pos.X >= Self.Popisky.Data[i].Position.X-1) and (Pos.X <= Self.Popisky.Data[i].Position.X+1) and (Pos.Y = Self.Popisky.Data[i].Position.Y)) then
     Exit(Self.Popisky.Data[i].prejezd_ref);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPPrejezdy.Reset();
var i:Integer;
    prj:TPPrejezd;
begin
 for i := 0 to Self.data.Count-1 do
  begin
   prj := Self.data[i];
   prj.PanelProp := _Def_Prj_Prop;
   Self.data[i] := prj;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

end.

