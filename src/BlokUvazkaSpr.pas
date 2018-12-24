unit BlokUvazkaSpr;

{
  Definice bloku uvazka-spr, jeho vlastnosti a stavu v panelu.
  Definice databaze bloku typu uvazka-spr.
  Uvazka-spr je seznam souprav u uvazky.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TUvazkaSpr = class
  strings:TStrings;
  show_index:Integer;
  time:string;
  time_color:TColor;
  color:TColor;

  constructor Create();
  destructor Destroy(); override;
 end;

 TUvazkaSprPanelProp = class
  spr:TObjectList<TUvazkaSpr>;

  constructor Create();
  destructor Destroy(); override;
  procedure Change(parsed:TStrings);
 end;

 TUvazkaSprVertDir = (top = 0, bottom = 1);

 TPUvazkaSpr = class
  Blok:Integer;
  Pos:TPoint;
  vertical_dir:TUvazkaSprVertDir;
  spr_cnt:Integer;
  OblRizeni:Integer;
  PanelProp:TUvazkaSprPanelProp;

  constructor Create();
  destructor Destroy(); override;
 end;

 TPUvazkySpr = class
  private
   change_time:TDateTime;

    function GetItem(index:Integer):TPUvazkaSpr;
    function GetCount():Integer;

  public
   data:TObjectList<TPUvazkaSpr>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini:TMemIniFile);
    procedure Show(obj:TDXDraw);
    procedure Reset(orindex:Integer = -1);

    property Items[index : integer] : TPUvazkaSpr read GetItem; default;
    property Count : integer read GetCount;
 end;

const
  _UVAZKY_BLIK_PERIOD = 1500;      // perioda blikani soupravy u uvazky v ms

implementation

uses PanelPainter, parseHelper, StrUtils;

////////////////////////////////////////////////////////////////////////////////

constructor TPUvazkaSpr.Create();
begin
 inherited;
 Self.PanelProp := TUvazkaSprPanelProp.Create();
end;

destructor TPUvazkaSpr.Destroy();
begin
 Self.PanelProp.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TUvazkaSprPanelProp.Create();
begin
 inherited;
 Self.spr := TObjectList<TuvazkaSpr>.Create();
end;

destructor TUvazkaSprPanelProp.Destroy();
begin
 Self.spr.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TUvazkaSpr.Create();
begin
 inherited;
 Self.strings := TStringList.Create();
end;

destructor TUvazkaSpr.Destroy();
begin
 Self.strings.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPUvazkySpr.Create();
begin
 inherited;
 Self.data := TObjectList<TPUvazkaSpr>.Create();
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
   uvs := TPUvazkaSpr.Create();

   uvs.Blok         := ini.ReadInteger('UvS'+IntToStr(i), 'B', -1);
   uvs.OblRizeni    := ini.ReadInteger('UvS'+IntToStr(i), 'OR', -1);
   uvs.Pos.X        := ini.ReadInteger('UvS'+IntToStr(i), 'X', 0);
   uvs.Pos.Y        := ini.ReadInteger('UvS'+IntToStr(i), 'Y', 0);
   uvs.vertical_dir := TUvazkaSprVertDir(ini.ReadInteger('UvS'+IntToStr(i), 'VD', 0));
   uvs.spr_cnt      := ini.ReadInteger('UvS'+IntToStr(i), 'C', 1);
   uvs.PanelProp    := TUvazkaSprPanelProp.Create();
   uvs.PanelProp.spr := TObjectList<TUvazkaSpr>.Create();

   Self.data.Add(uvs);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Show(obj:TDXDraw);
var top,incr:Integer;
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

   for UvazkaSpr in uvs.PanelProp.spr do
    begin
     if (not Assigned(UvazkaSpr.strings)) then continue;

     // kontrola preblikavani
     if ((change) and (UvazkaSpr.strings.Count > 1)) then
       Inc(UvazkaSpr.show_index);
     if (UvazkaSpr.show_index >= UvazkaSpr.strings.Count) then // tato podminka musi byt vne predchozi podminky
       UvazkaSpr.show_index := 0;

     PanelPainter.TextOutput(Point(uvs.Pos.X, top),
          UvazkaSpr.strings[UvazkaSpr.show_index],
          UvazkaSpr.color, clBlack, obj, UvazkaSpr.show_index = 0);

     if (UvazkaSpr.show_index = 0) then
       PanelPainter.TextOutput(Point(uvs.Pos.X+7, top),
            UvazkaSpr.time, UvazkaSpr.time_color, clBlack, obj);

     top := top + incr;
    end;//for j
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazkySpr.Reset(orindex:Integer = -1);
var uvs:TPUvazkaSpr;
begin
 for uvs in Self.data do
   if (((orindex < 0) or (uvs.OblRizeni = orindex)) and (uvs.Blok > -2)) then
     uvs.PanelProp.spr.Clear();
end;

////////////////////////////////////////////////////////////////////////////////

function TPUvazkySpr.GetItem(index:Integer):TPUvazkaSpr;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPUvazkySpr.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TUvazkaSprPanelProp.Change(parsed:TStrings);
var j:Integer;
    sprs_data:TStrings;
    str:string;
    uvazkaSpr:TUvazkaSpr;
begin
 if (parsed.Count < 9) then Exit();

 Self.spr.Clear();
 sprs_data := TStringList.Create();

 try
   ExtractStringsEx([','], [], parsed[8], sprs_data);

   for str in sprs_data do
    begin
     uvazkaSpr := TUvazkaSpr.Create();

     ExtractStringsEx(['|'], [], str, uvazkaSpr.strings);
     if (LeftStr(str, 1) = '$') then
      begin
       uvazkaSpr.strings[0] := RightStr(UvazkaSpr.strings[0], Length(UvazkaSpr.strings[0])-1);
       uvazkaSpr.color := clYellow;
      end else begin
       uvazkaSpr.color := clWhite;
      end;

     if (LeftStr(uvazkaSpr.strings[1], 1) = '$') then
      begin
       uvazkaSpr.time := RightStr(uvazkaSpr.strings[1], Length(uvazkaSpr.strings[1])-1);
       uvazkaSpr.time_color := clYellow;
      end else begin
       uvazkaSpr.time := uvazkaSpr.strings[1];
       uvazkaSpr.time_color := clAqua;
      end;

     uvazkaSpr.strings.Delete(1);

     // kontrola preteceni textu
     for j := 0 to uvazkaSpr.strings.Count-1 do
       if (Length(uvazkaSpr.strings[j]) > 9) then
         uvazkaSpr.strings[j] := LeftStr(UvazkaSpr.strings[j], 8) + '.';

     Self.spr.Add(UvazkaSpr);
    end;
 finally
   sprs_data.Free();
 end;
end;

////////////////////////////////////////////////////////////////////////////////

end.
