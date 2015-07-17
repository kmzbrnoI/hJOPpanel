object F_Settings: TF_Settings
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'Nastaven'#237
  ClientHeight = 321
  ClientWidth = 641
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
  PixelsPerInch = 96
  TextHeight = 13
  object Label4: TLabel
    Left = 28
    Top = 137
    Width = 125
    Height = 13
    Caption = #381#225'dost o tra'#357'ov'#253' souhlas:'
  end
  object B_Apply: TButton
    Left = 558
    Top = 287
    Width = 75
    Height = 25
    Caption = 'Pou'#382#237't'
    Default = True
    TabOrder = 0
    OnClick = B_ApplyClick
  end
  object B_Storno: TButton
    Left = 477
    Top = 287
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 1
    OnClick = B_StornoClick
  end
  object PC_Main: TPageControl
    Left = 8
    Top = 8
    Width = 629
    Height = 273
    ActivePage = TS_Rights
    TabOrder = 2
    object TS_Server: TTabSheet
      Caption = 'P'#345'ipojen'#237
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label1: TLabel
        Left = 168
        Top = 75
        Width = 81
        Height = 13
        Caption = 'Server (IP/DNS):'
      end
      object Label2: TLabel
        Left = 168
        Top = 105
        Width = 24
        Height = 13
        Caption = 'Port:'
      end
      object E_Host: TEdit
        Left = 278
        Top = 75
        Width = 179
        Height = 21
        TabOrder = 0
        Text = '[E_Host]'
      end
      object CHB_Autoconnect: TCheckBox
        Left = 168
        Top = 144
        Width = 257
        Height = 17
        Caption = 'P'#345'ipojit se k serveru po startu'
        TabOrder = 1
      end
      object SE_Port: TSpinEdit
        Left = 278
        Top = 105
        Width = 179
        Height = 22
        MaxValue = 65535
        MinValue = 1
        TabOrder = 2
        Value = 1
      end
      object CHB_Resuscitation: TCheckBox
        Left = 168
        Top = 167
        Width = 209
        Height = 17
        Caption = 'Automatick'#225' resuscitace spojen'#237
        TabOrder = 3
      end
    end
    object TS_Sounds: TTabSheet
      Caption = 'Zvuky'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label3: TLabel
        Left = 16
        Top = 14
        Width = 125
        Height = 13
        Caption = #381#225'dost o tra'#357'ov'#253' souhlas:'
      end
      object Label5: TLabel
        Left = 16
        Top = 41
        Width = 35
        Height = 13
        Caption = 'Chyba:'
      end
      object Label6: TLabel
        Left = 16
        Top = 68
        Width = 108
        Height = 13
        Caption = 'Potvrzovac'#237' sekvence:'
      end
      object Label7: TLabel
        Left = 16
        Top = 95
        Width = 45
        Height = 13
        Caption = 'P'#345'et'#237#382'en'#237':'
      end
      object Label8: TLabel
        Left = 16
        Top = 122
        Width = 38
        Height = 13
        Caption = 'Zpr'#225'va:'
      end
      object E_Snd_Trat: TEdit
        Left = 160
        Top = 16
        Width = 361
        Height = 21
        TabOrder = 0
        Text = '[E_Snd_Trat]'
      end
      object B_Proch1: TButton
        Tag = 1
        Left = 533
        Top = 16
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 1
        OnClick = B_Proch1Click
      end
      object CHB_Relative: TCheckBox
        Left = 16
        Top = 201
        Width = 97
        Height = 17
        Caption = 'Relativn'#237' cesty'
        Checked = True
        State = cbChecked
        TabOrder = 10
      end
      object E_Snd_Error: TEdit
        Left = 160
        Top = 43
        Width = 361
        Height = 21
        TabOrder = 2
        Text = '[E_Snd_Error]'
      end
      object B_Proch2: TButton
        Tag = 2
        Left = 533
        Top = 43
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 3
        OnClick = B_Proch1Click
      end
      object E_Snd_PS: TEdit
        Left = 160
        Top = 70
        Width = 361
        Height = 21
        TabOrder = 4
        Text = '[E_Snd_PS]'
      end
      object B_Proch3: TButton
        Tag = 3
        Left = 533
        Top = 70
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 5
        OnClick = B_Proch1Click
      end
      object E_Snd_Pretizeni: TEdit
        Left = 160
        Top = 97
        Width = 361
        Height = 21
        TabOrder = 6
        Text = '[E_Snd_Pretizeni]'
      end
      object B_Proch4: TButton
        Tag = 4
        Left = 533
        Top = 97
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 7
        OnClick = B_Proch1Click
      end
      object E_Snd_Zprava: TEdit
        Left = 160
        Top = 124
        Width = 361
        Height = 21
        TabOrder = 8
        Text = '[E_Snd_Zprava]'
      end
      object B_Proch5: TButton
        Tag = 5
        Left = 533
        Top = 124
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 9
        OnClick = B_Proch1Click
      end
    end
    object TS_Symbols: TTabSheet
      Caption = 'Symboly'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label9: TLabel
        Left = 248
        Top = 16
        Width = 70
        Height = 13
        Caption = 'Sada symbol'#367':'
      end
      object Label10: TLabel
        Left = 176
        Top = 152
        Width = 261
        Height = 13
        Caption = 'Zm'#283'ny v sad'#283' symbol'#367' se projev'#237' po restartu aplikace.'
      end
      object LB_Symbols: TListBox
        Left = 248
        Top = 35
        Width = 121
        Height = 97
        ItemHeight = 13
        Items.Strings = (
          'standartn'#237
          'zv'#283't'#353'en'#233)
        TabOrder = 0
      end
    end
    object TS_Vysvetlivky: TTabSheet
      Caption = 'Vysv'#283'tlivky'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label11: TLabel
        Left = 96
        Top = 21
        Width = 157
        Height = 13
        Caption = 'Cesta k souboru s vysv'#283'tlivkami:'
      end
      object CHB_Vysv_Rel: TCheckBox
        Left = 16
        Top = 201
        Width = 97
        Height = 17
        Caption = 'Relativn'#237' cesty'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object E_Vysv: TEdit
        Left = 96
        Top = 40
        Width = 337
        Height = 21
        TabOrder = 0
        Text = '[E_Vysv]'
      end
      object B_Proch_Vysv: TButton
        Tag = 1
        Left = 439
        Top = 40
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 1
        OnClick = B_Proch_VysvClick
      end
    end
    object TS_Panel: TTabSheet
      Caption = 'Panel'
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label12: TLabel
        Left = 96
        Top = 21
        Width = 133
        Height = 13
        Caption = 'Cesta k souboru s panelem:'
      end
      object E_Panel: TEdit
        Left = 96
        Top = 40
        Width = 337
        Height = 21
        TabOrder = 0
        Text = '[E_Panel]'
      end
      object B_Panel_Proch: TButton
        Tag = 1
        Left = 439
        Top = 40
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 1
        OnClick = B_Panel_ProchClick
      end
      object CHB_Panel_Rel: TCheckBox
        Left = 16
        Top = 201
        Width = 97
        Height = 17
        Caption = 'Relativn'#237' cesty'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object RG_Mouse: TRadioGroup
        Left = 192
        Top = 80
        Width = 185
        Height = 57
        Caption = ' P'#345'ekreslen'#237' my'#353'i '
        Items.Strings = (
          'Panel'
          'Opera'#269'n'#237' syst'#233'm')
        TabOrder = 3
      end
      object StaticText1: TStaticText
        Left = 192
        Top = 143
        Width = 185
        Height = 25
        AutoSize = False
        Caption = 
          'P'#345'ekreslov'#225'n'#237' my'#353'i opera'#269'n'#237'm syst'#233'mem m'#367#382'e zrychlit b'#283'h aplikace' +
          '.'
        TabOrder = 4
      end
    end
    object TS_Timer: TTabSheet
      Caption = 'Prim'#225'rn'#237' smy'#269'ka'
      ImageIndex = 5
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label13: TLabel
        Left = 248
        Top = 16
        Width = 128
        Height = 13
        Caption = 'Perioda p'#345'ekreslen'#237' reli'#233'fu:'
      end
      object LB_Timer: TListBox
        Left = 248
        Top = 35
        Width = 121
        Height = 97
        ItemHeight = 13
        Items.Strings = (
          '50'
          '100'
          '200'
          '250'
          '500'
          '750'
          '1000')
        TabOrder = 0
      end
    end
    object TS_Rights: TTabSheet
      Caption = 'Autorizace'
      ImageIndex = 6
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object GB_Auth: TGroupBox
        Left = 32
        Top = 16
        Width = 257
        Height = 203
        Caption = ' P'#345#237'stup k syst'#233'mu '
        TabOrder = 0
        object Label14: TLabel
          Left = 16
          Top = 24
          Width = 90
          Height = 13
          Caption = 'U'#382'ivatelsk'#233' jm'#233'no:'
        end
        object Label15: TLabel
          Left = 16
          Top = 72
          Width = 30
          Height = 13
          Caption = 'Heslo:'
        end
        object CHB_RememberAuth: TCheckBox
          Left = 16
          Top = 151
          Width = 185
          Height = 17
          Caption = 'Ulo'#382'it u'#382'ivatelsk'#233' jm'#233'no a heslo'
          TabOrder = 0
          OnClick = CHB_RememberAuthClick
        end
        object E_username: TEdit
          Left = 16
          Top = 43
          Width = 193
          Height = 21
          TabOrder = 1
          Text = 'E_username'
          OnKeyPress = E_usernameKeyPress
        end
        object E_Password: TEdit
          Left = 16
          Top = 91
          Width = 193
          Height = 21
          PasswordChar = '*'
          TabOrder = 2
          Text = 'Edit1'
          OnChange = E_PasswordChange
          OnKeyPress = E_usernameKeyPress
        end
        object CHB_ShowPassword: TCheckBox
          Left = 16
          Top = 128
          Width = 97
          Height = 17
          Caption = 'Zobrazit heslo'
          TabOrder = 3
          OnClick = CHB_ShowPasswordClick
        end
        object CHB_Forgot: TCheckBox
          Left = 16
          Top = 173
          Width = 185
          Height = 17
          Caption = 'Zapomenout login po odpojen'#237
          TabOrder = 4
        end
      end
      object GroupBox1: TGroupBox
        Left = 312
        Top = 16
        Width = 268
        Height = 203
        Caption = ' Automatick'#225' autorizace '
        TabOrder = 1
        object Label16: TLabel
          Left = 16
          Top = 16
          Width = 227
          Height = 13
          Caption = 'Po p'#345'ipojen'#237' k serveru automaticky autorizovat:'
        end
        object LB_AutoAuthOR: TListBox
          Left = 24
          Top = 40
          Width = 217
          Height = 122
          ItemHeight = 13
          TabOrder = 0
          OnClick = LB_AutoAuthORClick
        end
        object CB_ORRights: TComboBox
          Left = 24
          Top = 168
          Width = 217
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 1
          OnChange = CB_ORRightsChange
          Items.Strings = (
            #382#225'dn'#233' opr'#225'vn'#283'n'#237
            'opr'#225'vn'#283'n'#237' ke '#269'ten'#237
            'opr'#225'vn'#283'n'#237' k z'#225'pisu'
            'superuser')
        end
      end
    end
    object TS_Regulator: TTabSheet
      Caption = 'Regul'#225'tor'
      ImageIndex = 7
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label17: TLabel
        Left = 96
        Top = 21
        Width = 93
        Height = 13
        Caption = 'Cesta k regul'#225'toru:'
      end
      object CHB_Jerry_username: TCheckBox
        Left = 16
        Top = 82
        Width = 265
        Height = 17
        Caption = 'P'#345'ed'#225'vat u'#382'ivatelsk'#233' jm'#233'no a heslo regul'#225'toru'
        TabOrder = 0
      end
      object E_Regulator: TEdit
        Left = 96
        Top = 40
        Width = 337
        Height = 21
        TabOrder = 1
        Text = '[E_Regulator]'
      end
      object B_Reg_Proch: TButton
        Tag = 1
        Left = 439
        Top = 40
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 2
        OnClick = B_Reg_ProchClick
      end
      object CHB_Reg_Rel: TCheckBox
        Left = 16
        Top = 201
        Width = 97
        Height = 17
        Caption = 'Relativn'#237' cesty'
        Checked = True
        State = cbChecked
        TabOrder = 3
      end
    end
  end
  object OD_Snd: TOpenDialog
    Filter = 'Zvuk (*.wav)|*.wav'
    Left = 24
    Top = 272
  end
  object OD_Vysv: TOpenDialog
    Filter = 'Soubor vysv'#283'tlivek (*.csv)|*.csv'
    Left = 96
    Top = 272
  end
  object OD_Panel: TOpenDialog
    Filter = 'Objektov'#253' panel (*.opnl)|*.opnl'
    Left = 168
    Top = 272
  end
  object OD_Reg: TOpenDialog
    Filter = 'Exe soubor (*.exe)|*.exe'
    Left = 240
    Top = 272
  end
end
