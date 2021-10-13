unit datamodule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, Sqlite3DS, sqlite3conn, FileUtil;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    TasksDataSource: TDataSource;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TasksDataset: TSqlite3Dataset;
    procedure DataModuleCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.lfm}

{ TDataModule1 }

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  // Create database file if not exists
  if not FileExists(TasksDataset.FileName) then
  begin
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
  end;


  TasksDataset.Active := True;
end;

end.

