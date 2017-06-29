unit parseHelper;

{
  Tato unit implementuje pmocne parsovaci funkce.
}

interface

uses Types, Classes, SysUtils;

function GetPos(data:string):TPoint;

implementation

//input format: x;y
function GetPos(data:string):TPoint;
var list:TStrings;
begin
 list := TStringList.Create;
 ExtractStrings([';'], [], PChar(data), list);

 if (list.Count < 2) then
  begin
   Result := Point(-1,-1);
   Exit;
  end;

 Result := Point(StrToIntDef(list[0],-1), StrToIntDef(list[1],-1));

 list.Free;
end;//function

end.
