      SUBROUTINE  HEDING_WIND ( LNEW, MT, NT, NLINES, XPAGE, KSG )
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine prints out the headings for the H.8 Card related
!C     tabular time histories, i.e. the wind force data.
!C
!C    It is called only by Subroutine HEDING.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       UNITL, UNITM, UNITT,                           ! /CNSNTS/
     &       NGRND, NPG,                                    ! /CONTRL/
     &       KREF, MSG, NSG, XSG,                           ! /RSAVE/
     &       BDYTTL, COMENT, DATE, VPSTTL,                  ! /TITLES/
     &       HEAD, USEC, ZTTH,                              ! /HEDING_TEMPVS/
     &       SEG, JNT,                                      ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LOGICAL_STD, LUAOU, NUM_TTH_OFFSET,            ! parameters 
     &       I_0, I_1, I_2, I_3, I_4, I_8                   ! parameters
!C
!C    NAME        ! SEG%
!C    JNT_NAME    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, IT, J, J1, J2, JJ, KK, KSG, MT, NLINES, NT
!C
      REAL  ( KIND = IREAL_HIGH )  PAGE, XPAGE 
!C
      CHARACTER ( LEN =  4, KIND = ICHAR_STD )   BLANK, GHED
      CHARACTER ( LEN =  8, KIND = ICHAR_STD )   HEADR
      DIMENSION        HEADR(20)
      CHARACTER ( LEN = 20, KIND = ICHAR_STD )   AHED, AHEAD
      DIMENSION        AHED(2), AHEAD(20)
!C
      LOGICAL  ( KIND = LOGICAL_STD )   LNEW
!C
      DATA BLANK / ICHAR_STD_'    ' /                                  
      DATA AHED/  ICHAR_STD_' In      Reference  ',                      
     &            ICHAR_STD_'  Accelerometer     '  /                    
      DATA GHED / ICHAR_STD_'(1G)' /                     
!C
      INTENT ( IN )  LNEW, NLINES, XPAGE, KSG
      INTENT ( INOUT )  MT, NT
!C
      DO  J1=1,KSG,I_3                                                  
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
  105   FORMAT ( 8X, 'Run Description:', 3X, A80, /, 27X, A80,
     &           'Page:', F6.2, /, 3X, 'Vehicle Deceleration:', 3X,
     &           A80, /, 11X, 'Test Subject:', 3X, A20 )                 
!C
        WRITE ( NT, 110 )  UNITM                                          
  110   FORMAT ( ' ', /, 47X, 'Segment Wind Force (', A4, ')', / )        
       J2 = MIN ( ( J1 + I_2 ), KSG )                      
       DO  J=J1,J2                                                       
        KK = MSG(J,I_8)                                                      
        HEAD(J) = SEG( ABS ( KK ) )%NAME                                    
        IF ( MSG(J,I_8)  .GE. I_0 )  THEN                                
         HEADR(J) = SEG(NGRND)%NAME              
         IF ( KREF(J,I_8) .NE. I_0 )  HEADR(J) = SEG(KREF(J,I_8))%NAME       
         AHEAD(J) = AHED(1)                                                
         AHEAD(J)(5:8) = HEADR(J)
        ELSE
         AHEAD(J)(1:16) = AHED(2)(1:16)                                    
         AHEAD(J)(17:20) = GHED                               
        END IF
       END DO                                                            
!C
       WRITE ( NT, 115 )  ( BLANK, MSG(J,I_8), HEAD(J), J=J1,J2 )              
  115  FORMAT ( '         ', 3( A4, 9X, 'Segment No.', I3, ' - ',
     &          A4, 5X ) )                                               
       WRITE ( NT, 120 )  ( BLANK, AHEAD(J), J=J1,J2 )            
  120  FORMAT ( '    Time ', 3( A4, 9X, A20, 6X ) )                         
       WRITE ( NT, 125 )  ( BLANK, J=J1,J2 )                          
  125  FORMAT ( '   (msec)', 3( A4, 5X, 'X', 8X, 'Y', 8X, 'Z', 7X,
     &          'Res', 1X ) )                                              
       WRITE ( NT,  130 )                                                   
  130  FORMAT ( 1X )                                                       
       IF  ( LNEW )  THEN                                       
        JJ = I_4 * ( J2 - J1 + I_1 )                                  
        DO  I=1,NLINES                                                     
         WRITE ( NT, 135 )  USEC(I), ( ZTTH(J,I,IT), J=1,JJ )               
  135    FORMAT ( F9.3, 3( 3X, 4F9.3 ) )                                   
        END DO
       END IF
      END DO                                                           
!C
      RETURN
      END
      