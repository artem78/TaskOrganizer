unit Reports;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type

  TTaskTotalTimeMap = specialize TFPGMap<String, Integer>;

  TPeriodDataMap = specialize TFPGMap<string, TTaskTotalTimeMap>;

  { TReport }

  TReport = class
    public
      Items: TPeriodDataMap;

      constructor Create;
      destructor Destroy; override;
  end;

  TReportGroupBy = (rgbYear, rgbMonth, rgbDay);

  TTaskIds = array of Integer;

  { TReportGenerator }

  TReportGenerator = class
    private

    public
      BeginDate: TDateTime;
      EndDate: TDateTime;
      GroupBy: TReportGroupBy;
      Tasks: TTaskIds;

      function GenerateReport: TReport;
  end;

implementation

uses DateUtils, StrUtils, DatabaseDM;

{ TReport }

constructor TReport.Create;
begin
  Items := TPeriodDataMap.Create;
end;

destructor TReport.Destroy;
begin
  inherited Destroy;

  Items.Free;
end;

{ TReportGenerator }

function TReportGenerator.GenerateReport: TReport;
(*{*** STUB *** }
var
  taskid: integer;
  d: TTaskTotalTimeMap;
  date: tdate;
  p: string;
begin
  Result := TReport.Create;

  date := BeginDate;

  while date <= EndDate do
  begin
    d := TTaskTotalTimeMap.Create;
    for taskid:=0 to {9}{4}4 do
    begin
      If Random > 0{.5} then
      begin
        d.Add('task ' + inttostr(taskid), Random(8*60*60));
      end;
    end;

    case GroupBy of
      rgbYear: p := FormatDateTime('YYYY', date);
      rgbMonth: p := FormatDateTime('YYYY-MM', date);
      rgbDay: p := FormatDateTime('YYYY-MM-DD', date);
    end;
    Result.Items.Add(p, d);

    case GroupBy of
      rgbYear: date := IncYear(date);
      rgbMonth: date := IncMonth(date);
      rgbDay: date := IncDay(date);
    end;
  end;
end;
{*** STUB *** }  *)
var
  d: TTaskTotalTimeMap;
  p: String;
  TableName: String;
  TaskId: Integer;
  TaskIdList: TStringList;
  BeginDateStr, EndDateStr: String;
  FilterDateFmt: String;
begin
  Result := TReport.Create;

  ////////
  if DatabaseDataModule=nil then exit;
  ////////

  TaskIdList := TStringList.Create;
  TaskIdList.Delimiter := ',';
  for TaskId in Tasks do
    TaskIdList.Add(IntToStr(TaskId));

  case GroupBy of
    rgbYear: TableName := 'duration_per_year_and_task';
    rgbMonth: TableName := 'duration_per_month_and_task';
    rgbDay: TableName := 'duration_per_day_and_task';
  end;

  case GroupBy of
    rgbYear:  FilterDateFmt := 'yyyy';
    rgbMonth: FilterDateFmt := 'yyyy-mm';
    rgbDay:   FilterDateFmt := 'yyyy-mm-dd';
  end;

  (*case GroupBy of
    //rgbYear;
    //rgbMonth;
    rgbDay:
      begin*)
        with DatabaseDataModule.CustomSQLQuery do
        begin
          Close;
          SQL.Text := 'SELECT `date`, task_id, tasks.name as `task_name`, duration, tasks.done as `task_done` '
                    + 'FROM /*:tbl*/ `' + TableName + '` '
                    + 'INNER JOIN tasks ON tasks.id = task_id '
                    + 'WHERE task_id IN (' + TaskIdList.DelimitedText + ')';
          //ParamByName('tbl').AsString := TableName;

          if (BeginDate > MinDateTime) {or} and (EndDate < MaxDateTime) then
          begin // Small SQL query optimization
            SQL.Append(' AND (`date` BETWEEN :begin_date AND :end_date)');

            //ParamByName('begin_date').AsDate := BeginDate;
            //ParamByName('end_date').AsDate := EndDate;
            DateTimeToString(BeginDateStr, FilterDateFmt, BeginDate);
            ParamByName('begin_date').AsString := BeginDateStr;
            DateTimeToString(EndDateStr, FilterDateFmt, EndDate);
            ParamByName('end_date').AsString := EndDateStr;
          end;

          Open;
          First;
          while not EOF do
          begin
            p := {FormatDateTime('YYYY-MM-DD', FieldByName('date').AsDateTime)} FieldByName('date').AsString;
            if not Result.Items.TryGetData(p, d) then
            begin
              d := TTaskTotalTimeMap.Create;
              Result.Items.Add(p, d);
            end;

            d.Add(FieldByName('task_name').AsString + IfThen(FieldByName('task_done').AsBoolean, ' (done)', ''),
                  Round(FieldByName('duration').AsFloat * 60 *60 *24));

            Next;
          end;
          Close;
        end;
      {end;
  end;}

  TaskIdList.Free;
end;

end.

