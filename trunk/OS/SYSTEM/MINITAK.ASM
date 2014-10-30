;MiniTAK Main System File(MINITAK.ASM -> MINITAK.SYS)

;**************************** EQUIVALENTS     **************************
        INCLUDE         ERRCODES.INC

        INCLUDE         KEYCODES.INC

        INT28H_MAX_CHAR_COUNT   EQU     80

        MINITAK_VERSION_WORD    EQU     0001H   ;MiniTAK 1.0
        MINITAK_REL_NUMBER      EQU     1
        MINITAK_VERSION_TYPE    EQU     0       ;0=Main,1=Alpha,2=Beta

        DOS_MAX_MAJOR_VER       EQU     7
        DOS_MAX_MINOR_VER       EQU     0AH

;***********************************************************************
INC_INDOS       MACRO
        INC     CS:BYTE PTR INDOS_FLAG
ENDM

DEC_INDOS       MACRO
        PUSHF
        DEC     CS:BYTE PTR INDOS_FLAG
        POPF
ENDM


;MINITAK.SYS
.MODEL  SMALL
.CODE
START_MINITAK:
        JMP     MINITAK_INITIALIZER

;**********************  DATA DEFENITIONS        ***********************
;MTF00001.ASM
        TAB_SPACE               DB      8
        CTRL_BREAK_STATUS       DB      0       ;0=CTRL-BREAK has not been pressed
                                                ;1=CTRL-BREAK has been pressed
        EXT_ASCII_CODE          DB      0
        FIRST_YEAR_DAY          DB      1
        CTRL_BREAK_LEVEL        DB      0       ;0=OFF(Only check in character I/O)
                                                ;1=ON(Check in all INT 21H function calls)
        INT28H_CHAR_COUNTER     DB      0
        DOS_VERSION_WORD        DW      1606H   ;DOS 6.22

;#####
EXT_ERROR_INF           LABEL           BYTE
        EEI_AX_VALUE            DW      0
        EEI_BX_VALUE            DW      0
        EEI_CX_VALUE            DW      0
        EEI_DX_VALUE            DW      0
        EEI_SI_VALUE            DW      0
        EEI_DI_VALUE            DW      0
        EEI_DS_VALUE            DW      ?
        EEI_ES_VALUE            DW      0
        EEI_RESERVED            DW      0       ;Reserved
        EEI_USER_ID             DW      0       ;User ID:    0=Local
        EEI_PROG_ID             DW      0       ;Program ID: 0=Local
;#####
        ;Layout of the following three variables must not be changed.
        CRITICAL_ERR_FLAG_1     DB      0
        INDOS_FLAG              DB      0
        CRITICAL_ERR_FLAG_2     DB      0

;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;                        MTF00001.ASM                                  ;

WAIT_MILI       PROC
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
WAIT_MILI       ENDP

;***********************************************************************

SPEAKER_BEEP    PROC
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
        ;-----------------------------------
        POP     DX
        POP     AX
        CALL    WAIT_MILI
        PUSH    AX
        ;-----------------------------------
        IN      AL,61H
        AND     AL,0FCH
        OUT     61H,AL
        POP     AX
BEEP_RETURN:
        RET
SPEAKER_BEEP    ENDP

;***********************************************************************

WAIT_SERVICE    PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 09H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        XCHG    AX,BX
        CALL    WAIT_MILI
        XCHG    AX,BX
        RET
WAIT_SERVICE    ENDP

;***********************************************************************

SPEAKER PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 0AH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        XCHG    AX,BX
        XCHG    BX,CX
        CALL    SPEAKER_BEEP
        XCHG    BX,CX
        XCHG    AX,BX
        RET
SPEAKER ENDP

;***********************************************************************
CTRL_BREAK_CHECKING_ENABLED     DB      1

CHECK_CTRL_BREAK        PROC
;INPUT:  CF=0 => Check Ctrl-Break status anyway
;        CF=1 => Check Ctrl-Break status only if CTRL_BREAK_LEVEL is ON(=1) and also depending on the INT 21H service number in AH.
;                AH=INT 21H service number
        PUSH    AX
        JNC     CCB_CHECK
        CMP     CTRL_BREAK_LEVEL,0
        JE      CCB_DONE
        CMP     AH,06H
        JE      CCB_DONE
        CMP     AH,07H
        JE      CCB_DONE
        CMP     AH,4CH
        JE      CCB_DONE
CCB_CHECK:
        CMP     CS:CTRL_BREAK_CHECKING_ENABLED,0
        JE      CCB_DONE
        CMP     CS:CTRL_BREAK_STATUS,1
        JE      INVOKE_INT_23H
        MOV     AH,01H
        INT     16H
        JZ      CCB_DONE
        CMP     AL,03H
        JNE     CCB_DONE
        MOV     AH,00H
        INT     16H
INVOKE_INT_23H:
        MOV     CS:CTRL_BREAK_STATUS,0
        CLC
        INT     23H
        JNC     CCB_DONE
        MOV     CS:INDOS_FLAG,0
        JMP     CTRL_BREAK_TERMINATION
CCB_DONE:
        POP     AX
        RET
CHECK_CTRL_BREAK        ENDP

;***********************************************************************
                                                                
MOVE_CURSOR     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 04H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    BX
        PUSH    DX
        PUSH    CX
        PUSH    AX
        MOV     AH,0FH
        INT     10H
        PUSH    AX
        MOV     AH,03H
        INT     10H
        POP     CX
        DEC     CH
        XOR     CL,CL
        POP     AX
        ;-----------------------------------
        CMP     AL,0
        JE      MOVE_RIGHT
        CMP     AL,1
        JE      MOVE_LEFT
        CMP     AL,2
        JE      MOVE_DOWN
        CMP     AL,4
        JE      LINE_UP
        CMP     AL,3
        JNE     MOVE_DONE_2
        ;-----------------------------------
        ;Carriage return
        XOR     DL,DL
        JMP     SET_CURSOR
        ;-----------------------------------
MOVE_LEFT:
        CMP     DL,0
        JE      LINE_UP
        DEC     DL
        JMP     SET_CURSOR
LINE_UP:
        CMP     DH,0
        JE      MOVE_DONE_2
        DEC     DH
        MOV     DL,CH
        JMP     SET_CURSOR
        ;-----------------------------------
MOVE_DOWN:
        PUSH    AX
        MOV     AX,0E0AH
        INT     10H
        JMP     Short MOVE_DONE_1
ADD_LINE:
        PUSH    AX
        MOV     AH,08H
        INT     10H
        PUSH    BX
        MOV     BH,AH
        MOV     AX,0601H
        PUSH    DX
        MOV     DL,CH
        MOV     DH,24
        PUSH    CX
        XOR     CX,CX
        INT     10H
        POP     CX
        POP     DX
        POP     BX
        POP     AX
        CMP     CL,1
        JE      SET_CURSOR
        JMP     SHORT MOVE_DONE_2
        ;-----------------------------------
MOVE_RIGHT:
        CMP     DL,CH
        JE      NEXT_LINE
        INC     DL
        JMP     SHORT SET_CURSOR
NEXT_LINE:
        PUSH    AX
        MOV     AX,0E0DH
        INT     10H
        MOV     AL,0AH
        INT     10H
        JMP     Short MOVE_DONE_1
        ;-----------------------------------
SET_CURSOR:
        PUSH    AX
        MOV     AH,02H
        INT     10H
MOVE_DONE_1:
        POP     AX
MOVE_DONE_2:
        POP     CX
        POP     DX
        POP     BX
        RET
MOVE_CURSOR     ENDP

;***********************************************************************

WRITE_CHAR      PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,0FH
        INT     10H
        CMP     DL,CR
        JE      CARRIAGE_RETURN
        CMP     DL,LF
        JE      LINE_FEED
        CMP     DL,TAB
        JE      TAB_JUMP
        CMP     DL,BS
        JE      BACK_SPACE_CHAR
        CMP     DL,BEEP
        JE      SP_BEEP
        CMP     DL,0
        JE      WRITE_DONE
        ;-----------------------------------
        ;A normal character
        MOV     AH,0AH
        PUSH    CX
        MOV     CX,1
        MOV     AL,DL
        INT     10H
        POP     CX
        XOR     AL,AL
        CALL    MOVE_CURSOR
        JMP     WRITE_DONE
        ;-----------------------------------
CARRIAGE_RETURN:
        MOV     AL,3
        CALL    MOVE_CURSOR
        JMP     WRITE_DONE
LINE_FEED:
        MOV     AL,2
        CALL    MOVE_CURSOR
        JMP     WRITE_DONE
TAB_JUMP:
        PUSH    CX
        MOV     CL,CS:TAB_SPACE
        XOR     CH,CH
        MOV     AX,0E20H
WRITE_TAB:
        INT     10H
        LOOP    WRITE_TAB
        POP     CX
        JMP     SHORT WRITE_DONE
BACK_SPACE_CHAR:
        MOV     AL,1
        CALL    MOVE_CURSOR
        PUSH    CX
        MOV     AX,0A20H
        MOV     CX,1
        INT     10H
        POP     CX
        JMP     SHORT WRITE_DONE
SP_BEEP:
        MOV     AX,600
        MOV     BX,2400
        CALL    SPEAKER_BEEP
        ;-----------------------------------
WRITE_DONE:
        POP     AX
        POP     BX
        INC     CS:INT28H_CHAR_COUNTER
        CMP     CS:INT28H_CHAR_COUNTER,INT28H_MAX_CHAR_COUNT
        JB      WRITE_RETURN
        CALL    INT_28H_CALLER
        MOV     CS:INT28H_CHAR_COUNTER,0
WRITE_RETURN:
        RET
WRITE_CHAR      ENDP

;***********************************************************************

WRITE_CHAR_B    PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 02H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    CHECK_CTRL_BREAK
        CALL    WRITE_CHAR
        RET
WRITE_CHAR_B    ENDP

;***********************************************************************

WRITE_UNTIL_SPEC_CHAR   PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 03H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        XCHG    DX,BX
        PUSH    DX
        PUSH    SI
        XOR     SI,SI
START_WRITE:
        MOV     DL,BYTE PTR[BX+SI]
        CMP     DL,AL
        JE      WRITE_STR_DONE
        CALL    WRITE_CHAR_B
        INC     SI
        JMP     SHORT START_WRITE
WRITE_STR_DONE:
        POP     SI
        POP     DX
        XCHG    BX,DX
        RET
WRITE_UNTIL_SPEC_CHAR   ENDP

;***********************************************************************

WRITE_STRING    PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 09H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    AX
        MOV     AL,'$'
        CALL    WRITE_UNTIL_SPEC_CHAR
        POP     AX
        RET
WRITE_STRING    ENDP

;***********************************************************************

WRITE_ASCIIZ    PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 02H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    AX
        MOV     AL,00H
        CALL    WRITE_UNTIL_SPEC_CHAR
        POP     AX
        RET
WRITE_ASCIIZ    ENDP

;***********************************************************************

CHECK_KBD_BUF   PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 0BH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    CHECK_CTRL_BREAK
        CMP     CS:EXT_ASCII_CODE,0
        JA      NOT_EMPTY
        ;-----------------------------------
        PUSH    AX
        MOV     AH,01H
        INT     16H
        POP     AX
        JNZ     NOT_EMPTY
        XOR     AL,AL
        JMP     Short CHECK_RETURN_2
NOT_EMPTY:
        MOV     AL,0FFH
        ;-----------------------------------
CHECK_RETURN_2:
        RET
CHECK_KBD_BUF   ENDP

;***********************************************************************

RESET_KBD_BUF   PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 0CH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    AX
        MOV     CS:EXT_ASCII_CODE,0
PURGE_KEY_BUF:
        MOV     AH,01H
        INT     16H
        JZ      BUF_EMPTY
        XOR     AH,AH
        INT     16H
        JMP     SHORT PURGE_KEY_BUF
        ;-----------------------------------
BUF_EMPTY:
        MOV     CS:CTRL_BREAK_STATUS,0
        POP     AX
        ;Only the following services are allowed:
        ;  01H,06H,07H,08H,0AH
        CMP     AL,01H
        JE      ACTIVATE_FN
        CMP     AL,0AH
        JA      RESET_RETURN
        CMP     AL,06H
        JB      RESET_RETURN
        CMP     AL,09H
        JE      RESET_RETURN
ACTIVATE_FN:
        MOV     AH,AL
        INT     21H
        ;-----------------------------------
RESET_RETURN:
        RET
RESET_KBD_BUF   ENDP

;***********************************************************************

READ_KEY_W      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 07H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DS
        PUSH    DX
        MOV     DX,CS
        MOV     DS,DX
        CMP     EXT_ASCII_CODE,0
        JNE     EXT_CODE
        ;-----------------------------------
        PUSH    AX
READ_KEY_LOOP:
        CALL    INT_28H_CALLER
        MOV     CS:CTRL_BREAK_CHECKING_ENABLED,0
        CALL    CHECK_KBD_BUF
        MOV     CS:CTRL_BREAK_CHECKING_ENABLED,1
        OR      AL,AL
        JZ      READ_KEY_LOOP
        XOR     AH,AH
        INT     16H
        CMP     AL,0
        JE      READ_EXT_KEY
        MOV     DL,AL
        POP     AX
        MOV     AL,DL
        JMP     SHORT READ_KEY_DONE
READ_EXT_KEY:
        MOV     EXT_ASCII_CODE,AH
        POP     AX
        XOR     AL,AL
        JMP     SHORT READ_KEY_DONE
        ;-----------------------------------
EXT_CODE:
        MOV     AL,EXT_ASCII_CODE
        MOV     EXT_ASCII_CODE,0
READ_KEY_DONE:
        POP     DX
        POP     DS
        RET
READ_KEY_W      ENDP

;***********************************************************************

READ_KEY_WB     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 08H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    CHECK_CTRL_BREAK
        CALL    READ_KEY_W
        CLC
        CALL    CHECK_CTRL_BREAK
        RET
READ_KEY_WB     ENDP

;***********************************************************************

READ_KEY_WEB    PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 01H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CALL    READ_KEY_WB
        XCHG    AL,DL
        CALL    WRITE_CHAR_B
        XCHG    AL,DL
        RET
READ_KEY_WEB    ENDP

;***********************************************************************

READ_WRITE_KEY  PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 06H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CMP     DL,0FFH
        JB      WRITE_KEY
        ;-----------------------------------
        CMP     CS:EXT_ASCII_CODE,0
        JNE     GET_KEY
        PUSH    AX
        MOV     AH,01H
        INT     16H
        POP     AX
        JNZ     GET_KEY
        JMP     SHORT RW_KEY_RETURN
GET_KEY:
        CALL    READ_KEY_W
        PUSH    AX
        MOV     AH,1
        ADD     AH,1    ;ZF=0
        POP     AX
        JMP     SHORT RW_KEY_RETURN
        ;-----------------------------------
WRITE_KEY:
        CALL    WRITE_CHAR
RW_KEY_RETURN:
        RET
READ_WRITE_KEY  ENDP

;***********************************************************************

READ_STRING_BUF         PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 0AH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    BX
        PUSH    CX
        PUSH    SI
        MOV     SI,DX
        XOR     BX,BX
        DEC     BYTE PTR [SI]
        PUSH    AX
        MOV     AL,[SI+1]
        MOV     BYTE PTR [SI+1],0
        CMP     BYTE PTR [SI],0
        JE      STR_DONE
        MOV     [SI+1],AL
        ;-----------------------------------
READ_NEXT_KEY:
        CALL    READ_KEY_WB
        CMP     AL,K_ENTER
        JE      END_STR
        CMP     AL,0
        JE      EXTENDED_KEY
        CMP     AL,K_BS
        JE      BACK_SPACE
        CMP     AL,K_ESCAPE
        JE      ESCAPE_KEY
        CMP     BYTE PTR[SI],BL
        JE      BUFFER_FULL
        INC     BX
        MOV     [BX+SI+1],AL
        XCHG    AL,DL
        CALL    WRITE_CHAR_B
        MOV     DL,AL
        JMP     SHORT READ_NEXT_KEY
EXTENDED_KEY:
        CALL    READ_KEY_WB
        CMP     AL,K_L_ARROW
        JE      BACK_SPACE
        ;Other function keys can be handled here.
        JMP     SHORT READ_NEXT_KEY
BACK_SPACE:
        CMP     BL,0
        JZ      READ_NEXT_KEY
        MOV     CL,1
        CMP     BYTE PTR[BX+SI+1],TAB
        JNE     BS_COUNT_OK
        MOV     CL,CS:TAB_SPACE
BS_COUNT_OK:
        XOR     CH,CH
        DEC     BX      ;BH=0
        MOV     AL,DL
        MOV     DL,BS
WRITE_BS:
        CALL    WRITE_CHAR_B
        LOOP    WRITE_BS
        MOV     DL,AL
        JMP     SHORT READ_NEXT_KEY
ESCAPE_KEY:
        MOV     AL,DL
        MOV     DL,BS
        INC     BX
PURGE_BUFFER:
        DEC     BX
        JZ      PURGE_DONE
        CALL    WRITE_CHAR_B
        JMP     SHORT PURGE_BUFFER
PURGE_DONE:
        MOV     DL,AL
        JMP     READ_NEXT_KEY
BUFFER_FULL:
        MOV     AX,600
        PUSH    BX
        MOV     BX,2400
        CALL    SPEAKER_BEEP
        POP     BX
        JMP     READ_NEXT_KEY
        ;-----------------------------------
END_STR:
        MOV     [BX+SI+2],AL
        MOV     BYTE PTR [SI+1],BL
        MOV     AL,DL
        MOV     DL,CR
        CALL    WRITE_CHAR_B
        MOV     DL,AL
STR_DONE:
        INC     BYTE PTR [SI]
        POP     AX
        POP     SI
        POP     CX
        POP     BX
        RET
READ_STRING_BUF         ENDP

;***********************************************************************

INT_28H_CALLER  PROC
        PUSH    AX
        MOV     AX,1
        PUSH    AX      ;PUSH stack number on the stack(1=Services 1 through 0CH)
        INT     28H
        POP     AX
        POP     AX
        RET
INT_28H_CALLER  ENDP

;***********************************************************************

INT_1BH_HANDLER         PROC      FAR
;-----------------------------------------------------------------------;
; <INT 1BH (Keyboard Ctrl-Break) Handler> | <Used Internally>           ;
;-----------------------------------------------------------------------;
        MOV     CS:CTRL_BREAK_STATUS,1
        IRET
INT_1BH_HANDLER         ENDP

;***********************************************************************

INT_29H_HANDLER PROC
;-----------------------------------------------------------------------;
; <INT 29H Handler> | <API Interrupt>                                   ;
;-----------------------------------------------------------------------;
        PUSH    AX
        PUSH    BX
        MOV     AH,0EH
        MOV     BX,7
        INT     10H
        POP     BX
        POP     AX
        IRET
INT_29H_HANDLER ENDP

;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;

READ_STDAUX     PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 03H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DX
        PUSH    AX
        MOV     AH,02H
        MOV     DX,1            ;Read from COM1
        INT     14H
        POP     DX
        MOV     AH,DH
        POP     DX
        RET
READ_STDAUX     ENDP

;***********************************************************************

WRITE_STDAUX    PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 04H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    AX
        PUSH    DX
        MOV     AL,DL
        MOV     AH,01H
        MOV     DX,1            ;Write to COM1
        INT     14H
        POP     DX
        POP     AX
        RET
WRITE_STDAUX    ENDP

;***********************************************************************

WRITE_STDPRN    PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 05H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    AX
        PUSH    DX
        MOV     AL,DL
        MOV     AH,00H
        XOR     DX,DX           ;Write to LPT1(DX=0)
        INT     17H
        POP     DX
        POP     AX
        RET
WRITE_STDPRN    ENDP

;***********************************************************************

DECODE_BCD      PROC
        PUSH    BX
        MOV     BL,AL
        MOV     BH,AL
        AND     BH,0FH
        XOR     BL,BH
        SHR     BL,1
        SHR     BL,1
        SHR     BL,1
        PUSH    AX
        MOV     AL,5
        MUL     BL      ;AL*BL=AX
        MOV     BL,AL
        POP     AX
        ADD     BL,BH
        MOV     AL,BL
        POP     BX
        RET
DECODE_BCD      ENDP

;***********************************************************************

ENCODE_BCD      PROC
        CMP     AL,99
        JA      ENCODE_RETURN
        PUSH    BX
        PUSH    AX
        XOR     AH,AH
        MOV     BL,10
        DIV     BL
        MOV     BL,AL
        SHL     BL,1
        SHL     BL,1
        SHL     BL,1
        SHL     BL,1
        OR      BL,AH
        POP     AX
        MOV     AL,BL
        POP     BX
ENCODE_RETURN:
        RET
ENCODE_BCD      ENDP

;***********************************************************************

CALC_WEEK_DAY   PROC
        CMP     AL,12
        JA      CALC_RETURN
        CMP     AL,0
        JE      CALC_RETURN
        CMP     AH,31
        JA      CALC_RETURN
        CMP     AH,0
        JE      CALC_RETURN
        ;-----------------------------------
        ;AL and AH are valid numbers
        PUSH    CX
        XOR     CX,CX
        ;-----------------------------------
        CMP     AL,1
        JE      COUNT_DONE
        ADD     CX,31
        CMP     AL,2
        JE      COUNT_DONE
        ADD     CX,28
        CMP     AL,3
        JE      COUNT_DONE
        ADD     CX,31
        CMP     AL,4
        JE      COUNT_DONE
        ADD     CX,30
        CMP     AL,5
        JE      COUNT_DONE
        ADD     CX,31
        CMP     AL,6
        JE      COUNT_DONE
        ADD     CX,30
        CMP     AL,7
        JE      COUNT_DONE
        ADD     CX,31
        CMP     AL,8
        JE      COUNT_DONE
        ADD     CX,31
        CMP     AL,9
        JE      COUNT_DONE
        ADD     CX,30
        CMP     AL,10
        JE      COUNT_DONE
        ADD     CX,31
        CMP     AL,11
        JE      COUNT_DONE
        ADD     CX,30
        ;-----------------------------------
COUNT_DONE:
        PUSH    AX
        MOV     AL,AH
        XOR     AH,AH
        ADD     CX,AX
        POP     AX
        ;CX=Day of year
        ;-----------------------------------
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     AL,FIRST_YEAR_DAY
        POP     DS
        DEC     CX
        JZ      WEEK_DAY_DONE
DAY_LOOP:
        CMP     AL,6
        JE      RESET_DAY
        INC     AL
        JMP     SHORT NEXT_DAY
RESET_DAY:
        XOR     AL,AL
NEXT_DAY:
        LOOP    DAY_LOOP
WEEK_DAY_DONE:
        POP     CX
CALC_RETURN:
        RET
CALC_WEEK_DAY   ENDP

;***********************************************************************

CHECK_TIME      PROC
        CMP     CH,23
        JA      TIME_ERROR
        CMP     CL,59
        JA      TIME_ERROR
        CMP     DH,59
        JA      TIME_ERROR
        CMP     DL,99
        JA      TIME_ERROR
        XOR     AL,AL
        JMP     SHORT CHECK_RETURN_3
TIME_ERROR:
        MOV     AL,0FFH
CHECK_RETURN_3:
        RET
CHECK_TIME      ENDP

;***********************************************************************

CHECK_DATE      PROC
        CMP     CX,1980
        JB      DATE_ERROR
        CMP     CX,2099
        JA      DATE_ERROR
        CMP     DH,12
        JA      DATE_ERROR
        CMP     DH,1
        JB      DATE_ERROR
        CMP     DL,31
        JA      DATE_ERROR
        CMP     DL,1
        JB      DATE_ERROR
        XOR     AL,AL
        JMP     SHORT CHECK_RETURN_5
DATE_ERROR:
        MOV     AL,0FFH
CHECK_RETURN_5:
        RET
CHECK_DATE      ENDP

;***********************************************************************

GET_TIME        PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 2CH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    AX
        MOV     AH,02H
        INT     1AH
        JC      CLOCK_ERROR_2
        ;-----------------------------------
        MOV     AL,CH
        CALL    DECODE_BCD
        MOV     CH,AL
        MOV     AL,CL
        CALL    DECODE_BCD
        MOV     CL,AL
        MOV     AL,DH
        CALL    DECODE_BCD
        MOV     DH,AL
        XOR     DL,DL
        JMP     SHORT GET_DONE
        ;-----------------------------------
CLOCK_ERROR_2:
        XOR     CX,CX
        XOR     DX,DX
GET_DONE:
        POP     AX
        RET
GET_TIME        ENDP

;***********************************************************************

SET_TIME        PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 2DH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CALL    CHECK_TIME
        CMP     AL,0FFH
        JE      SET_RETURN
        ;-----------------------------------
        PUSH    AX
        PUSH    CX
        PUSH    DX
        MOV     AH,03H
        MOV     AL,CH
        CALL    ENCODE_BCD
        MOV     CH,AL
        MOV     AL,CL
        CALL    ENCODE_BCD
        MOV     CL,AL
        MOV     AL,DH
        CALL    ENCODE_BCD
        MOV     DH,AL
        XOR     DL,DL
        INT     1AH
        POP     DX
        POP     CX
        POP     AX
        ;-----------------------------------
SET_RETURN:
        RET
SET_TIME        ENDP

;***********************************************************************

GET_DATE        PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 2AH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    BX
        PUSH    AX
        MOV     AH,04H
        INT     1AH
        JC      CLOCK_ERROR
        ;-----------------------------------
        MOV     AL,CH
        CALL    DECODE_BCD
        MOV     CH,AL
        MOV     AL,CL
        CALL    DECODE_BCD
        MOV     CL,AL
        XCHG    CL,CH
        SHL     CL,1
        SHL     CL,1
        MOV     AL,25
        MUL     CL      ;CL+AL=AX
        MOV     CL,CH
        XOR     CH,CH
        ADD     AX,CX
        MOV     CX,AX
        MOV     AL,DL
        CALL    DECODE_BCD
        MOV     DL,AL
        MOV     AL,DH
        CALL    DECODE_BCD
        MOV     DH,AL
        MOV     AH,DL
        CALL    CALC_WEEK_DAY
        POP     BX
        MOV     AH,BH
        JMP     SHORT GET_RETURN
        ;-----------------------------------
CLOCK_ERROR:
        XOR     CX,CX
        XOR     DX,DX
        POP     AX
        XOR     AL,AL
GET_RETURN:
        POP     BX
        RET
GET_DATE        ENDP

;***********************************************************************

SET_DATE        PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 2BH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CALL    CHECK_DATE
        CMP     AL,0FFH
        JE      SET_RETURN_2
        PUSH    AX
        PUSH    CX
        PUSH    DX
        ;-----------------------------------
        MOV     AL,DH
        CALL    ENCODE_BCD
        MOV     DH,AL
        MOV     AL,DL
        CALL    ENCODE_BCD
        MOV     DL,AL
        MOV     AX,CX
        MOV     CL,100
        DIV     CL      ;AX/CL=>AL,AH
        CALL    ENCODE_BCD
        XCHG    AL,AH
        CALL    ENCODE_BCD
        MOV     CX,AX
        ;-----------------------------------
        MOV     AH,05H
        INT     1AH
        POP     DX
        POP     CX
        POP     AX
SET_RETURN_2:
        RET
SET_DATE        ENDP

;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;

GET_INT_VECTOR  PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 35H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        XOR     BX,BX
        PUSH    DS
        MOV     DS,BX
        MOV     BL,AL
        SHL     BX,1
        SHL     BX,1
        MOV     ES,[BX+2]
        MOV     BX,[BX]
        POP     DS
        RET
GET_INT_VECTOR  ENDP

;***********************************************************************

SET_INT_VECTOR  PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 25H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    ES
        PUSH    AX
        XOR     AX,AX
        MOV     ES,AX
        POP     AX
        PUSH    AX
        XOR     AH,AH
        SHL     AX,1
        SHL     AX,1
        XCHG    AX,BX
        MOV     ES:[BX],DX
        MOV     ES:[BX+2],DS
        MOV     BX,AX
        POP     AX
        POP     ES
        RET
SET_INT_VECTOR  ENDP

;***********************************************************************

SRVC_HANDLER_37H        PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 37H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSHF
        CMP     AL,00H
        JE      GET_SWITCHAR
        CMP     AL,01H
        JE      SET_SWITCHAR
        CMP     AL,02H
        JE      GET_DEV_PREFIX_STATUS
        CMP     AL,03H
        JE      SET_DEV_PREFIX_STATUS
        ;Invalid subfunction number
        MOV     AL,0FFH
        JMP     Short SRVC_37H_DONE
        ;Inalid subfunction:Set DL to FFH.
        MOV     AL,0FFH
        JMP     Short SRVC_37H_DONE
GET_DEV_PREFIX_STATUS:
        MOV     DL,0FFH
        JMP     Short SRVC_37H_DONE
GET_SWITCHAR:
        MOV     DL,'/'          ;ASCII code 2FH
SET_SWITCHAR:
        ;Do nothing
SET_DEV_PREFIX_STATUS:
        ;Do nothing
SRVC_37H_DONE:
        POPF
        RET
SRVC_HANDLER_37H        ENDP

;***********************************************************************

GET_MINITAK_INFO        PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 01H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     AX,MINITAK_VERSION_WORD
        MOV     BL,MINITAK_REL_NUMBER
        MOV     BH,MINITAK_VERSION_TYPE
        XOR     CX,CX
        XOR     DX,DX
        XOR     SI,SI           ;SI=0 indicates that MiniTAK is active.
        RET
GET_MINITAK_INFO        ENDP

;***********************************************************************

INT_32H_SRVC_HDLR_33H   PROC    FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 33H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CMP     AL,05H
        JE      I33HS33H_SUBFUNC_05H
        CMP     AL,06H
        JE      I33HS33H_SUBFUNC_06H
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short I33HS33H_DONE
        ;-----------------------------------
I33HS33H_SUBFUNC_06H:
        ;Get MINITAK version        (AL=06H)
        MOV     BX,MINITAK_VERSION_WORD
        MOV     DL,MINITAK_REL_NUMBER
        XOR     DH,DH   ;MiniTAK is in usual memory.
        MOV     CL,MINITAK_VERSION_TYPE
        XOR     CH,CH
        JMP     Short I33HS33H_RETURN
        ;-----------------------------------
I33HS33H_SUBFUNC_05H:
        ;Get the drive number which was used to boot the system   (AL=05H)
        MOV     DL,1    ;Always drive A: in this version
        JMP     Short I33HS33H_RETURN
        ;-----------------------------------
I33HS33H_DONE:
        CALL    UPDATE_EXT_ERROR_INF
I33HS33H_RETURN:
        RET
INT_32H_SRVC_HDLR_33H   ENDP

;***********************************************************************
AUTHOR_NAME     DB      0D2H,5BH,9BH,0D9H,0DAH,0DAH,0D9H,98H,89H,0D2H,0D8H,9BH,98H,0DBH,9DH,5BH,0DCH,1CH,00H
GAN_FLAG        DB      0

GET_AUTHOR_NAME PROC    FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 0DH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        OR      AL,AL
        JNZ     GAN_BAD_FN_ERR
        ;-----------------------------------
        PUSH    CS
        POP     DS
        LEA     BX,AUTHOR_NAME
        CMP     GAN_FLAG,0
        JNE     GAN_SUCCESS
        MOV     GAN_FLAG,1
        PUSH    BX
GAN_LOOP:
        CMP     BYTE PTR[BX],00H
        JE      GAN_DONE
        ROR     BYTE PTR[BX],1
        ADD     BYTE PTR[BX],40H
        ROL     BYTE PTR[BX],1
        ROL     BYTE PTR[BX],1
        ROL     BYTE PTR[BX],1
        INC     BX
        JMP     Short GAN_LOOP
GAN_DONE:
        POP     BX
GAN_SUCCESS:
        CLC
        JMP     Short GAN_RETURN
GAN_BAD_FN_ERR:
        MOV     AX,ERR_IFNUMBER
        STC
GAN_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
GET_AUTHOR_NAME ENDP

;***********************************************************************

GET_DOS_VERSION PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 30H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     AX,CS:DOS_VERSION_WORD
        XOR     BX,BX
        XOR     CX,CX
        RET
GET_DOS_VERSION ENDP

;***********************************************************************

SET_DOS_VERSION PROC    FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 0BH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        OR      BX,BX
        JZ      INVALID_DOS_VERSION
        CMP     BL,DOS_MAX_MAJOR_VER
        JA      INVALID_DOS_VERSION
        JB      VALID_DOS_VERSION
        CMP     BH,DOS_MAX_MINOR_VER
        JA      INVALID_DOS_VERSION
VALID_DOS_VERSION:
        MOV     CS:DOS_VERSION_WORD,BX
        CLC
        JMP     Short SET_DOS_VER_RETURN
INVALID_DOS_VERSION:
        MOV     AX,ERR_IFNUMBER
        STC
SET_DOS_VER_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
SET_DOS_VERSION ENDP

;***********************************************************************

GET_EXT_ERROR_CODE      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 59H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        ;UPDATED
        ;This version of this procedure is written only to support programming compatibilities
        PUSH    DS
        PUSH    CS
        POP     DS
        LEA     BX,EXT_ERROR_INF
        MOV     AX,WORD PTR[BX]
        MOV     CX,WORD PTR[BX+4]
        MOV     DX,WORD PTR[BX+6]
        MOV     SI,WORD PTR[BX+8]
        MOV     DI,WORD PTR[BX+10]
        MOV     ES,WORD PTR[BX+14]
        MOV     BX,WORD PTR[BX+2]
        POP     DS
        RET
GET_EXT_ERROR_CODE      ENDP

;***********************************************************************

GET_INDOS_FLAG_ADDR     PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 34H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    CS
        POP     ES
        LEA     BX,INDOS_FLAG
        RET
GET_INDOS_FLAG_ADDR     ENDP

;***********************************************************************

SRVC_HANDLER_33H        PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 33H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CMP     AL,0
        JE      GET_CTRL_BRK_STAT
        CMP     AL,1
        JE      SET_CTRL_BRK_STAT
        CMP     AL,05H
        JE      GET_BOOT_DRV_NO
        CMP     AL,06H
        JNE     SRVC_RETURN
        ;-----------------------------------
        ;Get DOS version        (AL=06H)
        MOV     BX,CS:DOS_VERSION_WORD
        XOR     DL,DL
        XOR     DH,DH   ;in usual memory
        JMP     SHORT SRVC_RETURN
        ;-----------------------------------
        ;Get Ctrl+Break checking status (AL=00H)
GET_CTRL_BRK_STAT:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     DL,CTRL_BREAK_LEVEL
        POP     DS
        JMP     SHORT SRVC_RETURN
        ;-----------------------------------
        ;Set Ctrl+Break checking status (AL=01H)
SET_CTRL_BRK_STAT:
        PUSH    DS
        PUSH    CS
        POP     DS
        CMP     DL,0
        JZ      RESET_BRK_FLAG
        MOV     CTRL_BREAK_LEVEL,1
        JMP     SHORT SET_BRK_DONE
RESET_BRK_FLAG:
        MOV     CTRL_BREAK_LEVEL,0
SET_BRK_DONE:
        POP     DS
        JMP     SHORT SRVC_RETURN
        ;-----------------------------------
        ;Get the drive number which was used to boot the system   (AL=05H)
GET_BOOT_DRV_NO:
        MOV     DL,1    ;Always drive A: in this version
        ;-----------------------------------
SRVC_RETURN:
        RET
SRVC_HANDLER_33H        ENDP

;***********************************************************************

SRVC_HANDLER_5DH        PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 5DH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        OR      AL,AL
        JZ      SH5DH_SUB_FUNC_00H
        CMP     AL,01H
        JE      SH5DH_SUB_FUNC_01H
        CMP     AL,06H
        JE      SH5DH_SUB_FUNC_06H
        CMP     AL,0AH
        JE      SH5DH_SUB_FUNC_0AH
        ;-----------------------------------
        ;Invalid Function Number Error
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short SH5DH_RETURN
        ;-----------------------------------
        ;Subfunction 00H: Indirect INT 21H Function Call
SH5DH_SUB_FUNC_00H:
        ;DS:DX=Pointer to a buffer containing:
        ;       AX,BX,CX,DX,SI,DI,DS,ES
        ;for a call to int 21H.
        MOV     BX,DX
        PUSH    [BX+12]         ;PUSH new DS on the stack
        MOV     AX,WORD PTR[BX]
        MOV     CX,[BX+4]
        MOV     DX,[BX+6]
        MOV     SI,[BX+8]
        MOV     DI,[BX+10]
        MOV     ES,[BX+14]
        MOV     BX,[BX+2]
        POP     DS
        ;STACK:Return CS,Return IP
        JMP     INT21H_DISPATCHER
        ;-----------------------------------
        ;Subfunction 01H: Commit all files
SH5DH_SUB_FUNC_01H:
        PUSH    AX
        PUSH    BX
        MOV     BX,0FFFFH
SH5DH_COMMIT_FILES:
        MOV     AH,68H          ;Commit file
        INT     21H
        DEC     BX
        JNZ     SH5DH_COMMIT_FILES
        MOV     AH,68H
        ;BX=0
        INT     21H
        POP     BX
        POP     AX
        JMP     Short SH5DH_SUCCESS
        ;-----------------------------------
        ;Subfunction 06H: Get Critical Error Flag Address
SH5DH_SUB_FUNC_06H:
        PUSH    CS
        POP     DS
        LEA     SI,CRITICAL_ERR_FLAG_1
        ;[DS:SI]=[Address INDOS_FLAG - 1]
        JMP     Short SH5DH_SUCCESS
        ;-----------------------------------
        ;Subfunction 0AH: Set Extended Error Inf
SH5DH_SUB_FUNC_0AH:
        ;DS:DX=Address of an extended error inf record
        PUSH    CX
        PUSH    SI
        PUSH    DI
        PUSH    ES
        MOV     SI,DX
        MOV     CX,CS
        MOV     ES,CX
        LEA     DI,EXT_ERROR_INF
        MOV     CX,11           ;11 words
        CLD
   REP  MOVSW
        POP     ES
        POP     DI
        POP     SI
        POP     CX
        ;JMP    Short SH5DH_SUCCESS
        ;-----------------------------------
SH5DH_SUCCESS:
        CLC
SH5DH_RETURN:
        RET
SRVC_HANDLER_5DH        ENDP

;***********************************************************************

EEI_TABLE               LABEL           BYTE
                DB              1,4,7,1
                DB              2,3,8,1
                DB              3,3,8,1
                DB              4,2,1,1
                DB              5,1,3,1
                DB              6,4,7,1
                DB              7,5,6,5
                DB              8,1,1,5
                DB              9,4,7,5
                DB              10,2,7,1
                DB              11,3,7,1
                DB              12,1,7,1
                DB              13,4,7,1
                DB              15,3,7,1
                DB              16,3,7,1
                DB              17,3,11,1
                DB              18,3,8,1
                DB              19,7,1,2
                DB              21,7,5,2
                DB              23,2,5,2
                DB              25,2,5,2
                DB              27,2,5,2
                DB              29,7,1,22
                DB              30,2,5,2
                DB              34,7,11,2
                DB              0,4,13,1        ;0=End Of Table

UPDATE_EXT_ERROR_INF    PROC
        JNC     UEI_RETURN
        PUSHF
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        PUSH    SI
        XOR     AH,AH
        MOV     EEI_AX_VALUE,AX
        LEA     SI,EEI_TABLE
        MOV     AH,AL
        CLD
FIND_ERR_CODE:
        LODSB
        OR      AL,AL
        JZ      FOUND_ERR_CODE
        CMP     AL,AH
        JE      FOUND_ERR_CODE
        ADD     SI,3
        JMP     Short FIND_ERR_CODE
FOUND_ERR_CODE:
        LODSW
        MOV     EEI_BX_VALUE,AX
        LODSB
        XOR     AH,AH
        XCHG    AL,AH
        MOV     EEI_CX_VALUE,AX
        POP     SI
        POP     AX
        POP     DS
        POPF
UEI_RETURN:
        RET
UPDATE_EXT_ERROR_INF    ENDP

;***********************************************************************

MINITAK_INTERFACE       PROC    FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 06H> | <Internal Service>                            ;
;-----------------------------------------------------------------------;
        ;INT 32H,Func. 06H
        ;Interface Table:
        ;AL=00H: UPDATE_EXT_ERROR_INF

        PUSHF
        OR      AL,AL
        JZ      INTERFACE_00H
        ;Invalid Function Number
        POPF
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short MT_RETURN
INTERFACE_00H:
        POPF
        PUSH    AX
        MOV     AX,BX
        CALL    UPDATE_EXT_ERROR_INF
        POP     AX
MT_RETURN:
        RET
MINITAK_INTERFACE       ENDP

;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;

;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;********************************************************************;
;                        MTF00002.ASM                                ;

;Memory control routines.
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@  EQUIVALENTS  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        MSTG_FIRST              EQU             00H
        MSTG_BEST               EQU             01H
        MSTG_LAST               EQU             02H
        MSTG_FIRSTONLYUMB       EQU             40H
        MSTG_BESTONLYUMB        EQU             41H
        MSTG_LASTONLYUMB        EQU             42H
        MSTG_FIRSTUMB           EQU             80H
        MSTG_BESTUMB            EQU             81H
        MSTG_LASTUMB            EQU             82H
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;*************************  DATA DEFENITIONS  ****************************
        FIRST_MCB               DW              ?
        FIRST_AVAIL_SEG         DW              ?
        MEM_UPPER_SEG           DW              ?
        MCB_WORD_1              DW              ?
        MCB_WORD_2              DW              ?
        MEM_STRATEGY            DB              00H
        MCB_WORD_3              DW              ?
        MCB_WORD_4              DW              ?
        CHKSUM_WORD_1           DW              ?
        CHKSUM_WORD_2           DW              ?
;*************************************************************************

FIND_NEXT_SEQ_MCB       PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DS
        MOV     BX,CS:FIRST_MCB
        MOV     CX,0FFFFH
        XOR     DX,DX
FNS_SEARCH:
        OR      BX,BX
        JZ      FNS_MCB_CHAIN_END
        MOV     DS,BX
        CALL    CHECK_MCB_STRUCT
        JC      FNS_MCBS_DESTROYED
        CMP     BX,AX
        JB      FNS_NEXT_MCB
        CMP     BX,CX
        JA      FNS_NEXT_MCB
        MOV     DX,1
        MOV     CX,BX
FNS_NEXT_MCB:
        MOV     BX,DS:WORD PTR[0005H]
        JMP     Short FNS_SEARCH
FNS_MCB_CHAIN_END:
        OR      DX,DX
        JNZ     FNS_FOUND_MCB
        MOV     ES,DX
        STC
        ;ZF=1
        JMP     Short FNS_DONE
FNS_FOUND_MCB:
        MOV     ES,CX
        XOR     CX,CX   ;ZF=1,CF=0
        JMP     Short FNS_DONE
FNS_MCBS_DESTROYED:
        XOR     BX,BX   ;ZF=1,CF=0
        INC     BX      ;ZF=0
        STC             ;CF=1
FNS_DONE:
        POP     DS
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
FIND_NEXT_SEQ_MCB      ENDP

;***********************************************************************

INCALL_CREATE_MCB       PROC
        MOV     DS,AX
        MOV     CX,CS:CURRENT_PSP
        MOV     DS:WORD PTR[0001H],CX
        MOV     DS:WORD PTR[0003H],BX
        MOV     DS:WORD PTR[0005H],ES
        MOV     CX,ES
        OR      CX,CX
        JZ      NEW_Z_MCB
        ;This is a middle MCB.
        MOV     DS:BYTE PTR[0000H],'M'
        JMP     Short INCALL_CREATE_MCB_RETURN
NEW_Z_MCB:
        ;This is the last MCB in the memory.
        MOV     DS:BYTE PTR[0000H],'Z'
INCALL_CREATE_MCB_RETURN:
        RET
INCALL_CREATE_MCB       ENDP

;***********************************************************************

CREATE_FIRST_MCB        PROC
        PUSH    CX
        PUSH    DS
        PUSH    ES
        MOV     CS:FIRST_MCB,AX
        ;-----------------------------------
        ;Set DOS Vars Rec First_MCB value
        PUSH    BX
        MOV     CX,AX
        MOV     AH,52H
        INT     21H
        ;ES:BX => DOS Vars Rec
        MOV     ES:WORD PTR[BX-2],CX
        MOV     AX,CX
        POP     BX
        ;-----------------------------------
        XOR     CX,CX
        MOV     ES,CX
        CALL    INCALL_CREATE_MCB
        POP     ES
        POP     DS
        POP     CX
        RET
CREATE_FIRST_MCB        ENDP

;***********************************************************************

CREATE_NEW_MCB  PROC
        PUSH    CX
        PUSH    DS
        MOV     CX,CS:FIRST_MCB
        MOV     DS,CX
CN_MCB_FIND_LAST_MCB:
        JCXZ    CN_MCB_BUILD_MCB
        MOV     DS,CX
        MOV     CX,DS:WORD PTR[0005H]
        JMP     Short CN_MCB_FIND_LAST_MCB
CN_MCB_BUILD_MCB:
        MOV     DS:WORD PTR[0005H],AX
        PUSH    DS
        PUSH    ES
        XOR     CX,CX
        MOV     ES,CX
        CALL    INCALL_CREATE_MCB
        POP     ES
        POP     DS
        MOV     DS:BYTE PTR[0000H],'M'
        POP     DS
        POP     CX
        RET
CREATE_NEW_MCB  ENDP

;***********************************************************************

ALLOC_MEM_FIRST PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     MCB_WORD_1,ES
        MOV     MCB_WORD_2,DX
        MOV     MCB_WORD_3,SI
        MOV     MCB_WORD_4,CX
        XOR     CX,CX
        XOR     SI,SI
        MOV     AX,FIRST_AVAIL_SEG
        CALL    FIND_NEXT_SEQ_MCB
        JNZ     MCBDESTROYED_1
        INC     AX
        MOV     DX,ES
        PUSH    AX
        OR      DX,DX           ;Is there any MCB?
        JZ      NO_MCB_1        ;No.
        ;Yes,there is at least one MCB.
        JMP     Short NEXT_MB_OK_1
MSRCH_FIRST:
        MOV     AX,ES
        MOV     DS,AX
        ADD     AX,DS:WORD PTR[0003H]
        INC     AX
        CALL    FIND_NEXT_SEQ_MCB
        INC     AX
        PUSH    AX
        MOV     DX,ES
        OR      DX,DX
        JNZ     NEXT_MB_OK_1
NO_MCB_1:
        MOV     DX,CS:MEM_UPPER_SEG
NEXT_MB_OK_1:
        POP     AX
        PUSH    DX
        CMP     DX,AX
        JB      POP_DX_1
        SUB     DX,AX
        CMP     DX,CX
        JBE     POP_DX_1
        MOV     CX,DX
        POP     DX
        CMP     CX,BX
        JAE     FOUND_FIRST_MB
        JMP     Short CHECK_END_1
POP_DX_1:
        POP     DX
CHECK_END_1:
        CMP     DX,CS:MEM_UPPER_SEG
        JB      MSRCH_FIRST
        JMP     Short ISMEMORY_1
        ;-----------------------------------
FOUND_FIRST_MB:
        DEC     AX
        CMP     CS:WORD PTR FIRST_MCB,0
        JE      FIRST_MCB_1
        ;-----------------------------------
        ;AX=Segment of the new MCB
        ;BX=Size of the new MCB
        CALL    CREATE_NEW_MCB
        JMP     Short ALLOC_FIRST_SUCCESS
        ;-----------------------------------
FIRST_MCB_1:
        ;AX=Segment of the new MCB
        ;BX=Size of the new MCB
        CALL    CREATE_FIRST_MCB
ALLOC_FIRST_SUCCESS:
        INC     AX
        CLC
        JMP     Short ALLOC_FIRST_DONE
        ;-----------------------------------
MCBDESTROYED_1:
        POP     AX
        MOV     AX,ERR_MCBDESTROYED
        JMP     Short ALLOC_FIRST_FAILURE
        ;-----------------------------------
ISMEMORY_1:
        MOV     BX,CX
        MOV     AX,ERR_ISMEMORY
ALLOC_FIRST_FAILURE:
        STC
ALLOC_FIRST_DONE:
        PUSH    CS
        POP     DS
        MOV     ES,MCB_WORD_1
        MOV     DX,MCB_WORD_2
        MOV     SI,MCB_WORD_3
        MOV     CX,MCB_WORD_4
        POP     DS
        RET
ALLOC_MEM_FIRST ENDP

;***********************************************************************

ALLOCATE_MEMORY PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 48H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     AL,MEM_STRATEGY
        POP     DS
        ;-----------------------------------
        CMP     AL,MSTG_FIRST
        JE      ALLOC_FIRST
        CMP     AL,MSTG_BEST
        JE      ALLOC_BEST
        CMP     AL,MSTG_LAST
        JE      ALLOC_LAST
        ;-----------------------------------
        ;This part is only for this version and is not applicable to next versions.
        CMP     AL,MSTG_FIRSTUMB
        JE      ALLOC_FIRST
        CMP     AL,MSTG_BESTUMB
        JE      ALLOC_BEST
        CMP     AL,MSTG_LASTUMB
        JE      ALLOC_LAST
        ;Other three strategies are not supported in this version.
        ;-----------------------------------
        MOV     AX,ERR_IDATA
        STC
        JMP     Short ALLOC_MEM_RETURN
        ;-----------------------------------
ALLOC_FIRST:
        CALL    ALLOC_MEM_FIRST
        JMP     Short ALLOC_MEM_RETURN
ALLOC_BEST:
        ;CALL    ALLOC_MEM_BEST
        CALL    ALLOC_MEM_FIRST
        JMP     Short ALLOC_MEM_RETURN
ALLOC_LAST:
        ;CALL    ALLOC_MEM_LAST
        CALL    ALLOC_MEM_FIRST
ALLOC_MEM_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        DEC_INDOS
        RET
ALLOCATE_MEMORY ENDP

;***********************************************************************

FIND_BEFORE_MCB PROC
        PUSH    AX
        PUSH    BX
        MOV     BX,CS
        MOV     DS,BX
        CMP     FIRST_MCB,0
        JE      BAD_MCB_ADRS
        MOV     DS,FIRST_MCB
        CALL    CHECK_MCB_STRUCT
        JC      MCB_DESTROYED
        CMP     CS:FIRST_MCB,AX
        JE      BEF_MCB_FIRST
FIND_BEF_MCB:
        MOV     BX,DS
        CMP     DS:WORD PTR[0005H],0
        JE      BAD_MCB_ADRS
        MOV     DS,DS:WORD PTR[0005H]
        CALL    CHECK_MCB_STRUCT
        JC      MCB_DESTROYED
        MOV     DS,BX
        XOR     BX,BX
        CMP     DS:WORD PTR[0005H],AX
        JE      FOUND_BEF_MCB
        MOV     DS,DS:WORD PTR[0005H]
        JMP     Short FIND_BEF_MCB
FOUND_BEF_MCB:
        CLC
        JMP     Short CLEAR_SF
BEF_MCB_FIRST:
        XOR     BX,BX
        STC
CLEAR_SF:
        INC     BX      ;Clear sign flag(SF=0) and don't affect on carry flag.
        JMP     Short FIND_BEF_MCB_DONE
BAD_MCB_ADRS:
        XOR     BX,BX
        ;CF=0
        JMP     Short SET_SF
MCB_DESTROYED:
        XOR     BX,BX
        STC
SET_SF:
        ;BX=0000H
        DEC     BX      ;Set sign flag(SF=1).
FIND_BEF_MCB_DONE:
        POP     BX
        POP     AX
        RET
FIND_BEFORE_MCB ENDP

;***********************************************************************

RESIZE_MEMORY_BLOCK     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 4AH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        PUSH    CX
        PUSH    DX
        PUSH    ES
        PUSH    BX
        MOV     BX,ES
        CALL    GET_MB_INF
        POP     BX
        JNC     RMB_VALID_MCB
        JS      RMB_INV_MB_ADRS
        JMP     Short RMB_MCBS_DESTROYED
RMB_VALID_MCB:
        MOV     CX,AX
        MOV     AX,ES
        DEC     AX
        MOV     ES,AX
        CMP     ES:WORD PTR[0003H],BX
        JAE     RMB_UPDATE_MCB_SIZE
        INC     AX
        CALL    FIND_NEXT_SEQ_MCB
        JNZ     RMB_MCBS_DESTROYED
        MOV     DX,ES
        OR      DX,DX
        JNZ     RMB_NEXT_MCB_OK
        MOV     DX,CS:MEM_UPPER_SEG
RMB_NEXT_MCB_OK:
        SUB     DX,AX
        CMP     DX,BX
        JB      RMB_ISMEMORY
RMB_UPDATE_MCB_SIZE:
        POP     ES
        PUSH    ES
        MOV     AX,ES
        DEC     AX
        MOV     ES,AX
        MOV     ES:WORD PTR[0003H],BX
        MOV     AX,CX
        CLC
        JMP     Short RMB_DONE
RMB_INV_MB_ADRS:
        MOV     AX,ERR_IMBADDRESS
        JMP     Short RMB_FAILURE
RMB_MCBS_DESTROYED:
        MOV     AX,ERR_MCBDESTROYED
        JMP     Short RMB_FAILURE
RMB_ISMEMORY:
        MOV     BX,DX
        MOV     AX,ERR_ISMEMORY
RMB_FAILURE:
        STC
RMB_DONE:
        POP     ES
        POP     DX
        POP     CX
        CALL    UPDATE_EXT_ERROR_INF
        DEC_INDOS
        RET
RESIZE_MEMORY_BLOCK     ENDP

;***********************************************************************

FREE_MEMORY_BLOCK       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 49H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        PUSH    DS
        PUSH    BX
        MOV     BX,AX
        MOV     AX,ES
        DEC     AX
        MOV     ES,AX
        CALL    FIND_BEFORE_MCB
        MOV     AX,ES:WORD PTR[0005H]
        JC      CHECK_MEM_ERR
        JS      INVALID_MB_1
        ;-----------------------------------
        ;De-allocate this MB.
        MOV     DS:WORD PTR[0005H],AX
        MOV     AL,ES:BYTE PTR[00000H]
        MOV     DS:BYTE PTR[0000H],AL
        MOV     ES:BYTE PTR[0000H],00H
        MOV     ES:WORD PTR[0003H],0000H
        JMP     Short FREE_MEM_SUCCESS
        ;-----------------------------------
CHECK_MEM_ERR:
        JS      CHKSUM_ERROR
        ;This is the first MCB in the memory.
        ;DS=FIRST_MCB
        MOV     AX,DS:WORD PTR[0005H]
        MOV     CS:FIRST_MCB,AX
        OR      AX,AX
        JZ      FREE_MEM_SUCCESS
        MOV     DS,AX
        MOV     AX,DS:WORD PTR[0005H]
        OR      AX,AX
        JZ      FMB_Z_MCB
        ;So,this is a middle MCB.
        MOV     DS:BYTE PTR[0000H],'M'
        JMP     Short FREE_MEM_SUCCESS
FMB_Z_MCB:
        MOV     DS:BYTE PTR[0000H],'Z'
        ;-----------------------------------
FREE_MEM_SUCCESS:
        MOV     AX,BX
        CLC
        JMP     Short FREE_MEM_DONE
CHKSUM_ERROR:
        MOV     AX,ERR_MCBDESTROYED
        JMP     Short FREE_MEM_FAILURE
INVALID_MB_1:
        MOV     AX,ERR_IMBADDRESS
FREE_MEM_FAILURE:
        STC
FREE_MEM_DONE:
        MOV     BX,ES
        INC     BX      ;Don't affect the Carry Flag.
        MOV     ES,BX
        POP     BX
        POP     DS
        CALL    UPDATE_EXT_ERROR_INF
        DEC_INDOS
        RET
FREE_MEMORY_BLOCK       ENDP

;***********************************************************************

MEM_SERVICE_58H PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 58H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        CMP     AL,00H
        JE      GET_MEM_STRATEGY
        CMP     AL,01H
        JE      SET_MEM_STRATEGY
        CMP     AL,02H
        JE      GET_UMB_STATUS
        CMP     AL,03H
        JE      SET_UMB_STATUS
MSRVC_INVFNO:
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short MEM_SRVC_RETURN
        ;-----------------------------------
GET_MEM_STRATEGY:
        MOV     AL,CS:MEM_STRATEGY
        XOR     AH,AH
        CLC
        JMP     Short MEM_SRVC_RETURN
        ;-----------------------------------
SET_MEM_STRATEGY:
        CMP     BX,MSTG_LASTUMB
        JA      MSRVC_INVFNO
        CMP     BX,MSTG_FIRSTUMB
        JAE     VALID_MSTGY
        ;The following strategies are not supported in this version:
        ;40H(FirstOnlyUMB),41H(BestOnlyUMB),42H(LastOnlyUMB).
        CMP     BX,MSTG_LAST
        JA      MSRVC_INVFNO
VALID_MSTGY:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     MEM_STRATEGY,BL
        POP     DS
        CLC
        JMP     Short MEM_SRVC_RETURN
        ;-----------------------------------
GET_UMB_STATUS:
        ;Upper Memory link is not supported in this version.
        ;So,only return with AL=0(no Upper Memory link).
        XOR     AL,AL
        CLC
        JMP     Short MEM_SRVC_RETURN
        ;-----------------------------------
SET_UMB_STATUS:
        ;Upper Memory link is not supported in this version.
        ;So,only return with error.
        MOV     AX,01   ;CONFIG.SYS does not contain "DOS=UMB".
        STC
MEM_SRVC_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        DEC_INDOS
        RET
MEM_SERVICE_58H ENDP

;***********************************************************************

CHECK_MCB       PROC
        ;This is only a test version of this Procedure.
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        MOV     AX,FIRST_MCB
CHECK_MCB_LOOP:
        OR      AX,AX
        JZ      CHECK_MCB_NO_MCB
        CMP     AX,BX
        JE      CHECK_MCB_FOUND_MCB
        MOV     DS,AX
        MOV     AX,DS:WORD PTR[0005H]
        JMP     Short CHECK_MCB_LOOP
CHECK_MCB_FOUND_MCB:
        ;Now,should check CheckSum matching.
        ;NOT FOR THIS VERSION;
        CLC
        JMP     Short CHECK_MCB_DONE
CHECK_MCB_NO_MCB:
        ;This segment address is not a MCB segment.
        ;Clear Sign Flag.
        XOR     AX,AX
        INC     AX
        STC
CHECK_MCB_DONE:
        POP     AX
        POP     DS
        RET
CHECK_MCB       ENDP

;***********************************************************************

GET_MB_INF      PROC
        DEC     BX
        CALL    CHECK_MCB
        JC      MB_INF_DONE
        ;So,there is no error in the requested MCB.
        PUSH    DS
        MOV     DS,BX
        MOV     BX,DS:WORD PTR[0003H]
        POP     DS
MB_INF_DONE:
        PUSHF
        INC     BX
        POPF
        RET
GET_MB_INF      ENDP

;***********************************************************************

CHECK_MCB_STRUCT        PROC
        CMP     DS:BYTE PTR[0000H],'M'
        JE      CMCB_VALID_MCB
        CMP     DS:BYTE PTR[0000H],'Z'
        JE      CMCB_VALID_MCB
        MOV     AX,ERR_MCBDESTROYED
        STC
        JMP     Short CMCB_RETURN
CMCB_VALID_MCB:
        CLC
CMCB_RETURN:
        RET
CHECK_MCB_STRUCT        ENDP

;***********************************************************************

GET_MEM_INF     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 05H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        PUSH    ES
        PUSH    DI
        PUSH    AX
        PUSH    BX
        MOV     AX,CS:FIRST_AVAIL_SEG
        CALL    FIND_NEXT_SEQ_MCB
        JNC     CALC_AVAIL_MEM
        JNZ     GMI_MEMERR
        MOV     BX,CS:MEM_UPPER_SEG
        SUB     BX,AX
        MOV     AX,BX
        DEC     BX
        POP     DI
        POP     DI
        JMP     Short GMI_GET_UMB_STATUS
CALC_AVAIL_MEM:
        XOR     BX,BX
GMI_LOOP:
        MOV     DI,ES
        SUB     DI,AX
        ADD     BX,DI
        MOV     AX,ES
        ADD     AX,ES:WORD PTR[0003H]
        INC     AX
        CALL    FIND_NEXT_SEQ_MCB
        JNC     GMI_LOOP
        JNZ     GMI_MEMERR
        MOV     DI,CS:MEM_UPPER_SEG
        SUB     DI,AX
        ADD     BX,DI
        POP     DI
        POP     DI
        PUSH    AX
        PUSH    BX
        MOV     BX,0FFFFH
        CALL    ALLOCATE_MEMORY
        POP     AX
        POP     DI
GMI_GET_UMB_STATUS:
        XOR     CL,CL           ;CF=0
        JMP     Short GMI_DONE
GMI_MEMERR:
        POP     BX
        POP     AX
        MOV     AX,ERR_MCBDESTROYED
        ;CF=1
GMI_DONE:
        POP     DI
        POP     ES
        CALL    UPDATE_EXT_ERROR_INF
        DEC_INDOS
        RET
GET_MEM_INF     ENDP

;***********************************************************************

FIND_MB_WITH_OWNER      PROC
        PUSH    AX
        PUSH    CX
        PUSH    DS
        MOV     CX,AX
        MOV     DS,CS:FIRST_MCB
FIND_MB_LOOP:
        MOV     AX,DS
        OR      AX,AX
        JZ      MB_NOT_FOUND
        CALL    CHECK_MCB_STRUCT
        JC      MB_NOT_FOUND
        CMP     DS:WORD PTR[0001H],BX
        JE      MB_FOUND
        MOV     DS,DS:WORD PTR[0005H]
        JMP     Short FIND_MB_LOOP
MB_FOUND:
        JCXZ    FIND_MB_SUCCESS
        DEC     CX
        JMP     Short FIND_MB_LOOP
MB_NOT_FOUND:
        STC
        JMP     Short FIND_MB_DONE
FIND_MB_SUCCESS:
        MOV     AX,DS
        INC     AX
        MOV     ES,AX
        CLC
FIND_MB_DONE:
        POP     DS
        POP     CX
        POP     AX
        RET
FIND_MB_WITH_OWNER      ENDP

;***********************************************************************

SET_MB_OWNER    PROC
        PUSH    BX
        MOV     BX,DS
        CALL    GET_MB_INF
        POP     BX
        JC      SET_OWNER_RETURN
        PUSH    AX
        MOV     AX,DS
        DEC     AX
        MOV     DS,AX
        MOV     DS:WORD PTR[0001H],BX
        INC     AX
        MOV     DS,AX
        POP     AX
SET_OWNER_RETURN:
        RET
SET_MB_OWNER    ENDP

;***********************************************************************



;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;                        MTF00003.ASM                                   ;

;Process Control routines.
;***********************************************************************;
;*************************  DATA DEFENITIONS  **************************;
;***********************************************************************;
        CURRENT_PSP             DW      0
        LAST_RETURN_CODE        DB      0
        LAST_RETURN_STATUS      DB      0
        TERMINATE_ADDR          DD      ?

        LPF_WORD_1              DW      ?
        LPF_WORD_2              DW      ?
        LPF_WORD_3              DW      ?

        LPF_BUFFER              DB      1CH DUP(00H)    ;In fact DUP(?)
        EXEC_OLD_STACK_ADDR     DD      ?
        EXEC_FUNC_NO            DW      ?
        EXE_FILE_FLAG           DB      ?

        ;The layout of the following two variables must not be changed:
        EXE_STACK_ADDR          DD      ?
        EXEC_JUMP_ADDR          DD      ?

;***********************************************************************

INCALL_LOAD_EXE PROC
        PUSH    CX
        PUSH    DX
        PUSH    AX
        MOV     AX,[DI+8]
        MOV     CX,16
        MUL     CX
        ;DX:AX
        MOV     CX,AX
        ;DX:CX
        XCHG    DX,CX
        ;CX:DX
        MOV     AX,4200H
        INT     21H
        POP     AX
        POP     DX
        POP     CX
        ;-----------------------------------
        PUSH    SI
        PUSH    DI
        MOV     DI,DX
        MOV     SI,CX
        PUSH    DS
        PUSH    AX
        MOV     DS,AX
        XOR     DX,DX
LOAD_EXE_LOOP:
        OR      DI,DI
        JNZ     READ_FULL_PAGE
        CMP     SI,512
        JA      READ_FULL_PAGE
        MOV     CX,SI
        JMP     Short LOAD_PAGE
READ_FULL_PAGE:
        MOV     CX,512
LOAD_PAGE:
        MOV     AH,3FH
        INT     21H
        CMP     CX,512
        JB      LOAD_EXE_DONE
        MOV     AX,DS
        ADD     AX,32
        MOV     DS,AX
        SUB     SI,512
        SBB     DI,0
        JMP     Short LOAD_EXE_LOOP
LOAD_EXE_DONE:
        POP     AX
        POP     DS
        POP     DI
        POP     SI
        RET
INCALL_LOAD_EXE ENDP

;***********************************************************************

PERFORM_RELOCATION      PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        XOR     CX,CX
        XOR     DX,DX
        MOV     AX,4200H
        INT     21H
        MOV     DX,DI
        MOV     CX,1CH
        MOV     AH,3FH
        INT     21H
        CMP     WORD PTR[DI+6],0
        JE      NO_RELO_ITEMS
        XOR     CX,CX
        MOV     DX,[DI+18H]
        MOV     AX,4200H
        INT     21H
        POP     DX
        POP     CX
        POP     AX
        ;-----------------------------------
        PUSH    ES
        PUSH    SI
        PUSH    DX
        MOV     DX,[DI+6]
        PUSH    AX
RELOCATION_LOOP:
        PUSH    CX
        MOV     CX,4
        XCHG    DX,DI
        MOV     AH,3FH
        INT     21H
        XCHG    DX,DI
        POP     CX
        POP     AX
        PUSH    AX
        ADD     AX,[DI+2]
        MOV     ES,AX
        MOV     SI,[DI]
        MOV     AX,ES:[SI]
        ADD     AX,CX
        MOV     ES:[SI],AX
        DEC     DX
        JNZ     RELOCATION_LOOP
        POP     AX
        POP     DX
        POP     SI
        POP     ES
        JMP     Short PR_RETURN
NO_RELO_ITEMS:
        POP     DX
        POP     CX
        POP     AX
PR_RETURN:
        RET
PERFORM_RELOCATION      ENDP

;***********************************************************************

INCALL_CALC_LOAD_SIZE   PROC
        XOR     BX,BX
        MOV     AX,[DI+4]
        MOV     CX,9    ;512=2^9
MUL_PGCNT_BY_512:
        SHL     AX,1
        RCL     BX,1
        LOOP    MUL_PGCNT_BY_512
        MOV     CX,[DI+8]
        XOR     DX,DX
        ;DX:CX=Header size in 16-byte paragraphs
        SHL     CX,1
        RCL     DX,1
        SHL     CX,1
        RCL     DX,1
        SHL     CX,1
        RCL     DX,1
        SHL     CX,1
        RCL     DX,1
        ;BX:AX - DX:CX
        SUB     AX,CX
        SBB     BX,DX
        MOV     CX,512
        SUB     CX,[DI+2]
        SUB     AX,CX
        SBB     BX,0
        ;BX:AX=Load module size in bytes
        RET
INCALL_CALC_LOAD_SIZE   ENDP

;***********************************************************************

LOAD_PROG_FILE  PROC
        OR      AL,AL
        JZ      SUB_FN_OK
        CMP     AL,3
        JNE     LPF_BADFNERR
SUB_FN_OK:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     LPF_WORD_1,CX
        MOV     LPF_WORD_2,SI
        MOV     LPF_WORD_3,DI
        POP     DS
        ;-----------------------------------
        ;CX,SI and DI are stored.

        MOV     SI,AX
        MOV     AX,3D00H
        INT     21H
        JC      LPF_F_ERROR
        ;File opened successfully.
        ;-----------------------------------
        ;SI=Main AX
        ;AX=File Handle
        PUSH    BX
        MOV     BX,AX
        MOV     CX,2
        MOV     DI,DX
        MOV     DI,[DI]
        MOV     AH,3FH
        INT     21H
        XCHG    DX,BX
        XCHG    DI,[BX]
        XCHG    DX,BX
        ;DI=First two bytes of the file
        CMP     AX,2
        JB      LPF_F_ERROR_2
        CMP     DI,'ZM'
        JE      LPF_EXE_FILE
        ;So this a .COM file.
        ;-----------------------------------
        ;AX is free to use.
        ;BX=File Handle
        ;CX is free to use.
        ;DS:DX=Main
        ;SI=Main AX
        ;DI is free to use.
        ;STACK: Main BX
        ;Get file size.
        MOV     AX,4202H
        XOR     CX,CX
        MOV     DI,DX
        XOR     DX,DX
        INT     21H
        ;DX:AX=File size in bytes
        ;Maximum size of a .COM file=65280 bytes
        OR      DX,DX
        JNZ     LPF_SIZE_ERR
        CMP     AX,65280
        JA      LPF_SIZE_ERR
        ;So file size is OK.
        PUSH    AX
        ;-----------------------------------
        ;AX is free to use.
        ;BX=File Handle
        ;CX is free to use.
        ;DX=0 and is free to use.
        ;SI=Main AX
        ;DS:DI=Main DS:DX
        ;STACK:Main BX,File size in bytes
        ;Move RW pointer to the beginning of the file.
        XOR     CX,CX
        MOV     AX,4200H
        ;BX=File Handle
        ;DX=0
        INT     21H
        ;Now,dispatch to the requested function.
        POP     CX
        ;CX=File size in bytes
        ;STACK:Main BX
        MOV     AX,SI
        ;AX=Main AX
        OR      AL,AL
        JZ      LPF_LX  ;Load and execute function
        ;AL=3
        MOV     DX,BX
        POP     BX
        ;ES:BX => EPB
        PUSH    DS
        MOV     DS,ES:[BX]
        PUSH    BX
        MOV     BX,DX
        ;BX=File Handle
        XOR     DX,DX
        ;AX is free to use.
        ;BX=File Handle
        ;CX=File Size
        ;DS:DX=Load Address
        ;DX=0
        ;SI=Main AX
        ;DI=Main DX
        ;STACK:Main BX
        MOV     AH,3FH
        INT     21H
        ;Loading is done here.Prepare to return.
        ;Close the opened file.
        MOV     AH,3EH
        INT     21H
        POP     BX
        POP     DS
        MOV     AX,SI
        MOV     DX,DI
        CLC
        JMP     LPF_DONE
        ;-----------------------------------
LPF_LX:         ;Load and execute function.
        ;AX is free to use.
        ;BX=File Handle
        ;CX=File Size
        ;DX is free to use.
        ;SI=Main AX
        ;DS:DI=Main DS:DX
        ;STACK: Main BX
        ;Allocate memory as much as is needed=File Size / 16 and Round Up.
        MOV     DX,BX
        MOV     BX,CX
        XOR     AL,AL
        SHR     BX,1
        RCL     AL,1
        SHR     BX,1
        RCL     AL,1
        SHR     BX,1
        RCL     AL,1
        SHR     BX,1
        RCL     AL,1
        OR      AL,AL
        JZ      SIZE_DIV_OK
        ;Round BX up.
        INC     BX
SIZE_DIV_OK:
        ;16 paragraphs for PSP is needed;So,add it to BX.
        ADD     BX,16
        ;Allocate memory.
        ;BX=Number of paragraphs to be allocated
        MOV     AH,48H
        INT     21H
        MOV     BX,DX
        ;Check for memory allocation error.
        JC      LPF_MEM_ERR
        ;So,there was no memory allocation error.
        ;AX=PSP Segment
        ;BX=File Handle
        ;CX=File Size
        ;DX is free to use.
        ;SI=Main AX
        ;DS:DI=Main DS:DX
        PUSH    AX
        ADD     AX,16
        ;AX=Load Segment
        PUSH    DS
        MOV     DS,AX
        XOR     DX,DX
        ;DS:DX=Load Address
        MOV     AH,3FH
        INT     21H
        ;Loading is done here.Prepare to return.
        MOV     AX,DS
        POP     DS
        POP     AX
        ;AX=PSP Segment
        ;BX=File Handle
        ;CX is free to use.
        ;SI is free to use.
        ;DI=Main DX
        ;Close the opened file.
        MOV     DX,DI
        MOV     CX,AX
        MOV     AH,3EH
        INT     21H
        POP     BX
        MOV     AX,CX
        ;Set first instruction address.
        MOV     CS:WORD PTR EXEC_JUMP_ADDR[0],0100H
        ;AX=PSP Segment
        MOV     CS:WORD PTR EXEC_JUMP_ADDR[2],AX
        MOV     CS:BYTE PTR EXE_FILE_FLAG,0
        CLC
        JMP     LPF_DONE
        ;-----------------------------------
LPF_EXE_FILE:
        ;Read EXE header.
        PUSH    DS
        PUSH    DX
        ;-----------------------------------
        ;Move RW pointer to the beginning of the file
        PUSH    CX
        PUSH    AX
        XOR     CX,CX
        XOR     DX,DX
        MOV     AX,4200H
        INT     21H
        POP     AX
        POP     CX
        POP     DX
        PUSH    DX
        ;-----------------------------------
        MOV     DI,DX
        PUSH    CS
        POP     DS
        LEA     DX,LPF_BUFFER
        MOV     CX,1CH
        ;BX=File Handle
        MOV     AH,3FH
        INT     21H
        CMP     AX,1CH
        JNE     LPF_EXE_SIZE_ERR
        MOV     DI,DX
        CMP     AL,3
        JE      LPF_ONLY_LOAD
        ;AX is free to use.
        ;BX=File Handle
        ;CX is free to use.
        ;DX is free to use.
        ;SI=M AX
        ;DS:DI=Pointer to EXE header in the memory.
        ;Get load module size in BX:AX.
        PUSH    BX
        CALL    INCALL_CALC_LOAD_SIZE
        ;BX:AX=Load module size in bytes
        PUSH    AX
        MOV     DX,BX
        ;DX:AX=Load module size in bytes
        MOV     CX,0400H
DIV_SIZE_BY_16:
        SHR     DX,1
        RCR     AX,1
        RCR     CL,1
        DEC     CH
        JNZ     DIV_SIZE_BY_16
        OR      CL,CL
        JZ      MEM_SIZE_OK
        ;Round up.
        ADD     AX,1
        ADC     DX,0
MEM_SIZE_OK:
        ADD     AX,[DI+0AH]
        ADC     DX,0
        MOV     CX,AX
        POP     AX
        OR      DX,DX
        JZ      PARA_SIZE_OK
        ;Error in mem. paragraph count
        MOV     AX,ERR_IFORMAT
        JMP     LPF_EXE_ERR_DONE
PARA_SIZE_OK:
        XCHG    BX,CX
        MOV     DX,AX
        ADD     BX,16   ;16 paragraphs for PSP
        MOV     AH,48H
        INT     21H
        JNC     ALLOCATION_OK
        JMP     LPF_EXE_ERR_DONE
ALLOCATION_OK:
        ;AX=PSP Segment
        ;CX:DX=Load module size in bytes
        ;DS:DI=Pointer to LPF_BUFFER(EXE Header)
        ADD     AX,16
        PUSH    AX
        ADD     AX,[DI+16H]
        MOV     CS:WORD PTR EXEC_JUMP_ADDR[2],AX
        MOV     AX,[DI+14H]
        MOV     CS:WORD PTR EXEC_JUMP_ADDR[0],AX
        MOV     CS:BYTE PTR EXE_FILE_FLAG,1
        POP     AX
        PUSH    AX
        ADD     AX,[DI+0EH]
        MOV     CS:WORD PTR EXE_STACK_ADDR[2],AX
        MOV     AX,[DI+10H]
        MOV     CS:WORD PTR EXE_STACK_ADDR[0],AX
        POP     AX
        POP     BX
        XCHG    CX,DX
        CALL    INCALL_LOAD_EXE
        MOV     CX,AX
        CALL    PERFORM_RELOCATION
        SUB     AX,16
        ;AX=PSP Segment
        ;BX=File Handle
        ;CX and DX are free to use.
        ;SI=Main AX
        ;DS:DI=Pointer to LPF_BUFFER
        ;STACK: M BX,M DS,M DX
        MOV     CX,AX
        MOV     AH,3EH  ;Close the file.
        INT     21H
        MOV     AX,CX
        POP     DX
        POP     DS
        POP     BX
        CLC
        JMP     Short LPF_DONE
        ;-----------------------------------
LPF_ONLY_LOAD:
        ;AX,CX and DX are free to use.
        ;BX=File Handle
        ;SI=M AX
        ;DS:DI=Pointer to LPF_BUFFER(EXE Header)
        ;STACK: M BX,M DS,M DX
        ;Get load module size in BX:AX.
        PUSH    BP
        PUSH    BX
        CALL    INCALL_CALC_LOAD_SIZE
        MOV     DX,BX
        MOV     CX,AX
        MOV     BP,SP
        MOV     BX,[BP+10]
        MOV     AX,ES:[BX]
        POP     BX
        CALL    INCALL_LOAD_EXE
        PUSH    BX
        MOV     BX,[BP+10]
        MOV     CX,ES:[BX+2]
        POP     BX
        POP     BP
        CALL    PERFORM_RELOCATION
        ;AX,CX and DX are free to use.
        ;BX=File Handle
        ;SI=M AX
        ;DS:DI=Pointer to LPF_BUFFER
        ;STACK: M BX,M DS,M DX
        POP     DX
        POP     DS
        MOV     AH,3EH
        INT     21H
        POP     BX
        MOV     AX,SI
        CLC
        JMP     Short LPF_DONE
        ;-----------------------------------
LPF_EXE_ERR_DONE:
        POP     BX
        POP     DX
        POP     DS
        PUSH    AX
        MOV     AH,3EH
        INT     21H
        POP     AX
        POP     BX
        STC
        JMP     Short LPF_DONE
        ;-----------------------------------
LPF_F_ERROR:
        ;AX=Error Code
        ;Carry flag is set.
        JMP     Short LPF_DONE
LPF_F_ERROR_2:
        MOV     AH,3EH
        ;BX=File Handle
        INT     21H
        MOV     AX,ERR_IFORMAT
        ;AX=Error Code
        POP     BX
        STC
        JMP     Short LPF_DONE
LPF_EXE_SIZE_ERR:
        POP     DX
        POP     DS
LPF_SIZE_ERR:
        MOV     AH,3EH
        ;BX=File Handle
        INT     21H
        MOV     AX,ERR_IFORMAT
        ;AX=Error Code
        POP     BX
        MOV     DX,DI
        ;Carry Flag is set.
        JMP     Short LPF_DONE
LPF_BADFNERR:
        MOV     AX,ERR_IFNUMBER
        ;AX=Error Code
        STC
        JMP     Short LPF_RETURN
LPF_MEM_ERR:
        ;AX=Error Code
        POP     BX
        MOV     DX,DI
        ;Carry Flag is set.
LPF_DONE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     CX,LPF_WORD_1
        MOV     SI,LPF_WORD_2
        MOV     DI,LPF_WORD_3
        POP     DS
LPF_RETURN:
        RET
LOAD_PROG_FILE  ENDP

;***********************************************************************

CREATE_PSP_STAGE_1      PROC
        PUSH    AX
        PUSH    ES
        PUSH    DI
        MOV     AX,DS
        MOV     ES,AX
        XOR     AX,AX
        MOV     DS,AX
        XOR     DI,DI
        ;Fill field no. 1.
        MOV     AX,20CDH
        CLD
        STOSW
        INC     DI
        INC     DI
        ;Fill fields no. 3 and 4.
        MOV     AX,9AFFH
        STOSW
        ;Fill next two words with address of INT 21H dispatcher.
        LEA    AX,INT21H_DISPATCHER
        STOSW
        MOV     AX,CS
        ;LEA     AX,...
        STOSW
        ;Fill field no. 5.
        MOV     AX,DS:WORD PTR[0088H]
        STOSW
        MOV     AX,DS:WORD PTR[008AH]
        STOSW
        ;Fill field no. 6.
        MOV     AX,DS:WORD PTR[008CH]
        STOSW
        MOV     AX,DS:WORD PTR[008EH]
        STOSW
        ;Fill field no. 7.
        MOV     AX,DS:WORD PTR[0090H]
        STOSW
        MOV     AX,DS:WORD PTR[0092H]
        STOSW
        ;Fill field no. 8.
        INC     DI      ;First word is used to hold parent PSP segment address.
        INC     DI

        MOV     AX,DS:WORD PTR[0088H]
        STOSW
        MOV     AX,DS:WORD PTR[008AH]
        STOSW

        MOV     AX,0FF02H
        STOSW
        MOV     AL,0FFH
        STOSW
        STOSW
        STOSW
        STOSW
        STOSW
        STOSW
        STOSW
        ;Fill field no. 10.
        INC     DI
        INC     DI
        MOV     AX,0FFFFH
        STOSW
        STOSW
        MOV     AX,0014H
        STOSW
        MOV     AL,18H
        STOSW
        MOV     AX,ES
        ;ES=PSP Segment
        STOSW
        MOV     AX,0FFFFH
        STOSW
        STOSW
        MOV     AX,0A07H
        STOSW
        MOV     AX,21CDH
        STOSW
        MOV     AX,00CBH
        STOSW
        XOR     AL,AL
        ;AX=0000H
        MOV     DS,CX
        MOV     CX,13
   REP  STOSW
        MOV  CX,DS
        ;Create_PSP_Stage_1 is done here.
        PUSH    ES
        POP     DS
        POP     DI
        POP     ES
        POP     AX
        RET
CREATE_PSP_STAGE_1      ENDP

;***********************************************************************

CREATE_PSP      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 26H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DS
        PUSH    ES
        PUSH    SI
        PUSH    DI
        MOV     SI,SP
        MOV     DS,CS:CURRENT_PSP
        MOV     ES,DX
        XOR     SI,SI
        XOR     DI,DI
        MOV     DX,CX
        MOV     CX,128
        CLD
   REP  MOVSW
        MOV     CX,DX
        MOV     DX,ES
        MOV     DS,DX
        CALL    CREATE_PSP_STAGE_1

        mov     si,ds:word ptr[16h]
        mov     es:word ptr[16h],si

        POP     DI
        POP     SI
        POP     ES
        POP     DS
        RET
CREATE_PSP      ENDP

;***********************************************************************

INSERT_EXEC_PATH        PROC
        PUSH    AX
        PUSH    DX
        PUSH    DI
        PUSH    ES
        PUSH    DS
        MOV     ES,SI
        ;-----------------------------------
        MOV     DS,SI
        XOR     SI,SI
        CLD
FIND_ENV_END:
        LODSB
        CMP     AL,00H
        JZ      ENV_END_DONE
FIND_STR_END:
        LODSB
        CMP     AL,00H
        JNE     FIND_STR_END
        JMP     Short FIND_ENV_END
ENV_END_DONE:
        MOV     DI,SI
        MOV     AX,1
        STOSW
        LDS     DX,CS:DWORD PTR EXEC_PATH_ADDR
        MOV     AX,1D01H        ;CALL   PREPARE_FILE_PATH from MiniIO.SYS
        INT     21H
        MOV     SI,DX
        CLD
INSERT_PATH:
        LODSB
        STOSB
        CMP     AL,00H
        JNE     INSERT_PATH
        MOV     AX,1D02H        ;CALL   RESTORE_FILE_PATH from MiniIO.SYS
        INT     21H
        MOV     AL,00H
        STOSB
        ;-----------------------------------
        MOV     SI,ES
        POP     DS
        POP     ES
        POP     DI
        POP     DX
        POP     AX
        RET
INSERT_EXEC_PATH        ENDP

;***********************************************************************

INCALL_EXEC     PROC

        cmp     cs:exec_func_no,4b01h
        je      terminate_addr_done

        MOV     SI,CS:WORD PTR TERMINATE_ADDR[0]
        MOV     DS:[88H],SI
        MOV     SI,CS:WORD PTR TERMINATE_ADDR[2]
        MOV     DS:[8AH],SI

terminate_addr_done:

        MOV     DS,AX
        CALL    CREATE_PSP_STAGE_1
        MOV     SI,ES:[BX+2]
        MOV     DS,ES:[BX+4]
        PUSH    ES
        MOV     ES,AX
        MOV     DI,80H
        MOV     CX,64
        CLD
  REP   MOVSW
        POP     ES
        MOV     SI,ES:[BX+6]
        MOV     DS,ES:[BX+8]
        PUSH    ES
        MOV     ES,AX
        MOV     DI,5CH
        MOV     CX,8
  REP   MOVSW
        POP     ES
        MOV     SI,ES:[BX+0AH]
        MOV     DS,ES:[BX+0CH]
        PUSH    ES
        MOV     ES,AX
        MOV     DI,6CH
        MOV     CX,10
  REP   MOVSW
        POP     ES
        MOV     SI,ES:[BX]
        OR      SI,SI
        JNZ     SET_ENV_SEG
        ;Inherit current environment.
        MOV     DS,CS:CURRENT_PSP
        MOV     SI,DS:WORD PTR[2CH]
SET_ENV_SEG:
        MOV     DS,AX
        MOV     DS:[2CH],SI
        MOV     SI,CS:CURRENT_PSP
        OR      SI,SI
        JNZ     STORE_PARENT_PSP
        MOV     SI,AX
STORE_PARENT_PSP:
        MOV     DS:[16H],SI
        MOV     DS:[36H],AX
        RET
INCALL_EXEC     ENDP

;***********************************************************************
EXEC_PATH_ADDR          DD      ?

EXEC    PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 4BH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        MOV     CS:EXEC_FUNC_NO,AX
        CMP     AL,05H          ;Subfunc. 05H: Set EXECSTATE ,if AL=05H carry flag is cleared as a result of comparison.
        JE      EXEC_RETURN
        CMP     AL,1
        JNE     EXEC_LOAD
        MOV     AL,0
EXEC_LOAD:
        CALL    LOAD_PROG_FILE
        JC      EXEC_RETURN
        CMP     AL,3
        JE      EXEC_RETURN
        ;-----------------------------------
        MOV     CS:WORD PTR EXEC_PATH_ADDR[0],DX
        MOV     CS:WORD PTR EXEC_PATH_ADDR[2],DS
        POP     CS:WORD PTR TERMINATE_ADDR[0]           ;Return IP
        POP     CS:WORD PTR TERMINATE_ADDR[2]           ;Return CS
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    BP
        PUSH    ES
        PUSH    BX
        MOV     CS:WORD PTR EXEC_OLD_STACK_ADDR[0],SP
        MOV     CS:WORD PTR EXEC_OLD_STACK_ADDR[2],SS
        ;-----------------------------------
        CMP     CS:BYTE PTR EXE_FILE_FLAG,1
        JE      EXEC_EXE_FILE
        ;So,this is a .COM file.
        ;AL=0
        ;Load and execute function
        ;Create PSP.
        ;Set DTA address.
        ;Set register values for a .COM file.
        ;Jump to first instruction.
        ;AX=PSP Segment
        MOV     DS,AX
        XCHG    AX,BX
        CALL    SET_MB_OWNER
        XCHG    AX,BX
        XOR     SI,SI
        MOV     DS,SI
        CALL    INCALL_EXEC
        ;DS=PSP Segment
        MOV     SI,DS:WORD PTR[2CH]
        CALL    INSERT_EXEC_PATH
        MOV     ES,AX
        MOV     BX,0FFFFH
        CALL    RESIZE_MEMORY_BLOCK
        CALL    RESIZE_MEMORY_BLOCK
        MOV     AX,ES
        ADD     AX,BX
        MOV     DS:[02H],AX
        MOV     AX,16
        MUL     BX
        OR      DX,DX
        JNZ     FULL_SEG
        MOV     DS:[06H],AX
        JMP     Short MEM_AVAIL_DONE
FULL_SEG:
        MOV     DS:WORD PTR[06H],0FFFFH
MEM_AVAIL_DONE:
        ;Set DTA address.
        MOV     DX,80H
        MOV     AH,1AH
        INT     21H
        MOV     AX,DS
        MOV     CS:CURRENT_PSP,AX
        ;Set register values for a .COM file.
        MOV     ES,AX
        CLI
        MOV     SS,AX
        MOV     SP,DS:WORD PTR[06H]
        STI
        XOR     AX,AX
        PUSH    AX
        JMP     Short EXECUTE_PROGRAM
EXEC_EXE_FILE:
        ;So,this is a .EXE file.
        ;AL=0
        ;Load and execute function
        ;Create PSP
        ;Set DTA address.
        ;Set register values for a .EXE file.
        ;Jump to first instruction.
        ;AX=PSP Segaament
        XOR     SI,SI
        MOV     DS,SI
        CALL    INCALL_EXEC
        ;DS=PSP Segment
        MOV     SI,DS:WORD PTR[2CH]
        CALL    INSERT_EXEC_PATH
        MOV     ES,AX
        MOV     BX,0FFFFH
        CALL    RESIZE_MEMORY_BLOCK
        CALL    RESIZE_MEMORY_BLOCK
        MOV     AX,ES
        ADD     AX,BX
        MOV     DS:[02H],AX
        ;Set DTA address.
        ;DS=PSP Segment
        MOV     DX,80H
        MOV     AH,1AH
        INT     21H
        MOV     AX,DS
        MOV     CS:CURRENT_PSP,AX
        ;Set register values for a .EXE file.
        ;DS=PSP
        MOV     ES,AX
        CLI
        MOV     SS,CS:WORD PTR EXE_STACK_ADDR[2]
        MOV     SP,CS:WORD PTR EXE_STACK_ADDR[0]
        STI
        XOR     AX,AX
EXECUTE_PROGRAM:
        MOV     CX,00FFH
        XOR     BX,BX           ;BX=0000H
        ;-----------------------------------
        CMP     CS:BYTE PTR EXEC_FUNC_NO[0],01H
        JE      EXEC_DONT_EXECUTE
        CMP     CS:LOADING_STAGE,0
        JE      EXEC_JUMP
        MOV     CS:LOADING_STAGE,0
        CALL    CLEAR_SCREEN
EXEC_JUMP:
        DEC_INDOS
        JMP     CS:EXEC_JUMP_ADDR
        ;-----------------------------------
EXEC_DONT_EXECUTE:
        MOV     CS:WORD PTR EXE_STACK_ADDR[0],SP
        MOV     CS:WORD PTR EXE_STACK_ADDR[2],SS
        CLI
        MOV     SP,CS:WORD PTR EXEC_OLD_STACK_ADDR[0]
        MOV     SS,CS:WORD PTR EXEC_OLD_STACK_ADDR[2]
        STI
        POP     DI
        POP     ES
        PUSH    DI
        ADD     DI,0EH
        PUSH    CS
        POP     DS
        LEA     SI,EXE_STACK_ADDR
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        POP     BX
        POP     BP
        POP     DS
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        MOV     AX,CS:EXEC_FUNC_NO
        CLC
        DEC_INDOS
        JMP     CS:DWORD PTR TERMINATE_ADDR
        ;-----------------------------------
EXEC_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        DEC_INDOS
        RET
EXEC    ENDP

;***********************************************************************

DO_TERMINATION  PROC
        PUSH    AX
        PUSH    DS
        PUSH    ES
        PUSH    SI
        PUSH    DI
        MOV     SI,BX
        OR      AL,AL
        JNZ     MEM_DONE
        MOV     AX,DS
        MOV     ES,AX
        MOV     AH,49H
        CALL    FREE_MEMORY_BLOCK
        ;Free other MBs associated with this PSP
        MOV     BX,DS
        XOR     AX,AX
FREE_MEM_BLOCKS:
        CALL    FIND_MB_WITH_OWNER
        JC      MEM_DONE
        CALL    FREE_MEMORY_BLOCK
        INC     AX
        JMP     Short FREE_MEM_BLOCKS
MEM_DONE:
CLOSE_PROCESS_FILES:
        MOV     BX,DS
        MOV     AX,1D00H
        INT     21H
        JC      FILES_DONE
        MOV     AH,3EH
        INT     21H
        JNC     CLOSE_PROCESS_FILES
FILES_DONE:
        MOV     BX,SI
        ;MOV     DS,DS:WORD PTR[16H]
        MOV     SI,0AH
        XOR     AX,AX
        MOV     ES,AX
        MOV     DI,0088H
        CLD
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        POP     DI
        POP     SI
        POP     ES
        POP     DS
        POP     AX
        MOV     CS:CTRL_BREAK_STATUS,0
        RET
DO_TERMINATION  ENDP

;***********************************************************************

GET_RETURN_CODE PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 4DH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     AL,CS:LAST_RETURN_CODE
        MOV     AH,CS:LAST_RETURN_STATUS
        RET
GET_RETURN_CODE ENDP

;***********************************************************************

SERVICE_00H:
;-----------------------------------------------------------------------;
; <INT 21H Service 00H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        POP     AX
        POP     AX
        PUSHF
        PUSH    AX
        PUSH    AX
INT_20H_HANDLER:
;-----------------------------------------------------------------------;
; <INT 20H Handler> | <API Interrupt>                                   ;
;-----------------------------------------------------------------------;
        POP     DS
        POP     DS
        POPF
        ;DS=PSP Segment
        MOV     AX,DS:[16H]
        PUSH    AX
        MOV     CS:LAST_RETURN_CODE,00H
        MOV     CS:LAST_RETURN_STATUS,00H
        XOR     AX,AX
        MOV     ES,AX
        MOV     AX,ES:[0088H]
        MOV     CS:WORD PTR TERMINATE_ADDR[0],AX
        MOV     AX,ES:[008AH]
        MOV     CS:WORD PTR TERMINATE_ADDR[2],AX
        XOR     AL,AL
        CALL    DO_TERMINATION
        POP     CS:CURRENT_PSP
        CLC
        JMP     CS:TERMINATE_ADDR

;***********************************************************************

TERMINATE       PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 4CH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     CS:LAST_RETURN_STATUS,00H
        JMP     Short RETURN_STATUS_DONE
CTRL_BREAK_TERMINATION  LABEL   FAR
        MOV     CS:LAST_RETURN_STATUS,01H
RETURN_STATUS_DONE:
        INC_INDOS
        POP     DS
        POP     DS
        MOV     DS,CS:CURRENT_PSP
        MOV     CS:LAST_RETURN_CODE,AL
        MOV     AX,DS:[16H]
        PUSH    AX
        XOR     AX,AX
        MOV     ES,AX

        MOV     AX,DS:WORD PTR[18H]
        MOV     CS:WORD PTR TERMINATE_ADDR[0],AX
        MOV     AX,DS:WORD PTR[1AH]
        MOV     CS:WORD PTR TERMINATE_ADDR[2],AX

COMMENT +        MOV     AX,ES:[0088H]
        MOV     CS:WORD PTR TERMINATE_ADDR[0],AX
        MOV     AX,ES:[008AH]
        MOV     CS:WORD PTR TERMINATE_ADDR[2],AX+

        XOR     AL,AL
        CALL    DO_TERMINATION
        POP     CS:CURRENT_PSP
        CLC
        DEC_INDOS
        JMP     CS:TERMINATE_ADDR
TERMINATE       ENDP

;***********************************************************************

INT_27H_HANDLER:
;-----------------------------------------------------------------------;
; <INT 27H Handler> | <API Interrupt>                                   ;
;-----------------------------------------------------------------------;
        MOV     AX,DX
        XOR     DX,DX
        MOV     BX,16
        DIV     BX
        OR      DX,DX
        JZ      TSR_SIZE_OK
        ;Round up.
        INC     AX
TSR_SIZE_OK:
        MOV     DX,AX
        XOR     AX,AX
        ;Continue with TSR_SERVICE

TSR_SERVICE     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 31H> | <API Service>                                 ;
;-----------------------------------------------------------------------;

        INC_INDOS
        MOV     ES,CS:CURRENT_PSP
        MOV     BX,DX
        CALL    RESIZE_MEMORY_BLOCK
        MOV     CS:LAST_RETURN_STATUS,03H
        MOV     DS,CS:CURRENT_PSP
        MOV     AX,DS:[16H]
        PUSH    AX
        MOV     CS:LAST_RETURN_CODE,AL
        XOR     AX,AX
        MOV     ES,AX
        MOV     AX,ES:[0088H]
        MOV     CS:WORD PTR TERMINATE_ADDR[0],AX
        MOV     AX,ES:[008AH]
        MOV     CS:WORD PTR TERMINATE_ADDR[2],AX
        MOV     AL,1
        CALL    DO_TERMINATION
        POP     CS:CURRENT_PSP
        CLC
        DEC_INDOS
       JMP     CS:TERMINATE_ADDR
TSR_SERVICE     ENDP

;***********************************************************************

GET_CURRENT_PSP PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 51H> | <API Service>                                 ;
; <INT 21H Service 62H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        MOV     BX,CS:CURRENT_PSP
        DEC_INDOS
        RET
GET_CURRENT_PSP ENDP

;***********************************************************************

SET_CURRENT_PSP PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 50H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        MOV     CS:CURRENT_PSP,BX
        DEC_INDOS
        RET
SET_CURRENT_PSP ENDP

;***********************************************************************




;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================

;MINITAK.SYS
        MINITAK_DISP_JUMP               DD              ?
        NEXT_INT21H_DISPATCHER          DD              ?
        IO_TABLE21H_OFF                 DW              ?
        IO_TABLE21H_SEG                 DW              ?

        INT21H_TABLE            LABEL           BYTE
        ;INT 21H Service No.
        ;FAR pointer of routine
        ;DB     ServiceNo
        ;DD     SEGMENT:OFFSET

        DB      00H
                        DD      OFFSET SERVICE_00H
        DB      01H
                        DD      OFFSET READ_KEY_WEB
        DB      02H
                        DD      OFFSET WRITE_CHAR_B
        DB      03H
                        DD      OFFSET READ_STDAUX
        DB      04H
                        DD      OFFSET WRITE_STDAUX
        DB      05H
                        DD      OFFSET WRITE_STDPRN
        DB      06H
                        DD      OFFSET READ_WRITE_KEY
        DB      07H
                        DD      OFFSET READ_KEY_W
        DB      08H
                        DD      OFFSET READ_KEY_WB
        DB      09H
                        DD      OFFSET WRITE_STRING
        DB      0AH
                        DD      OFFSET READ_STRING_BUF
        DB      0BH
                        DD      OFFSET CHECK_KBD_BUF
        DB      0CH
                        DD      OFFSET RESET_KBD_BUF
        DB      18H
                        DD      OFFSET UNKNOWN_SRVC_18H_1EH_20H_61H
        DB      1EH
                        DD      OFFSET UNKNOWN_SRVC_18H_1EH_20H_61H
        DB      20H
                        DD      OFFSET UNKNOWN_SRVC_18H_1EH_20H_61H
        DB      25H
                        DD      OFFSET SET_INT_VECTOR
        DB      26H
                        DD      OFFSET CREATE_PSP
        DB      2AH
                        DD      OFFSET GET_DATE
        DB      2BH
                        DD      OFFSET SET_DATE
        DB      2CH
                        DD      OFFSET GET_TIME
        DB      2DH
                        DD      OFFSET SET_TIME
        DB      30H
                        DD      OFFSET GET_DOS_VERSION
        DB      31H
                        DD      OFFSET TSR_SERVICE
        DB      33H
                        DD      OFFSET SRVC_HANDLER_33H
        DB      34H
                        DD      OFFSET GET_INDOS_FLAG_ADDR
        DB      35H
                        DD      OFFSET GET_INT_VECTOR
        DB      37H
                        DD      OFFSET SRVC_HANDLER_37H
        DB      38H
                        DD      OFFSET SS_38H
        DB      48H
                        DD      OFFSET ALLOCATE_MEMORY
        DB      49H
                        DD      OFFSET FREE_MEMORY_BLOCK
        DB      4AH
                        DD      OFFSET RESIZE_MEMORY_BLOCK
        DB      4BH
                        DD      OFFSET EXEC
        DB      4CH
                        DD      OFFSET TERMINATE
        DB      4DH
                        DD      OFFSET GET_RETURN_CODE
        DB      50H
                        DD      OFFSET SET_CURRENT_PSP
        DB      51H
                        DD      OFFSET GET_CURRENT_PSP
        DB      58H
                        DD      OFFSET MEM_SERVICE_58H
        DB      59H
                        DD      OFFSET GET_EXT_ERROR_CODE
        DB      5DH
                        DD      OFFSET SRVC_HANDLER_5DH
        DB      61H
                        DD      OFFSET UNKNOWN_SRVC_18H_1EH_20H_61H
        DB      62H
                        DD      OFFSET GET_CURRENT_PSP
        DB      65H
                        DD      OFFSET SS_65H
        DB      66H
                        DD      OFFSET SS_66H
        ;-----------------------------------
        DB      0FFH            ;END OF TABLE


ENTRY_SP                DW              ?

INT_21H_HANDLER:
;-----------------------------------------------------------------------;
; <INT 21H Handler> | <INT 21H Service Dispatcher>                      ;
;-----------------------------------------------------------------------;
        ;STACK: Flags,Return CS,Return IP
        PUSH    BP
        PUSH    AX
        MOV     BP,SP
        ;STACK: Flags,Return CS,Return IP,Main BP,Main AX
        PUSH    BX
        MOV     BX,[BP+8]
        MOV     AX,[BP+6]
        MOV     [BP+8],AX
        MOV     AX,[BP+4]
        MOV     [BP+6],AX
        MOV     [BP+4],BX
        POP     BX
        POP     AX
        POP     BP
        POPF
        ;STACK: Return CS,Return IP
        ;-----------------------------------
INT21H_DISPATCHER:
        ;STACK: Return CS,Return IP
        PUSHF
        STC
        CALL    CHECK_CTRL_BREAK
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,INT21H_TABLE
SEARCH_SERVICE:
        CMP     BYTE PTR[SI],0FFH
        JE      NOT_AVAIL
        CMP     BYTE PTR[SI],AH
        JE      FOUND_SERVICE
        ADD     SI,5
        JMP     Short SEARCH_SERVICE
FOUND_SERVICE:
        PUSH    AX
        MOV     AX,[SI+1]
        MOV     WORD PTR MINITAK_DISP_JUMP[0],AX
        MOV     AX,[SI+3]
        MOV     WORD PTR MINITAK_DISP_JUMP[2],AX
        POP     AX
        POP     SI
        POP     DS
        POPF
        JMP     CS:MINITAK_DISP_JUMP
NOT_AVAIL:
        POP     SI
        POP     DS
        INC_INDOS
        POPF
        MOV     CS:ENTRY_SP,SP                  ;ENTRY_SP is mainly used for direct return from a critical error handler to the calling program.
        CALL    CS:DWORD PTR NEXT_INT21H_DISPATCHER
        MOV     SP,CS:ENTRY_SP
        DEC_INDOS
        RETF

;*******************************************

INT_23H_HANDLER:
;-----------------------------------------------------------------------;
; <INT 23H (Ctrl-Break Exit) Handler> | <Default INT 23H Handler>       ;
;-----------------------------------------------------------------------;
        PUSH    AX
        MOV     AH,0DH          ;Flush all disk buffers to disk
        INT     21H
        POP     AX
        STC
        RETF

;*******************************************

;This PROC is used for the following interrupt vectors:
;       28H,2AH,2BH,2CH,2DH,2EH,2FH,33H,34H through 3EH,3FH
IRET_INTERRUPT_HANDLER  PROC
        IRET
IRET_INTERRUPT_HANDLER  ENDP


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++SERVICE SUPPORT+++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;

COUNTRY_INFO_BLOCK              LABEL           BYTE
        DW              0                       ;Date Format: USA
        DB              '$',00H,3 DUP(00H)      ;Currency Symbol(ASCIIZ string)
        DB              ','                     ;Thousand Separator
        DB              00H
        DB              '.'                     ;Decimal Separator
        DB              00H
        DB              '-'                     ;Date Separator
        DB              00H
        DB              ':'                     ;Time Separator
        DB              00H
        DB              0                       ;Currency Format: "$123.00"
        DB              2                       ;Precision(Number Of Significant Decimal Digits In Currency Notation)
        DB              1                       ;Time Format: 24-Hour Clock
CAP_CONV_OFF    DW              OFFSET CAP_CONVERTOR    ;Capital Convertor
CAP_CONV_SEG    DW      ?
        DB              ','                     ;Dta List Separator
        DB              00H
        DB              8 DUP(00H)              ;(Reserved)

CAP_CONVERTOR   PROC    FAR
        CMP     AL,'a'
        JB      CAP_CONV_RETURN
        CMP     AL,'z'
        JA      CAP_CONV_RETURN
        SUB     AL,'a'-'A'
CAP_CONV_RETURN:
        RET
CAP_CONVERTOR   ENDP

SS_38H  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 38H> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;38H: Get/Set Country-dependant Info
        CMP     DX,0FFFFH
        JE      SS_38_SUCCESS
        ;DX<0FFFFH: Get Country-dependant Info
        ;DS:DX=Buffer address
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        PUSH    DI
        PUSH    CX
        LEA     SI,COUNTRY_INFO_BLOCK
        MOV     DI,DX
        MOV     CX,16
  REP   MOVSW
        POP     CX
        POP     DI
        POP     SI
        POP     DS
        POP     ES
        MOV     BX,1            ;BX=Country Code(1=USA)
SS_38_SUCCESS:
        CLC
        RET
SS_38H  ENDP

;*******************************************

SS_66H  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 66H> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;66H: Get/Set Code Page
        CMP     AL,2            ;AL=02H: Set Code Page
        JE      SS_66H_SUCCESS
        CMP     AL,1
        JNE     SS_66H_INV_FUNCTION
        ;AL=01H: Get Code Page
        MOV     BX,437          ;BX=Active Code Page
        MOV     DX,437          ;DX=System Code Page(As In Boot Time)
        JMP     Short SS_66H_SUCCESS
SS_66H_INV_FUNCTION:
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short SS_66H_RETURN
SS_66H_SUCCESS:
        CLC
SS_66H_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
SS_66H  ENDP

;*******************************************

SS_65H  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 65H> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;65H: Get Extended Country Information
        MOV     AX,ERR_IFORMAT  ;Error: Invalid Format
        STC
        CALL    UPDATE_EXT_ERROR_INF
        RET
SS_65H  ENDP

;*******************************************

UNKNOWN_SRVC_18H_1EH_20H_61H    PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Unknown (or Unused) Services: 18H,1EH,20H,61H>               ;
;-----------------------------------------------------------------------;
        MOV     AL,00H
        RET
UNKNOWN_SRVC_18H_1EH_20H_61H    ENDP

;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================
;INT 32H

INT32H_TABLE            LABEL           BYTE
        ;INT 32H Service No.
        ;FAR pointer of routine
        ;DB     SERVICENO
        ;DD     SEGMENT:OFFSET

        DB      01H
                        DD      OFFSET GET_MINITAK_INFO
        DB      02H
                        DD      OFFSET WRITE_ASCIIZ
        DB      03H
                        DD      OFFSET WRITE_UNTIL_SPEC_CHAR
        DB      04H
                        DD      OFFSET MOVE_CURSOR
        DB      05H
                        DD      OFFSET GET_MEM_INF
        DB      06H
                        DD      OFFSET MINITAK_INTERFACE
        DB      07H
                        DD      OFFSET SET_SERVICE_VECTOR
        DB      08H
                        DD      OFFSET GET_SERVICE_VECTOR
        DB      09H
                        DD      OFFSET WAIT_SERVICE
        DB      0AH
                        DD      OFFSET SPEAKER
        DB      0BH
                        DD      OFFSET SET_DOS_VERSION
        DB      0DH
                        DD      OFFSET GET_AUTHOR_NAME
        DB      33H
                        DD      OFFSET INT_32H_SRVC_HDLR_33H
        ;-----------------------------------
        DB      0FFH            ;END OF TABLE

;=======================================================================
INT_32H_HANDLER:
;-----------------------------------------------------------------------;
; <INT 32H Handler> | <INT 32H Service Dispatcher>                      ;
;-----------------------------------------------------------------------;
        ;Just like INT_21H_HANDLER:
        ;STACK: Flags,Return CS,Return IP
        PUSH    BP
        PUSH    AX
        MOV     BP,SP
        ;STACK: Flags,Return CS,Return IP,Main BP,Main AX
        PUSH    BX
        MOV     BX,[BP+8]
        MOV     AX,[BP+6]
        MOV     [BP+8],AX
        MOV     AX,[BP+4]
        MOV     [BP+6],AX
        MOV     [BP+4],BX
        POP     BX
        POP     AX
        POP     BP
        POPF
        ;STACK: Return CS,Return IP
        ;-----------------------------------
INT_32H_DISPATCHER:
        ;Just like INT21H_DISPATCHER,but
        ;INT21H_TABLE     -> INT32H_TABLE
        ;STACK: Return CS,Return IP
        PUSHF
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,INT32H_TABLE
INT32H_SEARCH_SERVICE:
        CMP     BYTE PTR[SI],0FFH
        JE      INVALID_SERVICE
        CMP     BYTE PTR[SI],AH
        JE      INT32H_FOUND_SERVICE
        ADD     SI,5
        JMP     Short INT32H_SEARCH_SERVICE
INT32H_FOUND_SERVICE:
        PUSH    AX
        MOV     AX,[SI+1]
        MOV     WORD PTR MINITAK_DISP_JUMP[0],AX
        MOV     AX,[SI+3]
        MOV     WORD PTR MINITAK_DISP_JUMP[2],AX
        POP     AX
        POP     SI
        POP     DS
        POPF
        JMP     CS:MINITAK_DISP_JUMP
INVALID_SERVICE:
        POP     SI
        POP     DS
        POPF
        MOV     AX,1    ;Error: Invalid function number
        STC
        RETF

;=======================================================================
;OTHER SERVICES

FIND_SERVICE_HANDLER    PROC
        PUSH    DX
        PUSH    DS
        PUSH    SI
        MOV     DL,3    ;Number of tables
        ;-----------------------------------
        ;FSH_INT_21H:
        CMP     AL,21H
        JNE     FSH_NEXT_TABLE
        MOV     SI,CS
        MOV     DS,SI
        LEA     SI,INT21H_TABLE
        JMP     Short FSH_SEARCH
FSH_CHECK_INT:
        CMP     DL,2
        JE      FSH_INT_2AH
        CMP     DL,1
        ;JE     FSH_INT_32H
        ;FSH_INT_32H:
        CMP     AL,32H
        JNE     FSH_NEXT_TABLE
        MOV     SI,CS
        MOV     DS,SI
        LEA     SI,INT32H_TABLE
        JMP     Short FSH_SEARCH
FSH_INT_2AH:
        CMP     AL,21H
        JNE     FSH_NEXT_TABLE
        MOV     DS,CS:IO_TABLE21H_SEG
        MOV     SI,CS:IO_TABLE21H_OFF
        ;JMP    Short FSH_SEARCH
FSH_SEARCH:
        CMP     BYTE PTR[SI],0FFH
        JE      FSH_NEXT_TABLE
        CMP     BYTE PTR[SI],CL
        JE      FSH_FOUND
        ADD     SI,5
        JMP     Short FSH_SEARCH
FSH_FOUND:
        INC     SI
        ADD     SP,4
        CLC
        JMP     Short FSH_DONE
FSH_NEXT_TABLE:
        DEC     DL
        JNZ     FSH_CHECK_INT
        POP     SI
        POP     DS
        STC
FSH_DONE:
        POP     DX
        RET
FIND_SERVICE_HANDLER    ENDP

;***********************************************************************

GET_SERVICE_VECTOR      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 08H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        PUSH    DS
        PUSH    SI
        CALL    FIND_SERVICE_HANDLER
        JC      GSV_INV_SRVC
        MOV     BX,[SI]
        MOV     ES,[SI+2]
        ;Carry Flag is cleared.
        JMP     Short GSV_DONE
GSV_INV_SRVC:
        ;Carry Flag is set.
GSV_DONE:
        POP     SI
        POP     DS
        DEC_INDOS
        RET
GET_SERVICE_VECTOR      ENDP

;***********************************************************************

SET_SERVICE_VECTOR      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 32H Service 07H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        INC_INDOS
        PUSH    BX
        PUSH    DI
        MOV     DI,DS
        MOV     BX,DX
        CALL    FIND_SERVICE_HANDLER
        JC      SSV_INV_SRVC
        MOV     [SI],BX
        MOV     [SI+2],DI
        ;Carry Flag is cleared.
        JMP     Short SSV_DONE
SSV_INV_SRVC:
        ;Carry Flag is set.
SSV_DONE:
        MOV     DS,DI
        MOV     DX,BX
        POP     DI
        POP     BX
        DEC_INDOS
        RET
SET_SERVICE_VECTOR      ENDP

;***********************************************************************

;Data defenitions for LOAD_MINIMAN
        LOADING_STAGE           DB      1       ;0=Normal stage
                                                ;1=Executing shell program

        MINIMAN_PATH            DB      'A:\MiniMan.COM',00H
        MINIMAN_CMD_LINE        DB      02H,'/P',0DH
        MINIMAN_FCB             DB      16 DUP(20H)
        MINIMAN_PATH_MSG        DB      0DH,0AH,'MINITAK command interpreter'
                                DB      ',"MINIMAN.COM",was not found.',0DH,0AH
                                DB      'Enter the path to a command'
                                DB      ' interpreter program: $'
        PATH_BUFFER             DB      65,66 DUP(00H)

        DEFAULT_ENV_SEG         LABEL           BYTE
                ;NOTE: UPDATE ENV_SEG_VARS_SIZE AFTER CHANGING DEFAULT_ENV_SEG
                DB              'PROMPT=$P$G',00H
                DB              'COMSPEC=A:\MINIMAN.COM',00H
                DB              'PATH=A:\',00H
                DB              'CMDLINE=',00H
                DB              00H

        ENV_SEG_VARS_SIZE       EQU             54
        ENV_SEG_SIZE            EQU             32      ;Number of paragraphs to reserve for environment

        MINIMAN_EPB             LABEL           BYTE
        ENV_SEG_ADDR            DW              ?
        CMD_LINE_ADDR           DD              OFFSET MINIMAN_CMD_LINE,0000H
        FCB_1_ADDR              DD              OFFSET MINIMAN_FCB,0000H
        FCB_2_ADDR              DD              OFFSET MINIMAN_FCB,0000H


CLEAR_SCREEN    PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        PUSH    DS
        MOV     AX,0040H        ;BIOS Data Area Segment
        MOV     DS,AX
        MOV     DL,DS:BYTE PTR[4AH]
        DEC     DL
        MOV     DH,DS:BYTE PTR[84H]
        POP     DS
        MOV     AX,0600H
        XOR     CX,CX
        MOV     BH,07H          ;Normal attribute
        INT     10H
        MOV     AH,0FH
        INT     10H
        MOV     AH,02H
        MOV     DX,0100H
        INT     10H

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CLEAR_SCREEN    ENDP

;-------------------------------------------

REST_OF_INITIALIZATION:
        LEA     AX,MINITAK_INITIALIZER
        INC     AX
        XOR     DX,DX
        MOV     BX,16
        DIV     BX
        INC     AX
        MOV     BX,CS
        ADD     AX,BX
        MOV     ENV_SEG_ADDR,AX
        MOV     DS,BX
        LEA     SI,DEFAULT_ENV_SEG
        MOV     ES,AX
        XOR     DI,DI
        MOV     CX,ENV_SEG_VARS_SIZE
        PUSH    CX
        CLD
  REP   MOVSB
        POP     CX
        MOV     BX,16*ENV_SEG_SIZE
        ADD     AX,ENV_SEG_SIZE
        SUB     BX,CX
        MOV     CX,BX
        MOV     FIRST_AVAIL_SEG,AX
        MOV     FIRST_MCB,0
        XOR     AL,AL
  REP   STOSB
        ;DS=CS
        MOV     AX,CS
        MOV     WORD PTR CMD_LINE_ADDR[2],AX
        MOV     WORD PTR FCB_1_ADDR[2],AX
        MOV     WORD PTR FCB_2_ADDR[2],AX
        ;-----------------------------------
        ;Set DOS Vars Rec First_MCB value
        ;DS=CS
        MOV     AH,52H
        INT     21H
        ;ES:BX => DOS Vars Rec
        MOV     AX,FIRST_MCB
        MOV     ES:WORD PTR[BX-2],AX

LOAD_MINIMAN:
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        MOV     LOADING_STAGE,1
        MOV     AX,4B00H
        LEA     DX,MINIMAN_PATH
        LEA     BX,MINIMAN_EPB
        INT     21H
        JC      LOAD_ERROR
        JMP     Short LOAD_MINIMAN
LOAD_ERROR:
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        LEA     DX,MINIMAN_PATH_MSG
        MOV     AH,09H
        INT     21H
        LEA     DX,PATH_BUFFER
        MOV     AH,0AH
        INT     21H
        MOV     BX,DX
        MOV     DL,[BX+1]
        XOR     DH,DH
        MOV     SI,DX
        MOV     BYTE PTR[BX+SI+2],00H
        MOV     DX,BX
        INC     DX
        INC     DX
        LEA     BX,MINIMAN_EPB
        MOV     AX,4B00H
        INT     21H
        MOV     CS:CURRENT_PSP,0
        JC      LOAD_ERROR
        JMP     LOAD_MINIMAN
        ;-----------------------------------

MINITAK_INITIALIZER:
        ;Register values from MINIIO.SYS:
        ;       ES:BX=Address of NEXT_INT21H_DISPATCHER
        ;       CX:DX=Address of MINIIO.SYS INT 21H Service Table
        ;SS and SP are set correctly.
        ;Set segment address of interrupt services.
        MOV     AX,CS
        MOV     DS,AX
        ;DS=CS
        ;AX=CS

        MOV     WORD PTR NEXT_INT21H_DISPATCHER[0],BX
        MOV     WORD PTR NEXT_INT21H_DISPATCHER[2],ES
        MOV     IO_TABLE21H_OFF,DX
        MOV     IO_TABLE21H_SEG,CX

        MOV     CAP_CONV_SEG,AX

        LEA     SI,INT21H_TABLE
SET_INT21H_SEG:
        CMP     BYTE PTR[SI],0FFH
        JE      INT21H_SEG_DONE
        MOV     WORD PTR[SI+3],AX
        ADD     SI,5
        JMP     Short SET_INT21H_SEG
INT21H_SEG_DONE:
        LEA     SI,INT32H_TABLE
        ;DS=CS
        ;AX=CS
SET_INT32H_SEG:
        CMP     BYTE PTR[SI],0FFH
        JE      INT32H_SEG_DONE
        MOV     WORD PTR[SI+3],AX
        ADD     SI,5
        JMP     Short SET_INT32H_SEG
INT32H_SEG_DONE:
        ;Set interrupt vectors for INT 20H,21H,23H,27H,28H,29H,1BH,2BH,2CH,2DH,2EH,2FH and 32H.
        PUSH    CS
        POP     DS

        MOV     AL,20H
        LEA     DX,INT_20H_HANDLER
        CALL    SET_INT_VECTOR

        MOV     AL,21H
        LEA     DX,INT_21H_HANDLER
        CALL    SET_INT_VECTOR

        MOV     AL,23H
        LEA     DX,INT_23H_HANDLER
        CALL    SET_INT_VECTOR

        MOV     AL,27H
        LEA     DX,INT_27H_HANDLER
        CALL    SET_INT_VECTOR

        MOV     AL,29H
        LEA     DX,INT_29H_HANDLER
        CALL    SET_INT_VECTOR

        LEA     DX,IRET_INTERRUPT_HANDLER
        MOV     AL,28H                          ;Interrupt 28H:IDLE INT
        CALL    SET_INT_VECTOR
        MOV     AL,2AH                          ;Interrupt 2AH:Microsoft Networks
        CALL    SET_INT_VECTOR
        MOV     AL,2BH                          ;Interrupt 2BH:Rserved(IRET)
        CALL    SET_INT_VECTOR
        MOV     AL,2CH                          ;Interrupt 2CH:Rserved(IRET)
        CALL    SET_INT_VECTOR
        MOV     AL,2DH                          ;Interrupt 2DH:Rserved(IRET)
        CALL    SET_INT_VECTOR
        MOV     AL,2EH                          ;Interrupt 2EH:DOS Execute Shell Command
        CALL    SET_INT_VECTOR
        MOV     AL,2FH                          ;Interrupt 2FH:Multiplex(IRET)
        CALL    SET_INT_VECTOR
        MOV     AL,33H                          ;Interrupt 33H:Mouse Services
        CALL    SET_INT_VECTOR
        ;-----------------------------------
        ;Borland/Microsoft Languages:Interrupts 34H through 3EH
        MOV     AX,34H
SET_INT_VECTORS_LOOP_1:
        CALL    SET_INT_VECTOR
        INC     AX
        CMP     AX,3EH
        JBE     SET_INT_VECTORS_LOOP_1
        ;-----------------------------------
        MOV     AL,3FH                          ;Interrupt 3FH:Overlay Manager Interrupt(Microsoft/IBM LINK.EXE)
        CALL    SET_INT_VECTOR

        MOV     AL,1BH
        LEA     DX,INT_1BH_HANDLER
        CALL    SET_INT_VECTOR

        MOV     AL,32H
        LEA     DX,INT_32H_HANDLER
        CALL    SET_INT_VECTOR
        ;Set MEM_UPPER_SEG.
        INT     12H
        ;AX=Conventional memory size in Kbytes
        MOV     DX,1024
        MUL     DX
        ;DX:AX=Conventional memory size in bytes
        MOV     BX,16
        DIV     BX
        ;AX=Last available segment+1
        MOV     MEM_UPPER_SEG,AX
        ;Set first available segment.

        JMP     REST_OF_INITIALIZATION

        END     START_MINITAK
