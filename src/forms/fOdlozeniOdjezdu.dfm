object F_OOdj: TF_OOdj
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Upravit odlo'#382'en'#237' odjezdu vlaku'
  ClientHeight = 209
  ClientWidth = 297
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 273
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'N'#225'sleduj'#237'c'#237' '#269'asy se ud'#225'vaj'#237' v:'
  end
  object L_Time: TLabel
    Left = 8
    Top = 27
    Width = 273
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = 'modelov'#233'm '#269'asu'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 24
    Top = 75
    Width = 102
    Height = 13
    Caption = '[hodin:minut:sekund]'
  end
  object Label3: TLabel
    Left = 24
    Top = 131
    Width = 72
    Height = 13
    Caption = '[minut:sekund]'
  end
  object CHB_Absolute: TCheckBox
    Left = 8
    Top = 56
    Width = 117
    Height = 17
    Caption = 'Odjet (nejd'#345#237've) v:'
    TabOrder = 0
    OnClick = CHB_AbsoluteClick
  end
  object CHB_Relative: TCheckBox
    Left = 8
    Top = 112
    Width = 97
    Height = 17
    Caption = 'Vy'#269'kat nejm'#233'n'#283':'
    TabOrder = 2
    OnClick = CHB_RelativeClick
  end
  object ME_Absolute: TMaskEdit
    Left = 154
    Top = 56
    Width = 136
    Height = 45
    Hint = 'Zadejte aktu'#225'ln'#237' modelov'#253' cas'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Alignment = taCenter
    EditMask = '00:00:00;1;_'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    MaxLength = 8
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    Text = '  :  :  '
  end
  object ME_Relative: TMaskEdit
    Left = 197
    Top = 110
    Width = 93
    Height = 45
    Hint = 'Zadejte aktu'#225'ln'#237' modelov'#253' cas'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Alignment = taCenter
    EditMask = '00:00;1;_'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    MaxLength = 5
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    Text = '  :  '
  end
  object B_OK: TButton
    Left = 214
    Top = 176
    Width = 75
    Height = 25
    Caption = 'Pou'#382#237't'
    Default = True
    TabOrder = 4
    OnClick = B_OKClick
  end
  object B_Storno: TButton
    Left = 133
    Top = 176
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 5
    OnClick = B_StornoClick
  end
end
