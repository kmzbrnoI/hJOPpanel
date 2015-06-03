unit ORList;

// TORDb shromazduje vsechny oblasti rizeni
//  ostatni casti programu se ho pak muzou na ORs ptat

interface

uses SysUtils, StrUtils, Classes;

const
  _MAX_OR = 64;

type
  TOR = record
   id:string;
   name:string;
  end;

  TORDb = class
   private
   public

    data: array [0.._MAX_OR] of TOR;
    cnt:Integer;

    constructor Create();

    procedure Parse(data:string);

  end;//class

var
  ORDb : TORDb;

implementation

////////////////////////////////////////////////////////////////////////////////

constructor TORDb.Create();
begin
 inherited Create();

 Self.cnt := 0;
end;//ctor

////////////////////////////////////////////////////////////////////////////////

procedure TORDb.Parse(data:string);
var i:Integer;
    list1, list2:TStrings;
begin
 try
   list1 := TStringList.Create();
   list2 := TStringList.Create();

   ExtractStrings(['(', ')'], [], PChar(data), list1);

   Self.cnt := list1.Count;

   for i := 0 to list1.Count-1 do
    begin
     list2.Clear();
     ExtractStrings([','], [], PChar(list1[i]), list2);

     try
       Self.data[i].id   := list2[0];
       Self.data[i].name := list2[1];
     except
       Self.data[i].id   := '';
       Self.data[i].name := '';
     end;
    end;

   list1.Free();
   list2.Free();
 except
   Self.cnt := 0;
 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

initialization
  ORDb := TORDb.Create();

finalization
  FreeAndNil(ORDb);

end.//unit
