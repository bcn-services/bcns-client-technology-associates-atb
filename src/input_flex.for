      SUBROUTINE INPUT_FLEX
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine inputs and echoes the flexible element 
!C     parameters.
!C
      USE  MODULE_STANDARD, ONLY: 
     &        NFLX, NPG,                                    ! /CONTRL/
     &        HF, NFLEX,                                    ! /FLXBLE/
     &        INTEGER_STD, LUAIN, LUAOU, MAXJNT, MAXFLX,    ! parameters
     &        I_0, I_1, I_4, I_10, I_18, LULIN,             ! parameters
     &        LIN_FLAG, AIN_CONVERT, ICHAR_STD, LUTERM_OUT  ! parameters
!C 
      IMPLICIT  NONE
!C
      INTEGER   ( INTEGER_STD )  I, J, J1, J2, JJ, K, KNT, L, LL, 
     &                           N, NFX, NREM
      DIMENSION   KNT(MAXJNT) 
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  26, KIND = ICHAR_STD )  A_FRMT_26
      CHARACTER ( LEN =  27, KIND = ICHAR_STD )  A_FRMT_27
!C
!C    Input and print Cards B.7                                           
!C    Card B.7.a  NFX: no. of interior segments of flexible elements.     
!C                KNT(J),J=1,NFX: the segment numbers.                    
!C                                                                       
!C
!C    Note: for list-directed input, NFX is on the first
!C     B.7.a card, followed by cards with interior segments
!C     listed with up to 18 per card.
!C
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )  NFX                       
       N = NFX / I_18
       NREM = MOD ( NFX, I_18 )
       IF ( N .NE. I_0 )  THEN
        J1 = I_1
        J2 = I_18
        DO I=1,N
         READ ( LULIN, * ) ( KNT(J), J=J1,J2 )                       
         J1 = J1 + I_18
         J2 = J2 + I_18
        END DO
        IF ( NREM .GT. I_0 )  THEN
         J1 = N * I_18 + I_1
         J2 = J1 + NREM - I_1
         READ ( LULIN, * ) ( KNT(J), J=J1,J2 )                       
        END IF
       ELSE
        READ ( LULIN, * ) ( KNT(J), J=1,NFX )                       
       END IF
      ELSE
       READ ( LUAIN, 100 )  NFX, ( KNT(J), J=1,NFX )                       
  100  FORMAT ( 18I4 )                                                  
       IF ( NFX .LE. I_0 )  THEN
        WRITE ( LUTERM_OUT, 105 )  NFX
        WRITE ( LUAIN, 105 )  NFX
  105   FORMAT ( 1X, 'The value for NFX, ', I4, 'can not be',
     &               ' less than 1. ' )
        STOP ' STOP 790 in Subroutine INPUT_FLEX'
       END IF
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 110 )  NFX, 'Card B.7.a.1'
  110   FORMAT ( 1X, I6, 2X, A )
        N = NFX / I_18
        NREM = MOD ( NFX, I_18 )
        IF ( NREM .LT. I_10 )  THEN
         WRITE ( ALEN1, 115 )  NREM
  115    FORMAT ( I1 )
         READ ( ALEN1, 120 )  AL1
  120    FORMAT ( A1 )
         A_FRMT_26 = '( 1X, ' // AL1 // '( I6, 1X ), 1X, A )'
        ELSE
         WRITE ( ALEN2, 125 )  NREM
  125    FORMAT ( I2 )
         READ ( ALEN2, 130 )  AL2
  130    FORMAT ( A2 )
         A_FRMT_27 = '( 1X, ' // AL2 // '( I6, 1X ), 1X, A )'
        END IF
!C
        IF ( N .GT. I_0 )  THEN
         J1 = I_1
         J2 = I_18
         DO I=1,N
          WRITE ( LULIN, 135 ) ( KNT(J), J=J1,J2 ), 'Card B.7.a.2'                       
  135     FORMAT ( 1X, 18( I6, 1X ), 1X, A )  
          J1 = J1 + I_18
          J2 = J2 + I_18
         END DO                                                
         J1 = N * I_18 + I_1
         J2 = J1 + NREM - I_1
         IF ( NREM .GT. I_0 )  THEN
          IF ( NREM .LT. I_10 )  THEN
           WRITE ( LULIN, A_FRMT_26 ) ( KNT(J), J=J1,J2 ), 
     &                                'Card B.7.a.2'                       
          ELSE
           WRITE ( LULIN, A_FRMT_27 ) ( KNT(J), J=J1,J2 ), 
     &                                'Card B.7.a.2'                       
          END IF
         END IF
        ELSE
         IF ( NFX .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_26 ) ( KNT(J), J=1,NFX ), 
     &                               'Card B.7.a.2'                       
         ELSE
          WRITE ( LULIN, A_FRMT_27 ) ( KNT(J), J=1,NFX ), 
     &                               'Card B.7.a.2'                       
         END IF
        END IF
       END IF
      END IF
!C
      IF ( NFX .NE. NFLX )  THEN
       WRITE ( LUAOU, 140 )  NFX, NFLX                                    
  140  FORMAT ( '0Input error on Card B.7.A, NFX =', I4,
     &          ' But NFLX =', I4, /,  
     &          ' as computed from Cards B.3. Program Terminated.' )    
       STOP 4                                         
      END IF
!C
      WRITE ( LUAOU, 145 )  NPG                                                     
  145 FORMAT ( '1', 122X, 'Page', I5, /, 121X, 'Cards B.7' )                          
      NPG = NPG + I_1                                                            
!C
      DO  JJ=1,NFX                                                     
       DO  K=1,NFLX                                                      
        IF ( KNT(JJ) .EQ. NFLEX(2,K) )  THEN
         IF ( NFLX .GT. MAXFLX )  THEN
          STOP 99                                   
         ELSE
          EXIT
         END IF
        ELSE
         WRITE ( LUAOU, 150 )  KNT(JJ)                                              
  150    FORMAT ( '0Input error on Card B.7, Segment No.', I4,
     &            ' is not an interior segment of a flexible element',
     &            ' from data on Cards B.3.', /,  
     &            ' Program Terminated.' )                                
         STOP 5                                                             
        END IF
       END DO                                                           
!C                                                                      
!C     Cards B.7  HF array for segment KNT(JJ).                            
!C                                                                        
       IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  ( HF(1,J,K), J=1,12 )              
         READ ( LULIN, * )  ( HF(2,J,K), J=1,12 )              
         READ ( LULIN, * )  ( HF(3,J,K), J=1,12 )              
         READ ( LULIN, * )  ( HF(4,J,K), J=1,12 )              
       ELSE
        READ ( LUAIN, 155 )  ( ( HF(I,J,K), J=1,12 ), I=1,4 )              
  155   FORMAT ( 12F6.0 )                                                 
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 160 )  ( HF(1,J,K), J=1,12 ), 'Card B.7.b.1'              
         WRITE ( LULIN, 160 )  ( HF(2,J,K), J=1,12 ), 'Card B.7.b.2'              
         WRITE ( LULIN, 160 )  ( HF(3,J,K), J=1,12 ), 'Card B.7.b.3'              
         WRITE ( LULIN, 160 )  ( HF(4,J,K), J=1,12 ), 'Card B.7.b.4'              
  160    FORMAT ( 1X, 12( F15.7, 1X ), 1X, A )                                                 
        END IF
       END IF
       DO  LL=1,3                                                       
        L = ( LL - I_1 ) * I_4                                               
        DO  I=1,4                                                        
         DO  J=1,4                                                       
          IF ( HF(I,J+L,K) .NE. HF(J,I+L,K) )  STOP 100                      
         END DO
        END DO
       END DO
       WRITE ( LUAOU, 165 ) KNT(JJ), K, ( NFLEX(I,K), I=1,3 ),                
     &                      ( ( HF(I,J,K), J=1,12 ), I=1,4 )                        
  165  FORMAT ( '0 HF Array for Interior Segment No.', I4, 20X,    
     &          '(NFLEX(I,', I1, '),I=1,3) =', 3I6, //,                    
     &          ( 3X, 4F10.4, 3X, 4F10.4, 3X, 4F10.4 ) )                       
      END DO 
!C
      RETURN
      END
      