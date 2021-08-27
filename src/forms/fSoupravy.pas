unit fSoupravy;

{
  Okno seznamu vsech souprav.
}

interface

uses Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Generics.Collections, StrUtils;

type
  TF_SprList = class(TForm)
    P_Top: TPanel;
    B_Refresh: TButton;
    B_RemoveSpr: TButton;
    LV_Soupravy: TListView;
    procedure FormShow(Sender: TObject);
    procedure B_RefreshClick(Sender: TObject);
    procedure LV_SoupravyChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure B_RemoveSprClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }

    listRequest: boolean;

    procedure AddSpr(str: string);
    function ParseHV(str: string): string;
    function FindIndexForNewSpr(cislo: Integer): Integer;

  public

    procedure ParseLoko(str: string);
  end;

var
  F_SprList: TF_SprList;

implementation

uses TCPClientPanel, ORList, parseHelper;

{$R *.dfm}
/// /////////////////////////////////////////////////////////////////////////////

procedure TF_SprList.ParseLoko(str: string);
var sl: TStrings;
  i: Integer;
begin
  Self.LV_Soupravy.Clear();
  Self.LV_Soupravy.Color := clWhite;
  Self.B_RemoveSpr.Enabled := false;

  sl := TStringList.Create();
  try
    ExtractStringsEx([']'], ['['], str, sl);

    for i := 0 to sl.Count - 1 do
    begin
      try
        Self.AddSpr(sl[i]);
      except

      end;
    end;

    if (Self.listRequest) then
      Application.MessageBox('Tabulka souprav aktualizována.', 'OK', MB_OK OR MB_ICONINFORMATION);
    Self.listRequest := false;
  finally
    sl.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_SprList.AddSpr(str: string);
var sl, slhv: TStrings;
  LI: TListItem;
begin
  sl := TStringList.Create();
  slhv := TStringList.Create();
  ExtractStringsEx([';'], [], str, sl);

  try
    try
      LI := Self.LV_Soupravy.Items.Insert(Self.FindIndexForNewSpr(StrToInt(sl[0])));
    except
      LI := Self.LV_Soupravy.Items.Add;
    end;

    LI.Caption := sl[0];

    if (sl.Count > 6) then
    begin
      ExtractStringsEx([']'], ['['], sl[6], slhv);
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

    if ((sl.Count > 7) and (areaDb.db.ContainsKey(sl[7]))) then
      LI.SubItems.Add(areaDb.db[sl[7]])
    else
      LI.SubItems.Add('Nevyplněno');

    if ((sl.Count > 8) and (areaDb.db.ContainsKey(sl[8]))) then
      LI.SubItems.Add(areaDb.db[sl[8]])
    else
      LI.SubItems.Add('Nevyplněno');
  except

  end;

  sl.Free();
  slhv.Free();
end;

/// /////////////////////////////////////////////////////////////////////////////

// format zapisu: nazev|majitel|oznaceni|poznamka|adresa|trida|souprava|stanovisteA|funkce
function TF_SprList.ParseHV(str: string): string;
var sl: TStrings;
begin
  sl := TStringList.Create();

  try
    ExtractStringsEx(['|'], [], str, sl);
    Result := sl[4] + ' : ' + sl[0] + ' (' + sl[2] + ')';
  except

  end;

  sl.Free();
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_SprList.B_RefreshClick(Sender: TObject);
begin
  Self.LV_Soupravy.Color := clSilver;
  Self.LV_Soupravy.Clear();
  Self.listRequest := true;

  PanelTCPClient.SendLn('-;SPR-LIST;');
end;

procedure TF_SprList.B_RemoveSprClick(Sender: TObject);
var toRemove: TList<string>;
  LI: TListItem;
  sprs, spr: string;
  Count: Integer;
begin
  if (Self.LV_Soupravy.Selected = nil) then
    Exit();

  toRemove := TList<string>.Create();
  try
    sprs := '';
    Count := 0;
    for LI in Self.LV_Soupravy.Items do
    begin
      if (LI.Selected) then
      begin
        toRemove.Add(LI.Caption);
        sprs := sprs + LI.Caption + ', ';
        Inc(Count);
      end;
    end;
    sprs := LeftStr(sprs, Length(sprs) - 2);

    if (Count = 1) then
      sprs := 'soupravu ' + sprs
    else
      sprs := 'soupravy ' + sprs;

    if (Application.MessageBox(PChar('Opravdu smazat ' + sprs + ' z kolejiště?'), 'Otázka', MB_YESNO OR MB_ICONQUESTION)
      = mrYes) then
      for spr in toRemove do
        PanelTCPClient.SendLn('-;SPR-REMOVE;' + spr);
  finally
    toRemove.Clear();
  end;
end;

procedure TF_SprList.FormCreate(Sender: TObject);
begin
  Self.listRequest := false;
end;

procedure TF_SprList.FormShow(Sender: TObject);
begin
  Self.LV_Soupravy.Color := clSilver;
  Self.LV_Soupravy.Clear();
  Self.B_RemoveSpr.Enabled := false;

  PanelTCPClient.SendLn('-;SPR-LIST;');
end;

procedure TF_SprList.LV_SoupravyChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if (Self.LV_Soupravy.Selected = nil) then
    Self.B_RemoveSpr.Enabled := false
  else
    Self.B_RemoveSpr.Enabled := true;

  if (Self.LV_Soupravy.SelCount > 1) then
    Self.B_RemoveSpr.Caption := 'Smazat soupravy'
  else
    Self.B_RemoveSpr.Caption := 'Smazat soupravu';
end;

/// /////////////////////////////////////////////////////////////////////////////

function TF_SprList.FindIndexForNewSpr(cislo: Integer): Integer;
var i: Integer;
begin
  try
    i := Self.LV_Soupravy.Items.Count - 1;
    while ((i >= 0) and (StrToInt(Self.LV_Soupravy.Items[i].Caption) > cislo)) do
      i := i - 1;
    Result := i + 1;
  except
    Result := Self.LV_Soupravy.Items.Count;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
