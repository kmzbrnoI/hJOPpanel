unit TCPClientPanel;

interface

uses SysUtils, IdTCPClient, ListeningThread, IdTCPConnection, IdGlobal,
     Classes, StrUtils, RPConst, Graphics, Windows, fPotvrSekv, Forms, Controls,
     Generics.Collections, Resuscitation;

const
  _DEFAULT_PORT = 5896;

  // tady jsou vyjmenovane vsechny verze protokoluk pripojeni k serveru, ktere klient podporuje
  protocol_version_accept : array[0..0] of string =
    (
      '1.0'
    );

type
  TPanelConnectionStatus = (closed, opening, handshake, opened);

  TPanelTCPClient = class
   private const
    _PROTOCOL_VERSION = '1.0';

   private
    rthread: TReadingThread;
    tcpClient: TIdTCPClient;
    fstatus : TPanelConnectionStatus;
    parsed: TStrings;
    data:string;
    control_disconnect:boolean;       // je true, pokud disconnect plyne ode me
    recusc_destroy:boolean;

     procedure OnTcpClientConnected(Sender: TObject);
     procedure OnTcpClientDisconnected(Sender: TObject);
     procedure DataReceived(const data: string);
     procedure Timeout();   // timeout from socket = broken pipe

     // data se predavaji v Self.Parsed
     procedure ParseGlobal();
     procedure ParseOR();
     procedure ParseORChange();
     procedure ParseLokToken();

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

   public

    resusct : TResuscitation;

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
      procedure PanelClick(Sender:string; blokid:Integer; Button:TPanelButton);
      procedure PanelMenuClick(item_hint:string);
      procedure PanelSetStitVyl(typ:Integer; stitvyl:string);
      procedure PanelEscape();
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

{
 Specifikace komunikacnho protkolu:
  jedna se o retezec, ve kterem jsou jednotliva data oddelena strednikem
  prvni parametr je vzdy id oblasti rizeni, popr. '-' pokud se jedna o rezijni prikaz

 PRIKAZY:

////////////////////////////////////////////////////////////////////////////////
/////////////////////////// KLIENT -> SERVER ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
  -;HELLO;verze;                                                                handshake a specifikace komunikacniho protokolu
  -;ESCAPE;                                                                     stisknuti tlacitka ESC
  -;STIT;stitek                                                                 nastaveni stitku
  -;VYL;vyluka                                                                  nastaveni vyluky
  -;PS;stav                                                                     odpoved na potvrzovaci sekvenci
  -;MENUCLICK;text                                                              uzivatel kliknul na polozku v menu s textem text
  -;UPO;OK                                                                      vsechna upozorneni schvalena
  -;UPO;ESC                                                                     upozorneni neschvalena
  -;MOD-CAS;START;                                                              zapnuti modeloveho casu
  -;MOD-CAS;STOP;                                                               vypnuti modleoveho casu
  -;MOD-CAS;TIME;time;nasobic                                                   nastaveni modeloveho casu
  -;DCC;GO                                                                      central start
  -;DCC;STOP                                                                    central stop
  -;SPR-LIST;                                                                   pozadavek na zsikani seznamu souprav v mych oblastech rizeni
  -;SPR-REMOVE;spr_name                                                         pozadavek na smazani soupravy s cislem spr_name
  -;OR-LIST;                                                                    pozadavek na ziskani seznamu OR

  -;LOK;G;AUTH;username;passwd                                                  pozadavek na autorizaci uzivatele regulatoru
  -;LOK;G:PLEASE;or_id;comment                                                  pozadavek na rizeni loko z dane oblasti rizeni
  -;LOK;G:CANCEL;                                                               zruseni pozadavku o loko

  -:LOK;addr;PLEASE;token                                                       zadost o rizeni konkretni lokomotivy; token neni potreba pripojovat v pripade, kdy loko uz mame autorizovane a bylo nam ukradeno napriklad mysi
  -;LOK;addr;RELEASE                                                            uvolneni lokomotivy z rizeni regulatoru
  -;LOK;addr;SP;sp_km/h                                                         nastaveni rychlosti lokomotivy
  -;LOK;addr;SPD;sp_km/h;dir ()                                                 nastaveni rychlosti a smeru lokomotivy
  -;LOK;addr;D;dir ()                                                           nastaveni smeru lokomotivy
  -;LOK;addr;F;F_left-F_right;states                                            nastaveni funkci lokomotivy
                                                                                  napr.; or;LOK;F;0-4;00010 nastavi F3 a ostatni F vypne
  -;LOK;addr;STOP;                                                              nouzove zastaveni
  -;LOK;addr;TOTAL;[0,1]                                                        nastaveni totalniho rizeni hnaciho vozidla

  -;LOK;addr:ASK                                                                tazani se na existenci HV s adresou \addr; pokud existuje, chci o nem vedet data

  -;MTBd;                                                                       MTB debugger, viz MTBdebugger.pas

  or;NUZ;stav                                                                   1 = zapnout NUZ, 0 = vypnout NUZ
  or;GET-ALL;                                                                   pozadavek na zjisteni stavu vsech bloku v prislusne OR
  or;CLICK;block_id;button                                                      klik na blok na panelu
  or;AUTH;opravneni;username;password                                           pozadavek o autorizaci
  or;MSG:recepient;msg                                                          zprava pro recepient od or
  or;HV-LIST;                                                                   pozadavek na ziskani seznamu hnacich vozidel v dane stanici
  or;SPR-CHANGE;vlastosti soupravy dle definice zpravy v TSouprava
      (format: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla)            zmena soupravy
  or;LOK-MOVE-OR;lok_addr;or_id                                                 presun soupravy do jine oblasti rizeni

  or;OSV;SET;code;stav [0,1]                                                    nastaveni stavu osvetleni
  or;OSV;GET;                                                                   ziskani stavu vsech osvetleni

  or;HV;ADD;data                                                                pridani hnaciho vozidla
  or;HV;REMOVE;addr                                                             smazani hnaciho vozdila
  or;HV;EDIT;data                                                               editace hnaciho vozidla

  or;ZAS;VZ                                                                     volba do zasobniku
  or;ZAS;PV                                                                     prima volba
  or;ZAS;EZ;[0,1]                                                               zapnuti/vypnuti editace zasobniku
  or;ZAS;RM;id                                                                  smazani jizdni cesty [id] ze zasobniku
  or;ZAS;UPO                                                                    uzivatel klikl na UPO v zasobniku

  or;DK-CLICK;[L,M,R]                                                           klik na dopravni kancelar prislusnym tlacitkem mysi

  or;LOK-REQ;PLEASE;addr1|addr2|...                                             zadost o vydani tokenu
  or;LOK-REQ;U-PLEASE;blk_id                                                    zadost o vydani seznamu hnacich vozidel na danem useku
  or;LOK-REQ;LOK;addr1|addr2|...                                                lokomotivy pro rucni rizeni na zaklde PLEASE regulatoru vybrany
  or;LOK-REQ;DENY;                                                              odmitnuti pozadavku na rucni rizeni

  -;F-VYZN-ADD;vyznam1;vyznam2;...                                              pridani novych vyznamu funkci
  -;F-VYZN-GET;                                                                 pozadavek na ziskani vyznamu funkci (odpoved F-VYZN-LIST)


////////////////////////////////////////////////////////////////////////////////
/////////////////////////// SERVER -> KLIENT ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
  -;HELLO;verze;                                                                handshake a specifikace komunikacniho protokolu
  -;STIT;blk_name;stitek;                                                       pozadavek na zobrazeni vstupu pro stitek
  -;VYL;blk_name;vyluka;                                                        pozadavek na zobrazeni vstupu pro vyluku
  -;PS;stanice;udalost;sender1|sender2|...;(blok1_name|blok1_podminka)
      (blok2_name|blok2_podminka)(...)...                                       pozadavek na zobrazeni potvrzovaci sekvence
  -;PS-CLOSE;[duvod]                                                            zruseni potvrzovaci sekvence; duvod je nepovinny
  -;MENU;prikaz1,prikaz2,...                                                    pozadavek na zobrazeni MENU
  -;INFOMSG;msg                                                                 zobrazeni notifikace pro dispecera
  -;BOTTOMERR;err;stanice;technologie                                           zobrazeni technologicke chyby
  -;SND;PLAY;code;[delay (ms)]                                                  prehravani zvuku, delay je nepovinny, pokud neni uveden, je zvuk prehran jen jednou
  -;SND;STOP;code                                                               zastaveni prehravani zvuku
  -;OR-LIST;(or1id,or1name)(or2id, ...                                          seznam vsech oblasti rizeni
  -;UPO-CLOSE;                                                                  zavrit upozorneni
  -;UPO;[item1][item2]                                                          otevrit upozorneni
  -;UPO-CRIT;[item1][item2]                                                     kriticke upozorneni - nelze porkacovat dale
      format [item_x]:
          (radek1)(radek2)(radek3)                                                LRM je zarovnani, fg je barva popredi radku, bg je barva pozadi radku a text je text na radku
        radek_x: [L,R,M]|fg|bg|text                                               barvy na dalsich radcich nemusi byt vyplnene, pak prebiraji tu barvu, jako radek predchozi
  -;INFO-TIMER;id;time_min;time_sec;message                                     zobrazit odpocet
  -;INFO-TIMER-RM;id;                                                           smazat odpocet
  -;MOD-CAS;running;nasobic;cas;                                                oznameni o stavu modeloveho casu - aktualni modelovy cas a jestli bezi
  -;DCC;GO                                                                      DCC zapnuto
  -;DCC;STOP                                                                    DCC vypnuto
  -;DCC;DISABLED                                                                neni mozno zmenit stav DCC z tohoto klienta
  -;SPR-LIST;(spr1)(spr2)(...)                                                  odeslani seznamu souprav ve vsech oblastech rizeni daneho panelu
  or;AUTH;rights;comment;username                                               odpoved na pozadavek o autorizaci
  or;MENU;items
                                                                                  pokud je polozka '-', vypisuje se oddelovac
                                                                                  pokud je prvni znak polozky #, pole je disabled
                                                                                  pokud je prvni znak polozky $, pole je vycentrovane a povazovane na nadpis
  or;CAS;START;id;delka_sekundy;                                                pridani mereni casu, id je vzdy unikatni unsigned int, ktery obvykle zacina od 0
  or;CAS;STOP;id;                                                               smazani mereni casu
  or;CHANGE;typ_blk;tech_blk_id;barva_popredi;barva_pozadi;blikani;dalsi argumenty u konkretnich typu bloku:
    typ_blk = cislo podle typu bloku na serveru
      usek : konec_jc;ramecek_color;[souprava;barva_soupravy;sipkaLsipkaS] -  posledni 3 argumenty jsou nepovinne, pokud je ramecek_color string '-', ramecek se nezobrazuje
      vyhybka : poloha (cislo odpovidajici poloze na serveru - [disabled = -5, none = -1, plus = 0, minus = 1, both = 2])
      navestidlo: ab (false = 0, true = 1)
      prejezd: stav (otevreno = 0, vystraha = 1, uzavreno = 2, anulace = 3)
      uvazka: smer (-5 = disabled, 0 = bez smeru, 1 = zakladni, 2 = opacny); soupravy - cisla souprav oddelene carkou (pokid cislo zacina znakem $, ma byt barevne odliseno barvou - predpovidana souprava)
         prvni souprava je vzdy ta, ktere do trati prisla prvni
      zamek: zadne dalsi argumenty
  or;NUZ;stav                                                                   stav in [0, 1, 2] - jestli probiha NUZ na DK - fakticky rika, jeslti ma DK blikat
                                                                                  0 = zadne bloky v NUZ, neblikat
                                                                                  1 = bloky v NUZ, blikat, nabidnout NUZ>
                                                                                  2 = probiha NUZ, neblika, nabidnout NUZ<
  or;MSG:sender;msg                                                             zprava pro or od sender
  or;MSG-ERR;sender;err                                                         chyba pri odesilani zpravy
  or;HV-LIST;[HV1][HV2]                                                         odeslani seznamu hnacich vozidel dane stanice
  or;SPR-NEW;
  or;SPR-EDIT;vlastosti soupravy dle definice zpravy v TSouprava
    (format: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla)              zobrazeni editacniho okna soupravu
  or;SPR-EDIT-ERR;err                                                           chyba pri ukladani supravy po editaci
  or;SPR-EDIT-ACK;                                                              editace soupravy probehla uspesne

  -;OR-LIST;(or1id,or1name)(or2id, ...                                          zaslani seznamu vsech oblasti rizeni

  -;LOK;G:PLEASE-RESP;[ok, err];info                                            odpoved na zadost o lokomotivu z reliefu; v info je pripadna chybova zprava
  -;LOK;G;AUTH;[ok,not,total];info                                              navratove hlaseni o autorizaci
  -;LOK;addr;AUTH;[ok,not,stolen,release];info;hv_data                          odpoved na pozadavek o autorizaci rizeni hnaciho vozidla (odesilano take jako informace o zruseni ovladani hnacicho vozidla)
                                                                                  info je string
                                                                                  hv_data jsou pripojovana k prikazu v pripade, ze doslo uspesne k autorizaci; jedna se o PanelString hnaciho vozdila obsahujici vsechny informace
  -;LOK;addr;F;F_left-F_right;states                                            informace o stavu funkci lokomotivy
                                                                                  napr.; or;LOK;0-4;00010 informuje, ze je zaple F3 a F0, F1, F2 a F4 jsou vyple
  -;LOK;addr;SPD;sp_km/h;sp_stupne;dir                                          informace o zmene rychlosti (ci smeru) lokomotivy
  -;LOK;addr;RESP;[ok, err];info;speed_kmph                                     odpoved na prikaz;  speed_kmph je nepovinny argument; info zpravidla obsahuje rozepsani chyby, pokud je odpoved "ok", info je prazdne
  -;LOK;addr;TOTAL;[0,1]                                                        zmena rucniho rizeni lokomotivy

  -;LOK;addr:FOUND;lok-string                                                   odpoved na existenci hnaciho vozidla s adresou addr
  -;LOK;addr;NOT-FOUND

  -;MTBd;                                                                       MTB debugger, viz MTBdebugger.pas

  -;F-VYZN-LIST;vyznam1;vyznam2;...                                             odeslani seznamu vyznamu funkci

  or;OSV;(code;stav)(code;srav) ...                                             informace o stavu osvetleni (stav = [0,1])

  or;ZAS;VZ                                                                     volba do zasobniku
  or;ZAS;PV                                                                     prima volba
  or;ZAS;LIST;first-enabled[0,1];(id1|name1)(id2|name2) ...                     seznam jizdnich cest v zasobniku
  or;ZAS;FIRST;first-enabled[0,1]                                               jestli je mozno prvni prvek mazat
  or;ZAS;INDEX;index                                                            oznameni indexu zasobniku
  or;ZAS;RM;id                                                                  smazani cesty [id] ze zasobniku
  or;ZAS;ADD;id|name                                                            pridani cesty [id, name] do zasobniku
  or;ZAS;RM;id                                                                  oznameni o smazani cesty ze zasobniku
  or;ZAS;HINT;hint                                                              zmena informacni zpravy vedle zasobniku
  or;ZAS;UPO;[0,1]                                                              1 pokud je UPO klikaci, 0 pokud ne

  or;DK-CLICK;[0, 1];menu                                                       nastavuje, kam posilat info o kliku na DK, 0 = klientoi, 1 = na server; pokud 1, tak se posila i menu DK

  or;RUC;addr;text                                                              informace o rucnim rizeni hnaciho vozdila addr; text se zobrazi jako string v panelu
  or;RUC-RM;addr                                                                smazani informace o rucnim rizeni hnaciho vozidla

  or;LOK-TOKEN;OK;[addr|token][addr|token]                                      odpovìï na žádost o token, je posílano také pøi RUÈ loko
  or;LOK-TOKEN;ERR;comment                                                      chybova odpoved na zadost o token
  or;LOK-REQ;REQ;username;firstname;lastname;comment                            pozadavek na prevzeti loko na rucni rizeni
  or;LOK-REQ;U-OK;[hv1][hv2]...                                                 seznamu hnacich vozidel v danem useku
  or;LOK-REQ;U-ERR;info                                                         chyba odpoved na pozadavek na seznam loko v danem useku
  or;LOK-REQ;OK                                                                 seznam loko na rucni rizeni schvalen serverem
  or;LOK-REQ;ERR;comment                                                        seznam loko na rucni rizeni odmitnut serverem
  or;LOK-REQ;CANCEL;                                                            zruseni pozadavku na prevzeti loko na rucni rizeni
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

{
 Navazani komunikace:
  1) klient se pripoji
  2) klient posle hanshake
  3) klient vycka na odpoved na handshake
  4) klient vysila pozadavek na autorizaci oblasti rizeni
  5) po klientovi muze byt vyzadovano heslo
  5) klient bud dostane, nebo nedostae pristup k prislusnym OR

  username a heslo se zadava vzdy jen jedno
   autorizace pro OR ale prichazi samostatne - pokud jsou na panelu 2 OR, tak uzivatel klidne muze dostat autorizaci jen pro jedno z nich

 rights:
  (null = 0, read = 1, write = 2, superuser = 3); prenasi se pouze cislo

 barva se prenasi jako 3 text, ktery obsahuje 3 sestnactkova cisla = napr. FFAAFF
  poradi barev: RED, GREEN, BLUE
}

uses Panel, fMain, fStitVyl, BottomErrors, Sounds, ORList, fZpravy, Debug, fSprEdit,
      ModelovyCas, fNastaveni_casu, DCC_Icons, fSoupravy, LokoRuc,
      GlobalCOnfig, HVDb, fRegReq, fHVEdit, fHVSearch;

////////////////////////////////////////////////////////////////////////////////

constructor TPanelTCPClient.Create();
begin
 inherited;

 Self.parsed := TStringList.Create;

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
 Self.control_disconnect := true;

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

 if (Assigned(Self.tcpClient)) then
   FreeAndNil(Self.tcpClient);

 if (Assigned(Self.parsed)) then
   FreeAndNil(Self.parsed);

 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

function TPanelTCPClient.Connect(host:string; port:Word):Integer;
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

 // send handshake
 Self.SendLn('-;HELLO;'+Self._PROTOCOL_VERSION+';');
end;//procedure

procedure TPanelTCPClient.OnTcpClientDisconnected(Sender: TObject);
begin
 if Assigned(Self.rthread) then Self.rthread.Terminate;

 Relief.DisableElements();
 TF_Messages.CloseForms();
 if (F_StitVyl.Showing) then F_StitVyl.Close();
 if (F_SoupravaEdit.Showing) then F_SoupravaEdit.Close();
 if (F_PotvrSekv.Showing) then F_PotvrSekv.Close();
 if (F_SprList.Showing) then F_SprList.Close();
 if (F_HVSearch.Showing) then F_HVSearch.Close();

 SoundsPlay.DeleteAll();
 ModCas.Reset();
 F_ModCasSet.Close();
 DCC.status := TDCCStatus.disabled;
 F_Main.SB_Soupravy.Enabled := false;
 RucList.Clear();
 F_RegReq.Close();

 Self.fstatus := TPanelConnectionStatus.closed;

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
 Errors.writeerror('Spojení se serverem pøerušeno', 'KLIENT', '-');
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
     Application.MessageBox(PChar('Verze protokolu, kterou požívá server ('+Self.parsed[2]+') není podporována'),
       'Upozornìní', MB_OK OR MB_ICONWARNING);

   Self.fstatus := TPanelConnectionStatus.opened;
   Self.SendLn('-;OR-LIST;');
   PanelTCPClient.SendLn('-;F-VYZN-GET;');
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
    begin
     if (parsed.Count > 4) then
       SoundsPlay.Play(StrToInt(parsed[3]), StrToInt(parsed[4]))
     else
       SoundsPlay.Play(StrToInt(parsed[3]));
    end;

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
  Self.ParseLokToken()

 else if ((parsed[1] = 'RUC') or (parsed[1] = 'RUC-RM')) then
  RucList.ParseCommand(parsed)

 else if (parsed[1] = 'LOK-REQ') then
  Relief.ORLokReq(parsed[0], parsed);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TPanelTCPClient.ParseLokToken();
var HVs:THVDb;
begin
 if (parsed[2] = 'OK') then
  begin
   if (F_RegReq.token_req_sent) then F_RegReq.ServerResponseOK();

   HVs := THVDb.Create();
   HVs.ParseHVsFromToken(parsed[3]);
   try
     HVs.OpenJerry();
   except
     on E:Exception do
       Errors.writeerror(E.Message, 'Jerry', '');
   end;
   HVs.Free();
  end

 else if (parsed[2] = 'ERR') then
   if (F_RegReq.token_req_sent) then F_RegReq.ServerResponseErr(parsed[3]);
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
begin
  UsekPanelProp.Symbol  := StrToColor(parsed[4]);
  UsekPanelProp.Pozadi  := StrToColor(parsed[5]);
  UsekPanelProp.blikani := StrToBool(parsed[6]);
  UsekPanelProp.KonecJC := TJCType(StrToInt(parsed[7]));

  if (parsed[8] = '-') then
    UsekPanelProp.ramecekColor := clBlack
  else
    UsekPanelProp.ramecekColor := strToColor(parsed[8]);

  if (parsed.Count > 9) then
   begin
    UsekPanelProp.spr     := parsed[9];
    UsekPanelProp.SprC    := StrToColor(parsed[10]);
    if (parsed[11][1] = '1') then
      UsekPanelProp.sipkaL := true
    else
      UsekPanelProp.sipkaL := false;
    if (parsed[11][2] = '1') then
      UsekPanelProp.sipkaS := true
    else
      UsekPanelProp.sipkaS := false;

    if (parsed.Count > 12) then
     UsekPanelProp.sprPozadi := StrToColor(parsed[12])
    else
     UsekPanelProp.sprPozadi := clBlack;
   end else begin
    UsekPanelProp.spr     := '';
    UsekPanelProp.SprC    := clBlack;
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

procedure TPanelTCPClient.PanelClick(Sender:string;blokid:Integer;Button:TPanelButton);
begin
 Self.SendLn(Sender+';CLICK;'+IntToStr(blokid)+';'+IntToStr(Integer(Button))+';');
end;//procedure

procedure TPanelTCPClient.PanelMenuClick(item_hint:string);
begin
 Self.SendLn('-;MENUCLICK;'+item_hint+';');
end;//procedure

procedure TPanelTCPClient.PanelSetStitVyl(typ:Integer; stitvyl:string);
begin
 case (typ) of
  _STITEK: Self.SendLn('-;STIT;{'+stitvyl+'}');
  _VYLUKA: Self.SendLn('-;VYL;{'+stitvyl+'}');
 end;
end;//procedure

procedure TPanelTCPClient.PanelEscape();
begin
 Self.SendLn('-;ESCAPE;');
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
 if (not Self.tcpClient.Connected) then Exit; 

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

initialization
 PanelTCPClient := TPanelTCPClient.Create;

finalization
 FreeAndNil(PanelTCPCLient);

end.//unit
