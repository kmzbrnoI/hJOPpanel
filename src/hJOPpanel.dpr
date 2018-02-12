// JCL_DEBUG_EXPERT_INSERTJDBG OFF
program hJOPpanel;

uses
  Forms,
  fMain in 'fMain.pas' {F_Main},
  GlobalConfig in 'GlobalConfig.pas',
  Panel in 'Panel.pas',
  fPotvrSekv in 'fPotvrSekv.pas',
  RPConst in 'RPConst.pas',
  BottomErrors in 'BottomErrors.pas',
  Sounds in 'Sounds.pas',
  SoundsThread in 'SoundsThread.pas',
  TCPClientPanel in 'TCPClientPanel.pas',
  ListeningThread in 'ListeningThread.pas',
  fStitVyl in 'fStitVyl.pas',
  MenuPanel in 'MenuPanel.pas',
  Symbols in 'Symbols.pas',
  Debug in 'Debug.pas' {F_Debug},
  PGraphics in 'PGraphics.pas',
  fSettings in 'fSettings.pas' {F_Settings},
  fSplash in 'fSplash.pas' {F_splash},
  fSprEdit in 'fSprEdit.pas' {F_SoupravaEdit},
  fSprHelp in 'fSprHelp.pas' {F_SprHelp},
  fZpravy in 'fZpravy.pas' {F_Messages},
  ORList in 'ORList.pas',
  fZprava in 'fZprava.pas' {F_Message},
  HVDb in 'HVDb.pas',
  fHVMoveSt in 'fHVMoveSt.pas' {F_HV_Move},
  fSprHVEdit in 'fSprHVEdit.pas' {F_SprHVEdit},
  CloseTabSheet in 'CloseTabSheet.pas',
  fAuth in 'fAuth.pas' {F_Auth},
  fHVEdit in 'fHVEdit.pas' {F_HVEdit},
  fHVDelete in 'fHVDelete.pas' {F_HVDelete},
  Zasobnik in 'Zasobnik.pas',
  UPO in 'UPO.pas',
  ModelovyCas in 'ModelovyCas.pas',
  fNastaveni_Casu in 'fNastaveni_Casu.pas' {F_ModCasSet},
  DCC_Icons in 'DCC_Icons.pas',
  fSoupravy in 'fSoupravy.pas' {F_SprList},
  LokoRuc in 'LokoRuc.pas',
  Resuscitation in 'Resuscitation.pas',
  Verze in 'Verze.pas',
  fRegReq in 'fRegReq.pas' {F_RegReq},
  fHVPomEdit in 'fHVPomEdit.pas' {F_HV_Pom},
  Hash in 'Hash.pas',
  fHVSearch in 'fHVSearch.pas' {F_HVSearch},
  uLIclient in 'uLIclient.pas',
  LokTokens in 'LokTokens.pas',
  fSprToSlot in 'fSprToSlot.pas' {F_SprToSlot},
  InterProcessCom in 'InterProcessCom.pas',
  parseHelper in 'parseHelper.pas',
  PanelPainter in 'PanelPainter.pas',
  BlokUvazka in 'BlokUvazka.pas',
  BlokUvazkaSpr in 'BlokUvazkaSpr.pas',
  BlokZamek in 'BlokZamek.pas',
  BlokPrejezd in 'BlokPrejezd.pas',
  BlokUsek in 'BlokUsek.pas',
  PanelOR in 'PanelOR.pas',
  BlokVyhybka in 'BlokVyhybka.pas',
  BlokNavestidlo in 'BlokNavestidlo.pas',
  BlokyUsek in 'BlokyUsek.pas',
  BlokyVyhybka in 'BlokyVyhybka.pas',
  BlokVykolejka in 'BlokVykolejka.pas',
  BlokRozp in 'BlokRozp.pas',
  BlokPopisek in 'BlokPopisek.pas',
  BlokPomocny in 'BlokPomocny.pas',
  BlokTypes in 'BlokTypes.pas';

{$R *.res}

begin
  Randomize();

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'hJOPpanel';
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
  Application.CreateForm(TF_HVSearch, F_HVSearch);
  Application.CreateForm(TF_SprToSlot, F_SprToSlot);
  if (ParamCount > 0) then
    F_Main.Init(ParamStr(1))
  else
    F_Main.Init();

  Application.Run;
end.
