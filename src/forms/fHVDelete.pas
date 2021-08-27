unit fHVDelete;

{
  Confirmation window for engine delete.
}

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  HVDb, RPConst, TCPClientPanel;

type
  TF_HVDelete = class(TForm)
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    Label1: TLabel;
    CB_HV: TComboBox;
    B_Storno: TButton;
    B_Remove: TButton;
    procedure B_StornoClick(Sender: TObject);
    procedure B_RemoveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }

    sender_or: string;
    HVIndexes: TWordAr;
  public
    { Public declarations }

    procedure OpenForm(sender_or: string; HVs: THVDb);
    procedure ServerResp(parsed: TStrings);
  end;

var
  F_HVDelete: TF_HVDelete;

implementation

{$R *.dfm}

procedure TF_HVDelete.B_RemoveClick(Sender: TObject);
begin
  if (Self.CB_HV.ItemIndex < 0) then
  begin
    Application.MessageBox('Vyberte hnací vozdilo', 'Nelz pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  if (Application.MessageBox(PChar('Opravdu odstranit hnací vozidlo ' + Self.CB_HV.Items.Strings[Self.CB_HV.ItemIndex] +
    ' z databáze?'), 'Opravdu?', MB_YESNO OR MB_ICONWARNING) = mrYes) then
  begin
    PanelTCPClient.PanelHVRemove(Self.sender_or, Self.HVIndexes[Self.CB_HV.ItemIndex]);
    Screen.Cursor := crHourGlass;
  end;
end;

procedure TF_HVDelete.B_StornoClick(Sender: TObject);
begin
  Self.Close();
end;

procedure TF_HVDelete.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Screen.Cursor := crDefault;
end;

procedure TF_HVDelete.OpenForm(sender_or: string; HVs: THVDb);
begin
  Self.sender_or := sender_or;
  HVs.FillHVs(Self.CB_HV, Self.HVIndexes);
  Self.Show();
end;

procedure TF_HVDelete.ServerResp(parsed: TStrings);
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

    Application.MessageBox(PChar('Při odstraňování HV nastala chyba:' + #13#10 + err), 'Chyba',
      MB_OK OR MB_ICONWARNING);
  end else if (parsed[4] = 'OK') then
  begin
    Application.MessageBox(PChar('Lokomotiva ' + parsed[3] + ' odstraněna.'), 'Chyba', MB_OK OR MB_ICONINFORMATION);
    Self.Close();
  end;
end;

end.
