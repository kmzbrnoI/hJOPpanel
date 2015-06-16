object F_Debug: TF_Debug
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Debug'
  ClientHeight = 537
  ClientWidth = 616
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 424
    Top = 453
    Width = 66
    Height = 13
    Caption = 'D'#233'lka zpr'#225'vy:'
  end
  object L_len: TLabel
    Left = 545
    Top = 453
    Width = 25
    Height = 13
    Alignment = taRightJustify
    Caption = 'L_len'
  end
  object Label2: TLabel
    Left = 576
    Top = 453
    Width = 28
    Height = 13
    Caption = 'znak'#367
  end
  object CHB_DataLogging: TCheckBox
    Left = 8
    Top = 8
    Width = 97
    Height = 17
    Caption = 'Logovat data'
    TabOrder = 0
  end
  object LV_Log: TListView
    Left = 8
    Top = 31
    Width = 600
    Height = 272
    Columns = <
      item
        Caption = #268'as'
        Width = 80
      end
      item
        Caption = 'Zpr'#225'va'
        Width = 480
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnChange = LV_LogChange
    OnCustomDrawItem = LV_LogCustomDrawItem
  end
  object M_Data: TMemo
    Left = 10
    Top = 309
    Width = 598
    Height = 140
    ReadOnly = True
    TabOrder = 2
    OnChange = M_DataChange
  end
  object B_ClearLog: TButton
    Left = 533
    Top = 8
    Width = 75
    Height = 17
    Caption = 'Clear'
    TabOrder = 3
    OnClick = B_ClearLogClick
  end
  object GB_SendData: TGroupBox
    Left = 8
    Top = 472
    Width = 598
    Height = 57
    Caption = ' Odeslat data '
    TabOrder = 4
    object E_Send: TEdit
      Left = 16
      Top = 24
      Width = 490
      Height = 21
      TabOrder = 0
      OnKeyPress = E_SendKeyPress
    end
    object B_Send: TButton
      Left = 512
      Top = 23
      Width = 75
      Height = 22
      Caption = 'Odeslat'
      TabOrder = 1
      OnClick = B_SendClick
    end
  end
end
