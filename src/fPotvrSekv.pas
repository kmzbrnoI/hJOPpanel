unit fPotvrSekv;

{
  Okno potvrzovaci sekvence.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Generics.Collections;

const
  _POTVR_TIMEOUT_MIN = 2;

type
  TF_PotvrSekv = class(TForm)
    B_Storno: TButton;
    B_OK: TButton;
    P_bg: TPanel;
    P_Header: TPanel;
    P_Podminky: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    L_Timeout: TLabel;
    L_DateTime: TLabel;
    PB_SFP_indexes: TPaintBox;
    PB_podm_Indexes: TPaintBox;
    PB_SFP: TPaintBox;
    PB_Podm: TPaintBox;
    procedure B_OKClick(Sender: TObject);
    procedure B_StornoClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

 TPSEnd = (prubeh = 1,  success = 2, error = 3);

 TEndEvent = procedure(reason:TPSEnd) of object;

 TPSPodminka = record
  blok:string;
  podminka:string;
 end;

 //tato trida se stara o povrzovaci sekvenci
 TPotvrSekv=class                                   //data rizikove funkce
  private
    started:Boolean;
    StartPotvrSekv:TDateTime;                          //zacatek vyvolani Potvr. sekv (cas)

    udalost,stanice:string;
    senders:TList<string>;
    podminky:TList<TPSPodminka>;

    blik:Boolean;
    Timer:TTimer;

    FOnEnd : TEndEvent;

     procedure UpdateForm();

  public
   EndReason:TPSEnd;

   constructor Create();
   destructor Destroy(); override;

    procedure Start(parsed:TStrings; callback:TEndEvent);//zobrazi rizikovaou udalost a vyvola Potvr. sekv
    procedure Update(Sender:TObject);
    procedure Stop(reason:string = '');          //rusi Potvr. sekv

    property OnEnd:TEndEvent read FOnEnd write FOnEnd;
 end;//class TPotvrSekv


var
  F_PotvrSekv: TF_PotvrSekv;
  PotvrSek:TPotvrSekv;

implementation

uses fMain, Verze, BottomErrors, Sounds, RPConst;

{$R *.dfm}
////////////////////////////////////////////////////////////////////////////////


constructor TPotvrSekv.Create();
begin
 inherited Create();

 Self.senders  := TList<string>.Create();
 Self.podminky := TList<TPSPodminka>.Create();
end;//ctor

destructor TPotvrSekv.Destroy();
begin
 Self.senders.Free();
 Self.podminky.Free();

 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

//  -;PS;stanice;udalost;sender1|sender2|...;(blok1_name;blok1_podminka)(blok2_name;blok2_podminka)(...)...
//                                          - pozadavek na zobrazeni potvrzovaci sekvence
procedure TPotvrSekv.Start(parsed:TStrings; callback:TEndEvent);
var i:Integer;
    str,str2:TStrings;
    podm:TPSPodminka;
begin
 str  := TStringList.Create();
 str2 := TStringList.Create();

 Self.EndReason := TPSEnd.prubeh;
 Self.FOnEnd    := callback;

 Self.stanice := parsed[2];
 Self.udalost := parsed[3];

 Self.senders.Clear();

 if (parsed.Count >= 5) then
  begin
   ExtractStringsEx(['|'], [], parsed[4], str);
   for i := 0 to str.Count-1 do
    Self.senders.Add(str[i]);
  end;

 Self.podminky.Clear();
 str.Clear();

 if (parsed.Count >= 6) then
  begin
   ExtractStringsEx([']'], ['['], parsed[5], str);
   for i := 0 to str.Count-1 do
    begin
     str2.Clear();
     ExtractStringsEx(['|'], [], str[i], str2);

     try
      podm.blok     := str2[0];
      podm.podminka := str2[1];
      Self.podminky.Add(podm);
     except

     end;//except
    end;//for i
  end;//if parsed.Count >= 6


 Self.blik := false;
 if (not Self.started) then
   Self.StartPotvrSekv := now;
 Self.started := true;

 if (not Assigned(Timer)) then
  begin
   Timer := TTimer.Create(nil);
   Timer.Interval := 500;
   Timer.OnTimer  := Self.Update;
  end;
 Timer.Enabled := true;

 if (not SoundsPlay.IsPlaying(_SND_POTVR_SEKV)) then
   SoundsPlay.Play(_SND_POTVR_SEKV, true);

 str.Free();
 str2.Free();

 with (F_PotvrSekv.PB_SFP_indexes) do
   Canvas.FillRect(Rect(0, 0, Width, Height));
 with (F_PotvrSekv.PB_podm_Indexes) do
   Canvas.FillRect(Rect(0, 0, Width, Height));
 with (F_PotvrSekv.PB_SFP) do
   Canvas.FillRect(Rect(0, 0, Width, Height));
 with (F_PotvrSekv.PB_Podm) do
   Canvas.FillRect(Rect(0, 0, Width, Height));

 F_Main.DXD_Main.Enabled := false;
 F_PotvrSekv.Show();
 F_PotvrSekv.B_OK.SetFocus();
 Self.Update(Self);
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TPotvrSekv.Update(Sender:TObject);
begin
 Self.UpdateForm();
 Self.blik := not Self.blik;

 if (Self.StartPotvrSekv+encodetime(0, _POTVR_TIMEOUT_MIN, 0, 0) < now) then
  begin
   Self.Stop('Pøekroèení èasu potvrzovací sekvence!');
   Errors.writeerror('Pøekroèení èasu potvrzovací sekvence','Potvr. sekvence','');
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

//pokud je v reason '', ukonceni se povazuje za ok, pokud ne, ukonceni se povazuje za error
procedure TPotvrSekv.Stop(reason:string = '');
begin
 F_Main.DXD_Main.Enabled := true;

 if (reason = '') then
  begin
   Self.EndReason := TPSEnd.success;
  end else begin
   Self.EndReason := TPSEnd.error;
   Errors.writeerror(reason, 'Potvr. sekvence', '');
  end;

 SoundsPlay.DeleteSound(_SND_POTVR_SEKV);

 if (Assigned(Self.FOnEnd)) then Self.FOnEnd(Self.EndReason);
 Self.started := false;
 Self.Timer.Enabled := false;
 F_PotvrSekv.Close();
end;//procedure

procedure TPotvrSekv.UpdateForm();
var i, plus:Integer;
begin
  // blikani
  if (blik) then
    plus := 6
  else
    plus := 0;

  F_Main.IL_Ostatni.BkColor := clBlack;

  // texty S: F: P1..Pn
  with (F_PotvrSekv.PB_SFP_indexes.Canvas) do
   begin
    TextOut(0, 0, 'S:');
    TextOut(0, 12, 'F:');
    for i := 0 to Self.senders.Count-1 do
     TextOut(0, 24+(i*12), 'P'+IntToStr(i+1));
   end;//with

  // indexy kontrolovanych podminek
  with (F_PotvrSekv.PB_podm_Indexes.Canvas) do
   begin
    for i := 0 to Self.podminky.Count do
     begin
      if (i > 8) then
        TextOut(0, (i*12), IntToStr(i+1))
      else
        TextOut(8, (i*12), IntToStr(i+1));
     end;
   end;//with

  // stanice, udalost, bloky:
  with (F_PotvrSekv.PB_SFP.Canvas) do
   begin
    Font.Color := clWhite;
    TextOut(16, 0, Self.stanice);
    TextOut(16, 12, ' '+Self.udalost);

    Font.Color := $A0A0A0;
    for i := 0 to Self.senders.Count-1 do
     TextOut(16, 24+(i*12), Self.senders[i]);

    // blikani
    if (plus = 6) then
      F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0, 0, 69);
    F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0, plus, 64);
    F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0, 12+plus, 64);
    for i := 0 to Self.senders.Count-1 do
      F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_SFP.Canvas, 0, 24+plus+(i*12), 64);
   end;

  // podminky
  with (F_PotvrSekv.PB_Podm.Canvas) do
   begin
    Font.Color := $A0A0A0;
    for i := 0 to Self.podminky.Count-1 do
     begin
      TextOut(16, (i*12), Self.podminky[i].blok);
      TextOut(300, (i*12), '# '+Self.podminky[i].podminka);
     end;
    Font.Color := clWhite;
    TextOut(12, (Self.podminky.Count*12), ' KONEC SEZNAMU');

    // blikani
    if (plus = 6) then
      F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_Podm.Canvas, 0, 0, 69);
    for i := 0 to Self.podminky.Count do
      F_Main.IL_Ostatni.Draw(F_PotvrSekv.PB_Podm.Canvas, 0, (i*12)+plus, 64);
   end;

  with (F_PotvrSekv) do
   begin
    L_DateTime.Caption := FormatDateTime('dd.mm.yyyy hh:mm:ss', Now);
    L_Timeout.Caption  := FormatDateTime('nn:ss', (now-Self.StartPotvrSekv));
   end;//with
end;//procedure

procedure TF_PotvrSekv.B_OKClick(Sender: TObject);
begin
 PotvrSek.Stop();
end;//procedure

procedure TF_PotvrSekv.B_StornoClick(Sender: TObject);
begin
 PotvrSek.Stop('Stisknuto tlaèítko Nesouhlasím');
end;

procedure TF_PotvrSekv.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (PotvrSek.started) then
  PotvrSek.Stop('Zavøeno okno potvrzovací sekvence');
end;

procedure TF_PotvrSekv.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) then Self.B_StornoClick(Self.B_Storno);
end;

////////////////////////////////////////////////////////////////////////////////

initialization
  PotvrSek := TPotvrSekv.Create();
finalization
  if Assigned(PotvrSek) then
    FreeAndNil(PotvrSek);

end.//unit

