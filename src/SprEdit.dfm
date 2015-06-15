object F_SoupravaEdit: TF_SoupravaEdit
  Left = 770
  Top = 195
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Souprava [...]'
  ClientHeight = 410
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
    Caption = #268#237'slo soupravy (0.999999) :'
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
    Top = 312
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
    Width = 83
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'D'#233'lka vlaku (cm):'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label3: TLabel
    Left = 224
    Top = 7
    Width = 50
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Typ vlaku:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label4: TLabel
    Left = 239
    Top = 311
    Width = 162
    Height = 13
    Alignment = taRightJustify
    Caption = 'Zak'#225'zan'#233' znaky: enter / \ | [ ] ; { }'
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
    TabOrder = 0
    OnKeyPress = E_SprDelkaKeyPress
  end
  object B_Save: TButton
    Left = 6
    Top = 374
    Width = 89
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Pou'#382#237't'
    Default = True
    TabOrder = 8
    OnClick = B_SaveClick
  end
  object B_Storno: TButton
    Left = 113
    Top = 374
    Width = 89
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Storno'
    TabOrder = 9
    OnClick = B_StornoClick
  end
  object B_Help: TButton
    Left = 327
    Top = 21
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
    Top = 47
    Width = 177
    Height = 47
    Caption = ' Ozna'#269'en'#237' sm'#283'ru'
    TabOrder = 5
    object CHB_Sipka_L: TCheckBox
      Left = 44
      Top = 18
      Width = 25
      Height = 17
      Caption = 'L'
      TabOrder = 0
    end
    object CHB_Sipka_S: TCheckBox
      Left = 107
      Top = 18
      Width = 33
      Height = 17
      Caption = 'S'
      TabOrder = 1
    end
  end
  object PC_HVs: TPageControl
    Left = 8
    Top = 100
    Width = 393
    Height = 205
    MultiLine = True
    TabOrder = 6
    OnDrawTab = PageControlCloseButtonDrawTab
    OnMouseDown = PageControlCloseButtonMouseDown
    OnMouseLeave = PageControlCloseButtonMouseLeave
    OnMouseMove = PageControlCloseButtonMouseMove
    OnMouseUp = PageControlCloseButtonMouseUp
  end
  object BB_HV_Add: TBitBtn
    Left = 378
    Top = 99
    Width = 21
    Height = 21
    DoubleBuffered = True
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
    ParentDoubleBuffered = False
    TabOrder = 10
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
    Top = 21
    Width = 87
    Height = 21
    ItemHeight = 13
    TabOrder = 1
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
    Top = 330
    Width = 393
    Height = 39
    MaxLength = 1000
    ScrollBars = ssVertical
    TabOrder = 7
    OnKeyPress = E_PoznamkaKeyPress
  end
  object T_Timeout: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = T_TimeoutTimer
    Left = 368
    Top = 8
  end
end
