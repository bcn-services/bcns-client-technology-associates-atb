      SUBROUTINE  HEDING_JNT_PARM ( LNEW, MT, NT, NLINES, XPAGE, KSG )
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine prints out the headings for the H.7 Card related
!C     tabular time histories, i.e. the joint parameter data.
!C 
!C    It is called only by Subroutine HEDING.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       UNITL, UNITM,                                  ! /CNSNTS/
     &       NPG,                                           ! /CONTRL/
     &       MSG,                                           ! /RSAVE/
     &       BDYTTL, COMENT, DATE, VPSTTL,                  ! /TITLES/
     &       HEAD, USEC, ZTTH,                              ! /HEDING_TEMPVS/
     &       SEG, JNT,                                      ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LOGICAL_STD, LUAOU, NUM_TTH_OFFSET,            ! parameters 
     &       I_0, I_1, I_2, I_7                             ! parameters
!C
!C    NAME        ! SEG%
!C    JNT_NAME    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, IT, J, J1, J2, JJ, JJ2,  
     &         K2, KK, KSG, MT, NLINES, NT
!C
      REAL  ( KIND = IREAL_HIGH )  PAGE, XPAGE 
!C
      CHARACTER ( LEN =  4, KIND = ICHAR_STD )   BLANK
      CHARACTER ( LEN = 32, KIND = ICHAR_STD )   HEDJ, HEADJJ
      DIMENSION        HEDJ(2), HEADJJ(2)                               
!C
      LOGICAL  ( KIND = LOGICAL_STD )   LNEW
!C
      DATA BLANK / ICHAR_STD_'    ' /                                  
      DATA HEDJ / ICHAR_STD_'JTYPE Flexure  Azimuth  Torsion ',            
     &            ICHAR_STD_'IEULER  Prec.  Nutation   Spin  ' /          
!C
      INTENT (    IN )  LNEW, NLINES, XPAGE, KSG
      INTENT ( INOUT )  MT, NT
!C
      DO  J1=1,KSG,I_2                                                  
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
       WRITE ( NT, 105 )  COMENT(1:80), COMENT(81:160), 
     &                   PAGE, VPSTTL, BDYTTL                     
  105  FORMAT ( 8X, 'Run Description:', 3X, A80, /, 27X, A80,
     &          'Page:', F6.2, /, 3X, 'Vehicle Deceleration:', 3X,
     &          A80, /, 11X, 'Test Subject:', 3X, A20 )                 
!C
       WRITE ( NT, 110 )                                                   
  110  FORMAT ( ' ', /, 47X, 'Joint Parameters', / )                     
!C
       J2 = MIN ( ( J1 + I_1 ), KSG )                      
       DO  J=J1,J2                                                       
        KK = MSG(J,I_7)                                                      
        HEAD(J) = SEG( ABS ( KK ) )%NAME                                    
        KK = ABS ( KK )                                                   
        HEAD(J) = JNT(KK)%JNT_NAME                               
        JJ2 = J - J1 + I_1                                            
        K2 = I_1                                                     
        IF ( MSG(J,I_7) .LT. I_0 )  K2 = I_2                               
        HEADJJ(JJ2) = HEDJ(K2)                                            
       END DO                                                            
!C
!C
       WRITE ( NT, 115 ) ( BLANK, MSG(J,I_7), HEAD(J), J=J1,J2 )              
  115  FORMAT ( 9X,2( A1, 21X, 'Joint No.', I3, ' - ', A4, 20X )  )        
       WRITE ( NT, 120 ) ( BLANK, UNITL,UNITM, J=J1,J2 )                    
  120  FORMAT ( '    Time ', 2( A1, 'State', 5X, 'Joint Angles (deg)',
     &          8X, 'Total Torque (', 2A4, ') ' ) )                        
       WRITE ( NT, 125 ) ( BLANK,  HEADJJ(J), J=1,JJ2 )                     
  125  FORMAT ( '   (msec)', 2( A1, A32, 4X, 
     &          'Spring  Viscous    Res. ' ) )                             
!C 
       WRITE ( NT, 130 )                                                   
  130  FORMAT ( 1X )                                                       
       IF  ( LNEW )  THEN                                       
        JJ = I_7 * ( J2 - J1 + I_1 )                                 
        DO  I=1,NLINES                                                     
         WRITE ( NT, 135 )   USEC(I), ( ZTTH(J,I,IT), J=1,JJ )              
  135    FORMAT ( F9.3, 2( F5.0, 3E9.3, 2X, 3E9.3 ) )                       
        END DO
       END IF                                                          
!C
      END DO                                                           
!C
      RETURN
      END
      