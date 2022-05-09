unit DBPoolConnection.Interfaces;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes,
  DBPoolConnection.Types;

type

  IDBConnection = interface
  ['{7BEE7CD3-7054-4080-B4A8-B021F2392A0D}']
    function GetDatabaseComponent: TObject;
    property DatabaseComponent: TComponent read GetDatabaseComponent;
  end;

  IDBPoolConnection = interface
  ['{BB99A3F8-ACC7-43A5-A9C4-F01799A5BAF2}']
    function SetMaxPool(AMaxPool: Integer): IDBPoolConnection;
    function SetOnCreateDatabaseComponent(AValue: TCreateDatabaseComponentEvent): IDBPoolConnection;
    function WaintAvailableConnection(AValue: Boolean): IDBPoolConnection;
    function GetDBConnection: IDBConnection; overload;
    function GetDBConnection(ATenantDatabase: string): IDBConnection; overload;
    function GetStatus: string;
  end;

implementation

end.
