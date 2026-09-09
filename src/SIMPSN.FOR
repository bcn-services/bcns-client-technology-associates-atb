      FUNCTION SIMPSN ( F_LCL, N, A, B_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Evaluates integrals using Simpson's rule.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH,   ! parameters 
     &        I_2, D_0, D_2, D_4, D_6    ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, M, N
!C
      REAL  ( KIND = IREAL_HIGH )   SIMPSN
      REAL  ( KIND = IREAL_HIGH )   A, B_LCL, DEL, F_LCL, S
      DIMENSION F_LCL(1)
!C
      INTENT ( IN )  F_LCL, N, A, B_LCL
!C 
      IF ( N .LT. I_2 ) THEN
       SIMPSN = D_0
       RETURN
      END IF
      M = N / I_2
      DEL = ( B_LCL - A ) / REAL ( M, IREAL_HIGH )
      S = F_LCL(1)
      DO  I = 1,M-1
       S = S + D_4 * F_LCL(2*I) + D_2 * F_LCL(2*I+1)
      END DO
      S = S + D_4 * F_LCL(2*M) + F_LCL(2*M+1)
      SIMPSN = DEL * S / D_6
!C
      RETURN
      END
