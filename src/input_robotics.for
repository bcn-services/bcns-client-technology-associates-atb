      SUBROUTINE INPUT_ROBOTICS                                       
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C    This subroutine is called only by Subroutine INITIALIZE to
!C     read in the actuator joint torque functions.
!C
      USE  MODULE_STANDARD,  ONLY:   
     &        NRTORQ,                                        ! /ACTFR/
     &        ACT_THETA_CUR, ACT_THETA_PREV, ACT_TIME_PREV,  ! /ACTFR1/
     &        NPG,                                           ! /CONTRL/
     &        HT,                                            ! /DESCRP/
     &        ACT, JNT,                                      ! structures
     &        INTEGER_STD, LUAIN, LUAOU,                     ! parameters
     &        I_0, I_1, D_0, LULIN,                          ! parameters
     &        AIN_CONVERT, LIN_FLAG                          ! parameters
!C
!C     ACT_JNT, BASE_SEG, TARGET_ANGLE_FUNCT, PROPOR_FUNCT,  ! ACT%
!C      DERIV_FUNCT, INTEGRAL_FUNCT, TOR_AXIS                ! ACT%
!C     PROX_SEG, JTYPE                                       ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J
!C                                                                        
!C    Read cards F.10 actuator joint torque function relations            
!C                                                                        
      WRITE ( LUAOU, 100 )  NPG                                           
  100 FORMAT ( '1', 122X, 'Page', I5, /, 7X,
     &         'Actuator Joint Torque Functions Inputs', 76X,
     &         'Cards F.10', //, 5X, 'No.', 4X, 'Joint', 4X,              
     &         'Seg.', 4X, 'FCN', // )                                    
      NPG = NPG + I_1                                                 
!C
!C    Initialize the previous time used for the computation of the
!C     of the PID joint actuator torque function, ACT_TIME_PREV.
!C    Also initialize the cumulative current joint angle, ACT_THETA_CUR, 
!C     of the joint associated with the joint actuator, and the previous
!C     cumulative joint angle, ACT_THETA_PREV.
!C
      ACT_TIME_PREV  = D_0                                                       
      ACT_THETA_CUR  = D_0
      ACT_THETA_PREV = D_0
!C
      DO  J=1,NRTORQ                                                      
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )   ACT(J)%ACT_JNT, 
     &                      ACT(J)%BASE_SEG,
     &                      ACT(J)%TARGET_ANGLE_FUNCT, 
     &                      ACT(J)%PROPOR_FUNCT,
     &                      ACT(J)%DERIV_FUNCT, 
     &                      ACT(J)%INTEGRAL_FUNCT
       ELSE
        READ ( LUAIN, 105 ) ACT(J)%ACT_JNT, 
     &                      ACT(J)%BASE_SEG,
     &                      ACT(J)%TARGET_ANGLE_FUNCT, 
     &                      ACT(J)%PROPOR_FUNCT,
     &                      ACT(J)%DERIV_FUNCT, 
     &                      ACT(J)%INTEGRAL_FUNCT
  105   FORMAT ( 6I4 )                                                     
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 110 )  ACT(J)%ACT_JNT, 
     &                         ACT(J)%BASE_SEG,
     &                         ACT(J)%TARGET_ANGLE_FUNCT, 
     &                         ACT(J)%PROPOR_FUNCT,
     &                         ACT(J)%DERIV_FUNCT, 
     &                         ACT(J)%INTEGRAL_FUNCT,
     &                         'Card F.10'         
  110    FORMAT ( 1X, 6( I4, 1X ), 1X, A )                                                    
        END IF
       END IF
!C
       WRITE ( LUAOU, 115 ) J, ACT(J)%ACT_JNT, 
     &                         ACT(J)%BASE_SEG,
     &                         ACT(J)%TARGET_ANGLE_FUNCT, 
     &                         ACT(J)%PROPOR_FUNCT,
     &                         ACT(J)%DERIV_FUNCT, 
     &                         ACT(J)%INTEGRAL_FUNCT
  115  FORMAT ( 7I8 )                                                     
       IF  ( ABS ( JNT(ACT(J)%ACT_JNT)%JTYPE ) .NE. I_1 )  THEN                 
        WRITE ( LUAOU, 120 ) J                                             
  120   FORMAT ( ' The actuator joint for actuator no. ', I3, 
     &           ' must be a pin type joint.' )            
        STOP ' STOP 111 in Subroutine INPUT_ROBOTICS'                                                          
       END IF
!C
!C     Check to see if the specified base segment for the actuator
!C      is equal to either the proximal segment of the joint the 
!C      actuator is associated with, or to the distal segment of the
!C      joint the actuator is associated with.
!C
       IF ( ( ACT(J)%BASE_SEG .EQ. 
     &        JNT(ACT(J)%ACT_JNT)%PROX_SEG ) .OR. 
     &      ( ACT(J)%BASE_SEG .EQ. 
     &      ( ACT(J)%ACT_JNT + I_1 ) ) )  THEN                  
!C
!C      Get the pin joint axis for the joint associated with the 
!C       actuator.
!C
        IF ( ACT(J)%BASE_SEG .EQ. 
     &       JNT(ACT(J)%ACT_JNT)%PROX_SEG )  THEN
         DO  I=1,3                                                         
          ACT(J)%TOR_AXIS(I) = HT(I,2,2*ACT(J)%ACT_JNT-1)                                  
         END DO
        ELSE
         DO I=1,3
          ACT(J)%TOR_AXIS(I) = HT(I,2,2*ACT(J)%ACT_JNT)  
         END DO
        END IF
       ELSE
        WRITE ( LUAOU, 125 ) J                                             
  125   FORMAT ( ' Improper segment input for an actuator joint for ',
     &           ' actuator no. ', I2, '.' )       
        STOP ' STOP 112 in Subroutine INPUT_ROBOTICS'                                                         
       END IF
!C
      END DO                                                              
!C                                                                      
      RETURN                                                            
      END                                                               
