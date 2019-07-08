unit fZpravy;

{
  Okynko zprav.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, RPConst, StdCtrls, fZprava, CloseTabSheet, Themes,
  Generics.Collections;

const
  _MAX_CLIENTS = 32;
  _MAX_OR = 16;

type
  TF_Messages = class(TForm)
    LV_ORs: TListView;
    PC_Clients: TPageControl;
    procedure FormShow(Sender: TObject);
    procedure PC_ClientsChange(Sender: TObject);
    procedure LV_ORsDblClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PC_ClientsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure PC_ClientsDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure FormResize(Sender: TObject);
    procedure LV_ORsKeyPress(Sender: TObject; var Key: Char);

    procedure PageControlCloseButtonDrawTab(Control: TCustomTabControl;
      TabIndex: Integer; const Rect: TRect; Active: Boolean);
    procedure PageControlCloseButtonMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PageControlCloseButtonMouseLeave(Sender: TObject);
    procedure PageControlCloseButtonMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer);
    procedure PageControlCloseButtonMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure OnTabClose(Sender:TObject);

  private
    fname, fid:string;

    // databaze otevrenych zalozek se stanicemi
    // pozor> poradi nemusi odpovidat poradi na okynku !! (diky umozneni prehazovani)
    clients: TObjectList<TF_Message>;

    FCloseButtonMouseDownTab: TCloseTabSheet;
    FCloseButtonShowPushed: Boolean;

  public

    constructor Create(name:string; id:string); reintroduce;
    destructor Destroy(); override;
    procedure MsgReceive(msg:string; sender:string); overload;
    procedure ErrorReceive(error:string; sender:string); overload;

    function OpenTab(name:string; id:string):TF_Message;
    procedure RemoveClients();
    function IsTypin():boolean;

    property name:string read fname;
    property id:string read fid;

    // static function
    class procedure MsgReceive(recepient:string; msg:string; sender:string); overload;
    class procedure ErrorReceive(recepient:string; error:string; sender:string); overload;
    class procedure DestroyForms();
    class procedure CloseForms();
    class function IsTyping():boolean;

    class var frm_cnt : Integer;
    class var frm_db : array [0.._MAX_OR] of TF_Messages;

  end;

var
  F_Messages: TF_Messages;

implementation

uses Sounds, ORList;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

constructor TF_Messages.Create(name:string; id:string);
begin
 inherited Create(nil);
 Self.clients := TObjectList<TF_Message>.Create();
 Self.fname := name;
 Self.fid   := id;
end;//ctor

destructor TF_Messages.Destroy();
begin
 Self.clients.Free();
 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure TF_Messages.MsgReceive(msg:string; sender:string);
var i:Integer;
    form:TF_Message;
    id:string;
begin
 if (not Self.Showing) then Self.Show();
 SoundsPlay.Play(_SND_ZPRAVA);

 for i := 0 to Self.clients.Count-1 do
   if (Self.clients[i].id = sender) then
    begin
     Self.clients[i].ReceiveMsg(msg);
     Exit();
    end;

 //okynko se zpravou neexituje -> otevreme ho
 for id in ORDb.db.Keys do
   if (id = sender) then
    begin
     form := Self.OpenTab(ORDb.db[id], sender);
     if (form <> nil) then form.ReceiveMsg(msg);
     Exit();
    end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Messages.ErrorReceive(error:string; sender:string);
var form: TF_Message;
begin
 if (not Self.Showing) then Self.Show();
 SoundsPlay.Play(_SND_CHYBA);

 for form in Self.Clients do
   if (form.id = sender) then
    begin
     form.ReceiveErr(error);
     Exit();
    end;
end;

////////////////////////////////////////////////////////////////////////////////

function TF_Messages.OpenTab(name:string; id:string):TF_Message;
var TS: TCloseTabSheet;
    form: TF_Message;
begin
 // nejdrive zkontolujeme, jestli zalozku uz nemame ...
 for form in Self.clients do
  begin
   if (form.id = id) then
    begin
     form.SetFocus();
     Exit(form);
    end;
  end;//for

 if (Self.clients.Count >= _MAX_CLIENTS) then Exit(nil);

 // je potreba otevrit novou zalozku -> otevreme ji
 TS := TCloseTabSheet.Create(Self.PC_Clients);
 TS.PageControl := Self.PC_Clients;
 TS.Caption := name + '      ';     // mezery kvuli tlacitku zavreni
 TS.OnClose := OnTabClose;
 Self.PC_Clients.ActivePage := TS;

 form := TF_Message.Create(TS, id, name);
 form.Parent := TS;
 form.Show();
 form.SetFocus();

 Self.clients.Add(form);

 Self.PC_ClientsChange(nil);

 Result := form;
end;

procedure TF_Messages.PC_ClientsChange(Sender: TObject);
begin
 Self.Caption := Self.PC_Clients.ActivePage.Caption + ' - ' + Self.name + ' - zprávy';
end;

procedure TF_Messages.PC_ClientsDragDrop(Sender, Source: TObject; X,
  Y: Integer);
const
   TCM_GETITEMRECT = $130A;
var
   TabRect: TRect;
   j: Integer;
begin
   if (Sender is TPageControl) then
   for j := 0 to Self.PC_Clients.PageCount - 1 do
   begin
     Self.PC_Clients.Perform(TCM_GETITEMRECT, j, LParam(@TabRect)) ;
     if PtInRect(TabRect, Point(X, Y)) then
     begin
       if Self.PC_Clients.ActivePage.PageIndex <> j then
         Self.PC_Clients.ActivePage.PageIndex := j;
       Exit;
     end;
   end;
end;

procedure TF_Messages.PC_ClientsDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
 if (Sender is TPageControl) then Accept := True;
end;

procedure TF_Messages.RemoveClients();
var i:Integer;
begin
 Self.clients.Clear();

 for i := Self.PC_Clients.PageCount-1 downto 0 do
  Self.PC_Clients.Pages[i].Free();
end;

////////////////////////////////////////////////////////////////////////////////

function TF_Messages.IsTypin():boolean;
var form:TF_Message;
begin
 for form in Self.clients do
  if (form.M_Send.Text <> '') then
   Exit(true);
 Exit(false);
end;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//////////////////////////  STATIC FUNCTIONS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class procedure TF_Messages.MsgReceive(recepient:string; msg:string; sender:string);
var i:Integer;
begin
 for i := 0 to TF_Messages.frm_cnt-1 do
  if (TF_Messages.frm_db[i].id = recepient) then
   begin
    TF_Messages.frm_db[i].MsgReceive(msg, sender);
    Exit();
   end;
end;

////////////////////////////////////////////////////////////////////////////////

class procedure TF_Messages.ErrorReceive(recepient:string; error:string; sender:string);
var i:Integer;
begin
 for i := 0 to TF_Messages.frm_cnt-1 do
  if (TF_Messages.frm_db[i].id = recepient) then
   begin
    TF_Messages.frm_db[i].ErrorReceive(error, sender);
    Exit();
   end;
end;

procedure TF_Messages.FormDestroy(Sender: TObject);
begin
 Self.RemoveClients();
end;

procedure TF_Messages.FormResize(Sender: TObject);
begin
 Self.LV_ORs.Height     := Self.ClientHeight - 15;
 Self.PC_Clients.Height := Self.ClientHeight - 15;

 Self.PC_Clients.Width := Self.ClientWidth - Self.LV_ORs.Width - 20;
end;

procedure TF_Messages.FormShow(Sender: TObject);
var LI:TListItem;
    name:string;
begin
 Self.LV_ORs.Clear();
 for name in ORDb.names_sorted do
  begin
   LI := Self.LV_ORs.Items.Add;
   LI.Caption := name;
   LI.SubItems.Add(ORDb.db_reverse[name]);
  end;

 Self.Caption := Self.name + ' - zprávy';
end;

procedure TF_Messages.LV_ORsDblClick(Sender: TObject);
begin
 if (Self.LV_ORs.Selected <> nil) then
  Self.OpenTab(Self.LV_ORs.Selected.Caption, Self.LV_ORs.Selected.SubItems.Strings[0]);
end;

procedure TF_Messages.LV_ORsKeyPress(Sender: TObject; var Key: Char);
begin
 if (Key = #13) then Self.LV_ORsDblClick(Self.LV_ORs); 
end;

////////////////////////////////////////////////////////////////////////////////

class procedure TF_Messages.DestroyForms();
var i:Integer;
begin
 for i := 0 to Self.frm_cnt-1 do
  if (Assigned(Self.frm_db[i])) then
   FreeAndNil(Self.frm_db[i]);
end;

////////////////////////////////////////////////////////////////////////////////

class procedure TF_Messages.CloseForms();
var i:Integer;
begin
 for i := 0 to Self.frm_cnt-1 do
  if (Assigned(Self.frm_db[i])) then
   begin
    Self.frm_db[i].Close();
    Self.frm_db[i].RemoveClients();
   end;
end;

////////////////////////////////////////////////////////////////////////////////

class function TF_Messages.IsTyping():boolean;
var i:Integer;
begin
 for i := 0 to Self.frm_cnt-1 do
   if (Self.frm_db[i].IsTypin()) then
    Exit(true);
 Exit(false);
end;

////////////////////////////////////////////////////////////////////////////////
//////////// PAGE CONTROL CLOSE BUTTON DRAWING AND HANDLING ////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TF_Messages.PageControlCloseButtonDrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const Rect: TRect; Active: Boolean);
var
  CloseBtnSize: Integer;
  PageControl: TPageControl;
  TabSheet:TCloseTabSheet;
  TabCaption: TPoint;
  CloseBtnRect: TRect;
  CloseBtnDrawState: Cardinal;
  CloseBtnDrawDetails: TThemedElementDetails;
begin
  PageControl := Control as TPageControl;
  TabCaption.Y := Rect.Top + 3;

  // coloured caption
  if (PC_Clients.Pages[TabIndex].ShowHint) then
   Control.Canvas.Brush.Color := clYellow
  else
   Control.Canvas.Brush.Color := clBtnFace;
  PC_Clients.Pages[TabIndex].Brush.Color:=Control.Canvas.Brush.Color;

  if Active then
  begin
    CloseBtnRect.Top := Rect.Top + 4;
    CloseBtnRect.Right := Rect.Right - 5;
    TabCaption.X := Rect.Left + 6;
  end
  else
  begin
    CloseBtnRect.Top := Rect.Top + 3;
    CloseBtnRect.Right := Rect.Right - 5;
    TabCaption.X := Rect.Left + 3;
  end;

  if (PageControl.Pages[TabIndex] is TCloseTabSheet) then
  begin
    TabSheet := PageControl.Pages[TabIndex] as TCloseTabSheet;
    CloseBtnSize := 14;

    CloseBtnRect.Bottom := CloseBtnRect.Top + CloseBtnSize;
    CloseBtnRect.Left := CloseBtnRect.Right - CloseBtnSize;
    TabSheet.FCloseButtonRect := CloseBtnRect;

    PageControl.Canvas.FillRect(Rect);
    PageControl.Canvas.TextOut(TabCaption.X, TabCaption.Y,
            PageControl.Pages[TabIndex].Caption);

    if not ThemeServices.ThemesEnabled then
    begin
      if (FCloseButtonMouseDownTab = TabSheet) and FCloseButtonShowPushed then
        CloseBtnDrawState := DFCS_CAPTIONCLOSE + DFCS_PUSHED
      else
        CloseBtnDrawState := DFCS_CAPTIONCLOSE;

      Windows.DrawFrameControl(PageControl.Canvas.Handle,
        TabSheet.FCloseButtonRect, DFC_CAPTION, CloseBtnDrawState);
    end
    else
    begin
      Dec(TabSheet.FCloseButtonRect.Left);

      if (FCloseButtonMouseDownTab = TabSheet) and FCloseButtonShowPushed then
        CloseBtnDrawDetails := ThemeServices.GetElementDetails(twCloseButtonPushed)
      else
        CloseBtnDrawDetails := ThemeServices.GetElementDetails(twCloseButtonNormal);

      ThemeServices.DrawElement(PageControl.Canvas.Handle, CloseBtnDrawDetails,
                TabSheet.FCloseButtonRect);
    end;
  end else begin
    PageControl.Canvas.FillRect(Rect);
    PageControl.Canvas.TextOut(TabCaption.X, TabCaption.Y,
                 PageControl.Pages[TabIndex].Caption);
  end;
end;

procedure TF_Messages.PageControlCloseButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  PageControl: TPageControl;
  TabSheet:TCloseTabSheet;
begin
  PageControl := Sender as TPageControl;

  if Button = mbLeft then
  begin
    for I := 0 to PageControl.PageCount - 1 do
    begin
      if not (PageControl.Pages[i] is TCloseTabSheet) then Continue;
      TabSheet:=PageControl.Pages[i] as TCloseTabSheet;
      if PtInRect(TabSheet.FCloseButtonRect, Point(X, Y)) then
      begin
        FCloseButtonMouseDownTab := TabSheet;
        FCloseButtonShowPushed := True;
        PageControl.Repaint;
      end;
    end;
  end;

  Self.PC_Clients.BeginDrag(False);
end;

procedure TF_Messages.PageControlCloseButtonMouseLeave(Sender: TObject);
var
  PageControl: TPageControl;
begin
  PageControl := Sender as TPageControl;
  FCloseButtonShowPushed := False;
  PageControl.Repaint;
end;

procedure TF_Messages.PageControlCloseButtonMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  PageControl: TPageControl;
  Inside: Boolean;
begin
  PageControl := Sender as TPageControl;

  if (ssLeft in Shift) and Assigned(FCloseButtonMouseDownTab) then
  begin
    Inside := PtInRect(FCloseButtonMouseDownTab.FCloseButtonRect, Point(X, Y));

    if FCloseButtonShowPushed <> Inside then
    begin
      FCloseButtonShowPushed := Inside;
      PageControl.Repaint;
    end;
  end;
end;

procedure TF_Messages.PageControlCloseButtonMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  PageControl: TPageControl;
begin
  PageControl := Sender as TPageControl;

  if (Button = mbLeft) and Assigned(FCloseButtonMouseDownTab) then
  begin
    if PtInRect(FCloseButtonMouseDownTab.FCloseButtonRect, Point(X, Y)) then
    begin
      FCloseButtonMouseDownTab.DoClose;
      FCloseButtonMouseDownTab := nil;
      PageControl.Repaint;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_Messages.OnTabClose(Sender:TObject);
var i:Integer;
begin
 for i := 0 to Self.clients.Count-1 do
  if (Self.clients[i].Parent = Sender) then
   begin
    Self.clients.Delete(i);
    Sender.Free();
    Self.PC_Clients.Repaint();
    Exit();
   end;
end;

////////////////////////////////////////////////////////////////////////////////

initialization
 TF_Messages.frm_cnt := 0;

finalization
 TF_Messages.DestroyForms();

end.//unit
