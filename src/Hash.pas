unit Hash;

{
  Generace hashu hesla pro odesilani na server.
}

interface

uses DCPsha256, SysUtils;

  function GenerateHash(plain:AnsiString):string;

implementation

function GenerateHash(plain: AnsiString):string;
var hash: TDCP_sha256;
    digest: array[0..31] of byte;
    i:Integer;
begin
 hash := TDCP_sha256.Create(nil);
 hash.Init();
 hash.UpdateStr(plain);
 hash.Final(digest);
 hash.Free();

 Result := '';
 for i := 0 to 31 do
   Result := Result + IntToHex(Digest[i], 2);
 Result := LowerCase(Result);
end;

end.//unit
