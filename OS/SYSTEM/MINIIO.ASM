;MiniTAK First Loading System File(MINIIO.ASM -> MINIIO.SYS)

        INCLUDE         ERRCODES.INC

        ;@@@@@@@@@@@@@@@@@@@@@@   EQUIVALENTS  1   @@@@@@@@@@@@@@@@@@@@@
        MAX_DISK_RETRY_COUNT            EQU             3
        FAT12_MAXRSVDSECCNT             EQU             01H
        ;Maximum number of logical sectors on a 3.5 inc. floppy.
        FLOPPY_MAX_LOGIC_SEC_NO         EQU             2879

        FATTR_READ_ONLY                 EQU             01H
        FATTR_HIDDEN                    EQU             02H
        FATTR_SYSTEM                    EQU             04H
        FATTR_VOLUME_ID                 EQU             08H
        FATTR_DIRECTORY                 EQU             10H
        FATTR_ARCHIVE                   EQU             20H
        ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        RLS_DSKBUF_MAX_LEN              EQU             9
        ;@@@@@@@@@@@@@@@@@@@@@@   EQUIVALENTS  2   @@@@@@@@@@@@@@@@@@@@@
        FAT12_EOC                       EQU             0FF8H
        FAT12_BADCLUS                   EQU             0FF7H
        ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;MINIIO.SYS:

.MODEL  SMALL
.CODE
MINIIO_START:
        JMP     MINIIO_INITIALIZER

        ;DOS Variables Rec(DOS Info Block)
        ;Only for compatibility
;#######
        FIRST_MCB               DW              ?
        DOS_VARS_REC            LABEL           BYTE
        FIRST_DEV_DRIVER_OFF    DW              OFFSET NUL_DRIVER
        FIRST_DEV_DRIVER_SEG    DW              ?       ;Cod Segment
                                DW              -1      ;First SFT Off
                                DW              -1      ;First SFT Seg
        CLOCK_DEV_HDR_OFF       DW              OFFSET NUL_DRIVER
        CLOCK_DEV_HDR_SEG       DW              ?       ;Code Segment
        CON_DEV_HDR_OFF         DW              OFFSET NUL_DRIVER
        CON_DEV_HDR_SEG         DW              ?       ;Code Segment
        MAX_SECTOR_SIZE         DW              512
                                DW              -1      ;Cache head buffer off
                                DW              -1      ;Cache head buffer seg
        PATH_TABLE_OFF          DW              OFFSET PATH_TABLE
        PATH_TABLE_SEG          DW              ?       ;Code Segment
                                DW              -1      ;FCB file Table Off
                                DW              -1      ;FCB file Table Seg
                                DW              0       ;Size of FCB file Table
        NUMBER_OF_DRIVES        DB              1
        LASTDRIVE_VALUE         DB              1       ;1=A
        NUL_DRIVER              LABEL           BYTE
                                DW              -1,-1                   ;Pointer to next driver(-1=No more  drivers available)
                                DW              1000100000001111b       ;Driver attrinutes
                                DW              OFFSET NUL_STRATINT     ;Offset address of Strategy routine
                                DW              OFFSET NUL_STRATINT     ;Offset address of Interrupt routine
                                DB              'NUL     '              ;Character device driver name(8 bytes)
;#######
        PATH_TABLE              LABEL           BYTE
        CURRENT_DIRECTORY       DB              'A:\',00H
                                DB              63 DUP(00H)
                                DB              01H     ;Drive bit flags
        DPB_OFF                 DW              OFFSET DPB
        DPB_SEG                 DW              ?       ;Code Segment
                                DW              19      ;Default Dir first cluster
                                DD              0FFFFFFFFH
                                DW              0FFFFH  ;<network>
                                DB              2       ;Offset of first backslash
                                DB              0       ;<unknown>
                                DD              0       ;Pointer to IFS
                                DW              0       ;<unknown>
;#######
        DPB                     LABEL           BYTE
        DPB_DRIVE_NUMBER        DB              0
        DPB_DEV_SUB_UNIT        DB              0
        DPB_BYTES_PER_SEC       DW              512
        DPB_SEC_PER_CLUS        DB              0       ;Minus 1
                                DB              0       ;Clus to sec shift
                                DW              1       ;First FAT sec
                                DB              2       ;Num of FATs
                                DW              224     ;Root dir entries
                                DW              -1      ;Sec num of clus 2
                                DW              -1      ;Tot Clus+1
                                DB              9       ;Length of each FAT
                                DW              19      ;Root dir start sec
                                DD              -1      ;Dev header addr
        DPB_MEDIA_DESCRIPTOR    DB              0F0H    ;3.5" 1.44 MB
                                DB              -1      ;This DPB should be rebuilt
                                DD              0FFFFH  ;Next DPB addr(FFFFH=Last DPB)
                                DW              0       ;Next cluster to be allocated
                                DW              -1      ;Num of free clusters(-1=undefined)
        ;************************
        DISK_RETRY_COUNT                DB      ?
        INT_25H_26H_ACTIVE              DB      0
        INT_25H_26H_STACK_POINTER       DW      ?
        ;************************
        INT_13_INF      DW      ?       ;Max head no. | Max sector no.
        DOS_SEC_NO      DW      0
        BIOS_CYL_NO     DW      0
        BIOS_HEAD_NO    DB      0
        BIOS_SEC_NO     DB      0
        ;************************
        FAT12_ROOT_ENT_COUNT    DW      ?
        FAT12_DRIVE_NO          DB      ?       ;0=A ,1=B ,2=C ,...
        FAT12_NUM_FATS          DB      ?
        FAT12_ROOT_START_SEC    DB      ?
        FAT12_FAT_START_SEC1    DB      ?
        FAT12_FAT_START_SEC2    DB      ?
        FAT12_DATA_START_SEC    DB      ?
        FAT12_MAX_CLUS_NO       DW      ?
        FAT12_SEC_PER_CLUS      DB      ?
        FAT12_DRIVE_SN          DD      ?       ;Drive Serial Number
        ;************************
        NUM_OF_SEC_RW   DW      ?
        FIRST_SEC_NO    DW      ?
        BUFF_ADDR_TEMP  DW      ?
        DRIVE_NO_TEMP   DW      ?
        MAX_HS_VALUES   DW      ?
        ;************************
        DSKBUF_BUFFER_TYPE              DB              ?       ;0=FAT Area
                                                                ;1=Directory Area
                                                                ;2=Data Area
        DSKBUF_MAX_RW_PRTY_DIS          DB              20
;#######
        FIRST_DISK_BUF                  LABEL           BYTE
        DSKBUF_STATUS                   DB              0
        DSKBUF_DRIVE_NO                 DB              ?
        DSKBUF_DRIVE_SERIAL_NUMBER      DD              ?
        DSKBUF_SECTOR_NO                DW              ?
        DSKBUF_WRITE_REQUEST            DB              ?
        DSKBUF_NEXT_BUF_OFF             DW              ?
        DSKBUF_NEXT_BUF_SEG             DW              0
        DSKBUF_REQUEST_PRIORITY         DB              ?
        DSKBUF_DATA_TYPE                DB              0
        DSKBUF_RESERVED                 DB              17 DUP(?)
        DSKBUF_DATA                     DB              512 DUP(?)
         ;************************
        FAT12_RW_DIR_WORD1      DW      ?
        FAT12_RW_DIR_WORD2      DW      ?
        FAT12_RW_DIR_WORD3      DW      ?
        DISK_SEC_TEMP           DB      512 DUP(?)

        DEFAULT_DRIVE_NO        DB      0       ;0=A ,1=B ,2=C ,...
        FAT_ID_BYTE             DB      ?
        DIR_ENT_TEMP            DB      32 DUP(0)
        ;************************
        MAIN_FILE_PATH_ADDR     DD      ?
        FILE_PATH_FLAG          DB      0
        FILE_PATH               DB      16 DUP(00H)
        RFP_MOVE_COUNT          DB      0
        ;************************
        SEARCH_STATUS           DB      0
        SEARCH_DRIVE_NO         DB      0
        SEARCH_PATH             DB      80 DUP(00H)
        SEARCH_PATH_SEGMENT     DW      ?
        SEARCH_PATH_OFFSET      DW      ?
        SEARCH_FILE_ATTR        DB      0
        LAST_FOUND_DIR_ENT      DW      0
        PATH_FILE_NAME          DB      13 DUP(0)
        MATCH_FILE_NAME         DB      13 DUP(0)
        MATCH_STR_BUF1          DB      9 DUP(0)
        MATCH_STR_BUF2          DB      9 DUP(0)
        DIR_11_BYTE_F_NAME      DB      11 DUP(20H)
        ;************************
        DTA_SEGMENT     DW      ?
        DTA_OFFSET      DW      ?
;#######
        ;This DTA actually is not used internally and only shows a typical DTA structure for FIND_FIRST_FILE and FIND_NEXT_FILE.
;        INTERNAL_DTA    LABEL   BYTE           ;DTA Structure
;                        DB      21 DUP(20H)
;        INDTA_ATTR      DB      0
;        INDTA_TIME      DW      0
;        INDTA_DATE      DW      0
;        INDTA_LOWSIZE   DW      0
;        INDTA_HIGHSIZE  DW      0
;        INDTA_NAME      DB      13 DUP(20H)
        ;************************
;#######
        FIRST_FILE_HANDLE               LABEL           BYTE
        HDL_STAT                        DB              0       ;0=Unused Handle
                                                        ;1=Used Handle-normal)
        HDL_ID                          DW              0
                ;Predefined file handles:
                ;       0: Std In      | 2: Std Err     | 4: Std Printer
                ;       1: Std Out     | 3: Std Aux
        HDL_DIRECTION                   DW              ?
        HDL_CHCK_SUM                    DB              ?
        ACCESS_CODE                     DB              ?
        RW_PTR_LOW                      DW              ?
        RW_PTR_HIGH                     DW              ?
        MAX_PRT_LOW                     DW              ?
        MAX_PRT_HIGH                    DW              ?
        NEXT_HDL_OFF                    DW              ?
        NEXT_HDL_SEG                    DW              ?
        FIRST_CLUS_NO                   DW              ?
        SEC_PER_CLUS                    DB              ?
        REDIRECTION_FLAG                DB              ?
        DIRECTION_FLAG                  DB              ?
        SIMULATED_HDL                   DB              ?
        HDL_OWNER                       DW              ?
        HDL_FLAGS                       DB              ?       ;Bit 0: 1=Update file date and time at close
        HDL_RSVD                        DB              11 DUP(0)
        F_NAME                          DB              16 DUP(0)
        ;************************
        ;Names of reserved handles
        RSVD_HDL_CON            DB      'CON',00H
        RSVD_HDL_PRN            DB      'PRN',00H
        RSVD_HDL_AUX            DB      'AUX',00H
        RSVD_HDL_LPT            DB      'LPT',00H
        RSVD_HDL_COM            DB      'COM',00H
        ;************************
        FHB_DIR_ENT             DB      32 DUP(?)
        FHB_DWORD_TEMP          DD      ?
        FHB_WORD_1              DW      ?
        FHB_WORD_2              DW      ?
        FHB_WORD_3              DW      ?
        FHB_WORD_4              DW      ?
        FHB_WORD_5              DW      ?
        FHB_DISK_BUF            DB      512 DUP(?)
        FHB_SYSTEM_CALL         DB      0
        ;************************
        HALT_MSG        DB      'The current running program sent an illegal'
                        DB      ' request to the system. System halted'
                        DB      ' to prevent danger to your system.'
                        DB      00H
        ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;OTHER DATA DEFENITIONS

        ;Disk Buffers
        DSKBUF_1        DB      544 DUP(0)
        DSKBUF_2        DB      544 DUP(0)
        DSKBUF_3        DB      544 DUP(0)
        DSKBUF_4        DB      544 DUP(0)
        DSKBUF_5        DB      544 DUP(0)
        DSKBUF_6        DB      544 DUP(0)
        DSKBUF_7        DB      544 DUP(0)
        DSKBUF_8        DB      544 DUP(0)
        DSKBUF_9        DB      544 DUP(0)
        DSKBUF_10       DB      544 DUP(0)
        DSKBUF_11       DB      544 DUP(0)
        DSKBUF_12       DB      544 DUP(0)
        DSKBUF_13       DB      544 DUP(0)
        DSKBUF_14       DB      544 DUP(0)
        DSKBUF_15       DB      544 DUP(0)
        DSKBUF_16       DB      544 DUP(0)
        DSKBUF_17       DB      544 DUP(0)
        DSKBUF_18       DB      544 DUP(0)
        DSKBUF_19       DB      544 DUP(0)
        DSKBUF_20       DB      544 DUP(0)
        DSKBUF_21       DB      544 DUP(0)
        DSKBUF_22       DB      544 DUP(0)
        DSKBUF_23       DB      544 DUP(0)
        DSKBUF_24       DB      544 DUP(0)
        ;File Handle Blocks
        FHB1            DB      55 DUP(0)
        FHB2            DB      55 DUP(0)
        FHB3            DB      55 DUP(0)
        FHB4            DB      55 DUP(0)
        FHB5            DB      55 DUP(0)
        FHB6            DB      55 DUP(0)
        FHB7            DB      55 DUP(0)
        FHB8            DB      55 DUP(0)
        FHB9            DB      55 DUP(0)
        FHB10           DB      55 DUP(0)
        FHB11           DB      55 DUP(0)
        FHB12           DB      55 DUP(0)
        FHB13           DB      55 DUP(0)
        FHB14           DB      55 DUP(0)


;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;


;=======================================================================;
;=======================================================================;
;=======================================================================;
;=======================================================================;
;=======================================================================;
;                        MTF00011.ASM                                   ;

NUL_STRATINT    PROC    FAR
        RET
NUL_STRATINT    ENDP

;***********************************************************************

GET_DOS_VARS    PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 52H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    CS
        POP     ES
        LEA     BX,DOS_VARS_REC
        RET
GET_DOS_VARS    ENDP

;***********************************************************************

GET_BIOS_DRIVE_NO       PROC
        ;This is only a test version of this procedure
        CMP     DL,1
        JBE     DRIVE_NO_OK
        MOV     DL,80H
DRIVE_NO_OK:
        RET
GET_BIOS_DRIVE_NO       ENDP

;***********************************************************************

VALIDATE_DRIVE_NO       PROC
        ;This code is only a test version of this procedure
        CMP     DL,0
        JNE     INVALID_DRIVE
        CLC
        JMP     Short VDN_RETURN
INVALID_DRIVE:
        STC
VDN_RETURN:
        RET
VALIDATE_DRIVE_NO       ENDP

;***********************************************************************

GET_INT_13_DRIVE_INF    PROC
        MOV     AX,CS:INT_13_INF
        RET
GET_INT_13_DRIVE_INF    ENDP

;***********************************************************************

CALC_BIOS_CHS           PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        PUSH    DX
        PUSH    AX
        INC     AH
        MUL     AH      ;AX = AH*AL = Max_Sec_Per_Track
        MOV     BX,AX
        MOV     AX,DOS_SEC_NO
        INC     AX
        XOR     DX,DX
        DIV     BX
        CMP     DX,0
        JNE     CALC_HS
        DEC     AX
        MOV     BIOS_CYL_NO,AX
        POP     AX
        PUSH    AX
        MOV     BIOS_HEAD_NO,AH
        MOV     BIOS_SEC_NO,AL
        JMP     Short END_CALC
CALC_HS:
        MOV     BIOS_CYL_NO,AX
        POP     AX
        PUSH    AX
        XOR     BH,BH
        MOV     BL,AL
        MOV     AX,DX
        XOR     DX,DX
        DIV     BX
        CMP     DX,0
        JE      SET_HS
        MOV     BIOS_HEAD_NO,AL
        MOV     BIOS_SEC_NO,DL
        JMP     Short END_CALC
SET_HS:
        DEC     AX
        MOV     BIOS_HEAD_NO,AL
        POP     AX
        PUSH    AX
        MOV     BIOS_SEC_NO,AL
END_CALC:
        POP     AX
        POP     DX
        POP     BX
        POP     DS
        RET
CALC_BIOS_CHS           ENDP

;***********************************************************************

READ_LOGIC_SECTOR       PROC
        XCHG    AL,DL
        CALL    VALIDATE_DRIVE_NO
        JC      RLS_DRIVE_ERR
        XCHG    AL,DL
        OR      CX,CX
        JZ      RLS_SUCCESS
        CMP     CX,0FFFFH
        JE      RLS_SECNF_ERR
        ;-----------------------------------
        PUSH    DX
        DEC     CX
        ADD     DX,CX
        INC     CX
        JC      RLS_SEC_ERR
        CMP     DX,FLOPPY_MAX_LOGIC_SEC_NO
        JBE     RLS_NO_SEC_ERR
RLS_SEC_ERR:
        POP     DX
        JMP     RLS_SECNF_ERR
RLS_NO_SEC_ERR:
        POP     DX
        ;-----------------------------------
        PUSH    DS
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    CS
        POP     DS
        ;DS = CS
        ;ES = DS(output buffer)
        ;-----------------------------------
        MOV     NUM_OF_SEC_RW,CX
        MOV     FIRST_SEC_NO,DX
        MOV     BUFF_ADDR_TEMP,BX
        MOV     DRIVE_NO_TEMP,AX
        PUSH    BX
        PUSH    DX
        LEA     BX,DISK_SEC_TEMP
        MOV     DL,AL
        ;DS:BX => sector temp
        ;DL = Drive No
        CALL    FAT12_START_RW
        POP     DX
        POP     BX
        CALL    GET_INT_13_DRIVE_INF
        MOV     MAX_HS_VALUES,AX
        ;DS = CS
        ;ES:BX => output buffer
        ;-----------------------------------
        XCHG    SI,DRIVE_NO_TEMP
        XCHG    DI,MAX_HS_VALUES
REPEAT_READING:
        MOV     DOS_SEC_NO,DX
        CALL    CALC_BIOS_CHS
        TEST    BIOS_SEC_NO,11000000b
        JNZ     RLS_HLT
        PUSH    DX
        PUSH    CX
        MOV     DX,BIOS_CYL_NO
        MOV     CX,6
        SHL     DH,CL
        MOV     CX,DX
        XCHG    CL,CH
        OR      CL,BIOS_SEC_NO
        MOV     DX,SI
        CALL    GET_BIOS_DRIVE_NO
        MOV     DH,BIOS_HEAD_NO
        MOV     AX,0201H

;        INT     13H
        XCHG    DI,MAX_HS_VALUES
        CALL    CHECK_RLS_BUF
        XCHG    DI,MAX_HS_VALUES

        POP     CX
        POP     DX
        DEC     CX
        JZ      RLS_DONE
        ADD     BX,512
        INC     DX
        MOV     AX,DI
        JMP     Short REPEAT_READING
RLS_HLT:
        CALL    HALT
RLS_DONE:
        MOV     AX,SI
        MOV     SI,DRIVE_NO_TEMP
        MOV     DI,MAX_HS_VALUES
        MOV     BX,BUFF_ADDR_TEMP
        MOV     DX,FIRST_SEC_NO
        MOV     CX,NUM_OF_SEC_RW
        POP     ES
        POP     DS
RLS_SUCCESS:
        CLC
        JMP     Short RLS_RETURN
RLS_DRIVE_ERR:
        MOV     AX,ERR_IDSPECIFIED
        STC
        JMP     Short RLS_RETURN
RLS_SECNF_ERR:
        MOV     AX,ERR_SNFOUND
        STC
RLS_RETURN:
        RET
READ_LOGIC_SECTOR       ENDP

;***********************************************************************

NORMALIZE_INT_25H_26H_INPUT     PROC
        CMP     CX,0FFFFH
        JNE     NORMALIZE_SUCCESS
        CMP     WORD PTR[BX+2],0
        JNE     NORMALIZE_FAILURE
        MOV     DX,DS:WORD PTR[BX]
        MOV     CX,WORD PTR[BX+4]
        LDS     BX,DWORD PTR[BX+6]
NORMALIZE_SUCCESS:
        CLC
        JMP     Short NORMALIZE_RETURN
NORMALIZE_FAILURE:
        ;Set error code to Disk Sector Not Found.
        MOV     AX,0408H
        STC
NORMALIZE_RETURN:
        RET
NORMALIZE_INT_25H_26H_INPUT     ENDP

;***********************************************************************

READ_LOGIC_SECTOR_25H   PROC    FAR
;-----------------------------------------------------------------------;
; <INT 25H Handler> | <API Interrupt>                                   ;
;-----------------------------------------------------------------------;
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    BP
        PUSH    DS
        PUSH    ES
        MOV     CS:INT_25H_26H_STACK_POINTER,SP
        ;-----------------------------------
        PUSH    DX
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        MOV     INT_25H_26H_ACTIVE,1
        LEA     BX,DISK_SEC_TEMP
        XOR     DL,DL
        CALL    FAT12_START_RW
        POP     BX
        POP     DS
        POP     DX
        ;-----------------------------------
        PUSH    CX
        PUSH    BX
        PUSH    DS
        CALL    NORMALIZE_INT_25H_26H_INPUT
        JC      RLS_25H_DONE
        CALL    READ_LOGIC_SECTOR
RLS_25H_DONE:
        POP     DS
        POP     BX
        POP     CX
        ;-----------------------------------
        MOV     CS:INT_25H_26H_ACTIVE,0
        CALL    UPDATE_EXT_ERROR_INF
        PUSHF
        POP     CS:INT_25H_26H_STACK_POINTER    ;Use this variable as a temp word
        ADD     SP,18
        PUSH    CS:INT_25H_26H_STACK_POINTER
        POPF
RLS_25H_RETURN:
        RET
READ_LOGIC_SECTOR_25H   ENDP

;***********************************************************************

WRITE_LOGIC_SECTOR      PROC
        XCHG    AL,DL
        CALL    VALIDATE_DRIVE_NO
        JC      WLS_DRIVE_ERR
        XCHG    AL,DL
        OR      CX,CX
        JZ      WLS_SUCCESS
        CMP     CX,0FFFFH
        JE      WLS_SECNF_ERR
        ;-----------------------------------
        PUSH    DX
        DEC     CX
        ADD     DX,CX
        INC     CX
        JC      WLS_SEC_ERR
        CMP     DX,FLOPPY_MAX_LOGIC_SEC_NO
        JBE     WLS_NO_SEC_ERR
WLS_SEC_ERR:
        POP     DX
        JMP     WLS_SECNF_ERR
WLS_NO_SEC_ERR:
        POP     DX
        ;-----------------------------------
        PUSH    DS
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    CS
        POP     DS
        ;DS = CS
        ;ES = DS(output buffer)
        ;-----------------------------------
        MOV     NUM_OF_SEC_RW,CX
        MOV     FIRST_SEC_NO,DX
        MOV     BUFF_ADDR_TEMP,BX
        MOV     DRIVE_NO_TEMP,AX
        PUSH    BX
        PUSH    DX
        LEA     BX,DISK_SEC_TEMP
        MOV     DL,AL
        ;DS:BX => sector temp
        ;DL = Drive No
        CALL    FAT12_START_RW
        POP     DX
        POP     BX
        CALL    GET_INT_13_DRIVE_INF
        MOV     MAX_HS_VALUES,AX
        ;DS = CS
        ;ES:BX => output buffer
        ;-----------------------------------
        XCHG    SI,DRIVE_NO_TEMP
        XCHG    DI,MAX_HS_VALUES
REPEAT_WRITING:
        MOV     DOS_SEC_NO,DX
        CALL    CALC_BIOS_CHS
        TEST    BIOS_SEC_NO,11000000b
        JNZ     WLS_HLT
        PUSH    DX
        PUSH    CX
        MOV     DX,BIOS_CYL_NO
        MOV     CX,6
        SHL     DH,CL
        MOV     CX,DX
        XCHG    CL,CH
        OR      CL,BIOS_SEC_NO
        MOV     DX,SI
        CALL    GET_BIOS_DRIVE_NO
        MOV     DH,BIOS_HEAD_NO
        MOV     AX,0301H

;        INT     13H
        XCHG    DI,MAX_HS_VALUES
        CALL    CHECK_WLS_BUF
        XCHG    DI,MAX_HS_VALUES

        POP     CX
        POP     DX
        DEC     CX
        JZ      WLS_DONE
        ADD     BX,512
        INC     DX
        MOV     AX,DI
        JMP     Short REPEAT_WRITING
WLS_HLT:
        CALL    HALT
WLS_DONE:
        MOV     AX,SI
        MOV     SI,DRIVE_NO_TEMP
        MOV     DI,MAX_HS_VALUES
        MOV     BX,BUFF_ADDR_TEMP
        MOV     DX,FIRST_SEC_NO
        MOV     CX,NUM_OF_SEC_RW
        POP     ES
        POP     DS
WLS_SUCCESS:
        CLC
        JMP     Short WLS_RETURN
WLS_DRIVE_ERR:
        MOV     AX,ERR_IDSPECIFIED
        STC
        JMP     Short WLS_RETURN
WLS_SECNF_ERR:
        MOV     AX,ERR_SNFOUND
        STC
WLS_RETURN:
        RET
WRITE_LOGIC_SECTOR      ENDP

;***********************************************************************

WRITE_LOGIC_SECTOR_26H  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 26H Handler> | <API Interrupt>                                   ;
;-----------------------------------------------------------------------;
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    BP
        PUSH    DS
        PUSH    ES
        MOV     CS:INT_25H_26H_STACK_POINTER,SP
        ;-----------------------------------
        PUSH    DX
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        MOV     INT_25H_26H_ACTIVE,1
        LEA     BX,DISK_SEC_TEMP
        XOR     DL,DL
        CALL    FAT12_START_RW
        POP     BX
        POP     DS
        POP     DX
        ;-----------------------------------
        PUSH    CX
        PUSH    BX
        PUSH    DS
        CALL    NORMALIZE_INT_25H_26H_INPUT
        JC      WLS_26H_DONE
        CALL    WRITE_LOGIC_SECTOR
WLS_26H_DONE:
        POP     DS
        POP     BX
        POP     CX
        JC      WLS_26H_SRW_DONE
        ;-----------------------------------
        PUSH    DX
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        LEA     BX,DISK_SEC_TEMP
        XOR     DL,DL
        CALL    FORCE_FAT12_START_RW
        MOV     INT_25H_26H_ACTIVE,0
        POP     BX
        POP     DS
        POP     DX
        CLC
        ;-----------------------------------
WLS_26H_SRW_DONE:
        CALL    UPDATE_EXT_ERROR_INF
        PUSHF
        POP     CS:INT_25H_26H_STACK_POINTER    ;Use this variable as a temp word
        ADD     SP,18
        PUSH    CS:INT_25H_26H_STACK_POINTER
        POPF
        RET
WRITE_LOGIC_SECTOR_26H  ENDP

;***********************************************************************

DDPT            LABEL           BYTE                                    ;OFFSET
        DB      0DFH    ;*Step rate time(bits 0-3)                       ;00H
                        ;  and head unload time(bits 4-7)
        DB      02H     ;*Head load time((1 to 127)*2 milliseconds)      ;01H
                        ;  and DMA flag(bit 0)
        DB      25H     ;Clock ticks until motor off                    ;02H
        DB      02H     ;Sector size(0=128,1=256,2=512,3=1024)          ;03H
        DB      3FH     ;Sectors per track                              ;04H
        DB      1BH     ;Length of GAP3 when reading/writing            ;05H
        DB      0FFH    ;DTL(Data Length)                               ;06H
        DB      54H     ;Length of GAP3 when formatting                 ;07H
        DB      0F6H    ;Fill character for formatting                  ;08H
        DB      0FH     ;*Head settle time(in milliseconds)              ;09H
        DB      08H     ;*Motor start delay(in 0.125 second intervals)   ;0AH

START_DISKETTE_IO       PROC
        ;Nothing to do in this version
        ;This procedure is called before any disk read/write operation and
        ;  can be used to refresh disk parameter table or do any other necessary intialization before a disk read/write operation.
        RET
START_DISKETTE_IO       ENDP

;***********************************************************************

END_DISKETTE_IO PROC
        ;Nothing to do in this version
        ;This procedure is called after any disk read/write operation and
        ;  can be used to do any necessary finalization after a disk read/write operation.
        RET
END_DISKETTE_IO ENDP

;***********************************************************************

RESET_DISKETTE_CONTROLLER       PROC
        CALL    END_DISKETTE_IO
        PUSHF
        PUSH    AX
        PUSH    DX
        MOV     AH,00H
        MOV     DL,00H  ;Drive number
        INT     13H
        POP     DX
        POP     AX
        POPF
        CALL    START_DISKETTE_IO
        RET
RESET_DISKETTE_CONTROLLER       ENDP

;***********************************************************************

FAT12_UPDATE_CLKTICK    PROC
        PUSHF
        PUSH    CX
        PUSH    DX
        CALL    GET_TICK_COUNT  ;In CX:DX
        MOV     WORD PTR FAT12_SRW_CLKTICK[0],DX
        MOV     WORD PTR FAT12_SRW_CLKTICK[2],CX
        POP     DX
        POP     CX
        POPF
        RET
FAT12_UPDATE_CLKTICK    ENDP

;***********************************************************************

CHECK_DISKETTE_CHANGE_LINE      PROC
;INPUT:  DL=BIOS drive number
;OUTPUT: NONE
        PUSH    AX
        PUSH    DX
        CMP     DL,01H
        JA      CDCL_DONE
        MOV     AH,16H
        INT     13H
        CMP     AH,06H
        JNE     CDCL_DONE
        MOV     DL,CS:FAT12_DRIVE_NO
        MOV     CS:FAT12_SRW_ENABLED,0
        CALL    FAT12_END_RW
        MOV     CS:FAT12_SRW_ENABLED,1
        MOV     AL,DL
        CALL    DSKBUF_RESET_BUFFERS
        MOV     CS:RLS_DSKBUF_VALID,0
CDCL_DONE:
        POP     DX
        POP     AX
        RET
CHECK_DISKETTE_CHANGE_LINE      ENDP

;***********************************************************************
FAT12_SRW_CLKTICK       DD      0
MAX_SRW_CLK_DIS         DD      00000025H       ;18 Ticks = One Second
FAT12_SRW_ENABLED       DB      1               ;0=Don't perform SRW
                                                ;1=Perform SRW

FAT12_START_RW          PROC
        CMP     CS:FAT12_SRW_ENABLED,0
        JE      FAT12_SRW_RETURN
        ;~~~~~~~~~~~~~~~~~~~~
        PUSH    CX
        PUSH    DX
        CALL    GET_TICK_COUNT  ;In CX:DX
        SUB     DX,WORD PTR FAT12_SRW_CLKTICK[0]
        SBB     CX,WORD PTR FAT12_SRW_CLKTICK[2]
        CMP     CX,WORD PTR MAX_SRW_CLK_DIS[2]
        JA      NEW_SRW
        JB      NO_NEW_SRW
        CMP     DX,WORD PTR MAX_SRW_CLK_DIS[0]
        JA      NEW_SRW
NO_NEW_SRW:
        POP     DX
        POP     CX
        JMP     FAT12_SRW_RETURN
NEW_SRW:
        POP     DX
        POP     CX
        ;~~~~~~~~~~~~~~~~~~~~
        CALL    VALIDATE_DRIVE_NO
        JC      NOT_SUPPORTED
        PUSH    AX
        PUSH    ES
        PUSH    DS
        MOV     AX,DS
        MOV     ES,AX
        MOV     AX,CS
        MOV     DS,AX
        PUSH    DX
        MOV     FAT12_MAX_CLUS_NO,CX
        ;-----------------------------------
        MOV     FAT12_DRIVE_NO,DL
        ;Read boot sector
        MOV     CS:DISK_OPERATION_TYPE,0        ;Reading disk
        MOV     CS:DISK_RETRY_COUNT,MAX_DISK_RETRY_COUNT
        CALL    START_DISKETTE_IO
        CALL    GET_BIOS_DRIVE_NO
        CALL    CHECK_DISKETTE_CHANGE_LINE
READ_BOOT_SECTOR:
        XOR     DH,DH
        XOR     CH,CH
        MOV     CL,1
        MOV     AX,0201H        ;Read one sector
        INT     13H
        JNC     BOOT_SECTOR_READ
        DEC     CS:DISK_RETRY_COUNT
        JNZ     READ_BOOT_SECTOR
        CALL    HANDLE_CRITICAL_ERROR
        CALL    RESET_DISKETTE_CONTROLLER
        MOV     CS:DISK_RETRY_COUNT,MAX_DISK_RETRY_COUNT
        JMP     Short READ_BOOT_SECTOR
BOOT_SECTOR_READ:
        CALL    END_DISKETTE_IO
        ;-----------------------------------
        ;Update max head no. and max sector no.(INT_13_INF)
        MOV     AX,ES:[BX+19]
        ;AX = total sectors on the volume
        OR      AX,AX   ;Is total sectors value zero?
        JZ      NOT_SUPPORTED
        MOV     DX,ES:[BX+26]
        DEC     DX
        CMP     DH,0
        JNE     NOT_SUPPORTED
        MOV     AH,DL
        MOV     DX,ES:[BX+24]
        CMP     DH,0
        JNE     NOT_SUPPORTED
        MOV     AL,DL
        MOV     INT_13_INF,AX
        ;-----------------------------------
        MOV     AL,ES:[BX+13]
        MOV     FAT12_SEC_PER_CLUS,AL
        MOV     AL,ES:[BX+16]
        MOV     FAT12_NUM_FATS,AL
        MOV     AX,ES:[BX+17]
        MOV     FAT12_ROOT_ENT_COUNT,AX
        MOV     AX,ES:[BX+14]
        CMP     AH,0
        JNE     NOT_SUPPORTED
        CMP     AL,FAT12_MAXRSVDSECCNT
        JA      NOT_SUPPORTED
        MOV     FAT12_FAT_START_SEC1,AL
        ;-----------------------------------
        MOV     CX,ES:[BX+22]
        OR      CX,CX
        JZ      NOT_SUPPORTED
        ADD     AX,CX
        JC      NOT_SUPPORTED
        CMP     AH,0
        JNE     NOT_SUPPORTED
        CMP     FAT12_NUM_FATS,1
        JE      ONLY_ONE_FAT
        CMP     FAT12_NUM_FATS,2
        JE      TWO_FATS
        JMP     NOT_SUPPORTED
ONLY_ONE_FAT:
        MOV     FAT12_ROOT_START_SEC,AL
        MOV     AL,FAT12_FAT_START_SEC1
        MOV     FAT12_FAT_START_SEC2,AL
        JMP     Short CONTINUE_INF
TWO_FATS:
        MOV     FAT12_FAT_START_SEC2,AL
        ADD     AX,CX
        JC      NOT_SUPPORTED
        CMP     AH,0
        JNE     NOT_SUPPORTED
        MOV     FAT12_ROOT_START_SEC,AL
        ;-----------------------------------
CONTINUE_INF:
        MOV     AX,FAT12_ROOT_ENT_COUNT
        MOV     CX,32
        MUL     CX
        CMP     DX,0
        JNE     NOT_SUPPORTED
        MOV     CX,512
        DIV     CX
        CMP     DX,0
        JE      DONT_ROUND_UP
        INC     AX      ;Round up root sector count
DONT_ROUND_UP:
        ;-----------------------------------
        MOV     CL,FAT12_ROOT_START_SEC
        MOV     DL,AL
        ADD     DL,CL
        JC      NOT_SUPPORTED
        MOV     FAT12_DATA_START_SEC,DL
        ;-----------------------------------
        ;AX = Root sector count
        MOV     CX,ES:[BX+22]
        ADD     AX,CX
        CMP     FAT12_NUM_FATS,1
        JE      ADD_RSVD_SEC_COUNT
        ADD     AX,CX
ADD_RSVD_SEC_COUNT:
        MOV     CX,ES:[BX+14]
        ADD     AX,CX
        MOV     CX,ES:[BX+19]
        OR      CX,CX
        JZ      NOT_SUPPORTED
        CMP     CX,AX
        JBE     NOT_SUPPORTED
        SUB     CX,AX
        MOV     AX,CX
        MOV     CL,FAT12_SEC_PER_CLUS
        XOR     CH,CH
        XOR     DX,DX
        DIV     CX
        INC     AX
        MOV     CX,FAT12_MAX_CLUS_NO
        MOV     FAT12_MAX_CLUS_NO,AX
        MOV     AX,ES:[BX+39]
        CMP     AX,WORD PTR FAT12_DRIVE_SN[0]
        JNE     MEDIUM_CHANGED
        MOV     AX,ES:[BX+41]
        CMP     AX,WORD PTR FAT12_DRIVE_SN[2]
        JE      MEDIUM_NOT_CHANGED
MEDIUM_CHANGED:
        MOV     AX,ES:[BX+39]
        MOV     WORD PTR FAT12_DRIVE_SN[0],AX
        MOV     AX,ES:[BX+41]
        MOV     WORD PTR FAT12_DRIVE_SN[2],AX
        CALL    FAT12_MEDIUM_CHANGED
MEDIUM_NOT_CHANGED:
        POP     DX
        POP     DS
        POP     ES
        POP     AX
        ;CLC    ;not used in this version of this procedure
        JMP     Short FAT12_SRW_RETURN
NOT_SUPPORTED:
        ;Not supported media type - only halt
        CALL    HALT
FAT12_SRW_RETURN:
        CALL    FAT12_UPDATE_CLKTICK
        RET
FAT12_START_RW          ENDP

;***********************************************************************

FORCE_FAT12_START_RW    PROC
        MOV     CS:WORD PTR FAT12_SRW_CLKTICK[0],0
        MOV     CS:WORD PTR FAT12_SRW_CLKTICK[2],0
        CALL    FAT12_START_RW
        RET
FORCE_FAT12_START_RW    ENDP

;***********************************************************************

FAT12_MEDIUM_CHANGED    PROC
        CALL    VALIDATE_DISK_BUFFERS
        MOV     CS:RLS_DSKBUF_VALID,0
        RET
FAT12_MEDIUM_CHANGED    ENDP

;***********************************************************************

GET_DRIVE_SN    PROC
        ;The procedure which goes here is only a test version of GET_DRIVE_SN.
        MOV     AX,CS:WORD PTR FAT12_DRIVE_SN[0]
        MOV     DX,CS:WORD PTR FAT12_DRIVE_SN[2]
        RET
GET_DRIVE_SN    ENDP

;***********************************************************************

CHECK_RLS_BUF   PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        PUSH    SI
        PUSH    DI
        MOV     SI,CX
        CMP     RLS_DSKBUF_VALID,0
        JE      CRLS_BUF_NOT_IN_BUF
        CMP     RLS_DSKBUF_DRIVE_NO,DL
        JNE     CRLS_BUF_NOT_IN_BUF
        MOV     AX,CX
        XCHG    AL,AH
        MOV     CX,6
        SHR     AH,CL
        CMP     AX,RLS_DSKBUF_CYL_NO
        JNE     CRLS_BUF_NOT_IN_BUF
        CMP     RLS_DSKBUF_HEAD_NO,DH
        JNE     CRLS_BUF_NOT_IN_BUF
        MOV     AX,SI
        AND     AL,00111111b
        MOV     AH,RLS_DSKBUF_SEC_NO
        CMP     AL,AH
        JB      CRLS_BUF_NOT_IN_BUF
        ADD     AH,RLS_DSKBUF_LENGTH
        CMP     AL,AH
        JAE     CRLS_BUF_NOT_IN_BUF
        PUSH    SI
        LEA     SI,RLS_DSKBUF_BUFFER
        SUB     AL,RLS_DSKBUF_SEC_NO
        XOR     AH,AH
        MOV     CX,9
        SHL     AX,CL
        ADD     SI,AX
        MOV     DI,BX
        MOV     CX,256
        CLD
   REP  MOVSW
        POP     SI
        MOV     CX,SI
        POP     DI
        POP     SI
        POP     AX
        POP     DS
        RET
        ;-----------------------------------
CRLS_BUF_NOT_IN_BUF:
        MOV     RLS_DSKBUF_VALID,1
        MOV     RLS_DSKBUF_DRIVE_NO,DL
        MOV     RLS_DSKBUF_HEAD_NO,DH
        MOV     AX,SI
        AND     AL,00111111b
        CMP     AL,9
        JA      CRLS_CHECK_SEC_2
        MOV     RLS_DSKBUF_SEC_NO,1
        JMP     Short CRLS_SEC_NO_OK
CRLS_CHECK_SEC_2:
        MOV     RLS_DSKBUF_SEC_NO,10
CRLS_SEC_NO_OK:
        MOV     AX,SI
        XCHG    AL,AH
        MOV     CX,6
        SHR     AH,CL
        MOV     RLS_DSKBUF_CYL_NO,AX
        MOV     AH,BYTE PTR MAX_HS_VALUES[0]
        ;MOV     RLS_DSKBUF_LENGTH,AH
        MOV     CX,SI
        AND     CL,11000000b
        OR      CL,RLS_DSKBUF_SEC_NO
        PUSH    ES
        MOV     DI,BX
        MOV     BX,CS
        MOV     ES,BX
        LEA     BX,RLS_DSKBUF_BUFFER
        MOV     CS:DISK_OPERATION_TYPE,0        ;Reading disk
        MOV     CS:DISK_RETRY_COUNT,MAX_DISK_RETRY_COUNT
        CALL    START_DISKETTE_IO
CRLS_BUF_TRY_READ:
        MOV     AL,RLS_DSKBUF_LENGTH
        MOV     AH,02H
        INT     13H
        JNC     CRLS_BUF_READ_DONE
        DEC     CS:DISK_RETRY_COUNT
        JNZ     CRLS_BUF_TRY_READ
        CALL    HANDLE_CRITICAL_ERROR
        CALL    RESET_DISKETTE_CONTROLLER
        MOV     CS:DISK_RETRY_COUNT,MAX_DISK_RETRY_COUNT
        JMP     Short CRLS_BUF_TRY_READ
CRLS_BUF_READ_DONE:
        CALL    END_DISKETTE_IO
        MOV     BX,DI
        POP     ES
        MOV     CX,SI
        POP     DI
        POP     SI
        POP     AX
        POP     DS
        JMP     CHECK_RLS_BUF
        ;END OF THIS PROCEDURE;
CHECK_RLS_BUF   ENDP

;***********************************************************************

CHECK_WLS_BUF   PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        PUSH    SI
        PUSH    DI
        MOV     SI,CX
        CMP     RLS_DSKBUF_VALID,0
        JE      CWLS_BUF_NOT_IN_BUF
        CMP     RLS_DSKBUF_DRIVE_NO,DL
        JNE     CWLS_BUF_NOT_IN_BUF
        MOV     AX,CX
        XCHG    AL,AH
        MOV     CX,6
        SHR     AH,CL
        CMP     AX,RLS_DSKBUF_CYL_NO
        JNE     CWLS_BUF_NOT_IN_BUF
        CMP     RLS_DSKBUF_HEAD_NO,DH
        JNE     CWLS_BUF_NOT_IN_BUF
        MOV     AX,SI
        AND     AL,00111111b
        MOV     AH,RLS_DSKBUF_SEC_NO
        CMP     AL,AH
        JB      CWLS_BUF_NOT_IN_BUF
        ADD     AH,RLS_DSKBUF_LENGTH
        CMP     AL,AH
        JA      CWLS_BUF_NOT_IN_BUF

        PUSH  SI
        LEA     DI,RLS_DSKBUF_BUFFER
        SUB     AL,RLS_DSKBUF_SEC_NO
        XOR     AH,AH
        MOV     CX,9
        SHL     AX,CL
        ADD     DI,AX
        MOV     SI,BX
        PUSH    ES
        MOV     AX,ES
        MOV     DS,AX
        MOV     AX,CS
        MOV     ES,AX
        MOV     CX,256
        CLD
   REP  MOVSW
        POP     ES
        POP     SI
        MOV     CX,SI
        POP     DI
        POP     SI
        POP     AX
        POP     DS
WLS_TRY_WRITE:
        MOV     AX,0301H
        INT     13H
        JNC     WLS_WRITE_DONE
        DEC     CS:DISK_RETRY_COUNT
        JNZ     WLS_TRY_WRITE
        CALL    HANDLE_CRITICAL_ERROR
        MOV     CS:DISK_RETRY_COUNT,MAX_DISK_RETRY_COUNT
        JMP     Short WLS_TRY_WRITE
WLS_WRITE_DONE:
        CALL    END_DISKETTE_IO
        RET
        ;-----------------------------------
CWLS_BUF_NOT_IN_BUF:
        MOV     RLS_DSKBUF_VALID,0
        MOV     CX,SI
        POP     DI
        POP     SI
        POP     AX
        POP     DS
        MOV     CS:DISK_OPERATION_TYPE,1        ;Writing to disk
        CALL    START_DISKETTE_IO
        MOV     CS:DISK_RETRY_COUNT,MAX_DISK_RETRY_COUNT
        JMP     WLS_TRY_WRITE
        ;END OF THIS PROCEDURE;
CHECK_WLS_BUF   ENDP

;***********************************************************************

DSKBUF_UPDATE_PRIORITIES        PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,FIRST_DISK_BUF
UPDATE_PRIORITIES:
        CMP     BYTE PTR[SI+13],254
        JE      UPDATE_NEXT_BUF
        INC     BYTE PTR[SI+13]
UPDATE_NEXT_BUF:
        CMP     WORD PTR[SI+11],0
        JE      UPDATE_PRIORITIES_DONE
        LDS     SI,[SI+9]
        JMP     Short UPDATE_PRIORITIES
UPDATE_PRIORITIES_DONE:
        POP     DS
        POP     SI
        RET
DSKBUF_UPDATE_PRIORITIES        ENDP

;***********************************************************************

VALIDATE_DISK_BUFFERS   PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        PUSH    DX
        PUSH    SI
        LEA     SI,FIRST_DISK_BUF
VDB_FIND_LOOP:
        CMP     BYTE PTR[SI],00H
        JE      VDB_NEXT_DSKBUF
        CALL    GET_DRIVE_SN
        CMP     AX,[SI+2]
        JNE     VDB_BAD_SN
        CMP     DX,[SI+4]
        JE      VDB_NEXT_DSKBUF
VDB_BAD_SN:
        XOR     AL,AL           ;Only drive A: in this version
        CALL    DSKBUF_RESET_BUFFERS
        JMP     Short VDB_DONE
VDB_NEXT_DSKBUF:
        MOV     AX,[SI+11]
        LDS     SI,[SI+9]
        OR      AX,AX
        JNZ     VDB_FIND_LOOP
VDB_DONE:
        POP     SI
        POP     DX
        POP     AX
        POP     DS
        RET
VALIDATE_DISK_BUFFERS   ENDP

;***********************************************************************

DSKBUF_RESET_BUFFERS     PROC
;-------------------------------------------
;INPUT:         AL=Drive number(0=A,...)
;OUTPUT:        NONE
;-------------------------------------------
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,FIRST_DISK_BUF
RESET_DRIVE_BUFFERS:
        CMP     BYTE PTR[SI],00H
        JE      RDB_NEXT_BUF
        CMP     BYTE PTR[SI+1],AL
        JNE     RDB_NEXT_BUF
        MOV     BYTE PTR[SI],00H
RDB_NEXT_BUF:
        CMP     WORD PTR[SI+11],0
        JE      RDB_DONE
        LDS     SI,[SI+9]
        JMP     Short RESET_DRIVE_BUFFERS
RDB_DONE:
        POP     SI
        POP     DS
        RET
DSKBUF_RESET_BUFFERS     ENDP

;***********************************************************************

DSKBUF_FIND_SECTOR      PROC
        ;This is an access to disk buffers.So,update priorities.
        CALL    DSKBUF_UPDATE_PRIORITIES
        PUSH    BX
        PUSH    CX
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     CX,SI
        LEA     SI,FIRST_DISK_BUF
FIND_LOOP:
        CMP     BYTE PTR[SI],00H
        JE      NEXT_DSKBUF
        CMP     [SI+1],AL
        JNE     NEXT_DSKBUF
        CMP     [SI+6],DX
        JNE     NEXT_DSKBUF
        POP     CX
        CLC
        JMP     Short FIND_DBSEC_DONE
NEXT_DSKBUF:
        MOV     BX,[SI+11]
        MOV     SI,[SI+9]
        MOV     DS,BX
        OR      BX,BX
        JNZ     FIND_LOOP
        ;Sector was not found in the disk buffer
        MOV     SI,CX
        POP     DS
        STC
FIND_DBSEC_DONE:
        POP     CX
        POP     BX
        RET
DSKBUF_FIND_SECTOR      ENDP

;***********************************************************************

DSKBUF_FIND_NEW_SEC     PROC
        PUSH    AX
        PUSH    CX
        MOV     CX,0FFFFH
        ;CL=Minimum Read Priority
        ;CH=Minimum Write Priority
        ;First,search for an unused disk buffer
        MOV     AX,CS
        MOV     DS,AX
        LEA     SI,FIRST_DISK_BUF
FIND_UNUSED_BUF:
        MOV     AL,[SI+14]      ;AL=Buffer data type
        CMP     AL,CS:DSKBUF_BUFFER_TYPE
        JNE     NEXT_BUF
        CMP     BYTE PTR[SI],00H
        JE      DSKBUF_NEW_DONE
        ;-----------------------------------
        MOV     AL,[SI+13]
        CMP     BYTE PTR[SI+8],1
        JE      WRITE_PRIORITY
        CMP     CL,AL
        JBE     NEXT_BUF
        MOV     CL,AL
        JMP     Short NEXT_BUF
WRITE_PRIORITY:
        CMP     CH,AL
        JBE     NEXT_BUF
        MOV     CH,AL
        ;-----------------------------------
NEXT_BUF:
        MOV     AX,[SI+11]
        OR      AX,AX
        JZ      NO_UNUSED_BUF
        MOV     SI,[SI+9]
        MOV     DS,AX
        JMP     Short FIND_UNUSED_BUF
NO_UNUSED_BUF:
        MOV     AX,CS
        MOV     DS,AX
        LEA     SI,FIRST_DISK_BUF
        CMP     CL,0FFH
        JE      FIND_WRITE_PRIORITY
        CMP     CL,CH
        JBE     FIND_READ_PRIORITY
        MOV     AH,CL
        SUB     AH,CH
        CMP     AH,DSKBUF_MAX_RW_PRTY_DIS
        JBE     FIND_READ_PRIORITY
FIND_WRITE_PRIORITY:
        MOV     CL,CH
        MOV     CH,1
        JMP     Short FIND_PRIORITY
FIND_READ_PRIORITY:
        XOR     CH,CH
FIND_PRIORITY:
        MOV     AL,[SI+14]      ;AL=Buffer data type
        CMP     AL,CS:DSKBUF_BUFFER_TYPE
        JNE     NEXT_BUF_2
        CMP     BYTE PTR[SI+8],CH
        JNE     NEXT_BUF_2
        CMP     BYTE PTR[SI+13],CL
        JE      DSKBUF_NEW_DONE
NEXT_BUF_2:
        MOV     AX,[SI+11]
        MOV     SI,[SI+9]
        MOV     DS,AX
        JMP     Short FIND_PRIORITY
DSKBUF_NEW_DONE:
        POP     CX
        POP     AX
        CALL    DSKBUF_DO_WRITE_REQUEST
        RET
DSKBUF_FIND_NEW_SEC     ENDP

;***********************************************************************

DSKBUF_READ_LOGIC_SECTOR        PROC
        CMP     CX,1
        JA      DSKBUF_RLS_MANY_SEC
        OR      CX,CX
        JZ      DSKBUF_RLS_SUCCESS_1
        PUSH    DI
        PUSH    SI
        PUSH    ES
        MOV     DI,DS
        MOV     ES,DI
        CALL    DSKBUF_FIND_SECTOR
        JC      DSKBUF_RLS_NOTINBUF
        ADD     SI,32
DSKBUF_RLS_INBUF:
        ;DS:SI => Disk sector buffer
        MOV     DI,BX
        ;ES:DI => Output buffer
        MOV     BX,CX
        MOV     CX,256
        CLD
   REP  MOVSW
        SUB  DI,512
        MOV  CX,BX
        MOV  BX,DI
        MOV  DI,ES
        MOV  DS,DI
        JMP  Short DSKBUF_RLS_SUCCESS_2
DSKBUF_RLS_NOTINBUF:
        CALL    DSKBUF_FIND_NEW_SEC
        CALL    DSKBUF_SET_BUF_INF
        MOV     BYTE PTR[SI],00H
        ADD     SI,32
        XCHG    SI,BX
        CALL    READ_LOGIC_SECTOR
        XCHG    SI,BX
        JC      DSKBUF_RLS_FAILURE
        MOV     BYTE PTR[SI-32],1
        MOV     BYTE PTR[SI-24],00H
        JMP     Short DSKBUF_RLS_INBUF
DSKBUF_RLS_FAILURE:
        MOV     DI,ES
        MOV     DS,DI
        JMP     Short DSKBUF_RLS_DONE
DSKBUF_RLS_SUCCESS_1:
        CLC
        JMP     Short DSKBUF_RLS_RETURN
DSKBUF_RLS_SUCCESS_2:
        CLC
DSKBUF_RLS_DONE:
        POP     ES
        POP     SI
        POP     DI
        JMP     Short DSKBUF_RLS_RETURN
DSKBUF_RLS_MANY_SEC:
        XCHG    AL,DL
        CALL    FAT12_END_RW
        XCHG    AL,DL
        CALL    READ_LOGIC_SECTOR
DSKBUF_RLS_RETURN:
        RET
DSKBUF_READ_LOGIC_SECTOR        ENDP

;***********************************************************************

DSKBUF_SET_BUF_INF      PROC
        MOV     BYTE PTR[SI],1
        MOV     [SI+1],AL
        MOV     [SI+6],DX
        PUSH    AX
        CALL    GET_DRIVE_SN
        ;DX:AX=Drive Serial Number
        MOV     [SI+2],AX
        POP     AX
        MOV     [SI+4],DX
        MOV     DX,[SI+6]
        MOV     BYTE PTR[SI+13],00H
        RET
DSKBUF_SET_BUF_INF      ENDP

;***********************************************************************

DSKBUF_WRITE_LOGIC_SECTOR       PROC
        CMP     CX,1
        JA      DSKBUF_WLS_MANY_SEC
        OR      CX,CX
        JZ      DSKBUF_WLS_SUCCESS_1
        PUSH    DI
        PUSH    SI
        PUSH    CX
        PUSH    ES
        MOV     DI,DS
        CALL    DSKBUF_FIND_SECTOR
        JC      DSKBUF_WLS_NOTINBUF
DSKBUF_WLS_INBUF:
        MOV     BYTE PTR[SI+8],1
        ADD     SI,32
        MOV     CX,DS
        MOV     ES,CX
        MOV     DS,DI
        MOV     DI,BX
        XCHG    SI,DI
        ;DS:SI => Input buffer
        ;ES:DI => Disk sector buffer
        MOV     CX,256
        CLD
   REP  MOVSW
        JMP     Short DSKBUF_WLS_SUCCESS_2
DSKBUF_WLS_NOTINBUF:
        CALL    DSKBUF_FIND_NEW_SEC
        CALL    DSKBUF_SET_BUF_INF
        JMP     Short DSKBUF_WLS_INBUF
DSKBUF_WLS_MANY_SEC:
        XCHG    AL,DL
        CALL    FAT12_END_RW
        XCHG    AL,DL
        CALL    WRITE_LOGIC_SECTOR
        JMP     Short DSKBUF_WLS_RETURN
DSKBUF_WLS_SUCCESS_2:
        POP     ES
        POP     CX
        POP     SI
        POP     DI
DSKBUF_WLS_SUCCESS_1:
        CLC
DSKBUF_WLS_RETURN:
        RET
DSKBUF_WRITE_LOGIC_SECTOR       ENDP

;***********************************************************************

DSKBUF_DO_WRITE_REQUEST         PROC
        CMP     BYTE PTR[SI],00H
        JE      DO_WRT_REQ_RETURN
        CMP     BYTE PTR[SI+8],00H
        JE      DO_WRT_REQ_RETURN
        PUSH    AX
        PUSH    CX
        MOV     CX,DX
        ;-----------------------------------
        PUSH    BX
        LEA     BX,DISK_SEC_TEMP
        XOR     DL,DL
        CALL    FAT12_START_RW
        POP     BX
        ;-----------------------------------
        MOV     AL,[SI+1]
        CALL    GET_DRIVE_SN
        XCHG    CX,DX
        CMP     AX,[SI+2]
        JNE     SERIAL_ERROR
        CMP     CX,[SI+4]
        JNE     SERIAL_ERROR
        MOV     AL,[SI+1]
        MOV     CX,1
        XCHG    DX,[SI+6]
        ADD     SI,32
        XCHG    SI,BX
        CALL    WRITE_LOGIC_SECTOR
        XCHG    SI,BX
        JC      WRT_REQ_ERR
        SUB     SI,32
        XCHG    DX,[SI+6]
        MOV     BYTE PTR[SI+8],00H
        JMP     Short WRT_REQ_DONE
SERIAL_ERROR:
        ;*ONLY IN THIS VERSION*;
        CALL    HALT
        JMP     Short WRT_REQ_DONE
WRT_REQ_ERR:
        SUB     SI,32
        XCHG    DX,[SI+6]
        ;*ONLY IN THIS VERSION*;
        CALL    HALT
WRT_REQ_DONE:
        POP     CX
        POP     AX
        CALL    FAT12_UPDATE_CLKTICK
DO_WRT_REQ_RETURN:
        RET
DSKBUF_DO_WRITE_REQUEST         ENDP

;***********************************************************************

FAT12_END_RW    PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        PUSH    SI
        ;DS=CS
        LEA     SI,FIRST_DISK_BUF
END_RW_LOOP:
        CMP     BYTE PTR[SI+8],01H
        JE      WRITE_REQUEST
FERW_NEXT_DSKBUF:
        MOV     BX,[SI+11]
        OR      BX,BX
        JZ      END_RW_DONE
        MOV     SI,[SI+9]
        MOV     DS,BX
        JMP     Short END_RW_LOOP
WRITE_REQUEST:
        CALL    DSKBUF_DO_WRITE_REQUEST
        JMP     Short FERW_NEXT_DSKBUF
END_RW_DONE:
        POP     SI
        POP     BX
        POP     DS
        CALL    FAT12_UPDATE_CLKTICK
        RET
FAT12_END_RW    ENDP

;***********************************************************************

CALC_FAT12_FAT_ENT_POS          PROC
        ;Multiply AX by 3
        PUSH    DX
        PUSH    CX
        MOV     CX,AX
        SHL     AX,1
        ADD     AX,CX
        ;Divide AX by 2
        SHR     AX,1    ;OK and continue
        MOV     CX,512
        XOR     DX,DX
        DIV     CX      ;DX:AX/CX
        POP     CX
        MOV     CL,AL
        MOV     AX,DX
        POP     DX
        RET
CALC_FAT12_FAT_ENT_POS          ENDP

;***********************************************************************

FAT12_READ_FAT_ENTRY            PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FAT12_RW_DIR_WORD1,BX
        MOV     FAT12_RW_DIR_WORD2,CX
        MOV     FAT12_RW_DIR_WORD3,DX
        CMP     AX,FAT12_MAX_CLUS_NO
        JA      INVD_CLUS_NO
        PUSH    AX
        CALL    CALC_FAT12_FAT_ENT_POS
        XOR     CH,CH
        ADD     CL,FAT12_FAT_START_SEC1
        ;-----------------------------------
        PUSH    AX
        XOR     AH,AH
        MOV     DX,CX
READ_SECTOR:
        MOV     CX,1
        MOV     AL,FAT12_DRIVE_NO
        LEA     BX,DISK_SEC_TEMP
        MOV     CS:DSKBUF_BUFFER_TYPE,0
        CALL    DSKBUF_READ_LOGIC_SECTOR
        ;-----------------------------------
        CMP     AH,0
        JNZ     READ_NEXT_BYTE
        POP     AX
        ADD     BX,AX
        MOV     CX,AX
        POP     AX
        XOR     AH,AH
        RCR     AL,1
        ADC     AH,0
        MOV     AL,[BX]
        INC     DX
        INC     BX
        PUSH    AX
        MOV     AH,1
        CMP     CX,511
        JE      READ_SECTOR
READ_NEXT_BYTE:
        POP     AX
        MOV     CL,AH
        MOV     AH,[BX]
        CMP     CL,1    ;Is the cluster number odd?
        JE      FETCH_HIGH_12_BITS
        AND     AX,0FFFH
        JMP     Short RFE_DONE
FETCH_HIGH_12_BITS:
        MOV     CL,4
        SHR     AX,CL
        JMP     Short RFE_DONE
INVD_CLUS_NO:
        CALL    HALT
RFE_DONE:
        MOV     DX,FAT12_RW_DIR_WORD3
        MOV     CX,FAT12_RW_DIR_WORD2
        MOV     BX,FAT12_RW_DIR_WORD1
        POP     DS
RFE_RETURN:
        CALL    FAT12_UPDATE_CLKTICK
        RET
FAT12_READ_FAT_ENTRY            ENDP

;***********************************************************************

FAT12_WRITE_FAT_ENTRY           PROC
        PUSH    DS
        PUSH    AX
        PUSH    CS
        POP     DS
        MOV     FAT12_RW_DIR_WORD1,BX
        MOV     FAT12_RW_DIR_WORD2,CX
        MOV     FAT12_RW_DIR_WORD3,DX
        CMP     AX,FAT12_MAX_CLUS_NO
        JA      INVD_CLUS_NO_2
        CALL    CALC_FAT12_FAT_ENT_POS
        XOR     CH,CH
        ADD     CL,FAT12_FAT_START_SEC1
        ;-----------------------------------
        PUSH    AX
        XOR     AH,AH
        MOV     DX,CX
WREAD_SECTOR:
        MOV     CX,1
        MOV     AL,FAT12_DRIVE_NO
        LEA     BX,DISK_SEC_TEMP
        MOV     CS:DSKBUF_BUFFER_TYPE,0
        CALL    DSKBUF_READ_LOGIC_SECTOR
        ;-----------------------------------
        CMP     AH,0
        JNZ     WREAD_NEXT_BYTE
        POP     AX
        ADD     BX,AX
        MOV     CX,AX
        ;-----------------------------------
        POP     AX
        PUSH    AX
        MOV     AH,AL
        AND     AH,01H
        ;-----------------------------------
        MOV     AL,[BX]
        PUSH    CX
        MOV     CX,FAT12_RW_DIR_WORD2
        CMP     AH,1
        JE      ODD_CLUSTER
        ;Even Cluster
        MOV     AL,CL
        JMP     Short NEXT_BYTE
ODD_CLUSTER:
        MOV     AH,CL
        MOV     CL,4
        SHL     AH,CL
        AND     AL,0FH
        OR      AL,AH
        ;-----------------------------------
NEXT_BYTE:
        MOV     [BX],AL
        POP     CX
        PUSH    CX
        MOV     AH,1
        CMP     CX,511
        JE      WRITE_SECTOR
        ;-----------------------------------
AFTER_WRITE:
        INC     DX
        INC     BX
        POP     CX
        PUSH    CX
        CMP     CX,511
        JE      WREAD_SECTOR
        DEC     DX
        ;-----------------------------------
WREAD_NEXT_BYTE:
        POP     CX
        POP     AX
        PUSH    AX
        MOV     AH,AL
        AND     AH,01H
        MOV     AL,[BX]
        MOV     CX,FAT12_RW_DIR_WORD2
        CMP     AH,1
        JNE     EVEN_CLUSTER
        ;Odd Cluster
        SHL     CX,1
        SHL     CX,1
        SHL     CX,1
        SHL     CX,1    ;high 8 bits
        MOV     AL,CH
        JMP     Short WRITE_NEXT_BYTE
EVEN_CLUSTER:
        AND     CH,0FH
        AND     AL,0F0H
        OR      AL,CH
        ;-----------------------------------
WRITE_NEXT_BYTE:
        MOV     [BX],AL
        XOR     AH,AH
WRITE_SECTOR:
        MOV     AL,FAT12_DRIVE_NO
        MOV     CX,1
        LEA     BX,DISK_SEC_TEMP
        MOV     CS:DSKBUF_BUFFER_TYPE,0
        CALL    DSKBUF_WRITE_LOGIC_SECTOR
        ;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;UPDATE NEXT FAT IF EXISTS
        ;DS=CS
        CMP     FAT12_NUM_FATS,1
        JNA     NEXT_FAT_UPDATED
        PUSH    DX
        SUB     DL,FAT12_FAT_START_SEC1
        SBB     DH,0
        ADD     DL,FAT12_FAT_START_SEC2
        ADC     DH,0
        MOV     CS:DSKBUF_BUFFER_TYPE,0
        CALL    DSKBUF_WRITE_LOGIC_SECTOR
        POP     DX
NEXT_FAT_UPDATED:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;        
        CMP     AH,1
        JE      AFTER_WRITE
        JMP     Short WRITEFE_DONE
        ;-----------------------------------
INVD_CLUS_NO_2:
        CALL    HALT
WRITEFE_DONE:
        POP     AX
        MOV     DX,FAT12_RW_DIR_WORD3
        MOV     CX,FAT12_RW_DIR_WORD2
        MOV     BX,FAT12_RW_DIR_WORD1
        POP     DS
WFE_RETURN:
        CALL    FAT12_UPDATE_CLKTICK
        RET
FAT12_WRITE_FAT_ENTRY           ENDP

;***********************************************************************

CALC_ROOT_ENT_POS       PROC
        PUSH    AX
        MOV     CL,16
        DIV     CL      ;AX/CL
        CMP     AH,0
        JA      CALC_OFFSET
        DEC     AL
        MOV     AH,16
CALC_OFFSET:
        DEC     AH
        MOV     CL,4
        SHL     AH,CL   ;AH = AH*16
        MOV     CL,AH
        MOV     CH,AL
        POP     AX
        RET
CALC_ROOT_ENT_POS       ENDP

;***********************************************************************

FAT12_READ_DIR_ENTRY            PROC
        CMP     AX,FAT12_ROOT_ENT_COUNT
        JA      INVD_ENT_NO
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    CX
        CALL    CALC_ROOT_ENT_POS
        ADD     CH,FAT12_ROOT_START_SEC
        JC      NOT_SUPPORTED_SEC
        ;-----------------------------------
        MOV     FAT12_RW_DIR_WORD1,CX
        MOV     FAT12_RW_DIR_WORD2,BX
        MOV     FAT12_RW_DIR_WORD3,DX
        ;-----------------------------------
        PUSH    AX
        MOV     AL,FAT12_DRIVE_NO
        XOR     DX,DX
        MOV     DL,CH
        MOV     CX,1
        LEA     BX,DISK_SEC_TEMP
        MOV     CS:DSKBUF_BUFFER_TYPE,1
        CALL    DSKBUF_READ_LOGIC_SECTOR
        ;-----------------------------------
        MOV     CX,FAT12_RW_DIR_WORD1
        XOR     CH,CH
        SHL     CX,1    ;CX*2
        ADD     BX,CX
        ;Exchange BX and SI
        XCHG    BX,SI
        ;Move 32 bytes from DS:SI to ES:DI
        MOV     CX,16
        CLD             ;for increment
        ;DS:SI -> ES:DI
   REP  MOVSW
        ;Restore SI from BX
        MOV     SI,BX
        SUB     DI,32
        ;-----------------------------------
        POP     AX
        POP     CX
        MOV     DX,FAT12_RW_DIR_WORD3
        MOV     BX,FAT12_RW_DIR_WORD2
        POP     DS
        JMP     Short RDE_RETURN
NOT_SUPPORTED_SEC:
INVD_ENT_NO:
        CALL    HALT
RDE_RETURN:
        CALL    FAT12_UPDATE_CLKTICK
        RET
FAT12_READ_DIR_ENTRY            ENDP

;***********************************************************************

FAT12_WRITE_DIR_ENTRY           PROC
        CMP     AX,FAT12_ROOT_ENT_COUNT
        JA      INVD_ENT_NO_2
        PUSH    AX
        PUSH    CX
        PUSH    DS
        CALL    CALC_ROOT_ENT_POS
        PUSH    CS
        POP     DS
        ADD     CH,FAT12_ROOT_START_SEC
        JC      NOT_SUPPORTED_W_SEC
        ;-----------------------------------
        MOV     FAT12_RW_DIR_WORD1,CX
        MOV     FAT12_RW_DIR_WORD2,BX
        MOV     FAT12_RW_DIR_WORD3,DX
        ;-----------------------------------
        MOV     AL,FAT12_DRIVE_NO
        MOV     DL,CH
        XOR     DH,DH
        MOV     CX,1
        LEA     BX,DISK_SEC_TEMP
        MOV     CS:DSKBUF_BUFFER_TYPE,1
        CALL    DSKBUF_READ_LOGIC_SECTOR
        ;-----------------------------------
        MOV     CX,FAT12_RW_DIR_WORD1
        XOR     CH,CH
        SHL     CX,1    ;CX*2
        ADD     BX,CX
        ;Exchange BX and DI
        XCHG    BX,DI
        POP     DS
        PUSH    ES
        MOV     AX,CS
        MOV     ES,AX
        MOV     CX,16
        CLD             ;for increment
   REP  MOVSW
        ;Exchange BX and DI again
        XCHG    BX,DI
        SUB     SI,32
        POP     ES
        PUSH    DS
        MOV     DS,AX   ;AX = CS
        ;-----------------------------------
        LEA     BX,DISK_SEC_TEMP
        MOV     AL,FAT12_DRIVE_NO
        MOV     DL,BYTE PTR FAT12_RW_DIR_WORD1[1]
        XOR     DH,DH
        MOV     CX,1
        MOV     CS:DSKBUF_BUFFER_TYPE,1
        CALL    DSKBUF_WRITE_LOGIC_SECTOR
        ;-----------------------------------
        MOV     DX,FAT12_RW_DIR_WORD3
        MOV     BX,FAT12_RW_DIR_WORD2
        POP     DS
        POP     CX
        POP     AX
        JMP     Short WDE_RETURN
NOT_SUPPORTED_W_SEC:
INVD_ENT_NO_2:
        CALL    HALT
WDE_RETURN:
        CALL    FAT12_UPDATE_CLKTICK
        RET
FAT12_WRITE_DIR_ENTRY           ENDP

;***********************************************************************

FAT12_RW_CLUS_SEC       PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FAT12_RW_DIR_WORD1,AX
        MOV     FAT12_RW_DIR_WORD2,CX
        MOV     FAT12_RW_DIR_WORD3,DX
        CMP     CX,2
        JB      INV_CLUS_NO
        CMP     CX,FAT12_MAX_CLUS_NO
        JA      INV_CLUS_NO
        ;-----------------------------------
        MOV     DX,CX
        SUB     DX,2
        MOV     CX,AX
        MOV     AL,FAT12_SEC_PER_CLUS
        XOR     AH,AH
        MUL     DX
        CMP     DX,0
        JNE     INV_SEC_NO
        MOV     DL,FAT12_DATA_START_SEC
        ADD     DX,AX
        JC      INV_SEC_NO
        MOV     AX,CX
        XOR     AH,AH
        DEC     AX
        ADD     DX,AX   ;DX = logic sector no. to read
        MOV     AL,FAT12_DRIVE_NO
        MOV     AH,CH
        MOV     CX,1
        POP     DS
        CMP     AH,0
        JNE     WRITE_CLUSTER
READ_CLUSTER:
        MOV     CS:DSKBUF_BUFFER_TYPE,2
        CALL    DSKBUF_READ_LOGIC_SECTOR
        JMP     Short RW_SUCCESS
WRITE_CLUSTER:
        MOV     CS:DSKBUF_BUFFER_TYPE,2
        CALL    DSKBUF_WRITE_LOGIC_SECTOR
RW_SUCCESS:
        PUSH DS
        PUSH    CS
        POP     DS
        CLC
        JMP     Short RW_CLUS_DONE
        ;-----------------------------------
INV_CLUS_NO:
        CALL    HALT
        STC
        JMP     Short RW_CLUS_DONE
INV_SEC_NO:
        CALL    HALT
        STC
RW_CLUS_DONE:
        MOV     DX,FAT12_RW_DIR_WORD3
        MOV     CX,FAT12_RW_DIR_WORD2
        MOV     AX,FAT12_RW_DIR_WORD1
        POP     DS
        CALL    FAT12_UPDATE_CLKTICK
        RET
FAT12_RW_CLUS_SEC       ENDP

;***********************************************************************

HALT            PROC
        ;Write halt string on the screen and halt
        MOV     AH,0EH
        MOV     AL,13
        INT     10H
        MOV     AL,10
        INT     10H
        XOR     BP,BP
        PUSH    CS
        POP     DS
        LEA     SI,HALT_MSG
WRITE_HALT_STR:
        LODSB
        CMP     AL,0
        JE      HALT_LOOP
        INT     10H
        JMP     Short WRITE_HALT_STR
HALT_LOOP:
        HLT
        JMP     Short HALT_LOOP
HALT            ENDP

;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;                              MTF00012.ASM                             ;

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

DRIVE_LETTER_TO_NUMBER          PROC
        CALL    UPPER_CASE
        CMP     AL,'A'
        JB      WRONG_LETTER
        CMP     AL,'Z'
        JA      WRONG_LETTER
        SUB     AL,'A'
        CLC
        JMP     Short CONVERT_DONE
WRONG_LETTER:
        STC
CONVERT_DONE:
        RET
DRIVE_LETTER_TO_NUMBER          ENDP

;***********************************************************************

ASCIIZ_TO_UPPER         PROC
        PUSH    BX
        MOV     BX,DX
UPPER_LOOP:
        CMP     BYTE PTR[BX],00H
        JZ      STRUPPER_DONE
        CMP     BYTE PTR[BX],'a'
        JB      NOT_LOWER
        CMP     BYTE PTR[BX],'z'
        JA      NOT_LOWER
        ADD     BYTE PTR[BX],'A'-'a'
NOT_LOWER:
        INC     BX
        JMP     Short UPPER_LOOP
STRUPPER_DONE:
        POP     BX
        RET
ASCIIZ_TO_UPPER         ENDP

;***********************************************************************

EXTRACT_DRIVE_NO        PROC
        PUSH    AX
        XCHG    BX,DX
        MOV     AL,[BX]
        XCHG    BX,DX
        CALL    DRIVE_LETTER_TO_NUMBER
        JNC     DRV_OK
BAD_LET_NUM:            ;Critical error
        CALL    HALT
DRV_OK:
        MOV     DL,AL
        CMP     DL,0    ;Only drive A:(=0) is valid in this version
        JNE     BAD_LET_NUM
        POP     AX
        RET
EXTRACT_DRIVE_NO        ENDP

;***********************************************************************

CHECK_FILE_PATH         PROC
        PUSH    BX
        MOV     BX,DX
        MOV     AL,[BX]
        CALL    UPPER_CASE
        CMP     AL,'A'
        JNE     CFP_ERROR_PNF
        CMP     BYTE PTR[BX+1],':'
        JNE     CFP_ERROR_PNF
        CMP     BYTE PTR[BX+2],'\'
        JNE     CFP_ERROR_PNF
        ADD     BX,3
        MOV     AX,0FF00H
COUNT_NAME:
        CMP     BYTE PTR[BX],0
        JZ      NAME_C_DONE
        CMP     BYTE PTR[BX],'.'
        JE      NAME_C_DONE
        INC     AL
        INC     BX
        JMP     Short COUNT_NAME
NAME_C_DONE:
        CMP     BYTE PTR[BX],0
        JZ      EXT_C_DONE
        INC     BX
COUNT_EXTLEN:
        CMP     BYTE PTR[BX],0
        JZ      EXT_C_DONE
        INC     AH
        INC     BX
        JMP     Short COUNT_EXTLEN
EXT_C_DONE:
        CMP     AL,0
        JZ      ERROR_BAD_LEN
        CMP     AL,8
        JA      ERROR_BAD_LEN
        CMP     AH,0FFH
        JE      NO_EXTENTION
        CMP     AH,3
        JA      ERROR_BAD_LEN
        JMP     Short CHECK_FP_SUCCESS
NO_EXTENTION:
        ;DEC     BX
        MOV     BYTE PTR[BX],0
CHECK_FP_SUCCESS:
        XOR     AX,AX
        JMP     Short CHECK_FP_DONE
CFP_ERROR_PNF:
        MOV     AX,ERR_PNFOUND
        JMP     Short CHECK_FP_DONE
ERROR_BAD_LEN:
        MOV     AX,ERR_FNFOUND
CHECK_FP_DONE:
        POP     BX
        RET
CHECK_FILE_PATH         ENDP

;***********************************************************************

SET_DEFAULT_DRIVE       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 0EH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     AL,1            ;Only 1 drive is available in this version.
        OR      DL,DL           ;Only drive A:(DL=00H) is supported in this version.
        JNZ     RETURN_DRIVE
        MOV     CS:DEFAULT_DRIVE_NO,DL
RETURN_DRIVE:
        RET
SET_DEFAULT_DRIVE       ENDP

;***********************************************************************

GET_DEFAULT_DRIVE       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 19H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     AL,CS:DEFAULT_DRIVE_NO
        RET
GET_DEFAULT_DRIVE       ENDP

;***********************************************************************

CHANGE_DEFAULT_DIR      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 3BH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        ;This is only a test version of this procedure
        CLC
        CALL    PREPARE_FILE_PATH
        JC      CDD_RETURN
        ;-----------------------------------
        CALL    ASCIIZ_TO_UPPER
        XCHG    BX,DX
        ;Check the input path to be only 'A:\' in this version
        CMP     BYTE PTR[BX],'A'
        JNE     BAD_DEF_DIR
        CMP     BYTE PTR[BX+1],':'
        JNE     BAD_DEF_DIR
        CMP     BYTE PTR[BX+2],'\'
        JNE     BAD_DEF_DIR
        CMP     BYTE PTR[BX+3],00H
        JNE     BAD_DEF_DIR
        JMP     Short DEF_DIR_OK
BAD_DEF_DIR:
        MOV     AX,ERR_PNFOUND
        STC
        JMP     Short CDD_DONE
DEF_DIR_OK:
        CLC
CDD_DONE:
        XCHG    BX,DX
CDD_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
CHANGE_DEFAULT_DIR      ENDP

;***********************************************************************

GET_DRIVE_DEFAULT_DIR           PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 47H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        ;This is only a test version of this procedure
        CMP     DL,1    ;Only drive A:
        JA      BAD_DRIVE_NO
        MOV     BYTE PTR[SI],0  ;Only root directory of drive
        CLC
        JMP     Short GDDD_RETURN
BAD_DRIVE_NO:
        MOV     AX,ERR_IDSPECIFIED
        STC
GDDD_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
GET_DRIVE_DEFAULT_DIR           ENDP

;***********************************************************************

CALC_DRIVE_NO           PROC
        CMP     DL,0
        JNE     DECREASE_DRIVE_NO
        MOV     DL,AL
        CALL    GET_DEFAULT_DRIVE
        XCHG    AL,DL
        JMP     Short CALC_DNO_RETURN
DECREASE_DRIVE_NO:
        DEC     DL
CALC_DNO_RETURN:
        RET
CALC_DRIVE_NO           ENDP

;***********************************************************************

DELETE_LAST_CLUSTER             PROC
        CMP     AX,2
        JB      DEL_CLUS_RETURN
        PUSH    BX
        ;-----------------------------------
        PUSH    CX
        MOV     BX,AX
        PUSH    AX
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_EOC
        JAE     FIRST_CLUS
        MOV     CX,AX
FIND_LAST_CLUS:
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_EOC
        JAE     FOUND_CLUS
        MOV     BX,CX
        MOV     CX,AX
        JMP     Short FIND_LAST_CLUS
FOUND_CLUS:
        MOV     AX,CX
        XOR     CX,CX
        CALL    FAT12_WRITE_FAT_ENTRY
        MOV     AX,BX
        MOV     CX,FAT12_EOC
        CALL    FAT12_WRITE_FAT_ENTRY
        POP     AX
        JMP     Short DEL_CLUS_DONE
FIRST_CLUS:
        POP     AX
        XOR     CX,CX
        CALL    FAT12_WRITE_FAT_ENTRY
        ;-----------------------------------
DEL_CLUS_DONE:
        ;-----------------------------------
        POP     CX
        POP     BX
DEL_CLUS_RETURN:
        RET
DELETE_LAST_CLUSTER             ENDP

;***********************************************************************
FFFE_LAST_ENTRY         DW      1

FIND_FREE_FAT_ENTRY             PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    CX
        PUSH    BX
        MOV     CX,FAT12_MAX_CLUS_NO
        MOV     AX,FFFE_LAST_ENTRY
START_FAT_SEARCH:
        INC     AX      ;next entry
        CMP     AX,CX
        JA      FFE_NOT_FOUND
        MOV     BX,AX
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,00H
        JE      FOUND_FFE
        MOV     AX,BX
        JMP     Short START_FAT_SEARCH
FFE_NOT_FOUND:
        INC     CX
        CMP     CX,FFFE_LAST_ENTRY
        JE      FFE_NOT_FOUND_2
        MOV     CX,FFFE_LAST_ENTRY
        MOV     AX,1
        MOV     WORD PTR FFFE_LAST_ENTRY,AX
        DEC     CX
        JMP     Short START_FAT_SEARCH
FFE_NOT_FOUND_2:
        XOR     AX,AX
        JMP     Short FFFE_DONE
FOUND_FFE:
        MOV     AX,BX
        MOV     FFFE_LAST_ENTRY,AX
FFFE_DONE:
        ;-----------------------------------
        POP     BX
        POP     CX
        POP     DS
        RET
FIND_FREE_FAT_ENTRY             ENDP

;***********************************************************************

FIND_FREE_DIR_ENTRY             PROC
        PUSH    CX
        PUSH    BX        
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     CX,FAT12_ROOT_ENT_COUNT
        POP     DS
        XOR     AX,AX
START_DIR_SEARCH:
        INC     AX      ;next entry
        CMP     AX,CX
        JA      FDE_NOT_FOUND
        CALL    FAT12_READ_DIR_ENTRY
        MOV     BX,AX
        MOV     AL,ES:[DI]
        CMP     AL,0E5H
        JE      FOUND_FDE
        CMP     AL,00H
        JE      FOUND_FDE
        MOV     AX,BX
        JMP     Short START_DIR_SEARCH
FDE_NOT_FOUND:
        XOR     AX,AX
        JMP     Short FFDE_DONE
FOUND_FDE:
        MOV     AX,BX
FFDE_DONE:
        ;-----------------------------------
        POP     BX
        POP     CX
        RET
FIND_FREE_DIR_ENTRY             ENDP

;***********************************************************************

APPEND_CLUSTER          PROC
        PUSH    BX
        CMP     AX,1
        JE      APP_ERROR
        MOV     BX,AX
        CALL    FIND_FREE_FAT_ENTRY     ;FAT12_RW Started Into This Procedure
        XCHG    AX,BX
        CMP     BX,0
        JE      APP_ERROR
        PUSH    CX
        CMP     AX,0
        JE      APP_FIRST
        ;-----------------------------------
FIND_EOC:
        MOV     CX,AX
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_EOC
        JB      FIND_EOC
        MOV     AX,CX
        MOV     CX,BX
        CALL    FAT12_WRITE_FAT_ENTRY
APP_FIRST:
        MOV     AX,BX
        MOV     CX,FAT12_EOC
        CALL    FAT12_WRITE_FAT_ENTRY
        POP     CX
        CLC
        JMP     Short APP_CLUS_DONE
        ;-----------------------------------
APP_ERROR:
        STC
APP_CLUS_DONE:
        ;-----------------------------------
        POP     BX
        RET
APPEND_CLUSTER          ENDP

;***********************************************************************

ENCODE_FILE_DATE        PROC
        SHL     CH,1
        SHL     CH,1
        SHL     CH,1
        SHL     CH,1
        RCL     CH,1
        RCL     AL,1
        AND     CH,0E0H
        OR      CL,CH
        MOV     CH,AL
        SHR     AL,1
        RET
ENCODE_FILE_DATE        ENDP

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

ENCODE_FILE_TIME        PROC
        PUSH    AX
        MOV     AH,AL
        SHL     CH,1
        SHL     CH,1
        MOV     AL,CH
        SHL     AX,1
        SHL     AX,1
        SHL     AX,1
        SHR     CL,1
        OR      CL,AL
        MOV     CH,AH
        POP     AX
        RET
ENCODE_FILE_TIME        ENDP

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

DELETE_CLUSTER_CHAIN    PROC
        CMP     AX,1
        JBE     DEL_CHAIN_RETURN
        ;-----------------------------------
        PUSH    AX
        PUSH    CX
        XOR     CX,CX
START_CLUS_DEL:
        CMP     CX,FAT12_EOC
        JAE     FINISH_CLUS_DEL
        PUSH    AX
        CALL    FAT12_READ_FAT_ENTRY
        MOV     CX,AX
        POP     AX
        PUSH    CX
        XOR     CX,CX
        CALL    FAT12_WRITE_FAT_ENTRY
        POP     CX
        MOV     AX,CX
        JMP     Short START_CLUS_DEL
FINISH_CLUS_DEL:
        ;-----------------------------------
        POP     CX
        POP     AX
DEL_CHAIN_RETURN:
        RET
DELETE_CLUSTER_CHAIN    ENDP

;***********************************************************************

GET_11_BYTE_F_NAME              PROC
        PUSH    DI
        LEA     DI,DIR_11_BYTE_F_NAME
        PUSH    ES
        PUSH    CS
        POP     ES
        PUSH    BX
        PUSH    AX
        XOR     AH,AH
        CLD
MOVE_START:
        CMP     AH,11
        JE      MOVE_FN_DONE
        MOV     AL,[BX]
        CMP     AL,0
        JZ      MOVE_FN_DONE
        CMP     AL,'.'
        JE      FILL_NAME
        STOSB
        INC     AH
        INC     BX
        JMP     Short MOVE_START
FILL_NAME:
        MOV     AL,20H
        INC     BX
FILL_START:
        CMP     AH,8
        JE      MOVE_START
        STOSB
        INC     AH
        JMP     Short FILL_START
MOVE_FN_DONE:
        MOV     AL,20H
FILL_EXT:
        CMP     AH,11
        JE      MOVE_OK
        STOSB
        INC     AH
        JMP     Short FILL_EXT
MOVE_OK:
        POP     AX
        POP     BX
        POP     ES
        POP     DI
        RET
GET_11_BYTE_F_NAME              ENDP

;***********************************************************************

FAST_FIND_FILE          PROC
        CALL    GET_11_BYTE_F_NAME
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        ;-----------------------------------
        XOR     AX,AX
FFF_START_SEARCH:
        INC     AX
        PUSH    AX
        CMP     AX,FAT12_ROOT_ENT_COUNT
        JA      ENTRY_NOT_FOUND
        CALL    FAT12_READ_DIR_ENTRY
        CMP     ES:BYTE PTR[DI],00H
        JZ      ENTRY_NOT_FOUND
        XOR     AH,AH
        XOR     BX,BX
CMP_NAMES:
        MOV     AL,ES:[DI+BX]
        CMP     AL,DIR_11_BYTE_F_NAME[BX]
        JNE     FFF_NEXT_ENTRY
        INC     BX
        CMP     BX,11
        JE      FOUND_ENTRY
        JMP     Short CMP_NAMES
FFF_NEXT_ENTRY:
        POP     AX
        JMP     Short FFF_START_SEARCH
ENTRY_NOT_FOUND:
        POP     AX
        XOR     AX,AX
        JMP     Short FAST_FIND_DONE
FOUND_ENTRY:
        POP     AX
FAST_FIND_DONE:
        ;-----------------------------------
        POP     BX
        POP     DS
        RET
FAST_FIND_FILE          ENDP

;***********************************************************************

READ_FILE_DIR_ENTRY             PROC
        CALL    CHECK_FILE_PATH
        OR      AX,AX
        JNZ     ERROR_1
        XCHG    DX,BX
        ADD     BX,3
        PUSH    DX
        XOR     DL,DL           ;Drive A: Only (DL=0)
        CALL    FAST_FIND_FILE
        POP     DX
        SUB     BX,3
        XCHG    DX,BX
        OR      AX,AX
        JZ      ERROR_FNF_1
        CLC
        JMP     Short READ_FDE_RETURN
ERROR_1:
        STC
        JMP     Short READ_FDE_RETURN
ERROR_FNF_1:
        MOV     AX,ERR_FNFOUND
        STC
READ_FDE_RETURN:
        RET
READ_FILE_DIR_ENTRY             ENDP

;***********************************************************************

DELETE_FILE             PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 41H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    PREPARE_FILE_PATH
        JC      DEL_RETURN
        ;-----------------------------------
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        PUSH    DX
        XOR     DL,DL           ;Only drive A: in this version
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     DX
        POP     BX
        POP     DS
        ;-----------------------------------
        PUSH    CX
        MOV     CX,AX
        PUSH    DI
        LEA     DI,DIR_ENT_TEMP
        PUSH    ES
        MOV     AX,CS
        MOV     ES,AX
        CALL    READ_FILE_DIR_ENTRY
        JC      DEL_FILE_ERROR
        ;-----------------------------------
        TEST    ES:BYTE PTR[DI+11],00011000b    ;Directories and volum label can not be deleted by this service.
        JNZ     DEL_FILE_ERROR
        PUSH    AX
        MOV     AL,ES:[DI+11]
        TEST    AL,01H
        JNZ     ACCESS_ERROR_1
        MOV     AX,ES:[DI+26]
        PUSH    DX
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     DL,FAT12_DRIVE_NO
        POP     DS
        CALL    DELETE_CLUSTER_CHAIN
        POP     DX
        POP     AX
        MOV     ES:BYTE PTR[DI],0E5H
        PUSH    SI
        MOV     SI,DI
        MOV     DI,DS
        PUSH    ES
        POP     DS
        CALL    FAT12_WRITE_DIR_ENTRY
        MOV     DS,DI
        POP     SI
        MOV     AX,CX
        ;--------------END_RW---------------
        ;In this point DI and CX are free to use.
        MOV     DI,DS
        PUSH    CS
        POP     DS
        MOV     CX,DX
        MOV     DL,FAT12_DRIVE_NO
        CALL    FAT12_END_RW
        MOV     DX,CX
        MOV     DS,DI
        ;-----------------------------------
        CLC
        JMP     Short DEL_FILE_DONE
        ;-----------------------------------
ACCESS_ERROR_1:
        POP     AX
        MOV     AX,ERR_ADENIED
        STC
        JMP     Short DEL_FILE_DONE
DEL_FILE_ERROR:
        STC
DEL_FILE_DONE:
        POP     ES
        POP     DI
        POP     CX
DEL_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
DELETE_FILE             ENDP

;***********************************************************************

GET_SET_FILE_ATTR       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 43H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    PREPARE_FILE_PATH
        JC      ATTR_RETURN
        ;-----------------------------------
        PUSH    BX
        ;-----------------------------------
        PUSH    DS
        PUSH    DX
        XOR     DL,DL           ;Only drive A: in this version
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     DX
        POP     DS
        ;-----------------------------------
        MOV     BX,AX
        PUSH    DI
        PUSH    ES
        PUSH    CS
        POP     ES
        LEA     DI,DIR_ENT_TEMP
        CALL    READ_FILE_DIR_ENTRY     ;FAT12_RW Started Into This Procedure
        JC      FILE_ATTR_ERROR
        CMP     BL,1
        JE      SET_ATTR
        XOR     CH,CH
        MOV     CL,ES:[DI+11]
        MOV     AX,BX
        CLC
        JMP     Short ATTR_DONE
SET_ATTR:
        MOV     ES:[DI+11],CL
        PUSH    SI
        MOV     SI,DI
        MOV     DI,DS
        PUSH    ES
        POP     DS
        CALL    FAT12_WRITE_DIR_ENTRY
        MOV     DS,DI
        POP     SI
        MOV     AX,BX
        ;--------------END_RW---------------
        ;In this point DI and BX are free to use.
        MOV     DI,DS
        PUSH    CS
        POP     DS
        MOV     BX,DX
        MOV     DL,FAT12_DRIVE_NO
        CALL    FAT12_END_RW
        MOV     DX,BX
        MOV     DS,DI
        ;-----------------------------------
        CLC
        JMP     Short ATTR_DONE
FILE_ATTR_ERROR:
        STC
ATTR_DONE:
        POP     ES
        POP     DI
        POP     BX
ATTR_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
GET_SET_FILE_ATTR       ENDP

;***********************************************************************

GET_DRIVE_SPEC          PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 36H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CMP     DL,1            ;Only drive A: in this version
        JA      DRIVE_ERROR
        PUSH    DS
        MOV     BX,CS
        MOV     DS,BX
        CALL    CALC_DRIVE_NO
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        MOV     CX,FAT12_MAX_CLUS_NO
        XOR     BX,BX
READ_LOOP:
        MOV     AX,CX
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,0
        JNE     READ_NEXT_CLUS
        INC     BX
READ_NEXT_CLUS:
        DEC     CX
        CMP     CX,1
        JE      EXIT_LOOP
        JMP     Short READ_LOOP
EXIT_LOOP:
        XOR     AH,AH
        MOV     AL,FAT12_SEC_PER_CLUS
        MOV     CX,512
        ;-----------------------------------
        MOV     DX,FAT12_MAX_CLUS_NO
        DEC     DX
        POP     DS
        JMP     Short GDS_RETURN
DRIVE_ERROR:
        MOV     AX,0FFFFH
GDS_RETURN:
        RET
GET_DRIVE_SPEC          ENDP

;***********************************************************************

GET_FAT_INF     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 1CH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     CX,CS
        MOV     DS,CX
        CALL    CALC_DRIVE_NO
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        MOV     CH,AH
        XOR     AX,AX
        CALL    FAT12_READ_FAT_ENTRY
        MOV     FAT_ID_BYTE,AL
        LEA     BX,FAT_ID_BYTE
        MOV     AH,CH
        MOV     AL,FAT12_SEC_PER_CLUS
        ;-----------------------------------
        MOV     DX,FAT12_MAX_CLUS_NO
        DEC     DX
        MOV     CX,512
        RET
GET_FAT_INF     ENDP

;***********************************************************************

GET_DEFAULT_FAT_INF     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 1BH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CALL    GET_DEFAULT_DRIVE
        MOV     DL,AL
        CALL    GET_FAT_INF
        RET
GET_DEFAULT_FAT_INF     ENDP

;***********************************************************************
REN_DES_FILE_PATH               DB      16 DUP(00H)
MAIN_REN_FILE_PATH_ADDR         DD      ?

PREPARE_REN_DES_FILE_PATH       PROC
        MOV     CS:WORD PTR MAIN_REN_FILE_PATH_ADDR[0],DI
        MOV     CS:WORD PTR MAIN_REN_FILE_PATH_ADDR[2],ES
        PUSH    DS
        PUSH    ES
        POP     DS
        PUSH    SI
        PUSH    DI
        POP     SI
        PUSH    AX
PRDF_CHECK_WILD_CARDS:
        LODSB
        OR      AL,AL
        JZ      PRDF_WILD_CARDS_OK
        CMP     AL,'?'
        JE      PRDF_FAILURE
        CMP     AL,'*'
        JE      PRDF_FAILURE
        JMP     Short PRDF_CHECK_WILD_CARDS
PRDF_WILD_CARDS_OK:
        PUSH    DI
        POP     SI
        PUSH    CS
        POP     ES
        LEA     DI,REN_DES_FILE_PATH
        CALL    BUILD_FULL_PATH
        JNC     PRDF_PATH_OK
        POP     SI      ;POP AX from the stack into SI
        JMP     Short PRDF_DONE
PRDF_PATH_OK:
        POP     AX
        CLC
        JMP     Short PRDF_DONE
PRDF_FAILURE:
        POP     AX
        MOV     AX,ERR_PNFOUND
        STC
PRDF_DONE:
        POP     SI
        POP     DS
        RET
PREPARE_REN_DES_FILE_PATH       ENDP

RESTORE_REN_DES_FILE_PATH       PROC
        MOV     DI,CS:WORD PTR MAIN_REN_FILE_PATH_ADDR[0]
        MOV     ES,CS:WORD PTR MAIN_REN_FILE_PATH_ADDR[2]
        RET
RESTORE_REN_DES_FILE_PATH       ENDP

RENAME_FILE     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 56H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    PREPARE_FILE_PATH
        JC      REN_RETURN
        CALL    PREPARE_REN_DES_FILE_PATH
        JC      REN_RETURN
        ;-----------------------------------
        PUSH    CX
        MOV     CX,AX
        CALL    CHECK_FILE_PATH
        CMP     AX,0
        JNZ     REN_ERROR_1
        PUSH    DS
        MOV     AX,ES
        MOV     DS,AX
        XCHG    DX,DI
        CALL    CHECK_FILE_PATH
        POP     DS
        XCHG    DX,DI
        CMP     AX,0
        JNZ     REN_ERROR_1
        MOV     AX,CX
        POP     CX
        ;-----------------------------------
        ;Source and dest. file names are valid,so...
        PUSH    AX
        MOV     AL,ES:[DI]
        XCHG    BX,DX
        CMP     AL,[BX]
        XCHG    BX,DX
        POP     AX
        JNZ     REN_ERROR_NSD
        ;-----------------------------------
        PUSH    AX
        PUSH    DX
        ;-----------------------------------
        PUSH    DS
        PUSH    CS
        POP     DS
        XOR     DL,DL           ;Only drive A: in this version
        MOV     AX,BX
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        MOV     BX,AX
        POP     DS
        ;-----------------------------------
        MOV     DX,DI
        PUSH    DS
        LEA     DI,DIR_ENT_TEMP
        MOV     AX,ES
        MOV     DS,AX
        PUSH    ES
        MOV     AX,CS
        MOV     ES,AX
        CALL    READ_FILE_DIR_ENTRY     ;FAT12_RW Started Into This Procedure
        POP     ES
        POP     DS
        MOV     DI,DX
        POP     DX
        POP     AX
        JNC     REN_ACCESS_ERROR
        ;Dest. file name does not exist
        ;-----------------------------------
        PUSH    AX
        PUSH    DI
        LEA     DI,DIR_ENT_TEMP
        PUSH    ES
        MOV     AX,CS
        MOV     ES,AX
        CALL    READ_FILE_DIR_ENTRY
        POP     ES
        POP     DI
        JC      REN_ERROR_FNF
        PUSH    DS
        PUSH    ES
        POP     DS
        PUSH    BX
        MOV     BX,DI
        ADD     BX,3
        CALL    GET_11_BYTE_F_NAME
        POP     BX
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,DIR_ENT_TEMP
        PUSH    CX
        PUSH    BX
        XOR     BX,BX
RENAME:
        MOV     CX,WORD PTR DIR_11_BYTE_F_NAME[BX]
        MOV     [SI+BX],CX
        ADD     BX,2
        CMP     BX,10
        JB      RENAME
        MOV     CL,DIR_11_BYTE_F_NAME[BX]
        MOV     [SI+BX],CL
        POP     BX
        POP     CX
        CALL    FAT12_WRITE_DIR_ENTRY
        ;--------------END_RW---------------
        ;In this point SI and DS and AX are free to use.
        ;DS=CS
        MOV     AL,DL
        MOV     DL,FAT12_DRIVE_NO
        CALL    FAT12_END_RW
        MOV     DL,AL
        ;-----------------------------------
        POP     SI
        POP     DS
        POP     AX
        CLC
        JMP     Short REN_RETURN
        ;-----------------------------------
REN_ERROR_1:
        POP     CX
        STC
        JMP     Short REN_RETURN
REN_ERROR_NSD:
        MOV     AX,ERR_NSDEVICE
        STC
        JMP     Short REN_RETURN
REN_ACCESS_ERROR:
        MOV     AX,ERR_ADENIED
        STC
        JMP     Short REN_RETURN
REN_ERROR_FNF:
        POP     AX
        MOV     AX,ERR_FNFOUND
        STC
REN_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    RESTORE_REN_DES_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
RENAME_FILE     ENDP

;***********************************************************************

SET_DTA_ADDRESS         PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 1AH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     CS:DTA_SEGMENT,DS
        MOV     CS:DTA_OFFSET,DX
        RET
SET_DTA_ADDRESS         ENDP

;***********************************************************************

DIR_NAME_TO_F_NAME      PROC
        PUSH    SI
        PUSH    DI
        PUSH    AX
        XOR     AH,AH
        CLD
MOVE_NAME_STR:
        LODSB
        INC     AH
        CMP     AH,9
        JE      PUT_DOT
        CMP     AH,12
        JE      MOVE_N_DONE
        JMP     Short PUT_NAME_CHAR
PUT_DOT:
        MOV     ES:BYTE PTR[DI],'.'
        INC     DI
PUT_NAME_CHAR:
        CMP     AL,20H
        JE      MOVE_NAME_STR
        STOSB
        JMP     Short MOVE_NAME_STR
MOVE_N_DONE:
        CMP     ES:BYTE PTR[DI-1],'.'
        JNE     PUT_Z
        DEC     DI
PUT_Z:
        MOV     ES:BYTE PTR[DI],0
        POP     AX
        POP     DI
        POP     SI
        RET
DIR_NAME_TO_F_NAME      ENDP

;***********************************************************************

EXTRACT_PATH_FILE_NAME          PROC
        PUSH    BX
        PUSH    CX
        XOR     CL,CL
COUNT_LENGTH:
        MOV     CH,[BX]
        CMP     CH,0
        JE      COUNT_LEN_DONE
        INC     CL
        INC     BX
        CMP     CH,'\'
        JNE     COUNT_LENGTH
        XOR     CL,CL
        JMP     Short COUNT_LENGTH
        ;-----------------------------------
COUNT_LEN_DONE:
        SUB     BX,CX
        PUSH    SI
MOVE_FILE_NAME:
        MOV     CH,[BX]
        MOV     ES:[SI],CH
        INC     BX
        INC     SI
        DEC     CL
        CMP     CL,0
        JNZ     MOVE_FILE_NAME
        MOV     ES:BYTE PTR[SI],00H
        POP     SI
        POP     CX
        POP     BX
        RET
EXTRACT_PATH_FILE_NAME          ENDP

;***********************************************************************

MATCH_STRS      PROC
        PUSH    SI
        PUSH    DI
MATCH_STRS_LOOP:
        MOV     AH,[SI]
        CMP     AH,'?'
        JE      QUES_MARK
        CMP     AH,'*'
        JE      STAR_MARK
        CMP     AH,[DI]
        JNE     STRS_NOT_MATCH
        CMP     AH,0
        JE      MATCH_STRS_SUCCESS
STR_NEXT_CHAR:
        INC     SI
        INC     DI
        JMP     Short MATCH_STRS_LOOP
        ;-----------------------------------
QUES_MARK:
        CMP     BYTE PTR[DI],00H
        JNE     STR_NEXT_CHAR
        JMP     Short STRS_NOT_MATCH
STAR_MARK:
        CMP     BYTE PTR[SI+1],00H
        JE      MATCH_STRS_SUCCESS
        INC     SI
        XOR     AH,AH
STAR_LOOP:
        CMP     BYTE PTR[DI],00H
        JE      MATCH_STRS_DONE
        CALL    MATCH_STRS
        CMP     AH,1
        JE      MATCH_STRS_DONE
        INC     DI
        JMP     Short STAR_LOOP
        ;-----------------------------------
STRS_NOT_MATCH:
        XOR     AH,AH
        JMP     Short MATCH_STRS_DONE
MATCH_STRS_SUCCESS:
        MOV     AH,1
MATCH_STRS_DONE:
        POP     DI
        POP     SI
        RET
MATCH_STRS      ENDP

;***********************************************************************

COMPARE_FILE_NAMES      PROC
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    SI
        MOV     SI,DI
        LEA     DI,MATCH_FILE_NAME
        CALL    DIR_NAME_TO_F_NAME
        MOV     DI,SI
        POP     SI
        POP     ES
        ;-----------------------------------
        PUSH    AX
        PUSH    CX
        PUSH    DX
        XOR     DX,DX
        XOR     CL,CL
        MOV     CH,0FFH
        PUSH    SI
COUNT_LEAST_1:
        MOV     AL,[SI]
        CMP     AL,0
        JE      LEAST_1_DONE
        CMP     AL,'*'
        JE      NEXT_STR_CHAR
        CMP     AL,'.'
        JE      COUNT_EXT
        CMP     CH,0FFH
        JNE     EXT_CHAR
        INC     CL
        JMP     Short NEXT_STR_CHAR
COUNT_EXT:
        XOR     CH,CH
        JMP     Short NEXT_STR_CHAR
EXT_CHAR:
        INC     CH
NEXT_STR_CHAR:
        INC     SI
        JMP     Short COUNT_LEAST_1
LEAST_1_DONE:
        CMP     DX,0
        JZ      NEXT_STR
        MOV     DX,CX
        POP     CX
        POP     SI
        JMP     Short CHECK_SIZE
NEXT_STR:
        MOV     DX,1
        LEA     SI,MATCH_FILE_NAME
        PUSH    CX
        XOR     CL,CL
        MOV     CH,0FFH
        JMP     Short COUNT_LEAST_1
        ;-----------------------------------
CHECK_SIZE:
        CMP     CL,DL
        JA      SIZE_FAILURE
        CMP     CH,0
        JE      NO_EXT
        CMP     CH,0FFH
        JE      CHECK_FFH
        CMP     DH,0FFH
        JE      SIZE_FAILURE
        CMP     CH,DH
        JA      SIZE_FAILURE
        MOV     AL,1
        JMP     Short NEXT_STAGE
NO_EXT:
        XOR     AL,AL
        JMP     Short NEXT_STAGE
CHECK_FFH:
        CMP     DH,0FFH
        JNE     SIZE_FAILURE
        XOR     AL,AL
        JMP     Short NEXT_STAGE
        ;-----------------------------------
SIZE_FAILURE:
        POP     DX
        POP     CX
        POP     AX
        XOR     CH,CH
        JMP     MATCH_RETURN
NEXT_STAGE:
        POP     DX
        POP     CX
        ;-----------------------------------
        PUSH    DI
        LEA     DI,MATCH_FILE_NAME
        PUSH    CX
CMP_STR:
        PUSH    BX
        PUSH    AX
        PUSH    SI
        XOR     BX,BX
        XOR     CX,CX
MOVE_STR_1:
        MOV     AL,[SI]
        CMP     AL,0
        JZ      STR_1_DONE
        CMP     AL,'.'
        JE      STR_1_DONE
        MOV     MATCH_STR_BUF1[BX],AL
        INC     BX
        INC     CL
        INC     SI
        JMP     Short MOVE_STR_1
STR_1_DONE:
        MOV     BYTE PTR MATCH_STR_BUF1[BX],00H
        POP     SI
        PUSH    DI
        XOR     BX,BX
MOVE_STR_2:
        MOV     AL,[DI]
        CMP     AL,0
        JZ      STR_2_DONE
        CMP     AL,'.'
        JE      STR_2_DONE
        MOV     MATCH_STR_BUF2[BX],AL
        INC     BX
        INC     CH
        INC     DI
        JMP     Short MOVE_STR_2
STR_2_DONE:
        MOV     BYTE PTR MATCH_STR_BUF2[BX],00H
        POP     DI
        POP     AX              
        POP     BX
        ;-----------------------------------
        PUSH    AX
        PUSH    SI
        PUSH    DI
        LEA     SI,MATCH_STR_BUF1
        LEA     DI,MATCH_STR_BUF2
        CALL    MATCH_STRS
        POP     DI
        POP     SI
        CMP     AH,0
        POP     AX
        JZ      MATCH_FAILURE
        CMP     AL,0
        JNZ     MATCH_EXT
        JMP     Short MATCH_OK
MATCH_EXT:
        PUSH    CX
        XOR     CH,CH
        INC     CL
        ADD     SI,CX
        POP     CX
        MOV     CL,CH
        XOR     CH,CH
        INC     CL
        ADD     DI,CX
        XOR     AL,AL
        JMP     Short CMP_STR
        ;-----------------------------------
MATCH_FAILURE:
        POP     CX
        XOR     CH,CH
        JMP     Short MATCH_DONE
MATCH_OK:
        POP     CX
        MOV     CH,1
MATCH_DONE:
        POP     DI
        POP     AX
MATCH_RETURN:
        RET
COMPARE_FILE_NAMES      ENDP

;***********************************************************************

MATCH_FILE_ATTRIBUTES   PROC
        PUSH    AX
        MOV     AL,CH
        TEST    AL,00010000b       ;No subdirectory entries are allowed in this version
        JNZ     MFA_FAILURE
        CMP     AL,0FH             ;No long directory entries are allowed
        JE      MFA_FAILURE
        MOV     AL,CL
        AND     AL,00001110b
        MOV     AH,AL
        OR      AH,CH
        AND     AH,00001110b
        CMP     AL,AH
        JNE     MFA_FAILURE
        CLC
        JMP     Short MFA_DONE
MFA_FAILURE:
        STC
MFA_DONE:
        POP     AX
        RET
MATCH_FILE_ATTRIBUTES   ENDP

;***********************************************************************

SEARCH_FILE     PROC
        PUSH    SI
        PUSH    ES
        MOV     SI,CS
        MOV     ES,SI
        LEA     SI,PATH_FILE_NAME
        CALL    EXTRACT_PATH_FILE_NAME
        POP     ES
        POP     SI
        PUSH    DS
        PUSH    DI
        ;MOV     DI,BX
        MOV     DI,CS;BX,CS
        MOV     DS,DI;DS,BX
        MOV     AX,LAST_FOUND_DIR_ENT
        LEA     DI,DIR_ENT_TEMP
        PUSH    CX
        MOV     CH,CL
START_SEARCH:
        INC     AX
        CMP     AX,FAT12_ROOT_ENT_COUNT
        JA      SEARCH_FAILURE
        PUSH    ES
        PUSH    CS
        POP     ES
        CALL    FAT12_READ_DIR_ENTRY
        POP     ES
        ;-----------------------------------
        CMP     BYTE PTR[DI],00H
        JZ      SEARCH_FAILURE
        ;-----------------------------------
        CMP     BYTE PTR[DI],0E5H
        JE      START_SEARCH
        MOV     CH,[DI+11]
        CALL    MATCH_FILE_ATTRIBUTES
        JC      START_SEARCH
        ;-----------------------------------
        PUSH    SI
        LEA     SI,PATH_FILE_NAME
        CALL    COMPARE_FILE_NAMES
        POP     SI
        CMP     CH,1
        JE      SEARCH_SUCCESS
NEXT_ENTRY:
        JMP     Short START_SEARCH
        ;-----------------------------------
SEARCH_SUCCESS:
        MOV     LAST_FOUND_DIR_ENT,AX
        PUSH    SI
        PUSH    ES
        MOV     ES,DTA_SEGMENT
        MOV     SI,DTA_OFFSET
        ;-----------------------------------
        MOV     ES:BYTE PTR[SI],01H        ;Drive number(only drive A: in this version)
        MOV     CL,[DI+11]
        MOV     ES:[SI+21],CL
        MOV     CX,[DI+22]
        MOV     ES:[SI+22],CX
        MOV     CX,[DI+24]
        MOV     ES:[SI+24],CX
        MOV     CX,[DI+28]
        MOV     ES:[SI+26],CX
        MOV     CX,[DI+30]
        MOV     ES:[SI+28],CX
        ;-----------------------------------
        MOV     SI,DI
        MOV     ES,DTA_SEGMENT
        MOV     DI,DTA_OFFSET
        ADD     DI,30
        CALL    DIR_NAME_TO_F_NAME
        POP     ES
        POP     SI
        JMP     Short SEARCH_DONE
        ;-----------------------------------
SEARCH_FAILURE:
        XOR     AX,AX
SEARCH_DONE:
        POP     CX
        POP     DI
        POP     DS
        RET
SEARCH_FILE     ENDP

;***********************************************************************

FIND_FIRST_FILE         PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 4EH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        STC
        CALL    PREPARE_FILE_PATH
        JC      FIND_FIRST_RETURN
        ;-----------------------------------
        PUSH    BX
        MOV     BX,AX
        CALL    CHECK_FILE_PATH
        OR      AX,AX
        JNZ     FIND_FIRST_FILE_FAILURE
        PUSH    BX
        MOV     BX,DX
        MOV     AL,[BX]
        CALL    DRIVE_LETTER_TO_NUMBER
        JC      PATH_NF_ERR_1
        CMP     AL,0
        JA      PATH_NF_ERR_1
        ;-----------------------------------
        ADD     BX,3
        MOV     DL,AL
        PUSH    DS
        MOV     AX,CS
        MOV     DS,AX
        ;-----------------------------------
        ;DL = Drive number
        ;DS = CS
        PUSH    BX
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     BX
        ;-----------------------------------
        MOV     LAST_FOUND_DIR_ENT,0
        POP     DS
        CALL    SEARCH_FILE
        OR      AX,AX
        JZ      NO_FIRST_FILE
        MOV     AL,DL
        MOV     DX,DS
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     SEARCH_STATUS,2
        MOV     SEARCH_DRIVE_NO,AL
        MOV     SEARCH_PATH_SEGMENT,CS;DX
        MOV     SEARCH_PATH_OFFSET,OFFSET SEARCH_PATH;BX
        MOV     SEARCH_FILE_ATTR,CL
        POP     DS
        SUB     BX,3
        PUSH    SI
        XOR     SI,SI
SAVE_SEARCH_PATH:
        MOV     AL,[BX+SI]
        MOV     CS:SEARCH_PATH[SI],AL
        INC     SI
        OR      AL,AL
        JNZ     SAVE_SEARCH_PATH
        POP     SI
        MOV     DX,BX
        POP     AX
        CLC
        JMP     Short FIND_FIRST_DONE
        ;-----------------------------------
PATH_NF_ERR_1:
        MOV     BX,DS
        MOV     AX,CS
        MOV     DS,AX
        MOV     SEARCH_STATUS,0
        MOV     DS,BX
        POP     AX
        MOV     AX,ERR_PNFOUND
        STC
        JMP     Short FIND_FIRST_DONE
NO_FIRST_FILE:
        SUB     BX,3
        MOV     DX,BX
        MOV     BX,DS
        MOV     AX,CS
        MOV     DS,AX
        MOV     SEARCH_STATUS,1
        MOV     DS,BX
        POP     AX
        MOV     AX,ERR_NMMFILES
FIND_FIRST_FILE_FAILURE:
        STC
FIND_FIRST_DONE:
        POP     BX
FIND_FIRST_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
FIND_FIRST_FILE         ENDP

;***********************************************************************

FIND_NEXT_FILE          PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 4FH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DS
        MOV     AX,CS
        MOV     DS,AX
        CMP     SEARCH_STATUS,0
        JZ      PATH_NF_ERR_2
        CMP     SEARCH_STATUS,1
        JE      NO_FIRST_FILE_2
        ;-----------------------------------
        PUSH    DX
        PUSH    CX
        PUSH    BX
        ;-----------------------------------
        XOR     DL,DL           ;Only drive A: in this version.
        ;DS=CS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        ;-----------------------------------
        XOR     DH,DH
        MOV     DL,SEARCH_DRIVE_NO
        MOV     CL,SEARCH_FILE_ATTR
        XOR     CH,CH
        MOV     BX,SEARCH_PATH_OFFSET
        PUSH    DX
        MOV     DX,SEARCH_PATH_SEGMENT
        MOV     DS,DX
        POP     DX
        CALL    SEARCH_FILE
        POP     BX
        POP     CX
        POP     DX
        CMP     AX,0
        JZ      NO_MORE_FILES
        XOR     AX,AX
        CLC
        JMP     Short FIND_NEXT_DONE
        ;-----------------------------------
PATH_NF_ERR_2:
        MOV     AX,ERR_PNFOUND
        STC
        JMP     Short FIND_NEXT_DONE
NO_FIRST_FILE_2:
        MOV     AX,ERR_FNFOUND
        STC
        JMP     Short FIND_NEXT_DONE
NO_MORE_FILES:
        MOV     AX,ERR_NMMFILES
        STC
FIND_NEXT_DONE:
        POP     DS
        CALL    UPDATE_EXT_ERROR_INF
        RET
FIND_NEXT_FILE          ENDP

;***********************************************************************
FCB_FNAME_SEPARATORS    DB      ':;,+<>|/\[]="',00H

CHECK_FCB_FNAME_SEP     PROC
        CLD
        CMP     AL,20H
        JBE     FNAME_SEP_2
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        PUSH    AX
        LEA     SI,FCB_FNAME_SEPARATORS
        MOV     AH,AL
CHECK_FNAME_SEP:
        LODSB
        CMP     AL,00H
        JE      NO_FNAME_SEP
        CMP     AL,AH
        JNE     CHECK_FNAME_SEP
        ;So,this is a FCB filename separator.
        STC
        JMP     Short CHECK_FNAME_SEP_DONE
NO_FNAME_SEP:
        CLC
CHECK_FNAME_SEP_DONE:
        POP     AX
        POP     SI
        POP     DS
        JMP     Short FNAME_SEP_RETURN
FNAME_SEP_2:
        STC
FNAME_SEP_RETURN:
        RET
CHECK_FCB_FNAME_SEP     ENDP

;***********************************************************************

PARSE_FILENAME  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 29H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        ;Service 29H: Parse Filespec For a FCB
        PUSH    BX
        PUSH    CX
        PUSH    ES
        PUSH    DI
        MOV     BL,AL
        MOV     BH,00H
        CLD
        ;-----------------------------------
        TEST    BL,01H
        JZ      PF_SEPARATORS_DONE
PF_SCAN_SEPS:
        LODSB
        CALL    CHECK_FCB_FNAME_SEP
        JC      PF_SCAN_SEPS
        DEC     SI
PF_SEPARATORS_DONE:
        LODSB
        CMP     BYTE PTR[SI],':'
        JNE     PF_NO_DRIVE
        INC     SI
        CALL    DRIVE_LETTER_TO_NUMBER
        INC     AL
        MOV     ES:BYTE PTR[DI],AL
        CMP     AL,1            ;Only drive A: is valid in this version
        JE      PF_DRV_DONE
        MOV     BH,0FFH
        JMP     Short PF_DRV_DONE
PF_NO_DRIVE:
        DEC     SI
        TEST    BL,02H
        JNZ     PF_DRV_DONE
        MOV     ES:BYTE PTR[DI],0
PF_DRV_DONE:
        ;-----------------------------------
        INC     DI
        XOR     CX,CX
PF_GET_NAME:
        LODSB
        CALL    CHECK_FCB_FNAME_SEP
        JC      PF_NAME_DONE
        CMP     AL,'.'
        JE      PF_NAME_DONE
        CMP     AL,'*'
        JE      PF_NAME_STAR
        CMP     AL,'?'
        JNE     PF_NO_Q_MARK_1
        OR      BH,01H
PF_NO_Q_MARK_1:
        STOSB
        INC     CL
        CMP     CL,8
        JE      PF_NAME_DONE
        JMP     Short PF_GET_NAME
PF_NAME_STAR:
        MOV     AL,'?'
PF_FILL_NAME:
        STOSB
        INC     CL
        CMP     CL,8
        JNE     PF_FILL_NAME
        OR      BH,01H
PF_NAME_DONE:
        DEC     SI
        CMP     CL,0
        JNE     PF_NAME_OK_1
        ;No name was found in the source filename
        TEST    BL,04H
        JNZ     PF_NAME_OK_2
PF_NAME_OK_1:
        MOV     AL,' '          ;ASCII code 32
PF_FILL_NAME_SPACES:
        CMP     CL,8
        JE      PF_NAME_OK_2
        STOSB
        INC     CL
        JMP     Short PF_FILL_NAME_SPACES
PF_NAME_OK_2:
        MOV     AL,8
        SUB     AL,CL
        XOR     AH,AH
        ADD     DI,AX
        ;-----------------------------------
        XOR     CL,CL
PF_FIND_DOT:
        LODSB
        CALL    CHECK_FCB_FNAME_SEP
        JC      PF_NO_EXT
        CMP     AL,'.'
        JNE     PF_FIND_DOT
        XOR     CL,CL
PF_GET_EXT:
        LODSB
        CALL    CHECK_FCB_FNAME_SEP
        JC      PF_EXT_DONE
        CMP     AL,'.'
        JE      PF_EXT_DONE
        CMP     AL,'*'
        JE      PF_EXT_STAR
        CMP     AL,'?'
        JNE     PF_NO_Q_MARK_2
        OR      BH,01H
PF_NO_Q_MARK_2:
        INC     CL
        STOSB
        CMP     CL,3
        JE      PF_EXT_DONE
        JMP     Short PF_GET_EXT
PF_EXT_STAR:
        MOV     AL,'?'
PF_FILL_EXT:
        STOSB
        INC     CL
        CMP     CL,3
        JNE     PF_FILL_EXT
        OR      BH,01H
PF_EXT_DONE:
        CMP     CL,0
        JE      PF_NO_EXT
PF_FILL_EXT_SPACES:
        MOV     AL,' '          ;ASCII code 32
        CMP     CL,3
        JE      PF_DONE_1
        STOSB
        INC     CL
        JMP     Short PF_FILL_EXT_SPACES
PF_NO_EXT:
        TEST    BL,08H
        JZ      PF_FILL_EXT_SPACES
PF_DONE_1:
        POP     DI
        PUSH    DI
        ADD     DI,12
        XOR     AX,AX
        STOSW
        STOSW
        DEC     SI
PF_FIND_END:
        LODSB
        CALL    CHECK_FCB_FNAME_SEP
        JC      PF_END_DONE
        CMP     AL,'.'
        JNE     PF_FIND_END
PF_END_DONE:
        DEC     SI
PF_DONE_2:
        MOV     AH,29H
        MOV     AL,BH
        POP     DI
        POP     ES
        POP     CX
        POP     BX
        RET
PARSE_FILENAME  ENDP

;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;***********************************************************************;
;                              MTF00013.ASM                             ;

FIND_FHB        PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    CX
        PUSH    BX
        LEA     BX,FIRST_FILE_HANDLE
        ;-----------------------------------
START_FIND_FHB:
        CMP     BYTE PTR[BX],00H
        JA      USED_HDL
NEXT_HDL:
        CMP     WORD PTR[BX+17],0
        JE      HDL_NOT_FOUND
        MOV     CX,[BX+15]
        MOV     DS,[BX+17]
        MOV     BX,CX
        JMP     Short START_FIND_FHB
USED_HDL:
        MOV     CX,BX
        POP     BX
        PUSH    BX
        XCHG    CX,BX
        CMP     CX,[BX+1]
        JE      FOUND_HANDLE
        JMP     Short NEXT_HDL
        ;-----------------------------------
HDL_NOT_FOUND:
        STC
        JMP     Short FIND_FHDL_DONE
FOUND_HANDLE:
        MOV     DI,BX
        MOV     BX,DS
        MOV     ES,BX
        CLC
FIND_FHDL_DONE:
        POP     BX
        POP     CX
        POP     DS
        RET
FIND_FHB        ENDP

;***********************************************************************

FIND_UNUSED_FHB         PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    BX
        PUSH    CX
        LEA     BX,FIRST_FILE_HANDLE
START_FIND_U_FHB:
        CMP     BYTE PTR[BX],0
        JE      FOUND_U_FHB
        CMP     WORD PTR[BX+17],0
        JE      NO_U_FHB
        MOV     CX,[BX+15]
        MOV     DS,[BX+17]
        MOV     BX,CX
        JMP     Short START_FIND_U_FHB
NO_U_FHB:
        STC
        JMP     Short FIND_U_FHB_DONE
FOUND_U_FHB:
        MOV     DI,BX
        MOV     BX,DS
        MOV     ES,BX
        CLC
FIND_U_FHB_DONE:
        POP     CX
        POP     BX
        POP     DS
        RET
FIND_UNUSED_FHB         ENDP

;***********************************************************************

FIND_SPEC_FHB   PROC
        PUSH    DS
        PUSH    SI
        PUSH    CX
        MOV     CX,CS
        MOV     DS,CX
        LEA     SI,FIRST_FILE_HANDLE
FIND_SFHB:
        CMP     [SI+1],BX
        JE      FOUND_SFHB
        CMP     WORD PTR[SI+17],0
        JE      NO_SFHB
        MOV     CX,[SI+15]
        MOV     DS,[SI+17]
        MOV     SI,CX
        JMP     Short FIND_SFHB
NO_SFHB:
        STC
        JMP     Short FIND_SFHB_DONE
FOUND_SFHB:
        MOV     DI,SI
        MOV     CX,DS
        MOV     ES,CX
        CLC
FIND_SFHB_DONE:
        POP     CX
        POP     SI
        POP     DS
        RET
FIND_SPEC_FHB   ENDP

;***********************************************************************

FIND_FHB_WITH_OWNER     PROC
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,FIRST_FILE_HANDLE
FO_FIND_FHB:
        CMP     BYTE PTR[SI],0
        JE      FO_NEXT_FHB
        CMP     WORD PTR[SI+25],BX
        JE      FO_FOUND_FHB
FO_NEXT_FHB:
        CMP     WORD PTR[SI+17],0
        JE      FO_NO_FHB
        LDS     SI,[SI+15]
        JMP     Short FO_FIND_FHB
FO_FOUND_FHB:
        MOV     BX,WORD PTR[SI+1]
        CLC
        JMP     Short FO_DONE
FO_NO_FHB:
        STC
FO_DONE:
        POP     SI
        POP     DS
        RET
FIND_FHB_WITH_OWNER     ENDP

;***********************************************************************

FIND_TARGET_FHB         PROC
        PUSH    BX
FIND_TARGET:
        CMP     ES:BYTE PTR[DI+22],0
        JE      FOUND_TARGET_FHB
        MOV     BX,ES:[DI+3]
        CALL    FIND_FHB
        JC      FOUND_TARGET_FHB
        JMP     Short FIND_TARGET
FOUND_TARGET_FHB:
        POP     BX
        RET
FIND_TARGET_FHB         ENDP

;***********************************************************************

FIND_REDIRECTED_FHB     PROC
        CMP     AX,0
        JE      FRFHB_RETURN
        PUSH    AX
        PUSH    CX
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,FIRST_FILE_HANDLE
FIND_RED_FHB:
        CMP     BYTE PTR[SI],0
        JA      CHECK_FHB
NEXT_FHB:
        CMP     WORD PTR[SI+17],0
        JE      NO_RED_FHB
        MOV     CX,[SI+15]
        MOV     DS,[SI+17]
        MOV     SI,CX
        JMP     Short FIND_RED_FHB
CHECK_FHB:
        CMP     BYTE PTR[SI+22],0
        JE      NEXT_FHB
        CMP     [SI+3],BX
        JNE     NEXT_FHB
        CMP     [SI+1],BX
        JE      NEXT_FHB
        DEC     AX
        JNZ     NEXT_FHB
        ;Found FHB
        MOV     AX,DS
        MOV     ES,AX
        MOV     DI,SI
        CLC
        JMP     Short FRFHB_DONE
NO_RED_FHB:
        STC
FRFHB_DONE:
        POP     SI
        POP     DS
        POP     CX
        POP     AX
FRFHB_RETURN:
        RET
FIND_REDIRECTED_FHB     ENDP

;***********************************************************************

COMPARE_STRS    PROC
        PUSH    SI
        PUSH    DI
        CMP     AH,1
        JNE     CMP_STRS
        PUSH    AX      ;AH = 1
CMP_STRS:
        CMP     AH,1
        JE      COMP_1
        CMP     AH,2
        JE      COMP_2
COMP_0:
        CMP     BYTE PTR[SI],0
        JE      CMP_STRS_SUCCESS
        CMPSB
        JZ      COMP_0
        JMP     Short CMP_STRS_FAILURE
COMP_1:
        MOV     AH,ES:[DI]
        CMP     AH,0
        JE      CMP_1_SUCCESS
        INC     DI
        LODSB
        CMP     AL,AH
        JE      COMP_1
        JMP     Short CMP_1_FAILURE
COMP_2:
        CMPSB
        JNZ     CMP_STRS_FAILURE
        CMP     BYTE PTR[SI-1],0
        JNE     COMP_2
CMP_STRS_SUCCESS:
        CLC
        JMP     Short CMP_STRS_DONE
CMP_STRS_FAILURE:
        STC
        JMP     Short CMP_STRS_DONE
CMP_1_SUCCESS:
        CLC
        JMP     Short CMP_1_DONE
CMP_1_FAILURE:
        STC
CMP_1_DONE:
        POP     AX
CMP_STRS_DONE:
        POP     DI
        POP     SI
        RET
COMPARE_STRS    ENDP

;***********************************************************************

CHECK_RSVD_HDLS         PROC
        CALL    ASCIIZ_TO_UPPER
        XCHG    DX,SI
        PUSH    ES
        PUSH    DI
        MOV     DI,CS
        MOV     ES,DI
        ;-----------------------------------
        MOV     AH,2
        LEA     DI,RSVD_HDL_CON
        CALL    COMPARE_STRS
        JNC     CON_OK
        LEA     DI,RSVD_HDL_PRN
        CALL    COMPARE_STRS
        JNC     PRN_OK
        LEA     DI,RSVD_HDL_AUX
        CALL    COMPARE_STRS
        JNC     AUX_OK
        ;-----------------------------------
        CMP     BYTE PTR[SI+4],0
        JNE     NO_RSVD_HDL
        MOV     AH,[SI+3]
        CMP     AH,0
        JE      NO_RSVD_HDL
        CMP     AH,'0'
        JE      NO_RSVD_HDL
        SUB     AH,'0'
        CMP     AH,4
        JA      NO_RSVD_HDL
        JE      CHECK_COM
        MOV     AH,1
        LEA     DI,RSVD_HDL_LPT
        CALL    COMPARE_STRS
        JNC     PRN_OK
CHECK_COM:
        LEA     DI,RSVD_HDL_COM
        CALL    COMPARE_STRS
        JNC     AUX_OK
        JMP     Short NO_RSVD_HDL
        ;-----------------------------------
CON_OK:
        MOV     AH,1
        JMP     Short RSVD_OK
PRN_OK:
        MOV     AH,4
        JMP     Short RSVD_OK
AUX_OK:
        MOV     AH,3
RSVD_OK:
        CLC
        JMP     Short CHECK_RSVD_DONE
NO_RSVD_HDL:
        MOV     AH,05H
        STC
CHECK_RSVD_DONE:
        XCHG    DX,SI
        POP     DI
        POP     ES
        RET
CHECK_RSVD_HDLS         ENDP

;***********************************************************************

BUILD_FULL_PATH PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 60H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    BX
        PUSH    CX
        PUSH    DI
        PUSH    SI
        MOV     BX,AX
        XOR     CX,CX
        XOR     AH,AH
        CLD
BFP_CHECK_1:
        LODSB
        OR      AL,AL
        JZ      BFP_CHECK_1_DONE
        INC     CX
        CMP     AL,'/'
        JE      BFP_ERR
        CMP     AL,'>'
        JE      BFP_ERR
        CMP     AL,'<'
        JE      BFP_ERR
        CMP     AL,'"'
        JE      BFP_ERR
        CMP     AL,'.'
        JNE     BFP_CHECK_1
        INC     AH
        JMP     Short BFP_CHECK_1
BFP_CHECK_1_DONE:
        OR      CX,CX
        JZ      BFP_INSERT_FULL
        CMP     CX,15
        JA      BFP_ERR
        CMP     AH,1
        JA      BFP_ERR
        POP     SI
        PUSH    SI
        XCHG    SI,DX
        XOR     AL,AL
        CALL    CHECK_RSVD_HDLS
        XCHG    SI,DX
        JNC     BFP_ALL
        ;So it is not a standard handle.
        CLD
        LODSB
        CMP     AL,':'
        JE      BFP_ERR
        CMP     AL,'.'
        JE      BFP_ERR
        LODSB
BFP_CHECK_2:
        LODSB
        OR      AL,AL
        JZ      BFP_CHECK_2_DONE
        CMP     AL,':'
        JE      BFP_ERR
        ;Check character range
        CMP     AL,32
        JB      BFP_ERR
        JMP     Short BFP_CHECK_2
BFP_CHECK_2_DONE:
        POP     SI
        PUSH    SI
        LODSB
        CMP     AL,'\'
        JE      BFP_INSERT_DRIVE
        CMP     CX,1
        JE      BFP_INSERT_FULL
        LODSB
        CMP     AL,':'
        JNE     BFP_INSERT_FULL
        LODSB
        CMP     AL,'\'
        JE      BFP_ALL
        ;Insert a '\'
        POP     SI
        PUSH    SI
        MOVSB
        MOVSB
        MOV     AL,'\'
        STOSB
        DEC     CX
   REP  MOVSB
        JMP     Short BFP_SUCCESS
BFP_INSERT_DRIVE:
        POP     SI
        PUSH    SI
        MOV     AX,':A'
        STOSW
        INC     CX
   REP  MOVSB
        JMP     Short BFP_SUCCESS
BFP_INSERT_FULL:
        POP     SI
        PUSH    SI
        MOV     AX,':A'
        STOSW
        MOV     AL,'\'
        STOSB
        INC     CX
   REP  MOVSB
   JMP  Short BFP_SUCCESS
BFP_ALL:
        POP     SI
        PUSH    SI
        INC     CX
   REP  MOVSB
        OR      AL,AL
        JZ      BFP_SUCCESS_2
BFP_SUCCESS:
        POP     SI
        POP     DI
        PUSH    DI
        PUSH    SI
        CMP     ES:BYTE PTR[DI+3],'.'
        JE      BFP_ERR
        MOV     CX,DS
        MOV     SI,ES
        MOV     DS,SI
        MOV     SI,DI
        XOR     AH,AH
BFP_CHECK_3:
        LODSB
        OR      AL,AL
        JZ      BFP_CHECK_3_DONE
        CMP     AL,'\'
        JNE     BFP_CHECK_3
        INC     AH
        CMP     AH,1
        JBE     BFP_CHECK_3
BFP_CHECK_3_DONE:
        MOV     DS,CX
        CMP     AH,1
        JA      BFP_ERR
BFP_SUCCESS_2:
        CLC
        MOV     AX,BX
        JMP     Short BFP_DONE
BFP_ERR:
        STC
        MOV     AX,3;ERR_PNFOUND
BFP_DONE:
        POP     SI
        POP     DI
        POP     CX
        POP     BX
        RET
BUILD_FULL_PATH ENDP

;***********************************************************************

PREPARE_FILE_PATH       PROC
        PUSH    ES
        PUSH    DI
        PUSHF
        CMP     CS:FILE_PATH_FLAG,1
        JE      PFP_SUCCESS
        ;-----------------------------------
        POPF
        PUSHF
        PUSH    SI
        PUSH    AX
        JC      PFP_WILD_CARDS_OK
        MOV     SI,DX
        CLD
PFP_CHECK_WILD_CARDS:
        LODSB
        OR      AL,AL
        JZ      PFP_WILD_CARDS_OK
        CMP     AL,'?'
        JE      PFP_FAILURE
        CMP     AL,'*'
        JE      PFP_FAILURE
        JMP     Short PFP_CHECK_WILD_CARDS
PFP_WILD_CARDS_OK:
        POP     AX
        POP     SI
        ;-----------------------------------
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,FILE_PATH
        XCHG    DX,SI
        CALL    BUILD_FULL_PATH
        XCHG    DX,SI
        JC      PFP_DONE
        MOV     CS:WORD PTR MAIN_FILE_PATH_ADDR[0],DX
        MOV     CS:WORD PTR MAIN_FILE_PATH_ADDR[2],DS
        MOV     CS:FILE_PATH_FLAG,1
        MOV     DX,ES
        MOV     DS,DX
        MOV     DX,DI
PFP_SUCCESS:
        CLC
        JMP     Short PFP_DONE
PFP_FAILURE:
        POP     AX
        POP     SI
        MOV     AX,ERR_PNFOUND
        STC
PFP_DONE:
        POP     DI      ;POP old flags from the stack
        POP     DI
        POP     ES
PFP_RETURN:
        RET
PREPARE_FILE_PATH       ENDP

;***********************************************************************

RESTORE_FILE_PATH       PROC
        PUSHF
        CMP     CS:FILE_PATH_FLAG,0
        JE      RFP_RETURN
        MOV     CS:FILE_PATH_FLAG,0
        MOV     DX,CS:WORD PTR MAIN_FILE_PATH_ADDR[0]
        MOV     DS,CS:WORD PTR MAIN_FILE_PATH_ADDR[2]
        PUSH    AX
        MOV     AH,CS:RFP_MOVE_COUNT
        OR      AH,AH
        JZ      RFP_DONE
        ;Append AH characters to the end of the main path
        PUSH    SI
        PUSH    DI
        MOV     SI,DX
        CLD
RFP_FIND_END_1:
        LODSB
        OR      AL,AL
        JNZ     RFP_FIND_END_1
        XOR     AL,AL
        XCHG    AL,AH
        LEA     DI,FILE_PATH
RFP_FIND_END_2:
        CMP     CS:BYTE PTR[DI],00H
        JE      RFP_FOUND_END_2
        INC     DI
        JMP     Short RFP_FIND_END_2
RFP_FOUND_END_2:
        SUB     DI,AX
        INC     AX      ;1-byte instruction instead of INC AL
RFP_MOVE_CHARS:
        MOV     AH,CS:BYTE PTR[DI]
        MOV     BYTE PTR[SI],AH
        INC     DI
        INC     SI
        DEC     AL      ;2-byte instruction
        JNZ     RFP_MOVE_CHARS
        ;AL=0
        MOV     CS:RFP_MOVE_COUNT,AL
        POP     DI
        POP     SI
RFP_DONE:
        POP     AX
RFP_RETURN:
        POPF
        RET
RESTORE_FILE_PATH       ENDP

;***********************************************************************

GET_CURRENT_PSP PROC
        PUSH    BX
        MOV     AH,62H
        INT     21H
        MOV     AX,BX
        POP     BX
        RET
GET_CURRENT_PSP ENDP

;***********************************************************************
con_input_buf           label           byte
con_buf_len             db              128
num_read                db              0
con_buf                 db              128 dup(00h)
dummy                   db              0

rest_offset             dw              ?

read_std_device proc
        jcxz    r_std_dev_done
        push    es
        push    ds
        pop     es
        push    di
        push    cx
        mov     di,dx
r_std_dev_loop:
        int     21h
        stosb
        loop    r_std_dev_loop
        pop     cx
        pop     di
        pop     es
r_std_dev_done:
        mov     ax,cx
        clc
        ret
read_std_device endp

read_std_in     proc
        jcxz    raw_mode
        test    cs:con_dev_attr,100000b
        jnz     raw_mode
        ;-----------------------------------
        push    es
        push    ds
        pop     es
        push    ds
        push    cs
        pop     ds
        push    dx
        push    si
        push    di
        push    cx
        mov     di,dx
        lea     dx,con_input_buf
        lea     si,con_buf
        cmp     num_read,0
        jne     get_buf_rest
        mov     ah,0ah
        int     21h
        mov     al,num_read
        xor     ah,ah
        add     si,ax
        inc     si
        mov     byte ptr[si],0ah
        lea     si,con_buf
        cmp     al,01h
        jne     not_eof
        cmp     byte ptr[si],1ah        ;1AH=^Z
        jne     not_eof
        mov     num_read,0
        jmp     Short cooked_mode_done
not_eof:
        add     num_read,2
        jmp     Short get_con_input
get_buf_rest:
        mov     si,rest_offset
get_con_input:
        cld
move_bytes:
        lodsb
        stosb
        dec     num_read
        jz      input_done_1
        loop    move_bytes
        mov     rest_offset,si
        jmp     Short cooked_mode_done
input_done_1:
        dec     cx
cooked_mode_done:
        mov     dl,0ah
        mov     ah,02h
        int     21h
        pop     ax
        push    ax
        sub     ax,cx
        pop     cx
        pop     di
        pop     si
        pop     dx
        pop     ds
        pop     es
        clc
        jmp     Short r_std_in_return
        ;-----------------------------------
raw_mode:
        mov     ah,01h
        call    read_std_device
r_std_in_return:
        ret
read_std_in     endp

read_stdaux     proc
        mov     ah,03h
        call    read_std_device
        ret
read_stdaux     endp

READ_FILE_REC   PROC
        MOV     AL,ES:[DI+24]
        CMP     AL,05H
        JAE     R_NORMAL_FILE
        CMP     AL,00H
        JE      R_STD_IN
        CMP     AL,01H
        JE      R_STD_OUT
        CMP     AL,02H
        JE      R_STD_ERR
        CMP     AL,03H
        JE      R_STD_AUX
        ;-----------------------------------
        ;Read from Standard Printer
        ;Do nothing and only return with AX=0 bytes read
        XOR     AX,AX
        CLC
        JMP     RFR_RETURN
        ;-----------------------------------
R_STD_IN:
        CALL    READ_STD_IN
        JMP     RFR_RETURN
        ;-----------------------------------
R_STD_OUT:
        CALL    READ_STD_IN
        JMP     RFR_RETURN
        ;-----------------------------------
R_STD_ERR:
        CALL    READ_STD_IN
        JMP     RFR_RETURN
        ;-----------------------------------
R_STD_AUX:
        CALL    READ_STDAUX
        JMP     RFR_RETURN
        ;-----------------------------------
R_NORMAL_FILE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FHB_WORD_1,DI
        MOV     FHB_WORD_2,ES
        MOV     FHB_WORD_3,BX
        MOV     FHB_WORD_4,CX
        MOV     FHB_WORD_5,DX
        POP     DS
        ;-----------------------------------
        OR      CX,CX
        JZ      ZERO_REC_SIZE
        TEST    ES:BYTE PTR[DI+6],1
        JNZ     R_ACCESS_ERR
        MOV     AX,ES:[DI+11]
        MOV     DX,ES:[DI+13]
        ;DX:AX = Max_PTR
        SUB     AX,ES:[DI+7]
        SBB     DX,ES:[DI+9]
        CMP     DX,0
        JA      REC_SIZE_OK
        CMP     AX,CX
        JAE     REC_SIZE_OK
        MOV     CX,AX
REC_SIZE_OK:
        OR      CX,CX
        JZ      ZERO_REC_SIZE
        ;-----------------------------------
        PUSH    CX
        MOV     AX,ES:[DI+7]
        MOV     DX,ES:[DI+9]
        ;DX:AX = RW_PTR
        ;Now calculate cluster number
        ;DX:AX / 512
        XOR     BX,BX
        MOV     CX,9    ;512 = 2^9
DIVIDE:
        SHR     DX,1
        RCR     AX,1
        RCR     BX,1
        LOOP    DIVIDE
        MOV     CX,7
        SHR     BX,CL
        ADD     AX,1
        ADC     DX,0
        ;DX:AX = Sector number
        ;BX = Sector offset
        MOV     CL,ES:[DI+21]
        ;CL = Sector per cluster
        XOR     CH,CH
        DIV     CX
        CMP     DX,0
        JE      SET_SEC
        ADD     AX,1
        JNC     CLUS_NO_OK
        JMP     BAD_CLUS_NO
SET_SEC:
        MOV     DX,CX
CLUS_NO_OK:
        MOV     DH,ES:[DI+21]
        ;DH = Sector per cluster
        ;-----------------------------------
        MOV     CX,DS
        PUSH    DX
        PUSH    BX
        MOV     DX,ES
        MOV     DS,DX
        MOV     DX,DI
        ADD     DX,39
        CALL    EXTRACT_DRIVE_NO
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     BX
        POP     DX
        MOV     DS,CX
        ;FAT RW Started
        ;-----------------------------------
        MOV     CX,AX
        MOV     AX,ES:[DI+19]
        DEC     CX
        JZ      READ_RECORD
FIND_CLUS:
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_EOC
        JAE     JUMP_INVFRMT
        CMP     AX,FAT12_BADCLUS
        JE      READ_FAULT
        LOOP    FIND_CLUS
        JMP     Short READ_RECORD
JUMP_INVFRMT:
        POP     CX
        JMP     INVALID_FRMT
        ;-----------------------------------
READ_RECORD:
        ;AX = Cluster number
        ;DL = Sector number of cluster
        ;BX = Offset of first sector
        ;DH = Number of sectors per cluster
        POP     CX
        PUSH    DS
        PUSH    SI
        PUSH    CX
        MOV     SI,DS
        MOV     ES,SI
        MOV     SI,CS
        MOV     DS,SI
        MOV     DI,FHB_WORD_5
        ;ES:DI = Pointer to output buffer
START_RF:
        LEA     SI,FHB_DISK_BUF
        ;DS:SI = Pointer to FHB_DISK_BUF
        XCHG    BX,SI
        PUSH    CX
        MOV     CX,AX
        XOR     AH,AH
        MOV     AL,DL
        CALL    FAT12_RW_CLUS_SEC
        MOV     AX,CX
        POP     CX
        XCHG    BX,SI
        ADD     SI,BX
        PUSH    BX
        PUSH    CX
        CMP     CX,512
        JBE     MOVE_REST_2
        MOV     CX,512
MOVE_REST_2:
        PUSH    AX
        MOV     AX,512
        SUB     AX,BX
        CMP     CX,AX
        JBE     COUNT_OK_2
        MOV     CX,AX
COUNT_OK_2:
        POP     AX
        MOV     BX,CX
        CLD
    REP MOVSB
        POP     CX
        SUB     CX,BX
        POP     BX
        XOR     BX,BX
        OR      CX,CX
        JZ      STOP_RF
        ;-----------------------------------
        INC     DL
        CMP     DL,DH
        JA      GO_NEXT_CLUS
        JMP     Short START_RF
GO_NEXT_CLUS:
        MOV     DL,1
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_BADCLUS
        JE      STOP_RF
        CMP     AX,FAT12_EOC
        JB      START_RF
        ;invalid format error in FAT
        POP     CX
        POP     SI
        POP     DS
        JMP     Short INVALID_FRMT
STOP_RF:
        POP     AX
        POP     SI
        MOV     DI,FHB_WORD_1
        MOV     ES,FHB_WORD_2
        POP     DS
        ADD     ES:[DI+7],AX
        ADC     ES:WORD PTR[DI+9],0
        CLC
        JMP     Short RFR_DONE
        ;-----------------------------------
R_ACCESS_ERR:
        MOV     AX,ERR_IACODE
        STC
        JMP     Short RFR_RETURN
ZERO_REC_SIZE:
        XOR     AX,AX
        CLC
        JMP     Short RFR_DONE
BAD_CLUS_NO:
        POP     CX
        MOV     AX,ERR_IFORMAT
        STC
        JMP     Short RFR_DONE
READ_FAULT:
        POP     CX
        MOV     AX,ERR_RFAULT
        STC
        JMP     Short RFR_DONE
INVALID_FRMT:
        MOV     AX,ERR_IFORMAT
        STC
        ;-----------------------------------
RFR_DONE:
        PUSH    DS
        MOV     DX,CS
        MOV     DS,DX
        MOV     DI,FHB_WORD_1
        MOV     ES,FHB_WORD_2
        MOV     BX,FHB_WORD_3
        MOV     CX,FHB_WORD_4
        MOV     DX,FHB_WORD_5
        POP     DS
RFR_RETURN:
        RET
READ_FILE_REC   ENDP

;***********************************************************************

write_std_device        proc
        jcxz    w_std_dev_done
        push    bx
        push    cx
        push    dx
        mov     bx,dx
w_std_dev_loop:
        mov     dl,byte ptr[bx]
        int     21h
        inc     bx
        loop    w_std_dev_loop
        pop     dx
        pop     cx
        pop     bx
w_std_dev_done:
        mov     ax,cx
        clc
        ret
write_std_device        endp

write_std_out   proc
        mov     ah,02h
        call    write_std_device
        ret
write_std_out   endp

write_stdprn    proc
        mov     ah,05h
        call    write_std_device
        ret
write_stdprn    endp

write_stdaux    proc
        mov     ah,04h
        call    write_std_device
        ret
write_stdaux    endp

WRITE_FILE_REC  PROC
        MOV     AL,ES:[DI+24]
        CMP     AL,05H
        JAE     W_NORMAL_FILE
        CMP     AL,00H
        JE      W_STD_IN
        CMP     AL,01H
        JE      W_STD_OUT
        CMP     AL,02H
        JE      W_STD_ERR
        CMP     AL,03H
        JE      W_STD_AUX
        ;-----------------------------------
        ;Write to Standard Printer
        CALL    WRITE_STDPRN
        JMP     WFR_RETURN
        ;-----------------------------------
W_STD_IN:
        CALL    WRITE_STD_OUT
        JMP     WFR_RETURN
        ;-----------------------------------
W_STD_OUT:
        CALL    WRITE_STD_OUT
        JMP     WFR_RETURN
        ;-----------------------------------
W_STD_ERR:
        CALL    WRITE_STD_OUT
        JMP     WFR_RETURN
        ;-----------------------------------
W_STD_AUX:
        CALL    WRITE_STDAUX
        JMP     WFR_RETURN
        ;-----------------------------------
W_NORMAL_FILE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FHB_WORD_1,DI
        MOV     FHB_WORD_2,ES
        MOV     FHB_WORD_3,BX
        MOV     FHB_WORD_4,CX
        MOV     FHB_WORD_5,DX
        POP     DS
        ;-----------------------------------
        TEST    ES:BYTE PTR[DI+6],3
        JZ      W_ACCESS_ERR
        ;-----------------------------------
        OR      ES:BYTE PTR[DI+27],01H          ;Update file date and time at close
        MOV     AX,ES:[DI+7]
        MOV     DX,ES:[DI+9]
        ;DX:AX = RW_PTR
        ;Now calculate cluster number
        ;DX:AX / 512
        XOR     BX,BX
        MOV     CX,9    ;512 = 2^9
DIVIDE_IT:
        SHR     DX,1
        RCR     AX,1
        RCR     BX,1
        LOOP    DIVIDE_IT
        MOV     CX,7
        SHR     BX,CL
        ADD     AX,1
        ADC     DX,0
        ;DX:AX = Sector number(1-n)
        ;BX = Sector offset
        MOV     CL,ES:[DI+21]
        ;CL = Sector per cluster
        XOR     CH,CH
        DIV     CX
        CMP     DX,0
        JE      SET_SEC_NO
        ADD     AX,1
        JNC     VALID_CLUS_NO
        JMP     WFR_INV_CLUS_NO
SET_SEC_NO:
        MOV     DX,CX
VALID_CLUS_NO:
        MOV     DH,ES:[DI+21]
        ;DH = Sector per cluster
        ;-----------------------------------
        MOV     CX,DS
        PUSH    DX
        PUSH    BX
        PUSH    ES
        POP     DS
        MOV     DX,DI
        ADD     DX,39
        CALL    EXTRACT_DRIVE_NO
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        ;FAT RW Started
        MOV     DS,CX
        POP     BX
        MOV     CX,AX
        MOV     AX,ES:[DI+19]
        OR      AX,AX
        JNZ     FIRST_CLUS_OK
        CALL    APPEND_CLUSTER
        JC      JMP_WRITE_FAULT
        MOV     ES:[DI+19],AX
        PUSH    DS
        PUSH    SI
        PUSH    ES
        POP     DS
        MOV     DX,DI
        ADD     DX,39
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,FHB_DIR_ENT
        MOV     SI,AX
        CALL    READ_FILE_DIR_ENTRY
        JC      WFR_CRIT_ERR
        MOV     ES:[DI+26],SI
        MOV     SI,DS
        MOV     ES,SI
        MOV     SI,DI
        MOV     DI,DX
        SUB     DI,39
        MOV     DX,CS
        MOV     DS,DX
        CALL    FAT12_WRITE_DIR_ENTRY
        POP     SI
        POP     DS
        ;-----------------------------------
FIRST_CLUS_OK:
        MOV     AX,ES:[DI+19]
        ;AX = First Cluster Number Of File
        DEC     CX
        JZ      FOUND_W_CLUS
FIND_W_CLUS:
        PUSH    AX
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_EOC
        JAE     CHECK_INVFRMT
        ADD     SP,2
        CMP     AX,FAT12_BADCLUS
        JE      JMP_INVALID_FRMT_W
        LOOP    FIND_W_CLUS
FOUND_W_CLUS:
        POP     DX
        CMP     CS:FHB_WORD_4,0         ;FHB_WORD_4 = Original CX(Number of bytes to be written)
        JNE     WRITE_RECORD
        ;-----------------------------------
        ;CX=0 => Truncate the file to the current read/write pointer position
        ;AX = Cluster number
        ;DL = Sector number of cluster
        ;BX = Offset of first sector
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     DI,FHB_WORD_1
        MOV     ES,FHB_WORD_2
        MOV     ES:WORD PTR[DI+11],0
        MOV     ES:WORD PTR[DI+13],0
        MOV     BX,AX
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_EOC
        JE      CLUS_CHAIN_UPDATED
        MOV     CX,FAT12_EOC
        XCHG    AX,BX
        CALL    FAT12_WRITE_FAT_ENTRY
        MOV     AX,BX
        CALL    DELETE_CLUSTER_CHAIN
CLUS_CHAIN_UPDATED:
        POP     DS
        XOR     AX,AX
        PUSH    SI      ;PUSH original SI on the stack
        JMP     CHECK_SIZE_UPDATE
        ;-----------------------------------
JMP_WRITE_FAULT:
        POP     DX
        JMP     WRITE_FAULT
JMP_INVALID_FRMT_W:
        POP     DX
        JMP     INVALID_FRMT_W
CHECK_INVFRMT:
        POP     AX
        CMP     CX,1
        JNE     JMP_INVALID_FRMT_W
        PUSH    AX
        MOV     AX,ES:[DI+7]
        CMP     AX,ES:[DI+11]
        POP     AX
        JNE     JMP_INVALID_FRMT_W
        PUSH    AX
        MOV     AX,ES:[DI+9]
        CMP     AX,ES:[DI+13]
        POP     AX
        JNE     JMP_INVALID_FRMT_W
        CALL    APPEND_CLUSTER
        POP     DX
        JC      WRITE_FAULT
        ;-----------------------------------
WRITE_RECORD:
        PUSH    SI
        MOV     CX,CS:FHB_WORD_4
        MOV     SI,CS:FHB_WORD_5
        ;DS:SI = Pointer to input buffer
        ;AX = Cluster number
        ;DL = Sector number of cluster
        ;BX = Offset of first sector
        ;DH = Number of sectors per cluster
        PUSH    CX
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,FHB_DISK_BUF
START_WF:
        ;ES:DI = Pointer to 512 bytes buffer
        OR      BX,BX
        JNZ     PARTIAL_SECTOR
        CMP     CX,512
        JAE     MOVE_DATA
PARTIAL_SECTOR:
        ;Read sector
        XCHG    BX,DI
        PUSH    CX
        PUSH    DS
        PUSH    ES
        POP     DS
        MOV     CX,AX
        XOR     AH,AH   ;read cluster
        MOV     AL,DL
        CALL    FAT12_RW_CLUS_SEC
        MOV     AX,CX
        POP     DS
        POP     CX
        JC      W_READ_FAULT
        XCHG    BX,DI
        ;-----------------------------------
MOVE_DATA:
        ADD     DI,BX
        PUSH    BX
        PUSH    CX
        CMP     CX,512
        JBE     MOVE_REST
        MOV     CX,512
MOVE_REST:
        PUSH    AX
        MOV     AX,512
        SUB     AX,BX
        CMP     CX,AX
        JBE     COUNT_OK
        MOV     CX,AX
COUNT_OK:
        POP     AX
        MOV     BX,CX
        CLD
    REP MOVSB
        POP     CX
        SUB     CX,BX
        POP     BX
        XOR     BX,BX
        ;-----------------------------------
        ;Write sector
        LEA     DI,FHB_DISK_BUF
        XCHG    BX,DI
        PUSH    CX
        PUSH    DS
        PUSH    ES
        POP     DS
        MOV     CX,AX
        MOV     AH,1    ;Write sector
        MOV     AL,DL
        CALL    FAT12_RW_CLUS_SEC
        MOV     AX,CX
        POP     DS
        POP     CX
        JC      WRITE_FAULT_2
        XCHG    BX,DI
        OR      CX,CX
        JZ      STOP_WF
        INC     DL
        CMP     DL,DH
        JA      GO_NEXT_CLUS_2
        JMP     Short START_WF
GO_NEXT_CLUS_2:
        MOV     DL,1
        PUSH    DX
        MOV     DX,AX
        CALL    FAT12_READ_FAT_ENTRY
        CMP     AX,FAT12_BADCLUS
        JE      BAD_CLUSTER
        CMP     AX,FAT12_EOC
        JB      NEXT_CLUS_OK_3
        MOV     AX,DX
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        MOV     DX,FHB_WORD_1
        ADD     DX,39
        MOV     AX,FHB_WORD_2
        MOV     DS,AX
        POP     AX
        CALL    EXTRACT_DRIVE_NO
        POP     DS
        CALL    APPEND_CLUSTER
        POP     DX
        JC      STOP_WF
        JMP     Short NEXT_CLUS_OK
NEXT_CLUS_OK_3:
        POP     DX
NEXT_CLUS_OK:
        JMP     START_WF
BAD_CLUSTER:
        POP     DX
STOP_WF:
        POP     AX
        SUB     AX,CX
        PUSH    DS
        MOV     SI,CS
        MOV     DS,SI
        MOV     DI,FHB_WORD_1
        MOV     ES,FHB_WORD_2
        POP     DS
        ADD     ES:[DI+7],AX
        ADC     ES:WORD PTR[DI+9],0
CHECK_SIZE_UPDATE:
        PUSH    AX
        MOV     AX,ES:[DI+7]
        MOV     SI,ES:[DI+9]
        ;SI:AX = RW_PTR
        CMP     SI,ES:[DI+13]
        JA      UPDATE_SIZE
        JB      SIZE_OK
        CMP     AX,ES:[DI+11]
        JBE     SIZE_OK
        ;-----------------------------------
UPDATE_SIZE:
        MOV     ES:[DI+11],AX
        MOV     ES:[DI+13],SI
        PUSH    DS
        MOV     AX,ES
        MOV     DS,AX
        MOV     DX,DI
        ADD     DX,39
        MOV     AX,CS
        MOV     ES,AX
        LEA     DI,FHB_DIR_ENT
        CALL    READ_FILE_DIR_ENTRY
        JC      DIR_ENT_NOT_FOUND
        MOV     SI,DX
        SUB     SI,39
        PUSH    AX
        MOV     AX,ES:[SI+11]
        MOV     ES:[DI+28],AX
        MOV     AX,[SI+13]
        MOV     ES:[DI+30],AX
        MOV     AX,ES
        MOV     DS,AX
        MOV     SI,DI
        POP     AX
        CALL    FAT12_WRITE_DIR_ENTRY
DIR_ENT_NOT_FOUND:
        POP     DS
SIZE_OK:
        POP     AX
        POP     SI
        CLC
        JMP     Short WFR_DONE
        ;-----------------------------------
W_ACCESS_ERR:
        MOV     AX,ERR_IACODE
        STC
        JMP     Short WFR_RETURN
WFR_INV_CLUS_NO:
INVALID_FRMT_W:
        MOV     AX,ERR_IFORMAT
        STC
        JMP     Short WFR_DONE
WRITE_FAULT_2:
        POP     CX
        POP     SI
WRITE_FAULT:
        MOV     AX,ERR_WFAULT
        STC
        JMP     Short WFR_DONE
W_READ_FAULT:
        POP     CX
        POP     SI
        MOV     AX,ERR_RFAULT
        STC
        JMP     Short WFR_DONE
WFR_CRIT_ERR:           ;There was a critical error.
        CALL    HALT    ;In this version
        STC
WFR_DONE:
        PUSH    DS
        MOV     BX,CS
        MOV     DS,BX
        MOV     DI,FHB_WORD_1
        MOV     ES,FHB_WORD_2
        MOV     BX,FHB_WORD_3
        MOV     CX,FHB_WORD_4
        MOV     DX,FHB_WORD_5
        POP     DS
WFR_RETURN:
        RET
WRITE_FILE_REC  ENDP

;***********************************************************************

INCALL_UPDATE_FHBS      PROC
        PUSH    AX
        PUSH    BX
        MOV     BX,ES:[DI+1]
        MOV     AX,1
UPDATE_FHBS_2:
        CALL    FIND_REDIRECTED_FHB
        JC      UPDATE_DONE_2
        ADD     DI,7
        CLD
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        SUB     SI,8
        SUB     DI,15
        INC     AX
        CMP     ES:BYTE PTR[DI+23],0
        JE      UPDATE_FHBS_2
        CALL    INCALL_UPDATE_FHBS
        JMP     Short UPDATE_FHBS_2
UPDATE_DONE_2:
        POP     BX
        POP     AX
        RET
INCALL_UPDATE_FHBS      ENDP

;***********************************************************************

RW_FILE         PROC
        PUSH    ES
        PUSH    DI
        CALL    FIND_FHB
        JC      ERR_INVHDL
        ;-----------------------------------
        CMP     ES:BYTE PTR[DI+22],0
        JE      CORRECT_FHB
        CALL    FIND_TARGET_FHB
        JC      ERR_INVHDL
CORRECT_FHB:
        CMP     AL,0
        JE      RF_FUNCTION
        CMP     AL,1
        JNE     RWF_DONE
        ;WF_FUNCTION
        CALL    WRITE_FILE_REC
        JMP     Short CONTINUE_RWF
RF_FUNCTION:
        CALL    READ_FILE_REC
CONTINUE_RWF:
        JC      RWF_DONE
        OR      AX,AX
        JZ      RW_ZERO_REC
        ;-----------------------------------
        ;Update all related FHBs
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FHB_WORD_1,SI
        MOV     FHB_WORD_2,AX
        MOV     FHB_WORD_3,BX
        MOV     BX,ES:[DI+1]
        MOV     AX,ES
        MOV     DS,AX
        MOV     SI,DI
        ADD     SI,7
        MOV     AX,1
UPDATE_FHBS:
        CALL    FIND_REDIRECTED_FHB
        JC      UPDATE_DONE
        ADD     SI,7
        CLD
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        SUB     SI,8
        SUB     DI,15
        INC     AX
        CMP     ES:BYTE PTR[DI+23],0
        JE      UPDATE_FHBS
        CALL    INCALL_UPDATE_FHBS
        JMP     Short UPDATE_FHBS
UPDATE_DONE:
        PUSH    CS
        POP     DS
        MOV     SI,FHB_WORD_1
        MOV     AX,FHB_WORD_2
        MOV     BX,FHB_WORD_3
        POP     DS
        CLC
        JMP     Short RWF_DONE
        ;-----------------------------------
ERR_INVHDL:
        MOV     AX,ERR_IHANDLE
        STC
        JMP     Short RWF_DONE
RW_ZERO_REC:
        CLC
RWF_DONE:
        POP     DI
        POP     ES
        RET
RW_FILE         ENDP

;***********************************************************************

READ_FILE       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 3FH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        XOR     AL,AL   ;Read file
        CALL    RW_FILE
        CALL    UPDATE_EXT_ERROR_INF
        RET
READ_FILE       ENDP

;***********************************************************************

WRITE_FILE      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 40H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     AL,1    ;Write file
        CALL    RW_FILE
        CALL    UPDATE_EXT_ERROR_INF
        RET
WRITE_FILE      ENDP

;***********************************************************************

OPEN_FILE       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 3DH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    PREPARE_FILE_PATH
        JC      OPEN_RETURN
        ;-----------------------------------
        PUSH    ES
        PUSH    DI
        CALL    FIND_UNUSED_FHB
        JC      OF_ERROR_TMOF
        ;-----------------------------------
        PUSH    DS
        PUSH    BX
        PUSH    DX
        XOR     DL,DL           ;Only drive A: in this version
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     DX
        POP     BX
        POP     DS
        ;-----------------------------------
        CALL    CHECK_RSVD_HDLS
        JNC     ALL_OK
        ;-----------------------------------
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,FHB_DIR_ENT
        PUSH    AX
        CALL    READ_FILE_DIR_ENTRY
        JC      OF_ERROR_1
        TEST    ES:BYTE PTR[DI+11],00011000b    ;Directories and volume labels can not be opened.
        JNZ     OF_ERROR_1
        POP     AX
        TEST    ES:BYTE PTR[DI+11],10H
        JNZ     ERROR_FNF
        TEST    AL,3
        JZ      ALL_OK
TEST_RO_FILE:
        CMP     CS:FHB_SYSTEM_CALL,0
        JNE     ALL_OK
        TEST    ES:BYTE PTR[DI+11],1
        JNZ     ERROR_RO_FILE
        ;-----------------------------------
ALL_OK:
        CALL    FIND_UNUSED_FHB
        MOV     ES:BYTE PTR[DI],1
        MOV     ES:BYTE PTR[DI+6],AL
        MOV     ES:BYTE PTR[DI+24],AH
        CALL    GET_CURRENT_PSP
        MOV     ES:[DI+25],AX
        XOR     AX,AX
        MOV     ES:[DI+27],AL
        MOV     ES:[DI+22],AX
        MOV     ES:[DI+7],AX
        MOV     ES:[DI+9],AX
        CMP     ES:BYTE PTR[DI+24],05H
        JAE     NORMAL_FILE
        MOV     AX,ES:[DI+1]
        CLC
        JMP     Short OPEN_DONE
        ;-----------------------------------
NORMAL_FILE:
        XCHG    DX,SI
        ADD     DI,39
        XOR     AX,AX
FILL_FHB_NAME:
        CMP     BYTE PTR[SI],0
        JE      FHB_NAME_DONE
        CLD
        MOVSB
        INC     AX
        JMP     Short FILL_FHB_NAME
FHB_NAME_DONE:
        MOV     ES:BYTE PTR[DI],00H
        SUB     DI,AX
        SUB     DI,39
        SUB     SI,AX
        XCHG    DX,SI
        PUSH    CX
        PUSH    BX
        PUSH    ES
        PUSH    DI
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,FHB_DIR_ENT
        CALL    READ_FILE_DIR_ENTRY
        MOV     AX,ES:[DI+28]
        MOV     CX,ES:[DI+30]
        MOV     BX,ES:[DI+26]
        POP     DI
        POP     ES
        MOV     ES:[DI+11],AX
        MOV     ES:[DI+13],CX
        MOV     ES:[DI+19],BX
        MOV     CX,DS
        PUSH    CS
        POP     DS
        MOV     BL,FAT12_SEC_PER_CLUS
        MOV     ES:[DI+21],BL
        MOV     DS,CX
        POP     BX
        POP     CX
        MOV     AX,ES:[DI+1]
        CLC
        JMP     Short OPEN_DONE
        ;-----------------------------------
OF_ERROR_TMOF:
        MOV     AX,ERR_TMOFILES
        STC
        JMP     Short OPEN_DONE
OF_ERROR_1:
        MOV     DI,AX
        POP     AX
        MOV     AX,DI
        STC
        JMP     Short OPEN_DONE
ERROR_FNF:
        MOV     AX,ERR_FNFOUND
        STC
        JMP     Short OPEN_DONE
ERROR_RO_FILE:
        MOV     AX,ERR_ADENIED
        STC
OPEN_DONE:
        POP     DI
        POP     ES
OPEN_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
OPEN_FILE       ENDP

;***********************************************************************

CHECK_FHB_CLOSE_ACCESS  PROC
;INPUT:  ES:DI=Pointer to the beginning of a FHB to check current process close access
;OUTPUT: CF=0=> Close permitted , CF=1=> Access is denied
        PUSH    AX
        CMP     CS:LOADING_STAGE,0
        JNE     ACCESS_OK
        CMP     ES:WORD PTR[DI+1],4
        JBE     ACCESS_OK
        CALL    GET_CURRENT_PSP
        CMP     AX,ES:[DI+25]
        JNE     ACCESS_DENIED
ACCESS_OK:
        CLC
        JMP     Short CHECK_ACCESS_DONE
ACCESS_DENIED:
        STC
CHECK_ACCESS_DONE:
        POP     AX
        RET
CHECK_FHB_CLOSE_ACCESS  ENDP

;***********************************************************************

CLOSE_FILE      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 3EH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FHB_WORD_1,ES
        MOV     FHB_WORD_2,DI
        MOV     FHB_WORD_3,CX
        MOV     FHB_WORD_4,DX
        MOV     FHB_WORD_5,BX
        POP     DS
        ;-----------------------------------
        CALL    FIND_FHB
        JC      CF_ERR_IHDL
        CALL    CHECK_FHB_CLOSE_ACCESS
        JC      CF_ACCESS_ERR
        ;-----------------------------------
        PUSH    AX
        CMP     ES:BYTE PTR[DI+23],0
        JE      DIRECTION_OK
        MOV     CX,ES:[DI+3]
        MOV     DL,ES:[DI+24]
        MOV     DH,ES:[DI+22]
        MOV     AX,1
        PUSH    ES
        PUSH    DI
UPDATE_DIR:
        CALL    FIND_REDIRECTED_FHB
        JC      UPDT_DIR_DONE
        CMP     DH,0
        JE      NOT_REDIR
        MOV     ES:[DI+3],CX
        JMP     Short UPDATE_DIR
NOT_REDIR:
        MOV     ES:BYTE PTR[DI+22],0
        MOV     ES:[DI+24],DL
        JMP     Short UPDATE_DIR
UPDT_DIR_DONE:
        POP     DI
        POP     ES
        ;-----------------------------------
DIRECTION_OK:
        CMP     ES:BYTE PTR[DI+22],0
        JE      REDIRECTION_OK
        MOV     ES:BYTE PTR[DI+22],0
        MOV     BX,ES:[DI+3]
        MOV     AX,1
        PUSH    ES
        PUSH    DI
        CALL    FIND_REDIRECTED_FHB
        JNC     REDIRECTED
        CALL    FIND_FHB
        MOV     ES:BYTE PTR[DI+23],0
REDIRECTED:
        POP     DI
        POP     ES
        ;-----------------------------------
REDIRECTION_OK:
        MOV     ES:BYTE PTR[DI],0
        TEST    ES:BYTE PTR[DI+6],03H
        JZ      DIR_ENTRY_DONE
        TEST    ES:BYTE PTR[DI+27],01H
        JZ      DIR_ENTRY_DONE
        CMP     ES:BYTE PTR[DI+24],05H
        JB      DIR_ENTRY_DONE
        ;So it is a normal file
        PUSH    DS
        ;-----------------------------------
        ;In this point DS and AX and DX are free to use.
        XOR     DL,DL           ;Only drive A: in this version
        PUSH    CS
        POP     DS
        MOV     AX,BX
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        MOV     BX,AX
        ;-----------------------------------
        PUSH    ES
        POP     DS
        MOV     DX,DI
        ADD     DX,39
        PUSH    ES
        MOV     BX,DI
        PUSH    CS
        POP     ES
        LEA     DI,FHB_DIR_ENT
        CALL    READ_FILE_DIR_ENTRY
        JC      DT_UPDATED
        PUSH    AX
        MOV     AX,ES
        MOV     DS,AX
        XCHG    DI,SI
        MOV     AH,2CH
        INT     21H
        MOV     AL,CH
        MOV     CH,CL
        MOV     CL,DH
        CALL    ENCODE_FILE_TIME
        MOV     [SI+22],CX
        MOV     AH,2AH
        INT     21H
        MOV     AX,CX
        SUB     AX,1980
        MOV     CX,DX
        CALL    ENCODE_FILE_DATE
        MOV     [SI+24],CX
        POP     AX
        CALL    FAT12_WRITE_DIR_ENTRY
        MOV     SI,DI
DT_UPDATED:
        MOV     DI,BX
        POP     ES
        POP     DS
        ;-----------------------------------
DIR_ENTRY_DONE:
        ;END_RW
        ;In this point AX and BX and CX and DX and ES and DI are free to use.
        XOR     DL,DL           ;Only drive A: in this version
        CALL    FAT12_END_RW
        ;-----------------------------------
        CLC
        POP     AX
        JMP     Short CLOSE_DONE
        ;-----------------------------------
CF_ACCESS_ERR:
        MOV     AX,ERR_ADENIED
        JMP     Short CF_FAILURE
CF_ERR_IHDL:
        MOV     AX,ERR_IHANDLE
CF_FAILURE:
        STC
CLOSE_DONE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     ES,FHB_WORD_1
        MOV     DI,FHB_WORD_2
        MOV     CX,FHB_WORD_3
        MOV     DX,FHB_WORD_4
        MOV     BX,FHB_WORD_5
        POP     DS
        CALL    UPDATE_EXT_ERROR_INF
        RET
CLOSE_FILE      ENDP

;***********************************************************************

MCR_DUP_FHB     PROC
        CMP     ES:BYTE PTR[DI],1
        JE      MCR_OWNER_DONE
        MOV     ES:BYTE PTR[DI],1
        MOV     CX,AX
        CALL    GET_CURRENT_PSP
        MOV     ES:[DI+25],AX
        MOV     AX,CX
MCR_OWNER_DONE:
        MOV     CX,[SI+1]
        MOV     ES:[DI+3],CX
        MOV     ES:BYTE PTR[DI+22],1
        MOV     ES:BYTE PTR[DI+23],0
        MOV     CL,[SI+24]
        MOV     ES:[DI+24],CL
        MOV     CX,[SI+19]
        MOV     ES:[DI+19],CX
        MOV     CL,[SI+21]
        MOV     ES:[DI+21],CL
        MOV     CL,[SI+27]
        MOV     ES:[DI+27],CL
        ADD     SI,6
        ADD     DI,6
        CLD
        MOVSB
        MOV     CX,4
   REP  MOVSW
        ADD     SI,24
        ADD     DI,24
        MOV     CX,8
        CLD
   REP  MOVSW
        SUB     DI,55
        SUB     SI,55
        RET
MCR_DUP_FHB     ENDP

;***********************************************************************

DUPLICATE_FHB   PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 45H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DS
        MOV     AX,CS
        MOV     DS,AX
        MOV     FHB_WORD_1,ES
        MOV     FHB_WORD_2,DI
        MOV     FHB_WORD_3,CX
        MOV     FHB_WORD_4,SI
        POP     DS
        ;-----------------------------------
        CALL    FIND_FHB
        JC      DUP_FHB_ERR_INVHDL
        MOV     CX,ES
        MOV     SI,DI
        CALL    FIND_UNUSED_FHB
        JC      ERR_TMO_FILES
        ;-----------------------------------
        PUSH    DS
        MOV     DS,CX
        ;DS:SI = Pointer to main FHB
        ;ES:DI = Pointer to new FHB
        MOV     AX,ES:[DI+1]
        CALL    MCR_DUP_FHB
        POP     DS
        CLC
        JMP     Short DUP_DONE
        ;-----------------------------------
DUP_FHB_ERR_INVHDL:
        MOV     AX,ERR_IHANDLE
        JMP     Short ERROR_HERE
ERR_TMO_FILES:
        MOV     AX,ERR_TMOFILES
ERROR_HERE:
        STC
DUP_DONE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     ES,FHB_WORD_1
        MOV     DI,FHB_WORD_2
        MOV     CX,FHB_WORD_3
        MOV     SI,FHB_WORD_4
        POP     DS
        CALL    UPDATE_EXT_ERROR_INF
        RET
DUPLICATE_FHB   ENDP

;***********************************************************************

REDIRECT_FHB    PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 46H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FHB_WORD_1,ES
        MOV     FHB_WORD_2,DI
        MOV     FHB_WORD_3,DX
        MOV     FHB_WORD_4,SI
        POP     DS
        ;-----------------------------------
        CALL    FIND_SPEC_FHB
        JC      HDL_NOT_EXISTS
        XCHG    BX,CX
        CALL    FIND_SPEC_FHB
        XCHG    BX,CX
        JC      HDL_NOT_EXISTS
        ;-----------------------------------
        OR      CX,CX
        JZ      ERR_INV_HANDLE
        CMP     CX,03
        JE      ERR_INV_HANDLE
        CMP     CX,04
        JE      ERR_INV_HANDLE
        ;-----------------------------------
        CMP     BX,CX
        JE      ERR_INV_HANDLE
        CALL    FIND_FHB
        JC      ERR_INV_HANDLE
        XCHG    BX,CX
        CALL    FIND_SPEC_FHB
        XCHG    BX,CX
        JE      RESET_DIRECTION
        ;Close source file handle(CX)
        ;In fact flush it
        ;...
        ;nothing to do in this version
        ;...
        JMP     Short DUPLICATE
RESET_DIRECTION:
        MOV     ES:BYTE PTR[DI+23],0
DUPLICATE:
        ;ES:DI => CX FHB
        PUSH    DS
        PUSH    ES
        MOV     DX,DI
        CALL    FIND_FHB
        MOV     SI,DI
        MOV     DI,DX
        MOV     DX,ES
        MOV     DS,DX
        POP     ES
        PUSH    CX
        MOV     DL,ES:[DI+23]
        CALL    MCR_DUP_FHB
        POP     CX
        POP     DS
        CLC
        JMP     Short REDIRECTION_DONE
        ;-----------------------------------
HDL_NOT_EXISTS:
        MOV     AX,ERR_IHANDLE
        JMP     Short REDIRECTION_ERR
ERR_INV_HANDLE:
        MOV     AX,ERR_IHANDLE
REDIRECTION_ERR:
        STC
REDIRECTION_DONE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     ES,FHB_WORD_1
        MOV     DI,FHB_WORD_2
        MOV     DX,FHB_WORD_3
        MOV     SI,FHB_WORD_4
        POP     DS
        CALL    UPDATE_EXT_ERROR_INF
        RET
REDIRECT_FHB    ENDP

;***********************************************************************

ADD_DIR_ENTRY   PROC
        PUSH    BX
        PUSH    ES
        PUSH    DS
        MOV     BX,CS
        MOV     DS,BX
        MOV     ES,BX
        MOV     FHB_WORD_1,SI
        MOV     FHB_WORD_2,DI
        POP     DS
        PUSH    AX
        PUSH    DX
        CALL    EXTRACT_DRIVE_NO
        LEA     DI,FHB_DIR_ENT
        CALL    FIND_FREE_DIR_ENTRY
        POP     DX
        CMP     AX,0
        JE      ERROR_NODIRENT
        MOV     BX,DX
        ADD     BX,3
        CALL    GET_11_BYTE_F_NAME
        POP     BX
        XCHG    AX,BX
        ;-----------------------------------
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    CX
        LEA     DI,FHB_DIR_ENT
        MOV     SI,AX
        XOR     AX,AX
        MOV     CX,16
        CLD
   REP  STOSW
        SUB     DI,32
        MOV     AX,SI
        LEA     SI,DIR_11_BYTE_F_NAME
        MOV     CX,11
        CLD
   REP  MOVSB
        POP     CX
        SUB     DI,11
        MOV     SI,DI
        MOV     [SI+11],CL
        MOV     [SI+26],AX
        ;now DS=CS
        MOV     DI,WORD PTR FHB_DWORD_TEMP[0]
        MOV     [SI+28],DI
        MOV     DI,WORD PTR FHB_DWORD_TEMP[2]
        MOV     [SI+30],DI
        ;-----------------------------------
        MOV     DI,AX
        PUSH    CX
        PUSH    DX
        MOV     AH,2CH
        INT     21H
        MOV     AL,CH
        MOV     CH,CL
        MOV     CL,DH
        CALL    ENCODE_FILE_TIME
        MOV     [SI+22],CX
        MOV     AH,2AH
        INT     21H
        MOV     AX,CX
        SUB     AX,1980
        MOV     CH,DH
        MOV     CL,DL
        POP     DX
        CALL    ENCODE_FILE_DATE
        MOV     [SI+24],CX
        POP     CX
        MOV     AX,BX
        CALL    FAT12_WRITE_DIR_ENTRY
        MOV     AX,DI
        CLC
        JMP     Short ADD_DONE
        ;-----------------------------------
ERROR_NODIRENT:
        POP     AX
        PUSH    DS
        MOV     BX,CS
        MOV     DS,BX
        STC
ADD_DONE:
        MOV     SI,FHB_WORD_1
        MOV     DI,FHB_WORD_2
        POP     DS
        POP     ES
        POP     BX
        RET
ADD_DIR_ENTRY   ENDP

;***********************************************************************

CREATE_FILE     PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 3CH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    PREPARE_FILE_PATH
        JC      CREATE_RETURN
        ;-----------------------------------
        CALL    CHECK_RSVD_HDLS
        JNC     FILE_OK
        ;-----------------------------------
        PUSH    ES
        PUSH    DI
        CALL    FIND_UNUSED_FHB
        JC      ERROR_TMOF
        ;-----------------------------------
        ;In this point ES and DI are free to use.
        MOV     DI,DS
        MOV     ES,DX
        PUSH    BX
        XOR     DL,DL           ;Only drive A: in this version
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     BX
        MOV     DX,ES
        MOV     DS,DI
        ;-----------------------------------
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,FHB_DIR_ENT
        CALL    READ_FILE_DIR_ENTRY
        JC      ADD_NEW_FILE
        TEST    ES:BYTE PTR[DI+11],00011000b    ;Directories and volume label is not allowed.
        JNZ     ERROR_AD
        ;File already exists
        TEST    ES:BYTE PTR[DI+11],1
        JNZ     ERROR_AD
        PUSH    AX
        MOV     AX,ES:[DI+26]
        PUSH    DX
        CALL    EXTRACT_DRIVE_NO
        CALL    DELETE_CLUSTER_CHAIN
        XOR     DX,DX
        MOV     ES:[DI+26],DX
        MOV     ES:[DI+28],DX
        MOV     ES:[DI+30],DX
        POP     DX
        MOV     ES:[DI+11],CL
        POP     AX
        XCHG    DI,SI
        PUSH    DS
        PUSH    ES
        POP     DS
        CALL    FAT12_WRITE_DIR_ENTRY
        POP     DS
        MOV     SI,DI
        POP     DI
        POP     ES
FILE_OK:
        MOV     AL,2    ;read/write mode
        MOV     CS:FHB_SYSTEM_CALL,1
        CALL    OPEN_FILE
        MOV     CS:FHB_SYSTEM_CALL,0
        JMP     Short CREATE_END_RW
        ;-----------------------------------
ADD_NEW_FILE:
        POP     DI
        POP     ES
        PUSH    DS
        PUSH    CS
        POP     DS
        XOR     AX,AX
        MOV     WORD PTR FHB_DWORD_TEMP[0],AX
        MOV     WORD PTR FHB_DWORD_TEMP[2],AX
        POP     DS
        CALL    ADD_DIR_ENTRY
        JC      ERROR_DIR
        MOV     AL,2    ;read/write mode
        MOV     CS:FHB_SYSTEM_CALL,1
        CALL    OPEN_FILE
        MOV     CS:FHB_SYSTEM_CALL,0
        JMP     Short CREATE_END_RW
        ;-----------------------------------
ERROR_TMOF:
        MOV     AX,ERR_TMOFILES
        STC
        JMP     Short CREATE_DONE
ERROR_AD:
        MOV     AX,ERR_ADENIED
        STC
        JMP     Short CREATE_DONE
ERROR_DIR:
        MOV     AX,ERR_ADENIED
        STC
        JMP     Short CREATE_RETURN
CREATE_DONE:
        POP     DI
        POP     ES
        JMP     Short CREATE_RETURN
CREATE_END_RW:
        ;-----------------------------------
        ;END_RW
        PUSHF
        PUSH    DX
        XOR     DL,DL           ;Only drive A: in this version
        CALL    FAT12_END_RW
        POP     DX
        POPF
        ;-----------------------------------
CREATE_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
CREATE_FILE     ENDP

;***********************************************************************

CREATE_NEW_FILE         PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 5BH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    PREPARE_FILE_PATH
        JC      NEW_F_RETURN
        ;-----------------------------------
        CALL    CHECK_RSVD_HDLS
        JNC     NEW_F_FILE_OK
        ;-----------------------------------
        PUSH    ES
        PUSH    DI
        CALL    FIND_UNUSED_FHB
        JC      ERR_TMOF
        ;-----------------------------------
        ;In this point ES and DI are free to use.
        MOV     DI,DS
        MOV     ES,DX
        PUSH    BX
        XOR     DL,DL           ;Only drive A: in this version
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     BX
        MOV     DX,ES
        MOV     DS,DI
        ;-----------------------------------
        MOV     DI,CS
        MOV     ES,DI
        LEA     DI,FHB_DIR_ENT
        CALL    READ_FILE_DIR_ENTRY
        JNC     ERR_F_EXISTS
        CMP     AX,ERR_PNFOUND
        JE      ERR_DONE
        CMP     AX,ERR_ADENIED
        JE      ERR_DONE
        ;-----------------------------------
        POP     DI
        POP     ES
NEW_F_FILE_OK:
        CALL    CREATE_FILE
        JMP     Short NEW_F_RETURN
        ;-----------------------------------
ERR_TMOF:
        MOV     AX,ERR_TMOFILES
        JMP     Short ERR_DONE
ERR_F_EXISTS:
        MOV     AX,ERR_ADENIED
ERR_DONE:
        POP     DI
        POP     ES
        STC
NEW_F_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
CREATE_NEW_FILE         ENDP

;***********************************************************************

BYTE_TO_HEX     PROC
        MOV     AH,AL
        AND     AH,0FH
        PUSH    CX
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
        CMP     CX,0
        MOV     CX,1
        JE      CONV_TO_HEX
        POP     CX
        RET
BYTE_TO_HEX     ENDP

;***********************************************************************

WORD_TO_HEX     PROC
        MOV     CL,AL
        MOV     AL,AH
        CALL    BYTE_TO_HEX
        XCHG    AX,CX
        CALL    BYTE_TO_HEX
        XCHG    AX,CX
        RET
WORD_TO_HEX     ENDP

;***********************************************************************

CREATE_TEMP_FILE        PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 5AH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CLC
        CALL    PREPARE_FILE_PATH
        JC      TMP_F_RETURN
        ;-----------------------------------
        PUSH    DI
        PUSH    DS
        MOV     DI,CS
        MOV     DS,DI
        MOV     FHB_WORD_1,ES
        MOV     FHB_WORD_2,SI
        POP     DS
        PUSH    BX
        PUSH    CX
        ;-----------------------------------
        CALL    FIND_UNUSED_FHB
        JC      TMP_ERR_TMOF
        XOR     SI,SI
        MOV     BX,DX
FIND_Z_POS:
        INC     SI
        CMP     BYTE PTR[BX+SI],0
        JNE     FIND_Z_POS
        ;-----------------------------------
        ;In this point ES and DI are free to use.
        MOV     DI,DS
        MOV     ES,DX
        PUSH    BX
        XOR     DL,DL           ;Only drive A: in this version
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     BX
        MOV     DX,ES
        MOV     DS,DI
        ;-----------------------------------
        PUSH    CS
        POP     ES
        LEA     DI,FHB_DIR_ENT
        ;-----------------------------------
TRY_FIND:
        MOV     AH,2CH
        INT     21H
        MOV     AL,CH
        MOV     CH,CL
        MOV     CL,DH
        CALL    ENCODE_FILE_TIME
        MOV     AX,CX
        CALL    WORD_TO_HEX
        MOV     [BX+SI],AX
        MOV     [BX+SI+2],CX
        MOV     AX,'T.'
        MOV     [BX+SI+4],AX
        MOV     AX,'PM'
        MOV     [BX+SI+6],AX
        MOV     BYTE PTR[BX+SI+8],0
        MOV     DX,BX
        CALL    READ_FILE_DIR_ENTRY
        JNC     TRY_FIND
        ;-----------------------------------
        CMP     AX,ERR_PNFOUND
        JE      TMP_ERR_DONE
        CMP     AX,ERR_ADENIED
        JE      TMP_ERR_DONE
        POP     CX
        MOV     ES,CS:FHB_WORD_1
        MOV     SI,CS:FHB_WORD_2
        POP     BX
        POP     DI
        CALL    CREATE_FILE
        JNC     TMP_F_SUCCESS
        JMP     Short TMP_F_RETURN
        ;-----------------------------------
TMP_ERR_TMOF:
        MOV     AX,ERR_TMOFILES
TMP_ERR_DONE:
        POP     CX
        MOV     ES,CS:FHB_WORD_1
        MOV     SI,CS:FHB_WORD_2
        POP     BX
        POP     DI
        STC
        JMP     Short TMP_F_RETURN
TMP_F_SUCCESS:
        MOV     CS:RFP_MOVE_COUNT,8
TMP_F_RETURN:
        CALL    RESTORE_FILE_PATH
        CALL    UPDATE_EXT_ERROR_INF
        RET
CREATE_TEMP_FILE        ENDP

;***********************************************************************

MOVE_RW_PTR     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 42H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FHB_WORD_1,ES
        MOV     FHB_WORD_2,DI
        MOV     FHB_WORD_3,BX
        MOV     FHB_WORD_4,CX
        MOV     FHB_WORD_5,DX
        POP     DS
        ;-----------------------------------
        CALL    FIND_FHB
        JC      ERR_IHDL
        CMP     ES:BYTE PTR[DI+22],0
        JE      FHB_OK
        CALL    FIND_TARGET_FHB
        JC      ERR_IHDL
FHB_OK:
        MOV     AH,ES:[DI+24]
        CMP     AH,05H
        JAE     NORMAL_FILE_PTR
        CMP     AH,00H
        JE      STD_IN_PTR
        CMP     AH,01H
        JE      STD_OUT_PTR
        CMP     AH,02H
        JE      STD_ERR_PTR
        CMP     AH,03H
        JE      STD_AUX_PTR
        ;-----------------------------------
        ;So Std Printer PTR
        ;DO nothing and only return with seek error
        JMP     ERR_SEEK
        ;-----------------------------------
STD_IN_PTR:
        ;So Std In PTR
        ;DO nothing and only return with seek error
        JMP     ERR_SEEK
        ;-----------------------------------
STD_OUT_PTR:
        ;So Std Out PTR
        ;DO nothing and only return with seek error
        JMP     ERR_SEEK
        ;-----------------------------------
STD_ERR_PTR:
        ;So Std Out PTR
        ;DO nothing and only return with seek error
        JMP     ERR_SEEK
        ;-----------------------------------
STD_AUX_PTR:
        ;So Std AUX PTR
        ;DO nothing and only return with seek error
        JMP     ERR_SEEK
        ;-----------------------------------
NORMAL_FILE_PTR:
        CMP     AL,0
        JE      START_OF_FILE
        CMP     AL,1
        JE      CURRENT_PTR
        CMP     AL,2
        JE      END_OF_FILE
        JMP     ERR_IFN
        ;-----------------------------------
START_OF_FILE:
        XOR     AX,AX
        XOR     BX,BX
        JMP     Short ADD_OFFSET
CURRENT_PTR:
        MOV     AX,ES:[DI+9]
        MOV     BX,ES:[DI+7]
        JMP     Short ADD_OFFSET
END_OF_FILE:
        MOV     AX,ES:[DI+13]
        MOV     BX,ES:[DI+11]
        ;-----------------------------------
        ;now add CX:DX(offset) to AX:BX
ADD_OFFSET:
        ADD     BX,DX
        ADC     AX,CX
        JC      ERR_SEEK
        ;AX:BX = New PTR
        CMP     ES:[DI+13],AX
        JA      UPDATE_PTR
        JB      UPDATE_F_SIZE
        CMP     ES:[DI+11],BX
        JAE     UPDATE_PTR
        ;-----------------------------------
        ;so update file size
UPDATE_F_SIZE:
        PUSH    AX
        PUSH    BX
        SUB     BX,ES:[DI+11]
        SBB     AX,ES:[DI+13]
        MOV     CX,AX
        MOV     DX,BX
        ;CX:DX = number of bytes to append
        MOV     BX,ES:[DI+11]
        MOV     AX,ES:[DI+13]
        ;AX:BX = File size in bytes
        ;Divide AX:BX by 512
        PUSH    SI
        PUSH    DX
        PUSH    CX
        MOV     CX,9    ;512 = 2^9
        XOR     DX,DX
DIV_BY_512:
        SHR     AX,1
        RCR     BX,1
        RCR     DX,1
        LOOP    DIV_BY_512
        MOV     CX,7
        SHR     DX,CL
        POP     CX
        ;DX = number of bytes used in last sector
        CMP     DX,0
        JE      ADJ_SECTOR
        ADD     BX,1
        ADC     AX,0
        MOV     SI,512
        SUB     SI,DX
        MOV     DX,SI
ADJ_SECTOR:
        POP     SI
        XCHG    SI,DX
        SUB     DX,SI
        SBB     CX,0
        POP     SI
        ;CX:DX = exact number of bytes to append
        ;AX:BX = number of sectors used by file
        ;-----------------------------------
        PUSH    DX
        MOV     DX,AX
        MOV     AX,BX
        MOV     BL,ES:[DI+21]
        XOR     BH,BH
        DIV     BX      ;AX=quotient,DX=remainder
        XOR     BL,BL
        CMP     DX,0
        JE      SEC_IN_CLUS_OK
        MOV     BL,ES:[DI+21]
        SUB     BX,DX
SEC_IN_CLUS_OK:
        POP     DX
        ;BX = number of sectors available in last cluster
        ;-----------------------------------
        ;Divide CX:DX by 512 to get the number of sectors to append
        PUSH    BX
        MOV     AX,CX   ;AX:DX
        ;AX:DX/512
        MOV     CX,9    ;512 = 2^9
        XOR     BX,BX
DIV_IT:
        SHR     AX,1
        RCR     DX,1
        RCR     BX,1
        LOOP    DIV_IT
        MOV     CX,7
        SHR     BX,CL
        CMP     BX,0
        JE      SEC_CNT_OK
        ADD     DX,1
        ADC     AX,0
SEC_CNT_OK:
        MOV     CX,AX   ;CX:DX
        POP     BX
        SUB     DX,BX
        SBB     CX,0
        ;CX:DX = exact number of sectors to append
        ;-----------------------------------
        ;Calculate the number of clusters to append
        MOV     BL,ES:[DI+21]
        XOR     BH,BH
        XCHG    CX,DX   ;DX:CX
        MOV     AX,CX   ;DX:AX
        DIV     BX
        CMP     DX,0
        JE      CLUS_CNT_OK
        ADD     AX,1
CLUS_CNT_OK:
        MOV     CX,AX
        ;CX = number of clusters to append
        ;-----------------------------------
        ;       *In This Point*                 ;
        ;AX,BX and DX are free to use
        ;CX = number of clusters to append
        ;ES:DI = pointer to FHB
        ;       ***************                 ;
        PUSH    DS
        MOV     AX,ES
        MOV     DS,AX
        MOV     DX,DI
        ADD     DX,39
        CALL    EXTRACT_DRIVE_NO
        ;-----------------------------------
        ;In this point DS is free to use.
        ;DL = Drive number(0..n)
        PUSH    BX
        PUSH    CS
        POP     DS
        LEA     BX,DISK_SEC_TEMP
        CALL    FAT12_START_RW
        POP     BX
        ;-----------------------------------
        POP     DS
        MOV     AX,ES:[DI+19]
        ;AX = First cluster number
        ;DL = Drive number(0..n)
        ;Now,append clusters to file
APPEND_CLUS:
        CALL    APPEND_CLUSTER
        JC      END_APPEND
        LOOP    APPEND_CLUS
END_APPEND:
        OR      CX,CX
        JZ      APP_NO_ERR
        ;-----------------------------------
        ;So there was an error
        ;The code that goes here is not the main and correct code
        MOV     AL,ES:[DI+21]
        XOR     AH,AH
        MUL     CX
        MOV     CX,9    ;512 = 2^9
MUL_BY_512:
        SHL     AX,1
        RCL     DX,1
        LOOP    MUL_BY_512
        ;DX:AX
        MOV     CX,AX
        ;DX:CX
        POP     BX
        POP     AX
        SUB     BX,CX
        SBB     AX,DX
        JMP     Short APP_DONE
        ;-----------------------------------
APP_NO_ERR:
        POP     BX
        POP     AX
        ;-----------------------------------
APP_DONE:
        ;now,only should update file size in directory entry
        MOV     ES:[DI+11],BX
        MOV     ES:[DI+13],AX
        OR      ES:BYTE PTR[DI+27],01H
        ;-----------------------------------
        MOV     CX,AX
        PUSH    SI
        PUSH    DS
        PUSH    ES
        POP     DS
        PUSH    ES
        MOV     DX,DI
        ADD     DX,39
        MOV     AX,CS
        MOV     ES,AX
        LEA     DI,DIR_ENT_TEMP
        CALL    READ_FILE_DIR_ENTRY
        PUSH    ES
        POP     DS
        MOV     SI,DI
        SUB     DX,39
        MOV     DI,DX
        POP     ES
        MOV     [SI+28],BX
        MOV     [SI+30],CX
        CALL    FAT12_WRITE_DIR_ENTRY
        POP     DS
        POP     SI
        MOV     AX,CX
        ;-----------------------------------
UPDATE_PTR:
        MOV     ES:[DI+7],BX
        MOV     ES:[DI+9],AX
        MOV     DX,AX
        MOV     AX,BX
        ;now,update all related FHBs
        MOV     CX,DS   ;store DS in CX
        PUSH    DX
        PUSH    AX
        PUSH    SI
        MOV     BX,ES:[DI+1]
        PUSH    ES
        POP     DS
        MOV     SI,DI
        ADD     SI,7
        MOV     AX,1
UPDATE_REL_FHBS:
        CALL    FIND_REDIRECTED_FHB
        JC      UPDATE_REL_DONE
        ADD     DI,7
        CLD
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        SUB     SI,8
        SUB     DI,15
        INC     AX
        CMP     ES:BYTE PTR[DI+23],0
        JE      UPDATE_REL_FHBS
        CALL    INCALL_UPDATE_FHBS
        JMP     Short UPDATE_REL_FHBS
UPDATE_REL_DONE:
        POP     SI
        POP     AX
        POP     DX
        MOV     DS,CX   ;restore DS from CX
        CLC
        JMP     Short MP_DONE
        ;-----------------------------------
ERR_IHDL:
        MOV     AX,ERR_IHANDLE
        JMP     Short MP_E_DONE
ERR_IFN:
        MOV     AX,ERR_IFNUMBER
        JMP     Short MP_E_DONE
ERR_SEEK:
        MOV     AX,ERR_SERROR
        ;-----------------------------------
MP_E_DONE:
        MOV     DX,CS:FHB_WORD_5
        STC
MP_DONE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     ES,FHB_WORD_1
        MOV     DI,FHB_WORD_2
        MOV     BX,FHB_WORD_3
        MOV     CX,FHB_WORD_4
        POP     DS
        CALL    UPDATE_EXT_ERROR_INF
        RET
MOVE_RW_PTR     ENDP

;***********************************************************************

GET_SET_FILE_DT         PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 57H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CMP     AL,1
        JA      ERR_INVFNO
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     FHB_WORD_1,ES
        MOV     FHB_WORD_2,DI
        MOV     FHB_WORD_3,BX
        MOV     FHB_WORD_4,SI
        POP     DS
        ;-----------------------------------
        CALL    FIND_FHB
        JC      ERR_INVHANDLE
        MOV     BL,AL
        AND     BL,01H
        NOT     BL
        AND     ES:[DI+27],BL
        PUSH    DS
        PUSH    ES
        POP     DS
        PUSH    AX
        MOV     BX,DX   ;store DX in BX
        MOV     DX,DI
        ADD     DX,39
        MOV     SI,CS
        MOV     ES,SI
        LEA     DI,DIR_ENT_TEMP
        CALL    READ_FILE_DIR_ENTRY
        JC      ERR_DIR_NF
        MOV     SI,DI
        PUSH    CS
        POP     DS
        MOV     DX,BX   ;restore DX from BX
        MOV     BX,AX
        POP     AX
        ;-----------------------------------
        ;BX = File directory entry number
        ;DS:SI = Pointer to the beginning of the entry in memory
        CMP     AL,1
        JE      SET_F_DT
        ;Get file date and time(AL=0)
        MOV     CX,[SI+22]
        MOV     DX,[SI+24]
        JMP     Short DT_OK
SET_F_DT:
        MOV     [SI+22],CX
        MOV     [SI+24],DX
        XCHG    AX,BX
        CALL    FAT12_WRITE_DIR_ENTRY
        MOV     AX,BX
DT_OK:
        POP     DS
        CLC
        JMP     Short DT_DONE
        ;-----------------------------------
ERR_INVFNO:
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short DT_RETURN
ERR_INVHANDLE:
        MOV     AX,ERR_IHANDLE
        JMP     Short DT_ERR_DONE
ERR_DIR_NF:
        POP     AX
        POP     DS
        MOV     AX,ERR_FNFOUND
DT_ERR_DONE:
        STC
        ;-----------------------------------
DT_DONE:
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     ES,FHB_WORD_1
        MOV     DI,FHB_WORD_2
        MOV     BX,FHB_WORD_3
        MOV     SI,FHB_WORD_4
        POP     DS
DT_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
GET_SET_FILE_DT         ENDP

;***********************************************************************

GET_TICK_COUNT  PROC
;-------------------------------------------
;INPUT:         NONE
;OUTPUT:        CX:DX = Current clock tick count
;-------------------------------------------
        PUSH    AX
        MOV     AH,00H
        INT     1AH     ;Read the clock tick count
        POP     AX
        RET
GET_TICK_COUNT  ENDP

;***********************************************************************

BIOS_ERR_TO_DEV_ERR     PROC
;INPUT:  AH=BIOS disk error code as returned from INT 13H
;OUTPUT: AL=Equivalent device driver error code
        CMP     AH,03H          ;attempt to write on write protected disk
        JE      DEV_ERR_00H
        CMP     AH,04H          ;sector not found
        JE      DEV_ERR_08H
        CMP     AH,06H          ;diskette change line is active(diskette changed or removed)
        JE      DEV_ERR_0FH
        CMP     AH,10H          ;ECC/CRC error
        JE      DEV_ERR_04H
        CMP     AH,40H          ;Seek failure
        JE      DEV_ERR_06H
        ;Any other errors are considered as Drive Not Ready error
        MOV     AL,02H          ;Drive not ready
        JMP     Short DEV_ERR_DONE
DEV_ERR_00H:
        MOV     AL,00H          ;Attempt to write on write protected disk
        JMP     Short DEV_ERR_DONE
DEV_ERR_04H:
        MOV     AL,04H          ;CRC error
        JMP     Short DEV_ERR_DONE
DEV_ERR_06H:
        MOV     AL,06H          ;Seek error
        JMP     Short DEV_ERR_DONE
DEV_ERR_08H:
        MOV     AL,08H          ;Sector not found
        JMP     Short DEV_ERR_DONE
DEV_ERR_0FH:
        MOV     AL,0FH          ;Invalid disk change
DEV_ERR_DONE:
        RET
BIOS_ERR_TO_DEV_ERR     ENDP

;***********************************************************************
RETURN_STACK_POINTER            DW              ?
RETURN_ADDRESS                  DD              ?
DISK_OPERATION_TYPE             DB              ?       ;0=Read , 1=Write
;#####
ENTRY_REGISTER_VALUES           LABEL           BYTE
        ENTRY_FLAGS             DW              ?
        ENTRY_ES                DW              ?
        ENTRY_DS                DW              ?
        ENTRY_BP                DW              ?
        ENTRY_DI                DW              ?
        ENTRY_SI                DW              ?
        ENTRY_DX                DW              ?
        ENTRY_CX                DW              ?
        ENTRY_BX                DW              ?
        ENTRY_AX                DW              ?
;#####
BLOCK_DEVICE_HEADER             LABEL           BYTE
                DW              -1,-1
                DW              0000000000000000b
                DW              OFFSET NUL_STRATINT
                DW              OFFSET NUL_STRATINT
                DB              1,7 DUP(00H)

HANDLE_CRITICAL_ERROR   PROC
;INPUT: AX=BIOS disk error code as returned from INT 13H
        PUSHF
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    BP
        PUSH    DS
        PUSH    ES
        PUSH    CS
        POP     DS
        ;-----------------------------------
        ;If error is occured in the loading stage, display an error message and retry after a key press.
        CMP     LOADING_STAGE,0
        JE      HCE_CONTINUE
        LEA     SI,LOADING_DISK_ERROR_MSG
        CLD
        MOV     AH,0EH
HCE_WRT_MSG:
        LODSB
        CMP     AL,00H
        JE      HCE_MSG_DONE
        INT     10H
        JMP     Short HCE_WRT_MSG
HCE_MSG_DONE:
        MOV     AH,00H
        INT     16H
        JMP     HCE_RETRY
HCE_CONTINUE:
        ;-----------------------------------
        CALL    BIOS_ERR_TO_DEV_ERR
        XOR     AH,AH
        MOV     DI,AX
        ADD     AL,19           ;Convert device driver error code to extended error code
        STC
        CALL    UPDATE_EXT_ERROR_INF
        LEA     SI,ENTRY_REGISTER_VALUES
        CLD
        LODSW
        PUSH    AX
        PUSH    WORD PTR RETURN_ADDRESS[2]
        PUSH    WORD PTR RETURN_ADDRESS[0]
        MOV     CX,9
PUSH_APP_REGISTERS:
        LODSW
        PUSH    AX
        LOOP    PUSH_APP_REGISTERS
        ;-----------------------------------
        ;DI=Device driver error code
        MOV     BP,CS
        LEA     SI,BLOCK_DEVICE_HEADER
        MOV     AL,0            ;Drive A:
        MOV     AH,00011110b
        OR      AH,DISK_OPERATION_TYPE

        ;-----------------------------------
        ;Check for INT 25H/26H(if active must not invoke INT 24H)
        CMP     INT_25H_26H_ACTIVE,0
        JE      INVOKE_CRITICAL_ERROR_HANDLER
        XOR     AL,AL           ;Only drive A: in this version
        CALL    DSKBUF_RESET_BUFFERS
        CALL    END_DISKETTE_IO
        MOV     CS:RLS_DSKBUF_VALID,0
        MOV     CS:FILE_PATH_FLAG,0
        MOV     CS:WORD PTR FAT12_SRW_CLKTICK[0],0
        MOV     CS:WORD PTR FAT12_SRW_CLKTICK[2],0
        MOV     AX,DI
        MOV     AH,80H
        MOV     SP,INT_25H_26H_STACK_POINTER
        POP     ES
        POP     DS
        POP     BP
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        INC     SP
        INC     SP
        ;AX=INT 25H/26H error code
        STC
        MOV     INT_25H_26H_ACTIVE,0
        RETF
        ;-----------------------------------
INVOKE_CRITICAL_ERROR_HANDLER:
        INT     24H
        OR      AL,AL
        JZ      FAIL_24H
        CMP     AL,01H
        JE      RETRY_24H
        CMP     AL,03H
        JE      FAIL_24H
        ;Abort
        XOR     AL,AL           ;Only drive A: in this version
        CALL    DSKBUF_RESET_BUFFERS
        MOV     CS:RLS_DSKBUF_VALID,0
        MOV     CS:FILE_PATH_FLAG,0
        CALL    END_DISKETTE_IO
        MOV     AX,4C02H
        INT     21H
FAIL_24H:
        ;Restore application registers
        POP     AX
        POP     BX
        POP     CX
        POP     DX
        POP     SI
        POP     DI
        POP     BP
        POP     DS
        POP     ES
        POPF
        CLI
        MOV     SP,CS:RETURN_STACK_POINTER
        STI
        XOR     AL,AL           ;Only drive A: in this version
        CALL    DSKBUF_RESET_BUFFERS
        MOV     CS:RLS_DSKBUF_VALID,0
        MOV     CS:FILE_PATH_FLAG,0
        CALL    END_DISKETTE_IO
        MOV     AX,53H          ;Error: Fail on INT 24H
        STC
        RETF                    ;Return to the application
RETRY_24H:
        ADD     SP,24
HCE_RETRY:
        POP     ES
        POP     DS
        POP     BP
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        POPF
        RET
HANDLE_CRITICAL_ERROR   ENDP

;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================
;=======================================================================


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        MINIIO_DISP_JUMP        DD              ?

        INT21H_TABLE            LABEL           BYTE
        ;DB     INT 21H Service No.
        ;DD     FAR pointer to routine

        DB      0EH
                     DD      OFFSET SET_DEFAULT_DRIVE
        DB      19H
                     DD      OFFSET GET_DEFAULT_DRIVE
        DB      1AH
                     DD      OFFSET SET_DTA_ADDRESS
        DB      1BH
                     DD      OFFSET GET_DEFAULT_FAT_INF
        DB      1CH
                     DD      OFFSET GET_FAT_INF
        DB      2FH
                     DD      OFFSET GET_DTA_ADDRESS
        DB      36H
                     DD      OFFSET GET_DRIVE_SPEC
        DB      3BH
                     DD      OFFSET CHANGE_DEFAULT_DIR
        DB      3CH
                     DD      OFFSET CREATE_FILE
        DB      3DH
                     DD      OFFSET OPEN_FILE
        DB      3EH
                     DD      OFFSET CLOSE_FILE
        DB      3FH
                     DD      OFFSET READ_FILE
        DB      40H
                     DD      OFFSET WRITE_FILE
        DB      41H
                     DD      OFFSET DELETE_FILE
        DB      42H
                     DD      OFFSET MOVE_RW_PTR
        DB      43H
                     DD      OFFSET GET_SET_FILE_ATTR
        DB      45H
                     DD      OFFSET DUPLICATE_FHB
        DB      46H
                     DD      OFFSET REDIRECT_FHB
        DB      47H
                     DD      OFFSET GET_DRIVE_DEFAULT_DIR
        DB      4EH
                     DD      OFFSET FIND_FIRST_FILE
        DB      4FH
                     DD      OFFSET FIND_NEXT_FILE
        DB      52H
                     DD      OFFSET GET_DOS_VARS
        DB      56H
                     DD      OFFSET RENAME_FILE
        DB      57H
                     DD      OFFSET GET_SET_FILE_DT
        DB      5AH
                     DD      OFFSET CREATE_TEMP_FILE
        DB      5BH
                     DD      OFFSET CREATE_NEW_FILE
        DB      60H
                     DD      OFFSET BUILD_FULL_PATH
        ;-----------------------------------
        DB      0DH
                     DD      OFFSET RESET_DISK
        DB      2EH
                     DD      OFFSET SET_VERIFY_SWITCH
        DB      54H
                     DD      OFFSET GET_VERIFY_SWITCH
        DB      68H
                     DD      OFFSET COMMIT_FILE
        ;-----------------------------------
        DB      44H
                     DD      OFFSET SS_44H
        DB      5CH
                     DD      OFFSET SS_5CH
        DB      5EH
                     DD      OFFSET SS_5EH
        ;DB      5FH: Netword Device Redirection
                     ;Autoreturn with ERR_IFNUMBER
        ;-----------------------------------
        DB      67H
                     DD      OFFSET SS_67H
        ;-----------------------------------
        DB      39H
                     DD      OFFSET SS_39H_3AH
        DB      3AH
                     DD      OFFSET SS_39H_3AH
        ;-----------------------------------
        DB      1FH
                     DD      OFFSET GET_CURRENT_DRIVE_DPB
        DB      32H
                     DD      OFFSET GET_DRIVE_DPB
        ;-----------------------------------
        DB      29H
                     DD      OFFSET PARSE_FILENAME
        ;-----------------------------------
        DB      24H
                     DD      OFFSET SS_24H
        ;-----------------------------------
        DB      0FH
                     DD      OFFSET SS_FCB_SERVICES_1
        DB      10H
                     DD      OFFSET SS_FCB_SERVICES_1
        DB      11H
                     DD      OFFSET SS_FCB_SERVICES_1
        DB      12H
                     DD      OFFSET SS_FCB_SERVICES_1
        DB      13H
                     DD      OFFSET SS_FCB_SERVICES_1
        DB      16H
                     DD      OFFSET SS_FCB_SERVICES_1
        DB      17H
                     DD      OFFSET SS_FCB_SERVICES_1
        DB      23H
                     DD      OFFSET SS_FCB_SERVICES_1
        ;-----------------------------------
        DB      14H
                     DD      OFFSET SS_FCB_SERVICES_2
        DB      15H
                     DD      OFFSET SS_FCB_SERVICES_2
        DB      21H
                     DD      OFFSET SS_FCB_SERVICES_2
        DB      22H
                     DD      OFFSET SS_FCB_SERVICES_2
        DB      27H
                     DD      OFFSET SS_FCB_SERVICES_2
        DB      28H
                     DD      OFFSET SS_FCB_SERVICES_2
        ;-----------------------------------
        DB      1DH
                     DD      OFFSET MINIIO_INTERFACE
        ;-----------------------------------
        DB      0FFH            ;END OF TABLE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MINIIO_DISPATCHER       PROC      FAR
;-----------------------------------------------------------------------;
; <MiniIO.SYS Service Dispatcher for INT 21H Services>                  ;
;-----------------------------------------------------------------------;
        ;STACK: Return CS,Return IP
        MOV     CS:RETURN_STACK_POINTER,SP
        POP     CS:WORD PTR RETURN_ADDRESS[0]
        POP     CS:WORD PTR RETURN_ADDRESS[2]
        PUSH    CS:WORD PTR RETURN_ADDRESS[2]
        PUSH    CS:WORD PTR RETURN_ADDRESS[0]
        PUSHF
        POP     CS:ENTRY_FLAGS
        MOV     CS:ENTRY_ES,ES
        MOV     CS:ENTRY_DS,DS
        MOV     CS:ENTRY_BP,BP
        MOV     CS:ENTRY_DI,DI
        MOV     CS:ENTRY_SI,SI
        MOV     CS:ENTRY_DX,DX
        MOV     CS:ENTRY_CX,CX
        MOV     CS:ENTRY_BX,BX
        MOV     CS:ENTRY_AX,AX
        PUSHF
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,INT21H_TABLE
SEARCH_SERVICE:
        CMP     BYTE PTR[SI],0FFH
        JE      INVALID_SERVICE
        CMP     BYTE PTR[SI],AH
        JE      FOUND_SERVICE
        ADD     SI,5
        JMP     Short SEARCH_SERVICE
FOUND_SERVICE:
        PUSH    AX
        MOV     AX,[SI+1]
        MOV     WORD PTR MINIIO_DISP_JUMP[0],AX
        MOV     AX,[SI+3]
        MOV     WORD PTR MINIIO_DISP_JUMP[2],AX
        POP     AX
        POP     SI
        POP     DS
        POPF
        JMP     CS:MINIIO_DISP_JUMP
INVALID_SERVICE:
        POP     SI
        POP     DS
        POPF
        MOV     AX,1    ;Error: Invalid function number
        STC
        RETF
MINIIO_DISPATCHER       ENDP

;***********************************************************************

MINIIO_INTERFACE        PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 1DH> | <Internal Service>                            ;
;-----------------------------------------------------------------------;
        ;INT 21H,Func. 1DH
        ;Interface Table:
        ;AL=00H: FIND_FHB_WITH_OWNER
        ;AL=01H: PREPARE_FILE_PATH
        ;AL=02H: RESTORE_FILE_PATH

        OR      AL,AL
        JZ      INTERFACE_00H
        CMP     AL,01H
        JE      INTERFACE_01H
        CMP     AL,02H
        JE      INTERFACE_02H
        ;Invalid Function Number
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short MI_RETURN
INTERFACE_00H:
        CALL    FIND_FHB_WITH_OWNER
        JMP     Short MI_RETURN
INTERFACE_01H:
        CALL    PREPARE_FILE_PATH
        JMP     Short MI_RETURN
INTERFACE_02H:
        CALL    RESTORE_FILE_PATH
MI_RETURN:
        RET
MINIIO_INTERFACE        ENDP

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++MTF00012.ASM++++++++++++++++++++++++++++

VERIFY_SWITCH           DB              00H             ;00H=Verify Off
                                                        ;01H=Verify On

;***********************************************************************

RESET_DISK      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 0DH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        PUSH    DX
        XOR     DL,DL   ;Only drive A: in this version
        CALL    FAT12_END_RW
        POP     DX
        RET
RESET_DISK      ENDP

;***********************************************************************

SET_VERIFY_SWITCH       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 2EH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        CMP     AL,01H
        JA      SVS_RETURN
        MOV     CS:VERIFY_SWITCH,AL
SVS_RETURN:
        RET
SET_VERIFY_SWITCH       ENDP

;***********************************************************************

GET_VERIFY_SWITCH       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 54H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     AL,CS:VERIFY_SWITCH
        RET
GET_VERIFY_SWITCH       ENDP

;***********************************************************************

COMMIT_FILE     PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 68H> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        ;Only for this version;
        PUSH    DX
        XOR     DL,DL   ;Only drive A: in this version
        CALL    FAT12_END_RW
        POP     DX
        ;Return with no error.
        CLC
        RET
COMMIT_FILE     ENDP

;***********************************************************************

GET_DTA_ADDRESS PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 2FH> | <API Service>                                 ;
;-----------------------------------------------------------------------;
        MOV     ES,CS:DTA_SEGMENT
        MOV     BX,CS:DTA_OFFSET
        RET
GET_DTA_ADDRESS ENDP

;***********************************************************************

UPDATE_EXT_ERROR_INF    PROC
        PUSH    AX
        PUSH    BX
        MOV     BX,AX
        MOV     AX,0600H
        INT     32H
        ;Flags are not affected by this function
        POP     BX
        POP     AX
        RET
UPDATE_EXT_ERROR_INF    ENDP

;***********************************************************************

INT_24H_DEFAULT_HANDLER PROC
;-----------------------------------------------------------------------;
; <INT 24H (Critical Error) Handler> | <Default INT 24H Handler>        ;
;-----------------------------------------------------------------------;
        MOV     AL,03H          ;Fail
        IRET
INT_24H_DEFAULT_HANDLER ENDP

;***********************************************************************

;This PROC is used for the following interrupt vectors:
;       21H,32H
IRET_INTERRUPT_HANDLER  PROC
        IRET
IRET_INTERRUPT_HANDLER  ENDP

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++SERVICE SUPPORT+++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
CON_DEV_ATTR            DW              1000000010000011b
AUX_DEV_ATTR            DW              1000000011000000b
PRN_DEV_ATTR            DW              1000000011000000b

SS_44H  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 44H> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;IOCTL
        OR      AL,AL
        JZ      IOCTL_QUERY_DEVICE_ATTR
        CMP     AL,01H
        JE      IOCTL_SET_DEVICE_ATTR
        CMP     AL,05H
        JBE     IOCTL_SUBFUNC_02H_TO_05H
        CMP     AL,06H
        JE      IOCTL_QUERY_INPUT_STATUS
        CMP     AL,07H
        JE      IOCTL_QUERY_OUTPUT_STATUS
        CMP     AL,08H
        JE      IOCTL_REMOVABLE_MEDIA
        CMP     AL,09H
        JE      IOCTL_REMOTE_DRIVE
        CMP     AL,0AH
        JE      IOCTL_REMOTR_HANDLE
        CMP     AL,0BH
        JE      IOCTL_SUCCESS
        CMP     AL,0EH
        JE      IOCTL_QUERY_LOGICAL_DRIVE_MAP
        CMP     AL,0FH
        JE      IOCTL_SET_LOGICAL_DRIVE_MAP
        MOV     AX,ERR_IFNUMBER
        JMP     IOCTL_FAILURE
IOCTL_SUBFUNC_02H_TO_05H:
        XOR     AX,AX
        JMP     IOCTL_SUCCESS
IOCTL_QUERY_INPUT_STATUS:
        OR      BX,BX
        JNZ     QIS_READY
        MOV     AH,0BH
        INT     21H
        XOR     AH,AH
        JMP     IOCTL_SUCCESS
QIS_READY:
        MOV     AX,00FFH
        JMP     IOCTL_SUCCESS
IOCTL_QUERY_OUTPUT_STATUS:
        MOV     AX,00FFH
        JMP     IOCTL_SUCCESS
IOCTL_REMOVABLE_MEDIA:
        CMP     BL,01H
        JA      IOCTL_INVALID_DRIVE
        XOR     AX,AX           ;Medium is changeable
        CLC
        JMP     IOCTL_SUCCESS
IOCTL_REMOTE_DRIVE:
        CMP      BL,1
        JA      IOCTL_INVALID_DRIVE
        XOR     DX,DX           ;Local drive
        JMP     IOCTL_SUCCESS
IOCTL_REMOTR_HANDLE:
        XOR     DX,DX           ;Local handle
        JMP     IOCTL_SUCCESS
IOCTL_QUERY_LOGICAL_DRIVE_MAP:
        CMP     BL,1
        JA      IOCTL_INVALID_DRIVE
        XOR     AL,AL
        JMP     IOCTL_SUCCESS
IOCTL_SET_LOGICAL_DRIVE_MAP:
        CMP     BL,1
        JA      IOCTL_INVALID_DRIVE
        XOR     AL,AL
        JMP     IOCTL_SUCCESS
        ;-----------------------------------
IOCTL_QUERY_DEVICE_ATTR:
        PUSH    ES
        PUSH    DI
        CALL    FIND_FHB
        JC      IOCTL_INVALID_HANDLE
        PUSH    CX
        MOV     CL,ES:[DI+24]
        OR      CL,CL
        JZ      IOCTL_STDIN
        CMP     CL,01H
        JE      IOCTL_STDOUT
        CMP     CL,02H
        JE      IOCTL_STDERR
        CMP     CL,03H
        JE      IOCTL_AUX
        CMP     CL,04H
        JE      IOCTL_PRN
        ;So this handle is an opened file on the disk.
        MOV     DX,0000000001000000b
        JMP     Short IOCTL_00H_DONE
IOCTL_INVALID_HANDLE:
        POP     DI
        POP     ES
        MOV     AX,ERR_IHANDLE
        JMP     Short IOCTL_FAILURE
IOCTL_00H_DONE:
        POP     CX
        POP     DI
        POP     ES
        JMP     Short IOCTL_SUCCESS
IOCTL_STDIN:
IOCTL_STDOUT:
IOCTL_STDERR:
        MOV     DX,CS:CON_DEV_ATTR
        JMP     Short IOCTL_00H_DONE
IOCTL_AUX:
        MOV     DX,CS:AUX_DEV_ATTR
        JMP     Short IOCTL_00H_DONE
IOCTL_PRN:
        MOV     DX,CS:PRN_DEV_ATTR
        JMP     Short IOCTL_00H_DONE
        ;-----------------------------------
IOCTL_SET_DEVICE_ATTR:
        CMP     DH,00H
        JE      VALID_DEV_ATTR
        MOV     AX,ERR_ADENIED
        JMP     Short IOCTL_FAILURE
VALID_DEV_ATTR:
        PUSH    ES
        PUSH    DI
        CALL    FIND_FHB
        JC      IOCTL_INVALID_HANDLE
        PUSH    CX
        MOV     CL,ES:[DI+24]
        OR      CL,CL
        JZ      IOCTL_SET_STDIN
        CMP     CL,01H
        JE      IOCTL_SET_STDOUT
        CMP     CL,02H
        JE      IOCTL_SET_STDERR
        CMP     CL,03H
        JE      IOCTL_SET_AUX
        CMP     CL,04H
        JE      IOCTL_SET_PRN
        ;So this handle is an opened file on the disk.
        JMP     Short IOCTL_00H_DONE
IOCTL_SET_STDIN:
IOCTL_SET_STDOUT:
IOCTL_SET_STDERR:
        MOV     CS:BYTE PTR CON_DEV_ATTR[0],DL
        JMP     Short IOCTL_00H_DONE
IOCTL_SET_AUX:
        MOV     CS:BYTE PTR AUX_DEV_ATTR[0],DL
        JMP     Short IOCTL_00H_DONE
IOCTL_SET_PRN:
        MOV     CS:BYTE PTR PRN_DEV_ATTR[0],DL
        JMP     Short IOCTL_00H_DONE
        ;-----------------------------------
IOCTL_SUCCESS:
        CLC
        JMP     Short IOCTL_RETURN
IOCTL_INVALID_DRIVE:
        MOV     AX,ERR_IDSPECIFIED
IOCTL_FAILURE:
        STC
IOCTL_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
SS_44H  ENDP

;*******************************************

SS_5CH  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 5CH> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;5C00H: Lock File Section
        ;5C01H: Unlock File Section
        CMP     AL,01H
        JA      SS_5CH_FAILURE
        CLC                     ;Return with no error
        JMP     Short SS_5CH_RETURN
SS_5CH_FAILURE:
        MOV     AX,ERR_IFNUMBER
        STC
SS_5CH_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
SS_5CH  ENDP

;*******************************************
MACHINE_NAME    DB      'MiniTAK_OS',00H

SS_5EH  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 5EH> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;5E00H: Get Machine Name
        ;5E02H: Set Printer Setup
        ;5E03H: Get Printer Setup
        OR      AL,AL
        JZ      GET_MACHINE_NAME
        MOV     AX,ERR_IFNUMBER
        STC
        JMP     Short SS_5EH_RETURN
GET_MACHINE_NAME:
        ;DS:DX=Output buffer address
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    SI
        PUSH    DI
        MOV     CX,11
        LEA     SI,MACHINE_NAME
        MOV     DI,DX
  REP   MOVSB
        POP     SI
        POP     DI
        POP     DS
        POP     ES
        MOV     CX,0FF00H
        CLC
SS_5EH_RETURN:
        CALL    UPDATE_EXT_ERROR_INF
        RET
SS_5EH  ENDP

;*******************************************

SS_67H  PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 67H> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;67H: Set Maximum Number Of File Handles
        MOV     AX,8            ;Error: Insufficient Memory
        STC
        CALL    UPDATE_EXT_ERROR_INF
        RET
SS_67H  ENDP

;*******************************************

SS_39H_3AH      PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 39H> | <API Service>                                 ;
; <INT 21H Service 3AH> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;39H: Create Subdirectory
        ;3AH: Delete Subdirectory
        MOV     AX,3            ;Error: Path Not Found
        STC
        CALL    UPDATE_EXT_ERROR_INF
        RET
SS_39H_3AH      ENDP

;*******************************************

GET_CURRENT_DRIVE_DPB   PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 1FH> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;Current disk is always A: in this version
        PUSH    CS
        POP     DS
        LEA     BX,DPB
        MOV     AL,00H          ;No error
        RET
GET_CURRENT_DRIVE_DPB   ENDP

;*******************************************

GET_DRIVE_DPB   PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 32H> | <API Service>                                 ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        CMP     DL,1                    ;Only drive A: is valid in this version
        JA      GET_DPB_INVALID_DRIVE
        PUSH    CS
        POP     DS
        LEA     BX,DPB
        MOV     AL,00H          ;No error
        JMP     Short GET_DPB_RETURN
GET_DPB_INVALID_DRIVE:
        MOV     AL,0FFH         ;Error: Invalid drive ID
GET_DPB_RETURN:
        RET
GET_DRIVE_DPB   ENDP

;*******************************************

SS_24H  PROC    FAR
;-----------------------------------------------------------------------;
; <INT 21H Service 24H (FCB Compatibility Service)> | <API Service>     ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;24H: Set Random File Block Address(for FCB)
        RET
SS_24H  ENDP

;*******************************************

SS_FCB_SERVICES_1       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H FCB Compatibility Services> | <API Service>                  ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;0FH: Open FCB
        ;10H: Close FCB
        ;11H: Find 1st Matching File Via FCB
        ;12H: Find Next Matching File Via FCB
        ;13H: Delete File Via FCB
        ;16H: Create File Via FCB
        ;17H: Rename File Via FCB
        ;23H: Get File Size Via FCB
        ;Return with error.
        MOV     AL,0FFH
        RET
SS_FCB_SERVICES_1       ENDP

;*******************************************

SS_FCB_SERVICES_2       PROC      FAR
;-----------------------------------------------------------------------;
; <INT 21H FCB Compatibility Services> | <API Service>                  ;
;INFO: In this version only provides compatibility for programs.        ;
;-----------------------------------------------------------------------;
        ;14H: Read Sequential File Via FCB
        ;15H: Write Sequential File Via FCB
        ;: Read Random File Record(for FCB)
        ;22H: Write Random File Record(for FCB)
        ;27H: Read Random File Block(for FCB)
        ;28H: Write Random File Block(for FCB)
        ;Return with error.
        MOV     AL,01H
        RET
SS_FCB_SERVICES_2       ENDP

;*******************************************

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;

MINIIO_SEG              EQU             0060H
MINIIO_PATH             DB              'A:\MINIIO.SYS',00H
MINIIO_STAGE_2_ADDR     DD              OFFSET MINIIO_INITIALIZER_STAGE_2

LOAD_MINIIO_STAGE_2:
        LEA     DX,MINIIO_PATH
        MOV     AL,00H
        CALL    OPEN_FILE
        MOV     BX,AX
        MOV     AX,0060H
        MOV     WORD PTR MINIIO_STAGE_2_ADDR[2],AX
        MOV     DS,AX
        XOR     DX,DX
        MOV     CX,0FFFFH
        CALL    READ_FILE
        JMP     CS:DWORD PTR MINIIO_STAGE_2_ADDR

LOAD_MINITAK:
        CALL    OPEN_FILE
        JNC     MINITAK_OPEN_DONE
        LEA     DX,MINITAK_ERR_MSG
        CALL    WRITE_ASCIIZ
HALT_ON_LOAD:
        JMP     Short HALT_ON_LOAD
MINITAK_OPEN_DONE:
        MOV     BX,AX
        ;POP     DS              ;POP load segment from the stack
        MOV     DS,BP
        XOR     DX,DX
        ;BX=File Handle
        ;DS:DX=MiniTAK.SYS Load Address
        MOV     CX,0FFF0H
LOAD_MINITAK_2:
        CALL    READ_FILE
        JC      HALT_ON_READ
        OR      AX,AX
        JNZ     LOAD_MINITAK_2
        CALL    CLOSE_FILE
        ;Successful;Set register values for MINITAK.SYS:
        ;       ES:BX => MINIIO.SYS INT 21H Dispatcher
        ;       CX:DX => MINIIO.SYS INT 21H Service Table
        PUSH    CS
        POP     ES
        MOV     CX,ES
        MOV     BX,OFFSET MINIIO_DISPATCHER
        MOV     DX,OFFSET INT21H_TABLE
        ;Jump to MINITAK.SYS first instruction
        MOV     CS:LOADING_STAGE,0
        JMP     CS:LOAD_JUMP
HALT_ON_READ:
        JMP     Short HALT_ON_READ

LOAD_JUMP               DD              ?

WRITE_ASCIIZ    PROC
        PUSH    AX
        PUSH    SI
        MOV     SI,DX
        CLD
        MOV     AH,0EH
WA_LOOP:
        LODSB
        CMP     AL,00H
        JE      WA_DONE
        INT     10H
        JMP     Short WA_LOOP
WA_DONE:
        POP     SI
        POP     AX
        RET
WRITE_ASCIIZ    ENDP

;-------------------------------------------
;INITIALIZER:
        ;Data Defenitions for MINIIO_INITIALIZER

        MINITAK_PATH            DB      'A:\MiniTAK.SYS',00H
        MINITAK_ERR_MSG         DB      10,13,'Unable to find the system file MINITAK.SYS. System halted.',00H
        LOADING_STAGE           DB      1       ;0=Normal
                                                ;1=Loading MINIIO.SYS stage 1
                                                ;2=Loading MINIIO.SYS stage 2
        LOADING_DISK_ERROR_MSG  DB      10,13,'Disk I/O error',10,13,'Replace the disk, and press any key to retry',10,13,00H

MINIIO_INITIALIZER_STAGE_2:
        MOV     CS:LOADING_STAGE,2
MINIIO_INITIALIZER:
        JMP     Short CONTINIUE_INITIALIZATION

        ;***********************************
;#######
        RLS_DISK_BUF            LABEL           BYTE
        RLS_DSKBUF_VALID        DB              0
        RLS_DSKBUF_DRIVE_NO     DB              ?
        RLS_DSKBUF_CYL_NO       DW              ?
        RLS_DSKBUF_SEC_NO       DB              1
        RLS_DSKBUF_HEAD_NO      DB              ?
        RLS_DSKBUF_LENGTH       DB              RLS_DSKBUF_MAX_LEN
        RLS_DSKBUF_BUFFER       LABEL           BYTE
        ;RLS_DSKBUF_BUFFER       DB              RLS_DSKBUF_MAX_LEN * 512  DUP(00H)

        ;***********************************
        LOAD_MSG        DB      10,13,'Starting MiniTAK Operating System...',00H
        ;***********************************

CONTINIUE_INITIALIZATION:

        MOV     AX,03C00H-64
        CLI
        MOV     SS,AX
        MOV     SP,1024         ;1KB Stack
        STI
        PUSH    CS
        POP     DS
        CMP     LOADING_STAGE,2
        JE      MESSAGE_OK
        ;-----------------------------------
        ;Clear screen
        MOV     AX,0040H        ;BIOS Data Area Segment
        MOV     DS,AX
        MOV     DL,DS:BYTE PTR[4AH]
        DEC     DL
        MOV     DH,DS:BYTE PTR[84H]
        MOV     AX,0600H
        XOR     CX,CX
        MOV     BH,07H
        INT     10H
        MOV     AH,0FH
        INT     10H
        MOV     AH,02H
        XOR     DX,DX
        INT     10H
        ;-----------------------------------
        PUSH    CS
        POP     DS
        LEA     DX,LOAD_MSG
        CALL    WRITE_ASCIIZ
        ;-----------------------------------
MESSAGE_OK:
        CMP     LOADING_STAGE,1
        JE      INITIALIZE_DISK_IO
        ;Set segment values for DOS Vars Rec,DPB, and Path Table.
        ;DS=CS
        MOV     AX,CS
        MOV     FIRST_DEV_DRIVER_SEG,AX
        MOV     CLOCK_DEV_HDR_SEG,AX
        MOV     CON_DEV_HDR_SEG,AX
        MOV     PATH_TABLE_SEG,AX
        MOV     DPB_SEG,AX
        ;Set segment address of interrupt services.
        ;AX=CS,DS=CS
        LEA     SI,INT21H_TABLE
        ;DS=CS
        ;AX=CS
SET_INT21H_SEG:
        CMP     BYTE PTR[SI],0FFH
        JE      INT21H_SEG_DONE
        MOV     WORD PTR[SI+3],AX
        ADD     SI,5
        JMP     Short SET_INT21H_SEG
INT21H_SEG_DONE:
        ;-----------------------------------
        ;Set interrupt vectors for INT 24H,25H,26H,21H and 32H.
        PUSH    CS
        POP     DS

        MOV     AL,24H
        LEA     DX,INT_24H_DEFAULT_HANDLER
        CALL    SET_INT_VECTOR

        MOV     AL,25H
        LEA     DX,READ_LOGIC_SECTOR_25H
        CALL    SET_INT_VECTOR

        MOV     AL,26H
        LEA     DX,WRITE_LOGIC_SECTOR_26H
        CALL    SET_INT_VECTOR

        LEA     DX,IRET_INTERRUPT_HANDLER
        MOV     AL,21H
        CALL    SET_INT_VECTOR
        MOV     AL,32H
        CALL    SET_INT_VECTOR

INITIALIZE_DISK_IO:
        CALL    INITIALIZE_DISKETTE_PARAMS
        ;***********************************
        ;Initialize FHBs.
        MOV     WORD PTR FHB1[1],1
        MOV     WORD PTR FHB2[1],2
        MOV     WORD PTR FHB3[1],3
        MOV     WORD PTR FHB4[1],4
        MOV     WORD PTR FHB5[1],5
        MOV     WORD PTR FHB6[1],6
        MOV     WORD PTR FHB7[1],7
        MOV     WORD PTR FHB8[1],8
        MOV     WORD PTR FHB9[1],9
        MOV     WORD PTR FHB10[1],10
        MOV     WORD PTR FHB11[1],11
        MOV     WORD PTR FHB12[1],12
        MOV     WORD PTR FHB13[1],13
        MOV     WORD PTR FHB14[1],14

        MOV     BYTE PTR FIRST_FILE_HANDLE[24],00H
        MOV     BYTE PTR FHB1[24],01H
        MOV     BYTE PTR FHB2[24],02H
        MOV     BYTE PTR FHB3[24],03H
        MOV     BYTE PTR FHB4[24],04H

        MOV     BYTE PTR FIRST_FILE_HANDLE[0],1
        MOV     BYTE PTR FHB1[0],1
        MOV     BYTE PTR FHB2[0],1
        MOV     BYTE PTR FHB3[0],1
        MOV     BYTE PTR FHB4[0],1

        MOV     AX,CS
        MOV     WORD PTR FIRST_FILE_HANDLE[17],AX
        MOV     WORD PTR FHB1[17],AX
        MOV     WORD PTR FHB2[17],AX
        MOV     WORD PTR FHB3[17],AX
        MOV     WORD PTR FHB4[17],AX
        MOV     WORD PTR FHB5[17],AX
        MOV     WORD PTR FHB6[17],AX
        MOV     WORD PTR FHB7[17],AX
        MOV     WORD PTR FHB8[17],AX
        MOV     WORD PTR FHB9[17],AX
        MOV     WORD PTR FHB10[17],AX
        MOV     WORD PTR FHB11[17],AX
        MOV     WORD PTR FHB12[17],AX
        MOV     WORD PTR FHB13[17],AX
        MOV     WORD PTR FHB14[17],0
        MOV     WORD PTR FIRST_FILE_HANDLE[15],OFFSET FHB1
        MOV     WORD PTR FHB1[15],OFFSET FHB2
        MOV     WORD PTR FHB2[15],OFFSET FHB3
        MOV     WORD PTR FHB3[15],OFFSET FHB4
        MOV     WORD PTR FHB4[15],OFFSET FHB5
        MOV     WORD PTR FHB5[15],OFFSET FHB6
        MOV     WORD PTR FHB6[15],OFFSET FHB7
        MOV     WORD PTR FHB7[15],OFFSET FHB8
        MOV     WORD PTR FHB8[15],OFFSET FHB9
        MOV     WORD PTR FHB9[15],OFFSET FHB10
        MOV     WORD PTR FHB10[15],OFFSET FHB11
        MOV     WORD PTR FHB11[15],OFFSET FHB12
        MOV     WORD PTR FHB12[15],OFFSET FHB13
        MOV     WORD PTR FHB13[15],OFFSET FHB14
        MOV     WORD PTR FHB14[15],0
        ;Initialize Disk Buffers.
        MOV     AX,CS
        MOV     WORD PTR FIRST_DISK_BUF[11],AX
        MOV     WORD PTR DSKBUF_1[11],AX
        MOV     WORD PTR DSKBUF_2[11],AX
        MOV     WORD PTR DSKBUF_3[11],AX
        MOV     WORD PTR DSKBUF_4[11],AX
        MOV     WORD PTR DSKBUF_5[11],AX
        MOV     WORD PTR DSKBUF_6[11],AX
        MOV     WORD PTR DSKBUF_7[11],AX
        MOV     WORD PTR DSKBUF_8[11],AX
        MOV     WORD PTR DSKBUF_9[11],AX
        MOV     WORD PTR DSKBUF_10[11],AX
        MOV     WORD PTR DSKBUF_11[11],AX
        MOV     WORD PTR DSKBUF_12[11],AX
        MOV     WORD PTR DSKBUF_13[11],AX
        MOV     WORD PTR DSKBUF_14[11],AX
        MOV     WORD PTR DSKBUF_15[11],AX
        MOV     WORD PTR DSKBUF_16[11],AX
        MOV     WORD PTR DSKBUF_17[11],AX
        MOV     WORD PTR DSKBUF_18[11],AX
        MOV     WORD PTR DSKBUF_19[11],AX
        MOV     WORD PTR DSKBUF_20[11],AX
        MOV     WORD PTR DSKBUF_21[11],AX
        MOV     WORD PTR DSKBUF_22[11],AX
        MOV     WORD PTR DSKBUF_23[11],AX
        MOV     WORD PTR DSKBUF_24[11],0

        MOV     WORD PTR FIRST_DISK_BUF[9],OFFSET DSKBUF_1
        MOV     WORD PTR DSKBUF_1[9],OFFSET DSKBUF_2
        MOV     WORD PTR DSKBUF_2[9],OFFSET DSKBUF_3
        MOV     WORD PTR DSKBUF_3[9],OFFSET DSKBUF_4
        MOV     WORD PTR DSKBUF_4[9],OFFSET DSKBUF_5
        MOV     WORD PTR DSKBUF_5[9],OFFSET DSKBUF_6
        MOV     WORD PTR DSKBUF_6[9],OFFSET DSKBUF_7
        MOV     WORD PTR DSKBUF_7[9],OFFSET DSKBUF_8
        MOV     WORD PTR DSKBUF_8[9],OFFSET DSKBUF_9
        MOV     WORD PTR DSKBUF_9[9],OFFSET DSKBUF_10
        MOV     WORD PTR DSKBUF_10[9],OFFSET DSKBUF_11
        MOV     WORD PTR DSKBUF_11[9],OFFSET DSKBUF_12
        MOV     WORD PTR DSKBUF_12[9],OFFSET DSKBUF_13
        MOV     WORD PTR DSKBUF_13[9],OFFSET DSKBUF_14
        MOV     WORD PTR DSKBUF_14[9],OFFSET DSKBUF_15
        MOV     WORD PTR DSKBUF_15[9],OFFSET DSKBUF_16
        MOV     WORD PTR DSKBUF_16[9],OFFSET DSKBUF_17
        MOV     WORD PTR DSKBUF_17[9],OFFSET DSKBUF_18
        MOV     WORD PTR DSKBUF_18[9],OFFSET DSKBUF_19
        MOV     WORD PTR DSKBUF_19[9],OFFSET DSKBUF_20
        MOV     WORD PTR DSKBUF_20[9],OFFSET DSKBUF_21
        MOV     WORD PTR DSKBUF_21[9],OFFSET DSKBUF_22
        MOV     WORD PTR DSKBUF_22[9],OFFSET DSKBUF_23
        MOV     WORD PTR DSKBUF_23[9],OFFSET DSKBUF_24
        MOV     WORD PTR DSKBUF_24[11],0

        MOV     BYTE PTR FIRST_DISK_BUF[14],0
        MOV     BYTE PTR DSKBUF_1[14],0
        MOV     BYTE PTR DSKBUF_2[14],0
        MOV     BYTE PTR DSKBUF_3[14],0
        MOV     BYTE PTR DSKBUF_4[14],0
        MOV     BYTE PTR DSKBUF_5[14],0
        MOV     BYTE PTR DSKBUF_6[14],0
        MOV     BYTE PTR DSKBUF_7[14],0
        MOV     BYTE PTR DSKBUF_8[14],0

        MOV     BYTE PTR DSKBUF_9[14],1
        MOV     BYTE PTR DSKBUF_10[14],1
        MOV     BYTE PTR DSKBUF_11[14],1
        MOV     BYTE PTR DSKBUF_12[14],1
        MOV     BYTE PTR DSKBUF_13[14],1
        MOV     BYTE PTR DSKBUF_14[14],1
        MOV     BYTE PTR DSKBUF_15[14],1
        MOV     BYTE PTR DSKBUF_16[14],1
        MOV     BYTE PTR DSKBUF_17[14],1
        MOV     BYTE PTR DSKBUF_18[14],1
        MOV     BYTE PTR DSKBUF_19[14],1
        MOV     BYTE PTR DSKBUF_20[14],1
        MOV     BYTE PTR DSKBUF_21[14],1
        MOV     BYTE PTR DSKBUF_22[14],1

        MOV     BYTE PTR DSKBUF_23[14],2
        MOV     BYTE PTR DSKBUF_24[14],2

        CMP     LOADING_STAGE,1
        JE      LOAD_MINIIO_STAGE_2
        ;***********************************
        ;Prepare to load MiniTAK.SYS.
        ;Calculate load segment
        LEA     AX,MINIIO_INITIALIZER
        XOR     DX,DX
        MOV     BX,16
        DIV     BX
        INC     AX
        MOV     BX,CS
        ADD     AX,BX
        ADD     AX,RLS_DSKBUF_MAX_LEN*32+1
        ;PUSH    AX              ;PUSH load segment on the stack
        MOV     BP,AX
        MOV     CS:WORD PTR LOAD_JUMP[2],AX
        XOR     AX,AX
        MOV     CS:WORD PTR LOAD_JUMP[0],AX

        PUSH    CS
        POP     DS
        LEA     DX,MINITAK_PATH
        XOR     AL,AL
        JMP     LOAD_MINITAK

INITIALIZE_DISKETTE_PARAMS      PROC
        PUSH    AX
        PUSH    DX
        PUSH    ES
        ;Redirect diskette parameter table (INT 1EH) to internal DDPT
        XOR     AX,AX
        MOV     ES,AX
        LEA     AX,DDPT
        MOV     ES:WORD PTR[007AH],CS
        MOV     ES:WORD PTR[0078H],AX
        ;Reset disk to use the new DDPT
        MOV     AH,00H
        MOV     DL,00H
        INT     13H
        POP     ES
        POP     DX
        POP     AX
        RET
INITIALIZE_DISKETTE_PARAMS      ENDP

SET_INT_VECTOR  PROC
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


        END     MINIIO_START

