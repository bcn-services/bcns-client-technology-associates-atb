      SUBROUTINE FMODV0 ( VAR_LCL, NEQ_LCL )                            
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Transfers initial modal conditions to the state variable vector.      
!C    Called by PDAUX.                                                      
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, I_0, I_1   ! parameters  
!C
      USE  MODULE_FLEXIBLE,  ONLY:  NEQP,                  ! /FXINT/
     &                              AMP, AMV, NFBOD, NMOD  ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, NEQ_LCL 
!C
      REAL  ( KIND = IREAL_HIGH )  VAR_LCL
      DIMENSION VAR_LCL(1)                                              
!C
      INTENT (   OUT )  VAR_LCL
      INTENT ( INOUT )  NEQ_LCL
!C
      NEQP = NEQ_LCL
      IF ( NFBOD .EQ. I_0 )   RETURN
!C
      DO  I=1,NFBOD
       DO  J=1,NMOD(I)
        NEQ_LCL          = NEQ_LCL + I_1
        VAR_LCL(NEQ_LCL) = AMP(J,I)
       END DO
      END DO
!C
      DO  I=1,NFBOD
       DO  J=1,NMOD(I)
        NEQ_LCL          = NEQ_LCL + I_1
        VAR_LCL(NEQ_LCL) = AMV(J,I)
       END DO
      END DO
!C
      RETURN
      END
      