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
  private

  public

  end;

implementation

{$R *.lfm}

end.

