      SUBROUTINE  INPUT_FILES                                               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                      
!C    Subroutine FILES is called by .MAIN at the beginning of a         
!C    simulation to open the needed files.                              
!C                                                                      
      USE  MODULE_STANDARD,  ONLY: 
     &       INFIL, OUTFIL,                              ! /FILEN/
     &       WORK_DIRECTORY,                             ! /FILEN/, new variable
     &       ICHAR_STD, INTEGER_STD, LOGICAL_STD,        ! parameters
     &       LUAIN, LUAOU, LU_MEM, LUDEBUG, LULIN,       ! parameters
     &       LUTERM_IN, LUTERM_OUT, TRUE, FALSE,         ! parameters
     &       LIN_FLAG, AIN_CONVERT,                      ! parameters
     &       I_0, I_2                                    ! parameters
!C
      !  (gfortran: GETCWD, STAT are intrinsics)
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  IRESULT_CWD, IRESULT_STAT,
     &                                 ISTATB
      DIMENSION     ISTATB(13)   
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  CHAR_INPUT,
     &                 LINFIL_OVERWRITE 
      CHARACTER ( LEN =   4, KIND = ICHAR_STD )  AIN, AOU, DBG, LIN                                       
      CHARACTER ( LEN =  13, KIND = ICHAR_STD )  ATB_PARAMETERS_FILE
      CHARACTER ( LEN  = 32, KIND = ICHAR_STD )  INFIL2
      CHARACTER ( LEN =  80, KIND = ICHAR_STD )  TEMP_WORK_DIRECTORY
      CHARACTER ( LEN = 116, KIND = ICHAR_STD )  AINFIL, AOUFIL, 
     &                                           LINFIL, DBGFIL                  
!C
      CHARACTER ( LEN = 116, KIND = ICHAR_STD )  FNAME
      EXTERNAL  FNAME
!C
      LOGICAL ( KIND = LOGICAL_STD )  LFILE_EXISTS, DEBUG_RUN
!C
      DATA AIN / ICHAR_STD_'.ain' /, AOU / ICHAR_STD_'.aou' /,
     &     DBG / ICHAR_STD_'.dbg' /, LIN / ICHAR_STD_'.lin' /                                
      DATA ATB_PARAMETERS_FILE / ICHAR_STD_'atb_parms.mem' /
!C
!C    Define whether the debug logical output unit will be opened.
!C
      DEBUG_RUN = FALSE
!C
      WRITE ( LUTERM_OUT, 212)
212   FORMAT ( 1X, 'The Government makes no express or implied', /,                                      
     & 1X, 'warranty as to any matter whatsoever including the',/, 
     & 1X, 'conditions of the research or any product agreement',/, 
     & 1X, 'or of the merchantability, validity, suitability, ',/,
     & 1X, 'or fitness for a particular ',/,
     & 1X, 'purpose of the research or product developed from',/,
     & 1X, 'the use of this software.  In no event will the',/,
     & 1X, 'Government be liable to any other party for',/,
     & 1X, 'compensatory, punitive, exemplary or consequential',/,
     & 1X, 'damages.  The Government is neither liable nor',/,
     & 1X, 'responsible for maintenance, updating or correcting',/,
     & 1X, 'any errors in the provided software.  The user  ',/,
     & 1X, 'accepts all risks and responsibilities from the ',/,
     & 1X, 'following analysis.  Please see the ATB  Users   ',/,
     & 1X, 'guide for information on suppressing this startup',/,
     & 1X, 'message in the future.  Do you accept these terms?',/,
     & 1X, 'Enter [Y/y] to accept or [N/n] to reject:')
      READ ( LUTERM_IN, 213 ) CHAR_INPUT
213   FORMAT ( A1 )
      IF ((CHAR_INPUT .EQ. 'Y' ).OR.( CHAR_INPUT .EQ. 'y')) THEN 
       CONTINUE
      ELSE 
       STOP
      END IF
!C
!C    Determine if the ATB parameters file exists in the directory
!C     where the executable program is located.
!C
      INQUIRE ( FILE = ATB_PARAMETERS_FILE, ERR = 30,
     &          EXIST = LFILE_EXISTS )
!C
!C    If the file exists, read the currently stored default
!C     directory name.  Otherwise, create the file and use the
!C     location of the executable file as the default working 
!C     directory.
!C
      IF ( LFILE_EXISTS )  THEN
       OPEN ( UNIT = LU_MEM, FILE = ATB_PARAMETERS_FILE, ERR = 35,
     &        ACCESS = 'SEQUENTIAL', ACTION = 'READWRITE',
     &        FORM = 'FORMATTED', POSITION = 'REWIND', 
     &        STATUS = 'OLD' )
       READ ( LU_MEM, 100 )  WORK_DIRECTORY
  100  FORMAT ( A79 )
      ELSE
       OPEN ( UNIT = LU_MEM, FILE = ATB_PARAMETERS_FILE, ERR = 40,
     &        ACCESS = 'SEQUENTIAL', ACTION = 'READWRITE',
     &        FORM = 'FORMATTED', POSITION = 'REWIND',
     &        STATUS = 'NEW' ) 
       IRESULT_CWD = GETCWD ( WORK_DIRECTORY )
       IF ( IRESULT_CWD .NE. I_0 )  THEN
        WRITE ( LUTERM_OUT, 105 )
  105   FORMAT ( 1X, ' Error obtaining working directory! ' )
        STOP ' STOP 5004 in Subroutine INPUT_FILES. '
       END IF
       WRITE ( LUTERM_OUT, 110 ) WORK_DIRECTORY
  110  FORMAT ( A79 )
       WRITE ( LU_MEM, 112 ) WORK_DIRECTORY
  112  FORMAT ( A79 )
      END IF
!C
!C    Get the working directory name.  This directory will contain the
!C     input(s) file and where all the output files will be placed.
!C    The default is the directory name that is stored in the file 
!C     ATB_PARMS.MEM.  This file is stored in the subdirectory where the 
!C     executable program is.
      DO
       WRITE ( LUTERM_OUT, 115 ) WORK_DIRECTORY 
  115  FORMAT ( 1X, ' Enter the working directory, the default is: ', /,
     &          A79 )
       READ ( LUTERM_IN, 120 )  TEMP_WORK_DIRECTORY
  120  FORMAT ( A79 )
       IF ( TEMP_WORK_DIRECTORY .NE. ' ' )  THEN
!C
!C      Check if the supplied directory exists.
!C
        IRESULT_STAT = STAT ( TEMP_WORK_DIRECTORY, ISTATB )
        IF ( IRESULT_STAT .EQ. I_2 )  THEN
         WRITE ( LUTERM_OUT, 125 ) ADJUSTL (TEMP_WORK_DIRECTORY )
  125    FORMAT ( 1X, ' The specified directory: ', 
     &            1X,  A79, ' does not exist. ', / )
         CYCLE
        ELSE
         WORK_DIRECTORY = TEMP_WORK_DIRECTORY
         EXIT
        END IF
       ELSE
        EXIT
       END IF
      END DO
!C
      WRITE ( LUTERM_OUT, 130 ) ADJUSTL ( WORK_DIRECTORY )
  130 FORMAT ( 1X, ' The working directory for this run is: ', /, 
     &         1X, A79 )
      REWIND ( UNIT = LU_MEM, ERR = 42 )
      WRITE ( LU_MEM, 135 ) WORK_DIRECTORY
  135 FORMAT ( A79 )
!C
!C    Get the type of input file that will be supplied.
!C
      DO 
       WRITE ( LUTERM_OUT, 140 )
  140  FORMAT ( 1X, ' Specify the type of input file that will be used:'
     &              , /, 1X, ' Listed-directed - it must have the .LIN ',
     &                       ' extension [default or L/l] or ', /,
     &          1X, ' Explicit format - it must have the .AIN ',
     &              'extension [A/a]  ' )
       READ ( LUTERM_IN, 145 ) CHAR_INPUT
  145  FORMAT ( A1 )
       IF ( ( CHAR_INPUT .EQ. 'L' ) .OR. 
     &      ( CHAR_INPUT .EQ. 'l' ) .OR. ( CHAR_INPUT .EQ. ' ' ) ) THEN
        LIN_FLAG = TRUE
        EXIT
       ELSE IF ( ( CHAR_INPUT .EQ. 'A' ) .OR. 
     &           ( CHAR_INPUT .EQ. 'a' ) )  THEN
!C
!C      If an explicitly formatted input file is to be used, i.e.
!C       an '.ain' file, ask if the user wants to create a list-directed
!C       form of that input file, which will be given the extension
!C       '.lin'.
!C
        LIN_FLAG = FALSE
        DO
         WRITE ( LUTERM_OUT, 150 )
  150    FORMAT ( 1X, ' Do you want a list-directed file, with the',
     &                ' same filename as the .AIN file',
     &                ' to be created with the extension .LIN? ',
     &                ' [Default is N/n] ' )
         READ ( LUTERM_IN, 155 ) CHAR_INPUT
  155    FORMAT ( A1 )
         IF ( ( CHAR_INPUT .EQ. 'N' ) .OR. ( CHAR_INPUT .EQ. 'n' ) 
     &        .OR. ( CHAR_INPUT .EQ. ' ' ) )  THEN
          AIN_CONVERT = FALSE
          EXIT
         ELSE IF ( ( CHAR_INPUT .EQ. 'Y' ) .OR. 
     &             ( CHAR_INPUT .EQ. 'y' ) )  THEN
          AIN_CONVERT = TRUE
          EXIT
         ELSE
          CYCLE
         END IF
        END DO
!C
        EXIT
       ELSE 
        CYCLE
       END IF
      END DO
!C                                                                      
!C    Input and output filenames without extensions are specified.      
!C
!C    Get the input file ( .LIN or .AIN) file.
!C
      IF ( LIN_FLAG )  THEN
       DO
        WRITE ( LUTERM_OUT, 160 )  LIN                                      
  160   FORMAT (1X, ' Enter input filename, the extension',
     &              ' "', A4, '" is assumed:', / )
        READ ( LUTERM_IN, 165 ) INFIL                                 
  165   FORMAT ( A32 )
!C                                                                        
!C      Check if the user-supplied .LIN file exists.                      
!C
        LINFIL = FNAME ( WORK_DIRECTORY, INFIL,  LIN )                  
        INQUIRE ( FILE = LINFIL, ERR = 45,
     &            EXIST = LFILE_EXISTS )
        IF ( .NOT. LFILE_EXISTS )  THEN
         WRITE ( LUTERM_OUT, 170 ) LINFIL
  170    FORMAT ( 1X, ' Input file: ', A116, ' does not exist. ' )
         CYCLE
        ELSE
         EXIT
        END IF         
       END DO
!C
       OPEN ( UNIT = LULIN, FILE = LINFIL,  
     &        ACCESS = 'SEQUENTIAL', ACTION = 'READ', ERR = 50,
     &        FORM = 'FORMATTED', POSITION = 'REWIND', 
     &        STATUS = 'OLD', DELIM = 'QUOTE', RECL = 256 )                                   
      ELSE
       DO
        WRITE ( LUTERM_OUT, 175 )  AIN                                      
  175   FORMAT (1X, ' Enter input filename, the extension',
     &              ' "', A4, '" is assumed:', / )
        READ ( LUTERM_IN, 180 ) INFIL                                 
  180   FORMAT ( A32 )
!C                                                                        
!C      Check if the user-supplied .AIN file exists.                      
!C
        AINFIL = FNAME ( WORK_DIRECTORY, INFIL,  AIN )                  
        INQUIRE ( FILE = AINFIL, ERR = 55,
     &            EXIST = LFILE_EXISTS )
        IF ( .NOT. LFILE_EXISTS )  THEN
         WRITE ( LUTERM_OUT, 185 ) AINFIL
  185    FORMAT ( 1X, ' Input file: ', A116, ' does not exist. ' )
         CYCLE
        ELSE
         EXIT
        END IF         
       END DO
!C
       OPEN ( UNIT = LUAIN, FILE = AINFIL,  
     &        ACCESS = 'SEQUENTIAL', ACTION = 'READ', ERR = 60,
     &        FORM = 'FORMATTED', POSITION = 'REWIND', 
     &        STATUS = 'OLD' )                                   
      END IF
!C
!C    Get the output file name.
!C
      WRITE ( LUTERM_OUT, 190 )                                       
  190 FORMAT ( 1X, ' Enter filename for all output files',           
     &        ' extensions will be assigned:', /,
     &         1X, ' (Note: existing output files with the same ',  
     &         'name will be overwritten.) ', /)   
      READ ( LUTERM_IN, 195 )  OUTFIL                         
  195 FORMAT ( A32 )
!C
!C    If no output filename is supplied, the input filename will be
!C     used as the default.
!C
      IF ( OUTFIL .EQ. ' ' )  THEN
       OUTFIL = INFIL
      END IF
!C                                                                      
!C    Concatenate filenames with extensions.                      
!C
      AOUFIL = FNAME ( WORK_DIRECTORY, OUTFIL, AOU )                    
      OPEN ( UNIT = LUAOU, FILE = AOUFIL, 
     &       ACCESS = 'SEQUENTIAL', ACTION = 'WRITE', ERR = 65, 
     &       FORM = 'FORMATTED', POSITION = 'REWIND',
     &       STATUS = 'UNKNOWN' )                   
!C
!C    Create the .LIN file if specified.
!C
      IF ( AIN_CONVERT )  THEN
!C
!C     If a .LIN file is to be created, create the filename,
!C      which will be the input filename with the extension .LIN.
!C                                                                      
!C     Concatenate filenames with extensions.                      
!C
       LINFIL = FNAME ( WORK_DIRECTORY, INFIL,  LIN )                  
       INQUIRE ( FILE = LINFIL, ERR = 43,
     &           EXIST = LFILE_EXISTS )
!C
!C     Test if .LIN file already exists.  If it does, either
!C      overwrite, or specify a different name for the .LIN
!C      file than for the other files from this run.
!C
       IF ( LFILE_EXISTS )  THEN
        DO
         WRITE ( LUTERM_OUT, 200 )  LINFIL
  200    FORMAT ( 1X, '.LIN file: ', A116, ' already exists. ' )
         WRITE ( LUTERM_OUT, 205 )
  205    FORMAT ( 1X, ' Do you wish to overwrite the existing',
     &                ' file [Y/N - default Y]? ' )
         READ ( LUTERM_IN, 206 ) LINFIL_OVERWRITE
  206    FORMAT ( A1 )
         IF ( ( LINFIL_OVERWRITE .EQ. 'Y' ) .OR.
     &        ( LINFIL_OVERWRITE .EQ. 'y' ) .OR.
     &        ( LINFIL_OVERWRITE .EQ. ' ' ) )  THEN
          OPEN ( UNIT = LULIN, FILE = LINFIL, 
     &           ACCESS = 'SEQUENTIAL', ACTION = 'WRITE', ERR = 70, 
     &           FORM = 'FORMATTED', POSITION = 'REWIND',
     &           STATUS = 'REPLACE', DELIM = 'QUOTE', RECL = 256 )                   
          EXIT
         ELSE IF ( ( LINFIL_OVERWRITE .EQ. 'N' ) .OR.
     &             ( LINFIL_OVERWRITE .EQ. 'n' ) )  THEN
          WRITE ( LUTERM_OUT, 210 )
  210     FORMAT ( 1X, ' Enter a new filename, without extensions.',
     &             /, ' The .LIN filename may be different from the',
     &             ' other simulation filenames.' )
          READ ( LUTERM_IN, 215 ) INFIL2                                 
  215     FORMAT ( A32 )
!C
!C        Create a LIN file with a filename different from the other
!C         files in the simulation.  The filename will have the 
!C         extension .LIN.
!C                                                                      
!C        Concatenate filenames with extensions.                      
!C
          LINFIL = FNAME ( WORK_DIRECTORY, INFIL2,  LIN )                  
          INQUIRE ( FILE = LINFIL, ERR = 43,
     &              EXIST = LFILE_EXISTS )
          IF ( .NOT. LFILE_EXISTS )  THEN
           OPEN ( UNIT = LULIN, FILE = LINFIL, 
     &            ACCESS = 'SEQUENTIAL', ACTION = 'WRITE', ERR = 70, 
     &            FORM = 'FORMATTED', POSITION = 'REWIND',
     &            STATUS = 'NEW', DELIM = 'QUOTE', RECL = 256 )                   
           EXIT
          END IF
         ELSE
          WRITE ( LUTERM_OUT, 220 )
  220     FORMAT ( 1X, ' Must enter "Y"/"y" or "N"/"n". ' )
         END IF      
        END DO
       ELSE
!C
        OPEN ( UNIT = LULIN, FILE = LINFIL, 
     &         ACCESS = 'SEQUENTIAL', ACTION = 'WRITE', ERR = 70, 
     &         FORM = 'FORMATTED', POSITION = 'REWIND',
     &         STATUS = 'NEW', DELIM = 'QUOTE', RECL = 256 )                   
       END IF
      END IF
!C
!C    Create the debug filename with the '.dbg' extension using the
!C     the run's output filename.
!C
      IF ( DEBUG_RUN )  THEN
       DBGFIL = FNAME ( WORK_DIRECTORY, OUTFIL, DBG )                    
       OPEN ( UNIT = LUDEBUG, FILE = DBGFIL, 
     &        ACCESS = 'SEQUENTIAL', ACTION = 'WRITE', ERR = 75, 
     &        FORM = 'FORMATTED', POSITION = 'REWIND',
     &        STATUS = 'UNKNOWN' )                   
      END IF
!C                                                                      
      RETURN                                                            
!C
!C    Error messages related to file handling.
!C
   30 WRITE ( LUTERM_OUT, 330 )
  330 FORMAT ( 1X, ' Error determining if ATB parameter file exists. ' )
      STOP ' STOP 5001 in Subroutine INPUT_FILES. '
!C
   35 WRITE ( LUTERM_OUT, 335 )
  335 FORMAT ( 1X, ' Error opening an existing ATB parameter file. ' )
      STOP ' STOP 5002 in Subroutine INPUT_FILES. '
!C
   40 WRITE ( LUTERM_OUT, 340 )
  340 FORMAT ( 1X, ' Error opening a new ATB parameter file. ' )
      STOP ' STOP 5003 in Subroutine INPUT_FILES. '
!C
   42 WRITE ( LUTERM_OUT, 342 )
  342 FORMAT ( 1X, ' Error rewinding ATB parameter file. ' )
      STOP ' STOP 5005 in Subroutine INPUT_FILES. '
!C
   43 WRITE ( LUTERM_OUT, 343 )
  343 FORMAT ( 1X, ' Error determining if .LIN file exists. ' )
      STOP ' STOP 5006 in Subroutine INPUT_FILES. '
!C
   45 WRITE ( LUTERM_OUT, 345 )
  345 FORMAT ( 1X, ' Error determining if .LIN file exists. ' )
      STOP ' STOP 5007 in Subroutine INPUT_FILES. '
!C
   50 WRITE ( LUTERM_OUT, 350 ) LINFIL
  350 FORMAT ( 1X, ' Error opening .LIN file: ', A116 )
      STOP ' STOP 5008 in Subroutine INPUT_FILES. '
!C
   55 WRITE ( LUTERM_OUT, 355 )
  355 FORMAT ( 1X, ' Error determining if .AIN file exists. ' )
      STOP ' STOP 5009 in Subroutine INPUT_FILES. '
!C
   60 WRITE ( LUTERM_OUT, 360 ) AINFIL
  360 FORMAT ( 1X, ' Error opening .AIN file: ', A116 )
      STOP ' STOP 5010 in Subroutine INPUT_FILES. '
!C
   65 WRITE ( LUTERM_OUT, 365 ) AOUFIL
  365 FORMAT ( 1X, ' Error opening .AOU file: ',A116 )
      STOP ' STOP 5011 in Subroutine INPUT_FILES. '
!C
   70 WRITE ( LUTERM_OUT, 370 ) LINFIL
  370 FORMAT ( 1X, ' Error creating .LIN file: ',A116 ) 
      STOP ' STOP 5012 in Subroutine INPUT_FILES. '
!C
   75 WRITE ( LUTERM_OUT, 375 ) DBGFIL
  375 FORMAT ( 1X, ' Error opening .DBG file: ',A116 )
      STOP ' STOP 5013 in Subroutine INPUT_FILES. '
!C
      END                                                             
