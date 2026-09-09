      SUBROUTINE  JNTFNC ( J )                                            
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Calculates the applied driving joint function torque.                
!C                                                                        
!C    Input parameter                                                     
!C                                                                        
!C       J - actuator number                                              
!C                                                                       
      USE  MODULE_STANDARD,  ONLY: 
     &       RADIAN,                  ! /CNSNTS/
     &       HT,                      ! /DESCRP/
     &       ACT, SEG, JNT,           ! structures
     &       INTEGER_STD, IREAL_HIGH, ! parameters
     &       D_0, D_1, I_1            ! parameters
!C
!C    ACT_JNT, BASE_SEG             ! ACT%
!C    ANG_VEL, DIR_COS              ! SEG%
!C    PROX_SEG                      ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, NRJ, NRS1, NRS2
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  T1, T2_LCL, T3, T4, T5_LCL, W1, W2, W3, Q,
     &                  DOT1, DOT2, DOT3, THETA, THETAD
      DIMENSION         T1(3,3), T2_LCL(3,3), T3(3), T4(3),
     &                  T5_LCL(3), W1(3), W2(3), W3(3), Q(3)              
!C
      INTENT ( IN )  J
!C                                                                        
!C    Get joint and segment numbers for actuator J.                        
!C                                                                        
      NRJ  = ACT(J)%ACT_JNT                                                     
      NRS1 = JNT(NRJ)%PROX_SEG                                  
      NRS2 = NRJ + I_1                                               
!C                                                                       
!C    Calculate torque axis in inertial reference frame                  
!C                                                                        
      CALL DOT31 ( SEG(ACT(J)%BASE_SEG)%DIR_COS, 
     &             ACT(J)%TOR_AXIS(1), Q )                    
!C                                                                        
!C    Calculate joint angle, THETA, from joint axes vectors               
!C                                                                       
      CALL DOT33 ( SEG(NRS1)%DIR_COS, HT(1,1,2*NRJ-1), T1 )             
      CALL DOT33 ( SEG(NRS2)%DIR_COS, HT(1,1,2*NRJ),   T2_LCL )          
      DO  I=1,3                                                          
       T3(I) = T1(I,1)                                                 
       T4(I) = T2_LCL(I,1)                                                
      END DO
      DOT1 = DOT_PRODUCT ( T3, T4 )
      CALL CROSS ( T3, T4, T5_LCL )                                      
      IF ( ABS ( DOT1 ) .GT. D_1 )  THEN
       DOT1 = SIGN ( D_1, DOT1 )    
      END IF
      THETA = ACOS ( DOT1 ) / RADIAN                                      
!C                                                                        
!C    Correct sign on THETA.                                               
!C                                                                        
      DOT2 = DOT_PRODUCT ( T5_LCL, Q )
      IF ( DOT2 .LT. D_0 )  THETA = -THETA                        
!C                                                                        
!C    Get segment angular velocities in inertial reference frame          
!C                                                                        
      CALL DOT31 ( SEG(NRS1)%DIR_COS, SEG(NRS1)%ANG_VEL, W1 )                   
      CALL DOT31 ( SEG(NRS2)%DIR_COS, SEG(NRS2)%ANG_VEL, W2 )                 
!C                                                                        
!C    Calculate joint angular velocity, THETAD                           
!C                                                                        
      DOT3 = D_0                                                     
      DO  I=1,3                                                           
       W3(I) = W1(I) - W2(I)                                              
       DOT3 = DOT3 + W3(I) * Q(I)                                         
      END DO
      THETAD = DOT3 / RADIAN                                              
!C                                                                        
!C    Call subroutine to calculate actuator torque.                
!C                                                                       
      CALL ACTUATOR_TORQUE ( J, THETA, THETAD ) 
!C
      RETURN                                                            
      END                                                               
