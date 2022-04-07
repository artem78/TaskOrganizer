unit TasksFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ComCtrls, DBGrids, Grids,
  ExtCtrls, StdCtrls;

type

  { TTasksFrame }

  TTasksFrame = class(TFrame)
    ShowDoneTasksCheckBox: TCheckBox;
    ClearFilterButton: TButton;
    FilterEdit: TLabeledEdit;
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
    procedure ClearFilterButtonClick(Sender: TObject);
    procedure FilterEditChange(Sender: TObject);
    procedure ShowDoneTasksCheckBoxChange(Sender: TObject);
    procedure TasksDBGridPrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
  private
    
  public
    //constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  Variants, Graphics, DatabaseDM;

{$R *.lfm}

{ TTasksFrame }

procedure TTasksFrame.TasksDBGridPrepareCanvas(sender: TObject;
  DataCol: Integer; Column: TColumn; AState: TGridDrawState);
begin
  // Green color for active task

  if (Sender as TDBGrid).Datasource.Dataset.FieldByName('is_active').AsBoolean then
  begin
    (Sender as TDBGrid).Canvas.Font.Color := clGreen;
    (Sender as TDBGrid).Canvas.Font.Style := [fsBold];
  end;
end;

procedure TTasksFrame.ClearFilterButtonClick(Sender: TObject);
begin
  FilterEdit.Clear;
end;

procedure TTasksFrame.FilterEditChange(Sender: TObject);
begin
  DatabaseDataModule.TasksFilterText := FilterEdit.Text;
end;

procedure TTasksFrame.ShowDoneTasksCheckBoxChange(Sender: TObject);
begin
  DatabaseDataModule.DoneTasksFilter := ShowDoneTasksCheckBox.Checked;
end;

{constructor TTasksFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  RefreshStartStopBtnsVisibility;
end;  }

end.

