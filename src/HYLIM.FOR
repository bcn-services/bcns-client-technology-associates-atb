      SUBROUTINE HYLIM ( A, U_LCL, B_LCL, V, C_LCL, W_LCL, 
     &                   Z, BD_LCL )                                       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Given Z, find A,B,Z: ZEZ = 1,  ZEV = 0,  TZ = TP                     
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                      ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,     ! parameters
     &       D_0, D_HALF, D_1, D_2, I_100, FALSE, TRUE ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IT, ITER
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A, B_LCL, C_LCL, G_LCL, EIU, EVM, EVZ,
     &                  P1_LCL, P2_LCL, POW, PP, RHO, RHOV, 
     &                  RHOZ, SS, TZ, TZV, ZEV, ZEZ, ZZ
      REAL  ( KIND = IREAL_HIGH )
     &                  BD_LCL, U_LCL, V, W_LCL, EI, EJ, 
     &                  T, TV, Z, E_LCL, EV, Q, S, EZ, SM
      DIMENSION         BD_LCL(24), U_LCL(3), V(3), W_LCL(3), EI(3),
     &                  EJ(3), T(3),TV(3), Z(3), E_LCL(3), EV(3),          
     &                  Q(3), S(3), EZ(3), SM(3,3)                    
!C
      REAL  ( KIND = IREAL_HIGH )  HYFCN
      EXTERNAL          HYFCN
!C
      LOGICAL  ( KIND = LOGICAL_STD )  PASS, USEV                          
!C
      PARAMETER  ( ITER = I_100 )
!C
      PASS = FALSE                                                   
      PP =  -D_1 / BD_LCL(1)                                               
      POW = -BD_LCL(1) - D_2                                              
      P1_LCL  = -BD_LCL(1) - D_1                                           
      P2_LCL  =  -BD_LCL(1) / P1_LCL                                    
      DO  I = 1,3                                                          
       TV(I) = D_0                                                  
       IF ( V(I) .NE. D_0 )  THEN
        TV(I) = HYFCN ( ( D_1 / V(I) ), V(I), BD_LCL(I+1), P2_LCL )   
       END IF
      END DO                                                            
!C
!C    Get reciprocal set                                                
!C
      CALL CROSS ( V,     W_LCL, EI )                                      
      CALL CROSS ( W_LCL, U_LCL, EJ )                                      
      CALL CROSS ( U_LCL, V,     T  )                                      
      EIU = EI(1) * U_LCL(1) + EI(2) * U_LCL(2) + EI(3) * U_LCL(3)         
      G_LCL = C_LCL * EIU                                                  
!C                                                                         
      DO 55 IT = 1,ITER                                                    
       EVM = D_0                                                      
       EVZ = D_0                                                      
       ZEZ = D_0                                                      
       USEV = FALSE                                                   
       DO  I = 1,3                                                      
        E_LCL(I) = HYFCN ( BD_LCL(I+16), Z(I), BD_LCL(I+1), POW )       
        EV(I) = E_LCL(I) * V(I)                                         
        IF ( EV(I) .EQ. D_0 )   USEV = TRUE                         
        IF ( ABS ( EV(I) ) .GT. EVM )    EVM = ABS ( EV(I) )            
        EZ(I) = E_LCL(I) * Z(I)                                         
        IF ( ABS ( EZ(I) ) .GT. EVZ )    EVZ = ABS ( EZ(I) )            
        ZEZ = ZEZ + Z(I) * EZ(I)                                        
       END DO                                                           
       RHO  = ZEZ**PP                                                   
       DO  I = 1,3                                                      
        Z(I) = Z(I) / RHO                                               
       END DO                                                           
       IF ( PASS )  EXIT                                            
       RHOZ = ZEZ / RHO                                                 
       RHOV = EVM * RHOZ / RHO                                          
       RHOZ = EVZ * RHOZ                                                
       IF  ( USEV )   THEN                                              
        RHOV = D_1                                                      
        DO  I = 1,3                                                   
         EV(I) = TV(I)                                                  
        END DO                                                          
       END IF
!C
!C     What if no TV is 0 and EV are all 0 ?                            
!C
       DO  I = 1,3                                                      
        EV(I) = EV(I) / RHOV                                            
        EZ(I) = EZ(I) / RHOZ                                            
       END DO                                                           
!C
!C     Set up matrix                                                    
!C
       CALL CROSS ( EV, T,  SM(1,1) )                                   
       CALL CROSS ( T , EZ, SM(1,2) )                                   
       CALL CROSS ( EZ, EV, SM(1,3) )                                   
       TZV = T(1) * SM(1,3) + T(2) * SM(2,3) + T(3) * SM(3,3)           
       TZ  = T(1) * Z(1)    + T(2) * Z(2)    + T(3) * Z(3)              
       ZEV = Z(1) * EV(1)   + Z(2) * EV(2)   + Z(3) * EV(3)             
       IF ( TZV .EQ. D_0 )   STOP 39                                  
       ZEV = ZEV / TZV                                                  
       Q(1) = D_0                                                    
       Q(2) = -ZEV                                                      
       IF ( .NOT. USEV )    Q(2) = Q(2) / P1_LCL                        
       Q(3) = ( G_LCL - TZ ) / TZV                                      
       CALL MAT31 ( SM, Q, S )                                          
       SS = D_0                                                        
       ZZ = D_0                                                       
       DO  I = 1,3                                                      
        SS = SS + ABS ( S(I) )                                          
        IF ( ABS ( Z(I) ) .GE. ( EPS(1) * BD_LCL(I+1) ) )  THEN        
         IF ( ABS ( S(I) ) .GT. ABS ( Z(I) ) )   THEN
          S(I) = SIGN ( ( D_HALF * Z(I) ), S(I) )                       
         END IF
        END IF
        Z(I) = Z(I) + S(I)                                              
        IF ( ABS ( Z(I) ) .GT. BD_LCL(I+1) )   THEN
         Z(I) = SIGN ( BD_LCL(I+1), Z(I) )                              
        END IF
        ZZ = ZZ + ABS ( Z(I) )                                          
       END DO                                                           
       IF ( SS .LT. ( EPS(10) * ZZ ) )  PASS = TRUE                  
   55 CONTINUE                                                          
!C                                                                      
      A     = ( EI(1) * Z(1) + EI(2) * Z(2) + EI(3) * Z(3) ) / EIU      
      B_LCL = ( EJ(1) * Z(1) + EJ(2) * Z(2) + EJ(3) * Z(3) ) / EIU      
!C
      RETURN                                                            
      END                                                               
      