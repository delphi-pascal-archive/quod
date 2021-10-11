program Quod;

uses
  Forms,
  Main in 'MAIN.PAS' {MainForm},
  Windlg in 'WINDLG.PAS' {Winner},
  About in 'ABOUT.PAS' {AboutBox};

{$R *.RES}

begin
  Application.Title := 'Quod';
  Application.HelpFile := 'Quod.hlp';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
