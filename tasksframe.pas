unit TasksFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ComCtrls, DBGrids, taskedit, DatabaseDM, Dialogs;

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
  DatabaseDataModule.TasksSQLQuery.Append;
  if TaskEditForm.ShowModal = mrOK then
  begin
    DatabaseDataModule.TasksSQLQuery.FieldByName('created').AsDateTime := Now;
    DatabaseDataModule.TasksSQLQuery.Post;
    DatabaseDataModule.TasksSQLQuery.ApplyUpdates;
    DatabaseDataModule.SQLTransaction1.CommitRetaining;
  end
  else
    DatabaseDataModule.TasksSQLQuery.Cancel;
end;

procedure TTasksFrame.EditToolButtonClick(Sender: TObject);
begin
  if DatabaseDataModule.TasksSQLQuery.IsEmpty then
    Exit;

  DatabaseDataModule.TasksSQLQuery.Edit;
  if TaskEditForm.ShowModal = mrOK then
  begin
    DatabaseDataModule.TasksSQLQuery.FieldByName('modified').AsDateTime := Now;
    DatabaseDataModule.TasksSQLQuery.Post;
    DatabaseDataModule.TasksSQLQuery.ApplyUpdates;
    DatabaseDataModule.SQLTransaction1.CommitRetaining;
  end
  else
    DatabaseDataModule.TasksSQLQuery.Cancel;
end;

procedure TTasksFrame.RemoveToolButtonClick(Sender: TObject);
var
  Msg: String;
begin
  if DatabaseDataModule.TasksSQLQuery.IsEmpty then
    Exit;

  Msg := Format('Are you sure to delete task "%s"?', [DatabaseDataModule.TasksSQLQuery.FieldByName('name').AsString]);
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DatabaseDataModule.TasksSQLQuery.Delete;
    DatabaseDataModule.TasksSQLQuery.ApplyUpdates;
    DatabaseDataModule.SQLTransaction1.CommitRetaining;
  end;
end;

{constructor TTasksFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  RefreshStartStopBtnsVisibility;
end;  }

end.

