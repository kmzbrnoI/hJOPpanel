object F_HV_Move: TF_HV_Move
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'P'#345'edat lokomotivu stanici'
  ClientHeight = 155
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
  object Label2: TLabel
    Left = 16
    Top = 61
    Width = 39
    Height = 13
    Caption = 'Stanice:'
  end
  object CB_HV: TComboBox
    Left = 16
    Top = 27
    Width = 225
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
  end
  object CB_Stanice: TComboBox
    Left = 16
    Top = 80
    Width = 225
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
  end
  object B_Storno: TButton
    Left = 85
    Top = 122
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 3
    OnClick = B_StornoClick
  end
  object B_OK: TButton
    Left = 166
    Top = 122
    Width = 75
    Height = 25
    Caption = 'P'#345'edat'
    Default = True
    TabOrder = 2
    OnClick = B_OKClick
  end
end
