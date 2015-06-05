unit SprHVEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, HVDb, RPConst;

type
  TF_SprHVEdit = class(TForm)
    CB_HV1_HV: TComboBox;
    RG_HV1_dir: TRadioGroup;
    M_HV1_Notes: TMemo;
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
    L_S09: TLabel;
    procedure M_HV1_NotesKeyPress(Sender: TObject; var Key: Char);
    procedure CB_HV1_HVChange(Sender: TObject);
  private
    HVs:THVDb;
    sprHV:THV;

    Indexes: TWordAr;

    function GetHV(addr:Word):THV;

  public

    constructor FillHV(HVs:THVDb; sprHV:THV);
    function GetHVString():string;

  end;

var
  F_SprHVEdit: TF_SprHVEdit;

implementation

{$R *.dfm}

procedure TF_SprHVEdit.M_HV1_NotesKeyPress(Sender: TObject; var Key: Char);
begin
 case (key) of
  #13, '/', '\', '|', '(', ')', '[', ']', '-', ';': Key := #0;
 end;//case
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprHVEdit.CB_HV1_HVChange(Sender: TObject);
var HV:THV;
begin
 if (Self.CB_HV1_HV.ItemIndex < 0) then
  begin
   Self.RG_HV1_dir.Enabled     := false;
   Self.M_HV1_Notes.Enabled    := false;
   Self.CHB_HV1_Svetla.Enabled := false;
   Self.CHB_HV1_F1.Enabled     := false;
   Self.CHB_HV1_F2.Enabled     := false;
   Self.CHB_HV1_F3.Enabled     := false;
   Self.CHB_HV1_F4.Enabled     := false;
   Self.CHB_HV1_F5.Enabled     := false;
   Self.CHB_HV1_F6.Enabled     := false;
   Self.CHB_HV1_F7.Enabled     := false;
   Self.CHB_HV1_F8.Enabled     := false;
   Self.CHB_HV1_F9.Enabled     := false;
   Self.CHB_HV1_F10.Enabled    := false;
   Self.CHB_HV1_F11.Enabled    := false;
   Self.CHB_HV1_F12.Enabled    := false;

   Self.RG_HV1_dir.ItemIndex   := -1;
   Self.M_HV1_Notes.Text       := '';
   Self.CHB_HV1_Svetla.Checked := false;
   Self.CHB_HV1_F1.Checked     := false;
   Self.CHB_HV1_F2.Checked     := false;
   Self.CHB_HV1_F3.Checked     := false;
   Self.CHB_HV1_F4.Checked     := false;
   Self.CHB_HV1_F5.Checked     := false;
   Self.CHB_HV1_F6.Checked     := false;
   Self.CHB_HV1_F7.Checked     := false;
   Self.CHB_HV1_F8.Checked     := false;
   Self.CHB_HV1_F9.Checked     := false;
   Self.CHB_HV1_F10.Checked    := false;
   Self.CHB_HV1_F11.Checked    := false;
   Self.CHB_HV1_F12.Checked    := false;
  end else begin
   Self.RG_HV1_dir.Enabled     := true;
   Self.M_HV1_Notes.Enabled    := true;
   Self.CHB_HV1_Svetla.Enabled := true;
   Self.CHB_HV1_F1.Enabled     := true;
   Self.CHB_HV1_F2.Enabled     := true;
   Self.CHB_HV1_F3.Enabled     := true;
   Self.CHB_HV1_F4.Enabled     := true;
   Self.CHB_HV1_F5.Enabled     := true;
   Self.CHB_HV1_F6.Enabled     := true;
   Self.CHB_HV1_F7.Enabled     := true;
   Self.CHB_HV1_F8.Enabled     := true;
   Self.CHB_HV1_F9.Enabled     := true;
   Self.CHB_HV1_F10.Enabled    := true;
   Self.CHB_HV1_F11.Enabled    := true;
   Self.CHB_HV1_F12.Enabled    := true;

   HV := Self.GetHV(Self.Indexes[Self.CB_HV1_HV.ItemIndex]);
   if (HV = nil) then Exit();        // tohleto by se teoreticky nikdy nemelo stat

   Self.RG_HV1_dir.ItemIndex   := Integer(HV.StanovisteA);
   Self.M_HV1_Notes.Text       := HV.Poznamka;
   Self.CHB_HV1_Svetla.Checked := HV.funkce[0];
   Self.CHB_HV1_F1.Checked     := HV.funkce[1];
   Self.CHB_HV1_F2.Checked     := HV.funkce[2];
   Self.CHB_HV1_F3.Checked     := HV.funkce[3];
   Self.CHB_HV1_F4.Checked     := HV.funkce[4];
   Self.CHB_HV1_F5.Checked     := HV.funkce[5];
   Self.CHB_HV1_F6.Checked     := HV.funkce[6];
   Self.CHB_HV1_F7.Checked     := HV.funkce[7];
   Self.CHB_HV1_F8.Checked     := HV.funkce[8];
   Self.CHB_HV1_F9.Checked     := HV.funkce[9];
   Self.CHB_HV1_F10.Checked    := HV.funkce[10];
   Self.CHB_HV1_F11.Checked    := HV.funkce[11];
   Self.CHB_HV1_F12.Checked    := HV.funkce[12];
  end;//else

end;

////////////////////////////////////////////////////////////////////////////////

constructor TF_SprHVEdit.FillHV(HVs:THVDb; sprHV:THV);
begin
 Self.HVs   := HVs;
 Self.sprHV := sprHV;

 if (sprHV = nil) then
   HVs.FillHVs(Self.CB_HV1_HV, Self.Indexes)
 else
   HVs.FillHVs(Self.CB_HV1_HV, Self.Indexes, sprHV.Adresa, sprHV);

 Self.CB_HV1_HVChange(Self.CB_HV1_HV);
end;//contructor

////////////////////////////////////////////////////////////////////////////////

function TF_SprHVEdit.GetHVString():string;
var HV:THV;
begin
 HV := THV.Create();

 HV.StanovisteA := THVStanoviste(Self.RG_HV1_dir.ItemIndex);
 HV.Adresa      := Self.Indexes[Self.CB_HV1_HV.ItemIndex];
 HV.Poznamka    := Self.M_HV1_Notes.Lines[0];
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

 Result := '[' + HV.GetPanelLokString() + ']';
end;//function

////////////////////////////////////////////////////////////////////////////////

function TF_SprHVEdit.GetHV(addr:Word):THV;
var i:Integer;
begin
 // nejdrive hledame lokomotivu ve hnacim vozidle k souprave
 if (Assigned(Self.sprHV)) then
  if (Self.sprHV.Adresa = addr) then
    Exit(Self.sprHV);

 // pak hledame hnaci vozidlo v HVs, ktere mame k dispozici
 if (Assigned(Self.HVs)) then
   for i := 0 to Self.HVs.count-1 do
    if (Self.HVs.HVs[i].Adresa = addr) then
      Exit(Self.HVs.HVs[i]);

 Exit(nil);
end;//function

////////////////////////////////////////////////////////////////////////////////

end.//unit
