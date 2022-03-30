unit NonVisualCtrlsDM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, UniqueInstance, Controls, ActnList, ExtCtrls, Menus, Models,
  PeriodEditFrm;

type

  { TNonVisualCtrlsDataModule }

  TNonVisualCtrlsDataModule = class(TDataModule)
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
    StartTimerackingMenuItem: TMenuItem;
    StartTimeTrackingAction: TAction;
    StopTimeTrackingAction: TAction;
    StopTimeTrackingMenuItem: TMenuItem;
    TrayIcon: TTrayIcon;
    TrayPopupMenu: TPopupMenu;
    UniqueInstance1: TUniqueInstance;
    UnMarkTaskAsDoneAction: TAction;
    procedure CreatePeriodActionExecute(Sender: TObject);
    procedure CreateTaskActionExecute(Sender: TObject);
    procedure DeleteTaskActionExecute(Sender: TObject);
    procedure EditPeriodActionExecute(Sender: TObject);
    procedure EditTaskActionExecute(Sender: TObject);
    procedure ExitActionExecute(Sender: TObject);
    procedure MarkTaskAsDoneActionExecute(Sender: TObject);
    procedure StartTimeTrackingActionExecute(Sender: TObject);
    procedure StopTimeTrackingActionExecute(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure UnMarkTaskAsDoneActionExecute(Sender: TObject);
    {procedure UniqueInstance1OtherInstance(Sender: TObject;
      ParamCount: Integer; const Parameters: array of String);}
  private

  public
    procedure RefreshStartStopActionsVisibility;
  end;

var
  NonVisualCtrlsDataModule: TNonVisualCtrlsDataModule;

implementation

uses
  DatabaseDM, main, taskedit, Dialogs;

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

  RefreshStartStopActionsVisibility;
end;

procedure TNonVisualCtrlsDataModule.ExitActionExecute(Sender: TObject);
begin
  MainForm.Close;
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

procedure TNonVisualCtrlsDataModule.CreatePeriodActionExecute(Sender: TObject);
begin
  with DatabaseDataModule.PeriodsSQLQuery do
  begin
    Append;
    FieldByName('begin').AsDateTime := Now;
    FieldByName('end').AsDateTime := Now;
    FieldByName('task_id').AsInteger := DatabaseDataModule.TasksSQLQuery.FieldByName('id').AsInteger;
    if PeriodEditForm.ShowModal = mrOK then
    begin
      // Fix dates
      FieldByName('begin').AsDateTime := FieldByName('begin').AsDateTime - 2415018.5;
      FieldByName('end').AsDateTime := FieldByName('end').AsDateTime - 2415018.5;

      Post;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;
    end
    else
      Cancel;
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

    Msg := Format('Are you sure to delete task "%s"?', [DatabaseDataModule.TasksSQLQuery.FieldByName('name').AsString]);
    if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Delete;
      ApplyUpdates;
      DatabaseDataModule.SQLTransaction1.CommitRetaining;
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

    {// Fix dates
    FieldByName('begin').AsDateTime := FieldByName('begin').AsDateTime + 2415018.5;
    FieldByName('end').AsDateTime := FieldByName('end').AsDateTime + 2415018.5;}

    if PeriodEditForm.ShowModal = mrOK then
    begin
      // Fix dates
      FieldByName('begin').AsDateTime := FieldByName('begin').AsDateTime - 2415018.5;
      FieldByName('end').AsDateTime := FieldByName('end').AsDateTime - 2415018.5;

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
    Edit;
    FieldByName('done').AsBoolean := True;
    Post;
    ApplyUpdates;
  end;

  DatabaseDataModule.SQLTransaction1.CommitRetaining;
end;

procedure TNonVisualCtrlsDataModule.StopTimeTrackingActionExecute(
  Sender: TObject);
begin
  TTask.Stop;

  DatabaseDataModule.PeriodsSQLQuery.Refresh;

  RefreshStartStopActionsVisibility;
end;

procedure TNonVisualCtrlsDataModule.TrayIconDblClick(Sender: TObject);
begin
  MainForm.RestoreFromTray;
end;

procedure TNonVisualCtrlsDataModule.UnMarkTaskAsDoneActionExecute(
  Sender: TObject);
begin
  with DatabaseDataModule.TasksSQLQuery do
  begin
    Edit;
    FieldByName('done').AsBoolean := False;
    Post;
    ApplyUpdates;
  end;

  DatabaseDataModule.SQLTransaction1.CommitRetaining;
end;

procedure TNonVisualCtrlsDataModule.RefreshStartStopActionsVisibility;
var
  IsActive: Boolean;
begin
  IsActive := TTask.HasActive;
  StartTimeTrackingAction.Enabled:=not IsActive;
  StopTimeTrackingAction.Enabled:=IsActive;
end;

{procedure TDataModule1.UniqueInstance1OtherInstance(Sender: TObject;
  ParamCount: Integer; const Parameters: array of String);
begin
  //MainForm.Show;
  //MainForm.BringToFront;
  Application.BringToFront;
end; }

end.

