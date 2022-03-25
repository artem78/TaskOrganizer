unit TasksFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ComCtrls, DBGrids, Grids;

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
    procedure TasksDBGridPrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
  private
    
  public
    //constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  Variants, Graphics;

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

{constructor TTasksFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  RefreshStartStopBtnsVisibility;
end;  }

end.

