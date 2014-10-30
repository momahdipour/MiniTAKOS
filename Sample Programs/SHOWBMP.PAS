program Using_BMP_Unit;
uses
  BMP,Graph,Crt;
var
  grDriver: Integer;
  grMode: Integer;
  ErrCode: Integer;
  Image: File;
  S:String;
  X,Y:Integer;
  I:Integer;
  ShowMessages:Boolean;

procedure InvalidcommandLine;
begin
  if ShowMessages then
    WriteLn('Invalid command line parameters.Use /? for help.');
  Halt;
end;

begin
  for i:=1 to ParamCount do
    if (ParamStr(i)='/?') or (ParamStr(i)='-?') then
    begin
      WriteLn('4-Bit(16-Color) Bitmap File Viewer');
      WriteLn;
      WriteLn('    Usage: SHOWBMP  [bmpfilespec [/P[milisecs] [/X=xpos] [/Y=ypos] [/N]] | [/?]');
      WriteLn;
      WriteLn(' bmpfilespec:  The bitmap file to show.');
      WriteLn(' /P[milisecs]: Without milisecs pauses to press a key before exiting.');
      WriteLn('               To pause milisecs miliseconds,use an integer number.');
      WriteLn('               Example: SHOWBMP bmpfile /P1000 => Pauses 1 second.');
      WriteLn(' /X=xpos:      Specifies the x coordinate of image position in the screen.');
      WriteLn('               Default is 0 and valid values are 0óxposó639.');
      WriteLn(' /Y=ypos:      Specifies the y coordinate of image position in the screen.');
      WriteLn('               Default is 0 and valid vaues are 0óyposó479.');
      WriteLn(' /N:           Use to display no message in output(even error messages).');
      WriteLn(' /? , -?:      Shows this help message.');
      WriteLn;
      Halt;
    end;

  ShowMessages:=True;
  for i:=1 to ParamCount do
  begin
   S:=ParamStr(i);
   if (S[1]='/') and (UpCase(S[2])='N') and (Length(S)=2) then
   begin
     ShowMessages:=False;
     Break;
   end;
 end;

  if (ParamCount=0) or (ParamCount>5) then
    InvalidCommandLine;
  for i:=2 to ParamCount do
  begin
    S:=ParamStr(i);
    if S[1]<>'/' then
      InvalidCommandLine;
    S[2]:=UpCase(S[2]);
    if (S[2]='X') and (S[3]<>'=') then
      InvalidCommandLine;
    if (S[2]='Y') and (S[3]<>'=') then
      InvalidCommandLine;
    if (S[2]='N') and (Length(S)>2) then
      InvalidCommandLine;
    if (S[2]<>'N') and (S[2]<>'P') and (S[2]<>'X') and (S[2]<>'Y') then
      InvalidCommandLine;
  end;

  Assign(Image,ParamStr(1));
  {$I-}Reset(Image);{$I+}
  if IOResult<>0 then
  begin
    if ShowMessages then
      WriteLn('Error->>> The file "'+ParamStr(1)+'" was not found.');
    Halt;
  end;
  Close(Image);
  grDriver := Detect;
  InitGraph(grDriver, grMode,'');
  ErrCode := GraphResult;
  if ErrCode <> grOk then
  begin
    if ShowMessages then
      Writeln('Graphics error:', GraphErrorMsg(ErrCode));
    Exit;
  end;

  X:=0;
  Y:=0;
  if ParamCount>1 then
  begin
    for i:=2 to ParamCount do
    begin
      S:=ParamStr(i);
      if (S[1]='/') and (UpCase(S[2])='X') and (S[3]='=') then
      begin
        Val(Copy(S,4,Length(S)-3),X,ErrCode);
        if not((ErrCode=0) and (X>=0) and (X<=639)) then
          X:=0;
        Break;
      end;
    end;
    for i:=2 to ParamCount do
    begin
      S:=ParamStr(i);
      if (S[1]='/') and (UpCase(S[2])='Y') and (S[3]='=') then
      begin
        Val(Copy(S,4,Length(S)-3),Y,ErrCode);
        if not((ErrCode=0) and (Y>=0) and (Y<=479)) then
          Y:=0;
        Break;
      end;
    end;
  end;
  load_bmp(X,Y,ParamStr(1));
  Delay(400);

  for i:=2 to ParamCount do
  begin
    S:=ParamStr(i);
    if (UpCase(S[1])='/') and (UpCase(S[2])='P') then
    begin
      if Length(S)=2 then
        ReadKey
      else
      begin
        Val(Copy(S,3,Length(S)-2),grMode,ErrCode);
        if ErrCode=0 then
          Delay(grMode);
      end;
      CloseGraph;
      Halt;
    end;
  end;
  CloseGraph;
end.