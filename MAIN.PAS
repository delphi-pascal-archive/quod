{$A+,B-,D+,F+,G+,I+,K+,L+,N+,P+,Q+,R+,S+,T+,V+,W+,X+,Y+}
{$IFNDEF Win32}{$M 16384,8192}{$ENDIF}

unit Main;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, Buttons, StdCtrls, WinDlg, About,
  IniFiles;

type
  TPiece = (Empty, Red, Blue, White);
  TPlayers = (RedPlayer, BluePlayer);

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    NewBtn: TSpeedButton;
    Timer1: TTimer;
    AboutBtn: TSpeedButton;
    HelpBtn: TSpeedButton;
    VersusPCBtn: TSpeedButton;
    VersusHumanBtn: TSpeedButton;
    Label1: TLabel;
    Scores: TGroupBox;
    Label2: TLabel;
    BlueWinsLbl: TLabel;
    Label3: TLabel;
    RedWinsLbl: TLabel;
    ClearBtn: TSpeedButton;
    SpeedButton1: TSpeedButton;
    Panel2: TPanel;
    Board: TImage;
    Panel3: TPanel;
    StatusImg: TImage;
    Timer2: TTimer;
    ScrollBar1: TScrollBar;
    ResetBtn: TSpeedButton;
    function  FirstTurn : boolean;
    procedure Move;
    function  StartPotential : boolean;
    function  BlockPotential : boolean;
    function  BlueAttack : boolean;
    function  BlockWithAttacker : boolean;
    function  BlockOffensively : boolean;
    function  BlockWithBlocker : boolean;
    procedure BuildRedMoves;
    procedure BuildBlueMoves;
    function  BlueWinningMove : boolean;
    procedure Computer;
    procedure UpdateWins;
    procedure DeclareWinner(Piece : TPiece);
    procedure CkWinner;
    procedure NextTurn;
    function  LegalSquare(Col, Row : integer) : boolean;
    procedure XYToSquare(X, Y : integer; var Col, Row : integer);
    procedure DrawStatus;
    procedure DrawQuod(Col, Row : integer);
    procedure DrawBoard;
    procedure Timer1Timer(Sender: TObject);
    procedure UpdatePlayer;
    procedure NewGame;
    procedure FormCreate(Sender: TObject);
    procedure NewBtnClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ModeBtnClick(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure BoardMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure VersusPCBtnClick(Sender: TObject);
    procedure VersusHumanBtnClick(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure ResetBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    Squares : array [0..10, 0..10] of TPiece;

    RedQuods : integer;
    RedBlockers : integer;
    BlueQuods : integer;
    BlueBlockers : integer;

    ComputerMove : record
      Col : integer;
      Row : integer;
      Piece : TPiece;
    end;

    RedMovesCnt : integer;
    RedWinningMoves : array[0..1000] of record
      Col : integer;
      Row : integer;
    end;

    BlueMovesCnt : integer;
    BlueMoves : array[0..1000] of record
      Col : integer;
      Row : integer;
    end;

    PlayerTurn : TPlayers;
    ComputerTurn : boolean;
    ComputerMode : boolean;
    TimerCount : integer;
    Turns : integer;
    VersusStr : string[20];

    WinnerPiece : TPiece;
    Winner : boolean;
    BlueWins : integer;
    RedWins : integer;

    PreemptMoves : integer;
  end;

  const
    SquareSize = 40;
    QuodSize = 26;
    QuodStart = (SquareSize - QuodSize) div 2 + 1;
    Center = SquareSize div 2 + 1;
    StatusSpacing = 8;
var
  MainForm: TMainForm;

implementation

{$R *.DFM}

function TMainForm.FirstTurn : boolean;
var
  Col, Row : integer;
begin
  Result:= false;
  if Turns <> 1 then exit;

  repeat
    Col:= 3 + Random(5);
    Row:= 3 + Random(5);
  until Squares[Col, Row] = Empty;

  ComputerMove.Col:= Col;
  ComputerMove.Row:= Row;
  ComputerMove.Piece:= Blue;
  Timer1.Enabled:= true;

  Result:= true;
end;

procedure TMainForm.Move;
var
  Count : integer;
  i, j : integer;
  Col, Row : integer;
begin
  for Count:= 0 to 5 do
    for i:= -Count to Count do
      for j:= -Count to Count do
      begin
        Col:= 5 - i;
        Row:= 5 - j;
        if (LegalSquare(Col, Row)) and
           (Squares[Col, Row] = Empty) then
        begin
          ComputerMove.Col:= Col;
          ComputerMove.Row:= Row;
          ComputerMove.Piece:= Blue;
          Timer1.Enabled:= true;
          exit;
        end;
      end;
end;

function TMainForm.StartPotential : boolean;
var
  Col1, Row1, Col2, Row2 : integer;
  Col3, Row3, Col4, Row4 : integer;
  ColDiff, RowDiff : integer;
begin
  BlueMovesCnt:= 0;

  for Col1:= 0 to 10 do
    for Row1:= 0 to 10 do
      if Squares[Col1, Row1] = Blue then
        for Col2:= 0 to 10 do
          for Row2:= 0 to 10 do
            if (Squares[Col2, Row2] = Empty) and
              ((Col1 <> Col2) or (Row1 <> Row2)) and
               (BlueMovesCnt < 1000 - 3) then
            begin
              ColDiff:= Col2 - Col1;
              RowDiff:= Row2 - Row1;
              Col3:= Col1 - RowDiff;
              Row3:= Row1 + ColDiff;
              Col4:= Col2 - RowDiff;
              Row4:= Row2 + ColDiff;
              if (LegalSquare(Col3, Row3)) and
                 (LegalSquare(Col4, Row4)) and
                 (Squares[Col3, Row3] = Empty) and
                 (Squares[Col4, Row4] = Empty) then
              begin
                BlueMoves[BlueMovesCnt].Col:= Col2;
                BlueMoves[BlueMovesCnt].Row:= Row2;
                inc(BlueMovesCnt);
                BlueMoves[BlueMovesCnt].Col:= Col3;
                BlueMoves[BlueMovesCnt].Row:= Row3;
                inc(BlueMovesCnt);
                BlueMoves[BlueMovesCnt].Col:= Col4;
                BlueMoves[BlueMovesCnt].Row:= Row4;
                inc(BlueMovesCnt);
              end;
            end;

  Result:= BlueAttack;
end;

function TMainForm.BlockPotential : boolean;
var
  Col1, Row1, Col2, Row2 : integer;
  Col3, Row3, Col4, Row4 : integer;
  ColDiff, RowDiff : integer;
begin
  BlueMovesCnt:= 0;

  for Col1:= 0 to 10 do
    for Row1:= 0 to 10 do
      if Squares[Col1, Row1] = Red then
        for Col2:= 0 to 10 do
          for Row2:= 0 to 10 do
            if (Squares[Col2, Row2] = Red) and
              ((Col1 <> Col2) or (Row1 <> Row2)) then
            begin
              ColDiff:= Col2 - Col1;
              RowDiff:= Row2 - Row1;
              Col3:= Col1 - RowDiff;
              Row3:= Row1 + ColDiff;
              Col4:= Col2 - RowDiff;
              Row4:= Row2 + ColDiff;
              if (LegalSquare(Col3, Row3)) and
                 (LegalSquare(Col4, Row4)) and
                 (Squares[Col3, Row3] = Empty) and
                 (Squares[Col4, Row4] = Empty) then
              begin
                BlueMoves[BlueMovesCnt].Col:= Col3;
                BlueMoves[BlueMovesCnt].Row:= Row3;
                inc(BlueMovesCnt);
                BlueMoves[BlueMovesCnt].Col:= Col4;
                BlueMoves[BlueMovesCnt].Row:= Row4;
                inc(BlueMovesCnt);
              end;
            end;

  Result:= BlueAttack;
end;

function TMainForm.BlueAttack : boolean;
var
  i : integer;
begin
  Result:= false;

  if BlueMovesCnt = 0 then exit;

  i:= Random(BlueMovesCnt);
  ComputerMove.Col:= BlueMoves[i].Col;
  ComputerMove.Row:= BlueMoves[i].Row;
  ComputerMove.Piece:= Blue;
  Result:= true;
  Timer1.Enabled:= true;
end;

function TMainForm.BlockWithAttacker : boolean;
var
  i : integer;
begin
  Result:= false;

  if RedMovesCnt = 0 then exit;

  i:= Random(RedMovesCnt);
  ComputerMove.Col:= RedWinningMoves[i].Col;
  ComputerMove.Row:= RedWinningMoves[i].Row;
  ComputerMove.Piece:= Blue;
  Result:= true;
  Timer1.Enabled:= true;
end;

function TMainForm.BlockWithBlocker : boolean;
var
  i : integer;
begin
  Result:= false;

  if (RedMovesCnt = 0) or
     ((RedMovesCnt < 2) and
      (BlueMovesCnt = 0)) or
     (BlueBlockers = 0) then exit;

  i:= Random(RedMovesCnt);
  ComputerMove.Col:= RedWinningMoves[i].Col;
  ComputerMove.Row:= RedWinningMoves[i].Row;
  ComputerMove.Piece:= White;
  Result:= true;
  Timer1.Enabled:= true;
end;

function TMainForm.BlockOffensively : boolean;
var
  i, j : integer;
begin
  Result:= false;

  if (RedMovesCnt <> 1) or
     (BlueMovesCnt = 0) then exit;

  for i:= 0 to RedMovesCnt - 1 do
    for j:= 0 to BlueMovesCnt - 1 do
    begin
      if (RedWinningMoves[i].Col = BlueMoves[j].Col) and
         (RedWinningMoves[i].Row = BlueMoves[j].Row) then
      begin
        ComputerMove.Col:= RedWinningMoves[i].Col;
        ComputerMove.Row:= RedWinningMoves[j].Row;
        ComputerMove.Piece:= Blue;
        Result:= true;
        Timer1.Enabled:= true;
        exit;
      end;
    end;
end;

procedure TMainForm.BuildRedMoves;
var
  Col1, Row1, Col2, Row2 : integer;
  Col3, Row3, Col4, Row4 : integer;
  ColDiff, RowDiff : integer;
begin
  RedMovesCnt:= 0;

  for Col1:= 0 to 10 do
    for Row1:= 0 to 10 do
      if Squares[Col1, Row1] = Red then
        for Col2:= 0 to 10 do
          for Row2:= 0 to 10 do
            if (Squares[Col2, Row2] = Red) and
              ((Col1 <> Col2) or (Row1 <> Row2)) then
            begin
              ColDiff:= Col2 - Col1;
              RowDiff:= Row2 - Row1;
              Col3:= Col1 - RowDiff;
              Row3:= Row1 + ColDiff;
              Col4:= Col2 - RowDiff;
              Row4:= Row2 + ColDiff;
              if (LegalSquare(Col3, Row3)) and
                 (LegalSquare(Col4, Row4)) then
              begin
                if (Squares[Col3, Row3] = Empty) and
                   (Squares[Col4, Row4] = Red) then
                begin
                  RedWinningMoves[RedMovesCnt].Col:= Col3;
                  RedWinningMoves[RedMovesCnt].Row:= Row3;
                  inc(RedMovesCnt);
                end;
                if (Squares[Col3, Row3] = Red) and
                   (Squares[Col4, Row4] = Empty) then
                begin
                  RedWinningMoves[RedMovesCnt].Col:= Col4;
                  RedWinningMoves[RedMovesCnt].Row:= Row4;
                  inc(RedMovesCnt);
                end;
              end;
            end;
end;

procedure TMainForm.BuildBlueMoves;
var
  Col1, Row1, Col2, Row2 : integer;
  Col3, Row3, Col4, Row4 : integer;
  ColDiff, RowDiff : integer;
begin
  BlueMovesCnt:= 0;

  for Col1:= 0 to 10 do
    for Row1:= 0 to 10 do
      if Squares[Col1, Row1] = Blue then
        for Col2:= 0 to 10 do
          for Row2:= 0 to 10 do
            if (Squares[Col2, Row2] = Blue) and
              ((Col1 <> Col2) or (Row1 <> Row2)) then
            begin
              ColDiff:= Col2 - Col1;
              RowDiff:= Row2 - Row1;
              Col3:= Col1 - RowDiff;
              Row3:= Row1 + ColDiff;
              Col4:= Col2 - RowDiff;
              Row4:= Row2 + ColDiff;
              if (LegalSquare(Col3, Row3)) and
                 (LegalSquare(Col4, Row4)) and
                 (Squares[Col3, Row3] = Empty) and
                 (Squares[Col4, Row4] = Empty) then
              begin
                BlueMoves[BlueMovesCnt].Col:= Col3;
                BlueMoves[BlueMovesCnt].Row:= Row3;
                inc(BlueMovesCnt);
                BlueMoves[BlueMovesCnt].Col:= Col4;
                BlueMoves[BlueMovesCnt].Row:= Row4;
                inc(BlueMovesCnt);
              end;
            end;
end;

function TMainForm.BlueWinningMove : boolean;
var
  Col1, Row1, Col2, Row2 : integer;
  Col3, Row3, Col4, Row4 : integer;
  ColDiff, RowDiff : integer;
begin
  Result:= false;

  for Col1:= 0 to 10 do
    for Row1:= 0 to 10 do
      if Squares[Col1, Row1] = Blue then
        for Col2:= 0 to 10 do
          for Row2:= 0 to 10 do
            if (Squares[Col2, Row2] = Blue) and
              ((Col1 <> Col2) or (Row1 <> Row2)) then
            begin
              ColDiff:= Col2 - Col1;
              RowDiff:= Row2 - Row1;
              Col3:= Col1 - RowDiff;
              Row3:= Row1 + ColDiff;
              Col4:= Col2 - RowDiff;
              Row4:= Row2 + ColDiff;
              if (LegalSquare(Col3, Row3)) and
                 (LegalSquare(Col4, Row4)) then
              begin
                if (Squares[Col3, Row3] = Empty) and
                   (Squares[Col4, Row4] = Blue) then
                begin
                  ComputerMove.Col:= Col3;
                  ComputerMove.Row:= Row3;
                  ComputerMove.Piece:= Blue;
                  Result:= true;
                  Timer1.Enabled:= true;
                  exit;
                end;
                if (Squares[Col3, Row3] = Blue) and
                   (Squares[Col4, Row4] = Empty) then
                begin
                  ComputerMove.Col:= Col4;
                  ComputerMove.Row:= Row4;
                  ComputerMove.Piece:= Blue;
                  Result:= true;
                  Timer1.Enabled:= true;
                  exit;
                end;
              end;
            end;
end;

procedure TMainForm.Computer;
begin
  TimerCount:= 0;

  if FirstTurn then exit;

  if BlueWinningMove then exit;

  BuildRedMoves;
  BuildBlueMoves;

  if BlockOffensively then exit;

  if ((Turns > PreemptMoves) or
      (RedMovesCnt > 1)) and
     (BlockWithBlocker) then exit;

  if BlockWithAttacker then exit;

  if BlueAttack then exit;

  if BlockPotential then exit;

  if StartPotential then exit;

  Move;
end;

procedure TMainForm.UpdateWins;
begin
  BlueWinsLbl.Caption:= IntToStr(BlueWins);
  RedWinsLbl.Caption:= IntToStr(RedWins);
end;

procedure TMainForm.DeclareWinner(Piece : TPiece);
begin
  Caption := 'Quod ' + VersusStr;
  with TWinner.Create(Application) do
  try
    case Piece of
      Red   : begin
                inc(RedWins);
                Player.Caption:= 'Red won!';
                Player.Font.Color:= clRed;
              end;
      Blue  : begin
                inc(BlueWins);
                if ComputerMode then
                  Player.Caption:= 'Computer got lucky'
                else
                  Player.Caption:= 'Blue won!';
                Player.Font.Color:= clBlue;
              end;
      Empty : begin
                Player.Caption:= 'Draw';
                Player.Font.Color:= clBlack;
              end;
    end;
    UpdateWins;

    ShowModal;
  finally
    Free;
  end;
end;

procedure TMainForm.CkWinner;
var
  Col1, Row1, Col2, Row2 : integer;
  Col3, Row3, Col4, Row4 : integer;
  ColDiff, RowDiff : integer;
  Piece : TPiece;
begin
  if (RedQuods = 0) and (BlueQuods = 0) then
  begin
    if RedBlockers > BlueBlockers then
      DeclareWinner(Red);
    if BlueBlockers > RedBlockers then
      DeclareWinner(Blue);
    if RedBlockers = BlueBlockers then
      DeclareWinner(Empty);
    Winner:= true;
    exit;
  end;

  for Col1:= 0 to 10 do
    for Row1:= 0 to 10 do
      begin
        Piece:= Squares[Col1, Row1];
        if (Piece = Red) or (Piece = Blue) then
          for Col2:= 0 to 10 do
            for Row2:= 0 to 10 do
              if (Squares[Col2, Row2] = Piece) and
                 ((Col1 <> Col2) or (Row1 <> Row2)) then
              begin
                ColDiff:= Col2 - Col1;
                RowDiff:= Row2 - Row1;
                Col3:= Col1 - RowDiff;
                Row3:= Row1 + ColDiff;
                Col4:= Col2 - RowDiff;
                Row4:= Row2 + ColDiff;
                if (LegalSquare(Col3, Row3)) and
                   (Squares[Col3, Row3] = Piece) and
                   (LegalSquare(Col4, Row4)) and
                   (Squares[Col4, Row4] = Piece) then
                begin
                  with Board.Canvas do
                  begin
                    if Piece = red then
                      Pen.Color:= clRed
                    else
                      Pen.Color:= clBlue;
                    Pen.Width:= 2;
                    MoveTo(Col1 * SquareSize + Center,
                      Row1 * SquareSize + Center);
                    LineTo(Col2 * SquareSize + Center,
                      Row2 * SquareSize + Center);
                    LineTo(Col4 * SquareSize + Center,
                      Row4 * SquareSize + Center);
                    LineTo(Col3 * SquareSize + Center,
                      Row3 * SquareSize + Center);
                    LineTo(Col1 * SquareSize + Center,
                      Row1 * SquareSize + Center);
                  end;
                  Board.Invalidate;
                  Winner:= true;
                  WinnerPiece:= Piece;
                  Timer2.Enabled:= true;
                  exit;
                end;
              end;
      end;
end;

procedure TMainForm.NextTurn;
begin
  if PlayerTurn = RedPlayer then
    PlayerTurn:= BluePlayer
  else
    PlayerTurn:= RedPlayer;

  UpdatePlayer;

  if (PlayerTurn = BluePlayer) and (ComputerMode) then
  begin
    ComputerTurn:= true;
    inc(Turns);
    Computer;
  end
  else
    ComputerTurn:= false;
end;

function TMainForm.LegalSquare(Col, Row : integer) : boolean;
begin
  Result := ((Col>=0) and (Col<=10) and (Row>=1) and (Row<=9)) or
            ((Row>=0) and (Row<=10) and (Col>=1) and (Col<=9));
end;

procedure TMainForm.XYToSquare(X, Y : integer; var Col, Row : integer);
var
  i, j : integer;
begin
  i:= X mod SquareSize;
  j:= Y mod SquareSize;
  if (i < QuodStart) or
     (i > SquareSize - QuodStart) or
     (j < QuodStart) or
     (j > SquareSize - QuodStart) then
  begin
    Col:= -1;
    Row:= -1;
  end
  else
  begin
    Col:= X div SquareSize;
    Row:= Y div SquareSize;
  end;
end;

procedure TMainForm.DrawStatus;
var
  Text : string;
  x, y : integer;
  i, YBase : integer;
begin
  with StatusImg.Canvas do
  begin
    Brush.Color:= clSilver;
    FillRect(ClientRect);
    MoveTo(0, StatusImg.Height div 2);
    LineTo(Width, StatusImg.Height div 2);

    Font.Name:= 'Arial';
    Font.Size:= 9;

    YBase:= 1;
    Text:= 'Blue';
    x:= (StatusImg.Width - TextWidth(Text)) div 2;
    TextOut(x, YBase, Text);

    x:= (StatusImg.Width div 2 - QuodSize) div 2;
    y:= YBase + TextHeight(Text) + StatusSpacing * 20;
    Brush.Color:= clBlue;
    for i:= 0 to BlueQuods - 1 do
    begin
      Ellipse(x, y,  x + QuodSize, y + QuodSize);
      y:= y - StatusSpacing;
    end;

    x:= x + StatusImg.Width div 2;
    y:= YBase + TextHeight(Text) + StatusSpacing * 20;
    Brush.Color:= clWhite;
    for i:= 0 to BlueBlockers - 1 do
    begin
      Ellipse(x, y,  x + QuodSize, y + QuodSize);
      y:= y - StatusSpacing;
    end;

    Brush.Color:= clSilver;
    YBase:= StatusImg.Height div 2 + 1;
    Text:= 'Red';
    x:= (StatusImg.Width - TextWidth(Text)) div 2;
    TextOut(x, YBase, Text);

    x:= (StatusImg.Width div 2 - QuodSize) div 2;
    y:= YBase + TextHeight(Text) + StatusSpacing * 20;
    Brush.Color:= clRed;
    for i:= 0 to RedQuods - 1 do
    begin
      Ellipse(x, y,  x + QuodSize, y + QuodSize);
      y:= y - StatusSpacing;
    end;

    x:= x + StatusImg.Width div 2;
    y:= YBase + TextHeight(Text) + StatusSpacing * 20;
    Brush.Color:= clWhite;
    for i:= 0 to RedBlockers - 1 do
    begin
      Ellipse(x, y,  x + QuodSize, y + QuodSize);
      y:= y - StatusSpacing;
    end;
  end;
end;

procedure TMainForm.DrawQuod(Col, Row : integer);
var
  x, y : integer;
begin
  with Board.Canvas do
  begin
    x:= Col * SquareSize + QuodStart;
    y:= Row * SquareSize + QuodStart;

    case Squares[Col, Row] of
      Empty : Brush.Color:= clSilver;
      Red   : Brush.Color:= clRed;
      Blue  : Brush.Color:= clBlue;
      White : Brush.Color:= clWhite;
    end;

    Pen.Color:= clBlack;

    Ellipse(x, y, x + QuodSize, y + QuodSize);
  end;
end;

procedure TMainForm.DrawBoard;
var
  Col, Row : integer;
begin
  with Board.Canvas do
  begin
    Brush.Color:= clSilver;
    FillRect(ClientRect);
    Pen.Width:= 1;

    for Col:= 0 to 10 do
      for Row:= 0 to 10 do
        if LegalSquare(Col, Row) then
          DrawQuod(Col, Row)
        else
          continue;
  end;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  with ComputerMove do
  begin
    if Odd(TimerCount) then
      Squares[Col, Row]:= Empty
    else
      Squares[Col, Row]:= Piece;
    DrawQuod(Col, Row);

    inc(TimerCount);
    if TimerCount = 3 then
    begin
      Timer1.Enabled:= false;
      if Piece = Blue then
      begin
        dec(BlueQuods);
        DrawStatus;
        CkWinner;
        if Winner then
          exit
        else
          NextTurn;
      end
      else
      begin
        dec(BlueBlockers);
        DrawStatus;
        Computer;
      end;
    end;
  end;
end;

procedure TMainForm.UpdatePlayer;
begin
  if PlayerTurn = RedPlayer then
    Caption := 'Quod ' + VersusStr +
      ' Red''s Turn'
  else
    if ComputerMode then
      Caption := 'Quod ' + VersusStr +
        ' Computer''s Thinking'
    else
      Caption := 'Quod ' + VersusStr +
        ' Blue''s Turn';
end;

procedure TMainForm.NewGame;
var
  Col, Row: integer;
begin
  Timer1.Enabled:= false;
  Timer2.Enabled:= false;
  Turns:= 0;
  PreemptMoves:= Random(5);

  for Col:= 0 to 10 do
    for Row:= 0 to 10 do
      Squares[Col, Row]:= Empty;

  RedQuods:= 20;
  BlueQuods:= 20;
  RedBlockers:= 6;
  BlueBlockers:= 6;

  DrawBoard;
  DrawStatus;

  PlayerTurn:= RedPlayer;
  Winner:= false;
  ComputerTurn:= false;

  if ComputerMode then
    VersusStr := '(Playing Computer)'
  else
    VersusStr:= '(Two Players)';
  Caption := 'Quod ' + VersusStr;
  UpdatePlayer;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.INI')) do
  try
    ComputerMode:= ReadBool('Options', 'Computer Mode', true);
    ScrollBar1.Position:= ReadInteger('Options', 'Speed', 1450);
    BlueWins:= ReadInteger('Wins', 'Blue', 0);
    RedWins:= ReadInteger('Wins', 'Red', 0);
  finally
    Free;
  end;
  ScrollBar1Change(Sender);
  if ComputerMode = false then
    VersusHumanBtn.Down:= true;
  UpdateWins;

  with Panel2 do
  begin
    Width:= SquareSize * 11 + 2;
    Height:= Width;
    Left:= Panel3.Width + 2;
    Top:= 0;
    Board.Width:= Width;
    Board.Height:= Height;
    Board.Left:= 0;
    Board.Top:= 0;
  end;

  with Panel3 do
  begin
    Height:= Panel2.Height;
    Left:= 2;
    Top:= 0;
    StatusImg.Width:= Width;
    StatusImg.Height:= Height - 2;
    StatusImg.Top:= 1;
    StatusImg.Left:= 2;
  end;

  with Panel1 do
  begin
    Canvas.Brush.Color:= clGray;
    Canvas.FillRect(ClientRect);
    Height:= Panel2.Height;
    Left:= Panel2.Width + Panel3.Width + 2;
    Top:= 0;
  end;

  Self.ClientWidth:= Panel1.Width + Panel2.Width + Panel3.Width + 4;
  Self.ClientHeight:= Panel2.Height + 2;

  Randomize;
  NewGame;
end;

procedure TMainForm.NewBtnClick(Sender: TObject);
begin
  NewGame;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

procedure TMainForm.ModeBtnClick(Sender: TObject);
begin
  if ComputerMode then
    ComputerMode:= false
  else
    ComputerMode:= true;
  NewGame;
end;

procedure TMainForm.AboutBtnClick(Sender: TObject);
begin
  with TAboutBox.Create(Application) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TMainForm.HelpBtnClick(Sender: TObject);
begin
  Application.HelpCommand(HELP_CONTENTS, 0);
end;

procedure TMainForm.BoardMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col, Row : integer;
  Piece : TPiece;
begin
  if (ComputerTurn) or (Winner) then
    exit;

  XYToSquare(X, Y, Col, Row);
  if (not LegalSquare(Col, Row)) or
     (Squares[Col, Row] <> Empty) then
    exit;

  if Button = mbRight then
  begin
    Piece:= White;
    if PlayerTurn = RedPlayer then
    begin
      if RedBlockers = 0 then exit;
      dec(RedBlockers);
    end
    else
    begin
      if BlueBlockers = 0 then exit;
      dec(BlueBlockers);
    end;
  end
  else
  begin
    if PlayerTurn = RedPlayer then
    begin
      if RedQuods = 0 then exit;
      Piece:= Red;
      dec(RedQuods);
    end
    else
    begin
      if BlueQuods = 0 then exit;
      Piece:= Blue;
      dec(BlueQuods);
    end;
  end;

  Squares[Col, Row]:= Piece;
  DrawQuod(Col, Row);
  DrawStatus;
  CkWinner;
  if Winner then exit;
  if Piece = White then exit;
  NextTurn;
end;

procedure TMainForm.VersusPCBtnClick(Sender: TObject);
begin
  ComputerMode:= true;
  NewGame;
end;

procedure TMainForm.VersusHumanBtnClick(Sender: TObject);
begin
  ComputerMode:= False;
  NewGame;
end;

procedure TMainForm.ClearBtnClick(Sender: TObject);
begin
  BlueWins:= 0;
  RedWins:= 0;
  UpdateWins;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.INI')) do
  try
    WriteBool('Options', 'Computer Mode', ComputerMode);
    WriteInteger('Options', 'Speed', ScrollBar1.Position);
    WriteInteger('Wins', 'Blue', BlueWins);
    WriteInteger('Wins', 'Red', RedWins);
  finally
    Free;
  end;

end;

procedure TMainForm.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.Timer2Timer(Sender: TObject);
begin
  Timer2.Enabled:= false;
  DeclareWinner(WinnerPiece);
end;

procedure TMainForm.ScrollBar1Change(Sender: TObject);
begin
  with ScrollBar1 do
  begin
    Timer1.Interval:= Max + Min - Position;
    Timer2.Interval:= (Max + Min - Position) * 2;
  end;
end;

procedure TMainForm.ResetBtnClick(Sender: TObject);
begin
  ScrollBar1.Position:= 1450;
  ScrollBar1Change(Sender);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:= MessageDlg('Do you wish to quit Quod?',
    mtConfirmation, [mbYes, mbCancel], 0) = mrYes;
end;

end.
