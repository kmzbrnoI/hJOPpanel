unit PanelOR;

interface

uses Generics.Collections, Zasobnik, Types, HVDb, RPConst, Classes, SysUtils,
     PGraphics;


type
 TORControlRights = (null = 0, read = 1, write = 2, superuser = 3);

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

 TORRegPleaseStatus = (none = 0, request = 1, selected = 2);

 TORRegPlease = record
  status:TORRegPleaseStatus;
  user,firstname, lastname, comment:string;
 end;

 EInvalidData = class(Exception);

 // 1 oblast rizeni
 TORPanel = class
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

   constructor Create(line:string; Graphics:TPanelGraphics);
   destructor Destroy(); override;
 end;

implementation

////////////////////////////////////////////////////////////////////////////////

constructor TORPanel.Create(line:string; Graphics:TPanelGraphics);
var data_main, data_osv, data_osv2:TStrings;
    j:Integer;
    Osv:TOsv;
    Pos:TPoint;
begin
 inherited Create();

 data_main := TStringList.Create();
 data_osv  := TStringList.Create();
 data_osv2 := TStringList.Create();

 try
   ExtractStringsEx([';'], [], line, data_main);

   if (data_main.Count < 14) then
     raise EInvalidData.Create('Prilis malo polozek v zaznamu oblasti rizeni!');

   Self.str := line;

   Self.Name       := data_main[0];
   Self.ShortName  := data_main[1];
   Self.id         := data_main[2];
   Self.Lichy      := StrToInt(data_main[3]);
   Self.Poss.DKOr  := StrToInt(data_main[4]);

   Self.Rights.ModCasStart := StrToBool(data_main[5]);
   Self.Rights.ModCasStop  := StrToBool(data_main[6]);
   Self.Rights.ModCasSet   := StrToBool(data_main[7]);

   Self.Poss.DK.X := StrToInt(data_main[8]);
   Self.Poss.DK.Y := StrToInt(data_main[9]);

   Pos.X := StrToInt(data_main[10]);
   Pos.Y := StrToInt(data_main[11]);
   Self.stack := TORStack.Create(graphics, Self.id, Pos);

   Self.Poss.Time.X := StrToInt(data_main[12]);
   Self.Poss.Time.Y := StrToInt(data_main[13]);

   Self.Osvetleni := TList<TOsv>.Create();
   Self.MereniCasu := TList<TMereniCasu>.Create();

   data_osv.Clear();
   if (data_main.Count >= 15) then
    begin
     ExtractStrings(['|'],[],PChar(data_main[14]),data_osv);
     for j := 0 to data_osv.Count-1 do
      begin
       data_osv2.Clear();
       ExtractStrings(['#'],[],PChar(data_osv[j]),data_osv2);

       if (data_osv2.Count < 2) then continue;

       Osv.board := StrToInt(data_osv2[0]);
       Osv.port  := StrToInt(data_osv2[1]);
       if (data_osv2.Count > 2) then Osv.name := data_osv2[2] else Osv.name := '';
       Self.Osvetleni.Add(Osv);
      end;//for j
     end;//.Count >= 15

   Self.HVs := THVDb.Create();
 finally
   data_main.Free();
   data_osv.Free();
   data_osv2.Free();
 end;
end;

////////////////////////////////////////////////////////////////////////////////

destructor TORPanel.Destroy();
begin
 Self.stack.Free();
 Self.Osvetleni.Free();
 Self.MereniCasu.Free();
 Self.HVs.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

end.
