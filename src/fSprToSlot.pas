unit fSprToSlot;

{
  Okno predavani LOKO do konkretniho slotu uLI-master.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, uLIClient, RPConst;

type
  TF_SprToSlot = class(TForm)
    Label1: TLabel;
    L_Addrs: TLabel;
    P_Buttons: TPanel;
    L_Slot: TLabel;
    L_Stav: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    B_Slots: array [1..TBridgeClient._SLOTS_CNT] of TButton;
    B_Slots_Ruc: array [1..TBridgeClient._SLOTS_CNT] of TButton;

    HVs:TWordAr;
    orId:string;

     procedure CreateSlotsButtons();
     procedure ButtonSlotClick(Sender:TObject);
     procedure ButtonSlotRucClick(Sender:TObject);

  public

    token_req_sent : boolean;

     procedure RepaintSlots();
     procedure Open(orId:string; HVs:TWordAr);

     procedure ServerResponseOK();
     procedure ServerResponseErr(err:string);

  end;

var
  F_SprToSlot: TF_SprToSlot;

implementation

uses LokTokens;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprToSlot.CreateSlotsButtons();
var i:Integer;
begin
 for i := 1 to TBridgeClient._SLOTS_CNT do
  begin
   Self.B_Slots[i] := TButton.Create(Self.P_Buttons);
   with (Self.B_Slots[i]) do
    begin
     Parent := Self.P_Buttons;
     Top := 5;
     Tag := i;
     Width := 70;
     OnClick := Self.ButtonSlotClick;
     Caption := IntToStr(i);
     TabOrder := 2*i;
    end;

   Self.B_Slots_Ruc[i] := TButton.Create(Self.P_Buttons);
   with (Self.B_Slots_Ruc[i]) do
    begin
     Parent := Self.P_Buttons;
     Top := 35;
     Tag := i;
     Width := 70;
     OnClick := Self.ButtonSlotRucClick;
     Caption := IntToStr(i) + ' ruè.';
     TabOrder := 2*i + 1;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprToSlot.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Self.token_req_sent := false;
end;

procedure TF_SprToSlot.FormCreate(Sender: TObject);
begin
 Self.CreateSlotsButtons();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprToSlot.RepaintSlots();
var cnt, i, j:Integer;
    partWidth:Integer;
begin
 cnt := BridgeClient.activeSlotsCount;

 if (cnt = 0) then
   Self.L_Slot.Caption := 'Do slotu: (žádný slot není k dispozici)'
 else
   Self.L_Slot.Caption := 'Do slotu:';

 j := 0;
 if (cnt > 0) then
   partWidth := ((P_Buttons.Width-20) div cnt)
 else
   partWidth := 0;

 for i := 1 to TBridgeClient._SLOTS_CNT do
  begin
   with (Self.B_Slots[i]) do
    begin
     Visible := ((BridgeClient.sloty[i] = ssAvailable) or (BridgeClient.sloty[i] = ssFull));
     Enabled := (BridgeClient.sloty[i] = ssAvailable);

     if (Visible) then
       Left := (partWidth*j + (partWidth div 2) - (Self.B_Slots[i].Width div 2)) + 10;
    end;

   with (Self.B_Slots_Ruc[i]) do
    begin
     Visible := Self.B_Slots[i].Visible;
     Enabled := Self.B_Slots[i].Enabled;

     if (Visible) then
      begin
       Left := (partWidth*j + (partWidth div 2) - (Self.B_Slots[i].Width div 2)) + 10;
       Inc(j);
      end;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprToSlot.ButtonSlotClick(Sender:TObject);
begin
 tokens.LokosToMaus(Self.orId, Self.HVs, TButton(Sender).Tag, false);

 Self.L_Stav.Caption := 'Odeslána žádost o vydání tokenù...';
 Self.token_req_sent := true;
end;

procedure TF_SprToSlot.ButtonSlotRucClick(Sender:TObject);
begin
 tokens.LokosToMaus(Self.orId, Self.HVs, TButton(Sender).Tag, true);

 Self.L_Stav.Caption := 'Odeslána žádost o vydání tokenù...';
 Self.token_req_sent := true;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprToSlot.Open(orId:string; HVs:TWordAr);
var i:Integer;
begin
 Self.orId := orId;
 Self.HVs  := HVs;

 Self.L_Addrs.Caption := '';
 for i := 0 to Length(HVs)-2 do
   Self.L_Addrs.Caption := Self.L_Addrs.Caption + IntToStr(HVs[i]) + ', ';
 Self.L_Addrs.Caption := Self.L_Addrs.Caption + IntToStr(HVs[Length(HVs)-1]);

 Self.L_Stav.Caption    := 'Vyberte slot';
 Self.L_Stav.Font.Color := clBlack;

 Self.RepaintSlots();

 for i := 1 to TBridgeClient._SLOTS_CNT do
  begin
   if ((self.B_Slots[i].Visible) and (Self.B_Slots[i].Enabled)) then
    begin
     Self.B_Slots[i].Default := true;
     Self.ActiveControl := Self.B_Slots[i];
     break;
    end;
  end;

 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprToSlot.ServerResponseOK();
begin
 Self.token_req_sent := false;
 Self.Close();
end;//procedure

procedure TF_SprToSlot.ServerResponseErr(err:string);
begin
 Self.token_req_sent := false;
 Self.L_Stav.Font.Color := clRed;
 Self.L_Stav.Caption := err;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

end.
