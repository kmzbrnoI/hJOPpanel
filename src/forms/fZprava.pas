unit fZprava;

{
  Single message thread window.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, StrUtils;

type
  TF_Message = class(TForm)
    M_Send: TMemo;
    B_Send: TButton;
    LV_Messages: TListView;
    procedure B_SendClick(Sender: TObject);
    procedure M_SendKeyPress(Sender: TObject; var Key: Char);
    procedure LV_MessagesCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      var DefaultDraw: Boolean);
    procedure FormResize(Sender: TObject);
    procedure LV_MessagesDblClick(Sender: TObject);
    procedure LV_MessagesCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure M_SendEnter(Sender: TObject);
  private
    { Private declarations }
    fid, fname: string;

  public

    constructor Create(AOwner: TComponent; id, name: string); reintroduce;

    property id: string read fid;
    property name: string read fname;

    procedure SetFocus(); override;

    procedure ReceiveMsg(msg: string);
    procedure ReceiveErr(err: string);
  end;

var
  F_Message: TF_Message;

implementation

{$R *.dfm}

uses TCPClientPanel, fZpravy, RPConst;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Message.B_SendClick(Sender: TObject);
begin
  if (Self.M_Send.Text = '') then
    Exit();

  for var i := 1 to Length(Self.M_Send.Text) do
    for var j := 0 to Length(_forbidden_chars) - 1 do
      if (_forbidden_chars[j] = Self.M_Send.Text[i]) then
      begin
        Application.MessageBox(PChar('Zpráva obsahuje zakázané znaky!' + #13#10 + 'Zakázané znaky: ' +
          GetForbidderChars()), 'Nelze odeslat zprávu', MB_OK OR MB_ICONWARNING);
        Exit();
      end;

  var LI := Self.LV_Messages.Items.Add();
  LI.Caption := FormatDateTime('hh:nn:ss', Now);
  LI.SubItems.Add('');
  LI.SubItems.Add(Self.M_Send.Text);

  PanelTCPClient.PanelMessage((((Self.Parent as TTabSheet).Parent as TPageControl).Parent as TF_Messages).id, Self.id,
    Self.M_Send.Text);
  Self.M_Send.Clear();

  Self.LV_Messages.Scroll(0, 100);
end;

constructor TF_Message.Create(AOwner: TComponent; id, name: string);
begin
  inherited Create(AOwner);

  Self.fid := id;
  Self.fname := name;
end;

procedure TF_Message.FormResize(Sender: TObject);
begin
  Self.LV_Messages.Width := Self.ClientWidth - 15;
  Self.LV_Messages.Height := Self.ClientHeight - Self.M_Send.Height - 20;

  Self.M_Send.Width := Self.ClientWidth - Self.B_Send.Width - 20;
  Self.M_Send.Top := Self.LV_Messages.Top + Self.LV_Messages.Height + 5;
  Self.B_Send.Top := Self.M_Send.Top;
  Self.B_Send.Left := Self.M_Send.Width + Self.M_Send.Left + 5;

  Self.LV_Messages.Column[1].Width := ((Self.LV_Messages.ClientWidth - Self.LV_Messages.Column[0].Width) div 2) - 10;
  Self.LV_Messages.Column[2].Width := ((Self.LV_Messages.ClientWidth - Self.LV_Messages.Column[0].Width) div 2) - 10;
end;

procedure TF_Message.LV_MessagesCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  if (LeftStr(Item.SubItems.Strings[0], 3) = 'ERR') then
  begin
    Self.LV_Messages.Canvas.Brush.Color := $66CCFF;
  end else begin
    Self.LV_Messages.Canvas.Brush.Color := $FFFFFF;
  end;

  Sender.Canvas.Font.Color := clGray;
end;

procedure TF_Message.LV_MessagesCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer;
  State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if (LeftStr(Item.SubItems.Strings[0], 3) = 'ERR') then
  begin
    Self.LV_Messages.Canvas.Brush.Color := $66CCFF;
  end else begin
    Self.LV_Messages.Canvas.Brush.Color := $FFFFFF;
  end;
  Sender.Canvas.Font.Color := clBlack;
end;

procedure TF_Message.LV_MessagesDblClick(Sender: TObject);
begin
  Self.LV_Messages.Clear();
end;

procedure TF_Message.M_SendEnter(Sender: TObject);
begin
  (Self.Parent as TTabSheet).ShowHint := false;
  ((Self.Parent as TTabSheet).Parent as TPageControl).Repaint();
end;

procedure TF_Message.M_SendKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
  begin
    Self.B_SendClick(Self.B_Send);
    Key := #0;
  end;

  for var i := 0 to Length(_forbidden_chars) - 1 do
    if (_forbidden_chars[i] = Key) then
    begin
      Key := #0;
      Exit();
    end;
end;

procedure TF_Message.SetFocus();
begin
  ((Self.Parent as TTabSheet).Parent as TPageControl).ActivePage := (Self.Parent as TTabSheet);
  Self.M_Send.SetFocus();
  (Self.Parent as TTabSheet).ShowHint := false;
  ((Self.Parent as TTabSheet).Parent as TPageControl).Repaint();
end;

/// ////////////////////////////////////////////////////////////////////////

procedure TF_Message.ReceiveMsg(msg: string);
begin
  var LI := Self.LV_Messages.Items.Add();
  LI.Caption := FormatDateTime('hh:nn:ss', Now);
  LI.SubItems.Add(msg);

  Self.LV_Messages.Scroll(0, 100);

  if (not TF_Messages.IsTyping()) then
    Self.SetFocus()
  else
  begin
    (Self.Parent as TTabSheet).ShowHint := true;
    ((Self.Parent as TTabSheet).Parent as TPageControl).Repaint();
  end;
end;

procedure TF_Message.ReceiveErr(err: string);
begin
  var LI := Self.LV_Messages.Items.Add();
  LI.Caption := FormatDateTime('hh:nn:ss', Now);
  LI.SubItems.Add('ERR: ' + err);

  Self.LV_Messages.Scroll(0, 100);
end;

/// ////////////////////////////////////////////////////////////////////////

end.// unit
