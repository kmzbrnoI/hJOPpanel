unit BlokVyhybka;

interface

uses Classes, Graphics, Types;

type
 TVyhPoloha  = (disabled = -5, none = -1, plus = 0, minus = 1, both = 2);

 // data pro vykreslovani
 TVyhPanelProp = record
  blikani:boolean;
  Symbol,Pozadi:TColor;
  Poloha:TVyhPoloha;
 end;

 // 1 vyhybka na reliefu
 TPVyhybka=record
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

end.

