unit fRVSearch;

{
  Search for engine parameters based on its address.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RVDb, StdCtrls;

type
  TF_RVSearch = class(TForm)
    Label6: TLabel;
    E_Adresa: TEdit;
    B_OK: TButton;
    procedure FormShow(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
  private
    { Private declarations }
  public

    procedure VehicleFound(vehicle: TRV);
    procedure VehicleNotFound();
  end;

var
  F_RVSearch: TF_RVSearch;

implementation

uses ORList, TCPClientPanel;

{$R *.dfm}

procedure TF_RVSearch.B_OKClick(Sender: TObject);
begin
  if (Self.E_Adresa.Text = '') then
  begin
    Application.MessageBox('Vyplňte adresu vozidla!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
    Exit();
  end;

  PanelTCPClient.SendLn('-;HV;ASK;' + Self.E_Adresa.Text);
  Self.Close();
end;

procedure TF_RVSearch.FormShow(Sender: TObject);
begin
  Self.E_Adresa.Text := '';
  Self.ActiveControl := E_Adresa;
end;

procedure TF_RVSearch.VehicleFound(vehicle: TRV);
var str: string;
begin
  str := 'Vozidlo nalezeno!' + #13#10 + 'Název : ' + vehicle.name + #13#10 + 'Majitel : ' + vehicle.owner + #13#10 +
    'Označení : ' + vehicle.designation + #13#10 + 'Adresa : ' + IntToStr(vehicle.addr) + #13#10 + 'Vlak : ' + vehicle.train +
    #13#10 + 'Stanice : ' + vehicle.orid + ' (' + areaDb.db[vehicle.orid] + ')' + #13#10;
  Application.MessageBox(PChar(str), 'Loko nalezeno', MB_OK OR MB_ICONINFORMATION);
end;

procedure TF_RVSearch.VehicleNotFound();
begin
  Application.MessageBox('Vozidlo nebylo nalezeno v databázi vozidel serveru.', 'Vozidlo nenalezeno',
    MB_OK OR MB_ICONINFORMATION);
end;

end.// unit
