unit SoundsThread;

// toto vlako je jen pro opakujici se zvuky

interface

uses
  Classes, mmsystem, sysutils;

type
  TFinishedEvent = procedure (Sender:TObject) of object;

  TSndThread = class(TThread)
  private

   ffilename:string;
   priority:string;
   changed:boolean;

   procedure SetFN(new:string);

  protected
   FinishedEvent: TFinishedEvent;

   procedure Execute; override;

  public

   property filename:string read ffilename write SetFN;
   procedure PriorityPlay(fn:string);

  end;

implementation

uses fMain;

procedure TSndThread.Execute;
 begin
   while (not Terminated) do
    begin
     if (Self.changed) then
      begin
       if (Self.priority <> '') then
        begin
         sndPlaySound(PChar(Self.priority), 0);
         Self.priority := '';
        end else begin
         if (Self.filename <> '') then
           sndPlaySound(PChar(Self.filename), SND_ASYNC or SND_LOOP)
         else
           sndPlaySound(nil, 0);

         Self.changed := false;
        end;
      end;

     Sleep(1);
    end;//while
 end;//procedure

procedure TSndThread.SetFN(new:string);
begin
 Self.ffilename := new;
 Self.changed := true;
end;

procedure TSndThread.PriorityPlay(fn:string);
begin
 Self.priority := fn;
 Self.changed := true;
end;

end.//unit
