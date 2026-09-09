      FUNCTION  CHECK_HIGH_VALUE ( HIGH_VALUE )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This function checks the value of the high precision value passed
!C     to it.  If it is smaller than or equal to the smallest single 
!C     precision value, the function returns a value of single precision 0.  
!C     If it greater than the smallest allowable single precision value,
!C     the function returns the single precision equivalent of the passed
!C     double precision value.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       IREAL_STD, IREAL_HIGH, R_0              ! parameters
!C                                                                      
      IMPLICIT  NONE                                                      
!C
      REAL  ( KIND = IREAL_STD )   CHECK_HIGH_VALUE, SINGLE_PREC
      REAL  ( KIND = IREAL_HIGH )  HIGH_VALUE, SMALLEST_SNGLE 
!C
      INTENT (  IN )  HIGH_VALUE
!C
!C    Get the smallest allowable value for a single precision
!C     number.
!C
      SMALLEST_SNGLE = TINY ( SINGLE_PREC )
!C
!C    Set the value of CHECK_HIGH_VALUE
!C
      IF ( ABS ( HIGH_VALUE ) .LE. SMALLEST_SNGLE )  THEN
       CHECK_HIGH_VALUE = R_0
      ELSE
       CHECK_HIGH_VALUE =  REAL ( HIGH_VALUE, IREAL_STD )
      END IF
!C
      RETURN
      END

