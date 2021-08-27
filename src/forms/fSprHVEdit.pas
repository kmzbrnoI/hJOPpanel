unit fSprHVEdit;

{
  Okno editace HV v ramci editace soupravy.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, HVDb, RPConst, ComCtrls;

type
  TF_SprHVEdit = class(TForm)
    CB_HV1_HV: TComboBox;
    RG_HV1_dir: TRadioGroup;
    M_HV1_Notes: TMemo;
    L_S09: TLabel;
    PC_Funkce: TPageControl;
    TS_F0_F14: TTabSheet;
    TS_F15_F28: TTabSheet;
    procedure M_HV1_NotesKeyPress(Sender: TObject; var Key: Char);
    procedure CB_HV1_HVChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    HVs: THVDb;
    sprHV: THV;

    Indexes: TWordAr;

    function GetHV(addr: Word): THV;
    function GetCurrentHV(): THV;

    procedure CreateCHBFunkce();
    procedure DestroyCHBFunkce();

  public
    CHB_funkce: array [0 .. _MAX_FUNC] of TCheckBox;

    procedure FillHV(HVs: THVDb; sprHV: THV);
    function GetHVString(): string;
    property HV: THV read GetCurrentHV;
  end;

var
  F_SprHVEdit: TF_SprHVEdit;

implementation

{$R *.dfm}

procedure TF_SprHVEdit.M_HV1_NotesKeyPress(Sender: TObject; var Key: Char);
var i: Integer;
begin
  // osetreni vstupu
  for i := 0 to Length(_forbidden_chars) - 1 do
    if (_forbidden_chars[i] = Key) then
    begin
      Key := #0;
      Exit();
    end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_SprHVEdit.CB_HV1_HVChange(Sender: TObject);
var HV: THV;
  i: Integer;
  str: string;
begin
  if (Self.CB_HV1_HV.ItemIndex < 0) then
  begin
    Self.RG_HV1_dir.Enabled := false;
    Self.M_HV1_Notes.Enabled := false;

    for i := 0 to _MAX_FUNC do
    begin
      Self.CHB_funkce[i].Enabled := false;
      Self.CHB_funkce[i].Checked := false;
      Self.CHB_funkce[i].Caption := 'F' + IntToStr(i);
    end;

    Self.RG_HV1_dir.ItemIndex := -1;
    Self.M_HV1_Notes.Text := '';
  end else begin
    Self.RG_HV1_dir.Enabled := true;
    Self.M_HV1_Notes.Enabled := true;

    HV := Self.GetHV(Self.Indexes[Self.CB_HV1_HV.ItemIndex]);
    if (HV = nil) then
      Exit(); // tohleto by se teoreticky nikdy nemelo stat

    for i := 0 to _MAX_FUNC do
    begin
      Self.CHB_funkce[i].Visible := true;
      Self.CHB_funkce[i].Enabled := ((HV.funcType[i] = THVFuncType.permanent) or (HV.functions[i]));
      Self.CHB_funkce[i].Checked := HV.functions[i];
      str := 'F' + IntToStr(i);
      if (HV.funcType[i] = THVFuncType.momentary) then
        str := str + ' [M]';
      if (HV.funcDesc[i] <> '') then
        str := str + ': ' + HV.funcDesc[i];
      Self.CHB_funkce[i].Caption := str;
    end;

    Self.RG_HV1_dir.ItemIndex := Integer(HV.siteA);
    Self.M_HV1_Notes.Text := HV.note;
  end; // else

end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_SprHVEdit.FillHV(HVs: THVDb; sprHV: THV);
begin
  Self.HVs := HVs;
  Self.sprHV := sprHV;

  if (sprHV = nil) then
    HVs.FillHVs(Self.CB_HV1_HV, Self.Indexes)
  else
    HVs.FillHVs(Self.CB_HV1_HV, Self.Indexes, sprHV.addr, sprHV);

  Self.CB_HV1_HVChange(Self.CB_HV1_HV);
  Self.PC_Funkce.ActivePageIndex := 0;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_SprHVEdit.FormCreate(Sender: TObject);
begin
  Self.CreateCHBFunkce();
end;

procedure TF_SprHVEdit.FormDestroy(Sender: TObject);
begin
  Self.DestroyCHBFunkce();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TF_SprHVEdit.GetHVString(): string;
var HV: THV;
  i: Integer;
begin
  HV := THV.Create();

  HV.siteA := THVSite(Self.RG_HV1_dir.ItemIndex);
  HV.addr := Self.Indexes[Self.CB_HV1_HV.ItemIndex];
  HV.note := Self.M_HV1_Notes.Text;

  for i := 0 to _MAX_FUNC do
    HV.functions[i] := Self.CHB_funkce[i].Checked;

  Result := '[{' + HV.GetPanelLokString() + '}]';
end;

/// /////////////////////////////////////////////////////////////////////////////

function TF_SprHVEdit.GetHV(addr: Word): THV;
var HV: THV;
begin
  // nejdrive hledame lokomotivu ve hnacim vozidle k souprave
  if (Assigned(Self.sprHV)) then
    if (Self.sprHV.addr = addr) then
      Exit(Self.sprHV);

  // pak hledame hnaci vozidlo v HVs, ktere mame k dispozici
  if (Assigned(Self.HVs)) then
    for HV in Self.HVs.HVs do
      if (HV.addr = addr) then
        Exit(HV);

  Exit(nil);
end;

function TF_SprHVEdit.GetCurrentHV(): THV;
begin
  if (Self.CB_HV1_HV.ItemIndex < 0) then
    Result := nil
  else
    Result := Self.GetHV(Self.Indexes[Self.CB_HV1_HV.ItemIndex]);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_SprHVEdit.CreateCHBFunkce();
var i: Integer;
  atop: Integer;
begin
  atop := 0;

  for i := 0 to _MAX_FUNC do
  begin
    Self.CHB_funkce[i] := TCheckBox.Create(Self);

    with (Self.CHB_funkce[i]) do
    begin
      if (i < 15) then
        Parent := Self.TS_F0_F14
      else
        Parent := Self.TS_F15_F28;

      Top := atop;
      Left := 2;
      Caption := 'F' + IntToStr(i);
      AutoSize := false;
      Width := 160;

      atop := atop + 16;
      if (i = 14) then
        atop := 16;
    end; // with
  end; // for i
end;

procedure TF_SprHVEdit.DestroyCHBFunkce();
var i: Integer;
begin
  for i := 0 to _MAX_FUNC do
    Self.CHB_funkce[i].Free();
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
