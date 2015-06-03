unit Soupravy;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls;

type
  TF_SprList = class(TForm)
    P_Top: TPanel;
    B_Refresh: TButton;
    B_RemoveSpr: TButton;
    LV_Soupravy: TListView;
    procedure FormShow(Sender: TObject);
    procedure B_RefreshClick(Sender: TObject);
    procedure LV_SoupravyChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure B_RemoveSprClick(Sender: TObject);
  private
    { Private declarations }

    procedure AddSpr(str:string);
    function ParseHV(str:string):string;

  public

    procedure ParseLoko(str:string);
  end;

var
  F_SprList: TF_SprList;

implementation

uses RPConst, TCPClientPanel;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprList.ParseLoko(str:string);
var sl:TStrings;
    i:Integer;
begin
 Self.LV_Soupravy.Clear();
 Self.LV_Soupravy.Color := clWhite;
 Self.B_RemoveSpr.Enabled := false;

 sl := TStringList.Create();
 ExtractStrings(['(', ')'], [], PChar(str), sl);

 for i := 0 to sl.Count-1 do
  begin
   try
     Self.AddSpr(sl[i]);
   except

   end;
  end;

 sl.Free();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

// format dat soupravy: nazev;pocet_vozu;poznamka;smer_Lsmer_S;delka;typ;hnaci vozidla
procedure TF_SprList.AddSpr(str:string);
var sl,slhv:TStrings;
    LI:TListItem;
begin
 sl := TStringList.Create();
 slhv := TStringList.Create();
 ExtractStringsEx(';', str, sl);

 try
   LI := Self.LV_Soupravy.Items.Add;
   LI.Caption := sl[0];

   if (sl.Count > 6) then
    begin
     ExtractStrings(['[', ']'], [], PChar(sl[6]), slhv);
     if (slhv.Count > 0) then
      begin
       LI.SubItems.Add(Self.ParseHV(slhv[0]));
       if (slhv.Count > 1) then
        LI.SubItems.Add(Self.ParseHV(slhv[1]))
       else
        LI.SubItems.Add('');
      end;
    end else begin
     LI.SubItems.Add('');
     LI.SubItems.Add('');
    end;
   LI.SubItems.Add(sl[2]);
   LI.SubItems.Add(sl[1]);
   LI.SubItems.Add(sl[4]);
   LI.SubItems.Add(sl[5]);
 except

 end;

 sl.Free();
 slhv.Free();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

 // format zapisu: nazev|majitel|oznaceni|poznamka|adresa|trida|souprava|stanovisteA|funkce
function TF_SprList.ParseHV(str:string):string;
var sl:TStrings;
begin
 sl := TStringList.Create();

 try
   ExtractStringsEx('|', str, sl);
   Result := sl[4] + ' : ' + sl[0] + ' (' + sl[2] + ')';
 except

 end;

 sl.Free();
end;//function

////////////////////////////////////////////////////////////////////////////////

procedure TF_SprList.B_RefreshClick(Sender: TObject);
begin
 Self.LV_Soupravy.Color := clSilver;
 Self.LV_Soupravy.Clear();

 PanelTCPClient.SendLn('-;SPR-LIST;');
end;

procedure TF_SprList.B_RemoveSprClick(Sender: TObject);
begin
 if (Self.LV_Soupravy.Selected <> nil) then
  if (Application.MessageBox(PChar('Opravdu smazat soupravu '+Self.LV_Soupravy.Selected.Caption+' z kolejištì?'), 'Otázka', MB_YESNO OR MB_ICONQUESTION) = mrYes) then
    PanelTCPClient.SendLn('-;SPR-REMOVE;'+Self.LV_Soupravy.Selected.Caption);
end;

procedure TF_SprList.FormShow(Sender: TObject);
begin
 Self.B_RemoveSpr.Enabled   := false;
 Self.LV_Soupravy.ItemIndex := -1;
 Self.B_RefreshClick(Self);
end;

procedure TF_SprList.LV_SoupravyChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
 if (Self.LV_Soupravy.Selected = nil) then
  Self.B_RemoveSpr.Enabled := false
 else
  Self.B_RemoveSpr.Enabled := true;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit
