unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, DBGrids, Menus, XMLPropStorage, TasksFrame, DatabaseDM,
  PeriodsFrame, NonVisualCtrlsDM, ReportFrm;

type

  { TMainForm }

  TMainForm = class(TForm)
    BackupDBMenuItem: TMenuItem;
    GoToTaskMenuItem: TMenuItem;
    MenuItem1: TMenuItem;
    PeriodsFrame1: TPeriodsFrame;
    ReportFrame1: TReportFrame;
    ShowDoneTasksMenuItem: TMenuItem;
    TasksFrame1: TTasksFrame;
    ViewMenuItem: TMenuItem;
    MainMenu: TMainMenu;
    ExportMenuItem: TMenuItem;
    ServiceMenuItem: TMenuItem;
    LogsMemo: TMemo;
    PageControl1: TPageControl;
    LogsTabSheet: TTabSheet;
    ReportTabSheet: TTabSheet;
    TasksTabSheet: TTabSheet;
    PeriodsTabSheet: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GoToTaskMenuItemClick(Sender: TObject);
    procedure ReportTabSheetShow(Sender: TObject);
    procedure TasksTabSheetShow(Sender: TObject);
  private
    procedure ApplicationMinimize(Sender: TObject);
    procedure GoToTaskMenuItemClick2(Sender: TObject); // ToDo: Better name
    procedure StoreFormState;
    procedure RestoreFormState;
  public
    procedure MinimizeToTray;
    procedure RestoreFromTray;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Models, TypInfo;

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

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  StoreFormState;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  NonVisualCtrlsDataModule.RunningTaskUpdated;

  RestoreFormState;
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

procedure TMainForm.ReportTabSheetShow(Sender: TObject);
begin
  //DatabaseDataModule.StatsSQLQuery.Refresh;
  //StatsDBGrid.Refresh;

  ReportFrame1.OnShow;
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

procedure TMainForm.StoreFormState;
begin
  with NonVisualCtrlsDataModule.XMLConfig do
  begin
    SetValue('MainWindow/Left', Left);
    SetValue('MainWindow/Top', Top);
    SetValue('MainWindow/Width', Width);
    SetValue('MainWindow/Height', Height);

    SetValue('MainWindow/RestoredLeft', RestoredLeft);
    SetValue('MainWindow/RestoredTop', RestoredTop);
    SetValue('MainWindow/RestoredWidth', RestoredWidth);
    SetValue('MainWindow/RestoredHeight', RestoredHeight);

    SetValue('MainWindow/WindowState', GetEnumName(TypeInfo(TWindowState), Ord(WindowState)));

    SetValue('View/ShowDoneTasks', NonVisualCtrlsDataModule.ShowDoneTasksAction.Checked);
    SetValue('SelectedTask', TasksFrame1.TasksDBGrid.DataSource.DataSet.FieldByName('id').AsInteger);
  end;
end;

procedure TMainForm.RestoreFormState;
var
  LastWindowState: TWindowState;
  LastWindowStateStr: String;
begin
  with NonVisualCtrlsDataModule.XMLConfig do
  begin
    LastWindowStateStr := GetEnumName(TypeInfo(TWindowState), Ord(WindowState));
    LastWindowStateStr := GetValue('MainWindow/WindowState', LastWindowStateStr);
    LastWindowState := TWindowState(GetEnumValue(TypeInfo(TWindowState), LastWindowStateStr));;

    if LastWindowState = wsMaximized then
    begin
      WindowState := wsNormal;
      BoundsRect := Bounds(
        GetValue('MainWindow/RestoredLeft', RestoredLeft),
        GetValue('MainWindow/RestoredTop', RestoredTop),
        GetValue('MainWindow/RestoredWidth', RestoredWidth),
        GetValue('MainWindow/RestoredHeight', RestoredHeight));
      WindowState := wsMaximized;
    end
    else
    begin
      WindowState := wsNormal;
      BoundsRect := Bounds(
        GetValue('MainWindow/Left', Left),
        GetValue('MainWindow/Top', Top),
        GetValue('MainWindow/Width', Width),
        GetValue('MainWindow/Height', Height));
    end;

    // ToDo: Remake this
    with NonVisualCtrlsDataModule.ShowDoneTasksAction do
    begin
      Checked := not GetValue('View/ShowDoneTasks', False);
      Execute;
    end;

    TasksFrame1.TasksDBGrid.DataSource.DataSet.Locate(
          'id', GetValue('SelectedTask', -1), []);
  end;
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

