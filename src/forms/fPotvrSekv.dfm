object F_PotvrSekv: TF_PotvrSekv
  Left = 194
  Top = 202
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Potvrzovac'#237' sekvence'
  ClientHeight = 401
  ClientWidth = 685
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnPaint = FormPaint
  TextHeight = 13
  object B_Storno: TButton
    Left = 597
    Top = 366
    Width = 73
    Height = 28
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Nesouhlas'#237'm'
    TabOrder = 1
    OnClick = B_StornoClick
    OnKeyPress = FormKeyPress
  end
  object B_OK: TButton
    Left = 518
    Top = 366
    Width = 74
    Height = 28
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Souhlas'#237'm'
    TabOrder = 0
    OnClick = B_OKClick
    OnKeyPress = FormKeyPress
  end
  object P_bg: TPanel
    Left = 0
    Top = 0
    Width = 685
    Height = 361
    Align = alTop
    BevelOuter = bvNone
    Color = clSilver
    ParentBackground = False
    TabOrder = 2
    ExplicitWidth = 677
    object L_ListDescription: TLabel
      Left = 40
      Top = 127
      Width = 168
      Height = 15
      Caption = 'KONTROLOVAN'#201' PODM'#205'NKY'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object L_Description: TLabel
      Left = 40
      Top = 0
      Width = 248
      Height = 15
      Caption = '!!! PROB'#205'H'#193' RIZIKOV'#193' FUNKCE !!!'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object Label3: TLabel
      Left = 42
      Top = 345
      Width = 24
      Height = 15
      Caption = 'SZZ'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object Label4: TLabel
      Left = 186
      Top = 345
      Width = 8
      Height = 15
      Caption = 't'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object L_Timeout: TLabel
      Left = 200
      Top = 345
      Width = 32
      Height = 15
      Caption = '0000'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object L_DateTime: TLabel
      Left = 552
      Top = 345
      Width = 128
      Height = 15
      Alignment = taRightJustify
      Caption = '01.01.2014 12:00'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object PB_SFP_indexes: TPaintBox
      Left = 0
      Top = 16
      Width = 17
      Height = 105
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object PB_podm_Indexes: TPaintBox
      Left = 0
      Top = 144
      Width = 17
      Height = 201
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object Label5: TLabel
      Left = 320
      Top = 127
      Width = 90
      Height = 15
      Caption = #9650'PgUp '#9660'PgDn'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
    end
    object P_Header: TPanel
      Left = 16
      Top = 16
      Width = 669
      Height = 105
      BevelOuter = bvNone
      Color = clBlack
      ParentBackground = False
      TabOrder = 0
      object PB_SFP: TPaintBox
        Left = 0
        Top = 0
        Width = 669
        Height = 105
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Fixedsys'
        Font.Style = []
        ParentFont = False
        ExplicitLeft = 160
        ExplicitTop = 16
        ExplicitWidth = 105
      end
    end
    object P_Podminky: TPanel
      Left = 16
      Top = 144
      Width = 669
      Height = 201
      BevelOuter = bvNone
      Color = clBlack
      ParentBackground = False
      TabOrder = 1
      object PB_Podm: TPaintBox
        Left = 0
        Top = 0
        Width = 669
        Height = 201
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Fixedsys'
        Font.Style = []
        ParentFont = False
        ExplicitHeight = 166
      end
    end
  end
  object T_Main: TTimer
    Enabled = False
    Interval = 500
    OnTimer = TimerUpdate
    Left = 16
    Top = 352
  end
end
