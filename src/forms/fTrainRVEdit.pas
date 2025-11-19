unit fTrainRVEdit;

{
  Edit engine in train edit window.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, RVDb, RPConst, ComCtrls;

type
  TF_TrainRVEdit = class(TForm)
    CB_RV: TComboBox;
    RG_direction: TRadioGroup;
    M_note: TMemo;
    L_S09: TLabel;
    PC_functions: TPageControl;
    TS_F0_F14: TTabSheet;
    TS_F15_F28: TTabSheet;
    procedure M_noteKeyPress(Sender: TObject; var Key: Char);
    procedure CB_RVChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    RVs: TRVDb;
    trainRV: TRV;

    Indexes: TWordAr;

    function GetRV(addr: Word): TRV;
    function GetCurrentRV(): TRV;

    procedure CreateCHBFunkce();
    procedure DestroyCHBFunkce();

  public
    CHB_funkce: array [0 .. _MAX_FUNC] of TCheckBox;

    procedure FillRV(RVs: TRVDb; trainRV: TRV);
    function GetRVString(): string;
    property vehicle: TRV read GetCurrentRV;
  end;

var
  F_TrainRVEdit: TF_TrainRVEdit;

implementation

{$R *.dfm}

procedure TF_TrainRVEdit.M_noteKeyPress(Sender: TObject; var Key: Char);
begin
  for var i := 0 to Length(_forbidden_chars) - 1 do
    if (_forbidden_chars[i] = Key) then
    begin
      Key := #0;
      Exit();
    end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainRVEdit.CB_RVChange(Sender: TObject);
begin
  if (Self.CB_RV.ItemIndex < 0) then
  begin
    Self.RG_direction.Enabled := false;
    Self.M_note.Enabled := false;

    for var i := 0 to _MAX_FUNC do
    begin
      Self.CHB_funkce[i].Enabled := false;
      Self.CHB_funkce[i].Checked := false;
      Self.CHB_funkce[i].Caption := 'F' + IntToStr(i);
    end;

    Self.RG_direction.ItemIndex := -1;
    Self.M_note.Text := '';
  end else begin
    Self.RG_direction.Enabled := true;
    Self.M_note.Enabled := true;

    var vehicle := Self.GetRV(Self.Indexes[Self.CB_RV.ItemIndex]);
    if (vehicle = nil) then
      Exit(); // tohleto by se teoreticky nikdy nemelo stat

    for var i := 0 to _MAX_FUNC do
    begin
      Self.CHB_funkce[i].Visible := true;
      Self.CHB_funkce[i].Enabled := ((vehicle.funcType[i] = TRVFuncType.permanent) or (vehicle.functions[i]));
      Self.CHB_funkce[i].Checked := vehicle.functions[i];
      var str := 'F' + IntToStr(i);
      if (vehicle.funcType[i] = TRVFuncType.momentary) then
        str := str + ' [M]';
      if (vehicle.funcDesc[i] <> '') then
        str := str + ': ' + vehicle.funcDesc[i];
      Self.CHB_funkce[i].Caption := str;
    end;

    Self.RG_direction.ItemIndex := Integer(vehicle.siteA);
    Self.M_note.Text := vehicle.note;
  end;

end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainRVEdit.FillRV(RVs: TRVDb; trainRV: TRV);
begin
  Self.RVs := RVs;
  Self.trainRV := trainRV;

  if (trainRV = nil) then
    RVs.Fill(Self.CB_RV, Self.Indexes)
  else
    RVs.Fill(Self.CB_RV, Self.Indexes, trainRV.addr, trainRV);

  Self.CB_RVChange(Self.CB_RV);
  Self.PC_functions.ActivePageIndex := 0;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainRVEdit.FormCreate(Sender: TObject);
begin
  Self.CreateCHBFunkce();
end;

procedure TF_TrainRVEdit.FormDestroy(Sender: TObject);
begin
  Self.DestroyCHBFunkce();
end;

/// /////////////////////////////////////////////////////////////////////////////

function TF_TrainRVEdit.GetRVString(): string;
begin
  var vehicle: TRV := TRV.Create();

  vehicle.siteA := TRVSite(Self.RG_direction.ItemIndex);
  vehicle.addr := Self.Indexes[Self.CB_RV.ItemIndex];
  vehicle.note := Self.M_note.Text;

  for var i: Integer := 0 to _MAX_FUNC do
    vehicle.functions[i] := Self.CHB_funkce[i].Checked;

  Result := '[{' + vehicle.GetPanelLokString() + '}]';
end;

/// /////////////////////////////////////////////////////////////////////////////

function TF_TrainRVEdit.GetRV(addr: Word): TRV;
begin
  // nejdrive hledame vozidlo ve hnacim vozidle k vlaku
  if (Assigned(Self.trainRV)) then
    if (Self.trainRV.addr = addr) then
      Exit(Self.trainRV);

  // pak hledame hnaci vozidlo v HVs, ktere mame k dispozici
  if (Assigned(Self.RVs)) then
    for var vehicle in Self.RVs do
      if (vehicle.addr = addr) then
        Exit(vehicle);

  Exit(nil);
end;

function TF_TrainRVEdit.GetCurrentRV(): TRV;
begin
  if (Self.CB_RV.ItemIndex < 0) then
    Result := nil
  else
    Result := Self.GetRV(Self.Indexes[Self.CB_RV.ItemIndex]);
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_TrainRVEdit.CreateCHBFunkce();
var atop: Integer;
begin
  atop := 0;

  for var i: Integer := 0 to _MAX_FUNC do
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
      Width := Self.TS_F0_F14.Width - 2*Left;

      atop := atop + Height - 1;
      if (i = 14) then
        atop := Height - 1;
    end; // with
  end; // for i
end;

procedure TF_TrainRVEdit.DestroyCHBFunkce();
begin
  for var i := 0 to _MAX_FUNC do
    Self.CHB_funkce[i].Free();
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
