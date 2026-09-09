      SUBROUTINE LUSUB ( R_LU, B_LCL, X, N, M, I_ORDER, ND, MD )        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C   This subroutine solves a set of linear simultaneous equations      
!C    through backward and forward substitution.  The coefficient matrix 
!C    R_LU has already been decomposed into L and U BY Subroutine LUDCMP.
!C    It is called by Subroutine INVERS.                                                   
!C
      USE  MODULE_STANDARD,   ONLY: 
     &       INTEGER_STD, IREAL_HIGH, D_0, I_1    ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &             N, M, ND, MD, I_ORDER, I, J, L, IM1, NP1, NVBL,
     &             IROW, JCOL                                          
      DIMENSION  I_ORDER(ND)
!C
      REAL  ( KIND = IREAL_HIGH )   R_LU, B_LCL, X, SUM
      DIMENSION         R_LU(ND,ND), B_LCL(ND,MD), X(ND,MD)           
!C
      DO  L=1,M
       DO  I=1,N
        J = I_ORDER(I)
        X(I,L) = B_LCL(J,L)
       END DO
       X(1,L) = X(1,L) / R_LU(1,1)
!C
       DO  IROW=2,N
        IM1 = IROW - I_1
        SUM = D_0
        DO  JCOL=1,IM1
         SUM = SUM + R_LU(IROW,JCOL) * X(JCOL,L)
        END DO
        X(IROW,L) = ( X(IROW,L) - SUM ) / R_LU(IROW,IROW)
       END DO
!C
       DO  IROW=2,N
        NVBL = N - IROW + I_1
        SUM = D_0
        NP1 = NVBL + I_1
        DO  JCOL=NP1,N
         SUM = SUM + R_LU(NVBL,JCOL) * X(JCOL,L)
        END DO
        X(NVBL,L) = X(NVBL,L) - SUM
       END DO
!C
      END DO
!C
      RETURN
      END
