﻿unit Verze;

interface

uses Windows, SysUtils;

 function VersionStr(const FileName: string): string;
 function BuildDateTime(): TDateTime;

 const _RELEASE: Boolean = False;

implementation

uses DateUtils;

function VersionStr(const FileName: string): string;
var
  size, len: longword;
  handle: Cardinal;
  buffer: pchar;
  pinfo: ^VS_FIXEDFILEINFO;
  Major, Minor, Release: word;
begin
  Result := 'Není dostupná';
  size := GetFileVersionInfoSize(Pointer(FileName), handle);
  if (size > 0) then
   begin
    GetMem(buffer, size);
    if ((GetFileVersionInfo(Pointer(FileName), 0, size, buffer)) and
        (VerQueryValue(buffer, '\', pointer(pinfo), len))) then
     begin
      Major := HiWord(pinfo.dwFileVersionMS);
      Minor := LoWord(pinfo.dwFileVersionMS);
      Release := HiWord(pinfo.dwFileVersionLS);
      Result := Format('%d.%d.%d',[Major, Minor, Release]);
      if (not _RELEASE) then
        Result := Result + '-dev';
     end;
    FreeMem(buffer);
  end;
end;

function BuildDateTime(): TDateTime;
begin
  Result := (TTimeZone.Local.ToLocalTime(PImageNtHeaders(HInstance + Cardinal(PImageDosHeader(HInstance)^._lfanew))^.FileHeader.TimeDateStamp / SecsPerDay) + UnixDateDelta);
end;

end.//unit
