object F_SprToSlot: TF_SprToSlot
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Souprava do slotu'
  ClientHeight = 155
  ClientWidth = 447
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 88
    Height = 19
    Caption = 'Lokomotivy:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object L_Addrs: TLabel
    Left = 112
    Top = 8
    Width = 327
    Height = 19
    Alignment = taRightJustify
    AutoSize = False
    Caption = '1234, 1235'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object L_Slot: TLabel
    Left = 8
    Top = 40
    Width = 43
    Height = 13
    Caption = 'Do slotu:'
  end
  object L_Stav: TLabel
    Left = 8
    Top = 131
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
  object P_Buttons: TPanel
    Left = 8
    Top = 56
    Width = 431
    Height = 69
    BevelOuter = bvNone
    TabOrder = 0
  end
end
