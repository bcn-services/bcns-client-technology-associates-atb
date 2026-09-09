      SUBROUTINE  INPUT_CONSTRAINTS
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine controls the subroutines that read and print
!C    the input cards that describe constraints.                          
!C                                                                         
!C    This subroutine is called only by INPUT_DCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       UNITL,                                 ! /CNSNTS/
     &       NPG, NQ,                               ! /CONTRL/
     &       KQ1, KQ2, KQTYPE, RK1, RK2,            ! /CSTRNT/
     &       INTEGER_STD, LUAIN, LUAOU, I_1, LULIN, ! parameters
     &       AIN_CONVERT, LIN_FLAG                  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )    I, K 
!C
!C    Read and print Cards D.6 for constraint input.             
!C
      DO  K=1,NQ                                                      
!C
!C     Check for comments.
!C
       CALL  CHECK_COMMENT
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  KQTYPE(K), KQ1(K), KQ2(K),
     &                     ( RK1(I,K), I=1,3 ), ( RK2(I,K), I=1,3 )       
       ELSE
        READ ( LUAIN, 110 )  KQTYPE(K), KQ1(K), KQ2(K),
     &                     ( RK1(I,K), I=1,3 ), ( RK2(I,K), I=1,3 )       
  110   FORMAT ( 3I6, 6F6.0 )                                             
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 115 )  KQTYPE(K), KQ1(K), KQ2(K),
     &                     ( RK1(I,K), I=1,3 ), ( RK2(I,K), I=1,3 ),
     &                       'Card D.6'       
  115   FORMAT ( 1X, 3( I8, 1X ), 1X, 6( F15.7, 1X ), 1X, A )                                             
        END IF
       END IF
       IF ( K .EQ. I_1 )  THEN 
        WRITE ( LUAOU, 120 )   NPG, UNITL, UNITL                            
  120   FORMAT ( '1 Constraint Input', 105X, 'Page', I5, /,
     &           120X, 'Cards D.6', /, '   Type   Segment  ',
     &           'Segment       Point on 1st Segment (',  
     &           A4, ')', '      Point on 2nd Segment (', A4, ')', /,    
     &           '    No.    No. 1    No. 2          X        Y',
     &           '        Z              X        Y        Z', // )      
        NPG = NPG + I_1                                                  
       END IF
       WRITE ( LUAOU, 125 )   KQTYPE(K), KQ1(K), KQ2(K),
     &                      ( RK1(I,K), I=1,3 ), ( RK2(I,K), I=1,3 )     
  125  FORMAT ( I6, 2I9, 2( 6X, 3F9.3 ) )                               
      END DO                                                          
!C
      RETURN
      END