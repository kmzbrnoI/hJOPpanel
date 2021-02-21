unit parseHelper;

{
  Tato unit implementuje pmocne parsovaci funkce.
}

interface

uses Classes, SysUtils, Graphics, Windows, StrUtils, Types;

procedure ExtractStringsEx(Separators: TSysCharSet; Ignore: TSysCharSet; Content: string; var Strings: TStrings);
function GetPos(data: string): TPoint;
function StrToColor(str: string): TColor;

implementation

/// /////////////////////////////////////////////////////////////////////////////
// Vlastni parsovani stringu predevsim pro TCP komunikaci.
// Toto parsovani oproti systemovemu ExtractStrings oddeluje i pradzne stringy.
// Navic cokoliv ve znacich "{" a "}" je povazovano jako plaintext bez oddelnovacu.
// Tyto znaky mohou by i zanorene.
// Napr. text: ahoj;ja;jsem;{Honza;Horazek}
// vrati: ["ahoj", "ja", "jsem", "Honza;Horacek"]

procedure ExtractStringsEx(Separators: TSysCharSet; Ignore: TSysCharSet; Content: string; var Strings: TStrings);
var i: word;
  s: string;
  plain_cnt: Integer;
begin
  s := '';
  plain_cnt := 0;
  if (Length(Content) = 0) then
    Exit();

  for i := 1 to Length(Content) do
  begin
    if (Content[i] = '{') then
    begin
      if (plain_cnt > 0) then
        s := s + Content[i];
      Inc(plain_cnt);
    end else if ((Content[i] = '}') and (plain_cnt > 0)) then
    begin
      Dec(plain_cnt);
      if (plain_cnt > 0) then
        s := s + Content[i];
    end else begin
      if ((CharInSet(Content[i], Separators)) and (plain_cnt = 0)) then
      begin
        Strings.Add(s);
        s := '';
      end else if (not CharInSet(Content[i], Ignore) or (plain_cnt > 0)) then
        s := s + Content[i];
    end; // else Content[i]
  end;

  if (s <> '') then
    Strings.Add(s);
end;

// input format: x;y
function GetPos(data: string): TPoint;
var list: TStrings;
begin
  list := TStringList.Create;
  ExtractStrings([';'], [], PChar(data), list);

  if (list.Count < 2) then
  begin
    Result := Point(-1, -1);
    Exit;
  end;

  Result := Point(StrToIntDef(list[0], -1), StrToIntDef(list[1], -1));

  list.Free;
end;

function StrToColor(str: string): TColor;
begin
  Result := RGB(StrToInt('$' + LeftStr(str, 2)), StrToInt('$' + Copy(str, 3, 2)), StrToInt('$' + RightStr(str, 2)));
end;

end.
