unit PeriodsFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, DBGrids, ComCtrls;

type

  { TPeriodsFrame }

  TPeriodsFrame = class(TFrame)
    DBGrid1: TDBGrid;
    ToolBar: TToolBar;
    CreatePeriodToolButton: TToolButton;
    EditPeriodToolButton: TToolButton;
    DeletePeriodToolButton: TToolButton;
    procedure DBGrid1DblClick(Sender: TObject);
    procedure DBGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
  private

  public

  end;

implementation

uses
  LCLType, NonVisualCtrlsDM, WinMouse, Grids;

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

procedure TPeriodsFrame.DBGrid1DblClick(Sender: TObject);
  function IsMouseOverCell: Boolean;
  var
    ClientCoord: TPoint;
  begin
    ClientCoord := DBGrid1.ScreenToClient(Mouse.CursorPos);

    Result := DBGrid1.MouseToGridZone(ClientCoord.X, ClientCoord.Y) = gzNormal;
  end;

begin
  if IsMouseOverCell then NonVisualCtrlsDataModule.EditPeriodAction.Execute;
end;


end.

