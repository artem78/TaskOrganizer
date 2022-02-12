unit taskedit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DbCtrls, ButtonPanel, datamodule;

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

{$R *.lfm}

{ TTaskEditForm }


procedure TTaskEditForm.FormShow(Sender: TObject);
begin
  case DataModule1.TasksSQLQuery.State of
       dsInsert: Caption := 'Create task';
       dsEdit:   Caption := 'Edit task';
       else      Caption := '???';
  end;
end;

end.

