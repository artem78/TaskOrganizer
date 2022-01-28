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
    { private declarations }
  public
    { public declarations }
  end;

implementation

uses
  Variants;

{$R *.lfm}

{ TTasksFrame }

procedure TTasksFrame.AddToolButtonClick(Sender: TObject);
begin
  DataModule1.TasksDataset.Append;
  if TaskEditForm.ShowModal = mrOK then
  begin
    DataModule1.TasksDataset.FieldByName('created').AsDateTime := Now;
    DataModule1.TasksDataset.Post;
    DataModule1.TasksDataset.ApplyUpdates;
  end
  else
    DataModule1.TasksDataset.Cancel;
end;

procedure TTasksFrame.EditToolButtonClick(Sender: TObject);
begin
  if DataModule1.TasksDataset.IsEmpty then
    Exit;

  DataModule1.TasksDataset.Edit;
  if TaskEditForm.ShowModal = mrOK then
  begin
    DataModule1.TasksDataset.FieldByName('modified').AsDateTime := Now;
    DataModule1.TasksDataset.Post;
    DataModule1.TasksDataset.ApplyUpdates;
  end
  else
    DataModule1.TasksDataset.Cancel;
end;

procedure TTasksFrame.RemoveToolButtonClick(Sender: TObject);
var
  Msg: String;
begin
  if DataModule1.TasksDataset.IsEmpty then
    Exit;

  Msg := Format('Are you sure to delete task "%s"?', [DataModule1.TasksDataset.FieldByName('name').AsString]);
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DataModule1.TasksDataset.Delete;
    DataModule1.TasksDataset.ApplyUpdates;
  end;
end;

procedure TTasksFrame.ShowTimeToolButtonClick(Sender: TObject);
var
  TotalTime: TTime;
  Period: TTime;
begin
  TotalTime:=EncodeTime(0,0,0,0);

  with DataModule1.SQLQuery1 do
  begin
    Close();
    SQL.Text := 'select begin, end from periods where task_id = ' + IntToStr(DataModule1.TasksDataset.FieldByName('id').AsInteger) + ';';
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
  with DataModule1.PeriodsDataset do
  begin
    // ToDo: Check if no unfinished periods
    Append;
    FieldByName('task_id').AsInteger
      := DataModule1.TasksDataset.FieldByName('id').AsInteger;
    FieldByName('begin').AsDateTime := Now;
    Post;
    ApplyUpdates;
  end;
end;

procedure TTasksFrame.StopTrackingToolButtonClick(Sender: TObject);
begin
  with DataModule1.SQLQuery1 do
  begin
    Close;
    SQL.Text := 'update periods set end=:end WHERE `end` IS NULL';
    // ToDo: Check if only one result
    ParamByName('end').AsDateTime:=now - 2415018.5;
    ExecSQL;
    SQLTransaction.Commit;
    Close;
  end;
end;

end.

