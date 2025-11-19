unit fHVSearch;

{
  Search for engine parameters based on its address.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, HVDb, StdCtrls;

type
  TF_HVSearch = class(TForm)
    Label6: TLabel;
    E_Adresa: TEdit;
    B_OK: TButton;
    procedure FormShow(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
  private
    { Private declarations }
  public

    procedure LokoFound(HV: THV);
    procedure LokoNotFound();
  end;

var
  F_HVSearch: TF_HVSearch;

implementation

uses ORList, TCPClientPanel;

{$R *.dfm}

procedure TF_HVSearch.B_OKClick(Sender: TObject);
begin
  if (Self.E_Adresa.Text = '') then
  begin
    Application.MessageBox('Vyplňte adresu hnacího vozidla!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  PanelTCPClient.SendLn('-;HV;ASK;' + Self.E_Adresa.Text);
  Self.Close();
end;

procedure TF_HVSearch.FormShow(Sender: TObject);
begin
  Self.E_Adresa.Text := '';
  Self.ActiveControl := E_Adresa;
end;

procedure TF_HVSearch.LokoFound(HV: THV);
var str: string;
begin
  str := 'Lokomotiva nalezena!' + #13#10 + 'Název : ' + HV.name + #13#10 + 'Majitel : ' + HV.owner + #13#10 +
    'Označení : ' + HV.designation + #13#10 + 'Adresa : ' + IntToStr(HV.addr) + #13#10 + 'Vlak : ' + HV.train +
    #13#10 + 'Stanice : ' + HV.orid + ' (' + areaDb.db[HV.orid] + ')' + #13#10;
  Application.MessageBox(PChar(str), 'Loko nalezeno', MB_OK OR MB_ICONINFORMATION);
end;

procedure TF_HVSearch.LokoNotFound();
begin
  Application.MessageBox('Lokomotiva nebyla nalezena v databázi hnacích vozidel serveru.', 'Loko nenalezeno',
    MB_OK OR MB_ICONINFORMATION);
end;

end.// unit
