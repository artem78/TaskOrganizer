unit taskedit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DbCtrls, ButtonPanel, DatabaseDM;

type

  { TTaskEditForm }

  TTaskEditForm = class(TForm)
    ButtonPanel1: TButtonPanel;
    PriorityComboBox: TComboBox;
    PriorityLabel: TLabel;
    TaskNameDBEdit: TDBEdit;
    TaskDescriptionDBMemo: TDBMemo;
    TaskNameLabel: TLabel;
    TaskDescriptionLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  TaskEditForm: TTaskEditForm;

implementation

uses DB, Models;

resourcestring
  RSCreateTask = 'Create task';
  RSEditTask = 'Edit task';
  RSSave = 'Save';
  RSCancel = 'Cancel';
  RSVeryLowPriority = 'Very low';
  RSLowPriority = 'Low';
  RSNormalPriority = 'Normal';
  RSHighPriority = 'High';
  RSVeryHighPriority = 'Very high';

{$R *.lfm}

{ TTaskEditForm }


procedure TTaskEditForm.FormShow(Sender: TObject);
var
  Priority: Integer;
begin
  case DatabaseDataModule.TasksSQLQuery.State of
       dsInsert: Caption := RSCreateTask;
       dsEdit:   Caption := RSEditTask;
       else      Caption := '???';
  end;

  ButtonPanel1.OKButton.Caption := RSSave;
  ButtonPanel1.CancelButton.Caption := RSCancel;

  //ActiveControl.SetFocus;
  TaskNameDBEdit.SetFocus;

  Priority := DatabaseDataModule.TasksSQLQuery.FieldByName('priority').AsInteger;
  PriorityComboBox.ItemIndex := PriorityComboBox.Items
          .IndexOfObject(TObject(PtrUInt(Priority)));
end;

procedure TTaskEditForm.OKButtonClick(Sender: TObject);
var
  Priority: Integer;
begin
  Priority := {PtrUInt}PtrInt(PriorityComboBox.Items.Objects[PriorityComboBox.ItemIndex]);
  DatabaseDataModule.TasksSQLQuery.FieldByName('priority').AsInteger := Priority;
end;

procedure TTaskEditForm.FormCreate(Sender: TObject);
begin
  with PriorityComboBox do
  begin
    Clear;
    AddItem(RSVeryHighPriority, TObject(PtrUInt(tpVeryHigh)));
    AddItem(RSHighPriority, TObject(PtrUInt(tpHigh)));
    AddItem(RSNormalPriority, TObject(PtrUInt(tpNormal)));
    AddItem(RSLowPriority, TObject(PtrUInt(tpLow)));
    AddItem(RSVeryLowPriority, TObject(PtrUInt(tpVeryLow)));
  end;
end;

end.

