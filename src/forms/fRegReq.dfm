object F_RegReq: TF_RegReq
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'P'#345'edat vozidlo do ru'#269'n'#237'ho '#345#237'zen'#237
  ClientHeight = 393
  ClientWidth = 433
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
  object L_Stav: TLabel
    Left = 8
    Top = 366
    Width = 417
    Height = 16
    Align = alCustom
    Alignment = taCenter
    AutoSize = False
    Caption = 'L_Stav'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = False
  end
  object P_MausSlot: TPanel
    Left = 8
    Top = 335
    Width = 417
    Height = 50
    BevelOuter = bvNone
    TabOrder = 4
    Visible = False
    object L_Slot: TLabel
      Left = 8
      Top = 8
      Width = 43
      Height = 13
      Caption = 'Do slotu:'
    end
  end
  object GB_User: TGroupBox
    Left = 8
    Top = 8
    Width = 417
    Height = 137
    Caption = ' '#381#225'daj'#237'c'#237' u'#382'ivatel '
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 90
      Height = 13
      Caption = 'U'#382'ivatelsk'#233' jm'#233'no:'
    end
    object L_Username: TLabel
      Left = 16
      Top = 31
      Width = 59
      Height = 13
      Caption = 'L_Username'
    end
    object Label2: TLabel
      Left = 232
      Top = 15
      Width = 84
      Height = 13
      Caption = 'Jm'#233'no a p'#345#237'jmen'#237':'
    end
    object L_Name: TLabel
      Left = 232
      Top = 31
      Width = 38
      Height = 13
      Caption = 'L_Name'
    end
    object Label3: TLabel
      Left = 16
      Top = 64
      Width = 97
      Height = 13
      Caption = 'Pozn'#225'mka k '#382#225'dosti:'
    end
    object M_Note: TMemo
      Left = 16
      Top = 83
      Width = 385
      Height = 38
      Lines.Strings = (
        'M_Note')
      ReadOnly = True
      TabOrder = 0
    end
  end
  object GB_Lokos: TGroupBox
    Left = 8
    Top = 151
    Width = 417
    Height = 178
    Caption = ' Vyberte vozidla '
    TabOrder = 1
    object LV_Lokos: TListView
      Left = 2
      Top = 15
      Width = 413
      Height = 161
      Align = alClient
      Checkboxes = True
      Columns = <
        item
          Caption = 'Adresa'
          Width = 80
        end
        item
          Caption = 'Vozidlo'
          Width = 200
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object B_Remote: TButton
    Left = 304
    Top = 335
    Width = 119
    Height = 25
    Caption = 'Potvrdit '#382#225'dost'
    Default = True
    TabOrder = 2
    OnClick = B_RemoteClick
  end
  object B_Local: TButton
    Left = 112
    Top = 335
    Width = 186
    Height = 25
    Caption = 'Otev'#345'it v lok'#225'ln'#237'm regul'#225'toru'
    TabOrder = 3
    OnClick = B_LocalClick
  end
end
