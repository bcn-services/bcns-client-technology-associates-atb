      SUBROUTINE SPLINE ( X, Y_LCL, F_LCL, N, L )                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                       
!C    Routine to fit a set of polynomials of degree L                     
!C    to a set of given data points (X(I),Y(I),I=1,N)                     
!C                                                                        
!C    Function is of form:                                                
!C                                                                        
!C      Y = F(2,K) + F(3,K)*DX + F(4,K)*DX**2 + F(5,K)*DX**3              
!C      where: DX = XX - F(1,K)                                           
!C             F(1,K) .LE. XX .LT. F(1,K+1)  ;  (SETS K)                  
!C             IF  (XX.GT.F(1,N))  ;  use K=N, constant fit to Y(N)       
!C             IF  (XX.LT.F(1,1))  ;  extrapolated fit for K=1            
!C                                                                        
!C                F(1,I) = X(I) ,                I=1,N                    
!C                F(2,I) = Y(I) ,                I=1,N                   
!C                                                                        
!C     Degree L                                           continuity      
!C            0   F(3,I) = F(4,I) = F(5,I) = 0 , I=1,N       none         
!C            1   F(4,I) = F(5,I) = 0  ,         I=1,N       Y            
!C            2   F(5,I) = 0 ,                   I=1,N       Y,Y'        
!C            3   cubic spline                               Y,Y',Y''     
!C                                                                       
!C                F(K,N)=0 for K=3,5 in all cases                         
!C                                                                      
!C    For L=2 and L=3 the changes in the L'th derivatives are minimized   
!C                                                                        
!C    Special cases:                                                      
!C        N=1 ;     treated as L=0                                       
!C        N=2 ;     treated as L=MIN(L,1)                                
!C        L<0 ;     treated as L=0                                        
!C        L>3 ;     treated as L=3                                      
!C                                                                        
!C    Storage required  X(N),Y(N),F(5,N); set by calling program         
!C                                                                        
!C    Usage:                                                              
!C      all computations and real variables are double precision          
!C      given:  L,N, (X(I),Y(I),I=1,N)                                    
!C      Call SPLINE (X,Y,F,N,L)        ; sets F                           
!C                                                                        
!CC                                                                      
!CC     To evaluate function and derivatives at point XX                  
!CC                                                                       
!C          DO  10  K=1,N                                                 
!C           IF ( K .EQ. N )  EXIT                                        
!C           IF ( XX .LT. F(1,K+1) ) EXIT                                  
!C      10  CONTINUE                                                      
!C      11  DX = XX - F(1,K)                                              
!C          YY = F(2,K) + DX * ( F(3,K) + DX * ( F(4,K) + DX * F(5,K) ) )               
!C          YD = F(3,K) + DX * ( 2.0 * F(4,K) + 3.0 * DX * F(5,K) )                   
!C          YDD = 2.0 * F(4,K) + 6.0 * DX * F(5,K)                              
!C          YDDD = 6.0 * F(5,K)                                            
!C          YDDDD = 0.0                                                   
!CC                                                                       
!CC     Functional value in YY, derivatives in YD'S                       
!CC     repeat for next value of XX                                       
!C                                                                       
!C    Author: Dr. John T. Fleck                                          
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS,                       ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,   ! parameters 
     &        D_0, D_1, D_2, D_3,        ! parameters 
     &        I_0, I_1, I_2, I_3         ! parameters
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                    I, I1, I2, J, J1, K, K1, L, N, NI
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  C_LCL, CA, DD, DEN, D1, DS, DX, DX1, DX2, 
     &                  F_LCL, FJ, FJA, FK, FKA, SS, X, XX, Y_LCL  
      DIMENSION         X(N), Y_LCL(N), F_LCL(5,N), C_LCL(2,3)           
!C
      DO  I=1,N                                                          
       F_LCL(1,I) = X(I)                                                  
       DO  K=2,5                                                        
        F_LCL(K,I) = D_0                                              
       END DO
       IF  ( L .LT. I_3 )   F_LCL(2,I) = Y_LCL(I)                   
       IF  ( ( L .GT. I_0 ) .AND. ( I .LT. N ) )  THEN  
        F_LCL(3,I) = ( Y_LCL(I+1) - Y_LCL(I) ) / ( X(I+1) - X(I) )        
       END IF
      END DO
      IF  ( ( L .LT. I_2 ) .OR. ( N .LT. I_3 ) )  THEN
       RETURN
      END IF                                                              
      IF  ( L .LT. I_3 )  THEN                                      
       D1 = X(2) - X(1)                                                   
       SS = D_0                                                       
       DS = D_0                                                      
       DO  I=3,N                                                          
        F_LCL(4,I-1) = F_LCL(3,I-1) - F_LCL(3,I-2) - F_LCL(4,I-2)         
        DX1 = X(I) - X(I-1)                                               
        DX2 = X(I-1) - X(I-2)                                             
        DD = D1 / DX1 + D1 / DX2                                        
        SS = SS + DD * DD                                                 
        DS = DS + DD * ( F_LCL(4,I-1) / DX1 - F_LCL(4,I-2) / DX2 )        
        D1 = -D1                                                          
       END DO
       F_LCL(4,1) = DS / SS                                               
       DX = ( X(2) - X(1) ) * F_LCL(4,1)                                  
       F_LCL(3,1) = F_LCL(3,1) - DX                                      
       DO  I=3,N                                                         
        XX = F_LCL(4,I-1) - DX                                            
        F_LCL(3,I-1) = F_LCL(3,I-1) - XX                                 
        F_LCL(4,I-1) = XX / ( X(I) - X(I-1) )                           
        DX = -DX                                                         
       END DO
       RETURN                                                            
      END IF
!C                                                                        
!C    Cubic spline                                                        
!C                                                                        
      DO  I=2,N                                                           
       IF  ( I .NE. N )  THEN                                             
        F_LCL(4,I) = D_3 * ( F_LCL(3,I) - F_LCL(3,I-1) )                
        F_LCL(5,I) = D_2 * ( X(I+1) - X(I-1) )                           
       END IF
       F_LCL(3,I-1) = D_0                                           
      END DO
      F_LCL(2,N) = -D_1                                                 
      F_LCL(3,1) = -D_1                                                  
      DO  I=3,N                                                          
       DX = X(I-1) - X(I-2)                                               
       IF  ( I .GT. I_3 )   DX = DX / F_LCL(5,I-2)                   
       DO  K=3,5                                                         
          F_LCL(K,I-1) = F_LCL(K,I-1) 
     &  - F_LCL(K,I-2) * DX**( ( K - I_1 ) / I_2 )                     
       END DO
      END DO
      DO  I=3,N                                                          
       NI = N - I                                                         
       DX = X(NI+3) - X(NI+2)                                             
       DO  K=2,4                                                         
        F_LCL(K,NI+2) = ( F_LCL(K,NI+2) - DX * F_LCL(K,NI+3) )
     &                                  / F_LCL(5,NI+2)                   
       END DO
      END DO
      DO  J=1,2                                                           
       DO  K=J,3                                                        
        C_LCL(J,K) = D_0                                               
        DO  I=3,N                                                        
         DX1 = X(I) - X(I-1)                                             
         DX2 = X(I-1) - X(I-2)                                           
         J1 = J + I_1                                                  
         K1 = K + I_1                                                   
         I1 = I - I_1                                                   
         I2 = I - I_2                                                  
         FJ =   ( F_LCL(J1,I)  - F_LCL(J1,I1) ) / DX1
     &        - ( F_LCL(J1,I1) - F_LCL(J1,I2) ) / DX2                     
         FJA = ABS ( FJ )                                                
         IF ( FJA .LT. EPS(24) )   FJ = D_0                          
         FK =   ( F_LCL(K1,I)  - F_LCL(K1,I1) ) / DX1 
     &        - ( F_LCL(K1,I1) - F_LCL(K1,I2) ) / DX2                     
         FKA = ABS ( FK )                                                 
         IF ( FKA .LT. EPS(24) )  FK = D_0                            
         C_LCL(J,K) = C_LCL(J,K) + FJ * FK                                
         CA = ABS ( C_LCL(J,K) )                                         
         IF ( CA .LT. EPS(24) )  C_LCL(J,K) = D_0                    
        END DO
       END DO
      END DO                                                              
      DEN    =  C_LCL(1,1) * C_LCL(2,2) - C_LCL(1,2) * C_LCL(1,2)        
      F_LCL(4,1) = ( C_LCL(1,1) * C_LCL(2,3) - C_LCL(1,2) * C_LCL(1,3) )
     &                                       / DEN                        
      F_LCL(4,N) = ( C_LCL(2,2) * C_LCL(1,3) - C_LCL(1,2) * C_LCL(2,3) )
     &                                       / DEN                        
      DO  I=3,N                                                           
       F_LCL(4,I-1) = F_LCL(4,I-1) - F_LCL(4,1) * F_LCL(3,I-1)
     &                             - F_LCL(4,N) * F_LCL(2,I-1)            
      END DO
      D1 = X(2) - X(1)                                                   
      F_LCL(3,1) = ( Y_LCL(2) - Y_LCL(1) ) / D1 - 
     &             ( D_2 * F_LCL(4,1) + F_LCL(4,2) ) * D1 / D_3        
      F_LCL(2,1) = Y_LCL(1)                                               
      DO  I=2,N                                                           
       F_LCL(2,I) = Y_LCL(I)                                              
       DX = X(I) - X(I-1)                                                 
       IF  ( I .LT. N )  THEN  
         F_LCL(3,I) = F_LCL(3,I-1) + ( F_LCL(4,I) + F_LCL(4,I-1) ) * DX  
       END IF
       F_LCL(5,I-1) = ( F_LCL(4,I) - F_LCL(4,I-1) ) / ( D_3 * DX )     
      END DO
      F_LCL(4,N) = D_0                                                 
!C
      RETURN                                                              
      END                                                               
