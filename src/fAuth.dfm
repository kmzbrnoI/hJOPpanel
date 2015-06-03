object F_Auth: TF_Auth
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Server vy'#382'aduje autentikaci'
  ClientHeight = 217
  ClientWidth = 242
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object Label14: TLabel
    Left = 24
    Top = 16
    Width = 90
    Height = 13
    Caption = 'U'#382'ivatelsk'#233' jm'#233'no:'
  end
  object Label15: TLabel
    Left = 24
    Top = 64
    Width = 30
    Height = 13
    Caption = 'Heslo:'
  end
  object CHB_RememberAuth: TCheckBox
    Left = 32
    Top = 121
    Width = 185
    Height = 17
    Caption = 'Ulo'#382'it u'#382'ivatelsk'#233' jm'#233'no a heslo'
    TabOrder = 2
    OnClick = CHB_RememberAuthClick
    OnKeyPress = FormKeyPress
  end
  object E_username: TEdit
    Left = 24
    Top = 35
    Width = 193
    Height = 21
    MaxLength = 64
    TabOrder = 0
    Text = 'E_username'
    OnKeyPress = FormKeyPress
  end
  object E_Password: TEdit
    Left = 24
    Top = 83
    Width = 193
    Height = 21
    MaxLength = 64
    PasswordChar = '*'
    TabOrder = 1
    Text = 'Edit1'
    OnKeyPress = FormKeyPress
  end
  object B_Apply: TButton
    Left = 142
    Top = 176
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 4
    OnClick = B_ApplyClick
    OnKeyPress = FormKeyPress
  end
  object B_Cancel: TButton
    Left = 61
    Top = 176
    Width = 75
    Height = 25
    Caption = 'Zru'#353'it'
    TabOrder = 5
    OnClick = B_CancelClick
    OnKeyPress = FormKeyPress
  end
  object CHB_Forgot: TCheckBox
    Left = 32
    Top = 144
    Width = 185
    Height = 17
    Caption = 'Zapomenout login po odpojen'#237
    TabOrder = 3
  end
end
