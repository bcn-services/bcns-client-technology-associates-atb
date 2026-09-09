      SUBROUTINE  INPUT_HCARDS ( JRNUM ) 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine reads and echoes in the H.1 through H.11 card input.
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       INTEGER_STD, LUAOU, I_3, I_7     ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )   JRNUM, K, KPASS
!C
      INTENT ( OUT )  JRNUM
!C                                                                        
!C    Read card input for output control.                                 
!C                                                                        
!C     1. No. of point total accelerations ,point nos. and location       
!C     2. No. of point rel. velocities, point nos. and location           
!C     3. No. of point rel. linear  displacements ,point nos. and loc. 
!C     4. No. of segment angular accelerations and segment nos.           
!C     5. No. of segment rel. angular velocities and segment nos.         
!C     6. No. of segment rel. angular displacements and segment nos.      
!C     7. No. of joint parameters and joint nos.                         
!C     8. No. of segment wind forces and segment nos.                     
!C     9. No. of joint forces and torque nos.                             
!C    10. No. of center of gravity and related information                
!C    11. No. of actuator joint torque nos.                                
!C                                                                        
      WRITE ( LUAOU, 100 )                                                
  100 FORMAT ( 1X, /, 2X, 'Tabular Time History Control Parameters' )     
      WRITE ( LUAOU, 105 )                                                
  105 FORMAT ( 3X, 'Type  KSG     Selected Segments or Joints' )         
!C
      DO  K=1,9                                                         
       KPASS = K
!C                                                                        
!C     Input Cards H.(K) for K = 1,3                                         
!C                                                                        
       IF ( K .LE. I_3 )  THEN
!C
!C    Check for comments.
!C
        CALL CHECK_COMMENT
        CALL INPUT_H1_H3_CARDS ( KPASS )
!C                                                                        
!C     Input Cards H.(K) for K = 4, 5, 6, 8, 9.                                     
!C                                                                        
       ELSE IF ( K .NE. I_7 )  THEN
        CALL CHECK_COMMENT
        CALL INPUT_H4_H9_CARDS ( JRNUM, KPASS )
!C                                                                        
!C     Input Cards H.(K) for K= 7.                                    
!C                                                                        
       ELSE
        CALL CHECK_COMMENT
        CALL INPUT_H7_CARDS
       END IF
      END DO
!C                                                                        
!C    Read the H.10 Cards for the Total Body properties.                              
!C                                                                        
      CALL CHECK_COMMENT
      CALL INPUT_H10_CARDS
!C                                                                        
!C    Read the H.11 Cards for the actuator joint torque time histories.                                           
!C                                                                        
      CALL CHECK_COMMENT
      CALL INPUT_H11_CARDS
!C
      RETURN
      END
      