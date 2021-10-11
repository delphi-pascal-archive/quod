unit Windlg;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TWinner = class(TForm)
    BitBtn1: TBitBtn;
    Player: TLabel;
    Salutation: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Winner: TWinner;

implementation

{$R *.DFM}

end.
