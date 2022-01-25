unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  tasks, taskedit, datamodule, PeriodsFrame;

type

  { TMainForm }

  TMainForm = class(TForm)
    PageControl1: TPageControl;
    PeriodsFrame1: TPeriodsFrame;
    TasksTabSheet: TTabSheet;
    PeriodsTabSheet: TTabSheet;
    TasksFrame1: TTasksFrame;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

end.

