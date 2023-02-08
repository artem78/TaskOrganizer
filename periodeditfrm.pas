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

resourcestring
  RSCreatePeriod = 'Create period';
  RSEditPeriod = 'Edit period';
  RSSave = 'Save';
  RSCancel = 'Cancel';

{$R *.lfm}

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
end;

end.

