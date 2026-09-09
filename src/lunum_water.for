       SUBROUTINE LUNUM_WATER ( LNEW, MT, NT, IT, XPAGE )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine sets up the output unit counter and output 
!C     unit number.
!C
!C    This subroutine is called only by Subroutine HEDING_WATER.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       NPG,                                      ! /CONTRL/
     &       BDYTTL, COMENT, DATE, VPSTTL,             ! /TITLES/
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,       ! parameters
     &       LOGICAL_STD, LUAOU, NUM_TTH_OFFSET, I_1   ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  IT, MT, NT
!C
      REAL  ( KIND = IREAL_HIGH )  PAGE, XPAGE
!C
      LOGICAL  ( KIND = LOGICAL_STD )   LNEW
!C
      CHARACTER ( LEN = 4, KIND = ICHAR_STD )  BLANK
!C
      DATA     BLANK / ICHAR_STD_'    ' /    
!C
      INTENT (    IN )  LNEW, XPAGE
      INTENT (   OUT )  IT, NT
      INTENT ( INOUT )  MT
!C
      MT = MT + I_1
      NT = MT
      IF ( LNEW )  NT = LUAOU 
      IT   = MT - NUM_TTH_OFFSET
      PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE
      WRITE ( NT, 100 )
  100 FORMAT ( 1X, /, 1X )                              
      IF ( NT .EQ. LUAOU ) THEN
       WRITE ( NT, 105 )  DATE, BLANK, NPG
  105  FORMAT ( '1', 18X, 'Date:', 3X, A12, A4, 80X, 'Page', I5 )                   
       NPG = NPG + I_1
      ELSE
       WRITE ( NT, 105 )  DATE
      END IF
      WRITE ( NT, 110 )  COMENT(1:80), COMENT(81:160), PAGE, 
     &                   VPSTTL, BDYTTL
  110 FORMAT ( 8X, 'Run Description:', 3X, A80, /, 27X, A80,
     &         'Page:', F6.2, /, 3X, 'Vehicle Deceleration:',
     &         3X, A80, /, 11X, 'Test Subject:', 3X, A20 ) 
!C
      RETURN
      END
