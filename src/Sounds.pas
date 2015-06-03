unit Sounds;

interface

uses SysUtils, SoundsThread, Classes, mmsystem;

// vyssi cislo zvuku ma vzdy vetsi prioritu na prehrani
const
  _SND_TRAT_ZADOST = 4;
  _SND_POTVR_SEKV  = 8;
  _SND_CHYBA       = 10;
  _SND_PRETIZENI   = 7;
  _SND_ZPRAVA      = 9;

  _SND_BUF_LEN     = 8;

type
 TSound = record
   code:Integer;
   repeat_delay:Integer;    // cekani po dokonceni zvuku - v ms
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

    procedure Play(code:integer; repeat_delay:Integer = -1);
    procedure DeleteSound(code:Integer);
    procedure DeleteAll();
    function IsPlaying(code:integer):boolean;

    property muted:boolean read fmuted write SetMute;

 end;

var
  SoundsPlay: TSoundsPlay;

implementation

uses GlobalConfig, Main;

////////////////////////////////////////////////////////////////////////////////

constructor TSoundsPlay.Create();
var i:Integer;
begin
 inherited Create();

 thread := TSndThread.Create(true);
 thread.code := -1;
 thread.Suspended := false;

 for i := 0 to _SND_BUF_LEN-1 do
  Self.buffer[i].code := -1;
end;//ctor

destructor TSoundsPlay.Destroy();
begin
 thread.Terminate();
 FreeAndNil(thread);

 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.Play(code:integer; repeat_delay:Integer = -1);
var i, highest:integer;
 begin
  if (repeat_delay = -1) then
   begin
    // neopakujici se zvuky pustime hned
    if (not muted) then
      sndPlaySound(PChar(Self.ResolveSndFilename(code)), SND_ASYNC);
   end else begin
    // opakujici se zvuky pustime v smostatnem vlakne, kde hledime na prioritu
    for i := 0 to _SND_BUF_LEN-1 do
     if (Self.buffer[i].code < 0) then
      begin
       Self.buffer[i].code         := code;
       Self.buffer[i].repeat_delay := repeat_delay;
       break;
      end;

    if (Self.muted) then Exit();

    if (Self.thread.code = -1) then
     begin
      // no sounds playing
      Self.thread.repeat_delay := repeat_delay;
      Self.thread.filename     := Self.ResolveSndFilename(code);
      Self.thread.code         := code;
     end else begin
      // sound already playing
      highest := Self.GetHighestSound();
      if (Self.thread.code <> Self.buffer[highest].code) then
       begin
        Self.thread.repeat_delay := repeat_delay;
        Self.thread.filename     := Self.ResolveSndFilename(code);
        Self.thread.code         := code;
       end;
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

 if (Self.thread.code = code) then
  Self.thread.code := -1;

 i := Self.GetHighestSound();
 if (i > -1) then
  begin
   Self.thread.filename     := Self.ResolveSndFilename(Self.buffer[i].code);
   Self.thread.repeat_delay := Self.buffer[i].repeat_delay;
   Self.thread.code         := Self.buffer[i].code;
  end;
end;//procedure

procedure TSoundsPlay.DeleteAll();
var i:Integer;
begin
 for i := 0 to _SND_BUF_LEN-1 do
  if (Self.buffer[i].code > -1) then
    Self.buffer[i].code := -1;

 if (Self.thread.code > -1) then
  Self.thread.code := -1;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.ResolveSndFilename(code:Integer):string;
begin
 case (code) of
  _SND_TRAT_ZADOST: Result := GlobConfig.data.sounds.sndTratSouhlas;
  _SND_POTVR_SEKV : Result := GlobConfig.data.sounds.sndRizikovaFce;
  _SND_CHYBA      : Result := GlobConfig.data.sounds.sndChyba;
  _SND_PRETIZENI  : Result := GlobConfig.data.sounds.sndPretizeni;
  _SND_ZPRAVA     : Result := GlobConfig.data.sounds.sndPrichoziZprava;
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
 if ((not Self.fmuted) and (state) and (Self.thread.code > -1)) then
   Self.thread.code := -1;

 if ((Self.muted) and (not state)) then
  begin
   highest := Self.GetHighestSound();
   if (highest > -1) then
    begin
     Self.thread.repeat_delay := Self.buffer[highest].repeat_delay;
     Self.thread.filename     := Self.ResolveSndFilename(Self.buffer[highest].code);
     Self.thread.code         := Self.buffer[highest].code;
    end;
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
