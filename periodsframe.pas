unit PeriodsFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, DBGrids, ComCtrls, Menus, VirtualDBGrid, VirtualTrees, DB;

type

  { TPeriodsFrame }

  TPeriodsFrame = class(TFrame)
    DBGrid1: TVirtualDBGrid;
    EditPeriodMenuItem: TMenuItem;
    DeletePeriodMenuItem: TMenuItem;
    PeriodsGridPopupMenu: TPopupMenu;
    ToolBar: TToolBar;
    CreatePeriodToolButton: TToolButton;
    EditPeriodToolButton: TToolButton;
    DeletePeriodToolButton: TToolButton;
    procedure DBGrid1DblClick(Sender: TObject);
    procedure DBGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure DBGrid1LoadRecord(Sender: TCustomVirtualDBGrid;
      RecordData: TRecordData; RowIndex: Cardinal);
  private

  public

  end;

implementation

uses
  LCLType, NonVisualCtrlsDM, WinMouse, StrUtils, Variants, Grids;

resourcestring
  RSYes = 'Yes';

{$R *.lfm}

{ TPeriodsFrame }

procedure TPeriodsFrame.DBGrid1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_DELETE then
  begin
    NonVisualCtrlsDataModule.DeletePeriodAction.Execute;
    Key := 0;
  end;
end;

procedure TPeriodsFrame.DBGrid1LoadRecord(Sender: TCustomVirtualDBGrid;
  RecordData: TRecordData; RowIndex: Cardinal);

  function FormatBoolStr(const AStr: String): String; inline;
  begin
    Result := IfThen(AStr = 'True', RSYes, '');
  end;

begin
  with RecordData do
  begin
    if VarIsNull(FieldValue['is_active']) then
      FieldValue['is_active'] := ''
    else
      FieldValue['is_active'] := FormatBoolStr(FieldValue['is_active']);

    if VarIsNull(FieldValue['is_manually_added']) then
      FieldValue['is_manually_added'] := ''
    else
      FieldValue['is_manually_added'] := FormatBoolStr(FieldValue['is_manually_added']);
  end;
end;

procedure TPeriodsFrame.DBGrid1DblClick(Sender: TObject);
  {function IsMouseOverCell: Boolean;
  var
    ClientCoord: TPoint;
  begin
    ClientCoord := DBGrid1.ScreenToClient(Mouse.CursorPos);

    Result := DBGrid1.MouseToGridZone(ClientCoord.X, ClientCoord.Y) = gzNormal;
  end;}

begin
  {if IsMouseOverCell then} NonVisualCtrlsDataModule.EditPeriodAction.Execute;
end;


end.

