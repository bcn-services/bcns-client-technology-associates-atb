      FUNCTION  NUMCHR ( N, CHRN )
!C
!C                                                   Rev. V.3 12/15/2002 
!C    This function returns an integer value of "1"
!C     if the input argument is < 10 and an integer
!C     value of "2" if the input argument, N, is
!C     >= 10.
!C
!C    It also returns N in CHARACTER format via the 
!C     CHARACTER variable CHRN.
!C
      USE  MODULE_STANDARD,   ONLY: 
     &       ICHAR_STD, INTEGER_STD, I_1, I_2, I_10     ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  NUMCHR
      INTEGER  ( KIND = INTEGER_STD )  N, NC 
!C
      CHARACTER ( LEN = *, KIND = ICHAR_STD )  CHRN
!C
      INTENT ( IN )   N
      INTENT ( OUT )  CHRN
!C
      IF ( N .LT. I_10 )  THEN
       WRITE ( CHRN, 101 )  N
  101  FORMAT ( I1 )
       NC = I_1
      ELSE
       WRITE ( CHRN, 102 )  N
  102  FORMAT ( I2 )
       NC = I_2
      END IF
!C
      NUMCHR = NC
!C
      RETURN
      END
