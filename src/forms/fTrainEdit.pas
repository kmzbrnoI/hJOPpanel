unit fTrainEdit;

{
  Train edit window.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Spin, RVDb, RPConst, ComCtrls, fTrainRVEdit, Buttons,
  CloseTabSheet, Themes, Generics.Collections, Types;

const
  _MAX_RV_CNT = 4;
  _ANNONUNCE_TRAIN_FORBIDDEN: array [0 .. 5] of string = ('Pn', 'Mn', 'Vn', 'Lv', 'Vle', 'Slu');

type

  TF_TrainEdit = class(TForm)
    L_S01: TLabel;
    E_Nazev: TEdit;
    B_Save: TButton;
    B_Storno: TButton;
    L_S02: TLabel;
    B_Help: TButton;
    Label1: TLabel;
    SE_PocetVozu: TSpinEdit;
    GB_Sipky: TGroupBox;
    CHB_Sipka_L: TCheckBox;
    CHB_Sipka_S: TCheckBox;
    T_Timeout: TTimer;
    PC_Vehicles: TPageControl;
    BB_RV_Add: TBitBtn;
    Label2: TLabel;
    SE_Delka: TSpinEdit;
    CB_Typ: TComboBox;
    Label3: TLabel;
    M_Poznamka: TMemo;
    Label4: TLabel;
    Label5: TLabel;
    CB_Vychozi: TComboBox;
    Label6: TLabel;
    CB_Cilova: TComboBox;
    SB_st_change: TSpeedButton;
    CHB_report: TCheckBox;
    CHB_MaxSpeed: TCheckBox;
    SE_MaxSpeed: TSpinEdit;
    procedure B_HelpClick(Sender: TObject);
    procedure B_StornoClick(Sender: TObject);
    procedure B_SaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure T_TimeoutTimer(Sender: TObject);
    procedure E_PoznamkaKeyPress(Sender: TObject; var Key: Char);
    procedure BB_RV_AddClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PageControlCloseButtonDrawTab(Control: TCustomTabControl; TabIndex: Integer; const Rect: TRect;
      Active: Boolean);
    procedure PageControlCloseButtonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PageControlCloseButtonMouseLeave(Sender: TObject);
    procedure PageControlCloseButtonMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PageControlCloseButtonMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SB_st_changeClick(Sender: TObject);
    procedure CB_TypChange(Sender: TObject);
    procedure CHB_MaxSpeedClick(Sender: TObject);
  private
    OblR: string;
    RVs: TObjectList<TF_TrainRVEdit>;
    RVDb: TRVDb;
    trainRVs: TRVDb;

    FCloseButtonMouseDownTab: TCloseTabSheet;
    FCloseButtonShowPushed: Boolean;

    procedure OnTabClose(Sender: TObject);
    procedure FillORs(vychoziId: string; cilovaId: string);

  public

    procedure NewTrain(RVs: TRVDb; Sender: string);
    procedure EditTrain(parsed: TStrings; RVs: TRVDb; sender_id: string; owner: string);

    procedure TechError(err: string);
    procedure TechACK();

  end;

var
  F_TrainEdit: TF_TrainEdit;

implementation

uses fTrainHelp, fMain, TCPClientPanel, ORList, IfThenElse;

// format dat vlaku: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla;vychozi stanice;cilova stanice

{$R *.dfm}
/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.E_PoznamkaKeyPress(Sender: TObject; var Key: Char);
begin
  for var i := 0 to Length(_forbidden_chars) - 1 do
    if (_forbidden_chars[i] = Key) then
    begin
      Key := #0;
      Exit();
    end;
end;

procedure TF_TrainEdit.BB_RV_AddClick(Sender: TObject);
begin
  if (Self.PC_Vehicles.PageCount >= _MAX_RV_CNT) then
  begin
    Application.MessageBox('Více vozidel nelze přidat', 'Nelze přidat další vozidlo', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  var ts := TCloseTabSheet.Create(Self.PC_Vehicles);
  ts.Caption := 'Vozidlo ' + IntToStr(Self.PC_Vehicles.PageCount + 1);

  ts.PageControl := Self.PC_Vehicles;
  ts.OnClose := Self.OnTabClose;
  Self.PC_Vehicles.ActivePage := ts;

  var form := TF_TrainRVEdit.Create(ts);
  form.Parent := ts;
  form.Show();
  Self.RVs.Add(form);

  form.FillRV(Self.RVDb, nil);

  if (Self.PC_Vehicles.PageCount >= _MAX_RV_CNT) then
    Self.BB_RV_Add.Enabled := false;
end;

procedure TF_TrainEdit.B_HelpClick(Sender: TObject);
begin
  F_TrainHelp.Show();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.NewTrain(RVs: TRVDb; Sender: string);
begin
  Self.RVDb := RVs;
  Self.OblR := Sender;

  Self.E_Nazev.Text := '';
  Self.SE_PocetVozu.Value := 0;
  Self.CHB_Sipka_L.Checked := false;
  Self.CHB_Sipka_S.Checked := false;

  Self.BB_RV_Add.Enabled := true;

  Self.SE_Delka.Value := 0;
  Self.CB_Typ.Text := '';
  Self.M_Poznamka.Text := '';
  Self.CHB_MaxSpeed.Checked := false;
  Self.CHB_MaxSpeedClick(Self);
  Self.CHB_report.Enabled := true;
  Self.CHB_report.Checked := false;

  Self.FillORs(Sender, '');
  Self.CB_Cilova.ItemIndex := 0;

  // smazat vsechny zalozky
  Self.RVs.Clear();

  for var i := Self.PC_Vehicles.PageCount - 1 downto 0 do
    Self.PC_Vehicles.Pages[i].Free();

  // vytvorit 1 zalozku
  var ts := TCloseTabSheet.Create(Self.PC_Vehicles);
  ts.PageControl := Self.PC_Vehicles;
  ts.Caption := 'Vozidlo 1';
  ts.OnClose := OnTabClose;

  var form := TF_TrainRVEdit.Create(ts);
  form.Parent := ts;
  form.Show();
  Self.RVs.Add(form);

  form.FillRV(RVs, nil);

  Self.ActiveControl := Self.E_Nazev;
  Self.Caption := 'Nový vlak';
  Self.Show();
end;

/// /////////////////////////////////////////////////////////////////////////////

// format dat vlaku: nazev;pocet_vozu;poznamka;smer_Lsmer_S;delka;typ;hnaci vozidla;vychozi stanice;cilova stanice
procedure TF_TrainEdit.EditTrain(parsed: TStrings; RVs: TRVDb; sender_id: string; owner: string);
begin
  Self.RVDb := RVs;
  Self.OblR := sender_id;

  try
    Self.E_Nazev.Text := parsed[2];
    Self.SE_PocetVozu.Value := StrToInt(parsed[3]);
    Self.M_Poznamka.Text := parsed[4];

    Self.CHB_Sipka_L.Checked := (parsed[5][1] = '1');
    Self.CHB_Sipka_S.Checked := (parsed[5][2] = '1');

    Self.SE_Delka.Value := StrToInt(parsed[6]);
    Self.CB_Typ.Text := parsed[7];

    if (parsed.Count > 10) then
      Self.FillORs(parsed[9], parsed[10])
    else
    begin
      Self.FillORs('', '');
      Self.CB_Vychozi.ItemIndex := 0;
      Self.CB_Cilova.ItemIndex := 0;
    end;

    Self.CHB_report.Enabled := (parsed.Count > 11);
    if (parsed.Count > 11) then
      Self.CHB_report.Checked := (parsed[11] = '1')
    else
      Self.CHB_report.Checked := false;

    Self.CHB_MaxSpeed.Checked := ((parsed.Count > 12) and (parsed[12] <> ''));
    Self.CHB_MaxSpeedClick(Self);
    if ((parsed.Count > 12) and (parsed[12] <> '')) then
      Self.SE_MaxSpeed.Value := StrToInt(parsed[12]);

    Self.trainRVs.ParseRVs(parsed[8]);
  except
    Application.MessageBox('Neplatný formát dat vlaku !', 'Nelze editovat vlak', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  // smazat vsechny zalozky
  Self.RVs.Clear();

  for var i := Self.PC_Vehicles.PageCount - 1 downto 0 do
    Self.PC_Vehicles.Pages[i].Free();

  // vytvorit zalozky podle poctu vozidel
  for var i := 0 to Self.trainRVs.Count - 1 do
  begin
    var ts := TCloseTabSheet.Create(Self.PC_Vehicles);
    ts.PageControl := Self.PC_Vehicles;
    ts.Caption := 'Vozidlo ' + IntToStr(i + 1);
    ts.OnClose := OnTabClose;

    var form := TF_TrainRVEdit.Create(ts);
    form.Parent := ts;
    form.Show();
    Self.RVs.Add(form);

    form.FillRV(RVs, Self.trainRVs[i]);
  end; // for i

  Self.BB_RV_Add.Enabled := (Self.trainRVs.Count < _MAX_RV_CNT);

  Self.ActiveControl := Self.E_Nazev;
  Self.Caption := 'Vlak ' + Self.E_Nazev.Text + ' – ' + owner;
  Self.Show();
end;

/// /////////////////////////////////////////////////////////////////////////////

// format dat vlaku: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla;vychozi stanice;cilova stanice
procedure TF_TrainEdit.B_SaveClick(Sender: TObject);
begin
  if (Self.E_Nazev.Text = '') then
  begin
    Application.MessageBox('Vyplňte název vlaku!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  // kontrola M_Poznamka
  for var j := 0 to Length(_forbidden_chars) - 1 do
  begin
    if (StrScan(PChar(Self.M_Poznamka.Text), _forbidden_chars[j]) <> nil) then
    begin
      Application.MessageBox(PChar('Poznámka k vlaku obsahuje zakázané znaky!' + #13#10 + 'Zakázané znaky: ' +
        GetForbidderChars()), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
      Exit();
    end;
  end;

  if ((Self.CHB_report.Checked) and ((Self.CB_Vychozi.ItemIndex < 1) or (Self.CB_Cilova.ItemIndex < 1))) then
  begin
    Application.MessageBox('Pro staniční hlášení musí být vyplněna výchozí a cílová stanice!', 'Nelze pokračovat',
      MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  if ((Self.CHB_report.Checked) and (Self.CB_Typ.Text = '')) then
  begin
    Application.MessageBox('Pro staniční hlášení musí být vyplněn typ vlaku!', 'Nelze pokračovat',
      MB_OK OR MB_ICONWARNING);
    Exit();
  end;
  if ((Self.CHB_MaxSpeed.Checked) and (Self.SE_MaxSpeed.Value < 10)) then
  begin
    Application.MessageBox('Omezení na maximální rychlost vlaku musí být alespoň 10 km/h!', 'Nelze pokračovat',
      MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  var sprstr := Self.E_Nazev.Text + ';' + IntToStr(Self.SE_PocetVozu.Value) + ';{' + Self.M_Poznamka.Text + '};';

  sprstr := sprstr + BoolToStr10(Self.CHB_Sipka_L.Checked);
  sprstr := sprstr + BoolToStr10(Self.CHB_Sipka_S.Checked) + ';';
  sprstr := sprstr + IntToStr(Self.SE_Delka.Value) + ';' + Self.CB_Typ.Text + ';';
  sprstr := sprstr + '{';

  var err := '';
  var cannotMultitrack: TRV := nil;
  var noNonCarEngines: Cardinal := 0;
  for var i := 0 to Self.PC_Vehicles.PageCount - 1 do
  begin
    if (Self.RVs[i].vehicle = nil) then
    begin
      Application.MessageBox(PChar('Vyberte vozidlo vlaku na záložce ' + Self.PC_Vehicles.Pages[i].Caption),
        'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
      Exit();
    end;
    if (Self.RVs[i].RG_direction.ItemIndex < 0) then
    begin
      Application.MessageBox(PChar('Vyberte orientaci stanoviště A vozidla na záložce ' + Self.PC_Vehicles.Pages[i]
        .Caption), 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
      Exit();
    end;
    for var j := 0 to Length(_forbidden_chars) - 1 do
    begin
      if (StrScan(PChar(Self.RVs[i].M_note.Text), _forbidden_chars[j]) <> nil) then
      begin
        Application.MessageBox(PChar('Poznámka k vozidlu obsahuje zakázané znaky!' + #13#10 + 'Zakázané znaky: '
          + GetForbidderChars()), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
      end;
    end;

    for var j := 0 to _MAX_FUNC do
      if ((Self.RVs[i].vehicle.funcType[j] = TRVFuncType.momentary) and (Self.RVs[i].CHB_funkce[j].Checked)) then
        err := err + Self.PC_Vehicles.Pages[i].Caption + ' má aktivovanou funkci ' + IntToStr(j) + ' (' +
          Self.RVs[i].vehicle.funcDesc[j] + '), která je momentary.' + #13#10;

    if ((cannotMultitrack = nil) and (not Self.RVs[i].vehicle.multitrackCapable)) then
    begin
      cannotMultitrack := Self.RVs[i].vehicle;
      Inc(noNonCarEngines);
    end else if (Self.RVs[i].vehicle.typ <> TRVType.car) then
      Inc(noNonCarEngines);

    sprstr := sprstr + Self.RVs[i].GetRVString();
  end;

  if ((cannotMultitrack <> nil) and (noNonCarEngines >= 2)) then
  begin
    Application.MessageBox(PChar('Vozidlo '+IntToStr(cannotMultitrack.addr)+' je označené jako nezpůsobilé multritrakce!'), 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  if (err <> '') then
    if (Application.MessageBox(PChar(err + 'Skutečně chcete pokračovat?'), 'Pokračovat?', MB_YESNO OR MB_ICONQUESTION OR
      MB_DEFBUTTON2) <> mrYes) then
      Exit();

  sprstr := sprstr + '};';

  if (Self.CB_Vychozi.ItemIndex > 0) then
    sprstr := sprstr + areaDb.db_reverse[CB_Vychozi.Items[CB_Vychozi.ItemIndex]];
  sprstr := sprstr + ';';

  if (Self.CB_Cilova.ItemIndex > 0) then
    sprstr := sprstr + areaDb.db_reverse[CB_Cilova.Items[CB_Cilova.ItemIndex]];
  sprstr := sprstr + ';';

  sprstr := sprstr + BoolToStr10(Self.CHB_report.Checked) + ';';

  if (Self.CHB_MaxSpeed.Checked) then
    sprstr := sprstr + IntToStr(Self.SE_MaxSpeed.Value) + ';'
  else
    sprstr := sprstr + ';';

  PanelTCPClient.PanelSprChange(Self.OblR, sprstr);

  Screen.Cursor := crHourGlass;
  Self.T_Timeout.Enabled := true;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.B_StornoClick(Sender: TObject);
begin
  Relief.Escape();
  Self.Close();
end;

procedure TF_TrainEdit.CB_TypChange(Sender: TObject);
begin
  if (not Self.CHB_report.Enabled) then
    Exit();

  for var s in _ANNONUNCE_TRAIN_FORBIDDEN do
  begin
    if (Self.CB_Typ.Text = s) then
    begin
      CHB_report.Checked := false;
      Exit();
    end;
  end;

  CHB_report.Checked := true;
end;

procedure TF_TrainEdit.CHB_MaxSpeedClick(Sender: TObject);
begin
  Self.SE_MaxSpeed.Enabled := Self.CHB_MaxSpeed.Checked;
  if (not Self.CHB_MaxSpeed.Checked) then
    Self.SE_MaxSpeed.Value := 0;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Self.RVDb := nil;

  Self.RVs.Clear();
  for var i := Self.PC_Vehicles.PageCount - 1 downto 0 do
    Self.PC_Vehicles.Pages[i].Free();
end;

procedure TF_TrainEdit.FormCreate(Sender: TObject);
begin
  Self.RVs := TObjectList<TF_TrainRVEdit>.Create();

  Self.PC_Vehicles.TabWidth := 75;
  Self.PC_Vehicles.OwnerDraw := true;

  Self.trainRVs := TRVDb.Create();
end;

procedure TF_TrainEdit.FormDestroy(Sender: TObject);
begin
  // smazeme zalozky pro hnaci vozidla
  Self.RVs.Free();

  for var i := Self.PC_Vehicles.PageCount - 1 downto 0 do
    Self.PC_Vehicles.Pages[i].Free();

  FreeAndNil(Self.trainRVs);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.TechError(err: string);
begin
  Screen.Cursor := crDefault;
  Self.T_Timeout.Enabled := false;
  Application.MessageBox(PChar('Technologický server odpověděl chybou:' + #13#10 + err), 'Varování',
    MB_OK OR MB_ICONWARNING);
end;

procedure TF_TrainEdit.T_TimeoutTimer(Sender: TObject);
begin
  Self.T_Timeout.Enabled := false;
  Screen.Cursor := crDefault;
  Application.MessageBox('Technologický server neodpověděl na požadavek o editaci vlaku', 'Varování',
    MB_OK OR MB_ICONWARNING);
end;

procedure TF_TrainEdit.TechACK();
begin
  Screen.Cursor := crDefault;
  Relief.ORInfoMsg('Vlak uložen');
  Self.T_Timeout.Enabled := false;
  Self.Close();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.PageControlCloseButtonDrawTab(Control: TCustomTabControl; TabIndex: Integer;
  const Rect: TRect; Active: Boolean);
var
  CloseBtnSize: Integer;
  PageControl: TPageControl;
  TabSheet: TCloseTabSheet;
  TabCaption: TPoint;
  CloseBtnRect: TRect;
  CloseBtnDrawState: Cardinal;
  CloseBtnDrawDetails: TThemedElementDetails;
begin
  PageControl := Control as TPageControl;
  TabCaption.Y := Rect.Top + 3;

  if Active then
  begin
    CloseBtnRect.Top := Rect.Top + 4;
    CloseBtnRect.Right := Rect.Right - 5;
    TabCaption.X := Rect.Left + 6;
  end else begin
    CloseBtnRect.Top := Rect.Top + 3;
    CloseBtnRect.Right := Rect.Right - 5;
    TabCaption.X := Rect.Left + 3;
  end;

  if (PageControl.Pages[TabIndex] is TCloseTabSheet) then
  begin
    TabSheet := PageControl.Pages[TabIndex] as TCloseTabSheet;
    CloseBtnSize := 14;

    CloseBtnRect.Bottom := CloseBtnRect.Top + CloseBtnSize;
    CloseBtnRect.Left := CloseBtnRect.Right - CloseBtnSize;
    TabSheet.FCloseButtonRect := CloseBtnRect;

    PageControl.Canvas.FillRect(Rect);
    PageControl.Canvas.TextOut(TabCaption.X, TabCaption.Y, PageControl.Pages[TabIndex].Caption);

    if not StyleServices.Enabled then
    begin
      if (FCloseButtonMouseDownTab = TabSheet) and FCloseButtonShowPushed then
        CloseBtnDrawState := DFCS_CAPTIONCLOSE + DFCS_PUSHED
      else
        CloseBtnDrawState := DFCS_CAPTIONCLOSE;

      Windows.DrawFrameControl(PageControl.Canvas.Handle, TabSheet.FCloseButtonRect, DFC_CAPTION, CloseBtnDrawState);
    end else begin
      Dec(TabSheet.FCloseButtonRect.Left);

      if (FCloseButtonMouseDownTab = TabSheet) and FCloseButtonShowPushed then
        CloseBtnDrawDetails := StyleServices.GetElementDetails(twCloseButtonPushed)
      else
        CloseBtnDrawDetails := StyleServices.GetElementDetails(twCloseButtonNormal);

      StyleServices.DrawElement(PageControl.Canvas.Handle, CloseBtnDrawDetails, TabSheet.FCloseButtonRect);
    end;
  end else begin
    PageControl.Canvas.FillRect(Rect);
    PageControl.Canvas.TextOut(TabCaption.X, TabCaption.Y, PageControl.Pages[TabIndex].Caption);
  end;
end;

procedure TF_TrainEdit.PageControlCloseButtonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  PageControl: TPageControl;
  TabSheet: TCloseTabSheet;
begin
  PageControl := Sender as TPageControl;

  if Button = mbLeft then
  begin
    for var i := 0 to PageControl.PageCount - 1 do
    begin
      if not(PageControl.Pages[i] is TCloseTabSheet) then
        Continue;
      TabSheet := PageControl.Pages[i] as TCloseTabSheet;
      if PtInRect(TabSheet.FCloseButtonRect, Point(X, Y)) then
      begin
        FCloseButtonMouseDownTab := TabSheet;
        FCloseButtonShowPushed := true;
        PageControl.Repaint;
      end;
    end;
  end;
end;

procedure TF_TrainEdit.PageControlCloseButtonMouseLeave(Sender: TObject);
var
  PageControl: TPageControl;
begin
  PageControl := Sender as TPageControl;
  FCloseButtonShowPushed := false;
  PageControl.Repaint;
end;

procedure TF_TrainEdit.PageControlCloseButtonMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  PageControl: TPageControl;
  Inside: Boolean;
begin
  PageControl := Sender as TPageControl;

  if (ssLeft in Shift) and Assigned(FCloseButtonMouseDownTab) then
  begin
    Inside := PtInRect(FCloseButtonMouseDownTab.FCloseButtonRect, Point(X, Y));

    if FCloseButtonShowPushed <> Inside then
    begin
      FCloseButtonShowPushed := Inside;
      PageControl.Repaint;
    end;
  end;
end;

procedure TF_TrainEdit.PageControlCloseButtonMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  PageControl: TPageControl;
begin
  PageControl := Sender as TPageControl;

  if (Button = mbLeft) and Assigned(FCloseButtonMouseDownTab) then
  begin
    if PtInRect(FCloseButtonMouseDownTab.FCloseButtonRect, Point(X, Y)) then
    begin
      FCloseButtonMouseDownTab.DoClose;
      FCloseButtonMouseDownTab := nil;
      PageControl.Repaint;
    end;
  end;
end;

procedure TF_TrainEdit.SB_st_changeClick(Sender: TObject);
var tmp: Integer;
begin
  tmp := Self.CB_Cilova.ItemIndex;
  Self.CB_Cilova.ItemIndex := Self.CB_Vychozi.ItemIndex;
  Self.CB_Vychozi.ItemIndex := tmp;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.OnTabClose(Sender: TObject);
begin
  for var i := 0 to Self.PC_Vehicles.PageCount - 1 do
  begin
    if (Self.PC_Vehicles.Pages[i] = Sender) then
    begin
      Self.RVs.Delete(i);

      // preradime vozidlo z vlaku do obecneho seznamu vozidel
      if (i < Self.trainRVs.Count) then
      begin
        for var vehicle in Self.RVDb do
          if (vehicle.addr = Self.trainRVs[i].addr) then
            vehicle.train := '-';
        Self.trainRVs.Delete(i);
      end;

      break;
    end;
  end;

  (Sender as TTabSheet).Free();
  Self.BB_RV_Add.Enabled := true;

  for var i := 0 to Self.PC_Vehicles.PageCount - 1 do
  begin
    Self.PC_Vehicles.Pages[i].Caption := 'Vozidlo ' + IntToStr(i + 1);
    if (i < Self.trainRVs.Count) then
      Self.RVs[i].FillRV(Self.RVDb, Self.trainRVs[i])
    else
      Self.RVs[i].FillRV(Self.RVDb, nil);
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainEdit.FillORs(vychoziId: string; cilovaId: string);
var name: string;
begin
  Self.CB_Vychozi.Clear();
  Self.CB_Cilova.Clear();

  Self.CB_Vychozi.Items.Add('Nevyplněno');
  Self.CB_Cilova.Items.Add('Nevyplněno');

  for name in areaDb.names_sorted do
  begin
    Self.CB_Vychozi.Items.Add(name);
    Self.CB_Cilova.Items.Add(name);

    if (areaDb.db_reverse[name] = vychoziId) then
      Self.CB_Vychozi.ItemIndex := Self.CB_Vychozi.Items.Count - 1;

    if (areaDb.db_reverse[name] = cilovaId) then
      Self.CB_Cilova.ItemIndex := Self.CB_Cilova.Items.Count - 1;
  end;

  if (Self.CB_Vychozi.ItemIndex < 0) then
    Self.CB_Vychozi.ItemIndex := 0;

  if (Self.CB_Cilova.ItemIndex < 0) then
    Self.CB_Cilova.ItemIndex := 0;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
