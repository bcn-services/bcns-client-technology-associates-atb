      FUNCTION  L_LTIME( N )                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This function returns the number of 0.01 seconds of CPU time that
!C     occurs from when it was first called, N = 0, to when it is 
!C     next called, N = 1.  
!C
!C     It uses the f95 standard intrinsic call, CALL CPU_TIME.
!C                                                                      
!C                                                                      
      USE  MODULE_STANDARD,   ONLY: 
     &       INTEGER_STD, IREAL_STD, I_0, I_1, I_100    ! parameters
!C
      IMPLICIT  NONE
!C
      INTENT ( IN )  N
!C
      SAVE  START_TIME
!C
      INTEGER  ( KIND = INTEGER_STD )  L_LTIME
      INTEGER  ( KIND = INTEGER_STD )  N
!C
      REAL  ( KIND = IREAL_STD )
     &            REMAINDER,  DIF_TIME, END_TIME, START_TIME, TIME_CPU
!C
      IF ( N .EQ. I_0 )  THEN
       CALL CPU_TIME ( TIME_CPU )
       START_TIME = TIME_CPU
       L_LTIME = I_0
       RETURN
      ELSE IF ( N .EQ. I_1 )  THEN
       CALL CPU_TIME ( TIME_CPU )
       END_TIME = TIME_CPU
!C
!C    For N .NE. 0, and N .NE. 1  
!C
      ELSE
       CONTINUE
      END IF
!C
!C    Get the elapsed CPU time in seconds.
!C
      DIF_TIME = END_TIME - START_TIME
!C
!C    Convert the elapsed CPU time from seconds to number of
!C     0.01 seconds.   
!C
      REMAINDER = I_100 * ( DIF_TIME - AINT ( DIF_TIME ) )
      L_LTIME = I_100 * INT ( DIF_TIME ) + NINT( REMAINDER ) 
!C
      RETURN                                                            
      END                                                               
