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

uses DateUtils;

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
{*** STUB *** }
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
{*** STUB *** }

end.

