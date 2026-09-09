      SUBROUTINE  INPUT_H10_CARDS
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads and echoes for the H.10 card input.
!C     It is called only by Subroutine INPUT_HCARDS.
!C
!C    10. No. of center of gravity and related information                
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       IDCG, ISEQ, ORIGIN, XYZANG,                         ! /CDH10C/
     &       NGRND,                                              ! /CONTRL/
     &       MCG, MCGIN,                                         ! /RSAVE/
     &       INTEGER_STD, LOGICAL_STD, LUAIN, LUAOU, LUTERM_OUT, ! parameters
     &       I_0, I_1, I_2, I_3, I_10, MAX_TOTAL_BODY,           ! parameters
     &       AIN_CONVERT, LULIN, LIN_FLAG, ICHAR_STD             ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &             I, ISEQ_DEFAULT, ISEQUENCE, 
     &             J, K, M, N, NMAX
      DIMENSION    ISEQ_DEFAULT(3), ISEQUENCE(3) 
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  42, KIND = ICHAR_STD )  A_FRMT_42
      CHARACTER ( LEN =  43, KIND = ICHAR_STD )  A_FRMT_43
!C
      LOGICAL  ( KIND = LOGICAL_STD )  L_VALID
!C
      DATA  
     &  ISEQ_DEFAULT / I_3, I_2, I_1 /, 
     &  NMAX / 22_INTEGER_STD / 
!C
!C    Read in Cards H.10.a.
!C
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )  MCG                                            
      ELSE
       READ ( LUAIN, 100 )  MCG                                            
  100  FORMAT ( I6 )                                                       
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 105 )  MCG, 'Card H.10.a'                                            
  105   FORMAT ( 1X, I6, 2X, A )                                                       
       END IF
      END IF
!C
      IF ( ( MCG .GT. MAX_TOTAL_BODY ) .OR. ( MCG .LT. I_0 ) ) STOP 86         
!C
!C    If no Total Body property time histories requested, return.
!C
      IF ( MCG .LT. I_1 )  RETURN
!C                                    
      DO  K=1,MCG                                                        
!C
!C     Read in Cards H.10.b.
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  M, N, ( MCGIN(I+2,K), I=1,N )                
!C
!C      Check input values.
!C
        IF ( ( M .LT. I_1 ) .OR. ( M .GT. NGRND ) ) THEN
         WRITE ( LUTERM_OUT, 110 )  M, K
         WRITE ( LUAOU, 110 ) M, K
  110    FORMAT ( 1X, ' Reference segment ', I4, ' is invalid ',
     &            'for body ', I4, '.' )
         STOP ' STOP 570 in Subroutine INPUT_H10_CARDS'
        END IF
        IF ( N .LT. I_1 )  THEN
         WRITE ( LUTERM_OUT, 115 ) N, K
  115    FORMAT ( 1X, 'The number of segment ', I4, 'for body set ',
     &           I4, ' must be greater than 0.' )
         STOP ' STOP 571 in Subroutine INPUT_H10_CARDS'
        END IF
       ELSE
        READ ( LUAIN, 120 )  M, N, ( MCGIN(I+2,K), I=1,N )                
  120   FORMAT ( 24I3 )                                                   
!C
!C      Check input values.
!C
!C
        IF  ( N .GT. NMAX )  THEN
         STOP 87                                      
        END IF
!C
        IF ( ( M .LT. I_1 ) .OR. ( M .GT. NGRND ) ) THEN
         WRITE ( LUTERM_OUT, 125 )  M, K
         WRITE ( LUAOU, 125 ) M, K
  125    FORMAT ( 1X, ' Reference segment ', I4, ' is invalid ',
     &            'for body ', I4, '.' )
         STOP ' STOP 573 in Subroutine INPUT_H10_CARDS'
        END IF
!C
        IF ( N .LT. I_1 )  THEN
         WRITE ( LUTERM_OUT, 130 ) N, K
  130    FORMAT ( 1X, 'The number of segments ', I4, 'for body set ',
     &           I4, ' must be greater than 0.' )
         STOP ' STOP 574 in Subroutine INPUT_H10_CARDS'
        END IF
!C
        IF ( AIN_CONVERT )  THEN
         IF  ( N .LT. I_10  )  THEN
          WRITE ( ALEN1, 135 ) N
  135     FORMAT ( I1 )
          READ ( ALEN1, 140 ) AL1
  140     FORMAT ( A1 )
          A_FRMT_42 = '( 1X, I4, 1X, I4, 1X, ' // AL1 // 
     &                '( I3, 1X ), 1X, A )'                               
         ELSE
          WRITE ( ALEN2, 145 ) N
  145     FORMAT ( I2 )
          READ ( ALEN2, 150 ) AL2
  150     FORMAT ( A2 )
          A_FRMT_43 = '( 1X, I4, 1X, I4, 1X, ' // AL2 // 
     &                '( I3, 1X ), 1X, A )'                               
         END IF
!C
         IF ( N .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_42 )  M, N, ( MCGIN(I+2,K), I=1,N ),
     &                           'Card H.10.b'                
         ELSE 
          WRITE ( LULIN, A_FRMT_43 )  M, N, ( MCGIN(I+2,K), I=1,N ),
     &                           'Card H.10.b'                
         END IF
        END IF
       END IF
!C
!C     Check segment numbers of the body.
!C
       DO I=1,N
        IF ( ( MCGIN(I+2,K) .LT. I_1 ) .OR. 
     &       ( MCGIN(I+2,K) .GT. NGRND ) )  THEN
         WRITE ( LUTERM_OUT, 152 )  MCGIN(I+2,K), K
  152    FORMAT ( 1X, ' Segment number ', I4, ' is invalid for ',
     &            'body set ', I4, '.' )
         STOP ' STOP 575 in Subroutine INPUT_H10_CARDS'
        END IF
       END DO
!C
!C
!C     Echo the Card H.10.b data.
!C
       WRITE ( LUAOU, 155 )  N, ( MCGIN(I+2,K), I=1,N )                 
  155  FORMAT ( '    H.10', I3, 3X, 22I3 )                              
       WRITE ( LUAOU, 160 )  M                                           
  160  FORMAT ( '       Ref    ', 20I3 )                                 
!C
!C     Read in Cards H.10.c.
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * ) ( ORIGIN(I,K),    I=1,3 ),
     &                       ( XYZANG(I,K),    I=1,3 ),                
     &                       ( ISEQUENCE(I),   I=1,3 ), IDCG(K)     
       ELSE
        READ ( LUAIN, 165 ) ( ORIGIN(I,K),    I=1,3 ),
     &                       ( XYZANG(I,K),    I=1,3 ),                
     &                       ( ISEQUENCE(I),   I=1,3 ), IDCG(K)     
  165   FORMAT ( 6F10.0, 4I2 )                                        
        IF ( AIN_CONVERT )  THEN
         WRITE( LULIN, 170 ) ( ORIGIN(I,K),    I=1,3 ),
     &                        ( XYZANG(I,K),    I=1,3 ),                
     &                        ( ISEQUENCE(I),   I=1,3 ), IDCG(K),
     &                        'Card H.10.c'     
  170    FORMAT ( 1X, 6( F17.9, 1X ), 4( I2, 1X ), 1X, A )                                        
        END IF
       END IF
!C
!C     Check if valid rotation has been entered.
!C
       CALL CHECK_ROT_SEQUENCE ( ISEQUENCE, L_VALID )
       IF ( .NOT. L_VALID )  THEN
        WRITE ( LUAOU, 175 )  K
  175   FORMAT ( 1X, 'Invalid value specified for ISEQ(*,', I1, 
     &               ').  Program terminated.' )
        STOP  ' STOP  2301 in Subroutine INPUT_H10_CARDS. '  
       END IF
!C
!C
!C     Assign default rotation sequence if input value is 0.
!C
       IF ( ISEQUENCE(1) .EQ. I_0 )  THEN
        DO J=1,3
         ISEQ(J,K) = ISEQ_DEFAULT(J)
        END DO
       ELSE
        DO J=1,3
         ISEQ(J,K) = ISEQUENCE(J)
        END DO
       END IF
!C
       WRITE ( LUAOU, 180 ) ( ORIGIN(I,K), I=1,3 ), IDCG(K)           
  180  FORMAT ( 5X, 'Ref Origin:', 3( 2X, F9.3 ), 2X,
     &          'at Total Body C.G.:', I2 )                              
       WRITE ( LUAOU, 185 )  ( XYZANG(I,K), I=1,3 ), 
     &         ( ISEQ(I,K), I=1,3 )                                    
  185  FORMAT ( 5X, 'Ref Axes:', 3( 2X, F7.1 ), 2X, 'Sequence:', 3I2 ) 
       MCGIN(1,K) = M                                                    
       MCGIN(2,K) = N                                                    
      END DO
!C
      RETURN
      END