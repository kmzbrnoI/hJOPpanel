unit HVRuc;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, HVDb, RPConst;

type
  TF_HV_Ruc = class(TForm)
    Label1: TLabel;
    CB_HV: TComboBox;
    B_Storno: TButton;
    B_OK: TButton;
    procedure B_StornoClick(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
  private
    hv_indexes:TWordAr;
    sender_id:string;

  public
    procedure Open(sender:string; HVs:THVDb);
  end;

var
  F_HV_Ruc: TF_HV_Ruc;

implementation

{$R *.dfm}

uses OrList, TCPClientPanel;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HV_Ruc.B_OKClick(Sender: TObject);
begin
 if (Self.CB_HV.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte HV!', 'Nelze pokraèovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 PanelTCPClient.SendLn(Self.sender_id+';LOK;'+IntToStr(Self.hv_indexes[Self.CB_HV.ItemIndex])+';PLEASE;');

 Self.Close();
end;//procedure

procedure TF_HV_Ruc.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HV_Ruc.Open(sender:string; HVs:THVDb);
begin
 Self.sender_id := sender;

 if (HVs.count = 1) then
   HVs.FillHVs(Self.CB_HV, Self.hv_indexes, HVs.HVs[0].Adresa, nil, true)
 else
   HVs.FillHVs(Self.CB_HV, Self.hv_indexes, -1, nil, true);

 Self.ActiveControl := Self.CB_HV;
 Self.Show();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

end.//unit
