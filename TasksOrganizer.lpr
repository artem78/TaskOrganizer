program TasksOrganizer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, tasks, DatabaseDM, taskedit, periodsframe, Models, NonVisualCtrlsDM
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDatabaseDataModule, DatabaseDataModule);
  Application.CreateForm(TTaskEditForm, TaskEditForm);
  Application.CreateForm(TNonVisualCtrlsDataModule, NonVisualCtrlsDataModule);
  Application.Run;
end.

