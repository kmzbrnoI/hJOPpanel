object F_Settings: TF_Settings
  Left = 0
  Top = 0
  ActiveControl = PC_Main
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Nastaven'#237
  ClientHeight = 322
  ClientWidth = 641
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
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
    Left = 6
    Top = 8
    Width = 629
    Height = 273
    ActivePage = TS_ORAuth
    TabOrder = 2
    object TS_Server: TTabSheet
      Caption = 'P'#345'ipojen'#237
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
    object TS_Rights: TTabSheet
      Caption = 'Login'
      ImageIndex = 6
      object GB_Auth: TGroupBox
        Left = 41
        Top = 16
        Width = 257
        Height = 203
        Caption = ' Login '
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
          Width = 225
          Height = 21
          TabOrder = 1
          Text = 'E_username'
          OnKeyPress = E_usernameKeyPress
        end
        object E_Password: TEdit
          Left = 16
          Top = 91
          Width = 225
          Height = 21
          Hint = 
            'Varov'#225'n'#237': po'#269'et znak'#367' neodpov'#237'd'#225' skute'#269'n'#233' d'#233'lce hesla, te'#269'ky v p' +
            'oli jsou pouze ilustrativn'#237'.'
          ParentShowHint = False
          PasswordChar = '*'
          ShowHint = True
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
          Width = 217
          Height = 20
          Caption = 'Zapomenout login po odpojen'#237' od serveru'
          TabOrder = 4
        end
      end
      object GroupBox2: TGroupBox
        Left = 312
        Top = 16
        Width = 257
        Height = 203
        Caption = ' V'#253'choz'#237' zapamatov'#225'n'#237' hesla '
        TabOrder = 1
        object TB_Remeber: TTrackBar
          Left = 10
          Top = 16
          Width = 41
          Height = 177
          Max = 2
          Orientation = trVertical
          ShowSelRange = False
          TabOrder = 0
          TickMarks = tmBoth
          OnChange = TB_RemeberChange
        end
        object ST_Rem1: TStaticText
          Left = 59
          Top = 18
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
          TabOrder = 1
        end
        object ST_Rem2: TStaticText
          Left = 59
          Top = 37
          Width = 184
          Height = 42
          AutoSize = False
          Caption = 
            'Heslo bude ulo'#382'eno pouze pro toto spojen'#237', po odpojen'#237' od server' +
            'u bude heslo smaz'#225'no.'
          TabOrder = 2
        end
        object ST_Rem3: TStaticText
          Left = 59
          Top = 83
          Width = 185
          Height = 57
          AutoSize = False
          Caption = 
            'P'#345'i zm'#283'n'#283' opr'#225'vn'#283'n'#237' oblasti '#345#237'zen'#237', otev'#345'en'#237' regul'#225'toru apod. bu' +
            'de pou'#382'ito toto heslo, nemus'#237'te jej tedy znovu zad'#225'vat.'
          TabOrder = 3
        end
        object ST_Rem4: TStaticText
          Left = 59
          Top = 140
          Width = 184
          Height = 57
          AutoSize = False
          Caption = 
            'Heslo je ulo'#382'eno pouze v pam'#283'ti programu, '#382#225'dn'#253' jin'#253' program k n' +
            #283'mu nem'#225' p'#345#237'stup, ve form'#283' hashe SHA 256.'
          TabOrder = 4
        end
      end
    end
    object TS_Guest: TTabSheet
      Caption = #218#269'et hosta'
      ImageIndex = 9
      object Label10: TLabel
        Left = 200
        Top = 72
        Width = 90
        Height = 13
        Caption = 'U'#382'ivatelsk'#233' jm'#233'no:'
      end
      object Label18: TLabel
        Left = 200
        Top = 120
        Width = 30
        Height = 13
        Caption = 'Heslo:'
      end
      object E_Guest_Username: TEdit
        Left = 200
        Top = 91
        Width = 225
        Height = 21
        TabOrder = 0
        Text = 'E_username'
        OnKeyPress = E_usernameKeyPress
      end
      object E_Guest_Password: TEdit
        Left = 200
        Top = 139
        Width = 225
        Height = 21
        Hint = 
          'Varov'#225'n'#237': po'#269'et znak'#367' neodpov'#237'd'#225' skute'#269'n'#233' d'#233'lce hesla, te'#269'ky v p' +
          'oli jsou pouze ilustrativn'#237'.'
        ParentShowHint = False
        PasswordChar = '*'
        ShowHint = True
        TabOrder = 1
        Text = 'Edit1'
        OnChange = E_Guest_PasswordChange
        OnKeyPress = E_usernameKeyPress
      end
      object CHB_Guest_Enable: TCheckBox
        Left = 200
        Top = 49
        Width = 105
        Height = 17
        Caption = 'Povolit '#250#269'et hosta'
        TabOrder = 2
        OnClick = CHB_Guest_EnableClick
      end
    end
    object TS_Symbols: TTabSheet
      Caption = 'Symboly'
      ImageIndex = 2
      object Label9: TLabel
        Left = 248
        Top = 16
        Width = 70
        Height = 13
        Caption = 'Sada symbol'#367':'
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
        OnDblClick = LB_SymbolsDblClick
      end
    end
    object TS_ORAuth: TTabSheet
      Caption = 'Autorizace O'#344
      ImageIndex = 8
      object GroupBox1: TGroupBox
        Left = 176
        Top = 16
        Width = 268
        Height = 203
        Caption = ' Automatick'#225' autorizace oblast'#237' '#345#237'zen'#237' '
        TabOrder = 0
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
          MultiSelect = True
          TabOrder = 0
          OnClick = LB_AutoAuthORClick
        end
        object CB_ORRights: TComboBox
          Left = 24
          Top = 168
          Width = 217
          Height = 21
          Style = csDropDownList
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
    object TS_Panel: TTabSheet
      Caption = 'Panel'
      ImageIndex = 4
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
        OnDblClick = LB_TimerDblClick
      end
    end
    object TS_uLIdaemon: TTabSheet
      Caption = 'uLI-daemon'
      ImageIndex = 10
      object GB_uLI_Run: TGroupBox
        Left = 123
        Top = 15
        Width = 374
        Height = 122
        TabOrder = 0
        object Label19: TLabel
          Left = 12
          Top = 41
          Width = 157
          Height = 13
          Caption = 'Cesta ke spustiteln'#233'mu souboru:'
        end
        object CHB_uLI_Run: TCheckBox
          Left = 12
          Top = 10
          Width = 233
          Height = 17
          Caption = 'Spustit uLI-daemon se startem hJOPpanelu'
          TabOrder = 0
          OnClick = CHB_uLI_RunClick
        end
        object E_uLI_Path: TEdit
          Left = 12
          Top = 60
          Width = 349
          Height = 21
          TabOrder = 1
          Text = '[E_Panel]'
        end
        object B_uLI_Search: TButton
          Tag = 1
          Left = 287
          Top = 87
          Width = 75
          Height = 21
          Caption = 'Proch'#225'zet'
          TabOrder = 2
          OnClick = B_uLI_SearchClick
        end
        object CHB_uLI_Rel: TCheckBox
          Left = 12
          Top = 87
          Width = 97
          Height = 17
          Caption = 'Relativn'#237' cesty'
          Checked = True
          State = cbChecked
          TabOrder = 3
        end
      end
      object GB_uLI_Connect: TGroupBox
        Left = 123
        Top = 151
        Width = 374
        Height = 80
        TabOrder = 1
        object CHB_uLI_Login: TCheckBox
          Left = 112
          Top = 32
          Width = 153
          Height = 17
          Caption = 'Pou'#382#237'vat lok'#225'ln'#237' uLI-daemon'
          TabOrder = 0
        end
      end
    end
    object TS_Regulator: TTabSheet
      Caption = 'Regul'#225'tor'
      ImageIndex = 7
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
        Caption = 'P'#345'ed'#225'vat regul'#225'toru u'#382'ivatelsk'#233' jm'#233'no a heslo'
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
    object TS_Sounds: TTabSheet
      Caption = 'Zvuky'
      ImageIndex = 1
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
        Top = 97
        Width = 45
        Height = 13
        Caption = 'P'#345'et'#237#382'en'#237':'
      end
      object Label8: TLabel
        Left = 16
        Top = 124
        Width = 38
        Height = 13
        Caption = 'Zpr'#225'va:'
      end
      object Label20: TLabel
        Left = 16
        Top = 151
        Width = 91
        Height = 13
        Caption = 'P'#345'ivol'#225'vac'#237' n'#225'v'#283'st:'
      end
      object Label21: TLabel
        Left = 16
        Top = 178
        Width = 42
        Height = 13
        Caption = 'Timeout:'
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
      object E_Snd_Privolavacka: TEdit
        Left = 160
        Top = 151
        Width = 361
        Height = 21
        TabOrder = 11
        Text = '[E_Snd_Privolavacka]'
      end
      object B_Proch6: TButton
        Tag = 6
        Left = 533
        Top = 151
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 12
        OnClick = B_Proch1Click
      end
      object E_Snd_Timeout: TEdit
        Left = 160
        Top = 178
        Width = 361
        Height = 21
        TabOrder = 13
        Text = '[E_Snd_Timeout]'
      end
      object B_Proch7: TButton
        Tag = 7
        Left = 533
        Top = 178
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 14
        OnClick = B_Proch1Click
      end
    end
    object TS_Sounds2: TTabSheet
      Caption = 'Zvuky 2'
      ImageIndex = 12
      object Label22: TLabel
        Left = 16
        Top = 14
        Width = 100
        Height = 13
        Caption = 'V'#253'zva ke stav'#283'n'#237' JC:'
      end
      object Label23: TLabel
        Left = 16
        Top = 41
        Width = 83
        Height = 13
        Caption = 'Nepostaven'#225' JC:'
      end
      object E_Snd_NeniJC: TEdit
        Left = 160
        Top = 43
        Width = 361
        Height = 21
        TabOrder = 0
        Text = '[E_Snd_NeniJC]'
      end
      object E_Snd_StaveniVyzva: TEdit
        Left = 160
        Top = 16
        Width = 361
        Height = 21
        TabOrder = 1
        Text = '[E_Snd_StaveniVyzva]'
      end
      object B_Proch8: TButton
        Tag = 8
        Left = 533
        Top = 16
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 2
        OnClick = B_Proch1Click
      end
      object B_Proch9: TButton
        Tag = 9
        Left = 533
        Top = 43
        Width = 75
        Height = 21
        Caption = 'Proch'#225'zet'
        TabOrder = 3
        OnClick = B_Proch1Click
      end
      object CHB_Relative2: TCheckBox
        Left = 16
        Top = 201
        Width = 97
        Height = 17
        Caption = 'Relativn'#237' cesty'
        Checked = True
        State = cbChecked
        TabOrder = 4
      end
    end
    object TS_Vysvetlivky: TTabSheet
      Caption = 'Vysv'#283'tlivky'
      ImageIndex = 3
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
    object TS_IPC: TTabSheet
      Caption = 'Meziprocesov'#253' login'
      ImageIndex = 11
      object CHB_IPC_Send: TCheckBox
        Left = 176
        Top = 49
        Width = 265
        Height = 17
        Caption = 'Povolit odes'#237'l'#225'n'#237' po'#382'adavk'#367' na meziprocesov'#253' login'
        TabOrder = 0
      end
      object CHB_IPC_Receive: TCheckBox
        Left = 176
        Top = 72
        Width = 265
        Height = 17
        Caption = 'Akceptovat meziprocesov'#253' login od dal'#353#237'ch panel'#367
        TabOrder = 1
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
  object OD_uLI: TOpenDialog
    Filter = 'Exe soubor (*.exe)|*.exe'
    Left = 312
    Top = 272
  end
end
