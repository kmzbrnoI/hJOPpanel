unit fHVEdit;

{
  Okno editace vlastnosti hnacicho vozidla.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, HVDb, RPConst, TCPClientPanel, ComCtrls, Buttons,
  Generics.Collections, AppEvnts;

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
  private
    { Private declarations }

    HVIndexes:TWordAr;
    HVs:THVDb;
    new:boolean;
    sender_or:string;
    CB_funkce:array[0.._MAX_FUNC] of TComboBox;
    RB_P:array[0.._MAX_FUNC] of TRadioButton;
    RB_M:array[0.._MAX_FUNC] of TRadioButton;
    P_types:array[0.._MAX_FUNC] of TPanel;
    FOldListviewWindowProc: TWndMethod;

    procedure InitFunkce();
    procedure FreeFunkce();
    procedure RepaintFunkce();
    procedure LV_FunkceWindowproc(var Message: TMessage);

  public
    { Public declarations }

    procedure HVAdd(sender_or:string; HVs:THVDb);
    procedure HVEdit(sender_or:string; HVs:THVDb);
    procedure ParseVyznamy(vyznamy:string);
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
 for j := 0 to Length(_forbidden_chars)-1 do
   if (strscan(PChar(Self.M_Poznamka.Text), _forbidden_chars[j]) <> nil) then
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
     Application.MessageBox(PChar('Význam funkce obsahuje zakázaný znak ":" (dvojteèka)!'), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
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
     newVyznamy := newVyznamy + '{' + Self.CB_funkce[i].Text + '};';
  end;//for i
 if (newVyznamy <> '') then
  PanelTCPClient.SendLn('-;F-VYZN-ADD;{'+newVyznamy+'}');

 HV.Free();
 Self.Close();
end;//procedure

procedure TF_HVEdit.B_CancelClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HVEdit.B_SearchClick(Sender: TObject);
begin
 if (Self.E_Adresa.Text = '') then
  begin
   Application.MessageBox('Vyplòte adresu hnacího vozidla!', 'Nelze pokraèovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 PanelTCPClient.SendLn('-;LOK;'+Self.E_Adresa.Text+';ASK');
end;

procedure TF_HVEdit.CB_HVChange(Sender: TObject);
var HV:THV;
    LI:TListItem;
    pomCv:THVPomCv;
    i:Integer;
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

   Self.SB_Take_Add.Enabled    := true;
   Self.SB_Rel_Add.Enabled     := true;
   Self.LV_Pom_Load.Enabled    := true;
   Self.LV_Pom_Release.Enabled := true;

   Self.LV_Funkce.Enabled := true;
   for i := 0 to _MAX_FUNC do
    begin
     Self.CB_funkce[i].Enabled := true;
     Self.RB_P[i].Enabled := true;
     Self.RB_M[i].Enabled := true;
    end;

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

   Self.E_Name.Enabled      := false;
   Self.E_Oznaceni.Enabled  := false;
   Self.E_Majitel.Enabled   := false;
   Self.E_Adresa.Enabled    := false;
   Self.M_Poznamka.Enabled  := false;
   Self.RG_Trida.Enabled    := false;
   Self.RG_StA.Enabled      := false;

   Self.E_Name.Text         := '';
   Self.E_Oznaceni.Text     := '';
   Self.E_Majitel.Text      := '';
   Self.E_Adresa.Text       := '';
   Self.M_Poznamka.Text     := '';
   Self.RG_Trida.ItemIndex  := -1;
   Self.RG_StA.ItemIndex    := -1;

   Self.LV_Funkce.Items[0].Checked := true;
   for i := 1 to _MAX_FUNC do
    Self.LV_Funkce.Items[i].Checked := false;

   Self.SB_Take_Add.Enabled    := false;
   Self.SB_Rel_Add.Enabled     := false;
   Self.LV_Pom_Load.Enabled    := false;
   Self.LV_Pom_Release.Enabled := false;

   Self.LV_Funkce.Enabled := false;
   for i := 0 to _MAX_FUNC do
    begin
     Self.CB_funkce[i].Enabled := false;
     Self.CB_funkce[i].Text    := '';
     Self.RB_P[i].Enabled := false;
     Self.RB_P[i].Checked := false;
     Self.RB_M[i].Enabled := false;
     Self.RB_M[i].Enabled := false;
    end;

  end;

end;//procedure

procedure TF_HVEdit.FormCreate(Sender: TObject);
begin
 Self.InitFunkce();
end;

procedure TF_HVEdit.FormDestroy(Sender: TObject);
begin
 Self.FreeFunkce();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HVEdit.HVAdd(sender_or:string; HVs:THVDb);
var i:Integer;
begin
 Self.sender_or := sender_or;
 Self.HVs       := HVs;
 Self.new       := true;

 Self.CB_HV.Enabled := false;
 Self.CB_HV.Clear();
 Self.CB_HVChange(Self.CB_HV);
 Self.CB_HV.Items.Add('Nové hnací vozidlo');
 Self.CB_HV.ItemIndex := 0;

 Self.E_Name.Text         := '';
 Self.E_Oznaceni.Text     := '';
 Self.E_Majitel.Text      := '';
 Self.E_Adresa.Text       := '';
 Self.M_Poznamka.Text     := '';
 Self.RG_Trida.ItemIndex  := -1;
 Self.RG_StA.ItemIndex    := -1;

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

 Self.B_Search.Visible := true;

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

 Self.B_Search.Visible := false;

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
end;//procedure

procedure TF_HVEdit.FreeFunkce();
var i:Integer;
begin
 for i := 0 to _MAX_FUNC do
  begin
   FreeAndNil(Self.CB_funkce[i]);
   FreeAndNil(Self.P_types[i]);
  end;
end;//procedure

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
end;//procedure

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
    sl:TStrings;
begin
 sl := TStringList.Create();
 ExtractStringsEx([';'], [], vyznamy, sl);

 for i := 0 to _MAX_FUNC do
  begin
   Self.CB_funkce[i].Items.Clear();
   Self.CB_funkce[i].Items.AddStrings(sl);
  end;//for i

 sl.Free();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

end.//unit
