object F_splash: TF_splash
  Left = 908
  Top = 252
  Cursor = crHourGlass
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 225
  ClientWidth = 289
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 13
  object L_Created: TLabel
    Left = 8
    Top = 143
    Width = 201
    Height = 23
    Cursor = crHourGlass
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    AutoSize = False
    Caption = #169' Jan Malina 2014'#8211'2026'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsUnderline]
    ParentColor = False
    ParentFont = False
  end
  object L_BuildTime: TLabel
    Left = 8
    Top = 120
    Width = 125
    Height = 20
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = '1.1.200  00:00:00'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object I_Logo: TImage
    Left = 222
    Top = 120
    Width = 64
    Height = 64
    Hint = 'Logo spolecnosti Horasystems'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    ParentShowHint = False
    Picture.Data = {
      0954506E67496D61676589504E470D0A1A0A0000000D49484452000000400000
      00400806000000AA6971DE000000017352474200AECE1CE90000000467414D41
      0000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000
      01624B47440088051D480000002574455874646174653A637265617465003230
      31352D30372D31375431373A31303A34372D30353A303080090BC70000002574
      455874646174653A6D6F6469667900323031352D30372D31375431373A31303A
      34372D30353A3030F154B37B0000018769545874584D4C3A636F6D2E61646F62
      652E786D7000000000003C3F787061636B657420626567696E3D27EFBBBF2720
      69643D2757354D304D7043656869487A7265537A4E54637A6B633964273F3E0D
      0A3C783A786D706D65746120786D6C6E733A783D2261646F62653A6E733A6D65
      74612F223E3C7264663A52444620786D6C6E733A7264663D22687474703A2F2F
      7777772E77332E6F72672F313939392F30322F32322D7264662D73796E746178
      2D6E7323223E3C7264663A4465736372697074696F6E207264663A61626F7574
      3D22757569643A66616635626464352D626133642D313164612D616433312D64
      33336437353138326631622220786D6C6E733A746966663D22687474703A2F2F
      6E732E61646F62652E636F6D2F746966662F312E302F223E3C746966663A4F72
      69656E746174696F6E3E313C2F746966663A4F7269656E746174696F6E3E3C2F
      7264663A4465736372697074696F6E3E3C2F7264663A5244463E3C2F783A786D
      706D6574613E0D0A3C3F787061636B657420656E643D2777273F3E2C94980B00
      0001654944415478DAEDDABB0D02310C066032030CC1FED33004CC7008890251
      4048FCBFC2A58302DB9F44ECE4AE1DFE7C357502EAB503A81350AF6E80F3F5B8
      BD7EBE9C6E4BE00D03AC823005B002C234403A420940324219402AC223E1AF85
      3D01A602B9E2D0005C11A8008E0874003704E82698D03AE16DD01D8132083923
      D046615704EA61C811817E1C764390A83B21C8FE7B2E08D21DD80141DE87D508
      3301DE131FFE2D25422540244235401C0202200A0105108380048840E8BE1051
      ACCA4B98480006823D001A2102008960BB0902F26ADD5F1601D8178F0488281E
      0510533C0220AAF86A80B8E25549DB149F0C50B6FF2402946EBE6900E59D2709
      00D276530060330702A0BA3D42072E06C04C1CF8B4C90218894519B59900BFC4
      A39D33D8003D31A9872C05C0A7B8F41366DB8AAFC40099629F0D9A03E09F0E1B
      0370DE0F3005887E43C4F5B6D806C0A678058055F16C00BBE2990096C5B3006C
      8BB74F6E0720AC3B09A6BAD911B71E160000000049454E44AE426082}
    ShowHint = True
  end
  object L_1: TLabel
    Left = 8
    Top = 184
    Width = 47
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Nac'#237't'#225'n'#237' :'
  end
  object L_Load: TLabel
    Left = 72
    Top = 184
    Width = 69
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Start programu'
  end
  object ST_name: TStaticText
    Left = 0
    Top = 16
    Width = 289
    Height = 41
    Cursor = crHourGlass
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Alignment = taCenter
    AutoSize = False
    Caption = 'hJOPpanel'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -32
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object ST_Version: TStaticText
    Left = 0
    Top = 80
    Width = 289
    Height = 28
    Cursor = crHourGlass
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Alignment = taCenter
    AutoSize = False
    Caption = 'Verze [Verze]'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -20
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object PB_Progress: TProgressBar
    Left = 0
    Top = 201
    Width = 289
    Height = 24
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Max = 10
    Smooth = True
    TabOrder = 2
  end
end
