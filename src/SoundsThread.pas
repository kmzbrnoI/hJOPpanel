unit SoundsThread;

// toto vlako je jen pro opakujici se zvuky

interface

uses
  Classes, mmsystem, sysutils;

type
  TFinishedEvent = procedure (Sender:TObject) of object;

  TSndThread = class(TThread)
  private

  protected
   FinishedEvent: TFinishedEvent;

   procedure Execute; override;

  public
    code:Integer;
    filename:string;
    repeat_delay:Integer;
    next:TDateTime;
  end;

implementation

uses fMain;

procedure TSndThread.Execute;
 begin
   while (not Terminated) do
    begin
     if (Self.code > -1) then
      begin
       PlaySound(PChar(Self.filename), 0, SND_ASYNC);

       next := Now + EncodeTime(0, 0, Self.repeat_delay div 1000, Self.repeat_delay mod 1000);
       while ((Now < next) and (not Terminated)) do
         Sleep(1);
      end else
       Sleep(10);
    end;//while
 end;//procedure

end.//unit
