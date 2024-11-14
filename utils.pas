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
function ExtractIntFromStr(const AStr:string): Integer;

implementation

uses DateUtils, Character;

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

function ExtractIntFromStr(const AStr: string): Integer;
var
  S:string='';
  C:char {TCharacter};
begin
  for c in astr do
  begin
    if IsDigit(c) then
      s:=s+c;

    if (not IsDigit(c)) and (not s.IsEmpty) then
      Break;
  end;

  if s='' then
    raise Exception.CreateFmt('Can''t extract integer from string "%s"', [astr]);

  Result:=StrToInt(s);
end;

end.

