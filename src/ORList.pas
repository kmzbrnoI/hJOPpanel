unit ORList;

{
  TORDb shromazduje vsechny oblasti rizeni
   ostatni casti programu se ho pak muzou na ORs ptat
}

interface

uses SysUtils, Classes, Generics.Collections, Generics.Defaults;

type
  TORDb = class
   private
   public

    db: TDictionary<string, string>;
    db_reverse: TDictionary<string, string>;
    names_sorted: TList<string>;

    constructor Create();
    destructor Destroy(); override;

    procedure Parse(data:string);
    class function StrComparer():IComparer<string>;

  end;//class

var
  ORDb : TORDb;

implementation

uses parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor TORDb.Create();
begin
 inherited;
 Self.db := TDictionary<string, string>.Create();
 Self.db_reverse := TDictionary<string, string>.Create();
 Self.names_sorted := TList<string>.Create(Self.StrComparer());
end;//ctor

destructor TORDb.Destroy();
begin
 Self.db.Free();
 Self.db_reverse.Free();
 Self.names_sorted.Free();
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
   try
     ExtractStringsEx([']'], ['['], data, list1);

     Self.db.Clear();
     Self.db_reverse.Clear();
     Self.names_sorted.Clear();

     for i := 0 to list1.Count-1 do
      begin
       list2.Clear();
       ExtractStringsEx([','], [], list1[i], list2);

       try
         Self.db.Add(list2[0], list2[1]);
         Self.db_reverse.Add(list2[1], list2[0]);
         Self.names_sorted.Add(list2[1]);
       except

       end;
      end;

     Self.names_sorted.Sort();
   finally
     list1.Free();
     list2.Free();
   end;
 except

 end;
end;

////////////////////////////////////////////////////////////////////////////////

class function TORDb.StrComparer():IComparer<string>;
begin
 Result := TComparer<string>.Construct(
  function(const Left, Right: string): Integer
   begin
    Result := CompareStr(Left, Right, loUserLocale);
   end
 );
end;

////////////////////////////////////////////////////////////////////////////////

initialization
  ORDb := TORDb.Create();

finalization
  FreeAndNil(ORDb);

end.//unit
