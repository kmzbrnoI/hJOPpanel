object F_RV_Move: TF_RV_Move
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'P'#345'edat vozidlo stanici'
  ClientHeight = 409
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 8
    Width = 97
    Height = 13
    Caption = 'Vozidlo/a k p'#345'esunu:'
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
  object LV_Vehicles: TListView
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
