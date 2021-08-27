unit fHVMoveSt;

{
  Move engine to different area.
}

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  HVDb, RPConst, ComCtrls, SysUtils;

type
  TF_HV_Move = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    CB_Stanice: TComboBox;
    B_Storno: TButton;
    B_OK: TButton;
    LV_HVs: TListView;
    procedure B_StornoClick(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    sender_id: string;
    successfully_moved: Integer;
    to_move: Integer;

  public
    procedure Open(Sender: string; HVs: THVDb);
    procedure ServerResp(parsed: TStrings);
  end;

var
  F_HV_Move: TF_HV_Move;

implementation

{$R *.dfm}

uses OrList, TCPClientPanel;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_HV_Move.B_OKClick(Sender: TObject);
begin
  if (Self.LV_HVs.Selected = nil) then
  begin
    Application.MessageBox('Vyberte alespoň jedno hnací vozidlo!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;
  if (Self.CB_Stanice.ItemIndex < 0) then
  begin
    Application.MessageBox('Vyberte stanici!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  Self.successfully_moved := 0;
  Self.to_move := 0;
  for var LI in Self.LV_HVs.Items do
    if (LI.Selected) then
      Inc(Self.to_move);

  for var LI in Self.LV_HVs.Items do
    if (LI.Selected) then
      PanelTCPClient.PanelLokMove(Self.sender_id, Integer(LI.Data), areaDb.db_reverse[Self.CB_Stanice.Text]);

  Screen.Cursor := crHourGlass;
end;

procedure TF_HV_Move.B_StornoClick(Sender: TObject);
begin
  Self.Close();
end;

procedure TF_HV_Move.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Screen.Cursor := crDefault;
end;

procedure TF_HV_Move.Open(Sender: string; HVs: THVDb);
begin
  Self.sender_id := Sender;

  Self.LV_HVs.Clear();
  for var HV in HVs.HVs do
  begin
    if (HV.train = '-') then
    begin
      var LI := Self.LV_HVs.Items.Add();
      LI.Caption := IntToStr(HV.addr);
      LI.SubItems.Add(HV.name);
      LI.SubItems.Add(HV.designation);
      LI.Data := Pointer(HV.addr);
    end;
  end;

  Self.CB_Stanice.Clear();
  for var name in areaDb.names_sorted do
    Self.CB_Stanice.Items.Add(name);

  Self.ActiveControl := Self.LV_HVs;
  Self.Show();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_HV_Move.ServerResp(parsed: TStrings);
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

    Application.MessageBox(PChar('Při přesouvání HV ' + parsed[2] + ' nastala chyba:' + #13#10 + err), 'Chyba',
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
