unit fRVMoveArea;

{
  Move engine to different area.
}

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  RVDb, RPConst, ComCtrls, SysUtils;

type
  TF_RV_Move = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    CB_Stanice: TComboBox;
    B_Storno: TButton;
    B_OK: TButton;
    LV_Vehicles: TListView;
    procedure B_StornoClick(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    sender_id: string;
    successfully_moved: Integer;
    to_move: Integer;

  public
    procedure Open(Sender: string; RVs: TRVDb);
    procedure ServerResp(parsed: TStrings);
  end;

var
  F_RV_Move: TF_RV_Move;

implementation

{$R *.dfm}

uses OrList, TCPClientPanel;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_RV_Move.B_OKClick(Sender: TObject);
begin
  if (Self.LV_Vehicles.Selected = nil) then
  begin
    Application.MessageBox('Vyberte alespoň jedno vozidlo!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;
  if (Self.CB_Stanice.ItemIndex < 0) then
  begin
    Application.MessageBox('Vyberte stanici!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  Self.successfully_moved := 0;
  Self.to_move := 0;
  for var LI in Self.LV_Vehicles.Items do
    if (LI.Selected) then
      Inc(Self.to_move);

  for var LI in Self.LV_Vehicles.Items do
    if (LI.Selected) then
      PanelTCPClient.PanelLokMove(Self.sender_id, Integer(LI.Data), areaDb.db_reverse[Self.CB_Stanice.Text]);

  Screen.Cursor := crHourGlass;
end;

procedure TF_RV_Move.B_StornoClick(Sender: TObject);
begin
  Self.Close();
end;

procedure TF_RV_Move.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Screen.Cursor := crDefault;
end;

procedure TF_RV_Move.Open(Sender: string; RVs: TRVDb);
begin
  Self.sender_id := Sender;

  Self.LV_Vehicles.Clear();
  for var vehicle in RVs do
  begin
    if (vehicle.train = '-') then
    begin
      var LI := Self.LV_Vehicles.Items.Add();
      LI.Caption := IntToStr(vehicle.addr);
      LI.SubItems.Add(vehicle.name);
      LI.SubItems.Add(vehicle.designation);
      LI.Data := Pointer(vehicle.addr);
    end;
  end;

  Self.CB_Stanice.Clear();
  for var name in areaDb.names_sorted do
    Self.CB_Stanice.Items.Add(name);

  Self.ActiveControl := Self.LV_Vehicles;
  Self.Show();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_RV_Move.ServerResp(parsed: TStrings);
var err: string;
begin
  if (not Self.Showing) then
    Exit();
  Screen.Cursor := crDefault;

  if (parsed[4] = 'ERR') then
  begin
    if (parsed.Count >= 6) then
      err := parsed[5]
    else
      err := 'neznámá chyba';

    Application.MessageBox(PChar('Při přesouvání vozidla ' + parsed[2] + ' nastala chyba:' + #13#10 + err), 'Chyba',
      MB_OK OR MB_ICONWARNING);
  end else if (parsed[4] = 'OK') then
  begin
    Inc(Self.successfully_moved);
    if (Self.successfully_moved = Self.to_move) then
      Self.Close();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
