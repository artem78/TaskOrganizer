unit datamodule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, sqlite3conn, FileUtil, Controls, ExtCtrls,
  ActnList, UniqueInstance;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    StopTimeTrackingAction: TAction;
    StartTimeTrackingAction: TAction;
    ActionList: TActionList;
    Icons: TImageList;
    StatsSQLQuery: TSQLQuery;
    StatsDataSource: TDataSource;
    PeriodsDataSource: TDataSource;
    PeriodsSQLQuery: TSQLQuery;
    TasksDataSource: TDataSource;
    SQLite3Connection1: TSQLite3Connection;
    CustomSQLQuery: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TasksSQLQuery: TSQLQuery;
    TrayIcon: TTrayIcon;
    UniqueInstance1: TUniqueInstance;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure SQLite3Connection1Log(Sender: TSQLConnection;
      EventType: TDBEventType; const Msg: String);
    procedure StartTimeTrackingActionExecute(Sender: TObject);
    procedure StopTimeTrackingActionExecute(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    {procedure UniqueInstance1OtherInstance(Sender: TObject;
      ParamCount: Integer; const Parameters: array of String);}
  private
    { private declarations }
  public
    function HasActiveTask: Boolean;
    procedure RefreshStartStopBtnsVisibility;
  end;

var
  DataModule1: TDataModule1;

implementation

uses main{, Forms};

{$R *.lfm}

{ TDataModule1 }

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  {// Create database file if not exists
  if not FileExists(TasksDataset.FileName) then
  begin}
    // Create tasks table
    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE TABLE IF NOT EXISTS `tasks` (');
      Append('      `id`          INTEGER PRIMARY KEY,');
      Append('      `name`        VARCHAR (255),');
      Append('      `description` VARCHAR (255),');
      Append('      `created`     DATETIME, ');
      Append('      `modified`    DATETIME');
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
      Append('			IIF(`end` IS NULL, TRUE, FALSE) as `is_active`');
      Append('		FROM `_periods`');
      Append('		)');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;

    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE TRIGGER IF NOT EXISTS delete_period_trigger');
      Append('    INSTEAD OF DELETE');
      Append('            ON periods');
      Append('BEGIN');
      Append('    DELETE FROM _periods');
      Append('          WHERE id = OLD.id;');
      Append('END;');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;

    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE TRIGGER IF NOT EXISTS insert_period_trigger');
      Append('    INSTEAD OF INSERT');
      Append('            ON periods');
      Append('BEGIN');
      Append('    INSERT INTO _periods (');
      Append('                             [begin],');
      Append('                             [end],');
      Append('                             task_id');
      Append('                         )');
      Append('                         VALUES (');
      Append('                             NEW.[begin],');
      Append('                             NEW.[end],');
      Append('                             NEW.task_id');
      Append('                         );');
      Append('END;');
    end;
    CustomSQLQuery.ExecSQL;
    CustomSQLQuery.Clear;

    with CustomSQLQuery.SQL do
    begin
      Clear;
      Append('CREATE TRIGGER IF NOT EXISTS update_period_trigger');
      Append('    INSTEAD OF UPDATE');
      Append('            ON periods');
      Append('BEGIN');
      Append('    UPDATE _periods');
      Append('       SET [begin] = NEW.[begin],');
      Append('           [end] = NEW.[end],');
      Append('           task_id = NEW.task_id');
      Append('     WHERE id = NEW.id;');
      Append('END;');
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
end;

procedure TDataModule1.DataModuleDestroy(Sender: TObject);
begin
  // Save all changes to DB on exit
  DataModule1.SQLTransaction1.CommitRetaining;
end;

procedure TDataModule1.SQLite3Connection1Log(Sender: TSQLConnection;
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

procedure TDataModule1.StartTimeTrackingActionExecute(Sender: TObject);
begin
  with PeriodsSQLQuery do
  begin
    // ToDo: Check if no unfinished periods
    Append;
    FieldByName('task_id').AsInteger
      := DataModule1.TasksSQLQuery.FieldByName('id').AsInteger;
    FieldByName('begin').AsDateTime := Now - 2415018.5;
    Post;
    ApplyUpdates;
    SQLTransaction1.CommitRetaining;
  end;

  RefreshStartStopBtnsVisibility;
end;

procedure TDataModule1.StopTimeTrackingActionExecute(Sender: TObject);
begin
  with CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'update periods set end=:end WHERE `is_active` = TRUE';
    // ToDo: Check if only one result
    ParamByName('end').AsDateTime:=now - 2415018.5;
    ExecSQL;
    SQLTransaction1.CommitRetaining;
    Close;
  end;
  PeriodsSQLQuery.Refresh;

  RefreshStartStopBtnsVisibility;
end;

procedure TDataModule1.TrayIconDblClick(Sender: TObject);
begin
  MainForm.RestoreFromTray;
end;

function TDataModule1.HasActiveTask: Boolean;
begin
  Result:=False;

  if (DataModule1 <> nil) and (DataModule1.CustomSQLQuery <> nil) then
  begin
    with DataModule1.CustomSQLQuery do
    begin
      Close;
      SQL.Text:='select count(*) as cnt from `periods` where `is_active` = TRUE;';
      Open;
      First;
      Result:=FieldByName('cnt').AsInteger > 0;
      Close;
    end;
  end;
end;

procedure TDataModule1.RefreshStartStopBtnsVisibility;
var
  IsActive: Boolean;
begin
  IsActive := HasActiveTask;
  StartTimeTrackingAction.Enabled:=not IsActive;
  StopTimeTrackingAction.Enabled:=IsActive;
end;

{procedure TDataModule1.UniqueInstance1OtherInstance(Sender: TObject;
  ParamCount: Integer; const Parameters: array of String);
begin
  //MainForm.Show;
  //MainForm.BringToFront;
  Application.BringToFront;
end; }

end.

