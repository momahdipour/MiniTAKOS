;************************        MACROS         ************************

PUSHALL         MACRO
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        ENDM

POPALL         MACRO
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        ENDM

MOVDW           MACRO   DWORD_VALUE,WORD_VALUE
        MOV     WORD PTR DWORD_VALUE[0],WORD_VALUE
        MOV     WORD PTR DWORD_VALUE[2],0
        ENDM

ADDDW           MACRO   DWORD_VALUE,WORD_VALUE
        ADD     WORD PTR DWORD_VALUE[0],WORD_VALUE
        ADC     WORD PTR DWORD_VALUE[2],0
        ENDM

;**************************** EQUIVALENTS     **************************
MINITAK_VALID_VERSION_WORD              EQU             0001H   ;MiniTAK 1.0
MINIMAN_FILE_VER                        EQU             0A001H
;-------------------------------------------
STACK_SIZE                      EQU     1024    ;1 KB Stack
;***********************************************************************
;Key Codes
CR      EQU     0DH
LF      EQU     0AH
ESCAPE  EQU     1BH
BS      EQU     08H
TAB     EQU     09H
;***********************************************************************
;***********************************************************************
        ;@@@@@@@@@@@@@@@@@@@@@@   EQUIVALENTS  1   @@@@@@@@@@@@@@@@@@@@@
        FATTR_READ_ONLY                 EQU             01H
        FATTR_HIDDEN                    EQU             02H
        FATTR_SYSTEM                    EQU             04H
        FATTR_VOLUME_ID                 EQU             08H
        FATTR_DIRECTORY                 EQU             10H
        FATTR_ARCHIVE                   EQU             20H
        ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ;@@@@@@@@@@@@@@@@@@@@@@   EQUIVALENTS  2   @@@@@@@@@@@@@@@@@@@@@
        FAT12_EOC                       EQU             0FF8H
        FAT12_BADCLUS                   EQU             0FF7H

        STD_OUT_ACCESS                  EQU             2
        ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ;@@@@@@@@@@@@@@@   EQUIVALENTS  3 (ERROR CODES)  @@@@@@@@@@@@@@@
        ERR_IFNUMBER            EQU     01H     ;Invalid Function Number
        ERR_FNFOUND             EQU     02H     ;File Not Found
        ERR_PNFOUND             EQU     03H     ;Path Not Found
        ERR_TMOFILES            EQU     04H     ;Too Many Open Files
        ERR_ADENIED             EQU     05H     ;Access Denied
        ERR_IHANDLE             EQU     06H     ;Invalid Handle
        ERR_MCBDESTROYED        EQU     07H     ;Memory Control
                                                ; Blocks Destroyed
        ERR_ISMEMORY            EQU     08H     ;InSufficient Memory
        ERR_IMBADDRESS          EQU     09H     ;Invalid Memory Block
                                                ; Address
        ERR_IENVIRONMENT        EQU     0AH     ;Invalid Environment
        ERR_IFORMAT             EQU     0BH     ;Invalid Format
        ERR_IACODE              EQU     0CH     ;Invalid Access Code
        ERR_IDATA               EQU     0DH     ;Invalid Data
        ERR_IDSPECIFIED         EQU     0FH     ;Invalid Drive Specified
        ERR_ATRCDIR             EQU     10H     ;Attemt To Remove Current
                                                ; Directory
        ERR_NSDEVICE            EQU     11H     ;Not Same Device
        ERR_NMMFILES            EQU     12H     ;No More Matching Files
        ERR_RFAULT              EQU     1EH     ;Read Fault
        ERR_WFAULT              EQU     1DH     ;Write Fault
        ERR_SERROR              EQU     19H     ;Seek Error
        ERR_SNFOUND             EQU     1BH     ;Sector Not Found

        ERR_FAIL24H             EQU     53H     ;Fail on INT 24H


        ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;***********************************************************************

.MODEL  SMALL
.CODE
ORG     100H
START:  JMP     MINIMAN_INITIALIZE
        DW      MINIMAN_FILE_VER        ;MiniMan.COM File Version
                                        ;This version number is checked any time an access to
                                        ;the MINIMAN.COM file is required to avoid using
                                        ;incorrect MINIMAN.COM file versions.

;*************************   DATA DEFENITIONS   ************************
;***********************************************************************
;*********************       LOCAL   VARIABLES       *******************
        ;Disk Transfer Area
        DTA             DB      43 DUP(?)
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        TYPE_?_MSG      DB      'Use /? for help.$'
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        BYTE_1          DB      ?
        BYTE_2          DB      ?
        WORD_1          DW      ?
        WORD_2          DW      ?
        DWORD_1         DD      ?
        DWORD_2         DD      ?
        FNAME_1         DB      80 DUP(0)
        FNAME_2         DB      80 DUP(0)
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;Command Table
        CMD_TABLE       LABEL     BYTE
                DB      4,'ATTR',00H
                DW      OFFSET CMD_ATTRIB
                DB      4,'BEEP',00H
                DW      OFFSET CMD_BEEP
                DB      5,'BREAK',00H
                DW      OFFSET CMD_BREAK
                DB      4,'CALL',00H
                DW      OFFSET CMD_CALL
                DB      2,'CD',00H
                DW      OFFSET CMD_CD
                DB      5,'CHDIR',00H
                DW      OFFSET CMD_CD
                DB      3,'CLS',00H
                DW      OFFSET CMD_CLS
                DB      4,'COPY',00H
                DW      OFFSET CMD_COPY
                DB      6,'COPYTO',00H
                DW      OFFSET CMD_COPYTO
                DB      4,'DATE',00H
                DW      OFFSET CMD_DATE
                DB      3,'DEL',00H
                DW      OFFSET CMD_DEL
                DB      3,'DIR',00H
                DW      OFFSET CMD_DIR
                DB      6,'DOSVER',00H
                DW      OFFSET CMD_DOSVER
                DB      4,'ECHO',00H
                DW      OFFSET CMD_ECHO
                DB      5,'ECHO.',00H
                DW      OFFSET CMD_ECHO
                DB      5,'ERASE',00H
                DW      OFFSET CMD_DEL
                DB      4,'EXIT',00H
                DW      OFFSET CMD_EXIT
                DB      8,'FASTHELP',00H
                DW      OFFSET CMD_FASTHELP
                DB      3,'LED',00H
                DW      OFFSET CMD_LED
                DB      2,'LS',00H
                DW      OFFSET CMD_DIR
                DB      2,'MD',00H
                DW      OFFSET CMD_MD
                DB      3,'MEM',00H
                DW      OFFSET CMD_MEM
                DB      5,'MKDIR',00H
                DW      OFFSET CMD_MD
                DB      4,'PATH',00H
                DW      OFFSET CMD_PATH
                DB      5,'PATH;',00H
                DW      OFFSET CMD_PATH
                DB      5,'PAUSE',00H
                DW      OFFSET CMD_PAUSE
                DB      6,'PROMPT',00H
                DW      OFFSET CMD_PROMPT
                DB      2,'RD',00H
                DW      OFFSET CMD_RD
                DB      3,'REM',00H
                DW      OFFSET CMD_REM
                DB      3,'REN',00H
                DW      OFFSET CMD_RENAME
                DB      6,'RENAME',00H
                DW      OFFSET CMD_RENAME
                DB      7,'RESTART',00H
                DW      OFFSET CMD_RESTART
                DB      5,'RMDIR',00H
                DW      OFFSET CMD_RD
                DB      3,'SET',00H
                DW      OFFSET CMD_SET
                DB      4,'TIME',00H
                DW      OFFSET CMD_TIME
                DB      4,'TYPE',00H
                DW      OFFSET CMD_TYPE
                DB      3,'VER',00H
                DW      OFFSET CMD_VER
                DB      6,'VERIFY',00H
                DW      OFFSET CMD_VERIFY
                DB      3,'VOL',00H
                DW      OFFSET CMD_VOL
                DB      6,'VOLUME',00H
                DW      OFFSET CMD_VOL
                ;---------------------------
                DB      7,'CONTACT',00H
                DW      OFFSET CMD_CONTACT
                DB      23,'$MINITAK_QUERY_CREATOR$',00H
                DW      OFFSET CMD_MINITAK_QUERY_CREATOR
                DB      8,'$RELOAD$',00H
                DW      OFFSET CMD_RELOAD
                DB      0FFH            ;End Of Table

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        MINIMAN_ACTIVE          DB      1
        ENV_SEG_SIZE            DW      512-81  ;81 bytes reserved for INT 21H Func. 4BH(EXEC)
        BATCH_STAGE             DB      0       ;0=No batch file is active
                                                ;Greater than 0=Level of nested batch file processing
        PSP_SEGMENT             DW      ?
        ECHO_STATUS             DB      1       ;1=ON , 0=OFF
        STARTUP_FLAGS           DB      00000001b
                ;Bit 0: 1=EXIT command is enabled.
                EXIT_CMD_ENABLED        EQU     01H
                ;Bit 1: 1=Process AUTOEXEC.BAT
                AUTOEXEC_BAT            EQU     02H
                ;Bit 3: 1=/K command line switch
                K_CMD_LINE_SWITCH       EQU     08H
                ;Bit 4: 1=/C command line switch
                C_CMD_LINE_SWITCH       EQU     10H

        CURSOR_UP_FLAG          DB      0

        CMD_BUF         LABEL   BYTE
        CMD_LEN_LIMIT   DB      128
        CMD_LEN         DB      0
        CMD_LINE_BUF    DB      137 DUP(0)      ;(128 bytes)+(1 byte for NORMALIZE_COMMAND_LINE)+(8 bytes for "CMDLINE=" environment variable string)

        ;--------EXECUTING VARIABLES--------
        EXEC_CMD_LINE_LEN       DB              ?
        EXEC_CMD_LINE           DB              7EH DUP(00H)
        EXEC_FCB_1              DB              10H DUP(20H)
        EXEC_FCB_2              DB              14H DUP(20H)

        EXEC_EPB                LABEL           BYTE
                                DW              0000H

                                DW              OFFSET EXEC_CMD_LINE_LEN
        EXEC_CMD_LINE_SEG       DW              ?

                                DW              OFFSET EXEC_FCB_1
        EXEC_FCB_1_SEG          DW              ?

                                DW              OFFSET EXEC_FCB_2
        EXEC_FCB_2_SEG          DW              ?
        ;-----------------------------------
        CMD_STR         DB      129 DUP(0)
        CMD_PARAM       DB      129 DUP(0)
        CURRENT_PATH    DB      70 DUP(00H)
        ;-----------------------------------
        
        BAD_CMD_MSG     DB              'Unknown command or executable filename',CR,LF,'$'


BEGIN_OS        PROC
;-----------------------------------------------------------------------;
;BEGIN_OS: Main start point of MiniMan.COM                              ;
;-----------------------------------------------------------------------;
        CALL    PROCESS_CMD_LINE_PARAMETERS
        CALL    RESET_RESERVED_HDLS
        TEST    STARTUP_FLAGS,C_CMD_LINE_SWITCH
        JZ      NO_IMMEDIATE_EXIT
        ;-----------------------------------
        LEA     AX,END_ADDRESS
        ADD     AX,STACK_SIZE
        MOV     SP,AX
        CALL    SHRINK_MEMORY
        ;-----------------------------------
        CALL    PROCESS_COMMAND
        MOV     AX,4C00H
        INT     21H
NO_IMMEDIATE_EXIT:
        CALL    INSTALL_INT_24H_HANDLER
        TEST    STARTUP_FLAGS,K_CMD_LINE_SWITCH
        JNZ     BANNER_OK
        CALL    SHOW_BANNER
BANNER_OK:
        CALL    CHECK_MINIMAN_INSTALLATION
        JNC     ISNTALLATION_STATUS_DONE
        CALL    INSTALL_MINIMAN
ISNTALLATION_STATUS_DONE:
        ;-----------------------------------
        LEA     AX,END_ADDRESS
        ADD     AX,STACK_SIZE
        MOV     SP,AX
        CALL    SHRINK_MEMORY
        ;-----------------------------------
        CALL    PROCESS_AUTOEXEC_BAT
        ;***************************************************************
COMMAND_LOOP:
        MOV     AX,CS
        MOV     DS,AX
        CALL    BUILD_CURRENT_PATH
        CALL    PREPARE_PROMPT_LINE
        ;CALL    RESET_LINE
        LEA     DX,CMD_BUF
        CALL    READ_COMMAND_LINE
        MOV     BL,CMD_LEN
        XOR     BH,BH
        MOV     BYTE PTR CMD_LINE_BUF[BX],0
        CALL    PROCESS_COMMAND
        JMP     Short COMMAND_LOOP
BEGIN_OS        ENDP

;***********************************************************************

PREPARE_PROMPT_LINE     PROC
        CMP     ECHO_STATUS,0
        JNE     CHECK_CURSOR_FLAG
        CALL    CURSOR_UP
CHECK_CURSOR_FLAG:
        CMP     CURSOR_UP_FLAG,1
        JE      CURSOR_POSITION_OK
        CALL    NEW_LINE
CURSOR_POSITION_OK:
        MOV     CURSOR_UP_FLAG,0
        CALL    WRITE_PROMPT
        RET
PREPARE_PROMPT_LINE     ENDP

;***********************************************************************

PROCESS_COMMAND PROC
;INPUT:  CMD_LINE_BUF includes the command line as an ASCIIZ string.
;OUTPUT: All register values except DS,ES,SS and SP are destroyed.
        PUSH    DS
        PUSH    ES
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        ;--------------COMMAND DISPATCHER---------------
RETRY_COMMAND_LINE:
        LEA     SI,CMD_LINE_BUF
PCL_SEMI_COLON_IGNORE:
        CALL    STR_LTRIM
        CMP     BYTE PTR[SI],';'
        JNE     PCL_SM_DONE
        MOV     BYTE PTR[SI],' '        ;ASCII code 32
        JMP     Short PCL_SEMI_COLON_IGNORE
PCL_SM_DONE:
        LEA     DI,CMD_STR
        CALL    STR_COPY
        MOV     BX,DI
        CALL    STR_TO_UPPER
        MOV     CX,1
        CALL    GET_CMD_PARAM
        JNC     PCL_CONTINUE
        CMP     ECHO_STATUS,0
        JNE     PCL_DONE
        CALL    NEW_LINE
        JMP     Short PCL_DONE
PCL_CONTINUE:
        CALL    CHECK_DRIVE_DESIGNATOR
        JNC     PCL_DONE
        LEA     DI,CMD_PARAM
        LEA     SI,CMD_TABLE
        XOR     AH,AH
DISPATCH_LOOP:
        CMP     BYTE PTR[SI],0FFH
        JE      BAD_CMD
        INC     SI
        CALL    COMP_STRS
        JNC     CALL_CMD
        MOV     AL,[SI-1]
        ADD     SI,AX
        ADD     SI,3
        JMP     Short DISPATCH_LOOP
CALL_CMD:
        CMP     ECHO_STATUS,0
        JE      NO_NEW_LINE
        CALL    NEW_LINE
NO_NEW_LINE:
        MOV     AL,[SI-1]
        ADD     SI,AX
        INC     SI
        CALL    WORD PTR[SI]
        JMP     Short PCL_DONE

        ;Unknown command
BAD_CMD:
        CALL    NORMALIZE_COMMAND_LINE
        JNC     RETRY_COMMAND_LINE
        CALL    NEW_LINE
        MOV     SI,DI
        CALL    FIND_EXECUTABLE_FILE
        JNC     PCL_EXTERNAL_COMMAND
        CMP     AL,ERR_FAIL24H
        JNE     PCL_SHOW_ERROR_MSG
        CALL    WRITE_ERROR_MESSAGE
        CALL    NEW_LINE
        JMP     Short PCL_DONE
PCL_EXTERNAL_COMMAND:
        CMP     AH,2
        JE      PCL_BATCH_FILE
        MOV     MINIMAN_ACTIVE,0
        CALL    EXECUTE_EXTERNAL_COMMAND
        MOV     MINIMAN_ACTIVE,1
        JNC     PCL_DONE
PCL_SHOW_ERROR_MSG:
        LEA     DX,BAD_CMD_MSG
        CALL    WRITE_STRING
        JMP     Short PCL_DONE
PCL_BATCH_FILE:
        MOV     DX,SI
        CALL    PROCESS_BATCH_FILE
PCL_DONE:
        POP     ES
        POP     DS
        RET
PROCESS_COMMAND ENDP

;***********************************************************************
BATCH_BREAK_MSG         DB      CR,LF,'Terminate batch job (Y/N)?',00H

CONFIRM_BATCH_BREAK     PROC
        PUSH    AX
        PUSH    DX
CBB_LOOP:
        LEA     DX,BATCH_BREAK_MSG
        CALL    WRITE_ASCIIZ_NO_BREAK
        MOV     AH,07H
        INT     21H
        CMP     AL,00H
        JE      CBB_EXT_KEY
        CMP     AL,0DH
        JE      CBB_LOOP
        CMP     AL,TAB
        JE      CBB_LOOP
        CMP     AL,BS
        JE      CBB_LOOP
        MOV     DL,AL
        MOV     AH,06H
        INT     21H
        CALL    UPPER_CASE
        CMP     AL,'N'
        JE      CBB_FAILURE
        CMP     AL,'Y'
        JNE     CBB_LOOP
        CLC
        JMP     Short CBB_DONE
CBB_EXT_KEY:
        INT     21H
        JMP     Short CBB_LOOP
CBB_FAILURE:
        STC
CBB_DONE:
        POP     DX
        POP     AX
        RET
CONFIRM_BATCH_BREAK     ENDP

;***********************************************************************

PROCESS_BATCH_FILE      PROC
        INC     BATCH_STAGE
        MOV     AL,ECHO_STATUS
        PUSH    AX
        MOV     AL,00H
        CALL    OPEN_FILE
        JC      PBF_WRTERRMSG
        MOV     BX,AX
        MOV     CX,127
        LEA     DI,CMD_LINE_BUF
PBF_LOOP:
        CMP     CTRL_C_FLAG,1
        JNE     PBF_NO_BREAK
        MOV     CTRL_C_FLAG,0
        CALL    CONFIRM_BATCH_BREAK
        JNC     PBF_LOOP_DONE
PBF_NO_BREAK:
        CALL    CHECK_EOF
        JC      PBF_LOOP_DONE
        CALL    READ_FILE_LINE
        JC      PBF_FILE_ERROR
        MOV     DL,CR
        CALL    WRITE_CHAR
        CALL    BUILD_CURRENT_PATH
        CMP     BYTE PTR[DI],'@'
        JNE     PBF_CHECK_ECHO_STATUS
        MOV     BYTE PTR[DI],' '
        JMP     Short PBF_NO_ECHO
PBF_CHECK_ECHO_STATUS:
        CALL    PREPARE_PROMPT_LINE
        CMP     ECHO_STATUS,0
        JE      PBF_NO_ECHO
        MOV     DX,DI
        CALL    WRITE_ASCIIZ
PBF_NO_ECHO:
        PUSH    BX
        PUSH    CX
        PUSH    DI
        PUSH    DS
        CALL    PROCESS_COMMAND
        POP     DS
        POP     DI
        POP     CX
        POP     BX
        JMP     Short PBF_LOOP
PBF_LOOP_DONE:
        CALL    CLOSE_FILE
        CALL    NEW_LINE
        JMP     Short PBF_DONE
PBF_FILE_ERROR:
        MOV     AL,ERR_UNKNOWN
        CALL    CLOSE_FILE
PBF_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
        CALL    NEW_LINE
PBF_DONE:
        POP     AX
        MOV     ECHO_STATUS,AL
        DEC     BATCH_STAGE
        RET
PROCESS_BATCH_FILE      ENDP

;***********************************************************************
AUTOEXEC_BAT_PATH       DB      'AUTOEXEC.BAT',00H

PROCESS_AUTOEXEC_BAT    PROC
        PUSH    AX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        TEST    STARTUP_FLAGS,AUTOEXEC_BAT
        JZ      AUTOEXEC_DONE
        CALL    START_FIND_FILE
        LEA     DX,AUTOEXEC_BAT_PATH
        CALL    FIND_FILE
        JC      AUTOEXEC_DONE
        ;AL=File attribute
        TEST    AL,00011000b
        JNZ     AUTOEXEC_DONE
        MOV     SI,DX
        LEA     DI,CMD_LINE_BUF
        CALL    STR_COPY
        CALL    PROCESS_COMMAND
AUTOEXEC_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     AX
        RET
PROCESS_AUTOEXEC_BAT    ENDP

;***********************************************************************

CMD_CALL        PROC
        PUSH    AX
        PUSH    CX
        PUSH    SI
        PUSH    DI
        LEA     DI,CALL_?_STR
        CALL    HELP_SWITCH
        JNC     CALL_DONE
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      CALL_DONE
        LEA     SI,CMD_LINE_BUF
        MOV     DI,SI
        MOV     AH,' '
        CALL    STR_FIND_CHAR
        CLD
CALL_FIND_CMD:
        LODSB
        CMP     AL,' '
        JE      CALL_FIND_CMD
        DEC     SI
        CALL    STR_COPY
        CALL    PROCESS_COMMAND
CALL_DONE:
        POP     DI
        POP     SI
        POP     CX
        POP     AX
        RET
CMD_CALL        ENDP

;***********************************************************************
RFL_FLAGS               DB              ?
EOL_SIGN                EQU             0A0DH

READ_FILE_LINE  PROC
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        MOV     RFL_FLAGS,00H
        LEA     DX,BYTE_1
        MOV     SI,CX
        XOR     CX,CX
RFL_READ:
        MOV     CL,1
        CALL    READ_FILE
        JC      RFL_READ_ERROR
        OR      AX,AX
        JZ      RFL_EOF
RFL_NEW_CHAR:
        MOV     CL,BYTE_1
        CMP     CL,LOW EOL_SIGN
        JE      RFL_CHECK_EOL
        OR      SI,SI
        JZ      RFL_TOO_LONG
        MOV     BYTE PTR[DI],CL
        INC     DI
        DEC     SI
        JMP     Short RFL_READ
RFL_TOO_LONG:
        OR      RFL_FLAGS,01H
        JMP     Short RFL_READ
        ;-----------------------------------
RFL_CHECK_EOL:
        MOV     CL,1
        CALL    READ_FILE
        JC      RFL_READ_ERROR
        OR      AX,AX
        JZ      RFL_EOF
        CMP     BYTE_1,HIGH EOL_SIGN
        JE      RFL_EOL
RFL_NO_SIGN:
        OR      SI,SI
        JZ      RFL_TOO_LONG
        MOV     BYTE PTR[DI],CL
        INC     DI
        DEC     SI
        JMP     Short RFL_NEW_CHAR
        ;-----------------------------------
RFL_EOF:
RFL_EOL:
        MOV     BYTE PTR[DI],00H
        XOR     AX,AX
        TEST    RFL_FLAGS,01H
        JZ      RFL_LENGTH_OK
        INC     AX
RFL_LENGTH_OK:
        CLC
        JMP     Short RFL_DONE
RFL_READ_ERROR:
        ;CF=1
RFL_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        RET
READ_FILE_LINE  ENDP

;***********************************************************************

CHECK_EOF       PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        MOV     AX,4201H
        XOR     CX,CX
        XOR     DX,DX
        INT     21H
        JC      CEOF_EOF
        MOV     SI,AX
        MOV     DI,DX
        MOV     AX,4202H
        XOR     DX,DX
        INT     21H
        JC      CEOF_EOF
        PUSH    AX
        PUSH    DX
        MOV     AX,4200H
        MOV     DX,SI
        MOV     CX,DI
        INT     21H
        POP     DX
        POP     AX
        ;Compare DX:AX with DI:SI
        CMP     AX,SI
        JNE     CEOF_NOT_EOF
        CMP     DX,DI
        JE      CEOF_EOF
CEOF_NOT_EOF:
        CLC
        JMP     Short CEOF_DONE
CEOF_EOF:
        STC
CEOF_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
CHECK_EOF       ENDP

;***********************************************************************

SHRINK_MEMORY   PROC
        PUSH    ES
        PUSH    AX
        PUSH    BX
        PUSH    DX
        LEA     AX,END_ADDRESS
        ADD     AX,STACK_SIZE
        INC     AX
        INC     AX
        XOR     DX,DX
        MOV     BX,16
        DIV     BX
        INC     AX
        MOV     BX,AX
        MOV     AH,4AH
        MOV     ES,PSP_SEGMENT
        INT     21H
        JNC     SHRINK_DONE
        CALL    WRITE_ERROR_MESSAGE
        MOV     AX,4C01H
        INT     21H
SHRINK_DONE:
        POP     DX
        POP     BX
        POP     AX
        POP     ES
        RET
SHRINK_MEMORY   ENDP

;***********************************************************************

RESET_LINE      PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AH,03H
        XOR     BH,BH
        INT     10H
        PUSH    DX
        XOR     DL,DL
RESET_LINE_LOOP:
        MOV     AH,02H
        INT     10H
        MOV     AH,08H
        INT     10H
        MOV     CX,1
        MOV     BL,07H
        MOV     AH,09H
        INT     10H
        INC     DL
        CMP     DL,79
        JBE     RESET_LINE_LOOP
        POP     DX
        MOV     AH,02H
        INT     10H
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
RESET_LINE      ENDP

;***********************************************************************

EXECUTE_PROGRAM PROC
;INPUT:  SI=Pointer to the full command line of program name(including optional switches)
;        CF: 1=Show error messages , 0=Be quiet for errors
;OUTPUT: CF: 0=Successful execution , 1=Error in execution
        PUSHALL
        PUSH    DS
        PUSH    ES
        MOV     ECMD_ERROR_MODE,0
        JNC     EXECP_CONTINUE
        MOV     ECMD_ERROR_MODE,1
EXECP_CONTINUE:
        CALL    STR_LTRIM
        CALL    STR_LENGTH
        CMP     AH,0
        JNE     EXECP_BAD_LEN
        CMP     AL,CMD_LEN_LIMIT
        JAE     EXECP_BAD_LEN
        LEA     DI,CMD_LINE_BUF
        CALL    STR_COPY
        MOV     SI,DI
        LEA     DI,CMD_STR
        CALL    STR_COPY
        CALL    EXECUTE_EXTERNAL_COMMAND
        JMP     Short EXECP_DONE
EXECP_BAD_LEN:
        STC
EXECP_DONE:
        MOV     ECMD_ERROR_MODE,1
        POP     ES
        POP     DS
        POPALL
        RET
EXECUTE_PROGRAM ENDP

;***********************************************************************

READ_COMMAND_LINE       PROC
        PUSH    AX
        MOV     AX,4810H
        INT     2FH
        OR      AX,AX
        JZ      RCL_DONE
NO_INPUT_EDITOR:
        CALL    READ_STRING_BUF
RCL_DONE:
        POP     AX
        RET
READ_COMMAND_LINE       ENDP

;***********************************************************************
NCL_FLAGS               DB              ?

NORMALIZE_COMMAND_LINE  PROC
        PUSH    AX
        PUSH    SI
        MOV     NCL_FLAGS,00000000b
        LEA     SI,CMD_LINE_BUF
        CLD
        LODSB
        CMP     AL,'.'
        JE      NCL_NO_EFFECT
        CMP     AL,'\'
        JE      NCL_NO_EFFECT
NCL_SKIP_COMMAND:
        LODSB
        CMP     AL,00H
        JE      NCL_NO_EFFECT
        CMP     AL,' '
        JE      NCL_NO_EFFECT
        CMP     AL,'.'
        JE      NCL_NORMALIZE_DOT
        CMP     AL,'/'
        JE      NCL_NORMALIZE_SLASH
        CMP     AL,'='
        JE      NCL_NORMALIZE_EQUAL_SIGN
        CMP     AL,'\'
        JNE     NCL_SKIP_COMMAND
        OR      NCL_FLAGS,01H
        JMP     Short NCL_SKIP_COMMAND
NCL_NORMALIZE_EQUAL_SIGN:
        TEST    NCL_FLAGS,01H
        JNZ     NCL_SKIP_COMMAND
        JMP     Short NCL_SHIFT_RIGHT
NCL_NORMALIZE_SLASH:
        JMP     Short NCL_SHIFT_RIGHT
NCL_NORMALIZE_DOT:
        MOV     AL,BYTE PTR[SI]
        CMP     AL,00H
        JE      NCL_SHIFT_RIGHT
        CMP     AL,' '          ;ASCII code 32
        JE      NCL_SHIFT_RIGHT
        CMP     AL,'.'
        JE      NCL_SHIFT_RIGHT
        CMP     AL,'/'
        JE      NCL_SHIFT_RIGHT
        CMP     AL,'\'
        JNE     NCL_SKIP_COMMAND
NCL_SHIFT_RIGHT:
        DEC     SI
        MOV     AL,1
        CALL    STR_SHIFT_RIGHT
        CLC
        JMP     Short NCL_DONE
NCL_NO_EFFECT:
        STC
NCL_DONE:
        POP     SI
        POP     AX
        RET
NORMALIZE_COMMAND_LINE  ENDP

;***********************************************************************

CHECK_DRIVE_DESIGNATOR  PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        MOV     CX,1
        CALL    GET_CMD_PARAM
        JC      CDD_SUCCESS
        LEA     SI,CMD_PARAM
        LODSB
        CMP     WORD PTR[SI],003AH      ;003AH=':',00H
        JNE     CDD_FAILURE
        CALL    UPPER_CASE
        CMP     AL,'A'
        JB      CDD_INVDRIVE
        CMP     AL,'Z'
        JA      CDD_INVDRIVE
        SUB     AL,'A'
        MOV     DL,AL
        MOV     AH,0EH
        INT     21H
        MOV     AH,19H
        INT     21H
        CMP     AL,DL
        JE      CDD_SUCCESS
CDD_INVDRIVE:
        MOV     AL,ERR_IDSPECIFIED
        CALL    NEW_LINE
        CALL    WRITE_ERROR_MESSAGE
CDD_SUCCESS:
        CALL    NEW_LINE
        CLC
        JMP     Short CDD_DONE
CDD_FAILURE:
        STC
CDD_DONE:
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
CHECK_DRIVE_DESIGNATOR  ENDP

;***********************************************************************
MINITAK_ACTIVATION_MSG  DB      'MiniTAK is not active.',CR,LF,'$'

CHECK_OS        PROC
;INPUT:  CF=0: Don't shows any messages if MiniTAK is not active.
;        CF=1: Shows activation messages if MiniTAK is not active.
;OUTPUT: CF=0: MiniTAK is active. , CF=1: MiniTAK is not active.
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSHF
        MOV     AH,01H
        MOV     SI,0FFFFH
        INT     32H
        OR      SI,SI           ;Check to see whether MiniTAK is active(SI=0).
        JNZ     CHKOS_NOT_MINITAK
        POPF
        CLC
        JMP     Short CHKOS_DONE
CHKOS_NOT_MINITAK:
        POPF
        JNC     CHKOS_ACTIVATION_MSG_DONE
        LEA     DX,MINITAK_ACTIVATION_MSG
        CALL    WRITE_STRING
CHKOS_ACTIVATION_MSG_DONE:
        STC
CHKOS_DONE:
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CHECK_OS        ENDP

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
TEXT_LINE_COUNT         DB      ?

NEW_TEXT_LINE   PROC
        PUSH    DX
        INC     TEXT_LINE_COUNT
        CALL    GET_SCREEN_SIZE
        CMP     TEXT_LINE_COUNT,DH
        JBE     NTL_DONE
        MOV     TEXT_LINE_COUNT,1
        CALL    SCREEN_PAUSE
NTL_DONE:
        POP     DX
        RET
NEW_TEXT_LINE   ENDP

;***********************************************************************

CHAR_TO_DIGIT   PROC
        CMP     AL,'0'
        JB      CTD_BAD_DIGIT
        CMP     AL,'9'
        JA      CTD_BAD_DIGIT
        SUB     AL,'0'
        CLC
        JMP     Short CTD_RETURN
CTD_BAD_DIGIT:
        STC
CTD_RETURN:
        RET
CHAR_TO_DIGIT   ENDP

;***********************************************************************

STR_TO_NUM_16   PROC
        PUSH    BX
        PUSH    DX
        PUSH    SI
        PUSH    AX
        CALL    STR_LENGTH
        OR      AX,AX
        JZ      STN_BAD_NUM
        XOR     BX,BX
        XOR     AH,AH
        CLD
        ;-----------------------------------
STN_LOOP:
        LODSB
        CMP     AL,00H
        JE      STN_NUM_END
        CALL    CHAR_TO_DIGIT
        JC      STN_BAD_NUM
        PUSH    AX
        MOV     AX,10
        MUL     BX
        MOV     BX,AX
        POP     AX
        OR      DX,DX
        JNZ     STN_BAD_NUM
        ADD     BX,AX
        JC      STN_BAD_NUM
        JMP     Short STN_LOOP
STN_NUM_END:
        ;-----------------------------------
        POP     AX
        MOV     AX,BX
        CLC
        JMP     Short STN_DONE
STN_BAD_NUM:
        POP     AX
        STC
STN_DONE:
        POP     SI
        POP     DX
        POP     BX
        RET
STR_TO_NUM_16   ENDP

;***********************************************************************

STR_FIND_CHAR   PROC
;INPUT:  SI=Address of an ASCIIZ string
;        AH=Character to find(if AH=00H, in return SI points to the end of the input string([SI]=00H))
;OUTPUT: CF=0=> SI=Points to the first occurence of the specified char in the input string
;        CF=1=> No occurence found
        PUSH    AX
        PUSH    SI
        CLD
SFC_LOOP:
        LODSB
        CMP     AL,AH
        JE      SFC_SUCCESS
        OR      AL,AL
        JNZ     SFC_LOOP
        POP     SI
        STC
        JMP     Short SFC_DONE
SFC_SUCCESS:
        DEC     SI
        POP     AX
        CLC
SFC_DONE:
        POP     AX
        RET
STR_FIND_CHAR   ENDP

;***********************************************************************

STR_FIND_END    PROC
        PUSH    AX
        CALL    STR_LENGTH
        ADD     SI,AX
        POP     AX
        RET
STR_FIND_END    ENDP

;***********************************************************************

GET_SEQ_ENV_VAR PROC
        PUSH    CX
        PUSH    SI
        PUSH    DS
        MOV     DS,PSP_SEGMENT
        MOV     DS,DS:WORD PTR[2CH]
        XOR     SI,SI
        JCXZ    GSEV_FAILURE
GSEV_LOOP:
        CMP     BYTE PTR[SI],00H
        JE      GSEV_FAILURE
        DEC     CX
        JZ      GSEV_SUCCESS
        CALL    STR_FIND_END
        INC     SI
        JMP     Short GSEV_LOOP
GSEV_FAILURE:
        POP     DS
        STC
        JMP     Short GSEV_DONE
GSEV_SUCCESS:
        POP     CX
        MOV     DX,SI
        CLC
GSEV_DONE:
        POP     SI
        POP     CX
        RET
GET_SEQ_ENV_VAR ENDP

;***********************************************************************

GET_ENV_VAR     PROC
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        MOV     DI,SI
        CALL    STR_FIND_END
        MOV     DS:BYTE PTR[SI],'='
        MOV     BX,SI
        MOV     AL,'='
        XOR     CX,CX
GEV_LOOP:
        INC     CX
        XCHG    DX,SI
        CALL    GET_SEQ_ENV_VAR
        XCHG    DX,SI
        JC      GEV_FAILURE
        CLC
        CALL    COMP_STRS_SPEC
        JC      GEV_LOOP
        MOV     DX,SI
        POP     AX              ;POP old DS from the stack
        CLC
        JMP     Short GEV_DONE
GEV_FAILURE:
        POP     DS
        STC
GEV_DONE:
        MOV     ES:BYTE PTR[BX],00H
        POP     DI
        POP     SI
        POP     CX
        POP     BX
        POP     AX
        POP     ES
        RET
GET_ENV_VAR     ENDP

;***********************************************************************

SET_ENV_VAR_SIZE        PROC
        PUSHALL
        PUSH    ES
        PUSH    DS
        POP     ES
        MOV     DI,SI
        CALL    STR_LENGTH
        CMP     AX,CX
        JE      SEVS_SUCCESS
        JA      SEVS_SHRINK
        ;-----------------------------------
        MOV     BX,AX
        XOR     SI,SI
        PUSH    CX
        XOR     CX,CX
        CLD
SEVS_GET_ENV_SIZE:
        LODSB
        INC     CX
        CMP     AL,00H
        JNE     SEVS_GET_ENV_SIZE
        LODSB
        CMP     AL,00H
        JNE     SEVS_GET_ENV_SIZE
        MOV     AX,ENV_SEG_SIZE
        SUB     AX,CX
        POP     CX
        ADD     AX,BX
        CMP     AX,CX
        JAE     SEVS_ENV_SIZE_OK
        STC
        JMP     Short SEVS_DONE
        ;-----------------------------------
SEVS_ENV_SIZE_OK:
        MOV     AX,CX
        SUB     AX,BX
        MOV     BX,AX
        ;BX=Number of bytes to append to the end of this environment variable
        MOV     SI,DI
        CALL    STR_FIND_END
        DEC     SI
        MOV     DX,SI
SEVS_FIND_ENV_END:
        CALL    STR_FIND_END
        INC     SI
        ;DF=0
        LODSB
        CMP     AL,00H
        JNE     SEVS_FIND_ENV_END
        DEC     SI
        MOV     DI,SI
        ADD     DI,BX
        STD
SEVS_EXPAND_ENV:
        LODSB
        STOSB
        CMP     SI,DX
        JNE     SEVS_EXPAND_ENV
        MOV     AL,' '          ;ASCII code 32
        MOV     DI,SI
        MOV     CX,BX
        CLD
  REP   STOSB
        JMP     Short SEVS_SUCCESS
        ;-----------------------------------
SEVS_SHRINK:
        CALL    STR_FIND_END
        ADD     DI,CX
        CLD
SEVS_SHRINK_ENV:
        LODSB
        STOSB
        CMP     AL,00H
        JNE     SEVS_SHRINK_ENV
        LODSB
        STOSB
        CMP     AL,00H
        JNE     SEVS_SHRINK_ENV
        ;-----------------------------------
SEVS_SUCCESS:
        CLC
SEVS_DONE:
        POP     ES
        POPALL
        RET
SET_ENV_VAR_SIZE        ENDP

;***********************************************************************

SET_ENV_VAR     PROC
        PUSHALL
        MOV     BX,DS
        CALL    STR_LENGTH
        MOV     CX,AX
        MOV     DI,SI
        CALL    GET_ENV_VAR
        JC      SEV_ADD_NEW_VAR
        ;-----------------------------------
        MOV     SI,DX
        JMP     Short SEV_SET_VARIABLE
        ;-----------------------------------
SEV_ADD_NEW_VAR:
        MOV     DS,PSP_SEGMENT
        MOV     DS,DS:WORD PTR[2CH]
        XOR     SI,SI
        CLD
SEV_FIND_ENV_END:
        CALL    STR_FIND_END
        ;DF=0
        INC     SI
        LODSB
        CMP     AL,00H
        JNE     SEV_FIND_ENV_END
        DEC     SI
        MOV     WORD PTR[SI],0020H      ;0020H=' ',00H
        MOV     BYTE PTR[SI+2],00H
        ;-----------------------------------
SEV_SET_VARIABLE:
        ;DS:SI=Pointer to the beginning of the variable in the environment segment
        ;BX:DI=Pointer to the new value for the variable as an ASCIIZ string
        ;CX=Length of the input string
        CALL    SET_ENV_VAR_SIZE
        JC      SEV_FAILURE
        XCHG    SI,DI
        PUSH    ES
        MOV     AX,DS
        MOV     ES,AX
        MOV     DS,BX
        CLD
  REP   MOVSB
        POP     ES
        CLC
        JMP     Short SEV_DONE
        ;-----------------------------------
SEV_FAILURE:
        MOV     WORD PTR[SI],0000H
        ;CF=1
SEV_DONE:
        MOV     DS,BX
        POPALL
        RET
SET_ENV_VAR     ENDP
;***********************************************************************

REMOVE_ENV_VAR  PROC
;INPUT:  DS:SI=Address of the environment variable name as an ASCIIZ string
;OUTPUT: CF=0=> Successful , CF=1=> Environment variable not defined
        PUSH    AX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
        ;-----------------------------------
        PUSH    DX
        CALL    GET_ENV_VAR
        MOV     SI,DX
        POP     DX
        JC      REV_FAILURE
        MOV     DI,SI
        PUSH    DS
        POP     ES
        CALL    STR_FIND_END
        CMP     WORD PTR[SI],0000H
        JE      REV_REMOVE
        INC     SI
REV_REMOVE:
        ;DF=0
        LODSB
        STOSB
        CMP     AL,00H
        JNE     REV_REMOVE
        LODSB
        STOSB
        CMP     AL,00H
        JNE     REV_REMOVE
        CLC
        JMP     Short REV_DONE
        ;-----------------------------------
REV_FAILURE:
        STC
REV_DONE:
        POP     ES
        POP     DS
        POP     DI
        POP     SI
        POP     AX
        RET
REMOVE_ENV_VAR  ENDP

;***********************************************************************

CHECK_ALL_FILES_WILDCARDS       PROC
;INPUT:  DS:DX=File specification as an ASCIIZ string
;OUTPUT: CF=0=> Filename is not *.* , CF=1=> Filename is *.*
        PUSH    SI
        MOV     SI,DX
        CALL    FIND_FNAME_POS
        CMP     WORD PTR[SI],'.*'
        JNE     NOT_ALL_FILES
        CMP     WORD PTR[SI+2],002AH    ;002AH='*',00H
        JNE     NOT_ALL_FILES
        STC
        JMP     Short CHECK_WILDCARDS_DONE
NOT_ALL_FILES:
        CLC
CHECK_WILDCARDS_DONE:
        POP     SI
        RET
CHECK_ALL_FILES_WILDCARDS       ENDP

;***********************************************************************

EXTRACT_FILE_EXT        PROC
        PUSH    AX
        PUSH    CX
        PUSH    SI
        XOR     CX,CX
        CLD
EFE_FIND_END:
        INC     CX
        LODSB
        OR      AL,AL
        JNZ     EFE_FIND_END
        DEC     CX
        STD
        DEC     SI
        DEC     SI
EFE_FIND_DOT:
        LODSB
        CMP     AL,'.'
        JE      EFE_FOUND_DOT
        CMP     AL,'\'
        JE      EFE_NO_EXT
        LOOP    EFE_FIND_DOT
EFE_NO_EXT:
        POP     SI
        STC
        JMP     Short EFE_DONE
EFE_FOUND_DOT:
        INC     SI
        INC     SI
        POP     CX
        CLC
EFE_DONE:
        CLD
        POP     CX
        POP     AX
        RET
EXTRACT_FILE_EXT        ENDP

;***********************************************************************

REPLACE_FILE_EXT        PROC
        PUSH    SI
        PUSH    DI
        CMP     BYTE PTR[DI],00H
        JE      RFE_DONE
        CALL    EXTRACT_FILE_EXT
        JC      RFE_APPEND_DOT
RFE_REPLACE:
        XCHG    SI,DI
        CALL    STR_COPY
        JMP     Short RFE_DONE
RFE_APPEND_DOT:
        CALL    STR_FIND_END
        MOV     BYTE PTR[SI],'.'
        INC     SI
        JMP     Short RFE_REPLACE
RFE_DONE:
        POP     DI
        POP     SI
        RET
REPLACE_FILE_EXT        ENDP

;***********************************************************************

FIND_FNAME_POS  PROC
        PUSH    AX
        PUSH    BX
        MOV     BX,SI
        CLD
FIND_POS:
        LODSB
        OR      AL,AL
        JZ      FOUND_POS
        CMP     AL,'\'
        JE      SET_FNAME_POS
        CMP     AL,':'
        JNE     FIND_POS
SET_FNAME_POS:
        MOV     BX,SI
        JMP     Short FIND_POS
FOUND_POS:
        MOV     SI,BX
        POP     BX
        POP     AX
        RET
FIND_FNAME_POS  ENDP

;***********************************************************************

REPLACE_FILE_NAME       PROC
        PUSH    AX
        PUSH    SI
        PUSH    DI
        PUSH    ES
        PUSH    DS
        POP     ES
        CALL    FIND_FNAME_POS
        XCHG    SI,DI
        CLD
RFN_REPLACE:
        LODSB
        STOSB
        OR      AL,AL
        JNZ     RFN_REPLACE
        POP     ES
        POP     DI
        POP     SI
        POP     AX
        RET
REPLACE_FILE_NAME       ENDP

;***********************************************************************
NEW_FIND_FILE_FLAG              DB              ?

START_FIND_FILE PROC
        PUSH    AX
        PUSH    DX
        MOV     AH,1AH
        LEA     DX,DTA
        INT     21H
        MOV     NEW_FIND_FILE_FLAG,1
        POP     DX
        POP     AX
        RET
START_FIND_FILE ENDP

;***********************************************************************
FIND_FILE_ERROR_CODE            DB              ?

FIND_FILE       PROC
        PUSH    DI
        PUSH    AX
        CMP     NEW_FIND_FILE_FLAG,1
        JE      FF_START_NEW
        CALL    FIND_NEXT_FILE
        JC      FF_NO_MORE_FILES
FF_ADD_FNAME:
        POP     DI
        LEA     DI,DTA
        MOV     AL,[DI+21]
        ADD     DI,30
        XCHG    SI,DX
        CALL    REPLACE_FILE_NAME
        XCHG    SI,DX
        CLC
        JMP     Short FF_DONE
        ;-----------------------------------
FF_START_NEW:
        MOV     NEW_FIND_FILE_FLAG,0
        PUSH    CX
        MOV     CX,0037H
        CALL    FIND_FIRST_FILE
        POP     CX
        JNC     FF_ADD_FNAME
        ;-----------------------------------
FF_NO_MORE_FILES:
        MOV     FIND_FILE_ERROR_CODE,AL
        POP     AX
        ;CF=1
FF_DONE:
        POP     DI
        RET
FIND_FILE       ENDP

;***********************************************************************
EXECUTABLE_EXTS         LABEL           BYTE
COM_EXT         DB      'COM',00H
EXE_EXT         DB      'EXE',00H
BAT_EXT         DB      'BAT',00H

FIND_EXECUTABLE_FILE    PROC
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        XCHG    AH,CL
        MOV     AH,'?'
        CALL    STR_FIND_CHAR
        JNC     FEF_BAD_FNAME
        MOV     AH,'*'
        CALL    STR_FIND_CHAR
        JNC     FEF_BAD_FNAME
        MOV     AH,CL
        MOV     DX,SI
        XOR     CX,CX
        LEA     DI,EXECUTABLE_EXTS
        CALL    EXTRACT_FILE_EXT
        JC      FEF_TRY_EXT
FEF_CHECK_EXT:
        CALL    COMP_STRS
        JNC     FEF_EXT_OK
        ADD     DI,4
        INC     CX
        CMP     CL,3
        JB      FEF_CHECK_EXT
        JMP     Short FEF_ERROR
FEF_EXT_OK:
        CALL    START_FIND_FILE
        CALL    FIND_FILE
        JC      FEF_ERROR
FEF_FOUND_EX_FILE:
        MOV     AH,CL
        JMP     Short FEF_SUCCESS
        ;-----------------------------------
FEF_TRY_EXT:
        CALL    REPLACE_FILE_EXT
        CALL    START_FIND_FILE
        CALL    FIND_FILE
        JNC     FEF_FOUND_EX_FILE
        CMP     FIND_FILE_ERROR_CODE,ERR_FAIL24H
        JE      FEF_ERROR
        ADD     DI,4
        INC     CX
        CMP     CL,3
        JB      FEF_TRY_EXT
        ;-----------------------------------
FEF_ERROR:
        MOV     AL,FIND_FILE_ERROR_CODE
        JMP     Short FEF_FAILURE
FEF_BAD_FNAME:
        MOV     AH,CL
        MOV     AL,ERR_FNFOUND
FEF_FAILURE:
        STC
        JMP     Short FEF_DONE
FEF_SUCCESS:
        CLC
FEF_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        RET
FIND_EXECUTABLE_FILE    ENDP

;***********************************************************************
RSVD_HDL_CON            DB              'CON',00H
RSVD_HDL_AUX            DB              'AUX',00H
RSVD_HDL_PRN            DB              'PRN',00H

RESET_RESERVED_HDLS     PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        ;-----------------------------------
        ;Close the five standard handles
        MOV     CX,4
CLOSE_LOOP:
        MOV     BX,CX
        CALL    CLOSE_FILE
        LOOP    CLOSE_LOOP
        DEC     BX      ;BX=0
        CALL    CLOSE_FILE
        ;-----------------------------------
        ;Reopen the first three standard handles
        LEA     DX,RSVD_HDL_CON
        MOV     AL,02H
        CALL    OPEN_FILE
        MOV     AL,02H
        CALL    OPEN_FILE
        MOV     AL,02H
        CALL    OPEN_FILE
        ;-----------------------------------
        ;Reopen AUX and PRN standard handles
        LEA     DX,RSVD_HDL_AUX
        MOV     AL,02H
        CALL    OPEN_FILE
        LEA     DX,RSVD_HDL_PRN
        MOV     AL,02H
        CALL    OPEN_FILE
        ;-----------------------------------
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
RESET_RESERVED_HDLS     ENDP

;***********************************************************************

CURSOR_UP       PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AH,0FH
        INT     10H
        MOV     AH,03H
        INT     10H
        OR      DH,DH
        JZ      CURSOR_UP_DONE
        MOV     AH,02H
        DEC     DH
        INT     10H
CURSOR_UP_DONE:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CURSOR_UP       ENDP

;***********************************************************************

BUILD_CURRENT_PATH      PROC
        PUSH    AX
        PUSH    DX
        PUSH    SI
        LEA     SI,CURRENT_PATH
        MOV     AH,19H
        INT     21H
        MOV     DL,AL
        INC     DL
        ADD     AL,'A'
        MOV     BYTE PTR[SI],AL
        MOV     WORD PTR[SI+1],'\:'
        MOV     AH,47H
        ADD     SI,3
        INT     21H
        POP     SI
        POP     DX
        POP     AX
        RET
BUILD_CURRENT_PATH      ENDP

;***********************************************************************
MINIMAN_PATH    DB      'MINIMAN.COM',00H

OPEN_MINIMAN    PROC
;INPUT: NONE
;OUTPUT:CF=0=> AX=File handle
;       CF=1=> AX=System error code
        PUSH    DX
        LEA     DX,MINIMAN_PATH
        MOV     AX,3D00H        ;Open in read-only mode
        INT     21H
        JC      OM_DONE
OM_DONE:
        POP     DX
        RET
OPEN_MINIMAN    ENDP

;***********************************************************************

VALIDATE_MINIMAN_FILE_VER       PROC
;INPUT:  BX=File handle
;        File pointer should be at the beginning of file.
;OUTPUT: CF=0=> File version is valid.
;        CF=1=> Invalid file version
        PUSH    AX
        PUSH    CX
        PUSH    DX
        LEA     DX,WORD_1
        MOV     CX,2
        CALL    READ_FILE
        DEC     CX
        CALL    READ_FILE
        INC     CX
        CALL    READ_FILE
        XOR     CX,CX
        XOR     DX,DX
        MOV     AX,4200H
        INT     21H
        CMP     WORD_1,MINIMAN_FILE_VER         ;If WORD_1=MINIMAN_FILE_VER carry flag is cleared.
        JE      MINIMAN_VER_DONE
        STC
MINIMAN_VER_DONE:
        POP     DX
        POP     CX
        POP     AX
        RET
VALIDATE_MINIMAN_FILE_VER       ENDP

;***********************************************************************

CHECK_MINIMAN_INSTALLATION      PROC
        PUSH    AX
        PUSH    CX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
        MOV     AH,INTSTALLATION_FUNC_NO
        XOR     AL,AL
        MOV     SI,0FFFFH
        INT     2FH
        CMP     AL,0FFH
        JNE     NOT_INSTALLED
        PUSH    CS
        POP     ES
        LEA     DI,MINIMAN_ID_STR
        MOV     CX,MINIMAN_ID_STR_LEN
  REPE  CMPSB
        OR      CX,CX
        JNZ     NOT_INSTALLED
        ;So MINIMAN.COM is already installed in memory.
        CLC
        JMP     Short CMI_DONE
NOT_INSTALLED:
        STC
CMI_DONE:
        POP     ES
        POP     DS
        POP     DI
        POP     SI
        POP     CX
        POP     AX
        RET
CHECK_MINIMAN_INSTALLATION      ENDP

;***********************************************************************
PROMPT_STRING           DB              'PROMPT',00H

WRITE_PROMPT    PROC
        CMP     ECHO_STATUS,1
        JE      WRT_PRPT_ECHO_ON
        JMP     WRT_PRPT_RETUEN
WRT_PRPT_ECHO_ON:
        PUSH    AX
        PUSH    BX
        PUSH    DX
        PUSH    SI
        MOV     BX,DS   ;BX holds the input DS
        LEA     SI,PROMPT_STRING
        CALL    GET_ENV_VAR
        JC      DEFAULT_PROMPT
        MOV     SI,DX
        MOV     AH,'='
        CALL    STR_FIND_CHAR
        INC     SI
        PUSH    DS
        JMP     Short WRT_LOOP
DEFAULT_PROMPT:
        MOV     DL,BYTE PTR CURRENT_PATH[0]
        CALL    WRITE_CHAR
        MOV     DL,'>'
        CALL    WRITE_CHAR
        JMP     WRT_PRPT_DONE
WRT_LOOP:
        CLD
        POP     DS
        LODSB
        PUSH    DS
        CMP     AL,00H
        JE      WRT_PRPT_DONE
        CMP     AL,'$'
        JE      CTRL_CHAR
        MOV     DL,AL
        CALL    WRITE_CHAR
        JMP     Short WRT_LOOP
CTRL_CHAR:
        CLD
        POP     DS
        LODSB
        PUSH    DS
        MOV     DS,BX
        CALL    UPPER_CASE
        CMP     AL,00H
        JE      WRT_PRPT_DONE
        CMP     AL,'P'
        JE      WRT_PATH
        CMP     AL,'N'
        JE      WRT_DRIVE
        CMP     AL,'L'
        JE      WRT_L
        CMP     AL,'G'
        JE      WRT_G
        CMP     AL,'B'
        JE      WRT_B
        CMP     AL,'_'
        JE      WRT_CRLF
        CMP     AL,'$'
        JE      WRT_DOLLAR
        CMP     AL,'Q'
        JE      WRT_Q
        CMP     AL,'D'
        JE      WRT_D
        CMP     AL,'T'
        JE      WRT_T
        CMP     AL,'E'
        JE      WRT_E
        CMP     AL,'H'
        JE      WRT_H
        CMP     AL,'/'
        JE      WRT_SLASH
        CMP     AL,'S'
        JE      WRT_SPACE
        CMP     AL,'C'
        JE      WRT_LPARENTHESIS
        CMP     AL,'F'
        JE      WRT_RPARENTHESIS
        JMP     Short WRT_LOOP
WRT_PATH:
        LEA     DX,CURRENT_PATH
        CALL    WRITE_ASCIIZ
        JMP     Short WRT_LOOP
WRT_DRIVE:
        MOV     DL,BYTE PTR CURRENT_PATH[0]
        CALL    WRITE_CHAR
        JMP     Short WRT_LOOP
WRT_L:
        MOV     DL,'<'
        JMP     Short WRT_CH
WRT_G:
        MOV     DL,'>'
        JMP     Short WRT_CH
WRT_B:
        MOV     DL,'|'
        JMP     Short WRT_CH
WRT_CRLF:
        CALL    NEW_LINE
        JMP     WRT_LOOP
WRT_DOLLAR:
        MOV     DL,'$'
        JMP     Short WRT_CH
WRT_Q:
        MOV     DL,'='
        JMP     Short WRT_CH
WRT_D:
        CALL    WRITE_CURRENT_DATE
        JMP     WRT_LOOP
WRT_T:
        CALL    WRITE_CURRENT_TIME
        JMP     WRT_LOOP
WRT_E:
        MOV     DL,ESCAPE
        JMP     Short WRT_CH
WRT_H:
        MOV     DL,BS
        JMP     Short WRT_CH
WRT_SLASH:
        MOV     DL,'/'
        JMP     Short WRT_CH
WRT_SPACE:
        MOV     DL,' '
        JMP     Short WRT_CH
WRT_LPARENTHESIS:
        MOV     DL,'('
        JMP     Short WRT_CH
WRT_RPARENTHESIS:
        MOV     DL,')'
WRT_CH:
        CALL    WRITE_CHAR
        JMP     WRT_LOOP
WRT_PRPT_DONE:
        MOV     DS,BX
        POP     SI
        POP     SI
        POP     DX
        POP     BX
        POP     AX
WRT_PRPT_RETUEN:
        RET
WRITE_PROMPT    ENDP

;***********************************************************************
MEM_MSG1        DB      ' Total Memory(KB): $'
MEM_MSG2        DB      0AH,0DH,' Total free memory for programs: $'
MEM_MSG3        DB      ' KB$'
MEM_MSG4        DB      0AH,0DH,' Maximum executable program size: $'
MEM_MSG5        DB      ' Upper memory is $'
MEM_MSG6        DB      'not $'
MEM_MSG7        DB      'available.$'

CMD_MEM         PROC
        PUSHALL
        LEA     DI,MEM_?_STR
        CALL    HELP_SWITCH
        JNC     MEM_DONE
        STC
        CALL    CHECK_OS
        JC      MEM_DONE
        ;-----------------------------------
        MOV     AH,05H
        INT     32H
        JC      MEM_ERR
        ;-----------------------------------
        LEA     DX,MEM_MSG1
        CALL    WRITE_STRING
        INT     12H
        MOV     DX,AX
        CALL    WRITE_DECIMAL
        MOV     AH,05H
        INT     32H
        LEA     DX,MEM_MSG2
        CALL    WRITE_STRING
        MOV     DI,CX
        MOV     CL,6
        SHR     AX,CL
        MOV     DX,AX
        CALL    WRITE_DECIMAL
        LEA     DX,MEM_MSG3
        CALL    WRITE_STRING
        LEA     DX,MEM_MSG4
        CALL    WRITE_STRING
        MOV     DX,BX
        MOV     CL,6
        SHR     DX,CL
        CALL    WRITE_DECIMAL
        LEA     DX,MEM_MSG3
        CALL    WRITE_STRING
        CALL    NEW_LINE
        MOV     CX,DI
        LEA     DX,MEM_MSG5
        CALL    WRITE_STRING
        LEA     DX,MEM_MSG6
        OR      CL,CL
        JNZ     MEM_MSG_DONE
        CALL    WRITE_STRING
MEM_MSG_DONE:
        LEA     DX,MEM_MSG7
        CALL    WRITE_STRING
        JMP     Short MEM_DONE_1
        ;-----------------------------------
MEM_ERR:
        CALL    WRITE_ERROR_MESSAGE
MEM_DONE_1:
        CALL    NEW_LINE
MEM_DONE:
        POPALL
        RET
CMD_MEM         ENDP

;***************************************************************

CMD_LED         PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    ES
        ;-----------------------------------
        LEA     DI,LED_?_STR
        CALL    HELP_SWITCH
        JNC     LED_DONE
        MOV     DX,250
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      LED_DEFAULT_COUNT
        LEA     SI,CMD_PARAM
        CMP     BYTE PTR[SI],'/'
        JNE     LED_DEFAULT_COUNT
        INC     SI
        MOV     CX,SI
        MOV     AH,','
        CALL    STR_FIND_CHAR
        JC      LED_GET_COUNT
        MOV     BYTE PTR[SI],00H
        INC     SI
        CALL    STR_TO_NUM_16
        JC      LED_GET_COUNT
        MOV     DX,AX
        SHR     DX,1
LED_GET_COUNT:
        MOV     SI,CX
        CALL    STR_TO_NUM_16
        JC      LED_DEFAULT_COUNT
        MOV     CX,AX
        JMP     Short LED_START
LED_DEFAULT_COUNT:
        MOV     CX,6
        ;-----------------------------------
LED_START:
        JCXZ    LED_ONLY_PAUSE
        MOV     AX,0040H
        MOV     ES,AX
        MOV     SI,17H
        MOV     BL,ES:[SI]
LED_LOOP:
        AND     ES:BYTE PTR [SI],8FH
        MOV     AH,01H
        INT     16H
        MOV     AX,DX
        CALL    WAIT_MILI
        OR      ES:BYTE PTR [SI],70H
        MOV     AH,01H
        INT     16H
        MOV     AX,DX
        CALL    WAIT_MILI
        LOOP    LED_LOOP
        AND     BL,0F0H
        MOV     ES:[SI],BL
        JMP     Short LED_DONE
        ;-----------------------------------
LED_ONLY_PAUSE:
        MOV     AX,DX
        CALL    WAIT_MILI
        ;-----------------------------------
LED_DONE:
        POP     ES
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CMD_LED         ENDP

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
WRITE_DIGIT_LOOP:
        POP     DX
        ADD     DL,'0'
        CALL    WRITE_CHAR
        LOOP    WRITE_DIGIT_LOOP
END_DECIMAl:
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
WRITE_DECIMAL   ENDP

;***************************************************************************

NEW_LINE        PROC
        PUSH    DX
        MOV     DL,0DH
        CALL    WRITE_CHAR
        MOV     DL,0AH
        CALL    WRITE_CHAR
        POP     DX
        RET
NEW_LINE        ENDP

;***************************************************************************

STR_TO_UPPER    PROC
;INPUT: BX=Pointer to an ASCIIZ string to be converted to upper case
        PUSH    BX
        JMP     Short CONV_FIRST
CONV_NEXT_CHAR:
        INC     BX
CONV_FIRST:
        CMP     BYTE PTR [BX],0
        JE      END_UPPER
        CMP     BYTE PTR [BX],'a'
        JB      CONV_NEXT_CHAR
        CMP     BYTE PTR [BX],'z'
        JA      CONV_NEXT_CHAR
        SUB     BYTE PTR[BX],'a'-'A'
        JMP     SHORT CONV_NEXT_CHAR
END_UPPER:
        POP     BX
        RET
STR_TO_UPPER    ENDP

;***********************************************************************

COMP_STRS       PROC
        PUSH    AX
        PUSH    BX
        XOR     BX,BX
COMP_LOOP:
        MOV     AL,[SI+BX]
        CMP     [DI+BX],AL
        JNE     COMP_SETCF
        CMP     AL,00H
        JE      COMP_CLCF
        INC     BX
        JMP     Short COMP_LOOP
COMP_CLCF:
        CLC
        JMP     Short COMPS_DONE
COMP_SETCF:
        STC
COMPS_DONE:
        POP     BX
        POP     AX
        RET
COMP_STRS       ENDP

;***********************************************************************

COMP_STRS_SPEC  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSHF
        MOV     CL,AL
        XOR     BX,BX
CSS_LOOP:
        MOV     AL,[SI+BX]
        MOV     AH,ES:[DI+BX]
        CMP     AL,AH
        JNE     CSS_CHECK_CASE
CSS_CHECK_END:
        CMP     CL,[SI+BX]
        JE      CSS_CHECK_END_2
        CMP     CL,ES:[DI+BX]
        JE      CSS_FAILURE
        INC     BX
        JMP     Short CSS_LOOP
CSS_CHECK_END_2:
        CMP     CL,ES:[DI+BX]
        JNE     CSS_FAILURE
        ;-----------------------------------
        POPF
        CLC
        JMP     Short CSS_DONE
        ;-----------------------------------
CSS_CHECK_CASE:
        POPF
        PUSHF
        JC      CSS_FAILURE
        CALL    UPPER_CASE
        XCHG    AL,AH
        CALL    UPPER_CASE
        CMP     AL,AH
        JE      CSS_CHECK_END
        ;-----------------------------------
CSS_FAILURE:
        POPF
        STC
CSS_DONE:
        POP     CX
        POP     BX
        POP     AX
        RET
COMP_STRS_SPEC  ENDP

;***********************************************************************

STR_LENGTH      PROC
        PUSH    CX
        PUSH    SI
        XOR     CX,CX
        CLD
SLEN_LOOP:
        LODSB
        CMP     AL,00H
        JE      SLEN_DONE
        INC     CX
        JMP     Short SLEN_LOOP
SLEN_DONE:
        MOV     AX,CX
        POP     SI
        POP     CX
        RET
STR_LENGTH      ENDP

;***********************************************************************

STR_COPY        PROC
        PUSH    SI
        PUSH    DI
        PUSH    AX
        CLD
SCPY_LOOP:
        LODSB
        STOSB
        CMP     AL,00H
        JNE     SCPY_LOOP
        POP     AX
        POP     DI
        POP     SI
        RET
STR_COPY        ENDP

;***********************************************************************

GET_CMD_PARAM   PROC
        PUSH    AX
        PUSH    SI
        PUSH    DI
        LEA     SI,CMD_STR
        CALL    STR_LOCATE_WORD
        JC      PARAM_DONE
        LEA     DI,CMD_PARAM
GET_PARAM:
        ;DF=0
        LODSB
        CMP     AL,' '
        JE      GOT_PARAM
        CMP     AL,00H
        JE      GOT_PARAM
        STOSB
        JMP     Short GET_PARAM
GOT_PARAM:
        XOR     AL,AL
        STOSB
        CLC
PARAM_DONE:
        POP     DI
        POP     SI
        POP     AX
        RET
GET_CMD_PARAM   ENDP

;***********************************************************************
HELP_SYNTAX_STR                 DB              'Syntax: $'

HELP_SWITCH     PROC
        PUSH    CX
        PUSH    SI
        LEA     SI,CMD_PARAM
        XOR     CX,CX
SWITCH_?:
        INC     CX
        CALL    GET_CMD_PARAM
        JC      NO_?_SWITCH
        CMP     WORD PTR[SI],'?/'
        JNE     SWITCH_?
        CMP     BYTE PTR[SI+2],00H
        JNE     SWITCH_?
        PUSH    DX
        MOV     SI,DI
WRITE_HELP:
        MOV     DL,[SI]
        INC     SI
        CMP     DL,00H
        JE      HELP_DONE
        CMP     DL,LF           ;LF=Line Feed
        JE      HELP_TEXT_NEW_LINE
        CMP     DL,01H
        JE      HELP_WRITE_SYNTAX
        CALL    WRITE_CHAR
        JMP     Short WRITE_HELP
HELP_TEXT_NEW_LINE:
        CALL    NEW_LINE
        JMP     Short WRITE_HELP
HELP_WRITE_SYNTAX:
        LEA     DX,HELP_SYNTAX_STR
        CALL    WRITE_STRING
        JMP     Short WRITE_HELP
HELP_DONE:
        POP     DX
        CALL    NEW_LINE
        CLC
        JMP     Short HS_DONE
NO_?_SWITCH:
        STC
HS_DONE:
        POP     SI
        POP     CX
        RET
HELP_SWITCH     ENDP

;***********************************************************************

WRITE_HEX_DIGIT         PROC
        PUSH    DX
        CMP     DL,10
        JAE     LETTER_DIGIT
        ADD     DL,'0'
        JMP     Short WRITE_DIGIT
LETTER_DIGIT:
        ADD     DL,'A'-10
WRITE_DIGIT:
        CALL    WRITE_CHAR
        POP     DX
        RET
WRITE_HEX_DIGIT         ENDP

;***********************************************************************

STR_LTRIM       PROC
        PUSH    AX
        PUSH    DI
        MOV     DI,SI
        CLD
SKIP_LEFT_SPACES:
        LODSB
        CMP     AL,' '
        JE      SKIP_LEFT_SPACES
        DEC     SI
        CMP     SI,DI
        JE      LTRIM_DONE
        PUSH    ES
        MOV     AX,DS
        MOV     ES,AX
        CALL    STR_COPY
        POP     ES
LTRIM_DONE:
        MOV     SI,DI
        POP     DI
        POP     AX
        RET
STR_LTRIM       ENDP

;***********************************************************************

STR_RTRIM       PROC
        CMP     BYTE PTR[SI],00H
        JE      RTRIM_RETURN
        PUSH    AX
        PUSH    BX
        MOV     BX,SI
        CALL    STR_FIND_END
        DEC     SI
        STD
FIND_TRIM_POS:
        LODSB
        CMP     AL,' '
        JNE     TRIM_RIGHT
        CMP     SI,BX
        JAE     FIND_TRIM_POS
        DEC     SI
TRIM_RIGHT:
        INC     SI
        INC     SI
        MOV     BYTE PTR[SI],00H
        MOV     SI,BX
        POP     BX
        POP     AX
        CLD
RTRIM_RETURN:
        RET
STR_RTRIM       ENDP

;***********************************************************************

STR_TRIM        PROC
        CALL    STR_LTRIM
        CALL    STR_RTRIM
        RET
STR_TRIM        ENDP

;***********************************************************************

STR_SHIFT_RIGHT PROC
;INPUT: SI=Pointer to the beginning of an ASCIIZ string
;       AL=Number of shifts
        PUSH    CX
        PUSH    DI
        PUSH    SI
        PUSH    AX
        CALL    STR_LENGTH
        MOV     CX,AX
        ADD     SI,CX
        INC     CX
        MOV     DI,SI
        POP     AX
        PUSH    AX
        XOR     AH,AH
        ADD     DI,AX
        STD
  REP   MOVSB
        MOV     CX,AX
        MOV     AL,' '
  REP   STOSB
        CLD
        POP     AX
        POP     SI
        POP     DI
        POP     CX
        RET
STR_SHIFT_RIGHT ENDP

;***********************************************************************

STR_SHIFT_LEFT  PROC
;INPUT: SI=Pointer to the beginning of a ASCIIZ string
;       AL=Number of shifts
        PUSH    AX
        PUSH    CX
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    SI
        PUSH    DI
        MOV     DI,SI
        MOV     CL,AL
        XOR     CH,CH
        ADD     SI,CX
        CLD
SSL_SHIFT:
        LODSB
        STOSB
        CMP     AL,00H
        JNE     SSL_SHIFT
        POP     DI
        POP     SI
        POP     ES
        POP     CX
        POP     AX
        RET
STR_SHIFT_LEFT  ENDP

;***********************************************************************
WAIT_KEY        PROC
;INPUT:  AL=Key code to wait for
;           AL=00H:wait for any key(don't purge input buffer)
;           AL>00H:purge input buffer and wait for the specified key(in AL)
;OUTPUT: NONE
        PUSH    AX
        PUSH    BX
        MOV     BL,AL
WK_LOOP:
        OR      BL,BL
        JZ      WK_DONT_PURGE
        MOV     AX,0C08H
        JMP     Short WK_INPUT_BUF_DONE
WK_DONT_PURGE:
        MOV     AH,08H
WK_INPUT_BUF_DONE:
        INT     21H
        OR      BL,BL
        JZ      WK_DONE
        CMP     AL,BL
        JNE     WK_LOOP
WK_DONE:
        POP     BX
        POP     AX
        RET
WAIT_KEY        ENDP

;***********************************************************************
DEVICE_DRIVER_ERROR_TABLE       LABEL           BYTE
        DB              00H
                DB      'Write protect error',00H
        DB              02H
                DB      'Drive not ready',00H
        DB              04H
                DB      'Data error',00H
        DB              06H
                DB      'Seek error',00H
        DB              08H
                DB      'Sector not found',00H
        DB              0AH
                DB      'Write fault',00H
        DB              0BH
                DB      'Read fault',00H
        DB              0FH
                DB      'Invalid disk change',00H
        DB              0FFH
                DB      'General failure',00H

WRITE_DEV_ERR_MSG       PROC
;INPUT: DI(low byte)=Device driver error code
        PUSH    AX
        PUSH    DX
        PUSH    SI
        LEA     SI,DEVICE_DRIVER_ERROR_TABLE
        MOV     AX,DI
        MOV     AH,AL
DEV_ERR_LOOP:
        LODSB
        CMP     AL,AH
        JE      FOUND_DEV_ERR
        CMP     AL,0FFH
        JNE     DEV_ERR_LOOP
FOUND_DEV_ERR:
        MOV     DX,SI
        CALL    WRITE_ASCIIZ
        POP     SI
        POP     DX
        POP     AX
        RET
WRITE_DEV_ERR_MSG       ENDP
;***********************************************************************

WRITE_ASCIIZ_NO_BREAK   PROC
;INPUT:  DS:DX=Points to an ASCIIZ string to write to stdout with no Ctrl-Break checking
;OUTPUT: NONE
        PUSH    AX
        PUSH    DX
        PUSH    SI
        MOV     SI,DX
        MOV     AH,06H
        CLD
NO_BREAK_LOOP:
        LODSB
        CMP     AL,00H
        JE      WRITE_NO_BREAK_DONE
        CMP     AL,0FFH
        JE      NO_BREAK_LOOP
        MOV     DL,AL
        INT     21H
        JMP     Short NO_BREAK_LOOP
WRITE_NO_BREAK_DONE:
        POP     SI
        POP     DX
        POP     AX
        RET
WRITE_ASCIIZ_NO_BREAK   ENDP

;***********************************************************************
CTRL_C_STR              DB              CR,LF,'^C',CR,LF,00H
CTRL_C_FLAG             DB              0       ;0=Ctrl-Break has been detected
                                                ;1=No Ctrl-Break has been detected

INT_23H_HANDLER PROC    FAR
        CMP     CS:MINIMAN_ACTIVE,0
        JE      TERMINATE_23H
        MOV     CS:CTRL_C_FLAG,1
        IRET
TERMINATE_23H:
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    DX
        LEA     DX,CTRL_C_STR
        CALL    WRITE_ASCIIZ_NO_BREAK
        POP     DX
        POP     DS
        STC
        RETF
INT_23H_HANDLER ENDP

;***********************************************************************
INT_24H_MSG_2   DB      ' reading ',00H
INT_24H_MSG_3   DB      ' writing ',00H
INT_24H_MSG_4   DB      'drive ',00H
INT_24H_MSG_5   DB      CR,LF,'<R>etry, <F>ail?',00H

INT_24H_HANDLER PROC    FAR
;INT 24H: Critical Error Handler
        PUSH    BX
        PUSH    DX
        PUSH    DS
        PUSH    CS
        POP     DS
        CALL    NEW_LINE
        CALL    WRITE_DEV_ERR_MSG
        LEA     DX,INT_24H_MSG_2
        TEST    AH,01H
        JZ      WRITE_OPERATION_TYPE
        LEA     DX,INT_24H_MSG_3
WRITE_OPERATION_TYPE:
        CALL    WRITE_ASCIIZ
        LEA     DX,INT_24H_MSG_4
        CALL    WRITE_ASCIIZ
        MOV     BX,AX
        ADD     AL,'A'
        MOV     DL,AL
        CALL    WRITE_CHAR
INT_24H_LOOP:
        LEA     DX,INT_24H_MSG_5
        CALL    WRITE_ASCIIZ
        MOV     AX,0C07H        ;Clear input buffer and then input
        INT     21H
        CMP     AL,0DH
        JE      INT_24H_LOOP
        CMP     AL,TAB
        JE      INT_24H_LOOP
        CMP     AL,BS
        JE      INT_24H_LOOP
        CMP     AL,00H
        JNE     INT_24H_CHECK_KEY
        INT     21H             ;Read extended ASCII key code
        JMP     Short INT_24H_LOOP
INT_24H_CHECK_KEY:
        MOV     DL,AL
        CALL    WRITE_CHAR
        CALL    UPPER_CASE
        CMP     AL,'R'
        JE      INT_24H_RETRY
        CMP     AL,'F'
        JNE     INT_24H_LOOP
        ;Fail
        MOV     BL,3
        JMP     Short INT_24H_DONE
INT_24H_RETRY:
        ;Retry
        MOV     BL,1
INT_24H_DONE:
        CALL    NEW_LINE
        MOV     AX,BX
        POP     DS
        POP     DX
        POP     BX
        IRET
INT_24H_HANDLER ENDP

;***********************************************************************
INTSTALLATION_FUNC_NO           EQU             0DFH
MINIMAN_ID_STR_LEN              EQU             8
OLD_INT_2FH_HANDLER             DD              ?
MINIMAN_ID_STR                  DB              '$MiniMan'

INT_2FH_HANDLER PROC    FAR
        PUSHF
        CMP     AH,INTSTALLATION_FUNC_NO
        JNE     CALL_OLD_INT_2FH_HANDLER
        POPF
        CMP     AL,01H
        JE      INT_2FH_GET_PSP
        OR      AL,AL
        JNZ     CALL_OLD_INT_2FH_HANDLER
        MOV     AL,0FFH
        PUSH    CS
        POP     DS
        LEA     SI,MINIMAN_ID_STR
        JMP     Short INT_2FH_DONE
INT_2FH_GET_PSP:
        PUSH    CS
        POP     AX
INT_2FH_DONE:
        IRET
CALL_OLD_INT_2FH_HANDLER:
        POPF
        JMP     CS:DWORD PTR OLD_INT_2FH_HANDLER
INT_2FH_HANDLER ENDP


;***********************************************************************

CMD_CD  PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        LEA     DI,CD_?_STR
        CALL    HELP_SWITCH
        JNC     CD_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     CD_PARAMERR
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      CD_DISP_CURRENT_PATH
        LEA     DX,CMD_PARAM
        MOV     AH,3BH
        INT     21H
        JC      CD_WRTERRMSG
        JMP     Short CD_DONE
CD_DISP_CURRENT_PATH:
        LEA     DX,CURRENT_PATH
        CALL    WRITE_ASCIIZ
        JMP     Short CD_DONE
CD_PARAMERR:
        MOV     AL,ERR_ICLPARAMETERS
CD_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
CD_DONE:
        POP     DI
        POP     DX
        POP     CX
        POP     AX
        RET
CMD_CD  ENDP

;***********************************************************************

CMD_MD  PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        LEA     DI,MD_?_STR
        CALL    HELP_SWITCH
        JNC     MD_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     MD_PARAMERR
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      MD_PARAMERR
        LEA     DX,CMD_PARAM
        MOV     AH,39H
        INT     21H
        JC      MD_WRTERRMSG
        JMP     Short MD_DONE
MD_PARAMERR:
        MOV     AL,ERR_ICLPARAMETERS
MD_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
MD_DONE:
        POP     DI
        POP     DX
        POP     CX
        POP     AX
        RET
CMD_MD  ENDP

;***********************************************************************

CMD_RD  PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        LEA     DI,RD_?_STR
        CALL    HELP_SWITCH
        JNC     RD_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     RD_PARAMERR
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      RD_PARAMERR
        LEA     DX,CMD_PARAM
        MOV     AH,3AH
        INT     21H
        JC      RD_WRTERRMSG
        JMP     Short RD_DONE
RD_PARAMERR:
        MOV     AL,ERR_ICLPARAMETERS
RD_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
RD_DONE:
        POP     DI
        POP     DX
        POP     CX
        POP     AX
        RET
CMD_RD  ENDP

;***********************************************************************
PATH_STRING             DB              'PATH=',00H

CMD_SET PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        LEA     DI,SET_?_STR
        CALL    HELP_SWITCH
        JNC     SET_DONE
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      SET_SHOW_ALL

        LEA     SI,CMD_LINE_BUF
        MOV     AH,' '          ;ASCII code 32
        CALL    STR_FIND_CHAR
        CALL    STR_LTRIM
        MOV     AH,'='
        MOV     CX,SI
        CALL    STR_FIND_CHAR
        JC      SET_SHOW_SPEC_VAR

        INC     SI
        CMP     BYTE PTR[SI],00H
        JE      SET_REMOVE_VAR
SET_CHECK_SYNTAX:
        CALL    STR_FIND_CHAR
        JNC     SET_SYNTAX_ERR
        DEC     SI
        MOV     BYTE PTR[SI],00H
        XCHG    CX,BX
        CALL    STR_TO_UPPER
        XCHG    CX,BX
        MOV     BYTE PTR[SI],'='
        MOV     SI,CX
        CALL    SET_ENV_VAR
        JNC     SET_DONE
        MOV     AL,ERR_NEESPACE
        JMP     Short SET_WRTERRMSG
        ;-----------------------------------
SET_SHOW_SPEC_VAR:
        PUSH    DS
        CALL    GET_ENV_VAR
        JC      SET_VAR_NOT_FOUND
        CALL    WRITE_ASCIIZ
        POP     DS
        JMP     Short SET_DONE_2
SET_VAR_NOT_FOUND:
        POP     DS
        MOV     AL,ERR_EVNDEFINED
        JMP     Short SET_WRTERRMSG
        ;-----------------------------------
SET_SHOW_ALL:
        DEC     CX      ;CX=1
SET_LOOP:
        PUSH    DS
        CALL    GET_SEQ_ENV_VAR
        JC      SET_LOOP_DONE
        CALL    WRITE_ASCIIZ
        CALL    NEW_LINE
        POP     DS
        INC     CX
        JMP     Short SET_LOOP
SET_LOOP_DONE:
        POP     DS
        JMP     Short SET_DONE
        ;-----------------------------------
SET_REMOVE_VAR:
        ;SI=Pointer to the end of the input string
        ;Don't remove the "PATH" environment variable
        XCHG    SI,CX
        LEA     DI,PATH_STRING
        XCHG    BX,SI
        CALL    STR_TO_UPPER
        XCHG    BX,SI
        CALL    COMP_STRS
        XCHG    SI,CX
        JNC     SET_CHECK_SYNTAX
        MOV     BYTE PTR[SI-1],00H
        MOV     SI,CX
        CALL    REMOVE_ENV_VAR
        JMP     Short SET_DONE
        ;-----------------------------------
SET_SYNTAX_ERR:
        MOV     AL,ERR_SYNERROR
SET_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
SET_DONE_2:
        CALL    NEW_LINE
SET_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
CMD_SET ENDP

;***********************************************************************

CMD_PATH        PROC
        PUSHALL
        PUSH    ES
        LEA     DI,PATH_?_STR
        CALL    HELP_SWITCH
        JNC     PATH_DONE
        ;-----------------------------------
        PUSH    CS
        POP     ES
        LEA     DI,CMD_LINE_BUF
        MOV     AX,'ES'
        CLD
        STOSW
        MOV     AX,' T'
        STOSW
        LEA     SI,PATH_STRING
        CALL    STR_COPY
        MOV     SI,DI
        CALL    STR_FIND_END
        MOV     DI,SI
        ;-----------------------------------
        LEA     SI,CMD_PARAM
        MOV     CX,1
        CALL    GET_CMD_PARAM
        CMP     BYTE PTR[SI+4],';'
        JE      PATH_SM
        ;-----------------------------------
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      PATH_SHOW_PATH
        INC     CX
        INC     CX      ;CX=4
        CALL    GET_CMD_PARAM
        JNC     PATH_TOO_MANY_PARAMS
        DEC     CX      ;CX=3
        CALL    GET_CMD_PARAM
        JC      PATH_SET_PATH
        DEC     CX      ;CX=2
        CALL    GET_CMD_PARAM
        CMP     WORD PTR[SI],003DH      ;003DH='=',00H
        JNE     PATH_TOO_MANY_PARAMS
        INC     CX
        INC     CX      ;CX=4
        ;-----------------------------------
PATH_SET_PATH:
        DEC     CX
        CALL    GET_CMD_PARAM
        CMP     BYTE PTR[SI],';'
        JE      PATH_REMOVE
        CMP     BYTE PTR[SI],'='
        JNE     PATH_OK
        INC     SI
PATH_OK:
        CALL    STR_COPY
        JMP     Short PATH_SET_CMD
        ;-----------------------------------
PATH_SHOW_PATH:
        MOV     BYTE PTR[DI-1],00H
        MOV     SI,DI
        SUB     SI,5
        PUSH    DS
        CALL    GET_ENV_VAR
        POP     DS
        MOV     AL,ERR_NO_PATH
        JC      PATH_WRTERRMSG
        ;-----------------------------------
PATH_SET_CMD:
        CALL    CURSOR_UP
        CALL    PROCESS_COMMAND
        JMP     Short PATH_DONE
        ;-----------------------------------
PATH_SM:
        INC     CX
        CALL    GET_CMD_PARAM
        JNC     PATH_TOO_MANY_PARAMS
        ADD     SI,4
PATH_REMOVE:
        CMP     BYTE PTR[SI+1],00H
        JNE     PATH_TOO_MANY_PARAMS
        LEA     SI,PATH_STRING
        MOV     BYTE PTR[SI+4],00H
        CALL    REMOVE_ENV_VAR
        MOV     BYTE PTR[SI+4],'='
        JMP     Short PATH_DONE
        ;-----------------------------------
PATH_TOO_MANY_PARAMS:
        MOV     AL,ERR_TMPARAMETERS
PATH_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
        CALL    NEW_LINE
PATH_DONE:
        POP     ES
        POPALL
        RET
CMD_PATH        ENDP

;***********************************************************************
ON_STR          DB              'ON',00H
OFF_STR         DB              'OFF',00H

CHECK_ONOFF     PROC
;INPUT:  SI=Address of an ASCIIZ string to be checked
;OUTPUT: CF=0=> AL=1(ON) or AL=0(OFF)
;        CF=1=> The input string is not an 'ON' or 'OFF' string.
        PUSH    DI
        PUSH    AX
        MOV     AL,1
        LEA     DI,ON_STR
        CALL    COMP_STRS
        JNC     ONOFF_SUCCESS
        MOV     AL,0
        LEA     DI,OFF_STR
        CALL    COMP_STRS
        JNC     ONOFF_SUCCESS
        POP     AX
        STC
        JMP     Short ONOFF_DONE
ONOFF_SUCCESS:
        POP     DI
        CLC
ONOFF_DONE:
        POP     DI
        RET
CHECK_ONOFF     ENDP

;***********************************************************************

WRITE_ONOFF     PROC
        PUSH    DX
        LEA     DX,ON_STR
        CMP     AL,1
        JE      W_ONOFF_WRTMSG
        LEA     DX,OFF_STR
        CMP     AL,0
        JNE     W_ONOFF_DONE
W_ONOFF_WRTMSG:
        CALL    WRITE_ASCIIZ
        MOV     DL,'.'
        CALL    WRITE_CHAR
W_ONOFF_DONE:
        POP     DX
        RET
WRITE_ONOFF     ENDP

;***********************************************************************

ECHO_MSG                DB              'ECHO is $'

CMD_ECHO        PROC
        PUSHALL
        LEA     DI,ECHO_?_STR
        CALL    HELP_SWITCH
        JNC     ECHO_DONE
        LEA     SI,CMD_LINE_BUF
        LEA     BX,CMD_PARAM
        MOV     CX,1
        CALL    GET_CMD_PARAM
        CMP     BYTE PTR[BX+4],'.'
        JNE     ECHO_CONTINUE
        MOV     AH,' '
        CALL    STR_FIND_CHAR
        JC      ECHO_DONE_1
        INC     SI
        MOV     DX,SI
        CALL    WRITE_ASCIIZ
        JMP     Short ECHO_DONE_1
ECHO_CONTINUE:
        INC     CX
        INC     CX      ;CX=3
        CALL    GET_CMD_PARAM
        JNC     ECHO_WRTMSG
        DEC     CX
        CALL    GET_CMD_PARAM
        JC      ECHO_SHOW_STAT
        XCHG    SI,BX
        CALL    CHECK_ONOFF
        XCHG    SI,BX
        JC      ECHO_WRTMSG
        MOV     ECHO_STATUS,AL
        JMP     Short ECHO_DONE
ECHO_SHOW_STAT:
        LEA     DX,ECHO_MSG
        CALL    WRITE_STRING
        MOV     AL,ECHO_STATUS
        CALL    WRITE_ONOFF
        JMP     Short ECHO_DONE_1
ECHO_WRTMSG:
        MOV     AH,' '
        CALL    STR_FIND_CHAR
        INC     SI
        MOV     DX,SI
        CALL    WRITE_ASCIIZ
ECHO_DONE_1:
        CALL    NEW_LINE
ECHO_DONE:
        POPALL
        RET
CMD_ECHO        ENDP

;***********************************************************************

CMD_REM PROC
        PUSH    CX
        PUSH    DI
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     REM_DONE
        LEA     DI,REM_?_STR
        CALL    HELP_SWITCH
REM_DONE:
        POP     DI
        POP     CX
        RET
CMD_REM ENDP

;***********************************************************************
PAUSE_DOT       DB      ' .$'

CMD_PAUSE       PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        LEA     DI,PAUSE_?_STR
        CALL    HELP_SWITCH
        JNC     PAUSE_DONE
        ;-----------------------------------
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     PAUSE_DISP_MSG
        DEC     CX      ;CX=2
        CALL    GET_CMD_PARAM
        JC      PAUSE_DISP_MSG
        CMP     WORD PTR CMD_PARAM[0],'Q/'
        JNE     PAUSE_DISP_MSG
        CMP     BYTE PTR CMD_PARAM[2],00H
        JE      PAUSE_WAIT_KEY
        ;-----------------------------------
PAUSE_DISP_MSG:
        LEA     DX,PAUSE_MSG
        CALL    WRITE_STRING
        LEA     DX,PAUSE_DOT
        CALL    WRITE_STRING
        CALL    WRITE_STRING
        CALL    WRITE_STRING
        CALL    NEW_LINE
        ;-----------------------------------
PAUSE_WAIT_KEY:
        CALL    READ_FULL_KEY
PAUSE_DONE:
        POP     DI
        POP     DX
        POP     CX
        POP     AX
        RET
CMD_PAUSE       ENDP

;***********************************************************************

CMD_CLS         PROC
        PUSH    AX
        PUSH    BX
        PUSH    DX
        PUSH    DI
        LEA     DI,CLS_?_STR
        CALL    HELP_SWITCH
        JNC     CLS_DONE
        CALL    CLEAR_SCREEN
        MOV     AH,0FH
        INT     10H
        MOV     AH,02H
        XOR     DX,DX
        INT     10H
        MOV     CURSOR_UP_FLAG,1
CLS_DONE:
        POP     DI
        POP     DX
        POP     BX
        POP     AX
        RET
CMD_CLS         ENDP

;***********************************************************************

CMD_BEEP        PROC
        PUSH    AX
        PUSH    BX
        MOV     AX,600
        MOV     BX,2400
        CALL    SPEAKER_BEEP
        POP     BX
        POP     AX
        RET
CMD_BEEP        ENDP

;***********************************************************************

WRITE_DATE      PROC
        PUSH    AX
        MOV     AX,DX
        MOV     DL,DH
        XOR     DH,DH
        CMP     DL,9
        JA      WIRTE_MONTH
        CALL    WRITE_0
WIRTE_MONTH:
        CALL    WRITE_DECIMAL
        MOV     DL,'/'
        CALL    WRITE_CHAR
        MOV     DL,AL
        CMP     DL,9
        JA      WIRTE_DAY
        CALL    WRITE_0
WIRTE_DAY:
        CALL    WRITE_DECIMAL
        MOV     DL,'/'
        CALL    WRITE_CHAR
        MOV     DX,CX
        CALL    WRITE_DECIMAL
        MOV     DX,AX
        POP     AX
        RET
WRITE_DATE      ENDP

;***********************************************************************

WRITE_CURRENT_DATE      PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        CALL    GET_DATE
        CALL    WRITE_DATE
        POP     DX
        POP     CX
        POP     AX
        RET
WRITE_CURRENT_DATE      ENDP

;***********************************************************************

WRITE_0 PROC
        PUSH    DX
        MOV     DL,'0'
        CALL    WRITE_CHAR
        POP     DX
        RET
WRITE_0 ENDP

;***********************************************************************

WRITE_TIME      PROC
        PUSH    AX
        MOV     AX,DX
        XOR     DH,DH
        MOV     DL,CH
        CMP     DL,9
        JA      WRITE_HH
        CALL    WRITE_0
WRITE_HH:
        CALL    WRITE_DECIMAL
        MOV     DL,':'
        CALL    WRITE_CHAR
        MOV     DL,CL
        CMP     DL,9
        JA      WIRTE_MM
        CALL    WRITE_0
WIRTE_MM:
        CALL    WRITE_DECIMAL
        MOV     DL,':'
        CALL    WRITE_CHAR
        MOV     DL,AH
        CMP     DL,9
        JA      WIRTE_SS
        CALL    WRITE_0
WIRTE_SS:
        CALL    WRITE_DECIMAL
        MOV     DX,AX
        POP     AX
        RET
WRITE_TIME      ENDP

;***********************************************************************

WRITE_CURRENT_TIME      PROC
        PUSH    CX
        PUSH    DX
        CALL    GET_TIME
        CALL    WRITE_TIME
        POP     DX
        POP     CX
        RET
WRITE_CURRENT_TIME      ENDP

;***********************************************************************

CMD_RESTART     PROC
        PUSH    CX
        PUSH    DI
        LEA     DI,RESTART_?_STR
        CALL    HELP_SWITCH
        JNC     RSETART_DONE
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JNC     RSETART_FAILURE
        ;-----------------------------------
        ;Restart
        MOV     AX,0040H
        MOV     DS,AX
        MOV     AX,1234H
        MOV     DS:WORD PTR[0072H],AX
        MOV     AX,0F000H
        PUSH    AX
        MOV     AX,0FFF0H
        PUSH    AX
        RETF
        ;-----------------------------------
RSETART_FAILURE:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
RSETART_DONE:
        POP     DI
        POP     CX
        RET
CMD_RESTART     ENDP

;***********************************************************************
ALL_FILES_MATCH_STR             LABEL           BYTE
VOLUME_DRIVE_LETTER             DB              ?
VOLUME_LABEL_FILE_SPEC          DB              ':\*.*',00H

DISPLAY_VOLUME_LABEL    PROC
;INPUT:  AL=Drive number (0=A,1=B,...)
;OUTPUT: Displays volume label
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        ADD     AL,'A'
        MOV     VOLUME_DRIVE_LETTER,AL
        LEA     DX,DTA
        CALL    SET_DTA_ADDRESS
        LEA     DX,ALL_FILES_MATCH_STR
        MOV     CX,8
        CALL    FIND_FIRST_FILE
        JC      DVL_NO_LABEL
        LEA     DX,VOL_LMSG
        CALL    WRITE_STRING
        LEA     DX,DTA
        ADD     DX,30
        MOV     SI,DX
        MOV     AH,'.'
        CALL    STR_FIND_CHAR
        JC      WRITE_LABEL
        MOV     AL,1
        CALL    STR_SHIFT_LEFT
WRITE_LABEL:
        CALL    WRITE_ASCIIZ
        JMP     Short DVL_DONE
DVL_NO_LABEL:
        LEA     DX,VOL_NOLABELMSG
        CALL    WRITE_STRING
DVL_DONE:
        CALL    NEW_TEXT_LINE
        CALL    NEW_LINE
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
DISPLAY_VOLUME_LABEL    ENDP

;***********************************************************************

DISPLAY_VOLUME_INF      PROC
;INPUT:  AL=Drive number(0=A,1=B,...)
;OUTPUT: NONE
;INFO:   Uses ALLOCATE_DISK_BUFFER
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    ES
        CALL    DISPLAY_VOLUME_LABEL
        STC
        CALL    ALLOCATE_DISK_BUFFER
        JC      DVI_DONE
        MOV     CX,1
        XOR     DX,DX
        XOR     BX,BX
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    READ_LOGIC_SECTOR
        POP     DS
        JC      DVI_READ_ERR
        LEA     DX,VOL_SMSG
        CALL    WRITE_STRING
        ;-----------------------------------
        ;Write disk serial number
        MOV     ES,DISK_BUF_SEG
        MOV     AX,ES:[BX+41]
        MOV     DX,AX
        MOV     CX,12
        SHR     DX,CL
        CALL    WRITE_HEX_DIGIT
        MOV     DX,AX
        MOV     CX,8
        SHR     DX,CL
        AND     DL,0FH
        CALL    WRITE_HEX_DIGIT
        MOV     DX,AX
        MOV     CX,4
        SHR     DX,CL
        AND     DL,0FH
        CALL    WRITE_HEX_DIGIT
        MOV     DX,AX
        AND     DL,0FH
        CALL    WRITE_HEX_DIGIT
        MOV     DL,'-'
        CALL    WRITE_CHAR
        MOV     AX,ES:[BX+39]
        MOV     DX,AX
        MOV     CX,12
        SHR     DX,CL
        CALL    WRITE_HEX_DIGIT
        MOV     DX,AX
        MOV     CX,8
        SHR     DX,CL
        AND     DL,0FH
        CALL    WRITE_HEX_DIGIT
        MOV     DX,AX
        MOV     CX,4
        SHR     DX,CL
        AND     DL,0FH
        CALL    WRITE_HEX_DIGIT
        MOV     DX,AX
        AND     DL,0FH
        CALL    WRITE_HEX_DIGIT
        JMP     Short DVI_DONE_1
        ;-----------------------------------
DVI_READ_ERR:
        MOV     AL,ERR_DRERROR
        CALL    WRITE_ERROR_MESSAGE
DVI_DONE_1:
        CALL    NEW_TEXT_LINE
        CALL    NEW_LINE
DVI_DONE:
        CALL    FREE_DISK_BUFFER
        POP     ES
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
DISPLAY_VOLUME_INF      ENDP

;***********************************************************************
VOL_SMSG        DB      'Volume Serial Number: $'
VOL_LMSG        DB      'Volume Label: $'
VOL_NOLABELMSG  DB      'Volume has no label.$'
VOL_NOLABEL_STR DB      'NO NAME    ',00H

CMD_VOL         PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        LEA     DI,VOL_?_STR
        CALL    HELP_SWITCH
        JNC     VOL_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     VOL_OPERR
        MOV     CX,2
        CALL    GET_DEFAULT_DRIVE       ;AL=Default drive
        CALL    GET_CMD_PARAM
        JC      VOL_DRV_OK
        LEA     SI,CMD_PARAM
        CALL    STR_LENGTH
        CMP     AX,2
        JA      VOL_BADDRV
        CMP     BYTE PTR[SI+1],':'
        JNE     VOL_BADDRV
        MOV     AL,[SI]
        SUB     AL,'A'
VOL_DRV_OK:
        ;AL=Drive number(0=A,1=B,2=C,...)
        MOV     DL,AL
        CALL    VALIDATE_DRIVE_NO
        JNC     VOL_SHOW_INF
VOL_BADDRV:
        MOV     AX,ERR_IDSPECIFIED
        JMP     Short VOL_WRTERRMSG
VOL_SHOW_INF:
        MOV     TEXT_LINE_COUNT,0
        CALL    DISPLAY_VOLUME_INF
        JMP     Short VOL_DONE
VOL_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        JMP     Short VOL_WRTERRMSG
VOL_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
        CALL    NEW_LINE
VOL_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
CMD_VOL         ENDP

;***********************************************************************
ATR_ATTRIB_COL          EQU             5
ATR_NAME_COL            EQU             12
OK_SUFFIX       DB      ' - OK$'
ERROR_SUFFIX    DB      ' - ERROR: $'

CMD_ATTRIB      PROC
        PUSHALL
        LEA     DI,ATTR_?_STR
        CALL    HELP_SWITCH
        JNC     ATR_DONE
        XOR     BL,BL
        MOV     BH,0FFH
        MOV     CX,1
        LEA     SI,CMD_PARAM
ATR_LOOP:
        INC     CX
        CALL    GET_CMD_PARAM
        JC      ATR_OPERR
        CALL    STR_LENGTH
        CMP     AX,2
        JA      ATR_FILE
        JB      ATR_FILE
        MOV     DX,[SI]
        CMP     DX,'R+'
        JE      ATR_ADDR
        CMP     DX,'A+'
        JE      ATR_ADDA
        CMP     DX,'H+'
        JE      ATR_ADDH
        CMP     DX,'S+'
        JE      ATR_ADDS
        CMP     DX,'R-'
        JE      ATR_DELR
        CMP     DX,'A-'
        JE      ATR_DELA
        CMP     DX,'H-'
        JE      ATR_DELH
        CMP     DX,'S-'
        JE      ATR_DELS
        JMP     Short ATR_FILE
ATR_ADDR:
        TEST    BH,01H
        JZ      ATR_OPERR
        OR      BL,01H
        JMP     Short ATR_LOOP
ATR_ADDA:
        TEST    BH,20H
        JZ      ATR_OPERR
        OR      BL,20H
        JMP     Short ATR_LOOP
ATR_ADDH:
        TEST    BH,02H
        JZ      ATR_OPERR
        OR      BL,02H
        JMP     Short ATR_LOOP
ATR_ADDS:
        TEST    BH,04H
        JZ      ATR_OPERR
        OR      BL,04H
        JMP     ATR_LOOP
ATR_DELR:
        TEST    BL,01H
        JNZ     ATR_OPERR
        AND     BH,0FEH
        JMP     ATR_LOOP
ATR_DELA:
        TEST    BL,20H
        JNZ     ATR_OPERR
        AND     BH,0DFH
        JMP     ATR_LOOP
ATR_DELH:
        TEST    BL,02H
        JNZ     ATR_OPERR
        AND     BH,0FDH
        JMP     ATR_LOOP
ATR_DELS:
        TEST    BL,04H
        JNZ     ATR_OPERR
        AND     BH,0FBH
        JMP     ATR_LOOP
ATR_FILE:
        INC     CX
        CALL    GET_CMD_PARAM
        JNC     ATR_OPERR
        CALL    START_FIND_FILE
        MOV     DX,SI
        CMP     BL,00H
        JNE     CHANGE_ATTR
        XOR     SI,SI
        CMP     BH,0FFH
        JE      SHOW_ATTR
CHANGE_ATTR:
        MOV     SI,1
SHOW_ATTR:
        CALL    FIND_FILE
        JC      ATTR_NO_FILES
ATTR_FILE_LOOP:
        XOR     AL,AL
        CALL    GET_SET_FILE_ATTR
        JC      ATR_WRTERRMSG
        CMP     SI,1
        JE      APPLY_ATTR
        PUSH    DX
        CALL    GET_XY
        MOV     DL,ATR_ATTRIB_COL
        CALL    GOTO_XY
        MOV     AL,CL
        CALL    WRITE_DIR_ATTRIB
        MOV     DL,ATR_NAME_COL
        CALL    GOTO_XY
        POP     DX
        CALL    WRITE_ASCIIZ
        JMP     Short ATR_NEXT_ITEM
        ;-----------------------------------
APPLY_ATTR:
        CALL    WRITE_ASCIIZ
        OR      CL,BL
        AND     CL,BH
        MOV     AL,1
        PUSH    DX
        CALL    GET_SET_FILE_ATTR
        JNC     ATR_APPLY_SUCCESS
        CMP     AL,ERR_FAIL24H
        JE      ATR_FAIL24H_ERR
        LEA     DX,ERROR_SUFFIX
        CALL    WRITE_STRING
        CALL    WRITE_ERROR_MESSAGE
        POP     DX
        JMP     Short ATR_NEXT_ITEM
ATR_FAIL24H_ERR:
        POP     DX
        CALL    NEW_LINE
        JMP     Short ATR_WRTERRMSG
ATR_APPLY_SUCCESS:
        LEA     DX,OK_SUFFIX
        CALL    WRITE_STRING
        POP     DX
ATR_NEXT_ITEM:
        CALL    NEW_LINE
        CALL    FIND_FILE
        JNC     ATTR_FILE_LOOP
        JMP     Short ATR_DONE
ATR_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        JMP     Short ATR_WRTERRMSG
ATTR_NO_FILES:
        MOV     AL,ERR_FNFOUND
ATR_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
        JMP     Short ATR_DONE_1
ATR_WRTMSG:
        CALL    WRITE_STRING
ATR_DONE_1:
        CALL    NEW_LINE
ATR_DONE:
        POPALL
        RET
CMD_ATTRIB      ENDP

;***********************************************************************
VER_MSG                 DB      'MiniTAK Operating System Version $'
RELEASE_MSG             DB      ' Release $'

CMD_VER         PROC
        STC
        CALL    CHECK_OS
        JC      VER_RETURN
        PUSH    DI
        LEA     DI,VER_?_STR
        CALL    HELP_SWITCH
        JNC     VER_DONE_1
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JNC     VER_OPERR
        ;-----------------------------------
        MOV     AH,01H
        INT     32H
        LEA     DX,VER_MSG
        CALL    WRITE_STRING
        MOV     DL,AL
        XOR     DH,DH
        CALL    WRITE_DECIMAL
        MOV     DL,'.'
        CALL    WRITE_CHAR
        MOV     DL,AH
        CALL    WRITE_DECIMAL
        LEA     DX,RELEASE_MSG
        CALL    WRITE_STRING
        MOV     DL,BL
        XOR     DH,DH
        CALL    WRITE_DECIMAL
        JMP     Short VER_DONE_2
        ;-----------------------------------
VER_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
VER_DONE_2:
        CALL    NEW_LINE
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
VER_DONE_1:
        POP     DI
VER_RETURN:
        RET
CMD_VER         ENDP

;***********************************************************************
DISK_BUF_SEG            DW              ?
DISK_BUF_LENGTH         DW              0

ALLOCATE_DISK_BUFFER    PROC
;INPUT:  CF=0=> Don't display error message if allocation fails
;        CF=1=> Display error message if allocation fails
;OUTPUT: NONE
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     CL,0
        JNC     ADF_CONTINUE
        MOV     CL,1
ADF_CONTINUE:
        CMP     DISK_BUF_LENGTH,0
        JNE     INTERNAL_ERROR
        MOV     AH,48H
        MOV     BX,1000H
        INT     21H
        JC      CHECK_FREE_MEM
        JMP     Short ADB_CALC_BUF_LENGTH
CHECK_FREE_MEM:
        CMP     AL,ERR_ISMEMORY
        JNE     ADB_WRTERRMSG
        CMP     BX,33           ;At least more than 512 bytes is needed
        JB      ADB_WRTERRMSG
        MOV     AH,48H
        INT     21H
ADB_CALC_BUF_LENGTH:
        MOV     DISK_BUF_SEG,AX
        MOV     AX,16
        MUL     BX
        DEC     AX
        DEC     AX
        MOV     DISK_BUF_LENGTH,AX
        CLC
        JMP     Short ADB_DONE
INTERNAL_ERROR:
        MOV     AL,ERR_IERROR
ADB_WRTERRMSG:
        CMP     CL,0
        JE      ADB_ERR_MSG_DONE
        CALL    WRITE_ERROR_MESSAGE
        CALL    NEW_LINE
ADB_ERR_MSG_DONE:
        STC
ADB_DONE:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
ALLOCATE_DISK_BUFFER    ENDP

;***********************************************************************

FREE_DISK_BUFFER        PROC
;INPUT:  NONE
;OUTPUT: NONE
        PUSHF
        PUSH    AX
        PUSH    ES
        CMP     DISK_BUF_LENGTH,0
        JE      FDB_DONE
        MOV     ES,DISK_BUF_SEG
        MOV     AH,49H
        INT     21H
        MOV     DISK_BUF_LENGTH,0
FDB_DONE:
        POP     ES
        POP     AX
        POPF
        RET
FREE_DISK_BUFFER        ENDP

;***********************************************************************
CPY_ERR1MSG             DB      'You should specify source and destination file'
                        DB      ' names.$'
CPY_ERR2MSG             DB      'Source and destination file names are same.$'
CPY_ERRMSG              DB      'System error.$'
CPY_NOERR               DB      CR,LF,'1 file copied.$'
CPY_BAD_COPY_MSG        DB      CR,LF,'Unsuccessful copy: Maybe the disk is full.$'
CPY_WAITMSG             DB      'Copying(this may take a little long)...',CR,LF,'$'

CMD_COPY        PROC
        PUSHALL
        LEA     DI,COPY_?_STR
        CALL    HELP_SWITCH
        JNC     CPY_DONE
        MOV     CX,1
        LEA     SI,CMD_PARAM
        MOV     BYTE_1,0
        MOV     FNAME_1[0],0
        MOV     FNAME_2[0],0
CPY_LOOP:
        INC     CX
        CALL    GET_CMD_PARAM
        JC      CPY_LX
        CALL    STR_LENGTH
        CMP     AX,63
        JA      CPY_ERR
        LEA     DI,FNAME_1
        CMP     FNAME_1[0],0
        JE      CPY_GETNAME
        LEA     DI,FNAME_2
        CMP     FNAME_2[0],0
        JE      CPY_GETNAME
        MOV     AL,ERR_ICLPARAMETERS
        JMP     CPY_SYSERR_2
CPY_GETNAME:
        CALL    STR_COPY
        JMP     Short CPY_LOOP
CPY_LX:
        CMP     CX,2
        JNE     CPY_CONTINUE
        LEA     DX,TYPE_?_MSG
        JMP     CPY_WRTMSG
CPY_CONTINUE:
        CMP     FNAME_1[0],0
        JE      CPY_ERR1
        CMP     FNAME_2[0],0
        JE      CPY_ERR1
        LEA     SI,FNAME_1
        LEA     DI,FNAME_2
        CALL    COMP_STRS
        JNC     CPY_ERR2
        STC
        CALL    ALLOCATE_DISK_BUFFER
        JC      CPY_DONE
        MOV     DX,SI
        XOR     AL,AL
        CALL    OPEN_FILE
        JC      CPY_SYSERR_2
        MOV     WORD_1,AX
        MOV     CX,20H          ;File Attributes:Archive
        MOV     DX,DI
        CALL    CREATE_NEW_FILE
        JC      CPY_SYSERR_2
        MOV     WORD_2,AX
        LEA     DX,CPY_WAITMSG
        CALL    WRITE_STRING
        XOR     DX,DX
        MOVDW   DWORD_1,0
        MOVDW   DWORD_2,0
CPY_COPY:
        MOV     CX,DISK_BUF_LENGTH
        MOV     BX,WORD_1
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    READ_FILE
        POP     DS
        JC      CPY_SYSERR_1
        ADDDW   DWORD_1,AX
        MOV     CX,AX
        MOV     BX,WORD_2
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    WRITE_FILE
        POP     DS
        ADDDW   DWORD_2,AX
        OR      CX,CX
        JNZ     CPY_COPY
        MOV     BX,WORD_1
        CALL    CLOSE_FILE
        MOV     BX,WORD_2
        CALL    CLOSE_FILE
        JC      CPY_SYSERR_1
        MOV     AX,WORD PTR DWORD_1[0]
        MOV     BX,WORD PTR DWORD_1[2]
        CMP     AX,WORD PTR DWORD_2[0]
        JNE     CPY_BAD_COPY
        CMP     BX,WORD PTR DWORD_2[2]
        JNE     CPY_BAD_COPY
        ;Copy was successful.
        LEA     DX,CPY_NOERR
        JMP     Short CPY_WRTMSG
CPY_BAD_COPY:
        LEA     DX,CPY_BAD_COPY_MSG
        JMP     Short CPY_WRTMSG
CPY_SYSERR_1:
        CALL    NEW_LINE
CPY_SYSERR_2:
        CALL    WRITE_ERROR_MESSAGE
        JMP     Short CPY_DONE_1
CPY_ERR1:
        LEA     DX,CPY_ERR1MSG
        JMP     Short CPY_WRTMSG
CPY_ERR2:
        LEA     DX,CPY_ERR2MSG
        JMP     Short CPY_WRTMSG
CPY_ERR:
        LEA     DX,CPY_ERRMSG
CPY_WRTMSG:
        CALL    WRITE_STRING
CPY_DONE_1:
        CALL    NEW_LINE
CPY_DONE:
        CALL    FREE_DISK_BUFFER
        POPALL
        RET
CMD_COPY        ENDP

;***********************************************************************
CPYTO_DISK_MSG_1        DB      10,13,'Insert the $'
CPYTO_DISK_MSG_2        DB      ' disk into drive and press ENTER when ready...$'
CPYTO_DISK_1_MSG        DB      'first$'
CPYTO_DISK_2_MSG        DB      'second$'

COPYTO_DISK_PROMPT      PROC
;INPUT:  AL=Disk no.(1=First Disk,>2=Second Disk)
;OUTPUT: NONE
        PUSH    AX
        PUSH    DX
        LEA     DX,CPYTO_DISK_MSG_1
        CALL    WRITE_STRING
        CMP     AL,1
        JE      CPYTODP_FIRST_DISK
        ;Prompt for the second disk
        LEA     DX,CPYTO_DISK_2_MSG
        JMP     Short CPYTODP_WRITE_PROMPT
CPYTODP_FIRST_DISK:
        LEA     DX,CPYTO_DISK_1_MSG
CPYTODP_WRITE_PROMPT:
        CALL    WRITE_STRING
        LEA     DX,CPYTO_DISK_MSG_2
        CALL    WRITE_STRING
        MOV     AX,1800
        CALL    WAIT_MILI       ;Wait about 2 seconds
        MOV     AL,0DH
        CALL    WAIT_KEY
        POP     DX
        POP     AX
        RET
COPYTO_DISK_PROMPT      ENDP

CMD_COPYTO      PROC
        PUSHALL
        LEA     DI,COPYTO_?_STR
        CALL    HELP_SWITCH
        JNC     CPYTO_DONE
        MOV     CX,1
        LEA     SI,CMD_PARAM
        MOV     BYTE_1,0
        MOV     FNAME_1[0],0
        MOV     FNAME_2[0],0
CPYTO_LOOP:
        INC     CX
        CALL    GET_CMD_PARAM
        JC      CPYTO_LX
        CALL    STR_LENGTH
        CMP     AX,63
        JA      CPYTO_FERR
        LEA     DI,FNAME_1
        CMP     FNAME_1[0],0
        JE      CPYTO_GETNAME
        LEA     DI,FNAME_2
        CMP     FNAME_2[0],0
        JE      CPYTO_GETNAME
        MOV     AL,ERR_ICLPARAMETERS
        JMP     CPYTO_WRTERRMSG
CPYTO_GETNAME:
        CALL    STR_COPY
        JMP     Short CPYTO_LOOP
CPYTO_LX:
        CMP     CX,2
        JNE     CPYTO_CONTINUE
        LEA     DX,TYPE_?_MSG
        JMP     CPYTO_WRTMSG
CPYTO_CONTINUE:
        CMP     FNAME_1[0],0
        JE      CPYTO_ERR1
        CMP     FNAME_2[0],0
        JE      CPYTO_ERR1
        LEA     SI,FNAME_1
        LEA     DI,FNAME_2
        STC
        CALL    ALLOCATE_DISK_BUFFER
        JC      CPYTO_DONE
        CALL    COMMIT_ALL_FILES
        MOV     AL,1
        CALL    COPYTO_DISK_PROMPT
        MOV     DX,SI
        XOR     AL,AL
        CALL    OPEN_FILE
        JC      CPYTO_WRTERRMSG
        MOV     WORD_1,AX
        MOV     BX,AX
        MOV     CX,DISK_BUF_LENGTH
        XOR     DX,DX
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    READ_FILE
        POP     DS
        JC      CPYTO_R_ERR
        MOV     SI,AX

        MOV     AL,2
        CALL    COPYTO_DISK_PROMPT
        MOV     DX,DI
        MOV     CX,20H          ;File Attributes:Archive
        CALL    CREATE_NEW_FILE
        JC      CPYTO_WRTERRMSG
        MOV     WORD_2,AX
        XOR     DX,DX
        MOV     CX,SI
CPYTO_COPY:
        MOV     BX,WORD_2
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    WRITE_FILE
        POP     DS
        JC      CPYTO_W_ERR
        CMP     CX,DISK_BUF_LENGTH
        JNE     CPYTO_COPY_DONE
        CALL    COMMIT_ALL_FILES

        MOV     AL,1
        CALL    COPYTO_DISK_PROMPT
        MOV     CX,DISK_BUF_LENGTH
        MOV     BX,WORD_1
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    READ_FILE
        POP     DS
        JC      CPYTO_R_ERR
        MOV     CX,AX
        MOV     AL,2
        CALL    COPYTO_DISK_PROMPT
        JMP     Short CPYTO_COPY
CPYTO_COPY_DONE:
        ;BX=WORD_2
        CALL    CLOSE_FILE
        ;LEA     DX,CPYTO_DISK_1_MSG
        ;CALL    WRITE_STRING
        ;POP     DX
        ;MOV     AL,0DH
        ;CALL    WAIT_KEY
        MOV     BX,WORD_1
        CALL    CLOSE_FILE
        CALL    NEW_LINE
        LEA     DX,CPY_NOERR
        JMP     Short CPYTO_WRTMSG
CPYTO_W_ERR:
        MOV     AX,ERR_DWERROR
        JMP     Short CPYTO_RW_ERR
CPYTO_R_ERR:
        MOV     AX,ERR_DRERROR
CPYTO_RW_ERR:
        PUSH    AX
        MOV     BX,WORD_1
        CALL    CLOSE_FILE
        MOV     BX,WORD_2
        CALL    CLOSE_FILE
        POP     AX
        JMP     Short CPYTO_WRTERRMSG
CPYTO_ERR1:
        LEA     DX,CPY_ERR1MSG
        JMP     Short CPYTO_WRTMSG
CPYTO_FERR:
        MOV     AX,ERR_BADFILENAME
        JMP     Short CPYTO_WRTERRMSG
CPYTO_WRTMSG:
        CALL    WRITE_STRING
        JMP     Short CPYTO_DONE_1
CPYTO_WRTERRMSG:
        CALL    NEW_LINE
        CALL    WRITE_ERROR_MESSAGE
CPYTO_DONE_1:
        CALL    NEW_LINE
CPYTO_DONE:
        CALL    FREE_DISK_BUFFER
        POPALL
        RET
CMD_COPYTO      ENDP

;***********************************************************************

CMD_PROMPT      PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    SI
        PUSH    DI
        LEA     SI,CMD_LINE_BUF
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      PRPT_NOPARAM
        INC     CX      ;CX=3
        CALL    GET_CMD_PARAM
        JNC     PRPT_SETTEXT
        LEA     DI,PROMPT_?_STR
        CALL    HELP_SWITCH
        JNC     PRPT_DONE
PRPT_SETTEXT:
        PUSH    SI
        MOV     AH,' '          ;ASCII code 32
        CALL    STR_FIND_CHAR
        MOV     BYTE PTR[SI],00H
        POP     BX
        CALL    STR_TO_UPPER
        MOV     BYTE PTR[SI],'='
        INC     SI
PRPT_TRUNC_EQS:
        CALL    STR_LTRIM
        CMP     BYTE PTR[SI],00H
        JE      PRPT_NO_PARAM_1
        CMP     BYTE PTR[SI],'='
        JNE     PRPT_EQS_DONE
        MOV     BYTE PTR[SI],' ';ASCII code 32
        JMP     Short PRPT_TRUNC_EQS
PRPT_EQS_DONE:
        MOV     SI,BX
        CALL    SET_ENV_VAR
        JNC     PRPT_DONE
        MOV     AL,ERR_NEESPACE
        CALL    WRITE_ERROR_MESSAGE
        CALL    NEW_LINE
        JMP     Short PRPT_DONE
PRPT_NO_PARAM_1:
        LEA     SI,CMD_LINE_BUF
        MOV     BYTE PTR[SI+6],00H
PRPT_NOPARAM:
        CALL    STR_TRIM
        ;SI points to the string "PROMPT"
        CALL    REMOVE_ENV_VAR
PRPT_DONE:
        POP     DI
        POP     SI
        POP     CX
        POP     BX
        POP     AX
        RET
CMD_PROMPT      ENDP

;***********************************************************************
DELETE_MSG              DB      'Deleting $'
DELF_ALL_FILE_MSG       DB      '* All files in directory will be deleted *',CR,LF,'Are you sure (Y/N)?',00H
DELF_CONFIRM_MSG        DB      ',   Delete (Y/N)?$'
DELF_FLAGS              DB      ?

CMD_DEL PROC
        PUSH    DI
        LEA     DI,DEL_?_STR
        CALL    HELP_SWITCH
        JNC     DELF_DONE_2
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        MOV     CX,4
        CALL    GET_CMD_PARAM
        JNC     DELF_OPERR
        MOV     DELF_FLAGS,0
        DEC     CX      ;CX=3
        CALL    GET_CMD_PARAM
        JC      DELF_GET_FNAME
        CMP     WORD PTR CMD_PARAM[0],'P/'
        JNE     DELF_OPERR
        CMP     BYTE PTR CMD_PARAM[2],00H
        JNE     DELF_OPERR
        OR      DELF_FLAGS,01H
DELF_GET_FNAME:
        DEC     CX      ;CX=2
        CALL    GET_CMD_PARAM
        JC      DELF_OPERR
        LEA     DX,CMD_PARAM
        CALL    CHECK_ALL_FILES_WILDCARDS
        JNC     DELF_CONTINUE
        TEST    DELF_FLAGS,01H
        JNZ     DELF_CONTINUE
        ;-----------------------------------
        PUSH    DX
        LEA     DX,DELF_ALL_FILE_MSG
        CLC
        CALL    CONFIRM_YNA
        CMP     DL,'Y'
        POP     DX
        JNE     DELF_DONE_1
        ;-----------------------------------
        CALL    NEW_LINE
DELF_CONTINUE:
        CALL    START_FIND_FILE
        CALL    FIND_FILE
        JC      DELF_NO_FILES
DELF_FILE_LOOP:
        PUSH    DX
        ;AL=File attributes
        TEST    AL,00011101b
        JNZ     DELF_NEXT_ITEM_2
        OR      DELF_FLAGS,02H
        TEST    DELF_FLAGS,01H
        JZ      DELF_DELETE_FILE
DELF_CONFIRM_LOOP:
        POP     DX
        PUSH    DX
        CALL    WRITE_ASCIIZ
        LEA     DX,DELF_CONFIRM_MSG
        CALL    WRITE_STRING
        CALL    RESET_KBD_BUF
        CALL    READ_FULL_KEY
        MOV     DL,AL
        CALL    WRITE_CHAR
        CALL    UPPER_CASE
        CMP     AL,'Y'
        JE      DELF_CONFIRM_OK
        CMP     AL,'N'
        JNE     DELF_CONFIRM_LOOP
        JMP     Short DELF_NEXT_ITEM
DELF_CONFIRM_OK:
        CALL    NEW_LINE
DELF_DELETE_FILE:
        LEA     DX,DELETE_MSG
        CALL    WRITE_STRING
        POP     DX
        CALL    WRITE_ASCIIZ
        CALL    WRITE_3DOT
        CALL    DELETE_FILE
        PUSH    DX
        JNC     DELF_DEL_SUCCESS
        CMP     AL,ERR_FAIL24H
        JE      DELF_FAIL_24H
        LEA     DX,ERROR_SUFFIX
        CALL    WRITE_STRING
        CALL    WRITE_ERROR_MESSAGE
        JMP     Short DELF_NEXT_ITEM
DELF_FAIL_24H:
        POP     DX
        CALL    NEW_LINE
        JMP     Short DELF_WRTERRMSG
DELF_DEL_SUCCESS:
        LEA     DX,OK_SUFFIX
        CALL    WRITE_STRING
DELF_NEXT_ITEM:
        CALL    NEW_LINE
DELF_NEXT_ITEM_2:
        POP     DX
        CALL    FIND_FILE
        JNC     DELF_FILE_LOOP
        TEST    DELF_FLAGS,02H
        JNZ     DELF_DONE_1
        JMP     Short DELF_NO_FILES
DELF_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
        CALL    WRITE_TYPE_?_MSG
        JMP     Short DELF_DONE_3
DELF_NO_FILES:
        MOV     AL,ERR_FNFOUND
DELF_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
DELF_DONE_3:
        CALL    NEW_LINE
DELF_DONE_1:
        POP     SI
        POP     DX
        POP     CX
        POP     AX
DELF_DONE_2:
        POP     DI
        RET
CMD_DEL ENDP

;***********************************************************************
RENF_ERR1MSG    DB      'Error:You should specify a new name for the file.$'
RENF_MSG        DB      'The file renamed successfully.$'

CMD_RENAME      PROC
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        LEA     DI,RENAME_?_STR
        CALL    HELP_SWITCH
        JNC     RENF_DONE
        MOV     CX,4
        CALL    GET_CMD_PARAM
        JNC     RENF_OPERR
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      RENF_OPERR
        LEA     DI,FNAME_1
        LEA     SI,CMD_PARAM
        CALL    STR_COPY
        INC     CX      ;CX=3
        CALL    GET_CMD_PARAM
        JC      RENF_ERR1
        MOV     DX,DI
        LEA     DI,FNAME_2
        ;SI => CMD_PARAM
        CALL    STR_COPY
        CALL    RENAME_FILE
        JC      RENF_WRTERRMSG
        LEA     DX,RENF_MSG
        JMP     Short RENF_WRTMSG
RENF_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
        CALL    WRITE_TYPE_?_MSG
        JMP     Short RENF_DONE_1
RENF_ERR1:
        LEA     DX,RENF_ERR1MSG
        JMP     Short RENF_WRTMSG
RENF_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
        JMP     Short RENF_DONE
RENF_WRTMSG:
        CALL    WRITE_STRING
RENF_DONE_1:
        CALL    NEW_LINE
RENF_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        RET
CMD_RENAME      ENDP

;***********************************************************************

STR_LOCATE_WORD PROC
;INPUT:  SI=Pointer to an ASCIIZ string
;        CX=Order number of word in the input string
;OUTPUT: CF=0=> SI=Pointer to the first character of the word
;        CF=1=> Cannot find a word with the specified order
        PUSH    AX
        PUSH    CX
        PUSH    SI
        OR      CX,CX
        JZ      SLW_SUCCESS
        DEC     CX
        MOV     DI,SI
        CLD
SLW_TRUNCATE_LEFT:
        LODSB
        CMP     AL,00H
        JE      SLW_FAILURE
        CMP     AL,' '
        JE      SLW_TRUNCATE_LEFT
        DEC     SI
        OR      CX,CX
        JZ      SLW_SUCCESS
        DEC     CX
        MOV     AH,' '
        CALL    STR_FIND_CHAR
        JNC     SLW_TRUNCATE_LEFT
SLW_FAILURE:
        POP     SI
        STC
        JMP     Short SLW_DONE
SLW_SUCCESS:
        POP     AX      ;POP old SI from the stack
        CLC
SLW_DONE:
        POP     CX
        POP     AX
        RET
STR_LOCATE_WORD ENDP

;***********************************************************************

VALIDATE_DRIVE_NO       PROC
;INPUT:  DL=Drive number(0=A,1=B,2=C,...)
;OUTPUT: CF=0=> Input drive number is a valid drive number.
;        CF=1=> Input drive number is invalid.
        PUSH    AX
        PUSH    DX
        MOV     AH,19H
        INT     21H
        MOV     DH,AL
        MOV     AH,0EH
        INT     21H
        MOV     AH,19H
        INT     21H
        PUSH    AX
        MOV     AH,0EH
        XCHG    DL,DH
        INT     21H
        POP     AX
        CMP     AL,DH
        JE      VALID_DRIVE
        STC
        JMP     Short VDN_DONE
VALID_DRIVE:
        CLC
VDN_DONE:
        POP     DX
        POP     AX
        RET
VALIDATE_DRIVE_NO       ENDP

;***********************************************************************

CHECK_DRIVE_READY       PROC
;INPUT:  AL=Drive number to check (0=A,1=B,...)
;OUTPUT: CF=0=> Drive is ready , CF=1=> Drive is not ready (AX=Error Code)
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    AX
        MOV     DL,AL
        INC     DL
        CALL    GET_DRIVE_SPEC
        JNC     CDR_READY
        POP     DX              ;POP old AX from the stack
        JMP     Short CDR_DONE
CDR_READY:
        POP     AX
CDR_DONE:
        POP     DX
        POP     CX
        POP     BX
        RET
CHECK_DRIVE_READY       ENDP

;***********************************************************************
THREEDOT_STR    DB      '...$'

WRITE_3DOT      PROC
        PUSH    DX
        LEA     DX,THREEDOT_STR
        CALL    WRITE_STRING
        POP     DX
        RET
WRITE_3DOT      ENDP
;***********************************************************************
CONFIRM_BUFFER          LABEL           BYTE
CONFIRM_BUF_LEN         DB              2
CONFIRM_READ_NUM        DB              1
CONFIRM_TEXT            DB              2 DUP(?)

CONFIRM_YNA     PROC
;INPUT:  DX=Address of an ASCIIZ string to write as prompt
;        CF=0=>'A' is not in selection list
;        CF=1=>'A' is in selection list in addition to 'Y' and 'N'
;OUTPUT: DL=Selected character('Y' for Yes,'N' for No,'A' for All)
        PUSH    AX
        PUSHF
CONFIRM_LOOP:
        CALL    WRITE_ASCIIZ
        PUSH    DX
        LEA     DX,CONFIRM_BUFFER
        MOV     AH,0AH
        INT     21H
        POP     DX
        MOV     AL,CONFIRM_TEXT[0]
        CALL    UPPER_CASE
        CMP     AL,'Y'
        JE      CONFIRM_DONE
        CMP     AL,'N'
        JE      CONFIRM_DONE
        POPF
        PUSHF
        JNC     CONFIRM_INVALID_CHAR
        CMP     AL,'A'
        JE      CONFIRM_DONE
CONFIRM_INVALID_CHAR:
        CALL    NEW_LINE
        JMP     Short CONFIRM_LOOP
CONFIRM_DONE:
        POPF
        MOV     DL,AL
        POP     AX
        RET
CONFIRM_YNA     ENDP

;***********************************************************************
PAUSE_MSG       DB      'Press any key to continue$'

SCREEN_PAUSE    PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        LEA     DX,PAUSE_MSG
        CALL    WRITE_STRING
        CALL    WRITE_3DOT
        CALL    READ_FULL_KEY
        MOV     DL,CR
        CALL    WRITE_CHAR
        MOV     CX,28
        MOV     DL,' '
        MOV     AH,02H
SP_CLEAR_LINE:
        INT     21H
        LOOP    SP_CLEAR_LINE
        MOV     DL,CR
        CALL    WRITE_CHAR
        POP     DX
        POP     CX
        POP     AX
        RET
SCREEN_PAUSE    ENDP

;***********************************************************************

RESET_KBD_BUF   PROC
        PUSH    AX
        MOV     AX,0C00H
        INT     21H
        POP     AX
        RET
RESET_KBD_BUF   ENDP

;***********************************************************************

READ_FULL_KEY   PROC
        CALL    READ_KEY_W
        OR      AL,AL
        JNZ     RFK_RETURN
        CALL    READ_KEY_W
        XOR     AL,AL
RFK_RETURN:
        RET
READ_FULL_KEY   ENDP

;***********************************************************************

GOTO_XY PROC
        PUSH    AX
        PUSH    BX
        MOV     AH,0FH
        INT     10H
        CMP     DL,AH
        JNB     BAD_POINT
        MOV     AH,02H
        INT     10H
        CLC
GOTO_XY_DONE:
        POP     BX
        POP     AX
        RET
BAD_POINT:
        STC
        JMP     Short GOTO_XY_DONE
GOTO_XY ENDP

;***********************************************************************

GET_XY  PROC
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
GET_XY  ENDP

;***********************************************************************
W0      DW      ?
W1      DW      ?
W2      DW      ?
W3      DW      ?
Z0      DW      ?
Z1      DW      ?

DIVIDE_64       PROC
        XCHG    BX,Z1
        XCHG    CX,Z0
        XOR     AX,AX
        XOR     DX,DX
        PUSH    SI
        MOV     SI,64
DIV_64:
        SHL     W0,1
        RCL     W1,1
        RCL     W2,1
        RCL     W3,1
        RCL     AX,1
        RCL     DX,1
        JC      HIT_Q_2
        ;BX:CX , DX:AX
        CMP     DX,BX
        JA      HIT_Q
        JB      NEXT_BIT
        CMP     AX,CX
        JB      NEXT_BIT
HIT_Q:
        SUB     AX,CX
        SBB     DX,BX
        ADD     W0,1
NEXT_BIT:
        DEC     SI
        JNZ     DIV_64
        JMP     Short DIV_64_DONE
HIT_Q_2:
        PUSH    SI
        PUSH    DI
        XOR     SI,SI
        XOR     DI,DI   ;SI:DI
        ADD     DI,AX
        ADC     SI,DX
        ADD     DI,1
        ADC     SI,0
        MOV     AX,0FFFFH
        MOV     DX,AX
        SUB     AX,CX
        SBB     DX,BX
        ADD     W0,1
        ADD     AX,DI
        ADC     DX,SI
        POP     DI
        POP     SI
        JMP     Short NEXT_BIT
DIV_64_DONE:
        POP     SI
        XCHG    BX,Z1
        XCHG    CX,Z0
        RET
DIVIDE_64       ENDP

;***********************************************************************

WRITE_DECIMAL_32        PROC
        PUSH    AX
        PUSH    DX
        PUSH    CX
        MOV     WORD PTR W0,AX
        MOV     WORD PTR W1,BX
        XOR     AX,AX
        MOV     WORD PTR W2,AX       
        MOV     WORD PTR W3,AX       
        MOV     WORD PTR Z0,10       
        MOV     WORD PTR Z1,AX
        XOR     CX,CX
GET_DIGITS_32:
        CALL    DIVIDE_64
        PUSH    AX
        INC     CX
        CMP     W0,DX
        JNE     GET_DIGITS_32
        CMP     W1,DX
        JNE     GET_DIGITS_32
WRITE_DIGITS_32:
        POP     DX
        ADD     DL,'0'
        CALL    WRITE_CHAR
        LOOP    WRITE_DIGITS_32
        POP     CX
        POP     DX
        POP     AX
        RET
WRITE_DECIMAL_32        ENDP

;***********************************************************************

EXTRACT_DRIVE_NO        PROC
;INPUT:  DX=Points to an ASCIIZ string of a file specification
;OUTPUT: AL=Drive number of the file specification string (0=A,1=B,...)
        XCHG    DX,SI
        CMP     BYTE PTR[SI+1],':'
        JNE     EDN_DEFAULT_DRIVE
        MOV     AL,BYTE PTR[SI]
        CALL    UPPER_CASE
        CMP     AL,'A'
        JB      EDN_DEFAULT_DRIVE
        CMP     AL,'Z'
        JA      EDN_DEFAULT_DRIVE
        SUB     AL,'A'
        JMP     Short EDN_DONE
EDN_DEFAULT_DRIVE:
        CALL    GET_DEFAULT_DRIVE
EDN_DONE:
        XCHG    DX,SI
        RET
EXTRACT_DRIVE_NO        ENDP

;***********************************************************************

WRITE_DIR_ATTRIB        PROC
        PUSH    DX
        TEST    AL,01H
        JZ      CHECK_H
        MOV     DL,'R'
        CALL    WRITE_CHAR
CHECK_H:
        TEST    AL,02H
        JZ      CHECK_A
        MOV     DL,'H'
        CALL    WRITE_CHAR
CHECK_A:
        TEST    AL,20H
        JZ      CHECK_S
        MOV     DL,'A'
        CALL    WRITE_CHAR
CHECK_S:
        TEST    AL,04H
        JZ      WRT_DIR_ATTR_DONE
        MOV     DL,'S'
        CALL    WRITE_CHAR
WRT_DIR_ATTR_DONE:
        POP     DX
        RET
WRITE_DIR_ATTRIB        ENDP

;***********************************************************************
DIR_DIRECTORY_MSG       DB      '<FOLDER>$'

CHECK_DIR_DIRECTORY     PROC
;INPUT: SI=Points to the DTA filled with FIND NEXT service
;OUTPUT: CF=0=> This entry is a directory and the DIR_DIRECTORY_MSG has been written instead of file size column in DIR command.
;        CF=1=> This entry is not a directory.
        TEST    BYTE PTR[SI+21],00010000b
        JZ      NO_DIRECTORY
        PUSH    DX
        LEA     DX,DIR_DIRECTORY_MSG
        CALL    WRITE_STRING
        POP     DX
        CLC
        JMP     Short CDD_RETURN
NO_DIRECTORY:
        STC
CDD_RETURN:
        RET
CHECK_DIR_DIRECTORY     ENDP

;***********************************************************************
DIR_HEADER_LINE:
DIR_FOOTER_LINE         DB      '----------------------------$'
DIR_TOTAL_OBJECTS_MSG_1 DB      CR,LF,'Total: $'
DIR_TOTAL_OBJECTS_MSG_2 DB      ' object$'
DIR_MSG1                DB      '       Total disk space: $'
DIR_MSG2                DB      '       Disk free space:  $'
DIR_KBMSG               DB      ' KB$'
DIR_NOTMATCHMSG         DB      CR,LF,'File not found.',CR,LF,'$'
DIR_BYTEMSG             DB      ' byte$'

DIR_NAME_COL            EQU             1
DIR_DIRECTORY_COL       EQU             15
DIR_SIZE_COL            EQU             17
DIR_DATE_COL            EQU             29
DIR_TIME_COL            EQU             41
DIR_ATTR_COL            EQU             51

CMD_DIR PROC
;INFO: Uses the WORD_1 and DWORD_1 variables.
        PUSHALL
        LEA     DI,DIR_?_STR
        CALL    HELP_SWITCH
        JNC     DIR_DONE
        MOV     CX,1
        XOR     AH,AH
        LEA     DI,FNAME_1
        CALL    GET_DEFAULT_DRIVE
        ADD     AL,'A'
        MOV     BYTE PTR[DI],AL
        MOV     WORD PTR[DI+1],'*:'
        MOV     WORD PTR[DI+3],'*.'
        MOV     BYTE PTR[DI+5],00H
        LEA     SI,CMD_PARAM
DIR_LOOP:
        INC     CX
        CALL    GET_CMD_PARAM
        JC      DIR_LX
        CMP     BYTE PTR[SI],'/'
        JE      DIR_SWITCH
        OR      AH,AH
        JNZ     DIR_OPERR
        OR      AH,00000001B
        CALL    STR_COPY
        JMP     Short DIR_LOOP
DIR_SWITCH:
        CMP     BYTE PTR[SI+1],'A'
        JE      DIR_ATTRPARAM
        CMP     BYTE PTR[SI+1],'P'
        JNE     DIR_OPERR
        CMP     BYTE PTR[SI+2],00H
        JNE     DIR_OPERR
        TEST    AH,0000010B
        JNZ     DIR_OPERR
        OR      AH,00000010B
        JMP     Short DIR_LOOP
DIR_ATTRPARAM:
        TEST    AH,00000100B
        JNZ     DIR_OPERR
        OR      AH,00000100B
        XOR     DL,DL
        MOV     DH,0FFH
        ADD     SI,2
DIR_LOOP_2:
        CLD
        LODSB
        OR      AL,AL
        JZ      DIR_LX2
        CMP     AL,'-'
        JE      DIR_DELATTR
        CMP     AL,'R'
        JE      DIR_ADDR
        CMP     AL,'A'
        JE      DIR_ADDA
        CMP     AL,'D'
        JE      DIR_ADDD
        CMP     AL,'S'
        JE      DIR_ADDS
        CMP     AL,'H'
        JE      DIR_ADDH
        JMP     DIR_OPERR
DIR_ADDR:
        OR      DL,FATTR_READ_ONLY
        JMP     Short DIR_LOOP_2
DIR_ADDA:
        OR      DL,FATTR_ARCHIVE
        JMP     Short DIR_LOOP_2
DIR_ADDD:
        OR      DL,FATTR_DIRECTORY
        JMP     Short DIR_LOOP_2
DIR_ADDS:
        OR      DL,FATTR_SYSTEM
        JMP     Short DIR_LOOP_2
DIR_ADDH:
        OR      DL,FATTR_HIDDEN
        JMP     Short DIR_LOOP_2
        ;-----------------------------------
DIR_DELATTR:
        CLD
        LODSB
        CMP     AL,'R'
        JE      DIR_DELR
        CMP     AL,'A'
        JE      DIR_DELA
        CMP     AL,'D'
        JE      DIR_DELD
        CMP     AL,'S'
        JE      DIR_DELS
        CMP     AL,'H'
        JE      DIR_DELH
        JMP     DIR_OPERR
DIR_DELR:
        AND     DH,NOT FATTR_READ_ONLY
        JMP     Short DIR_LOOP_2
DIR_DELA:
        AND     DH,NOT FATTR_ARCHIVE
        JMP     Short DIR_LOOP_2
DIR_DELD:
        AND     DH,NOT FATTR_DIRECTORY
        JMP     Short DIR_LOOP_2
DIR_DELS:
        AND     DH,NOT FATTR_SYSTEM
        JMP     Short DIR_LOOP_2
DIR_DELH:
        AND     DH,NOT FATTR_HIDDEN
        JMP     Short DIR_LOOP_2
DIR_LX2:
        SUB     SI,2
        OR      DL,DL
        JNZ     DIR_ATTR
        CMP     DH,0FFH
        JNE     DIR_ATTR
        MOV     DL,00110111B
DIR_ATTR:
        XOR     AL,AL
        OR      AL,DL
        AND     AL,DH
        JMP     DIR_LOOP
        ;-----------------------------------
DIR_LX:
        TEST    AH,00000100b
        JNZ     DIR_ATTROK
        MOV     AL,00110000b
DIR_ATTROK:
        MOV     CL,AL
        XOR     CH,CH
        LEA     DX,DTA
        CALL    SET_DTA_ADDRESS
        MOV     DX,DI
        MOV     BL,AH
        CALL    EXTRACT_DRIVE_NO
        XCHG    AL,DL
        CALL    VALIDATE_DRIVE_NO
        XCHG    AL,DL
        JC      DIR_INVALID_DRIVE
        MOV     TEXT_LINE_COUNT,0
        CALL    CHECK_DRIVE_READY
        JC      DIR_WRTERRMSG
        CALL    DISPLAY_VOLUME_INF
        CALL    FIND_FIRST_FILE
        JC      DIR_NOTMATCH
        MOV     WORD_1,0
        MOVDW   DWORD_1,0
        LEA     DX,DIR_HEADER_LINE
        CALL    WRITE_STRING
        CALL    NEW_TEXT_LINE
        CALL    NEW_LINE
        LEA     SI,DTA
        CALL    NEW_TEXT_LINE
DIR_WRTLOOP:
        INC     WORD_1
        CALL    GET_XY
        MOV     DL,DIR_NAME_COL
        CALL    GOTO_XY
        ADD     SI,30
        XCHG    DX,SI
        CALL    WRITE_ASCIIZ
        XCHG    DX,SI
        SUB     SI,30
        MOV     DL,DIR_DIRECTORY_COL
        CALL    GOTO_XY
        CALL    CHECK_DIR_DIRECTORY
        JNC     DIR_WRT_DATE
        MOV     DL,DIR_SIZE_COL
        CALL    GOTO_XY
        PUSH    BX
        MOV     BX,[SI+28]
        MOV     AX,[SI+26]
        ADD     WORD PTR DWORD_1[0],AX
        ADC     WORD PTR DWORD_1[2],BX
        CALL    WRITE_DECIMAL_32
        POP     BX
DIR_WRT_DATE:
        MOV     DL,DIR_DATE_COL
        CALL    GOTO_XY
        PUSH    DX
        MOV     CX,[SI+24]
        CALL    DECODE_FILE_DATE
        MOV     DX,CX
        XOR     AH,AH
        ADD     AX,1980
        MOV     CX,AX
        CALL    WRITE_DATE
        POP     DX
        MOV     DL,DIR_TIME_COL
        CALL    GOTO_XY
        PUSH    DX
        MOV     CX,[SI+22]
        CALL    DECODE_FILE_TIME
        MOV     DH,CL
        MOV     CL,CH
        MOV     CH,AL
        CALL    WRITE_TIME
        POP     DX
        MOV     DL,DIR_ATTR_COL
        CALL    GOTO_XY
        MOV     AL,[SI+21]
        CALL    WRITE_DIR_ATTRIB
        ;-----------------------------------
        ;This line completed.
        CALL    NEW_LINE
        TEST    BL,00000010B
        JZ      DIR_CONTINUE
        CALL    NEW_TEXT_LINE
DIR_CONTINUE:
        CALL    FIND_NEXT_FILE
        JNC     DIR_WRTLOOP
        CMP     AX,ERR_NMMFILES
        JE      DIR_NO_FILE_ERR_1
        CMP     AX,ERR_FNFOUND
        JNE     DIR_WRTERRMSG
DIR_NO_FILE_ERR_1:
        LEA     DX,DIR_FOOTER_LINE
        CALL    WRITE_STRING
        LEA     DX,DIR_TOTAL_OBJECTS_MSG_1
        CALL    WRITE_STRING
        MOV     DX,WORD_1
        CALL    WRITE_DECIMAL
        LEA     DX,DIR_TOTAL_OBJECTS_MSG_2
        CALL    WRITE_STRING
        OR      DX,DX
        JZ      DIR_TOT_OBJECTS_COUNT_DONE
        MOV     DL,'s'
        CALL    WRITE_CHAR
DIR_TOT_OBJECTS_COUNT_DONE:
        MOV     DL,' '          ;ASCII code 32
        CALL    WRITE_CHAR
        PUSH    BX
        MOV     BX,WORD PTR DWORD_1[2]
        MOV     AX,WORD PTR DWORD_1[0]
        CALL    WRITE_DECIMAL_32
        LEA     DX,DIR_BYTEMSG
        CALL    WRITE_STRING
        OR      AX,AX
        JNZ     DIR_PLURAL_SIZE
        OR      BX,BX
        JZ      DIR_OBJECTS_SIZE_DONE
DIR_PLURAL_SIZE:
        MOV     DL,'s'
        CALL    WRITE_CHAR
DIR_OBJECTS_SIZE_DONE:
        POP     BX
        TEST    BL,00000010B
        JZ      DIR_LIST_DONE
        CALL    NEW_TEXT_LINE
DIR_LIST_DONE:
        CALL    NEW_LINE
        TEST    BL,00000010B
        JZ      DIR_WRITE_TOTSPACE
        CALL    NEW_TEXT_LINE
DIR_WRITE_TOTSPACE:
        LEA     DX,DIR_MSG1
        CALL    WRITE_STRING
        CMP     BYTE PTR FNAME_1[1],':'
        JNE     DIR_DEFAULT_DRIVE
        MOV     DL,BYTE PTR FNAME_1[0]
        JMP     Short DIR_DRIVE_OK
DIR_DEFAULT_DRIVE:
        MOV     DL,BYTE PTR CURRENT_PATH[0]
DIR_DRIVE_OK:
        SUB     DL,'@'
        CALL    GET_DRIVE_SPEC
        JC      DIR_WRTERRMSG_2
        PUSH    BX
        MOV     BX,AX
        MUL     DX      ;DX:AX = Total number of drive sectors
        ;-----------------------------------
        PUSH    DX
        PUSH    AX
        MOV     CX,9
MUL_TOTSECTS_BY_512:
        SHL     AX,1
        RCL     DX,1
        LOOP    MUL_TOTSECTS_BY_512
        XCHG    BX,DX
        CALL    WRITE_DECIMAL_32
        XCHG    BX,DX
        MOV     CX,DX
        LEA     DX,DIR_BYTEMSG
        CALL    WRITE_STRING
        CMP     AX,1
        JA      PLURAL
        CMP     CX,1
        JBE     DIR_WRTKB
PLURAL:
        MOV     DL,'s'
        CALL    WRITE_CHAR
DIR_WRTKB:
        MOV     DL,'('
        CALL    WRITE_CHAR
        POP     AX
        POP     DX
        SHR     DX,1
        RCR     AX,1    ;DX:AX = Size(KB)
        MOV     DX,AX
        CALL    WRITE_DECIMAL
        LEA     DX,DIR_KBMSG
        CALL    WRITE_STRING
        MOV     DL,')'
        CALL    WRITE_CHAR
        ;-----------------------------------
        CALL    NEW_LINE
        TEST    BL,00000010B
        JZ      DIR_WRITE_FREESPACE
        CALL    NEW_TEXT_LINE
        CALL    NEW_TEXT_LINE
DIR_WRITE_FREESPACE:
        LEA     DX,DIR_MSG2
        CALL    WRITE_STRING
        MOV     AX,BX   ;AX = Number of sectors per cluster
        POP     BX      ;BX = Number of available(free) clusters
        MUL     BX      ;DX:AX = Number of free sectors on drive
        SHR     DX,1
        RCR     AX,1    ;DX:AX = Free Space(KB)
                        ;DX=0
        MOV     DX,AX
        CALL    WRITE_DECIMAL
        LEA     DX,DIR_KBMSG
        JMP     Short DIR_WRTMSG
        ;-----------------------------------
DIR_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
        CALL    WRITE_TYPE_?_MSG
        JMP     Short DIR_DONE
DIR_NOTMATCH:
        CMP     AX,ERR_NMMFILES
        JE      DIR_NO_FILE_ERR_2
        CMP     AX,ERR_FNFOUND
        JNE     DIR_WRTERRMSG
DIR_NO_FILE_ERR_2:
        LEA     DX,DIR_NOTMATCHMSG
        CALL    WRITE_STRING
        JMP     DIR_LIST_DONE
DIR_INVALID_DRIVE:
        MOV     AL,ERR_IDSPECIFIED
        JMP     Short DIR_WRTERRMSG
DIR_WRTERRMSG_2:
        CALL    NEW_LINE
DIR_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
        JMP     Short DIR_DONE
DIR_WRTMSG:
        CALL    WRITE_STRING
DIR_DONE:
        CALL    NEW_LINE
        POPALL
        RET
CMD_DIR ENDP

;***********************************************************************

CHECK_NO_FILE_ERROR     PROC
;INPUT:  AL=System error code
;OUTPUT: CF=0=> This error code can be assumed as "An specified file was not found".
;        CF=1=> Other errors
;INFO: If AL is error code 53h(ERR_FAIL24H), in return CF is cleared.
        CMP     AX,ERR_FNFOUND
        JE      CNF_NO_FILE
        CMP     AX,ERR_PNFOUND
        JE      CNF_NO_FILE
        CMP     AX,ERR_FAIL24H
        JE      CNF_NO_FILE
        CMP     AX,ERR_IDSPECIFIED
        JE      CNF_NO_FILE
        STC
        JMP     Short CNF_RETURN
CNF_NO_FILE:
        CLC
CNF_RETURN:
        RET
CHECK_NO_FILE_ERROR     ENDP

;***********************************************************************

CMD_FASTHELP    PROC
        PUSHALL
        LEA     DI,FASTHELP_?_STR
        CALL    HELP_SWITCH
        JNC     FH_DONE
        CALL    OPEN_MINIMAN
        JC      FH_OPEN_ERROR
        MOV     BX,AX
        CALL    VALIDATE_MINIMAN_FILE_VER
        JC      FH_FAILED_2
        MOV     DX,OFFSET FASTHELP_MAINMSG
        SUB     DX,100H
        XOR     CX,CX
        MOV     AX,4200H
        INT     21H
        JC      FH_FAILED_1
        INC     CX      ;CX=1
        LEA     DX,WORD_1
        MOV     TEXT_LINE_COUNT,0
        CALL    NEW_TEXT_LINE
FH_WRITE_LIST:
        CALL    READ_FILE
        JC      FH_INV_RES
        OR      AX,AX
        JZ      FH_INV_RES
        MOV     AL,BYTE PTR WORD_1[0]
        OR      AL,AL
        JZ      FH_LIST_DONE
        CMP     AL,LF           ;LF=Line Feed
        JE      FH_NEW_LINE
        XCHG    AL,DL
        CALL    WRITE_CHAR
        XCHG    AL,DL
        JMP     Short FH_WRITE_LIST
FH_NEW_LINE:
        ;New line
        CALL    NEW_LINE
        CALL    NEW_TEXT_LINE
        JMP     Short FH_WRITE_LIST
FH_LIST_DONE:
        CALL    CLOSE_FILE
        JMP     FH_DONE_2
FH_OPEN_ERROR:
        CALL    CHECK_NO_FILE_ERROR
        JC      FH_FAILED_2
        MOV     AL,ERR_MNFOUND
        JMP     Short FH_WRTERRMSG
FH_FAILED_1:
        CALL    CLOSE_FILE
FH_FAILED_2:
        MOV     AL,ERR_RSNFOUND
        JMP     Short FH_WRTERRMSG
FH_INV_RES:
        CALL    CLOSE_FILE
        MOV     AL,ERR_IRSTRINGS
FH_WRTERRMSG:
        CALL    NEW_LINE
        CALL    WRITE_ERROR_MESSAGE
FH_DONE_2:
        CALL    NEW_LINE
FH_DONE:
        POPALL
        RET
CMD_FASTHELP    ENDP

;***********************************************************************

DEC_TO_WORD     PROC
        PUSH    CX
        PUSH    DX
        PUSH    SI
        CMP     BYTE PTR[SI],00H
        JE      RETURN_BAD
        PUSH    AX
        XOR     CX,CX
        XOR     AH,AH
        CLD
GET_DIGITS:
        LODSB
        OR      AL,AL
        JZ      DIGITS_DONE
        CMP     AL,'0'
        JB      BAD_DIGIT
        CMP     AL,'9'
        JA      BAD_DIGIT
        INC     CX
        SUB     AL,'0'
        PUSH    AX
        JMP     Short GET_DIGITS
DIGITS_DONE:
        MOV     SI,1
        XOR     DX,DX
CONV_TO_DEC:
        OR      CX,CX
        JZ      CONV_DEC_DONE
        DEC     CX
        POP     AX
        PUSH    DX
        MUL     SI
        POP     DX
        ADD     DX,AX
        JC      WORD_OVER_FLOW
        MOV     AX,SI
        MOV     SI,10
        PUSH    DX
        MUL     SI
        POP     DX
        MOV     SI,AX
        JMP     Short CONV_TO_DEC
CONV_DEC_DONE:
        POP     AX
        MOV     AX,DX
        CLC
        JMP     Short DEC_TO_WORD_DONE
WORD_OVER_FLOW:
BAD_DIGIT:
        POP     AX
        OR      CX,CX
        JZ      RETURN_BAD
RESET_STACK:
        POP     AX
        LOOP    RESET_STACK
RETURN_BAD:
        STC
DEC_TO_WORD_DONE:
        POP     SI
        POP     DX
        POP     CX
        RET
DEC_TO_WORD     ENDP

;***********************************************************************

CHECK_DATE_SEP  PROC
        CMP     AL,'/'
        JE      CDS_OK
        CMP     AL,'-'
        JE      CDS_OK
        CMP     AL,'.'
        JE      CDS_OK
        STC
        JMP     Short CDS_RETURN
CDS_OK:
        CLC
CDS_RETURN:
        RET
CHECK_DATE_SEP  ENDP

;***********************************************************************

PARSE_DATE_STRING       PROC
        PUSH    AX
        PUSH    BX
        PUSH    SI
        PUSH    CX
        PUSH    DX
        XOR     BX,BX
        XOR     CX,CX
FIND_DATE_SEP:
        MOV     AL,[SI+BX]
        OR      AL,AL
        JZ      PDS_BADFRMT
        CALL    CHECK_DATE_SEP
        JNC     FOUND_DATE_SEP
        INC     BX
        JMP     Short FIND_DATE_SEP
FOUND_DATE_SEP:
        INC     CL
        XCHG    CH,[SI+BX]
        CALL    DEC_TO_WORD
        XCHG    CH,[SI+BX]
        JC      PDS_BADFRMT
        OR      AH,AH
        JNZ     PDS_BADFRMT
        CMP     CL,2
        JE      PDS_DAY
        MOV     DH,AL
        JMP     Short PDS_CONTINUE
PDS_DAY:
        MOV     DL,AL
PDS_CONTINUE:
        INC     SI
        ADD     SI,BX
        XOR     BX,BX
        CMP     CL,2
        JB      FIND_DATE_SEP
        CALL    DEC_TO_WORD
        JC      PDS_BADFRMT
        CMP     AX,99
        JA      PDS_YEAR_OK
        ADD     AX,1900
PDS_YEAR_OK:
        POP     CX
        POP     CX
        MOV     CX,AX
        CLC
        JMP     Short PDS_DONE
PDS_BADFRMT:
        POP     DX
        POP     CX
        STC
PDS_DONE:
        POP     SI
        POP     BX
        POP     AX
        RET
PARSE_DATE_STRING       ENDP

;***********************************************************************        
DATE_MSG1       DB      'Current date(mm/dd/yy): $'
DATE_MSG2       DB      'Enter new date(mm/dd/yy) or press ENTER to cancel: $'
DATE_FRMTMSG    DB      'The input date format is incorrect.$'
DATE_INVMSG     DB      'The new date is invalid.$'
DATE_MSG        DB      'Date changed successfully.$'
DT_INPUTBUF     DB      15 DUP(?)

CMD_DATE        PROC
        PUSHALL
        LEA     DI,DATE_?_STR
        CALL    HELP_SWITCH
        JNC     DATE_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     DATE_OPERR
        DEC     CX      ;CX=2
        LEA     SI,CMD_PARAM
        CALL    GET_CMD_PARAM
        JNC     DATE_SETDATE
        ;Show date and ask for a new date
        LEA     DX,DATE_MSG1
        CALL    WRITE_STRING
        CALL    WRITE_CURRENT_DATE
        CALL    NEW_LINE
        LEA     DX,DATE_MSG2
        CALL    WRITE_STRING
        MOV     BYTE PTR DT_INPUTBUF[0],11
        LEA     DX,DT_INPUTBUF
        CALL    READ_STRING_BUF
        MOV     SI,DX
        MOV     BL,[SI+1]
        OR      BL,BL
        JZ      DATE_DONE
        CALL    NEW_LINE
        XOR     BH,BH
        INC     SI
        INC     SI
        MOV     BYTE PTR[SI+BX],00H
DATE_SETDATE:
        CALL    PARSE_DATE_STRING
        JC      DATE_BADFRMT
        CALL    SET_DATE
        OR      AL,AL
        JNZ     DATE_INVDATE
        LEA     DX,DATE_MSG
        JMP     Short DATE_WRTMSG
        ;-----------------------------------
DATE_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
        CALL    WRITE_TYPE_?_MSG
        JMP     Short DATE_DONE
DATE_BADFRMT:
        LEA     DX,DATE_FRMTMSG
        JMP     Short DATE_WRTMSG
DATE_INVDATE:
        LEA     DX,DATE_INVMSG
DATE_WRTMSG:
        CALL    WRITE_STRING
DATE_DONE:
        CALL    NEW_LINE
        POPALL
        RET
CMD_DATE        ENDP

;***********************************************************************

PARSE_TIME_STRING       PROC
        PUSH    AX
        PUSH    BX
        PUSH    SI
        PUSH    CX
        PUSH    DX
        XOR     BX,BX
        XOR     DX,DX
FIND_TIME_SEP:
        MOV     AL,[SI+BX]
        OR      AL,AL
        JZ      PTS_BADFRMT
        CMP     AL,':'
        JE      FOUND_TIME_SEP
        INC     BX
        JMP     Short FIND_TIME_SEP
FOUND_TIME_SEP:
        INC     DL
        XCHG    DH,[SI+BX]
        CALL    DEC_TO_WORD
        XCHG    DH,[SI+BX]
        JC      PTS_BADFRMT
        OR      AH,AH
        JNZ     PTS_BADFRMT
        CMP     DL,2
        JE      PTS_MINUTE
        JA      PTS_CONTINUE
        MOV     CH,AL
        JMP     Short PTS_CONTINUE
PTS_MINUTE:
        MOV     CL,AL
PTS_CONTINUE:
        INC     SI
        ADD     SI,BX
        XOR     BX,BX
        CMP     DL,2
        JB      FIND_TIME_SEP
        CALL    DEC_TO_WORD
        JC      PTS_BADFRMT
        OR      AH,AH
        JNZ     PTS_BADFRMT
        POP     DX
        XCHG    AL,AH
        MOV     DX,AX
        POP     AX
        CLC
        JMP     Short PTS_DONE
PTS_BADFRMT:
        POP     DX
        POP     CX
        STC
PTS_DONE:
        POP     SI
        POP     BX
        POP     AX
        RET
PARSE_TIME_STRING       ENDP

;***********************************************************************
TIME_MSG1       DB      'Current time: $'
TIME_MSG2       DB      'Enter new time(hh:mm:ss) or press ENTER to cancel: $'
TIME_FRMTMSG    DB      'The input time format is incorrect.$'
TIME_INVMSG     DB      'The new time is invalid.$'
TIME_MSG        DB      'Time changed successfully.$'

CMD_TIME        PROC
        PUSHALL
        LEA     DI,TIME_?_STR
        CALL    HELP_SWITCH
        JNC     TIME_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     TIME_OPERR
        LEA     SI,CMD_PARAM
        DEC     CX      ;CX=2
        CALL    GET_CMD_PARAM
        JNC     TIME_SETTIME
        ;Show and ask for a new time
        LEA     DX,TIME_MSG1
        CALL    WRITE_STRING
        CALL    WRITE_CURRENT_TIME
        CALL    NEW_LINE
        LEA     DX,TIME_MSG2
        CALL    WRITE_STRING
        LEA     SI,DT_INPUTBUF
        MOV     BYTE PTR[SI],9
        MOV     DX,SI
        CALL    READ_STRING_BUF
        MOV     BL,[SI+1]
        OR      BL,BL
        JZ      TIME_DONE
        CALL    NEW_LINE
        XOR     BH,BH
        INC     SI
        INC     SI
        MOV     BYTE PTR[SI+BX],00H
TIME_SETTIME:
        CALL    PARSE_TIME_STRING
        JC      TIME_BADFRMT
        CALL    SET_TIME
        OR      AL,AL
        JNZ     TIME_INVTIME
        LEA     DX,TIME_MSG
        JMP     Short TIME_WRTMSG
        ;-----------------------------------
TIME_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
        CALL    WRITE_TYPE_?_MSG
        JMP     Short TIME_DONE
TIME_BADFRMT:
        LEA     DX,TIME_FRMTMSG
        JMP     Short TIME_WRTMSG
TIME_INVTIME:
        LEA     DX,TIME_INVMSG
TIME_WRTMSG:
        CALL    WRITE_STRING
TIME_DONE:
        CALL    NEW_LINE
        POPALL
        RET
CMD_TIME        ENDP

;***********************************************************************
DOSVER_MSG     DB      'Supported DOS Version: $'
DOSVER_BAD_VER_MSG      DB      'Invalid version number specified.$'

CMD_DOSVER      PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        LEA     DI,DOSVER_?_STR
        CALL    HELP_SWITCH
        JNC     DOSVER_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     DOSVER_OPERR
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JNC     DOSVER_SET_VER
        ;-----------------------------------
        LEA     DX,DOSVER_MSG
        CALL    WRITE_STRING
        MOV     AH,30H
        INT     21H
        MOV     DL,AL
        XOR     DH,DH
        CALL    WRITE_DECIMAL
        MOV     DL,'.'
        CALL    WRITE_CHAR
        MOV     DL,AH
        CALL    WRITE_DECIMAL
        JMP     Short DOVER_DONE_2
        ;-----------------------------------
DOSVER_SET_VER:
        LEA     SI,CMD_PARAM
        MOV     CX,SI
        XOR     BH,BH
DOSVER_VER_LOOP:
        CLD
        LODSB
        CMP     AL,'.'
        JE      DOSVER_DOT
        OR      AL,AL
        JNZ     DOSVER_VER_LOOP
        MOV     SI,CX
        CALL    STR_TO_NUM_16
        JC      DOSVER_BAD_VER
        OR      AH,AH
        JNZ     DOSVER_BAD_VER
        OR      BH,BH
        JNZ     DOSVER_MINOR_VER
        MOV     BL,AL
        JMP     Short DOSVER_CHANGE_VER
DOSVER_MINOR_VER:
        MOV     BH,AL
DOSVER_CHANGE_VER:
        STC
        CALL    CHECK_OS
        JC      DOSVER_DONE
        MOV     AH,0BH
        INT     32H
        JC      DOSVER_BAD_VER
        JMP     Short DOSVER_DONE
DOSVER_DOT:
        OR      BH,BH
        JNZ     DOSVER_BAD_VER
        MOV     BYTE PTR[SI-1],00H
        XCHG    SI,CX
        CALL    STR_TO_NUM_16
        JC      DOSVER_BAD_VER
        OR      AH,AH
        JNZ     DOSVER_BAD_VER
        MOV     BL,AL
        INC     BH
        MOV     SI,CX
        JMP     Short DOSVER_VER_LOOP
DOSVER_BAD_VER:
        LEA     DX,DOSVER_BAD_VER_MSG
        CALL    WRITE_STRING
        JMP     Short DOVER_DONE_2
        ;-----------------------------------
DOSVER_OPERR:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
DOVER_DONE_2:
        CALL    NEW_LINE
DOSVER_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CMD_DOSVER      ENDP

;***********************************************************************
VERIFY_MSG1     DB      'Verify is $'
VERIFY_ERRMSG   DB      'Valid command line parameter is ON or OFF.$'

CMD_VERIFY      PROC
        PUSHALL
        LEA     DI,VERIFY_?_STR
        CALL    HELP_SWITCH
        JNC     VERIFY_DONE
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      VERIFY_SHOWSTAT
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     VERIFY_OPERR
        ;-----------------------------------
        MOV     CX,2
        CALL    GET_CMD_PARAM
        LEA     SI,CMD_PARAM
        CALL    CHECK_ONOFF
        JC      VERIFY_OPERR
        MOV     AH,2EH
        INT     21H
        JMP     Short VERIFY_DONE
        ;-----------------------------------
VERIFY_SHOWSTAT:
        LEA     DX,VERIFY_MSG1
        CALL    WRITE_STRING
        MOV     AH,54H
        INT     21H
        CALL    WRITE_ONOFF
        JMP     Short VERIFY_DONE_1
VERIFY_OPERR:
        LEA     DX,VERIFY_ERRMSG
        CALL    WRITE_STRING
VERIFY_DONE_1:
        CALL    NEW_LINE
VERIFY_DONE:
        POPALL
        RET
CMD_VERIFY      ENDP

;***********************************************************************
BREAK_MSG       DB      'BREAK is $'

CMD_BREAK       PROC
        PUSHALL
        LEA     DI,BREAK_?_STR
        CALL    HELP_SWITCH
        JNC     BREAK_DONE
        MOV     CX,3
        CALL    GET_CMD_PARAM
        JNC     BREAK_OPERR
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      BREAK_SHOWSTAT
        ;-----------------------------------
        XOR     DL,DL
        LEA     SI,CMD_PARAM
        CALL    CHECK_ONOFF
        JC      BREAK_OPERR
        MOV     DL,AL
        MOV     AX,3301H
        INT     21H
        JMP     Short BREAK_DONE
        ;-----------------------------------
BREAK_SHOWSTAT:
        LEA     DX,BREAK_MSG
        CALL    WRITE_STRING
        MOV     AX,3300H
        INT     21H
        MOV     AL,DL
        CALL    WRITE_ONOFF
        JMP     Short BREAK_DONE_1
BREAK_OPERR:
        LEA     DX,VERIFY_ERRMSG
        CALL    WRITE_STRING
BREAK_DONE_1:
        CALL    NEW_LINE
BREAK_DONE:
        POPALL
        RET
CMD_BREAK       ENDP

;***********************************************************************
TYPE_OPERRMSG   DB      'Specify a filename to show its contents.$'
TYPE_READERRMSG DB      0AH,0DH,'TYPE ERROR: Unable to read from the file.$'

CMD_TYPE        PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        ;-----------------------------------
        LEA     DI,TYPE_?_STR
        CALL    HELP_SWITCH
        JNC     TYPE_DONE
        ;-----------------------------------
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JC      TYPE_OPERR_1
        INC     CX      ;CX=3
        CALL    GET_CMD_PARAM
        JNC     TYPE_OPERR_3
        ;-----------------------------------
        STC
        CALL    ALLOCATE_DISK_BUFFER
        JC      TYPE_DONE_2
        MOV     CX,2
        CALL    GET_CMD_PARAM
        LEA     DX,CMD_PARAM
        MOV     AX,3D00H
        INT     21H
        JC      TYPE_WRTERRMSG
        MOV     DI,AX
        XOR     DX,DX
TYPE_LOOP:
        MOV     CX,DISK_BUF_LENGTH
        MOV     BX,DI
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    READ_FILE
        POP     DS
        JC      TYPE_READERR
        OR      AX,AX
        JZ      TYPE_LOOP_DONE
        MOV     CX,AX
        MOV     BX,01H          ;Write to STDOUT
        PUSH    DS
        MOV     DS,DISK_BUF_SEG
        CALL    WRITE_FILE
        POP     DS
        JMP     Short TYPE_LOOP
TYPE_LOOP_DONE:
        MOV     AH,3EH
        INT     21H
        JMP     Short TYPE_DONE_2
        ;-----------------------------------
TYPE_OPERR_3:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
        MOV     DL,'.'
        CALL    WRITE_CHAR
TYPE_OPERR_1:
        LEA     DX,TYPE_OPERRMSG
        JMP     Short TYPE_WRTMSG
TYPE_WRTERRMSG:
        CALL    WRITE_ERROR_MESSAGE
        JMP     Short TYPE_DONE
TYPE_READERR:
        MOV     AH,3EH
        INT     21H
        LEA     DX,TYPE_READERRMSG
TYPE_WRTMSG:
        CALL    WRITE_STRING
        ;-----------------------------------
TYPE_DONE:
        CALL    NEW_LINE
TYPE_DONE_2:
        CALL    FREE_DISK_BUFFER
        POP     DI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
CMD_TYPE        ENDP

;***********************************************************************
MQC_CREATOR_STR         LABEL   BYTE
                DB      'Programmer: Mohammad Mehdipour',CR,LF
CONTACT_STR     DB      'Contact$'
CONTACT_MAIL    DB      ': Mo.Mehdipour@gmail.com$'

CMD_MINITAK_QUERY_CREATOR       PROC
        PUSH    DX
        MOV     WORD PTR CMD_STR[0],'EV'
        MOV     WORD PTR CMD_STR[2],0052H
        CALL    CMD_VER
        CALL    NEW_LINE
        LEA     DX,MQC_CREATOR_STR
        CALL    WRITE_STRING
        LEA     DX,CONTACT_MAIL
        CALL    WRITE_STRING
        POP     DX
        RET
CMD_MINITAK_QUERY_CREATOR       ENDP

;***********************************************************************
CONTACT_STR_2   DB      ' to$'

CMD_CONTACT     PROC
        PUSH    DX
        PUSH    DI
        LEA     DI,CONTACT_?_STR
        CALL    HELP_SWITCH
        JNC     CONTACT_DONE
        MOV     CX,2
        CALL    GET_CMD_PARAM
        JNC     CONTACT_INVPARAM
        LEA     DX,CONTACT_STR
        CALL    WRITE_STRING
        LEA     DX,CONTACT_STR_2
        CALL    WRITE_STRING
        LEA     DX,CONTACT_MAIL
        CALL    WRITE_STRING
        JMP     Short CONTACT_DONE
CONTACT_INVPARAM:
        MOV     AL,ERR_ICLPARAMETERS
        CALL    WRITE_ERROR_MESSAGE
CONTACT_DONE:
        POP     DI
        POP     DX
        RET
CMD_CONTACT     ENDP

;***********************************************************************
CMDLINE_STR             DB              'CMDLINE=',00H

EXEC_SS_TEMP            DW              ?
EXEC_SP_TEMP            DW              ?
ECMD_COM_EXT            DB              'COM',00H
ECMD_EXE_EXT            DB              'EXE',00H
ECMD_FLAG               DB              ?

ECMD_ERROR_MODE         DB              1       ;1=Show error messages
                                                ;0=Be quiet for errors

EXECUTE_EXTERNAL_COMMAND        PROC
        MOV     CS:EXEC_SS_TEMP,SS
        MOV     CS:EXEC_SP_TEMP,SP
        PUSH    CS
        POP     ES
        LEA     SI,CMD_LINE_BUF
        MOV     AL,8
        MOV     AH,BYTE PTR[SI]
        CALL    STR_SHIFT_RIGHT
        MOV     DI,SI
        LEA     SI,CMDLINE_STR
        CALL    STR_COPY
        MOV     SI,DI
        MOV     BYTE PTR[SI+8],AH
        CALL    SET_ENV_VAR
        ADD     SI,8
        CLD
ECMD_TRUN_LEFT:
        LODSB
        CMP     AL,' '
        JE      ECMD_TRUN_LEFT
        INC     SI
ECMD_TRUN_CMD:
        LODSB
        OR      AL,AL
        JZ      ECMD_NOCMDLINE
        CMP     AL,' '
        JNE     ECMD_TRUN_CMD
ECMD_FIND_CMD_LINE:
        LODSB
        OR      AL,AL
        JZ      ECMD_NOCMDLINE
        CMP     AL,' '
        JE      ECMD_FIND_CMD_LINE
        DEC     SI
        CALL    STR_LENGTH
        CMP     AX,7EH
        JA      ECMD_BAD_CMD_LINE_LEN
        MOV     EXEC_CMD_LINE_LEN,AL
        MOV     BX,AX
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,EXEC_CMD_LINE
        CALL    STR_COPY
        MOV     ES:BYTE PTR[BX+DI],0DH
        JMP     Short EXEC_CMDLINE_DONE
ECMD_NOCMDLINE:
        MOV     WORD PTR EXEC_CMD_LINE_LEN,0D00H
EXEC_CMDLINE_DONE:
        LEA     BX,EXEC_EPB
        MOV     AX,CS
        MOV     ES,AX
        MOV     EXEC_CMD_LINE_SEG,AX
        MOV     EXEC_FCB_1_SEG,AX
        MOV     EXEC_FCB_2_SEG,AX

        MOV     CX,1
        CALL    GET_CMD_PARAM
        LEA     DX,CMD_PARAM
        XCHG    DX,BX
        CALL    STR_TO_UPPER
        XCHG    DX,BX
        MOV     SI,DX
        CALL    EXTRACT_FILE_EXT
        JC      ECMD_TRY_COM
        MOV     ECMD_FLAG,0
        LEA     DI,ECMD_COM_EXT
        CALL    COMP_STRS
        JNC     ECMD_EXEC
        LEA     DI,ECMD_EXE_EXT
        CALL    COMP_STRS
        JC      EXEC_CMD_DONE
        JMP     Short ECMD_EXEC
ECMD_TRY_COM:
        MOV     ECMD_FLAG,1
        MOV     SI,DX
        CALL    STR_LENGTH
        ADD     SI,AX
        MOV     WORD PTR[SI],'C.'
        MOV     WORD PTR[SI+2],'MO'
        JMP     Short ECMD_SET_STR_END
ECMD_TRY_EXE:
        MOV     ECMD_FLAG,2
        MOV     SI,DX
        CALL    EXTRACT_FILE_EXT
        MOV     WORD PTR[SI],'XE'
        MOV     WORD PTR[SI+2],0045H    ;'E'=45H
        DEC     SI
ECMD_SET_STR_END:
        MOV     BYTE PTR[SI+4],00H
ECMD_EXEC:
        MOV     AX,4B00H
        INT     21H
        JNC     EXEC_CMD_SUCCESS
        CMP     AL,ERR_FNFOUND
        JE      ECMD_CONTINUE
        CMP     AL,ERR_PNFOUND
        JNE     ECMD_FAILURE
ECMD_CONTINUE:
        PUSH    CS
        POP     DS
        CMP     ECMD_FLAG,0
        JE      ECMD_FAILURE
        CMP     ECMD_FLAG,1
        JE      ECMD_TRY_EXE
ECMD_FAILURE:
        CMP     AL,ERR_FNFOUND
        JE      ECMD_STC
        CMP     AL,ERR_PNFOUND
        JNE     ECMD_WRTERRMSG
ECMD_STC:
        STC
        JMP     Short EXEC_CMD_DONE
ECMD_WRTERRMSG:
        STC
        CMP     ECMD_ERROR_MODE,0
        JE      EXEC_CMD_DONE
        CALL    WRITE_ERROR_MESSAGE
        CALL    NEW_LINE
        CLC
        JMP     Short EXEC_CMD_DONE
EXEC_CMD_SUCCESS:
        CLI
        MOV     SS,CS:EXEC_SS_TEMP
        MOV     SP,CS:EXEC_SP_TEMP
        STI
        PUSH    CS
        POP     DS
        CALL    RESET_RESERVED_HDLS
        ;Reset DTA address
        LEA     DX,DTA
        CALL    SET_DTA_ADDRESS
        CLC
        JMP     Short EXEC_CMD_DONE
ECMD_BAD_CMD_LINE_LEN:
        STC
EXEC_CMD_DONE:
        RET
EXECUTE_EXTERNAL_COMMAND        ENDP

;***********************************************************************

CMD_RELOAD      PROC
        MOV     AX,4C00H
        INT     21H
CMD_RELOAD      ENDP

;***********************************************************************

CMD_EXIT        PROC
        PUSH    DI
        LEA     DI,EXIT_?_STR
        CALL    HELP_SWITCH
        POP     DI
        JNC     EXIT_RETURN
        TEST    STARTUP_FLAGS,EXIT_CMD_ENABLED
        JZ      EXIT_RETURN
        MOV     AX,4C00H
        INT     21H
EXIT_RETURN:
        RET
CMD_EXIT        ENDP

;***********************************************************************

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
        ;----------------------------
        POP     DX
        POP     AX
        CALL    WAIT_MILI
        PUSH    AX
        ;----------------------------
        IN      AL,61H
        AND     AL,0FCH
        OUT     61H,AL
        POP     AX
BEEP_RETURN:
        RET
SPEAKER_BEEP    ENDP

;***********************************************************************

WRITE_CHAR      PROC
        PUSH    AX
        MOV     AH,02H
        INT     21H
        POP     AX
        RET
WRITE_CHAR      ENDP

;***********************************************************************

WRITE_UNTIL_SPEC_CHAR   PROC
        XCHG    DX,BX
        PUSH    DX
        PUSH    SI
        XOR     SI,SI
START_WRITE:
        MOV     DL,[BX+SI]
        CMP     DL,AL
        JE      WRITE_STR_DONE
        CALL    WRITE_CHAR
        INC     SI
        JMP     SHORT START_WRITE
WRITE_STR_DONE:
        POP     SI
        POP     DX
        XCHG    BX,DX
        RET
WRITE_UNTIL_SPEC_CHAR   ENDP

;***********************************************************************

WRITE_STRING    PROC
        PUSH    AX
        MOV     AH,09H
        INT     21H
        POP     AX
        RET
WRITE_STRING    ENDP

;***********************************************************************

WRITE_ASCIIZ    PROC
        PUSH    AX
        MOV     AL,00H
        CALL    WRITE_UNTIL_SPEC_CHAR
        POP     AX
        RET
WRITE_ASCIIZ    ENDP

;***********************************************************************

READ_KEY_W      PROC
        PUSH    CX
        MOV     CH,AH
        MOV     AH,07H
        INT     21H
        MOV     AH,CH
        POP     CX
        RET
READ_KEY_W      ENDP

;***********************************************************************

READ_KEY_WE     PROC
        PUSH    CX
        MOV     CH,AH
        MOV     AH,01H
        INT     21H
        MOV     AH,CH
        POP     CX
        RET
READ_KEY_WE     ENDP

;***********************************************************************

READ_STRING_BUF         PROC
        PUSH    AX
        MOV     AH,0AH
        INT     21H
        POP     AX
        RET
READ_STRING_BUF         ENDP

;***********************************************************************

GET_TIME        PROC
        PUSH    AX
        MOV     AH,2CH
        INT     21H
        POP     AX
        RET
GET_TIME        ENDP

;***********************************************************************

SET_TIME        PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,2DH
        INT     21H
        POP     BX
        MOV     AH,BH
        POP     BX
        RET
SET_TIME        ENDP

;***********************************************************************

GET_DATE        PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,2AH
        INT     21H
        POP     BX
        MOV     AH,BH
        POP     BX
        RET
GET_DATE        ENDP

;***********************************************************************

SET_DATE        PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,2BH
        INT     21H
        POP     BX
        MOV     AH,BH
        POP     BX
        RET
SET_DATE        ENDP

;***********************************************************************

READ_LOGIC_SECTOR       PROC
        PUSH    AX
        INT     25H
        POP     AX
        POP     AX
        RET
READ_LOGIC_SECTOR       ENDP

;***********************************************************************

WRITE_LOGIC_SECTOR      PROC
        PUSH    AX
        INT     26H
        POP     AX
        POP     AX
        RET
WRITE_LOGIC_SECTOR      ENDP

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

GET_DEFAULT_DRIVE       PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,19H
        INT     21H
        POP     BX
        MOV     AH,BH
        POP     BX
        RET
GET_DEFAULT_DRIVE       ENDP

;***********************************************************************

DECODE_FILE_DATE        PROC
        RCR     CH,1
        MOV     AL,CH
        MOV     CH,CL
        RCR     CH,1
        SHR     CH,1
        SHR     CH,1
        SHR     CH,1
        SHR     CH,1    ;CH = Month number
        AND     CL,1FH  ;CL = Day number
        AND     AL,7FH  ;AL = Year(0-127)
        RET
DECODE_FILE_DATE        ENDP

;***********************************************************************

DECODE_FILE_TIME        PROC
        MOV     AL,CH
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1    ;AL = Hours
        SHL     CX,1
        SHL     CX,1
        SHL     CX,1
        AND     CH,3FH  ;CH = Minutes
        SHR     CL,1
        SHR     CL,1    ;CL = Seconds
        RET
DECODE_FILE_TIME        ENDP

;***********************************************************************

DELETE_FILE     PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,41H
        INT     21H
        POP     BX
        JC      DT_AX_DONE
        MOV     AH,BH
DT_AX_DONE:
        POP     BX
        RET
DELETE_FILE             ENDP

;***********************************************************************

GET_SET_FILE_ATTR       PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,43H
        INT     21H
        POP     BX
        JC      GSFA_AX_DONE
        MOV     AH,BH
GSFA_AX_DONE:
        POP     BX
        RET
GET_SET_FILE_ATTR       ENDP

;***********************************************************************

GET_DRIVE_SPEC  PROC
        MOV     AH,36H
        INT     21H
        RET
GET_DRIVE_SPEC          ENDP

;***********************************************************************

RENAME_FILE     PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,56H
        INT     21H
        POP     BX
        JC      RNF_AX_DONE
        MOV     AH,BH
RNF_AX_DONE:
        POP     BX
        RET
RENAME_FILE     ENDP

;***********************************************************************

SET_DTA_ADDRESS         PROC
        PUSH    AX
        MOV     AH,1AH
        INT     21H
        POP     AX
        RET
SET_DTA_ADDRESS         ENDP

;***********************************************************************

FIND_FIRST_FILE         PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,4EH
        INT     21H
        POP     BX
        JC      FFF_AX_DONE
        MOV     AH,BH
FFF_AX_DONE:
        POP     BX
        RET
FIND_FIRST_FILE         ENDP

;***********************************************************************

FIND_NEXT_FILE          PROC
        MOV     AH,4FH
        INT     21H
        RET
FIND_NEXT_FILE          ENDP

;***********************************************************************

READ_FILE       PROC
        MOV     AH,3FH
        INT     21H
        RET
READ_FILE       ENDP

;***********************************************************************

WRITE_FILE      PROC
        MOV     AH,40H
        INT     21H
        RET
WRITE_FILE      ENDP

;***********************************************************************

OPEN_FILE       PROC
        MOV     AH,3DH
        INT     21H
        RET
OPEN_FILE       ENDP

;***********************************************************************

CLOSE_FILE      PROC
        PUSH    BX
        PUSH    AX
        MOV     AH,3EH
        INT     21H
        POP     BX
        JC      CF_AX_DONE
        MOV     AX,BX
CF_AX_DONE:
        POP     BX
        RET
CLOSE_FILE      ENDP

;***********************************************************************

COMMIT_ALL_FILES        PROC
        PUSH    AX
        MOV     AH,0DH                  ;Flush all file buffers to the disk
        INT     21H
        POP     AX
        RET
COMMIT_ALL_FILES        ENDP

;***********************************************************************

CREATE_NEW_FILE         PROC
        MOV     AH,5BH
        INT     21H
        RET
CREATE_NEW_FILE         ENDP

;***********************************************************************

WRITE_TYPE_?_MSG        PROC
        PUSH    DX
        MOV     DL,'.'
        CALL    WRITE_CHAR
        LEA     DX,TYPE_?_MSG
        CALL    WRITE_STRING
        POP     DX
        RET
WRITE_TYPE_?_MSG        ENDP

;***********************************************************************

WRITE_ERROR_MESSAGE     PROC
        PUSH    AX
        PUSH    DX
        PUSH    SI
        MOV     DL,AL
        LEA     SI,ERROR_TABLE
        CLD
SEARCH_ERROR:
        LODSB
        CMP     AL,0FFH
        JE      SEARCH_ERR_DONE
        CMP     DL,AL
        JE      SEARCH_ERR_DONE
        INC     SI
        INC     SI
        JMP     Short SEARCH_ERROR
SEARCH_ERR_DONE:
        MOV     DX,DS:WORD PTR[SI]
        CALL    WRITE_ASCIIZ
        POP     SI
        POP     DX
        POP     AX
        RET
WRITE_ERROR_MESSAGE     ENDP

;*****************************************************************
;*****************************************************************

;MINIMAN Error Codes
        ERR_UNKNOWN             EQU             0FFH    ;Unknown error
        ERR_BADFILENAME         EQU             0FEH    ;Bad filename
        ERR_DWERROR             EQU             0FDH    ;Disk writing error
        ERR_DRERROR             EQU             0FCH    ;Disk reading error
        ERR_ICLPARAMETERS       EQU             0FBH    ;Invalid command line parameters
        ERR_RSNFOUND            EQU             0FAH    ;Resource strings not found
        ERR_IRSTRINGS           EQU             0F9H    ;Invalid resource strings
        ERR_SYNERROR            EQU             0F8H    ;Syntax error
        ERR_EVNDEFINED          EQU             0F7H    ;Environment variable not defined
        ERR_NEESPACE            EQU             0F6H    ;Not enough environment space
        ERR_TMPARAMETERS        EQU             0F5H    ;Too many parameters
        ERR_NO_PATH             EQU             0F4H    ;No path
        ERR_MNFOUND             EQU             0F3H    ;MINIMAN.COM was not found.
        ERR_IERROR              EQU             0F2H    ;MiniMAN internal error

;*****************************************************************
;*****************************************************************

UNKNOWN_ERR_MSG         DB      'Unknown error',00H
BADFILENAME_MSG         DB      'Invalid file name specified',00H
DISK_WRITE_ERR_MSG      DB      'Error in writing to the disk',00H
DISK_READ_ERR_MSG       DB      'Error in reading from the disk',00H
INVPARAM_MSG            DB      'Invalid command line parameters',00H
RS_NOT_FOUND_MSG        DB      'Resource strings not found',00H
IRSTRINGS_MSG           DB      'Invalid resource strings',00H
SYNTAX_ERR_MSG          DB      'Syntax error',00H
EVNFOUND_MSG            DB      'Environment variable not defined',00H
ERR_NEESPACE_MSG        DB      'Not enough environment space',00H
ERR_TMPARAMETERS_MSG    DB      'Too many parameters',00H
ERR_NO_PATH_MSG         DB      'No Path',00H
NO_MINIMAN_ERR_MSG      DB      'MINIMAN.COM was not found.',00H
INTERNAL_ERR_MSG        DB      'MiniMAN internal error',00H

INV_FUNC_NO_ERR         DB      'Invalid function request',00H
INSUFFICIENT_MEM_ERR    DB      'Not enough memory available.',00H
MCBS_DESTROYED_ERR      DB      'Memory control blocks is destroyed.',00H
ACCESS_DENIED_ERR       DB      'Access is denied.',00H
TMOFILES_ERR            DB      'Error: Too many open files',00H
FNFOUND_ERR             DB      'File not found.',00H
PNFOUND_ERR             DB      'Path not found.',00H
INV_DRIVE_ERR           DB      'Invalid drive specification ',00H
INV_FORMAT_ERR          DB      'Error: Invalid format',00H
INT_24H_FAIL_ERR        DB      CR,LF,'Fail on INT 24H',00H

ERROR_TABLE             LABEL           BYTE
                DB      ERR_BADFILENAME
                DW              OFFSET BADFILENAME_MSG
                DB      ERR_DWERROR
                DW              OFFSET DISK_WRITE_ERR_MSG
                DB      ERR_DRERROR
                DW              OFFSET DISK_READ_ERR_MSG
                DB      ERR_ICLPARAMETERS
                DW              OFFSET INVPARAM_MSG
                DB      ERR_RSNFOUND
                DW              OFFSET RS_NOT_FOUND_MSG
                DB      ERR_IRSTRINGS
                DW              OFFSET IRSTRINGS_MSG
                DB      ERR_SYNERROR
                DW              OFFSET SYNTAX_ERR_MSG
                DB      ERR_EVNDEFINED
                DW              OFFSET EVNFOUND_MSG
                DB      ERR_NEESPACE
                DW              OFFSET ERR_NEESPACE_MSG
                DB      ERR_TMPARAMETERS
                DW              OFFSET ERR_TMPARAMETERS_MSG
                DB      ERR_NO_PATH
                DW              OFFSET ERR_NO_PATH_MSG
                DB      ERR_MNFOUND
                DW              OFFSET NO_MINIMAN_ERR_MSG
                DB      ERR_IERROR
                DW              OFFSET INTERNAL_ERR_MSG
                DB      ERR_IFNUMBER
                DW              OFFSET INV_FUNC_NO_ERR
                DB      ERR_ISMEMORY
                DW              OFFSET INSUFFICIENT_MEM_ERR
                DB      ERR_MCBDESTROYED
                DW              OFFSET MCBS_DESTROYED_ERR
                DB      ERR_ADENIED
                DW              OFFSET ACCESS_DENIED_ERR
                DB      ERR_TMOFILES
                DW              TMOFILES_ERR
                DB      ERR_FNFOUND
                DW              OFFSET FNFOUND_ERR
                DB      ERR_PNFOUND
                DW              OFFSET PNFOUND_ERR
                DB      ERR_IDSPECIFIED
                DW              OFFSET INV_DRIVE_ERR
                DB      ERR_IFORMAT
                DW              OFFSET INV_FORMAT_ERR
                DB      ERR_FAIL24H
                DW              OFFSET INT_24H_FAIL_ERR
                DB      0FFH
                DW              OFFSET UNKNOWN_ERR_MSG

;*****************************************************************
;*****************************************************************
;*****************************************************************
;*****************************************************************
;*****************************************************************
;Help strings of commands
;-------------------------------------------
;       Special characters for HELP_SWITCH procedure:
;               LF:             New line
;               01H:            'Syntax: '
;-------------------------------------------

FASTHELP_?_STR  DB      'Displays a list of available commands and a short description for each of them.',LF
                DB      01H,'FASTHELP',00H

;***********************************************************************

CLS_?_STR       DB      'Clears the screen.',LF
                DB      01H,'CLS',00H

;***********************************************************************

SET_?_STR       DB      'Displays, sets or removes MiniTAK environment variables.',LF
                DB      01H,'SET [variable][=string]',LF,LF
                DB      '  variable:    Specifies the environment variable name',LF
                DB      '  string:      Specifies a series of characters to assign to the variable.',LF,LF
                DB      'Use SET without parameters to display all of the current environment variables.',00H

;***********************************************************************

PATH_?_STR      DB      'Displays or sets a search path for executable files.',LF
                DB      01H,'PATH [[drive:]path[;...]]',LF
                DB      '        PATH ;',LF,LF
                DB      'Use PATH ; to clear all search path settings.',LF
                DB      'Use PATH without parameters to display the current PATH settings.',00H

;***********************************************************************

ECHO_?_STR      DB      'Displays messages, or turns command-echoing on or off.',LF
                DB      01H,'ECHO [ON | OFF]',LF
                DB      '        ECHO [message]',LF,LF
                DB      'Use ECHO without parameters to display the current echo setting.',00H

;***********************************************************************

REM_?_STR       DB      'Records comments (remarks) in a batch file.',LF
                DB      01H,'REM [comment]',00H

;***********************************************************************

CALL_?_STR      DB      'Calls one batch program from another.',LF
                DB      01H,'CALL [drive:][path]filename [batch-parameters]',LF,LF
                DB      '  batch-parameters:    Specifies the batch program command line parameters.',00H

;***********************************************************************

CD_?_STR        DB      'Displays or changes the current directory.',LF
                DB      01H,'CD    [drive:][path]',LF
                DB      '        CHDIR [drive:][path]',LF,LF
                DB      '        CD[..]',LF
                DB      '        CHDIR[..]',LF,LF
                DB      '  ..:          Specifies the parent directory of the current directory',LF,LF
                DB      'Use CD drive: to display the current directory of the specified drive.',LF
                DB      'Use CD without parameters to display the current path of the current drive.',00H

;***********************************************************************

MD_?_STR        DB      'Creates a directory.',LF
                DB      01H,'MD    [drive:]path',LF
                DB      '        MKDIR [drive:]path',00H

;***********************************************************************

RD_?_STR        DB      'Deletes an empty directory.',LF
                DB      01H,'RD    [drive:]path',LF
                DB      '        RMDIR [drive:]path',00H

;***********************************************************************

TYPE_?_STR      DB      'Displays the contents of text files.',LF
                DB      01H,'TYPE [drive:][path]filename',00H

;***********************************************************************

PAUSE_?_STR     DB      'Suspends processing of a batch program.',LF
                DB      01H,'PAUSE [/Q]',LF,LF
                DB      '  /Q:          Only waits for a key input (Quiet)',LF,LF
                DB      'Use PAUSE without /Q parameter to display a message before wait.',00H

;***********************************************************************

LED_?_STR       DB      'Turns the keyboard leds on and off for a specified number of times.',LF
                DB      01H,'LED [/count[,delay]]',LF,LF
                DB      '  count:       Specifies the number of blink times',LF
                DB      '               If count is 0,LED only delays for the specified time.',LF
                DB      '  delay:       Specifies delay time between each blink in milliseconds',LF,LF
                DB      'If no parameters or invalid parameters is specified, default values is used.',00H

;***********************************************************************

EXIT_?_STR      DB      'Quits the MINIMAN.COM command interpreter.',LF
                DB      01H,'EXIT',00H

;***********************************************************************

RESTART_?_STR   DB      'Restarts the computer.',LF
                DB      01H,'RESTART',00H

;***********************************************************************

ATTR_?_STR      DB      'Displays or changes file attributes.',LF
                DB      01H,'ATTR [+R|-R] [+A|-A] [+H|-H] [+S|-S] [drive:][path]filename',LF,LF
                DB      '  +R:          Set Read Only attribute',LF
                DB      '  -R:          Remove Read Only attribute',LF
                DB      '  +A:          Set Archive attribute',LF
                DB      '  -A:          Remove Archive attribute',LF
                DB      '  +H:          Set Hidden attribute',LF
                DB      '  -H:          Remove Hidden attribute',LF
                DB      '  +S:          Set System attribute',LF
                DB      '  -S:          Remove System attribute',LF,LF
                DB      'With no parameters other than filename,ATTR displays file attributes',00H

;***********************************************************************

COPY_?_STR      DB      'Cpies a file',LF
                DB      01H,'COPY source destination',LF,LF
                DB      '  source:      Specifies the source file name to'
                DB      ' be copied',LF
                DB      '  destination: Specifies the destination file'
                DB      ' name',00H

;***********************************************************************

COPYTO_?_STR    DB      'Copies a file from a disk to another disk in the same drive.',LF
                DB      01H,'COPYTO source destination',LF,LF
                DB      '  source:      Specifies the source file name on the first disk to be copied',LF
                DB      '  destination: Specifies the destination file name on the second disk',00H

;***********************************************************************

VER_?_STR       DB      'Displays the MiniTAK version.',LF
                DB      01H,'VER',00H

;***********************************************************************

MEM_?_STR       DB      'Displays current memory status.',LF
                DB      01H,'MEM',00H

;***********************************************************************

VOL_?_STR       DB      'Displays a disk volume label and serial number.',LF
                DB      01H,'VOL [drive:]',LF,LF
                DB      '  drive:       Specifies a drive to display its serial number and label.',LF
                DB      '               Default is the current drive.',00H

;***********************************************************************

PROMPT_?_STR    DB      'Changes the MiniTAK command prompt.',LF
                DB      01H,'PROMPT [text]',LF
                DB      '  text:        Specifies the new command prompt.To have some special characters',LF
                DB      '               in the prompt,you can use the following control characters:',LF
                DB      '               Control Character             Meaning',LF
                DB      '               ออออออออออออออออออฮออออออออออออออออออออออออออออ',LF
                DB      '                       $P        บ Current drive and path',LF
                DB      '                       $N        บ Current drive',LF
                DB      '                       $P        บ Current drive and path',LF
                DB      '                       $$        บ $     (dollar sign)',LF
                DB      '                       $T        บ Current time',LF
                DB      '                       $D        บ Current date',LF
                DB      '                       $G        บ >     ("greater than" sign)',LF
                DB      '                       $L        บ <     ("less than" sign)',LF
                DB      '                       $B        บ |     (pipe)',LF
                DB      '                       $_        บ Enter (new line)',LF
                DB      '                       $E        บ Escape code',LF
                DB      '                       $H        บ Backspace',LF
                DB      '                       $S        บ       (space)',LF
                DB      '                       $C        บ (     (left parenthesis)',LF
                DB      '                       $F        บ )     (right parenthesis)',LF,LF
                DB      'Use with no parameters to reset the prompt to the default setting.',00H

;***********************************************************************

DEL_?_STR       DB      'Deletes one or more files.',LF
                DB      01H,'DEL   [drive:][path]filename [/P]',LF
                DB      '        ERASE [drive:][path]filename [/P]',LF,LF
                DB      '  /P:          Prompts for confirmation before deleting each file.',00H

;***********************************************************************

RENAME_?_STR    DB      'Renames a file on the disk.',LF
                DB      01H,'RENAME [drive:][path]filename [drive:][path]newfilename',LF
                DB      '        REN    [drive:][path]filename [drive:][path]newfilename',00H

;***********************************************************************

DIR_?_STR       DB      'Lists files of a directory on the disk.',LF
                DB      01H,'DIR [drive:][path][filename] [/P] [/A[attrib]]',LF
                DB      '        LS  [drive:][path][filename] [/P] [/A[attrib]]',LF,LF
                DB      '  filename:    Specifies the filename match string. You can use wildcard ',LF
                DB      '               characters(*,?) in the filename.',LF
                DB      '               If no filename is defined,default will be *.*.',LF
                DB      '  /P:          Lists files page per page.',LF
                DB      '  /A:          Defines match attributes:',LF
                DB      '                   R: Read Only        H: Hidden',LF
                DB      '                   A: Archive          S: System',LF
                DB      '                   D: Directory        -: Use as prefix meaning NOT',LF
                DB      '               Example: DIR /AR-SHD',LF
                DB      '               Using /A with no attributes,will list files of any attribute.',LF
                DB      '               If you don',27H,'t use /A switch,default attributes will be RAD.',00H

;***********************************************************************

DOSVER_?_STR    DB      'Displays or sets the version number of DOS reported to DOS programs.',LF
                DB      01H,'DOSVER [version]',LF,LF
                DB      '  version:     Specifies a new version number to set as current DOS version.',LF
                DB      '               Example: DOSVER 6.22 => Changes the current DOS version to 6.22',LF,LF
                DB      'Use DOSVER without parameters to display the current DOS version.',00H

;***********************************************************************

CONTACT_?_STR   DB      'Displays contact information.',LF
                DB      01H,'CONTACT',00H

;***********************************************************************

DATE_?_STR      DB      'Displays or sets the date.',LF
                DB      01H,'DATE [date]',LF,LF
                DB      '  date:        Specifies a new date to set as current date.',LF,LF
                DB      'Use DATE without parameters to display the current date and ask for a new date.',00H

;***********************************************************************

TIME_?_STR      DB      'Displays or sets the time.',LF
                DB      01H,'TIME [time]',LF,LF
                DB      '  time:        Specifies a new time to set as current time.',LF,LF
                DB      'Use TIME without parameters to display the current time and ask for a new time.',00H

;***********************************************************************

VERIFY_?_STR    DB      'Tells MiniTAK whether to verify that your files are written correctly to a',LF
                DB      'disk.',LF
                DB      01H,'VERIFY [ON | OFF]',LF,LF
                DB      'Use VERIFY without parameters to display the current VERIFY setting.',00H

;***********************************************************************

BREAK_?_STR     DB      'Sets or clears extended CTRL+C checking.',LF
                DB      01H,'BREAK [ON | OFF]',LF,LF
                DB      'Use BREAK without parameters to display the current BREAK setting.',00H

;***********************************************************************

END_ADDRESS             LABEL           BYTE

;***********************************************************************
;The following procedures and data types are only needed on program startup:
;---------------------------------------------------------------------------
;PROCEDURES:
;---------------------------------------------------------------------------

;***********************************************************************
INCORRECT_VER_MSG       DB      CR,LF,'Incorrect MiniTAK version.$'

VALIDATE_MINITAK_VERSION        PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        ;-----------------------------------
        MOV     AH,01H
        MOV     SI,0FFFFH
        INT     32H
        OR      SI,SI           ;Check to see whether MiniTAK is active(SI=0).
        JNZ     VMV_NOT_MINITAK
        CMP     AX,MINITAK_VALID_VERSION_WORD
        JE      VMV_DONE
        LEA     DX,INCORRECT_VER_MSG
        CALL    WRITE_STRING
        MOV     AX,4C01H
        INT     21H
        ;-----------------------------------
VMV_DONE:
VMV_NOT_MINITAK:
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
VALIDATE_MINITAK_VERSION        ENDP

;***********************************************************************
INV_SWITCH_MSG  DB      CR,LF,'Invalid switch$'

PROCESS_CMD_LINE_PARAMETERS     PROC
        PUSHALL
        MOV     SI,81H
        MOV     BL,DS:BYTE PTR[80H]
        XOR     BH,BH
        MOV     BYTE PTR[BX+SI],00H
        CMP     BYTE PTR[SI],00H
        JE      PCLP_DONE
        LEA     DI,CMD_STR
        CALL    STR_COPY
        LEA     DI,MAIN_?_STR
        CALL    HELP_SWITCH
        JC      PARAMS_LOOP
        MOV     AX,4C00H
        INT     21H
        ;-----------------------------------
PARAMS_LOOP:
        CLD
        LODSB
        CMP     AL,00H
        JE      PCLP_DONE
        CMP     AL,' '
        JE      PARAMS_LOOP
        CMP     AL,'/'
        JE      CHECK_SWITCH
PCLP_SKIP_PARAM:
        LODSB
        CMP     AL,' '
        JE      PARAMS_LOOP
        CMP     AL,00H
        JE      PCLP_DONE
        JMP     Short PCLP_SKIP_PARAM
CHECK_SWITCH:
        LODSB
        CALL    UPPER_CASE
        CMP     AL,'C'
        JE      C_SWITCH
        CMP     AL,'K'
        JE      K_SWITCH
        CMP     AL,'P'
        JE      P_SWITCH
        LEA     DX,INV_SWITCH_MSG
        CALL    WRITE_STRING
NEXT_PARAM:
        INC     CX
        JMP     Short PARAMS_LOOP
        ;-----------------------------------
C_SWITCH:
        OR      STARTUP_FLAGS,C_CMD_LINE_SWITCH
        JMP     Short EXEC_PARAM
K_SWITCH:
        OR      STARTUP_FLAGS,K_CMD_LINE_SWITCH
EXEC_PARAM:
        LEA     DI,CMD_LINE_BUF
        CALL    STR_COPY
        JMP     Short PCLP_DONE
P_SWITCH:
        AND     STARTUP_FLAGS,NOT EXIT_CMD_ENABLED
        OR      STARTUP_FLAGS,AUTOEXEC_BAT
        ;-----------------------------------
PCLP_DONE:
        POPALL
        RET
PROCESS_CMD_LINE_PARAMETERS     ENDP

;***********************************************************************
BANNER_MESSAGE          DB      CR,LF,CR,LF,'MiniTAK Operating System',CR,LF,'   MiniMan Command Interpreter',CR,LF,00H

SHOW_BANNER     PROC
        PUSH    DX
        LEA     DX,BANNER_MESSAGE
        CALL    WRITE_ASCIIZ
        POP     DX
        RET
SHOW_BANNER     ENDP

;***********************************************************************

INSTALL_INT_24H_HANDLER PROC
        PUSH    AX
        PUSH    DX
        ;Install critical error handler only if is not already installed.
        CALL    CHECK_MINIMAN_INSTALLATION
        JNC     INIT_INT_24H_DONE
        TEST    STARTUP_FLAGS,AUTOEXEC_BAT
        JZ      INIT_INT_24H_DONE
        MOV     AX,2524H
        LEA     DX,INT_24H_HANDLER
        INT     21H
INIT_INT_24H_DONE:
        POP     DX
        POP     AX
        RET
INSTALL_INT_24H_HANDLER ENDP

;***********************************************************************

INSTALL_MINIMAN PROC
        PUSH    AX
        PUSH    DX
        PUSH    ES
        MOV     AX,352FH
        INT     21H
        MOV     WORD PTR OLD_INT_2FH_HANDLER[0],BX
        MOV     WORD PTR OLD_INT_2FH_HANDLER[2],ES
        MOV     AX,252FH
        LEA     DX,INT_2FH_HANDLER
        INT     21H
        POP     ES
        POP     DX
        POP     AX
        RET
INSTALL_MINIMAN ENDP

;***********************************************************************

INITIALIZE      PROC
        PUSH    AX
        PUSH    DX
        ;-----------------------------------
        ;Install Ctrl-Break exit handler (INT 23H)
        MOV     AX,2523H
        LEA     DX,INT_23H_HANDLER
        INT     21H
        ;-----------------------------------
        POP     DX
        POP     AX
        RET
INITIALIZE      ENDP

;***********************************************************************

MINIMAN_INITIALIZE      PROC
        PUSH    CS
        POP     DS
        LEA     AX,END_ADDRESS
        ADD     AX,STACK_SIZE
        CMP     SP,AX
        JAE     STACK_OK
        ;Insufficient stack (insufficient memory)
        MOV     AL,ERR_ISMEMORY
        CALL    WRITE_ERROR_MESSAGE
        MOV     AX,4C01H
        INT     21H
STACK_OK:
        MOV     AH,51H
        INT     21H
        MOV     PSP_SEGMENT,BX
        MOV     AX,CS
        CALL    VALIDATE_MINITAK_VERSION
        CALL    INITIALIZE
        JMP     BEGIN_OS
MINIMAN_INITIALIZE      ENDP

;***********************************************************************

;---------------------------------------------------------------------------
;DATA:
;---------------------------------------------------------------------------

MAIN_?_STR      DB      'Starts a new copy of MiniTAK Command Interpreter.',LF
                DB      01H,'MINIMAN [/P] [/<C|K>command]',LF,LF
                DB      "  /P:          Makes the new Command Interpreter permanent(can't exit)",LF
                DB      '  /Ccommand:   Executes the specified command and returns',LF
                DB      '  /Kcommand:   Executes the specified command and continues running',00H

;***********************************************************************

FASTHELP_MAINMSG        DB      '                         List Of Available Commands',LF
                        DB      ' ษออออออออออออหออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',LF
                        DB      ' บCommand     บDescription                                                   บ',LF
                        DB      ' ฬออออออออออออฮออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน',LF
                        DB      ' บATTR        บDisplays or changes file attributes.                          บ',LF
                        DB      ' บBEEP        บTests the system speaker with a beep signal.                  บ',LF
                        DB      ' บBREAK       บSets or clears extended CTRL+C checking.                      บ',LF
                        DB      ' บCALL        บCalls one batch program from another.                         บ',LF
                        DB      ' บCD          บDisplays or changes the current directory.                    บ',LF
                        DB      ' บCHDIR       บDisplays or changes the current directory.                    บ',LF
                        DB      ' บCLS         บClears the screen.                                            บ',LF
                        DB      ' บCONTACT     บDisplays contact information.                                 บ',LF
                        DB      ' บCOPY        บCopies a file.                                                บ',LF
                        DB      ' บCOPYTO      บCopies a file from a disk to another disk in the same drive.  บ',LF
                        DB      ' บDATE        บDisplays or sets the date.                                    บ',LF
                        DB      ' บDEL         บDeletes one or more files.                                    บ',LF
                        DB      ' บDIR         บLists files of a directory.                                   บ',LF
                        DB      ' บDOSVER      บDisplays or sets the version number of DOS reported to DOS    บ',LF
                        DB      ' บ            บprograms.                                                     บ',LF
                        DB      ' บECHO        บDisplays messages, or turns command-echoing on or off.        บ',LF
                        DB      ' บERASE       บDeletes one or more files.                                    บ',LF
                        DB      ' บEXIT        บQuits the MINIMAN.COM command interpreter.                    บ',LF
                        DB      ' บLED         บTurns keyboard leds on and off for a specified number of      บ',LF
                        DB      ' บ            บtimes.                                                        บ',LF
                        DB      ' บLS          บLists files of a directory(similar to DIR command).           บ',LF
                        DB      ' บMD          บCreates a directory.                                          บ',LF
                        DB      ' บMEM         บDisplays current memory status.                               บ',LF
                        DB      ' บMKDIR       บCreates a directory.                                          บ',LF
                        DB      ' บPATH        บDisplays or sets a search path for executable files.          บ',LF
                        DB      ' บPAUSE       บSuspends processing of a batch program.                       บ',LF
                        DB      ' บPROMPT      บChanges the MiniTAK command prompt.                           บ',LF
                        DB      ' บRD          บDeletes an empty directory.                                   บ',LF
                        DB      ' บREM         บRecords comments (remarks) in a batch file.                   บ',LF
                        DB      ' บREN         บRenames a file.                                               บ',LF
                        DB      ' บRENAME      บRenames a file.                                               บ',LF
                        DB      ' บRESTART     บRestarts the computer.                                        บ',LF
                        DB      ' บRMDIR       บDeletes an empty directory.                                   บ',LF
                        DB      ' บSET         บDisplays, sets or removes MiniTAK environment variables.      บ',LF
                        DB      ' บTIME        บDisplays or sets the time.                                    บ',LF
                        DB      ' บTYPE        บDisplays the contents of text files.                          บ',LF
                        DB      ' บVER         บDisplays the MiniTAK version.                                 บ',LF
                        DB      ' บVERIFY      บDisplays or sets the current write-verify setting for disks.  บ',LF
                        DB      ' บVOL         บDisplays a disk volume label and serial number.               บ',LF
                        DB      ' ศออออออออออออสออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ',LF
                        DB      '                              External Commands                               ',LF
                        DB      ' ษออออออออออออหออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',LF
                        DB      ' บFile Name   บDescription                                                   บ',LF
                        DB      ' ฬออออออออออออฮออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน',LF
                        DB      ' บSYS.COM     บCopies MiniTAK system files and command interpreter to a      บ',LF
                        DB      ' บ            บspecified disk and makes it a MiniTAK system disk.            บ',LF
                        DB      ' ศออออออออออออสออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ',LF
                        DB      'Use /? switch with each of the above commands to see a more detailed help.',00H

        ;***********************************

        END     START

