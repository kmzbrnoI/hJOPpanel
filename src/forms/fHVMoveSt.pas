unit fHVMoveSt;

{
  Okno presunu lokomotivy do jine oblasti rizeni.
}

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  HVDb, RPConst, ComCtrls, SysUtils;

type
  TF_HV_Move = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    CB_Stanice: TComboBox;
    B_Storno: TButton;
    B_OK: TButton;
    LV_HVs: TListView;
    procedure B_StornoClick(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
  private
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
var LI: TListItem;
begin
 if (Self.LV_HVs.Selected = nil) then
  begin
   Application.MessageBox('Vyberte alespoň jedno hnací vozidlo!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;
 if (Self.CB_Stanice.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte stanici!', 'Nelze pokračovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 for LI in Self.LV_HVs.Items do
   if (LI.Selected) then
     PanelTCPClient.PanelLokMove(Self.sender_id, Integer(LI.Data),
                                 ORDb.db_reverse[Self.CB_Stanice.Text]);

 Self.Close();
end;

procedure TF_HV_Move.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HV_Move.Open(sender:string; HVs:THVDb);
var HV: THV;
    LI: TListItem;
    name: string;
begin
 Self.sender_id := sender;

 Self.LV_HVs.Clear();
 for HV in HVs.HVs do
  begin
   if (HV.Souprava = '-') then
    begin
     LI := Self.LV_HVs.Items.Add();
     LI.Caption := IntToStr(HV.Adresa);
     LI.SubItems.Add(HV.Nazev);
     LI.SubItems.Add(HV.Oznaceni);
     LI.Data := Pointer(HV.Adresa);
    end;
  end;

 Self.CB_Stanice.Clear();
 for name in ORDb.names_sorted do
   Self.CB_Stanice.Items.Add(name);

 Self.ActiveControl := Self.LV_HVs;
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
