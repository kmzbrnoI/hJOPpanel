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

  protected

    procedure Execute; override;

  public
    server_ip:string;
    server_port:Word;

    property running:boolean read frunning;

  end;

var
  Resusct : TResuscitation;

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

procedure TResuscitation.Execute;
var IdTCPClient : TIdTCPClient;
//    TmpIdIOHandlerSocket : TIdIOHandlerSocket;
    i:Integer;
begin
 Self.frunning := false;

 IdTCPClient := TIdTCPClient.Create(nil);
// TmpIdIOHandlerSocket := TIdIOHandlerSocket.Create;
// TmpIdIOHandlerSocket.ConnectTimeout := 200;
// IdTCPClient.IOHandler := TmpIdIOHandlerSocket;

 while (not Terminated) do
  begin
    try
      IdTCPClient.Host := Self.server_ip;
      IdTCPClient.Port := Self.server_port;
      IdTCPClient.Connect();

      Self.frunning := true;
      Self.Terminate();
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

initialization

finalization
  if (Assigned(Resusct)) then Resusct.Free();

end.//unit
