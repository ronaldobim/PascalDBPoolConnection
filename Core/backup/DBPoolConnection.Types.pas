unit DBPoolConnection.Types;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


interface

uses Classes;

type

  TCreateDatabaseComponentEvent = {$IFNDEF FPC}reference to {$ENDIF}function(ATenantDatabase: string): TComponent;

implementation

end.
