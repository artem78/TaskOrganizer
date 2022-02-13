unit datamodule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, sqlite3conn, FileUtil, Controls,
  UniqueInstance;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    Icons: TImageList;
    StatsSQLQuery: TSQLQuery;
    StatsDataSource: TDataSource;
    PeriodsDataSource: TDataSource;
    PeriodsSQLQuery: TSQLQuery;
    TasksDataSource: TDataSource;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TasksSQLQuery: TSQLQuery;
    UniqueInstance1: TUniqueInstance;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure SQLite3Connection1Log(Sender: TSQLConnection;
      EventType: TDBEventType; const Msg: String);
    {procedure UniqueInstance1OtherInstance(Sender: TObject;
      ParamCount: Integer; const Parameters: array of String);}
  private
    { private declarations }
  public
    { public declarations }
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
    with SQLQuery1.SQL do
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
    SQLQuery1.ExecSQL;
    SQLQuery1.Clear;
    //SQLTransaction1.Commit;

    // Create periods table
    // ToDo: Думаю, в базе лучше хранить Юлианскую дату вместо паскалеской (с 1900 года)
    with SQLQuery1.SQL do
    begin
      Clear;
      Append('CREATE TABLE IF NOT EXISTS `periods` (');
      Append('    `id`    INTEGER PRIMARY KEY,');
      Append('    `begin` DATETIME,');
      Append('    `end`   DATETIME,');
      Append('    `task_id` INTEGER,');
      Append('    FOREIGN KEY (`task_id`)  REFERENCES `tasks` (`id`) ON DELETE CASCADE');
      Append(');');
    end;
    SQLQuery1.ExecSQL;
    SQLQuery1.Clear;
    //SQLTransaction1.Commit;

    // Create statistics view
    with SQLQuery1.SQL do
    begin
      Clear;
      Append('CREATE VIEW IF NOT EXISTS total_time_per_task AS');
      Append('    SELECT task_id,');
      Append('           tasks.name,');
      Append('           time(sum(ifnull(`end`, strftime(''%J'', ''now'', ''localtime'') - 2415018.5) - `begin`) + 0.5) AS total_time');
      Append('      FROM periods');
      Append('           INNER JOIN');
      Append('           tasks ON periods.task_id = tasks.id');
      Append('     GROUP BY task_id;');
    end;
    SQLQuery1.ExecSQL;
    SQLQuery1.Clear;


    // Commit all changes
    SQLTransaction1.Commit;
  {end;}


  TasksSQLQuery.Active := True;
  PeriodsSQLQuery.Active := True;
  StatsSQLQuery.Active:=True;
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

{procedure TDataModule1.UniqueInstance1OtherInstance(Sender: TObject;
  ParamCount: Integer; const Parameters: array of String);
begin
  //MainForm.Show;
  //MainForm.BringToFront;
  Application.BringToFront;
end; }

end.

