      SUBROUTINE INPUT_HARNESS                                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Controls the input of Cards F.8.A - F.8.D containing the setup and 
!C    control of the harness belt system.                                 
!C                                                                        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       EPS, UNITL,                              ! /CNSNTS/
     &       BD,                                      ! /CNTRSF/
     &       NHRNSS, NPG,                             ! /CONTRL/
     &       HRN_EPSDEL, HRN_MAX_ITR,                 ! /HBPTRB/
     &       KEEP, NBLTPH, NPTSPB, XLONG, NTHRNS,     ! /HRNESS/
     &       IBAR, BAR, BBDOT, PLOSS,                 ! /HRNESS/
     &       MXNTB,                                   ! /TABLES/
     &       NF_FUNCT,                                ! /CINPUT_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH, LUAIN, LUAOU,   ! parameters
     &       D_0, D_1, I_0, I_1, I_10, LULIN, MAXHRN, ! parameters                     
     &       LIN_FLAG, AIN_CONVERT, ICHAR_STD         ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &             I, ICHEC, J, J1, J2, K, K1, K2, KE, KPOINT, KS, 
     &             L, NDR, NPD
!C
      REAL  ( KIND = IREAL_HIGH )   SQRER
!C
      REAL  ( KIND = IREAL_HIGH )   XDY
      EXTERNAL          XDY
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =  26, KIND = ICHAR_STD )  A_FRMT_26
      CHARACTER ( LEN =  27, KIND = ICHAR_STD )  A_FRMT_27
!C                                                                      
!C    The variable "KEEP" has been introduced to flag those points      
!C    on the belt which should not be dropped (KEEP=1) even if the belt 
!C    angle is such that it is pulling away from the surface.  This     
!C    permits a belt point to simulate a ring attachment which allows   
!C    slippage along the belt line, but does not allow the belt to      
!C    leave the surface.  A large coefficient of transverse friction    
!C    ( >= 100 ) should be supplied for this option to work properly.   
!C    The value of KEEP(K) is determined by the sign of the friction    
!C    function number supplied on the F.8.D card.  If the number is     
!C    negative, the value of KEEP for that point will be set to "1".    
!C    The friction function number is then replaced by its absolute     
!C    value. (E. SIEVEKA, UVA - 11/14/96)                               
!C                                                                      
      KEEP = I_0                                                     
!C                                                                        
!C    Input Card F.8.A                                                    
!C        (Note: NHRNSS now supplied on input Card D.1)                   
!C        NBLTPH - no. of belts per harness                               
!C                                                                      
!C    Two new variables, HRN_MAX_ITR and HRN_EPSDEL, have been added to input    
!C    line A.4.  These give the user control over the maximum strain    
!C    stopping criterion (HRN_EPSDEL), used by Subroutine HPTURB when       
!C    rebalancing the harness belt, and the number of iterations        
!C    needed to meet this criterion (HRN_MAX_ITR).  The old, hard-coded      
!C    value of HRN_EPSDEL=0.01 was far too high for effective convergence.  
!C    Old input decks with no data in these fields will, however,       
!C    have the old defaults of 10 and 0.01 assigned to these variables. 
!C    Suggested values are 15 AND 0.001.  (E. SIEVEKA, UVA  5-10-1996)  
!C                                                                      
!C    Read in Card F.8.a.
!C
      IF ( LIN_FLAG )  THEN
       READ  ( LULIN, * )  ( NBLTPH(I), I=1,MAXHRN ), 
     &                     HRN_MAX_ITR, HRN_EPSDEL            
      ELSE
       READ  ( LUAIN, 100 )  ( NBLTPH(I), I=1,MAXHRN ), 
     &                       HRN_MAX_ITR, HRN_EPSDEL            
  100  FORMAT ( 5I4, 20X, I4, F8.0 )                                     
       IF ( AIN_CONVERT )  THEN
        WRITE  ( LULIN, 105 )  ( NBLTPH(I), I=1,MAXHRN ), 
     &                         HRN_MAX_ITR, HRN_EPSDEL,
     &                       'Card F.8.a'            
  105   FORMAT ( 1X, 5( I4, 1X ), I4, 1X, F15.7, 2X, A )                                     
       END IF
      END IF
!C
      IF ( HRN_MAX_ITR .EQ. I_0 )  HRN_MAX_ITR = I_10                         
      IF ( HRN_EPSDEL .EQ. I_0 )  HRN_EPSDEL = EPS(2)                          
!C
!C    Echo Card F.8.a.
!C
      WRITE ( LUAOU, 110 )  NPG, NHRNSS, ( NBLTPH(I), I=1,MAXHRN ), 
     &                     HRN_MAX_ITR, HRN_EPSDEL    
      NPG = NPG + I_1                                                   
  110 FORMAT ( '1 Harness-Belt System Input', 96X, 'Page', I5, /, 120X,     
     &         'Cards F.8', /, '  No. of Harnesses =', I4, //,              
     &         '  No. of Belts per Harness =', 5I6, 10X, 
     &         'MAXITR =', I4, 5X, 'EPSDEL =', F8.5 )                                     
      J1 = I_1                                                          
      K1 = I_1                                                          
      DO 20 I=1,NHRNSS                                                    
       IF ( NBLTPH(I) .LE. I_0 )  CYCLE                                 
       J2 = J1 + NBLTPH(I) - I_1                                         
!C                                                                        
!C     Input Card F.8.b - NPTSPB - no. of points per belt.  
!C      Only 1 F.8.b card for list-directed input as compared 
!C      to up to 2 for .AIN format.              
!C                                                                        
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( NPTSPB(J), J=J1,J2 )                         
       ELSE
        READ ( LUAIN, 115 )  ( NPTSPB(J), J=J1,J2 )                         
  115   FORMAT ( 18I4 )                                                    
        IF ( AIN_CONVERT )  THEN
         IF ( NBLTPH(I) .LT. I_10 )  THEN 
          WRITE ( ALEN1, 120 ) NBLTPH(I)
  120     FORMAT ( I1 )
          READ ( ALEN1, 125 ) AL1
  125     FORMAT ( A1 )
          A_FRMT_26 = '( 1X, ' // AL1 // '( I4, 1X ), 1X, A )'
         ELSE
          WRITE ( ALEN2, 130 ) NBLTPH(I)
  130     FORMAT ( I2 )
          READ ( ALEN2, 135 ) AL2
  135     FORMAT ( A2 )
          A_FRMT_27 = '( 1X, ' // AL2 // '( I4, 1X ), 1X, A )'
         END IF
         IF ( NBLTPH(I) .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_26 )  ( NPTSPB(J), J=J1,J2 ), 
     &                                'Card F.8.b'                         
         ELSE
          WRITE ( LULIN, A_FRMT_27 )  ( NPTSPB(J), J=J1,J2 ), 
     &                                'Card F.8.b'                         
         END IF
        END IF
       END IF
!C
       WRITE ( LUAOU, 140 )  I, ( NPTSPB(J), J=J1,J2 )                     
  140  FORMAT ( '0 For Harness No.', I3, 
     &          ' No. of Points per Belt =', 20I4 )                       
       DO 30 J=J1,J2                                                      
        IF ( NPTSPB(J) .EQ. I_0 )  CYCLE                              
!C                                                                        
!C      Input Card F.8.c - 5 function nos and length of each belt.      
!C                                                                        
        IF ( LIN_FLAG )  THEN
         READ  ( LULIN, * )     NF_FUNCT, XLONG(J)                        
        ELSE
         READ  ( LUAIN, 145 )     NF_FUNCT, XLONG(J)                        
  145    FORMAT ( 5I4, F12.6 )                                             
         IF ( AIN_CONVERT )  THEN
          WRITE  ( LULIN, 150 )     NF_FUNCT, XLONG(J), 'Card F.8.c'                        
  150     FORMAT ( 1X, 5( I4, 1X ), F19.11, 2X, A )                                             
         END IF
        END IF
        WRITE ( LUAOU, 155 )  I, J, NF_FUNCT, XLONG(J), UNITL              
  155   FORMAT ( '0 Harness No.', I3, ' Belt No.', I3, 
     &           ' Function Nos.', 5I6,  
     &          '  Reference Slack = ', F9.3, 1X, A4, / )                 
        IF   ( XLONG(J) .EQ. D_0 )   XLONG(J) = EPS(24)                 
        WRITE  ( LUAOU, 160 )                                              
  160   FORMAT ( '0    K    KS    KE    NT    NPD   NDR    ',
     &           'Function Nos.', 66X, 'Cards F.8.D', / )               
!C                                                                        
!C      Set up pointers in NTAB and initial values of TAB for belt J      
!C          as was done for other contacts.          
!C                                                                        
!C      Variable "KPOINT" has been added to initialize all segments     
!C      of a multi-segment belt.  See comment in FDINIT.  (E. SIEVEKA,  
!C      UVA - 11/28/92)                                                 
!C                                                                      
        K2 = K1 + NPTSPB(J) - I_1                                  
        DO 70 K=K1,K2                                                    
         KPOINT = K - K1 + I_1                                        
         NTHRNS(J,KPOINT) = MXNTB + I_1                               
         CALL FDINIT ( KPOINT )                                         
!C                                                                        
!C       Input Card F.8.d.1.                                                 
!C                                                                        
         IF ( LIN_FLAG )  THEN
          READ  ( LULIN, * )  KS, KE, NPD, NDR, NF_FUNCT, 
     &                         ( BAR(L,K), L=1,3 )   
         ELSE
          READ  ( LUAIN, 165 )  KS, KE, NPD, NDR, NF_FUNCT, 
     &                         ( BAR(L,K), L=1,3 )   
  165     FORMAT ( 9I4, 3F12.0 )                                           
          IF ( AIN_CONVERT )  THEN
           WRITE  ( LULIN, 170 )  KS, KE, NPD, NDR, NF_FUNCT, 
     &                          ( BAR(L,K), L=1,3 ), 'Card F.8.d.1'   
  170      FORMAT ( 1X, 9( I4, 1X ),  3( F19.11, 1X ), 1X, A )                                           
          END IF
         END IF
!C
!C       Read in Card F.8.d.2.
!C
         IF ( LIN_FLAG )  THEN
          READ  ( LULIN, * )  ( BAR(L,K), L=7,12 )                        
         ELSE
          READ  ( LUAIN, 175 )  ( BAR(L,K), L=7,12 )                        
  175     FORMAT ( 6F12.0 )                                                
          IF ( AIN_CONVERT )  THEN
           WRITE  ( LULIN, 180 )  ( BAR(L,K), L=7,12 ), 'Card F.8.d.2'                        
  180      FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )                                                
          END IF
         END IF
!C
         ICHEC = I_0                                                   
         IF  ( ( K .EQ. K1 )     .OR. ( K .EQ. K2 ) )   ICHEC = I_1       
         IF  ( ( ICHEC .EQ. I_1 ) .AND. ( NPD .EQ. I_0 ) )  STOP 60          
         IF  ( ( ICHEC .EQ. I_1 ) .AND. ( NDR .EQ. I_0 ) )  STOP 61       
         IF  ( ( NDR .EQ.   I_0 ) .AND. ( NPD .NE. I_0 ) )  STOP 62    
         IBAR(1,K) = KS                                                   
         IBAR(2,K) = KE                                                   
         IBAR(4,K) = NPD                                                  
         IBAR(5,K) = NDR                                                  
         IBAR(3,K) = MXNTB + I_1                                        
!C                                                                      
!C       Check to see if the point is a "sticky" point that will not be 
!C       allowed to pull off the surface ( NF_FUNCT(5) less than 0 ).  
!C       If true, set KEEP(K) equal to 1 and reset the friction function
!C       number to positive. (E. SIEVEKA, UVA - 11/14/96)               
!C                                                                      
         IF  ( NF_FUNCT(5) .LT. I_0 )  THEN                          
          KEEP(K) = I_1                                               
          NF_FUNCT(5) = ABS ( NF_FUNCT(5) )                              
         END IF                                                       
         CALL FDINIT ( I_1 )                                         
         SQRER = D_1                                                       
         IF  ( KE .NE. I_0 )  
     &    SQRER = SQRT ( XDY ( BAR(1,K), BD(7,KE), BAR(1,K) ) )           
         DO  L=1,3                                                        
          IF  ( KE .NE. I_0 )  BAR(L+6,K) = BD(L+3,KE)                  
          BAR(L+3,K) = BAR(L,K) / SQRER                                   
         END DO
         WRITE  ( LUAOU, 185 )  K, ( IBAR(L,K), L=1,5 ), NF_FUNCT           
  185    FORMAT ( 11I6 )                                                  
   70   CONTINUE                                                          
        WRITE  ( LUAOU, 190 )  UNITL, UNITL, UNITL, UNITL                  
  190   FORMAT ( '0', 12X, 'Base Reference (',     A4, ')',              
     &                 7X, 'Adjusted Reference (', A4, ')',               
     &                11X, 'Offset (',             A4, ')',              
     &                11X, 'Preferred Direction (',A4, ')', /,            
     &                5X, 'K', 4( 8X, 'X', 8X, 'Y', 8X, 'Z', 3X ), / )    
        WRITE  ( LUAOU, 195 )  ( K, ( BAR(L,K), L=1,12 ), K=K1,K2 )        
  195   FORMAT  ( I6, 3X, 3F9.3, 3X, 3F9.3, 3X, 3F9.3, 3X, 3F9.3 )        
        K1 = K2 + I_1                                                  
   30  CONTINUE                                                           
       J1 = J2 + I_1                                                   
   20 CONTINUE                                                            
      BBDOT = D_0
      PLOSS = D_0
      DO  K=1,100                                                         
       DO   J=1,3                                                         
        BAR(J+12,K) = D_0                                               
       END DO
      END DO
!C
      RETURN                                                              
      END                                                                
