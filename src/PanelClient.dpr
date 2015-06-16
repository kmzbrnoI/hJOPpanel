program PanelClient;

uses
  Forms,
  Main in 'Main.pas' {F_Main},
  GlobalConfig in 'GlobalConfig.pas',
  Panel in 'Panel.pas',
  PotvrSekv in 'PotvrSekv.pas',
  RPConst in 'RPConst.pas',
  BottomErrors in 'BottomErrors.pas',
  Sounds in 'Sounds.pas',
  SoundsThread in 'SoundsThread.pas',
  TCPClientPanel in 'TCPClientPanel.pas',
  ListeningThread in 'ListeningThread.pas',
  StitVyl in 'StitVyl.pas',
  MenuPanel in 'MenuPanel.pas',
  Symbols in 'Symbols.pas',
  Debug in 'Debug.pas' {F_Debug},
  PGraphics in 'PGraphics.pas',
  settings in 'settings.pas' {F_Settings},
  Splash in 'Splash.pas' {F_splash},
  SprEdit in 'SprEdit.pas' {F_SoupravaEdit},
  SprHelp in 'SprHelp.pas' {F_SprHelp},
  Zpravy in 'Zpravy.pas' {F_Messages},
  ORList in 'ORList.pas',
  Zprava in 'Zprava.pas' {F_Message},
  HVDb in 'HVDb.pas',
  HVMoveSt in 'HVMoveSt.pas' {F_HV_Move},
  SprHVEdit in 'SprHVEdit.pas' {F_SprHVEdit},
  CloseTabSheet in 'CloseTabSheet.pas',
  fAuth in 'fAuth.pas' {F_Auth},
  HVEdit in 'HVEdit.pas' {F_HVEdit},
  HVDelete in 'HVDelete.pas' {F_HVDelete},
  Zasobnik in 'Zasobnik.pas',
  UPO in 'UPO.pas',
  ModelovyCas in 'ModelovyCas.pas',
  Nastaveni_Casu in 'Nastaveni_Casu.pas' {F_ModCasSet},
  DCC_Icons in 'DCC_Icons.pas',
  Soupravy in 'Soupravy.pas' {F_SprList},
  LokoRuc in 'LokoRuc.pas',
  Resuscitation in 'Resuscitation.pas',
  Verze in 'Verze.pas',
  fRegReq in 'fRegReq.pas' {F_RegReq},
  HVPomEdit in 'HVPomEdit.pas' {F_HV_Pom};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Panel klient';
  Application.CreateForm(TF_Main, F_Main);
  Application.CreateForm(TF_splash, F_splash);
  Application.CreateForm(TF_Debug, F_Debug);
  Application.CreateForm(TF_PotvrSekv, F_PotvrSekv);
  Application.CreateForm(TF_StitVyl, F_StitVyl);
  Application.CreateForm(TF_Settings, F_Settings);
  Application.CreateForm(TF_SoupravaEdit, F_SoupravaEdit);
  Application.CreateForm(TF_SprHelp, F_SprHelp);
  Application.CreateForm(TF_Message, F_Message);
  Application.CreateForm(TF_HV_Move, F_HV_Move);
  Application.CreateForm(TF_SprHVEdit, F_SprHVEdit);
  Application.CreateForm(TF_Auth, F_Auth);
  Application.CreateForm(TF_HVEdit, F_HVEdit);
  Application.CreateForm(TF_HVDelete, F_HVDelete);
  Application.CreateForm(TF_ModCasSet, F_ModCasSet);
  Application.CreateForm(TF_SprList, F_SprList);
  Application.CreateForm(TF_RegReq, F_RegReq);
  Application.CreateForm(TF_HV_Pom, F_HV_Pom);
  if (ParamCount > 0) then
    F_Main.Init(ParamStr(1))
  else
    F_Main.Init();

  Application.Run;
end.
