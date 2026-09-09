      SUBROUTINE HYBOX ( E_LCL, T, P, N, Z, IV )                           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                         
!C    Computes the intersection of a plane with the edges of a box         
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH,   ! parameters 
     &       D_0, D_1, D_2,             ! parameters
     &       I_0, I_1, I_2, I_3, I_6    ! parameters 
!C
      IMPLICIT  NONE                                                       
!C
!C
!C    To be safe IV and Z should be dimension 14 in calling program        
!C
      INTEGER  ( KIND = INTEGER_STD )   I, IV, J, K, L, LL, M, N
      DIMENSION  IV(12)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  E_LCL, T, P, Z, TU, TUV, T2_LCL, CK_LCL,
     &                  D_LCL, F_LCL, P1_LCL, P2, P3, P4
      DIMENSION         T(3), E_LCL(3), TU(3), T2_LCL(3), P(3), Z(3,12)    
!C
!C    T - plane vector, P point in plane                                   
!C
      TUV = D_0                                                          
      DO  I = 1,3                                                          
       TU(I) = T(I) * E_LCL(I)                                             
       T2_LCL(I) = D_2 * TU(I)                                       
       TUV = TUV + T(I) * ( E_LCL(I) + P(I) )                              
      END DO
      N = I_0                                                         
      J = I_2                                                         
      K = I_3                                                         
      DO 20 I = 1,3                                                        
       CK_LCL = -E_LCL(K)                                                  
       P1_LCL = TUV                                                        
       DO 30 LL = 1,2                                                      
        P2 = P1_LCL - T2_LCL(I)                                            
        P3 = P2     - T2_LCL(J)                                            
        P4 = P1_LCL - T2_LCL(J)                                            
        M = N                                                              
        IF ( SIGN ( D_1, P2 ) .NE. SIGN ( D_1, P1_LCL ) )  THEN            
         M = M + I_1                                                    
         Z(I,M) = ( P1_LCL / TU(I) - D_1 ) * E_LCL(I)                     
         Z(J,M) = -E_LCL(J)                                                
         Z(K,M) =  CK_LCL                                                  
        END IF
        IF ( SIGN ( D_1, P3 ) .NE. SIGN ( D_1, P2 ) )  THEN                
         M = M + I_1                                                    
         Z(I,M) =  E_LCL(I)                                                
         Z(J,M) = ( P2 / TU(J) - D_1 ) * E_LCL(J)                       
         Z(K,M) =  CK_LCL                                                  
        END IF
        IF ( SIGN ( D_1, P3 ) .NE. SIGN ( D_1, P4 ) )  THEN                
         M = M + I_1                                                     
         Z(I,M) = ( P4 / TU(I) - D_1 ) * E_LCL(I)                       
         Z(J,M) =  E_LCL(J)                                                
         Z(K,M) =  CK_LCL                                                  
        END IF
        IF ( SIGN ( D_1, P4 ) .NE. SIGN ( D_1, P1_LCL ) )  THEN            
         M = M + I_1                                                  
         Z(I,M) = -E_LCL(I)                                                
         Z(J,M) = ( P1_LCL / TU(J) - D_1 ) * E_LCL(J)                     
         Z(K,M) =  CK_LCL                                                  
        END IF
        IF ( M .EQ. N )  THEN                                              
         CONTINUE
!C
!C      Check for precision (+-+-.OR -+-+)                                 
!C
        ELSE IF ( M .EQ. ( N + 4 ) )  THEN                                 
         CONTINUE
!C
!C       Delete 0 length side                                              
!C
        ELSE IF ( ( Z(I,M-1) .EQ. Z(I,M) ) .AND. 
     &            ( Z(J,M-1) .EQ. Z(J,M) ) )  THEN
     &                                                                     
         CONTINUE
        ELSE
         N = M                                                             
        END IF
        P1_LCL = P1_LCL - T2_LCL(K)                                        
        CK_LCL = -CK_LCL                                                   
   30  CONTINUE
       J = K                                                               
       K = I                                                               
   20 CONTINUE
!C                                                                         
      IF ( N .GE. I_6 )  THEN                                           
       IV(1) = I_1                                                      
       IV(2) = I_2                                                      
       M = I_2                                                         
       DO  J = 3,N,2                                                       
        D_LCL = ABS ( Z(1,M) ) + ABS ( Z(2,M) ) + ABS ( Z(3,M) )           
        DO  L = 3,N                                                        
         DO  LL = 2,J                                                      
          IF ( IV(LL-1) .EQ. L )  CYCLE                                    
         END DO                                                            
         F_LCL =   ABS ( Z(1,M) - Z(1,L) ) + ABS ( Z(2,M) - Z(2,L) )
     &           + ABS ( Z(3,M) - Z(3,L) )                                 
         IF ( F_LCL .GT. D_LCL )  CYCLE                                    
         D_LCL = F_LCL                                                     
         K = L                                                             
        END DO                                                             
        M = K + I_1                                                      
        IF ( MOD ( K, I_2 ) .EQ. I_0 )   M = K - I_1                 
        IV(J) = K                                                          
        IV(J+1) = M                                                        
       END DO                                                              
      END IF
!C
      RETURN                                                               
      END                                                                  
