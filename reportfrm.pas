unit ReportFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Messages, Forms, Controls, StdCtrls, EditBtn, ExtCtrls,
  CheckLst, {LMessages,} TreeListView, TAGraph, DateTimePicker,
  ListFilterEdit;

type

  TReportGroupBy = (rgbYear, rgbMonth, rgbDay);

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

    procedure UpdateTasksList;
    procedure CMShowingChanged(var AMsg: TMessage); message CM_SHOWINGCHANGED;
  public
    constructor Create(TheOwner: TComponent); override;

    property BeginDate: TDate read GetBeginDate write SetBeginDate;
    property EndDate: TDate read GetEndDate write SetEndDate;
    property GroupBy: TReportGroupBy read GetGroupBy write SetGroupBy;
    property View: TReportView read GetView write SetView;
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

