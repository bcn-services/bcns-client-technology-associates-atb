      SUBROUTINE HEDING_BODY_PROP ( LNEW, MT, NT, NLINES, XPAGE )
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine prints out the headings for the H.10 Card related
!C     tabular time histories, i.e., the total body property time
!C     histories.
!C
!C    It is called only by Subroutine HEDING.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       IDCG, ISEQ, ORIGIN, XYZANG,                    ! /CDH10C/
     &       UNITL, UNITM, UNITT,                           ! /CNSNTS/
     &       NPG,                                           ! /CONTRL/
     &       MCG, MCGIN,                                    ! /RSAVE/
     &       BDYTTL, COMENT, DATE, VPSTTL,                  ! /TITLES/
     &       USEC, ZTTH,                                    ! /HEDING_TEMPVS/
     &       SEG,                                           ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LOGICAL_STD, LUAOU, NUM_TTH_OFFSET, I_0, I_1   ! parameters
!C
!C    NAME        ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, IT, J, M, MT, NLINES, N, NCG, NT
!C
      REAL  ( KIND = IREAL_HIGH )  PAGE, XPAGE 
!C
      CHARACTER ( LEN =  4, KIND = ICHAR_STD )   BLANK
      CHARACTER ( LEN =  8, KIND = ICHAR_STD )   RHED
      DIMENSION        RHED(3)
!C
      LOGICAL  ( KIND = LOGICAL_STD )   LNEW
!C
      DATA BLANK / ICHAR_STD_'    ' /                                  
      DATA RHED / ICHAR_STD_'Roll ', ICHAR_STD_'Pitch', 
     &            ICHAR_STD_'Yaw  ' /                    
!C
      INTENT (    IN )  LNEW, NLINES, XPAGE
      INTENT ( INOUT )  MT, NT
!C                                                                        
!C    Print body properties controlled by H.10 cards                      
!C                                                                        
      DO  NCG=1,MCG                                                  
       MT = MT + I_1                                                     
       NT = MT                                                            
       IF ( LNEW )  NT = LUAOU                                            
       IT = MT - NUM_TTH_OFFSET                                          
       PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                             
       IF ( NT .EQ. LUAOU ) THEN 
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
       M = MCGIN(1,NCG)                                                    
       WRITE ( NT, 110 )  M, SEG(M)%NAME                                   
  110  FORMAT ( ' ', 47X, 'Body Properties - Reference Segment No.',      
     &          I3, ' (', A4, ')' )                                        
       N = MCGIN(2,NCG)                                                    
       WRITE ( NT, 115 )  ( MCGIN(I+2,NCG), I=1,N )                        
  115  FORMAT ( 15X, 'Included Segment Nos:', 20I3 )                       
       WRITE ( NT,  117 )                                                   
  117  FORMAT ( 1X )                                                       
       WRITE ( NT, 120 ) UNITL, UNITM, UNITT, UNITL, UNITM, UNITT,
     &                   UNITM, UNITL                                     
  120  FORMAT ( 14X, 'Center of Gravity', 13X, 'Linear Momentum', 17X,    
     &          'Angular Momentum', 18X, 'Kinetic Energy', /,             
     &          4X, 'Time', 11X, '(', A4, ')', 21X, '(', A4, '-',
     &          A4, ')', 19X,                                             
     &          '(', A4, '-', A4, '-', A4, ')', 20X, '(', A4, '-',
     &          A4, ')', /,                                                 
     &          3X, '(msec)', 5X, 'X', 7X, 'Y', 7X, 'Z',                  
     &          2( 10X, 'X', 10X, 'Y', 10X, 'Z' ), 6X, 'Linear', 5X,      
     &          'Angular', 5X, 'Total' )                                  
       WRITE ( NT,  125 )                                                   
  125  FORMAT ( 1X )                                                       
       IF ( LNEW )  THEN                                       
        DO  I=1,NLINES                                                     
         WRITE ( NT, 130 )  USEC(I), ( ZTTH(J,I,IT), J=1,12 )             
  130    FORMAT ( F9.3, 3F8.3, 9( 1X, D10.3 ) )                           
        END DO
       END IF
!C
!C     Print heding for inertia tensor output                            
!C
       MT = MT + I_1                                                   
       NT = MT                                                             
       IF ( LNEW )  NT = LUAOU                                            
       IT = MT - NUM_TTH_OFFSET                                            
       PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                            
       IF ( NT .EQ. LUAOU )  THEN
        WRITE ( NT, 100 )  DATE, BLANK, NPG                              
        NPG = NPG + I_1                                                
       ELSE
        WRITE ( NT, 100 )  DATE                                           
       END IF
       WRITE ( NT, 105 )  COMENT(1:80), COMENT(81:160), 
     &                   PAGE, VPSTTL, BDYTTL       
       IF ( IDCG(NCG) .EQ. I_1 )  THEN                               
        WRITE ( NT, 135 )                                                  
  135   FORMAT ( ' ', 31X, 'Body Properties - Inertia Matrix', /, 2X,    
     &           'Reference Origin: ', 'C.G. of the Total Body ' )       
        WRITE ( NT, 140 ) ( XYZANG(J,NCG), RHED(ISEQ(J,NCG)), J=1,3 ),   
     &                   M, SEG(M)%NAME                                     
  140   FORMAT ( 2X, 'Reference Axes (deg):', 3( F7.1, 1X, A5 ),         
     &           ' W.R.T. Local Axes of Segment No.', I3, ' (', A4, ')')
       ELSE IF ( IDCG(NCG) .EQ. I_0 )  THEN                           
        WRITE (NT,145) UNITL, ( ORIGIN(J,NCG), J=1,3 ), M, SEG(M)%NAME   
  145   FORMAT ( ' ', 31X, 'Body Properties - Inertia Matrix', /, 2X,    
     &           'Reference Origin (', A4, '):', 3F9.3, 1X,              
     &           'in Local Axes of Segment No.', I3, ' (', A4, ')' )     
        WRITE (NT,140) ( XYZANG(J,NCG), RHED(ISEQ(J,NCG)), J=1,3 ),      
     &                 M, SEG(M)%NAME                                      
       ELSE                                                              
        WRITE ( NT, 150 )                                                
  150   FORMAT ( ' ', 18X,
     &           'Body Properties - Principal Moment of Inertia'         
     &           /, 2X, 'Reference Origin: ', 'C.G. of the Total Body' ) 
        WRITE ( NT, 140 ) ( XYZANG(J,NCG), RHED(ISEQ(J,NCG)), J=1,3 ),   
     &                      M, SEG(M)%NAME                                 
       END IF                                                            
       WRITE ( NT, 155 )  ( MCGIN(I+2,NCG), I=1,N )                       
  155  FORMAT ( 15X, 'Included Segment Nos:', 20I3 )                       
       WRITE ( NT, 157 )                                                  
  157  FORMAT ( 1X )                                                       
       IF (  ( IDCG(NCG) .EQ. I_1 ) .OR. 
     &       ( IDCG(NCG) .EQ. I_0 ) )  THEN     
        WRITE ( NT, 160 )                                                 
  160   FORMAT ( 4X, 'TIME', 7X, 'Ixx', 11X, 'Iyy', 11X, 'Izz', 11X,
     &           'Ixy', 11X, 'Iyz', 11X, 'Izx', /, 3X, '(MSEC)', 34X,
     &           '(', 'lbs-sec**2-in', ')' )                             
       ELSE                                                              
        WRITE ( NT, 165 )                                                
  165   FORMAT ( 15X, 'Principal Moment of Inertia', 14X,                
     &           'Principal Axes in Reference System' )                  
        WRITE ( NT, 170 )                                                
  170   FORMAT ( 4X, 'Time', 7X, 'I1', 12X, 'I2', 12X, 'I3', 11X, 'Yaw',
     &           11X, 'Pitch', 10X, 'Roll', /, 3X,'(msec)',              
     &           14X, '(', 'lbs-sec**2-in', ')', 32X, 'deg' )            
       END IF                                                            
!C
       WRITE ( NT, 175 )                                                    
  175  FORMAT ( 1X )                                                       
       IF ( LNEW )  THEN                                                  
        DO  I=1,NLINES                                                    
         WRITE ( NT, 180 )  USEC(I), ( ZTTH(J,I,IT), J=1,6 )             
  180    FORMAT ( F9.3, 6( 2X, D12.5 ) )                                 
        END DO
       END IF
!C
      END DO                                                          
!C
      RETURN
      END