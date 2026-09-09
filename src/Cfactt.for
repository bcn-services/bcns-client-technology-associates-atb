      SUBROUTINE CFACTT ( A, B_LCL, D_LCL )                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C      Given 3X3 matrix A:                                             
!C       compute B transpose of cofactors (signed minors)                 
!C       and D the value of the determinant of A.                       
!C       inverse of A is B(J,K)/D. Also, set the value of the
!C       elements of A to 0 if below a certain threshold                                    
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                 ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH,             ! parameters 
     &       D_0, I_1, I_2, I_3, I_4              ! parameters
!C
      IMPLICIT  NONE
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD ) I, J, K, KK, L, M, N
!C
      REAL  ( KIND = IREAL_HIGH )  A, B_LCL, D_LCL
      DIMENSION                    A(3,3), B_LCL(3,3)                                
!C
      INTENT ( INOUT ) A
      INTENT ( OUT   ) B_LCL, D_LCL
!C
      M = I_4                                                        
      L = I_2                                                        
      N = I_3                                                       
      D_LCL = D_0                                                  
!C
!C    Zero any elements of the direction cosine matrix that are
!C     smaller than a specified value.
!C
      DO  I=1,3                                                          
       DO  J=1,3                                                          
        IF ( ABS ( A(I,J) ) .LT. EPS(24) )  A(I,J) = D_0                       
       END DO                                                            
      END DO
      DO  J=1,3                                                          
       B_LCL(J,J) = A(L,L) * A(N,N) - A(L,N) * A(N,L)                 
       IF ( J .NE. I_3 )  THEN                                              
        L = N                                                            
        N = J                                                            
        KK = J + I_1                                                    
        DO  K=KK,3                                                   
         M = M - I_1                                                        
         B_LCL(K,J) = A(K,M) * A(M,J) - A(K,J) * A(M,M)                   
         B_LCL(J,K) = A(J,M) * A(M,K) - A(J,K) * A(M,M)               
        END DO
       END IF
       D_LCL = D_LCL + A(1,J) * B_LCL(J,1)                           
      END DO
!C
      RETURN                                                             
      END                                                                 
