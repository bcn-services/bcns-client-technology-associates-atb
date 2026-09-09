      SUBROUTINE MULPLY ( A, B_LCL, C_LCL, N, L, M, ND, LD, MD )         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine multiplies matrices C(N,M) = A(N,L) * B(L,M)          
!C     called by FDUX11, FDUX12, FDUX22, FXMACC, FXMASS.                  
!C
      USE  MODULE_STANDARD,   ONLY: 
     &       INTEGER_STD, IREAL_HIGH, D_0    ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                 N, L, M, ND, LD, MD, I, J, K                   
!C
      REAL  ( KIND = IREAL_HIGH )  A, B_LCL, C_LCL
      DIMENSION         A(ND,LD), B_LCL(LD,MD), C_LCL(ND,MD)   
!C
      INTENT (  IN )  A, B_LCL, N, L, M, ND, LD, MD
      INTENT ( OUT )  C_LCL
!C
      DO  I=1,N
       DO  J=1,M
        C_LCL(I,J) = D_0
        DO  K=1,L
         C_LCL(I,J) = C_LCL(I,J) + A(I,K) * B_LCL(K,J)
        END DO
       END DO
      END DO
!C
      RETURN
      END
