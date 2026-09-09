      SUBROUTINE  ACTUATOR_TORQUE ( J, THETA, THETAD ) 
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C    This subroutine calculates the actuator torques.             
!C                                                                          
!C    Input parameters:                                                    
!C                                                                          
!C        J                    = actuator number
!C        THETA                = joint angle                                             
!C        THETAD               = joint angular velocity                                  
!C                                                                         
!C     Output parameter:                                                    
!C                                                                          
!C        TORQ(1)   actuator torque                                         
!C        TORQ(2-5) user defined parameters for output in actuator         
!C                  time history                                            
!C                                                                          
!C                                                                          
      USE  MODULE_STANDARD,  ONLY:  
     &   ACT_THETA_CUR, ACT_THETA_PREV, ACT_TIME_PREV,  ! /ACTFR1/
     &   TIME,                                          ! /CONTRL/
     &   NTI,                                           ! /TABLES/
     &   ACT,                                           ! structures
     &   INTEGER_STD, IREAL_HIGH,                       ! parameters
     &   I_0, I_1                                       ! parameters
!C
!C    TARGET_ANGLE_FUNCT, PROPOR_FUNCT, DERIV_FUNCT, INTEGRAL_FUNCT,  ! ACT%
!C     ACT_TORQ, PROP_TORQ, DERIV_TORQ, INTEGRAL_TORQ,                ! ACT%
!C     ACT_JNT_ANGLE, ACT_JNT_VEL                                     ! ACT%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  J, KFT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  DCONT, DTHETA, DTIME, 
     &                  PCONT, SCONT, THETA, THETA0, THETAD, 
     &                  THETA0D, THETAIN
!C
      REAL  ( KIND = IREAL_HIGH )   EVALFD
      EXTERNAL          EVALFD
!C
      INTENT ( IN )   J, THETA, THETAD
!C                                                                          
!C    This subroutine calculates the actuator torque with PID control 
!C     as follows:             
!C                                                                         
!C      TORQ = PROPOR( THETA - THETA0 ) - DERIV( THETAD ) - INTEGRAL( THETAI )                  
!C               where THETA0 = TARGET_ANGLE( TIME )                                      
!C                                                                         
!C                                                                          
!C    Calculate the joint target angle.                      
!C                                                                         
      KFT = NTI(ACT(J)%TARGET_ANGLE_FUNCT)                                                 
      THETA0 = EVALFD ( TIME, KFT, I_1 )                                  
      THETA0D = EVALFD ( TIME, KFT, I_0 )
      DTHETA = THETA - THETA0                                              
!C                                                                          
!C    Calculate the proportional component of the torque function.          
!C                                                                          
      KFT = NTI(ACT(J)%PROPOR_FUNCT)                                                  
      PCONT = EVALFD ( THETA0, KFT, I_1 )                               
      ACT(J)%PROP_TORQ  = DTHETA * PCONT                                         
!C                                                                          
!C    Calculate the derivative component of the torque function.         
!C                                                                         
      KFT = NTI(ACT(J)%DERIV_FUNCT)                                                 
      DCONT = EVALFD ( THETA0, KFT, I_1 )                                     
      ACT(J)%DERIV_TORQ = THETAD * DCONT - THETA0D * DCONT                                          
!C                                                                         
!C    Calculate the integral component of the torque function.        
!C                                                                         
      DTIME = TIME - ACT_TIME_PREV                                                 
      THETAIN = DTIME * DTHETA                                             
      KFT = NTI(ACT(J)%INTEGRAL_FUNCT)                                                 
      ACT_THETA_CUR = ACT_THETA_PREV + THETAIN                                     
      SCONT = EVALFD ( THETA0, KFT, I_1 )                                 
      ACT(J)%INTEGRAL_TORQ = ACT_THETA_CUR * SCONT                                            
!C                                                                          
!C    Calculate the actuator torque.                                        
!C                                                                          
      ACT(J)%ACT_TORQ = ACT(J)%PROP_TORQ - ACT(J)%DERIV_TORQ
     &                                  - ACT(J)%INTEGRAL_TORQ
!C                                                                          
!C    Also output THETA0 and THETA.                                      
!C                                                                       
      ACT(J)%ACT_JNT_ANGLE = THETA0                                                
      ACT(J)%ACT_JNT_VEL   = THETA                                                 
!C
      RETURN                                                               
      END                                                                  
