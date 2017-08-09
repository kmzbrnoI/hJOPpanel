unit Sounds;

interface

uses SysUtils, SoundsThread, Classes, mmsystem;

// vyssi cislo zvuku ma vzdy vetsi prioritu na prehrani
const
  _SND_TRAT_ZADOST  = 4;
  _SND_PRIVOLAVACKA = 5;
  _SND_TIMEOUT      = 6;
  _SND_PRETIZENI    = 7;
  _SND_POTVR_SEKV   = 8;
  _SND_ZPRAVA       = 9;
  _SND_CHYBA        = 10;

  _SND_BUF_LEN     = 8;

type
 TSound = record
   code:Integer;
 end;

 TSoundsPlay=class                                  // prehravani zvuku
  private
    buffer:array[0.._SND_BUF_LEN-1] of TSound;                    // z bufferu vzdy vyberu zvuk z nejvyssim 'code' a ten prehraji
                                                     // pokud repeat_delay < -1, prehravam porad dokola a prodlevou repeat_delay sekund

    thread:TSndThread;
    fmuted:boolean;

    function ResolveSndFilename(code:Integer):string;
    function GetHighestSound():Integer;   // vrati zvuk, ktery aktualne prehrat na zaklade bufferu - vybere ten s nejvyssi prioritou; vraci index v bufferu

    procedure SetMute(state:boolean);

  public
    constructor Create();
    destructor Destroy(); override;

    procedure Play(code:integer; loop:boolean = false);
    procedure DeleteSound(code:Integer);
    procedure DeleteAll();
    function IsPlaying(code:integer):boolean;

    property muted:boolean read fmuted write SetMute;

 end;

var
  SoundsPlay: TSoundsPlay;

implementation

uses GlobalConfig, fMain;

////////////////////////////////////////////////////////////////////////////////

constructor TSoundsPlay.Create();
var i:Integer;
begin
 inherited;

 thread := TSndThread.Create(true);
 thread.Suspended := false;

 for i := 0 to _SND_BUF_LEN-1 do
  Self.buffer[i].code := -1;
end;//ctor

destructor TSoundsPlay.Destroy();
begin
 thread.Terminate();
 FreeAndNil(thread);

 inherited;
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.Play(code:integer; loop:boolean = false);
var i, highest:integer;
 begin
  if (not loop) then
   begin
    // neopakujici se zvuky pustime hned
    if (not muted) then
      Self.thread.PriorityPlay(Self.ResolveSndFilename(code));
   end else begin
    // opakujici se zvuky pustime v smostatnem vlakne, kde hledime na prioritu
    for i := 0 to _SND_BUF_LEN-1 do
     if (Self.buffer[i].code < 0) then
      begin
       Self.buffer[i].code := code;
       break;
      end;

    if (Self.muted) then Exit();

    if (Self.thread.filename = '') then
     begin
      // no sounds playing
      Self.thread.filename := Self.ResolveSndFilename(code);
     end else begin
      // sound already playing
      highest := Self.GetHighestSound();
      if (Self.thread.filename <> Self.ResolveSndFilename(Self.buffer[highest].code)) then
        Self.thread.filename := Self.ResolveSndFilename(code);
     end;
   end;// else repeat_delay = -1
 end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.DeleteSound(code:Integer);
var i:Integer;
begin
 for i := 0 to _SND_BUF_LEN-1 do
  if (Self.buffer[i].code = code) then
   begin
    Self.buffer[i].code := -1;
    Break;
   end;

 if (Self.thread.filename = Self.ResolveSndFilename(code)) then
   Self.thread.filename := '';

 i := Self.GetHighestSound();
 if (i > -1) then
   Self.thread.filename := Self.ResolveSndFilename(Self.buffer[i].code);
end;//procedure

procedure TSoundsPlay.DeleteAll();
var i:Integer;
begin
 for i := 0 to _SND_BUF_LEN-1 do
  if (Self.buffer[i].code > -1) then
    Self.buffer[i].code := -1;

 if (Self.thread.filename <> '') then
   Self.thread.filename := '';
end;//procedure

////////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.ResolveSndFilename(code:Integer):string;
begin
 case (code) of
  _SND_TRAT_ZADOST  : Result := GlobConfig.data.sounds.sndTratSouhlas;
  _SND_POTVR_SEKV   : Result := GlobConfig.data.sounds.sndRizikovaFce;
  _SND_CHYBA        : Result := GlobConfig.data.sounds.sndChyba;
  _SND_PRETIZENI    : Result := GlobConfig.data.sounds.sndPretizeni;
  _SND_ZPRAVA       : Result := GlobConfig.data.sounds.sndPrichoziZprava;
  _SND_PRIVOLAVACKA : Result := GlobConfig.data.sounds.sndPrivolavacka;
  _SND_TIMEOUT      : Result := GlobConfig.data.sounds.sndTimeout;
 else
  Result := '';
 end;
end;//function

////////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.GetHighestSound():Integer;
var i, max, maxi:Integer;
begin
 max  := 0;
 maxi := -1;

 for i := 0 to _SND_BUF_LEN-1 do
  if (Self.buffer[i].code > max) then
   begin
    maxi := i;
    max  := Self.buffer[i].code;
   end;

 Result := maxi;
end;//fuctnion

////////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.SetMute(state:boolean);
var highest:Integer;
begin
 if ((not Self.fmuted) and (state) and (Self.thread.filename <> '')) then
   Self.thread.filename := '';

 if ((Self.muted) and (not state)) then
  begin
   highest := Self.GetHighestSound();
   if (highest > -1) then
     Self.thread.filename := Self.ResolveSndFilename(Self.buffer[highest].code);
  end;

 Self.fmuted := state;
end;

////////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.IsPlaying(code:integer):boolean;
var i:Integer;
begin
 for i := 0 to _SND_BUF_LEN-1 do
  if (Self.buffer[i].code = code) then
   Exit(true);
 Exit(false);
end;//function

////////////////////////////////////////////////////////////////////////////////

initialization
  SoundsPlay := TSoundsPlay.Create();
finalization
  FreeAndNil(SoundsPlay);

end.//unit
