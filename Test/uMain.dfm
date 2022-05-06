object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'Test'
  ClientHeight = 299
  ClientWidth = 652
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 16
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Test'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 16
    Top = 39
    Width = 628
    Height = 242
    TabOrder = 1
  end
  object Button2: TButton
    Left = 97
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Status'
    TabOrder = 2
    OnClick = Button2Click
  end
end
