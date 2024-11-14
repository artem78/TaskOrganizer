unit NonVisualCtrlsDM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, XMLConf, Controls, ActnList, ExtCtrls, Menus, Models,
  PeriodEditFrm, Utils, TrayIconEx;

type

  { TNonVisualCtrlsDataModule }

  TNonVisualCtrlsDataModule = class(TDataModule)
    LanguageIcons: TImageList;
    ShowDoneTasksAction: TAction;
    BackupDatabaseAction: TAction;
    ExportDatabaseAction: TAction;
    DeletePeriodAction: TAction;
    EditPeriodAction: TAction;
    CreatePeriodAction: TAction;
    DeleteTaskAction: TAction;
    EditTaskAction: TAction;
    CreateTaskAction: TAction;
    ActionList: TActionList;
    DelimiterMenuItem: TMenuItem;
    ExitAction: TAction;
    ExitMenuItem: TMenuItem;
    Icons: TImageList;
    MarkTaskAsDoneAction: TAction;
    ServiceMenuItem: TMenuItem;
    ExportMenuItem: TMenuItem;
    StartTimeTrackingMenuItem: TMenuItem;
    StartTimeTrackingAction: TAction;
    StopTimeTrackingAction: TAction;
    StopTimeTrackingMenuItem: TMenuItem;
    TrayIcon: TTrayIconEx;
    TrayPopupMenu: TPopupMenu;
    UnMarkTaskAsDoneAction: TAction;
    XMLConfig: TXMLConfig;
    procedure BackupDatabaseActionExecute(Sender: TObject);
    procedure CreatePeriodActionExecute(Sender: TObject);
    procedure CreateTaskActionExecute(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure DeletePeriodActionExecute(Sender: TObject);
    procedure DeleteTaskActionExecute(Sender: TObject);
    procedure EditPeriodActionExecute(Sender: TObject);
    procedure EditTaskActionExecute(Sender: TObject);
    procedure ExitActionExecute(Sender: TObject);
    procedure ExportDatabaseActionExecute(Sender: TObject);
    procedure MarkTaskAsDoneActionExecute(Sender: TObject);
    procedure ShowDoneTasksActionExecute(Sender: TObject);
    procedure StartTimeTrackingActionExecute(Sender: TObject);
    procedure StopTimeTrackingActionExecute(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure TrayIconMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure TrayPopupMenuPopup(Sender: TObject);
    procedure UnMarkTaskAsDoneActionExecute(Sender: TObject);
    {procedure UniqueInstance1OtherInstance(Sender: TObject;
      ParamCount: Integer; const Parameters: array of String);}
  private
    procedure LoadIconsFromResources;
    procedure StartTimeTrackingForTaskMenuItemClick(Sender: TObject);
  public
    procedure RunningTaskUpdated;
  end;

const
  // Indexes for icons in image list
  NoIconIdx       = -1;
  StartIconIdx    = 0;
  StopIconIdx     = 1;
  TickIconIdx     = 2;
  TickGrayIconIdx = 3;
  CreateIconIdx   = 4;
  DeleteIconIdx   = 5;
  EditIconIdx     = 6;
  ExitIconIdx     = 7;

  EnFlagIconIdx = 0;
  RuFlagIconIdx = 1;

var
  NonVisualCtrlsDataModule: TNonVisualCtrlsDataModule;

implementation

uses
  DatabaseDM, main, taskedit, Dialogs;

resourcestring
  RSDone = 'Done!';
  RSConfirmDeletePeriod = 'Are you sure to delete period?';
  RSSavedIn = 'Saved in "%s"';
  RSConfirmDeleteTask = 'Are you sure to delete task "%s"?';

{$R *.lfm}

{ TNonVisualCtrlsDataModule }

procedure TNonVisualCtrlsDataModule.StartTimeTrackingActionExecute(
  Sender: TObject);
var
  Task: TTask;
begin
  Task := TTask.GetById(DatabaseDataModule.TasksSQLQuery.FieldByName('id').AsInteger);
  Task.Start;
  Task.Free;

  RunningTaskUpdated;
end;

procedure TNonVisualCtrlsDataModule.ExitActionExecute(Sender: TObject);
begin
  MainForm.Close;
end;

procedure TNonVisualCtrlsDataModule.ExportDatabaseActionExecute(Sender: TObject
  );
begin
  with TSaveDialog.Create(nil) do
  begin
    try
      Filter := 'XML|*.xml';
      DefaultExt := 'xml';
      FileName := Format('export %s.xml', [FormatDateTime('yyyy-mm-dd hh-nn-ss', Now)]);
      if Execute then
      begin
        DatabaseDataModule.ExportDatabase(FileName);
        ShowMessage(RSDone);
      end;
    finally
      Free;
    end;
  end;
end;

procedure TNonVisualCtrlsDataModule.CreateTaskActionExecute(Sender: TObject);
begin
  with DatabaseDataModule.TasksSQLQuery do
  begin
    Append;
    if TaskEditForm.ShowModal = mrOK then
    begin
      FieldByName('created').AsDateTime := Now;
      Post;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;
    end
    else
      Cancel;
  end;
end;

procedure TNonVisualCtrlsDataModule.DataModuleCreate(Sender: TObject);
begin
  LoadIconsFromResources;
end;

procedure TNonVisualCtrlsDataModule.DeletePeriodActionExecute(Sender: TObject);
var
  Msg: String;
begin
  with DatabaseDataModule.PeriodsSQLQuery do
  begin
    if IsEmpty then
      Exit;

    Msg := RSConfirmDeletePeriod;
    if MessageDlg(Msg, mtConfirmation, mbYesNo, 0) = mrYes then
    begin
      Delete;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;
    end;
  end;
end;

procedure TNonVisualCtrlsDataModule.CreatePeriodActionExecute(Sender: TObject);
begin
  with DatabaseDataModule.PeriodsSQLQuery do
  begin
    Append;
    FieldByName('begin').AsDateTime := Now;
    FieldByName('end').AsDateTime := Now;
    FieldByName('task_id').AsInteger := DatabaseDataModule.TasksSQLQuery.FieldByName('id').AsInteger;
    FieldByName('is_manually_added').AsBoolean := True;
    if PeriodEditForm.ShowModal = mrOK then
    begin
      Post;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;
    end
    else
      Cancel;
  end;
end;

procedure TNonVisualCtrlsDataModule.BackupDatabaseActionExecute(Sender: TObject
  );
var
  BackupFileName: String;
begin
  try
    BackupFileName := DatabaseDataModule.SaveDatabaseBackup;
    MessageDlg(Format(RSSavedIn, [BackupFileName]), mtInformation, [mbOk] , 0);
  except
    on E: Exception do
      MessageDlg(E.Message, {mtWarning} mtError, [mbOk], 0);
  end;
end;

procedure TNonVisualCtrlsDataModule.DeleteTaskActionExecute(Sender: TObject);
var
  Msg: String;
begin
  with DatabaseDataModule.TasksSQLQuery do
  begin
    if IsEmpty then
      Exit;

    Msg := Format(RSConfirmDeleteTask, [DatabaseDataModule.TasksSQLQuery.FieldByName('name').AsString]);
    if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Delete;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;

      // Refresh periods list after cascade delete
      DatabaseDataModule.PeriodsSQLQuery.Refresh;
    end;
  end;
end;

procedure TNonVisualCtrlsDataModule.EditPeriodActionExecute(Sender: TObject);
begin
  with DatabaseDataModule.PeriodsSQLQuery do
  begin
    if IsEmpty then
      Exit;

    Edit;

    if PeriodEditForm.ShowModal = mrOK then
    begin
      FieldByName('is_manually_added').AsBoolean := True;

      Post;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;
    end
    else
      Cancel;
  end;
end;

procedure TNonVisualCtrlsDataModule.EditTaskActionExecute(Sender: TObject);
begin
  with DatabaseDataModule.TasksSQLQuery do
  begin
    if IsEmpty then
      Exit;

    Edit;
    if TaskEditForm.ShowModal = mrOK then
    begin
      FieldByName('created').AsDateTime :=
          TTask.GetById(FieldByName('id').AsInteger).Created; // Fix for date gets lost
      FieldByName('modified').AsDateTime := Now;
      Post;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;
    end
    else
      Cancel;
  end;
end;

procedure TNonVisualCtrlsDataModule.MarkTaskAsDoneActionExecute(Sender: TObject
  );
begin
  with DatabaseDataModule.TasksSQLQuery do
  begin
    // Stop selected task if it is active
    if FieldByName('is_active').AsBoolean then
    begin
      StopTimeTrackingAction.Execute;
    end;

    Edit;
    FieldByName('done').AsBoolean := True;
    FieldByName('modified').AsDateTime := Now;
    Post;
    ApplyUpdates;
  end;

  DatabaseDataModule.SQLTransaction1.CommitRetaining;
end;

procedure TNonVisualCtrlsDataModule.ShowDoneTasksActionExecute(Sender: TObject);
begin
  ShowDoneTasksAction.Checked := not ShowDoneTasksAction.Checked;
  DatabaseDataModule.DoneTasksFilter := ShowDoneTasksAction.Checked;
end;

procedure TNonVisualCtrlsDataModule.StopTimeTrackingActionExecute(
  Sender: TObject);
begin
  TTask.Stop;

  DatabaseDataModule.PeriodsSQLQuery.Refresh;

  RunningTaskUpdated;
end;

procedure TNonVisualCtrlsDataModule.TrayIconDblClick(Sender: TObject);
begin
  MainForm.RestoreFromTray;
end;

procedure TNonVisualCtrlsDataModule.TrayIconMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  ActivePeriod: TPeriod;
  HintText: String;
begin
  // Update tray icon hint text
  HintText := 'Task Organizer';

  ActivePeriod := TPeriod.GetActive;
  if Assigned(ActivePeriod) then
  begin
    HintText := Format('%s - %s (%s)', [HintText, ActivePeriod.GetTask.Name,
                                        DurationToStr(ActivePeriod.Duration)]);
  end;

  TrayIcon.Hint := HintText;
end;

procedure TNonVisualCtrlsDataModule.TrayPopupMenuPopup(Sender: TObject);
const
  Limit = {12} 7;
var
  MenuItem: TMenuItem;
  Tasks: TTasks;
  Task: TTask;
begin
  StartTimeTrackingMenuItem.Clear;

  Tasks := TTask.GetLastActive(Limit, not DatabaseDataModule.DoneTasksFilter);
  for Task in Tasks do
  begin
    MenuItem := TMenuItem.Create(StartTimeTrackingMenuItem);
    MenuItem.Caption := Task.Name;
    MenuItem.Name := Format('StartTimeTrackingForTask%dMenuItem', [Task.Id]);
    MenuItem.OnClick := @StartTimeTrackingForTaskMenuItemClick;
    StartTimeTrackingMenuItem.Add(MenuItem);
  end;
  Tasks.Free;
end;

procedure TNonVisualCtrlsDataModule.UnMarkTaskAsDoneActionExecute(
  Sender: TObject);
begin
  with DatabaseDataModule.TasksSQLQuery do
  begin
    Edit;
    FieldByName('done').AsBoolean := False;
    FieldByName('modified').AsDateTime := Now;
    Post;
    ApplyUpdates;
  end;

  DatabaseDataModule.SQLTransaction1.CommitRetaining;
end;

procedure TNonVisualCtrlsDataModule.LoadIconsFromResources;
begin
  with Icons do
  begin
    Clear;
    AddResourceName(HINSTANCE, 'START');
    AddResourceName(HINSTANCE, 'STOP');
    AddResourceName(HINSTANCE, 'TICK');
    AddResourceName(HINSTANCE, 'TICK_GRAY');
    AddResourceName(HINSTANCE, 'CREATE');
    AddResourceName(HINSTANCE, 'DELETE');
    AddResourceName(HINSTANCE, 'EDIT');
    AddResourceName(HINSTANCE, 'EXIT');
  end;

  with TrayIcon.Icons do
  begin
    Clear;
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_1');
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_2');
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_3');
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_4');
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_5');
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_6');
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_7');
    AddResourceName(HINSTANCE, 'CLOCK_ANIMATION_8');
  end;

  with TrayIcon do
  begin
    Icon.SetSize(16, 16); // To load icon with correct size
    Icon.LoadFromResourceName(HINSTANCE, 'MAINICON');
    DefaultIcon.SetSize(16, 16);
    DefaultIcon.LoadFromResourceName(HINSTANCE, 'MAINICON');
  end;

  with LanguageIcons do
  begin
    Clear;
    AddResourceName(HINSTANCE, 'FLAG_EN');
    AddResourceName(HINSTANCE, 'FLAG_RU');
  end;
end;

procedure TNonVisualCtrlsDataModule.StartTimeTrackingForTaskMenuItemClick(Sender: TObject);
var
  TaskId: Integer;
  Task:TTask;
begin
  //ShowMessage(TMenuItem(Sender).Name);
  TaskId:=ExtractIntFromStr(TMenuItem(Sender).Name);
  //ShowMessage(IntToStr(taskid));
  task := TTask.GetById(TaskId);
  try
    task.Start;
    RunningTaskUpdated;
  finally
    task.Free;
  end;
end;

procedure TNonVisualCtrlsDataModule.RunningTaskUpdated;
var
  IsActive: Boolean;
begin
  IsActive := TTask.HasActive;
  StartTimeTrackingAction.Enabled:=(not DatabaseDataModule.TasksSQLQuery.FieldByName('done').AsBoolean) and (not IsActive);
  StopTimeTrackingAction.Enabled:=IsActive;
  if IsActive then
  begin
    TrayIcon.Animate := True;
  end
  else
  begin
    TrayIcon.Animate := False;
    TrayIcon.RestoreIcon;
  end;

  DatabaseDataModule.PeriodsDataSource.DataSet.Last;
end;

{procedure TDataModule1.UniqueInstance1OtherInstance(Sender: TObject;
  ParamCount: Integer; const Parameters: array of String);
begin
  //MainForm.Show;
  //MainForm.BringToFront;
  Application.BringToFront;
end; }

end.

