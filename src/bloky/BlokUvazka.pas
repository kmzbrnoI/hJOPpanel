unit BlokUvazka;

{
  Definice bloku uvazka, jeho vlastnosti a stavu v panelu.
  Definice databaze bloku typu uvazka.
}

interface

uses Graphics, Types, Generics.Collections, IniFiles, SysUtils, DXDraws, Classes;

type
 TUvazkaSmer = (disabled = -1, zadny = 0, zakladni = 1, opacny = 2);

 TUvazkaPanelProp = record
  Symbol,Pozadi:TColor;
  blik:boolean;
  smer:TUvazkaSmer;

  procedure Change(parsed:TStrings);
 end;

 TPUvazka = class
  Blok:Integer;
  Pos:TPoint;
  defalt_dir:Integer;
  OblRizeni:Integer;
  PanelProp:TUvazkaPanelProp;
 end;

 TPUvazky = class
  private
    function GetItem(index:Integer):TPUvazka;
    function GetCount():Integer;

  public
   data:TObjectList<TPUvazka>;

    constructor Create();
    destructor Destroy(); override;

    procedure Load(ini:TMemIniFile);
    procedure Show(obj:TDXDraw; blik:boolean);
    function GetIndex(Pos:TPoint):Integer;
    procedure Reset(orindex:Integer = -1);

    property Items[index : integer] : TPUvazka read GetItem; default;
    property Count : integer read GetCount;
 end;

const
 _Def_Uvazka_Prop:TUvazkaPanelProp = (
      Symbol: clBlack;
      Pozadi: clFuchsia;
      blik: false;
      smer: disabled;
  );

 _UA_Uvazka_Prop:TUvazkaPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      blik: false;
      smer: zadny;
  );

implementation

uses PanelPainter, Symbols, parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor TPUvazky.Create();
begin
 inherited;
 Self.data := TObjectList<TPUvazka>.Create();
end;

destructor TPUvazky.Destroy();
begin
 Self.data.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazky.Load(ini:TMemIniFile);
var i, count:Integer;
    uv:TPUvazka;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'Uv', 0);
 for i := 0 to count-1 do
  begin
   uv := TPUvazka.Create();

   uv.Blok        := ini.ReadInteger('Uv'+IntToStr(i), 'B', -1);
   uv.OblRizeni   := ini.ReadInteger('Uv'+IntToStr(i), 'OR', -1);
   uv.Pos.X       := ini.ReadInteger('Uv'+IntToStr(i), 'X', 0);
   uv.Pos.Y       := ini.ReadInteger('Uv'+IntToStr(i), 'Y', 0);
   uv.defalt_dir  := ini.ReadInteger('Uv'+IntToStr(i), 'D', 0);

   //default settings:
   if (uv.Blok = -2) then
     uv.PanelProp := _UA_Uvazka_Prop
   else
     uv.PanelProp := _Def_Uvazka_Prop;

   Self.data.Add(uv);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazky.Show(obj:TDXDraw; blik:boolean);
var fg:TColor;
    uv:TPUvazka;
begin
 for uv in Self.data do
  begin
   if ((uv.PanelProp.blik) and (blik)) then
     fg := clBlack
   else
     fg := uv.PanelProp.Symbol;

   case (uv.PanelProp.smer) of
    TUvazkaSmer.disabled, TUvazkaSmer.zadny:begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, uv.Pos,
               _Uvazka_Start, fg, uv.PanelProp.Pozadi, obj);
     PanelPainter.Draw(SymbolSet.IL_Symbols, Point(uv.Pos.X+1, uv.Pos.Y),
               _Uvazka_Start+1, fg, uv.PanelProp.Pozadi, obj);
    end;

    TUvazkaSmer.zakladni, TUvazkaSmer.opacny:begin
     if (((uv.PanelProp.smer = zakladni) and (uv.defalt_dir = 0)) or
        ((uv.PanelProp.smer = opacny) and (uv.defalt_dir = 1))) then
      begin
       // sipka zleva doprava
       PanelPainter.Draw(SymbolSet.IL_Symbols, uv.Pos,
                 _Usek_Start, fg, uv.PanelProp.Pozadi, obj);
       PanelPainter.Draw(SymbolSet.IL_Symbols, Point(uv.Pos.X+1, uv.Pos.Y),
                 _Uvazka_Start+1, fg, uv.PanelProp.Pozadi, obj);
      end else begin
       // sipka zprava doleva
       PanelPainter.Draw(SymbolSet.IL_Symbols, uv.Pos,
                 _Uvazka_Start, fg, uv.PanelProp.Pozadi, obj);
       PanelPainter.Draw(SymbolSet.IL_Symbols, Point(uv.Pos.X+1, uv.Pos.Y),
                 _Usek_Start, fg, uv.PanelProp.Pozadi, obj);
      end;
    end;
   end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TPUvazky.GetIndex(Pos:TPoint):integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.data.Count-1 do
   if ((Pos.X >= Self.data[i].Pos.X) and (Pos.Y = Self.data[i].Pos.Y) and
       (Pos.X <= Self.data[i].Pos.X+1)) then
     Exit(i);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPUvazky.Reset(orindex:Integer = -1);
var uvazka: TPUvazka;
begin
 for uvazka in Self.data do
  begin
   if ((orindex < 0) or (uvazka.OblRizeni = orindex)) then
    begin
     if (uvazka.Blok > -2) then
       uvazka.PanelProp := _Def_Uvazka_Prop
     else
       uvazka.PanelProp := _UA_Uvazka_Prop;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TPUvazky.GetItem(index:Integer):TPUvazka;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPUvazky.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TUvazkaPanelProp.Change(parsed:TStrings);
begin
 Symbol := StrToColor(parsed[4]);
 Pozadi := StrToColor(parsed[5]);
 blik   := StrToBool(parsed[6]);
 smer   := TUvazkaSmer(StrToInt(parsed[7]));
end;

////////////////////////////////////////////////////////////////////////////////

end.
