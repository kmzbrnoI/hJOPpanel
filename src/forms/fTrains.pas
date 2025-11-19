unit fTrains;

{
  Window with list of all trains in all controlled areas.
}

interface

uses Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Generics.Collections, StrUtils;

type
  TF_Trains = class(TForm)
    P_Top: TPanel;
    B_Refresh: TButton;
    B_RemoveTrain: TButton;
    LV_Trains: TListView;
    procedure FormShow(Sender: TObject);
    procedure B_RefreshClick(Sender: TObject);
    procedure LV_TrainsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure B_RemoveTrainClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LV_TrainsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
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
  F_Trains: TF_Trains;

implementation

uses TCPClientPanel, ORList, parseHelper, GlobalConfig;

{$R *.dfm}
/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Trains.ParseLoko(str: string);
begin
  Self.LV_Trains.Clear();
  Self.LV_Trains.Color := clWhite;
  Self.B_RemoveTrain.Enabled := false;

  var sl: TStrings := TStringList.Create();
  try
    ExtractStringsEx([']'], ['['], str, sl);

    for var i := 0 to sl.Count - 1 do
    begin
      try
        Self.AddSpr(sl[i]);
      except

      end;
    end;

    if (Self.listRequest) then
      Application.MessageBox('Tabulka vlaků aktualizována.', 'OK', MB_OK OR MB_ICONINFORMATION);
    Self.listRequest := false;
  finally
    sl.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_Trains.AddSpr(str: string);
var sl, slhv: TStrings;
  LI: TListItem;
begin
  sl := TStringList.Create();
  slhv := TStringList.Create();
  ExtractStringsEx([';'], [], str, sl);

  try
    try
      LI := Self.LV_Trains.Items.Insert(Self.FindIndexForNewSpr(StrToInt(sl[0])));
    except
      LI := Self.LV_Trains.Items.Add();
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

// format zapisu: nazev|majitel|oznaceni|poznamka|adresa|trida|vlak|stanovisteA|funkce
function TF_Trains.ParseHV(str: string): string;
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

procedure TF_Trains.B_RefreshClick(Sender: TObject);
begin
  Self.LV_Trains.Color := clSilver;
  Self.LV_Trains.Clear();
  Self.listRequest := true;

  PanelTCPClient.SendLn('-;SPR-LIST;');
end;

procedure TF_Trains.B_RemoveTrainClick(Sender: TObject);
var toRemove: TList<string>;
  sprs, spr: string;
  Count: Integer;
begin
  if (Self.LV_Trains.Selected = nil) then
    Exit();

  toRemove := TList<string>.Create();
  try
    sprs := '';
    Count := 0;
    for var LI in Self.LV_Trains.Items do
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
      sprs := 'vlak ' + sprs
    else
      sprs := 'vlaky ' + sprs;

    if (Application.MessageBox(PChar('Opravdu smazat ' + sprs + ' z kolejiště?'), 'Otázka', MB_YESNO OR MB_ICONQUESTION)
      = mrYes) then
      for spr in toRemove do
        PanelTCPClient.SendLn('-;SPR-REMOVE;' + spr);
  finally
    toRemove.Clear();
  end;
end;

procedure TF_Trains.FormCreate(Sender: TObject);
begin
  Self.listRequest := false;
end;

procedure TF_Trains.FormShow(Sender: TObject);
begin
  Self.LV_Trains.Color := clSilver;
  Self.LV_Trains.Clear();
  Self.B_RemoveTrain.Enabled := false;

  PanelTCPClient.SendLn('-;SPR-LIST;');
  Self.Caption := 'Vlaky – ' + GlobConfig.panelName;
end;

procedure TF_Trains.LV_TrainsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  Self.B_RemoveTrain.Enabled := (Self.LV_Trains.Selected <> nil);

  if (Self.LV_Trains.SelCount > 1) then
    Self.B_RemoveTrain.Caption := 'Smazat vlaky'
  else
    Self.B_RemoveTrain.Caption := 'Smazat vlak';
end;

procedure TF_Trains.LV_TrainsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ((Key = VK_DELETE) and (Self.B_RemoveTrain.Enabled)) then
    Self.B_RemoveTrainClick(Self);
end;

/// /////////////////////////////////////////////////////////////////////////////

function TF_Trains.FindIndexForNewSpr(cislo: Integer): Integer;
var i: Integer;
begin
  try
    i := Self.LV_Trains.Items.Count - 1;
    while ((i >= 0) and (StrToInt(Self.LV_Trains.Items[i].Caption) > cislo)) do
      i := i - 1;
    Result := i + 1;
  except
    Result := Self.LV_Trains.Items.Count;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.// unit
