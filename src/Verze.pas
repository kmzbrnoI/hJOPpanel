unit Verze;

interface

uses  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Menus, ImgList, Buttons,
  ComCtrls,inifiles, ActnList, AppEvnts, Mask, ScktComp,ToolWin,jpeg,
  Spin, ExtDlgs, Grids, Gauges, Registry,
  StrUtils, DateUtils, mmsystem;

 function NactiVerzi(const FileName: string): string;//cteni verze z nastaveni
 function GetZkrVersion(const FileName: string):String;
 function GetUpdateVersion(const FileName: string):String;
 function GetLastBuildDate:string;
 function GetLastBuildTime:string;

var MyMsg:Cardinal;
    Mutex:THandle;

implementation

uses Main;

function NactiVerzi(const FileName: string): string;//cteni verze z nastaveni
var
  size, len: longword;
  handle: THandle;
  buffer: pchar;
  pinfo: ^VS_FIXEDFILEINFO;
  Major, Minor, Release: word;
begin
  Result:='Nen� dostupn�';
  size := GetFileVersionInfoSize(Pointer(FileName), handle);
  if size > 0 then begin
    GetMem(buffer, size);
    if GetFileVersionInfo(Pointer(FileName), 0, size, buffer)
    then
      if VerQueryValue(buffer, '\', pointer(pinfo), len) then begin
        Major   := HiWord(pinfo.dwFileVersionMS);
        Minor   := LoWord(pinfo.dwFileVersionMS);
        Release := HiWord(pinfo.dwFileVersionLS);
        Result := Format('%d.%d.%d',[Major, Minor, Release]);
      end;
    FreeMem(buffer);
  end;
end;

function GetZkrVersion(const FileName:String):String;
var
  size, len: longword;
  handle: THandle;
  buffer: pchar;
  pinfo: ^VS_FIXEDFILEINFO;
  Major, Minor, Release: word;
 begin
  Result:='Nen� dostupn�';
  size := GetFileVersionInfoSize(Pointer(FileName), handle);
  if size > 0 then begin
    GetMem(buffer, size);
    if GetFileVersionInfo(Pointer(FileName), 0, size, buffer)
    then
      if VerQueryValue(buffer, '\', pointer(pinfo), len) then begin
        Major   := HiWord(pinfo.dwFileVersionMS);
        Minor   := LoWord(pinfo.dwFileVersionMS);
        Release := HiWord(pinfo.dwFileVersionLS);
        Result := Format('%d%d%d',[Major, Minor, Release]);
      end;
    FreeMem(buffer);
   end;
 end;//function

function GetUpdateVersion(const FileName:String):String;
var
  size, len: longword;
  handle: THandle;
  buffer: pchar;
  pinfo: ^VS_FIXEDFILEINFO;
  Major, Minor, Release: word;
 begin
  Result:='Nen� dostupn�';
  size := GetFileVersionInfoSize(Pointer(FileName), handle);
  if size > 0 then begin
    GetMem(buffer, size);
    if GetFileVersionInfo(Pointer(FileName), 0, size, buffer)
    then
      if VerQueryValue(buffer, '\', pointer(pinfo), len) then begin
        Major   := HiWord(pinfo.dwFileVersionMS);
        Minor   := LoWord(pinfo.dwFileVersionMS);
        Release := HiWord(pinfo.dwFileVersionLS);
        Result  := IntToStr((Major shl 16)+(Minor shl 8)+(Release));
      end;
    FreeMem(buffer);
   end;
 end;//function
 
function GetLastBuildDate:String;
var lSearchRec: TSearchRec;
 begin
  if (FindFirst(Application.EXEName, faAnyFile, lSearchRec) = 0) then
   begin
    DateTimeToString(Result,'dd.mm.yyyy',FileDateToDateTime(lSearchRec.Time));
    FindClose(lSearchRec);
   end;
 end;//function

function GetLastBuildTime:String;
var lSearchRec: TSearchRec;
 begin
  if (FindFirst(Application.EXEName, faAnyFile, lSearchRec) = 0) then
   begin
    DateTimeToString(Result,'hh:mm:ss',FileDateToDateTime(lSearchRec.Time));
    FindClose(lSearchRec);
   end;
 end;//function

end.//unit
