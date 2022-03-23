unit NonVisualCtrlsDM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, UniqueInstance, Controls, ActnList, ExtCtrls, Menus, MainClasses;

type

  { TNonVisualCtrlsDataModule }

  TNonVisualCtrlsDataModule = class(TDataModule)
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
  datamodule, main;

{$R *.lfm}

{ TNonVisualCtrlsDataModule }

procedure TNonVisualCtrlsDataModule.StartTimeTrackingActionExecute(
  Sender: TObject);
var
  Task: TTask;
begin
  Task := TTask.GetById(DataModule1.TasksSQLQuery.FieldByName('id').AsInteger);
  Task.Start;
  Task.Free;

  RefreshStartStopActionsVisibility;
end;

procedure TNonVisualCtrlsDataModule.ExitActionExecute(Sender: TObject);
begin
  MainForm.Close;
end;

procedure TNonVisualCtrlsDataModule.MarkTaskAsDoneActionExecute(Sender: TObject
  );
begin
  with DataModule1.TasksSQLQuery do
  begin
    Edit;
    FieldByName('done').AsBoolean := True;
    Post;
    ApplyUpdates;
  end;

  DataModule1.SQLTransaction1.CommitRetaining;
end;

procedure TNonVisualCtrlsDataModule.StopTimeTrackingActionExecute(
  Sender: TObject);
begin
  TTask.Stop;

  DataModule1.PeriodsSQLQuery.Refresh;

  RefreshStartStopActionsVisibility;
end;

procedure TNonVisualCtrlsDataModule.TrayIconDblClick(Sender: TObject);
begin
  MainForm.RestoreFromTray;
end;

procedure TNonVisualCtrlsDataModule.UnMarkTaskAsDoneActionExecute(
  Sender: TObject);
begin
  with DataModule1.TasksSQLQuery do
  begin
    Edit;
    FieldByName('done').AsBoolean := False;
    Post;
    ApplyUpdates;
  end;

  DataModule1.SQLTransaction1.CommitRetaining;
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

