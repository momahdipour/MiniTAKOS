program Convert_binary_files_to_assembly_hex_format;
Const
  asm_first_line:String='        RAW_DATA                LABEL                   BYTE';
  asm_line_start:String='                DB       ';

function GetCurVer:String;
begin
  GetCurVer:='0.1';
end;

function GetCurYear:String;
begin
  GetCurYear:='2005';
end;

procedure ShowBanner;
begin
  WriteLn('MiniTAK binary to assembly convertor version ',GetCurVer,' , ',GetCurYear);
  WriteLn('By M. Mehdipour');
  WriteLn;
end;

procedure ShowErrorMsg(ErrCode:Integer);
begin
  Case ErrCode Of
    0:
      begin
        WriteLn('       Usage: BIN2ASM  source  [destination]');
        WriteLn;
        WriteLn('Converts the "source" file (as a binary file) to its equivalent in assembly ');
        WriteLn('language(MASM syntax) into "destination" file.');
      end;
    1:
      begin
        WriteLn('Error. Specify a source and/or a destination filename.');
      end;
    2:
      begin
        WriteLn('Error in reading from the source file "',ParamStr(1),'"');
      end;
    3:
      begin
        WriteLn('Error in writing to the destination file "',ParamStr(2),'"');
      end;
  end;
end;

function ExtractFileName(FName:String):String;
var
  i,FNameIndex:Word;
  Result:String;
begin
  FNameIndex:=1;
  for i:=1 to Length(FName) do
    if FName[i]='\' then
      FNameIndex:=i+1;
  Result:='';
  for i:=FNameIndex to Length(FName) do
    if FName[i]='.' then
      Break
    else
      Result:=Result+Copy(FName,i,1);
  ExtractFileName:=Result;
end;
function ExtractFilePath(FName:String):String;
var
  i,FNameIndex:Word;
  Result:String;
begin
  FNameIndex:=1;
  for i:=1 to Length(FName) do
    if FName[i]='\' then
      FNameIndex:=i+1;
  Result:='';
  if FNameIndex>1 then
    Result:=Copy(FName,1,FNameIndex-1);
  ExtractFilePath:=Result;
end;

function DecToHex(Num:Byte):String;
Var
  Hex:String;
  B1,B2:Byte;
begin
  B1:=Num;
  B2:=Num;
  B1:=B1 and $F0;
  B1:=B1 shr 4;
  B2:=B2 and $0F;
  Hex:='';
  if B1<=9 then
    Hex:=Hex+' '+Chr(B1+Ord('0'))
  else
    Hex:=Hex+'0'+Chr(B1+Ord('A')-10);
  if B2<=9 then
    Hex:=Hex+Chr(B2+Ord('0'))
  else
    Hex:=Hex+Chr(B2+Ord('A')-10);
  DecToHex:=Hex;
end;

var
  fin:File;
  fout:TEXT;
  OutFileName:String;
  Buf:array[1..1024] of Byte;
  NumRead:Word;
  ColCount:Byte;
  I:LongInt;
begin
  ShowBanner;
  if ParamCount=0 then
  begin
    ShowErrorMsg(0);
  end
  else if ParamCount>2 then
  begin
    ShowErrorMsg(1);
  end
  else
  begin
    if ParamCount>1 then
      OutFileName:=ParamStr(2)
    else
      OutFileName:=ExtractFilePath(ParamStr(1))+ExtractFileName(ParamStr(1))+'.INC';
    Assign(fin,ParamStr(1));
    Assign(fout,OutFileName);
    {$I-}
    Reset(fin,1);
    {$I+}
    if IOResult<>0 then
    begin
      ShowErrorMsg(2);
      Halt(1);
    end;
    {$I-}
    Rewrite(fout);
    {$I+}
    if IOResult<>0 then
    begin
       Close(fin);
       ShowErrorMsg(3);
       Halt(1);
    end;

    WriteLn(fout,';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
    Write(fout,';Assembly Equivalent Of ',PAramStr(1));
    for i:=1 to (76-Length(ParamStr(1))-23) do
      Write(fout,' ');
     WriteLn(fout,';');
    Write(fout,';Converted By MiniTAK BIN2ASM Version ',GetCurVer,' , ',GetCurYear);
    for i:=1 to (76-Length(GetCurVer)-Length(GetCurYear)-40) do
      Write(fout,' ');
     WriteLn(fout,';');
    WriteLn(fout,';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
    WriteLn(fout);
    WriteLn(fout,asm_first_line);
    ColCount:=0;
    write(fout,asm_line_start);
    BlockRead(fin,Buf,1024,NumRead);
    while(NumRead>0) do
    begin
      for i:=1 to NumRead do
      begin
        if ColCount=10 then
        begin
          ColCount:=0;
          WriteLn(fout);
          Write(fout,asm_line_start);
        end;
        Inc(ColCount);
        if ColCount<>1 then
          Write(fout,',');
        Write(fout,DecToHex(Buf[i]),'H');
      end;
      BlockRead(fin,Buf,1024,NumRead);
    end;
    Close(fin);
    Close(fout);
    WriteLn(ParamStr(1),' successfully converted to ',OutFileName,'.');
  end;
end.

