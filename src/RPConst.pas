unit RPConst;

{
  Deklarace globalnich konstant programu.
}

interface

uses Classes, SysUtils;

const
  // zakazane znaky pro pouziti v komentarich; delka tohoto pole musi byt alespon 1
  //   zakazane jsou proto, ze se pouzivaji jako oddelovace v komunikaci
  _forbidden_chars : array [0..2] of char = (#13, '{', '}');


type
  TPanelButton = (F1, F2, ENTER, ESCAPE);
  TNUZstatus = (no_nuz = 0, blk_in_nuz = 1, nuzing = 2);

  TWordAr = array of Word;
  TIntAr = array of Integer;

  function GetForbidderChars():string;

implementation

function StrToBool(str:string):boolean;
begin
 Result := (str = '1');
end;

////////////////////////////////////////////////////////////////////////////////

function GetForbidderChars():string;
var i:Integer;
begin
 Result := '';
 for i := 0 to Length(_forbidden_chars)-2 do
   Result := Result + _forbidden_chars[i] + ' ';
 Result := Result + _forbidden_chars[Length(_forbidden_chars)-1];
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
