      SUBROUTINE FDUX12 ( M1, M2, MB, CT, CTT )                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes C12 & C21 coefficients for a deformable body                 
!C     called by DAUX12                                                      
!C     calls MULPLY, MAT33, DOT33                                            
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        A22, B12,                        ! /CMATRX/
     &        SEG,                             ! structures
     &        INTEGER_STD, IREAL_HIGH, MXMOD,  ! parameters
     &        I_0, I_3                         ! parameters
!C
!C    SINGULAR    ! SEG%
!C
      USE  MODULE_FLEXIBLE,  
     &       ONLY:  A11F, A12P, A21P, A22F, A22P,    ! /FXCOEF/
     &              AA1P, AA2P, B1A, B2A, PHPI, WPI, ! /FXCOEF/
     &              IBODN, NMOD                      ! /FXVAR/
!C
      IMPLICIT  NONE     
!C      
      INTEGER   ( KIND = INTEGER_STD )  K, M1, M2, MB
!C
      REAL  ( KIND = IREAL_HIGH )   TM1, TM2, TM3, TM4, CT, CTT
      DIMENSION         TM1(3,3), TM2(3,3), TM3(3,3), TM4(3,3),        
     &                  CT(3,3), CTT(3,3)                               
!C
      K = NMOD(MB)
      CALL MULPLY ( B1A(1,1,M1), AA2P(1,1,M2), CT, I_3, 
     &              K, I_3, I_3, MXMOD, I_3 )
      CALL MULPLY ( B2A(1,1,M2), AA1P(1,1,M1), CTT,I_3, 
     &              K, I_3, I_3, MXMOD, I_3 )
      IF ( SEG(IBODN(MB))%SINGULAR .LT. I_0 )  RETURN
!C
!C.....C12
!C
      CALL MAT33 ( A11F(1,1,M1), WPI(1,1,MB), TM3 )
      CALL MAT33 ( TM3, A12P(1,1,M2), TM1 )
      CALL MAT33 ( B12(1,1,M1), PHPI(1,1,MB), TM3 )
      CALL MAT33 ( TM3, A22P(1,1,M2), TM2 )
!C
!C.....C21
!C
      CALL DOT33 ( A22F(1,1,M2), PHPI(1,1,MB), TM3 )
      CALL MAT33 ( TM3, A21P(1,1,M1), TM4 )
      CT  = TM1 + TM2 + CT
      CTT = TM4 + CTT
!C
      RETURN
      END
      