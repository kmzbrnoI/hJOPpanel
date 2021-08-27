unit ModelovyCas;

{
  Model time management.
}

interface

uses Classes, SysUtils, Graphics, ExtCtrls;

type

  TModelTime = class
  private
    ftime: TTime;
    fspeed: Real;
    fstarted: boolean;
    fused: boolean;
    timer: TTimer;
    last_call: TDateTime;

    procedure OnTimer(Sender: TObject);

    function GetStrSpeed(): string;

  public
    constructor Create();
    destructor Destroy(); override;

    procedure ParseData(data: TStrings);

    procedure Reset();

    property time: TTime read ftime;
    property speed: Real read fspeed;
    property used: boolean read fused;
    property started: boolean read fstarted;
    property strSpeed: string read GetStrSpeed;
  end; // class TModCas

var
  ModelTime: TModelTime;

implementation

uses fMain;

/// /////////////////////////////////////////////////////////////////////////////

constructor TModelTime.Create();
begin
  inherited Create();

  Self.timer := TTimer.Create(nil);
  Self.timer.Enabled := false;
  Self.timer.Interval := 200;
  Self.timer.OnTimer := OnTimer;
end;

destructor TModelTime.Destroy();
begin
  FreeAndNil(Self.timer);
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TModelTime.ParseData(data: TStrings);
begin
  Self.fstarted := (data[2] = '1');
  Self.timer.Enabled := Self.fstarted;
  Self.last_call := Now;

  Self.fspeed := StrToFloat(data[3]);
  Self.ftime := StrToTime(data[4]);

  if (data.Count >= 6) then
    Self.fused := (data[5] = '1')
  else
    Self.fused := true;

  F_Main.OnModTimeChanged();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TModelTime.OnTimer(Sender: TObject);
var diff: TTime;
begin
  // calculate current model time:
  diff := Now - Self.last_call;
  Self.ftime := Self.time + (diff * Self.speed);

  Self.last_call := Now;
  F_Main.OnModTimeChanged();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TModelTime.Reset();
begin
  Self.ftime := EncodeTime(0, 0, 0, 0);
  Self.fstarted := false;
  Self.fspeed := 1;
  Self.fused := false;

  Self.timer.Enabled := false;

  F_Main.OnModTimeChanged();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TModelTime.GetStrSpeed(): string;
begin
  Result := FloatToStrF(Self.speed, ffGeneral, 1, 1);
end;

/// /////////////////////////////////////////////////////////////////////////////

initialization

ModelTime := TModelTime.Create();

finalization

FreeAndNil(ModelTime);

end.// unit
