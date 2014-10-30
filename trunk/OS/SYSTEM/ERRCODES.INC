        ;@@@@@@@@@@@@@@@   EQUIVALENTS    (ERROR CODES)  @@@@@@@@@@@@@@@
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

