unit HVDb;

{
  Sprava seznamu hnacich vozidel, ktere nam posle server.
  (napr. pri prilezitosti editace soupravy)
}

interface

uses Classes, SysUtils, StdCtrls, RPConst, ShellApi, Dialogs, Windows,
     Generics.Collections, Generics.Defaults, Math;

const
  _MAX_FUNC = 28;
  _DEFAULT_MAX_SPEED = 120;

type
  THVType = (other = -1, steam = 0, diesel = 1, motor = 2, electro = 3, car = 4);
  TFunkce = array [0.._MAX_FUNC] of boolean;
  THVStanoviste = (lichy = 0, sudy = 1);              // v jakem smeru se nachazi stanoviste A

  // mod posilani dat hnaciho vozidla klientovi
  // full: s POM
  TLokStringMode = (normal = 0, full = 1);

  THVPomCV = record                                 // jeden zaznam POM se sklada z
    cv:Word;                                           // oznaceni CV a
    data:Byte;                                         // dat, ktera se maji do CV zapsat.
  end;

  THVFuncType = (permanent = 0, momentary = 1);

  THV = class
   private
     procedure DefaultData();

   public
     Nazev:string;                                                              // nazev HV
     Majitel:string;                                                            // majitel HV
     Oznaceni:string;                                                           // oznaceni HV
     Poznamka:String;                                                           // poznamka k HV
     Adresa:Word;                                                               // digitalni adresa HW (0..9999)
     Typ:THVType;                                                               // Typ hnaciho vozidla - parni, diesel, motor, elektro
     Souprava:string;                                                           // cislo soupravy, na ktere je HV
     StanovisteA:THVStanoviste;                                                 // orientace stanoviste A
     funkce:TFunkce;                                                            // stav funkci
     rychlost_stupne:Word;                                                      // aktualni rychlost ve stupnich
     rychlost_kmph:Word;                                                        // aktualni rychlost v km/h
     smer:Integer;                                                              // aktualni smer
     token:string;
     orid:string;                                                               // id oblasti rizeni, ve ktere se nachazi loko
     maxRychlost:Cardinal;
     prechodnost:Cardinal;

     POMtake : TList<THVPomCV>;                                                 // seznam POM pri prevzeti do automatu
     POMrelease : TList<THVPomCV>;                                              // seznam POM pri uvolneni to rucniho rizeni

     funcVyznam:array[0.._MAX_FUNC] of string;                                  // seznam popisu funkci hnaciho vozidla
     funcType:array[0.._MAX_FUNC] of THVFuncType;                               // typy funkci hnaciho vozidla

     procedure ParseFromToken(data:string);
     procedure ParseData(data:string);
     constructor Create(data:string); overload;
     constructor Create(); overload;
     constructor CreateFromToken(data:string);
     destructor Destroy(); override;

     function GetPanelLokString(mode:TLokStringMode = normal):string;

     class function CharToHVFuncType(c:char):THVFuncType;
     class function HVFuncTypeToChar(t:THVFuncType):char;
     class function AddrComparer():IComparer<THV>;
  end;

  THVDb = class
   public
    HVs:TObjectList<THV>;

    constructor Create();
    destructor Destroy(); override;

    procedure ParseHVs(data:string);
    procedure ParseHVsFromToken(data:string);
    procedure Add(HV:THV);
    procedure Delete(index:Integer);

    procedure FillHVs(var CB:TComboBox; var Indexes:TWordAr; addr:Integer = -1; special:THV = nil; with_spr:boolean = false);
    procedure OpenJerry();

  end;

implementation

uses GlobalConfig, fMain, TCPClientPanel, parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor THVDb.Create();
begin
 inherited;
 Self.HVs := TObjectList<THV>.Create(THV.AddrComparer);
end;//ctor

destructor THVDb.Destroy();
begin
 Self.HVs.Free();
 inherited;
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure THVDb.ParseHVs(data:string);
var str:TStrings;
    hv:string;
begin
 str := TStringList.Create();
 try
   ExtractStringsEx([']'], ['['], data, str);
   Self.HVs.Clear();
   for hv in str do
     Self.HVs.Add(THV.Create(hv));
 finally
   str.Free();
 end;
end;

procedure THVDb.ParseHVsFromToken(data:string);
var str:TStrings;
    hv:string;
begin
 str := TStringList.Create();
 try
   ExtractStringsEx([']'], ['['], data, str);
   Self.HVs.Clear();
   for hv in str do
     Self.HVs.Add(THV.CreateFromToken(hv));
 finally
   str.Free();
 end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure THVDb.FillHVs(var CB:TComboBox; var Indexes:TWordAr; addr:Integer = -1; special:THV = nil; with_spr:boolean = false);
var i,index:Integer;
begin
 CB.Clear();

 if (Assigned(special)) then
  begin
   SetLength(Indexes, Self.HVs.Count+1);
   CB.Items.Add(IntToStr(special.Adresa) + ' : ' + special.Nazev + ' (' + special.Oznaceni + ')');
   Indexes[0] := special.Adresa;
   if (special.Adresa = addr) then CB.ItemIndex := 0;
   index := 1;
  end else begin
   SetLength(Indexes, Self.HVs.Count);
   index := 0;
  end;

 for i := 0 to Self.HVs.Count-1 do
  begin
   if ((Self.HVs[i].Souprava = '-') or (with_spr)) then
    begin
     CB.Items.Add(IntToStr(Self.HVs[i].Adresa) + ' : ' + Self.HVs[i].Nazev + ' (' + Self.HVs[i].Oznaceni + ')');
     Indexes[index] := Self.HVs[i].Adresa;
     if (Self.HVs[i].Adresa = addr) then CB.ItemIndex := i;
     index := index + 1;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor THV.Create(data:string);
begin
 inherited Create();
 Self.POMtake    := TList<THVPomCv>.Create();
 Self.POMrelease := TList<THVPomCv>.Create();
 Self.ParseData(data);
end;//ctor

constructor THV.Create();
begin
 inherited;
 Self.POMtake    := TList<THVPomCv>.Create();
 Self.POMrelease := TList<THVPomCv>.Create();
end;//ctor

constructor THV.CreateFromToken(data:string);
begin
 inherited Create();
 Self.ParseFromToken(data);
end;//ctor

destructor THV.Destroy();
begin
 Self.POMtake.Free();
 Self.POMrelease.Free();
 inherited;
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure THV.ParseData(data:string);
var str, str2, str3:TStrings;
    i:Integer;
    pomCv:THVPomCv;
    tmp:string;
begin
 // format zapisu: nazev|majitel|oznaceni|poznamka|adresa|Typ|souprava|stanovisteA|funkce|rychlost_stupne|
 //   rychlost_kmph|smer|or_id{[{cv1take|cv1take-value}][{...}]...}|{[{cv1release|cv1release-value}][{...}]...}|
 //   {vyznam-F0;vyznam-F1;...}|typy_funkci|max rychlost

 // souprava je bud cislo soupravy, nebo znak '-'
 str  := TStringList.Create();
 str2 := TStringList.Create();
 str3 := TStringList.Create();
 ExtractStringsEx(['|'] , [], data, str);

 Self.DefaultData();

 try
  Self.Nazev := str[0];
  Self.Majitel := str[1];
  Self.Oznaceni := str[2];
  Self.Poznamka := str[3];
  Self.Adresa := StrToInt(str[4]);
  Self.Typ := THVType(StrToInt(str[5]));
  Self.Souprava := str[6];
  Self.StanovisteA := THVStanoviste(StrToInt(str[7]));

  for i := 0 to _MAX_FUNC do
   begin
    if (i < Length(str[8])) then
      if (str[8][i+1] = '1') then
        Self.funkce[i] := true
      else
        Self.funkce[i] := false;
   end;

   Self.rychlost_stupne := StrToInt(str[9]);
   Self.rychlost_kmph   := StrToInt(str[10]);
   Self.smer            := StrToInt(str[11]);
   Self.orid            := str[12];

   if (str.Count > 13) then
    begin
     // pom-take
     ExtractStringsEx([']'] , ['['], str[13], str2);
     for tmp in str2 do
      begin
       str3.Clear();
       ExtractStringsEx(['|'] , [], tmp, str3);
       pomCV.cv   := StrToInt(str3[0]);
       pomCV.data := StrToInt(str3[1]);
       Self.POMtake.Add(pomCV);
      end;

     // pom-release
     str2.Clear();
     ExtractStringsEx([']'] , ['['], str[14], str2);
     for tmp in str2 do
      begin
       str3.Clear();
       ExtractStringsEx(['|'] , [], tmp, str3);
       pomCV.cv   := StrToInt(str3[0]);
       pomCV.data := StrToInt(str3[1]);
       Self.POMrelease.Add(pomCV);
      end;
    end;//if str.Count > 11

   // func-vyznam
   if (str.Count > 15) then
    begin
     str2.Clear();
     ExtractStringsEx([';'], [], str[15], str2);
     for i := 0 to _MAX_FUNC do
       if (i < str2.Count) then
        Self.funcVyznam[i] := str2[i]
       else
        Self.funcVyznam[i] := '';
    end else begin
     for i := 0 to _MAX_FUNC do
       Self.funcVyznam[i] := '';
    end;

   // typy funkci
   if (str.Count > 16) then
    begin
     for i := 0 to _MAX_FUNC do
       if (i < Length(str[16])) then
        Self.funcType[i] := CharToHVFuncType(str[16][i+1])
       else
        Self.funcType[i] := THVFuncType.permanent;
    end else begin
     for i := 0 to _MAX_FUNC do
       Self.funcType[i] := THVFuncType.permanent;
    end;

   if (str.Count > 17) then
     Self.maxRychlost := StrToInt(str[17]);

   if (str.Count > 18) then
     Self.prechodnost := StrToInt(str[18]);

 except

 end;

 str.Free();
 str2.Free();
 str3.Free();
end;

procedure THV.ParseFromToken(data:string);
var str:TStrings;
// format zapisu: addr|token
begin
 str := TStringList.Create();
 ExtractStringsEx(['|'], [], data, str);

 Self.DefaultData();

 try
   Self.Adresa := StrToInt(str[0]);
   Self.token  := str[1];
 except

 end;

 str.Free();
end;

////////////////////////////////////////////////////////////////////////////////

procedure THV.DefaultData();
var i:Integer;
begin
 Self.Nazev := '';
 Self.Majitel := '';
 Self.Oznaceni := '';
 Self.Poznamka := '';
 Self.Adresa := 0;
 Self.Typ := THVType.other;
 Self.Souprava := '-';
 Self.maxRychlost := _DEFAULT_MAX_SPEED;
 Self.prechodnost := 0;

 for i := 0 to _MAX_FUNC do
   Self.funkce[i] := false;
end;

////////////////////////////////////////////////////////////////////////////////

function THV.GetPanelLokString(mode:TLokStringMode = normal):string;
var i:Integer;
    pomCV:THVPomCv;
begin
 Result := Self.Nazev + '|' + Self.Majitel + '|' + Self.Oznaceni + '|{' + Self.Poznamka + '}|' +
           IntToStr(Self.adresa) + '|' + IntToStr(Integer(Self.Typ)) + '|' + Self.souprava + '|' +
           IntToStr(Integer(Self.StanovisteA)) + '|';

 for i := 0 to _MAX_FUNC do
  begin
   if (Self.funkce[i]) then
     Result := Result + '1'
   else
     Result := Result + '0';
  end;

 Result := Result + '||||'+Self.orid+'|';

 if (mode = full) then
  begin
   // cv-take
   Result := Result + '{';
   for pomCV in Self.POMtake do
     Result := Result + '[{' + IntToStr(POMcv.cv) + '|' + IntToStr(POMcv.data) + '}]';
   Result := Result + '}|{';

   // cv-release
   for pomCV in Self.POMrelease do
     Result := Result + '[{' + IntToStr(POMcv.cv) + '|' + IntToStr(POMcv.data) + '}]';
   Result := Result + '}|';
  end;// if pom

 // vyznam funkci
 Result := Result + '{';
 for i := 0 to _MAX_FUNC do
  begin
   if (Self.funcVyznam[i] <> '') then
     Result := Result + '{' + Self.funcVyznam[i] + '};'
   else
     Result := Result + ';';
  end;
 Result := Result + '}|';

 // typy funkci
 for i := 0 to _MAX_FUNC do
   Result := Result + HVFuncTypeToChar(Self.funcType[i]);
 Result := Result + '|';

 Result := Result + IntToStr(Self.maxRychlost) + '|';
 Result := Result + IntToStr(Self.prechodnost) + '|';
end;

////////////////////////////////////////////////////////////////////////////////

// Otevreni regulatoru Jerry pro vsechna loko v seznamu
procedure THVDb.OpenJerry();
var args:string;
    res:Integer;
    f:string;
    HV:THV;
begin
 // predame autoconnect, server a port
 args := '-a -s "' + GlobConfig.data.server.host + '" -pt ' + IntToStr(GlobConfig.data.server.port) + ' ';

 // predat uzivatele ?
 if ((GlobConfig.data.reg.reg_user) and (GlobConfig.data.auth.username <> '')) then
   args := args + '-u "' + GlobConfig.data.auth.username + '" -p "' + GlobConfig.data.auth.password + '" ';

 // kontrola tokenu
 for HV in Self.HVs do
   if (HV.token = '') then
     raise Exception.Create('Hnaci vozidlo '+IntToStr(HV.Adresa)+' nema token');

 // predat vozidla
 for HV in Self.HVs do
  args := args + IntTostr(HV.Adresa) + ':' + HV.token + ' ';

 // spustit regulator
 f := ExpandFileName(GlobConfig.data.reg.reg_fn);
 res := ShellExecute(F_Main.Handle, 'open', PChar(f), PChar(args), PChar(ExtractFilePath(GlobConfig.data.reg.reg_fn)), SW_SHOWNORMAL);
 if (res < 32) then
   raise Exception.Create('Nelze spustit regulator - chyba '+IntToStr(res));
end;

////////////////////////////////////////////////////////////////////////////////

procedure THVDb.Add(HV:THV);
begin
 Self.HVs.Add(HV);
 Self.HVs.Sort();
end;

////////////////////////////////////////////////////////////////////////////////

procedure THVDb.Delete(index:Integer);
begin
 Self.HVs.Delete(index);
end;

////////////////////////////////////////////////////////////////////////////////

class function THV.CharToHVFuncType(c:char):THVFuncType;
begin
 if (UpperCase(c) = 'M') then
   Result := THVFuncType.momentary
 else
   Result := THVFuncType.permanent;
end;

class function THV.HVFuncTypeToChar(t:THVFuncType):char;
begin
 if (t = THVFuncType.momentary) then
   Result := 'M'
 else
   Result := 'P';
end;

////////////////////////////////////////////////////////////////////////////////

class function THV.AddrComparer():IComparer<THV>;
begin
 Result := TComparer<THV>.Construct(
  function(const Left, Right: THV): Integer
   begin
    Result := CompareValue(Left.Adresa, Right.Adresa);
   end
 );
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
