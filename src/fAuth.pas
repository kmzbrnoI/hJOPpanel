unit fAuth;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Hash, ComCtrls;

type
  TAuthLevelDesc = record
   short, save, use, save_hint:string;
  end;

const
  _AUTH_DESC : array [0..2] of TAuthLevelDesc =
  (
    (
      short:     'Paranoidní';
      save:      'Heslo nebude uloženo.';
      use:       'Pøi zmìnì oprávnìní oblasti øízení, otevøení regulátoru apod. budete vždy vyzvání k zadání uživatelského jména a hesla.';
      save_hint: '';
    ),

    (
      short:     'Výchozí';
      save:      'Heslo bude uloženo pouze pro toto spojení, po odpojení od serveru bude heslo smazáno.';
      use:       'Pøi zmìnì oprávnìní oblasti øízení, otevøení regulátoru apod. bude použito toto heslo, nemusíte jej tedy znovu zadávat.';
      save_hint: 'Heslo je uloženo pouze v pamìti programu, žádný jiný program k nìmu nemá pøístup, ve formì hashe SHA 256.';
    ),

    (
      short:     'Uložit heslo dlouhodobì';
      save:      'Heslo bude uloženo, dokud uložení v oknì Nastavení nezrušíte.';
      use:       'Pøi jakémkoliv budoucím požadavku o autorizaci, dokonce i po restartování programu, bude použito toto heslo.';
      save_hint: '';
    )
  );


type
  TF_Auth = class(TForm)
    Label14: TLabel;
    E_username: TEdit;
    Label15: TLabel;
    E_Password: TEdit;
    B_Apply: TButton;
    B_Cancel: TButton;
    TB_Remeber: TTrackBar;
    Label1: TLabel;
    GB_RemberDesc: TGroupBox;
    ST_Rem2: TStaticText;
    ST_Rem4: TStaticText;
    ST_Rem1: TStaticText;
    ST_Rem3: TStaticText;
    procedure B_CancelClick(Sender: TObject);
    procedure B_ApplyClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure TB_RemeberChange(Sender: TObject);
  private
    { Private declarations }
  public
    procedure OpenForm(caption:string);
  end;

var
  F_Auth: TF_Auth;

implementation

uses GlobalConfig;

{$R *.dfm}

procedure TF_Auth.B_ApplyClick(Sender: TObject);
begin
 if (Self.TB_Remeber.Position > 0) then
  begin
   GlobConfig.data.auth.autoauth := true;
   GlobConfig.data.auth.username := Self.E_username.Text;
   GlobConfig.data.auth.password := GenerateHash(AnsiString(Self.E_Password.Text));
   GlobConfig.data.auth.forgot   := (Self.TB_Remeber.Position = 1);
  end;

 Self.Close();
end;

procedure TF_Auth.B_CancelClick(Sender: TObject);
begin
 Self.E_username.Text := '';
 Self.E_Password.Text := '';
 Self.Close();
end;

procedure TF_Auth.FormKeyPress(Sender: TObject; var Key: Char);
begin
 if (Key = #$1B) then
  Self.B_CancelClick(Self.B_Cancel);
 if ((Key = ';') or (Key = ',')) then Key := #0;
end;

procedure TF_Auth.OpenForm(caption:string);
begin
 Self.E_username.Text := '';
 Self.E_Password.Text := '';
 Self.TB_Remeber.Position := GlobConfig.data.auth.auth_default_level;
 Self.TB_RemeberChange(Self.TB_Remeber);
 Self.ActiveControl := Self.E_username;
 Self.Caption := caption;
 Self.ShowModal();
end;

procedure TF_Auth.TB_RemeberChange(Sender: TObject);
begin
 Self.ST_Rem1.Caption := _AUTH_DESC[Self.TB_Remeber.Position].short;
 Self.ST_Rem2.Caption := _AUTH_DESC[Self.TB_Remeber.Position].save;
 Self.ST_Rem3.Caption := _AUTH_DESC[Self.TB_Remeber.Position].use;
 Self.ST_Rem4.Caption := _AUTH_DESC[Self.TB_Remeber.Position].save_hint;
end;

end.//unit
