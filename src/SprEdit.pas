unit SprEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Spin, HVDb, RPConst, ComCtrls, SprHVEdit, Buttons,
  CloseTabSheet, Themes;

const
  _MAX_HV_CNT = 4;

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
    procedure E_SprDelkaKeyPress(Sender: TObject; var Key: Char);
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
  private
    OblR:string;
    HVs:array [0..3] of TF_SprHVEdit;
    HVDb:THVDb;
    sprHVs:THVDb;

    FCloseButtonMouseDownTab: TCloseTabSheet;
    FCloseButtonShowPushed: Boolean;

    procedure OnTabClose(Sender:TObject);

  public

    procedure NewSpr(HVs:THVDb; sender:string);
    procedure EditSpr(spr:string; HVs:THVDb; sender:string);

    procedure TechError(err:string);
    procedure TechACK();

  end;

var
  F_SoupravaEdit: TF_SoupravaEdit;

implementation

uses SprHelp, Main, TCPClientPanel;

// format dat soupravy: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.E_PoznamkaKeyPress(Sender: TObject; var Key: Char);
begin
 // osetreni vstupu
 case (key) of
  #13, '/', '\', '|', '(', ')', '[', ']', '-', ';': Key := #0;
 end;//case
end;

procedure TF_SoupravaEdit.E_SprDelkaKeyPress(Sender: TObject;
  var Key: Char);
 begin
  case Key of
   '0'..'9',#9,#8:begin
                  end else begin
                   Key := #0;
                  end;
   end;//case
 end;//procedure

procedure TF_SoupravaEdit.BB_HV_AddClick(Sender: TObject);
var i:Integer;
begin
 for i := 0 to Self.PC_HVs.PageCount-1 do
  if (not Self.PC_HVs.Pages[i].TabVisible) then
   begin
    Self.PC_HVs.Pages[i].TabVisible := true;
    Self.PC_HVs.ActivePageIndex     := i;

    Self.HVs[i].FillHV(Self.HVDb, nil);

    if (i = _MAX_HV_CNT-1) then
     Self.BB_HV_Add.Enabled := false;

    Exit;
   end;

 // vsechny jsou jiz viditelne -> nelze pridat dalsi
 Application.MessageBox('Více HV nelze pøidat', 'Nelze pøidat další HV', MB_OK OR MB_ICONWARNING);
end;

procedure TF_SoupravaEdit.B_HelpClick(Sender: TObject);
 begin
  F_SprHelp.Show();
 end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.NewSpr(HVs:THVDb; sender:string);
var i:Integer;
begin
 Self.HVDb := HVs;
 Self.OblR := sender;

 Self.E_Nazev.Text := '';
 Self.SE_PocetVozu.Value := 0;
 Self.CHB_Sipka_L.Checked := false;
 Self.CHB_Sipka_S.Checked := false;

 Self.PC_HVs.Pages[0].TabVisible := true;
 Self.BB_HV_Add.Enabled := true;
 for i := 1 to _MAX_HV_CNT-1 do
   Self.PC_HVs.Pages[i].TabVisible := false;

 Self.SE_Delka.Value  := 0;
 Self.CB_Typ.Text     := '';
 Self.M_Poznamka.Text := '';

 Self.PC_HVs.ActivePageIndex := 0;
 Self.HVs[0].FillHV(HVs, nil);

 Self.ActiveControl := Self.E_Nazev;
 Self.Caption := 'Nová souprava';
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

// format dat soupravy: nazev;pocet_vozu;poznamka;smer_Lsmer_S;delka;typ;hnaci vozidla
procedure TF_SoupravaEdit.EditSpr(spr:string; HVs:THVDb; sender:string);
var str:TStrings;
    i:Integer;
begin
 Self.HVDb  := HVs;
 Self.OblR  := sender;

 str := TStringList.Create();
 ExtractStringsEx(';', spr, str);

 try
   Self.E_Nazev.Text := str[0];
   Self.SE_PocetVozu.Value := StrToInt(str[1]);
   Self.M_Poznamka.Text := str[2];

   if (str[3][1] = '1') then
     Self.CHB_Sipka_L.Checked := true
   else
     Self.CHB_Sipka_L.Checked := false;

   if (str[3][2] = '1') then
     Self.CHB_Sipka_S.Checked := true
   else
     Self.CHB_Sipka_S.Checked := false;

   Self.SE_Delka.Value := StrToInt(str[4]);
   Self.CB_Typ.Text    := str[5];

   Self.sprHVs.ParseHVs(str[6]);
 except
  Application.MessageBox('Neplatný formát dat soupravy !', 'Nelze editovat soupravu', MB_OK OR MB_ICONWARNING);
  Exit();
 end;

 // nejdrive vsechny zalozky skryjeme
 for i := 0 to _MAX_HV_CNT-1 do
   Self.PC_HVs.Pages[i].TabVisible := false;

 // pak jich odkryjeme jen tolik, kolik mame souprav
 for i := 0 to sprHVs.count-1 do
  begin
   Self.HVs[i].FillHV(HVs, sprHVs.HVs[i]);
   Self.PC_HVs.Pages[i].TabVisible := true;
  end;//for i

 if (Self.sprHVs.count >= _MAX_HV_CNT) then
   Self.BB_HV_Add.Enabled := false
 else
   Self.BB_HV_Add.Enabled := true;

 str.Free();
 Self.ActiveControl := Self.E_Nazev;
 Self.Caption := 'Souprava '+Self.E_Nazev.Text;
 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// format dat soupravy: nazev;pocet_vozu;poznamka;smer_Lsmer_S;hnaci vozidla
procedure TF_SoupravaEdit.B_SaveClick(Sender: TObject);
var sprstr:string;
    i:Integer;
begin
 if (Self.E_Nazev.Text = '') then
  begin
   Application.MessageBox('Vyplòte název soupravy', 'Nelze pokraèovat', MB_OK OR MB_ICONWARNING);
   Exit;
  end;

 sprstr := Self.E_Nazev.Text + ';' + IntToStr(Self.SE_PocetVozu.Value) + ';'+
            Self.M_Poznamka.Lines[0] + ';';

 if (Self.CHB_Sipka_L.Checked) then
  sprstr := sprstr + '1'
 else
  sprstr := sprstr + '0';

 if (Self.CHB_Sipka_S.Checked) then
  sprstr := sprstr + '1;'
 else
  sprstr := sprstr + '0;';

 sprstr := sprstr + IntToStr(Self.SE_Delka.Value) + ';' + Self.CB_Typ.Text + ';';

 for i := 0 to _MAX_HV_CNT-1 do
  begin
   if (not Self.PC_HVs.Pages[i].TabVisible) then continue;

   if (Self.HVs[i].CB_HV1_HV.ItemIndex < 0) then
    begin
     Application.MessageBox(PChar('Vyberte hnací vozidlo soupravy na záložce '+Self.PC_HVs.Pages[i].Caption), 'Nelze pokraèovat', MB_OK OR MB_ICONWARNING);
     Exit;
    end;
   if (Self.HVs[i].RG_HV1_dir.ItemIndex < 0) then
    begin
     Application.MessageBox(PChar('Vyberte orientaci stanovištì A hnacího vozidla na záložce '+Self.PC_HVs.Pages[i].Caption), 'Nelze pokraèovat', MB_OK OR MB_ICONWARNING);
     Exit;
    end;

   sprstr := sprstr +  Self.HVs[i].GetHVString();
  end;

 PanelTCPClient.PanelSprChange(Self.OblR, sprstr);

 Screen.Cursor := crHourGlass;
 Self.T_Timeout.Enabled := true;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.B_StornoClick(Sender: TObject);
begin
 Relief.Escape();
 Self.Close();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Self.HVDb := nil;
end;

procedure TF_SoupravaEdit.FormCreate(Sender: TObject);
var i:Integer;
    TS:TCloseTabSheet;
begin
 Self.PC_HVs.TabWidth := 60;
 Self.PC_HVs.OwnerDraw := True;

 Self.sprHVs := THVDb.Create();

 // vytvorime zalozky pro hanci vozidla
 for i := 0 to _MAX_HV_CNT-1 do
  begin
   TS := TCloseTabSheet.Create(Self.PC_HVs);
   TS.PageControl := Self.PC_HVs;
   TS.Caption := 'HV '+IntToStr(i+1);
   TS.OnClose := OnTabClose;

   Self.HVs[i] := TF_SprHVEdit.Create(TS);
   Self.HVs[i].Parent := TS;
   Self.HVs[i].Show();
  end;//for i
end;//procedure

procedure TF_SoupravaEdit.FormDestroy(Sender: TObject);
var i:Integer;
begin
 // smazeme zalozky pro hnaci vozidla
 for i := 0 to _MAX_HV_CNT-1 do
  if (Assigned(Self.HVs[i])) then FreeAndNIl(Self.HVs[i]);

 for i := Self.PC_HVs.PageCount-1 downto 0 do
  Self.PC_HVs.Pages[i].Free();

 FreeAndNil(Self.sprHVs);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.TechError(err:string);
begin
 Screen.Cursor := crDefault;
 Self.T_Timeout.Enabled := false;
 Application.MessageBox(PChar('Technologický server odpovìdìl chybou:'+#13#10+err), 'Varování', MB_OK OR MB_ICONWARNING);
end;

procedure TF_SoupravaEdit.T_TimeoutTimer(Sender: TObject);
begin
 Self.T_Timeout.Enabled := false;
 Screen.Cursor := crDefault;
 Application.MessageBox('Technologický server neodpovìdìl na požadavek o editaci soupravy', 'Varování', MB_OK OR MB_ICONWARNING);
end;//procedure

procedure TF_SoupravaEdit.TechACK();
begin
 Screen.Cursor := crDefault;
 Relief.ORInfoMsg('Souprava uložena');
 Self.T_Timeout.Enabled := false;
 Self.Close();
end;//procedure

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
  maxindex, i:Integer;
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

  maxindex := -1;
  for i := 0 to PageControl.PageCount-1 do
   if (PageControl.Pages[i].TabVisible) then
    maxindex := i;

  if ((PageControl.Pages[TabIndex] is TCloseTabSheet) and (TabIndex = maxindex) and (maxindex <> 0)) then
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

////////////////////////////////////////////////////////////////////////////////

procedure TF_SoupravaEdit.OnTabClose(Sender:TObject);
var i, maxindex:Integer;
begin
 maxindex := -1;
 for i := 0 to Self.PC_HVs.PageCount-1 do
  if (Self.PC_HVs.Pages[i].TabVisible) then
   maxindex := i;

 if (((Sender as TTabSheet) = Self.PC_HVs.Pages[maxindex]) and (maxindex <> -1)) then
  begin
   (Sender as TTabSheet).TabVisible := false;
   Self.BB_HV_Add.Enabled := true;
   Self.PC_HVs.Repaint();
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

end.//unit


