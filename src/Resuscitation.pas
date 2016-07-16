unit Resuscitation;

// Trida TResuscitation ma za ukol kontrolovat beh serveru.
//  Jakmile zjisti, ze server bezi, informuje o tom aplikaci a ta se k serveru pripoji.
//  Slouzi k automatickemu pripojovani k serveru.

interface

uses
  Classes, SysUtils, IdTCPClient, IdIOHandlerSocket;

type
  TResuscitation = class(TThread)
  private
    frunning:boolean;
    fOnActivate:TNotifyEvent;

  protected

    procedure Execute; override;
    procedure Activate();

  public
    server_ip:string;
    server_port:Word;

    constructor Create(CreateSuspended:boolean; activateCallback:TNotifyEvent = nil);

    property running:boolean read frunning;

    property OnActivate : TNotifyEvent read fOnActivate write fOnActivate;

  end;

implementation

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TResuscitation.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TResuscitation }

constructor TResuscitation.Create(CreateSuspended:boolean; activateCallback:TNotifyEvent = nil);
begin
 inherited Create(CreateSuspended);
 Self.fOnActivate := activateCallback;
 Self.frunning    := false;
end;

procedure TResuscitation.Activate();
begin
 if (Assigned(Self.fOnActivate)) then Self.fOnActivate(Self);
end;

procedure TResuscitation.Execute;
var IdTCPClient : TIdTCPClient;
    i:Integer;
begin
 IdTCPClient := TIdTCPClient.Create(nil);

 while (not Terminated) do
  begin
    try
      IdTCPClient.Host := Self.server_ip;
      IdTCPClient.Port := Self.server_port;
      IdTCPClient.Connect();

      Self.frunning := true;
      Self.Terminate();
      if (Assigned(Self.fOnActivate)) then Synchronize(Activate);
    except
      Self.frunning := false;
    end;

   for i := 0 to 200 do
    begin
     sleep(1);
     if (Terminated) then break;     
    end;
  end;//while

  IdTCPClient.Free();
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
