object F_HVEdit: TF_HVEdit
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Edtiovat hnac'#237' vozidlo'
  ClientHeight = 497
  ClientWidth = 689
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
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
    ItemHeight = 13
    TabOrder = 0
    OnChange = CB_HVChange
  end
  object GB_HV: TGroupBox
    Left = 8
    Top = 51
    Width = 673
    Height = 406
    Caption = ' Hnac'#237' vozidlo '
    TabOrder = 1
    object Label2: TLabel
      Left = 16
      Top = 24
      Width = 34
      Height = 13
      Caption = 'N'#225'zev:'
    end
    object Label3: TLabel
      Left = 16
      Top = 54
      Width = 48
      Height = 13
      Caption = 'Ozna'#269'en'#237':'
    end
    object Label4: TLabel
      Left = 15
      Top = 81
      Width = 35
      Height = 13
      Caption = 'Majitel:'
    end
    object Label6: TLabel
      Left = 15
      Top = 108
      Width = 61
      Height = 13
      Caption = 'DCC adresa:'
    end
    object Label7: TLabel
      Left = 262
      Top = 172
      Width = 126
      Height = 13
      Alignment = taRightJustify
      Caption = 'Zak'#225'zan'#233' znaky: enter { }'
    end
    object Label8: TLabel
      Left = 11
      Top = 262
      Width = 146
      Height = 13
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'POM p'#345'i p'#345'evzet'#237' do automatu:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object SB_Take_Add: TSpeedButton
      Left = 168
      Top = 280
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
      OnClick = SB_Take_AddClick
    end
    object SB_Take_Remove: TSpeedButton
      Left = 168
      Top = 308
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
      OnClick = SB_Take_RemoveClick
    end
    object SB_Rel_Add: TSpeedButton
      Left = 368
      Top = 280
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
      OnClick = SB_Rel_AddClick
    end
    object SB_Rel_Remove: TSpeedButton
      Left = 368
      Top = 308
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
      OnClick = SB_Rel_RemoveClick
    end
    object Label9: TLabel
      Left = 210
      Top = 262
      Width = 141
      Height = 13
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'POM p'#345'i uvoln'#283'n'#237' z automatu:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label10: TLabel
      Left = 397
      Top = 20
      Width = 200
      Height = 13
      Caption = 'P'#345#237#345'azen'#237' v'#253'znam'#367' funkc'#237', ovl'#225'd'#225'n'#237' funkc'#237':'
    end
    object Label5: TLabel
      Left = 15
      Top = 172
      Width = 52
      Height = 13
      Caption = 'Pozn'#225'mka:'
    end
    object M_Poznamka: TMemo
      Left = 11
      Top = 191
      Width = 377
      Height = 60
      Lines.Strings = (
        'M_Poznamka')
      MaxLength = 1000
      ScrollBars = ssVertical
      TabOrder = 6
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
      Height = 83
      Caption = ' Trakce '
      Items.Strings = (
        'parn'#237
        'diesel'
        'motor'
        'elektro')
      TabOrder = 4
    end
    object RG_StA: TRadioGroup
      Left = 239
      Top = 105
      Width = 149
      Height = 58
      Caption = ' Stanovi'#353't'#283' A ve sm'#283'ru '
      Items.Strings = (
        'lich'#233'm'
        'sud'#233'm')
      TabOrder = 5
    end
    object LV_Pom_Load: TListView
      Left = 11
      Top = 280
      Width = 152
      Height = 110
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
      TabOrder = 7
      ViewStyle = vsReport
      OnChange = LV_Pom_LoadChange
      OnDblClick = LV_Pom_LoadDblClick
    end
    object LV_Pom_Release: TListView
      Left = 210
      Top = 280
      Width = 152
      Height = 110
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
      TabOrder = 8
      ViewStyle = vsReport
      OnChange = LV_Pom_ReleaseChange
      OnDblClick = LV_Pom_ReleaseDblClick
    end
    object LV_Funkce: TListView
      Left = 397
      Top = 39
      Width = 268
      Height = 354
      Checkboxes = True
      Columns = <
        item
          Caption = 'Funkce'
          MaxWidth = 50
          MinWidth = 50
        end
        item
          Caption = 'V'#253'znam'
          MaxWidth = 150
          MinWidth = 150
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
      TabOrder = 9
      ViewStyle = vsReport
    end
    object B_Search: TButton
      Left = 112
      Top = 132
      Width = 121
      Height = 25
      Caption = 'Existuje lokomotiva?'
      TabOrder = 10
      OnClick = B_SearchClick
    end
  end
  object B_Apply: TButton
    Left = 606
    Top = 464
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = B_ApplyClick
  end
  object B_Cancel: TButton
    Left = 525
    Top = 464
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 3
    OnClick = B_CancelClick
  end
end
