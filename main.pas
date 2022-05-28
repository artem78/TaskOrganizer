unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, DBGrids, Menus, TasksFrame, DatabaseDM, PeriodsFrame,
  NonVisualCtrlsDM;

type

  { TMainForm }

  TMainForm = class(TForm)
    BackupDBMenuItem: TMenuItem;
    ShowDoneTasksMenuItem: TMenuItem;
    TasksFrame1: TTasksFrame;
    ViewMenuItem: TMenuItem;
    PeriodsFrame1: TPeriodsFrame;
    MainMenu: TMainMenu;
    ExportMenuItem: TMenuItem;
    ServiceMenuItem: TMenuItem;
    StatsDBGrid: TDBGrid;
    LogsMemo: TMemo;
    PageControl1: TPageControl;
    LogsTabSheet: TTabSheet;
    StatsTabSheet: TTabSheet;
    TasksTabSheet: TTabSheet;
    PeriodsTabSheet: TTabSheet;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StatsTabSheetShow(Sender: TObject);
    procedure TasksTabSheetShow(Sender: TObject);
  private
    procedure ApplicationMinimize(Sender: TObject);
  public
    procedure MinimizeToTray;
    procedure RestoreFromTray;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Models;

{$I revision.inc}

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption:=Caption+Format('    %s  %s', [GitRevisionStr, {$I %DATE%}]);
  PageControl1.ActivePageIndex:=0;
  //TasksFrame1.RefreshStartStopBtnsVisibility;
  Application.OnMinimize := @ApplicationMinimize; // Minimize to tray
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if TTask.HasActive then
  begin
    CanClose := MessageDlg('You have running task. Are you sure to exit?',
             mtConfirmation, mbYesNo, 0) = mrYes;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  NonVisualCtrlsDataModule.RunningTaskUpdated;
end;

procedure TMainForm.StatsTabSheetShow(Sender: TObject);
begin
  DatabaseDataModule.StatsSQLQuery.Refresh;
  StatsDBGrid.Refresh;
end;

procedure TMainForm.TasksTabSheetShow(Sender: TObject);
begin
  //TasksFrame1.RefreshStartStopBtnsVisibility;
end;

procedure TMainForm.ApplicationMinimize(Sender: TObject);
begin
  MinimizeToTray;
end;

procedure TMainForm.MinimizeToTray;
begin
  WindowState := wsMinimized;
  Hide;
  NonVisualCtrlsDataModule.TrayIcon.Show;
end;

procedure TMainForm.RestoreFromTray;
begin
  NonVisualCtrlsDataModule.TrayIcon.Hide;
  WindowState := wsNormal;
  Show;
end;

end.

