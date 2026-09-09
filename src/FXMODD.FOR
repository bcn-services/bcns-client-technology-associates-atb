      SUBROUTINE FXMODD ( DER_LCL, N )                                  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Transfers modal vel. & acc. to derivative of state variable vector    
!C     called by PDAUX.                                                       
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, I_0, I_1, I_3   ! parameters  
!C
      USE MODULE_FLEXIBLE,  ONLY: AMA, AMV, NFBOD, NMOD ! /FXMOD/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, N, NEQ_LCL
!C
      REAL  ( KIND = IREAL_HIGH )   DER_LCL
      DIMENSION  DER_LCL(1)                                             
!C
      INTENT (  IN )  N
      INTENT ( OUT )  DER_LCL
!C
      IF ( NFBOD .EQ. I_0 ) RETURN
!C
      NEQ_LCL = I_3 * N
      DO  I=1,NFBOD
       DO  J=1,NMOD(I)
        NEQ_LCL = NEQ_LCL + I_1
        DER_LCL(NEQ_LCL) = AMV(J,I)
       END DO
      END DO
      DO  I=1,NFBOD
       DO  J=1,NMOD(I)
        NEQ_LCL = NEQ_LCL + I_1
        DER_LCL(NEQ_LCL) = AMA(J,I)
       END DO
      END DO
!C
      RETURN
      END
      