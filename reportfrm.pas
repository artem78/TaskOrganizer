unit ReportFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ExtCtrls,
  CheckLst, TreeListView, Reports, TAGraph, TASeries,
  TASources, DateTimePicker, ListFilterEdit;

type

  TReportView = (rvTable, rvChart);

  { TReportFrame }

  TReportFrame = class(TFrame)
    ButtonPanel: TPanel;
    PeriodAllTimeCheckBox: TCheckBox;
    LabelsChartSource: TListChartSource;
    TaskListFilterEdit: TListFilterEdit;
    PeriodBeginDateTimePicker: TDateTimePicker;
    PeriodEndDateTimePicker: TDateTimePicker;
    SelectAllTasksButton: TButton;
    ReportChart: TChart;
    SettingsPanel: TPanel;
    TasksCheckListBox: TCheckListBox;
    TasksGroupBox: TGroupBox;
    PeriodBeginLabel: TLabel;
    PeriodEndLabel: TLabel;
    PeriodGroupBox: TGroupBox;
    GroupByRadioGroup: TRadioGroup;
    ReportTreeListView: TTreeListView;
    ViewRadioGroup: TRadioGroup;
    procedure GroupByRadioGroupClick(Sender: TObject);
    procedure PeriodAllTimeCheckBoxChange(Sender: TObject);
    procedure PeriodBeginDateTimePickerChange(Sender: TObject);
    procedure PeriodEndDateTimePickerChange(Sender: TObject);
    procedure ReportTreeListViewCustomItemDraw(sender: TObject;
      eventTyp_cdet: TCustomDrawEventTyp; item: TTreeListItem;
      var defaultDraw: Boolean);
    procedure ReportTreeListViewCustomRecordItemDraw(sender: TObject;
      eventTyp_cdet: TCustomDrawEventTyp; recordItem: TTreeListRecordItem;
      var defaultDraw: Boolean);
    procedure SelectAllTasksButtonClick(Sender: TObject);
    procedure TasksCheckListBoxClickCheck(Sender: TObject);
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
    procedure SetNoDateLimit(AVal: Boolean);
    function GetNoDateLimit: Boolean;

    procedure UpdateTasksList;
    //procedure CMShowingChanged(var AMsg: TMessage); message CM_SHOWINGCHANGED;
    procedure FillReportTree(const AReport: TReport);
    procedure FillReportChart(const AReport: TReport);
    procedure CreateChartLabels;
    procedure UpdateTranslations;
  public
    constructor Create(TheOwner: TComponent); override;

    property BeginDate: TDate read GetBeginDate write SetBeginDate;
    property EndDate: TDate read GetEndDate write SetEndDate;
    property GroupBy: TReportGroupBy read GetGroupBy write SetGroupBy;
    property View: TReportView read GetView write SetView;
    property SelectedTasks: TTaskIds read GetSelectedTasks {write ...};
    property NoDateLimit: Boolean read GetNoDateLimit write SetNoDateLimit;

    procedure UpdateReport;

    procedure OnShow;
  end;

implementation

uses DateUtils, DatabaseDM, Graphics, System.UITypes, fgl, Math{, LCLTranslator};

resourcestring
  RSYears = 'Years';
  RSMonths = 'Months';
  RSDays = 'Days';
  RSTable = 'Table';
  RSChart = 'Chart';

{$R *.lfm}

type
  TBarSeriesMap = specialize TFPGMap<String, TBarSeries>;

{ TReportFrame }

procedure TReportFrame.ViewRadioGroupClick(Sender: TObject);
begin
  View := View;
end;

procedure TReportFrame.GroupByRadioGroupClick(Sender: TObject);
begin
  GroupBy := GroupBy;
end;

procedure TReportFrame.PeriodAllTimeCheckBoxChange(Sender: TObject);
begin
  NoDateLimit := NoDateLimit;
end;

procedure TReportFrame.PeriodBeginDateTimePickerChange(Sender: TObject);
begin
  BeginDate := BeginDate;
end;

procedure TReportFrame.PeriodEndDateTimePickerChange(Sender: TObject);
begin
  EndDate := EndDate;
end;

procedure TReportFrame.ReportTreeListViewCustomItemDraw(sender: TObject;
  eventTyp_cdet: TCustomDrawEventTyp; item: TTreeListItem;
  var defaultDraw: Boolean);
begin
  if (eventTyp_cdet = cdetPrePaint) and (not Assigned(item.Parent)) then
  begin
    if not item.SeemsSelected then
    begin
      (sender as TTreeListView).Canvas.Brush.Color:=clSkyBlue;
    end;

    // (sender as TTreeListView).Canvas.Font.Bold := True;
  end;
  defaultDraw := True;
end;

procedure TReportFrame.ReportTreeListViewCustomRecordItemDraw(sender: TObject;
  eventTyp_cdet: TCustomDrawEventTyp; recordItem: TTreeListRecordItem;
  var defaultDraw: Boolean);
begin
  if (eventTyp_cdet = cdetPrePaint) and (Assigned(recordItem.Parent))
      and (not Assigned(recordItem.Parent.Parent)) then
  begin
    (sender as TTreeListView).Canvas.Font.Bold := True;
  end;
  defaultDraw := True;
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

  UpdateReport;
end;

procedure TReportFrame.TasksCheckListBoxClickCheck(Sender: TObject);
begin
  UpdateReport;
end;

procedure TReportFrame.UpdateReport;
var
  Generator: TReportGenerator = nil;
  Report: TReport = nil;
begin
  Generator := TReportGenerator.Create;

  try
    if not NoDateLimit then
    begin
      Generator.BeginDate := BeginDate;
      Generator.EndDate := EndDate;
    end
    else
    begin
      Generator.BeginDate := MinDateTime;
      Generator.EndDate := MaxDateTime;
    end;

    Generator.GroupBy := GroupBy;
    Generator.Tasks := SelectedTasks;

    try
      Report := Generator.GenerateReport;

      case View of
        rvTable:
          begin
            FillReportTree(Report);
          end;

        rvChart:
          begin
            FillReportChart(Report);
          end;
      end;
    finally
      Report.Free;
    end;
  finally
    Generator.Free;
  end;
end;

procedure TReportFrame.OnShow;
begin
  UpdateTasksList;
  UpdateReport;

  // Translate some strings if not translated yet
  UpdateTranslations;
end;

function TReportFrame.GetBeginDate: TDate;
begin
  //if PeriodAllTimeCheckBox.Checked then
  //  Result := PeriodBeginDateTimePicker.MinDate
  //else
    Result := PeriodBeginDateTimePicker.Date;
end;

procedure TReportFrame.SetBeginDate(ADate: TDate);
begin
  //if PeriodBeginDateTimePicker.Date = ADate then
  //  Exit;

  PeriodBeginDateTimePicker.Date := ADate;

  PeriodEndDateTimePicker.MinDate := ADate;

  UpdateReport;
end;

function TReportFrame.GetEndDate: TDate;
begin
  //if PeriodAllTimeCheckBox.Checked then
  //  Result := PeriodEndDateTimePicker.MaxDate
  //else
    Result := PeriodEndDateTimePicker.Date;
end;

procedure TReportFrame.SetEndDate(ADate: TDate);
begin
  //if PeriodEndDateTimePicker.Date = ADate then
  //  Exit;

  PeriodEndDateTimePicker.Date := ADate;

  PeriodBeginDateTimePicker.MaxDate := ADate;

  UpdateReport;
end;

function TReportFrame.GetGroupBy: TReportGroupBy;
begin
  Result := TReportGroupBy(GroupByRadioGroup.ItemIndex);
end;

procedure TReportFrame.SetGroupBy(AVal: TReportGroupBy);
begin
  //if GroupByRadioGroup.ItemIndex = Ord(AVal) then
  //  Exit;

  GroupByRadioGroup.ItemIndex := Ord(AVal);

  UpdateReport;
end;

function TReportFrame.GetView: TReportView;
begin
  Result := TReportView(ViewRadioGroup.ItemIndex);
end;

procedure TReportFrame.SetView(AVal: TReportView);
begin
  //if ViewRadioGroup.ItemIndex = Ord(AVal) then
  //  Exit;

  ViewRadioGroup.ItemIndex := Ord(AVal);

  UpdateReport;

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

procedure TReportFrame.SetNoDateLimit(AVal: Boolean);
begin
  PeriodAllTimeCheckBox.Checked     := AVal;
  PeriodBeginLabel.Enabled          := not AVal;
  PeriodBeginDateTimePicker.Enabled := not AVal;
  PeriodEndLabel.Enabled            := not AVal;
  PeriodEndDateTimePicker.Enabled   := not AVal;

  UpdateReport;
end;

function TReportFrame.GetNoDateLimit: Boolean;
begin
  Result := PeriodAllTimeCheckBox.Checked;
end;

procedure TReportFrame.UpdateTasksList;
begin
  {TasksCheckListBox.Clear} TaskListFilterEdit.Items.Clear;

  with DatabaseDataModule.CustomSQLQuery do
  begin
    Close;
    SQL.Text := 'SELECT `id`, `name` FROM `tasks` ORDER BY `name` COLLATE UTF8_CI ASC;';
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

{procedure TReportFrame.CMShowingChanged(var AMsg: TMessage);
begin
  inherited;

  if Showing then
  begin
    UpdateTasksList;
    UpdateReport;
  end;
end;   }

procedure TReportFrame.FillReportTree(const AReport: TReport);
    function TimeInSecondsToStr(ASec: Integer): String;
    var
      Days, Hours, Minutes, Seconds: Integer;
    begin
      Days := ASec div SecsPerDay;
      Hours := ASec mod SecsPerDay div SecsPerHour;
      Minutes := ASec mod SecsPerHour div SecsPerMin;
      Seconds := ASec mod 60;
      Result := Format('%d:%.2d:%.2d:%.2d', [
            Days, Hours, Minutes, Seconds
          ]);
    end;

var
  PeriodIdx: Integer;
  Period: String;
  TaskIdx: Integer;
  Task: String;
  TaskTimeSeconds: Integer;
  TaskTime: String;
  PeriodSecondsSum: integer;
begin
  ReportTreeListView.BeginUpdate;
  ReportTreeListView.Items.Clear;

  for PeriodIdx := 0 to AReport.Items.Count - 1 do
  begin
    Period := AReport.Items.Keys[PeriodIdx];
    case GroupBy of
      rgbDay: Period := FormatDateTime({'ddddd'} 'dddddd', ScanDateTime('yyyy-mm-dd', Period));
      rgbMonth: Period := FormatDateTime('mmmm yyyy', ScanDateTime('yyyy-mm-dd', Period + '-01'));
      //rgbYear: Period := AReport.Items.Keys[PeriodIdx];
    end;
    with ReportTreeListView.Items.Add(Period) do
    begin
      PeriodSecondsSum := 0;

      for TaskIdx := 0 to AReport.Items.Data[PeriodIdx].Count - 1 do
      begin
        Task := AReport.Items.Data[PeriodIdx].Keys[TaskIdx];
        TaskTimeSeconds := AReport.Items.Data[PeriodIdx].Data[TaskIdx];
        PeriodSecondsSum += TaskTimeSeconds;
        TaskTime := TimeInSecondsToStr(TaskTimeSeconds);
        SubItems.Add(Task).RecordItems.Add(TaskTime);
      end;

      RecordItems.Add(TimeInSecondsToStr(PeriodSecondsSum));
    end;
  end;

  ReportTreeListView.EndUpdate;
end;

procedure TReportFrame.FillReportChart(const AReport: TReport);
  function FixColorConstant(AColor: TColorRec): TColor;
  { Bug fix for current FPC (v3.2.2 and earlier)
    Issue: https://forum.lazarus.freepascal.org/index.php/topic,60069.0.html
    Fixed by commit (not included in release yet):
        https://gitlab.com/freepascal.org/fpc/source/-/commit/742ec5680f8edfdae744382f565a3fda804b0e5c?view=parallel
  }
  begin
    {$if defined(FPC_FULLVERSION) and (FPC_FULLVERSION <= 030202)}
    Result := RGBToColor(AColor.B, AColor.G, AColor.R);
    {$ELSE}
    {$Fatal  ToDo: Check if it fixed in current FPC version}
    Result := AColor;
    {$ENDIF}
  end;

  function GetDefaultColor(AIdx: Integer): TColor;
  var
    Colors: array of {TColorRec} TColor = (
      TColorRec.DodgerBlue,
      TColorRec.Gold,
      TColorRec.{OrangeRed}Red,
      TColorRec.GreenYellow,
      TColorRec.{DeepPink}Magenta,
      TColorRec.{Sienna}Maroon,
      TCOlorRec.Moccasin,
      TColorRec.Navy,
      TColorRec.MediumSeaGreen,
      TColorRec.Silver,
      TColorRec.DarkOrchid,
      TColorRec.Tomato,
      TColorRec.SpringGreen,
      TColorRec.PaleTurquoise,
      TColorRec.Orange
    );
  begin
    if AIdx in [Low(Colors) .. High(Colors)] then
      Result := FixColorConstant(Colors[AIdx])
    else
      Result := { $ffffff } Random(2 ** 24);
  end;

var
  PeriodIdx: Integer;
  Period: String;
  TaskIdx: Integer;
  Task: String;
  TaskTimeSeconds: Integer;
  BarSeries: TBarSeries;
  BarSeriesMap: TBarSeriesMap;
  BarSeriesIdx: Integer;
  XVal: TDate;
  YVal: Double;
begin
  ReportChart.ClearSeries;

  BarSeriesMap := TBarSeriesMap.Create;
  try
    for PeriodIdx := 0 to AReport.Items.Count - 1 do
    begin
      Period := AReport.Items.Keys[PeriodIdx];
      for TaskIdx := 0 to AReport.Items.Data[PeriodIdx].Count - 1 do
      begin
        Task := AReport.Items.Data[PeriodIdx].Keys[TaskIdx];
        TaskTimeSeconds := AReport.Items.Data[PeriodIdx].Data[TaskIdx];

        BarSeriesIdx := BarSeriesMap.IndexOf(Task);
        if BarSeriesIdx = -1 then
        begin
          BarSeries := TBarSeries.Create(ReportChart);
          BarSeries.Title := Task;
          BarSeries.SeriesColor := GetDefaultColor(BarSeriesMap.Count);
          BarSeriesMap.Add(Task, BarSeries);
        end
        else
        begin
          BarSeries := BarSeriesMap.Data[BarSeriesIdx];
        end;

        case GroupBy of
          rgbYear: XVal := EncodeDate(StrToInt(Period), 1, 1);
          rgbMonth: XVal := ScanDateTime('YYYY-MM-DD', Period + '-01');
          rgbDay: XVal := ScanDateTime('YYYY-MM-DD', Period);
        end;
        YVal := TaskTimeSeconds / 60 / 60;
        BarSeries.AddXY(XVal, YVal{, Period});
      end;
    end;

    for BarSeriesIdx := 0 to BarSeriesMap.Count - 1 do
    begin
      with BarSeriesMap.Data[BarSeriesIdx] do
      begin
        BarWidthStyle := bwPercentMin;
        BarWidthPercent := {Floor}Round(100 / (BarSeriesMap.Count + 1));
        BarOffsetPercent := Round((100 / (BarSeriesMap.Count + 1))
            * (BarSeriesIdx - (BarSeriesMap.Count - 1) / 2));
      end;
      ReportChart.AddSeries(BarSeriesMap.Data[BarSeriesIdx]);
    end;

    CreateChartLabels;

  finally
    BarSeriesMap.Free;
  end;
end;

procedure TReportFrame.CreateChartLabels;
var
  Date: TDate;
begin
  LabelsChartSource.Clear;

  Date := BeginDate;

  while Date <= EndDate do
  begin
    case GroupBy of
      rgbYear:
        begin
          LabelsChartSource.Add(EncodeDate(YearOf(Date), 1, 1), 0,
              FormatDateTime('yyyy', Date));
          Date := IncYear(Date);
        end;

      rgbMonth:
        begin
          LabelsChartSource.Add(EncodeDate(YearOf(Date), MonthOf(Date), 1), 0,
              FormatDateTime('mmmm yyyy', Date));
          Date := IncMonth(Date);
        end;

      rgbDay:
        begin
          LabelsChartSource.Add(Date, 0, FormatDateTime({'ddddd'} 'dddddd', Date));
          Date := IncDay(Date);
        end;
    end;
  end;
end;

procedure TReportFrame.UpdateTranslations;
begin
  with GroupByRadioGroup do
  begin
    Items[0] := RSYears;
    Items[1] := RSMonths;
    Items[2] := RSDays;
  end;

  with ViewRadioGroup do
  begin
    Items[0] := RSTable;
    Items[1] := RSChart;
  end;
end;

constructor TReportFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);

  EndDate := Now;
  BeginDate := IncWeek(EndDate, -1);
  GroupBy := rgbDay;
  View := rvChart;

  //UpdateTasksList;
  //UpdateReport;
end;

end.

