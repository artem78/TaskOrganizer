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
    procedure PeriodsDataSourceDataChange(Sender: TObject; Field: TField);
    procedure SQLite3Connection1Log(Sender: TSQLConnection;
      EventType: TDBEventType; const Msg: String);
    procedure TasksDataSourceDataChange(Sender: TObject; Field: TField);
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

uses main, Forms, LazUTF8, NonVisualCtrlsDM, Models, DateUtils, SQLite3Dyn,
  ctypes, DatabaseVersioning, Laz2_DOM, laz2_XMLWrite, LazFileUtils;

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

// https://forum.lazarus.freepascal.org/index.php/topic,34259.msg224029.html#msg224029
procedure UTF8xLower(ctx: psqlite3_context; N: cint; V: ppsqlite3_value); cdecl;
var S: AnsiString;
begin
  SetString(S, sqlite3_value_text(V[0]), sqlite3_value_bytes(V[0]));
  S := UTF8Encode(AnsiLowerCase(UTF8Decode(S)));
  sqlite3_result_text(ctx, PAnsiChar(S), Length(S), sqlite3_destructor_type(SQLITE_TRANSIENT));
end;

// Case-insensitive LIKE function working with non-ASCII characters
procedure UTF8xLike(ctx: psqlite3_context; N: cint; V: ppsqlite3_value); cdecl;
var Y1,X1,Z1: AnsiString;
    Y2,X2: UTF8String;
    Z2: {cint} cuint = 0;
begin
  Assert((N = 2) or (N = 3), 'Wrong amount of arguments passed to UTF8xLike()');

  // like(X,Y) = Y LIKE X
  // like(X,Y,Z) = Y LIKE X ESCAPE Z
  X1 := sqlite3_value_text(V[0]);
  Y1 := sqlite3_value_text(V[1]);
  X2 := UTF8Encode(AnsiLowerCase(UTF8Decode(X1)));
  Y2 := UTF8Encode(AnsiLowerCase(UTF8Decode(Y1)));

  if N = 3 then // With ESCAPE argument
  begin
    Z1 := sqlite3_value_text(V[2]);
    if not Z1.IsEmpty then
      Z2 := Ord(Z1[1]);
  end;

  sqlite3_result_int(ctx, ord(sqlite3_strlike(PAnsiChar(X2), PAnsiChar(Y2), Z2)=0));
end;

{ TDatabaseDataModule }

procedure TDatabaseDataModule.DataModuleCreate(Sender: TObject);
var
  DBVersioning: TDBVersioning;
begin
  // Initializations
  FTasksFilterText := '';
  FDoneTasksFilter := False;

  // Turn on Transaction and Connection if disabled
  SQLite3Connection1.Connected := True;
  SQLTransaction1.Active := True;

  SQLite3Connection1.CreateCollation('UTF8_CI',1,nil,@UTF8xCompare_CI);

  sqlite3_create_function(SQLite3Connection1.Handle, 'lower', 1, SQLITE_UTF8 or SQLITE_DETERMINISTIC, nil, @UTF8xLower, nil, nil);
  sqlite3_create_function(SQLite3Connection1.Handle, 'like', 2, SQLITE_UTF8 or SQLITE_DETERMINISTIC, nil, @UTF8xLike, nil, nil);
  sqlite3_create_function(SQLite3Connection1.Handle, 'like', 3, SQLITE_UTF8 or SQLITE_DETERMINISTIC, nil, @UTF8xLike, nil, nil);



  // Create DB schema
  DBVersioning := TDBVersioning.Create(SQLite3Connection1, SQLTransaction1);
  try
    if DBVersioning.UpgradeNeeded then
    begin
      if DBVersioning.{IsInitialized}CurrentVersion > 0 then
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

procedure TDatabaseDataModule.PeriodsDataSourceDataChange(Sender: TObject;
  Field: TField);
var
  Done, Active: Boolean;
begin
  if Assigned(NonVisualCtrlsDataModule) then
  begin
    Active := PeriodsSQLQuery.FieldByName('is_active').AsBoolean;
    NonVisualCtrlsDataModule.DeletePeriodAction.Enabled := not Active;
    NonVisualCtrlsDataModule.EditPeriodAction.Enabled := not Active;
  end;
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
  Done, Active: Boolean;
begin
  if Assigned(NonVisualCtrlsDataModule) then
  begin
    Done := TasksSQLQuery.FieldByName('done').AsBoolean;
    NonVisualCtrlsDataModule.MarkTaskAsDoneAction.{Enabled}Visible := not Done;
    NonVisualCtrlsDataModule.UnMarkTaskAsDoneAction.{Enabled}Visible := Done;

    Active := TasksSQLQuery.FieldByName('is_active').AsBoolean;
    NonVisualCtrlsDataModule.DeleteTaskAction.Enabled := not Active;

    NonVisualCtrlsDataModule.StartTimeTrackingAction.Enabled := (not Done) and (not TTask.HasActive);
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
  function PrepareLikeExpr(const AStr: String): String;
  begin
    Result := AStr;

    Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
    Result := StringReplace(Result, '%', '\%', [rfReplaceAll]);
    Result := StringReplace(Result, '_', '\_', [rfReplaceAll]);

    Result := QuotedStr('%' + Result + '%') + ' ESCAPE ''\''';
  end;

var
  Filters: TStringList;
  FilterSQL: String;
begin
  Filters := TStringList.Create;
  try
    if not FDoneTasksFilter then
      Filters.Append('`done` IS NOT TRUE');

    if (not FTasksFilterText.IsEmpty) then
      Filters.Append(Format('((`tasks`.`name` LIKE %0:s) OR (`tasks`.`description` LIKE %0:s))', [PrepareLikeExpr(FTasksFilterText)]));



    if (Filters.Count > 0) then
    begin // Enable filtering
      FilterSQL := ''.Join(' AND ', Filters.ToStringArray);

      TasksSQLQuery.ServerFiltered := False;
      TasksSQLQuery.ServerFilter := FilterSQL;
      TasksSQLQuery.ServerFiltered := True;
    end
    else // Disable filtering
    begin
      TasksSQLQuery.ServerFiltered := False;
    end;
    //TasksSQLQuery.Refresh;
  finally
    Filters.Free;
  end;
end;

procedure TDatabaseDataModule.ExportDatabase(AFileName: String);
  function DateTimeFieldToString(AField: TField): String;
  begin
    if AField.IsNull then
      Result := ''
    else
      Result := DateToISO8601(AField.AsDateTime, False);
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

  DestFileName := Format('database_Backup_%s_v%d%s', [
      FormatDateTime('yyyy-mm-dd_hh-nn-ss', Now),
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

