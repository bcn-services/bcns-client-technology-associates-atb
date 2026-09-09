      SUBROUTINE  INPUT_EQUILB ( NVAR, NCON, NTV, NI1, NSGE,
     &                           GX, XDEV, JPL, NAV, KSGE, 
     &                           IPL, ISG, LTYPE, INDGX, JSG )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the G.4, G.5 and G.6 cards needed
!C     by Subroutine EQUILB to compute an equilibrium position.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NPG, NSEG, NPL,                                ! /CONTRL/
     &       MNPL, MPL,                                     ! /JBARTZ/
     &       INTEGER_STD, IREAL_HIGH, ICHAR_STD,            ! parameters
     &       LUAIN, LUAOU, MAXSEG, LUTERM_OUT, LULIN,       ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_10,       ! parameters
     &       LIN_FLAG, AIN_CONVERT                          ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, IAV, J, K, NCON, NNPL, NVAR 
      INTEGER  ( KIND = INTEGER_STD )
     &           JPL, JSG, NTV, NI1, NSGE, NAV,
     &           KSGE, ISG, IPL, LTYPE, INDGX
      DIMENSION  JPL(10), JSG(10), NTV(10), NI1(10), NSGE(10), 
     &           NAV(10), KSGE(5,10), ISG(5), IPL(5), LTYPE(5), INDGX(5)
!C
      REAL  ( KIND = IREAL_HIGH )   GX, XDEV
      DIMENSION   GX(10), XDEV(10)
!C
      REAL  ( KIND = IREAL_HIGH )   VECMAG, XDY
      EXTERNAL                      VECMAG, XDY
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =  68, KIND = ICHAR_STD )  A_FRMT_68
!C
      INTENT ( OUT )  NVAR, NCON, NTV, NI1, NSGE,
     &                GX, XDEV, JPL, JSG, NAV, KSGE,
     &                IPL, ISG, LTYPE, INDGX 
!C                                                                       
!C    Input Cards G.4.                                     
!C                                                                        
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )  NVAR, NCON                                    
      ELSE
       READ   ( LUAIN, 100 )  NVAR, NCON                                    
  100  FORMAT ( 2I4 )
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 105 )  NVAR, NCON, 'Card G.4'                                    
  105   FORMAT ( 1X, 2( I4, 1X ), 1X, A )
       END IF
      END IF
!C
!C    Echo the G.4 data to the standard output unit.
!C
      WRITE  ( LUAOU, 110 )  NVAR, NCON, NPG                                
      NPG = NPG + I_1                                                     
  110 FORMAT ('1', 5X, 'NVAR =', I3, 3X, 'NCON =', I3, 96X,                 
     &        'Page', I5, /, 120X, 'Card  G.4', / )                         
!C
!C    Check the G.4 card values.
!C
      IF  ( ( NVAR .LT. I_1 )  .OR. ( NVAR .GT. I_10  ) )  THEN     
       WRITE  ( LUAOU, 115 )  NVAR                                  
       WRITE  ( LUTERM_OUT, 115 )  NVAR
  115  FORMAT( 1X, 'Invalid value, ', I4, ' supplied for NVAR. ',                  
     &         ' Program terminated.')                                   
       STOP 'STOP 2600 in Subroutine INPUT_EQUILB'                                                             
      END IF
!C
      IF  ( ( NCON .LT. I_0 ) .OR. ( NCON .GT. I_5 ) )  THEN      
       WRITE  ( LUAOU, 120 )  NCON                                  
       WRITE  ( LUTERM_OUT, 120 )  NCON
  120  FORMAT( 1X, 'Invalid value, ', I4, ' supplied for NCON.',                  
     &         ' Program terminated.')                                   
       STOP 'STOP 2601 in Subroutine INPUT_EQUILB'                                                             
      END IF
!C
      WRITE  ( LUAOU, 125 )                                               
  125 FORMAT ( '0', 4X, 'J', 4X, 'NTV', 3X, 'NI1', 3X, 'NSG', 8X,
     &         'GX', 12X, 'XDEV', 7X, 'JPL', 3X, 'JSG', 3X, 'NAV',
     &         3X, 'KSG(I,J),I=1,NAV', 28X, 'Cards G.5', / )              
!C                                                                       
!C    Input Cards G.5.                                     
!C                                                                        
      DO  58  J=1,NVAR                                                    
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )    NTV(J), NI1(J), NSGE(J), GX(J), XDEV(J),     
     &                     JPL(J), JSG(J), IAV, (KSGE(I,J), I=1,IAV )        
       ELSE
        READ  ( LUAIN, 130 )    NTV(J), NI1(J), NSGE(J), GX(J), XDEV(J),     
     &                     JPL(J), JSG(J), IAV, (KSGE(I,J), I=1,IAV )        
  130   FORMAT ( 3I4, 2F8.0, 8I4 )                                          
!C
        IF  ( ( IAV .LT. I_0 ) .OR. 
     &        ( IAV .GT. I_5    ) )  THEN    
         WRITE  ( LUAOU, 135 )  IAV, J                                  
         WRITE  ( LUTERM_OUT, 115 )  IAV, J
  135    FORMAT( 1X, 'Invalid value, ', I4, ' supplied for NAV(',
     &           I4,'). Program terminated.')                                   
         STOP 'STOP 2602 in Subroutine INPUT_EQUILB'                                                             
        END IF
!C
        IF ( AIN_CONVERT )  THEN
         IF ( IAV .GT. I_0 )  THEN
          WRITE ( ALEN1, 140 ) IAV
  140     FORMAT ( I1 )
          READ ( ALEN1, 145 ) AL1
  145     FORMAT ( A1 )
          A_FRMT_68 ='( 1X, 3( I4, 1X ), 2( F15.7, 1X ), 3( I4, 1X ), '
     &                 // AL1 // '( I4, 1X ), 1X, A )'                                          
          WRITE ( LULIN, A_FRMT_68 )  NTV(J), NI1(J), NSGE(J), GX(J), 
     &                                XDEV(J), JPL(J), JSG(J), IAV, 
     &                                (KSGE(I,J), I=1,IAV ), 'Card G.5'        
         ELSE
          WRITE ( LULIN, 150 )  NTV(J), NI1(J), NSGE(J), GX(J), 
     &                          XDEV(J), JPL(J), JSG(J), IAV, 
     &                          (KSGE(I,J), I=1,IAV ), 'Card G.5'        
  150     FORMAT ( 1X, 3( I4, 1X ), 2( F15.7, 1X ), 3( I4, 1X ),
     &             2X, A )                                         
         END IF
        END IF
       END IF
       NAV(J) = IAV                                                       
!C
!C     Echo the G.5 input data.
!C
       WRITE  ( LUAOU, 155 )  J, NTV(J), NI1(J), NSGE(J), GX(J),XDEV(J),     
     &                   JPL(J), JSG(J), IAV, ( KSGE(I,J), I=1,IAV )       
  155  FORMAT ( 4I6, 2F15.6, 8I6 )                                        
!C
!C     Check the input values from Card G.5.
!C
       IF  ( ( NTV(J) .LT. I_1 ) .OR. 
     &       ( NTV(J) .GT. I_2    ) )  THEN   
        WRITE  ( LUAOU, 160 )  NTV(J), J                                  
        WRITE  ( LUTERM_OUT, 160 )  NTV(J), J
  160   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for NTV(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2603 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( ( NI1(J) .LT. I_1 ) .OR. 
     &       ( NI1(J) .GT. I_3   ) )  THEN     
        WRITE  ( LUAOU, 115 )  NI1(J), J                                  
        WRITE  ( LUTERM_OUT, 165 )  NI1(J), J
  165   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for NI1(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2604 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( ( NSGE(J) .LT. I_1 ) .OR. 
     &       ( NSGE(J) .GT. NSEG ) )  THEN     
        WRITE  ( LUAOU, 115 )  NSGE(J), J                                  
        WRITE  ( LUTERM_OUT, 170 )  NSGE(J), J
  170   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for NSGE(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2605 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( ( JPL(J) .LT. I_1 ) .OR. ( JPL(J) .GT. NPL  ) )  THEN    
        WRITE  ( LUAOU, 175 )  JPL(J), J                                  
        WRITE  ( LUTERM_OUT, 175 ) JPL(J), J
  175   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for JPL(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2606 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( ( JSG(J) .LT. I_1 ) .OR. ( JSG(J) .GT. NSEG ) )  THEN    
        WRITE  ( LUAOU, 180 )  JSG(J), J                                  
        WRITE  ( LUTERM_OUT, 180 ) JSG(J), J
  180   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for JSG(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2607 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       K = JPL(J)                                                          
       NNPL = MNPL(K)                                                      
       IF  ( NNPL .LT. I_1 )   THEN    
        WRITE  ( LUAOU, 185 )  JPL(J), J                                  
        WRITE  ( LUTERM_OUT, 185 ) JPL(J), J
  185   FORMAT( 1X, 'No segment-plane contact found for plane ', I4, 
     &          ' for variable ', I4,'). Program terminated.')                                   
        STOP 'STOP 2608 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       DO  I=1,NNPL                                                        
        IF  ( JSG(J) .NE. MPL(2,I,K) )  CYCLE                              
        JSG(J) = I                                                         
        EXIT                                                           
       END DO                                                              
       IF  ( I .GT. NNPL )   THEN    
        WRITE  ( LUAOU, 190 )  JSG(J), J                                  
        WRITE  ( LUTERM_OUT, 190 ) JSG(J), J
  190   FORMAT( 1X, 'No segment-plane contact found for segment ', I4, 
     &          ' for variable ', I4,'). Program terminated.')                                   
        STOP 'STOP 2609 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( NAV(J) .GT. I_0 )  THEN                                 
        DO  I=1,IAV                                                      
         IF  ( ( KSGE(I,J) .LT. I_1 ) .OR. 
     &         ( KSGE(I,J) .GT. NSEG ) )  THEN  
          WRITE  ( LUAOU, 195 )  KSGE(I,J), I, J                                  
          WRITE  ( LUTERM_OUT, 195 ) KSGE(I,J), I, J
  195     FORMAT( 1X, 'Invalid value, ', I4, ' supplied for KSGE(',
     &            I4, I4, '). Program terminated.')                                   
          STOP 'STOP 2610 in Subroutine INPUT_EQUILB'                                                             
         END IF
        END DO                                                             
       END IF                                                              
  58  CONTINUE
!C
!C    If there are no constraints, exit the subroutine.
!C
      IF  ( NCON .LE. I_0 )  RETURN                                 
!C
      WRITE  ( LUAOU, 200 )                                                
  200 FORMAT ( '0', 4X, 'I', 4X, 'IPL', 3X, 'ISG', 2X, 'LTYPE',
     &         2X,'INDGX', 87X, 'Cards G.6', / )                          
!C                                                                       
!C    Input Cards G.6.                                     
!C                                                                        
      DO  I=1,NCON                                                    
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )    IPL(I), ISG(I), LTYPE(I), INDGX(I)         
       ELSE
        READ   ( LUAIN, 205 )    IPL(I), ISG(I), LTYPE(I), INDGX(I)         
  205  FORMAT ( 4I4 )                                                      
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 210 )    IPL(I), ISG(I), LTYPE(I), INDGX(I),
     &                          'Card G.6'         
  210    FORMAT ( 1X, 4 ( I4, 1X ), 1X, A )
        END IF
       END IF
!C
!C     Echo Card G.6 data to the standard output unit.
!C
       WRITE  ( LUAOU, 215 )   I, IPL(I), ISG(I), LTYPE(I), INDGX(I)        
  215  FORMAT ( 5I6 )                                                      
!C
       IF  ( ( IPL(I)   .LT. I_1 ) .OR. 
     &       ( IPL(I)   .GT. NPL  ) )  THEN 
        WRITE  ( LUAOU, 220 )  IPL(I), I                                  
        WRITE  ( LUTERM_OUT, 220 ) IPL(I), I
  220   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for IPL(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2611 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( ( ISG(I)   .LT. I_1 ) .OR. 
     &       ( ISG(I)   .GT. NSEG ) )  THEN  
        WRITE  ( LUAOU, 225 )  ISG(I), I                                  
        WRITE  ( LUTERM_OUT, 225 ) ISG(I), I
  225   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for ISG(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2612 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( ( LTYPE(I) .LT. I_3 ) .OR. 
     &       ( LTYPE(I) .GT. I_4    ) )  THEN   
        WRITE  ( LUAOU, 230 )  LTYPE(I), I                                  
        WRITE  ( LUTERM_OUT, 230 )  LTYPE(I), I
  230   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for LTYPE(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2613 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( ( INDGX(I) .LT. I_0 ) .OR. 
     &       ( INDGX(I) .GT. NVAR ) )  THEN 
        WRITE  ( LUAOU, 235 )  INDGX(I), I                                  
        WRITE  ( LUTERM_OUT, 235 )  INDGX(I), I
  235   FORMAT( 1X, 'Invalid value, ', I4, ' supplied for INDGX(',
     &          I4,'). Program terminated.')                                   
        STOP 'STOP 2614 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       J = IPL(I)                                                         
       NNPL = MNPL(J)                                                      
       IF   ( NNPL .LT. I_1 )  THEN 
        WRITE  ( LUAOU, 240 )  IPL(I), I                                  
        WRITE  ( LUTERM_OUT, 240 ) IPL(I), I
  240   FORMAT( 1X, 'No segment-plane contact found for plane ', I4, 
     &          ' for constraint ', I4,'). Program terminated.')                                   
        STOP 'STOP 2615 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       DO  K=1,NNPL                                                        
        IF  ( ISG(I) .NE. MPL(2,K,J) )  CYCLE                              
        ISG(I) = K                                                         
        EXIT                                                           
       END DO                                                              
       IF  ( K .GT. NNPL )   THEN    
        WRITE  ( LUAOU, 245 )  ISG(J), I                                  
        WRITE  ( LUTERM_OUT, 245 ) ISG(J), I
  245   FORMAT( 1X, 'No segment-plane contact found for segment ', I4, 
     &          ' for constrain ', I4,'). Program terminated.')                                   
        STOP 'STOP 2616 in Subroutine INPUT_EQUILB'                                                             
       END IF
!C
       IF  ( INDGX(I) .GT. I_0 )  THEN                               
        K = INDGX(I)                                                       
        IF  ( ( IPL(I) .NE. JPL(K) ) .OR. 
     &        ( ISG(I) .NE. JSG(K) ) )  THEN                            
         WRITE  ( LUAOU, 250 )  I, I                                  
         WRITE  ( LUTERM_OUT, 250 ) IPL(I), I
  250    FORMAT( 1X, 'Inconsistency between contact and constraint',
     &           ' for INDGX(', I4, 
     &           '), for constraint ', I4,'). Program terminated.')                                   
         STOP 'STOP 2617 in Subroutine INPUT_EQUILB'                                                             
        END IF
       END IF
      END DO                                                            
!C
      RETURN
      END