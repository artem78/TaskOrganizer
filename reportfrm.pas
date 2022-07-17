unit ReportFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ExtCtrls, ComboEx,
  CheckLst, TreeListView, TAGraph, DateTimePicker;

type

  { TStatisticsFrame }

  TReportFrame = class(TFrame)
    PeriodBeginDateTimePicker: TDateTimePicker;
    PeriodEndDateTimePicker: TDateTimePicker;
    SelectAllTasksButton: TButton;
    TaskFilterEdit: TEdit;
    ReportChart: TChart;
    SettingsPanel: TPanel;
    UpdateReportButton: TButton;
    TasksCheckListBox: TCheckListBox;
    TasksGroupBox: TGroupBox;
    PeriodBeginLabel: TLabel;
    PeriodEndLabel: TLabel;
    PeriodGroupBox: TGroupBox;
    GroupByRadioGroup: TRadioGroup;
    ReportTreeListView: TTreeListView;
    ViewRadioGroup: TRadioGroup;
  private

  public

  end;

implementation

{$R *.lfm}

end.

