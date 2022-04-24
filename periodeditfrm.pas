unit PeriodEditFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, DBCtrls,
  ButtonPanel, DBDateTimePicker, DatabaseDM;

type

  { TPeriodEditForm }

  TPeriodEditForm = class(TForm)
    BeginDateTimePicker1: TDBDateTimePicker;
    ButtonPanel: TButtonPanel;
    TaskDBLookupComboBox: TDBLookupComboBox;
    BeginLabel: TLabel;
    BeginDateTimePicker: TDBDateTimePicker;
    EndLabel: TLabel;
    TaskLabel: TLabel;
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  PeriodEditForm: TPeriodEditForm;

implementation

uses DB;

{$R *.lfm}

{ TPeriodEditForm }

procedure TPeriodEditForm.FormShow(Sender: TObject);
begin
  case DatabaseDataModule.PeriodsSQLQuery.State of
       dsInsert: Caption := 'Create period';
       dsEdit:   Caption := 'Edit period';
       else      Caption := '???';
  end;

  //ActiveControl.SetFocus;
  TaskDBLookupComboBox.SetFocus;
end;

end.

