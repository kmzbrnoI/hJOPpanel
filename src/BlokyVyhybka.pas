unit BlokyVyhybka;

{
  Definice databaze vyhybek.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils,
     BlokUsek, BlokVyhybka;

type
 TPVyhybky = class
  private
   function GetItem(index:Integer):TPVyhybka;
   function GetCount():Integer;

  public
   data:TObjectList<TPVyhybka>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
   function GetIndex(Pos:TPoint):Integer;
   procedure Reset(orindex:Integer = -1);

   property Items[index : integer] : TPVyhybka read GetItem; default;
   property Count : integer read GetCount;
 end;

implementation

uses PanelPainter, Symbols;

////////////////////////////////////////////////////////////////////////////////

constructor TPVyhybky.Create();
begin
 inherited;
 Self.data := TObjectList<TPVyhybka>.Create();
end;

destructor TPVyhybky.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVyhybky.Load(ini:TMemIniFile);
var count, i:Integer;
    vyh:TPVyhybka;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'V', 0);
 for i := 0 to count-1 do
  begin
   vyh := TPVyhybka.Create();

   vyh.Blok        := ini.ReadInteger('V'+IntToStr(i),'B',-1);
   vyh.SymbolID    := ini.ReadInteger('V'+IntToStr(i),'S',0);
   vyh.PolohaPlus  := ini.ReadInteger('V'+IntToStr(i),'P',0);
   vyh.Position.X  := ini.ReadInteger('V'+IntToStr(i),'X',0);
   vyh.Position.Y  := ini.ReadInteger('V'+IntToStr(i),'Y',0);
   vyh.obj         := ini.ReadInteger('V'+IntToStr(i),'O',-1);

   //OR
   vyh.OblRizeni := ini.ReadInteger('V'+IntToStr(i),'OR',-1);

   //default settings:
   vyh.visible   := true;
   if (vyh.Blok = -2) then
     vyh.PanelProp := _UA_Vyh_Prop
   else
     vyh.PanelProp := _Def_Vyh_Prop;

   Self.data.Add(vyh);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVyhybky.Show(obj:TDXDraw; blik:boolean; useky:TList<TPUsek>);
var fg:Integer;
    bkcol:TColor;
    vyh:TPVyhybka;
begin
 //vyhybky
 for vyh in Self.data do
  begin
   if ((vyh.PanelProp.blikani) and (blik) and (vyh.visible)) then
     fg := clBlack
   else begin
     if ((vyh.visible) or (vyh.PanelProp.Symbol = clAqua)) then
      fg := vyh.PanelProp.Symbol
     else
      fg := useky[vyh.obj].PanelProp.nebarVetve;
   end;

   if (vyh.PanelProp.Pozadi = clBlack) then
     bkcol := useky[vyh.obj].PanelProp.Pozadi
   else
     bkcol := vyh.PanelProp.Pozadi;

   if (vyh.Blok = -2) then
    begin
     // blok zamerne neprirazen
     PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
               vyh.SymbolID, fg, bkcol, obj);
    end else begin
     case (vyh.PanelProp.Poloha) of
      TVyhPoloha.disabled:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
                 vyh.SymbolID, useky[vyh.obj].PanelProp.Pozadi, clFuchsia, obj);
      end;
      TVyhPoloha.none:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position, vyh.SymbolID,
                 bkcol, fg, obj);
      end;
      TVyhPoloha.plus:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
                 (vyh.SymbolID)+4+(4*(vyh.PolohaPlus xor 0)),
                 fg, bkcol, obj);
      end;
      TVyhPoloha.minus:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position,
                 (vyh.SymbolID)+8-(4*(vyh.PolohaPlus xor 0)),
                 fg, bkcol, obj);
      end;
      TVyhPoloha.both:begin
       PanelPainter.Draw(SymbolSet.IL_Symbols, vyh.Position, vyh.SymbolID,
                 bkcol, clBlue, obj);
      end;
     end;//case
    end;//else blok zamerne neprirazn
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

function TPVyhybky.GetIndex(Pos:TPoint):Integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.data.Count-1 do
   if ((Pos.X = Self.data[i].Position.X) and (Pos.Y = Self.data[i].Position.Y)) then
     Exit(i);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPVyhybky.Reset(orindex:Integer = -1);
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
   if (((orindex < 0) or (Self.data[i].OblRizeni = orindex)) and (Self.data[i].Blok > -2)) then
     Self.data[i].PanelProp := _Def_Vyh_Prop;
end;

////////////////////////////////////////////////////////////////////////////////

function TPVyhybky.GetItem(index:Integer):TPVyhybka;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPVyhybky.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

end.

