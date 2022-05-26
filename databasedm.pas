unit DatabaseDM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, sqlite3conn, FileUtil, Controls, ExtCtrls;

type

  { TDatabaseDataModule }

  TDatabaseDataModule = class(TDataModule)
    PeriodsSQLQueryBegin: TDateTimeField;
    PeriodsSQLQueryDuration: TFloatField;
    PeriodsSQLQueryEnd: TDateTimeField;
    PeriodsSQLQueryId: TAutoIncField;
    PeriodsSQLQueryIsActive: TBooleanField;
    PeriodsSQLQueryIsManuallyAdded: TBooleanField;
    PeriodsSQLQueryTaskId: TLongintField;
    StatsSQLQuery: TSQLQuery;
    StatsDataSource: TDataSource;
    PeriodsDataSource: TDataSource;
    PeriodsSQLQuery: TSQLQuery;
    TasksDataSource: TDataSource;
    SQLite3Connection1: TSQLite3Connection;
    CustomSQLQuery: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TasksSQLQuery: TSQLQuery;
    TasksSQLQueryCreated: TDateTimeField;
    TasksSQLQueryDescription: TStringField;
    TasksSQLQueryDone: TBooleanField;
    TasksSQLQueryId: TAutoIncField;
    TasksSQLQueryIsActive: TBooleanField;
    TasksSQLQueryModified: TDateTimeField;
    TasksSQLQueryName: TStringField;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure SQLite3Connection1Log(Sender: TSQLConnection;
      EventType: TDBEventType; const Msg: String);
    procedure TasksDataSourceDataChange(Sender: TObject; Field: TField);
    procedure TasksSQLQueryFilterRecord(DataSet: TDataSet; var Accept: Boolean);
  private
    FTasksFilterText: String;
    FDoneTasksFilter: Boolean;

    procedure SetTasksFilterText(AText: String);
    procedure SetDoneTasksFilter(AVal: Boolean);

    procedure UpdateFilters;
  public
    property TasksFilterText: String write SetTasksFilterText;
    property DoneTasksFilter: Boolean write SetDoneTasksFilter;
  end;

var
  DatabaseDataModule: TDatabaseDataModule;

implementation

uses main{, Forms}, LazUTF8, NonVisualCtrlsDM, DatabaseVersioning;

{$R *.lfm}

{ TDatabaseDataModule }

procedure TDatabaseDataModule.DataModuleCreate(Sender: TObject);
var
  DBVersioning: TDBVersioning;
begin
  // Initializations
  FTasksFilterText := '';
  FDoneTasksFilter := False;


  // Create DB schema
  // ToDo: Думаю, в базе лучше хранить Юлианскую дату вместо паскалевской (с 1900 года)
  DBVersioning := TDBVersioning.Create(SQLite3Connection1, SQLTransaction1);
  try
    DBVersioning.UpgradeToLatest;
  finally
    DBVersioning.Free;
  end;


  TasksSQLQuery.Active := True;
  PeriodsSQLQuery.Active := True;
  StatsSQLQuery.Active:=True;

  {// Tray icon
  TrayIcon.Icon.Assign(MainForm.Icon);}

  UpdateFilters;
end;

procedure TDatabaseDataModule.DataModuleDestroy(Sender: TObject);
begin
  // Save all changes to DB on exit
  DatabaseDataModule.SQLTransaction1.CommitRetaining;
end;

procedure TDatabaseDataModule.SQLite3Connection1Log(Sender: TSQLConnection;
  EventType: TDBEventType; const Msg: String);
var
  Source: string;
begin
  case EventType of
    detCustom:   Source:='Custom';
    detPrepare:  Source:='Prepare';
    detExecute:  Source:='Execute';
    detFetch:    Source:='Fetch';
    detCommit:   Source:='Commit';
    detRollBack: Source:='Rollback';
    else Source:='Unknown';
  end;

  main.MainForm.LogsMemo.Append(Format('[%s] <%s> %s', [TimeToStr(Now), Source, Msg]));
end;

procedure TDatabaseDataModule.TasksDataSourceDataChange(Sender: TObject;
  Field: TField);
var
  Done: Boolean;
begin
  if Assigned(NonVisualCtrlsDataModule) then
  begin
    Done := TasksSQLQuery.FieldByName('done').AsBoolean;
    NonVisualCtrlsDataModule.MarkTaskAsDoneAction.{Enabled}Visible := not Done;
    NonVisualCtrlsDataModule.UnMarkTaskAsDoneAction.{Enabled}Visible := Done;
  end;
end;

procedure TDatabaseDataModule.TasksSQLQueryFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
var
  Name_, Descr, Search: String;
begin
  Accept := True;

  // Filter done tasks
  if not FDoneTasksFilter then
  begin
     Accept := not DataSet.FieldByName('done').AsBoolean;
  end;

  // Search by text
  if Accept and (FTasksFilterText <> '') then
  begin
    Name_ := UTF8LowerCase(DataSet.FieldByName('name').AsString);
    Descr := UTF8LowerCase(DataSet.FieldByName('description').AsString);
    Search:= UTF8LowerCase(FTasksFilterText);

    Accept := (UTF8Pos(Search, Name_) <> 0) or (UTF8Pos(Search, Descr) <> 0);
  end;
end;

procedure TDatabaseDataModule.SetTasksFilterText(AText: String);
begin
  FTasksFilterText := AText;
  UpdateFilters;
end;

procedure TDatabaseDataModule.SetDoneTasksFilter(AVal: Boolean);
begin
  FDoneTasksFilter := AVal;
  UpdateFilters;
end;

procedure TDatabaseDataModule.UpdateFilters;
begin
  if (FTasksFilterText <> '') or (not FDoneTasksFilter) then
  begin // Enable filtering
    TasksSQLQuery.Filtered := False;
    TasksSQLQuery.Filtered := True;
  end
  else // Disable filtering
  begin
    TasksSQLQuery.Filtered := False;
  end;
  //TasksSQLQuery.Refresh;
end;

end.

