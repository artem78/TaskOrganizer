unit Utils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TDuration = TDateTime {Double};

function DurationToStr(ADuration: TDuration): String;
function DurationToStr(ADT1, ADT2: TDateTime): String;

implementation

uses DateUtils;

function DurationToStr(ADuration: TDuration): String;
var
  Days: Integer;
begin
  Assert(ADuration >= 0, 'Duration can''t be negative');

  Days := DaysBetween(0, ADuration);
  Result := '';
  if Days > 0 then
    Result := Result + IntToStr(Days) + '.';
  Result := Result + FormatDateTime('hh:nn:ss', ADuration);
end;

function DurationToStr(ADT1, ADT2: TDateTime): String;
var
  Days: Integer;
begin
  Assert(ADT2 >= ADT1, 'Duration can''t be negative');

  Days := DaysBetween(ADT2, ADT1);
  Result := '';
  if Days > 0 then
    Result := Result + IntToStr(Days) + '.';
  Result := Result + FormatDateTime('hh:nn:ss', ADT2 - ADT1);
end;

end.

