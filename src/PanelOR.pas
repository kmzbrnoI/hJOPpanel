unit PanelOR;

interface

uses Generics.Collections, Zasobnik, Types, HVDb, RPConst;

type
 // prava oblasti rizeni
 TORRights=record
  ModCasStart:Boolean;
  ModCasStop:Boolean;
  ModCasSet:Boolean;
 end;

 // pozice symbolu OR
 TPoss=record
  DK:TPoint;
  DKOr:byte;  //orientace DK (0,1)
  Time:TPoint;
 end;

 // 1 element osvetleni oblasti rizeni
 TOsv = record
  board:Byte;
  port:Byte;
  name:string;  //max 5 znaku
  state:boolean;
 end;

 TMereniCasu = record
   Start:TDateTime;
   Length:TDateTime;
   id:Integer;
  end;

 TORRegPleaseStatus = (null = 0, request = 1, selected = 2);

 TORRegPlease = record
  status:TORRegPleaseStatus;
  user,firstname, lastname, comment:string;
 end;

 // 1 oblast rizeni
 TORPanel=class
  str:string;
  Name:string;
  ShortName:string;
  id:string;
  Lichy:Byte;     // 0 = zleva doprava ->, 1 = zprava doleva <-
  Rights:TORRights;
  Poss:TPoss;
  Osvetleni:TList<TOsv>;
  MereniCasu:TList<TMereniCasu>;

  tech_rights:TORControlRights;
  dk_osv:Boolean;
  dk_blik:Boolean;
  dk_click_server:boolean;
  stack:TORStack;

  username:string;
  login:string;

  NUZ_status:TNUZstatus;
  RegPlease:TORRegPlease;

  HVs:THVDb;

  hlaseni:boolean;
 end;

implementation

end.
