      SUBROUTINE  INPUT_H1_H3_CARDS ( K )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine reads and echoes in the H.1 through H.3 card input.
!C     It is called only by Subroutine INPUT_H_CARDS.
!C     1. No. of point total accelerations ,point nos. and location       
!C     2. No. of point rel. velocities, point nos. and location           
!C     3. No. of point rel. linear  displacements ,point nos. and loc. 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       KREF, MCG, MCGIN, MJS, MSG, NSG, XSG,               ! /RSAVE/
     &       INTEGER_STD,  LUAIN, LUAOU, MAXDEF,                 ! parameters
     &       I_0, I_1, MAX_HCARD_TTH,                            ! parameters
     &       AIN_CONVERT, LULIN, LIN_FLAG, ICHAR_STD             ! parameters
!C
!C     PROX_SEG, JTYPE        ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &        QNOD,                          ! /FXBODY/
     &        NFBPR, NODPR,                  ! /FXOUT/
     &        IBODN, NFBOD                   ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &             I, IDUMMY, J, K, KSG 
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =  10, KIND = ICHAR_STD )  H_CARD_NUMBER_A,
     &                                           H_CARD_NUMBER_B
!C
      INTENT (  IN )  K
!C
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )  KSG, KREF(1,K), MSG(1,K),
     &                    ( XSG(I,1,K), I=1,3 ), NODPR(1,K)   
      ELSE
       READ ( LUAIN, 110 )  KSG, KREF(1,K), MSG(1,K),
     &                     ( XSG(I,1,K), I=1,3 ), NODPR(1,K)   
  110  FORMAT ( I6, 2I3, 3F12.6, I6 )                                    
       IF ( AIN_CONVERT )  THEN
        WRITE ( ALEN1, 115 ) K
  115   FORMAT ( I1 ) 
        READ ( ALEN1, 117 ) AL1
  117   FORMAT ( A1 )
        H_CARD_NUMBER_A =  'Card H.' // AL1 // '.a'
        WRITE ( LULIN, 120 )  KSG, KREF(1,K), MSG(1,K),
     &                      ( XSG(I,1,K), I=1,3 ), NODPR(1,K),
     &                      H_CARD_NUMBER_A             
  120   FORMAT ( 1X, I6, 1X, 2( I3, 1X ), 3( F19.11, 1X ), I6, 2X, A )                                    
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
       STOP ' STOP 84.K in Subroutine INPUT_H1_H3_CARDS '                                       
      END IF
!C
      DO  I=1,NFBOD
       IF ( IBODN(I) .EQ. ABS ( MSG(1,K) ) )  THEN
        NFBPR(1,K) = IBODN(I)
       END IF
      END DO
!C
      IF ( NFBPR(1,K) .GT. I_0 ) THEN                              
       DO  I=1,3                                                       
        XSG(I,1,K) = QNOD(I,NODPR(1,K),NFBPR(1,K))                     
       END DO
      END IF                                                            
!C
      IF ( KSG .LE. I_1 )  THEN
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * ) IDUMMY                  
       ELSE
        READ ( LUAIN, 125 ) IDUMMY                  
  125   FORMAT ( I2 )                                                      
        IF ( AIN_CONVERT )  THEN
         H_CARD_NUMBER_B =  'Card H.' // AL1 // '.b'
         WRITE ( LULIN, 130 ) IDUMMY, H_CARD_NUMBER_B                  
 130     FORMAT ( 1X, I2, 2X, A )                                                      
        END IF
       END IF
      ELSE                                        
       DO  J=2,KSG                                                       
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * ) KREF(J,K), MSG(J,K), 
     &                       ( XSG(I,J,K), I=1,3 ), NODPR(J,K) 
        ELSE
         READ ( LUAIN, 135 ) KREF(J,K), MSG(J,K), 
     &                       ( XSG(I,J,K), I=1,3 ), NODPR(J,K) 
  135    FORMAT ( I9, I3, 3F12.6, I6 )                                  
         IF ( AIN_CONVERT )  THEN
          H_CARD_NUMBER_B =  'Card H.' // AL1 // '.b'
          WRITE ( LULIN, 140 ) KREF(J,K), MSG(J,K), 
     &                         ( XSG(I,J,K), I=1,3 ), NODPR(J,K),
     &                         H_CARD_NUMBER_B 
  140     FORMAT ( 1X, I9, 1X, I3, 1X, 3( F19.11, 1X ), I6, 2X, A )                                  
         END IF
        END IF
!C
        DO I = 1,MAXDEF
         IF ( IBODN(I) .EQ. ABS ( MSG(J,K) ) )  THEN
          NFBPR(J,K) = IBODN(I)
         END IF
        END DO
        IF ( NFBPR(J,K) .GT. I_0 )  THEN                            
         DO  I=1,3                                                     
          XSG(I,J,K) = QNOD(I,NODPR(J,K),NFBPR(J,K))                   
         END DO
        END IF                                                         
       END DO                                                            
      END IF
!C
!C    Echo H.1 - H.3 Card input.
!C
      WRITE ( LUAOU, 145 ) K, KSG, ( MSG(J,K), J=1,KSG )                  
  145 FORMAT ( '    H.', I2, 1X, I3, 3X, 20I3 )                          
      WRITE ( LUAOU, 150 )  ( KREF(J,K), J=1,KSG )                        
  150 FORMAT ( '       Ref    ', 20I3 )                                 
!C                                                                       
       IF ( K .EQ. I_1 )  THEN                                         
        DO  J=1,KSG                                                     
         IF  ( MSG(J,K) .LT. I_0 )  THEN
          WRITE ( LUAOU, 160 )                     
  160     FORMAT ( ' Note: beginning with ATB version IV.3, the 0 G',      
     &         ' accelerometer option is not available.', /, ' All ',  
     &         'accelerometer output uses the corrected 1 G option.' )
         END IF
        END DO                                                           
       END IF                                                            
!C
!C    Store number of tabular time histories for type K to be output.
!C
      NSG(K) = KSG                                                        
!C
      RETURN
      END