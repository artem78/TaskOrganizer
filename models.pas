unit Models;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, Utils;

type

  { TTableEntry }

  TTableEntry {TModel}= class
    public
      Id: Integer;
  end;


  TTask = class;

  TTasks = specialize TFPGObjectList<TTask>;

  { TTask }

  TTask = class(TTableEntry)
    public
      Name, Description: String;
      Created, Modified: TDateTime;
      Done: Boolean;

      function IsActive: Boolean;
      procedure Start;

      class procedure Stop; static;
      class function HasActive: Boolean; static;
      class function GetActive: TTask; static;
      class function GetById(anId: Integer): TTask; static;
      class function GetLastActive(ACount: Integer; AOnlyUnfinished: Boolean = False): TTasks;
    private
      class procedure RefreshSQLQuery;
  end;

  { TPeriod }

  TPeriod = class(TTableEntry)
    private
      function GetDuration: TDuration;
    public
      BeginTime, EndTime: TDateTime;
      TaskId: Integer;

      property Duration: TDuration read GetDuration;

      function GetTask: TTask;
      function IsActive: Boolean;
      class function GetActive: TPeriod; static;
      class function GetById(anId: Integer): TPeriod; static;
  end;

implementation

uses
  DatabaseDM, DB, StrUtils;

{ TPeriod }

function TPeriod.GetDuration: TDuration;
begin
  if IsActive then
    Result := Now - BeginTime
  else
    Result := EndTime - BeginTime;
end;

function TPeriod.GetTask: TTask;
begin
  Result := TTask.GetById(Self.TaskId);
end;

function TPeriod.IsActive: Boolean;
begin
  Result := EndTime = 0;
end;

class function TPeriod.GetActive: TPeriod;
begin
  Result := Nil;

  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT `id` FROM `periods` WHERE `is_active` == TRUE;';
    Open;
    if RecordCount > 0 then
    begin
      First;
      Result := TPeriod.GetById(FieldByName('id').AsInteger);
    end;
  end;
end;

class function TPeriod.GetById(anId: Integer): TPeriod;
begin
  Result := Nil;

  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT * FROM `periods` WHERE `id` == :id;';
    ParamByName('id').AsInteger := anId;
    Open;
    if RecordCount > 0 then
    begin
      First;
      Result := TPeriod.Create;
      Result.Id := FieldByName('id').AsInteger;
      Result.BeginTime := FieldByName('begin').AsDateTime;
      //if not FieldByName('end').IsNull then
      //try
      if FieldByName('end').DataType = ftDateTime then
        Result.EndTime := FieldByName('end').AsDateTime
      else
      //except
        Result.EndTime := 0;
      //end;
      Result.TaskId := FieldByName('task_id').AsInteger;
    end;
  end;
end;

{ TTask }

function TTask.IsActive: Boolean;
begin
  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT COUNT(*) AS `cnt` FROM `periods` WHERE `is_active` == TRUE AND `task_id` == :task_id;';
    ParamByName('task_id').AsInteger := Self.Id;
    Open;
    First;
    Result := FieldByName('cnt').AsInteger > 0;
  end;
end;

procedure TTask.Start;
begin
  with DatabaseDataModule.PeriodsSQLQuery do
  begin
    // ToDo: Check if no unfinished periods
    Append;
    FieldByName('task_id').AsInteger := Self.Id;
    FieldByName('begin').AsDateTime := Now;
    Post;
    ApplyUpdates;
  end;

  DatabaseDataModule.SQLTransaction1.CommitRetaining;

  RefreshSQLQuery;
end;

class procedure TTask.Stop;
begin
  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'UPDATE `_periods` SET `end`=:end WHERE /*`is_active` = TRUE*/ `end` IS NULL';
    // ToDo: Check if only one result
    ParamByName('end').AsDateTime := Now;
    ExecSQL;
  end;

  DatabaseDataModule.SQLTransaction1.CommitRetaining;

  //PeriodsSQLQuery.Refresh;

  //RefreshStartStopBtnsVisibility;

  RefreshSQLQuery;
end;

class function TTask.HasActive: Boolean;
begin
  Result:=False;

  //if (DatabaseDataModule <> nil) and (DataModule1.CustomSQLQuery <> nil) then
  //begin
    with DatabaseDataModule.CustomSQLQuery do
    begin
      Close;
      SQL.Text := 'SELECT COUNT(*) AS `cnt` FROM `periods` WHERE `is_active` = TRUE;';
      Open;
      First;
      Result := FieldByName('cnt').AsInteger > 0;
    end;
  //end;
end;

class function TTask.GetActive: TTask;
begin
  Result := Nil;

  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT `task_id` FROM `periods` WHERE `is_active` == TRUE;';
    Open;
    if RecordCount > 0 then
    begin
      First;
      Result := TTask.GetById(FieldByName('task_id').AsInteger);
    end;
  end;
end;

class function TTask.GetById(anId: Integer): TTask;
begin
  Result := Nil;

  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT * FROM `tasks` WHERE `id` == :id;';
    ParamByName('id').AsInteger := anId;
    Open;
    if RecordCount > 0 then
    begin
      First;
      Result := TTask.Create;
      Result.Id := FieldByName('id').AsInteger;
      Result.Name := FieldByName('name').AsString;
      Result.Description := FieldByName('description').AsString;
      Result.Created := FieldByName('created').AsDateTime;
      Result.Modified := FieldByName('modified').AsDateTime;
      Result.Done := FieldByName('done').AsBoolean;
    end;
  end;
end;

class function TTask.GetLastActive(ACount: Integer; AOnlyUnfinished: Boolean = False): TTasks;
var
  Task: TTask;
begin
  Result := TTasks.Create();

  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT `tasks`.*, MAX(`end`) AS `last_active` FROM `periods` '
                 + '/*LEFT*/ INNER JOIN `tasks` ON `periods`.`task_id` = `tasks`.`id` '
                 + IfThen(AOnlyUnfinished, 'where done == FALSE ')
                 + 'GROUP BY `task_id` '
                 + 'ORDER BY `last_active` DESC '
                 + 'LIMIT :limit ';
    ParamByName('limit').AsInteger := ACount;
    Open;
    First;
    while not EOF do
    begin
      Task := TTask.Create;
      // ToDo: Code duplicate
      with Task do
      begin
        Id := FieldByName('id').AsInteger;
        Name := FieldByName('name').AsString;
        Description := FieldByName('description').AsString;
        Created := FieldByName('created').AsDateTime;
        Modified := FieldByName('modified').AsDateTime;
        Done := FieldByName('done').AsBoolean;
      end;
      //////////////////
      Result.Add(Task);
      Next;
    end;
    Close;
  end;
end;

class procedure TTask.RefreshSQLQuery;
var
  r: Integer;
begin
  with DatabaseDataModule.TasksSQLQuery do
  begin
    r := RecNo;
    Refresh;
    RecNo := r; // Restore previous selected row
  end;
end;

end.

