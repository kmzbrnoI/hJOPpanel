object F_SprHelp: TF_SprHelp
  Left = 918
  Top = 247
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'N'#225'poveda k souprav'#225'm'
  ClientHeight = 286
  ClientWidth = 281
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object B_OK: TButton
    Left = 104
    Top = 254
    Width = 75
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Zav'#345#237't'
    TabOrder = 0
    OnClick = B_OKClick
  end
  object LV_SprHelp: TListView
    Left = 0
    Top = 0
    Width = 281
    Height = 250
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alTop
    Columns = <
      item
        Caption = 'P'#345'ed'#269#237'sl'#237
        Width = 60
      end
      item
        Caption = 'Vysv'#283'tlivka'
        Width = 200
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
  end
end
