      SUBROUTINE FDUX11 ( M1, M2, MB, CT, VT )                          
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes C11 & V1* coefficients for a deformable body               
!C    Called by DAUX11.                                                    
!C    Calls MULPLY, MAT33, MAT31.                                          
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       A11, B12,                       ! /CMATRX/
     &       SEG,                            ! structures
     &       INTEGER_STD, IREAL_HIGH, MXMOD, ! parameters
     &       I_0, I_1, I_3                   ! parameters
!C
!C    SINGULAR    ! SEG%
!C
      USE  MODULE_FLEXIBLE,  
     &        ONLY:  A11F, A11P, A21P, AA1P, B1A, ! /FXCOEF/
     &               PHPI, U1P, U2P, UAP, WPI,    ! /FXCOEF/
     &               IBODN, NMOD                  ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  K, M1, M2, MB
!C
      REAL  ( KIND = IREAL_HIGH  )
     &           TM1, TM2, TM3, TM4, CT, VT, T1, T2_LCL
      DIMENSION  TM1(3,3), TM2(3,3), TM3(3,3), TM4(3,3), CT(3,3),       
     &           VT(3), T1(3), T2_LCL(3)                                
!C
      K = NMOD(MB)
      CALL MULPLY ( B1A(1,1,M1), AA1P(1,1,M2), CT, I_3, K, 
     &              I_3, I_3, MXMOD, I_3 )
      CALL MULPLY ( B1A(1,1,M1), UAP(1,MB),    VT, I_3, K, 
     &              I_1, I_3, MXMOD, I_1 )
      IF ( SEG(IBODN(MB))%SINGULAR .LT. I_0 )   RETURN
      CALL MAT33 ( A11F(1,1,M1), WPI(1,1,MB),  TM1    )
      CALL MAT33 ( B12(1,1,M1),  PHPI(1,1,MB), TM2    )
      CALL MAT33 ( TM1,          A11P(1,1,M2), TM3    )
      CALL MAT33 ( TM2,          A21P(1,1,M2), TM4    )
      CALL MAT31 ( TM1,          U1P(1,MB),    T1     )
      CALL MAT31 ( TM2,          U2P(1,MB),    T2_LCL )
      VT = T1 + T2_LCL + VT
      CT = TM3 + TM4 + CT
!C
      RETURN
      END
      