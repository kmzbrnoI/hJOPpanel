unit Verze;

{
  Ziskani verze programu.
}

interface

uses Windows, SysUtils, Forms, jclPEImage;

function NactiVerzi(const FileName: string): string; // cteni verze z nastaveni
function GetLastBuildDate: string;
function GetLastBuildTime: string;

const _RELEASE: Boolean = false;

implementation

function NactiVerzi(const FileName: string): string; // cteni verze z nastaveni
var
  size, len: longword;
  handle: Cardinal;
  buffer: pchar;
  pinfo: ^VS_FIXEDFILEINFO;
  Major, Minor, Release: word;
begin
  Result := 'Není dostupná';
  size := GetFileVersionInfoSize(Pointer(FileName), handle);
  if size > 0 then
  begin
    GetMem(buffer, size);
    if GetFileVersionInfo(Pointer(FileName), 0, size, buffer) then
      if VerQueryValue(buffer, '\', Pointer(pinfo), len) then
      begin
        Major := HiWord(pinfo.dwFileVersionMS);
        Minor := LoWord(pinfo.dwFileVersionMS);
        Release := HiWord(pinfo.dwFileVersionLS);
        Result := Format('%d.%d.%d', [Major, Minor, Release]);
        if (not _RELEASE) then
          Result := Result + '-dev';
      end;
    FreeMem(buffer);
  end;
end;

function GetLastBuildDate(): String;
begin
  DateTimeToString(Result, 'd. m. yyyy', jclPEImage.PeReadLinkerTimeStamp(Application.ExeName));
end;

function GetLastBuildTime(): String;
begin
  DateTimeToString(Result, 'hh:mm:ss', jclPEImage.PeReadLinkerTimeStamp(Application.ExeName));
end;

end.// unit
