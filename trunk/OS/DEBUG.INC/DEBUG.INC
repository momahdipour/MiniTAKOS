;;MiniDebug Version 1.0: Macro Debug Package Utility
;;        %OUT ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;;        %OUT ³ MiniDebug Version 1.0: Macro Debug Package Utility ³
;;        %OUT ³ By M. Mehdipour                        (C)Freeware ³
;;        %OUT ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;;;;;;;;;;;;;;;;;;;;;;;;;;;  Available commands  ;;;;;;;;;;;;;;;;;;;;;;;;;
;;dBeep [Duration(in milliscnds)]
;;dCharOut      Char[,Count]
;;dClearCharAtPos
;;dClearLine    [Row]
;;dClearScreen
;;dClearToEol
;;dDefineAll
;;dDisable
;;dEnable
;;dGetChar      Output
;;dMemDump      Segment,Offset,Length
;;dNewLine      [Text(to display in the new line)]
;;dRestorePos
;;dSavePos
;;dSetPos       NewRow,NewCol
;;dSetRow       NewRow
;;dSetCol       NewCol
;;dShowRegisters        [Row]
;;dTextOut      Text[,Row,Col]
;;dTextOutOffset        Offset(in DS)[,Row,Col]
;;dWriteDecByte Value[,Row,Col]
;;dWriteDecWord Value[,Row,Col]
;;dWriteHexByte Value[,Row,Col]
;;dWriteHexWord Value[,Row,Col]
;;dWaitKey      [KeyCode]
;;dWaitMili     MilliScnds
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dHelp   MACRO   Topic
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <Topic>
          %OUT ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
          %OUT ³                  MiniDebug Instructions Summary                 ³
          %OUT ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
          %OUT ³dBeep           [Duration]      ³dSetPos         NewRow,NewCol   ³
          %OUT ³dCharOut        Char[,Count]    ³dShowRegisters  [Row]           ³
          %OUT ³dClearCharAtPos                 ³dTextOut        Text[,Row,Col]  ³
          %OUT ³dClearLine      [LineRow]       ³dTextOutOffset  Offset[,Row,Col]³
          %OUT ³dClearScreen                    ³dWriteDecByte   Value[,Row,Col] ³
          %OUT ³dClearToEol                     ³dWriteDecWord   Value[,Row,Col] ³
          %OUT ³dDisable                        ³dWriteHexByte   Value[,Row,Col] ³
          %OUT ³dEnable                         ³dWriteHexWord   Value[,Row,Col] ³
          %OUT ³dNewLine        [Text]          ³dWaitKey        [KeyCode]       ³
          %OUT ³dRestorePos                     ³dWaitMili       MilliScnds      ³
          %OUT ³dSavePos                        ³dSetRow         NewRow          ³
          %OUT ³dMemDump   Segment,Offset,Length³dSetCol         NewCol          ³
          %OUT ³dDefineAll                      ³dGetChar        Output          ³
          %OUT ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        ENDIF
ENDM

;************************************************

dSavePos        MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dSavePos
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_SPOS_INDEX=0
        DEBUG_SPOS_MAX=0
        DEBUG_DEFINE_GET_CURSOR_POS
dSavePos        MACRO   InvalidArg
        LOCAL   CONTINUE
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dSavePos
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_SPos_Index=Debug_SPos_Index+1
        IF Debug_SPos_Index GT Debug_SPos_Max
          Debug_SPos_Max=Debug_SPos_Max+1
          JMP   Short CONTINUE

          DEBUG_DEF_VAR D_SPOS_VAR,%Debug_SPos_Max,W,?
          CONTINUE:
        ENDIF

        Debug_PUSH_Flags
        PUSH    DX
        CALL    Debug_Get_Cursor_Pos
        DEBUG_MOVE_VAR  D_SPOS_VAR,%Debug_SPos_Index,DX,CS
        POP     DX
        Debug_POP_Flags
ENDM
        dSavePos
ENDM

;************************************************

dRestorePos     MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dRestorePos
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFE Debug_SPos_Index
          EXITM
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_SET_CURSOR_ROW_COL
        PUSH    CX
        DEBUG_MOVE_FROM_VAR     D_SPos_Var,%Debug_SPos_Index,CX,CS
        Debug_SPos_Index=Debug_SPos_Index-1
        CALL    Debug_Set_Cursor_ROW_COL
        POP     CX
        Debug_POP_Flags
ENDM

;************************************************

dSetRow MACRO   NewRow1,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dSetRow
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <NewRow1>
          %OUT > Debug Error: Not enough actual parameters for dSetRow
          %OUT SYNTAX: dSetRow  NewRow
          .ERR
          EXITM
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_SET_CURSOR_ROW_COL

        PUSH    CX
        MOV     CH,NewRow1
        MOV     CL,0FFH
        CALL    Debug_Set_Cursor_Row_Col
        POP     CX
        Debug_POP_Flags
ENDM

;************************************************

dSetCol MACRO   NewCol1,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dSetCol
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <NewCol1>
          %OUT > Debug Error: Not enough actual parameters for dSetCol
          %OUT SYNTAX: dSetCol  NewCol
          .ERR
          EXITM
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_SET_CURSOR_ROW_COL

        PUSH    CX
        MOV     CL,NewCol1
        MOV     CH,0FFH
        CALL    Debug_Set_Cursor_Row_Col
        POP     CX
        Debug_POP_Flags
ENDM

;************************************************

dSetPos MACRO   NewRow,NewCol,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dSetPos
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <NewRow>
          %OUT > Debug Warning: dSetPos was used without any parameters
          EXITM
        ENDIF
        IFNB <NewRow>
          IFB <NewCol>
            %OUT > Debug Error: Not enough actual parameters for dSetPos
            .ERR
            EXITM
          ENDIF
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_SET_CURSOR_ROW_COL

        PUSH    CX
        MOV     CH,NewRow
        MOV     CL,NewCol
        CALL    Debug_Set_Cursor_Row_Col
        POP     CX
        Debug_POP_Flags
ENDM

;************************************************

dNewLine        MACRO   Text,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dNewLine
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_NEW_LINE

        CALL    Debug_New_Line
        IFNB <Text>
          dTextOut      Text
        ENDIF
        Debug_POP_Flags
ENDM

;************************************************

dCharOut        MACRO   Char,Count,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dCharOut
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <Char>
          %OUT > Debug Warning: dCharOut was used without any parameters
        ENDIF
        Debug_PUSH_Flags

        PUSH    AX
        MOV     AL,Char
        IFNB <Count>
          DEBUG_DEFINE_CHAR_OUT
          PUSH    CX
          MOV CL,Count
          XOR CH,CH
          CALL    Debug_Char_Out
          POP     CX
        ELSE
          MOV   AH,0EH
          INT   10H
        ENDIF
        POP     AX
        Debug_POP_Flags
ENDM

;************************************************

dASCIICharOut   MACRO   Char,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dASCIICharOut
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <Char>
          %OUT > Debug Warning: dASCIICharOut was used without any parameters
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_ASCII_CHAR_OUT

        PUSH    AX
        MOV     AL,Char
        CALL    Debug_ASCII_Char_Out
        POP     AX
        Debug_POP_Flags
ENDM

;************************************************

dGetChar        MACRO   Output,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dGetChar
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <Output>
          %OUT > Debug Error: Not enough actual parameters for dGetChar
          .ERR
          EXITM
        ENDIF
        Debug_PUSH_Flags
        IFIDN <AL>,<Output>
          PUSH  BX
        ENDIF
        IFIDN <AH>,<Output>
          PUSH  BX
        ENDIF
        PUSH  AX
        XOR   AH,AH
        INT   16H
        IFIDN <AL>,<Output>
          POP BX
          MOV AH,BH
          POP BX
          Debug_POP_Flags
          EXITM
        ENDIF
        IFIDN <AH>,<Output>
          MOV AH,AL
          POP BX
          MOV AL,BL
          POP BX
          Debug_POP_Flags
          EXITM
        ENDIF
        MOV   Output,AL
        POP   AX
        Debug_POP_Flags
ENDM

;************************************************

dEnable MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dEnable
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFE Debug_Enabled_Flag
          %OUT MiniDebug: Enabled.
        ENDIF
        Debug_Enabled_Flag=1
ENDM

;************************************************

dDisable        MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dDisable
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IF Debug_Enabled_Flag
          %OUT MiniDebug: Disabled.
        ENDIF
        Debug_Enabled_Flag=0
ENDM

;************************************************

dClearScreen    MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dClearScreen
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_CLEAR_SCREEN

        CALL    Debug_Clear_Screen
        Debug_POP_Flags
ENDM

;************************************************

dClearLine      MACRO   Row,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dClearLine
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_CLEAR_LINE

        PUSH    AX
        IFNB <Row>
          MOV   AL,Row
        ELSE
          MOV   AL,0FFH
        ENDIF
        CALL    Debug_Clear_Line
        POP     AX
        Debug_POP_Flags
ENDM

;************************************************

dClearCharAtPos MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dClearCharAtPos
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_CLEAR_CHAR_AT_POS

        CALL    Debug_Clear_Char_At_Pos
        Debug_POP_Flags
ENDM

;************************************************

dClearToEol     MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dClearToEol
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_CLEAR_TO_EOL

        CALL    Debug_Clear_To_Eol
        Debug_POP_Flags
ENDM

;************************************************

dTextOut        MACRO   Text,Row,Col,InvalidArg
        LOCAL   CONTINUE,STRING
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dTextOut
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <Text>
          %OUT > Debug Warning: dTextOut was used without any parameters
          EXITM
        ENDIF

        Debug_PUSH_Flags
        DEBUG_DEFINE_WRITE_ASCIIZ
        JMP     Short CONTINUE
        String  DB      Text,00H
        CONTINUE:
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        IFNB <Row>
          dSetPos       %Row,%Col
        ENDIF
        LEA     SI,String
        CALL    Debug_Write_ASCIIZ
        POP     SI
        POP     DS
        Debug_POP_Flags
ENDM

;************************************************

dTextOutOffset  MACRO   Offset,Row,Col,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dTextOutOffset
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <Offset>
          %OUT > Debug Warning: dTextOutOffset was used without any parameters
          EXITM
        ENDIF

        Debug_PUSH_Flags
        DEBUG_DEFINE_WRITE_ASCIIZ
        PUSH    SI
        IFNB <Row>
          dSetPos       %Row,%Col
        ENDIF
        MOV     SI,Offset
        CALL    Debug_Write_ASCIIZ
        POP     SI
        Debug_POP_Flags
ENDM

;************************************************

dWriteDecWord   MACRO   DecWord,Row,Col,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dWriteDecWord
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <DecWord>
          %OUT > Debug Warning: dWriteDecWord was used without any parameters
          EXITM
        ENDIF
        IFNB <Row>
          IFB <Col>
            %OUT > Debug Error: "Col" parameter is not defined for dWriteDecWord
            .ERR
            EXITM
          ENDIF
        ENDIF            
        Debug_PUSH_Flags
        DEBUG_DEFINE_WRITE_DECIMAL

        PUSH    DX
        IFNB <Row>
          dSetPos       %Row,%Col
        ENDIF
        MOV     DX,DecWord
        CALL    Debug_Write_Decimal
        POP     DX
        Debug_POP_Flags
ENDM

;************************************************

dWriteDecByte   MACRO   DecByte,Row,Col,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dWriteDecByte
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <DecByte>
          %OUT > Debug Warning: dWriteDecByte was used without any parameters
          EXITM
        ENDIF
        IFNB <Row>
          IFB <Col>
            .ERR > Debug Error: Col parameter is not defined for dWriteDecWord
          ENDIF
        ENDIF            
        Debug_PUSH_Flags
        DEBUG_DEFINE_WRITE_DECIMAL

        PUSH    DX
        IFNB <Row>
          dSetPos       %Row,%Col
        ENDIF
        MOV     DL,DecByte
        XOR     DH,DH
        CALL    Debug_Write_Decimal
        POP     DX
        Debug_POP_Flags
ENDM

;************************************************

dWriteHexWord   MACRO   HexWord,Row,Col,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dWriteHexWord
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <HexWord>
          %OUT > Debug Warning: dWriteHexWord was used without any parameters
          EXITM
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_WRITE_HEX

        PUSH    DX
        IFNB <Row>
          dSetPos       %Row,%Col
        ENDIF
        MOV     DX,HexWord
        CALL    Debug_Write_Hex
        POP     DX
        Debug_POP_Flags
ENDM

;************************************************

dWriteHexByte   MACRO   HexByte,Row,Col,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dWriteHexByte
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <HexByte>
          %OUT > Debug Warning: dWriteHexByte was used without any parameters
          EXITM
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_WRITE_HEX_BYTE

        PUSH    DX
        IFNB <Row>
          dSetPos       %Row,%Col
        ENDIF
        MOV     DL,HexByte
        CALL    Debug_Write_Hex_Byte
        POP     DX
        Debug_POP_Flags
ENDM

;************************************************

dShowRegisters  MACRO   Row,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dShowRegisters
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_SHOW_REGISTERS

        IFNB <Row>
          dSetRow       %Row
        ENDIF
        CALL    Debug_Show_Registers
        Debug_POP_Flags
ENDM

;************************************************

dWaitKey        MACRO   KeyCode,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dWaitKey
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        Debug_PUSH_Flags
        IFNB <KeyCode>
          DEBUG_DEFINE_WAIT_KEY
          PUSH    DX
          MOV   DL,KeyCode
          CALL  Debug_Wait_Key
          POP   DX
        ELSE
          PUSH  AX
          XOR   AH,AH
          INT   16H
          POP   AX
        ENDIF
        Debug_POP_Flags
ENDM

;************************************************

dWaitMili       MACRO   MilliScnds,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dWaitMili
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <MilliScnds>
          %OUT > Debug Warning: dWaitMili was used without any parameters
          EXITM
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_WAIT_MILI

        PUSH    AX
        MOV     AX,MilliScnds
        CALL    Debug_Wait_Mili
        POP     AX
        Debug_POP_Flags
ENDM

;************************************************

dBeep   MACRO   Duration,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dBeep
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_SPEAKER_BEEP

        PUSH  AX
        PUSH    BX
        IFNB <Duration>
          MOV   AX,Duration
        ELSE
          MOV   AX,600
        ENDIF
        MOV     BX,2400         ;Frequency(HZ)
        CALL    Debug_Speaker_Beep
        POP     BX
        POP     AX
        Debug_POP_Flags
ENDM

;************************************************

dMemDump        MACRO   Segment1,Offset1,Length1,InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dMemDump
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IFB <Length1>
          %OUT > Debug Error: Not enough actual parameters for dMemDump
          %OUT SYNTAX: dMemDump  Segment,Offset,Length
          .ERR
          EXITM
        ENDIF
        Debug_PUSH_Flags
        DEBUG_DEFINE_MEM_DUMP

        PUSH    DS
        PUSH    CX
        PUSH    SI
        MOV     SI,Segment1
        MOV     DS,SI
        POP     SI
        PUSH    SI
        MOV     SI,Offset1
        MOV     CX,Length1
        CALL    Debug_Mem_Dump
        POP     SI
        POP     CX
        POP     DS
        Debug_POP_Flags
ENDM

;************************************************

dDefineAll      MACRO   InvalidArg
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DEBUG_DEFINE_DEBUG_VARIABLES
        IFE Debug_Enabled_Flag
          EXITM
        ENDIF
        IFNB <InvalidArg>
          %OUT > Debug Error: Too many parameters for dDefineAll
          .ERR
          EXITM
        ENDIF
        ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Debug_PUSH_Flags
        DEBUG_DEFINE_GET_CURSOR_POS
        DEBUG_DEFINE_SET_CURSOR_ROW_COL
        DEBUG_DEFINE_NEW_LINE
        DEBUG_DEFINE_CLEAR_SCREEN
        DEBUG_DEFINE_CLEAR_LINE
        DEBUG_DEFINE_CLEAR_CHAR_AT_POS
        DEBUG_DEFINE_CLEAR_TO_EOL
        DEBUG_DEFINE_WRITE_ASCIIZ
        DEBUG_DEFINE_WRITE_DECIMAL
        DEBUG_DEFINE_WRITE_HEX_BYTE
        DEBUG_DEFINE_WRITE_HEX
        DEBUG_DEFINE_BYTE_TO_HEX
        DEBUG_DEFINE_SHOW_REGISTERS
        DEBUG_DEFINE_WAIT_KEY
        DEBUG_DEFINE_WAIT_MILI
        DEBUG_DEFINE_SPEAKER_BEEP
        DEBUG_DEFINE_MEM_DUMP
        DEBUG_DEFINE_ASCII_CHAR_OUT
        DEBUG_DEFINE_CHAR_OUT
        Debug_POP_Flags
ENDM

;************************************************

DEBUG_MOVE_VAR  MACRO   NAME,INDEX,VALUE,SEG
        IFNB    <SEG>
          MOV     SEG:&NAME&INDEX,VALUE
        ELSE
          MOV     &NAME&INDEX,VALUE
        ENDIF
ENDM

DEBUG_MOVE_FROM_VAR     MACRO   NAME,INDEX,VALUE,SEG
        IFNB    <SEG>
          MOV     VALUE,SEG:&NAME&INDEX
        ELSE
          MOV     VALUE,&NAME&INDEX
        ENDIF
ENDM

DEBUG_DEF_VAR   MACRO   NAME,INDEX,TAG,VALUE
        &NAME&INDEX       D&TAG      VALUE
ENDM

DEBUG_DEFINE_GET_CURSOR_POS     MACRO
        LOCAL   CONTINUE
        IFNDEF  Debug_Get_Cursor_Pos
          JMP   Short CONTINUE
          Debug_Get_Cursor_Pos  PROC    FAR
                PUSH    AX
                PUSH    BX
                PUSH    CX
                MOV     AH,0FH
                INT     10H
                MOV     AH,03H
                INT     10H
                POP     CX
                POP     BX
                POP     AX
                RET
                ;DH=Row,DL=Column
          Debug_Get_Cursor_Pos ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_SET_CURSOR_ROW_COL MACRO
        LOCAL   CONTINUE,COLUMN_OK,ROW_OK
        IFNDEF  Debug_Set_Cursor_Row_Col
         JMP    Short CONTINUE
          Debug_Set_Cursor_Row_Col      PROC    FAR
                PUSH    AX
                PUSH    BX
                PUSH    DX
                MOV     AH,0FH
                INT     10H
                PUSH    CX
                MOV     AH,03H
                INT     10H
                POP     CX
                CMP     CL,0FFH
                JE      COLUMN_OK
                MOV     DL,CL
          COLUMN_OK:
                CMP     CH,0FFH
                JE      ROW_OK
                MOV     DH,CH
          ROW_OK:
                MOV     AH,02H
                INT     10H
                POP     DX
                POP     BX
                POP     AX
                RET
          Debug_Set_Cursor_Row_Col      ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_NEW_LINE   MACRO
        LOCAL   CONTINUE
        IFNDEF  Debug_New_Line
          JMP   Short CONTINUE
          Debug_New_Line        PROC    FAR
                PUSH    AX
                PUSH    BX
                MOV     AX,0E0DH
                INT     10H
                MOV     AX,0E0AH
                INT     10H
                POP     BX
                POP     AX
                RET
          Debug_New_Line        ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_CLEAR_SCREEN       MACRO
        LOCAL   CONTINUE
        IFNDEF Debug_Clear_Screen
          JMP   Short CONTINUE
          Debug_Clear_Screen    PROC    FAR
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
                MOV     AH,0FH
                INT     10H
                MOV     DL,AH
                DEC     DL
                MOV     DH,24
                MOV     AX,0600H
                MOV     BH,07H
                XOR     CX,CX
                INT     10H
                POP     DX
                POP     CX
                POP     BX
                POP     AX
                RET
          Debug_Clear_Screen    ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_CLEAR_LINE MACRO
        LOCAL   CONTINUE,ROW_OK
        IFNDEF Debug_Clear_Line
          DEBUG_DEFINE_CLEAR_TO_EOL
          JMP   Short CONTINUE
          Debug_Clear_Line      PROC    FAR
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
                MOV     CL,AL
                MOV     AH,0FH
                INT     10H
                MOV     AL,CL
                MOV     AH,03H
                INT     10H
                MOV     CX,DX
                XOR     DL,DL
                CMP     AL,0FFH
                JE      ROW_OK
                MOV     DH,AL
          ROW_OK:
                MOV     AH,02H
                INT     10H
                dClearToEol
                MOV     DX,CX
                INT     10H
                POP     DX
                POP     CX
                POP     BX
                POP     AX
                RET
          Debug_Clear_Line      ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_CLEAR_CHAR_AT_POS  MACRO
        LOCAL   CONTINUE
        IFNDEF Debug_Clear_Char_At_Pos
          JMP   Short CONTINUE
          Debug_Clear_Char_At_Pos       PROC    FAR
                PUSH    AX
                PUSH    BX
                PUSH    CX
                MOV     AH,0FH
                INT     10H
                MOV     CH,BH
                MOV     AH,08H
                INT     10H
                MOV     BL,BH
                MOV     BH,CH
                MOV     CX,1
                MOV     AH,09H
                INT     10H
                POP     CX
                POP     BX
                POP     AX
                RET
          Debug_Clear_Char_At_Pos       ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_CLEAR_TO_EOL       MACRO
        LOCAL   CONTINUE,START_CLEAR,CLEAR_DONE
        IFNDEF Debug_Clear_To_Eol
          DEBUG_DEFINE_CLEAR_CHAR_AT_POS
          JMP   Short CONTINUE
          Debug_Clear_To_Eol    PROC    FAR
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
                MOV     AH,0FH
                INT     10H
                MOV     AL,AH
                MOV     AH,03H
                INT     10H
                PUSH    DX
          START_CLEAR:
                dClearCharAtPos
                INC     DL
                CMP     DL,AL
                JAE     CLEAR_DONE
                MOV     AH,02H
                INT     10H
                JMP     Short START_CLEAR
          CLEAR_DONE:
                POP     DX
                MOV     AH,02H
                INT     10H
                POP     DX
                POP     CX
                POP     BX
                POP     AX
                RET
          Debug_Clear_To_Eol    ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_WRITE_ASCIIZ       MACRO
        LOCAL   CONTINUE,WRITE_LOOP,WRITE_DONE
        IFNDEF Debug_Write_ASCIIZ
          JMP   Short CONTINUE
          Debug_Write_ASCIIZ    PROC    FAR
                ;INPUT: DS:SI => ASCIIZ string to write at current cursor position

                PUSH    AX
                PUSH    SI
                CLD
          WRITE_LOOP:
                LODSB
                OR      AL,AL
                JZ      WRITE_DONE
                MOV     AH,0EH
                INT     10H
                JMP     Short WRITE_LOOP
          WRITE_DONE:
                POP     SI
                POP     AX
                RET
          Debug_Write_ASCIIZ    ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_WRITE_DECIMAL      MACRO
        LOCAL   CONTINUE,NON_ZERO,WRITE_DIGIT_LOOP,END_DECIMAl
        IFNDEF Debug_Write_Decimal
          JMP   Short CONTINUE
          Debug_Write_Decimal   PROC    FAR
                PUSH    AX
                PUSH    CX
                PUSH    DX
                PUSH    SI
                MOV     AX,DX
                MOV     SI,10
                XOR     CX,CX
          NON_ZERO:
                XOR     DX,DX
                DIV     SI
                PUSH    DX
                INC     CX
                OR      AX,AX
                JNE     NON_ZERO
          WRITE_DIGIT_LOOP:
                POP     DX
                ADD     DL,'0'
                MOV     AH,0EH
                MOV     AL,DL
                INT     10H
                LOOP    WRITE_DIGIT_LOOP
          END_DECIMAl:
                POP     SI
                POP     DX
                POP     CX
                POP     AX
                RET
          Debug_Write_Decimal   ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_WRITE_HEX_BYTE     MACRO
        LOCAL   CONTINUE
        IFNDEF  Debug_Write_Hex_Byte
          DEBUG_DEFINE_BYTE_TO_HEX
          JMP   Short CONTINUE
          Debug_Write_Hex_Byte  PROC    FAR
                PUSH    AX
                PUSH    DX
                MOV     AL,DL
                CALL    Debug_Byte_To_Hex
                MOV     DH,AH
                MOV     AH,0EH
                INT     10H
                MOV     AL,DH
                INT     10H
                POP     DX
                POP     AX
                RET
          Debug_Write_Hex_Byte  ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_WRITE_HEX  MACRO
        LOCAL   CONTINUE
        IFNDEF Debug_Write_Hex
          DEBUG_DEFINE_WRITE_HEX_BYTE
          JMP   Short CONTINUE
          Debug_Write_Hex       PROC    FAR
                ;----------------------
                XCHG    DL,DH
                CALL    Debug_Write_Hex_Byte
                ;----------------------
                XCHG    DL,DH
                CALL    Debug_Write_Hex_Byte
                ;----------------------
                RET
          Debug_Write_Hex       ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_BYTE_TO_HEX        MACRO
        LOCAL   CONTINUE,CONV_TO_HEX,HEX_LETTER,CONV_NEXT
        IFNDEF Debug_Byte_To_Hex
          JMP   Short CONTINUE
          Debug_Byte_To_Hex     PROC    FAR
                PUSH    CX
                MOV     AH,AL
                AND     AH,0FH
                MOV     CX,4
                SHR     AL,CL
                XOR     CX,CX
          CONV_TO_HEX:
                CMP     AL,9
                JA      HEX_LETTER
                ADD     AL,48
                JMP     Short CONV_NEXT
          HEX_LETTER:
                ADD     AL,55
          CONV_NEXT:
                XCHG    AL,AH
                OR      CX,CX
                MOV     CX,1
                JZ      CONV_TO_HEX
                POP     CX
                RET
          Debug_Byte_To_Hex     ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_SHOW_REGISTERS     MACRO
        LOCAL   CONTINUE,WRITE_OV,OF_DONE,WRITE_DN,DF_DONE,WRITE_EI,IF_DONE
        LOCAL   WRITE_NG,SF_DONE,WRITE_ZR,ZF_DONE,WRITE_AC,AF_DONE
        LOCAL   WRITE_PE,PF_DONE,WRITE_CY,CF_DONE
        IFNDEF Debug_Show_Registers
          DEBUG_DEFINE_CHAR_OUT
          DEBUG_DEFINE_WRITE_ASCIIZ
          DEBUG_DEFINE_WRITE_HEX
          JMP   CONTINUE
          Debug_Show_Registers  PROC    FAR
                PUSH    AX
                PUSHF
                dTextOut        <10,13,'É'>
                dCharOut        'Í',70
                dTextOut        <'»',10,13,'ºAX='>
                dWriteHexWord   AX
                dTextOut        '  BX='
                dWriteHexWord   BX
                dTextOut        '  CX='
                dWriteHexWord   CX
                dTextOut        '  DX='
                dWriteHexWord   DX
                dTextOut        '  SP='
                dWriteHexWord   SP
                dTextOut        '  BP='
                dWriteHexWord   BP
                dTextOut        '  SI='
                dWriteHexWord   SI
                dTextOut        '  DI='
                dWriteHexWord   DI
                dTextOut        <'º',10,13,'ºDS='>
                dWriteHexWord   DS
                dTextOut        '  ES='
                dWriteHexWord   ES
                dTextOut        '  SS='
                dWriteHexWord   SS
                dTextOut        '  CS='
                dWriteHexWord   CS

                ;Write flags:
                POP     AX
                dCharOut        ' ',12

                ;Overflow Flag
                TEST    AH,00001000b
                JNZ     WRITE_OV
                dTextOut        'NV'
                JMP     Short OF_DONE
          WRITE_OV:
                dTextOut        'OV'
          OF_DONE:

                ;Direction Flag
                TEST    AH,00000100b
                JNZ     WRITE_DN
                dTextOut        ' UP'
                JMP     Short DF_DONE
          WRITE_DN:
                dTextOut        ' DN'
          DF_DONE:

                ;Interrupt Flag
                TEST    AH,00000010b
                JNZ     WRITE_EI
                dTextOut        ' DI'
                JMP     Short IF_DONE
          WRITE_EI:
                dTextOut        ' EI'
          IF_DONE:

                ;Sign Flag
                TEST    AL,10000000b
                JNZ     WRITE_NG
                dTextOut        ' PL'
                JMP     Short SF_DONE
          WRITE_NG:
                dTextOut        ' NG'
          SF_DONE:

                ;Zero Flag
                TEST    AL,01000000b
                JNZ     WRITE_ZR
                dTextOut        ' NZ'
                JMP     Short ZF_DONE
          WRITE_ZR:
                dTextOut        ' ZR'
          ZF_DONE:

                ;Auxiliary Carry Flag
                TEST    AL,00010000b
                JNZ     WRITE_AC
                dTextOut        ' NA'
                JMP     Short AF_DONE
          WRITE_AC:
                dTextOut        ' AC'
          AF_DONE:

                ;Parity Flag
                TEST    AL,00000100b
                JNZ     WRITE_PE
                dTextOut        ' PO'
                JMP     Short PF_DONE
          WRITE_PE:
                dTextOut        ' PE'
          PF_DONE:

                ;Carry Flag
                TEST    AL,00000001b
                JNZ     WRITE_CY
                dTextOut        ' NC',
                JMP     Short CF_DONE
          WRITE_CY:
                dTextOut        ' CY'
          CF_DONE:

                dTextOut        <' º',10,13,'È'>
                dCharOut        'Í',70
                dTextOut        <'¼',13,10>
                POP     AX
                RET
          Debug_Show_Registers  ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_WAIT_KEY   MACRO
        LOCAL   CONTINUE,WAIT_LOOP
        IFNDEF Debug_Wait_Key
          JMP   Short CONTINUE
          Debug_Wait_Key        PROC    FAR
                PUSH    AX
          WAIT_LOOP:
                XOR     AH,AH
                INT     16H
                CMP     AL,DL
                JNE     WAIT_LOOP
                POP     AX
                RET
          Debug_Wait_Key        ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_WAIT_MILI  MACRO
        LOCAL   CONTINUE
        IFNDEF Debug_Wait_Mili
          JMP   Short CONTINUE
          Debug_Wait_Mili       PROC    FAR
                PUSH    AX
                PUSH    CX
                PUSH    DX
                MOV     DX,1000
                MUL     DX
                MOV     CX,DX
                MOV     DX,AX
                MOV     AH,86H
                INT     15H
                POP     DX
                POP     CX
                POP     AX
                RET
          Debug_Wait_Mili       ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_SPEAKER_BEEP       MACRO
        LOCAL   CONTINUE,SP_ON,BEEP_RETURN
        IFNDEF Debug_Speaker_Beep
          DEBUG_DEFINE_WAIT_MILI
          JMP   Short CONTINUE
          Debug_Speaker_Beep    PROC    FAR
                CMP     BX,0012H
                JBE     BEEP_RETURN
                PUSH    AX
                PUSH    DX
                MOV     AX,34DDH
                MOV     DX,0012H
                DIV     BX      ;DX:AX / BX
                MOV     DX,AX
                IN      AL,61H
                TEST    AL,03H
                JNZ     SP_ON
                OR      AL,03H
                OUT     61H,AL
                MOV     AL,0B6H
                OUT     43H,AL
          SP_ON:
                MOV     AL,DL
                OUT     42H,AL
                MOV     AL,DH
                OUT     42H,AL
                ;----------------------
                POP     DX
                POP     AX
                CALL    Debug_Wait_Mili
                PUSH    AX
                ;----------------------
                IN      AL,61H
                AND     AL,0FCH
                OUT     61H,AL
                POP     AX
          BEEP_RETURN:
                RET
          Debug_Speaker_Beep    ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_DEBUG_VARIABLES MACRO
        IFNDEF Debug_Enabled_Flag
          Debug_Enabled_Flag=1
        ENDIF
        IFNDEF Debug_InCall_Counter
          Debug_InCall_Counter=0
        ENDIF
ENDM

DEBUG_DEFINE_MEM_DUMP   MACRO
        LOCAL   CONTINUE,DMD_CHAR_LOOP,DMD_DUMP_LOOP,DMD_CONTINUE
        LOCAL   DASH_SEPARATOR,SEPARATOR_DONE
        IFNDEF  Debug_Mem_Dump
          DEBUG_DEFINE_SET_CURSOR_ROW_COL
          DEBUG_DEFINE_GET_CURSOR_POS
          DEBUG_DEFINE_CHAR_OUT
          DEBUG_DEFINE_ASCII_CHAR_OUT
          DEBUG_DEFINE_WRITE_HEX_BYTE
          DEBUG_DEFINE_WRITE_HEX
          DEBUG_DEFINE_NEW_LINE
          JMP   CONTINUE
          Debug_Mem_Dump        PROC    FAR
          ;INPUT: DS=Segment address
          ;       SI=Start offset address
          ;       CX=Length of dump in bytes
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
                PUSH    SI
                CMP     SI,16
                JAE     CALC_START_OFF
                XOR     AX,AX
                MOV     DX,SI
                JMP     Short START_OFF_DONE
          CALC_START_OFF:
                MOV     AX,SI
                XOR     DX,DX
                MOV     BX,16
                DIV     BX
                MOV     AX,SI
                SUB     AX,DX
          START_OFF_DONE:
                dNewLine
                dWriteHexWord   DS
                dCharOut        ':'
                dWriteHexWord   AX
                dCharOut        ' '
                MOV     BX,AX
                OR      DX,DX
                JZ      DMD_DUMP_LOOP
                PUSH    DX
          DMD_CHAR_LOOP:
                dCharOut        ' ',3
                DEC     DX
                JNZ     DMD_CHAR_LOOP
                POP     DX
                CLD
          DMD_DUMP_LOOP:
                CMP     DL,16
                JB      DMD_CONTINUE
                XOR     DL,DL
                ADD     BX,16
                dNewLine
                dWriteHexWord   DS
                dCharOut        ':'
                dWriteHexWord   BX
                dCharOut        ' '
          DMD_CONTINUE:
                INC     DL
                LODSB
                CMP     DL,9
                JE      DASH_SEPARATOR
                MOV     DH,' '
                JMP     Short SEPARATOR_DONE
          DASH_SEPARATOR:
                MOV     DH,'-'
          SEPARATOR_DONE:
                dCharOut        DH
                dWriteHexByte   AL
                ADD     DL,60
                dSavePos
                dSetCol DL
                dASCIICharOut   AL
                dRestorePos
                SUB     DL,60
                LOOP    DMD_DUMP_LOOP
                dNewLine
                POP     SI
                POP     DX
                POP     CX
                POP     BX
                POP     AX
                RET
          Debug_Mem_Dump        ENDP
          CONTINUE:
        ENDIF
ENDM

DEBUG_DEFINE_ASCII_CHAR_OUT    MACRO
        LOCAL   CONTINUE
        IFNDEF  Debug_ASCII_Char_Out
          JMP   Short CONTINUE
          Debug_ASCII_Char_Out  PROC    FAR
                PUSH    AX
                PUSH    BX
                PUSH    CX
                MOV     BL,AL
                MOV     AH,0FH
                INT     10H
                MOV     AL,BL
                MOV     CX,1
                MOV     AH,0AH
                INT     10H
                POP     CX
                POP     BX
                POP     AX
                RET
          Debug_ASCII_Char_Out  ENDP
          CONTINUE:
        ENDIF
ENDM

Debug_PUSH_Flags        MACRO
        Debug_InCall_Counter=Debug_InCall_Counter+1
        IF Debug_InCall_Counter EQ 1
          PUSHF
        ENDIF
ENDM

Debug_POP_Flags MACRO
        Debug_InCall_Counter=Debug_InCall_Counter-1
        IF Debug_InCall_Counter EQ 0
          POPF
        ENDIF
ENDM

DEBUG_DEFINE_CHAR_OUT   MACRO
        LOCAL   CONTINUE,WRITE_LOOP
        IFNDEF  Debug_Char_Out
          JMP   Short CONTINUE
          Debug_Char_Out        PROC    FAR
          ;INPUT: AL=Character to write
          ;       CX=Repeat count
          ;OUTPUT:CX=0
                PUSH    AX
                MOV     AH,0EH
          WRITE_LOOP:
                INT     10H
                LOOP    WRITE_LOOP
                POP     AX
                RET
          Debug_Char_Out        ENDP
          CONTINUE:
        ENDIF
ENDM

;;;;;;;;;;;
;DEBUG_GET_VAR_TYPE     MACRO   VARIABLE1
;        %OUT QQQ
;        ;;1=BYTE
;        ;;2=WORD
;        %OUT PPP
;        DEBUG_VAR_TYPE=0
;        IF1
;          EXITM
;        ENDIF
;        IFE TYPE VARIABLE1
;          IF VARIABLE1 LE 255
;            DEBUG_VAR_TYPE=1
;            EXITM
;          ENDIF
;          IF VARIABLE1 LE 0FFFFH
;            DEBUG_VAR_TYPE=2
;            EXITM
;          ELSE
;            %OUT > Debug Error:Invalid constant size(VARIABLE1)
;            .ERR
;            EXITM
;          ENDIF
;        ENDIF
;        IRP W_REG,<AX,BX,CX,DX,SI,DI,BP,SP,SS,DS,ES,CS>
;          IFIDN <VARIABLE1>,<W_REG>
;            DEBUG_VAR_TYPE=2
;            EXITM
;          ENDIF
;        ENDM
;        IFE DEBUG_VAR_TYPE
;          IRP B_REG,<AL,AH,BL,BH,CL,CH,DL,DH>
;            IFIDN <VARIABLE1>,<B_REG>
;              DEBUG_VAR_TYPE=1
;              EXITM
;            ENDIF
;          ENDM
;        ENDIF
;        IF2
;          IFNDEF VARIABLE1
;            %OUT > Debug Error:The variable VARIABLE1 is undefined
;            .ERR
;            EXITM
;          ENDIF
;          S=SIZE VARIABLE
;          IF S EQ 1
;            DEBUG_VAR_TYPE=1
;          ELSE
;            IF S EQ 2
;              DEBUG_VAR_TYPE=2
;            ELSE
;              %OUT > Debug Error:Invalid variable size(VARIABLE1)
;              .ERR
;              EXITM
;            ENDIF
;          ENDIF
;        ENDIF
;ENDM
;;;;;;;;;;;
