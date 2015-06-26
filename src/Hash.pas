unit Hash;

// Generace hashu hesla pro odesilani na server.

interface

uses DCPsha256, SysUtils;

  function GenerateHash(plain:string):string;

implementation

function GenerateHash(plain:string):string;
var hash: TDCP_sha256;
    Digest: array[0..31] of byte;  // RipeMD-160 produces a 160bit digest (20bytes)
    i:Integer;
begin
 hash := TDCP_sha256.Create(nil);
 hash.Init();
 hash.UpdateStr(plain);
 hash.Final(Digest);
 hash.Free();

 Result := '';
 for i:= 0 to 31 do
   Result := Result + IntToHex(Digest[i],2);
end;//function

end.//unit
