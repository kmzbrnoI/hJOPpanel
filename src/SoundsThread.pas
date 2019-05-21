unit SoundsThread;

{
  Vlakno resici prehravani dlouhotrvajicich zvuku.
  Toto vlako je jen pro opakujici se zvuky.
  Jednorazove zvuky se pousti z hlavniho vlakna (asynchronne, viz Sounds.pas).
}

interface

uses
  Classes, mmsystem, sysutils;

type
  TFinishedEvent = procedure (Sender:TObject) of object;
  PBytes = ^TBytes;

  TSndThread = class(TThread)
  private

   fdata:PBytes;
   priority:PBytes;
   changed:boolean;

   procedure SetData(new:PBytes);

  protected
   FinishedEvent: TFinishedEvent;

   procedure Execute; override;

  public

   property data:PBytes read fdata write SetData;
   procedure PriorityPlay(data: PBytes);

  end;

implementation

uses fMain;

procedure TSndThread.Execute;
 begin
   while (not Terminated) do
    begin
     if (Self.changed) then
      begin
       if (Self.priority <> nil) then
        begin
         sndPlaySound(PChar(Self.priority), SND_MEMORY);
         Self.priority := nil;
        end else begin
         if (Self.data <> nil) then
           sndPlaySound(PChar(Self.data), SND_ASYNC or SND_LOOP OR SND_MEMORY)
         else
           sndPlaySound(nil, 0);

         Self.changed := false;
        end;
      end;

     Sleep(1);
    end;//while
 end;//procedure

procedure TSndThread.SetData(new: PBytes);
begin
 Self.fdata := new;
 Self.changed := true;
end;

procedure TSndThread.PriorityPlay(data: PBytes);
begin
 Self.priority := data;
 Self.changed := true;
end;

end.//unit
