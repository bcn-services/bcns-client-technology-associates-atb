      SUBROUTINE  INPUT_SYMMETRY
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine controls the reading and printing of
!C    the input cards that describe the body segment symmetry    
!C    options.                            
!C                                                                         
!C    This subroutine is called only by INPUT_DCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       NGRND, NPG, NSEG,                         ! /CONTRL/
     &       SYMMETRY,                                 ! /SGMNTS/
     &       INTEGER_STD, LUAOU, I_0, I_1, I_10, I_18, ! parameters
     &       AIN_CONVERT, LIN_FLAG, LUAIN, LULIN,      ! parameters
     &       ICHAR_STD                                 ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )   I, J, J1, J2, JJ, LJ, LK, 
     &                                   N, NREM, NSEG1 
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  26, KIND = ICHAR_STD )  A_FRMT_26
      CHARACTER ( LEN =  27, KIND = ICHAR_STD )  A_FRMT_27
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C                                                                        
!C    Card D.7  body segment symmetry input.                               
!C                                                                       
      N = NSEG / I_18
      NREM = MOD ( NSEG, I_18 )
      IF ( LIN_FLAG )  THEN 
       IF ( N .NE. I_0 )  THEN 
        J1 = I_1
        J2 = I_18
        DO I=1,N
         READ ( LULIN, * ) ( SYMMETRY(J), J=J1,J2 )                
         J1 = J1 + I_18
         J2 = J2 + I_18
        END DO
        IF ( NREM .NE. I_0 )  THEN
         J1 = N * I_18 + I_1
         J2 = J1 + NREM - I_1
         READ ( LULIN, * ) ( SYMMETRY(J), J=J1,J2 )
        END IF
       ELSE
        READ ( LULIN, * ) ( SYMMETRY(J), J=1,NSEG )                
       END IF
      ELSE
       READ ( LUAIN, 100 ) ( SYMMETRY(J), J=1,NSEG )                
  100  FORMAT ( 18I4 )                                                  
!C
       IF ( AIN_CONVERT )  THEN
!C
!C      Determine the number of D.7 cards needed and the
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
!C      Write out the D.7 cards with a variable number of elements.
!C
        IF ( N .NE. I_0 )  THEN
         J1 = I_1
         J2 = I_18
         DO I=1,N
          WRITE ( LULIN, 125 ) ( SYMMETRY(J), J=J1,J2 ), 'Card D.7'                
  125     FORMAT ( 1X, 18( I4, 1X ), 1X, A )                                                  
          J1 = J1 + I_18
          J2 = J2 + I_18
         END DO
         IF ( NREM .NE. I_0 )  THEN
          J1 = N * I_18 + I_1
          J2 = J1 + NREM - I_1
          IF ( NREM .LT. I_10 )  THEN
           WRITE ( LULIN, A_FRMT_26 ) ( SYMMETRY(J), J=J1,J2 ), 
     &                                'Card D.7'
          ELSE
           WRITE ( LULIN, A_FRMT_27 ) ( SYMMETRY(J), J=J1,J2 ), 
     &                                'Card D.7'
          END IF
         END IF
        ELSE
         IF ( NSEG .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_26 ) ( SYMMETRY(J), J=1,NSEG ), 
     &                               'Card D.7'
         ELSE
          WRITE ( LULIN, A_FRMT_27 ) ( SYMMETRY(J), J=1,NSEG ), 
     &                               'Card D.7'
         END IF
        END IF
       END IF
      END IF
!C
      DO  J=1,NSEG                                                       
       LJ = SYMMETRY(J)                                               
       IF ( ABS ( LJ ) .GT. NSEG )  THEN                                 
        STOP 97
       END IF
       IF ( LJ .GT. I_1 )  THEN
        LK = SYMMETRY(LJ)                                         
        IF ( ABS ( LK ) .GT. NSEG )  THEN                                
         STOP 97
        END IF
        IF ( LK .NE. J )  THEN
         STOP 96                                                         
        END IF
       ELSE IF ( LJ .LT. I_0 )  THEN
        JJ = -J                                                          
        LJ = -LJ                                                         
        LK = SYMMETRY(LJ)                                            
        IF ( ABS ( LK ) .GT. NSEG )  THEN                                 
         STOP 97
        END IF
        IF ( ( LK .NE. JJ ) .OR. ( SYMMETRY(J) .EQ. JJ ) )  THEN
         STOP 96
        END IF                                                            
       END IF
      END DO                                                              
      WRITE ( LUAOU, 130 )  ( J, J=1,NSEG )                              
  130 FORMAT ( '0 Body Segment Symmetry Input', 91X, 'Card D.7', //,    
     &         '  Seg No.', 30I4 )                                       
      WRITE ( LUAOU, 135 )  ( SYMMETRY(J), J=1,NSEG )                  
  135 FORMAT ( '0 NSYM(J)', 30I4 )                                      
      NSEG1 = NSEG + I_1                                               
      DO  J=NSEG1,NGRND                                                
       SYMMETRY(J) = I_0                                               
      END DO
!C
      RETURN
      END 
