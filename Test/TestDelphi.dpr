program TestDelphi;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  {$IFDEF FPC}
  Interfaces,
  {$ENDIF}
  Forms,
  uMain in 'uMain.pas' {FrmMain},
  DBPoolConnection in '..\Core\DBPoolConnection.pas',
  DBPoolConnection.Interfaces in '..\Core\DBPoolConnection.Interfaces.pas',
  DBPoolConnection.Types in '..\Core\DBPoolConnection.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  {$IFNDEF FPC}
  ReportMemoryLeaksOnShutdown := True;
  Application.MainFormOnTaskbar := True;
  {$ENDIF}
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
