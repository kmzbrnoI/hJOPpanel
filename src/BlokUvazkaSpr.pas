unit BlokUvazkaSpr;

{
  Definice bloku uvazka-spr, jeho vlastnosti a stavu v panelu.
  Definice databaze bloku typu uvazka-spr.
  Uvazka-spr je seznam souprav u uvazky.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TUvazkaSpr = record
  strings:TStrings;
  show_index:Integer;
  time:string;
  color:TColor;
 end;

 TUvazkaSprPanelProp = record
  spr:TList<TUvazkaSpr>;
 end;

 TUvazkaSprVertDir = (top = 0, bottom = 1);

 TPUvazkaSpr=record
  Blok:Integer;
  Pos:TPoint;
  vertical_dir:TUvazkaSprVertDir;
  spr_cnt:Integer;
  OblRizeni:Integer;
  PanelProp:TUvazkaSprPanelProp;
 end;

 TPUvazkySpr = class
  private
   change_time:TDateTime;

  public
   data:TList<TPUvazkaSpr>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw);
   procedure Reset(orindex:Integer = -1);
 end;

const
  _Def_UvazkaSpr_Prop:TUvazkaSprPanelProp = (
      );

  _UVAZKY_BLIK_PERIOD = 1500;      // perioda blikani soupravy u uvazky v ms

implementation

uses PanelPainter;

////////////////////////////////////////////////////////////////////////////////

constructor TPUvazkySpr.Create();
begin
 inherited;
 Self.data := TList<TPUvazkaSpr>.Create();
 Self.change_time := Now;
end;

destructor TPUvazkySpr.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Load(ini:TMemIniFile);
var i, count:Integer;
    uvs:TPUvazkaSpr;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'UvS', 0);
 for i := 0 to count-1 do
  begin
   uvs.Blok         := ini.ReadInteger('UvS'+IntToStr(i), 'B', -1);
   uvs.OblRizeni    := ini.ReadInteger('UvS'+IntToStr(i), 'OR', -1);
   uvs.Pos.X        := ini.ReadInteger('UvS'+IntToStr(i), 'X', 0);
   uvs.Pos.Y        := ini.ReadInteger('UvS'+IntToStr(i), 'Y', 0);
   uvs.vertical_dir := TUvazkaSprVertDir(ini.ReadInteger('UvS'+IntToStr(i), 'VD', 0));
   uvs.spr_cnt      := ini.ReadInteger('UvS'+IntToStr(i), 'C', 1);
   uvs.PanelProp    := _Def_UvazkaSpr_Prop;
   uvs.PanelProp.spr := TList<TUvazkaSpr>.Create();

   Self.data.Add(uvs);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Show(obj:TDXDraw);
var j:Integer;
    top,incr:Integer;
    change:boolean;
    UvazkaSpr:TUvazkaSpr;
    uvs:TPUvazkaSpr;
begin
 if (Now > change_time) then
  begin
   change_time := Now + EncodeTime(0, 0, _UVAZKY_BLIK_PERIOD div 1000, _UVAZKY_BLIK_PERIOD mod 1000);
   change := true;
  end else
   change := false;

 for uvs in Self.data do
  begin
   if (not Assigned(uvs.PanelProp.spr)) then continue;

   top  := uvs.Pos.Y;
   if (uvs.vertical_dir = TUvazkaSprVertDir.top) then
     incr := -1
    else
     incr := 1;

   for j := 0 to uvs.PanelProp.spr.Count-1 do
    begin
     UvazkaSpr := uvs.PanelProp.spr[j];

     if (not Assigned(uvs.PanelProp.spr[j].strings)) then continue;

     // kontrola preblikavani
     if ((change) and (UvazkaSpr.strings.Count > 1)) then
       Inc(UvazkaSpr.show_index);
     if (UvazkaSpr.show_index >= UvazkaSpr.strings.Count) then // tato podminka musi byt vne predchozi podminky
       UvazkaSpr.show_index := 0;

     PanelPainter.TextOutput(Point(uvs.Pos.X, top),
          uvs.PanelProp.spr[j].strings[UvazkaSpr.show_index],
          uvs.PanelProp.spr[j].color, clBlack, obj, UvazkaSpr.show_index = 0);
     top := top + incr;

     uvs.PanelProp.spr[j] := UvazkaSpr;
    end;//for j
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Reset(orindex:Integer = -1);
var i, j:Integer;
    uvs:TPUvazkaSpr;
begin
 for i := 0 to Self.data.Count-1 do
  begin
   if (((orindex < 0) or (Self.data[i].OblRizeni = orindex)) and (Self.data[i].Blok > -2)) then
    begin
     uvs := Self.data[i];

     for j := 0 to uvs.PanelProp.spr.Count-1 do
       uvs.PanelProp.spr[j].strings.Free();
     uvs.PanelProp.spr.Free();

     uvs.PanelProp     := _Def_UvazkaSpr_Prop;
     uvs.PanelProp.spr := TList<TUvazkaSpr>.Create();

     Self.data[i] := uvs;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

end.
