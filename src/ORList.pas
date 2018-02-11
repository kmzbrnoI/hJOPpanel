unit ORList;

{
  TORDb shromazduje vsechny oblasti rizeni
   ostatni casti programu se ho pak muzou na ORs ptat
}

interface

uses SysUtils, StrUtils, Classes, Generics.Collections;

type
  TORDb = class
   private
   public

    db: TDictionary<string, string>;
    db_reverse: TDictionary<string, string>;

    constructor Create();
    destructor Destroy(); override;

    procedure Parse(data:string);

  end;//class

var
  ORDb : TORDb;

implementation

uses RPConst, parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor TORDb.Create();
begin
 inherited;
 Self.db := TDictionary<string, string>.Create();
 Self.db_reverse := TDictionary<string, string>.Create();
end;//ctor

destructor TORDb.Destroy();
begin
 Self.db.Free();
 Self.db_reverse.Clear();
 inherited;
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure TORDb.Parse(data:string);
var i:Integer;
    list1, list2:TStrings;
begin
 try
   list1 := TStringList.Create();
   list2 := TStringList.Create();

   ExtractStringsEx([']'], ['['], data, list1);

   Self.db.Clear();
   Self.db_reverse.Clear();

   for i := 0 to list1.Count-1 do
    begin
     list2.Clear();
     ExtractStringsEx([','], [], list1[i], list2);

     try
       Self.db.Add(list2[0], list2[1]);
       Self.db_reverse.Add(list2[1], list2[0]);
     except

     end;
    end;

   list1.Free();
   list2.Free();
 except

 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

initialization
  ORDb := TORDb.Create();

finalization
  FreeAndNil(ORDb);

end.//unit
