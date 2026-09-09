      SUBROUTINE INPUT_ACARDS
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the A cards and opens the files
!C     needed by the program.
!C    It is called by .MAIN.
!C
      USE  MODULE_STANDARD, ONLY:
     &       G, GRAVTY, UNITL, UNITM, UNITT,                  ! /CNSNTS/
     &       DT, H0, HMAX, HMIN, ISTEP, NDINT, NSTEPS,        ! /COMAIN/
     &       NPRT,                                            ! /CONTRL/
     &       OUTFIL, WORK_DIRECTORY,                          ! /FILEN/, new
     &       DATE, COMENT,                                    ! /TITLES/
     &       OUT_TIMES,                                       ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,              ! parameters
     &       LUAIN, LUAOU, LUTP8, LUVIEW, LUTERM_OUT, LULIN,  ! parameters
     &       MAX_NUM_OUT_TIMES, NUM_OUT_TIMES,                ! parameters
     &       D_0, I_0, I_1, I_2, I_6, TRUE, FALSE,            ! parameters
     &       AIN_CONVERT, LIN_FLAG                            ! parameters 
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )   I, L, LL, LLL
!C
      REAL  ( KIND = IREAL_HIGH )    TE, TS, VECMAG
      EXTERNAL    VECMAG
!C
      CHARACTER  ( LEN =   1, KIND = ICHAR_STD )  AP, AT, AV
      CHARACTER  ( LEN =   3, KIND = ICHAR_STD )  ATEMP3_1, ATEMP3_2,
     &                                            ATEMP3_3
      CHARACTER  ( LEN =   4, KIND = ICHAR_STD )  TP1, TP8, UF1, SA1,
     &                                            ATEMP4
      CHARACTER  ( LEN =   6, KIND = ICHAR_STD )  ATEMP6_1, ATEMP6_2,
     &                                            ATEMP6_3
      CHARACTER  ( LEN =  12, KIND = ICHAR_STD )  ATEMP12
      CHARACTER  ( LEN =  14, KIND = ICHAR_STD )  ATEMP14
      CHARACTER  ( LEN =  80, KIND = ICHAR_STD )  ATEMP80              
      CHARACTER  ( LEN =  82, KIND = ICHAR_STD )  ATEMP82              
      CHARACTER  ( LEN = 116, KIND = ICHAR_STD )  TP1FIL, TP8FIL              
!C
      CHARACTER  ( LEN = 116, KIND = ICHAR_STD )  FNAME
      EXTERNAL         FNAME
!C
      DATA TP1 / ICHAR_STD_'.tp1' /, TP8 / ICHAR_STD_'.tp8' /            
      DATA UF1 / ICHAR_STD_'.uf1' /, SA1 / ICHAR_STD_'.sa1' /              
!C
!C    Input and echo Card A.1.
!C
      CALL  CHECK_COMMENT
      IF ( LIN_FLAG )  THEN
       READ  ( LULIN, * )  DATE
       READ  ( LULIN, * )  COMENT(1:80)
       READ  ( LULIN, * )  COMENT(81:160)
      ELSE
       READ ( LUAIN, 100 )  DATE, COMENT(1:80), COMENT(81:160)                
  100  FORMAT ( A12, /, A80, /, A80 )                                    
       IF ( AIN_CONVERT )  THEN
        ATEMP12 = ADJUSTL ( DATE )
        L = LEN_TRIM ( ATEMP12 )
        ATEMP14(1:L+2) = '"' // ATEMP12(1:L) // '"'
        WRITE ( LULIN, 105 ) ATEMP14(1:L+2), 'Card A.1.a'
  105   FORMAT ( 1X, A, 2X, A )
        ATEMP80 = ADJUSTL ( COMENT(1:80) )
        L = LEN_TRIM ( ATEMP80 )
        ATEMP82(1:L+2) = '"' // ATEMP80(1:L) // '"'
        WRITE ( LULIN, 110 ) ATEMP82(1:L+2), 'Card A.1b'
  110   FORMAT ( 1X, A, 2X, A )
        ATEMP80 = ADJUSTL ( COMENT(81:160) )
        L = LEN_TRIM ( ATEMP80 )
        ATEMP82(1:L+2) = '"' // ATEMP80(1:L) // '"'
        WRITE ( LULIN,115 ) ATEMP82(1:L+2), 'Card A.1c'
  115   FORMAT ( 1X, A, 2X, A )
       END IF
      END IF
      WRITE ( LUAOU, 120 )  DATE, COMENT(1:80), COMENT(81:160)               
  120 FORMAT ( 4X, A12,                                                   
     &         61X, 'Cards A', //, 1X, A80, /, 1X, A80, // )             
!C                                                                         
!C    Input and echo Cards A.3,A.4 and A.5.                                
!C                                                                         
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )  UNITL, UNITM, UNITT, GRAVTY, G                   
      ELSE
       READ ( LUAIN, 125 )  UNITL, UNITM, UNITT, GRAVTY, G                   
  125  FORMAT ( 3A4, 4F12.0 )                                               
       IF ( AIN_CONVERT )  THEN
        ATEMP4 = ADJUSTL ( UNITL ) 
        L = LEN_TRIM ( ATEMP4 )
        ATEMP6_1(1:L+2) = '"' // ATEMP4(1:L) // '"' 
        ATEMP4 = ADJUSTL ( UNITM )
        LL = LEN_TRIM ( ATEMP4 )
        ATEMP6_2(1:LL+2) = '"' //  ATEMP4(1:LL) // '"'
        ATEMP4 = ADJUSTL ( UNITT )
        LLL = LEN_TRIM ( ATEMP4 )
        ATEMP6_3(1:LLL+2) = '"' //  ATEMP4(1:LLL) // '"'
        WRITE ( LULIN, 130 )  ATEMP6_1(1:L+2), ATEMP6_2(1:LL+2), 
     &                        ATEMP6_3(1:LLL+2), GRAVTY, G, 'Card A.3'                   
  130   FORMAT ( 1X, 3( A, 1X ), 4( F15.7, 1X ), 2X, A8 )
       END IF
      END IF
      IF  ( G .EQ. D_0 )    THEN
       G = VECMAG ( GRAVTY )
      END IF
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )   NDINT, NSTEPS, DT, H0, HMAX, HMIN         
       READ ( LULIN, * )   NPRT
      ELSE
       READ ( LUAIN, 135 )   NDINT, NSTEPS, DT, H0, HMAX, HMIN, NPRT         
  135  FORMAT ( 2I4, 4F8.0, /, 36I2 )                                    
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 140 )   NDINT, NSTEPS, DT, H0, HMAX, HMIN, 
     &                         'Card A.4', NPRT, 'Card A.5'
  140   FORMAT ( 2X, I4, 1X, I4, 4( F15.7, 1X ), A8, 
     &                          /, 1X, 36( I2, 1X ), A8 ) 
       END IF
      END IF
      WRITE ( LUAOU, 145 )  UNITL, UNITM, UNITT, GRAVTY, G,                
     &                     NDINT, NSTEPS, DT, H0, HMAX, HMIN               
  145 FORMAT ( 5X, 'UNITL = ', A4, 5X, 'UNITM = ', A4, 5X,
     &         'UNITT = ',A4, 5X, 'Gravity Vector = (', F9.4, ',',
     &         F9.4, ',', F9.4, ')', 5X, 'G =', F9.4, //, 5X,
     &         'NDINT =', I4, 5X, 'NSTEPS =', I5, 5X, 'DT =', F8.6,        
     &         5X, 'H0 =', F8.6, 5X, 'HMAX =', F8.6, 5X, 
     &         'HMIN =', F8.6 )                                            
!C
!C    Always set NPRT(36)(DRIFT) to be 1.                               
!C
      NPRT(36) = I_1                                                
      WRITE ( LUAOU, 150 )  ( I, I=1,36 ), NPRT                             
  150 FORMAT ( '0 NPRT Array', /, 3X, 36I3, /, 3X, 36I3 )                  
!C                                                                       
      IF ( NPRT(26) .GT. I_6 )  STOP 93                               
!C
!C    Check the control value for the output time windowing.
!C
      IF ( ( NPRT(34) .LT. I_0 ) .OR. 
     &     ( NPRT(34) .GT. MAX_NUM_OUT_TIMES ) ) THEN
       WRITE ( LUAOU, 155 )  NPRT(34)
  155  FORMAT ( 1X, ' Value for NPRT(34), ', I2, ', is invalid. ' )
       STOP ' Stop 3000 in Subroutine INPUT_ACARDS '
      ELSE
       NUM_OUT_TIMES = NPRT(34)
      END IF
!C
!C    Read in the A.6.a - Cards ( output time control ).
!C
      IF ( NUM_OUT_TIMES .GT. I_0 )  THEN
       DO I=1,NUM_OUT_TIMES
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * ) AP, AT, AV, TS, TE
        ELSE
         READ ( LUAIN, 160 )  AP, AT, AV, TS, TE
  160    FORMAT ( A1, 1X, A1, 1X, A1, 1X, F10.3, 1X, F10.3 )
         IF ( AIN_CONVERT )  THEN
          ATEMP3_1(1:3) = '"' // AP(1:1) // '"'
          ATEMP3_2(1:3) = '"' // AT(1:1) // '"'
          ATEMP3_3(1:3) = '"' // AV(1:1) // '"'
          WRITE ( LULIN, 165 ) ATEMP3_1, ATEMP3_2, ATEMP3_3, 
     &                         TS, TE, 'Card A.6'
  165     FORMAT ( 3( A3, 1X ), 2( F17.9, 1X ), A8 )
         END IF
        END IF
!C
!C      Check the input, except if NSTEPS = 0 or 1 (for quick 
!C       check-out runs).  For these cases, set the logical
!C       flags to 0 to ignore the time windowing.
!C
        IF ( ( NSTEPS .EQ. I_0 ) .OR. ( NSTEPS .EQ. I_1 ) )  THEN  
         OUT_TIMES(I)%PRINT = FALSE
         OUT_TIMES(I)%TTH   = FALSE
         OUT_TIMES(I)%VIEW  = FALSE
         OUT_TIMES(I)%START = TS
         OUT_TIMES(I)%END   = TE
         CYCLE
        END IF
!C
!C      Test the time control flag for Subroutine PRINT output,
!C       which is allowed only for the first time window.
!C
        IF ( I .EQ. I_1 )  THEN
         IF ( ( AP .EQ. 'F' ) .OR. ( AP .EQ. 'f' ) )  THEN
          OUT_TIMES(I)%PRINT = FALSE
         ELSE IF ( ( AP .EQ. 'T' ) .OR. ( AP .EQ. 't' ) )  THEN
          OUT_TIMES(I)%PRINT = TRUE
         ELSE
          WRITE ( LUAOU, 170 ) AP
  170     FORMAT ( 1X, ' Invalid value for PRINT time control ', 
     &             A1, '.' )
          STOP ' Stop 3001 in Subroutine INPUT_ACARDS '
         END IF
        ELSE
         IF ( AP .NE. ' ' )  THEN
          WRITE ( LUAOU, 175 )  I
  175     FORMAT ( 1X, ' Warning - time window ', I2, ' control',
     &             ' flag for standard output ignored. ' )
         END IF
         OUT_TIMES(I)%PRINT = OUT_TIMES(1)%PRINT
        END IF
!C
!C      Test time control flag for Subroutine OUTPUT (TTH) output,
!C       which is allowed only for the first time window.
!C
        IF ( I .EQ. I_1 ) THEN
         IF ( ( AT .EQ. 'F' ) .OR. ( AT .EQ. 'f' ) )  THEN
          OUT_TIMES(I)%TTH = FALSE
         ELSE IF ( ( AT .EQ. 'T' ) .OR. ( AT .EQ. 't' ) )  THEN
          OUT_TIMES(I)%TTH = TRUE
         ELSE
          WRITE ( LUAOU, 180 ) AT
  180     FORMAT ( 1X, ' Invalid value for TTH time control ', 
     &             A1, '.' )
          STOP ' Stop 3003 in Subroutine INPUT_ACARDS '
         END IF
        ELSE
         IF ( AT .NE. ' ' )  THEN
          WRITE ( LUAOU, 185 )  I
  185     FORMAT ( 1X, ' Warning - time window ', I2, ' control',
     &             ' flag for tabular time histories ignored. ' )
         END IF
         OUT_TIMES(I)%TTH = OUT_TIMES(1)%TTH
        END IF
!C
!C      Test time control flag for Subroutine UNIT1 (VIEW) output,
!C       which is allowed only for the first time window.
!C
        IF ( I .EQ. I_1 )  THEN
         IF ( ( AV .EQ. 'F' ) .OR. ( AV .EQ. 'f' ) )  THEN
          OUT_TIMES(I)%VIEW = FALSE
         ELSE IF ( ( AV .EQ. 'T' ) .OR. ( AV .EQ. 't' ) )  THEN
          OUT_TIMES(I)%VIEW = TRUE
         ELSE
          WRITE ( LUAOU, 190 ) AV
  190     FORMAT ( 1X, ' Invalid value for VIEW time control ', 
     &             A1, '.' )
           STOP ' Stop 3009 in Subroutine INPUT_ACARDS '
         END IF 
        ELSE
         IF ( AV .NE. ' ' )  THEN
          WRITE ( LUAOU, 195 )  I
  195     FORMAT ( 1X, ' Warning - time window ', I2, ' control',
     &             ' flag for VIEW output ignored. ' )
         END IF
         OUT_TIMES(I)%VIEW = OUT_TIMES(1)%VIEW
        END IF
!C
!C      Check the time control flag for a proper starting time.
!C
        IF ( ( TS .LT. D_0 ) .OR. 
     &       ( TS .GE. ( REAL ( NSTEPS, IREAL_HIGH ) * DT ) ) ) THEN
         WRITE ( LUAOU, 200 ) I 
  200    FORMAT ( 1X, ' Invalid output start time supplied',
     &            ' for time control ', I1, '.' )
         STOP ' Stop 3004 in Subroutine INPUT_ACARDS ' 
        ELSE
         OUT_TIMES(I)%START = TS
        END IF
!C
!C      Check the time control flag for a proper ending time.
!C
        IF ( ( TE .LT. D_0 ) .OR. 
     &       ( TE .GT. ( REAL( NSTEPS, IREAL_HIGH ) * DT ) ) .OR.
     &       ( ( TE .LE. TS ) .AND. ( TE .NE. D_0 ) )  )  THEN
         WRITE ( LUAOU, 205 )  I
  205    FORMAT ( 1X, ' Invalid output end time supplied',
     &            ' for time control ', I1, '.' )
         STOP ' Stop 3005 in Subroutine INPUT_ACARDS '
        ELSE IF ( TE .EQ. D_0 )  THEN
         OUT_TIMES(I)%END = REAL ( NSTEPS, IREAL_HIGH ) * DT
        ELSE
         OUT_TIMES(I)%END = TE
        END IF
       END DO
      END IF

!C
!C    Echo the time windowing parameters.
!C
      IF ( NUM_OUT_TIMES .GT. I_0 ) THEN
       WRITE ( LUAOU, 210 )  
  210  FORMAT ( 1X, 'Time Window', 2X, 'Print', 2X, ' TTH', 2X, 
     &          'VIEW', 4X, 'Start(sec)', 8X, 'End(sec)' )
       WRITE ( LUAOU, 215 )  ( I, OUT_TIMES(I)%PRINT, OUT_TIMES(I)%TTH,
     &                            OUT_TIMES(I)%VIEW,
     &                            OUT_TIMES(I)%START, OUT_TIMES(I)%END,
     &                            I=1,NUM_OUT_TIMES )
  215  FORMAT ( 4X, I2, 9X, L2, 5X, L2, 4X, L2, 4X, F10.3, 6X, F10.3 )
       WRITE ( LUAOU, 220 )
  220  FORMAT ( 1X, / )
      END IF
!C                                                                      
!C    Unit 8 POSTPR output                                              
!C
      IF ( NPRT(4) .NE. I_0 )  THEN                               
!C
!C     Concatenate filename with extension                              
!C
       TP8FIL = FNAME ( WORK_DIRECTORY, OUTFIL, TP8 )                   
       OPEN ( LUTP8, FILE = TP8FIL, STATUS = 'UNKNOWN', ERR = 30,
     &        ACCESS = 'SEQUENTIAL', FORM = 'UNFORMATTED' )             
      END IF                                                            
!C                                                                      
!C    Return if NRPT is negative, meaning that this run is only
!C     a postprocessing run, where Tape 8 is read, but not written
!C     to.
!C
      IF ( NPRT(4) .LT. I_0 )   RETURN                               
!C                                                                      
!C    Open needed output files                                          
!C                                                                      
!C    UNIT 1 output for VIEW program                                    
!C
      IF ( NPRT(1) .NE. I_0 )  THEN                                 
!C
!C     Concatenate filename with extension.                             
!C
       IF ( NPRT(35) .EQ. I_0 )  THEN
        TP1FIL = FNAME ( WORK_DIRECTORY, OUTFIL, SA1 )                  
        OPEN ( LUVIEW, FILE = TP1FIL, STATUS = 'UNKNOWN', ERR = 35,
     &         ACCESS = 'SEQUENTIAL', FORM = 'FORMATTED' )              
       ELSE IF ( NPRT(35) .EQ. I_1 )  THEN                            
        TP1FIL = FNAME ( WORK_DIRECTORY, OUTFIL, UF1 )                 
        OPEN ( LUVIEW, FILE = TP1FIL, STATUS = 'UNKNOWN', ERR = 40,
     &         ACCESS = 'SEQUENTIAL', FORM = 'UNFORMATTED' )            
       ELSE IF ( NPRT(35) .EQ. I_2 )  THEN                           
        TP1FIL = FNAME ( WORK_DIRECTORY, OUTFIL, TP1 )                 
        OPEN ( LUVIEW, FILE = TP1FIL, STATUS = 'UNKNOWN', ERR = 45, 
     &         ACCESS = 'SEQUENTIAL', FORM = 'FORMATTED' )              
       ELSE                                                             
        TP1FIL = FNAME ( WORK_DIRECTORY, OUTFIL, SA1 )                  
        OPEN ( LUVIEW, FILE = TP1FIL, STATUS = 'UNKNOWN', ERR = 50, 
     &         ACCESS = 'SEQUENTIAL',FORM = 'FORMATTED' )               
       END IF
      END IF                                                            
!C
      RETURN
!C
!C
!C    Error messages related to file handling.
!C
   30 WRITE ( LUTERM_OUT, 330 ) TP8FIL
  330 FORMAT ( 1X, ' Error opening file: ', A116 )
      STOP ' STOP 3010 in Subroutine INPUT_ACARDS. '
!C
   35 WRITE ( LUTERM_OUT, 335 ) TP1FIL
  335 FORMAT ( 1X, ' Error opening file: ', A116 )
      STOP ' STOP 3012 in Subroutine INPUT_ACARDS. '
!C
   40 WRITE ( LUTERM_OUT, 340 ) TP1FIL
  340 FORMAT ( 1X, ' Error opening file: ', A116 )
      STOP ' STOP 3013 in Subroutine INPUT_ACARDS. '
!C
   45 WRITE ( LUTERM_OUT, 345 ) TP1FIL
  345 FORMAT ( 1X, ' Error opening file: ', A116 )
      STOP ' STOP 3015 in Subroutine INPUT_ACARDS. '
!C
   50 WRITE ( LUTERM_OUT, 350 ) TP1FIL
  350 FORMAT ( 1X, ' Error opening file: ', A116 )
      STOP ' STOP 3016 in Subroutine INPUT_ACARDS. '
!C      
      END
      