object F_Messages: TF_Messages
  Left = 0
  Top = 0
  ActiveControl = LV_ORs
  BorderIcons = [biSystemMenu]
  Caption = 'Zpr'#225'vy'
  ClientHeight = 312
  ClientWidth = 647
  Color = clBtnFace
  Constraints.MinHeight = 200
  Constraints.MinWidth = 500
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  TextHeight = 13
  object LV_ORs: TListView
    Left = 8
    Top = 8
    Width = 163
    Height = 294
    Columns = <
      item
        Width = 140
      end>
    ColumnClick = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    Items.ItemData = {
      05520000000100000000000000FFFFFFFFFFFFFFFF00000000FFFFFFFF000000
      001C610061006100610061006100610061006100610061006100610061006100
      6100610061006100610061006100610061006100610061006100}
    ReadOnly = True
    RowSelect = True
    ParentFont = False
    ShowColumnHeaders = False
    TabOrder = 0
    ViewStyle = vsReport
    OnDblClick = LV_ORsDblClick
    OnKeyPress = LV_ORsKeyPress
  end
  object PC_Clients: TPageControl
    Left = 177
    Top = 8
    Width = 462
    Height = 294
    OwnerDraw = True
    TabOrder = 1
    OnChange = PC_ClientsChange
    OnDragDrop = PC_ClientsDragDrop
    OnDragOver = PC_ClientsDragOver
    OnDrawTab = PageControlCloseButtonDrawTab
    OnMouseDown = PageControlCloseButtonMouseDown
    OnMouseLeave = PageControlCloseButtonMouseLeave
    OnMouseMove = PageControlCloseButtonMouseMove
    OnMouseUp = PageControlCloseButtonMouseUp
  end
end
