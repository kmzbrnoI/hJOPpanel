unit fRVDelete;

{
  Confirmation window for engine delete.
}

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  RVDb, RPConst, TCPClientPanel;

type
  TF_RVDelete = class(TForm)
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    Label1: TLabel;
    CB_RV: TComboBox;
    B_Storno: TButton;
    B_Remove: TButton;
    procedure B_StornoClick(Sender: TObject);
    procedure B_RemoveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }

    sender_or: string;
    RVIndexes: TWordAr;
  public
    { Public declarations }

    procedure OpenForm(sender_or: string; RVs: TRVDb);
    procedure ServerResp(parsed: TStrings);
  end;

var
  F_RVDelete: TF_RVDelete;

implementation

{$R *.dfm}

procedure TF_RVDelete.B_RemoveClick(Sender: TObject);
begin
  if (Self.CB_RV.ItemIndex < 0) then
  begin
    Application.MessageBox('Vyberte vozdilo', 'Nelz pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  if (Application.MessageBox(PChar('Opravdu odstranit vozidlo ' + Self.CB_RV.Items.Strings[Self.CB_RV.ItemIndex] +
    ' z databáze?'), 'Opravdu?', MB_YESNO OR MB_ICONWARNING) = mrYes) then
  begin
    PanelTCPClient.PanelRVRemove(Self.sender_or, Self.RVIndexes[Self.CB_RV.ItemIndex]);
    Screen.Cursor := crHourGlass;
  end;
end;

procedure TF_RVDelete.B_StornoClick(Sender: TObject);
begin
  Self.Close();
end;

procedure TF_RVDelete.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Screen.Cursor := crDefault;
end;

procedure TF_RVDelete.OpenForm(sender_or: string; RVs: TRVDb);
begin
  Self.sender_or := sender_or;
  RVs.Fill(Self.CB_RV, Self.RVIndexes);
  Self.Show();
end;

procedure TF_RVDelete.ServerResp(parsed: TStrings);
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

    Application.MessageBox(PChar('Při odstraňování vozidla nastala chyba:' + #13#10 + err), 'Chyba',
      MB_OK OR MB_ICONWARNING);
  end else if (parsed[4] = 'OK') then
  begin
    Application.MessageBox(PChar('Vozidlo ' + parsed[3] + ' odstraněno.'), 'Chyba', MB_OK OR MB_ICONINFORMATION);
    Self.Close();
  end;
end;

end.
