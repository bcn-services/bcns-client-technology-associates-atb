      SUBROUTINE APPLY                                                    
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Applies driving joint torques to the adjacent segments.              
!C                                                                        
      USE  MODULE_STANDARD,  
     &       ONLY:  NRTORQ,                            ! /ACTFR/
     &              ACT, SEG, JNT,                     ! structures
     &              INTEGER_STD, IREAL_HIGH, I_1       ! parameters
!C
!C    ACT_JNT, BASE_SEG, TOR_AXIS, ACT_TORQ    ! ACT%
!C    DIR_COS, EXT_ANG_ACL,                    ! SEG%
!C    PROX_SEG                                 ! JNT%
!C
      IMPLICIT  NONE 
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, NRS1, NRS2
!C
      REAL  ( KIND = IREAL_HIGH )  T1, T2_LCL
      DIMENSION        T1(3), T2_LCL(3)                                    
!C                                                                        
!C    Increment through each actuator                                      
!C                                                                         
      DO  J=1,NRTORQ                                                   
!C                                                                         
!C     Get segments associated with actuator, J.                           
!C                                                                       
       NRS1 = ACT(J)%BASE_SEG                                                       
       NRS2 = ACT(J)%ACT_JNT + I_1                                             
       IF ( NRS1 .EQ. NRS2 ) 
     &            NRS2 = JNT(ACT(J)%ACT_JNT)%PROX_SEG    
!C                                                                         
!C     Call JNTFNC to obtain the value of the torque to be applied by      
!C     actuator J.                                                         
!C                                                                         
       CALL JNTFNC ( J )                                                   
!C                                                                         
!C     Obtain torque axis in both segments' reference frames               
!C                                                                         
       CALL DOT31 ( SEG(NRS1)%DIR_COS, ACT(J)%TOR_AXIS(1), T1 )                      
       CALL MAT31 ( SEG(NRS2)%DIR_COS, T1, T2_LCL )                       
!C                                                                         
!C     Add actuator torque to external angular acceleration array 
!C      for both segments              
!C                                                                         
       DO  I=1,3                                                          
        SEG(NRS1)%EXT_ANG_ACL(I) = SEG(NRS1)%EXT_ANG_ACL(I)
     &                           + ACT(J)%ACT_TORQ * ACT(J)%TOR_AXIS(I)  
        SEG(NRS2)%EXT_ANG_ACL(I) = SEG(NRS2)%EXT_ANG_ACL(I)
     &                           - ACT(J)%ACT_TORQ * T2_LCL(I)          
       END DO
      END DO                                                        
!C
      RETURN                                                              
      END                                                                 
