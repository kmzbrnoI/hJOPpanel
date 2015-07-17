unit fStitVyl;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Panel, fPotvrSekv;

//toto okno je primo podrizeno panelu, resp. TRelief
//nikdo jiny nema opravneni s timto oknem komunikovat

const
  _STITEK = 0;
  _VYLUKA = 1;

type
  TStitVylCallback = procedure(typ:Integer; stitvyl:string) of object;

  TF_StitVyl = class(TForm)
    E_Popisek: TEdit;
    L_What: TLabel;
    B_OK: TButton;
    procedure B_OKClick(Sender: TObject);
    procedure E_PopisekKeyPress(Sender: TObject; var Key: Char);
    procedure E_PopisekChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
   callback:TStitVylCallback;
   OpenStitVyl:Integer;    //typ otevreni (0=stit,1=vyl)
   OpenBlk:string;
  public
   procedure OpenFormStit(callback:TStitVylCallback; blk,stit:string);
   procedure OpenFormVyl(callback:TStitVylCallback; blk,vyl:string);
   procedure PotvrSekvCallBack(reason:TPSEnd);
  end;

var
  F_StitVyl: TF_StitVyl;

implementation

uses RPConst, fMain;

{$R *.dfm}

procedure TF_StitVyl.OpenFormStit(callback:TStitVylCallback; blk,stit:string);
begin
 Self.callback    := callback;
 Self.OpenStitVyl := _STITEK;
 Self.OpenBlk     := blk;

 Self.Caption := 'Štítek na bloku '+blk;
 Self.L_What.Caption := 'Štítek :';
 Self.Color := clTeal;
 Self.E_Popisek.Text := stit;

 Self.Show();
end;//procedure

procedure TF_StitVyl.OpenFormVyl(callback:TStitVylCallback; blk,vyl:string);
begin
 Self.callback    := callback;
 Self.OpenStitVyl := _VYLUKA;
 Self.OpenBlk     := blk;

 Self.Caption := 'Výluka na bloku '+blk;
 Self.L_What.Caption := 'Výluka :';
 Self.Color := clOlive;
 Self.E_Popisek.Text := vyl;

 Self.Show();
end;//procedure

procedure TF_StitVyl.B_OKClick(Sender: TObject);
var i, j:Integer;
 begin
 // kontrola teztu na zakazane znaky
 for i := 1 to Length(Self.E_Popisek.Text) do
   for j := 0 to Length(_forbidden_chars)-1 do
     if (_forbidden_chars[j] = Self.E_Popisek.Text[i]) then
       begin
        Application.MessageBox(PChar('Poznámka k hnacímu vozidlu obsahuje zakázané znaky!'+#13#10+'Zakázané znaky: '+GetForbidderChars()), 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
       end;

  Self.Close;
  Self.callback(Self.OpenStitVyl, Self.E_Popisek.Text);
 end;//procedure

procedure TF_StitVyl.E_PopisekKeyPress(Sender: TObject; var Key: Char);
var i:Integer;
 begin
  if (Key = #13) then B_OKClick(Self);
  if (Key = #27) then
   begin
    Self.Close;
    Relief.Escape();
   end;

 // osetreni vstupu
 for i := 0 to Length(_forbidden_chars)-1 do
   if (_forbidden_chars[i] = Key) then
     begin
      Key := #0;
      Exit();
     end;
 end;//procedure

procedure TF_StitVyl.E_PopisekChange(Sender: TObject);
 begin
  if (Self.E_Popisek.Text = '') then
   begin
    Self.E_Popisek.Color := clSilver;
   end else begin
    Self.E_Popisek.Color := clWhite;
   end;//else E_popisek.Text = ''
 end;//procedure

procedure TF_StitVyl.FormShow(Sender: TObject);
begin
  if (Self.E_Popisek.Text = '') then
   begin
    Self.E_Popisek.Color := clSilver;
   end else begin
    Self.E_Popisek.Color := clWhite;
   end;//else E_popisek.Text = ''
end;//procedure

procedure TF_StitVyl.PotvrSekvCallback(reason:TPSEnd);
begin
 if (PotvrSek.EndReason = TPSEnd.success) or (E_Popisek.Text <> '') then
   Self.callback(1, Self.E_Popisek.Text);
end;//procedure

end.//unit

