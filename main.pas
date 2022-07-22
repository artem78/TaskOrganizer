unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, DBGrids, Menus, XMLPropStorage, TasksFrame, DatabaseDM,
  PeriodsFrame, NonVisualCtrlsDM;

type

  { TMainForm }

  TMainForm = class(TForm)
    BackupDBMenuItem: TMenuItem;
    GoToTaskMenuItem: TMenuItem;
    MenuItem1: TMenuItem;
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
    XMLPropStorage: TXMLPropStorage;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GoToTaskMenuItemClick(Sender: TObject);
    procedure StatsTabSheetShow(Sender: TObject);
    procedure TasksTabSheetShow(Sender: TObject);
  private
    procedure ApplicationMinimize(Sender: TObject);
    procedure GoToTaskMenuItemClick2(Sender: TObject); // ToDo: Better name
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
  Caption:=Caption+Format('    %s  %s'{$IFOPT D+} + '    [Debug Build]'{$EndIf}, [GitRevisionStr, {$I %DATE%}]);
  PageControl1.ActivePageIndex:=0;
  {$IFOPT D-}
  LogsTabSheet.TabVisible := False;
  {$EndIf}
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

procedure TMainForm.GoToTaskMenuItemClick(Sender: TObject);
const
  Limit = 12;
var
  MenuItem: TMenuItem;
  Tasks: TTasks;
  Task: TTask;
begin
  GoToTaskMenuItem.Clear;

  Tasks := TTask.GetLastActive(Limit, not DatabaseDataModule.DoneTasksFilter);
  for Task in Tasks do
  begin
    MenuItem := TMenuItem.Create(GoToTaskMenuItem);
    MenuItem.Caption := Task.Name;
    MenuItem.Name := Format('GoToTask%dMenuItem', [Task.Id]);
    MenuItem.OnClick := @GoToTaskMenuItemClick2;
    GoToTaskMenuItem.Add(MenuItem);
  end;
  Tasks.Free;
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

procedure TMainForm.GoToTaskMenuItemClick2(Sender: TObject);
var
  S: String;
  TaskId: Integer;
begin
  S := (Sender as TMenuItem).Name;
  TaskId := StrToInt(S.Substring(8, S.Length - 16));
  TasksFrame1.SelectTask(TaskId);
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

