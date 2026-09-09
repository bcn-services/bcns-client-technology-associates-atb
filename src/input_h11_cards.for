      SUBROUTINE  INPUT_H11_CARDS
!c
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine reads H.11 card input.
!C     It is called only by Subroutine INPUT_HCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NRTORQ,                                        ! /ACTFR/
     &       NGRND,                                         ! /CONTRL/
     &       KREF, MJS, MSG, NSG,                           ! /RSAVE/
     &       ACT,                                           ! structures
     &       INTEGER_STD, LUAIN, LUAOU, LUTERM_OUT,         ! parameters
     &       I_0, I_1, I_10, MAX_HCARD_TTH,                 ! parameters
     &       AIN_CONVERT, LULIN, LIN_FLAG, ICHAR_STD        ! parameters
!C
!C    ACT_JNT, BASE_SEG                   !ACT%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &             J, K, KSG 
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  34, KIND = ICHAR_STD )  A_FRMT_34
      CHARACTER ( LEN =  35, KIND = ICHAR_STD )  A_FRMT_35
!C
      K = I_10                                                        
C
      IF ( NRTORQ .GT. I_0 )  THEN                                
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  KSG, ( MSG(J,K), J=1,KSG )                 
        IF ( KSG .LT. I_1 )  THEN
         WRITE ( LUTERM_OUT, 100 ) KSG
         WRITE ( LUAIN, 100 ) KSG
  100    FORMAT ( 1X, 'Number of actuator torques ', I4, 
     &            ' must be greater than 0.' )
         STOP ' STOP 741 in Subroutine INPUT_H11_CARDS'
        END IF    
       ELSE
        READ ( LUAIN, 105 )  KSG, ( MSG(J,K), J=1,KSG )                 
  105   FORMAT ( 12I6, /, ( I12, 10I6 ) )                                
        IF ( KSG .LT. I_1 )  THEN
         WRITE ( LUTERM_OUT, 100 ) KSG
         WRITE ( LUAIN, 100 ) KSG
         STOP ' STOP 742 in Subroutine INPUT_H11_CARDS'
        END IF    
!C
!C      For list-directed input, no blank or 2nd card is required.
!C
        IF ( AIN_CONVERT )  THEN
         IF  ( KSG .LT. I_10  )  THEN
          WRITE ( ALEN1, 110 ) KSG
  110     FORMAT ( I1 )
          READ ( ALEN1, 115 ) AL1
  115     FORMAT ( A1 )
          A_FRMT_34 = '( 1X, I6, 1X, ' // AL1 // 
     &                '( I6, 1X ), 1X, A )' 
         ELSE IF ( KSG .GE. I_10 )  THEN
          WRITE ( ALEN2, 120 ) KSG
  120     FORMAT ( I2 )
          READ ( ALEN2, 125 ) AL2
  125     FORMAT ( A2 )
          A_FRMT_35 = '( 1X, I6, 1X, ' // AL2 // 
     &                '( I6, 1X ), 1X, A )' 
         END IF
         IF ( KSG .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_34 )  KSG, ( MSG(J,K), J=1,KSG ), 
     &                                'Card H.11'                
         ELSE
          WRITE ( LULIN, A_FRMT_35 )  KSG, ( MSG(J,K), J=1,KSG ), 
     &                                'Card H.11'                
         END IF
        END IF
       END IF
!C
!C     Set the reference segment array for the actuator time
!C      histories to 0 because it is not used these time histories.
!C
       DO  J=1,KSG                                                      
        KREF(J,K) = I_0                                           
       END DO
!C
!C     Test to ensure that the requested number of actuator torque
!C      tabular time histories is not too great.
!C
       IF ( KSG .GT. MAX_HCARD_TTH )  THEN
        WRITE ( LUAOU, 128 ) KSG
  128   FORMAT ( 1X, 'The number of actuator torques, ', I2, 
     &          ' for the H.11 Cards is too large.' )
        STOP ' STOP 85.11 in Subroutine INPUT_H11_CARDS '
       END IF                                      
!C
!C     Echo the Card H.11 data to the standard output file.
!C
       WRITE ( LUAOU, 130 ) ( K + I_1 ), KSG, ( MSG(J,K), J=1,KSG )         
  130  FORMAT ( '    H.', I2, 1X, I3, 3X, 20I3 )                         
       WRITE ( LUAOU, 135 ) ( KREF(J,K), J=1,KSG )                               
  135  FORMAT ( '       Ref    ', 20I3 )                                 
!C
!C     Check reference segment numbers for validity.
!C
       DO  J=1,KSG                                                       
        IF ( ( KREF(J,K) .GT. NGRND ) .OR. 
     &       ( KREF(J,K) .LT. I_0 ) )  THEN
         STOP 55                                                        
        END IF
       END DO                                                             
!C
       IF ( KSG .NE. I_0 )   THEN                                 
!C                                                                        
!C      Save actuator joint and base segment numbers for headings.             
!C                                                                        
        DO  J=1,KSG                                                       
         MJS(J,1) = ACT(MSG(J,K))%ACT_JNT                                        
         MJS(J,2) = ACT(MSG(J,K))%BASE_SEG                                           
        END DO
       END IF
!C
       NSG(K) = KSG                                                     
      ELSE                                                              
       NSG(K) = I_0                                                  
      END IF                                                            
!C
      RETURN
      END