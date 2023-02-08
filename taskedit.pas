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
    TaskNameDBEdit: TDBEdit;
    TaskDescriptionDBMemo: TDBMemo;
    TaskNameLabel: TLabel;
    TaskDescriptionLabel: TLabel;
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  TaskEditForm: TTaskEditForm;

implementation

uses DB;

resourcestring
  RSCreateTask = 'Create task';
  RSEditTask = 'Edit task';
  RSSave = 'Save';
  RSCancel = 'Cancel';

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
end;

end.

