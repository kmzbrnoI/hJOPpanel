unit ORList;

{
  TORDb shromazduje vsechny oblasti rizeni
  ostatni casti programu se ho pak muzou na ORs ptat
}

interface

uses SysUtils, Classes, Generics.Collections, Generics.Defaults;

type
  TAreaDb = class
  private
  public

    db: TDictionary<string, string>;
    db_reverse: TDictionary<string, string>;
    names_sorted: TList<string>;

    constructor Create();
    destructor Destroy(); override;

    procedure Parse(data: string);
    class function StrComparer(): IComparer<string>;

  end; // class

var
  areaDb: TAreaDb;

implementation

uses parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

constructor TAreaDb.Create();
begin
  inherited;
  Self.db := TDictionary<string, string>.Create();
  Self.db_reverse := TDictionary<string, string>.Create();
  Self.names_sorted := TList<string>.Create(Self.StrComparer());
end;

destructor TAreaDb.Destroy();
begin
  Self.db.Free();
  Self.db_reverse.Free();
  Self.names_sorted.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TAreaDb.Parse(data: string);
var list1, list2: TStrings;
begin
  try
    list1 := TStringList.Create();
    list2 := TStringList.Create();
    try
      ExtractStringsEx([']'], ['['], data, list1);

      Self.db.Clear();
      Self.db_reverse.Clear();
      Self.names_sorted.Clear();

      for var i := 0 to list1.Count - 1 do
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

/// /////////////////////////////////////////////////////////////////////////////

class function TAreaDb.StrComparer(): IComparer<string>;
begin
  Result := TComparer<string>.Construct(
    function(const Left, Right: string): Integer
    begin
      Result := CompareStr(Left, Right, loUserLocale);
    end);
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

areaDb := TAreaDb.Create();

finalization

FreeAndNil(areaDb);

end.
