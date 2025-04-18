object F_SprList: TF_SprList
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Soupravy'
  ClientHeight = 477
  ClientWidth = 983
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 13
  object P_Top: TPanel
    Left = 0
    Top = 0
    Width = 983
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object B_Refresh: TButton
      Left = 8
      Top = 8
      Width = 121
      Height = 25
      Caption = 'Aktualizovat tabulku'
      TabOrder = 0
      OnClick = B_RefreshClick
    end
    object B_RemoveSpr: TButton
      Left = 135
      Top = 8
      Width = 122
      Height = 25
      Caption = 'Smazat soupravu'
      Enabled = False
      TabOrder = 1
      OnClick = B_RemoveSprClick
    end
  end
  object LV_Soupravy: TListView
    Left = 0
    Top = 41
    Width = 983
    Height = 436
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alClient
    Color = clSilver
    Columns = <
      item
        Caption = #268#237'slo'
        Width = 80
      end
      item
        Caption = 'HV1'
        Width = 180
      end
      item
        Caption = 'HV2'
        Width = 180
      end
      item
        Caption = 'Pozn'#225'mka'
        Width = 150
      end
      item
        Caption = 'Po'#269'et voz'#367
      end
      item
        Caption = 'D'#233'lka'
      end
      item
        Caption = 'Typ'
      end
      item
        Caption = 'V'#253'choz'#237' stanice'
        Width = 100
      end
      item
        Caption = 'C'#237'lov'#225' stanice'
        Width = 100
      end>
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    GridLines = True
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    ParentFont = False
    ParentShowHint = False
    ShowHint = False
    TabOrder = 1
    ViewStyle = vsReport
    OnChange = LV_SoupravyChange
    OnKeyDown = LV_SoupravyKeyDown
  end
end
