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
var vyh:TPVyhybka;
begin
 for vyh in Self.data do
   vyh.Show(obj, blik, useky);
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
var vyh:TPVyhybka;
begin
 for vyh in Self.data do
   if (((orindex < 0) or (vyh.OblRizeni = orindex))) then
     vyh.Reset();
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

