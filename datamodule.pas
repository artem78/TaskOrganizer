unit datamodule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, Sqlite3DS, sqlite3conn, FileUtil,
  UniqueInstance;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    StatsSQLQuery: TSQLQuery;
    StatsDataSource: TDataSource;
    PeriodsDataSource: TDataSource;
    PeriodsDataset: TSqlite3Dataset;
    TasksDataSource: TDataSource;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TasksDataset: TSqlite3Dataset;
    UniqueInstance1: TUniqueInstance;
    procedure DataModuleCreate(Sender: TObject);
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
    with TasksDataset do
    begin
      //Close;
      if not TableExists then
      begin
        FieldDefs.Clear;
        FieldDefs.Add('id',          ftAutoInc);
        FieldDefs.Add('name',        ftString);
        FieldDefs.Add('description', ftString);
        FieldDefs.Add('created',     ftDateTime);
        FieldDefs.Add('modified',    ftDateTime);
        CreateTable;
      end;
      //Open;
    end;

    // Create periods table
    with PeriodsDataset do
    begin
      //Close;
      if not TableExists then
      begin
        FieldDefs.Clear;
        FieldDefs.Add('id',      ftAutoInc);
        FieldDefs.Add('begin',   ftDateTime);
        FieldDefs.Add('end',     ftDateTime);
        FieldDefs.Add('task_id', ftInteger);
        CreateTable;
      end;
      //Open;
    end;
  {end;}


  TasksDataset.Active := True;
  PeriodsDataset.Active := True;
  StatsSQLQuery.Active:=True;
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

