unit TestConnectionFactory;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit 
  being tested.

}

interface

uses
  TestFramework, Core.Interfaces, Generics.Collections, SysUtils,
  Core.ConnectionFactory;

type
  // Test methods for class TConnectionFactory

  TestTConnectionFactory = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGetInstance;
    procedure TestGetInstance1;
    procedure TestGetInstanceFromFilename;
  end;

implementation

uses
  SQLiteTable3
  ,Adapters.SQLite
  ,uModels
  ;

procedure TestTConnectionFactory.SetUp;
begin
//
end;

procedure TestTConnectionFactory.TearDown;
begin
//
end;

procedure TestTConnectionFactory.TestGetInstance;
var
  ReturnValue: IDBConnection;
  AConcreteConnection: TObject;
begin
  AConcreteConnection := TSQLiteDatabase.Create(':memory:');
  try
    ReturnValue := nil;
    CheckFalse(Assigned(ReturnValue));
    ReturnValue := TConnectionFactory.GetInstance(dtSQLite, AConcreteConnection);
    CheckTrue(Assigned(ReturnValue));
  finally
    AConcreteConnection.Free;
  end;
end;

const
  JSON_SQLITE = '{"SQLiteTable3.TSQLiteDatabase": { "Filename": ":memory:" } }';

procedure TestTConnectionFactory.TestGetInstance1;
var
  ReturnValue: IDBConnection;
begin
  ReturnValue := nil;
  ReturnValue := TConnectionFactory.GetInstance(dtSQLite, JSON_SQLITE);
  CheckTrue(Assigned(ReturnValue));
  CheckEqualsString('SQLite3', ReturnValue.GetDriverName);
  CheckTrue(ReturnValue.IsConnected);
end;

const
  FILE_JSON = 'ConnectionFactory_Sqlite.json';

procedure TestTConnectionFactory.TestGetInstanceFromFilename;
var
  ReturnValue: IDBConnection;
  sDir: string;
begin
  sDir := IncludeTrailingPathDelimiter(ExtractFileDir(PictureFilename));
  ReturnValue := TConnectionFactory.GetInstanceFromFilename(dtSQLite, sDir + FILE_JSON);
  CheckTrue(Assigned(ReturnValue));
  CheckEqualsString('SQLite3', ReturnValue.GetDriverName);
  CheckTrue(ReturnValue.IsConnected);
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestTConnectionFactory.Suite);
end.

