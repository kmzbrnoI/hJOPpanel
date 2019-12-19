unit fHVMoveSt;

{
  Okno presunu lokomotivy do jine oblasti rizeni.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, HVDb, RPConst;

type
  TF_HV_Move = class(TForm)
    Label1: TLabel;
    CB_HV: TComboBox;
    Label2: TLabel;
    CB_Stanice: TComboBox;
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
  F_HV_Move: TF_HV_Move;

implementation

{$R *.dfm}

uses OrList, TCPClientPanel;

////////////////////////////////////////////////////////////////////////////////

procedure TF_HV_Move.B_OKClick(Sender: TObject);
begin
 if (Self.CB_HV.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte HV!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.CB_Stanice.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte stanici!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 PanelTCPClient.PanelLokMove(Self.sender_id, hv_indexes[Self.CB_HV.ItemIndex],
                             ORDb.db_reverse[Self.CB_Stanice.Text]);

 Self.Close();
end;

procedure TF_HV_Move.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HV_Move.Open(sender:string; HVs:THVDb);
var name:string;
begin
 Self.sender_id := sender;

 if (HVs.HVs.Count = 1) then
   HVs.FillHVs(Self.CB_HV, Self.hv_indexes, HVs.HVs[0].Adresa)
 else
   HVs.FillHVs(Self.CB_HV, Self.hv_indexes);

 Self.CB_Stanice.Clear();
 for name in ORDb.names_sorted do
   Self.CB_Stanice.Items.Add(name);

 Self.ActiveControl := Self.CB_HV;
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
