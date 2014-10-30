.MODEL  SMALL
.CODE
        ORG     100H
BEGIN:  JMP     START
START:
        PUSH    CS
        POP     DS
        CALL    WELCOME_TO_OS

        MOV     AX,4C00H
        INT     21H

;***********************************************************************

GET_SCREEN_SIZE PROC
;INPUT:  NONE
;OUTPUT: DL=Max column number,DH=Max row number
        PUSH    AX
        PUSH    DS
        MOV     AX,0040H        ;BIOS Data Area Segment
        MOV     DS,AX
        MOV     DL,DS:BYTE PTR[4AH]
        DEC     DL
        MOV     DH,DS:BYTE PTR[84H]
        POP     DS
        POP     AX
        RET
GET_SCREEN_SIZE ENDP

;***********************************************************************

NEW_LINE        PROC
        PUSH    AX
        PUSH    DX
        MOV     AH,02H
        MOV     DL,0DH
        INT     21H
        MOV     DL,0AH
        INT     21H
        POP     DX
        POP     AX
        RET
NEW_LINE        ENDP

;***********************************************************************

CLEAR_SCREEN    PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AX,0600H
        XOR     CX,CX
        CALL    GET_SCREEN_SIZE
        MOV     BH,07H          ;Normal attribute
        INT     10H
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CLEAR_SCREEN    ENDP

;***********************************************************************

WRITE_DECIMAL   PROC
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
        MOV     AH,02H
WRITE_DIGIT_LOOP:
        POP     DX
        ADD     DL,'0'
        INT     21H
        LOOP    WRITE_DIGIT_LOOP
END_DECIMAl:
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
WRITE_DECIMAL   ENDP

;***********************************************************************

WELCOME_TO_OS   PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI

        MOV     AH,01H
        MOV     SI,0FFFFH
        INT     32H
        OR      SI,SI           ;Check to see whether MiniTAK is active(SI=0).
        JNZ     NOT_MINITAK

        CALL    CLEAR_SCREEN
        MOV     AH,0FH
        INT     10H
        MOV     AH,02H
        XOR     DX,DX
        INT     10H

        MOV     AH,0AH
        MOV     AL,'*'
        MOV     CX,80
        MOV     BH,0
        INT     10H
        MOV     DH,4
        MOV     DL,22
        XOR     BH,BH
        LEA     CX,WELCOME_MSG
WRITE_MSG:
        MOV     AH,2
        INT     10H
        PUSH    DX
        MOV     DX,CX
        MOV     AH,09H
        INT     21H
        POP     DX
        INC     DH
        ADD     CX,33
        CMP     DH,11
        JB      WRITE_MSG
        MOV     AH,2
        INT     10H
        ;-----------------------------------
        ;Write MiniTAK version number
        LEA     DX,MINITAK_STRING
        MOV     AH,09H
        INT     21H
        MOV     AH,01H
        INT     32H
        MOV     DL,AL
        XOR     DH,DH
        CALL    WRITE_DECIMAL
        MOV     DL,'.'
        PUSH    AX
        MOV     AH,02H
        INT     21H
        POP     AX
        MOV     DL,AH
        CALL    WRITE_DECIMAL
        ;-----------------------------------
        CALL    NEW_LINE
        CALL    NEW_LINE
        LEA     DX,BEGIN_MSG
        MOV     AH,09H
        INT     21H
        CALL    NEW_LINE
        JMP     Short WELCOME_DONE
NOT_MINITAK:
        ;Do anything here when MiniTAK is not active.;
WELCOME_DONE:
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
WELCOME_TO_OS   ENDP

;***********************************************************************
;Data defenitions

MINITAK_STRING          DB      'MiniTAK $'

        ;***********************************
        WELCOME_MSG     LABEL   BYTE
        W_1     DB      'ษออออออออออออออออออออออออออออออป$'
        W_2     DB      'บ        Welcome    To         บ$'
        W_3     DB      'บ                              บ$'
        W_4     DB      'บ           MiniTAK            บ$'
        W_5     DB      'บ                              บ$'
        W_6     DB      'บ      Operating   System      บ$'
        W_7     DB      'ศออออออออออออออออออออออออออออออผ$'
        BEGIN_MSG       DB      'To begin,type FASTHELP.$'
        ;***********************************

        END     BEGIN
