unit tasks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ComCtrls, DBGrids, taskedit, datamodule, Dialogs;

type

  { TTasksFrame }

  TTasksFrame = class(TFrame)
    TasksDBGrid: TDBGrid;
    ToolBar1: TToolBar;
    AddToolButton: TToolButton;
    RemoveToolButton: TToolButton;
    EditToolButton: TToolButton;
    SeparatorToolButton: TToolButton;
    StartTrackingToolButton: TToolButton;
    StopTrackingToolButton: TToolButton;
    ShowTimeToolButton: TToolButton;
    procedure AddToolButtonClick(Sender: TObject);
    procedure EditToolButtonClick(Sender: TObject);
    procedure RemoveToolButtonClick(Sender: TObject);
    procedure ShowTimeToolButtonClick(Sender: TObject);
    procedure StartTrackingToolButtonClick(Sender: TObject);
    procedure StopTrackingToolButtonClick(Sender: TObject);
  private
    function HasActiveTask: Boolean;
    //procedure RefreshStartStopBtnsVisibility;
  public
    //constructor Create(AOwner: TComponent); override;
    procedure RefreshStartStopBtnsVisibility;
  end;

implementation

uses
  Variants;

{$R *.lfm}

{ TTasksFrame }

procedure TTasksFrame.AddToolButtonClick(Sender: TObject);
begin
  DataModule1.TasksSQLQuery.Append;
  if TaskEditForm.ShowModal = mrOK then
  begin
    DataModule1.TasksSQLQuery.FieldByName('created').AsDateTime := Now;
    DataModule1.TasksSQLQuery.Post;
    DataModule1.TasksSQLQuery.ApplyUpdates;
    DataModule1.SQLTransaction1.CommitRetaining;
  end
  else
    DataModule1.TasksSQLQuery.Cancel;
end;

procedure TTasksFrame.EditToolButtonClick(Sender: TObject);
begin
  if DataModule1.TasksSQLQuery.IsEmpty then
    Exit;

  DataModule1.TasksSQLQuery.Edit;
  if TaskEditForm.ShowModal = mrOK then
  begin
    DataModule1.TasksSQLQuery.FieldByName('modified').AsDateTime := Now;
    DataModule1.TasksSQLQuery.Post;
    DataModule1.TasksSQLQuery.ApplyUpdates;
    DataModule1.SQLTransaction1.CommitRetaining;
  end
  else
    DataModule1.TasksSQLQuery.Cancel;
end;

procedure TTasksFrame.RemoveToolButtonClick(Sender: TObject);
var
  Msg: String;
begin
  if DataModule1.TasksSQLQuery.IsEmpty then
    Exit;

  Msg := Format('Are you sure to delete task "%s"?', [DataModule1.TasksSQLQuery.FieldByName('name').AsString]);
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DataModule1.TasksSQLQuery.Delete;
    DataModule1.TasksSQLQuery.ApplyUpdates;
    DataModule1.SQLTransaction1.CommitRetaining;
  end;
end;

procedure TTasksFrame.ShowTimeToolButtonClick(Sender: TObject);
var
  TotalTime: TTime;
  Period: TTime;
begin
  TotalTime:=EncodeTime(0,0,0,0);

  with DataModule1.CustomSQLQuery do
  begin
    Close();
    SQL.Text := 'select begin, end from periods where task_id = ' + IntToStr(DataModule1.TasksSQLQuery.FieldByName('id').AsInteger) + ';';
    Open();

    while not EOF do
    begin
      if FieldByName('end').IsNull then
        Period := Now - FieldByName('begin').AsDateTime
      else
        Period := FieldByName('end').AsDateTime - FieldByName('begin').AsDateTime;

      TotalTime:=TotalTime+Period;
      Next;
    end;
  end;

  ShowMessage(TimeToStr(TotalTime));
end;

procedure TTasksFrame.StartTrackingToolButtonClick(Sender: TObject);
begin
  with DataModule1.PeriodsSQLQuery do
  begin
    // ToDo: Check if no unfinished periods
    Append;
    FieldByName('task_id').AsInteger
      := DataModule1.TasksSQLQuery.FieldByName('id').AsInteger;
    FieldByName('begin').AsDateTime := Now - 2415018.5;
    Post;
    ApplyUpdates;
    DataModule1.SQLTransaction1.CommitRetaining;
  end;

  RefreshStartStopBtnsVisibility;
end;

procedure TTasksFrame.StopTrackingToolButtonClick(Sender: TObject);
begin
  with DataModule1.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'update periods set end=:end WHERE `is_active` = TRUE';
    // ToDo: Check if only one result
    ParamByName('end').AsDateTime:=now - 2415018.5;
    ExecSQL;
    DataModule1.SQLTransaction1.CommitRetaining;
    Close;
  end;
  DataModule1.PeriodsSQLQuery.Refresh;

  RefreshStartStopBtnsVisibility;
end;

function TTasksFrame.HasActiveTask: Boolean;
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

procedure TTasksFrame.RefreshStartStopBtnsVisibility;
var
  IsActive: Boolean;
begin
  IsActive := HasActiveTask;
  StartTrackingToolButton.Enabled:=not IsActive;
  StopTrackingToolButton.Enabled:=IsActive;
end;

{constructor TTasksFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  RefreshStartStopBtnsVisibility;
end;  }

end.

