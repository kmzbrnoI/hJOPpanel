unit BlokNavestidlo;

{
  Definice bloku navestidla, jeho vlastnosti a stavu v panelu.
  Definice databaze navestidel.
}

interface

uses Classes, Graphics, Types, Generics.Collections, IniFiles, DXDraws, SysUtils;

type
 TNavPanelProp = record
  Symbol,Pozadi:TColor;
  AB:Boolean;
  blikani:boolean;

  procedure Change(data:TStrings);
 end;

 TPNavestidlo = class
  Blok:Integer;
  Position:TPoint;
  SymbolID:Integer;

  OblRizeni:Integer;
  PanelProp:TNavPanelProp;
 end;

 TStartJC=record
  Pos:TPoint;
  Color:TColor;
 end;

 TPNavestidla = class
  private
   function GetItem(index:Integer):TPNavestidlo;
   function GetCount():Integer;

  public
   data:TObjectList<TPNavestidlo>;
   startJC:TList<TStartJC>;

   constructor Create();
   destructor Destroy(); override;

   procedure Load(ini:TMemIniFile);
   procedure Show(obj:TDXDraw; blik:boolean);
   function GetIndex(Pos:TPoint):Integer;
   procedure Reset(orindex:Integer = -1);

   procedure UpdateStartJC();

   property Items[index : integer] : TPNavestidlo read GetItem; default;
   property Count : integer read GetCount;
 end;

const
  _Def_Nav_Prop:TNavPanelProp = (
      Symbol: clBlack;
      Pozadi: clFuchsia;
      AB: false;
      blikani: false);

  _UA_Nav_Prop:TNavPanelProp = (
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      AB: false;
      blikani: false);


implementation

uses PanelPainter, Symbols, parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor TPNavestidla.Create();
begin
 inherited;
 Self.data := TObjectList<TPNavestidlo>.Create();
 Self.startJC := TList<TStartJC>.Create();
end;

destructor TPNavestidla.Destroy();
begin
 Self.data.Free();
 Self.startJC.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.Load(ini:TMemIniFile);
var i, count: Integer;
    nav:TPNavestidlo;
begin
 Self.data.Clear();

 count := ini.ReadInteger('P', 'N', 0);
 for i := 0 to count-1 do
  begin
   nav := TPNavestidlo.Create();

   nav.Blok       := ini.ReadInteger('N'+IntToStr(i),'B',-1);
   nav.Position.X := ini.ReadInteger('N'+IntToStr(i),'X',0);
   nav.Position.Y := ini.ReadInteger('N'+IntToStr(i),'Y',0);
   nav.SymbolID   := ini.ReadInteger('N'+IntToStr(i),'S',0);

   //OR
   nav.OblRizeni := ini.ReadInteger('N'+IntToStr(i),'OR',-1);

   //default settings:
   if (nav.Blok = -2) then
     nav.PanelProp := _UA_Nav_Prop
   else
     nav.PanelProp := _Def_Nav_Prop;

   Self.data.Add(nav);
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.Show(obj:TDXDraw; blik:boolean);
var nav:TPNavestidlo;
    fg:TColor;
begin
 for nav in Self.data do
  begin
   if ((nav.PanelProp.blikani) and (blik)) then
     fg := clBlack
   else
     fg := nav.PanelProp.Symbol;

   if (nav.PanelProp.AB) then
    begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, nav.Position, _SCom_Start+nav.SymbolID+2,
               fg, nav.PanelProp.Pozadi, obj);
    end else begin
     PanelPainter.Draw(SymbolSet.IL_Symbols, nav.Position, _SCom_Start+nav.SymbolID,
               fg, nav.PanelProp.Pozadi, obj);
    end;
  end;//for i
end;

////////////////////////////////////////////////////////////////////////////////

function TPNavestidla.GetIndex(Pos:TPoint):Integer;
var i:Integer;
begin
 Result := -1;

 for i := 0 to Self.data.Count-1 do
   if ((Pos.X = Self.data[i].Position.X) and (Pos.Y = Self.data[i].Position.Y)) then
     Exit(i);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.Reset(orindex:Integer = -1);
var i:Integer;
begin
 for i := 0 to Self.data.Count-1 do
   if (((orindex < 0) or (Self.data[i].OblRizeni = orindex)) and
       (Self.data[i].Blok > -2)) then
     Self.data[i].PanelProp := _Def_Nav_Prop;

 Self.startJC.Clear();
end;

////////////////////////////////////////////////////////////////////////////////

function TPNavestidla.GetItem(index:Integer):TPNavestidlo;
begin
 Result := Self.data[index];
end;

////////////////////////////////////////////////////////////////////////////////

function TPNavestidla.GetCount():Integer;
begin
 Result := Self.data.Count;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPNavestidla.UpdateStartJC();
var nav:TPNavestidlo;
    sjc:TStartJC;
begin
 Self.startJC.Clear();

 for nav in Self.data do
  begin
   if ((nav.PanelProp.Pozadi = clGreen) or
       (nav.PanelProp.Pozadi = clWhite) or
       (nav.PanelProp.Pozadi = clTeal)) then
    begin
     sjc.Color := nav.PanelProp.Pozadi;
     sjc.Pos   := Point(nav.Position.X-1,nav.Position.Y);
     Self.startJC.Add(sjc);

     sjc.Color := nav.PanelProp.Pozadi;
     sjc.Pos   := Point(nav.Position.X+1,nav.Position.Y);
     Self.startJC.Add(sjc);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TNavPanelProp.Change(data:TStrings);
begin
 Symbol  := StrToColor(data[4]);
 Pozadi  := StrToColor(data[5]);
 blikani := StrToBool(data[6]);
 AB      := StrToBool(data[7]);
end;

////////////////////////////////////////////////////////////////////////////////

end.

