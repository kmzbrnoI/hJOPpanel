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
    ME_absolute: TMaskEdit;
    Label2: TLabel;
    Label3: TLabel;
    ME_Relative: TMaskEdit;
    B_OK: TButton;
    B_Storno: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  F_OOdj: TF_OOdj;

implementation

{$R *.dfm}

end.
