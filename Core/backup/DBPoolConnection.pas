unit DBPoolConnection;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  SyncObjs,
  Generics.Collections,
  DBPoolConnection.Interfaces,
  DBPoolConnection.Types;

type

  EDBPoolConnectionException = class(Exception);

  TDBConnectionItem = class
  private
    FLocked: Boolean;
    FLastUse: TDate;
    FDatabaseComponent: TComponent;
  public
    property Locked: Boolean read FLocked write FLocked;
    property LastUse: TDate read FLastUse write FLastUse;
    property DatabaseComponent: TComponent read FDatabaseComponent write FDatabaseComponent;//Zeos,UniDac,etc
  end;

  TDBConnection = class(TInterfacedObject, IDBConnection)
  private
    FDatabaseComponent: TComponent;
    FTenantDatabase: string;
    function GetDatabaseComponent: TComponent;
    procedure UnlockConnection;
  public
    constructor Create(ATenantDatabase: string; ADatabaseComponent: TComponent);
    destructor Destroy; override;
    class function New(ATenantDatabase: string; ADatabaseComponent: TComponent): IDBConnection;
  end;

  { TDBPoolConnection }

  TDBPoolConnection = class(TInterfacedObject, IDBPoolConnection)
  private
    FMaxPool: Integer;
    FWaitAvailableConnection: Boolean;
    FOnCreateDatabaseComponent: TCreateDatabaseComponentEvent;
    function GetAvailableConnection(ATenantDatabse: string; AConnectionList: TThreadList<TDBConnectionItem>): IDBConnection;
    function HaveDuplicatedConnection(ADatabaseComponent: TComponent): Boolean;
    procedure FreePool;
    constructor CreatePrivate;
  public
    constructor Create;
    destructor Destroy; override;
    class function GetInstance: IDBPoolConnection;
    function SetMaxPool(AMaxPool: Integer): IDBPoolConnection;
    function SetOnCreateDatabaseComponent(AValue: TCreateDatabaseComponentEvent): IDBPoolConnection;
    function WaintAvailableConnection(AValue: Boolean): IDBPoolConnection;
    function GetDBConnection: IDBConnection; overload;
    function GetDBConnection(ATenantDatabase: string): IDBConnection; overload;
    function GetStatus: string;
  end;

implementation

uses
  StrUtils;

var
  FDBPoolSingleton: IDBPoolConnection;
  FPool: TDictionary<string,TThreadList<TDBConnectionItem>>;
  FLockPool: TCriticalSection;

{ TDBPoolConnection }

function TDBPoolConnection.GetDBConnection: IDBConnection;
begin
  Result := Self.GetDBConnection('default');
end;

function TDBPoolConnection.HaveDuplicatedConnection(
  ADatabaseComponent: TComponent): Boolean;
var
  vTenantDatabase: string;
  vConnectionList: TThreadList<TDBConnectionItem>;
  vList: TList<TDBConnectionItem>;
  i, vCount: Integer;
begin
  vCount := 0;
  for vTenantDatabase in FPool.Keys do
  begin
    if FPool.TryGetValue(vTenantDatabase, vConnectionList) then
    begin
      try
        vList := vConnectionList.LockList;
        for i := 0 to vList.Count-1 do
        begin
          if vList.Items[i].DatabaseComponent = ADatabaseComponent then
            Inc(vCount);
        end;
      finally
       vConnectionList.UnlockList;
      end;
    end;
  end;
  Result := vCount > 1;
end;

constructor TDBPoolConnection.Create;
begin
  raise EDBPoolConnectionException.Create('Use TDBPoolConnection.GetInstance');
end;

constructor TDBPoolConnection.CreatePrivate;
begin
  inherited Create;
  FPool := TDictionary<string,TThreadList<TDBConnectionItem>>.Create;
  FLockPool := TCriticalSection.Create;
  FMaxPool:= 10;
  FWaitAvailableConnection := True;
end;

destructor TDBPoolConnection.Destroy;
begin
  FreePool;
  FLockPool.Free;
  inherited;
end;

procedure TDBPoolConnection.FreePool;
var
  i: Integer;
  vTenantDatabase: string;
  vConnectionList: TThreadList<TDBConnectionItem>;
  vList: TList<TDBConnectionItem>;
begin
  //free List Connections and Database Connections
  for vTenantDatabase in FPool.Keys do
  begin
    if FPool.TryGetValue(vTenantDatabase, vConnectionList) then
    begin
      try
        vList := vConnectionList.LockList;
        for i := 0 to vList.Count-1 do
        begin
          vList.Items[i].DatabaseComponent.Free;
          vList.Items[i].Free;
        end;
        vList.Clear;
      finally
        vConnectionList.UnlockList;
        vConnectionList.Clear;
        vConnectionList.Free;
      end;
    end;
  end;
  FPool.Clear;
  FPool.Free;
end;

function TDBPoolConnection.GetAvailableConnection(ATenantDatabse: string;
  AConnectionList: TThreadList<TDBConnectionItem>): IDBConnection;
var
  vList: TList<TDBConnectionItem>;
  vItem: TDBConnectionItem;
  vDatabaseComponent: TComponent;
  i: Integer;
begin
  Result := nil;

  while (Result = nil) do
  begin
    try
      vList := AConnectionList.LockList;
      //search for available connection in Pool
      for i:= 0 to vList.Count -1 do
      begin
        vItem := vList.Items[i];
        if not vItem.Locked then
        begin
          vItem.Locked := True;
          vItem.LastUse := Now;
          Result := TDBConnection.New(ATenantDatabse, vItem.DatabaseComponent);
          Break;
        end;
      end;
      if (Result = nil) and (vList.Count < FMaxPool) then
      begin
        //create new connection database
        vDatabaseComponent := FOnCreateDatabaseComponent(ATenantDatabse);
        vItem := TDBConnectionItem.Create;
        vItem.DatabaseComponent := vDatabaseComponent;
        vItem.Locked := True;
        vItem.LastUse := Now;
        vList.Add(vItem);
        Result := TDBConnection.New(ATenantDatabse, vItem.DatabaseComponent);
      end;
    finally
      AConnectionList.UnlockList;
    end;

    if (Result = nil) and (not FWaitAvailableConnection) then
      Break
    else if Result = nil then
      Sleep(100);//wait few milliseconds and try again
  end;
end;

function TDBPoolConnection.GetDBConnection(
  ATenantDatabase: string): IDBConnection;
var
  vList: TThreadList<TDBConnectionItem>;
begin
  Result := nil;

  if ATenantDatabase = '' then
    raise EDBPoolConnectionException.Create('Undefined TenantDatabase');
  if not Assigned(FOnCreateDatabaseComponent) then
    raise EDBPoolConnectionException.Create('Undefined OnCreateDatabaseComponent event');

  try
    FLockPool.Enter;
    if FPool.TryGetValue(ATenantDatabase, vList) then
      Result := GetAvailableConnection(ATenantDatabase, vList)
    else
    begin
      vList := TThreadList<TDBConnectionItem>.Create;
      FPool.Add(ATenantDatabase, vList);
      Result := GetAvailableConnection(ATenantDatabase, vList);
    end;
  finally
    FLockPool.Leave;
  end;
end;

class function TDBPoolConnection.GetInstance: IDBPoolConnection;
begin
  if FDBPoolSingleton = nil then
    FDBPoolSingleton := TDBPoolConnection.CreatePrivate;

  Result := FDBPoolSingleton;
end;

function TDBPoolConnection.GetStatus: string;
var
  vTenantDatabase, vStatus: string;
  vConnectionList: TThreadList<TDBConnectionItem>;
  vList: TList<TDBConnectionItem>;
  i, vAvailable, vLocked, vDuplicated: Integer;
begin
  vStatus := '';
  vDuplicated := 0;
  try
    FLockPool.Enter;
    for vTenantDatabase in FPool.Keys do
    begin
      if FPool.TryGetValue(vTenantDatabase, vConnectionList) then
      begin
        try
          vAvailable := 0;
          vLocked := 0;
          vList := vConnectionList.LockList;
          for i := 0 to vList.Count-1 do
          begin
            if TDBConnectionItem(vList.Items[i]).Locked then
              Inc(vLocked)
            else
              Inc(vAvailable);
            if HaveDuplicatedConnection(TDBConnectionItem(vList.Items[i]).DatabaseComponent) then
              Inc(vDuplicated);
          end;
          vStatus := vStatus + Format('TenantDatabase: %s Total: %d Locked: %d Available: %d',
            [vTenantDatabase, vList.Count, vLocked, vAvailable]) + sLineBreak;
        finally
         vConnectionList.UnlockList;
        end;
      end;
    end;
  finally
    FLockPool.Leave;
  end;
  vStatus := vStatus + 'Duplicated Connections: '+IntToStr(vDuplicated)+
    IfThen(vDuplicated=0, ' ITs OK', ' THIS IS NOT GOOD');
  Result := vStatus;
end;

function TDBPoolConnection.SetMaxPool(AMaxPool: Integer): IDBPoolConnection;
begin
  Result := Self;
  FMaxPool := AMaxPool;
end;

function TDBPoolConnection.SetOnCreateDatabaseComponent(
  AValue: TCreateDatabaseComponentEvent): IDBPoolConnection;
begin
  Result := Self;
  FOnCreateDatabaseComponent := AValue;
end;

function TDBPoolConnection.WaintAvailableConnection(AValue: Boolean
  ): IDBPoolConnection;
begin
  Result := Self;
  FWaitAvailableConnection := AValue;
end;

{ TDBConnection }

constructor TDBConnection.Create(ATenantDatabase: string; ADatabaseComponent: TComponent);
begin
  inherited Create;
  FDatabaseComponent := ADatabaseComponent;
  FTenantDatabase := ATenantDatabase;
end;

destructor TDBConnection.Destroy;
begin
  UnlockConnection;
  inherited;
end;

function TDBConnection.GetDatabaseComponent: TComponent;
begin
  Result := FDatabaseComponent;
end;

class function TDBConnection.New(ATenantDatabase: string; ADatabaseComponent: TComponent): IDBConnection;
begin
  Result := TDBConnection.Create(ATenantDatabase, ADatabaseComponent);
end;

procedure TDBConnection.UnlockConnection;
var
  vConnectionList: TThreadList<TDBConnectionItem>;
  vList: TList<TDBConnectionItem>;
  vItem: TDBConnectionItem;
  vFound: Boolean;
  i: Integer;
begin
  vConnectionList := nil;
  vFound := False;
  if FPool.TryGetValue(FTenantDatabase, vConnectionList) then
  begin
    try
      vList := vConnectionList.LockList;
      for i:= 0 to vList.Count-1 do
      begin
        vItem := vList.Items[i];
        if vItem.DatabaseComponent = FDatabaseComponent then
        begin
          vItem.Locked := False;
          vFound := True;
          Break;
        end;
      end;
    finally
      vConnectionList.UnlockList;
    end;
  end;
  Assert(vConnectionList<>nil, 'TenantDatabase not found');
  Assert(vFound, 'DatabaseComponent not found in List');
end;

initialization
  FDBPoolSingleton := nil;
  FLockPool := nil;

end.
