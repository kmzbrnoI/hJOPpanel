object F_HVEdit: TF_HVEdit
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Upravit hnac'#237' vozidlo'
  ClientHeight = 613
  ClientWidth = 689
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object L_HV: TLabel
    Left = 8
    Top = 8
    Width = 66
    Height = 13
    Caption = 'Hnac'#237' vozidlo:'
  end
  object CB_HV: TComboBox
    Left = 8
    Top = 24
    Width = 673
    Height = 21
    Style = csDropDownList
    TabOrder = 0
    OnChange = CB_HVChange
  end
  object GB_HV: TGroupBox
    Left = 8
    Top = 51
    Width = 673
    Height = 518
    Caption = ' Hnac'#237' vozidlo '
    TabOrder = 1
    object Label2: TLabel
      Left = 14
      Top = 24
      Width = 34
      Height = 13
      Caption = 'N'#225'zev:'
    end
    object Label3: TLabel
      Left = 14
      Top = 51
      Width = 48
      Height = 13
      Caption = 'Ozna'#269'en'#237':'
    end
    object Label4: TLabel
      Left = 14
      Top = 78
      Width = 35
      Height = 13
      Caption = 'Majitel:'
    end
    object Label6: TLabel
      Left = 14
      Top = 105
      Width = 61
      Height = 13
      Caption = 'DCC adresa:'
    end
    object Label7: TLabel
      Left = 263
      Top = 256
      Width = 126
      Height = 13
      Alignment = taRightJustify
      Caption = 'Zak'#225'zan'#233' znaky: enter { }'
    end
    object Label8: TLabel
      Left = 14
      Top = 347
      Width = 123
      Height = 13
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'POM automatick'#253' provoz:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object SB_POM_Automat_Add: TSpeedButton
      Left = 169
      Top = 365
      Width = 23
      Height = 22
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
      OnClick = SB_POM_Automat_AddClick
    end
    object SB_POM_Automat_Remove: TSpeedButton
      Left = 169
      Top = 393
      Width = 23
      Height = 22
      Glyph.Data = {
        36030000424D3603000000000000360000002800000010000000100000000100
        1800000000000003000000000000000000000000000000000000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CEDFFFFFFFFFFFF241CED
        241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241C
        ED241CED241CEDFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241C
        EDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFF
        FFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFF241CED241CED241CED241CED241CED241CEDFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED24
        1CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CED241CEDFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED24
        1CED241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFF241CED241CED241CEDFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFF
        FFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241C
        ED241CEDFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFF241CED
        241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FF241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
      OnClick = SB_POM_Automat_RemoveClick
    end
    object SB_POM_Manual_Add: TSpeedButton
      Left = 369
      Top = 365
      Width = 23
      Height = 22
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
      OnClick = SB_POM_Manual_AddClick
    end
    object SB_POM_Manual_Remove: TSpeedButton
      Left = 369
      Top = 393
      Width = 23
      Height = 22
      Glyph.Data = {
        36030000424D3603000000000000360000002800000010000000100000000100
        1800000000000003000000000000000000000000000000000000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CEDFFFFFFFFFFFF241CED
        241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241C
        ED241CED241CEDFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241C
        EDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFF
        FFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFF241CED241CED241CED241CED241CED241CEDFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED24
        1CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CED241CEDFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED24
        1CED241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFF241CED241CED241CEDFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFF
        FFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        241CED241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241C
        ED241CEDFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFF241CED241CED241CEDFFFFFFFFFFFF241CED
        241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FF241CED241CEDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
      OnClick = SB_POM_Manual_RemoveClick
    end
    object Label9: TLabel
      Left = 212
      Top = 347
      Width = 80
      Height = 13
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'POM ru'#269'n'#237' '#345#237'zen'#237':'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label10: TLabel
      Left = 397
      Top = 20
      Width = 234
      Height = 13
      Caption = 'P'#345#237#345'azen'#237' v'#253'znam'#367' a typ'#367' funkc'#237', ovl'#225'd'#225'n'#237' funkc'#237':'
    end
    object Label5: TLabel
      Left = 14
      Top = 256
      Width = 52
      Height = 13
      Caption = 'Pozn'#225'mka:'
    end
    object Label11: TLabel
      Left = 14
      Top = 170
      Width = 91
      Height = 13
      Caption = 'Maxim'#225'ln'#237' rychlost:'
    end
    object Label12: TLabel
      Left = 14
      Top = 207
      Width = 93
      Height = 13
      Caption = 'T'#345#237'da p'#345'echodnosti:'
    end
    object Label13: TLabel
      Left = 81
      Top = 184
      Width = 23
      Height = 13
      Caption = 'km/h'
    end
    object Label1: TLabel
      Left = 14
      Top = 484
      Width = 120
      Height = 13
      Caption = 'POM p'#345'i uvoln'#283'n'#237' z hJOP:'
    end
    object M_Poznamka: TMemo
      Left = 12
      Top = 275
      Width = 377
      Height = 60
      Lines.Strings = (
        'M_Poznamka')
      MaxLength = 1000
      ScrollBars = ssVertical
      TabOrder = 10
      OnKeyPress = M_PoznamkaKeyPress
    end
    object E_Name: TEdit
      Left = 112
      Top = 24
      Width = 121
      Height = 21
      MaxLength = 100
      TabOrder = 0
      Text = 'E_Name'
      OnKeyPress = M_PoznamkaKeyPress
    end
    object E_Oznaceni: TEdit
      Left = 112
      Top = 51
      Width = 121
      Height = 21
      MaxLength = 100
      TabOrder = 1
      Text = 'E_Oznaceni'
      OnKeyPress = M_PoznamkaKeyPress
    end
    object E_Majitel: TEdit
      Left = 112
      Top = 78
      Width = 121
      Height = 21
      MaxLength = 100
      TabOrder = 2
      Text = 'E_Majitel'
      OnKeyPress = M_PoznamkaKeyPress
    end
    object E_Adresa: TEdit
      Left = 112
      Top = 105
      Width = 121
      Height = 21
      MaxLength = 4
      NumbersOnly = True
      TabOrder = 3
      Text = 'E_Adresa'
    end
    object RG_Trida: TRadioGroup
      Left = 239
      Top = 16
      Width = 149
      Height = 123
      Caption = ' Typ '
      Items.Strings = (
        'parn'#237
        'dieselov'#225
        'motorov'#225
        'elektrick'#225
        'v'#367'z'
        'jin'#253)
      TabOrder = 6
    end
    object RG_StA: TRadioGroup
      Left = 239
      Top = 145
      Width = 149
      Height = 52
      Caption = ' Stanovi'#353't'#283' A ve sm'#283'ru '
      Items.Strings = (
        'lich'#233'm'
        'sud'#233'm')
      TabOrder = 7
    end
    object LV_Pom_Automat: TListView
      Left = 12
      Top = 365
      Width = 152
      Height = 113
      Columns = <
        item
          Caption = 'CV'
        end
        item
          Caption = 'Data'
        end>
      MultiSelect = True
      ReadOnly = True
      RowSelect = True
      TabOrder = 11
      ViewStyle = vsReport
      OnChange = LV_Pom_AutomatChange
      OnDblClick = LV_Pom_AutomatDblClick
      OnKeyDown = LV_Pom_AutomatKeyDown
    end
    object LV_Pom_Manual: TListView
      Left = 211
      Top = 365
      Width = 152
      Height = 113
      Columns = <
        item
          Caption = 'CV'
        end
        item
          Caption = 'Data'
        end>
      ReadOnly = True
      RowSelect = True
      SortType = stData
      TabOrder = 12
      ViewStyle = vsReport
      OnChange = LV_Pom_ManualChange
      OnDblClick = LV_Pom_ManualDblClick
      OnKeyDown = LV_Pom_ManualKeyDown
    end
    object LV_Funkce: TListView
      Left = 398
      Top = 39
      Width = 268
      Height = 466
      Checkboxes = True
      Columns = <
        item
          Caption = 'Funkce'
          MinWidth = 50
        end
        item
          Caption = 'V'#253'znam'
          MinWidth = 100
          Width = 150
        end
        item
          Caption = 'P / M'
          Width = 36
        end>
      ColumnClick = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ReadOnly = True
      ParentFont = False
      TabOrder = 14
      ViewStyle = vsReport
    end
    object B_Search: TButton
      Left = 112
      Top = 132
      Width = 121
      Height = 29
      Caption = 'Existuje lokomotiva?'
      TabOrder = 4
      OnClick = B_SearchClick
    end
    object SE_MaxSpeed: TSpinEdit
      Left = 112
      Top = 167
      Width = 121
      Height = 22
      MaxValue = 120
      MinValue = 0
      TabOrder = 5
      Value = 0
    end
    object CB_Prechodnost: TComboBox
      Left = 112
      Top = 208
      Width = 276
      Height = 21
      Style = csDropDownList
      TabOrder = 8
    end
    object CB_POM_Release: TComboBox
      Left = 152
      Top = 484
      Width = 212
      Height = 21
      Style = csDropDownList
      TabOrder = 13
      Items.Strings = (
        'POM ru'#269'n'#237' '#345#237'zen'#237
        'POM automatick'#233' '#345#237'zen'#237)
    end
    object CHB_Multitrack: TCheckBox
      Left = 112
      Top = 235
      Width = 161
      Height = 17
      Caption = 'Vozidlo zp'#367'sobil'#233' multitrakce'
      TabOrder = 9
    end
  end
  object B_Apply: TButton
    Left = 606
    Top = 580
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = B_ApplyClick
  end
  object B_Cancel: TButton
    Left = 525
    Top = 580
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 3
    OnClick = B_CancelClick
  end
  object B_Refresh: TButton
    Left = 8
    Top = 580
    Width = 137
    Height = 25
    Caption = 'Aktualizovat seznam HV'
    TabOrder = 4
    OnClick = B_RefreshClick
  end
end
