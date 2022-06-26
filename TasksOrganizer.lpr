program TasksOrganizer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, datetimectrls, main, TasksFrame, DatabaseDM, taskedit, periodsframe,
  Models, NonVisualCtrlsDM, PeriodEditFrm
  { you can add units after this },
  Dialogs, UniqueInstanceRaw;

{$R *.res}

const
  ProgId = 'TaskOrganizer' {$IFOPT D+} + '_DEBUG'{$EndIf};

begin
  // Check if no another instance is running
  if InstanceRunning(ProgId) then
  begin
    MessageDlg('Another instance already running!', mtWarning, [mbOK], 0);
    Exit;
  end;

  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDatabaseDataModule, DatabaseDataModule);
  Application.CreateForm(TTaskEditForm, TaskEditForm);
  Application.CreateForm(TNonVisualCtrlsDataModule, NonVisualCtrlsDataModule);
  Application.CreateForm(TPeriodEditForm, PeriodEditForm);
  Application.Run;
end.

