unit fHVEdit;

{
  Okno editace vlastnosti hnacicho vozidla.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, HVDb, RPConst, TCPClientPanel, ComCtrls, Buttons,
  Generics.Collections, AppEvnts, Spin, IniFiles;

type
  TF_HVEdit = class(TForm)
    L_HV: TLabel;
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
    LV_Funkce: TListView;
    Label10: TLabel;
    B_Search: TButton;
    Label11: TLabel;
    SE_MaxSpeed: TSpinEdit;
    Label12: TLabel;
    CB_Prechodnost: TComboBox;
    Label13: TLabel;
    procedure CB_HVChange(Sender: TObject);
    procedure B_CancelClick(Sender: TObject);
    procedure B_ApplyClick(Sender: TObject);
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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure B_SearchClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }

    HVs:THVDb;
    new:boolean;
    sender_or:string;
    CB_funkce:array[0.._MAX_FUNC] of TComboBox;
    RB_P:array[0.._MAX_FUNC] of TRadioButton;
    RB_M:array[0.._MAX_FUNC] of TRadioButton;
    P_types:array[0.._MAX_FUNC] of TPanel;
    FOldListviewWindowProc: TWndMethod;
    vyznType:TDictionary<string, THVFuncType>;
    prechodnost: TDictionary<Cardinal, string>;

    procedure InitFunkce();
    procedure FreeFunkce();
    procedure RepaintFunkce();
    procedure LV_FunkceWindowproc(var Message: TMessage);
    procedure CB_VyznamChange(Sender: TObject);

  public
    procedure HVAdd(sender_or:string; HVs:THVDb);
    procedure HVEdit(sender_or:string; HVs:THVDb);
    procedure ParseVyznamy(vyznamy:string);

    procedure ServerEditResp(parsed: TStrings);
    procedure ServerAddResp(parsed: TStrings);

    procedure LoadPrechodnost(ini: TMemIniFile);

  end;

var
  F_HVEdit: TF_HVEdit;

implementation

uses fHVPomEdit, commctrl, parseHelper;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.B_ApplyClick(Sender: TObject);
var HV:THV;
    i, j:Integer;
    pomCV:THVPomCV;
    newVyznamy:string;
    str: string;
begin
 if (Self.E_Name.Text = '') then
  begin
   Application.MessageBox('Vyplňte název lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.E_Adresa.Text = '') then
  begin
   Application.MessageBox('Vyplňte adresu lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.RG_Trida.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte třídu lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.RG_StA.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte stanoviště A lokomotivy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.CB_Prechodnost.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte třídu přechodnosti hnacího vozidla!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
   Exit();
  end;


 HV := THV.Create();

 // kontrola M_Poznamka
 for j := 0 to Length(_forbidden_chars)-1 do
  begin
   if (strscan(PChar(Self.M_Poznamka.Text), _forbidden_chars[j]) <> nil) then
     begin
      Application.MessageBox(PChar('Poznámka k hnacímu vozidlu obsahuje zakázané znaky!'+#13#10+'Zakázané znaky: '+GetForbidderChars()), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
      Exit();
     end;
  end;

 HV.Nazev := Self.E_Name.Text;
 HV.Majitel := Self.E_Majitel.Text;
 HV.Oznaceni := Self.E_Oznaceni.Text;
 HV.Poznamka := Self.M_Poznamka.Text;
 HV.Adresa := StrToInt(Self.E_Adresa.Text);
 if (Self.RG_Trida.ItemIndex = Self.RG_Trida.Items.Count-1) then
   HV.Typ := THVType.other
 else
   HV.Typ := THVType(Self.RG_Trida.ItemIndex);
 HV.Souprava := '-';
 HV.StanovisteA := THVStanoviste(Self.RG_StA.ItemIndex);
 HV.maxRychlost := Self.SE_MaxSpeed.Value;
 str := Self.CB_Prechodnost.Items[Self.CB_Prechodnost.ItemIndex];
 HV.prechodnost := StrToInt(Copy(str, 1, Pos(':', str)-1));

 for i := 0 to _MAX_FUNC do
   HV.funkce[i] := Self.LV_Funkce.Items[i].Checked;

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

 // parse func vyznam
 for i := 0 to _MAX_FUNC do
  begin
   if (StrScan(PChar(Self.CB_funkce[i].Text), ':') <> nil) then
    begin
     Application.MessageBox(PChar('Význam funkce obsahuje zakázaný znak ":" (dvojtečka)!'), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
     Exit();
    end;
   for j := 0 to Length(_forbidden_chars)-1 do
     if (strscan(PChar(Self.CB_funkce[i].Text), _forbidden_chars[j]) <> nil) then
       begin
        Application.MessageBox(PChar('Význam funkce obsahuje zakázané znaky!'+#13#10+'Zakázané znaky: '+GetForbidderChars()), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
       end;

   HV.funcVyznam[i] := Self.CB_funkce[i].Text;
   if (Self.RB_M[i].Checked) then
     HV.funcType[i] := THVFuncType.momentary
   else
     HV.funcType[i] := THVFuncType.permanent;
  end;

 if (Self.new) then
  begin
   PanelTCPClient.PanelHVAdd(Self.sender_or, '{'+HV.GetPanelLokString(full)+'}');
  end else begin
   PanelTCPClient.PanelHVEdit(Self.sender_or, '{'+HV.GetPanelLokString(full)+'}');
  end;

 // kontrola pridani novych vyznamu funkci
 newVyznamy := '';
 for i := 0 to _MAX_FUNC do
  begin
   if ((Self.CB_funkce[i].Text <> '') and (Self.CB_funkce[i].Items.IndexOf(Self.CB_funkce[i].Text) = -1)) then
    begin
     newVyznamy := newVyznamy + '{' + Self.CB_funkce[i].Text + ':';
     if (Self.RB_M[i].Checked) then
       newVyznamy := newVyznamy + 'M'
     else
       newVyznamy := newVyznamy + 'P';
     newVyznamy := newVyznamy + '};';
    end;
  end;//for i
 if (newVyznamy <> '') then
   PanelTCPClient.SendLn('-;F-VYZN-ADD;{'+newVyznamy+'}');

 HV.Free();
 Screen.Cursor := crHourGlass;
end;

procedure TF_HVEdit.B_CancelClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HVEdit.B_SearchClick(Sender: TObject);
begin
 if (Self.E_Adresa.Text = '') then
  begin
   Application.MessageBox('Vyplňte adresu hnacího vozidla!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 PanelTCPClient.SendLn('-;HV;ASK;'+Self.E_Adresa.Text);
end;

procedure TF_HVEdit.CB_HVChange(Sender: TObject);
var HV:THV;
    LI:TListItem;
    pomCv:THVPomCv;
    i:Integer;
    j: Cardinal;
    prechSorted: TList<Cardinal>;
begin
 Self.SB_Take_Remove.Enabled := false;
 Self.SB_Rel_Remove.Enabled  := false;
 Self.LV_Pom_Load.Clear();
 Self.LV_Pom_Release.Clear();

 if (Self.CB_HV.ItemIndex > -1) then
  begin
   Self.B_Apply.Enabled := true;

   Self.E_Name.Enabled := true;
   Self.E_Oznaceni.Enabled := true;
   Self.E_Majitel.Enabled := true;
   Self.E_Adresa.Enabled := true;
   Self.E_Adresa.ReadOnly := not Self.new;
   Self.M_Poznamka.Enabled := true;
   Self.RG_Trida.Enabled := true;
   Self.RG_StA.Enabled := true;
   Self.SE_MaxSpeed.Enabled := true;
   Self.CB_Prechodnost.Enabled := true;

   Self.SB_Take_Add.Enabled := true;
   Self.SB_Rel_Add.Enabled := true;
   Self.LV_Pom_Load.Enabled := true;
   Self.LV_Pom_Release.Enabled := true;

   Self.LV_Funkce.Enabled := true;
   for i := 0 to _MAX_FUNC do
    begin
     Self.CB_funkce[i].Enabled := true;
     Self.RB_P[i].Enabled := true;
     Self.RB_M[i].Enabled := true;
    end;

   if ((Self.new) and (Self.CB_HV.ItemIndex = 0)) then
    begin
     Self.E_Name.Text := '';
     Self.E_Oznaceni.Text := '';
     Self.E_Majitel.Text := '';
     Self.E_Adresa.Text := '';
     Self.M_Poznamka.Text := '';
     Self.RG_Trida.ItemIndex := -1;
     Self.RG_StA.ItemIndex := -1;
     Self.SE_MaxSpeed.Value := _DEFAULT_MAX_SPEED;

     prechSorted := TList<Cardinal>.Create(Self.prechodnost.Keys);
     try
       prechSorted.Sort();
       Self.CB_Prechodnost.Clear();
       for i in prechSorted do
         Self.CB_Prechodnost.Items.Add(IntToStr(i)+': '+Self.prechodnost[i]);
     finally
       prechSorted.Free();
     end;

     Self.LV_Funkce.Items[0].Checked := true;
     for i := 1 to _MAX_FUNC do
       Self.LV_Funkce.Items[i].Checked := false;

     Self.SB_Take_Remove.Enabled := false;
     Self.SB_Rel_Remove.Enabled  := false;

     for i := 0 to _MAX_FUNC do
      begin
       Self.CB_funkce[i].Text := '';
       Self.RB_P[i].Checked := true;
      end;

    end else begin
     if (Self.new) then
       HV := Self.HVs.HVs[Self.CB_HV.ItemIndex-1]
     else
       HV := Self.HVs.HVs[Self.CB_HV.ItemIndex];

     Self.E_Name.Text := HV.Nazev;
     Self.E_Oznaceni.Text := HV.Oznaceni;
     Self.E_Majitel.Text := HV.Majitel;
     Self.E_Adresa.Text := IntToStr(HV.Adresa);
     Self.M_Poznamka.Text := HV.Poznamka;
     if (HV.Typ = THVType.other) then
       Self.RG_Trida.ItemIndex := Self.RG_Trida.Items.Count-1
     else
       Self.RG_Trida.ItemIndex := Integer(HV.Typ);
     Self.RG_StA.ItemIndex := Integer(HV.StanovisteA);
     Self.SE_MaxSpeed.Value := HV.maxRychlost;

     prechSorted := TList<Cardinal>.Create(Self.prechodnost.Keys);
     try
       prechSorted.Sort();
       Self.CB_Prechodnost.Clear();
       for j in prechSorted do
        begin
         Self.CB_Prechodnost.Items.Add(IntToStr(j)+': '+Self.prechodnost[j]);
         if (j = HV.prechodnost) then
           Self.CB_Prechodnost.ItemIndex := Self.CB_Prechodnost.Items.Count-1;
        end;
       if (not Self.prechodnost.ContainsKey(HV.prechodnost)) then
        begin
         Self.CB_Prechodnost.Items.Add(IntToStr(HV.prechodnost)+': ?');
         Self.CB_Prechodnost.ItemIndex := Self.CB_Prechodnost.Items.Count-1;
        end;
     finally
       prechSorted.Free();
     end;

     for i := 0 to _MAX_FUNC do
      Self.LV_Funkce.Items[i].Checked := HV.funkce[i];

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

     for i := 0 to _MAX_FUNC do
      begin
       Self.CB_funkce[i].Text := HV.funcVyznam[i];
       if (HV.funcType[i] = THVFuncType.permanent) then
         Self.RB_P[i].Checked := true
       else
         Self.RB_M[i].Checked := true;
      end;

    end;//if not New

  end else begin
   Self.B_Apply.Enabled := false;

   Self.E_Name.Enabled := false;
   Self.E_Oznaceni.Enabled := false;
   Self.E_Majitel.Enabled := false;
   Self.E_Adresa.Enabled := false;
   Self.M_Poznamka.Enabled := false;
   Self.RG_Trida.Enabled := false;
   Self.RG_StA.Enabled := false;
   Self.SE_MaxSpeed.Enabled := false;
   Self.CB_Prechodnost.Enabled := false;

   Self.E_Name.Text := '';
   Self.E_Oznaceni.Text := '';
   Self.E_Majitel.Text := '';
   Self.E_Adresa.Text := '';
   Self.M_Poznamka.Text := '';
   Self.RG_Trida.ItemIndex := -1;
   Self.RG_StA.ItemIndex := -1;
   Self.CB_Prechodnost.ItemIndex := -1;

   Self.LV_Funkce.Items[0].Checked := true;
   for i := 1 to _MAX_FUNC do
    Self.LV_Funkce.Items[i].Checked := false;

   Self.SB_Take_Add.Enabled := false;
   Self.SB_Rel_Add.Enabled := false;
   Self.LV_Pom_Load.Enabled := false;
   Self.LV_Pom_Release.Enabled := false;

   Self.LV_Funkce.Enabled := false;
   for i := 0 to _MAX_FUNC do
    begin
     Self.CB_funkce[i].Enabled := false;
     Self.CB_funkce[i].Text := '';
     Self.RB_P[i].Enabled := false;
     Self.RB_P[i].Checked := false;
     Self.RB_M[i].Enabled := false;
     Self.RB_M[i].Enabled := false;
    end;
  end;
end;

procedure TF_HVEdit.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Screen.Cursor := crDefault;
end;

procedure TF_HVEdit.FormCreate(Sender: TObject);
begin
 Self.vyznType := TDictionary<string, THVFuncType>.Create();
 Self.prechodnost := TDIctionary<Cardinal, string>.Create();
 Self.InitFunkce();
end;

procedure TF_HVEdit.FormDestroy(Sender: TObject);
begin
 Self.FreeFunkce();
 Self.vyznType.Free();
 Self.prechodnost.Free();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.HVAdd(sender_or:string; HVs:THVDb);
var arr: TWordAr; // not used
begin
 Self.sender_or := sender_or;
 Self.HVs := HVs;
 Self.new := true;

 HVs.FillHVs(Self.CB_HV, arr, -1, nil, true);
 Self.CB_HV.Items.Insert(0, 'Nepoužít šablonu');
 Self.CB_HV.ItemIndex := 0;
 Self.CB_HVChange(Self.CB_HV);

 Self.B_Search.Visible := true;

 Self.Caption := 'Vytvořit nové hnací vozidlo';
 Self.L_HV.Caption := 'Vytvořit hnací vozidlo na základě šablony:';
 Self.Show();
 Self.ActiveControl := Self.CB_HV;
end;

procedure TF_HVEdit.HVEdit(sender_or:string; HVs:THVDb);
var arr: TWordAr; // not used
begin
 Self.sender_or := sender_or;
 Self.new := false;
 Self.HVs := HVs;

 HVs.FillHVs(Self.CB_HV, arr, -1, nil, true);
 Self.CB_HVChange(Self.CB_HV);

 Self.B_Search.Visible := false;

 Self.Caption := 'Upravit hnací vozidlo';
 Self.L_HV.Caption := 'Hnací vozidlo:';
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
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.InitFunkce();
var i:Integer;
    LI:TListItem;
begin
 Self.LV_Funkce.Clear();

 for i := 0 to _MAX_FUNC do
  begin
   LI := Self.LV_Funkce.Items.Add;
   LI.Caption := 'F'+IntToStr(i);

   Self.CB_funkce[i] := TComboBox.Create(Self);
   with (Self.CB_funkce[i]) do
    begin
     Parent := Self.LV_Funkce;
     BevelInner := bvNone;
     BevelOuter := bvNone;
     BevelKind  := bkFlat;
     MaxLength  := 32;
     OnKeyPress := Self.M_PoznamkaKeyPress;
     OnChange   := Self.CB_VyznamChange;
     Tag        := i;
     Sorted     := true;
     DropDownCount := 12;
    end;

   Self.P_types[i] := TPanel.Create(Self);
   with (Self.P_types[i]) do
    begin
     Parent := Self.LV_Funkce;
     BevelOuter := bvNone;
     Color := LV_Funkce.Color;
     ParentBackground := false;
    end;

   Self.RB_P[i] := TRadioButton.Create(Self.P_types[i]);
   with (Self.RB_P[i]) do
    begin
     Parent := Self.P_types[i];
     Left := 5;
     Top := 2;
    end;

   Self.RB_M[i] := TRadioButton.Create(Self.P_types[i]);
   with (Self.RB_M[i]) do
    begin
     Parent := Self.P_types[i];
     Left := 20;
     Top := 2;
    end;
  end;//for

 Self.FOldListviewWindowProc := Self.LV_Funkce.WindowProc;
 Self.LV_Funkce.WindowProc := LV_FunkceWindowproc;
 Self.RepaintFunkce();
end;

procedure TF_HVEdit.FreeFunkce();
var i:Integer;
begin
 for i := 0 to _MAX_FUNC do
  begin
   FreeAndNil(Self.CB_funkce[i]);
   FreeAndNil(Self.P_types[i]);
  end;
end;

procedure TF_HVEdit.RepaintFunkce();
var i:Integer;
    r: TRect;
    SInfo: TScrollInfo;
    top_index: Integer;
begin
 SInfo.cbSize := SizeOf(SInfo);
 SInfo.fMask := SIF_ALL;
 GetScrollInfo(Self.LV_Funkce.Handle, SB_VERT, SInfo);
 top_index := SInfo.nPos;

 for i := 0 to _MAX_FUNC do
  begin
   with (Self.CB_funkce[i]) do
    begin
     ListView_GetSubItemRect(Self.LV_Funkce.Handle, i, 1, LVIR_BOUNDS, @r);
     BoundsRect := r;
     Visible := (i >= top_index);
    end;

   with (Self.P_types[i]) do
    begin
     ListView_GetSubItemRect(Self.LV_Funkce.Handle, i, 2, LVIR_BOUNDS, @r);
     BoundsRect := r;
     Visible := (i >= top_index);
    end;
  end;
end;

procedure TF_HVEdit.LV_FunkceWindowproc(var Message: TMessage);
begin
  Self.FOldListviewWindowProc(Message);
  Case Message.Msg Of
    WM_VSCROLL, WM_HSCROLL:
      If Message.WParamLo <> SB_ENDSCROLL Then
        Self.RepaintFunkce();
  End;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.ParseVyznamy(vyznamy:string);
var i:Integer;
    sl, sl2, vyznamySl:TStrings;
    str:string;
begin
 Self.vyznType.Clear();
 sl := TStringList.Create();
 sl2 := TStringList.Create();
 vyznamySl := TStringList.Create();
 try
   ExtractStringsEx([';'], [], vyznamy, sl);
   for str in sl do
    begin
     sl2.Clear();
     ExtractStringsEx([':'], [], str, sl2);
     vyznamySl.Add(sl2[0]);
     if (sl2.Count > 1) then
       Self.vyznType.AddOrSetValue(sl2[0], THV.CharToHVFuncType(sl2[1][1]));
    end;

   for i := 0 to _MAX_FUNC do
    begin
     Self.CB_funkce[i].Items.Clear();
     Self.CB_funkce[i].Items.AddStrings(vyznamySl);
    end;
 finally
   sl.Free();
   sl2.Free();
   vyznamySl.Free();
 end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.CB_VyznamChange(Sender: TObject);
var func:Integer;
begin
 func := TComboBox(Sender).Tag;
 if (Self.vyznType.ContainsKey(TComboBox(Sender).Text)) then
  begin
   if (Self.vyznType[TComboBox(Sender).Text] = THVFuncType.momentary) then
     Self.RB_M[func].Checked := true
   else
     Self.RB_P[func].Checked := true;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.LoadPrechodnost(ini: TMemIniFile);
const _SECTION: string = 'prechodnost';
var strs: TStrings;
    str: string;
begin
 Self.prechodnost.Clear();
 strs := TStringList.Create();
 try
   ini.ReadSection(_SECTION, strs);
   for str in strs do
     Self.prechodnost.Add(StrToInt(str), ini.ReadString(_SECTION, str, ''));
 finally
   strs.Free();
 end;

 if (not Self.prechodnost.ContainsKey(0)) then
   Self.prechodnost.Add(0, 'základní');
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.ServerEditResp(parsed: TStrings);
var err: string;
begin
 if (not Self.Showing or Self.new) then Exit();
 Screen.Cursor := crDefault;

 if (parsed[4] = 'ERR') then
  begin
   if (parsed.Count >= 6) then
     err := parsed[5]
   else
     err := 'neznámá chyba';

   Application.MessageBox(PChar('Při úpravě HV nastala chyba:'+#13#10+err), 'Chyba', MB_OK OR MB_ICONWARNING);
  end else if (parsed[4] = 'OK') then
    Self.Close();
end;

procedure TF_HVEdit.ServerAddResp(parsed: TStrings);
var err: string;
begin
 if (not Self.Showing or not Self.new) then Exit();
 Screen.Cursor := crDefault;

 if (parsed[4] = 'ERR') then
  begin
   if (parsed.Count >= 6) then
     err := parsed[5]
   else
     err := 'neznámá chyba';

   Application.MessageBox(PChar('Při přidávání HV nastala chyba:'+#13#10+err), 'Chyba', MB_OK OR MB_ICONWARNING);
  end else if (parsed[4] = 'OK') then
    Self.Close();
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
