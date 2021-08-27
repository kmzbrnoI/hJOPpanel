// JCL_DEBUG_EXPERT_INSERTJDBG OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
program hJOPpanel;

uses
  Forms,
  SysUtils,
  fMain in 'forms\fMain.pas' {F_Main},
  GlobalConfig in 'GlobalConfig.pas',
  Panel in 'panel\Panel.pas',
  fPotvrSekv in 'forms\fPotvrSekv.pas',
  RPConst in 'RPConst.pas',
  BottomErrors in 'panel\BottomErrors.pas',
  Sounds in 'Sounds.pas',
  SoundsThread in 'SoundsThread.pas',
  TCPClientPanel in 'net\TCPClientPanel.pas',
  ListeningThread in 'net\ListeningThread.pas',
  fStitVyl in 'forms\fStitVyl.pas',
  MenuPanel in 'panel\MenuPanel.pas',
  Symbols in 'panel\Symbols.pas',
  fDebug in 'forms\fDebug.pas' {F_Debug},
  PGraphics in 'panel\PGraphics.pas',
  fSettings in 'forms\fSettings.pas' {F_Settings},
  fSplash in 'forms\fSplash.pas' {F_splash},
  fSprEdit in 'forms\fSprEdit.pas' {F_SoupravaEdit},
  fSprHelp in 'forms\fSprHelp.pas' {F_SprHelp},
  fZpravy in 'forms\fZpravy.pas' {F_Messages},
  ORList in 'ORList.pas',
  fZprava in 'forms\fZprava.pas' {F_Message},
  HVDb in 'HVDb.pas',
  fHVMoveSt in 'forms\fHVMoveSt.pas' {F_HV_Move},
  fSprHVEdit in 'forms\fSprHVEdit.pas' {F_SprHVEdit},
  CloseTabSheet in 'CloseTabSheet.pas',
  fAuth in 'forms\fAuth.pas' {F_Auth},
  fHVEdit in 'forms\fHVEdit.pas' {F_HVEdit},
  fHVDelete in 'forms\fHVDelete.pas' {F_HVDelete},
  Zasobnik in 'panel\Zasobnik.pas',
  UPO in 'panel\UPO.pas',
  ModelovyCas in 'ModelovyCas.pas',
  fNastaveni_Casu in 'forms\fNastaveni_Casu.pas' {F_ModelTIme},
  DCC_Icons in 'DCC_Icons.pas',
  fSoupravy in 'forms\fSoupravy.pas' {F_SprList},
  LokoRuc in 'LokoRuc.pas',
  Resuscitation in 'net\Resuscitation.pas',
  Verze in 'Verze.pas',
  fRegReq in 'forms\fRegReq.pas' {F_RegReq},
  fHVPomEdit in 'forms\fHVPomEdit.pas' {F_HV_Pom},
  Hash in 'Hash.pas',
  fHVSearch in 'forms\fHVSearch.pas' {F_HVSearch},
  uLIclient in 'net\uLIclient.pas',
  LokTokens in 'LokTokens.pas',
  fSprToSlot in 'forms\fSprToSlot.pas' {F_SprToSlot},
  InterProcessCom in 'InterProcessCom.pas',
  parseHelper in 'net\parseHelper.pas',
  BlokUvazka in 'bloky\BlokUvazka.pas',
  BlokUvazkaSpr in 'bloky\BlokUvazkaSpr.pas',
  BlokZamek in 'bloky\BlokZamek.pas',
  BlokPrejezd in 'bloky\BlokPrejezd.pas',
  BlokUsek in 'bloky\BlokUsek.pas',
  PanelOR in 'PanelOR.pas',
  BlokVyhybka in 'bloky\BlokVyhybka.pas',
  BlokNavestidlo in 'bloky\BlokNavestidlo.pas',
  BlokyUsek in 'bloky\BlokyUsek.pas',
  BlokyVyhybka in 'bloky\BlokyVyhybka.pas',
  BlokVykolejka in 'bloky\BlokVykolejka.pas',
  BlokRozp in 'bloky\BlokRozp.pas',
  BlokPopisek in 'bloky\BlokPopisek.pas',
  BlokPomocny in 'bloky\BlokPomocny.pas',
  BlokTypes in 'bloky\BlokTypes.pas',
  fOdlozeniOdjezdu in 'forms\fOdlozeniOdjezdu.pas' {F_OOdj};

{$R *.res}

begin
  Randomize();

  FormatSettings.DecimalSeparator := '.';

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
  Application.CreateForm(TF_ModelTIme, F_ModelTIme);
  Application.CreateForm(TF_SprList, F_SprList);
  Application.CreateForm(TF_RegReq, F_RegReq);
  Application.CreateForm(TF_HV_Pom, F_HV_Pom);
  Application.CreateForm(TF_HVSearch, F_HVSearch);
  Application.CreateForm(TF_SprToSlot, F_SprToSlot);
  Application.CreateForm(TF_OOdj, F_OOdj);
  if (ParamCount > 0) then
    F_Main.Init(ParamStr(1))
  else
    F_Main.Init();

  Application.Run;
end.
