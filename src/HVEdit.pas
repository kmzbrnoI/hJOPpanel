unit HVEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, HVDb, RPConst, TCPClientPanel;

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
    procedure CB_HVChange(Sender: TObject);
    procedure B_CancelClick(Sender: TObject);
    procedure B_ApplyClick(Sender: TObject);
    procedure E_AdresaKeyPress(Sender: TObject; var Key: Char);
    procedure M_PoznamkaKeyPress(Sender: TObject; var Key: Char);
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

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.B_ApplyClick(Sender: TObject);
var HV:THV;
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

 if (Self.new) then
  begin
   PanelTCPClient.PanelHVAdd(Self.sender_or, HV.GetPanelLokString());
  end else begin
   PanelTCPClient.PanelHVEdit(Self.sender_or, HV.GetPanelLokString());
  end;

 HV.Free();
 Self.Close();
end;//procedure

procedure TF_HVEdit.B_CancelClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HVEdit.CB_HVChange(Sender: TObject);
begin
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

   if (not Self.new) then
    begin
     Self.E_Name.Text         := Self.HVs.HVs[Self.CB_HV.ItemIndex].Nazev;
     Self.E_Oznaceni.Text     := Self.HVs.HVs[Self.CB_HV.ItemIndex].Oznaceni;
     Self.E_Majitel.Text      := Self.HVs.HVs[Self.CB_HV.ItemIndex].Majitel;
     Self.E_Adresa.Text       := IntToStr(Self.HVs.HVs[Self.CB_HV.ItemIndex].Adresa);
     Self.M_Poznamka.Text     := Self.HVs.HVs[Self.CB_HV.ItemIndex].Poznamka;
     Self.RG_Trida.ItemIndex  := Integer(Self.HVs.HVs[Self.CB_HV.ItemIndex].Trida);
     Self.RG_StA.ItemIndex    := Integer(Self.HVs.HVs[Self.CB_HV.ItemIndex].StanovisteA);

     Self.CHB_HV1_Svetla.Checked := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[0];
     Self.CHB_HV1_F1.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[1];
     Self.CHB_HV1_F2.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[2];
     Self.CHB_HV1_F3.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[3];
     Self.CHB_HV1_F4.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[4];
     Self.CHB_HV1_F5.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[5];
     Self.CHB_HV1_F6.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[6];
     Self.CHB_HV1_F7.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[7];
     Self.CHB_HV1_F8.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[8];
     Self.CHB_HV1_F9.Checked  := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[9];
     Self.CHB_HV1_F10.Checked := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[10];
     Self.CHB_HV1_F11.Checked := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[11];
     Self.CHB_HV1_F12.Checked := Self.HVs.HVs[Self.CB_HV.ItemIndex].funkce[12];
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
  end;

end;

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
 HVs.FillHVs(Self.CB_HV, Self.HVIndexes);
 Self.CB_HVChange(Self.CB_HV);

 Self.Caption := 'Editovat hnací vozidlo';
 Self.Show();
 Self.ActiveControl := Self.CB_HV;
end;

procedure TF_HVEdit.M_PoznamkaKeyPress(Sender: TObject; var Key: Char);
begin
 // osetreni vstupu
 case (key) of
  #13, '/', '\', '|', '(', ')', '[', ']', '-', ';': Key := #0;
 end;//case
end;//procedure

////////////////////////////////////////////////////////////////////////////////

end.//unit
