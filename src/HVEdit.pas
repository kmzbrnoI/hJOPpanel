unit HVEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, HVDb, RPConst, TCPClientPanel, ComCtrls, Buttons,
  Generics.Collections;

type
  TF_HVEdit = class(TForm)
    Label1: TLabel;
    CB_HV: TComboBox;
    GB_HV: TGroupBox;
    Label2: TLabel;
    E_Name: TEdit;
    E_Oznaceni: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    E_Majitel: TEdit;
    Label5: TLabel;
    M_Poznamka: TMemo;
    GroupBox1: TGroupBox;
    CHB_HV1_Svetla: TCheckBox;
    CHB_HV1_F1: TCheckBox;
    CHB_HV1_F2: TCheckBox;
    CHB_HV1_F3: TCheckBox;
    CHB_HV1_F4: TCheckBox;
    CHB_HV1_F5: TCheckBox;
    CHB_HV1_F6: TCheckBox;
    CHB_HV1_F8: TCheckBox;
    CHB_HV1_F7: TCheckBox;
    CHB_HV1_F9: TCheckBox;
    CHB_HV1_F10: TCheckBox;
    CHB_HV1_F11: TCheckBox;
    CHB_HV1_F12: TCheckBox;
    Label6: TLabel;
    E_Adresa: TEdit;
    RG_Trida: TRadioGroup;
    RG_StA: TRadioGroup;
    B_Apply: TButton;
    B_Cancel: TButton;
    Label7: TLabel;
    Label8: TLabel;
    SB_Take_Add: TSpeedButton;
    SB_Take_Remove: TSpeedButton;
    LV_Pom_Load: TListView;
    SB_Rel_Add: TSpeedButton;
    SB_Rel_Remove: TSpeedButton;
    Label9: TLabel;
    LV_Pom_Release: TListView;
    procedure CB_HVChange(Sender: TObject);
    procedure B_CancelClick(Sender: TObject);
    procedure B_ApplyClick(Sender: TObject);
    procedure E_AdresaKeyPress(Sender: TObject; var Key: Char);
    procedure M_PoznamkaKeyPress(Sender: TObject; var Key: Char);
    procedure SB_Take_RemoveClick(Sender: TObject);
    procedure SB_Rel_RemoveClick(Sender: TObject);
    procedure LV_Pom_LoadChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure LV_Pom_ReleaseChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure LV_Pom_LoadDblClick(Sender: TObject);
    procedure SB_Take_AddClick(Sender: TObject);
    procedure SB_Rel_AddClick(Sender: TObject);
    procedure LV_Pom_ReleaseDblClick(Sender: TObject);
  private
    { Private declarations }

    HVIndexes:TWordAr;
    HVs:THVDb;
    new:boolean;
    sender_or:string;
  public
    { Public declarations }

    procedure HVAdd(sender_or:string; HVs:THVDb);
    procedure HVEdit(sender_or:string; HVs:THVDb);
  end;

var
  F_HVEdit: TF_HVEdit;

implementation

uses HVPomEdit;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.B_ApplyClick(Sender: TObject);
var HV:THV;
    i, j:Integer;
    pomCV:THVPomCV;
begin
 if (Self.E_Name.Text = '') then
  begin
   Application.MessageBox('Vyplòte název lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.E_Adresa.Text = '') then
  begin
   Application.MessageBox('Vyplòte adresu lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.RG_Trida.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte tøídu lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.RG_StA.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte stanovištì A lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 HV := THV.Create();

 // kontrola M_Poznamka
 for i := 1 to Length(Self.M_Poznamka.Text) do
   for j := 0 to Length(_forbidden_chars)-1 do
     if (_forbidden_chars[j] = Self.M_Poznamka.Text[i]) then
       begin
        Application.MessageBox(PChar('Poznámka k hnacímu vozidlu obsahuje zakázané znaky!'+#13#10+'Zakázané znaky: '+GetForbidderChars()), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
       end;

 HV.Nazev       := Self.E_Name.Text;
 HV.Majitel     := Self.E_Majitel.Text;
 HV.Oznaceni    := Self.E_Oznaceni.Text;
 HV.Poznamka    := Self.M_Poznamka.Text;
 HV.Adresa      := StrToInt(Self.E_Adresa.Text);
 HV.Trida       := THVClass(Self.RG_Trida.ItemIndex);
 HV.Souprava    := '-';
 HV.StanovisteA := THVStanoviste(Self.RG_StA.ItemIndex);

 HV.funkce[0]   := Self.CHB_HV1_Svetla.Checked;
 HV.funkce[1]   := Self.CHB_HV1_F1.Checked;
 HV.funkce[2]   := Self.CHB_HV1_F2.Checked;
 HV.funkce[3]   := Self.CHB_HV1_F3.Checked;
 HV.funkce[4]   := Self.CHB_HV1_F4.Checked;
 HV.funkce[5]   := Self.CHB_HV1_F5.Checked;
 HV.funkce[6]   := Self.CHB_HV1_F6.Checked;
 HV.funkce[7]   := Self.CHB_HV1_F7.Checked;
 HV.funkce[8]   := Self.CHB_HV1_F8.Checked;
 HV.funkce[9]   := Self.CHB_HV1_F9.Checked;
 HV.funkce[10]  := Self.CHB_HV1_F10.Checked;
 HV.funkce[11]  := Self.CHB_HV1_F11.Checked;
 HV.funkce[12]  := Self.CHB_HV1_F12.Checked;


 HV.POMtake.Clear();
 HV.POMrelease.Clear();

 // parse POM take
 for i := 0 to Self.LV_Pom_Load.Items.Count-1 do
  begin
   try
     pomCV.cv   := StrToInt(Self.LV_Pom_Load.Items.Item[i].Caption);
     pomCV.data := StrToInt(Self.LV_Pom_Load.Items.Item[i].SubItems.Strings[0]);
     HV.POMtake.Add(pomCV);
   except

   end;
  end;

 // parse POM release
 for i := 0 to Self.LV_Pom_Release.Items.Count-1 do
  begin
   try
     pomCV.cv   := StrToInt(Self.LV_Pom_Release.Items.Item[i].Caption);
     pomCV.data := StrToInt(Self.LV_Pom_Release.Items.Item[i].SubItems.Strings[0]);
     HV.POMrelease.Add(pomCV);
   except

   end;
  end;

 if (Self.new) then
  begin
   PanelTCPClient.PanelHVAdd(Self.sender_or, '{'+HV.GetPanelLokString(true)+'}');
  end else begin
   PanelTCPClient.PanelHVEdit(Self.sender_or, '{'+HV.GetPanelLokString(true)+'}');
  end;

 HV.Free();
 Self.Close();
end;//procedure

procedure TF_HVEdit.B_CancelClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HVEdit.CB_HVChange(Sender: TObject);
var HV:THV;
    LI:TListItem;
    pomCv:THVPomCv;
begin
 Self.SB_Take_Remove.Enabled := false;
 Self.SB_Rel_Remove.Enabled  := false;
 Self.LV_Pom_Load.Clear();
 Self.LV_Pom_Release.Clear();

 if ((Self.CB_HV.ItemIndex > -1) or (Self.new)) then
  begin
   Self.B_Apply.Enabled := true;

   Self.E_Name.Enabled      := true;
   Self.E_Oznaceni.Enabled  := true;
   Self.E_Majitel.Enabled   := true;
   Self.E_Adresa.Enabled    := true;
   Self.M_Poznamka.Enabled  := true;
   Self.RG_Trida.Enabled    := true;
   Self.RG_StA.Enabled      := true;

   Self.CHB_HV1_Svetla.Enabled := true;
   Self.CHB_HV1_F1.Enabled  := true;
   Self.CHB_HV1_F2.Enabled  := true;
   Self.CHB_HV1_F3.Enabled  := true;
   Self.CHB_HV1_F4.Enabled  := true;
   Self.CHB_HV1_F5.Enabled  := true;
   Self.CHB_HV1_F6.Enabled  := true;
   Self.CHB_HV1_F7.Enabled  := true;
   Self.CHB_HV1_F8.Enabled  := true;
   Self.CHB_HV1_F9.Enabled  := true;
   Self.CHB_HV1_F10.Enabled := true;
   Self.CHB_HV1_F11.Enabled := true;
   Self.CHB_HV1_F12.Enabled := true;

   Self.SB_Take_Add.Enabled    := true;
   Self.SB_Rel_Add.Enabled     := true;
   Self.LV_Pom_Load.Enabled    := true;
   Self.LV_Pom_Release.Enabled := true;

   if (not Self.new) then
    begin
     HV := Self.HVs.HVs[Self.CB_HV.ItemIndex];
     Self.E_Name.Text         := HV.Nazev;
     Self.E_Oznaceni.Text     := HV.Oznaceni;
     Self.E_Majitel.Text      := HV.Majitel;
     Self.E_Adresa.Text       := IntToStr(HV.Adresa);
     Self.M_Poznamka.Text     := HV.Poznamka;
     Self.RG_Trida.ItemIndex  := Integer(HV.Trida);
     Self.RG_StA.ItemIndex    := Integer(HV.StanovisteA);

     Self.CHB_HV1_Svetla.Checked := HV.funkce[0];
     Self.CHB_HV1_F1.Checked  := HV.funkce[1];
     Self.CHB_HV1_F2.Checked  := HV.funkce[2];
     Self.CHB_HV1_F3.Checked  := HV.funkce[3];
     Self.CHB_HV1_F4.Checked  := HV.funkce[4];
     Self.CHB_HV1_F5.Checked  := HV.funkce[5];
     Self.CHB_HV1_F6.Checked  := HV.funkce[6];
     Self.CHB_HV1_F7.Checked  := HV.funkce[7];
     Self.CHB_HV1_F8.Checked  := HV.funkce[8];
     Self.CHB_HV1_F9.Checked  := HV.funkce[9];
     Self.CHB_HV1_F10.Checked := HV.funkce[10];
     Self.CHB_HV1_F11.Checked := HV.funkce[11];
     Self.CHB_HV1_F12.Checked := HV.funkce[12];

     for pomCv in HV.POMtake do
      begin
       LI := Self.LV_Pom_Load.Items.Add;
       LI.Caption := IntToStr(pomCV.cv);
       LI.SubItems.Add(IntToStr(pomCV.data));
      end;

     for pomCv in HV.POMrelease do
      begin
       LI := Self.LV_Pom_Release.Items.Add;
       LI.Caption := IntToStr(pomCV.cv);
       LI.SubItems.Add(IntToStr(pomCV.data));
      end;

    end;

  end else begin
   Self.B_Apply.Enabled := false;

   Self.E_Name.Enabled      := false;
   Self.E_Oznaceni.Enabled  := false;
   Self.E_Majitel.Enabled   := false;
   Self.E_Adresa.Enabled    := false;
   Self.M_Poznamka.Enabled  := false;
   Self.RG_Trida.Enabled    := false;
   Self.RG_StA.Enabled      := false;

   Self.CHB_HV1_Svetla.Enabled := false;
   Self.CHB_HV1_F1.Enabled  := false;
   Self.CHB_HV1_F2.Enabled  := false;
   Self.CHB_HV1_F3.Enabled  := false;
   Self.CHB_HV1_F4.Enabled  := false;
   Self.CHB_HV1_F5.Enabled  := false;
   Self.CHB_HV1_F6.Enabled  := false;
   Self.CHB_HV1_F7.Enabled  := false;
   Self.CHB_HV1_F8.Enabled  := false;
   Self.CHB_HV1_F9.Enabled  := false;
   Self.CHB_HV1_F10.Enabled := false;
   Self.CHB_HV1_F11.Enabled := false;
   Self.CHB_HV1_F12.Enabled := false;

   Self.E_Name.Text         := '';
   Self.E_Oznaceni.Text     := '';
   Self.E_Majitel.Text      := '';
   Self.E_Adresa.Text       := '';
   Self.M_Poznamka.Text     := '';
   Self.RG_Trida.ItemIndex  := -1;
   Self.RG_StA.ItemIndex    := -1;

   Self.CHB_HV1_Svetla.Checked := true;
   Self.CHB_HV1_F1.Checked  := false;
   Self.CHB_HV1_F2.Checked  := false;
   Self.CHB_HV1_F3.Checked  := false;
   Self.CHB_HV1_F4.Checked  := false;
   Self.CHB_HV1_F5.Checked  := false;
   Self.CHB_HV1_F6.Checked  := false;
   Self.CHB_HV1_F7.Checked  := false;
   Self.CHB_HV1_F8.Checked  := false;
   Self.CHB_HV1_F9.Checked  := false;
   Self.CHB_HV1_F10.Checked := false;
   Self.CHB_HV1_F11.Checked := false;
   Self.CHB_HV1_F12.Checked := false;

   Self.SB_Take_Add.Enabled    := false;
   Self.SB_Rel_Add.Enabled     := false;
   Self.LV_Pom_Load.Enabled    := false;
   Self.LV_Pom_Release.Enabled := false;

  end;

end;//procedure

procedure TF_HVEdit.E_AdresaKeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
   '0'..'9',#9,#8:;
   else
    Key := #0;
  end;//else case
end;

//procedure

procedure TF_HVEdit.HVAdd(sender_or:string; HVs:THVDb);
begin
 Self.sender_or := sender_or;
 Self.HVs       := HVs;
 Self.new       := true;

 Self.CB_HV.Enabled := false;
 Self.CB_HV.Clear();
 Self.CB_HV.Items.Add('Nové hnací vozidlo');
 Self.CB_HV.ItemIndex := 0;

 Self.E_Name.Text         := '';
 Self.E_Oznaceni.Text     := '';
 Self.E_Majitel.Text      := '';
 Self.E_Adresa.Text       := '';
 Self.M_Poznamka.Text     := '';
 Self.RG_Trida.ItemIndex  := -1;
 Self.RG_StA.ItemIndex    := -1;

 Self.CHB_HV1_Svetla.Checked := true;
 Self.CHB_HV1_F1.Checked  := false;
 Self.CHB_HV1_F2.Checked  := false;
 Self.CHB_HV1_F3.Checked  := false;
 Self.CHB_HV1_F4.Checked  := false;
 Self.CHB_HV1_F5.Checked  := false;
 Self.CHB_HV1_F6.Checked  := false;
 Self.CHB_HV1_F7.Checked  := false;
 Self.CHB_HV1_F8.Checked  := false;
 Self.CHB_HV1_F9.Checked  := false;
 Self.CHB_HV1_F10.Checked := false;
 Self.CHB_HV1_F11.Checked := false;
 Self.CHB_HV1_F12.Checked := false;

 Self.SB_Take_Remove.Enabled := false;
 Self.SB_Rel_Remove.Enabled  := false;

 Self.Caption := 'Nové hnací vozidlo';
 Self.Show();
 Self.ActiveControl := Self.E_Name;
end;//procedure

procedure TF_HVEdit.HVEdit(sender_or:string; HVs:THVDb);
begin
 Self.sender_or := sender_or;
 Self.new       := false;
 Self.HVs       := HVs;

 Self.CB_HV.Enabled := true;
 HVs.FillHVs(Self.CB_HV, Self.HVIndexes, -1, nil, true);
 Self.CB_HVChange(Self.CB_HV);

 Self.Caption := 'Editovat hnací vozidlo';
 Self.Show();
 Self.ActiveControl := Self.CB_HV;
end;

procedure TF_HVEdit.LV_Pom_LoadChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
 Self.SB_Take_Remove.Enabled := (Self.LV_Pom_Load.Selected <> nil);
end;

procedure TF_HVEdit.LV_Pom_LoadDblClick(Sender: TObject);
begin
 if (Self.LV_Pom_Load.Selected <> nil) then
  begin
   F_HV_Pom.OpenForm(StrToInt(Self.LV_Pom_Load.Selected.Caption), StrToInt(Self.LV_Pom_Load.Selected.SubItems.Strings[0]));
   if (F_HV_Pom.saved) then
     Self.LV_Pom_Load.Selected.SubItems.Strings[0] := IntToStr(F_HV_Pom.SE_Value.Value);
  end else begin
   Self.SB_Take_AddClick(Self);
  end;
end;

procedure TF_HVEdit.LV_Pom_ReleaseChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
 Self.SB_Rel_Remove.Enabled := (Self.LV_Pom_Release.Selected <> nil);
end;

procedure TF_HVEdit.LV_Pom_ReleaseDblClick(Sender: TObject);
begin
 if (Self.LV_Pom_Release.Selected <> nil) then
  begin
   F_HV_Pom.OpenForm(StrToInt(Self.LV_Pom_Release.Selected.Caption), StrToInt(Self.LV_Pom_Release.Selected.SubItems.Strings[0]));
   if (F_HV_Pom.saved) then
     Self.LV_Pom_Release.Selected.SubItems.Strings[0] := IntToStr(F_HV_Pom.SE_Value.Value);
  end else begin
   Self.SB_Rel_AddClick(Self);
  end;
end;

procedure TF_HVEdit.M_PoznamkaKeyPress(Sender: TObject; var Key: Char);
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

procedure TF_HVEdit.SB_Rel_AddClick(Sender: TObject);
var LI:TListItem;
    i:Integer;
begin
 F_HV_Pom.OpenForm(-1, 0);
 if (F_HV_Pom.saved) then
  begin
   i := 0;
   while ((i < Self.LV_Pom_Release.Items.Count) and (StrToInt(Self.LV_Pom_Release.Items.Item[i].Caption) < F_HV_Pom.SE_CV.Value)) do Inc(i);

   if ((Assigned(Self.LV_Pom_Release.Items.Item[i])) and (StrToInt(Self.LV_Pom_Release.Items.Item[i].Caption) = F_HV_Pom.SE_CV.Value)) then
    begin
     Self.LV_Pom_Release.Items.Item[i].SubItems.Strings[0] := IntToStr(F_HV_Pom.SE_Value.Value);
    end else begin
     LI := Self.LV_Pom_Release.Items.Insert(i);
     LI.Caption := IntToStr(F_HV_Pom.SE_CV.Value);
     LI.SubItems.Add(IntToStr(F_HV_Pom.SE_Value.Value));
    end;
  end;
end;

procedure TF_HVEdit.SB_Rel_RemoveClick(Sender: TObject);
begin
 if (Self.LV_Pom_Release.Selected <> nil) then
  Self.LV_Pom_Release.Items.Delete(Self.LV_Pom_Release.ItemIndex);
end;

procedure TF_HVEdit.SB_Take_AddClick(Sender: TObject);
var i:Integer;
    LI:TListItem;
begin
 F_HV_Pom.OpenForm(-1, 0);
 if (F_HV_Pom.saved) then
  begin
   i := 0;
   while ((i < Self.LV_Pom_Load.Items.Count) and (StrToInt(Self.LV_Pom_Load.Items.Item[i].Caption) < F_HV_Pom.SE_CV.Value)) do Inc(i);

   if ((Assigned(Self.LV_Pom_Load.Items.Item[i])) and (StrToInt(Self.LV_Pom_Load.Items.Item[i].Caption) = F_HV_Pom.SE_CV.Value)) then
    begin
     Self.LV_Pom_Load.Items.Item[i].SubItems.Strings[0] := IntToStr(F_HV_Pom.SE_Value.Value);
    end else begin
     LI := Self.LV_Pom_Load.Items.Insert(i);
     LI.Caption := IntToStr(F_HV_Pom.SE_CV.Value);
     LI.SubItems.Add(IntToStr(F_HV_Pom.SE_Value.Value));
    end;
  end;
end;

procedure TF_HVEdit.SB_Take_RemoveClick(Sender: TObject);
begin
 if (Self.LV_Pom_Load.Selected <> nil) then
  Self.LV_Pom_Load.Items.Delete(Self.LV_Pom_Load.ItemIndex);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

end.//unit
