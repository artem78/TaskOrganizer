unit TasksFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ComCtrls, DBGrids, Grids,
  ExtCtrls, StdCtrls, Menus, VirtualDBGrid, LocalizedForms, VirtualTrees, Graphics;

type

  { TTasksFrame }

  TTasksFrame = class(TLocalizedFrame)
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    TasksGridPopupMenu: TPopupMenu;
    ClearFilterButton: TButton;
    FilterEdit: TLabeledEdit;
    TasksDBGrid: TVirtualDBGrid;
    ToolBar1: TToolBar;
    AddToolButton: TToolButton;
    RemoveToolButton: TToolButton;
    EditToolButton: TToolButton;
    SeparatorToolButton: TToolButton;
    StartTrackingToolButton: TToolButton;
    StopTrackingToolButton: TToolButton;
    procedure ClearFilterButtonClick(Sender: TObject);
    procedure FilterEditChange(Sender: TObject);
    procedure TasksDBGridDblClick(Sender: TObject);
    procedure TasksDBGridGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
    procedure TasksDBGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TasksDBGridPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
  private
     procedure UpdateTranslation(ALang: String); override;
  public
    //constructor Create(AOwner: TComponent); override;
    procedure SelectTask(AnID: Integer);
  end;

implementation

uses
  Variants, DatabaseDM, LCLType, NonVisualCtrlsDM, WinMouse{, LCLTranslator};

resourcestring
  RSFilter = 'Filter:';

{$R *.lfm}

{ TTasksFrame }

procedure TTasksFrame.TasksDBGridPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  Grid: TVirtualDBGrid;
begin
  // Green color for active task

  if (Column <= NoColumn) then
    Exit;
  Grid := (Sender as TVirtualDBGrid);

  //if VarIsNull(Grid.GetNodeRecordData(Node).FieldValue['is_active']) then
  //  Exit;

  if Boolean(Grid.GetNodeRecordData(Node).FieldValue['is_active']) then
  begin
    if Node <> Grid.FocusedNode then
      TargetCanvas.Font.Color := clGreen;

    TargetCanvas.Font.Style := [fsBold];
  end;
end;

procedure TTasksFrame.UpdateTranslation(ALang: String);
begin
  inherited;

  FilterEdit.EditLabel.Caption := RSFilter;
end;

procedure TTasksFrame.SelectTask(AnID: Integer);
begin
  DatabaseDataModule.TasksSQLQuery.Locate('id', AnID, []);
end;

procedure TTasksFrame.ClearFilterButtonClick(Sender: TObject);
begin
  FilterEdit.Clear;
end;

procedure TTasksFrame.FilterEditChange(Sender: TObject);
begin
  DatabaseDataModule.TasksFilterText := FilterEdit.Text;
end;

procedure TTasksFrame.TasksDBGridDblClick(Sender: TObject);
  {function IsMouseOverCell: Boolean;
  var
    ClientCoord: TPoint;
  begin
    ClientCoord :=  TasksDBGrid.ScreenToClient(Mouse.CursorPos);

    Result := TasksDBGrid.MouseToGridZone(ClientCoord.X, ClientCoord.Y) = gzNormal;
  end;}

begin
  {if IsMouseOverCell then} NonVisualCtrlsDataModule.EditTaskAction.Execute;
end;

procedure TTasksFrame.TasksDBGridGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  Grid: TVirtualDBGrid;
  Col: TVirtualDBTreeColumn;
  RecordData: TRecordData;
begin
  if Column <= NoColumn then
    Exit;

  Grid := Sender as TVirtualDBGrid;
  Col := TVirtualDBTreeColumn(Grid.Header.Columns[Column]);

  if Col.FieldName = {'id'} 'name' then
  begin
    RecordData := Grid.GetNodeRecordData(Node);
    if RecordData.FieldValue['is_active'] then
      ImageIndex := 0
    else if RecordData.FieldValue['done'] then
      ImageIndex := 2;
  end;
end;

procedure TTasksFrame.TasksDBGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_DELETE then
  begin
    NonVisualCtrlsDataModule.DeleteTaskAction.Execute;
    Key := 0;
  end;
end;

{constructor TTasksFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  RefreshStartStopBtnsVisibility;
end;  }

end.

