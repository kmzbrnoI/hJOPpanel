unit BlokVyhybka;

{
  Definice bloku vyhybka.
  Sem patri pouze definice bloku, nikoliv definice databaze vyhybek
  (kvuli pouzivani v jinych unitach).
}

interface

uses Classes, Graphics, Types, SysUtils;

type
 TVyhPoloha  = (disabled = -5, none = -1, plus = 0, minus = 1, both = 2);

 // data pro vykreslovani
 TVyhPanelProp = record
  blikani:boolean;
  Symbol,Pozadi:TColor;
  Poloha:TVyhPoloha;

  procedure Change(parsed:TStrings);
 end;

 // 1 vyhybka na reliefu
 TPVyhybka = class
  Blok:Integer;
  PolohaPlus:Byte;
  Position:TPoint;
  SymbolID:Integer;
  obj:integer;

  OblRizeni:Integer;
  PanelProp:TVyhPanelProp;
  visible:boolean;      // na zaklade viditelnosti ve vetvich je rekonstruovana viditelnost vyhybky
 end;//Navestidlo

const
  _Def_Vyh_Prop:TVyhPanelProp = (
      blikani: false;
      Symbol: clBlack;
      Pozadi: clFuchsia;
      Poloha: TVyhPoloha.disabled);

  _UA_Vyh_Prop:TVyhPanelProp = (
      blikani: false;
      Symbol: $A0A0A0;
      Pozadi: clBlack;
      Poloha: TVyhPoloha.both);

implementation

uses parseHelper;

////////////////////////////////////////////////////////////////////////////////

procedure TVyhPanelProp.Change(parsed:TStrings);
begin
 Symbol  := StrToColor(parsed[4]);
 Pozadi  := StrToColor(parsed[5]);
 blikani := StrToBool(parsed[6]);
 Poloha  := TVyhPoloha(StrToInt(parsed[7]));
end;

////////////////////////////////////////////////////////////////////////////////

end.

