      SUBROUTINE HYLPX ( BM, BN, R_LCL, D_LCL, V )                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Linear program exec                                                  
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH,   ! parameters
     &       I_0, I_1, I_7,             ! parameters
     &       D_0, D_1, D_2, D_10        ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( INTEGER_STD )
     &           I, ID, IP, J, J1, J2, K, M, NK, NM, NP, NZ
      DIMENSION  ID(16), IP(2)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A, B_LCL, BM, BN, C_LCL, D_LCL, E_LCL, 
     &                  S, T, W_LCL, R_LCL, V
      DIMENSION         BM(23), BN(23), C_LCL(16), S(9,8),
     &                  E_LCL(9), T(7), A(7), B_LCL(3), D_LCL(3,3),
     &                  R_LCL(3), V(7)                                     
!C
      CALL MAT31 ( D_LCL, BN, B_LCL )                                      
      DO  I = 1,3                                                          
       B_LCL(I) = BM(I) - B_LCL(I) + R_LCL(I)                              
       A(I) = BM(I)                                                        
       A(I+3) = BN(I)                                                      
      END DO
      A(7) = -D_1                                                          
      DO  I = 1,16                                                     
       C_LCL(I) = D_0                                                    
       ID(I) = I                                                          
      END DO
      C_LCL(7) = -D_1                                                      
      S = D_0                                                            
      
!C                                                                         
!C    Costs 0   0  -1                                                      
!C          I  -D  -R    A - DB  + R  (>0)      inf cost                   
!C          I   0   0    2A                                                
!C          0   I   0    2B                                                
!C                                                                         
      DO  I = 1,6                                                          
       S(I+3,I) = D_1                                                     
      END DO
      DO  I = 1,3                                                          
       C_LCL(I+7) = D_10                                                 
       S(I,7) = -R_LCL(I)                                                  
       S(I,I) = D_1                                                  
       S(I,8) = B_LCL(I)                                                   
       S(I+3,8) = D_2 * A(I)                                               
       S(I+6,8) = D_2 * A(I+3)                                            
       DO  J = 1,3                                                        
        S(I,J+3) = -D_LCL(I,J)                                             
       END DO
      END DO
!C
!C    Check sign of RHS                                                    
!C
      DO  I = 1,3                                                          
       IF ( B_LCL(I) .GE. D_0 )  CYCLE                                   
       DO  J = 1,8                                                         
        S(I,J) = -S(I,J)                                                   
       END DO
      END DO                                                               
      J1 = I_1                                                           
      J2 = I_7                                                        
!C                                                                         
      CALL HYLPR ( J1, J2, ID, C_LCL, S, E_LCL, T )                        
      NK = I_0                                                          
      NZ = I_0                                                          
!C
!C    Count zeroes in solution                                             
!C
      DO  I = 1,7                                                          
!C
!C     Test should probably be an epsilon test, ABS(T(I)).GT.EPS       
!C
       IF ( ( T(I) .NE. D_0 ) .OR. ( C_LCL(I) .EQ. D_10 ) )  CYCLE         
       NZ = NZ + I_1                                                    
       IP(NZ) = I                                                          
      END DO                                                               
!C
!C    Set pass count                                                       
!C
      NP = I_1                                                          
      IF ( NZ .GT. I_0 )   NP = 2**NZ                                 
!C                                                                         
      DO  M = 1,NP                                                         
       NM = NK                                                             
       NK = NK + I_1                                                    
       DO  I = 1,16                                                        
        K = ID(I)                                                          
        IF ( K .GT. I_7 )   CYCLE                                     
        W_LCL = D_0                                                     
        IF ( I .GT. I_7 )    W_LCL = S(I-7,8)                        
        V(K) = (W_LCL - A(K) + NM * V(K) ) / NK                            
       END DO                                                              
!C
!C     Look for all solutions                                              
!C
       IF ( M .EQ. NP )  CYCLE                                             
       J1 = IP(1)                                                          
       IP(1) = IP(2)                                                       
       IP(2) = J1                                                          
       IF ( T(J1) .NE. D_0 )  CYCLE                                      
       J2 = J1                                                             
       CALL HYLPR ( J1, J2, ID, C_LCL, S, E_LCL, T )                       
      END DO                                                               
!C
      RETURN                                                               
      END                                                                  
