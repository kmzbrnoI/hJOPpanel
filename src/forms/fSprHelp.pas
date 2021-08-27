unit fSprHelp;

{
  Train help window.
}

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  ComCtrls, IniFiles;

type
  TF_SprHelp = class(TForm)
    B_OK: TButton;
    LV_SprHelp: TListView;
    procedure B_OKClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure LoadData(ini: TMemIniFile);
  end;

var
  F_SprHelp: TF_SprHelp;

implementation

{$R *.dfm}

procedure TF_SprHelp.B_OKClick(Sender: TObject);
begin
  Self.Close();
end;

procedure TF_SprHelp.LoadData(ini: TMemIniFile);
const _SECTION: string = 'train-types';
var strs: TStrings;
begin
  strs := TStringList.Create();
  try
    ini.ReadSection(_SECTION, strs);
    Self.LV_SprHelp.Clear();
    for var str in strs do
    begin
      var LI := Self.LV_SprHelp.Items.Add;
      LI.Caption := str;
      LI.SubItems.Add(ini.ReadString(_SECTION, str, ''));
    end;
  finally
    strs.Free();
  end;
end;

end.// unit
