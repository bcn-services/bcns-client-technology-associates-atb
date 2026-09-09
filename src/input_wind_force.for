      SUBROUTINE  INPUT_WIND_FORCE
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Also sets up tables to control time history information for         
!C    each function for each allowed contact, as well as inputting
!C    the airbag and wind force functions.                       
!C                                                                        
!C    This subroutine is called only by Subroutine INPUT_FCARDS.
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:
     &               NPG, NSEG,                             ! /CONTRL/
     &               FUNC_TITLE,                            ! /CINPUT_TEMPVS/
     &               PLTTL,                                 ! /TITLES/
     &               MWSEG, IWIND, WTIME, MOWSEG, MOWELP,   ! /WINDFR/
     &               SEG,                                   ! structures
     &               ICHAR_STD, INTEGER_STD, LUAIN, LUAOU,  ! parameters
     &               I_0, I_1, I_10, I_18, D_0, LULIN,      ! parameters
     &               AIN_CONVERT, LIN_FLAG, LUTERM_OUT      ! parameters
!C
!C    NAME        ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) 
     &         I, IPAGE, J, J1, J2, K, M3, M4, M5, M6, M7, N, NREM
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  20, KIND = ICHAR_STD )  BLANK_20, IN_TITLE
      CHARACTER ( LEN =  26, KIND = ICHAR_STD )  A_FRMT_26
      CHARACTER ( LEN =  27, KIND = ICHAR_STD )  A_FRMT_27
      CHARACTER ( LEN =  34, KIND = ICHAR_STD )  A_FRMT_34
      CHARACTER ( LEN =  35, KIND = ICHAR_STD )  A_FRMT_35
!C
      BLANK_20 = '                    '
!C
!C    Input Cards F.7.a - F.7.c, the wind force function parameters. 
!C     Note that Cards F.7.c are new to Version V.2 to account for 
!C     more than 18 segments and to make the input format more
!C     flexible.                    
!C
      N = NSEG / I_18
      NREM = MOD ( NSEG, I_18 )
      IF ( LIN_FLAG )  THEN
       IF ( N .NE. I_0 )  THEN 
        J1 = I_1
        J2 = I_18
        DO I=1,N
         READ ( LULIN, * ) ( MWSEG(1,J), J=J1,J2 )                
         J1 = J1 + I_18
         J2 = J2 + I_18
        END DO
        IF ( NREM .GT. I_0 )  THEN
         J1 = N * I_18 + I_1
         J2 = J1 + NREM - I_1
         READ ( LULIN, * ) ( MWSEG(1,J), J=J1,J2 )
        END IF
       ELSE
        READ ( LULIN, * ) ( MWSEG(1,J), J=1,NSEG )                
       END IF
      ELSE
       READ  ( LUAIN, 100 )  ( MWSEG(1,J), J=1,NSEG )                       
  100  FORMAT ( 18I4 )                                                   
       IF ( AIN_CONVERT )  THEN
!C
!C      Determine the number of F.7.a cards needed and the
!C       number of elements for a "non-full" card.
!C
        IF ( NREM .NE. I_0 )  THEN 
         IF ( NREM .LT. I_10 ) THEN
          WRITE ( ALEN1, 105 ) NREM
  105     FORMAT ( I1 )
          READ ( ALEN1, 110 ) AL1
  110     FORMAT ( A1 )
          A_FRMT_26 = '( 1X, ' // AL1 // '( I4, 1X ), 1X, A )'
         ELSE
          WRITE ( ALEN2, 115 ) NREM
  115     FORMAT ( I2 )
          READ ( ALEN2, 120 ) AL2
  120     FORMAT ( A2 )
          A_FRMT_27 = '( 1X, ' // AL2 // '( I4, 1X ), 1X, A )'
         END IF
        END IF
!C
!C      Write out the F.7.a cards with a variable number of elements.
!C
        IF ( N .NE. I_0 )  THEN
         J1 = I_1
         J2 = I_18
         DO I=1,N
          WRITE ( LULIN, 125 ) ( MWSEG(1,J), J=J1,J2 ), 'Card F.7.a'                
  125     FORMAT ( 1X, 18( I4, 1X ), 1X, A )                                                  
          J1 = J1 + I_18
          J2 = J2 + I_18
         END DO
         IF ( NREM .NE. I_0 )  THEN
          J1 = N * I_18 + I_1
          J2 = J1 + NREM - I_1
          IF ( NREM .LT. I_10 )  THEN
           WRITE ( LULIN, A_FRMT_26 ) ( MWSEG(1,J), J=J1,J2 ), 
     &                                'Card F.7.a'
          ELSE
           WRITE ( LULIN, A_FRMT_27 ) ( MWSEG(1,J), J=J1,J2 ), 
     &                                'Card F.7.a'
          END IF
         END IF
        ELSE
         IF ( NSEG .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_26 ) ( MWSEG(1,J), J=1,NSEG ), 
     &                               'Card F.7.a'
         ELSE
          WRITE ( LULIN, A_FRMT_27 ) ( MWSEG(1,J), J=1,NSEG ), 
     &                               'Card F.7.a'
         END IF
        END IF
       END IF
      END IF
!C 
!C    Test input values.
!C
      DO J=1,NSEG
       IF ( ( MWSEG(1,J) .EQ. I_0 ) .OR. ( MWSEG(1,J) .EQ. I_1 ) ) THEN
        CYCLE
       ELSE
        WRITE ( LUTERM_OUT, 127 )  J
  127   FORMAT ( 1X, ' Invalid value specified for MWSEG(1,J) for ',
     &           'segment ', I4, '.' )
        STOP ' STOP 376 in Subroutine INPUT_WIND_FORCE'
       END IF
      END DO
!C 
      IPAGE = I_0                                                    
      DO  J=1,NSEG                                                        
       IWIND(J) = I_0                                                  
       WTIME(J) = D_0                                                   
       IF ( MWSEG(1,J) .EQ. I_0 )  CYCLE                             
       IF ( IPAGE .EQ. I_0 )   THEN
        WRITE ( LUAOU, 130 )  NPG                                            
  130   FORMAT ( '1 Segment Wind Forces', 102X, 'Page', I5, /, 120X,
     &           'Cards F.7',/, 75X, 'Drag Coefficient     Blocking', /,  
     &           ' Segment-Ellipsoid   Segment-Plane',                    
     &           16X,'Wind Force Function', 10X, 'Function', 9X,         
     &           'Segments-Ellipsoid' )                                   
        NPG = NPG + I_1
       END IF
       IPAGE = I_1                                                    
!C
!C     Read in Cards F.7.b. and, for Version V.2, with list-directed
!C      input, Cards F.7.c.
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * ) ( MWSEG(I,J), I=1,7 ) 
        IF  ( ( MWSEG(7,J) .NE. I_0 ) .AND. 
     &        ( MWSEG(1,J) .GT. I_0 ) )  THEN
         WRITE ( LUTERM_OUT, 135 ) J
         WRITE ( LUAOU, 135 ) J
  135    FORMAT ( 1X, ' Segment number is not negative, but blocking',
     &                ' is specified for segment ', I4, '.' )
         STOP ' STOP 392 in Subroutine INPUT_WIND_FORCE'
        END IF
       ELSE
        READ ( LUAIN, 140 ) ( MWSEG(I,J), I=1,7 ), 
     &                      ( MOWSEG(K,J), MOWELP(K,J), 
     &                        K=1,MWSEG(7,J) )
  140   FORMAT ( 7I4, 22I2, /, ( 28X, 14I2 ) )                              
!C
        IF  ( ( MWSEG(7,J) .NE. I_0 ) .AND. 
     &        ( MWSEG(1,J) .GT. I_0 ) )  THEN
         WRITE ( LUTERM_OUT, 135 ) J
         WRITE ( LUAOU, 135 ) J
         STOP ' STOP 393 in Subroutine INPUT_WIND_FORCE'
        END IF
!C        
        IF ( AIN_CONVERT )  THEN
!C
!C       Write out the F.7.b cards.
!C
         WRITE ( LULIN, 145 ) ( MWSEG(I,J),  I=1,7 ), 'Card F.7.b' 
  145    FORMAT ( 1X, 7( I4, 1X ), 1X, A )
!C
!C       Determine the number of F.7.c cards needed and the
!C        number of elements for a "non-full" card for list-directed
!C        input.
!C
         N = MWSEG(7,J) / I_18
         NREM = MOD ( MWSEG(7,J), I_18 )
         IF ( NREM .NE. I_0 )  THEN 
          IF ( NREM .LT. I_10 ) THEN
           WRITE ( ALEN1, 150 ) NREM
  150      FORMAT ( I1 )
           READ ( ALEN1, 155 ) AL1
  155      FORMAT ( A1 )
           A_FRMT_34 = '( 1X, ' // AL1 // '( I4, 1X, I4, 1X ), 1X, A )'
          ELSE
           WRITE ( ALEN2, 160 ) NREM
  160      FORMAT ( I2 )
           READ ( ALEN2, 165 ) AL2
  165      FORMAT ( A2 )
           A_FRMT_35 = '( 1X, ' // AL2 // '( I4, 1X, I4, 1X ), 1X, A )'
          END IF
         END IF

!C
!C       Write out the F.7.c cards with a variable number of elements.
!C
         IF ( MWSEG(7,J) .NE. I_0 )  THEN
          IF ( N .GT. I_0 )  THEN
           DO I=1,N
            WRITE ( LULIN, 170 ) ( MOWSEG(K,J), 
     &                             MOWELP(K,J), K=1,I_18 ), 'Card F.7.c'                
  170       FORMAT ( 1X, 18( I4, 1X, I4, 1X ), 1X, A )                                                  
           END DO
           IF ( NREM .NE. I_0 )  THEN
            IF ( NREM .LT. I_10 )  THEN
             WRITE ( LULIN, A_FRMT_34 ) ( MOWSEG(K,J), 
     &                                    MOWELP(K,J), K=1,NREM ),
     &                                    'Card F.7.c'
            ELSE
             WRITE ( LULIN, A_FRMT_35 ) ( MOWSEG(K,J), 
     &                                    MOWELP(K,J), K=1,NREM ), 
     &                                    'Card F.7.c'
            END IF
           END IF
          ELSE
           IF ( NREM .LT. I_10 )  THEN
            WRITE ( LULIN, A_FRMT_34 ) ( MOWSEG(K,J), 
     &                                   MOWELP(K,J), K=1,NREM ), 
     &                                   'Card F.7.c'
           ELSE
            WRITE ( LULIN, A_FRMT_35 ) ( MOWSEG(K,J), 
     &                                   MOWELP(K,J), K=1,NREM ), 
     &                                   'Card F.7.c'
           END IF
          END IF
         END IF
        END IF
       END IF
!C
!C     Read in the Cards F.7.c if there are blocking ellipsoids for
!C      list-directed input.
!C
       IF ( LIN_FLAG )  THEN
        IF ( MWSEG(7,J) .GT. I_0 )  THEN
         N =  MWSEG(7,J) / I_18 
         NREM = MOD ( MWSEG(7,J), I_18 )
         IF ( N .NE. I_0 )  THEN 
          DO I=1,N
           READ ( LULIN, * ) ( MOWSEG(K,J), MOWELP(K,J), K=1,I_18 )                
          END DO
          READ ( LULIN, * ) ( MOWSEG(K,J), MOWELP(K,J), K=1,NREM )
         ELSE
          READ ( LULIN, * ) ( MOWSEG(K,J), MOWELP(K,J), 
     &                        K=1,MWSEG(7,J) )                
         END IF
        END IF
       END IF
!C
!C     Echo the input to the standard output file.
!C
       WRITE ( LUAOU, 175 )  ( MWSEG(I,J), I=1,6 )                         
  175  FORMAT ( '0', I6, ' -', I3, I13, ' -', I3, I31, I23 )              
       IF ( ABS ( MWSEG(1,J) ) .NE. J )   THEN
        WRITE ( LUTERM_OUT, 180 )
        WRITE ( LUAOU, 180 )                                               
  180   FORMAT ( ' Contact input error. Program terminated.' )          
        STOP ' STOP 21 in Subroutine INPUT_WIND_FORCE '
       END IF
       M3 = MWSEG(3,J)                                                    
       M4 = MWSEG(4,J)                                                    
       M5 = MWSEG(5,J)                                                   
       M6 = MWSEG(6,J)                                                    
       M7 = MWSEG(7,J)                                                    
       IN_TITLE = BLANK_20                                                
       IF ( M6 .NE. I_0 )  IN_TITLE = FUNC_TITLE(M6)                             
       WRITE ( LUAOU, 185 )  SEG(J)%NAME, SEG(M3)%NAME, PLTTL(M4),       
     &                  FUNC_TITLE(M5), IN_TITLE,   
     &                  ( MOWSEG(K,J),  K=1,2*M7 )                       
  185  FORMAT ( 3X, A4, 14X, A4, '-', A20, 3X, A20, 3X, A20, 2X,
     &          3( 5( I3, '-', I3 ), /, 94X ) )                           
      END DO                                                              
!C
      RETURN
      END