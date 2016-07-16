unit uLIClient;

interface

uses SysUtils, IdTCPClient, ListeningThread, IdTCPConnection, IdGlobal,
     Classes, StrUtils, RPConst;

const
  _BRIDGE_DEFAULT_PORT = 5733;                                                  // default port, na ktere bezi bridge server

type
  TBridgeClient = class
   private const
    _PROTOCOL_VERSION = '1.0';

   private
    rthread: TReadingThread;
    tcpClient: TIdTCPClient;
    parsed: TStrings;
    data:string;
    control_disconnect:boolean;       // je true, pokud disconnect plyne ode me

     procedure OnTcpClientConnected(Sender: TObject);
     procedure OnTcpClientDisconnected(Sender: TObject);
     procedure DataReceived(const data: string);
     procedure Timeout();   // timeout from socket = broken pipe

     // data se predavaji v Self.Parsed
     procedure Parse();

     function GetOpened():boolean;

   public

     constructor Create();
     destructor Destroy(); override;

     function Connect(host:string; port:Word):Integer;
     function Disconnect():Integer;

     procedure SendLn(str:string);

     property opened : boolean read GetOpened;
  end;//TPanelTCPClient

var
  BridgeClient : TBridgeClient;

implementation

{
 Jak funguje komunikace ze strany serveru:
  * Klient se pripoji, posila data, server posila data.
  * Neni vyzadovan hanshake.
  * Server neodpojuje klienty pokud to neni nutne.

}
{
 Specifikace komunikacniho protkolu:
  jedna se o retezec, ve kterem jsou jednotliva data oddelena strednikem.

 PRIKAZY:

////////////////////////////////////////////////////////////////////////////////
/////////////////////////// KLIENT -> SERVER ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

LOGIN;server;port;username;password      - pozadavek k pripojeni k serveru a autorizaci regulatoru
LOKO;slot;[addr;token];[addr;token];...  - pozadavek k umisteni lokomotiv do slotu \slot
SLOTS?                                   - pozadavek na vraceni seznamu slotu a jejich obsahu

////////////////////////////////////////////////////////////////////////////////
/////////////////////////// SERVER -> KLIENT ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

LOKO;ok                                  - loko uspesne prevzato
LOKO;err;err_code;error message          - loko se nepodarilo prevzit
SLOTS;[F/-/#];[F/-/#];...                  - sloty, ktere ma daemon k dispozici
                                           '-' je prazdny slot
                                           '#' je nefunkcni slot
                                           'F' je plny slot
                                           pocet slotu je variabilni

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////

constructor TBridgeClient.Create();
begin
 inherited Create();

 Self.parsed := TStringList.Create;

 Self.tcpClient := TIdTCPClient.Create(nil);
 Self.tcpClient.OnConnected := Self.OnTcpClientConnected;
 Self.tcpClient.OnDisconnected := Self.OnTcpClientDisconnected;
 Self.tcpClient.ConnectTimeout := 1500;
end;//ctor

destructor TBridgeClient.Destroy();
begin
 if (Assigned(Self.tcpClient)) then
   FreeAndNil(Self.tcpClient);

 if (Assigned(Self.parsed)) then
   FreeAndNil(Self.parsed);

 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

function TBridgeClient.Connect(host:string; port:Word):Integer;
begin
 try
   if (Self.tcpClient.Connected) then Exit(1);
 except
   try
     Self.tcpClient.Disconnect(False);
   except
   end;
   if (Self.tcpClient.IOHandler <> nil) then Self.tcpClient.IOHandler.InputBuffer.Clear;
 end;

 Self.tcpClient.Host := host;
 Self.tcpClient.Port := port;

 try
   Self.tcpClient.Connect();
 except

 end;

 Self.tcpClient.IOHandler.DefStringEncoding := TIdEncoding.enUTF8;
 Self.control_disconnect := false;

 Result := 0;
end;//function

////////////////////////////////////////////////////////////////////////////////

function TBridgeClient.Disconnect():Integer;
begin
 if (not Self.tcpClient.Connected) then Exit(1);

 Self.control_disconnect := true;
 if Assigned(Self.rthread) then Self.rthread.Terminate;
 try
   Self.tcpClient.Disconnect();
 finally
   if Assigned(Self.rthread) then
   begin
     Self.rthread.WaitFor;
     FreeAndNil(Self.rthread);
   end;
 end;

 Result := 0;
end;//function

////////////////////////////////////////////////////////////////////////////////
// eventy z IdTCPClient

procedure TBridgeClient.OnTcpClientConnected(Sender: TObject);
begin
 try
  Self.rthread := TReadingThread.Create((Sender as TIdTCPClient));
  Self.rthread.OnData := DataReceived;
  Self.rthread.OnTimeout := Timeout;
  Self.rthread.Resume;
 except
  (Sender as TIdTCPClient).Disconnect;
  raise;
 end;
end;//procedure

procedure TBridgeClient.OnTcpClientDisconnected(Sender: TObject);
begin
 if Assigned(Self.rthread) then Self.rthread.Terminate;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// parsing prijatych dat
procedure TBridgeClient.DataReceived(const data: string);
begin
 Self.parsed.Clear();
 ExtractStringsEx([';'], [#13, #10], data, Self.parsed);

 Self.data := data;

 if (parsed.Count < 0) then Exit();
 parsed[0] := UpperCase(parsed[0]);

 try
   Self.Parse()
 except

 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.Timeout();
begin
 Self.OnTcpClientDisconnected(Self);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.Parse();
begin
 if (parsed[0] = 'SLOTS') then begin

 end else if (parsed[0] = 'LOKO') then begin

 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.SendLn(str:string);
begin
 if (not Self.tcpClient.Connected) then Exit;

 try
   Self.tcpClient.Socket.WriteLn(str);
 except
   Self.OnTcpClientDisconnected(Self);
 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

function TBridgeClient.GetOpened():boolean;
begin
 Result := Self.tcpClient.Connected;
end;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

initialization
 BridgeClient := TBridgeClient.Create;

finalization
 FreeAndNil(BridgeClient);

end.//unit
