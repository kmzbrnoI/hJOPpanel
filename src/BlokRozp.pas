unit BlokRozp;

{
  Definice bloku rozpojovac, jeho vlastnosti a stavu v panelu.
  Definice databaze rozpojovacu.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TRozpPanelProp = record
  Symbol,Pozadi:TColor;
  blik:boolean;
 end;

 TPRozp = record
  Blok:Integer;
  Pos:TPoint;
  OblRizeni:Integer;
  PanelProp:TRozpPanelProp;
 end;


 TPRozpojovace = class
  private
   function GetItem(index:Integer):TPRozp;
   function GetCount():Integer;

  public
   data:TList<TPRozp>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw);
   procedure Reset(orindex:Integer = -1);

   property Items[index : integer] : TPRozp read GetItem; default;
   property Count : integer read GetCount;
 end;

const
  _Def_Rozp_Prop:TRozpPanelProp = (
      Symbol: clFuchsia;
      Pozadi: clBlack;
      blik: false;
      );

  _UA_Rozp_Prop:TRozpPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      blik: false;
      );


implementation

uses Symbols, PanelPainter;

////////////////////////////////////////////////////////////////////////////////

constructor TPRozpojovace.Create();
begin
 inherited;
 Self.data := TList<TPRozp>.Create();
end;

destructor TPRozpojovace.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPRozpojovace.Load(ini:TMemIniFile);
var count, i:Integer;
    rozp:TPRozp;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'R', 0);
 for i := 0 to count-1 do
  begin
   rozp.Blok      := ini.ReadInteger('R'+IntToStr(i), 'B', -1);
   rozp.OblRizeni := ini.ReadInteger('R'+IntToStr(i), 'OR', -1);
   rozp.Pos.X     := ini.ReadInteger('R'+IntToStr(i), 'X', 0);
   rozp.Pos.Y     := ini.ReadInteger('R'+IntToStr(i), 'Y', 0);

   //default settings:
   if (rozp.Blok = -2) then
     rozp.PanelProp := _UA_Rozp_Prop
   else
     rozp.PanelProp := _Def_Rozp_Prop;

   Self.data.Add(rozp);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPRozpojovace.Show(obj:TDXDraw);
var rozp:TPRozp;
begin
 for rozp in Self.data do
   PanelPainter.Draw(SymbolSet.IL_Symbols, rozp.Pos, _Rozp_Start+1, rozp.PanelProp.Symbol,
      clBlack, obj, true);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPRozpojovace.Reset(orindex:Integer = -1);
var i:Integer;
    rozp:TPRozp;
begin
 for i := 0 to Self.data.Count-1 do
  begin
   if (((orindex < 0) or (Self.data[i].OblRizeni = orindex)) and
       (Self.data[i].Blok > -2)) then
    begin
     rozp := Self.data[i];
     rozp.PanelProp := _Def_Rozp_Prop;
     Self.data[i] := rozp;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TPRozpojovace.GetItem(index:Integer):TPRozp;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPRozpojovace.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

end.

