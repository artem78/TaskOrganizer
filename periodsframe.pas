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
    procedure DBGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
  private

  public

  end;

implementation

uses
  LCLType, NonVisualCtrlsDM;

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

end.

