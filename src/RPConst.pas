unit RPConst;

{
  Deklarace globalnich konstant programu.
}

interface

uses Classes, SysUtils;

const
  _MAX_OR = 16;

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

  // zakazane znaky pro pouziti v komentarich; delka tohoto pole musi byt alespon 1
  //   zakazane jsou proto, ze se pouzivaji jako oddelovace v komunikaci
  _forbidden_chars : array [0..2] of char = (#13, '{', '}');


type
  TPanelButton = (F1, F2, ENTER, ESCAPE);
  TJCType = (undefinned = -1, no = 0, vlak = 1, posun = 2, nouz = 3, staveni = 4);
  TNUZstatus = (no_nuz = 0, blk_in_nuz = 1, nuzing = 2);

  TWordAr = array of Word;
  TIntAr = array of Integer;

  procedure ExtractStringsEx(Separators: TSysCharSet; Ignore: TSysCharSet; Content: string; var Strings: TStrings);
  function GetForbidderChars():string;
  function PanelButtonToString(button:TPanelButton):string;

implementation

function StrToBool(str:string):boolean;
begin
 if (str = '1') then Result := true
 else Result := false;
end;//function

////////////////////////////////////////////////////////////////////////////////
// Vlastni parsovani stringu predevsim pro TCP komunikaci.
// Toto parsovani oproti systemovemu ExtractStrings oddeluje i pradzne stringy.
// Navic cokoliv ve znacich "{" a "}" je povazovano jako plaintext bez oddelnovacu.
// Tyto znaky mohou by i zanorene.
// Napr. text: ahoj;ja;jsem;{Honza;Horazek}
//    vrati: ["ahoj", "ja", "jsem", "Honza;Horacek"]

procedure ExtractStringsEx(Separators: TSysCharSet; Ignore: TSysCharSet; Content: string; var Strings: TStrings);
var i: word;
    s: string;
    plain_cnt:Integer;
 begin
  s := '';
  plain_cnt := 0;
  if (Length(Content) = 0) then Exit();

  for i := 1 to Length(Content) do
   begin
    if (Content[i] = '{') then
     begin
      if (plain_cnt > 0) then s := s + Content[i];
      Inc(plain_cnt);
     end
    else if ((Content[i] = '}') and (plain_cnt > 0)) then
     begin
      Dec(plain_cnt);
      if (plain_cnt > 0) then s := s + Content[i];
     end
    else begin
      if ((CharInSet(Content[i], Separators)) and (plain_cnt = 0)) then
       begin
        Strings.Add(s);
        s := '';
       end else
        if (not CharInSet(Content[i], Ignore) or (plain_cnt > 0)) then
          s := s + Content[i];
    end;// else Content[i]
   end;

  if (s <> '') then Strings.Add(s);
end;

////////////////////////////////////////////////////////////////////////////////

function GetForbidderChars():string;
var i:Integer;
begin
 Result := '';
 for i := 0 to Length(_forbidden_chars)-2 do
   Result := Result + _forbidden_chars[i] + ' ';
 Result := Result + _forbidden_chars[Length(_forbidden_chars)-1];
end;//function

////////////////////////////////////////////////////////////////////////////////

function PanelButtonToString(button:TPanelButton):string;
begin
 case (button) of
   TPanelButton.F1 : Result := 'F1';
   TPanelButton.F2 : Result := 'F2';
   TPanelButton.ENTER : Result := 'ENTER';
   TPanelButton.ESCAPE : Result := 'ESCAPE';
 else
   Result := '';
 end;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
