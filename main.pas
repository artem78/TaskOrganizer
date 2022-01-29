unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, tasks, taskedit, datamodule, PeriodsFrame;

type

  { TMainForm }

  TMainForm = class(TForm)
    LogsMemo: TMemo;
    PageControl1: TPageControl;
    PeriodsFrame1: TPeriodsFrame;
    LogsTabSheet: TTabSheet;
    TasksFrame1: TTasksFrame;
    TasksTabSheet: TTabSheet;
    PeriodsTabSheet: TTabSheet;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$I revision.inc}

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption:=Caption+Format('    %s  %s', [GitRevisionStr, {$I %DATE%}]);
end;

end.

