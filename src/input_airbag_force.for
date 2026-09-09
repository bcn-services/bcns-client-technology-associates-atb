      SUBROUTINE  INPUT_AIRBAG_FORCE
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the force definitions for the
!C     airbags from the F.6 cards.
!C                                                                       
!C    This subroutine is called only by Subroutine INPUT_FCARDS
!C                                                                       
      USE  MODULE_STANDARD, ONLY: 
     &               MBAG, NBAG, MNBAG,                  ! /JBARTZ/
     &               KTITLE,                             ! /CINPUT_TEMPVS/
     &               BAGTTL,                             ! /TITLES/
     &               SEG,                                ! structures
     &               INTEGER_STD, LUAIN, LUAOU, I_0,     ! parameters
     &               I_10, LIN_FLAG, LULIN, AIN_CONVERT, ! parameters
     &               ICHAR_STD                           ! parameters
!C
!C    NAME        ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) 
     &         I, IJK_LCL, J, K, NK
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  39, KIND = ICHAR_STD )  A_FRMT_39
      CHARACTER ( LEN =  40, KIND = ICHAR_STD )  A_FRMT_40
!C
      IJK_LCL = I_0                                              
      DO  J=1,NBAG                                                      
!C                                                                       
!C     Input card F.6.                                              
!C                                                                       
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  K, NK, ( MBAG(2,I,J), MBAG(3,I,J), I=1,NK )  
       ELSE
        READ ( LUAIN, 100 )  K, NK, ( MBAG(2,I,J), MBAG(3,I,J), I=1,NK )  
  100   FORMAT ( 2I4, 20I2 )                                              
        IF ( AIN_CONVERT )  THEN
         IF ( NK .LT. I_10 ) THEN
          WRITE ( ALEN1, 105 ) NK
  105     FORMAT ( I1 )
          READ ( ALEN1, 110 ) AL1
  110     FORMAT ( A1 )
          A_FRMT_39 = '( 1X, 2( I4, 1X ), ' // AL1 // 
     &                '( I4, 1X ), 1X, A )'
         ELSE
          WRITE ( ALEN2, 115 ) NK
  115     FORMAT ( I2 )
          READ ( ALEN2, 120 ) AL2
  120     FORMAT ( A2 )
          A_FRMT_40 = '( 1X, 2( I4, 1X ), ' // AL2 // 
     &                '( I4, 1X ), 1X, A )'
         END IF
         IF ( NK .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_39 )  K, NK, ( MBAG(2,I,J), 
     &                                MBAG(3,I,J), I=1,NK ), 'Card F.6'  
         ELSE
          WRITE ( LULIN, A_FRMT_40 )  K, NK, ( MBAG(2,I,J), 
     &                                MBAG(3,I,J), I=1,NK ), 'Card F.6'  
         END IF
        END IF
       END IF
!C
       MNBAG(J) = NK                                                     
       IF ( NK .EQ. I_0 )  CYCLE                                     
       IF ( IJK_LCL .EQ. I_0 )   THEN
        WRITE ( LUAOU, 125 )                
  125   FORMAT ( ////, 5X, 'Airbag', 4X, 'vs.', 4X, 'Segments',
     &           90X, 'Cards F.6' )                                      
       END IF
       IF ( K .NE. J )  THEN
        WRITE ( LUAOU, 130 )                                   
  130   FORMAT ( ' Contact input error. Program terminated.' )        
        STOP ' STOP 20 in Subroutine INPUT_AIRBAG_FORCE '                                     
       END IF
       WRITE ( LUAOU, 135 )  J, ( MBAG(2,I,J), MBAG(3,I,J), I=1,NK )     
  135  FORMAT ( '0     NO.', I2, 12X, 10( I3, '-', I3 ) )               
       DO  I=1,NK                                                        
        K = MBAG(2,I,J)                                                  
        KTITLE(I) = SEG(K)%NAME                                       
       END DO
       WRITE ( LUAOU, 140 )  BAGTTL(J), ( KTITLE(I), I=1,NK )             
  140  FORMAT ( 1X, A20, 10( 3X, A4 ) )                                  
      END DO                                                            
!C
      RETURN
      END
