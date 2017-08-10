unit ModelovyCas;

{
  Sprava modeloveho casu.
}

interface

uses Classes, SysUtils, IniFiles, IDContext, Graphics, ExtCtrls, DateUtils;

type

  TModCas = class
   private
    ftime:TTime;
    fnasobic:Integer;
    fstarted:boolean;
    timer:TTimer;
    last_call:TDateTime;

    procedure OnTimer(Sender:TObject);

   public
     constructor Create();
     destructor Destroy(); override;

     procedure ParseData(data:TStrings);

     procedure Show();
     procedure Reset();

     property time:TTime read ftime;
     property nasobic:Integer read fnasobic;
     property started:boolean read fstarted;
  end;//class TModCas

var
  ModCas:TModCas;

implementation

uses fMain;

////////////////////////////////////////////////////////////////////////////////

constructor TModCas.Create();
begin
 inherited Create();

 Self.timer          := TTimer.Create(nil);
 Self.timer.Enabled  := false;
 Self.timer.Interval := 200;
 Self.timer.OnTimer  := OnTimer;
end;//ctor

destructor TModCas.Destroy();
begin
 FreeAndNil(Self.timer);

 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

//  -;MOD-CAS;running;nasobic;cas;                  - oznameni o stavu modeloveho casu - aktualni modelovy cas a jestli bezi
procedure TModCas.ParseData(data:TStrings);
begin
 Self.fstarted      := (data[2] = '1');
 Self.timer.Enabled := Self.fstarted;
 Self.last_call     := Now;

 Self.fnasobic := StrToInt(data[3]);
 Self.ftime    := StrToTime(data[4]);

 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TModCas.OnTimer(Sender:TObject);
var diff:TTime;
begin
 // pocitani aktualniho modeloveho casu:
 diff := Now - Self.last_call;
 Self.ftime := Self.time + (diff*Self.nasobic);

 Self.last_call := now;
 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TModCas.Show();
begin
 if (Self.started) then
  begin
   F_Main.P_Time_modelovy.Font.Color := clBlack;
   F_Main.P_Zrychleni.Font.Color     := clBlack;
  end else begin
   F_Main.P_Time_modelovy.Font.Color := clRed;
   F_Main.P_Zrychleni.Font.Color     := clRed;
  end;

 F_Main.P_Zrychleni.Caption     := IntToStr(Self.nasobic)+'x';
 F_Main.P_Time_modelovy.Caption := FormatDateTime('hh:nn:ss', Self.ftime);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TModCas.Reset();
begin
 Self.ftime    := EncodeTime(0, 0, 0, 0);
 Self.fstarted := false;
 Self.fnasobic := 1;

 Self.timer.Enabled := false;

 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

initialization
 ModCas := TModCas.Create();

finalization
 FreeAndNil(ModCas);

end.//unit

