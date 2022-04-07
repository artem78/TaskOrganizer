unit Utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function DateTimeToISO8601(DT: TDateTime): String;

implementation

function DateTimeToISO8601(DT: TDateTime): String;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:mm:ss', DT);
end;

end.

