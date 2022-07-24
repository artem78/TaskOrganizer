unit ReportFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Messages, Forms, Controls, StdCtrls, EditBtn, ExtCtrls,
  CheckLst, {LMessages,} TreeListView, Reports, TAGraph, DateTimePicker,
  ListFilterEdit;

type

  TReportView = (rvTable, rvChart);

  { TReportFrame }

  TReportFrame = class(TFrame)
    TaskListFilterEdit: TListFilterEdit;
    PeriodBeginDateTimePicker: TDateTimePicker;
    PeriodEndDateTimePicker: TDateTimePicker;
    SelectAllTasksButton: TButton;
    ReportChart: TChart;
    SettingsPanel: TPanel;
    UpdateReportButton: TButton;
    TasksCheckListBox: TCheckListBox;
    TasksGroupBox: TGroupBox;
    PeriodBeginLabel: TLabel;
    PeriodEndLabel: TLabel;
    PeriodGroupBox: TGroupBox;
    GroupByRadioGroup: TRadioGroup;
    ReportTreeListView: TTreeListView;
    ViewRadioGroup: TRadioGroup;
    procedure GroupByRadioGroupClick(Sender: TObject);
    procedure PeriodBeginDateTimePickerChange(Sender: TObject);
    procedure PeriodEndDateTimePickerChange(Sender: TObject);
    procedure SelectAllTasksButtonClick(Sender: TObject);
    procedure UpdateReportButtonClick(Sender: TObject);
    procedure ViewRadioGroupClick(Sender: TObject);
  private
    function GetBeginDate: TDate;
    procedure SetBeginDate(ADate: TDate);
    function GetEndDate: TDate;
    procedure SetEndDate(ADate: TDate);
    function GetGroupBy: TReportGroupBy;
    procedure SetGroupBy(AVal: TReportGroupBy);
    function GetView: TReportView;
    procedure SetView(AVal: TReportView);
    function GetSelectedTasks: TTaskIds;

    procedure UpdateTasksList;
    procedure CMShowingChanged(var AMsg: TMessage); message CM_SHOWINGCHANGED;
    procedure FillReportTree(const AReport: TReport);
  public
    constructor Create(TheOwner: TComponent); override;

    property BeginDate: TDate read GetBeginDate write SetBeginDate;
    property EndDate: TDate read GetEndDate write SetEndDate;
    property GroupBy: TReportGroupBy read GetGroupBy write SetGroupBy;
    property View: TReportView read GetView write SetView;
    property SelectedTasks: TTaskIds read GetSelectedTasks {write ...};
  end;

implementation

uses DateUtils, DatabaseDM;

{$R *.lfm}

{ TReportFrame }

procedure TReportFrame.ViewRadioGroupClick(Sender: TObject);
begin
  View := View;
end;

procedure TReportFrame.GroupByRadioGroupClick(Sender: TObject);
begin
  GroupBy := GroupBy;
end;

procedure TReportFrame.PeriodBeginDateTimePickerChange(Sender: TObject);
begin
  BeginDate := BeginDate;
end;

procedure TReportFrame.PeriodEndDateTimePickerChange(Sender: TObject);
begin
  EndDate := EndDate;
end;

procedure TReportFrame.SelectAllTasksButtonClick(Sender: TObject);
var
  IsAllChecked: Boolean;
  Idx: Integer;
begin
  IsAllChecked := True;
  for Idx := 0 to TasksCheckListBox.Count - 1 do
  begin
    if not TasksCheckListBox.Checked[Idx] then
    begin
      IsAllChecked := False;
      Break;
    end;
  end;

  if IsAllChecked then
    TasksCheckListBox.CheckAll(cbUnchecked)
  else
    TasksCheckListBox.CheckAll(cbChecked);
end;

procedure TReportFrame.UpdateReportButtonClick(Sender: TObject);
var
  Generator: TReportGenerator = nil;
  Report: TReport = nil;
begin
  Generator := TReportGenerator.Create;

  try
    Generator.BeginDate := BeginDate;
    Generator.EndDate := EndDate;
    Generator.GroupBy := GroupBy;
    Generator.Tasks := SelectedTasks;

    try
      Report := Generator.GenerateReport;

      case View of
        rvTable:
          begin
            FillReportTree(Report);
          end;
      end;
    finally
      Report.Free;
    end;
  finally
    Generator.Free;
  end;
end;

function TReportFrame.GetBeginDate: TDate;
begin
  Result := PeriodBeginDateTimePicker.Date;
end;

procedure TReportFrame.SetBeginDate(ADate: TDate);
begin
  PeriodBeginDateTimePicker.Date := ADate;

  PeriodEndDateTimePicker.MinDate := ADate;
end;

function TReportFrame.GetEndDate: TDate;
begin
  Result := PeriodEndDateTimePicker.Date;
end;

procedure TReportFrame.SetEndDate(ADate: TDate);
begin
  PeriodEndDateTimePicker.Date := ADate;

  PeriodBeginDateTimePicker.MaxDate := ADate;
end;

function TReportFrame.GetGroupBy: TReportGroupBy;
begin
  Result := TReportGroupBy(GroupByRadioGroup.ItemIndex);
end;

procedure TReportFrame.SetGroupBy(AVal: TReportGroupBy);
begin
  GroupByRadioGroup.ItemIndex := Ord(AVal);
end;

function TReportFrame.GetView: TReportView;
begin
  Result := TReportView(ViewRadioGroup.ItemIndex);
end;

procedure TReportFrame.SetView(AVal: TReportView);
begin
  ViewRadioGroup.ItemIndex := Ord(AVal);

  case AVal of
    rvTable:
      begin
        ReportChart.Hide;
        ReportTreeListView.Show;
      end;

    rvChart:
      begin
        ReportTreeListView.Hide;
        ReportChart.Show;
      end;
  end;
end;

function TReportFrame.GetSelectedTasks: TTaskIds;
var
  CheckedCount: Integer = 0;
  Idx, Idx2: Integer;
begin
  for Idx := 0 to TasksCheckListBox.Count - 1 do
  begin
    if TasksCheckListBox.Checked[Idx] then
      Inc(CheckedCount);
  end;

  SetLength(Result, CheckedCount);

  Idx2 := 0;
  for Idx := 0 to TasksCheckListBox.Count - 1 do
  begin
    if TasksCheckListBox.Checked[Idx] then
    begin
      Result[Idx2] := Integer(TasksCheckListBox.Items.Objects[Idx]);
      Inc(Idx2);
    end;
  end;
end;

procedure TReportFrame.UpdateTasksList;
begin
  {TasksCheckListBox.Clear} TaskListFilterEdit.Items.Clear;

  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT `id`, `name` FROM `tasks` ORDER BY `name` ASC;';
    Open;
    First;
    while not EOF do
    begin
      {TasksCheckListBox.AddItem} TaskListFilterEdit.Items.AddObject(FieldByName('name').AsString,
          TObject(FieldByName('id').AsInteger));
      Next;
    end;
    Close;
  end;

  TaskListFilterEdit.InvalidateFilter;
end;

procedure TReportFrame.CMShowingChanged(var AMsg: TMessage);
begin
  inherited;

  if Showing then
    UpdateTasksList;
end;

procedure TReportFrame.FillReportTree(const AReport: TReport);
var
  PeriodIdx: Integer;
  Period: String;
  TaskIdx: Integer;
  Task: String;
  TaskTimeSeconds: Integer;
  TaskTime: String;
begin
  ReportTreeListView.BeginUpdate;
  ReportTreeListView.Items.Clear;

  for PeriodIdx := 0 to AReport.Items.Count - 1 do
  begin
    Period := AReport.Items.Keys[PeriodIdx];
    with ReportTreeListView.Items.Add(Period) do
    begin
      for TaskIdx := 0 to AReport.Items.Data[PeriodIdx].Count - 1 do
      begin
        Task := AReport.Items.Data[PeriodIdx].Keys[TaskIdx];
        TaskTimeSeconds := AReport.Items.Data[PeriodIdx].Data[TaskIdx];
        TaskTime := Format('%.1f h', [TaskTimeSeconds / 60 / 60]);
        SubItems.Add(Task).RecordItems.Add(TaskTime);
      end;
    end;
  end;

  ReportTreeListView.EndUpdate;
end;

constructor TReportFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);

  EndDate := Now;
  BeginDate := IncWeek(EndDate, -1);
  GroupBy := rgbDay;
  View := rvChart;

  //UpdateTasksList;
end;

end.

