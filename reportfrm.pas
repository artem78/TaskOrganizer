unit ReportFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ExtCtrls, ComboEx,
  CheckLst, TreeListView, TAGraph, DateTimePicker;

type

  TReportGroupBy = (rgbYear, rgbMonth, rgbDay);

  TReportView = (rvTable, rvChart);

  { TReportFrame }

  TReportFrame = class(TFrame)
    PeriodBeginDateTimePicker: TDateTimePicker;
    PeriodEndDateTimePicker: TDateTimePicker;
    SelectAllTasksButton: TButton;
    TaskFilterEdit: TEdit;
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
  public
    constructor Create(TheOwner: TComponent); override;

    property BeginDate: TDate read GetBeginDate write SetBeginDate;
    property EndDate: TDate read GetEndDate write SetEndDate;
    property GroupBy: TReportGroupBy read GetGroupBy write SetGroupBy;
    property View: TReportView read GetView write SetView;
  end;

implementation

uses DateUtils;

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

function TReportFrame.GetBeginDate: TDate;
begin
  Result := PeriodBeginDateTimePicker.Date;
end;

procedure TReportFrame.SetBeginDate(ADate: TDate);
begin
  PeriodBeginDateTimePicker.Date := ADate;
end;

function TReportFrame.GetEndDate: TDate;
begin
  Result := PeriodEndDateTimePicker.Date;
end;

procedure TReportFrame.SetEndDate(ADate: TDate);
begin
  PeriodEndDateTimePicker.Date := ADate;
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

constructor TReportFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);

  EndDate := Now;
  BeginDate := IncWeek(EndDate, -1);
  GroupBy := rgbDay;
  View := rvChart;
end;

end.

