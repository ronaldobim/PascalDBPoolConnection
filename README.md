# PascalDBPoolConnection
Generic Database Connection Pooling for Delphi/Lazarus/FreePascal

## Why use a connection pool?
Using connection pooling on application servers increases application performance. Avoiding connections at all times.

## Functionalities
* Compatibility with Delphi XE7(Up) and Lazarus(Last version).
* Simple and secure, just request connections to the pool. connections are returned to the pool automatically using reference counting.
* Fully Thread-Safe, test project included to perform stress testing.
* Works with any type of database access component because it does not use dependency on them (Zeos, Unidac, FireDac, etc.), the dependency is only with your application.
* Multitenant Control.
* Flexible to use with any development framework (Datasnap, Horse, RDW, etc).

## Initialize Pool
```pas
{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

function NewDatabase(ATenantDatabase: string): TObject;
var
  Conn: TZConnection;
begin
  Conn := TZConnection.Create(nil);
  //..config your connection and open connection, check your TenantDatabse in Ini File for example
  //Conn.Open;
  //Sleep(100); //Uncomment this line to test with delay
  Result := Conn;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FPool := TDBPoolConnection.GetInstance
    .SetMaxPool(100)
    .SetOnCreateDatabaseComponent(NewDatabase);
end;
```
## Get connection from pool
```pas
var
  vDBConnection: IDBConnection;
begin
  vDBConnection := FPool.GetDBConnection;
  if vDBConnection <> nil then
  begin   
    //Using your connection
    //ZQuery.Connection := vDBConnection.DatabaseComponent as TZConnection;
    //ZQuery.SQL.Text := 'select * from dual';
    //ZQuery.Open;
  end  
end;
```
