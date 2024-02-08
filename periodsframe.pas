unit PeriodsFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, DBGrids, ComCtrls, Menus, VirtualDBGrid, VirtualTrees, DB, Graphics;

type

  { TPeriodsFrame }

  TPeriodsFrame = class(TFrame)
    PeriodDBGrid: TVirtualDBGrid;
    EditPeriodMenuItem: TMenuItem;
    DeletePeriodMenuItem: TMenuItem;
    PeriodsGridPopupMenu: TPopupMenu;
    ToolBar: TToolBar;
    CreatePeriodToolButton: TToolButton;
    EditPeriodToolButton: TToolButton;
    DeletePeriodToolButton: TToolButton;
    procedure PeriodDBGridBeforePaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas);
    procedure PeriodDBGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure PeriodDBGridLoadRecord(Sender: TCustomVirtualDBGrid;
      RecordData: TRecordData; RowIndex: Cardinal);
    procedure PeriodDBGridRecordDblClick(Sender: TCustomVirtualDBGrid;
      Column: TColumnIndex; RecordData: TRecordData);
  private
    FirstTimeGridShown: Boolean;

    procedure AutoFitGridColumns;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  LCLType, NonVisualCtrlsDM, Utils, WinMouse, StrUtils, Variants, Grids;

resourcestring
  RSYes = 'Yes';

{$R *.lfm}

{ TPeriodsFrame }

procedure TPeriodsFrame.PeriodDBGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_DELETE then
  begin
    NonVisualCtrlsDataModule.DeletePeriodAction.Execute;
    Key := 0;
  end;
end;

procedure TPeriodsFrame.PeriodDBGridBeforePaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas);
begin
  if FirstTimeGridShown then
  begin
    FirstTimeGridShown := False;
    AutoFitGridColumns;

    PeriodDBGrid.DBOptions.DataSource.DataSet.Last;
  end;
end;

procedure TPeriodsFrame.PeriodDBGridLoadRecord(Sender: TCustomVirtualDBGrid;
  RecordData: TRecordData; RowIndex: Cardinal);

  function FormatBoolStr(const AStr: String): String; inline;
  begin
    Result := IfThen(AStr = 'True', RSYes, '');
  end;

begin
  with RecordData do
  begin
    if (not VarIsNull(FieldValue['is_active'])) and FieldValue['is_active'] then
      FieldValue['end'] := '';

    if VarIsNull(FieldValue['is_manually_added']) then
      FieldValue['is_manually_added'] := ''
    else
      FieldValue['is_manually_added'] := FormatBoolStr(FieldValue['is_manually_added']);

    if VarIsNull(FieldValue['duration']) then
      FieldValue['duration'] := '-----'
    else
      FieldValue['duration'] := DurationToStr(VarToDateTime(FieldValue['duration']));
  end;
end;

procedure TPeriodsFrame.PeriodDBGridRecordDblClick(Sender: TCustomVirtualDBGrid;
  Column: TColumnIndex; RecordData: TRecordData);
begin
  NonVisualCtrlsDataModule.EditPeriodAction.Execute;
end;

procedure TPeriodsFrame.AutoFitGridColumns;
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
  with PeriodDBGrid.Header do
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

constructor TPeriodsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FirstTimeGridShown := True;
end;

end.

