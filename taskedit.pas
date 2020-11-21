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
    Label1: TLabel;
    Label2: TLabel;
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  TaskEditForm: TTaskEditForm;

implementation

{$R *.lfm}

{ TTaskEditForm }


procedure TTaskEditForm.FormShow(Sender: TObject);
var
  Id: Integer;
begin
  Id := DataModule1.TasksDataset.FieldByName('id').AsInteger;
  if Id = 0 then
    Caption := 'Create task'
  else
    Caption := 'Edit task';
end;

end.

