unit Sounds;

{
  Technologie prehravani zvuku.
}

interface

uses SysUtils, SoundsThread, Classes, Generics.Collections;

// vyssi cislo zvuku ma vzdy vetsi prioritu na prehrani
const
  _SND_TRAT_ZADOST = 4;
  _SND_PRIVOLAVACKA = 5;
  _SND_TIMEOUT = 6;
  _SND_PRETIZENI = 7;
  _SND_POTVR_SEKV = 8;
  _SND_ZPRAVA = 9;
  _SND_CHYBA = 10;
  _SND_STAVENI_VYZVA = 11;
  _SND_NENI_JC = 12;

  _SND_BUF_LEN = 8;

type
  TSound = record
    code: Integer;
  end;

  TSoundsPlay = class
  private
    buffer: array [0 .. _SND_BUF_LEN - 1] of TSound; // z bufferu vzdy vyberu zvuk z nejvyssim 'code' a ten prehraji
    // pokud repeat_delay < -1, prehravam porad dokola a prodlevou repeat_delay sekund
    memorySounds: TDictionary<string, PBytes>; // mapping filename: data (preloaded in memory)

    thread: TSndThread;
    fmuted: boolean;

    function ResolveSndFilename(code: Integer): string;
    function GetHighestSound(): Integer;
    // vrati zvuk, ktery aktualne prehrat na zaklade bufferu - vybere ten s nejvyssi prioritou; vraci index v bufferu

    procedure SetMute(state: boolean);
    procedure PreloadSound(const filename: string);

  public
    constructor Create();
    destructor Destroy(); override;

    procedure Play(code: Integer; loop: boolean = false);
    procedure DeleteSound(code: Integer);
    procedure DeleteAll();
    function IsPlaying(code: Integer): boolean;
    function LoadFile(const filename: string): PBytes;
    procedure PreloadSounds();

    property muted: boolean read fmuted write SetMute;

  end;

var
  SoundsPlay: TSoundsPlay;

implementation

uses GlobalConfig;

/// /////////////////////////////////////////////////////////////////////////////

constructor TSoundsPlay.Create();
var i: Integer;
begin
  inherited;

  Self.memorySounds := TDictionary<string, PBytes>.Create();

  thread := TSndThread.Create(true);
  thread.Suspended := false;

  for i := 0 to _SND_BUF_LEN - 1 do
    Self.buffer[i].code := -1;
end; // ctor

destructor TSoundsPlay.Destroy();
var sound: PBytes;
begin
  thread.Terminate();
  FreeAndNil(thread);

  for sound in Self.memorySounds.Values do
    FreeMem(sound);
  Self.memorySounds.Free();

  inherited;
end; // dtor

/// /////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.Play(code: Integer; loop: boolean = false);
var i, highest: Integer;
  filename: string;
begin
  filename := Self.ResolveSndFilename(code);
  if (filename = '') then
    Exit();

  try
    if (not Self.memorySounds.ContainsKey(filename)) then
      Self.LoadFile(Self.ResolveSndFilename(code));
  except
    // Ignore load exceptions
    Exit();
  end;

  if (not loop) then
  begin
    // neopakujici se zvuky pustime hned
    if (not muted) then
      Self.thread.PriorityPlay(Self.memorySounds[filename]);
  end else begin
    // opakujici se zvuky pustime v samostatnem vlakne, kde hledime na prioritu
    for i := 0 to _SND_BUF_LEN - 1 do
      if (Self.buffer[i].code < 0) then
      begin
        Self.buffer[i].code := code;
        break;
      end;

    if (Self.muted) then
      Exit();

    if (Self.thread.data = nil) then
    begin
      // no sounds playing
      Self.thread.data := Self.memorySounds[filename];
    end else begin
      // sound already playing
      highest := Self.GetHighestSound();
      if (Self.thread.data <> Self.memorySounds[Self.ResolveSndFilename(Self.buffer[highest].code)]) then
        Self.thread.data := Self.memorySounds[Self.ResolveSndFilename(code)];
    end;
  end; // else repeat_delay = -1
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.DeleteSound(code: Integer);
var i: Integer;
begin
  for i := 0 to _SND_BUF_LEN - 1 do
    if (Self.buffer[i].code = code) then
    begin
      Self.buffer[i].code := -1;
      break;
    end;

  if ((Self.memorySounds.ContainsKey(Self.ResolveSndFilename(code))) and
    (Self.thread.data = Self.memorySounds[Self.ResolveSndFilename(code)])) then
    Self.thread.data := nil;

  i := Self.GetHighestSound();
  if ((i > -1) and (Self.memorySounds.ContainsKey(Self.ResolveSndFilename(Self.buffer[i].code)))) then
    Self.thread.data := Self.memorySounds[Self.ResolveSndFilename(Self.buffer[i].code)];
end;

procedure TSoundsPlay.DeleteAll();
var i: Integer;
begin
  for i := 0 to _SND_BUF_LEN - 1 do
    if (Self.buffer[i].code > -1) then
      Self.buffer[i].code := -1;

  if (Self.thread.data <> nil) then
    Self.thread.data := nil;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.ResolveSndFilename(code: Integer): string;
begin
  case (code) of
    _SND_TRAT_ZADOST:
      Result := GlobConfig.data.Sounds.sndTratSouhlas;
    _SND_POTVR_SEKV:
      Result := GlobConfig.data.Sounds.sndRizikovaFce;
    _SND_CHYBA:
      Result := GlobConfig.data.Sounds.sndChyba;
    _SND_PRETIZENI:
      Result := GlobConfig.data.Sounds.sndPretizeni;
    _SND_ZPRAVA:
      Result := GlobConfig.data.Sounds.sndPrichoziZprava;
    _SND_PRIVOLAVACKA:
      Result := GlobConfig.data.Sounds.sndPrivolavacka;
    _SND_TIMEOUT:
      Result := GlobConfig.data.Sounds.sndTimeout;
    _SND_STAVENI_VYZVA:
      Result := GlobConfig.data.Sounds.sndStaveniVyzva;
    _SND_NENI_JC:
      Result := GlobConfig.data.Sounds.sndNeniJC;
  else
    Result := '';
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.GetHighestSound(): Integer;
var i, max, maxi: Integer;
begin
  max := 0;
  maxi := -1;

  for i := 0 to _SND_BUF_LEN - 1 do
    if (Self.buffer[i].code > max) then
    begin
      maxi := i;
      max := Self.buffer[i].code;
    end;

  Result := maxi;
end; // fuctnion

/// /////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.SetMute(state: boolean);
var highest: Integer;
begin
  if ((not Self.fmuted) and (state) and (Self.thread.data <> nil)) then
    Self.thread.data := nil;

  if ((Self.muted) and (not state)) then
  begin
    highest := Self.GetHighestSound();
    if (highest > -1) then
      Self.thread.data := Self.memorySounds[Self.ResolveSndFilename(Self.buffer[highest].code)];
  end;

  Self.fmuted := state;
end;

/// /////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.IsPlaying(code: Integer): boolean;
var i: Integer;
begin
  for i := 0 to _SND_BUF_LEN - 1 do
    if (Self.buffer[i].code = code) then
      Exit(true);
  Exit(false);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TSoundsPlay.LoadFile(const filename: string): PBytes;
var data: PBytes;
  stream: TFileStream;
begin
  stream := TFileStream.Create(filename, fmOpenRead);
  try
    GetMem(data, stream.Size);
    SetLength(data^, stream.Size);
    stream.Read(data^, stream.Size);

    if (Self.memorySounds.ContainsKey(filename)) then
      FreeMem(Self.memorySounds[filename]);
    Self.memorySounds.AddOrSetValue(filename, data);

    Result := data;
  finally
    FreeAndNil(stream);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TSoundsPlay.PreloadSounds();
begin
  Self.PreloadSound(GlobConfig.data.Sounds.sndTratSouhlas);
  Self.PreloadSound(GlobConfig.data.Sounds.sndRizikovaFce);
  Self.PreloadSound(GlobConfig.data.Sounds.sndChyba);
  Self.PreloadSound(GlobConfig.data.Sounds.sndPretizeni);
  Self.PreloadSound(GlobConfig.data.Sounds.sndPrichoziZprava);
  Self.PreloadSound(GlobConfig.data.Sounds.sndPrivolavacka);
  Self.PreloadSound(GlobConfig.data.Sounds.sndTimeout);
  Self.PreloadSound(GlobConfig.data.Sounds.sndStaveniVyzva);
  Self.PreloadSound(GlobConfig.data.Sounds.sndNeniJC);
end;

procedure TSoundsPlay.PreloadSound(const filename: string);
begin
  if (filename = '') then
    Exit();

  try
    Self.LoadFile(filename);
  except
    // Ignore load exceptions
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

SoundsPlay := TSoundsPlay.Create();

finalization

FreeAndNil(SoundsPlay);

end.// unit
