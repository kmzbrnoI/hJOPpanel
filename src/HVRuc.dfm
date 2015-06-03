object F_HV_Ruc: TF_HV_Ruc
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Lokomotivu do ru'#269'n'#237'ho '#345#237'zen'#237
  ClientHeight = 107
  ClientWidth = 259
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 8
    Width = 66
    Height = 13
    Caption = 'Hnac'#237' vozidlo:'
  end
  object CB_HV: TComboBox
    Left = 16
    Top = 27
    Width = 225
    Height = 21
    Style = csDropDownList
    ItemHeight = 0
    TabOrder = 0
  end
  object B_Storno: TButton
    Left = 85
    Top = 66
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 2
    OnClick = B_StornoClick
  end
  object B_OK: TButton
    Left = 166
    Top = 66
    Width = 75
    Height = 25
    Caption = 'P'#345'evz'#237't'
    Default = True
    TabOrder = 1
    OnClick = B_OKClick
  end
end
