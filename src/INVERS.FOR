      SUBROUTINE INVERS ( A, B_LCL, W_LCL, I_ORDER, N, ND )             
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine finds invers of an NxN matrix A: A^-1 = B_LCL     
!C    Contents of matrix A are saved                                    
!C    Calls LUDCMP, LUSUB                                               
!C    Called by FXMASS                                                  
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH, D_0, D_1  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, I_ORDER, J, N, ND            
      DIMENSION  I_ORDER(ND)
!C
      REAL  ( KIND = IREAL_HIGH )   A, B_LCL, W_LCL, AA 
      DIMENSION  A(ND,ND), B_LCL(ND,ND), W_LCL(ND,ND), AA(ND,ND)        
!C
!C    Check to ensure 
!C
      DO  I=1,N
       DO  J=1,N
        W_LCL(I,J) = D_0
        AA(I,J) = A(I,J)
       END DO
       W_LCL(I,I)= D_1
      END DO
!C
      CALL LUDCMP ( A, N, I_ORDER, ND )
      CALL LUSUB ( A, W_LCL, B_LCL, N, N, I_ORDER, ND, ND )
!C
      DO  I=1,N
       DO  J=1,N
        A(I,J) = AA(I,J)
       END DO
      END DO
!C
      RETURN
      END
