      SUBROUTINE  INPUT_H4_H9_CARDS ( JRNUM, K )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine reads and echoes in the H.4 through H.9 card input
!C     except for the H.7 card, which has a slightly different format.
!C
!C     It is called only by Subroutine INPUT_HCARDS.
!C
!C    Values of K represent the following:
!C     4. No. of segment angular accelerations and segment nos.           
!C     5. No. of segment rel. angular velocities and segment nos.         
!C     6. No. of segment rel. angular displacements and segment nos.      
!C     8. No. of segment wind forces and segment nos.                     
!C     9. No. of joint forces and torque nos.                             
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NGRND, NJNT,                                        ! /CONTRL/
     &       KREF, MSG, NSG,                                     ! /RSAVE/
     &       JNT,                                                ! structures
     &       INTEGER_STD, LUAIN, LUAOU, MAX_HCARD_TTH,           ! parameters
     &       I_0, I_1, I_2, I_4, I_6, I_7, I_10,                 ! parameters
     &       AIN_CONVERT, LULIN, LIN_FLAG, ICHAR_STD             ! parameters
!C
!C     PROX_SEG        ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &        IDJNT, IDSEG, JROUT, NTDEF,    ! /FXJROT/
     &        IBODN, NFBOD                   ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &             ID, J, JM, JRNUM, K, KSG, KTMP, 
     &             MARK, MTMP, NPT1, NPT2
      DIMENSION  KTMP(MAX_HCARD_TTH), MARK(MAX_HCARD_TTH), 
     &           MTMP(MAX_HCARD_TTH)
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  10, KIND = ICHAR_STD )  H_CARD_NUMBER_A
      CHARACTER ( LEN =  42, KIND = ICHAR_STD )  A_FRMT_42
      CHARACTER ( LEN =  43, KIND = ICHAR_STD )  A_FRMT_43
!C
      INTENT (  IN )  K
      INTENT ( OUT )  JRNUM
!C
!C    Read in data.
!C
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * ) KSG, 
     &                    ( KREF(J,K), MSG(J,K), J=1,KSG )    
      ELSE
       READ ( LUAIN, 100 ) KSG, 
     &                    ( KREF(J,K), MSG(J,K), J=1,KSG )    
  100  FORMAT ( I6, 22I3, /, ( I9, 21I3 ) )                               
!C
!C     For list-directed input, no blank or 2nd card is required.
!C
       IF ( AIN_CONVERT )  THEN
        IF ( ( KSG .LT. I_10 ) .AND. ( KSG .GT. I_0 ) )  THEN
         WRITE ( ALEN1, 105 ) KSG
  105    FORMAT ( I1 )
         READ ( ALEN1, 110 ) AL1
  110    FORMAT ( A1 )
         A_FRMT_42 = '( 1X, I6, 1X, ' // AL1 // 
     &               '( I3, 1X, I3, 1X ), 1X, A )'                               
        ELSE IF ( KSG .GE. I_10 )  THEN
         WRITE ( ALEN2, 115 ) KSG
  115    FORMAT ( I2 )
         READ ( ALEN2, 120 ) AL2
  120    FORMAT ( A2 )
         A_FRMT_43 = '( 1X, I6, 1X, ' // AL2 // 
     &               '( I3, 1X, I3, 1X ), 1X, A )'                               
        END IF
        WRITE ( ALEN1, 105 ) K
        READ  ( ALEN1, 110 ) AL1
        H_CARD_NUMBER_A =  'Card H.' // AL1 // '.a'
!C
        IF ( ( KSG .LT. I_10 ) .AND. ( KSG .GT. I_0 ) )  THEN
         WRITE ( LULIN, A_FRMT_42 ) KSG, 
     &                      ( KREF(J,K), MSG(J,K), J=1,KSG ),
     &                      H_CARD_NUMBER_A    
        ELSE IF ( KSG .GE. I_10 )  THEN
         WRITE ( LULIN, A_FRMT_43 ) KSG, 
     &                      ( KREF(J,K), MSG(J,K), J=1,KSG ),
     &                      H_CARD_NUMBER_A    
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
       WRITE ( LUAOU, 123 ) KSG, K
  123  FORMAT ( 1X, ' The number of items, ', I2, ', for H card ', I2,
     &          ' is too large. ' )
       STOP ' STOP 85.K in Subroutine INPUT_H4_H9_CARDS '                                       
      END IF
!C
      WRITE ( LUAOU, 125 ) K, KSG, ( MSG(J,K), J=1,KSG )                  
  125 FORMAT ( '    H.', I2, 1X, I3, 3X, 20I3 )                          
      WRITE ( LUAOU, 130 )  ( KREF(J,K), J=1,KSG )                        
  130 FORMAT ( '       Ref    ', 20I3 )                                 
!C
      DO  J=1,KSG                                                       
       IF ( ( KREF(J,K) .GT. NGRND ) .OR. 
     &      ( KREF(J,K) .LT. I_0 ) )  THEN
        STOP 55                                                         
       END IF
      END DO                                                             
!C
!C    For end rotations of deformable segment, output as separate page.   
!C
      IF ( K .EQ. I_6 ) THEN                                        
       NTDEF = I_0                                                   
       MARK = I_0                                                   
       DO  J = 1,KSG                                                    
        IF ( KREF(J,6) .EQ. MSG(J,6) ) THEN                             
         DO  ID = 1, NFBOD                                             
          IF ( MSG(J,6) .EQ. IBODN(ID) ) THEN                           
           NTDEF = NTDEF + I_1                                      
           MARK(NTDEF) = J                                              
           IDSEG(NTDEF) = MSG(J,6)                                      
           EXIT                                                    
          END IF                                                        
         END DO                                                         
        END IF                                                          
       END DO
       IF ( NTDEF .NE. I_0 ) THEN                           
        DO  J = 1,KSG                                                   
         KTMP(J) = KREF(J,6)                                            
         MTMP(J) = MSG(J,6)                                             
         KREF(J,6) = 999_INTEGER_STD                                   
         MSG(J,6) = 999_INTEGER_STD                                    
        END DO                                                         
        NPT1 = I_1                                                     
        NPT2 = I_1                                                   
        DO  J = 1,KSG                                                     
         IF ( ( NPT1 .GT. NTDEF ) .OR. ( J .NE. MARK(NPT1) ) )  THEN     
          KREF(NPT2,6) = KTMP(J)                                         
          MSG(NPT2,6) = MTMP(J)                                          
          NPT2 = NPT2 + I_1                                        
         ELSE                                                           
          NPT1 = NPT1 + I_1                                           
         END IF                                                          
        END DO                                                           
        JRNUM = I_0
        DO  J = 1, NTDEF                                                 
         JROUT(J) = I_1
         DO  JM = 1, NJNT                                                
          IF ( JNT(JM)%PROX_SEG .EQ. IDSEG(J) )  THEN                   
           IDJNT(JROUT(J),J) = I_2 * JM - I_1
           JROUT(J) = JROUT(J) + I_1
          END IF                                                         
         END DO                                                          
         IDJNT(2,J) = IDSEG(J) - I_1                                   
         IDJNT(JROUT(J),J) = ( IDSEG(J) - I_1 ) * I_2
         JRNUM = JRNUM + JROUT(J) / I_2 + MOD ( JROUT(J), I_2 )
        END DO                                                            
        KSG = KSG - NTDEF                                                
       END IF
      END IF                                                           
!C
!C    Store number of tabular time histories for type K to be output.
!C
      NSG(K) = KSG                                                        
!C
      RETURN
      END