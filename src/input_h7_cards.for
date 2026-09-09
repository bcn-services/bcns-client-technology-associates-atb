      SUBROUTINE  INPUT_H7_CARDS 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine reads and echoes in the H.7 card input.
!C
!C    It is called only by Subroutine INPUT_HCARDS.
!C
!C    The value of K represents the following:
!C     7. No. of joint parameters and joint nos.                         
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       MSG, NSG,                                           ! /RSAVE/
     &       JNT,                                                ! structures
     &       INTEGER_STD, LUAIN, LUAOU, MAX_HCARD_TTH,           ! parameters
     &       I_0, I_4, I_7, I_10,                                ! parameters
     &       AIN_CONVERT, LULIN, LIN_FLAG, ICHAR_STD             ! parameters
!C
!C     PROX_SEG, JTYPE        ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &             J, K, KSG, L 
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  10, KIND = ICHAR_STD )  H_CARD_NUMBER_A
      CHARACTER ( LEN =  34, KIND = ICHAR_STD )  A_FRMT_34
      CHARACTER ( LEN =  35, KIND = ICHAR_STD )  A_FRMT_35
!C
!C    Set the value of K since this subroutine is only for H.7 cards.
!C
      K = I_7
!C
!C    Read in the data.
!C
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * ) KSG, ( MSG(J,K), J=1,KSG )    
      ELSE
       READ ( LUAIN, 100 ) KSG, ( MSG(J,K), J=1,KSG )    
  100  FORMAT ( 12I6, /, ( I12, 10I6 ) )                               
!C
!C     For list-directed input, no blank or 2nd card is required.
!C
       IF ( AIN_CONVERT )  THEN
        IF ( ( KSG .LT. I_10 ) .AND. ( KSG .GT. I_0 ) )  THEN
         WRITE ( ALEN1, 105 ) KSG
  105    FORMAT ( I1 )
         READ ( ALEN1, 110 ) AL1
  110    FORMAT ( A1 )
         A_FRMT_34 = '( 1X, I3, 1X, ' // AL1 // 
     &               '( I3, 1X ), 1X, A )'                               
        ELSE IF ( KSG .GE. I_10 )  THEN
         WRITE ( ALEN2, 115 ) KSG
  115    FORMAT ( I2 )
         READ ( ALEN2, 120 ) AL2
  120    FORMAT ( A2 )
         A_FRMT_35 = '( 1X, I3, 1X, ' // AL2 // 
     &               '( I3, 1X ), 1X, A )'                               
        END IF
        WRITE ( ALEN1, 105 ) K
        READ  ( ALEN1, 110 ) AL1
        H_CARD_NUMBER_A =  'Card H.' // AL1 // '.a'
!C
!C      Write the H.7 to the .LIN file.
!C
        IF ( ( KSG .LT. I_10 ) .AND. ( KSG .GT. I_0 ) )  THEN
         WRITE ( LULIN, A_FRMT_34 ) KSG, ( MSG(J,K), J=1,KSG ),
     &                              H_CARD_NUMBER_A    
        ELSE IF ( KSG .GT. I_10 )  THEN
         WRITE ( LULIN, A_FRMT_35 ) KSG, ( MSG(J,K), J=1,KSG ),
     &                              H_CARD_NUMBER_A    
        ELSE
         WRITE ( LULIN, 121 )  KSG, H_CARD_NUMBER_A
  121    FORMAT ( 1X, I2, 2X, A )
        END IF
       END IF
      END IF
!C
!C    Check to ensure that the number of selected items
!C     does not exceed the maximum number allowed.
!C
      IF ( KSG .GT. MAX_HCARD_TTH )  THEN
       WRITE ( LUAOU, 122 )  KSG
  122  FORMAT ( 1X, 'The number of joints, ', I2, ' for the H.7 Cards',
     &          ' is too large.' )
       STOP 'STOP 85.7 in Subroutine INPUT_H7_CARDS'                                       
      END IF
!C
!C    Echo the input to the .AOU file.
!C
      WRITE ( LUAOU, 125 )  K, KSG, ( MSG(J,K), J=1,KSG )                  
  125 FORMAT ( '    H.', I2, 1X, I3, 3X, 20I3 )                          
!C
!C    For Euler joints ( JTYPE = +/-4 ), make the joint number
!C     negative as flag.
!C
      IF ( KSG .NE. I_0 )   THEN              
       DO  J=1,KSG                                                        
        L = MSG(J,K)                                                      
        IF ( ABS ( JNT(L)%JTYPE ) .EQ. I_4 )   MSG(J,K) = -L                 
       END DO
      END IF
!C
!C    Store number of tabular time histories for type K to be output.
!C
      NSG(K) = KSG                                                        
!C
      RETURN
      END