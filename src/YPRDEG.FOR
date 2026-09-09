      SUBROUTINE YPRDEG ( D_LCL, A )                                      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes yaw pitch and roll in degrees and places them              
!C       into the A array for a given direction cosine matrix D.          
!C                                                                        
!C       Assumes D = D(R)D(P)D(Y) , where                                 
!C                                                                        
!C           1  0  0           CP 0 -SP             CY SY 0               
!C    D(R) = 0  CR SR  ,D(P) = 0  1  0  AND D(Y) = -SY CY 0               
!C           0 -SR CR          SP 0  CP             0  0  1               
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS, PI, RADIAN,          ! /CNSNTS/
     &       IREAL_HIGH, D_0, D_HALF   ! parameters
!C
      IMPLICIT  NONE                                                      
!C
      REAL  ( KIND = IREAL_HIGH )  A, D_LCL, PITCH, ROLL, YAW
      DIMENSION         A(3), D_LCL(3,3)                                 
!C
      INTENT (  IN )  D_LCL
      INTENT ( OUT )  A
!C
      IF      ( ( ABS ( D_LCL(1,1) ) .LE. EPS(15) ) .AND.
     &          ( ABS ( D_LCL(1,2) ) .LE. EPS(15) ) )    THEN            
       YAW  = ATAN2 ( -D_LCL(2,1), D_LCL(2,2) )                          
       ROLL = D_0                                                        
      ELSE IF ( ( ABS ( D_LCL(2,3) ) .LE. EPS(15) ) .AND. 
     &          ( ABS ( D_LCL(3,3) ) .LE. EPS(15) ) )    THEN            
       YAW  = ATAN2 ( -D_LCL(2,1), D_LCL(2,2) )                           
       ROLL = D_0                                                       
      ELSE
       YAW  = ATAN2 ( D_LCL(1,2), D_LCL(1,1) )                           
       ROLL = ATAN2 ( D_LCL(2,3), D_LCL(3,3) )                            
      END IF                                                              
      PITCH = -ASIN ( D_LCL(1,3) )                                        
!C
      IF  ( ( ABS ( ROLL ) .LE. ( D_HALF * PI ) ) .OR.           
     &      ( ABS ( YAW  ) .LE. ( D_HALF * PI ) )  )  THEN       
       A(1) = YAW   / RADIAN                                             
       A(2) = PITCH / RADIAN                                             
       A(3) = ROLL  / RADIAN                                              
      ELSE
       PITCH = SIGN  ( ( PI - ABS ( PITCH ) ), PITCH )                    
       YAW   = ATAN2 ( -D_LCL(1,2), -D_LCL(1,1) )                         
       ROLL  = ATAN2 ( -D_LCL(2,3), -D_LCL(3,3) )                         
       A(1) = YAW   / RADIAN                                              
       A(2) = PITCH / RADIAN                                              
       A(3) = ROLL  / RADIAN                                              
      END IF
!C
      RETURN                                                              
      END                                                                
