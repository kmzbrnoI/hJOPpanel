unit PanelOR;

{
  Definice oblasti rizeni.
}

interface

uses Generics.Collections, Zasobnik, Types, HVDb, RPConst, Classes, SysUtils,
  PGraphics;

type
  TAreaControlRights = (null = 0, read = 1, write = 2, superuser = 3);
  TAreaDkOrientation = (dkBot = 0, dkTop = 1);

  TAreaRights = record
    modelTimeStart: Boolean;
    modelTimeStop: Boolean;
    modelTimeSet: Boolean;
  end;

  TAreaPos = record
    dk: TPoint;
    dkOrentation: TAreaDkOrientation;
    time: TPoint;
  end;

  TAreaLights = record
    board: Cardinal;
    port: Cardinal;
    name: string; // max length = 5
    state: Boolean;
  end;

  TCountdown = record
    start: TDateTime;
    length: TDateTime;
    id: Integer;
  end;

  TAreaRegPleaseStatus = (none = 0, request = 1, selected = 2);

  TAreaRegPlease = record
    status: TAreaRegPleaseStatus;
    user, firstname, lastname, comment: string;
  end;

  TAreaOrientation = (aoOddLeftToRight = 0, aoOddRightToLeft = 1);

  EInvalidData = class(Exception);

  TAreaPanel = class
    str: string;
    name: string;
    shortName: string;
    id: string;
    orientation: TAreaOrientation;
    rights: TAreaRights;
    positions: TAreaPos;
    lights: TList<TAreaLights>;
    countdown: TList<TCountdown>;

    tech_rights: TAreaControlRights;
    dk_blik: Boolean;
    dk_click_server: Boolean;
    stack: TORStack;

    username: string;
    login: string;

    NUZ_status: TNUZstatus;
    RegPlease: TAreaRegPlease;

    HVs: THVDb;

    announcement: Boolean;

    constructor Create(line: string; Graphics: TPanelGraphics);
    destructor Destroy(); override;
  end;

implementation

uses parseHelper;

/// /////////////////////////////////////////////////////////////////////////////

constructor TAreaPanel.Create(line: string; Graphics: TPanelGraphics);
var data_main, data_osv, data_osv2: TStrings;
  Pos: TPoint;
begin
  inherited Create();

  data_main := TStringList.Create();
  data_osv := TStringList.Create();
  data_osv2 := TStringList.Create();

  try
    ExtractStringsEx([';'], [], line, data_main);

    if (data_main.Count < 14) then
      raise EInvalidData.Create('Prilis malo polozek v zaznamu oblasti rizeni!');

    Self.str := line;

    Self.name := data_main[0];
    Self.shortName := data_main[1];
    Self.id := data_main[2];
    Self.orientation := TAreaOrientation(StrToInt(data_main[3]));
    Self.positions.dkOrentation := TAreaDkOrientation(StrToInt(data_main[4]));

    Self.rights.ModelTimeStart := StrToBool(data_main[5]);
    Self.rights.ModelTimeStop := StrToBool(data_main[6]);
    Self.rights.ModelTimeSet := StrToBool(data_main[7]);

    Self.positions.DK.X := StrToInt(data_main[8]);
    Self.positions.DK.Y := StrToInt(data_main[9]);

    Pos.X := StrToInt(data_main[10]);
    Pos.Y := StrToInt(data_main[11]);
    Self.stack := TORStack.Create(Graphics, Self.id, Pos);

    Self.positions.Time.X := StrToInt(data_main[12]);
    Self.positions.Time.Y := StrToInt(data_main[13]);

    Self.lights := TList<TAreaLights>.Create();
    Self.countdown := TList<TCountdown>.Create();

    data_osv.Clear();
    if (data_main.Count >= 15) then
    begin
      ExtractStrings(['|'], [], PChar(data_main[14]), data_osv);
      for var j := 0 to data_osv.Count - 1 do
      begin
        data_osv2.Clear();
        ExtractStrings(['#'], [], PChar(data_osv[j]), data_osv2);

        if (data_osv2.Count < 2) then
          continue;

        var lights: TAreaLights;
        lights.board := StrToInt(data_osv2[0]);
        lights.port := StrToInt(data_osv2[1]);
        if (data_osv2.Count > 2) then
          lights.name := data_osv2[2]
        else
          lights.name := '';
        Self.lights.Add(lights);
      end;
    end;

    Self.HVs := THVDb.Create();
  finally
    data_main.Free();
    data_osv.Free();
    data_osv2.Free();
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////

destructor TAreaPanel.Destroy();
begin
  Self.stack.Free();
  Self.lights.Free();
  Self.countdown.Free();
  Self.HVs.Free();
  inherited;
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
