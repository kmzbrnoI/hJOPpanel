unit Debug;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, StrUtils;

type
  TF_Debug = class(TForm)
    CHB_DataLogging: TCheckBox;
    LV_Log: TListView;
    M_Data: TMemo;
    B_ClearLog: TButton;
    GB_SendData: TGroupBox;
    E_Send: TEdit;
    B_Send: TButton;
    Label1: TLabel;
    L_len: TLabel;
    Label2: TLabel;
    procedure B_ClearLogClick(Sender: TObject);
    procedure LV_LogChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure LV_LogCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure B_SendClick(Sender: TObject);
    procedure E_SendKeyPress(Sender: TObject; var Key: Char);
    procedure M_DataChange(Sender: TObject);
  private
    { Private declarations }
  public
     procedure Log(msg:string);
  end;

var
  F_Debug: TF_Debug;

implementation

uses Sounds, Main, PotvrSekv, BottomErrors, TCPClientPanel;

{$R *.dfm}

procedure TF_Debug.B_ClearLogClick(Sender: TObject);
begin
 Self.M_Data.Clear();
 Self.LV_Log.Clear();
end;

procedure TF_Debug.LV_LogChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
 if (Assigned(Self.LV_Log.Selected)) then
   Self.M_Data.Text := Self.LV_Log.Selected.SubItems.Strings[0]
 else
   Self.M_Data.Text := '';
end;

procedure TF_Debug.LV_LogCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
 if (LeftStr(Item.SubItems.Strings[0], 3) = 'GET') then
  Self.LV_Log.Canvas.Brush.Color := $FFEEEE;
 if (LeftStr(Item.SubItems.Strings[0], 4) = 'SEND') then
  Self.LV_Log.Canvas.Brush.Color := $EEFFEE;
end;

procedure TF_Debug.M_DataChange(Sender: TObject);
var len:Cardinal;
begin
 len := Length(Self.M_Data.Text)-5;
 Self.L_len.Caption := IntToStr(len div 1000) + ' ' + IntToStr(len mod 1000);
end;

procedure TF_Debug.B_SendClick(Sender: TObject);
begin
 PanelTCPClient.SendLn(Self.E_Send.Text);
 Self.E_Send.Text := '';
end;

procedure TF_Debug.E_SendKeyPress(Sender: TObject; var Key: Char);
begin
 if (Key = #13) then
  Self.B_SendClick(Self);
end;//procedure

procedure TF_Debug.Log(msg:string);
var LI:TListItem;
begin
 if (not Self.CHB_DataLogging.Checked) then Exit();

 LI := Self.LV_Log.Items.Insert(0);
 LI.Caption := FormatDateTime('hh:nn:ss,zzz', Now);
 LI.SubItems.Add(msg);
end;//procedure

end.//unit
