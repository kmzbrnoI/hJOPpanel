unit fSprHelp;

{
  Okno napovedy k souprave.
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TF_SprHelp = class(TForm)
    B_OK: TButton;
    LV_SprHelp: TListView;
    procedure B_OKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  F_SprHelp: TF_SprHelp;

implementation

{$R *.dfm}

procedure TF_SprHelp.B_OKClick(Sender: TObject);
 begin
  F_SprHelp.Close;
 end;//procedure

procedure TF_SprHelp.FormCreate(Sender: TObject);
var LI:TListItem;
 begin
  LI := LV_SprHelp.Items.Add;
  LI.Caption := '10xxxx';
  LI.SubItems.Add('ExpresnÌ vlak');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '20xxxx';
  LI.SubItems.Add('');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '30xxxx';
  LI.SubItems.Add('RychlÌk');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '40xxxx';
  LI.SubItems.Add('OsobnÌ vlak hlavnÌ traù');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '50xxxx';
  LI.SubItems.Add('OsobnÌ vlak vedlejöÌ traù');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '60xxxx';
  LI.SubItems.Add('Pr˘bÏûn˝ n·kladnÌ vlak');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '70xxxx';
  LI.SubItems.Add('LokomotivnÌ vlak');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '80xxxx';
  LI.SubItems.Add('ManipulaËnÌ vlak');

  LI := LV_SprHelp.Items.Add;
  LI.Caption := '90xxxx';
  LI.SubItems.Add('Zvl·ötnÌ vlak');
 end;//procedure

end.//unit
