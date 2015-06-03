unit HVDelete;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, HVDb, RPConst, TCPClientPanel;

type
  TF_HVDelete = class(TForm)
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    Label1: TLabel;
    CB_HV: TComboBox;
    B_Storno: TButton;
    B_Remove: TButton;
    procedure B_StornoClick(Sender: TObject);
    procedure B_RemoveClick(Sender: TObject);
  private
    { Private declarations }

    sender_or:string;
    HVIndexes:TWordAr;
  public
    { Public declarations }

    procedure OpenForm(Sender_or:string; HVs:THVDb);
  end;

var
  F_HVDelete: TF_HVDelete;

implementation

{$R *.dfm}

procedure TF_HVDelete.B_RemoveClick(Sender: TObject);
begin
 if (Self.CB_HV.ItemIndex < 0) then
  begin
   Application.MessageBox('Vyberte hnací vozdilo', 'Nelz pokraèovat', MB_OK OR MB_ICONWARNING);
   Exit();
  end;

 PanelTCPClient.PanelHVRemove(Self.sender_or, Self.HVIndexes[Self.CB_HV.ItemIndex]);

 Self.Close();
end;//procedure

procedure TF_HVDelete.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_HVDelete.OpenForm(Sender_or:string; HVs:THVDb);
begin
 Self.sender_or := Sender_or;

 HVs.FillHVs(Self.CB_HV, Self.HVIndexes);

 Self.Show();
end;//procedure

end.//unit
