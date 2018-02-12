unit fOdlozeniOdjezdu;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Mask;

type
  TF_OOdj = class(TForm)
    Label1: TLabel;
    L_Time: TLabel;
    CHB_Absolute: TCheckBox;
    CHB_Relative: TCheckBox;
    ME_Absolute: TMaskEdit;
    Label2: TLabel;
    Label3: TLabel;
    ME_Relative: TMaskEdit;
    B_OK: TButton;
    B_Storno: TButton;
    procedure CHB_AbsoluteClick(Sender: TObject);
    procedure CHB_RelativeClick(Sender: TObject);
    procedure B_StornoClick(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure OpenForm(parsed:TStrings);
  end;

var
  F_OOdj: TF_OOdj;

implementation

uses ModelovyCas, TCPClientPanel;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////

procedure TF_OOdj.B_OKClick(Sender: TObject);
var rel, abs:string;
begin
 if (CHB_Absolute.Checked) then
   abs := Self.ME_Absolute.Text
 else
   abs := '';

 if (CHB_Relative.Checked) then
   rel := Self.ME_Relative.Text
 else
   rel := '';

 PanelTCPClient.SendLn('-;PODJ;' + abs + ';' + rel + ';');

 Self.Close();
end;

procedure TF_OOdj.B_StornoClick(Sender: TObject);
begin
 Self.Close();
end;

procedure TF_OOdj.CHB_AbsoluteClick(Sender: TObject);
begin
 Self.ME_Absolute.Enabled := Self.CHB_Absolute.Checked;
 if (Self.CHB_Absolute.Checked) then
  begin
   if (ModCas.used) then
     Self.ME_Absolute.Text := FormatDateTime('hh:nn', ModCas.time+EncodeTime(0, 1, 0, 0)) + ':00'
   else
     Self.ME_Absolute.Text := FormatDateTime('hh:nn', Now+EncodeTime(0, 1, 0, 0)) + ':00';
  end else
   Self.ME_Absolute.Text := '';
end;

procedure TF_OOdj.CHB_RelativeClick(Sender: TObject);
begin
 Self.ME_Relative.Enabled := Self.CHB_Relative.Checked;
 if (Self.CHB_Relative.Checked) then
   Self.ME_Relative.Text := '00:30'
 else
   Self.ME_Relative.Text := '';
end;

////////////////////////////////////////////////////////////////////////////////

procedure TF_OOdj.OpenForm(parsed:TStrings);
begin
 if (ModCas.used) then
  begin
   Self.L_Time.Caption := 'modelový èas';
  end else begin
   Self.L_Time.Caption := 'skuteèný èas';
  end;

 Self.ActiveControl := Self.CHB_Absolute;
 Self.Show();
end;

////////////////////////////////////////////////////////////////////////////////

end.
