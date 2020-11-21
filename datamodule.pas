unit datamodule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, Sqlite3DS, sqlite3conn, FileUtil;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    DataSource1: TDataSource;
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
  //TasksDataset.Active := True;
end;

end.

