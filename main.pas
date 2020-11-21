unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, tasks, taskedit, datamodule;

type

  { TMainForm }

  TMainForm = class(TForm)
    TasksFrame1: TTasksFrame;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

end.

