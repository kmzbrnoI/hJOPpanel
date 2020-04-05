﻿unit fSprEdit;

{
  Okno editace soupravy.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Spin, HVDb, RPConst, ComCtrls, fSprHVEdit, Buttons,
  CloseTabSheet, Themes, Generics.Collections;

const
  _MAX_HV_CNT = 4;

  _HLASENI_SPRTYP_FORBIDDEN: array [0..5] of string = (
    'Pn', 'Mn', 'Vn', 'Lv', 'Vle', 'Slu'
  );

type

  TF_SoupravaEdit = class(TForm)
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
    PC_HVs: TPageControl;
    BB_HV_Add: TBitBtn;
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
    procedure B_HelpClick(Sender: TObject);
    procedure B_StornoClick(Sender: TObject);
    procedure B_SaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure T_TimeoutTimer(Sender: TObject);
    procedure E_PoznamkaKeyPress(Sender: TObject; var Key: Char);
    procedure BB_HV_AddClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PageControlCloseButtonDrawTab(Control: TCustomTabControl;
      TabIndex: Integer; const Rect: TRect; Active: Boolean);
    procedure PageControlCloseButtonMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PageControlCloseButtonMouseLeave(Sender: TObject);
    procedure PageControlCloseButtonMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer);
    procedure PageControlCloseButtonMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SB_st_changeClick(Sender: TObject);
    procedure CB_TypChange(Sender: TObject);
  private
    OblR:string;
    HVs:TObjectList<TF_SprHVEdit>;
    HVDb:THVDb;
    sprHVs:THVDb;

    FCloseButtonMouseDownTab: TCloseTabSheet;
    FCloseButtonShowPushed: Boolean;

    procedure OnTabClose(Sender:TObject);
    procedure FillORs(vychoziId:string; cilovaId:string);

  public

    procedure NewSpr(HVs:THVDb; sender:string);
    procedure EditSpr(parsed:TStrings; HVs:THVDb; sender_id:string; owner:string);

    procedure TechError(err:string);
    procedure TechACK();

  end;

var
  F_SoupravaEdit: TF_SoupravaEdit;

implementation

uses fSprHelp, fMain, TCPClientPanel, ORList;

// format dat soupravy: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla;vychozi stanice;cilova stanice

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.E_PoznamkaKeyPress(Sender: TObject; var Key: Char);
var i:Integer;
begin
 // osetreni vstupu
 for i := 0 to Length(_forbidden_chars)-1 do
   if (_forbidden_chars[i] = Key) then
     begin
      Key := #0;
      Exit();
     end;
end;

procedure TF_SoupravaEdit.BB_HV_AddClick(Sender: TObject);
var ts:TCloseTabSheet;
    form:TF_SprHVEdit;
begin
 if (Self.PC_HVs.PageCount >= _MAX_HV_CNT) then
  begin
   Application.MessageBox('Více HV nelze přidat', 'Nelze přidat další HV', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 ts := TCloseTabSheet.Create(Self.PC_HVs);
 ts.Caption := 'HV ' + IntToStr(Self.PC_HVs.PageCount+1);

 ts.PageControl := Self.PC_HVs;
 ts.OnClose     := Self.OnTabClose;
 Self.PC_HVs.ActivePage := ts;

 form := TF_SprHVEdit.Create(TS);
 form.Parent := TS;
 form.Show();
 Self.HVs.Add(form);

 form.FillHV(Self.HVDb, nil);

 if (Self.PC_HVs.PageCount >= _MAX_HV_CNT) then
   Self.BB_HV_Add.Enabled := false;
end;

procedure TF_SoupravaEdit.B_HelpClick(Sender: TObject);
 begin
  F_SprHelp.Show();
 end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.NewSpr(HVs:THVDb; sender:string);
var i:Integer;
    ts:TCloseTabSheet;
    form:TF_SprHVEdit;
begin
 Self.HVDb := HVs;
 Self.OblR := sender;

 Self.E_Nazev.Text := '';
 Self.SE_PocetVozu.Value := 0;
 Self.CHB_Sipka_L.Checked := false;
 Self.CHB_Sipka_S.Checked := false;

 Self.BB_HV_Add.Enabled := true;

 Self.SE_Delka.Value  := 0;
 Self.CB_Typ.Text     := '';
 Self.M_Poznamka.Text := '';
 Self.CHB_report.Enabled := true;
 Self.CHB_report.Checked := false;

 Self.FillORs(sender, '');
 Self.CB_Cilova.ItemIndex := 0;

 // smazat vsechny zalozky
 Self.HVs.Clear();

 for i := Self.PC_HVs.PageCount-1 downto 0 do
   Self.PC_HVs.Pages[i].Free();

 // vytvorit 1 zalozku
 ts := TCloseTabSheet.Create(Self.PC_HVs);
 ts.PageControl := Self.PC_HVs;
 ts.Caption := 'HV 1';
 ts.OnClose := OnTabClose;

 form := TF_SprHVEdit.Create(TS);
 form.Parent := TS;
 form.Show();
 Self.HVs.Add(form);

 form.FillHV(HVs, nil);

 Self.ActiveControl := Self.E_Nazev;
 Self.Caption := 'Nová souprava';
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

// format dat soupravy: nazev;pocet_vozu;poznamka;smer_Lsmer_S;delka;typ;hnaci vozidla;vychozi stanice;cilova stanice
procedure TF_SoupravaEdit.EditSpr(parsed:TStrings; HVs:THVDb; sender_id:string; owner:string);
var i:Integer;
    ts:TCloseTabSheet;
    form:TF_SprHVEdit;
begin
 Self.HVDb  := HVs;
 Self.OblR  := sender_id;

 try
   Self.E_Nazev.Text := parsed[2];
   Self.SE_PocetVozu.Value := StrToInt(parsed[3]);
   Self.M_Poznamka.Text := parsed[4];

   if (parsed[5][1] = '1') then
     Self.CHB_Sipka_L.Checked := true
   else
     Self.CHB_Sipka_L.Checked := false;

   if (parsed[5][2] = '1') then
     Self.CHB_Sipka_S.Checked := true
   else
     Self.CHB_Sipka_S.Checked := false;

   Self.SE_Delka.Value := StrToInt(parsed[6]);
   Self.CB_Typ.Text    := parsed[7];

   if (parsed.Count > 10) then
     Self.FillORs(parsed[9], parsed[10])
   else begin
     Self.FillORs('', '');
     Self.CB_Vychozi.ItemIndex := 0;
     Self.CB_Cilova.ItemIndex := 0;
   end;

   Self.CHB_report.Enabled := (parsed.Count > 11);
   if (parsed.Count > 11) then
     Self.CHB_report.Checked := (parsed[11] = '1')
   else
     Self.CHB_report.Checked := false;

   Self.sprHVs.ParseHVs(parsed[8]);
 except
  Application.MessageBox('Neplatný formát dat soupravy !', 'Nelze editovat soupravu', MB_OK OR MB_ICONWARNING);
  Exit();
 end;

 // smazat vsechny zalozky
 Self.HVs.Clear();

 for i := Self.PC_HVs.PageCount-1 downto 0 do
   Self.PC_HVs.Pages[i].Free();

 // vytvorit zalozky podle poctu HV
 for i := 0 to sprHVs.HVs.Count-1 do
  begin
   ts := TCloseTabSheet.Create(Self.PC_HVs);
   ts.PageControl := Self.PC_HVs;
   ts.Caption := 'HV '+IntToStr(i+1);
   ts.OnClose := OnTabClose;

   form := TF_SprHVEdit.Create(TS);
   form.Parent := TS;
   form.Show();
   Self.HVs.Add(form);

   form.FillHV(HVs, sprHVs.HVs[i]);
  end;//for i

 Self.BB_HV_Add.Enabled := (Self.sprHVs.HVs.Count < _MAX_HV_CNT);

 Self.ActiveControl := Self.E_Nazev;
 Self.Caption := 'Souprava '+Self.E_Nazev.Text + ' – ' + owner;
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

// format dat soupravy: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla;vychozi stanice;cilova stanice
procedure TF_SoupravaEdit.B_SaveClick(Sender: TObject);
var sprstr:string;
    i, j:Integer;
    err:string;
begin
 if (Self.E_Nazev.Text = '') then
  begin
   Application.MessageBox('Vyplňte název soupravy!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit;
  end;

 // kontrola M_Poznamka
 for j := 0 to Length(_forbidden_chars)-1 do
   if (StrScan(PChar(Self.M_Poznamka.Text), _forbidden_chars[j]) <> nil) then
     begin
      Application.MessageBox(PChar('Poznámka k soupravě obsahuje zakázané znaky!'+#13#10+'Zakázané znaky: '+GetForbidderChars()),
                             'Nelze uložit data', MB_OK OR MB_ICONWARNING);
      Exit();
     end;

 if ((Self.CHB_report.Checked) and ((Self.CB_Vychozi.ItemIndex < 1) or (Self.CB_Cilova.ItemIndex < 1))) then
  begin
   Application.MessageBox('Pro staniční hlášení musí být vyplněna výchozí a cílová stanice!',
                          'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 if ((Self.CHB_report.Checked) and (Self.CB_Typ.Text = '')) then
  begin
   Application.MessageBox('Pro staniční hlášení musí být vyplněn typ soupravy!',
                          'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 sprstr := Self.E_Nazev.Text + ';' + IntToStr(Self.SE_PocetVozu.Value) + ';{' +
            Self.M_Poznamka.Text + '};';

 if (Self.CHB_Sipka_L.Checked) then
  sprstr := sprstr + '1'
 else
  sprstr := sprstr + '0';

 if (Self.CHB_Sipka_S.Checked) then
  sprstr := sprstr + '1;'
 else
  sprstr := sprstr + '0;';

 sprstr := sprstr + IntToStr(Self.SE_Delka.Value) + ';' + Self.CB_Typ.Text + ';';

 sprstr := sprstr + '{';

 err := '';
 for i := 0 to Self.PC_HVs.PageCount-1 do
  begin
   if (Self.HVs[i].HV = nil) then
    begin
     Application.MessageBox(PChar('Vyberte hnací vozidlo soupravy na záložce '+Self.PC_HVs.Pages[i].Caption),
                            'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
     Exit();
    end;
   if (Self.HVs[i].RG_HV1_dir.ItemIndex < 0) then
    begin
     Application.MessageBox(PChar('Vyberte orientaci stanoviště A hnacího vozidla na záložce '+Self.PC_HVs.Pages[i].Caption),
                            'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
     Exit();
    end;
   for j := 0 to Length(_forbidden_chars)-1 do
     if (StrScan(PChar(Self.HVs[i].M_HV1_Notes.Text), _forbidden_chars[j]) <> nil) then
       begin
        Application.MessageBox(PChar('Poznámka k hnacímu vozidlu obsahuje zakázané znaky!'+#13#10+'Zakázané znaky: '+
                               GetForbidderChars()), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
       end;

   for j := 0 to _MAX_FUNC do
     if ((Self.HVs[i].HV.funcType[j] = THVFuncType.momentary) and (Self.HVs[i].CHB_funkce[j].Checked)) then
       err := err + Self.PC_HVs.Pages[i].Caption+' má aktivovanou funkci '+IntToStr(j) +
              ' ('+Self.HVs[i].HV.funcVyznam[j]+'), která je momentary.'+#13#10;

   sprstr := sprstr + Self.HVs[i].GetHVString();
  end;

 if (err <> '') then
   if (Application.MessageBox(PChar(err+'Skutečně chcete pokračovat?'),
                              'Pokračovat?', MB_YESNO OR MB_ICONQUESTION OR MB_DEFBUTTON2) <> mrYes) then
     Exit();

 sprstr := sprstr + '};';

 if (Self.CB_Vychozi.ItemIndex > 0) then
   sprstr := sprstr + ORDb.db_reverse[CB_Vychozi.Items[CB_Vychozi.ItemIndex]];
 sprstr := sprstr + ';';

 if (Self.CB_Cilova.ItemIndex > 0) then
   sprstr := sprstr + ORDb.db_reverse[CB_Cilova.Items[CB_Cilova.ItemIndex]];
 sprstr := sprstr + ';';

 if (Self.CHB_report.Checked) then
  sprstr := sprstr + '1;'
 else
  sprstr := sprstr + '0;';

 PanelTCPClient.PanelSprChange(Self.OblR, sprstr);

 Screen.Cursor := crHourGlass;
 Self.T_Timeout.Enabled := true;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.B_StornoClick(Sender: TObject);
begin
 Relief.Escape();
 Self.Close();
end;

procedure TF_SoupravaEdit.CB_TypChange(Sender: TObject);
var s:string;
begin
 if (not Self.CHB_report.Enabled) then
   Exit();

 for s in _HLASENI_SPRTYP_FORBIDDEN do
  begin
   if (Self.CB_Typ.Text = s) then
    begin
     CHB_report.Checked := false;
     Exit();
    end;
  end;

 CHB_report.Checked := true;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.FormClose(Sender: TObject; var Action: TCloseAction);
var i:Integer;
begin
 Self.HVDb := nil;

 Self.HVs.Clear();
 for i := Self.PC_HVs.PageCount-1 downto 0 do
   Self.PC_HVs.Pages[i].Free();
end;

procedure TF_SoupravaEdit.FormCreate(Sender: TObject);
begin
 Self.HVs := TObjectList<TF_SprHVEdit>.Create();

 Self.PC_HVs.TabWidth := 60;
 Self.PC_HVs.OwnerDraw := True;

 Self.sprHVs := THVDb.Create();
end;

procedure TF_SoupravaEdit.FormDestroy(Sender: TObject);
var i:Integer;
begin
 // smazeme zalozky pro hnaci vozidla
 Self.HVs.Free();

 for i := Self.PC_HVs.PageCount-1 downto 0 do
  Self.PC_HVs.Pages[i].Free();

 FreeAndNil(Self.sprHVs);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.TechError(err:string);
begin
 Screen.Cursor := crDefault;
 Self.T_Timeout.Enabled := false;
 Application.MessageBox(PChar('Technologický server odpověděl chybou:'+#13#10+err), 'Varování', MB_OK OR MB_ICONWARNING);
end;

procedure TF_SoupravaEdit.T_TimeoutTimer(Sender: TObject);
begin
 Self.T_Timeout.Enabled := false;
 Screen.Cursor := crDefault;
 Application.MessageBox('Technologický server neodpověděl na požadavek o editaci soupravy', 'Varování', MB_OK OR MB_ICONWARNING);
end;

procedure TF_SoupravaEdit.TechACK();
begin
 Screen.Cursor := crDefault;
 Relief.ORInfoMsg('Souprava uložena');
 Self.T_Timeout.Enabled := false;
 Self.Close();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.PageControlCloseButtonDrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const Rect: TRect; Active: Boolean);
var
  CloseBtnSize: Integer;
  PageControl: TPageControl;
  TabSheet:TCloseTabSheet;
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
  end
  else
  begin
    CloseBtnRect.Top := Rect.Top + 3;
    CloseBtnRect.Right := Rect.Right - 5;
    TabCaption.X := Rect.Left + 3;
  end;

  if (PageControl.Pages[TabIndex] is TCloseTabSheet) then
  begin
    TabSheet:=PageControl.Pages[TabIndex] as TCloseTabSheet;
    CloseBtnSize := 14;

    CloseBtnRect.Bottom := CloseBtnRect.Top + CloseBtnSize;
    CloseBtnRect.Left := CloseBtnRect.Right - CloseBtnSize;
    TabSheet.FCloseButtonRect := CloseBtnRect;

    PageControl.Canvas.FillRect(Rect);
    PageControl.Canvas.TextOut(TabCaption.X, TabCaption.Y,
            PageControl.Pages[TabIndex].Caption);

    if not ThemeServices.ThemesEnabled then
    begin
      if (FCloseButtonMouseDownTab = TabSheet) and FCloseButtonShowPushed then
        CloseBtnDrawState := DFCS_CAPTIONCLOSE + DFCS_PUSHED
      else
        CloseBtnDrawState := DFCS_CAPTIONCLOSE;

      Windows.DrawFrameControl(PageControl.Canvas.Handle,
        TabSheet.FCloseButtonRect, DFC_CAPTION, CloseBtnDrawState);
    end
    else
    begin
      Dec(TabSheet.FCloseButtonRect.Left);

      if (FCloseButtonMouseDownTab = TabSheet) and FCloseButtonShowPushed then
        CloseBtnDrawDetails := ThemeServices.GetElementDetails(twCloseButtonPushed)
      else
        CloseBtnDrawDetails := ThemeServices.GetElementDetails(twCloseButtonNormal);

      ThemeServices.DrawElement(PageControl.Canvas.Handle, CloseBtnDrawDetails,
                TabSheet.FCloseButtonRect);
    end;
  end else begin
    PageControl.Canvas.FillRect(Rect);
    PageControl.Canvas.TextOut(TabCaption.X, TabCaption.Y,
                 PageControl.Pages[TabIndex].Caption);
  end;
end;

procedure TF_SoupravaEdit.PageControlCloseButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  PageControl: TPageControl;
  TabSheet:TCloseTabSheet;
begin
  PageControl := Sender as TPageControl;

  if Button = mbLeft then
  begin
    for I := 0 to PageControl.PageCount - 1 do
    begin
      if not (PageControl.Pages[i] is TCloseTabSheet) then Continue;
      TabSheet:=PageControl.Pages[i] as TCloseTabSheet;
      if PtInRect(TabSheet.FCloseButtonRect, Point(X, Y)) then
      begin
        FCloseButtonMouseDownTab := TabSheet;
        FCloseButtonShowPushed := True;
        PageControl.Repaint;
      end;
    end;
  end;
end;

procedure TF_SoupravaEdit.PageControlCloseButtonMouseLeave(Sender: TObject);
var
  PageControl: TPageControl;
begin
  PageControl := Sender as TPageControl;
  FCloseButtonShowPushed := False;
  PageControl.Repaint;
end;

procedure TF_SoupravaEdit.PageControlCloseButtonMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
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

procedure TF_SoupravaEdit.PageControlCloseButtonMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TF_SoupravaEdit.SB_st_changeClick(Sender: TObject);
var tmp:Integer;
begin
 tmp := Self.CB_Cilova.ItemIndex;
 Self.CB_Cilova.ItemIndex := Self.CB_Vychozi.ItemIndex;
 Self.CB_Vychozi.ItemIndex := tmp;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.OnTabClose(Sender:TObject);
var i:Integer;
    HV:THV;
begin
 for i := 0 to Self.PC_HVs.PageCount-1 do
  begin
   if (Self.PC_HVs.Pages[i] = Sender) then
    begin
     Self.HVs.Delete(i);

     // preradime HV ze soupravy do obecneho seznamu HV
     if (i < Self.sprHVs.HVs.Count) then
      begin
       for HV in HVDb.HVs do
         if (HV.Adresa = Self.sprHVs.HVs[i].Adresa) then
           HV.Souprava := '-';
       Self.sprHVs.Delete(i);
      end;

     break;
    end;
  end;

 (Sender as TTabSheet).Free();
 Self.BB_HV_Add.Enabled := true;

 for i := 0 to Self.PC_HVs.PageCount-1 do
  begin
   Self.PC_HVs.Pages[i].Caption := 'HV ' + IntToStr(i+1);
   if (i < Self.sprHVs.HVs.Count) then
     Self.HVs[i].FillHV(Self.HVDb, Self.sprHVs.HVs[i])
   else
     Self.HVs[i].FillHV(Self.HVDb, nil);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.FillORs(vychoziId:string; cilovaId:string);
var name:string;
begin
 Self.CB_Vychozi.Clear();
 Self.CB_Cilova.Clear();

 Self.CB_Vychozi.Items.Add('Nevyplněno');
 Self.CB_Cilova.Items.Add('Nevyplněno');

 for name in ORDb.names_sorted do
  begin
   Self.CB_Vychozi.Items.Add(name);
   Self.CB_Cilova.Items.Add(name);

   if (ORDb.db_reverse[name] = vychoziId) then
     Self.CB_Vychozi.ItemIndex := Self.CB_Vychozi.Items.Count - 1;

   if (ORDb.db_reverse[name] = cilovaId) then
     Self.CB_Cilova.ItemIndex := Self.CB_Cilova.Items.Count - 1;
  end;

 if (Self.CB_Vychozi.ItemIndex < 0) then
   Self.CB_Vychozi.ItemIndex := 0;

 if (Self.CB_Cilova.ItemIndex < 0) then
   Self.CB_Cilova.ItemIndex := 0;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
