object F_HVDelete: TF_HVDelete
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Smazat lokomotivu'
  ClientHeight = 173
  ClientWidth = 242
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 84
    Width = 113
    Height = 13
    Caption = 'Odstranit hnac'#237' vozidlo:'
  end
  object StaticText1: TStaticText
    Left = 8
    Top = 8
    Width = 226
    Height = 25
    AutoSize = False
    Caption = 
      'Varov'#225'n'#237': Tato operace povede k '#250'pln'#233'mu odstran'#283'n'#237' hnac'#237'ho vozid' +
      'la z datab'#225'ze serveru!'
    TabOrder = 0
  end
  object StaticText2: TStaticText
    Left = 8
    Top = 39
    Width = 226
    Height = 26
    AutoSize = False
    Caption = 
      'Data, jako je vzd'#225'lenost, kterou lokomotiva na koleji'#353'ti najela,' +
      ' budou bez n'#225'hrady ztracena.'
    TabOrder = 1
  end
  object CB_HV: TComboBox
    Left = 8
    Top = 103
    Width = 225
    Height = 21
    Style = csDropDownList
    TabOrder = 2
  end
  object B_Storno: TButton
    Left = 77
    Top = 137
    Width = 75
    Height = 25
    Caption = 'Storno'
    TabOrder = 3
    OnClick = B_StornoClick
  end
  object B_Remove: TButton
    Left = 158
    Top = 137
    Width = 75
    Height = 25
    Caption = 'Odstranit'
    Default = True
    TabOrder = 4
    OnClick = B_RemoveClick
  end
end
