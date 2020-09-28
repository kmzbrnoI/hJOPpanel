unit TCPClientPanel;

{
  TCP klient resici komunikaci s hJOPserverem.

  Kompletni specifikace komunikacnho protkolu je popsana na
  https://github.com/kmzbrnoI/hJOPserver/wiki/panelServer.
}

interface

uses SysUtils, IdTCPClient, ListeningThread, IdTCPConnection, IdGlobal, ExtCtrls,
     Classes, StrUtils, RPConst, Graphics, Windows, fPotvrSekv, Forms, Controls,
     Resuscitation, PanelOR;

const
  _DEFAULT_PORT = 5896;
  _PING_TIMER_PERIOD_MS = 5000;

  // tady jsou vyjmenovane vsechny verze protokolu k pripojeni k serveru, ktere klient podporuje
  protocol_version_accept : array[0..1] of string =
    (
      '1.0', '1.1'
    );

type
  TPanelConnectionStatus = (closed, opening, handshake, opened);

  TPanelTCPClient = class
   private const
    _PROTOCOL_VERSION_CLIENT = '1.1';

   private
    rthread: TReadingThread;
    tcpClient: TIdTCPClient;
    fstatus : TPanelConnectionStatus;
    parsed: TStrings;
    data:string;
    control_disconnect:boolean;       // je true, pokud disconnect plyne ode me
    recusc_destroy:boolean;
    pingTimer:TTimer;
    mServerVersion:Integer;

     procedure OnTcpClientConnected(Sender: TObject);
     procedure OnTcpClientDisconnected(Sender: TObject);
     procedure DataReceived(const data: string);
     procedure DataErrorGlobalHandle();
     procedure DataError();   // timeout from socket = broken pipe
     procedure DataTimeout();

     // data se predavaji v Self.Parsed
     procedure ParseGlobal();
     procedure ParseOR();
     procedure ParseORChange();

     procedure OsvListParse(oblr:string; data:string);

     procedure ConnetionResusced(Sender:TObject);
     procedure SendPing(Sedner:TObject);
     function GetServerVersionStr():string;

   public

    resusct : TResuscitation;
    openned_by_ipc: boolean;

     constructor Create();
     destructor Destroy(); override;

     function StrToColor(str:string):TColor; inline;

     function Connect(host:string; port:Word):Integer;
     function Disconnect():Integer;

     procedure SendLn(str:string);

     procedure Update();

     // udalosti z panelu:
      procedure PanelAuthorise(Sender:string; rights:TORControlRights; username,password:string);
      procedure PanelFirstGet(Sender:string);
      procedure PanelClick(Sender:string; Button:TPanelButton; blokid:Integer = -1; params:string = '');
      procedure PanelMenuClick(item_hint:string; item_index:Integer);
      procedure PanelDkMenuClick(Sender:string; rootItem: string; subItem: string = '');
      procedure PanelSetStitVyl(typ:Integer; stitvyl:string);
      procedure PanelPotvrSekv(Sender: TObject);
      procedure PanelNUZ(Sender:string);
      procedure PanelNUZCancel(Sender:string);
      procedure PanelSprChange(Sender:string; msg:string);
      procedure PanelLokMove(Sender:string; addr:Word; or_id:string);
      procedure PanelLokList(Sender:string);
      procedure PanelSetOsv(Sender:string; code:string; state:Integer);
      procedure PanelUpdateOsv(Sender:string);

      procedure PanelHVAdd(Sender:string; data:string);
      procedure PanelHVRemove(Sender:string; addr:Word);
      procedure PanelHVEdit(Sender:string; data:string);

      procedure PanelMessage(senderid:string; recepientid:string; msg:string);

      function PanelButtonToString(button:TPanelButton):string;
      function VersionToInt(version:string):Integer;
      function VersionToString(version:Integer):string;
      function IsServerVersionAtLeast(version:string):Boolean;

      property status:TPanelConnectionStatus read fstatus;
      property serverVersionStr:string read GetServerVersionStr;
      property serverVersionInt:Integer read mServerVersion;
  end;//TPanelTCPClient

var
  PanelTCPClient : TPanelTCPClient;

implementation

uses Panel, fMain, fStitVyl, BottomErrors, Sounds, ORList, fZpravy, fDebug, fSprEdit,
      ModelovyCas, fNastaveni_casu, DCC_Icons, fSoupravy, LokoRuc, fAuth,
      GlobalCOnfig, HVDb, fRegReq, fHVEdit, fHVSearch, uLIclient, LokTokens, fSprToSlot,

      parseHelper, fOdlozeniOdjezdu;

////////////////////////////////////////////////////////////////////////////////

constructor TPanelTCPClient.Create();
begin
 inherited;

 Self.parsed := TStringList.Create;
 Self.mServerVersion := 0;

 Self.pingTimer := TTimer.Create(nil);
 Self.pingTimer.Enabled := false;
 Self.pingTimer.Interval := _PING_TIMER_PERIOD_MS;
 Self.pingTimer.OnTimer := Self.SendPing;

 Self.tcpClient := TIdTCPClient.Create(nil);
 Self.tcpClient.OnConnected := Self.OnTcpClientConnected;
 Self.tcpClient.OnDisconnected := Self.OnTcpClientDisconnected;
 Self.tcpClient.ConnectTimeout := 1500;

 Self.fstatus := TPanelConnectionStatus.closed;
 Self.resusct := nil;
 self.recusc_destroy := false;
end;//ctor

destructor TPanelTCPClient.Destroy();
begin
 try
   if (Self.tcpClient.Connected) then
     Self.tcpClient.Disconnect();
 except

 end;

 // Znicime resuscitacni vlakno (vlakno obnovujici spojeni).
 if (Assigned(Self.resusct)) then
  begin
   try
     TerminateThread(Self.resusct.Handle, 0);
   finally
     if Assigned(Self.resusct) then
     begin
       Resusct.WaitFor;
       FreeAndNil(Self.resusct);
     end;
   end;
  end;

 try
   if (Assigned(Self.tcpClient)) then
     FreeAndNil(Self.tcpClient);

   if (Assigned(Self.parsed)) then
     FreeAndNil(Self.parsed);

   Self.pingTimer.Free();
 finally
   inherited;
 end;
end;//dtor

////////////////////////////////////////////////////////////////////////////////

function TPanelTCPClient.Connect(host:string; port:Word):Integer;
begin
 try
   // without .Clear() .Connected() sometimes returns true when actually not connected
   if (Self.tcpClient.IOHandler <> nil) then
     Self.tcpClient.IOHandler.InputBuffer.Clear();
   if (Self.tcpClient.Connected) then Exit(1);
 except
   try
     Self.tcpClient.Disconnect(False);
   except
   end;
   if (Self.tcpClient.IOHandler <> nil) then
     Self.tcpClient.IOHandler.InputBuffer.Clear();
 end;

 Self.tcpClient.Host := host;
 Self.tcpClient.Port := port;

 Self.openned_by_ipc := false;

 Self.fstatus := TPanelConnectionStatus.opening;
 F_Main.T_MainTimer(nil);

 try
   Self.tcpClient.Connect();
 except
   Self.fstatus := TPanelConnectionStatus.closed;
   raise;
 end;

 Self.tcpClient.IOHandler.DefStringEncoding := TIdEncoding.enUTF8;
 Self.tcpClient.IOHandler.MaxLineLength := 16777215;
 Self.control_disconnect := false;

 Result := 0;
end;

////////////////////////////////////////////////////////////////////////////////

function TPanelTCPClient.Disconnect():Integer;
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
end;

////////////////////////////////////////////////////////////////////////////////
// eventy z IdTCPClient

procedure TPanelTCPClient.OnTcpClientConnected(Sender: TObject);
begin
 try
  Self.rthread := TReadingThread.Create((Sender as TIdTCPClient));
  Self.rthread.OnData := DataReceived;
  Self.rthread.OnError := DataError;
  Self.rthread.OnTimeout := DataTimeout;
  Self.rthread.Resume;
 except
  (Sender as TIdTCPClient).Disconnect;
  raise;
 end;

 F_Main.A_Connect.Enabled    := false;
 F_Main.A_ReAuth.Enabled     := true;
 F_Main.A_Disconnect.Enabled := true;

 Self.fstatus := TPanelConnectionStatus.handshake;
 Self.pingTimer.Enabled := true;

 // send handshake
 Self.SendLn('-;HELLO;'+Self._PROTOCOL_VERSION_CLIENT+';');
end;

procedure TPanelTCPClient.OnTcpClientDisconnected(Sender: TObject);
begin
 if Assigned(Self.rthread) then Self.rthread.Terminate;

 Relief.OrDisconnect();
 TF_Messages.CloseForms();
 if (F_StitVyl.Showing) then F_StitVyl.Close();
 if (F_SoupravaEdit.Showing) then F_SoupravaEdit.Close();
 if (F_PotvrSekv.Showing) then F_PotvrSekv.Close();
 if (F_SprList.Showing) then F_SprList.Close();
 if (F_HVSearch.Showing) then F_HVSearch.Close();
 if (F_Auth.Showing) then F_Auth.Close();
 if (F_OOdj.Showing) then F_OOdj.Close();

 SoundsPlay.DeleteAll();
 ModCas.Reset();
 F_ModCasSet.Close();
 DCC.status := TDCCStatus.disabled;
 F_Main.SB_Soupravy.Enabled := false;
 RucList.Clear();
 F_RegReq.Close();
 F_SprToSlot.Close();

 Self.fstatus := TPanelConnectionStatus.closed;
 Self.pingTimer.Enabled := false;

 F_Main.A_Connect.Enabled    := true;
 F_Main.A_ReAuth.Enabled     := false;
 F_Main.A_Disconnect.Enabled := false;
 F_Main.OnReliefLoginChange(Self, '-');

 if (GlobConfig.data.auth.forgot) then
  begin
   GlobConfig.data.auth.autoauth := false;
   GlobConfig.data.auth.username := '';
   GlobConfig.data.auth.password := '';
   GlobConfig.data.auth.forgot   := false;
  end;

 // resuscitace
 // Resuscitaci povolime, pokud jsme od serveru byli odpojeni jinak, nez vlastni vuli.
 if ((not Self.control_disconnect) and (GlobConfig.data.resuscitation)) then
  begin
   Resusct := TResuscitation.Create(true, Self.ConnetionResusced);
   Resusct.server_ip   := GlobConfig.data.server.host;
   Resusct.server_port := GlobConfig.data.server.port;
   Resusct.Resume();
  end;

 if (F_Main.close_app) then
   F_Main.Close();
end;

////////////////////////////////////////////////////////////////////////////////

// parsing prijatych dat
procedure TPanelTCPClient.DataReceived(const data: string);
begin
 Self.parsed.Clear();
 ExtractStringsEx([';'], [#13, #10], data, Self.parsed);

 Self.data := data;

 F_Debug.Log('GET: '+data);

 try
   if (Self.parsed.Count < 2) then
     Exit();
   Self.parsed[1] := UpperCase(Self.parsed[1]);

   // zakladni rozdeleni parsovani - na data, ktera jsou obecna a na data pro konkretni oblast rizeni
   if (Self.parsed[0] = '-') then
    Self.ParseGlobal()
   else
    Self.ParseOR();
 except

 end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.DataErrorGlobalHandle();
begin
 try
   if (Self.tcpClient.Connected) then
     Self.tcpClient.Disconnect()
   else
     Self.OnTcpClientDisconnected(Self);
 except

 end;
end;

procedure TPanelTCPClient.DataError();
begin
 Self.DataErrorGlobalHandle();
 Errors.writeerror('Výjimka čtení socketu!', 'KLIENT', '-');
end;

procedure TPanelTCPClient.DataTimeout();
begin
 Self.DataErrorGlobalHandle();
 Errors.writeerror('Spojení se serverem přerušeno!', 'KLIENT', '-');
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.ParseGlobal();
var i:Integer;
    found:boolean;
begin
 // parse handhake
 if (Self.parsed[1] = 'HELLO') then
  begin
   // kontrola verze protokolu
   found := false;
   for i := 0 to Length(protocol_version_accept)-1 do
    begin
     if (Self.parsed[2] = protocol_version_accept[i]) then
      begin
       found := true;
       break;
      end;
    end;//for i

   if (not found) then
     Application.MessageBox(PChar('Verze protokolu, kterou požívá server ('+Self.parsed[2]+') není podporována'),
       'Upozornění', MB_OK OR MB_ICONWARNING);

   Self.mServerVersion := Self.VersionToInt(Self.parsed[2]);
   Self.fstatus := TPanelConnectionStatus.opened;
   Self.SendLn('-;OR-LIST;');
   PanelTCPClient.SendLn('-;F-VYZN-GET;');
   PanelTCPClient.SendLn('-;MAUS;'+IntToStr(Integer(BridgeClient.authStatus = tuLiAuthStatus.yes)));
   BridgeClient.toLogin.server := Self.tcpClient.Host;
   BridgeClient.toLogin.port   := Self.tcpClient.Port;
   Relief.ORConnectionOpenned();
   F_Main.SB_Soupravy.Enabled := true;
  end

 else if ((parsed[1] = 'PING') and (parsed.Count > 2) and (UpperCase(parsed[2]) = 'REQ-RESP')) then
  begin
   if (parsed.Count >= 4) then
     Self.SendLn('-;PONG;'+parsed[3])
   else
     Self.SendLn('-;PONG');
  end

 else if (parsed[1] = 'STIT') then
  begin
   if (parsed.Count > 3) then
     F_StitVyl.OpenFormStit(Self.PanelSetStitVyl, parsed[2], parsed[3])
   else
     F_StitVyl.OpenFormStit(Self.PanelSetStitVyl, parsed[2], '');
  end

 else if (parsed[1] = 'VYL') then
  begin
   if (parsed.Count > 3) then
     F_StitVyl.OpenFormVyl(Self.PanelSetStitVyl, parsed[2], parsed[3])
   else
     F_StitVyl.OpenFormVyl(Self.PanelSetStitVyl, parsed[2], '');
  end

 else if ((parsed[1] = 'PS') or (parsed[1] = 'IS')) then
  F_PotvrSekv.StartOrUpdate(parsed, Self.PanelPotvrSekv)

 else if (parsed[1] = 'PS-CLOSE') then
  begin
   F_PotvrSekv.OnEnd := nil;
   if (parsed.Count > 2) then
     F_PotvrSekv.Stop(parsed[2])
   else
     F_PotvrSekv.Stop();
  end

 else if (parsed[1] = 'MENU') then
  Relief.ORShowMenu(parsed[2])

 else if (parsed[1] = 'INFOMSG') then
  Relief.ORInfoMsg(parsed[2])

 else if (parsed[1] = 'BOTTOMERR') then
  Errors.writeerror(parsed[2], parsed[4], parsed[3])

 else if (parsed[1] = 'SND') then
  begin
   if (UpperCase(parsed[2]) = 'PLAY') then
     SoundsPlay.Play(StrToInt(parsed[3]), (parsed.Count > 4) and (parsed[4] = 'L'));

   if (UpperCase(parsed[2]) = 'STOP') then
     SoundsPlay.DeleteSound(StrToInt(parsed[3]));
  end

 else if (parsed[1] = 'OR-LIST') then
  ORDb.Parse(parsed[2])

 else if (parsed[1] = 'UPO') then
  Relief.UPO.ParseCommand(parsed[2], false)

 else if (parsed[1] = 'UPO-CRIT') then
  Relief.UPO.ParseCommand(parsed[2], true)

 else if (parsed[1] = 'UPO-CLOSE') then
  Relief.UPO.showing := false

 else if (parsed[1] = 'INFO-TIMER') then
  Relief.ORInfoTimer(StrToInt(parsed[2]), StrToInt(parsed[3]), StrToInt(parsed[4]), parsed[5])

 else if (parsed[1] = 'INFO-TIMER-RM') then
  Relief.ORInfoTimerRemove(StrToInt(parsed[2]))

 else if (parsed[1] = 'MOD-CAS') then
  ModCas.ParseData(parsed)

 else if (parsed[1] = 'DCC') then
  DCC.Parse(parsed)

 else if (parsed[1] = 'SPR-LIST') then
  if (Parsed.Count > 2) then
    F_SprList.ParseLoko(parsed[2])
  else
    F_SprList.ParseLoko('')

 else if ((parsed[1] = 'F-VYZN-LIST') and (parsed.Count > 2)) then
  F_HVEdit.ParseVyznamy(parsed[2])

 else if ((parsed[1] = 'LOK') and (parsed[3] = 'FOUND')) then
  F_HVSearch.LokoFound(THV.Create(parsed[4]))

 else if ((parsed[1] = 'LOK') and (parsed[3] = 'NOT-FOUND')) then
  F_HVSearch.LokoNotFound()

 else if (parsed[1] = 'PODJ') then
  F_OOdj.OpenForm(parsed);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.ParseOR();
var data:TStrings;
    ar:TWordAr;
    i:Integer;
begin
 if (parsed[1] = 'CHANGE') then
  Self.ParseORChange()

 else if (parsed[1] = 'AUTH') then begin
  if parsed.Count > 4 then
   Relief.ORAuthoriseResponse(parsed[0], TORControlRights(StrToInt(parsed[2])), parsed[3], parsed[4])
  else
   Relief.ORAuthoriseResponse(parsed[0], TORControlRights(StrToInt(parsed[2])), parsed[3])

 end else if (parsed[1] = 'NUZ') then
   Relief.ORNUZ(parsed[0], TNuzStatus(StrToInt(parsed[2])))

 else if (parsed[1] = 'CAS') then
  begin
   if (UpperCase(parsed[2]) = 'START') then
     Relief.AddMereniCasu(parsed[0], EncodeTime(0, 0, StrToInt(parsed[4]), 0), StrToInt(parsed[3]));
   if (UpperCase(parsed[2]) = 'STOP') then
     Relief.StopMereniCasu(parsed[0], StrToInt(parsed[3]));
  end

 else if (parsed[1] = 'MSG') then
  TF_Messages.MsgReceive(parsed[0], parsed[3], parsed[2])

 else if (parsed[1] = 'MSG-ERR') then
  TF_Messages.ErrorReceive(parsed[0], parsed[3], parsed[2])

 else if (parsed[1] = 'HV-LIST') then
  begin
   if (parsed.Count > 2) then
     Relief.ORHVList(parsed[0], parsed[2])
   else
     Relief.ORHVList(parsed[0], '');
  end

 else if (parsed[1] = 'SPR-NEW') then
  Relief.ORSprNew(parsed[0])

 else if (parsed[1] = 'SPR-EDIT') then
  Relief.ORSprEdit(parsed[0], parsed)

 else if (parsed[1] = 'SPR-EDIT-ERR') then
  F_SoupravaEdit.TechError(parsed[2])

 else if (parsed[1] = 'SPR-EDIT-ACK') then
  F_SoupravaEdit.TechACK()

 else if ((parsed[1] = 'OSV') and (parsed.Count > 2)) then
  Self.OsvListParse(parsed[0], parsed[2])

 else if (parsed[1] = 'ZAS') then
  Relief.ORStackMsg(parsed[0], parsed)

 else if (parsed[1] = 'DK-CLICK') then
  begin
   case (parsed[2][1]) of
    '0' : Relief.ORDKClickServer(parsed[0], false);
    '1' : Relief.ORDKClickServer(parsed[0], true);
   end;//case

 // token
 end else if (parsed[1] = 'LOK-TOKEN') then
  tokens.ParseData(Self.parsed)

 else if ((parsed[1] = 'RUC') or (parsed[1] = 'RUC-RM')) then
  RucList.ParseCommand(parsed)

 else if (parsed[1] = 'LOK-REQ') then
  Relief.ORLokReq(parsed[0], parsed)

 else if (parsed[1] = 'MAUS') then
  begin
   data := TStringList.Create();
   ExtractStringsEx(['|'], [], parsed[2], data);
   SetLength(ar, data.Count);
   for i := 0 to data.Count-1 do ar[i] := StrToInt(data[i]);
   F_SprToSlot.Open(parsed[0], ar);
   data.Free();

 end else if (parsed[1] = 'SHP') then
   Relief.ORHlaseniMsg(parsed[0], parsed)

 else if (parsed[1] = 'MENU') then
  Relief.ORDkShowMenu(parsed[0], parsed[2], parsed[3]);

end;

////////////////////////////////////////////////////////////////////////////////

// zmena stavu bloku
procedure TPanelTCPClient.ParseORChange();
begin
 try
  Relief.ORBlkChange(parsed[0], StrToInt(parsed[3]), StrToInt(parsed[2]), parsed);
 except
  Exit();   // pokud nastane nejaky problem s parsovanim, data proste zahodime
 end;
end;

////////////////////////////////////////////////////////////////////////////////
// udalosti z panelu:

procedure TPanelTCPClient.PanelAuthorise(Sender:string;rights:TORControlRights; username,password:string);
begin
 Self.SendLn(Sender+';AUTH;'+IntToStr(Integer(rights))+';{'+username+'};{'+password+'}');
end;

procedure TPanelTCPClient.PanelFirstGet(Sender:string);
begin
 Self.SendLn(Sender+';GET-ALL;');
end;

procedure TPanelTCPClient.PanelClick(Sender:string; Button:TPanelButton; blokid:Integer = -1; params:string = '');
begin
 if (blokid > -1) then
   Self.SendLn(Sender+';CLICK;'+PanelButtonToString(Button)+';'+IntToStr(blokid)+';'+params)
 else if (params = '') then
   Self.SendLn(Sender+';CLICK;'+PanelButtonToString(Button))
 else
   Self.SendLn(Sender+';CLICK;'+PanelButtonToString(Button)+';;'+params);
end;

procedure TPanelTCPClient.PanelMenuClick(item_hint:string; item_index:Integer);
begin
 Self.SendLn('-;MENUCLICK;'+item_hint+';'+IntToStr(item_index));
end;

procedure TPanelTCPClient.PanelDkMenuClick(Sender:string; rootItem: string; subItem: string = '');
begin
 Self.SendLn(Sender+';MENUCLICK;'+rootItem+';'+subItem);
end;

procedure TPanelTCPClient.PanelSetStitVyl(typ:Integer; stitvyl:string);
begin
 case (typ) of
  _STITEK: Self.SendLn('-;STIT;{'+stitvyl+'}');
  _VYLUKA: Self.SendLn('-;VYL;{'+stitvyl+'}');
 end;
end;

procedure TPanelTCPClient.PanelPotvrSekv(Sender: TObject);
begin
 Self.SendLn('-;'+F_PotvrSekv.mode+';'+IntToStr(Integer(F_PotvrSekv.EndReason))+';');
end;

procedure TPanelTCPClient.PanelNUZ(Sender:string);
begin
 Self.SendLn(Sender+';NUZ;1;');
end;

procedure TPanelTCPClient.PanelNUZCancel(Sender:string);
begin
 Self.SendLn(Sender+';NUZ;0;');
end;

procedure TPanelTCPClient.PanelMessage(senderid:string; recepientid:string; msg:string);
begin
 Self.SendLn(senderid+';MSG;'+recepientid+';{'+msg+'}');
end;

procedure TPanelTCPClient.PanelSprChange(Sender:string; msg:string);
begin
 Self.SendLn(sender+';SPR-CHANGE;'+msg);
end;

procedure TPanelTCPClient.PanelLokMove(Sender:string; addr:Word; or_id:string);
begin
 Self.SendLn(sender+';LOK-MOVE-OR;'+IntToStr(addr)+';'+or_id);
end;

procedure TPanelTCPClient.PanelLokList(Sender:string);
begin
 Self.SendLn(sender+';HV-LIST;');
end;

procedure TPanelTCPClient.PanelSetOsv(Sender:string; code:string; state:Integer);
begin
 Self.SendLn(sender+';OSV;SET;'+code+';'+IntToStr(state));
end;

procedure TPanelTCPClient.PanelUpdateOsv(Sender:string);
begin
 Self.SendLn(sender+';OSV;GET;');
end;

////////////////////////////////////////////////////////////////////////////////

// poradi RED, GREEN, BLUE
function TPanelTCPClient.StrToColor(str:string):TColor;
begin
 Result := RGB(StrToInt('$'+LeftStr(str, 2)), StrToInt('$'+Copy(str, 3, 2)), StrToInt('$'+RightStr(str, 2)));
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.SendLn(str:string);
begin
 try
   if (not Self.tcpClient.Connected) then Exit;
 except
   Exit();
 end;

 try
   Self.tcpClient.Socket.WriteLn(str);
 except
   if (Self.fstatus = opened) then
    Self.OnTcpClientDisconnected(Self);
 end;

 F_Debug.Log('SEND: '+str);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.OsvListParse(oblr:string; data:string);
var i:Integer;
    list,list2:TStrings;
begin
 list  := TStringList.Create();
 list2 := TStringList.Create();

 ExtractStringsEx([']'], ['['], data, list);

 for i := 0 to list.Count-1 do
  begin
   list2.Clear();
   ExtractStringsEx(['|'], [], list[i], list2);

   try
     case (list2[1][1]) of
      '0' : Relief.OROsvChange(oblr, list2[0], false);
      '1' : Relief.OROsvChange(oblr, list2[0], true);
     end;
   except

   end;
  end;

 list.Free();
 list2.Free();
end;

////////////////////////////////////////////////////////////////////////////////
//  or;HV;ADD;data                - pridani hnaciho vozidla
//  or;HV;REMOVE;addr             - smazani hnaciho vozdila
//  or;HV;EDIT;data               - editace hnaciho vozidla

procedure TPanelTCPClient.PanelHVAdd(Sender:string; data:string);
begin
 Self.SendLn(Sender+';HV;ADD;'+data);
end;

procedure TPanelTCPClient.PanelHVRemove(Sender:string; addr:Word);
begin
 Self.SendLn(Sender+';HV;REMOVE;'+IntToStr(addr));
end;

procedure TPanelTCPClient.PanelHVEdit(Sender:string; data:string);
begin
 Self.SendLn(Sender+';HV;EDIT;'+data);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.ConnetionResusced(Sender:TObject);
begin
 Self.Connect(GlobConfig.data.server.host, GlobConfig.data.server.port);
 Errors.RemoveAllErrors();
 Self.recusc_destroy := true;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.Update();
begin
 if (Self.recusc_destroy) then
  begin
   Self.recusc_destroy := false;
   try
     Self.resusct.Terminate();
   finally
     if Assigned(Self.resusct) then
     begin
       Self.resusct.WaitFor;
       FreeAndNil(Self.resusct);
     end;
   end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.SendPing(Sedner:TObject);
begin
 try
   if (Self.tcpClient.Connected) then
     Self.SendLn('-;PING');
 except

 end;
end;

////////////////////////////////////////////////////////////////////////////////

function TPanelTCPClient.PanelButtonToString(button:TPanelButton):string;
begin
 case (button) of
   TPanelButton.F1 : Result := 'F1';
   TPanelButton.F2 : Result := 'F2';
   TPanelButton.ENTER : Result := 'ENTER';
   TPanelButton.ESCAPE : Result := 'ESCAPE';
 else
   Result := '';
 end;
end;

////////////////////////////////////////////////////////////////////////////////

function TPanelTCPClient.VersionToInt(version:string):Integer;
var strs:TStrings;
begin
 strs := TStringList.Create();
 try
   ExtractStringsEx(['.'], [], version, strs);
   Result := StrToInt(strs[0])*1000 + StrToInt(strs[1]);
 finally
   strs.Free();
 end;
end;

function TPanelTCPClient.IsServerVersionAtLeast(version:string):Boolean;
begin
 Result := (Self.serverVersionInt >= Self.VersionToInt(version));
end;

function TPanelTCPClient.VersionToString(version:Integer):string;
begin
 Result := IntToStr(version div 1000) + '.' + IntToStr(version mod 1000);
end;

function TPanelTCPClient.GetServerVersionStr():string;
begin
 Result := Self.VersionToString(Self.serverVersionInt);
end;

////////////////////////////////////////////////////////////////////////////////

initialization
 PanelTCPClient := TPanelTCPClient.Create;

finalization
 FreeAndNil(PanelTCPCLient);

end.//unit
