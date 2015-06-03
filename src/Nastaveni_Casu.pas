unit Nastaveni_Casu;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Mask, DateUtils, StrUtils;

type
  TF_ModCasSet = class(TForm)
    ME_start_time: TMaskEdit;
    L_time_start: TLabel;
    RG_zrychleni: TRadioGroup;
    B_OK: TButton;
    B_Storno: TButton;
    procedure B_OKClick(Sender: TObject);
    procedure B_StornoClick(Sender: TObject);
    procedure ME_start_timeKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
   procedure OpenForm;
  end;

var
  F_ModCasSet: TF_ModCasSet;

implementation

uses ModelovyCas, TCPClientPanel;

{$R *.dfm}

procedure TF_ModCasSet.B_OKClick(Sender: TObject);
 begin
  try
    if (StrToInt(Copy(ME_start_time.Text, 4, 2)) > 59) then
     begin
      Application.MessageBox('Minuty zadejte v rozsahu 0-59','Nelze nastavit cas',MB_OK OR MB_ICONWARNING);
      Exit;
     end;

    if (StrToInt(LeftStr(ME_start_time.Text, 2)) > 23) then
     begin
      Application.MessageBox('Hodiny zadejte v rozsahu 0-23','Nelze nastavit cas',MB_OK OR MB_ICONWARNING);
      Exit;
     end;

    PanelTCPClient.SendLn('-;MOD-CAS;TIME;'+Self.ME_start_time.Text+':00;'+IntToStr(Self.RG_zrychleni.ItemIndex+2));

    Self.Close();
  except
   Application.MessageBox('Zad�na neplatn� data', 'Nelze nasatvit �as', MB_OK OR MB_ICONWARNING);
  end;

 end;//procedure

procedure TF_ModCasSet.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_ModCasSet.ME_start_timeKeyPress(Sender: TObject; var Key: Char);
begin
 Key := Key;
 case Key of
  '0'..'9',#9,#8:begin
              end else begin
               Key := #0;
              end;
  end;//case
end;//procedure

procedure TF_ModCasSet.OpenForm;
 begin
  Self.ME_start_time.Text     := FormatDateTime('hh:nn', ModCas.time);
  Self.RG_zrychleni.ItemIndex := ModCas.nasobic-2;

  Self.Show();
 end;//procedure


end.//unix
