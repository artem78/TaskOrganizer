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

uses main{, Forms}, LazUTF8;

{$R *.lfm}

{ TDatabaseDataModule }

procedure TDatabaseDataModule.DataModuleCreate(Sender: TObject);
begin
  // Initializations
  FTasksFilterText := '';
  FDoneTasksFilter := False;


  {// Create database file if not exists
  if not FileExists(TasksDataset.FileName) then
  begin}
    // Create tasks table
    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE TABLE IF NOT EXISTS `_tasks` (');
      Append('      `id`          INTEGER PRIMARY KEY,');
      Append('      `name`        VARCHAR,');
      Append('      `description` VARCHAR,');
      Append('      `created`     DATETIME, ');
      Append('      `modified`    DATETIME,');
      Append('      `done`        BOOLEAN DEFAULT (FALSE) NOT NULL ON CONFLICT REPLACE');
      Append(');');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;
    //SQLTransaction1.Commit;

    // Create periods table
    // ToDo: Думаю, в базе лучше хранить Юлианскую дату вместо паскалеской (с 1900 года)
    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE TABLE IF NOT EXISTS `_periods` (');
      Append('    `id`    INTEGER PRIMARY KEY,');
      Append('    `begin` DATETIME,');
      Append('    `end`   DATETIME,');
      Append('    `task_id` INTEGER,');
      Append('    `is_manually_added` BOOLEAN DEFAULT (FALSE) NOT NULL ON CONFLICT REPLACE,');
      Append('    FOREIGN KEY (`task_id`)  REFERENCES `tasks` (`id`) ON DELETE CASCADE');
      Append(');');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;
    //SQLTransaction1.Commit;

    
    // Create views
    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE VIEW IF NOT EXISTS `tasks` AS');
      Append('  SELECT `_tasks`.*, IFNULL(`p`.`is_active`, FALSE) as `is_active`');
      Append('  FROM `_tasks`');
      Append('  LEFT JOIN');
      Append('      (');
      Append('          SELECT `task_id`, `is_active`');
      Append('          FROM `periods`');
      Append('          WHERE `is_active`');
      Append('      ) AS `p`');
      Append('      ON `p`.`task_id` = `_tasks`.`id`;');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;

    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE VIEW IF NOT EXISTS `periods` AS');
      Append('	SELECT');
      Append('		*,');
      Append('		`end` - `begin` as `duration`');
      Append('	FROM');
      Append('		(');
      Append('		SELECT');
      Append('			`id`,');
      Append('			`begin`,');
      Append('			IFNULL(`end`, JULIANDAY(''now'', ''localtime'') - 2415018.5) as `end`,');
      Append('			`task_id`,');
      Append('			IIF(`end` IS NULL, TRUE, FALSE) as `is_active`,');
      Append('                  `is_manually_added`');
      Append('		FROM `_periods`');
      Append('		)');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;

    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE VIEW IF NOT EXISTS `duration_per_task` AS');
      Append('    SELECT task_id,');
      Append('           tasks.name,');
      Append('           time(sum(ifnull(`end`, strftime(''%J'', ''now'', ''localtime'') - 2415018.5) - `begin`) + 0.5) AS total_time');
      Append('      FROM periods');
      Append('           INNER JOIN');
      Append('           tasks ON periods.task_id = tasks.id');
      Append('     GROUP BY task_id;');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;

    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE VIEW IF NOT EXISTS `duration_per_day` AS');
      Append('WITH RECURSIVE dates AS (');
      Append('        SELECT DATE(MIN([begin] + 2415018.5) ) daydate,');
      Append('               DATE(MIN([begin] + 2415018.5), ''+1 DAY'') nextdate,');
      Append('               DATE(MAX([end] + 2415018.5) ) enddate');
      Append('          FROM periods');
      Append('        UNION ALL');
      Append('        SELECT nextdate,');
      Append('               DATE(nextdate, ''+1 DAY''),');
      Append('               enddate');
      Append('          FROM dates');
      Append('         WHERE daydate < enddate');
      Append('    )');
      Append('    SELECT dates.daydate AS `day`,');
      Append('           SUM(strftime(''%s'', MIN(dates.nextdate, DATETIME(periods.[end] + 2415018.5) ) ) - strftime(''%s'', MAX(dates.daydate, DATETIME(periods.[begin] + 2415018.5) ) ) ) / (24.0 * 60 * 60) AS `duration`');
      Append('      FROM dates');
      Append('           JOIN');
      Append('           periods ON dates.daydate < DATETIME(periods.[end] + 2415018.5) AND ');
      Append('                      DATETIME(periods.[begin] + 2415018.5) < dates.nextdate');
      Append('     GROUP BY dates.daydate;');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;


    // Commit all changes
    SQLTransaction1.Commit;
  {end;}


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

