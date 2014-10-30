;MiniMan COMMAND.COM compatibility driver for MiniTAK operating system

.MODEL  TINY
.CODE
        ORG     100H
BEGIN:
        PUSH    CS
        POP     DS
        MOV     CL,DS:BYTE PTR[80H]
        XOR     CH,CH
        MOV     SI,81H
        CLD
READ_CMD_LINE:
        LODSB
        CMP     AL,' '          ;ASCII code 32
        JNE     CHECK_SWITCH
        LOOP    READ_CMD_LINE
        JMP     Short EXEC_MINIMAN
CHECK_SWITCH:
        CMP     AL,'/'
        JNE     EXEC_MINIMAN
        LODSB
        CMP     AL,'?'
        JNE     EXEC_MINIMAN
        LODSB
        CMP     AL,'?'
        JNE     EXEC_MINIMAN
        LODSB
        CMP     AL,0DH
        JNE     EXEC_MINIMAN
        SUB     CL,3
        JNZ     EXEC_MINIMAN
        MOV     DX,OFFSET HELP_MSG
        MOV     AH,09H
        INT     21H
        MOV     AL,00H
        JMP     Short EXIT_TO_CALLER
        ;-----------------------------------
EXEC_MINIMAN:
        MOV     AX,DS:WORD PTR[002CH]
        MOV     ENV_SEG,AX
        MOV     AX,CS
        MOV     CMD_LINE_SEG,AX
        MOV     FCB_1_SEG,AX
        MOV     FCB_2_SEG,AX
        MOV     ES,AX
        MOV     BX,24
        MOV     AH,4AH
        INT     21H
        MOV     DX,OFFSET MINIMAN_PATH
        MOV     BX,OFFSET MINIMAN_EPB
        MOV     AX,4B00H
        INT     21H
        MOV     AH,4DH
        INT     21H
EXIT_TO_CALLER:
        MOV     AH,4CH
        INT     21H

MINIMAN_PATH    DB      'MINIMAN.COM',00H
MINIMAN_EPB     LABEL   BYTE
ENV_SEG         DW      ?
CMD_LINE_OFF    DW      80H
CMD_LINE_SEG    DW      ?
FCB_1_OFF       DW      5CH
FCB_1_SEG       DW      ?
FCB_2_OFF       DW      6CH
FCB_2_SEG       DW      ?

HELP_MSG        DB      'MiniMan COMMAND.COM compatibility driver for MiniTAK operating system',10,13,'$'

        END     BEGIN
