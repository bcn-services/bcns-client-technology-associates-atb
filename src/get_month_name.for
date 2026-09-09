      SUBROUTINE  GET_MONTH_NAME ( NUMBER_OF_MONTH, NAME_OF_MONTH )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine receives the month by number and 
!C     returns the month by name.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        ICHAR_STD, INTEGER_STD,         ! parameters  
     &        I_1, I_2, I_3, I_4, I_5, I_6,   ! parameters
     &        I_7, I_8, I_9, I_10, I_11       ! parameters
!C
      IMPLICIT NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  NUMBER_OF_MONTH
!C
      CHARACTER ( LEN = 4, KIND = ICHAR_STD ) NAME_OF_MONTH
!C
      INTENT  ( IN  )  NUMBER_OF_MONTH
      INTENT  ( OUT )  NAME_OF_MONTH
!C
      IF      ( NUMBER_OF_MONTH .EQ.  I_1 )  THEN
       NAME_OF_MONTH = 'Jan.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_2 )  THEN
       NAME_OF_MONTH = 'Feb.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_3 )  THEN
       NAME_OF_MONTH = 'Mar.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_4 )  THEN
       NAME_OF_MONTH = 'Apr.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_5 )  THEN
       NAME_OF_MONTH = 'May.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_6 )  THEN
       NAME_OF_MONTH = 'Jun.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_7 )  THEN
       NAME_OF_MONTH = 'Jul.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_8 )  THEN
       NAME_OF_MONTH = 'Aug.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_9  )  THEN
       NAME_OF_MONTH = 'Sep.' 
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_10 )  THEN
       NAME_OF_MONTH = 'Oct.'
      ELSE IF ( NUMBER_OF_MONTH .EQ.  I_11 )  THEN
       NAME_OF_MONTH = 'Nov.'
      ELSE
       NAME_OF_MONTH = 'Dec.'
      END IF
!C
      RETURN
      END
