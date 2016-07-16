object F_Auth: TF_Auth
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Server vy'#382'aduje autentizaci'
  ClientHeight = 401
  ClientWidth = 305
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object P_Message: TPanel
    Left = 24
    Top = 16
    Width = 257
    Height = 88
    BevelKind = bkFlat
    BevelOuter = bvNone
    Caption = 'P'#345'ihla'#353'uji ...'
    Color = 14606066
    DoubleBuffered = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentDoubleBuffered = False
    ParentFont = False
    TabOrder = 1
    Visible = False
    object ST_Error: TStaticText
      Left = 12
      Top = 8
      Width = 229
      Height = 65
      Alignment = taCenter
      AutoSize = False
      Caption = 'ST_Error'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object P_Body: TPanel
    Left = 8
    Top = 8
    Width = 289
    Height = 385
    BevelOuter = bvNone
    Caption = 'P_Body'
    ParentColor = True
    ParentShowHint = False
    ShowCaption = False
    ShowHint = False
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 110
      Width = 142
      Height = 13
      Caption = 'Nastavit zapamatov'#225'n'#237' hesla:'
    end
    object Label15: TLabel
      Left = 16
      Top = 56
      Width = 30
      Height = 13
      Caption = 'Heslo:'
    end
    object Label14: TLabel
      Left = 16
      Top = 8
      Width = 90
      Height = 13
      Caption = 'U'#382'ivatelsk'#233' jm'#233'no:'
    end
    object B_Apply: TButton
      Left = 216
      Top = 354
      Width = 57
      Height = 25
      Caption = 'OK'
      Default = True
      TabOrder = 3
      OnClick = B_ApplyClick
      OnKeyPress = FormKeyPress
    end
    object B_Cancel: TButton
      Left = 154
      Top = 354
      Width = 56
      Height = 25
      Caption = 'Zru'#353'it'
      TabOrder = 4
      OnClick = B_CancelClick
      OnKeyPress = FormKeyPress
    end
    object TB_Remeber: TTrackBar
      Left = 16
      Top = 129
      Width = 41
      Height = 192
      Max = 2
      Orientation = trVertical
      Position = 1
      ShowSelRange = False
      TabOrder = 2
      TickMarks = tmBoth
      OnChange = TB_RemeberChange
    end
    object GB_RemberDesc: TGroupBox
      Left = 69
      Top = 129
      Width = 204
      Height = 192
      TabOrder = 5
      object ST_Rem2: TStaticText
        Left = 8
        Top = 26
        Width = 184
        Height = 42
        AutoSize = False
        Caption = 
          'Heslo bude ulo'#382'eno pouze pro toto spojen'#237', po odpojen'#237' od server' +
          'u bude heslo smaz'#225'no.'
        TabOrder = 0
      end
      object ST_Rem4: TStaticText
        Left = 8
        Top = 129
        Width = 184
        Height = 59
        AutoSize = False
        Caption = 
          'Heslo je ulo'#382'eno pouze v pam'#283'ti programu, '#382#225'dn'#253' jin'#253' program k n' +
          #283'mu nem'#225' p'#345#237'stup, ve form'#283' hashe SHA 256.'
        TabOrder = 1
      end
      object ST_Rem1: TStaticText
        Left = 10
        Top = 8
        Width = 183
        Height = 17
        AutoSize = False
        Caption = 'V'#253'choz'#237
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
      object ST_Rem3: TStaticText
        Left = 8
        Top = 72
        Width = 185
        Height = 57
        AutoSize = False
        Caption = 
          'P'#345'i zm'#283'n'#283' opr'#225'vn'#283'n'#237' oblasti '#345#237'zen'#237', otev'#345'en'#237' regul'#225'toru apod. bu' +
          'de pou'#382'ito toto heslo, nemus'#237'te jej tedy znovu zad'#225'vat.'
        TabOrder = 3
      end
    end
    object E_Password: TEdit
      Left = 16
      Top = 75
      Width = 257
      Height = 21
      MaxLength = 64
      PasswordChar = '*'
      TabOrder = 1
      Text = 'Edit1'
      OnKeyPress = FormKeyPress
    end
    object E_username: TEdit
      Left = 16
      Top = 27
      Width = 257
      Height = 21
      MaxLength = 64
      TabOrder = 0
      Text = 'E_username'
      OnKeyPress = FormKeyPress
    end
    object B_Guest: TButton
      Left = 16
      Top = 354
      Width = 113
      Height = 25
      Caption = 'P'#345'ihl'#225'sit se jako host'
      TabOrder = 6
      OnClick = B_ApplyClick
    end
    object CHB_uLI_Daemon: TCheckBox
      Left = 16
      Top = 327
      Width = 257
      Height = 17
      Caption = 'Autorizovat uLI-daemon'
      TabOrder = 7
    end
  end
end
