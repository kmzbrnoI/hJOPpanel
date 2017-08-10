unit TCPClientPanel;

{
  TCP klient resici komunikaci s hJOPserverem.

  Kompletni specifikace komunikacnho protkolu je popsana na
  https://github.com/kmzbrnoI/hJOPserver/wiki/panelServer.
}

interface

uses SysUtils, IdTCPClient, ListeningThread, IdTCPConnection, IdGlobal, ExtCtrls,
     Classes, StrUtils, RPConst, Graphics, Windows, fPotvrSekv, Forms, Controls,
     Generics.Collections, Resuscitation;

const
  _DEFAULT_PORT = 5896;
  _PING_TIMER_PERIOD_MS = 20000;

  // tady jsou vyjmenovane vsechny verze protokoluk pripojeni k serveru, ktere klient podporuje
  protocol_version_accept : array[0..0] of string =
    (
      '1.0'
    );

type
  TPanelConnectionStatus = (closed, opening, handshake, opened);

  TPanelTCPClient = class
   private const
    _PROTOCOL_VERSION = '1.1';

   private
    rthread: TReadingThread;
    tcpClient: TIdTCPClient;
    fstatus : TPanelConnectionStatus;
    parsed: TStrings;
    data:string;
    control_disconnect:boolean;       // je true, pokud disconnect plyne ode me
    recusc_destroy:boolean;
    pingTimer:TTimer;

     procedure OnTcpClientConnected(Sender: TObject);
     procedure OnTcpClientDisconnected(Sender: TObject);
     procedure DataReceived(const data: string);
     procedure Timeout();   // timeout from socket = broken pipe

     // data se predavaji v Self.Parsed
     procedure ParseGlobal();
     procedure ParseOR();
     procedure ParseORChange();

     // parsovani Change jednotlivych typu bloku:
     procedure ParseORChangeVyh();
     procedure ParseORChangeUsek();
     procedure ParseORChangeSCom();
     procedure ParseORChangePrejezd();
     procedure ParseORChangeUvazka();
     procedure ParseORChangeZamek();
     procedure ParseORChangeRozp();

     procedure OsvListParse(oblr:string; data:string);

     procedure ConnetionResusced(Sender:TObject);
     procedure SendPing(Sedner:TObject);

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
      procedure PanelClick(Sender:string; Button:TPanelButton; blokid:Integer = -1);
      procedure PanelMenuClick(item_hint:string; item_index:Integer);
      procedure PanelSetStitVyl(typ:Integer; stitvyl:string);
      procedure PanelPotvrSekv(reason:TPSEnd);
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

      property status:TPanelConnectionStatus read fstatus;
  end;//TPanelTCPClient

var
  PanelTCPClient : TPanelTCPClient;

implementation

uses Panel, fMain, fStitVyl, BottomErrors, Sounds, ORList, fZpravy, Debug, fSprEdit,
      ModelovyCas, fNastaveni_casu, DCC_Icons, fSoupravy, LokoRuc, fAuth,
      GlobalCOnfig, HVDb, fRegReq, fHVEdit, fHVSearch, uLIclient, LokTokens, fSprToSlot,
      BlokUvazka;

////////////////////////////////////////////////////////////////////////////////

constructor TPanelTCPClient.Create();
begin
 inherited;

 Self.parsed := TStringList.Create;

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
 Self.control_disconnect := false;

 Result := 0;
end;//function

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
end;//function

////////////////////////////////////////////////////////////////////////////////
// eventy z IdTCPClient

procedure TPanelTCPClient.OnTcpClientConnected(Sender: TObject);
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

 F_Main.A_Connect.Enabled    := false;
 F_Main.A_ReAuth.Enabled     := true;
 F_Main.A_Disconnect.Enabled := true;

 Self.fstatus := TPanelConnectionStatus.handshake;
 Self.pingTimer.Enabled := true;

 // send handshake
 Self.SendLn('-;HELLO;'+Self._PROTOCOL_VERSION+';');
end;//procedure

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
 if (F_Auth.showing) then F_Auth.Close();

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
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// parsing prijatych dat
procedure TPanelTCPClient.DataReceived(const data: string);
begin
 Self.parsed.Clear();
 ExtractStringsEx([';'], [#13, #10], data, Self.parsed);

 Self.data := data;

 F_Debug.Log('GET: '+data);

 try
   // zakladni rozdeleni parsovani - na data, ktera jsou obecna a na data pro konkretni oblast rizeni
   if (Self.parsed[0] = '-') then
    Self.ParseGlobal()
   else
    Self.ParseOR();
 except

 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.Timeout();
begin
 Self.OnTcpClientDisconnected(Self);
 Errors.writeerror('Spojen� se serverem p�eru�eno', 'KLIENT', '-');
end;//procedure

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
     Application.MessageBox(PChar('Verze protokolu, kterou po��v� server ('+Self.parsed[2]+') nen� podporov�na'),
       'Upozorn�n�', MB_OK OR MB_ICONWARNING);

   Self.fstatus := TPanelConnectionStatus.opened;
   Self.SendLn('-;OR-LIST;');
   PanelTCPClient.SendLn('-;F-VYZN-GET;');
   PanelTCPClient.SendLn('-;MAUS;'+IntToStr(Integer(BridgeClient.authStatus = tuLiAuthStatus.yes)));
   BridgeClient.toLogin.server := Self.tcpClient.Host;
   BridgeClient.toLogin.port   := Self.tcpClient.Port;
   Relief.ORConnectionOpenned();
   F_Main.SB_Soupravy.Enabled := true;
  end

//  -;STIT;blk_name;stitek;                - pozadavek na zobrazeni vstupu pro stitek
//  -;VYL;blk_name;vyluka;                 - pozadavek na zobrazeni vstupu pro vyluku
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

 else if (parsed[1] = 'PS') then
  PotvrSek.Start(parsed, Self.PanelPotvrSekv)

 else if (parsed[1] = 'PS-CLOSE') then
  begin
   PotvrSek.OnEnd := nil;
   if (parsed.Count > 2) then
     PotvrSek.Stop(parsed[2])
   else
     PotvrSek.Stop();
  end

 else if (parsed[1] = 'MENU') then
  Relief.ORShowMenu(parsed[2])

 else if (parsed[1] = 'INFOMSG') then
  Relief.ORInfoMsg(parsed[2])

 else if (parsed[1] = 'BOTTOMERR') then
  Errors.writeerror(parsed[2], parsed[4], parsed[3])

 else if (parsed[1] = 'SND') then
  begin
   if (parsed[2] = 'PLAY') then
     SoundsPlay.Play(StrToInt(parsed[3]), (parsed.Count > 4) and (parsed[4] = 'L'));

   if (parsed[2] = 'STOP') then
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
  F_SprList.ParseLoko(parsed[2])

 else if ((parsed[1] = 'F-VYZN-LIST') and (parsed.Count > 2)) then
  F_HVEdit.ParseVyznamy(parsed[2])

 else if ((parsed[1] = 'LOK') and (parsed[3] = 'FOUND')) then
  F_HVSearch.LokoFound(THV.Create(parsed[4]))

 else if ((parsed[1] = 'LOK') and (parsed[3] = 'NOT-FOUND')) then
  F_HVSearch.LokoNotFound();

end;//procedure

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
   if (parsed[2] = 'START') then
     Relief.AddMereniCasu(parsed[0], EncodeTime(0, 0, StrToInt(parsed[4]), 0), StrToInt(parsed[3]));
   if (parsed[2] = 'STOP') then
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
   Relief.ORHlaseniMsg(parsed[0], parsed);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// zaciname Parsed[2], kde je ulozen typ bloku jako cislo
procedure TPanelTCPClient.ParseORChange();
begin
 try
//  or;CHANGE;typ_blk;tech_blk_id;barva_popredi;barva_pozadi;blikani; dalsi argumenty u konkretnich typu bloku:
//    typ_blk = cislo podle typu bloku na serveru
//      usek : konec_jc;[souprava;barva_soupravy;sipkaLsipkaS;barva_pozadi] -  posledni 3 argumenty jsou nepovinne
//      vyhybka : poloha (cislo odpovidajici poloze na serveru - [disabled = -5, none = -1, plus = 0, minus = 1, both = 2])
//      navestidlo: ab (false = 0, true = 1)
//      pjejezd: stav (otevreno = 0, vystraha = 1, uzavreno = 2, anulace = 3)
//      uvazka: smer (-5 = disabled, 0 = bez smeru, 1 = zakladni, 2 = opacny); soupravy - cisla souprav oddelene carkou
//         prvni souprava je vzdy ta, ktere do trati prisla prvni


  case (StrToInt(parsed[2])) of
   _BLK_VYH     : Self.ParseORChangeVyh();
   _BLK_USEK    : Self.ParseORChangeUsek();
   _BLK_SCOM    : Self.ParseORChangeSCom();
   _BLK_PREJEZD : Self.ParseORChangePrejezd();
   _BLK_UVAZKA  : Self.ParseORChangeUvazka();
   _BLK_ZAMEK   : Self.ParseORChangeZamek();
   _BLK_ROZP    : Self.ParseORChangeRozp();
  end;//case

 except
  Exit();   // pokud nastane nejaky problem s parsovanim, data proste zahodime
 end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.ParseORChangeVyh();
var VyhPanelProp:TVyhPanelProp;
begin
  VyhPanelProp.Symbol  := StrToColor(parsed[4]);
  VyhPanelProp.Pozadi  := StrToColor(parsed[5]);
  VyhPanelProp.blikani := StrToBool(parsed[6]);
  VyhPanelProp.Poloha  := TVyhPoloha(StrToInt(parsed[7]));

  Relief.ORVyhChange(parsed[0], StrToInt(parsed[3]), VyhPanelProp);
end;

procedure TPanelTCPClient.ParseORChangeUsek();
var UsekPanelProp:TUsekPanelProp;
    soupravy, souprava:TStrings;
    i: Integer;
    us:TUsekSouprava;
begin
  UsekPanelProp.Symbol  := StrToColor(parsed[4]);
  UsekPanelProp.Pozadi  := StrToColor(parsed[5]);
  UsekPanelProp.blikani := StrToBool(parsed[6]);
  UsekPanelProp.KonecJC := TJCType(StrToInt(parsed[7]));
  UsekPanelProp.nebarVetve := strToColor(parsed[8]);

  UsekPanelProp.soupravy := TList<TUsekSouprava>.Create();

  if (parsed.Count > 9) then
   begin
    soupravy := TStringList.Create();
    souprava := TStringList.Create();

    try
      ExtractStringsEx([')'], ['('], parsed[9], soupravy);

      for i := 0 to soupravy.Count-1 do
       begin
        souprava.Clear();
        ExtractStringsEx([';'], [], soupravy[i], souprava);

        us.nazev := souprava[0];
        us.sipkaL := ((souprava[1] <> '') and (souprava[1][1] = '1'));
        us.sipkaS := ((souprava[1] <> '') and (souprava[1][2] = '1'));
        us.fg := strToColor(souprava[2]);
        us.bg := strToColor(souprava[3]);

        if (souprava.Count > 4) then
          us.ramecek := strToColor(souprava[4])
        else
          us.ramecek := clBlack;

        UsekPanelProp.soupravy.Add(us);
       end;

    finally
      soupravy.Free();
      souprava.Free();
    end;
   end;

  Relief.ORUsekChange(parsed[0], StrToInt(parsed[3]), UsekPanelProp);
end;

procedure TPanelTCPClient.ParseORChangeSCom();
var NavPanelProp:TNavPanelProp;
begin
  NavPanelProp.Symbol  := StrToColor(parsed[4]);
  NavPanelProp.Pozadi  := StrToColor(parsed[5]);
  NavPanelProp.blikani := StrToBool(parsed[6]);
  NavPanelProp.AB      := StrToBool(parsed[7]);

  Relief.ORNavChange(parsed[0], StrToInt(parsed[3]), NavPanelProp);
end;

procedure TPanelTCPClient.ParseORChangePrejezd();
var PrjPanelProp:TPrjPanelProp;
begin
  PrjPanelProp.Symbol  := StrToColor(parsed[4]);
  PrjPanelProp.Pozadi  := StrToColor(parsed[5]);
  PrjPanelProp.stav    := TBlkPrjPanelStav(StrToInt(parsed[7]));

  Relief.ORPrjChange(parsed[0], StrToInt(parsed[3]), PrjPanelProp);
end;//procedure

procedure TPanelTCPClient.ParseORChangeUvazka();
var UvazkaPanelProp:TUvazkaPanelProp;
    UvazkaSprPanelProp:TUvazkaSprPanelProp;
    UvazkaSpr:TUvazkaSpr;
    i, j:Integer;
    data:TStrings;
begin
  UvazkaPanelProp.Symbol  := StrToColor(parsed[4]);
  UvazkaPanelProp.Pozadi  := StrToColor(parsed[5]);
  UvazkaPanelProp.blik    := StrToBool(parsed[6]);
  UvazkaPanelProp.smer    := TUvazkaSmer(StrToInt(parsed[7]));

  UvazkaSprPanelProp.spr := TList<TUvazkaSpr>.Create();

  if (parsed.Count >= 9) then
   begin
    data := TStringList.Create();
    ExtractStringsEx([','], [], parsed[8], data);

    for i := 0 to data.Count-1 do
     begin
      UvazkaSpr.strings := TStringList.Create();
      ExtractStringsEx(['|'], [], data[i], UvazkaSpr.strings);

      if (LeftStr(data[i], 1) = '$') then
       begin
        UvazkaSpr.strings[0] := RightStr(UvazkaSpr.strings[0], Length(UvazkaSpr.strings[0])-1);
        UvazkaSpr.color      := clYellow;
       end else begin
        UvazkaSpr.color      := clWhite;
       end;
      UvazkaSpr.time := '';

      // kontrola preteceni textu
      for j := 0 to UvazkaSpr.strings.Count-1 do
        if (Length(UvazkaSpr.strings[j]) > 8) then
          UvazkaSpr.strings[j] := LeftStr(UvazkaSpr.strings[j], 7) + '.';

      UvazkaSprPanelProp.spr.Add(UvazkaSpr);
     end;
    data.Free;
   end;

  Relief.ORUvazkaChange(parsed[0], StrToInt(parsed[3]), UvazkaPanelProp, UvazkaSprPanelProp);
end;

procedure TPanelTCPClient.ParseORChangeZamek();
var ZamekPanelProp:TZamekPanelProp;
begin
  ZamekPanelProp.Symbol  := StrToColor(parsed[4]);
  ZamekPanelProp.Pozadi  := StrToColor(parsed[5]);
  ZamekPanelProp.blik    := StrToBool(parsed[6]);

  Relief.ORZamekChange(parsed[0], StrToInt(parsed[3]), ZamekPanelProp);
end;

procedure TPanelTCPClient.ParseORChangeRozp();
var RozpPanelProp:TRozpPanelProp;
begin
  RozpPanelProp.Symbol  := StrToColor(parsed[4]);
  RozpPanelProp.Pozadi  := StrToColor(parsed[5]);
  RozpPanelProp.blik    := StrToBool(parsed[6]);

  Relief.ORRozpChange(parsed[0], StrToInt(parsed[3]), RozpPanelProp);
end;


////////////////////////////////////////////////////////////////////////////////
// udalosti z panelu:

procedure TPanelTCPClient.PanelAuthorise(Sender:string;rights:TORControlRights; username,password:string);
begin
 Self.SendLn(Sender+';AUTH;'+IntToStr(Integer(rights))+';{'+username+'};{'+password+'}');
end;//procedure

procedure TPanelTCPClient.PanelFirstGet(Sender:string);
begin
 Self.SendLn(Sender+';GET-ALL;');
end;//procedure

procedure TPanelTCPClient.PanelClick(Sender:string; Button:TPanelButton; blokid:Integer);
begin
 if (blokid > -1) then
   Self.SendLn(Sender+';CLICK;'+PanelButtonToString(Button)+';'+IntToStr(blokid))
 else
   Self.SendLn(Sender+';CLICK;'+PanelButtonToString(Button));
end;//procedure

procedure TPanelTCPClient.PanelMenuClick(item_hint:string; item_index:Integer);
begin
 Self.SendLn('-;MENUCLICK;'+item_hint+';'+IntToStr(item_index));
end;//procedure

procedure TPanelTCPClient.PanelSetStitVyl(typ:Integer; stitvyl:string);
begin
 case (typ) of
  _STITEK: Self.SendLn('-;STIT;{'+stitvyl+'}');
  _VYLUKA: Self.SendLn('-;VYL;{'+stitvyl+'}');
 end;
end;//procedure

procedure TPanelTCPClient.PanelPotvrSekv(reason:TPSEnd);
begin
 Self.SendLn('-;PS;'+IntToStr(Integer(reason))+';');
end;//procedure

procedure TPanelTCPClient.PanelNUZ(Sender:string);
begin
 Self.SendLn(Sender+';NUZ;1;');
end;//procedure

procedure TPanelTCPClient.PanelNUZCancel(Sender:string);
begin
 Self.SendLn(Sender+';NUZ;0;');
end;//procedure

procedure TPanelTCPClient.PanelMessage(senderid:string; recepientid:string; msg:string);
begin
 Self.SendLn(senderid+';MSG;'+recepientid+';{'+msg+'}');
end;//procedure

procedure TPanelTCPClient.PanelSprChange(Sender:string; msg:string);
begin
 Self.SendLn(sender+';SPR-CHANGE;'+msg);
end;//procedure

procedure TPanelTCPClient.PanelLokMove(Sender:string; addr:Word; or_id:string);
begin
 Self.SendLn(sender+';LOK-MOVE-OR;'+IntToStr(addr)+';'+or_id);
end;//procedure

procedure TPanelTCPClient.PanelLokList(Sender:string);
begin
 Self.SendLn(sender+';HV-LIST;');
end;//procedure

procedure TPanelTCPClient.PanelSetOsv(Sender:string; code:string; state:Integer);
begin
 Self.SendLn(sender+';OSV;SET;'+code+';'+IntToStr(state));
end;//procedure

procedure TPanelTCPClient.PanelUpdateOsv(Sender:string);
begin
 Self.SendLn(sender+';OSV;GET;');
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// poradi RED, GREEN, BLUE
function TPanelTCPClient.StrToColor(str:string):TColor;
begin
 Result := RGB(StrToInt('$'+LeftStr(str, 2)), StrToInt('$'+Copy(str, 3, 2)), StrToInt('$'+RightStr(str, 2)));
end;//function

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.SendLn(str:string);
begin
 try
   if (not Self.tcpClient.Connected) then Exit;
 except

 end;

 try
   Self.tcpClient.Socket.WriteLn(str);
 except
   if (Self.fstatus = opened) then
    Self.OnTcpClientDisconnected(Self);
 end;

 F_Debug.Log('SEND: '+str);
end;//procedure

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
end;//procedure

////////////////////////////////////////////////////////////////////////////////
//  or;HV;ADD;data                - pridani hnaciho vozidla
//  or;HV;REMOVE;addr             - smazani hnaciho vozdila
//  or;HV;EDIT;data               - editace hnaciho vozidla

procedure TPanelTCPClient.PanelHVAdd(Sender:string; data:string);
begin
 Self.SendLn(Sender+';HV;ADD;'+data);
end;//procedure

procedure TPanelTCPClient.PanelHVRemove(Sender:string; addr:Word);
begin
 Self.SendLn(Sender+';HV;REMOVE;'+IntToStr(addr));
end;//procedure

procedure TPanelTCPClient.PanelHVEdit(Sender:string; data:string);
begin
 Self.SendLn(Sender+';HV;EDIT;'+data);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.ConnetionResusced(Sender:TObject);
begin
 Self.Connect(GlobConfig.data.server.host, GlobConfig.data.server.port);
 while (Errors.Count > 0) do Errors.removeerror();
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

initialization
 PanelTCPClient := TPanelTCPClient.Create;

finalization
 FreeAndNil(PanelTCPCLient);

end.//unit
