object F_Message: TF_Message
  AlignWithMargins = True
  Left = 0
  Top = 0
  ActiveControl = M_Send
  Align = alClient
  BorderStyle = bsNone
  Caption = 'F_Message'
  ClientHeight = 256
  ClientWidth = 454
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnResize = FormResize
  ExplicitWidth = 320
  ExplicitHeight = 240
  PixelsPerInch = 96
  TextHeight = 13
  object M_Send: TMemo
    Left = 8
    Top = 216
    Width = 357
    Height = 32
    MaxLength = 256
    TabOrder = 0
    OnEnter = M_SendEnter
    OnKeyPress = M_SendKeyPress
  end
  object B_Send: TButton
    Left = 371
    Top = 214
    Width = 75
    Height = 34
    Caption = 'Odeslat'
    TabOrder = 1
    OnClick = B_SendClick
  end
  object LV_Messages: TListView
    Left = 8
    Top = 8
    Width = 438
    Height = 200
    Columns = <
      item
        Width = 60
      end
      item
        Width = 200
      end
      item
        Alignment = taRightJustify
        Width = 100
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    ViewStyle = vsReport
    OnCustomDrawItem = LV_MessagesCustomDrawItem
    OnCustomDrawSubItem = LV_MessagesCustomDrawSubItem
    OnDblClick = LV_MessagesDblClick
  end
end
