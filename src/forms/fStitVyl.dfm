object F_StitVyl: TF_StitVyl
  Left = 633
  Top = 177
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = '[typ] bloku [blok]'
  ClientHeight = 57
  ClientWidth = 513
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object L_What: TLabel
    Left = 8
    Top = 8
    Width = 20
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = '[typ]'
  end
  object E_Popisek: TEdit
    Left = 8
    Top = 24
    Width = 417
    Height = 23
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Fixedsys'
    Font.Style = []
    MaxLength = 50
    ParentFont = False
    TabOrder = 0
    OnChange = E_PopisekChange
    OnKeyPress = E_PopisekKeyPress
  end
  object B_OK: TButton
    Left = 432
    Top = 24
    Width = 75
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Pou'#382#237't'
    TabOrder = 1
    OnClick = B_OKClick
  end
end
