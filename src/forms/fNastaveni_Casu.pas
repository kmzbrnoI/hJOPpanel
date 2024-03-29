﻿unit fNastaveni_Casu;

{
  Okno nastaveni modeloveho casu.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Mask, StrUtils;

type
  TF_ModelTIme = class(TForm)
    ME_start_time: TMaskEdit;
    L_time_start: TLabel;
    B_OK: TButton;
    B_Storno: TButton;
    Label1: TLabel;
    ME_Nasobic: TMaskEdit;
    CHB_Used: TCheckBox;
    procedure B_OKClick(Sender: TObject);
    procedure B_StornoClick(Sender: TObject);
    procedure ME_start_timeKeyPress(Sender: TObject; var Key: Char);
    procedure CHB_UsedClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure OpenForm;
  end;

var
  F_ModelTIme: TF_ModelTIme;

implementation

uses ModelovyCas, TCPClientPanel;

{$R *.dfm}

procedure TF_ModelTIme.B_OKClick(Sender: TObject);
begin
  try
    if (StrToInt(Copy(ME_start_time.Text, 4, 2)) > 59) then
    begin
      Application.MessageBox('Minuty zadejte v rozsahu 0-59', 'Nelze nastavit cas', MB_OK OR MB_ICONWARNING);
      Exit;
    end;

    if (StrToInt(LeftStr(ME_start_time.Text, 2)) > 23) then
    begin
      Application.MessageBox('Hodiny zadejte v rozsahu 0-23', 'Nelze nastavit cas', MB_OK OR MB_ICONWARNING);
      Exit;
    end;

    if (StrToFloat(ME_Nasobic.Text) >= 10) then
    begin
      Application.MessageBox('Násobič zadejte v rozsahu 0-9.9', 'Nelze nastavit cas', MB_OK OR MB_ICONWARNING);
      Exit;
    end;

    if (Self.CHB_Used.Checked) then
      PanelTCPClient.SendLn('-;MOD-CAS;TIME;' + Self.ME_start_time.Text + ':00;' + Self.ME_Nasobic.Text + ';1')
    else
      PanelTCPClient.SendLn('-;MOD-CAS;TIME;' + Self.ME_start_time.Text + ':00;' + Self.ME_Nasobic.Text + ';0');

    Self.Close();
  except
    Application.MessageBox('Zadána neplatná data', 'Nelze nasatvit čas', MB_OK OR MB_ICONWARNING);
  end;

end;

procedure TF_ModelTIme.B_StornoClick(Sender: TObject);
begin
  Self.Close();
end;

procedure TF_ModelTIme.CHB_UsedClick(Sender: TObject);
begin
  Self.ME_start_time.Enabled := Self.CHB_Used.Checked;
  Self.ME_Nasobic.Enabled := Self.CHB_Used.Checked;
end;

procedure TF_ModelTIme.ME_start_timeKeyPress(Sender: TObject; var Key: Char);
begin
  Key := Key;
  case Key of
    '0' .. '9', #9, #8:
      begin
      end
  else
    begin
      Key := #0;
    end;
  end; // case
end;

procedure TF_ModelTIme.OpenForm;
begin
  Self.CHB_Used.Checked := ModelTime.used;
  Self.ME_start_time.Text := FormatDateTime('hh:nn', ModelTime.time);
  Self.ME_Nasobic.Text := FloatToStrF(ModelTime.speed, ffNumber, 1, 1);

  Self.CHB_UsedClick(Self.CHB_Used);

  Self.ActiveControl := Self.CHB_Used;
  Self.Show();
end;

end.// unix
