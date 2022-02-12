unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, DBGrids, tasks, taskedit, datamodule, PeriodsFrame;

type

  { TMainForm }

  TMainForm = class(TForm)
    StatsDBGrid: TDBGrid;
    LogsMemo: TMemo;
    PageControl1: TPageControl;
    PeriodsFrame1: TPeriodsFrame;
    LogsTabSheet: TTabSheet;
    StatsTabSheet: TTabSheet;
    TasksFrame1: TTasksFrame;
    TasksTabSheet: TTabSheet;
    PeriodsTabSheet: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StatsTabSheetShow(Sender: TObject);
    procedure TasksTabSheetShow(Sender: TObject);
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
  PageControl1.ActivePageIndex:=0;
  //TasksFrame1.RefreshStartStopBtnsVisibility;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  TasksFrame1.RefreshStartStopBtnsVisibility;
end;

procedure TMainForm.StatsTabSheetShow(Sender: TObject);
begin
  DataModule1.StatsSQLQuery.Refresh;
  StatsDBGrid.Refresh;
end;

procedure TMainForm.TasksTabSheetShow(Sender: TObject);
begin
  //TasksFrame1.RefreshStartStopBtnsVisibility;
end;

end.

