unit TasksFrame;

// Todo: Too much duplicates with PeriodFrame unit. Need to make common parent class for grids.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, ListViewFilterEdit, Forms, Controls, ComCtrls,
  ExtCtrls, Menus, VirtualDBGrid, LocalizedForms, VirtualTrees, Graphics,
  StdCtrls;

type

  { TTasksFrame }

  TTasksFrame = class(TLocalizedFrame)
    FilterEdit: TListViewFilterEdit;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    TasksGridPopupMenu: TPopupMenu;
    TasksDBGrid: TVirtualDBGrid;
    ToolBar1: TToolBar;
    AddToolButton: TToolButton;
    RemoveToolButton: TToolButton;
    EditToolButton: TToolButton;
    SeparatorToolButton: TToolButton;
    StartTrackingToolButton: TToolButton;
    StopTrackingToolButton: TToolButton;
    procedure FilterEditChange(Sender: TObject);
    procedure TasksDBGridBeforePaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas);
    procedure TasksDBGridGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
    procedure TasksDBGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TasksDBGridPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure TasksDBGridRecordDblClick(Sender: TCustomVirtualDBGrid;
      Column: TColumnIndex; RecordData: TRecordData);
  private
     FirstTimeGridShown: Boolean;

     procedure UpdateTranslation(ALang: String); override;
     procedure AutoFitGridColumns;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SelectTask(AnID: Integer);
  end;

implementation

uses
  Variants, DatabaseDM, LCLType, NonVisualCtrlsDM, WinMouse{, LCLTranslator};

resourcestring
  RSFilterHint = '(filter)';

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

procedure TTasksFrame.TasksDBGridRecordDblClick(Sender: TCustomVirtualDBGrid;
  Column: TColumnIndex; RecordData: TRecordData);
begin
  NonVisualCtrlsDataModule.EditTaskAction.Execute;
end;

procedure TTasksFrame.UpdateTranslation(ALang: String);
begin
  inherited;

  FilterEdit.TextHint := RSFilterHint;
end;

procedure TTasksFrame.AutoFitGridColumns;
  function GetTextWidth(const AText: String; const AFont: TFont): Integer;
  var
    Bmp: TBitmap;
  begin
    Result := 0;
    Bmp := TBitmap.Create;
    try
      Bmp.Canvas.Font.Assign(AFont);
      Result := Bmp.Canvas.TextWidth(AText);
    finally
      Bmp.Free;
    end;
  end;

var
  ColIdx: Integer;
  Column: TVirtualTreeColumn;
begin
  with TasksDBGrid.Header do
  begin
    AutoFitColumns(False, smaAllColumns);

    for ColIdx := 0 to Columns.Count - 1 do
    begin
      Column := Columns.Items[ColIdx];
      Column.MinWidth := GetTextWidth(Column.Text, Font)
                       + 20 {ToDo: Calculate REAL margin value};
    end;
  end;
end;

constructor TTasksFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FirstTimeGridShown := True;
end;

procedure TTasksFrame.SelectTask(AnID: Integer);
begin
  DatabaseDataModule.TasksSQLQuery.Locate('id', AnID, []);
end;

procedure TTasksFrame.FilterEditChange(Sender: TObject);
begin
  DatabaseDataModule.TasksFilterText := FilterEdit.Caption;
end;

procedure TTasksFrame.TasksDBGridBeforePaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas);
begin
  if FirstTimeGridShown then
  begin
    FirstTimeGridShown := False;
    AutoFitGridColumns;
  end;
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

end.

