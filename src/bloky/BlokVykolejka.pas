unit BlokVykolejka;

{
  Definice bloku vykolejka, jeho vlastnosti a stavu v panelu.
  Definice databaze vykolejek.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
     BlokVyhybka, BlokUsek;

type
 TPVykolejka = class
  Blok:Integer;
  Pos:TPoint;
  OblRizeni:Integer;
  PanelProp:TVyhPanelProp;

  symbol:Integer;
  usek:integer;              // index useku, na kterem je vykolejka
  vetev:integer;             // cislo vetve, ve kterem je vykolejka
 end;

 TPVykolejky = class
  private
   function GetItem(index:Integer):TPVykolejka;
   function GetCount():Integer;

  public
   data:TObjectList<TPVykolejka>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
   function GetIndex(Pos:TPoint):Integer;
   procedure Reset(orindex:Integer = -1);

   property Items[index : integer] : TPVykolejka read GetItem; default;
   property Count : integer read GetCount;
 end;

implementation

uses PanelPainter, Symbols;

////////////////////////////////////////////////////////////////////////////////

constructor TPVykolejky.Create();
begin
 inherited;
 Self.data := TObjectList<TPVykolejka>.Create();
end;

destructor TPVykolejky.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVykolejky.Load(ini:TMemIniFile);
var i, count:Integer;
    vykol:TPVykolejka;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'Vyk', 0);
 for i := 0 to count-1 do
  begin
   vykol := TPVykolejka.Create();

   vykol.Blok      := ini.ReadInteger('Vyk'+IntToStr(i), 'B', -1);
   vykol.OblRizeni := ini.ReadInteger('Vyk'+IntToStr(i), 'OR', -1);
   vykol.Pos.X     := ini.ReadInteger('Vyk'+IntToStr(i), 'X', 0);
   vykol.Pos.Y     := ini.ReadInteger('Vyk'+IntToStr(i), 'Y', 0);
   vykol.usek      := ini.ReadInteger('Vyk'+IntToStr(i), 'O', -1);
   vykol.vetev     := ini.ReadInteger('Vyk'+IntToStr(i), 'V', -1);
   vykol.symbol    := ini.ReadInteger('Vyk'+IntToStr(i), 'T', 0);

   //default settings:
   if (vykol.Blok = -2) then
     vykol.PanelProp := _UA_Vyh_Prop
   else
     vykol.PanelProp := _Def_Vyh_Prop;

   Self.data.Add(vykol);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVykolejky.Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
var fg, bkcol:TColor;
    visible:boolean;
    vykol:TPVykolejka;
begin
 for vykol in Self.data do
  begin
   visible := ((vykol.PanelProp.Poloha = TVyhPoloha.disabled) or (vykol.vetev < 0) or
     (vykol.vetev >= useky[vykol.usek].Vetve.Count) or
     (useky[vykol.usek].Vetve[vykol.vetev].visible));

   if ((vykol.PanelProp.blikani) and (blik) and (visible)) then
     fg := clBlack
   else begin
     if ((visible) or (vykol.PanelProp.Symbol = clAqua)) then
      fg := vykol.PanelProp.Symbol
     else
      fg := useky[vykol.usek].PanelProp.nebarVetve;
   end;

   if (vykol.PanelProp.Pozadi = clBlack) then
     bkcol := useky[vykol.usek].PanelProp.Pozadi
   else
     bkcol := vykol.PanelProp.Pozadi;

   case (vykol.PanelProp.Poloha) of
    TVyhPoloha.disabled : PanelPainter.Draw(SymbolSet.IL_Symbols, vykol.Pos,
        _Vykol_Start+vykol.symbol, useky[vykol.usek].PanelProp.Pozadi, clFuchsia, obj);
    TVyhPoloha.none     : PanelPainter.Draw(SymbolSet.IL_Symbols, vykol.Pos,
        _Vykol_Start+vykol.symbol, bkcol, fg, obj);
    TVyhPoloha.plus     : PanelPainter.Draw(SymbolSet.IL_Symbols, vykol.Pos,
        _Vykol_Start+vykol.symbol, fg, bkcol, obj);
    TVyhPoloha.minus    : PanelPainter.Draw(SymbolSet.IL_Symbols, vykol.Pos,
        _Vykol_Start+vykol.symbol+2, fg, bkcol, obj);
    TVyhPoloha.both     : PanelPainter.Draw(SymbolSet.IL_Symbols, vykol.Pos,
        _Vykol_Start+vykol.symbol, bkcol, clBlue, obj);
   end;
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

function TPVykolejky.GetIndex(Pos:TPoint):Integer;
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
   if ((pos.X = Self.data[i].Pos.X) and (pos.Y = Self.data[i].Pos.Y)) then
     Exit(i);

 Result := -1;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVykolejky.Reset(orindex:Integer = -1);
var vyk:TPVykolejka;
begin
 for vyk in Self.data do
  begin
   if ((orindex < 0) or (vyk.OblRizeni = orindex)) then
    begin
     if (vyk.Blok > -2) then
       vyk.PanelProp := _Def_Vyh_Prop
     else
       vyk.PanelProp := _UA_Vyh_Prop;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TPVykolejky.GetItem(index:Integer):TPVykolejka;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPVykolejky.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

end.

