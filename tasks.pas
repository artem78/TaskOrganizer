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
    procedure AddToolButtonClick(Sender: TObject);
    procedure EditToolButtonClick(Sender: TObject);
    procedure RemoveToolButtonClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

implementation

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
  Msg := Format('Are you sure to delete task "%s"?', [DataModule1.TasksDataset.FieldByName('name').AsString]);
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DataModule1.TasksDataset.Delete;
    DataModule1.TasksDataset.ApplyUpdates;
  end;
end;

end.

