unit fHVSearch;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, HVDb, StdCtrls;

type
  TF_HVSearch = class(TForm)
    Label6: TLabel;
    E_Adresa: TEdit;
    B_OK: TButton;
    procedure E_AdresaKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
  private
    { Private declarations }
  public

     procedure LokoFound(HV:THV);
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
   Application.MessageBox('Vypl�te adresu hnac�ho vozidla!', 'Nelze pokra�ovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 PanelTCPClient.SendLn('-;LOK;'+Self.E_Adresa.Text+';ASK');
 Self.Close();
end;

procedure TF_HVSearch.E_AdresaKeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
   '0'..'9',#9,#8:;
   else
    Key := #0;
  end;//else case
end;

procedure TF_HVSearch.FormShow(Sender: TObject);
begin
 Self.E_Adresa.Text := '';
 Self.ActiveControl := E_Adresa;
end;

procedure TF_HVSearch.LokoFound(HV:THV);
var str:string;
begin
 str := 'Lokomotiva nalezena!' + #13#10 +
        'N�zev : ' + HV.Nazev + #13#10 +
        'Majitel : ' + HV.Majitel + #13#10 +
        'Ozna�en� : ' + HV.Oznaceni + #13#10 +
        'Adresa : ' + IntToStr(HV.Adresa) + #13#10 +
        'Souprava : ' + HV.Souprava + #13#10 +
        'Stanice : ' + HV.orid + ' (' + ORDb.db[HV.orid] + ')' + #13#10;
 Application.MessageBox(PChar(str), 'Loko nalezeno', MB_OK OR MB_ICONINFORMATION);
end;

procedure TF_HVSearch.LokoNotFound();
begin
 Application.MessageBox('Lokomotiva nebyla nalezena v datab�zi hnac�ch vozidel serveru.', 'Loko nenalezeno', MB_OK OR MB_ICONINFORMATION);
end;

end.//unit