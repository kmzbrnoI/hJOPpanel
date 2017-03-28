unit uLIClient;

interface

uses SysUtils, IdTCPClient, ListeningThread, IdTCPConnection, IdGlobal,
     Classes, StrUtils, RPConst, Resuscitation, Windows, HVDb, Forms;

const
  _BRIDGE_DEFAULT_PORT = 5733;                                                  // default port, na ktere bezi bridge server
  _BRIDGE_DEFAULT_SERVER = '127.0.0.1';

type
  TuLIAuthStatus = (no, yes, cannot);
  TuLISlotStatus = (ssFull, ssAvailable, ssNotAvailable);

  TBridgeClient = class
   public const
     _SLOTS_CNT = 6;

   private
    rthread: TReadingThread;
    tcpClient: TIdTCPClient;
    parsed: TStrings;
    data:string;
    control_disconnect:boolean;       // je true, pokud disconnect plyne ode me
    resusc_destroy:boolean;
    resusc:TResuscitation;
    fAuthStatus:TuLIAuthStatus;
    fAuthStatusChanged:TNotifyEvent;

     function Connect(host:string; port:Word):Integer;
     function Disconnect():Integer;

     procedure OnTcpClientConnected(Sender: TObject);
     procedure OnTcpClientDisconnected(Sender: TObject);
     procedure DataReceived(const data: string);
     procedure Timeout();   // timeout from socket = broken pipe
     procedure ConnectionResusced(Sender:TObject);

     // data se predavaji v Self.Parsed
     procedure Parse();

     function GetOpened():boolean;

     function GetEnabled():boolean;
     procedure SetEnabled(enabled:boolean);
     procedure DestroyResusc();
     function GetActiveSlotsCount():Integer;

   public

    toLogin : record
      server, username, password: string;
      port: Word;
    end;

    sloty:array [1.._SLOTS_CNT] of TuLISlotStatus;

     constructor Create();
     destructor Destroy(); override;

     procedure SendLn(str:string);
     procedure Update();
     procedure Auth();
     procedure LoksToSlot(HVs:THVDb; slot:Integer; ruc:boolean);
     procedure GetSlotsStatus();

     property opened : boolean read GetOpened;
     property authStatus : TuLIAuthStatus read fAuthStatus;
     property enabled : boolean read GetEnabled write SetEnabled;
     property activeSlotsCount : Integer read GetActiveSlotsCount;

     property OnAuthStatushanged: TNotifyEvent read fAuthStatusChanged write fAuthStatusChanged;
  end;//TPanelTCPClient

var
  BridgeClient : TBridgeClient;

implementation

uses fAuth, fRegReq, TCPClientPanel, fSprToSlot, fMain;

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

LOGIN;server;port;username;password         - pozadavek k pripojeni k serveru a autorizaci regulatoru
LOKO;slot;[addr;token];[addr;token];...     - pozadavek k umisteni lokomotiv do slotu \slot
LOKO-RUC;slot;[addr;token];[addr;token];... - pozadavek k umisteni lokomotiv do slotu \slot a autorizaci do totalniho rizeni
SLOTS?                                      - pozadavek na vraceni seznamu slotu a jejich obsahu
AUTH?                                       - pozadavek na vraceni stavu autorizace vuci hJOPserveru

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
AUTH;[yes/no/cannot]                     - jestli je uLI-daemon autorizovan vuci hJOPserveru

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////

constructor TBridgeClient.Create();
var i:Integer;
begin
 inherited;

 Self.fAuthStatus := TuLIAuthStatus.cannot;
 Self.fAuthStatusChanged := nil;
 Self.parsed := TStringList.Create;

 for i := 1 to _SLOTS_CNT do Self.sloty[i] := ssNotAvailable;   

 Self.tcpClient := TIdTCPClient.Create(nil);
 Self.tcpClient.OnConnected := Self.OnTcpClientConnected;
 Self.tcpClient.OnDisconnected := Self.OnTcpClientDisconnected;
 Self.tcpClient.ConnectTimeout := 1500;
end;//ctor

destructor TBridgeClient.Destroy();
begin
 try
   if (Self.tcpClient.Connected) then
     Self.tcpClient.Disconnect();
 except

 end;

 Self.DestroyResusc();

 if (Assigned(Self.tcpClient)) then
   FreeAndNil(Self.tcpClient);

 if (Assigned(Self.parsed)) then
   FreeAndNil(Self.parsed);

 inherited;
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
 try
   if (not Self.tcpClient.Connected) then Exit(1);
 except

 end;

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

  Self.SendLn('AUTH?');
  Self.SendLn('SLOTS?');
 except
  (Sender as TIdTCPClient).Disconnect;
  raise;
 end;
end;//procedure

procedure TBridgeClient.OnTcpClientDisconnected(Sender: TObject);
begin
 if Assigned(Self.rthread) then Self.rthread.Terminate;

 Self.fAuthStatus := TuLIAuthStatus.cannot;

 if ((Assigned(F_Auth)) and ((F_Auth.Showing) or (F_Auth.listening))) then F_Auth.UpdateULIcheckbox();
 if (Assigned(PanelTCPClient)) then
   PanelTCPClient.SendLn('-;MAUS;0');

 // resuscitace spojeni se serverem
 if (not Self.control_disconnect) then
  begin
   Self.resusc := TResuscitation.Create(true, Self.ConnectionResusced);
   Self.resusc.server_ip   := _BRIDGE_DEFAULT_SERVER;
   Self.resusc.server_port := _BRIDGE_DEFAULT_PORT;
   Self.resusc.Resume();
  end;

 if (Assigned(Self.OnAuthStatushanged)) then Self.OnAuthStatushanged(Self);
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
var i:Integer;
begin
 if (parsed[0] = 'SLOTS') then begin
   for i := 1 to _SLOTS_CNT do
    begin
     if (i < parsed.Count) then
      begin
       case (parsed[i][1]) of
        'F' : Self.sloty[i] := ssFull;
        '-' : Self.sloty[i] := ssAvailable;
        '#' : Self.sloty[i] := ssNotAvailable;
       end;
      end else begin
       Self.sloty[i] := ssNotAvailable;
      end;
    end;

   if (F_RegReq.Showing) then F_RegReq.RepaintSlots();
   if (F_SprToSlot.Showing) then F_SprToSlot.RepaintSlots();

 end else if (parsed[0] = 'AUTH') then begin
   if (parsed[1] = 'no') then Self.fAuthStatus := tuLiAuthStatus.no
   else if (parsed[1] = 'yes') then Self.fAuthStatus := tuLiAuthStatus.yes
   else if (parsed[1] = 'cannot') then Self.fAuthStatus := tuLiAuthStatus.cannot;

   if ((Assigned(F_Auth)) and ((F_Auth.Showing) or (F_Auth.listening))) then F_Auth.UpdateULIcheckbox();
   PanelTCPClient.SendLn('-;MAUS;'+IntToStr(Integer(Self.fAuthStatus = tuLiAuthStatus.yes)));

   if (Assigned(Self.OnAuthStatushanged)) then Self.OnAuthStatushanged(Self);

   if ((Self.authStatus = tuLiAuthStatus.no) and (Self.toLogin.server <> '') and
       (Self.toLogin.username <> '') and (Self.toLogin.password <> '')) then
     Self.Auth();

 end else if (parsed[0] = 'LOKO') then begin
   if (parsed[1] = 'ok') then
     asm nop; end
     // TODO
   else if (parsed[1] = 'err') then begin
     if (StrToInt(parsed[2]) <= 6) then
       Application.MessageBox(PChar(parsed[3]), 'uLI-daemon', MB_OK OR MB_ICONWARNING);
   end;
 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.SendLn(str:string);
begin
 try
   if (not Self.tcpClient.Connected) then Exit;
 except

 end;

 try
   Self.tcpClient.Socket.WriteLn(str);
 except
   Self.OnTcpClientDisconnected(Self);
 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

function TBridgeClient.GetOpened():boolean;
begin
 try
   Result := Self.tcpClient.Connected;
 except
   Result := false;
 end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.Update();
begin
 if (Self.resusc_destroy) then
  begin
   Self.resusc_destroy := false;
   Self.DestroyResusc();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.ConnectionResusced(Sender:TObject);
begin
 Self.Connect(_BRIDGE_DEFAULT_SERVER, _BRIDGE_DEFAULT_PORT);
 Self.resusc_destroy := true;
end;

////////////////////////////////////////////////////////////////////////////////

function TBridgeClient.GetEnabled():boolean;
begin
 Result := (Assigned(Self.resusc) or (Self.opened));
end;

procedure TBridgeClient.SetEnabled(enabled:boolean);
begin
 if (enabled) then
  begin
   // zapnout resusc
   Self.resusc_destroy := false;
   if (not Assigned(Self.resusc)) then
    begin
     Self.resusc := TResuscitation.Create(true, Self.ConnectionResusced);
     Self.resusc.server_ip   := _BRIDGE_DEFAULT_SERVER;
     Self.resusc.server_port := _BRIDGE_DEFAULT_PORT;
     Self.resusc.Resume();
    end;
  end else begin
    if (Self.opened) then Self.Disconnect();
    if (Assigned(Self.resusc)) then Self.DestroyResusc();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.DestroyResusc();
begin
 // Znicime resuscitacni vlakno (vlakno obnovujici spojeni).
 if (Assigned(Self.resusc)) then
  begin
   try
     TerminateThread(Self.resusc.Handle, 0);
   finally
     if Assigned(Self.resusc) then
     begin
       Resusc.WaitFor;
       FreeAndNil(Self.resusc);
     end;
   end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.Auth();
begin
 Self.SendLn('LOGIN;{'+Self.toLogin.server+'};'+IntToStr(Self.toLogin.port)+';{'+
             Self.toLogin.username+'};{'+Self.toLogin.password+'}');
 Self.toLogin.password := '';
end;

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.LoksToSlot(HVs:THVDb; slot:Integer; ruc:boolean);
var str:string;
    i:Integer;
begin
 str := '';
 for i := 0 to HVs.count-1 do
   str := str + '{' + IntToStr(HVs.HVs[i].Adresa) + ';' + HVs.HVs[i].token + '};';

 if (ruc) then
   Self.SendLn('LOKO-RUC;'+IntToStr(slot)+';'+str)
 else
   Self.SendLn('LOKO;'+IntToStr(slot)+';'+str);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TBridgeClient.GetSlotsStatus();
begin
 Self.SendLn('SLOTS?');
end;

////////////////////////////////////////////////////////////////////////////////

function TBridgeClient.GetActiveSlotsCount():Integer;
var i:Integer;
begin
 Result := 0;
 for i := 1 to _SLOTS_CNT do
   if ((Self.sloty[i] = ssAvailable) or (Self.sloty[i] = ssFull)) then Inc(Result);
end;

////////////////////////////////////////////////////////////////////////////////

initialization
 BridgeClient := TBridgeClient.Create;

finalization
 FreeAndNil(BridgeClient);

end.//unit
