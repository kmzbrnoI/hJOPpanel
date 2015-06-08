unit RPConst;
//deklarace konstant programu
interface

uses Classes;

const
  _MAX_OSV = 8;
  _MAX_OR = 16;
  _MAX_TRAT_SPR = 4;

  // tady je jen napsano, kolikrat se nasobi puvodni rozmery = kolik symbol zabira poli
  _Trat_Sirka = 2;
  _Trat_Vyska = 1;

  _DK_Sirka = 5;
  _DK_Vyska = 3;

  _BLK_VYH     = 0;
  _BLK_USEK    = 1;
  _BLK_IR      = 2;
  _BLK_SCOM    = 3;
  _BLK_PREJEZD = 4;
  _BLK_TRAT    = 5;
  _BLK_UVAZKA  = 6;
  _BLK_ZAMEK   = 7;
  _BLK_ROZP    = 8;
  _BLK_UVAZKA_SPR = 9;
  _BLK_VYKOL   = 10;

  _MOUSE_PANEL = 0;
  _MOUSE_OS    = 1;

  _UVAZKY_BLIK_PERIOD = 1500;      // perioda blikani soupravy u uvazky v ms

  // zakazane znaky pro pouziti v komentarich; delka tohoto pole musi byt alespon 1
  //   zakazane jsou proto, ze se pouzivaji jako oddelovace v komunikaci
  _forbidden_chars : array [0..6] of char = (#13, '/', '\', '|', '[', ']', ';');


type
  TORControlRights = (null = 0, read = 1, write = 2, superuser = 3);
  TPanelButton = (left = 0, middle = 1, right = 2, F2 = 3, F3 = 4);
  TJCType = (undefinned = -1, no = 0, vlak = 1, posun = 2, nouz = 3, staveni = 4);
  TVyhPoloha  = (disabled = -5, none = -1, plus = 0, minus = 1, both = 2);
  TNUZstatus = (no_nuz = 0, blk_in_nuz = 1, nuzing = 2);
  TSymbolSetType = (normal = 0, bigger = 1);

  TWordAr = array of Word;

  procedure ExtractStringsEx(Separator: Char; Content: string; Strings: TStrings);
  function GetForbidderChars():string;

implementation


function StrToBool(str:string):boolean;
begin
 if (str = '1') then Result := true
 else Result := false;
end;//function

procedure ExtractStringsEx(Separator: Char; Content: string; Strings: TStrings);
var i: word;
    s: string;
 begin
  s := '';
  if (Length(Content) = 0) then
   begin
    Exit;
   end;
  for i := 1 to Length(Content) do
   begin
    if (Content[i] = Separator) then
     begin
      Strings.Add(s);
      s := '';
     end else begin
      s := s + Content[i];
     end;
   end;
  Strings.Add(s);
end;

function GetForbidderChars():string;
var i:Integer;
begin
 Result := '';
 for i := 0 to Length(_forbidden_chars)-2 do
   Result := Result + _forbidden_chars[i] + ' ';
 Result := Result + _forbidden_chars[Length(_forbidden_chars)-1];
end;//function

end.//unit
