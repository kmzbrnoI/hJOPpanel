unit fSplash;

{
  Splash window shown when starting the application.
}

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms, SysUtils,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls;

type
  TF_splash = class(TForm)
    ST_name: TStaticText;
    ST_Version: TStaticText;
    L_Created: TLabel;
    L_BuildTime: TLabel;
    I_Horasystems: TImage;
    PB_Progress: TProgressBar;
    L_1: TLabel;
    L_Load: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ShowState(Text: String);
  end;

var
  F_splash: TF_splash;

implementation

{$R *.dfm}

uses Verze;

procedure TF_splash.FormCreate(Sender: TObject);
begin
  Self.Show();
  Application.ProcessMessages();
end;

procedure TF_splash.FormShow(Sender: TObject);
begin
  Self.ST_Version.Caption := 'Verze ' + VersionStr(Application.ExeName);
  Self.L_BuildTime.Caption := FormatDateTime('dd.mm.yyyy hh:nn:ss', BuildDateTime());
end;

procedure TF_splash.ShowState(Text: String);
begin
  Self.L_Load.Caption := Text;
  Self.PB_Progress.Position := F_splash.PB_Progress.Position + 1;
  Self.Refresh();
end;

end.// unit
