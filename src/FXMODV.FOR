      SUBROUTINE FXMODV ( VAR_LCL, N )                                  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Transfers updated state variable vector to modal pos. & vel.         
!C    Called by PDAUX.                                                      
!C  
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, I_0, I_1, I_3      ! parameters  
!C
      USE  MODULE_FLEXIBLE,  ONLY:   AMP, AMV, NFBOD, NMOD   ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, N, NEQ_LCL
!C
      REAL  ( KIND = IREAL_HIGH )  VAR_LCL
      DIMENSION         VAR_LCL(1)                                      
!C
      INTENT ( IN )  N, VAR_LCL
!C
      IF ( NFBOD .EQ. I_0 )  RETURN
!C
      NEQ_LCL = I_3 * N
      DO  I=1,NFBOD
       DO  J=1,NMOD(I)
        NEQ_LCL = NEQ_LCL + I_1
        AMP(J,I) = VAR_LCL(NEQ_LCL)
       END DO
      END DO
!C
      DO  I=1,NFBOD
       DO  J=1,NMOD(I)
        NEQ_LCL = NEQ_LCL + I_1
        AMV(J,I) = VAR_LCL(NEQ_LCL)
       END DO
      END DO
!C
      RETURN
      END
      