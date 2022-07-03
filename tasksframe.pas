unit TasksFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ComCtrls, DBGrids, Grids,
  ExtCtrls, StdCtrls, Menus;

type

  { TTasksFrame }

  TTasksFrame = class(TFrame)
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    TasksGridPopupMenu: TPopupMenu;
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
    procedure ClearFilterButtonClick(Sender: TObject);
    procedure FilterEditChange(Sender: TObject);
    procedure TasksDBGridDblClick(Sender: TObject);
    procedure TasksDBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure TasksDBGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TasksDBGridPrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
  private
    
  public
    //constructor Create(AOwner: TComponent); override;
    procedure SelectTask(AnID: Integer);
  end;

implementation

uses
  Variants, Graphics, DatabaseDM, LCLType, NonVisualCtrlsDM, WinMouse;

{$R *.lfm}

{ TTasksFrame }

procedure TTasksFrame.TasksDBGridPrepareCanvas(sender: TObject;
  DataCol: Integer; Column: TColumn; AState: TGridDrawState);
begin
  // Green color for active task

  if (Sender as TDBGrid).Datasource.Dataset.FieldByName('is_active').AsBoolean then
  begin
    if not (gdSelected in AState) then
      (Sender as TDBGrid).Canvas.Font.Color := clGreen;

    (Sender as TDBGrid).Canvas.Font.Style := [fsBold];
  end;
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
  function IsMouseOverCell: Boolean;
  var
    ClientCoord: TPoint;
  begin
    ClientCoord :=  TasksDBGrid.ScreenToClient(Mouse.CursorPos);

    Result := TasksDBGrid.MouseToGridZone(ClientCoord.X, ClientCoord.Y) = gzNormal;
  end;

begin
  if IsMouseOverCell then NonVisualCtrlsDataModule.EditTaskAction.Execute;
end;

procedure TTasksFrame.TasksDBGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
const
  Indent = 3;
var
  Bitmap: TBitmap;
  BitmapPoint{, TextPoint}: TPoint;
  TextRect: TRect;
  IconIdx: Integer = -1;
begin
  if Assigned(Column.Field) and (Column.FieldName = {'id'} 'name')
      and (not (Sender as TDBGrid).DataSource.DataSet.IsEmpty) then
  begin
    with TasksDBGrid.Canvas do
    begin
      FillRect(Rect);

      with DatabaseDataModule.TasksSQLQuery do
      begin
        if FieldByName('is_active').AsBoolean then
          IconIdx := 0
        else if FieldByName('done').AsBoolean then
          IconIdx := 2;
      end;

      // Draw icon
      if IconIdx > -1 then
      begin
        Bitmap := TBitmap.Create;
        try
          NonVisualCtrlsDataModule.Icons.GetBitmap(IconIdx, Bitmap);
          BitmapPoint.X := Rect.Left + Indent;
          BitmapPoint.Y := Rect.Top + Round((Rect.Height - Bitmap.Height) / 2);
          Draw(BitmapPoint.X, BitmapPoint.Y, Bitmap);
        finally
          Bitmap.Free;
        end;
      end;

      {// Draw text
      TextPoint.X := Rect.Left + Indent * 2 + NonVisualCtrlsDataModule.Icons.Width;
      TextPoint.Y := Rect.Top + Round((Rect.Height - TextHeight(Column.Field.Text)) / 2);
      TextOut(TextPoint.X, TextPoint.Y, Column.Field.Text);}
    end;

    // Draw text
    TextRect := Rect;
    TextRect.Left := TextRect.Left + Indent {* 2} + NonVisualCtrlsDataModule.Icons.Width;
    TasksDBGrid.DefaultDrawColumnCell(TextRect, DataCol, Column, State);
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

