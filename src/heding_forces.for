      SUBROUTINE HEDING_FORCES ( LNEW, MT, NT, NLINES, XPAGE )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine prints out the headings for the forces
!C     tabular time histories.
!C    It is called only by Subroutine HEDING.
!C 
      USE  MODULE_STANDARD,  ONLY:
     &       UNITL, UNITM,                               ! /CNSNTS/
     &       NBAG, NBLT, NHRNSS, NPG, NPL, NSD, NSEG,    ! /CONTRL/
     &       NOUTPS, NOUTSS,                             ! /COUT/
     &       MSDM, MSDN,                                 ! /DAMPER/
     &       NPANEL,                                     ! /FORCES/
     &       NPTSPB, NBLTPH,                             ! /HRNESS/
     &       MBAG, MBLT, MNBAG, MNBLT, MNPL,             ! /JBARTZ/
     &       MNSEG, MPL, MSEG,                           ! /JBARTZ/
     &       BAGTTL, BDYTTL, BLTTTL, COMENT, DATE,       ! /TITLES/
     &       PLTTL, VPSTTL,                              ! /TITLES/
     &       HEAD, M1PL, M2PL, MOPL, NOPL, USEC, ZTTH,   ! /HEDING_TEMPVS/
     &       AIRBAG_TTH, BELT_TTH, HARNESS_TTH,          ! structures
     &       PLANE_SEG_TTH, SEG_SEG_TTH, SPRING_DAMP_TTH,! structures
     &       SEG,                                        ! structures                 
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,         ! parameters
     &       LOGICAL_STD, LUAOU, NUM_TTH_OFFSET,         ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_7                ! parameters
!C
!C    SEG%NAME
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &             I, IT, J, J1, J2, JJ, 
     &             K, K1, K2, KBAG, KP, KPL, KPS, KSS, LSEG,  
     &             M, M1, M2, MBSF, MM1, MM2, MPSF, MSSF, MT, 
     &             N1, N2, NLINES, NN1, NN2, NT
!C
      REAL  ( KIND = IREAL_HIGH )   PAGE, XPAGE 
!C
      CHARACTER ( LEN = 4, KIND = ICHAR_STD )  BLANK, PHED
      DIMENSION     PHED(5)
!C
      LOGICAL  ( KIND = LOGICAL_STD )   LNEW                                                
!C
      DATA BLANK / ICHAR_STD_'    ' /                                                
      DATA PHED / ICHAR_STD_'SPRF', ICHAR_STD_'PNL1', 
     &            ICHAR_STD_'PNL2', ICHAR_STD_'PNL3', 
     &            ICHAR_STD_'PNL4' /                  
!C
      INTENT ( IN )      LNEW, NLINES, XPAGE
      INTENT ( INOUT )   MT, NT
!C
!C    Plane/seg force headings.
!C                                                                      
      MPSF = I_0                                                           
      KPS = I_0                                                          
      IF ( PLANE_SEG_TTH%PRINT )  THEN
       DO  J=1,NPL                                                     
        IF ( MNPL(J) .EQ. I_0 ) CYCLE                                       
        KPL = MNPL(J)                                                  
        DO  I=1,KPL                                                    
         MPSF = MPSF + I_1                                                
         IF ( NOUTPS(MPSF) .EQ. I_1 )  THEN                               
          KPS = KPS + I_1                                              
          NOPL(KPS) = J                                               
          IF ( MPL(3,I,J) .LT. I_0 )  M1PL(KPS) = MPL(2,I,J)                
          IF ( MPL(3,I,J) .GE. I_0 )  M1PL(KPS) = MPL(1,I,J)             
          M2PL(KPS) = ABS ( MPL(3,I,J) )                                
          MOPL(KPS) = MPL(2,I,J)                                    
         END IF                                                      
        END DO                                                        
       END DO                                                          
!C
       MPSF = KPS                                                    
       IF ( MPSF .NE. I_0 )  THEN                                   
        DO  J1=1,MPSF,2                                                
         J2 = MIN ( ( J1 + I_1 ), MPSF )                                 
         MT = MT + I_1                                                   
         NT = MT                                                        
         IF  ( LNEW )  NT = LUAOU                                      
         IT = MT - NUM_TTH_OFFSET                                              
         PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                                    
         IF ( NT .EQ. LUAOU )  THEN
          WRITE ( NT, 121 )  DATE, BLANK, NPG                           
          NPG = NPG + I_1                                              
         ELSE
          WRITE ( NT, 121 )  DATE                                      
  121     FORMAT ( '1', 18X, 'Date:', 3X, A12, A4, 80X, 'Page', I5 )              
         END IF
         WRITE ( NT, 120 )  COMENT(1:80), COMENT(81:160),
     &                     PAGE, VPSTTL, BDYTTL                            
  120    FORMAT ( 8X, 'Run Description:', 3X, A80, /, 27X, A80,
     &            'PAGE:', F6.2, /, 3X, 'Vehicle Deceleration:', 3X,
     &            A80, /, 11X, 'Test Subject:', 3X, A20 )                 
         WRITE ( NT, 125 )                                                  
  125    FORMAT ( 27X, 'Contact Forces - Segment Panels vs. Segments' )     
         N1 = NOPL(J1)                                                       
         N2 = NOPL(J2)                                                     
         M1 = MOPL(J1)                                                     
         M2 = MOPL(J2)                                                 
         MM1 = M1PL(J1)                                                     
         MM2 = M1PL(J2)                                                   
         NN1 = M2PL(J1)                                                     
         NN2 = M2PL(J2)                                                     
!C
         IF  ( J1 .EQ. J2 )  THEN 
          WRITE  ( NT, 130 )  N1, PLTTL(N1),                                   
     &                        M1, SEG(M1)%NAME, NN1           
  130     FORMAT ( ' ', /, 11X, '  PANEL', I3, ' (', A20, 
     &             ') VS SEG', I3, ' (', A4, ') ', ' ELLIP', I3 )           
         ELSE
          WRITE  ( NT, 132 )   N1, PLTTL(N1), 
     &                        M1, SEG(M1)%NAME, NN1,                        
     &                        N2, PLTTL(N2),
     &                        M2, SEG(M2)%NAME, NN2             
  132     FORMAT ( ' ', /, 11X, 2( '  PANEL', I3, ' (', A20, 
     &             ') VS SEG', I3, ' (', A4, ') ', ' ELLIP', I3 ) )                        
         END IF
         WRITE ( NT, 135 )  ( BLANK, UNITL, J=J1,J2 )                             
  135    FORMAT ( ' ', 8X, A4, 'Defl-  Normal  Friction Resultant',
     &            ' Contact Location (', A4, ')', A2,
     &            'Defl-  Normal  Friction Resultant  Contact',
     &            ' Location (', A4, ')' )                                            
!C
         IF ( J1 .EQ. J2 )   THEN
          WRITE ( NT, 137 )  BLANK, SEG(MM1)%NAME                              
  137     FORMAT ( '    Time', A4, 'ection   Force    Force    Force',
     &             '     (', A4, ' Reference)'  )                                                
         ELSE
          WRITE ( NT, 140 )  BLANK, SEG(MM1)%NAME, BLANK, SEG(MM2)%NAME             
  140     FORMAT ( '    TIME', A4, 'ection   Force    Force    ', 
     &             'Force      (', A4, ' Reference)', 2X, A4,
     &             'ection   Force    Force    Force      (', A4,  
     &             ' Reference)'  )                                                   
         END IF
!C
         WRITE ( NT, 142 )  ( BLANK, UNITL, UNITM, UNITM, UNITM, 
     &                        J=J1,J2)             
  142    FORMAT ( '   (msec)', 2( A3, '(', A4, ')', 2X, '(', A4, 
     &            ')', 4X, '(', A4, ')', 3X, '(', A4, 
     &            ')     X       Y       Z  ') )                      
         WRITE ( NT, 145 )                                                
  145    FORMAT ( 1X )                                                     
         IF  ( .NOT. LNEW )  CYCLE                                        
         JJ = I_7 * ( J2 - J1 + I_1 )                                          
         DO  I=1,NLINES                                                  
          WRITE ( NT, 150 )  USEC(I), ( ZTTH(J,I,IT), J=1,JJ )                
  150     FORMAT ( F9.3, 2( F9.3, 3F9.2, 3F8.3 ) )                        
         END DO
        END DO                                                        
       END IF
      END IF
!C                                                                   
!C    Belt forces headings                                         
!C                                                                
      MBSF = I_0                                                         
      IF ( BELT_TTH%PRINT )  THEN
       DO  J=1,NBLT                                                      
        IF ( MNBLT(J) .EQ. I_0 )  CYCLE                                   
        MBSF = MBSF + I_1                                                    
        NOPL(MBSF) = J                                             
        MOPL(MBSF) = MBLT(2,1,J)                                 
       END DO                                                   
!C
       IF  ( MBSF .NE. I_0 )  THEN                           
        DO 50 J1=1,MBSF,2                                        
         J2 = MIN ( ( J1 + I_1 ), MBSF )                               
         MT = MT + I_1                                                    
         NT = MT                                                           
         IF  ( LNEW )  NT = LUAOU                                           
         IT = MT - NUM_TTH_OFFSET                                            
         PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                                     
         IF ( NT .EQ. LUAOU ) THEN
          WRITE ( NT, 121 )  DATE, BLANK, NPG                           
          NPG = NPG + I_1                                                      
         ELSE
          WRITE ( NT, 121 ) DATE                                              
         END IF
         WRITE ( NT, 120 ) COMENT(1:80), COMENT(81:160),
     &                    PAGE, VPSTTL, BDYTTL                              
         WRITE ( NT, 157 )                                            
  157    FORMAT ( '0', 26X, 'Contact Forces - Belts vs. Segments' )         
         N1 = NOPL(J1)                                                    
         N2 = NOPL(J2)                                                    
         M1 = MOPL(J1)                                                     
         M2 = MOPL(J2)                                                     
         IF  ( J1 .EQ. J2 )  THEN
          WRITE  ( NT, 158 )   BLANK, N1, BLTTTL(N1), M1, SEG(M1)          
  158     FORMAT ( ' ', 7X, 2( A4, '   Belt', I3, ' (', A20,
     &             ') vs. Segment',I3, ' (',A4,') ') )                    
         ELSE
          WRITE  ( NT, 158 )  BLANK, N1, BLTTTL(N1), M1, SEG(M1),         
     &                       BLANK, N2, BLTTTL(N2), M2, SEG(M2)          
         END IF
         WRITE ( NT, 159 ) ( BLANK, J=J1,J2 )                                
  159    FORMAT ( ' ', 2X, 
     &            2( A4, 11X, 'Anchor  Point  A', 14X, 
     &            'Anchor  Point  B' ) )  
         WRITE ( NT, 160 ) ( BLANK, J=J1,J2 )                               
  160    FORMAT ( 4X, 'Time', 2( A4, 5X, 'Strain', 7X, 'Force', 12X,         
     &                             'Strain', 7X, 'Force', 3X ) )          
         WRITE ( NT, 162 ) ( BLANK, UNITL, UNITL, UNITM, UNITL,
     &                      UNITL, UNITM, J=J1,J2 )                      
  162    FORMAT ( 3X, '(msec)', 2( A4, 2X, '(', A4, '/', A4, ')', 4X,
     &            '(', A4, ')', 9X, '(', A4, '/', A4, ')', 4X, '(',
     &            A4, ')', 3X ) )   
         WRITE ( NT, 163 )                                                   
  163    FORMAT ( 1X )                                                     
          IF  ( LNEW )  THEN                                             
          JJ = I_4 * ( J2 - J1 + I_1 )                                       
          DO  I=1,NLINES                                                 
           WRITE ( NT, 165 )  USEC(I), ( ZTTH(J,I,IT), J=1,JJ )              
  165      FORMAT ( F9.3, 4( F15.6, F12.2, 3X ) )                           
          END DO
         END IF
   50   CONTINUE                                                 
       END IF
      END IF
!C                                                               
!C    Harness belt endpoints forces headings                          
!C                                                                  
      MBSF = I_0                                                        
      IF ( HARNESS_TTH%PRINT )  THEN
       J1 = I_1                                                           
       K1 = I_1                                                      
       DO  I=1,NHRNSS                                            
        IF  ( NBLTPH(I) .LE. I_0 )  CYCLE                                      
        J2 = J1 + NBLTPH(I) - I_1                                         
        DO  J=J1,J2                                                      
         MBSF = MBSF + I_1                                            
         IF  ( NPTSPB(J) .LE. I_0 )  CYCLE                                
         K2 = K1 + NPTSPB(J) - I_1                                       
         NOPL(2*MBSF-1) = J                                             
         NOPL(2*MBSF  ) = I                                         
         MOPL(2*MBSF-1) = K1                                            
         MOPL(2*MBSF  ) = K2                                          
         K1 = K2 + I_1                                                   
        END DO                                                         
        J1 = J2 + I_1                                                  
       END DO                                                          
!C
       DO  J1=1,MBSF,2                                             
        J2 = MIN ( ( J1 + I_1 ), MBSF )                             
        MT = MT + I_1                                                     
        NT = MT                                                          
        IF  ( LNEW )  NT = LUAOU                                     
        IT = MT - NUM_TTH_OFFSET                                             
        PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                                      
        IF ( NT .EQ. LUAOU )  THEN
         WRITE ( NT, 121 )  DATE, BLANK, NPG                              
         NPG = NPG + I_1                                               
        ELSE
         WRITE ( NT, 121 )  DATE                                             
        END IF
        WRITE ( NT, 120 ) COMENT(1:80), COMENT(81:160),
     &                   PAGE, VPSTTL, BDYTTL                             
        WRITE ( NT, 188 )                                                  
  188   FORMAT ( '0', 26X, 'Harness System Belt Endpoint Forces' )          
        WRITE ( NT, 189 ) ( BLANK, NOPL(2*J-1), NOPL(2*J), J=J1,J2 )        
  189   FORMAT ( 9X, 2( A4, 11X, 'Belt No.', I4, ' of Harness No.',
     &           I3, 15X ) )       
        WRITE ( NT, 190 ) ( BLANK, MOPL(2*J-1), MOPL(2*J), J=J1,J2 )        
  190   FORMAT ( 9X, 2( A4, 6X, 'Point No.', I5, 16X, 'Point No.',
     &           I5, 6X ) )       
        WRITE ( NT, 160 ) ( BLANK, J=J1,J2 )                              
        WRITE ( NT, 162 ) ( BLANK, UNITL, UNITL, UNITM, UNITL, UNITL,
     &                     UNITM, J=J1,J2 )  
        WRITE ( NT, 192 )                                                   
  192    FORMAT ( 1X )                                                     
        IF  ( LNEW )   THEN                                          
         JJ =  I_4 * ( J2 - J1 + I_1 )                                        
         DO  I=1,NLINES                                                 
          WRITE ( NT, 165 )  USEC(I), ( ZTTH(J,I,IT), J=1,JJ )                 
         END DO
        END IF
       END DO                                                 
      END IF
!C                                                                  
!C    Spring damper forces headings                             
!C                                                                  
      IF ( SPRING_DAMP_TTH%PRINT )  THEN
       DO  J1=1,NSD,2                                           
        J2 = MIN ( ( J1 + I_1 ), NSD )                               
        MT = MT + I_1                                               
        NT = MT                                                         
        IF  ( LNEW )  NT = LUAOU                                           
        IT = MT - NUM_TTH_OFFSET                                         
        PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                                   
        IF ( NT .EQ. LUAOU )  THEN
         WRITE ( NT, 121 ) DATE, BLANK, NPG                               
         NPG = NPG + I_1                                                   
        ELSE
         WRITE ( NT, 121 )  DATE                                           
        END IF
        WRITE ( NT, 120 )  COMENT(1:80), COMENT(81:160),
     &                    PAGE, VPSTTL, BDYTTL                          
        WRITE ( NT, 195 )  ( BLANK, J, J=J1,J2 )                            
  195   FORMAT ( '0', 26X, 'Spring Damper Forces', /,                             
     &           9X, 2( 15X, A3, 3X, 'Spring Damper No.', I3, 19X) )                   
        DO   J=J1,J2                                                
         M1 = MSDM(J)                                                  
         N1 = MSDN(J)                                                  
!C
!C       Possible overflow into NOPL array is intentional.              
!C
         HEAD(2*J-1) = SEG(M1)%NAME                                        
         HEAD(2*J  ) = SEG(N1)%NAME                                        
        END DO
        WRITE ( NT, 196 )  ( BLANK, MSDM(J), HEAD(2*J-1), MSDN(J),
     &                      HEAD(2*J) ,J=J1,J2 )  
  196   FORMAT ( 9X, 2( 15X, A3, 'Seg', I3, '(', A4, ') - Seg', I3, 
     &           '(',A4,')', 15X ) )
        WRITE ( NT, 197 )  ( BLANK, J=J1,J2 )                                  
  197   FORMAT ( 4X, 'Time', 1X, 2( A3, 5X, 'Length', 5X,
     &           'TOT Force', 3X, 'SPR Force', 3X, 'DMP Force', 3X ) )
        WRITE ( NT, 198 )( BLANK, UNITL, UNITM, UNITM, UNITM, J=J1,J2 )                
        WRITE ( NT, 199 )                                                
  198   FORMAT ( 3X, '(msec)', 2( A3, 5X, '(', A4, ')', 6X, '(',
     &           A4, ')', 6X, '(', A4, ')', 6X, '(', A4, ')', 5X ) )
  199   FORMAT ( 1X )                                                     
        IF  ( LNEW )  THEN                                           
         JJ = I_4 * ( J2 - J1 + I_1 )             
         DO  I=1,NLINES                                             
          WRITE ( NT, 200 )  USEC(I), ( ZTTH(J,I,IT), J=1,JJ )        
  200     FORMAT ( F9.3, 2( F14.3, 1X, 3F12.2, 4X ) )                 
         END DO
        END IF
       END DO                                                         
      END IF
!C                                                                         
!C    Segment forces headings                                          
!C                                                                       
      MSSF = I_0                                                           
      KSS = I_0                                                   
      IF ( SEG_SEG_TTH%PRINT )  THEN
       DO  J=1,NSEG                                                   
       IF ( MNSEG(J) .EQ. I_0 )  CYCLE                                     
       LSEG = MNSEG(J)                                                  
        DO  I=1,LSEG                                                  
         MSSF = MSSF+1                                                 
         IF ( NOUTSS(MSSF) .EQ. I_1 ) THEN                               
          KSS = KSS + I_1                                               
          NOPL(KSS) = J                                                
          MOPL(KSS) = MSEG(2,I,J)                                    
         END IF                                                         
        END DO                                                    
       END DO                                                          
       MSSF = KSS                                                   
       IF ( MSSF .NE. I_0 )  THEN                                    
        DO  J=1,MSSF                                            
         MT = MT + I_1                                                
         NT = MT                                                      
         IF  ( LNEW )  NT = LUAOU                                      
         IT = MT - NUM_TTH_OFFSET                                         
         PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                                
         IF ( NT .EQ. LUAOU )  THEN 
          WRITE ( NT, 121 )   DATE, BLANK, NPG                           
          NPG = NPG + I_1                                                    
         ELSE
          WRITE ( NT, 121 ) DATE                                            
         END IF
         WRITE ( NT, 120 )  COMENT(1:80), COMENT(81:160),
     &                     PAGE, VPSTTL, BDYTTL                         
         N1 = NOPL(J)                                                    
         M1 = MOPL(J)                                                    
         WRITE ( NT, 205 )  N1, SEG(N1)%NAME, M1, SEG(M1)%NAME, UNITL, 
     &                     N1, M1,           
     &                     UNITL, UNITM, UNITM, UNITM                        
  205    FORMAT ( '0', 26X, 'Contact Forces - Segment No.', I3, ' (',
     &            A4, ') vs. Segment No.', I3, ' (', A4, ')', //,       
     &            13X, 'Defl-  Normal  Friction Resultant',                
     &            14X, 'Contact Location (', A4, ')', /,                  
     &            4X, 'Time    ection', 3( 3X, 'Force', 1X ),               
     &            2('  Seg.', I3, ' Local Reference '), /,                     
     &            3X, '(msec)', 3X, '(', A4, ')', 3( 3X, '(', A4, ')' ),           
     &            2( 5X, 'X', 7X, 'Y', 7X, 'Z', 4X ), /, 1X )                     
         IF  ( LNEW )  THEN                                                
          DO  I=1,NLINES                                                
           WRITE ( NT, 210 )  USEC(I), ( ZTTH(JJ,I,IT), JJ=1,10 )              
  210      FORMAT ( 2F9.3, 3F9.2, 3F8.3, 2X, 3F8.3 )                       
          END DO
         END IF
        END DO                                                   
       END IF
      END IF
!C                                                                    
!C    Airbag forces headings                                          
!C                                                                      
      IF ( AIRBAG_TTH%PRINT )  THEN
       DO  77  J=1,NBAG                                              
        IF ( MNBAG(J) .EQ. I_0 )  CYCLE                                 
        MT = MT + I_1                                                   
        NT = MT                                                       
        IF  ( LNEW )  NT = LUAOU                                        
        IT = MT - NUM_TTH_OFFSET                                         
        PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                                     
        IF ( NT .EQ. LUAOU ) THEN
         WRITE ( NT, 121 )   DATE, BLANK, NPG                             
         NPG = NPG + I_1                                                 
        ELSE
         WRITE ( NT, 121 )  DATE                                         
        END IF
        WRITE ( NT, 120 )  COMENT(1:80), COMENT(81:160), 
     &                    PAGE, VPSTTL, BDYTTL                             
        WRITE ( NT, 215 )  J, BAGTTL(I)                                   
  215   FORMAT ( '0', 26X, 'Parameters for Airbag No.', I2, 4X, A20, //,         
     &           16X, 'Supply Cylinder   Static', /, 4X,                         
     &           'Time', 8X, 'Pres.', 4X, 'Temp.', 4X, 'Pres.', 
     &           12X, 'Airbag', 3X, 'Center', 14X, 'Airbag  Semiaxes',
     &           12X, 'Orientation (deg.)', /, 3X, '(msec)', 7X, 
     &           '(Psig)  (deg.R)   (Psig)', 8X, 'X', 8X, 'Y', 8X, 'Z',  
     &           11X, 'A', 8X, 'B', 8X, 'C', 10X, 'Yaw', 4X,
     &           'Pitch', 5X, 'Roll', / )                                 
        IF  ( LNEW )  THEN                                              
         DO   I=1,NLINES                                             
          WRITE ( NT, 220 )  USEC(I), ( ZTTH(JJ,I,IT), JJ=1,12 )          
  220     FORMAT ( F9.3, 3X, 3F9.2, 2( 3X, 3F9.3 ), 3X, 3F9.2 )               
         END DO
        END IF
        KBAG = I_0                                                 
        KP = NPANEL(J) + I_1                                             
        DO  K=1,KP                                                 
         KBAG = KBAG + I_1                                               
         HEAD(KBAG) = PHED(K)                                          
        END DO
        KP = MNBAG(J)                                                  
        DO  K=1,KP                                                  
         KBAG = KBAG + I_1                                                
         M = MBAG(2,K,J)                                       
         HEAD(KBAG) = SEG(M)%NAME                                       
        END DO
        DO  J1=1,KBAG,4                                       
         J2 = MIN ( ( J1 + I_3 ), KBAG )                            
         MT = MT + I_1                                                  
         NT = MT                                                        
         IF  ( LNEW )  NT = LUAOU                                       
         IT = MT - NUM_TTH_OFFSET                                                
         PAGE = REAL ( MT, IREAL_HIGH ) + XPAGE                                      
         IF ( NT .EQ. LUAOU )  THEN
          WRITE ( NT, 121 )  DATE, BLANK, NPG                              
          NPG = NPG + I_1                                                    
         ELSE
          WRITE(NT,121) DATE                                              
         END IF
         WRITE ( NT, 120 )  COMENT(1:80), COMENT(81:160), 
     &                     PAGE, VPSTTL, BDYTTL                         
         WRITE ( NT, 225 ) UNITM, J, BAGTTL(J),
     &                    ( BLANK, J, HEAD(K), K=J1,J2 )  
  225    FORMAT ( '0', 26X, 'Contact Forces (', A4, ') on Airbag No.',
     &            I2, 4X, A20, ///, 4X, 'Time',
     &            4( A1, 11X, 'Airbag', I2, ' vs. ', A4, 1X ) )             
         WRITE ( NT, 230 ) ( BLANK, K=J1,J2 )                                    
  230    FORMAT ( 3X, '(msec)', 4( A1, 9X, 'X', 8X, 'Y', 8X, 'Z', 1X ) )              
         WRITE ( NT, 235 )                                                     
  235    FORMAT ( 1X )                                                     
         IF  ( LNEW )  THEN                                             
          JJ = I_3 * ( J2 - J1 + I_1 )                                        
          DO  I=1,NLINES                                                 
           WRITE ( NT, 240 )  USEC(I), ( ZTTH(K,I,IT), K=1,JJ )              
  240      FORMAT ( F9.3, 4( 3X, 3F9.2 ) )                                   
          END DO
         END IF
        END DO                                                        
   77  CONTINUE                                                         
      END IF
!C
      RETURN
      END
      