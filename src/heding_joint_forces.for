      SUBROUTINE HEDING_JOINT_FORCES ( LNEW, MT, NT, NLINES, XPAGE, 
     &                                 KSG )
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine prints out the headings for the H.9 Card related
!C     tabular time histories, i.e. the joint forces and torque time
!C     histories.
!C
!C    It is called only by Subroutine HEDING_HCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       UNITL, UNITM,                                  ! /CNSNTS/
     &       NPG, NVEH,                                     ! /CONTRL/
     &       KREF, MSG,                                     ! /RSAVE/
     &       BDYTTL, COMENT, DATE, VPSTTL,                  ! /TITLES/
     &       HEAD, USEC, ZTTH,                              ! /HEDING_TEMPVS/
     &       SEG, JNT,                                      ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LOGICAL_STD, LUAOU, NUM_TTH_OFFSET,            ! parameters 
     &       I_0, I_1                                       ! parameters
!C
!C    NAME        ! SEG%
!C    JNT_NAME    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         II, IT, J, JK, JRF, KRF, KSG, MT, NLINES, NT
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
!C    Print heading for joint forces & torques                            
!C                                                                        
      DO  II=1,KSG                                                    
       IF ( KREF(II,9) .EQ. I_0 ) THEN
        KRF = NVEH                          
       ELSE
        KRF = KREF(II,9)                   
       END IF
       JRF = MSG(II,9)                                                     
       MT = MT + I_1                                                     
       NT = MT                                                             
       IF ( LNEW ) NT = LUAOU                                             
       IT = MT - NUM_TTH_OFFSET                                            
       PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                          
       IF ( NT .EQ. LUAOU )  THEN
        WRITE ( NT, 100 )  DATE, BLANK, NPG                                 
  100   FORMAT ( '1', 18X, 'Date:', 3X, A12, A4, 80X, 'Page', I5 )           
        NPG = NPG + I_1                                                   
       ELSE
        WRITE ( NT, 100 )  DATE                                            
       END IF
!C
       WRITE ( NT,  105 )  COMENT(1:80), COMENT(81:160), 
     &                    PAGE, VPSTTL, BDYTTL       
  105  FORMAT ( 8X, 'Run Description:', 3X, A80, /, 27X, A80,
     &          'Page:', F6.2, /, 3X, 'Vehicle Deceleration:', 3X,
     &          A80, /, 11X, 'Test Subject:', 3X, A20 )                 
       WRITE ( NT, 110 )  JNT(JRF)%JNT_NAME, SEG(JRF+1)%NAME, 
     &                    SEG(KRF)%NAME       
  110  FORMAT ( ' ', /, 47X,                                              
     &          A4, ' Joint Forces & Torques on ', A4, ' in ', 
     &          A4, ' Reference' )                                         
       WRITE ( NT,  115 )                                                  
  115  FORMAT ( 1X )                                                       
       WRITE ( NT, 120 )  UNITM, UNITL, UNITM                              
  120  FORMAT ( 4X, 'Time', 7X, 'Joint Force (', A4, ' 10**2)', 10X,       
     &          'Joint Torque (', A4, '-', A4, ' 10**2)' )                 
       WRITE ( NT, 125 )                                                   
  125  FORMAT ( 3X, '(msec)', 8X, 'X', 8X, 'Y', 8X, 'Z', 14X,
     &          'X', 11X, 'Y', 11X, 'Z' )                                  
       WRITE ( NT,  130 )                                                   
  130  FORMAT ( 1X )                                                       
!C
       IF ( LNEW )  THEN                                       
        DO  JK=1,NLINES                                                    
         WRITE ( NT, 135 )  USEC(JK), ( ZTTH(J,JK,IT), J=1,6 )             
  135    FORMAT ( F9.3, 3X, 3F9.3, 3X, 3( 2X, D10.3 ) )                      
        END DO                                                             
       END IF                                                           
      END DO                                                           
!C
      RETURN
      END