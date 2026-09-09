      SUBROUTINE DSMSOL ( A, KK )                                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Solves a set of simultaneous linear equations AX=B.                 
!C                                                                        
!C      Arguments:                                                        
!C        A: 2-dimensional(KK,KK+1) matrix of coefficients.               
!C        KK: number of equations and unknowns.                           
!C        LL: 1st dimension of A in calling program.                      
!C                                                                        
!C      Calling program setup:                                            
!C        A(I,J) for I,J=1,KK                                             
!C        A(I,KK+1) = B(I) for I=1,KK                                     
!C        The solution X is returned in column KK+1 of A.                 
!C        Matrix A is destroyed by subroutine.                            
!C
      USE  MODULE_STANDARD, ONLY:  
     &        INTEGER_STD, IREAL_HIGH, LUAOU, ! parameters
     &        LUTERM_OUT, D_0, D_1, I_1       ! parameters
!C 
      IMPLICIT  NONE
!C
!C    Local Variables.
!C
      INTEGER  ( KIND =INTEGER_STD )  I, J, K, KK, L, L1, N, N1, N2
!C
      REAL  ( KIND = IREAL_HIGH )   A, B_LCL, BIG
      DIMENSION A(KK,KK+1)                                                 
!C
      INTENT (    IN )   KK
      INTENT ( INOUT )   A 
!C
      N  = KK                                                             
      N1 = N + I_1                                                    
      DO   L=1,N                                                        
       L1 = L + I_1                                                      
       BIG = D_0                                                       
!C
       DO  I=L,N                                                          
        IF ( ABS ( A(I,L) ) .GT. ABS ( BIG ) )  THEN                      
         K= I                                                             
         BIG = A(I,L)                                                     
        END IF                                                            
       END DO
!C
       IF ( BIG .EQ. D_0 )  THEN                                        
        WRITE ( LUAOU, 100 )                                               
        WRITE ( LUTERM_OUT, 100 )
  100   FORMAT ('0 DSMSOL matrix singular, program terminated.')          
        STOP  41                                                          
       END IF
!C
       BIG = D_1 / BIG                                                   
       DO  J=L,N1                                                         
        B_LCL  = A(K,J)                                                   
        A(K,J) = A(L,J)                                                   
        A(L,J) = B_LCL * BIG                                              
       END DO
!C
       IF ( L .NE. N )  THEN                                              
        DO  I=L1,N                                                        
         IF ( A(I,L) .NE. D_0 )  THEN                                  
          DO  J=L1,N1                                                     
           A(I,J) = A(I,J) - A(I,L) * A(L,J)                              
          END DO
         END IF                                                           
        END DO
       END IF                                                             
      END DO
!C
      IF ( N .NE. I_1 )  THEN                                          
       N2 = N - I_1                                                    
       DO  L=1,N2                                                         
        I  = N - L                                                        
        L1 = I + I_1                                                  
        DO  J=L1,N                                                        
         A(I,N1) = A(I,N1) - A(I,J) * A(J,N1)                             
        END DO
       END DO
      END IF                                                              
!C
      RETURN                                                              
      END                                                                 
