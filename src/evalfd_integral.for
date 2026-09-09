      SUBROUTINE  EVALFD_INTEGRAL ( NP, D_ABSCISSA, 
     &                              D0, D1, D2, FUNC_VAL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine computes the integral of a function from
!C     D0 to D.  It is called only by Function EVALFD.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       TAB,                                        ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH,                    ! parameters
     &       I_0, I_1, I_2, I_3, I_6,                    ! parameters
     &       D_0, D_HALF, D_2, D_3, D_4, D_5, D_6        ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                  I, K, K1, K2, MB, NP
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A0, A1, A2, A3, A4, A5, D_ABSCISSA, 
     &                  D0, D1, D2, DL, FUNC_VAL, FY, FYX, 
     &                  X, X0, X1, Z1, Z2
!C
      INTENT (    IN )  D_ABSCISSA, D0, D1, D2
      INTENT ( INOUT )  NP, FUNC_VAL
!C                                                                        
!C    L = 2: compute integral of function from D0 to D.                     
!C                                                                        
      X0 = D0                                                            
      X1 = D1                                                            
      DO 50 I=1,2                                                         
       IF ( X1 .LT. D_0 )  THEN
        MB = TAB(NP)                                                        
        K1 = NP + I_3                                                   
        K2 = NP + MB + MB                                                   
        NP = K2 + I_1                                                    
        DL = MIN ( D_ABSCISSA, ABS ( X1 ) )                                      
        DO  K=K1,K2,2                                                       
         IF ( X0 .GE. TAB(K) )  CYCLE                                       
         Z1 = MAX ( X0, TAB(K-2) )                                          
         Z2 = MIN ( DL, TAB(K) )                                            
         FYX = TAB(K-1) * TAB(K) - TAB(K+1) * TAB(K-2)                      
         FY = TAB(K+1) - TAB(K-1)                                           
         FUNC_VAL = FUNC_VAL + ( FYX  + D_HALF * FY * ( Z1 + Z2 ) ) * 
     &                ( Z2 - Z1 ) / ( TAB(K) - TAB(K-2) )                   
         IF ( Z2 .NE. DL )  CYCLE                                           
!C
         IF ( ( I .EQ. I_1 ) .AND. ( D2 .NE. D_0 ) )  THEN               
          X0 = ABS ( D1 )                                                     
          X1 = D2                                                             
          CYCLE
         END IF
!C
         IF ( Z2 .EQ. D_ABSCISSA ) THEN
          RETURN
         END IF
         FUNC_VAL = FUNC_VAL + ( D_ABSCISSA - Z2 ) * ( FYX + Z2 * FY )
     &                   / ( TAB(K) - TAB(K-2) )                            
         RETURN
        END DO                                                              
        X0 = ABS ( D1 )                                                     
        X1 = D2                                                             
       ELSE IF ( X1 .EQ. D_0 )  THEN
        X0 = ABS ( D1 )                                                     
        X1 = D2                                                             
       ELSE
        A0 = TAB(NP  )                                                     
        A1 = TAB(NP+1) / D_2                                               
        A2 = TAB(NP+2) / D_3                                          
        A3 = TAB(NP+3) / D_4                                          
        A4 = TAB(NP+4) / D_5                                          
        A5 = TAB(NP+5) / D_6                                               
        NP = NP + I_6                                                  
        X = X0                                                             
        IF ( X .NE. D_0 ) THEN
         FUNC_VAL = FUNC_VAL - X * ( A0 + 
     &                         X * ( A1 + 
     &                         X * ( A2 + 
     &                         X * ( A3 + 
     &                         X * ( A4 + 
     &                         X *   A5 ) ) ) ) )                                
        END IF
        X = MIN ( D_ABSCISSA, X1 )                                              
        IF ( X .NE. D_0 )  THEN
         FUNC_VAL = FUNC_VAL + X * ( A0 + 
     &                         X * ( A1 + 
     &                         X * ( A2 + 
     &                         X * ( A3 + 
     &                         X * ( A4 + 
     &                         X *   A5 ) ) ) ) )                                
        END IF
        IF ( D_ABSCISSA .LE. X1 )  THEN
         RETURN
        END IF
!C
        IF ( ( I .EQ. I_1 ) .AND. ( D2 .NE. D_0 ) )  THEN              
         X0 = ABS ( D1 )                                                     
         X1 = D2                                                             
         CYCLE                                                      
        END IF
!C                                                                        
!C      Note -  NP was updated NP = NP + 6 before this,                      
!C       ready for second pass                                             
!C                                                                         
        FUNC_VAL = FUNC_VAL + 
     &                  ( D_ABSCISSA - X1 ) * ( TAB(NP-6) + 
     &                                 X1   * ( TAB(NP-5) +
     &                                 X1   * ( TAB(NP-4) +                     
     &                                 X1   * ( TAB(NP-3) +
     &                                 X1   * ( TAB(NP-2) + 
     &                                 X1   *   TAB(NP-1) ) ) ) ) )             
        RETURN                                                             
       END IF
   50 CONTINUE
!C
      RETURN
      END 