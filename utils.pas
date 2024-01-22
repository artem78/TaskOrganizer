unit Utils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TDuration = TDateTime {Double};

function DurationToStr(ADuration: TDuration): String;
function DurationToStr(ADT1, ADT2: TDateTime): String;
function DurationToStr(ASeconds: Integer): String;

implementation

uses DateUtils;

resourcestring
  RSDayUnitShort = 'd';

function DurationToStr(ADuration: TDuration): String;
var
  Days: Integer;
begin
  Assert(ADuration >= 0, 'Duration can''t be negative');

  Days := DaysBetween(0, ADuration);
  Result := '';
  if Days > 0 then
    Result := Result + IntToStr(Days) + RSDayUnitShort + ' ';
  Result := Result + FormatDateTime('hh:nn:ss', ADuration);
end;

function DurationToStr(ADT1, ADT2: TDateTime): String;
var
  D: TDuration;
begin
  D := ADT2 - ADT1;
  Result := DurationToStr(D);
end;

function DurationToStr(ASeconds: Integer): String;
var
  D: TDuration;
begin
  D := IncSecond(0, ASeconds);
  Result := DurationToStr(D);
end;

end.

