unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, DBGrids, Menus, TasksFrame, DatabaseDM,
  PeriodsFrame, NonVisualCtrlsDM, ReportFrm, LocalizedForms;

type

  { TMainForm }

  TMainForm = class(TLocalizedForm)
    BackupDBMenuItem: TMenuItem;
    GoToTaskMenuItem: TMenuItem;
    MenuItem1: TMenuItem;
    LanguageMenuItem: TMenuItem;
    MenuItem2: TMenuItem;
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
    FirstShow: Boolean; // Indicates if FormShow event runs first time

    procedure ApplicationMinimize(Sender: TObject);
    procedure GoToTaskMenuItemClick2(Sender: TObject); // ToDo: Better name
    procedure StoreFormState;
    procedure RestoreFormState;
    procedure StoreSettings;
    procedure RestoreSettings;
    procedure FillLanguagesList;
    procedure OnLanguageMenuClick(ASender: TObject);
    procedure SetLanguage(ALang: String);
    function GetLanguage: String;
    procedure UpdateTranslation(ALang: String); override;
  public
    procedure MinimizeToTray;
    procedure RestoreFromTray;
    property Language: String read GetLanguage write SetLanguage;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Models, Utils, StrUtils, TypInfo, LCLTranslator, LazFileUtils
  {$IFOPT D+}
  ,LazLogger
  {$Else}
  ,LazLoggerDummy
  {$EndIf}
  ;

resourcestring
  RSRunningTaskNotification = 'You have running task "%s"!';
  RSLibraryNotFound = 'Library "%s" not found in program directory!';
  RSStopTaskAndExit = 'Stop task and exit';
  RSForceExit = 'Force exit';
  RSCAncel = 'Cancel';
  RSActiveTaskOnStartupNotification = 'Task "%s" was not stopped when program '
                                    + 'have been closed and is still active';

{$I revision.inc}

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
const
  SqliteLibName = 'sqlite3.dll';
begin
  FillLanguagesList;
  Language := '';
  FirstShow := True;

  if not FileExists(SqliteLibName) then
  begin
    MessageDlg(Format(RSLibraryNotFound, [SqliteLibName]), mtError, [mbOK], 0);
    //Close;
    Application.Terminate;
  end;

  PageControl1.ActivePageIndex:=0;
  {$IFOPT D-}
  LogsTabSheet.TabVisible := False;
  {$EndIf}
  //TasksFrame1.RefreshStartStopBtnsVisibility;
  Application.OnMinimize := @ApplicationMinimize; // Minimize to tray
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  Msg: string;
  Res: TModalResult;
  ActiveTask: TTask;
begin
  CanClose:=True;
  if TTask.HasActive then
  begin
    ActiveTask:=TTask.GetActive;
    try
      Msg:=Format(RSRunningTaskNotification, [ActiveTask.Name]);
      Res := QuestionDlg('', Msg, mtCustom {mtConfirmation},
                                            [mrAbort, RSStopTaskAndExit,
                                             mrClose, RSForceExit,
                                             mrCancel, RSCAncel], '');
      case Res of
        mrAbort: ActiveTask.Stop;
        mrCancel: CanClose:=False;
      end;
    finally
      ActiveTask.Free;
    end;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  StoreSettings;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  ActiveTask: TTask;
  Msg: String;
begin
  NonVisualCtrlsDataModule.RunningTaskUpdated;

  if FirstShow then
  begin
    RestoreSettings;

    // предупреждение о неостановленной задаче
    if TTask.HasActive then
    begin
      ActiveTask:=TTask.GetActive;
      try
        Msg := Format(RSActiveTaskOnStartupNotification, [ActiveTask.Name]);
        MessageDlg(Msg, mtInformation, [mbOK], 0);
      finally
        ActiveTask.Free;
      end;
    end;
  end;
  FirstShow := False;
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
  TaskId :=ExtractIntFromStr(s);
  TasksFrame1.SelectTask(TaskId);
  TasksFrame1.TasksDBGrid.SetFocus;
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
  end;
end;

procedure TMainForm.StoreSettings;
begin
  StoreFormState;

  with NonVisualCtrlsDataModule.XMLConfig do
  begin
    SetValue('View/ShowDoneTasks', NonVisualCtrlsDataModule.ShowDoneTasksAction.Checked);
    SetValue('SelectedTask', TasksFrame1.TasksDBGrid.DBOptions.DataSource.DataSet.FieldByName('id').AsInteger);
    SetValue('Language', Language);
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
  end;
end;

procedure TMainForm.RestoreSettings;
begin
  RestoreFormState;

  with NonVisualCtrlsDataModule.XMLConfig do
  begin
    // ToDo: Remake this
    with NonVisualCtrlsDataModule.ShowDoneTasksAction do
    begin
      Checked := not GetValue('View/ShowDoneTasks', False);
      Execute;
    end;

    TasksFrame1.TasksDBGrid.DBOptions.DataSource.DataSet.Locate(
          'id', GetValue('SelectedTask', -1), []);
    //TasksFrame1.SelectTask(GetValue('SelectedTask', -1));

    Language := GetValue('Language', '');
  end;
end;

procedure TMainForm.FillLanguagesList;
  function ExtractLangCodeFromFileName(AFileName: String): String;
  var
    Idx: Integer;
  begin
    Result := ExtractFileNameOnly(AFileName);
    Idx := WordCount(Result, ['.']);
    Result := ExtractWord(Idx, Result, ['.']);
    Result := LowerCase(Result);
  end;

var
  Files, Langs: TStringList;
  FileName, LangCode, LangName: String;
  MenuItem: TMenuItem;
begin
  LanguageMenuItem.Clear;

  Files := TStringList.Create;
  Langs := TStringList.Create;
  try
    Langs.Sorted := True;
    Langs.Duplicates := dupIgnore;

    FindAllFiles(Files, ConcatPaths([ProgramDirectory, 'languages']), '*.po;*.mo', False);

    for FileName in Files do
    begin
      Langs.Add(ExtractLangCodeFromFileName(FileName));
    end;

    Langs.Add('en');

    for LangCode in Langs do
    begin
      MenuItem := TMenuItem.Create(LanguageMenuItem);

      case LangCode of
        'en':
          begin
            LangName := 'English';
            MenuItem.ImageIndex := EnFlagIconIdx;
          end;

        'ru':
          begin
            LangName := 'Russian (Русский)';
            MenuItem.ImageIndex := RuFlagIconIdx;
          end

      else
        begin
          LangName := LangCode;
          MenuItem.ImageIndex := NoIconIdx;
        end;
      end;
      MenuItem.Caption := LangName;

      MenuItem.Name := LangCode + '_LangMenuItem';
      MenuItem.OnClick := @OnLanguageMenuClick;
      MenuItem.RadioItem := True;
      MenuItem.AutoCheck := {True} False;
      LanguageMenuItem.Add(MenuItem);
    end;
  finally
    Langs.Free;
    Files.Free;
  end;
end;

procedure TMainForm.OnLanguageMenuClick(ASender: TObject);
begin
  Language := ExtractWord(1, (ASender as TMenuItem).Name, ['_']);
end;

procedure TMainForm.SetLanguage(ALang: String);
var
  ResLang: String;
begin
  ResLang := SetDefaultLang(ALang);
  UpdateTranslation(ResLang);
end;

function TMainForm.GetLanguage: String;
begin
  Result := GetDefaultLang;
end;

procedure TMainForm.UpdateTranslation(ALang: String);
var
  LangMenuItem: TMenuItem;
begin
  inherited;

  // Update some labels
  if LanguageMenuItem.Caption <> 'Language' then
     LanguageMenuItem.Caption := LanguageMenuItem.Caption + ' / Language';
  //FillLanguagesList;

  Caption := Caption + Format('    %s  %s'{$IFOPT D+} + '    [Debug Build]'{$EndIf}, [GitRevisionStr, {$I %DATE%}]);

  // Update selected language in main menu
  LangMenuItem := (LanguageMenuItem.FindComponent(ALang + '_LangMenuItem') as TMenuItem);
  if Assigned(LangMenuItem) then
    LangMenuItem.Checked := True;

  //ShowMessage('lang changed');
end;

procedure TMainForm.MinimizeToTray;
begin
  StoreFormState;

  WindowState := wsMinimized;
  Hide;
  NonVisualCtrlsDataModule.TrayIcon.Show;
end;

procedure TMainForm.RestoreFromTray;
begin
  NonVisualCtrlsDataModule.TrayIcon.Hide;
  //WindowState := wsNormal;
  Show;

  RestoreFormState;
end;

initialization
  {$IFOPT D+}
  DeleteFile('log.txt');
  DebugLogger.LogName := 'log.txt';
  DebugLn('Logging started');
  {$EndIf}
end.

