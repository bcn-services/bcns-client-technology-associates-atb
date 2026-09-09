      SUBROUTINE  HEDING_ACTUATORS ( LNEW, MT, NT, NLINES, XPAGE, KSG )
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine prints out the headings for the H Card related
!C     tabular time histories.
!C    It is called only by Subroutine HEDING.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       UNITL, UNITM,                                  ! /CNSNTS/
     &       NPG,                                           ! /CONTRL/
     &       MSG, MJS,                                      ! /RSAVE/
     &       BDYTTL, COMENT, DATE, VPSTTL,                  ! /TITLES/
     &       HEAD, USEC, ZTTH,                              ! /HEDING_TEMPVS/
     &       SEG, JNT,                                      ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LOGICAL_STD, LUAOU, NUM_TTH_OFFSET,            ! parameters 
     &       I_0, I_1, I_6, I_10                            ! parameters
!C
!C    NAME        ! SEG%
!C    JNT_NAME    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, IT, J, J1, J2, JJ, JJ2,  
     &         KK, KSG, MT, NLINES, NT
!C
      REAL  ( KIND = IREAL_HIGH )  PAGE, XPAGE 
!C
      CHARACTER ( LEN =  4, KIND = ICHAR_STD )   BLANK
!C
      LOGICAL  ( KIND = LOGICAL_STD )   LNEW
!C
      DATA BLANK / ICHAR_STD_'    ' /                                  
!C
      INTENT (    IN )  LNEW, NLINES, XPAGE, KSG
      INTENT ( INOUT )  MT, NT
!C                                                                          
!C      Write header for actuator torques                                   
!C
      DO  J1=1,KSG,2                                                  
       MT = MT + I_1                                                     
       NT = MT                                                             
       IF  ( LNEW )  NT = LUAOU                                           
       IT = MT - NUM_TTH_OFFSET                                            
       PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                            
       IF ( NT .EQ. LUAOU )  THEN 
        WRITE ( NT, 100 )  DATE, BLANK, NPG                                 
        NPG = NPG + I_1                                                  
       ELSE   
        WRITE ( NT, 100 )  DATE                                             
  100   FORMAT ( '1', 18X, 'Date:', 3X, A12, A4, 80X, 'Page', I5 )           
       END IF
!C
       WRITE ( NT, 105 )  COMENT(1:80), COMENT(81:160), 
     &                   PAGE, VPSTTL, BDYTTL                     
  105     FORMAT ( 8X, 'Run Description:', 3X, A80, /, 27X, A80,
     &             'Page:', F6.2, /, 3X, 'Vehicle Deceleration:', 3X,
     &             A80, /, 11X, 'Test Subject:', 3X, A20 )                 
!C                                                                          
       J2 = MIN ( ( J1 + I_1 ), KSG )                      
       WRITE ( NT, 107 )                               
  107  FORMAT ( ' ', /, 27X, 'Actuator Joint Torque ', / )     
       WRITE ( NT, 110 ) ( BLANK, MSG(J,10), J=J1,J2 )                      
  110  FORMAT ( 9X, 2( A4, 18X, 'Actuator No.', I3, 20X ) )                
!C
       DO  J=J1,J2                                                       
        KK = MSG(J,I_10)                                                      
        HEAD(J) = SEG( ABS ( KK ) )%NAME                                    
        KK = MJS(J,1)                              
        HEAD(J) = JNT(KK)%JNT_NAME                               
        JJ2 = J - J1 + I_1                                            
       END DO                                                            
!C
       WRITE ( NT, 115 ) ( BLANK, MJS(J,2), HEAD(J), MJS(J,1),            
     &                     SEG(MJS(J,1))%NAME, J=J1,J2 )                   
  115  FORMAT ( '    Time ', 2( A4, 3X, 'Joint No.', I3, ' - ', A4,        
     &          '   Base Segment No.', I3, ' - ', A4, 2X ) )               
       WRITE ( NT, 120 ) ( BLANK, J=J1,J2 )                                
  120  FORMAT ( '   (msec)', 2( A4, 2X, 'Total ', 3X, 'Prop. ', 3X,
     &          'Deri. ', 3X, 'Inte. ', 3X, 'Target', 3X, 'Current' ) )
       WRITE ( NT, 125 ) ( BLANK, J=J1,J2 )
  125  FORMAT ( 9X, 2( A4, 2X, 'Torque', 3X, 'Torque', 3X, 
     &          'Torque', 3X, 'Torque', 3X, 'Angle ', 3X, 'Angle  ' ) )
       WRITE ( NT, 130 ) ( BLANK, 
     &                     UNITL(1:2), UNITM(1:2), 
     &                     UNITL(1:2), UNITM(1:2), 
     &                     UNITL(1:2), UNITM(1:2), 
     &                     UNITL(1:2), UNITM(1:2), J=J1,J2 )
  130  FORMAT ( 9X,  ( A4, 1X, '(', A2, '-', A2, ') ', 1X, 
     &                         '(', A2, '-', A2, ') ', 1X, 
     &                         '(', A2, '-', A2, ') ', 1X,
     &                         '(', A2, '-', A2, ') ', 
     &                 1X, ' (deg) ', 1X, ' (deg) ' ), 3X,
     &               ( A4, 1X, '(', A2, '-', A2, ') ', 1X, 
     &                         '(', A2, '-', A2, ') ', 1X, 
     &                         '(', A2, '-', A2, ') ', 1X,
     &                         '(', A2, '-', A2, ') ', 
     &                 1X, ' (deg) ', 1X, ' (deg) ' ) )
       WRITE ( NT,  135 )                                                   
  135  FORMAT ( 1X )                                                       
       IF  ( LNEW )  THEN                                       
        JJ = I_6 * ( J2 - J1 + I_1 )                                   
        DO  I=1,NLINES                                                     
         WRITE ( NT, 140 )  USEC(I), ( ZTTH(J,I,IT), J=1,JJ )              
  140    FORMAT ( F9.3, 2( 3X, 6F9.1 ) )                                    
        END DO
       END IF
      END DO
!C
      RETURN
      END