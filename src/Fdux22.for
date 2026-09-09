      SUBROUTINE FDUX22 ( M1, M2, MB, CT, VT )                          
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes C22 & V2* coefficients for a deformable body.                 
!C    Called by DAUX22.                                                      
!C    Calls MULPLY, MAT33, MAT31, DOT33.                                     
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        SEG,                             ! structures
     &        INTEGER_STD, IREAL_HIGH, MXMOD,  ! parameters
     &        I_0, I_1, I_3                    ! parameters
!C
!C    SINGULAR    ! SEG%
!C
      USE  MODULE_FLEXIBLE,  
     &        ONLY:  A22F, A22P, AA2P, B2A, PHPI, U2P, UAP,  ! /FXCOEF/
     &               IBODN, NMOD                             ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  K, M1, M2, MB
!C
      REAL  ( KIND = IREAL_HIGH )  TM1, TM2, CT, T1, VT
      DIMENSION         TM1(3,3), TM2(3,3), CT(3,3), T1(3), VT(3)      
!C
      K = NMOD(MB)
      CALL MULPLY ( B2A(1,1,M1), AA2P(1,1,M2), CT, I_3, 
     &              K, I_3, I_3, MXMOD, I_3 )
      CALL MULPLY ( B2A(1,1,M1), UAP(1,MB),    VT, I_3, 
     &              K, I_1, I_3, MXMOD, I_1)
      IF ( SEG(IBODN(MB))%SINGULAR .LT. I_0 )  RETURN
      CALL DOT33 ( A22F(1,1,M1),PHPI(1,1,MB), TM2 )
      CALL MAT33 ( TM2,         A22P(1,1,M2), TM1 )
      CALL MAT31 ( TM2,         U2P(1,MB),    T1 )
      VT = T1 + VT
      CT = TM1 + CT
!C
      RETURN
      END
