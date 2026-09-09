      FUNCTION HYPEN ( E_LCL, V )                  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Point of maximum penetration                                         
!C    Solves for value of ALP used by PLELP.                                
!C    The powers of the hyperellipsoid may be different.                            
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS,                       ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,   ! parameters
     &        I_1, D_0, D_1, D_2         ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )  I, L
!C
      REAL  ( KIND = IREAL_HIGH )  HYPEN  
      REAL  ( KIND = IREAL_HIGH )
     &             E_LCL, V, VM, A, AM, AN, AP, DEL, FM, FP, F_LCL
      DIMENSION    E_LCL(3),V(3)                                           
!C
      VM = V(1)                                                            
      L = I_1                                                            
      DO  I = 2,3                                                          
       IF ( V(I) .LE. VM ) CYCLE                                           
       L = I                                                               
       VM = V(I)                                                           
      END DO                                                               
!C
      A = V(1) + V(2) + V(3)                                               
      A = D_1 / A**( D_1 / E_LCL(L) )                                      
      DEL = A / D_2                                                        
      AP = D_0                                                           
!C
      DO
       F_LCL =   A**E_LCL(1) * V(1) + A**E_LCL(2) * V(2)
     &         + A**E_LCL(3) * V(3) - D_1                                   
       IF ( ABS ( F_LCL ) .LT. EPS(8) )  THEN
        HYPEN = A                                                           
        RETURN                                                              
       END IF
       IF ( F_LCL .GT. D_0 )  THEN
        IF ( ( A - DEL ) .LE. D_0 )    DEL = A / D_2                       
        AP = A                                                               
        FP = F_LCL                                                           
        A = A - DEL                                                          
        CYCLE                                                             
       ELSE IF ( F_LCL .LT. D_0 )  THEN
        IF ( AP .EQ. D_0 )   THEN                                         
         A = A + DEL                                                         
         CYCLE                                                            
        ELSE
         LOOP_10 : DO
          AM = A                                                               
          FM = F_LCL                                                           
          LOOP_20 : DO
           IF ( FP .EQ. FM )  THEN                                              
            HYPEN = A                                                           
            RETURN                                                              
           END IF
           DEL = -FM * ( AP - AM ) / ( FP - FM )                                
           AN = AM + DEL                                                        
           IF ( AN .EQ. A )  THEN
            HYPEN = A                                                           
            RETURN                                                              
           END IF
           A = AN                                                               
           F_LCL =   A**E_LCL(1) * V(1) + A**E_LCL(2) * V(2)
     &             + A**E_LCL(3) * V(3) - D_1                                 
           IF ( ABS ( F_LCL ) .LT. EPS(8) )   THEN                              
            HYPEN = A                                                           
            RETURN                                                              
           END IF
!C
           IF ( F_LCL .LT. D_0 )  THEN
            CYCLE  LOOP_10
           ELSE IF ( F_LCL .GT. D_0 ) THEN
            FP = F_LCL                                                           
            AP = A                                                               
            CYCLE  LOOP_20                                                             
           ELSE
            HYPEN = A                                                            
            RETURN
           END IF
          END DO  LOOP_20
         END DO  LOOP_10
        END IF
       ELSE
        HYPEN = A                                                           
        RETURN                                                              
       END IF
      END DO
!C
      END                                                                  
