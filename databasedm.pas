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
    property DoneTasksFilter: Boolean read FDoneTasksFilter write SetDoneTasksFilter;

    procedure ExportDatabase(AFileName: String);
    //procedure SaveDatabaseBackup;
    function SaveDatabaseBackup: String;
  end;

var
  DatabaseDataModule: TDatabaseDataModule;

implementation

uses main, Forms, LazUTF8, NonVisualCtrlsDM, DatabaseVersioning,
  Laz2_DOM, laz2_XMLWrite, Utils, LazFileUtils;

resourcestring
  RSBackupDBFailed = 'Failed to save database to file "%s"';

{$R *.lfm}

// https://wiki.freepascal.org/SQLite#Creating_user_defined_collations
// utf8 case-insensitive compare callback function
function UTF8xCompare_CI(user: pointer; len1: longint; data1: pointer; len2: longint; data2: pointer): longint; cdecl;
var S1, S2: AnsiString;
begin
  SetString(S1, data1, len1);
  SetString(S2, data2, len2);
  Result := UnicodeCompareText(UTF8Decode(S1), UTF8Decode(S2));
end;

{ TDatabaseDataModule }

procedure TDatabaseDataModule.DataModuleCreate(Sender: TObject);
var
  DBVersioning: TDBVersioning;
begin
  // Initializations
  FTasksFilterText := '';
  FDoneTasksFilter := False;

  SQLite3Connection1.CreateCollation('UTF8_CI',1,nil,@UTF8xCompare_CI);


  // Create DB schema
  DBVersioning := TDBVersioning.Create(SQLite3Connection1, SQLTransaction1);
  try
    if DBVersioning.UpgradeNeeded then
    begin
      SaveDatabaseBackup;
      DBVersioning.UpgradeToLatest;
    end;
  finally
    DBVersioning.Free;
  end;


  TasksSQLQuery.Active := True;
  PeriodsSQLQuery.Active := True;
  //StatsSQLQuery.Active:=True;

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
{$IfOpt D+}
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
{$Else}
begin
end;
{$EndIf}

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

procedure TDatabaseDataModule.ExportDatabase(AFileName: String);
  function DateTimeFieldToString(AField: TField): String;
  begin
    if AField.IsNull then
      Result := ''
    else
      Result := DateTimeToISO8601(AField.AsDateTime);
  end;

{$I revision.inc}
var
  XmlDoc: TXMLDocument;
  RootNode, TasksNode, TaskNode, PeriodsNode, PeriodNode, CommentNode: TDOMNode;
  TaskId: Integer = -1;
begin
  XmlDoc := TXMLDocument.Create;

  try
    RootNode := XmlDoc.CreateElement('export');
    XmlDoc.AppendChild(RootNode);
    RootNode:= XmlDoc.DocumentElement;

    CommentNode := XmlDoc.CreateComment(
        Format(' Created with %s version %s on %s ', ['Task Organizer',
          GitRevisionStr, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)
        ])
    );
    RootNode.AppendChild(CommentNode);

    TasksNode := XmlDoc.CreateElement('tasks');
    RootNode.AppendChild(TasksNode);

    CustomSQLQuery.Close;
    CustomSQLQuery.SQL.Text :=
          'SELECT `_tasks`.`id` AS `task_id`, `name`, `description`, `created`, `modified`, `done`, ' +
          '  `p`.`id` AS `period_id`, ' +
          '  `p`.`begin` AS `period_begin`, ' +
          '  `p`.`end` AS `period_end`, ' +
          '  `p`.`is_manually_added` AS `period_is_manually_added` ' +
          'FROM `_tasks` ' +
          'LEFT JOIN `_periods` AS `p` ON `_tasks`.`id` = `p`.`task_id` ' +
          'ORDER BY `_tasks`.`id` ASC';
    CustomSQLQuery.Open;
    CustomSQLQuery.First;
    while not CustomSQLQuery.EOF do
    begin
      if TaskId <> CustomSQLQuery.FieldByName('task_id').AsInteger then
      begin
        TaskId := CustomSQLQuery.FieldByName('task_id').AsInteger;

        TaskNode := XmlDoc.CreateElement('task');
        TDOMElement(TaskNode).SetAttribute('id',       CustomSQLQuery.FieldByName('task_id').AsString);
        TDOMElement(TaskNode).SetAttribute('name',     CustomSQLQuery.FieldByName('name').AsString);
        TDOMElement(TaskNode).SetAttribute('description', CustomSQLQuery.FieldByName('description').AsString);
        TDOMElement(TaskNode).SetAttribute('created',  DateTimeFieldToString(CustomSQLQuery.FieldByName('created')));
        TDOMElement(TaskNode).SetAttribute('modified', DateTimeFieldToString(CustomSQLQuery.FieldByName('modified')));
        TDOMElement(TaskNode).SetAttribute('done',     CustomSQLQuery.FieldByName('done').AsString);
        TasksNode.AppendChild(TaskNode);

        PeriodsNode := XmlDoc.CreateElement('periods');
        TaskNode.AppendChild(PeriodsNode);
      end;

      if not CustomSQLQuery.FieldByName('period_id').IsNull then
      begin
        PeriodNode := XmlDoc.CreateElement('period');
        TDOMElement(PeriodNode).SetAttribute('id',     CustomSQLQuery.FieldByName('period_id').AsString);
        TDOMElement(PeriodNode).SetAttribute('begin',  DateTimeFieldToString(CustomSQLQuery.FieldByName('period_begin')));
        TDOMElement(PeriodNode).SetAttribute('end',    DateTimeFieldToString(CustomSQLQuery.FieldByName('period_end')));
        TDOMElement(PeriodNode).SetAttribute('isManuallyAdded', CustomSQLQuery.FieldByName('period_is_manually_added').AsString);
        PeriodsNode.AppendChild(PeriodNode);
      end;

      CustomSQLQuery.Next;
    end;

    WriteXMLFile(XmlDoc, AFileName);
  finally
    XmlDoc.Free;
  end;
end;

function TDatabaseDataModule.SaveDatabaseBackup: String;
const
  DBBackupsDirName = 'db backups';
var
  SourceFileName, DestFileName, DestDir: String;
  Res: Boolean = False;
  CurrentVersion: Integer;
  DBVersioning: TDBVersioning;
  TasksQueryIsActive, PeriodsQueryIsActive{, StatsQueryIsActive},
    ConnectionIsConnected: Boolean;
begin
  Result := '';

  DBVersioning := TDBVersioning.Create(SQLite3Connection1, SQLTransaction1);
  CurrentVersion := DBVersioning.CurrentVersion;
  DBVersioning.Free;

  SourceFileName := ExpandFileNameUTF8(DatabaseDataModule.SQLite3Connection1.DatabaseName);

  DestDir := AppendPathDelim(ExtractFileDir(Application.ExeName));
  DestDir := AppendPathDelim(DestDir + DBBackupsDirName);

  DestFileName := Format('db backup %s v%d%s', [
      FormatDateTime('yyyy-mm-dd hh-nn-ss', Now),
      CurrentVersion, ExtractFileExt(SourceFileName)
  ]);
  DestFileName := ExpandFileNameUTF8(DestFileName, DestDir);

  ConnectionIsConnected := SQLite3Connection1.Connected;
  TasksQueryIsActive := TasksSQLQuery.Active;
  PeriodsQueryIsActive := PeriodsSQLQuery.Active;
  //StatsQueryIsActive := StatsSQLQuery.Active;
  DatabaseDataModule.SQLite3Connection1.Close(); // Temporarily turn off connection to DB
  try
    Res := CopyFile(SourceFileName, DestFileName, [cffCreateDestDirectory]);
    if not Res then
      Raise Exception.CreateFmt(RSBackupDBFailed, [DestFileName]);
    Result := DestFileName;
  finally
    // Restore connection to DB
    SQLite3Connection1.Connected := ConnectionIsConnected;
    TasksSQLQuery.Active := TasksQueryIsActive;
    PeriodsSQLQuery.Active := PeriodsQueryIsActive;
    //StatsSQLQuery.Active := StatsQueryIsActive;
  end;
end;

end.

