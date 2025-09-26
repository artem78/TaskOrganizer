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

  PriorityComboBox.ItemIndex := (DatabaseDataModule.TasksSQLQuery
                               .FieldByName('priority').AsInteger + 20) div 10;
end;

procedure TTaskEditForm.OKButtonClick(Sender: TObject);
begin
  DatabaseDataModule.TasksSQLQuery.FieldByName('priority').AsInteger
                  := (PriorityComboBox.ItemIndex - 2) * 10;
end;

procedure TTaskEditForm.FormCreate(Sender: TObject);
begin
  with PriorityComboBox do
  begin
    Clear;
    AddItem(RSVeryLowPriority, TObject(PtrUInt(tpVeryLow)));
    AddItem(RSLowPriority, TObject(PtrUInt(tpLow)));
    AddItem(RSNormalPriority, TObject(PtrUInt(tpNormal)));
    AddItem(RSHighPriority, TObject(PtrUInt(tpHigh)));
    AddItem(RSVeryHighPriority, TObject(PtrUInt(tpVeryHigh)));
  end;
end;

end.

