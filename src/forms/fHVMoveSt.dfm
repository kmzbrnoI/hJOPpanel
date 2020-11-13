object F_HV_Move: TF_HV_Move
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'P'#345'edat lokomotivu stanici'
  ClientHeight = 409
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 8
    Width = 126
    Height = 13
    Caption = 'Hnac'#237' vozidlo/a k p'#345'esunu:'
  end
  object Label2: TLabel
    Left = 16
    Top = 309
    Width = 70
    Height = 13
    Caption = 'C'#237'lov'#225' stanice:'
  end
  object CB_Stanice: TComboBox
    Left = 16
    Top = 328
    Width = 273
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
  end
  object B_Storno: TButton
    Left = 133
    Top = 370
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 3
    OnClick = B_StornoClick
  end
  object B_OK: TButton
    Left = 214
    Top = 370
    Width = 75
    Height = 25
    Caption = 'P'#345'edat'
    Default = True
    TabOrder = 2
    OnClick = B_OKClick
  end
  object LV_HVs: TListView
    Left = 16
    Top = 27
    Width = 273
    Height = 276
    Color = clWhite
    Columns = <
      item
        Caption = 'Adresa'
      end
      item
        Caption = 'N'#225'zev'
        Width = 100
      end
      item
        Caption = 'Ozna'#269'en'#237
        Width = 80
      end>
    GridLines = True
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
end
