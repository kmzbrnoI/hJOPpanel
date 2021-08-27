unit BlockTypes;

interface

uses Classes, Graphics;

type
  TBlkType = (btAny = -1, btTurnout = 0, btTrack = 1, btIr = 2, btSignal = 3, btCrossing = 4, btRailway = 5,
    btLinker = 6, btLock = 7, btDisconnector = 8, btRT = 9, btIO = 10, btSummary = 11, btAC = 12, btGroupSignal = 13,
    btPst = 14,
    btLinkerSpr = 100, btDerail = 101, btOther = 102);

  TJCType = (undefinned = -1, no = 0, vlak = 1, posun = 2, nouz = 3, staveni = 4);

  TGeneralPanelProp = record
    fg, bg: TColor;
    flash: boolean;

    procedure Change(parsed: TStrings);
  end;

implementation

uses ParseHelper, RPConst;

procedure TGeneralPanelProp.Change(parsed: TStrings);
begin
  fg := StrToColor(parsed[4]);
  bg := StrToColor(parsed[5]);
  flash := StrToBool(parsed[6]);
end;


end.
