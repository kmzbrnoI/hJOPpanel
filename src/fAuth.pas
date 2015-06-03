unit fAuth;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TF_Auth = class(TForm)
    CHB_RememberAuth: TCheckBox;
    Label14: TLabel;
    E_username: TEdit;
    Label15: TLabel;
    E_Password: TEdit;
    B_Apply: TButton;
    B_Cancel: TButton;
    CHB_Forgot: TCheckBox;
    procedure B_CancelClick(Sender: TObject);
    procedure B_ApplyClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure CHB_RememberAuthClick(Sender: TObject);
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
 if (Self.CHB_RememberAuth.Checked) then
  begin
   GlobConfig.data.auth.autoauth   := true;
   GlobConfig.data.auth.username   := Self.E_username.Text;
   GlobConfig.data.auth.password   := Self.E_Password.Text;
   GlobConfig.data.auth.forgot     := Self.CHB_Forgot.Checked;
  end;

 GlobConfig.data.auth.auth_chb_remember := Self.CHB_RememberAuth.Checked;

 Self.Close;
end;

procedure TF_Auth.B_CancelClick(Sender: TObject);
begin
 Self.E_username.Text := '';
 Self.E_Password.Text := '';
 Self.Close();
end;

procedure TF_Auth.CHB_RememberAuthClick(Sender: TObject);
begin
 Self.CHB_Forgot.Enabled := Self.CHB_RememberAuth.Checked;
 Self.CHB_Forgot.Checked := (Self.CHB_Forgot.Enabled);
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
 Self.CHB_RememberAuth.Checked := GlobConfig.data.auth.auth_chb_remember;
 Self.CHB_RememberAuthClick(Self.CHB_RememberAuth);
 Self.ActiveControl := Self.E_username;
 Self.Caption := caption;
 Self.ShowModal();
end;//proceudre

end.//unit
