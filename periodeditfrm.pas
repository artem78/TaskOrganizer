unit PeriodEditFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, DBCtrls,
  ButtonPanel, DBDateTimePicker, DatabaseDM;

type

  { TPeriodEditForm }

  TPeriodEditForm = class(TForm)
    EndDateTimePicker: TDBDateTimePicker;
    ButtonPanel: TButtonPanel;
    DurationLabel: TLabel;
    TaskDBLookupComboBox: TDBLookupComboBox;
    BeginLabel: TLabel;
    BeginDateTimePicker: TDBDateTimePicker;
    EndLabel: TLabel;
    TaskLabel: TLabel;
    procedure BeginDateTimePickerChange(Sender: TObject);
    procedure EndDateTimePickerChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure RefreshDuration;
  public

  end;

var
  PeriodEditForm: TPeriodEditForm;

implementation

uses DB, DateUtils, StrUtils, Utils;

resourcestring
  RSCreatePeriod = 'Create period';
  RSEditPeriod = 'Edit period';
  RSSave = 'Save';
  RSCancel = 'Cancel';

type

  { TMyDBDateTimePicker }

  TMyDBDateTimePicker = class(TDBDateTimePicker)
    public
      function VisibleDateTime: TDateTime;
  end;

{$R *.lfm}


// https://stackoverflow.com/a/9887684
procedure PatchInstanceClass(Instance: TObject; NewClass: TClass);
type
  PClass = ^TClass;
begin
  if Assigned(Instance) and Assigned(NewClass)
    and NewClass.InheritsFrom(Instance.ClassType)
    and (NewClass.InstanceSize = Instance.InstanceSize) then
  begin
    PClass(Instance)^ := NewClass;
  end;
end;

{ TMyDBDateTimePicker }

// Access protected property of base class
function TMyDBDateTimePicker.VisibleDateTime: TDateTime;
begin
  Result := DateTime;
end;

{ TPeriodEditForm }

procedure TPeriodEditForm.FormShow(Sender: TObject);
begin
  case DatabaseDataModule.PeriodsSQLQuery.State of
       dsInsert: Caption := RSCreatePeriod;
       dsEdit:   Caption := RSEditPeriod;
       else      Caption := '???';
  end;

  ButtonPanel.OKButton.Caption := RSSave;
  ButtonPanel.CancelButton.Caption := RSCancel;

  //ActiveControl.SetFocus;
  TaskDBLookupComboBox.SetFocus;

  RefreshDuration;
end;

procedure TPeriodEditForm.RefreshDuration;
var
  BeginDT, EndDT: TDateTime;
begin
  PatchInstanceClass(BeginDateTimePicker, TMyDBDateTimePicker);
  PatchInstanceClass(EndDateTimePicker, TMyDBDateTimePicker);

  BeginDT := (BeginDateTimePicker as TMyDBDateTimePicker).VisibleDateTime;
  EndDT := (EndDateTimePicker as TMyDBDateTimePicker).VisibleDateTime;

  DurationLabel.Caption := DurationToStr(BeginDT, EndDT);
end;

procedure TPeriodEditForm.BeginDateTimePickerChange(Sender: TObject);
begin
  RefreshDuration;
end;

procedure TPeriodEditForm.EndDateTimePickerChange(Sender: TObject);
begin
  RefreshDuration;
end;

end.

