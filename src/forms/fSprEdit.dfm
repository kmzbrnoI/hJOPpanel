object F_SoupravaEdit: TF_SoupravaEdit
  Left = 770
  Top = 195
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Souprava [...]'
  ClientHeight = 593
  ClientWidth = 409
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object L_S01: TLabel
    Left = 7
    Top = 5
    Width = 129
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = #268#237'slo soupravy (0..999999):'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object L_S02: TLabel
    Left = 7
    Top = 55
    Width = 57
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Po'#269'et voz'#367':'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label1: TLabel
    Left = 7
    Top = 501
    Width = 109
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Pozn'#225'mka k souprav'#283':'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 113
    Top = 55
    Width = 54
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'D'#233'lka (cm):'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label3: TLabel
    Left = 224
    Top = 5
    Width = 67
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Typ soupravy:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label4: TLabel
    Left = 278
    Top = 501
    Width = 123
    Height = 13
    Alignment = taRightJustify
    Caption = 'Zak'#225'zan'#233' znaky: enter { }'
  end
  object Label5: TLabel
    Left = 8
    Top = 103
    Width = 78
    Height = 13
    Caption = 'V'#253'choz'#237' stanice:'
  end
  object Label6: TLabel
    Left = 224
    Top = 103
    Width = 70
    Height = 13
    Caption = 'C'#237'lov'#225' stanice:'
  end
  object SB_st_change: TSpeedButton
    Left = 192
    Top = 120
    Width = 23
    Height = 22
    Glyph.Data = {
      36030000424D3603000000000000360000002800000010000000100000000100
      18000000000000030000130B0000130B00000000000000000000FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFF000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000
      00000000FFFFFFFEFEFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000
      0000000000000000000000000000000000000000000000F7F7F7FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000000000
      00000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000
      0000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000
      00000000F8F8F8FEFEFEFFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFF000000000000FEFEFEFFFFFFFFFFFFFFFFFFFFFFFF
      FEFEFE000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000FFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000
      000000000000000000000000000000000000000000000000000000FFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000000000000000
      0000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000
      000000000000000000000000000000000000000000000000000000FFFFFFFFFF
      FFFEFEFEFEFEFEFEFEFEFFFFFFFFFFFF000000000000000000FFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFEFEFEFEFEFEFEFEFEFEFEFFFFFFFFFFFF
      FFFFFF000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
    OnClick = SB_st_changeClick
  end
  object E_Nazev: TEdit
    Left = 7
    Top = 22
    Width = 189
    Height = 21
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    MaxLength = 6
    NumbersOnly = True
    TabOrder = 0
  end
  object B_Save: TButton
    Left = 313
    Top = 563
    Width = 89
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Pou'#382#237't'
    Default = True
    TabOrder = 13
    OnClick = B_SaveClick
  end
  object B_Storno: TButton
    Left = 216
    Top = 563
    Width = 89
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Storno'
    TabOrder = 14
    OnClick = B_StornoClick
  end
  object B_Help: TButton
    Left = 326
    Top = 22
    Width = 75
    Height = 21
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'N'#225'pov'#283'da'
    TabOrder = 2
    OnClick = B_HelpClick
  end
  object SE_PocetVozu: TSpinEdit
    Left = 8
    Top = 72
    Width = 89
    Height = 22
    MaxValue = 1000
    MinValue = 0
    TabOrder = 3
    Value = 0
  end
  object GB_Sipky: TGroupBox
    Left = 224
    Top = 49
    Width = 177
    Height = 47
    Caption = ' Ozna'#269'en'#237' sm'#283'ru '
    TabOrder = 5
    object CHB_Sipka_L: TCheckBox
      Left = 52
      Top = 18
      Width = 25
      Height = 17
      Caption = 'L'
      TabOrder = 0
    end
    object CHB_Sipka_S: TCheckBox
      Left = 99
      Top = 18
      Width = 33
      Height = 17
      Caption = 'S'
      TabOrder = 1
    end
  end
  object PC_HVs: TPageControl
    Left = 8
    Top = 149
    Width = 393
    Height = 315
    MultiLine = True
    TabOrder = 8
    OnDrawTab = PageControlCloseButtonDrawTab
    OnMouseDown = PageControlCloseButtonMouseDown
    OnMouseLeave = PageControlCloseButtonMouseLeave
    OnMouseMove = PageControlCloseButtonMouseMove
    OnMouseUp = PageControlCloseButtonMouseUp
  end
  object BB_HV_Add: TBitBtn
    Left = 378
    Top = 148
    Width = 21
    Height = 21
    Glyph.Data = {
      36030000424D3603000000000000360000002800000010000000100000000100
      1800000000000003000000000000000000000000000000000000FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFBEBEBEBBBBBBBBBBBBECECECFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000
      0000000000AAAAAAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000AAAAAAFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000
      0000000000AAAAAAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000AAAAAAFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000
      0000000000AAAAAAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBEBEBEBBBBBB
      BBBBBBBBBBBBBBBBBBBBBBBB0000000000000000007D7D7DBBBBBBBBBBBBBBBB
      BBBBBBBBBBBBBBECECEC00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000AAAAAA000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000AAAAAA09090900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000B3B3B3FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000AAAAAAFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000
      0000000000AAAAAAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000AAAAAAFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000
      0000000000AAAAAAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000AAAAAAFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF09090900
      0000000000B3B3B3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
    TabOrder = 15
    OnClick = BB_HV_AddClick
  end
  object SE_Delka: TSpinEdit
    Left = 113
    Top = 72
    Width = 83
    Height = 22
    MaxValue = 1000
    MinValue = 0
    TabOrder = 4
    Value = 0
  end
  object CB_Typ: TComboBox
    Left = 224
    Top = 22
    Width = 96
    Height = 21
    TabOrder = 1
    OnChange = CB_TypChange
    Items.Strings = (
      ''
      'Sc'
      'Ec'
      'Ic'
      'Ex'
      'R'
      'Sp'
      'Os'
      'MOs'
      'NEx'
      'Rn'
      'Sn'
      'Pn'
      'Vn'
      'Mn'
      'Pv'
      'Vle'#269
      'Slu'#382
      'Lv')
  end
  object M_Poznamka: TMemo
    Left = 8
    Top = 519
    Width = 393
    Height = 39
    MaxLength = 1000
    ScrollBars = ssVertical
    TabOrder = 11
    OnKeyPress = E_PoznamkaKeyPress
  end
  object CB_Vychozi: TComboBox
    Left = 8
    Top = 120
    Width = 175
    Height = 21
    Style = csDropDownList
    TabOrder = 6
  end
  object CB_Cilova: TComboBox
    Left = 224
    Top = 120
    Width = 177
    Height = 21
    Style = csDropDownList
    TabOrder = 7
  end
  object CHB_report: TCheckBox
    Left = 8
    Top = 565
    Width = 108
    Height = 17
    Caption = 'Stani'#269'n'#237' hl'#225#353'en'#237
    TabOrder = 12
  end
  object CHB_MaxSpeed: TCheckBox
    Left = 8
    Top = 470
    Width = 241
    Height = 17
    Caption = 'Omezit maxim'#225'ln'#237' rychlost soupravy na [km/h]:'
    TabOrder = 9
    OnClick = CHB_MaxSpeedClick
  end
  object SE_MaxSpeed: TSpinEdit
    Left = 288
    Top = 470
    Width = 113
    Height = 22
    MaxValue = 200
    MinValue = 0
    TabOrder = 10
    Value = 0
  end
  object T_Timeout: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = T_TimeoutTimer
    Left = 368
    Top = 8
  end
end
