unit Hash;

{
  Generace hashu hesla pro odesilani na server.
}

interface

uses System.Hash, SysUtils;

  function GenerateHash(plain: AnsiString):string;

implementation

function GenerateHash(plain: AnsiString):string;
begin
 Result := LowerCase(System.hash.THashSHA2.GetHashString(plain, SHA256));
end;

end.
