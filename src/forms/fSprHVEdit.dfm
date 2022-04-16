object F_SprHVEdit: TF_SprHVEdit
  Left = 0
  Top = 0
  BorderStyle = bsNone
  ClientHeight = 287
  ClientWidth = 386
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object L_S09: TLabel
    Left = 7
    Top = 105
    Width = 145
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Pozn'#225'mka k hnac'#237'mu vozidlu :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object CB_HV1_HV: TComboBox
    Left = 7
    Top = 13
    Width = 194
    Height = 21
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnChange = CB_HV1_HVChange
  end
  object RG_HV1_dir: TRadioGroup
    Left = 7
    Top = 38
    Width = 194
    Height = 57
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = ' Stanovi'#353'te A ve sm'#283'ru '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Items.Strings = (
      'L'
      'S')
    ParentFont = False
    TabOrder = 1
  end
  object M_HV1_Notes: TMemo
    Left = 7
    Top = 122
    Width = 194
    Height = 156
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    MaxLength = 1000
    ScrollBars = ssVertical
    TabOrder = 2
    OnKeyPress = M_HV1_NotesKeyPress
  end
  object PC_Funkce: TPageControl
    Left = 206
    Top = 8
    Width = 172
    Height = 270
    ActivePage = TS_F0_F14
    TabOrder = 3
    object TS_F0_F14: TTabSheet
      Caption = 'F0-F14'
    end
    object TS_F15_F28: TTabSheet
      Caption = 'F15-F28'
      ImageIndex = 1
    end
  end
end
