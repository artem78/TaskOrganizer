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
  I, taskid: integer;
  d: TTaskTotalTimeMap;
  year, startyear, endyear: integer;
begin
  Result := TReport.Create;

  startyear := yearof(BeginDate);
  endyear := yearof(EndDate);

  for year := startyear to endyear do
  begin
    d := TTaskTotalTimeMap.Create;
    for taskid:=0 to {9}{4}4 do
    begin
      If Random > 0{.5} then
      begin
        d.Add('task ' + inttostr(taskid), Random(8*60*60));
      end;
    end;

    Result.Items.Add(inttostr(year), d);
  end;
end;
{*** STUB *** }

end.

