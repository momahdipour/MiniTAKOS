ADDDW           MACRO   DWORD_VALUE,WORD_VALUE
        ADD     WORD PTR DWORD_VALUE[0],WORD_VALUE
        ADC     WORD PTR DWORD_VALUE[2],0
        ENDM

.MODEL  SMALL
.CODE
        ORG     100H
BEGIN:  JMP     SYS

BOOT_CODE:
        INCLUDE         BOOT12.INC

        SYS_DRIVE_NO            DB              ?
        ;-----------------------------------
        MINIIO_HDL              DW              ?
        MINIIO_SEG              DW              ?
        MINIIO_LENGTH           DW              ?
        ;-----------------------------------
        MINITAK_HDL             DW              ?
        MINITAK_SEG             DW              ?
        MINITAK_LENGTH          DW              ?
        ;-----------------------------------
        MINIMAN_HDL             DW              ?
        MINIMAN_SEG             DW              ?
        MINIMAN_LENGTH          DW              ?
        ;-----------------------------------

        SYS_?_STR       DB      'Copies MiniTAK system files and command interpreter (MINIMAN.COM) to a',10,13,'specified disk.',10,13
                        DB      'Syntax: SYS drive:',10,13,10,13
                        DB      '  drive:       Specifies the drive you want to make it a MiniTAK system disk.',10,13
                        DB      '               (Only drive A: is supported in this version.)',10,13,'$'

        ERR_RPMISSING_MSG       DB      'Required parameter missing',10,13,'$'
        ERR_IDSPECIFIED_MSG     DB      'Invalid drive specification',10,13,'$'
        ERR_IPARAMETER_MSG      DB      'Invalid parameter',10,13,'$'

        OPEN_ERROR_MSG          DB      'Unable to access to the file: $'
        ERR_FNFOUND_MSG         DB      'File not found: $'

        IS_MEM_ERR_MSG          DB      'Insufficient memory$'
        MEM_ERR_MSG             DB      'Memory allocation error$'

        READ_ERR_MSG            DB      'Disk read error$'

        DISK_SPACE_ERR_MSG      DB      'Insufficient disk space',10,13,'$'

        DISK_WRITE_ERR_MSG      DB      'Disk write error$'

        DONE_MSG                DB      10,13,'System transferred successfully.$'

SYS     PROC
        PUSH    CS
        POP     DS
        CALL    CHECK_OS_VERSION
        ;Resize memory
        PUSH    CS
        POP     ES              ;ES=PSP Segment
        LEA     AX,END_ADDRESS
        ADD     AX,1024         ;Reserve 1 KB stack
        PUSH    AX
        XOR     DX,DX
        MOV     BX,16
        DIV     BX
        INC     AX
        MOV     BX,AX
        MOV     AH,4AH
        INT     21H
        JC      MEM_ERR
        POP     SP
        CALL    PROCESS_CMD_LINE_PARAMETERS
        CALL    ALLOCATE_BUFFERS
        CALL    OPEN_FILES
        CALL    READ_FILES
        CALL    CLOSE_FILES
        MOV     AH,0DH                  ;Flush all file buffers to disk
        INT     21H
        CALL    PROMPT
        CALL    CHECK_DESTINATION_SPACE
        CALL    CHECK_FILE_EXISTENCE
        CALL    WRITE_FILES
        CALL    WRITE_BOOT_SECTOR
        MOV     AH,09H
        LEA     DX,DONE_MSG
        INT     21H
        MOV     AX,4C00H
        INT     21H
SYS     ENDP

;***********************************************************************
MINITAK_VALID_VERSION           EQU             0001H   ;MiniTAK 1.0

CHECK_OS_VERSION        PROC
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
        CMP     AX,MINITAK_VALID_VERSION
        JE      VALID_OS_VERSION
        ;Invalid MiniTAK version
        MOV     AX,4C01H
        INT     21H
NOT_MINITAK:
VALID_OS_VERSION:
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CHECK_OS_VERSION        ENDP

;***********************************************************************

UPPER_CASE      PROC
        CMP     AL,'a'
        JB      UPPER_DONE
        CMP     AL,'z'
        JA      UPPER_DONE
        SUB     AL,'a'-'A'
UPPER_DONE:
        RET
UPPER_CASE      ENDP

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

PROCESS_CMD_LINE_PARAMETERS     PROC
        PUSH    AX
        PUSH    SI
        ;DS=PSP Segment
        MOV     SI,81H
        CLD
PARAMS_LOOP:
        LODSB
        CMP     AL,0DH
        JE      PCLP_NO_PARAM
        CMP     AL,' '
        JE      PARAMS_LOOP
        CMP     AL,'/'
        JE      CHECK_SWITCH
        CALL    UPPER_CASE
        CMP     AL,'A'          ;Only drive A: is supported in this version.
        JNE     PCLP_INVALID_DRIVE
        PUSH    AX
        LODSB
        CMP     AL,':'
        JNE     PCLP_INVALID_DRIVE
CHECK_LINE_REST:
        LODSB
        CMP     AL,' '
        JE      CHECK_LINE_REST
        CMP     AL,0DH
        JNE     PCLP_INVALID_DRIVE
VALID_DRIVE:
        POP     AX
        SUB     AL,'A'
        MOV     SYS_DRIVE_NO,AL
        JMP     Short PCLP_PARAMS_DONE
CHECK_SWITCH:
        LODSB
        CMP     AL,'?'
        JNE     PCLP_INV_PARAM
        LODSB
        CMP     AL,0DH
        JNE     PCLP_INV_PARAM
        LEA     DX,SYS_?_STR
        JMP     Short PCLP_WRITE_MSG
PCLP_NO_PARAM:
        LEA     DX,ERR_RPMISSING_MSG
        JMP     Short PCLP_WRITE_MSG
PCLP_INVALID_DRIVE:
        LEA     DX,ERR_IDSPECIFIED_MSG
        JMP     Short PCLP_WRITE_MSG
PCLP_INV_PARAM:
        LEA     DX,ERR_IPARAMETER_MSG
PCLP_WRITE_MSG:
        MOV     AH,09H
        INT     21H
PCLP_TERMINATE:
        MOV     AX,4C02H
        INT     21H
PCLP_PARAMS_DONE:
        POP     SI
        POP     AX
        RET
PROCESS_CMD_LINE_PARAMETERS     ENDP

;***********************************************************************
MINIIO_PATH     DB      'MINIIO.SYS ',00H,'$'
MINITAK_PATH    DB      'MINITAK.SYS',00H,'$'
MINIMAN_PATH    DB      'MINIMAN.COM',00H,'$'

OPEN_FILES      PROC
        PUSH    AX
        PUSH    BX
        PUSH    DX
        ;Open MINIIO.SYS
        XOR     BX,BX
        MOV     AX,3D00H
        LEA     DX,MINIIO_PATH
        INT     21H
        JC      OPEN_ERROR
        MOV     MINIIO_HDL,AX
        ;Open MINITAK.SYS
        INC     BX
        MOV     AX,3D00H
        LEA     DX,MINITAK_PATH
        INT     21H
        JC      OPEN_ERROR
        MOV     MINITAK_HDL,AX
        ;Open MINIMAN.COM
        INC     BX
        MOV     AX,3D00H
        LEA     DX,MINIMAN_PATH
        INT     21H
        JC      OPEN_ERROR
        MOV     MINIMAN_HDL,AX
        ;-----------------------------------
        POP     DX
        POP     BX
        POP     AX
        RET
OPEN_ERROR:
        CMP     AL,02H          ;02H: File not found
        JE      FNF_MSG
        LEA     DX,OPEN_ERROR_MSG
        JMP     Short DISPLAY_OPEN_MSG
FNF_MSG:
        LEA     DX,ERR_FNFOUND_MSG
DISPLAY_OPEN_MSG:
        MOV     AH,09H
        INT     21H
        LEA     DX,MINIIO_PATH
        MOV     AL,11
        MUL     BL
        ADD     DX,AX
        MOV     AH,09H
        INT     21H
        CALL    NEW_LINE
        MOV     AX,4C03H
        INT     21H
OPEN_FILES      ENDP

;***********************************************************************

ALLOCATE_BUFFERS        PROC
        PUSH    AX
        PUSH    BX
        ;-----------------------------------
        ;Allocate memory for MINIIO.SYS
        MOV     AH,48H
        MOV     BX,1000H        ;64 KB
        INT     21H
        JC      MEM_ERR
        MOV     MINIIO_SEG,AX
        ;-----------------------------------
        ;Allocate memory for MINITAK.SYS
        MOV     AH,48H
        INT     21H
        JC      MEM_ERR
        MOV     MINITAK_SEG,AX
        ;-----------------------------------
        ;Allocate memory for MINIMAN.COM
        MOV     AH,48H
        INT     21H
        JC      MEM_ERR
        MOV     MINIMAN_SEG,AX
        ;-----------------------------------
        POP     BX
        POP     AX
        RET
MEM_ERR         LABEL           FAR
        CMP     AL,08H
        JE      IS_MEM_ERR
        LEA     DX,MEM_ERR_MSG
        JMP     Short WRITE_MEM_ERR
IS_MEM_ERR:
        LEA     DX,IS_MEM_ERR_MSG
WRITE_MEM_ERR:
        MOV     AH,09H
        INT     21H
        MOV     AX,4C04H
        INT     21H
ALLOCATE_BUFFERS        ENDP

;***********************************************************************

INCALL_CHECK_FILE_LENGTH        PROC
        MOV     AH,3FH
        INT     21H
        OR      AX,AX
        JNZ     READ_ERROR
        RET
INCALL_CHECK_FILE_LENGTH        ENDP

;***********************************************************************

READ_FILES      PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        ;-----------------------------------
        MOV     AH,3FH
        MOV     BX,MINIIO_HDL
        MOV     CX,65000
        XOR     DX,DX
        PUSH    DS
        MOV     DS,MINIIO_SEG
        INT     21H
        POP     DS
        JC      READ_ERROR
        OR      AX,AX
        JZ      READ_ERROR
        MOV     MINIIO_LENGTH,AX
        CALL    INCALL_CHECK_FILE_LENGTH
        ;-----------------------------------
        MOV     AH,3FH
        MOV     BX,MINITAK_HDL
        PUSH    DS
        MOV     DS,MINITAK_SEG
        INT     21H
        POP     DS
        JC      READ_ERROR
        OR      AX,AX
        JZ      READ_ERROR
        MOV     MINITAK_LENGTH,AX
        CALL    INCALL_CHECK_FILE_LENGTH
        ;-----------------------------------
        MOV     AH,3FH
        MOV     BX,MINIMAN_HDL
        PUSH    DS
        MOV     DS,MINIMAN_SEG
        INT     21H
        POP     DS
        JC      READ_ERROR
        OR      AX,AX
        JZ      READ_ERROR
        MOV     MINIMAN_LENGTH,AX
        CALL    INCALL_CHECK_FILE_LENGTH
        ;-----------------------------------
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
READ_ERROR      LABEL           FAR
        MOV     AH,09H
        LEA     DX,READ_ERR_MSG
        INT     21H
        MOV     AX,4C05H
        INT     21H
READ_FILES      ENDP

;***********************************************************************

CLOSE_FILES     PROC
        PUSH    AX
        PUSH    BX
        MOV     AH,3EH
        MOV     BX,MINIIO_HDL
        INT     21H
        MOV     AH,3EH
        MOV     BX,MINITAK_HDL
        INT     21H
        MOV     AH,3EH
        MOV     BX,MINIMAN_HDL
        INT     21H
        POP     BX
        POP     AX
        RET
CLOSE_FILES     ENDP

;***********************************************************************
PROMPT_MSG_1    DB      'Please insert a blank formatted disk into drive $'
PROMPT_MSG_2    DB      ':,',10,13,'and press ENTER when ready...$'

PROMPT  PROC
        PUSH    AX
        PUSH    DX
        MOV     AH,09H
        LEA     DX,PROMPT_MSG_1
        INT     21H
        MOV     DL,SYS_DRIVE_NO
        ADD     DL,'A'
        MOV     AH,02H
        INT     21H
        MOV     AH,09H
        LEA     DX,PROMPT_MSG_2
        INT     21H
WAIT_ENTER:
        MOV     AX,0C08H
        INT     21H
        CMP     AL,0DH
        JNE     WAIT_ENTER
        CALL    NEW_LINE
        POP     DX
        POP     AX
        RET
PROMPT  ENDP

;***********************************************************************
DWORD_TEMP              DD              0

CHECK_DESTINATION_SPACE PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AX,MINIIO_LENGTH
        ADDDW   DWORD_TEMP,AX
        MOV     AX,MINITAK_LENGTH
        ADDDW   DWORD_TEMP,AX
        MOV     AX,MINIMAN_LENGTH
        ADDDW   DWORD_TEMP,AX
        MOV     AH,36H
        MOV     DL,SYS_DRIVE_NO
        INC     DL
        INT     21H
        MUL     BX
        OR      DX,DX
        JNZ     SPCAE_AVAILABLE
        MUL     CX
        ;Compare DX:AX with DWORD_TEMP
        CMP     DX,WORD PTR DWORD_TEMP[2]
        JA      SPCAE_AVAILABLE
        JB      NOT_ENOUGH_DISK_SPACE
        CMP     AX,WORD PTR DWORD_TEMP[0]
        JAE     SPCAE_AVAILABLE
NOT_ENOUGH_DISK_SPACE:
        MOV     AH,09H
        LEA     DX,DISK_SPACE_ERR_MSG
        INT     21H
        MOV     AX,4C06H
        INT     21H
SPCAE_AVAILABLE:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CHECK_DESTINATION_SPACE ENDP

;***********************************************************************
MINIIO_DES_PATH         DB      'A:\MINIIO.SYS ',00H,'$'
MINITAK_DES_PATH        DB      'A:\MINITAK.SYS',00H,'$'
MINIMAN_DES_PATH        DB      'A:\MINIMAN.COM',00H,'$'

FILE_EXISTS_MSG         DB      'File already exists: $'

CHECK_FILE_EXISTENCE    PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        ;-----------------------------------
        MOV     AX,4300H
        LEA     DX,MINIIO_DES_PATH
        INT     21H
        JNC     ALREADY_EXISTS
        ;-----------------------------------
        MOV     AX,4300H
        LEA     DX,MINITAK_DES_PATH
        INT     21H
        JNC     ALREADY_EXISTS
        ;-----------------------------------
        MOV     AX,4300H
        LEA     DX,MINIMAN_DES_PATH
        INT     21H
        JC      CFE_DONE
        ;-----------------------------------
ALREADY_EXISTS:
        PUSH    DX
        MOV     AH,09H
        LEA     DX,FILE_EXISTS_MSG
        INT     21H
        POP     DX
        INT     21H
        MOV     AX,4C08H
        INT     21H
CFE_DONE:
        POP     DX
        POP     CX
        POP     AX
        RET
CHECK_FILE_EXISTENCE    ENDP

;***********************************************************************
CREATE_ERR_MSG          DB              10,13,'Error: Can not create the file $'

CREATE_FILE     PROC
        MOV     AH,5BH
        INT     21H
        JNC     CREATE_SUCCESS
        PUSH    DX
        MOV     AH,09H
        LEA     DX,CREATE_ERR_MSG
        INT     21H
        POP     DX
        INT     21H
        MOV     AX,4C07H
        INT     21H
CREATE_SUCCESS:
        RET
CREATE_FILE     ENDP

;***********************************************************************

WRITE_FILES     PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        ;-----------------------------------
        ;Write MINIIO.SYS
        LEA     DX,MINIIO_DES_PATH
        MOV     CX,07H                  ;File attribute: RHS
        CALL    CREATE_FILE
        MOV     BX,AX
        MOV     AH,40H
        MOV     CX,MINIIO_LENGTH
        XOR     DX,DX
        PUSH    DS
        MOV     DS,MINIIO_SEG
        INT     21H
        POP     DS
        JC      DISK_WRITE_ERROR
        CMP     AX,CX
        JNE     DISK_WRITE_ERROR
        MOV     AH,3EH
        INT     21H
        ;-----------------------------------
        ;Write MINITAK.SYS
        LEA     DX,MINITAK_DES_PATH
        MOV     CX,07H                  ;File attribute: RHS
        CALL    CREATE_FILE
        MOV     BX,AX
        MOV     AH,40H
        MOV     CX,MINITAK_LENGTH
        XOR     DX,DX
        PUSH    DS
        MOV     DS,MINITAK_SEG
        INT     21H
        POP     DS
        JC      DISK_WRITE_ERROR
        CMP     AX,CX
        JNE     DISK_WRITE_ERROR
        MOV     AH,3EH
        INT     21H
        ;-----------------------------------
        ;Write MINIMAN.COM
        LEA     DX,MINIMAN_DES_PATH
        MOV     CX,20H                  ;File attribute: R
        CALL    CREATE_FILE
        MOV     BX,AX
        MOV     AH,40H
        MOV     CX,MINIMAN_LENGTH
        XOR     DX,DX
        PUSH    DS
        MOV     DS,MINIMAN_SEG
        INT     21H
        POP     DS
        JC      DISK_WRITE_ERROR
        CMP     AX,CX
        JNE     DISK_WRITE_ERROR
        MOV     AH,3EH
        INT     21H
        ;-----------------------------------
        JMP     Short WRITE_FILES_DONE
DISK_WRITE_ERROR:
        MOV     AH,09H
        LEA     DX,DISK_WRITE_ERR_MSG
        INT     21H
        CALL    NEW_LINE
        MOV     AX,4C09H
        INT     21H
WRITE_FILES_DONE:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
WRITE_FILES     ENDP

;***********************************************************************

FIX_SN  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        ;-----------------------------------
        XOR     BX,BX
        MOV     AL,SYS_DRIVE_NO
        XOR     DX,DX
        MOV     CX,1
        PUSH    DS
        MOV     DS,MINIIO_SEG                   ;Use MINIIO_SEG as a temp memory
        INT     25H
        POP     AX
        JC      FIX_SN_DONE_1
        PUSH    ES
        PUSH    CS
        POP     ES
        MOV     SI,39
        LEA     DI,BOOT_CODE
        ADD     DI,39
        MOV     CX,15
   REP  MOVSB
        POP     ES
FIX_SN_DONE_1:
        POP     DS
FIX_SN_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
FIX_SN  ENDP

;***********************************************************************
BOOT_ERR_MSG            DB              10,13,'Error: Can not write to the boot sector of the disk.$'

WRITE_BOOT_SECTOR       PROC
        CALL    FIX_SN
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AL,SYS_DRIVE_NO
        LEA     BX,BOOT_CODE
        XOR     DX,DX
        MOV     CX,1
        INT     26H
        POP     AX
        JNC     BOOT_SEC_DONE
        ;-----------------------------------
        MOV     AH,09H
        LEA     DX,BOOT_ERR_MSG
        INT     21H
        MOV     AX,4C0AH
        INT     21H
BOOT_SEC_DONE:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
WRITE_BOOT_SECTOR       ENDP

END_ADDRESS             LABEL           BYTE

        END     BEGIN
