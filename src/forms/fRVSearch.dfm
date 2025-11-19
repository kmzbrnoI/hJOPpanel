object F_RVSearch: TF_RVSearch
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Vyhledat vozidlo v datab'#225'zi serveru'
  ClientHeight = 105
  ClientWidth = 249
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 13
  object Label6: TLabel
    Left = 15
    Top = 28
    Width = 38
    Height = 13
    Caption = 'Adresa:'
  end
  object E_Adresa: TEdit
    Left = 112
    Top = 25
    Width = 121
    Height = 21
    MaxLength = 4
    NumbersOnly = True
    TabOrder = 0
    Text = 'E_Adresa'
  end
  object B_OK: TButton
    Left = 158
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Vyhledat'
    Default = True
    TabOrder = 1
    OnClick = B_OKClick
  end
end
