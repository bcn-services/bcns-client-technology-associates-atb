      SUBROUTINE INPUT_BELTS
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine controls the reading and printing of
!C    the input cards that describe the physical dimensions of the 
!C    restraint belts.
!C                                                                         
!C    This subroutine is called only by .MAIN
!C
      USE  MODULE_STANDARD,  ONLY:
     &       BELT,                                    ! /CNTSRF/
     &       NBLT, NPG,                               ! /CONTRL/
     &       BLTTTL,                                  ! /TITLES/
     &       INTEGER_STD, LUAIN, LUAOU, I_1, I_5,     ! parameters
     &       LULIN, AIN_CONVERT, LIN_FLAG, ICHAR_STD  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, J, L 
!C
      CHARACTER  ( LEN =  20, KIND = ICHAR_STD )  ATEMP20
      CHARACTER  ( LEN =  22, KIND = ICHAR_STD )  ATEMP22
!C
      DO  J=1,NBLT                                                      
!C
!C     Check for comments.
!C
       CALL  CHECK_COMMENT
!C                                                                       
!C     Read and print Cards D.3.a, D.3.b and D.3.c for the Jth belt.   
!C                                                                      
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  BLTTTL(J)
        READ ( LULIN, * )  BELT(1,J), BELT(2,J), BELT(3,J), BELT(4,J),
     &                     BELT(5,J), BELT(6,J)
        READ ( LULIN, * )  BELT(7,J), BELT(8,J), BELT(9,J), BELT(10,J),
     &                     BELT(11,J)        
       ELSE
       READ ( LUAIN, 100 )  BLTTTL(J), ( BELT(I,J), I = 1,11 )          
  100  FORMAT ( A20, /, ( 6F12.0 ) )                                    
        IF ( AIN_CONVERT )  THEN
         ATEMP20 = ADJUSTL ( BLTTTL(J) )
         L = LEN_TRIM ( ATEMP20 )
         ATEMP22(1:L+2) = '"' // ATEMP20(1:L) // '"'       
         WRITE ( LULIN, 105 )  ATEMP22(1:L+2), 'Card D.3.a'
  105    FORMAT ( 1X, A, 2X, A )
         WRITE ( LULIN, 110 )  BELT(1,J), BELT(2,J), BELT(3,J), 
     &                         BELT(4,J), BELT(5,J), BELT(6,J), 
     &                         'Card D.3.b'
  110    FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )
         WRITE ( LULIN, 115 )  BELT(7,J),  BELT(8,J), BELT(9,J),
     &                         BELT(10,J), BELT(11,J), 'Card D.3.c'  
  115    FORMAT ( 1X, 5( F19.11, 1X ), 1X, A )
        END IF
       END IF
!C
       IF ( MOD ( J, I_5 ) .EQ. I_1 )  THEN
        WRITE ( LUAOU, 120 )  NPG                                          
  120   FORMAT ( '1 Belt Inputs', 110X, 'Page', I5, /, 
     &            120X, 'Cards D.3' )                                      
        NPG = NPG + I_1                                                 
       END IF
       WRITE ( LUAOU, 125 )  J, BLTTTL(J), 
     &                     ( BELT(I,J), I = 1,11 )                      
  125  FORMAT ( '0 Belt No.', I4, 4X, A20, //,                           
     &          30X, 'Anchor Point A', 46X, 'Anchor Point B', /,         
     &          2( 16X, 'X', 19X, 'Y', 19X, 'Z', 3X ), /, 6F20.3, //,    
     &          26X, 'Fixed Point on Segment', 45X, 'Slack(+)', /,       
     &          16X, 'X', 19X, 'Y', 19X, 'Z', 17X, 'Blank', 13X,
     &          'Length(-)', /, 5F20.3 )                               
      END DO
!C
      RETURN
      END