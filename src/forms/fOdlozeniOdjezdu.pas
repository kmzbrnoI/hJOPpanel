unit fOdlozeniOdjezdu;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
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
    procedure OpenForm(parsed: TStrings);
  end;

var
  F_OOdj: TF_OOdj;

implementation

uses ModelovyCas, TCPClientPanel, GlobalConfig;

{$R *.dfm}

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_OOdj.B_OKClick(Sender: TObject);
begin
  try
    if (Self.CHB_Absolute.Checked) then
    begin
      if ((StrToInt(Copy(Self.ME_Absolute.Text, 1, 2)) < 0) or (StrToInt(Copy(Self.ME_Absolute.Text, 1, 2)) >= 24)) then
      begin
        Application.MessageBox('Špatně zadané hodiny!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
      end;

      if ((StrToInt(Copy(Self.ME_Absolute.Text, 4, 2)) < 0) or (StrToInt(Copy(Self.ME_Absolute.Text, 4, 2)) >= 60)) then
      begin
        Application.MessageBox('Špatně zadané minuty!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
      end;

      if ((StrToInt(Copy(Self.ME_Absolute.Text, 7, 2)) < 0) or (StrToInt(Copy(Self.ME_Absolute.Text, 7, 2)) >= 60)) then
      begin
        Application.MessageBox('Špatně zadané sekundy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
      end;
    end;

    if (Self.CHB_Relative.Checked) then
    begin
      if ((StrToInt(Copy(Self.ME_Relative.Text, 1, 2)) < 0) or (StrToInt(Copy(Self.ME_Relative.Text, 1, 2)) >= 60)) then
      begin
        Application.MessageBox('Špatně zadané minuty!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
      end;

      if ((StrToInt(Copy(Self.ME_Relative.Text, 4, 2)) < 0) or (StrToInt(Copy(Self.ME_Relative.Text, 4, 2)) >= 60)) then
      begin
        Application.MessageBox('Špatně zadané sekundy!', 'Nelze uložit data', MB_OK OR MB_ICONWARNING);
        Exit();
      end;
    end;
  except
    on E: Exception do
    begin
      Application.MessageBox(PChar('Neplatný formát dat!' + #13#10 + E.Message), 'Nelze uložit data',
        MB_OK OR MB_ICONWARNING);
      Exit();
    end;
  end;

  var abs: string := '';
  if (CHB_Absolute.Checked) then
    abs := Self.ME_Absolute.Text;

  var rel: string := '';
  if (CHB_Relative.Checked) then
    rel := Self.ME_Relative.Text;

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
    if (ModelTime.used) then
      Self.ME_Absolute.Text := FormatDateTime('hh:nn', ModelTime.time + GlobConfig.data.podj.modelAbsolute) + ':00'
    else
      Self.ME_Absolute.Text := FormatDateTime('hh:nn', Now + GlobConfig.data.podj.realAbsolute) + ':00';
  end
  else
    Self.ME_Absolute.Text := '';
end;

procedure TF_OOdj.CHB_RelativeClick(Sender: TObject);
begin
  Self.ME_Relative.Enabled := Self.CHB_Relative.Checked;
  if (Self.CHB_Relative.Checked) then
  begin
    if (ModelTime.used) then
      Self.ME_Relative.Text := FormatDateTime('nn:ss', GlobConfig.data.podj.modelRelative)
    else
      Self.ME_Relative.Text := FormatDateTime('nn:ss', GlobConfig.data.podj.realRelative);
  end
  else
    Self.ME_Relative.Text := '';
end;

/// /////////////////////////////////////////////////////////////////////////////

procedure TF_OOdj.OpenForm(parsed: TStrings);
begin
  if (ModelTime.used) then
    Self.L_Time.Caption := 'modelovém času'
  else
    Self.L_Time.Caption := 'skutečném času';

  Self.CHB_Absolute.Checked := parsed[2] <> '';
  Self.ME_Absolute.Enabled := Self.CHB_Absolute.Checked;
  if (Self.CHB_Absolute.Checked) then
    Self.ME_Absolute.Text := parsed[2]
  else
    Self.ME_Absolute.Text := '__:__:__';

  Self.CHB_Relative.Checked := parsed[3] <> '';
  Self.ME_Relative.Enabled := Self.CHB_Relative.Checked;
  if (Self.CHB_Relative.Checked) then
    Self.ME_Relative.Text := parsed[3]
  else
    Self.ME_Relative.Text := '__:__';

  Self.ActiveControl := Self.CHB_Absolute;
  Self.Show();
end;

/// /////////////////////////////////////////////////////////////////////////////

end.
