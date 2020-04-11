unit fPotvrSekv;

{
  Okno potvrzovaci sekvence.
}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Generics.Collections;

const
  _POTVR_TIMEOUT_MIN = 2;
  _POTVR_ITEMS_PER_PAGE = 14;
  _FG_COLOR = $A0A0A0;
  _SYMBOL_HEIGHT = 12;
  _SYMBOL_WIDTH = 8;

type
  TPSEnd = (prubeh = 1,  success = 2, error = 3);
  TEndEvent = procedure(Sender: TObject) of object;

  TPSCondition = record
   block: string;
   condition: string;
    constructor Create(serverStr: string);
  end;

  TF_PotvrSekv = class(TForm)
    B_Storno: TButton;
    B_OK: TButton;
    P_bg: TPanel;
    P_Header: TPanel;
    P_Podminky: TPanel;
    L_ListDescription: TLabel;
    L_Description: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    L_Timeout: TLabel;
    L_DateTime: TLabel;
    PB_SFP_indexes: TPaintBox;
    PB_podm_Indexes: TPaintBox;
    PB_SFP: TPaintBox;
    PB_Podm: TPaintBox;
    Label5: TLabel;
    T_Main: TTimer;
    procedure B_OKClick(Sender: TObject);
    procedure B_StornoClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerUpdate(Sender:TObject);
    procedure FormPaint(Sender: TObject);

  private
    m_running: Boolean;
    m_start_time: TDateTime;
    m_event, m_station: string;
    m_senders: TList<string>;
    m_conditions: TList<TPSCondition>;
    m_flash: Boolean;
    m_page: Integer;
    m_end_reason: TPSEnd;
    m_OnEnd: TEndEvent;
    m_mode: string; // PS/IS

     procedure ShowTexts();
     procedure ShowFlashing();
     function GetPagesCount():Integer;

  public

     procedure StartOrUpdate(parsed:TStrings; callback:TEndEvent);
     procedure Stop(reason:string = '');
     procedure OnKeyUp(key: Integer; var handled: boolean);

     property OnEnd: TEndEvent read m_OnEnd write m_OnEnd;
     property PagesCount: Integer read GetPagesCount;
     property EndReason: TPSEnd read m_end_reason;
     property running: boolean read m_running;
     property mode: string read m_mode;

  end;

var
  F_PotvrSekv: TF_PotvrSekv;

implementation

uses fMain, BottomErrors, Sounds, parseHelper, IBUtils, Math;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

constructor TPSCondition.Create(serverStr: string);
var strs: TStrings;
begin
 strs := TStringList.Create();
 try
   ExtractStringsEx(['|'], [], serverStr, strs);
   block := strs[0];
   condition := strs[1];
 finally
   strs.Free();
 end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_PotvrSekv.FormCreate(Sender: TObject);
begin
 Self.m_senders := TList<string>.Create();
 Self.m_conditions := TList<TPSCondition>.Create();
end;

procedure TF_PotvrSekv.FormDestroy(Sender: TObject);
begin
 Self.m_senders.Free();
 Self.m_conditions.Free();
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_PotvrSekv.StartOrUpdate(parsed:TStrings; callback:TEndEvent);
var str: string;
    strs: TStrings;
begin
 strs := TStringList.Create();

 try
   Self.m_mode := parsed[1];
   Self.m_end_reason := TPSEnd.prubeh;
   Self.m_OnEnd := callback;
   Self.m_station := parsed[2];
   Self.m_event := parsed[3];
   Self.m_page := 0;
   Self.m_senders.Clear();
   Self.m_flash := false;

   Self.B_Storno.Visible := (m_mode <> 'IS');
   if (m_mode = 'IS') then
    begin
     Self.L_Description.Caption := 'INFORMAČNÍ STRÁNKA';
     Self.L_ListDescription.Caption := 'INFORMACE';
     Self.B_OK.Caption := 'OK';
    end else begin
     Self.L_Description.Caption := '!!! PROBÍHÁ RIZIKOVÁ FUNKCE !!!';
     Self.L_ListDescription.Caption := 'KONTROLOVANÉ PODMÍNKY';
     Self.B_OK.Caption := 'Souhlasím';
    end;

   if (parsed.Count >= 5) then
    begin
     ExtractStringsEx(['|'], [], parsed[4], strs);
     for str in strs do
       Self.m_senders.Add(str);
    end;

   Self.m_conditions.Clear();
   strs.Clear();

   if (parsed.Count >= 6) then
    begin
     ExtractStringsEx([']'], ['['], parsed[5], strs);
     for str in strs do
      begin
       try
        Self.m_conditions.Add(TPSCondition.Create(str));
       except

       end;
      end;
    end;

   if (not Self.running) then
     Self.m_start_time := now;
   Self.m_running := true;
   Self.T_Main.Enabled := true;

   if ((Self.mode = 'PS') and (not SoundsPlay.IsPlaying(_SND_POTVR_SEKV))) then
     SoundsPlay.Play(_SND_POTVR_SEKV, true);
 finally
   strs.Free();
 end;

 Relief.UpdateEnabled();
 Self.Show();
 Self.B_OK.SetFocus();
 Self.TimerUpdate(Self);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_PotvrSekv.TimerUpdate(Sender:TObject);
begin
 Self.m_flash := not Self.m_flash;
 Self.ShowFlashing();

 Self.L_DateTime.Caption := FormatDateTime('dd.mm.yyyy hh:mm:ss', Now);
 Self.L_Timeout.Caption := FormatDateTime('nn:ss', (now-Self.m_start_time));

 if (Self.m_start_time+encodetime(0, _POTVR_TIMEOUT_MIN, 0, 0) < now) then
  begin
   Self.Stop('Překročení času potvrzovací sekvence!');
   Errors.writeerror('Překročení času potvrzovací sekvence','Potvr. sekvence','');
  end;
end;

////////////////////////////////////////////////////////////////////////////////

//pokud je v reason '', ukonceni se povazuje za ok, pokud ne, ukonceni se povazuje za error
procedure TF_PotvrSekv.Stop(reason:string = '');
begin
 if ((reason = '') or (Self.mode = 'IS')) then
  begin
   Self.m_end_reason := TPSEnd.success;
  end else begin
   Self.m_end_reason := TPSEnd.error;
   Errors.writeerror(reason, 'Potvr. sekvence', '');
  end;

 Self.m_running := false;
 if (Self.mode = 'PS') then
   SoundsPlay.DeleteSound(_SND_POTVR_SEKV);
 Relief.UpdateEnabled();
 Self.T_Main.Enabled := false;
 if (Assigned(Self.OnEnd)) then
   Self.OnEnd(Self);
 Self.Close();
end;

procedure TF_PotvrSekv.ShowTexts();
var i, podm_start, podm_count: Integer;
begin
 Self.PB_SFP_indexes.Canvas.Pen.Color := Self.PB_SFP_indexes.Color;
 Self.PB_SFP_indexes.Canvas.Brush.Color := Self.PB_SFP_indexes.Color;
 Self.PB_SFP_indexes.Canvas.FillRect(Rect(0, 0, Self.PB_SFP_indexes.Width, Self.PB_SFP_indexes.Height));

 Self.PB_SFP.Canvas.Pen.Color := Self.PB_SFP.Color;
 Self.PB_SFP.Canvas.Brush.Color := Self.PB_SFP.Color;
 Self.PB_SFP.Canvas.FillRect(Rect(0, 0, Self.PB_SFP.Width, Self.PB_SFP.Height));

 Self.PB_podm_Indexes.Canvas.Pen.Color := Self.PB_podm_Indexes.Color;
 Self.PB_podm_Indexes.Canvas.Brush.Color := Self.PB_podm_Indexes.Color;
 Self.PB_podm_Indexes.Canvas.FillRect(Rect(0, 0, Self.PB_podm_Indexes.Width, Self.PB_podm_Indexes.Height));

 Self.PB_Podm.Canvas.Pen.Color := Self.PB_Podm.Color;
 Self.PB_Podm.Canvas.Brush.Color := Self.PB_Podm.Color;
 Self.PB_Podm.Canvas.FillRect(Rect(0, 0, Self.PB_Podm.Width, Self.PB_Podm.Height));

 with (Self.PB_SFP_indexes.Canvas) do
  begin
   Font.Color := clBlack;
   TextOut(0, 0, 'S:');
   TextOut(0, _SYMBOL_HEIGHT, 'F:');
   for i := 0 to Self.m_senders.Count-1 do
     TextOut(0, 2*_SYMBOL_HEIGHT+(i*_SYMBOL_HEIGHT), 'P'+IntToStr(i+1));
  end;

 with (Self.PB_SFP.Canvas) do
  begin
   Font.Color := clWhite;
   TextOut(2*_SYMBOL_WIDTH, 0, Self.m_station);
   TextOut(2*_SYMBOL_WIDTH, _SYMBOL_HEIGHT, ' '+Self.m_event);
   Font.Color := _FG_COLOR;
   for i := 0 to Self.m_senders.Count-1 do
     TextOut(2*_SYMBOL_WIDTH, 2*_SYMBOL_HEIGHT+(i*_SYMBOL_HEIGHT), Self.m_senders[i]);
  end;

 podm_start := (Self.m_page * (_POTVR_ITEMS_PER_PAGE-1));
 podm_count := Min(_POTVR_ITEMS_PER_PAGE-1, Self.m_conditions.Count-podm_start);

 // indexy kontrolovanych podminek
 with (Self.PB_podm_Indexes.Canvas) do
   for i := 0 to podm_count do
     TextOut(IfThen(i+podm_start > 8, 0, 8), (i*_SYMBOL_HEIGHT), IntToStr(podm_start+i+1));

 // podminky
 with (Self.PB_Podm.Canvas) do
  begin
   Font.Color := _FG_COLOR;
   for i := 0 to podm_count-1 do
    begin
     TextOut(2*_SYMBOL_WIDTH, (i*_SYMBOL_HEIGHT), Self.m_conditions[podm_start+i].block);
     TextOut(30*_SYMBOL_WIDTH, (i*_SYMBOL_HEIGHT), '# '+Self.m_conditions[podm_start+i].condition);
    end;
   Font.Color := clWhite;

   if (podm_start+podm_count >= Self.m_conditions.Count) then
     TextOut(2*_SYMBOL_WIDTH, (podm_count*12), 'KONEC SEZNAMU')
   else
     TextOut(2*_SYMBOL_WIDTH, (podm_count*12), 'SEZNAM POKRAČUJE');
  end;
end;

procedure TF_PotvrSekv.ShowFlashing();
var i, plus, podm_start, podm_count:Integer;
begin
 plus := IfThen(Self.m_flash, 6, 0);

 if (F_Main.IL_Ostatni.BkColor <> clBlack) then
   F_Main.IL_Ostatni.BkColor := clBlack;

 // stanice, udalost, bloky:
 with (Self.PB_SFP.Canvas) do
  begin
   if (plus = 6) then
     F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0, 0, 69);
   F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0, plus, 61);
   F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0, 12+plus, 61);
   for i := 0 to Self.m_senders.Count-1 do
     F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0,
                            2*_SYMBOL_HEIGHT+plus+(i*_SYMBOL_HEIGHT), 61);
  end;

 podm_start := (Self.m_page * (_POTVR_ITEMS_PER_PAGE-1));
 podm_count := Min(_POTVR_ITEMS_PER_PAGE-1, Self.m_conditions.Count-podm_start);

 // podminky
 with (Self.PB_Podm.Canvas) do
  begin
   if (plus = 6) then
     F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_Podm.Canvas, 0, 0, 69);
   for i := 0 to podm_count do
     F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_Podm.Canvas, 0, (i*12)+plus, 61);
  end;
end;

procedure TF_PotvrSekv.B_OKClick(Sender: TObject);
begin
 Self.Stop();
end;

procedure TF_PotvrSekv.B_StornoClick(Sender: TObject);
begin
 Self.Stop('Stisknuto tlačítko Nesouhlasím');
end;

procedure TF_PotvrSekv.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if ((Self.running) and (Self.mode = 'PS')) then
   Self.Stop('Zavřeno okno potvrzovací sekvence');
end;

procedure TF_PotvrSekv.FormKeyPress(Sender: TObject; var Key: Char);
begin
 if (Key = #27) then
  Self.B_StornoClick(Self.B_Storno)
end;

procedure TF_PotvrSekv.FormPaint(Sender: TObject);
begin
 Self.ShowTexts();
 Self.ShowFlashing();
end;

procedure TF_PotvrSekv.OnKeyUp(key: Integer; var handled: boolean);
begin
 if ((key = VK_PRIOR) and (Self.m_page > 0)) then begin
   Dec(Self.m_page);
   Self.ShowTexts();
   Self.ShowFlashing();
 end else if ((key = VK_NEXT) and (Self.m_page < Self.pagesCount)) then begin
   Inc(Self.m_page);
   Self.ShowTexts();
   Self.ShowFlashing();
 end;
end;

////////////////////////////////////////////////////////////////////////////////

function TF_PotvrSekv.GetPagesCount():Integer;
begin
 Result := (Self.m_conditions.Count div (_POTVR_ITEMS_PER_PAGE-1));
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit

