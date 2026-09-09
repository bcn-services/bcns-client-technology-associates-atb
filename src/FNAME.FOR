      CHARACTER ( LEN = 116, KIND = ICHAR_STD) 
     &                 FUNCTION FNAME ( DIR_IN, FILENM_IN, EXT_IN )                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                      
!C    Concatenates the prefix DIR_IN and the extension, EXT_IN, 
!C     to the filename, FILENM_IN.                  
!C                                                                      
      USE  MODULE_STANDARD,  ONLY: 
     &       ICHAR_STD, INTEGER_STD ! parameters
!C
      INTEGER  ( KIND = INTEGER_STD )  LEN_DIR_IN, LEN_FILENM_IN,
     &                                 LEN_EXT_IN, TOTAL_LENGTH
!C
      CHARACTER ( LEN =   4, KIND = ICHAR_STD )  EXT_IN                     
      CHARACTER ( LEN =   4, KIND = ICHAR_STD )  EXT_IN_LEFT                     
      CHARACTER ( LEN =  32, KIND = ICHAR_STD )  FILENM_IN                   
      CHARACTER ( LEN =  32, KIND = ICHAR_STD )  FILENM_IN_LEFT                   
      CHARACTER ( LEN =  80, KIND = ICHAR_STD )  DIR_IN
      CHARACTER ( LEN =  80, KIND = ICHAR_STD )  DIR_IN_LEFT
      CHARACTER ( LEN = 116, KIND = ICHAR_STD )  BLANK116
!C
      INTENT  ( IN )  DIR_IN, FILENM_IN, EXT_IN
!C
!C    Initialize BLANK116 to all blanks.
!C
      BLANK116 = ICHAR_STD_' '
!C
      DIR_IN_LEFT = ADJUSTL ( DIR_IN )
      LEN_DIR_IN = LEN_TRIM ( DIR_IN_LEFT )
!C
      FILENM_IN_LEFT = ADJUSTL ( FILENM_IN )
      LEN_FILENM_IN = LEN_TRIM ( FILENM_IN_LEFT )
!C
      EXT_IN_LEFT = ADJUSTL ( EXT_IN )
      LEN_EXT_IN = LEN_TRIM ( EXT_IN_LEFT )
!C
!C    Compute total length of filename.
!C
      TOTAL_LENGTH = LEN_DIR_IN + LEN_FILENM_IN + LEN_EXT_IN
!C
!C    Concatenate strings to create full filename, including trailing
!C     blanks to maintain a constant length name.
!C
      IF ( EXT_IN_LEFT(1:1) .EQ. '.' ) THEN
       FNAME =     DIR_IN_LEFT(1:LEN_DIR_IN) // '/' 
     &             // FILENM_IN_LEFT(1:LEN_FILENM_IN) 
     &             // EXT_IN_LEFT(1:LEN_EXT_IN) 
     &             // BLANK116(1:116-TOTAL_LENGTH)
      ELSE
       FNAME =     DIR_IN_LEFT(1:LEN_DIR_IN) // '/' 
     &             // FILENM_IN_LEFT(1:LEN_FILENM_IN) // '.' 
     &             // EXT_IN_LEFT(1:LEN_EXT_IN) 
     &             // BLANK116(1:116-TOTAL_LENGTH-1)
      END IF
!C
      RETURN                                                            
      END                                                               
