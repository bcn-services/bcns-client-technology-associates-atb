      SUBROUTINE ORTHO ( P, X, L )                                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Generates a set of right handed orthonormal vectors (P),             
!C    given one of the vectors (X), where                                  
!C         P - L X 3 matrix of 3 orthonormal vectors to be generated.        
!C         X - given vector.                                               
!C         L - 1st subscript of P in calling program.                      
!C                                                                         
      USE  MODULE_STANDARD,   ONLY: 
     &       INTEGER_STD, IREAL_HIGH,     ! parameters 
     &       D_0, D_1, I_2, I_3           ! parameters
!C
      IMPLICIT  NONE                                                      
!C
      INTEGER   ( KIND = INTEGER_STD )  I, L, M, N
!C
      REAL  ( KIND = IREAL_HIGH )    P, X, TEST, D_LCL
      DIMENSION         P(L,3), X(3)                                      
!C
      INTENT (  IN )  L, X 
      INTENT ( OUT )  P
!C
      M = I_2                                                            
      N = I_3                                                         
      TEST = D_0                                                       
      DO  I=1,3                                                            
       P(I,3) = X(I)                                                       
       D_LCL = D_1 - X(I)**2                                              
       IF ( D_LCL .GT. TEST )   THEN                                       
        TEST = D_LCL                                                       
        D_LCL = SQRT ( D_LCL )                                             
        P(I,1) = D_LCL                                                     
        P(I,2) = D_0                                              
        P(M,2) =  X(N) / D_LCL                                            
        P(N,2) = -X(M) / D_LCL                                             
        P(M,1) =  X(I) * P(N,2)                                            
        P(N,1) = -X(I) * P(M,2)                                            
       END IF
       M = N                                                               
       N = I                                                               
      END DO                                                               
!C
      RETURN                                                             
      END                                                                
