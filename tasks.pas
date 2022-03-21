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
    SetDoneButton: TToolButton;
    SetNotDoneButton: TToolButton;
    procedure AddToolButtonClick(Sender: TObject);
    procedure EditToolButtonClick(Sender: TObject);
    procedure RemoveToolButtonClick(Sender: TObject);
  private
    
  public
    //constructor Create(AOwner: TComponent); override;
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

{constructor TTasksFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  RefreshStartStopBtnsVisibility;
end;  }

end.

