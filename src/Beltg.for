      SUBROUTINE BELTG ( ZA, ZB, ZC, BD_BELTG )                           
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Compute tangent points, unit vectors from tangent points to          
!C    anchor points and lengths of the belt segments.                      
!C                                                                         
!C    Arguments:                                                           
!C                                                                         
!C        ZA,ZB - anchor points relative to ellipsoid center.              
!C        ZC    - fixed point of belt on segment ellipsoid.                
!C        BD    - segment ellipsoid semiaxes and center.                   
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS, TWOPI,                                  ! /CNSNTS/
     &       NPRT,                                        ! /CONTRL/
     &       DLGA, DLGB,  APA, APB, UVA, UVB, UAA, UBB,   ! /BELT_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,              ! parameters
     &       D_0, D_1, I_0, I_3                           ! parameters
!C
      REAL  ( KIND = IREAL_HIGH )  ELONG, VECMAG
      EXTERNAL                     ELONG, VECMAG
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )   I, J, K
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ZA, ZB, ZC, BD_BELTG, S, BET, YAY, YAY1,
     &                  ZZA, ZZB, C2A, C2B, TTA, TTB, C3A, C3B, TT,
     &                  TH1, TH2, TH3, TH4, THMIN, UPACA, UPACB,
     &                  UPUVA, UPUVB, UCACA, UCACB, UCUVA,UCUVB,
     &                  THA, THB, EPS1, GG_BELT,
     &                  TA, TB, TC, UP, B_BELT, UC, AX, XE, BX, 
     &                  ACA, ACB
      DIMENSION  ZA(3), ZB(3), ZC(3), BD_BELTG(24),                        
     &           TA(3), TB(3), TC(3), UP(3), B_BELT(3),                    
     &           UC(3), AX(3), XE(3), BX(3), ACA(3), ACB(3)                
!C                                                                         
!C    Compute                                                              
!C      TC: normalized vector of belt plane determined                    
!C          by anchor points and fixed point.                              
!C                                                                         
      DO  K=1,3                                                            
       TA(K) = ZC(K) - ZA(K)                                               
       TB(K) = ZC(K) - ZB(K)                                               
      END DO
      CALL CROSS ( TB, TA, TC )                                            
      S = SQRT ( TC(1)**2 + TC(2)**2 + TC(3)**2 )                          
      TC(1) = TC(1) / S                                                    
      TC(2) = TC(2) / S                                                    
      TC(3) = TC(3) / S                                                    
!C                                                                         
!C    Get distance of belt plane to center of ellipsiod.                   
!C                                                                         
      BET = DOT_PRODUCT ( TC, ZC )
!C                                                                         
!C    Compute                                                              
!C      XE: center of ellipse determined by intersection                   
!C          of belt plane and segment ellipsoid.                           
!C                                                                         
      CALL MAT31 ( BD_BELTG(16), TC, XE )                                 
      GG_BELT = BET / DOT_PRODUCT ( TC, XE )  
      DLGA = D_0                                                         
      DLGB = D_0                                                         
      DO  K=1,3                                                            
       XE(K)  = XE(K) * GG_BELT                                            
       UC(K)  = ZC(K) - XE(K)                                              
       APA(K) = UC(K)                                                      
       APB(K) = UC(K)                                                      
      END DO
      YAY = GG_BELT * BET                                                 
      YAY1 = D_1 - YAY                                                    
      IF ( YAY1 .GT. EPS(6) )  THEN                                     
!C                                                                         
!C     Calculate possible tangent points from                               
!C       UVA,UVB: vectors from ellipse center to midpoint of               
!C                line connecting possible tangent points.                  
!C       ACA,ACB: vectors from UVA,UVB to tangent points (positive).       
!C                                                                         
       CALL MAT31 ( BD_BELTG(7), ZA, AX )                                  
       CALL MAT31 ( BD_BELTG(7), ZB, BX )                                  
       ZZA = DOT_PRODUCT ( AX, ZA )
       IF ( ZZA .LE. D_1 )  STOP 88                                        
       ZZB = DOT_PRODUCT ( BX, ZB )
       IF ( ZZB .LE. D_1 )  STOP 89                                        
       C2A = YAY1 / ( ZZA - YAY )                                           
       C2B = YAY1 / ( ZZB - YAY )                                           
       CALL CROSS ( TC, AX, ACA )                                           
       CALL CROSS ( TC, BX, ACB )                                           
       TTA = D_0                                                          
       TTB = D_0                                                        
       DO  I=1,3                                                            
        DO  J=1,3                                                           
         K = I_3 * J + I + I_3                                     
         TTA = TTA + ACA(I) * BD_BELTG(K) * ACA(J)                         
         TTB = TTB + ACB(I) * BD_BELTG(K) * ACB(J)                         
        END DO
       END DO
       C3A = SQRT ( ( D_1 - C2A ) * YAY1 / TTA )                         
       C3B = SQRT ( ( D_1 - C2B ) * YAY1 / TTB )                          
       TT = VECMAG ( UC )
       DO  K=1,3                                                           
        UVA(K) = C2A * ( ZA(K) - XE(K) )                                   
        UVB(K) = C2B * ( ZB(K) - XE(K) )                                    
        ACA(K) = C3A * ACA(K)                                               
        ACB(K) = C3B * ACB(K)                                               
        UC(K) = UC(K) / TT                                                 
        B_BELT(K) = D_0                                                  
       END DO
!C                                                                         
!C     Obtain equation of ellipse                                          
!C        B1*X**2 + 2*B2*X*Y + B3*Y**2 = 1                                  
!C     in UC,UP coordinates where UC points to fixed point.                
!C                                                                          
       CALL CROSS ( TC, UC, UP )                                            
       DO  I=1,3                                                            
        DO  J=1,3                                                          
         K = I_3 * J + I + I_3                                     
         B_BELT(1) = B_BELT(1) + UC(I) * BD_BELTG(K) * UC(J)                
         B_BELT(2) = B_BELT(2) + UC(I) * BD_BELTG(K) * UP(J)               
         B_BELT(3) = B_BELT(3) + UP(I) * BD_BELTG(K) * UP(J)             
        END DO
       END DO
       B_BELT = B_BELT / YAY1                                      
!C                                                                         
!C     Compute angles from fixed point to possible tangent points.          
!C                                                                          
       UCUVA = DOT_PRODUCT ( UC, UVA )
       UCUVB = DOT_PRODUCT ( UC, UVB )
       UCACA = DOT_PRODUCT ( UC, ACA )
       UCACB = DOT_PRODUCT ( UC, ACB )
       UPUVA = DOT_PRODUCT ( UP, UVA )
       UPUVB = DOT_PRODUCT ( UP, UVB )
       UPACA = DOT_PRODUCT ( UP, ACA )
       UPACB = DOT_PRODUCT ( UP, ACB )
       TH1 = ATAN2 ( ( UPUVA - UPACA ), ( UCUVA - UCACA ) )               
       TH2 = ATAN2 ( ( UPUVA + UPACA ), ( UCUVA + UCACA ) )                
       TH3 = ATAN2 ( ( UPUVB - UPACB ), ( UCUVB - UCACB ) )                 
       TH4 = ATAN2 ( ( UPUVB + UPACB ), ( UCUVB + UCACB ) )               
       IF ( TH1 .LT. D_0 )  TH1 = TWOPI + TH1                            
       IF ( TH2 .LT. D_0 )  TH2 = TWOPI + TH2                          
       IF ( TH3 .LT. D_0 )  TH3 = TWOPI + TH3                          
       IF ( TH4 .LT. D_0 )  TH4 = TWOPI + TH4                        
!C                                                                         
!C     Choose proper tangent points and belt arc lengths.                  
!C                                                                        
       THMIN = MIN ( TH1, TH2, TH3, TH4 )                                  
       IF  ( ( ( THMIN .EQ. TH1 ) .AND. 
     &       ( MIN ( TH2, TH3, TH4 ) .NE. TH4 ) )  .OR.             
     &       ( ( THMIN .EQ. TH2 ) .AND. 
     &       ( MAX ( TH1, TH3, TH4 ) .EQ. TH4 ) ) ) THEN               
        THA = TH1                                                          
        THB = TWOPI - TH4                                                  
        APA = UVA - ACA                                          
        APB = UVB + ACB                                          
        EPS1 = EPS(1)                                                       
        DLGA = ABS ( ELONG ( B_BELT(1), B_BELT(2), B_BELT(3), 
     &                        EPS1, THA ) )                                 
        DLGB = ABS ( ELONG ( B_BELT(1), B_BELT(2), B_BELT(3),
     &                        EPS1, THB ) )                                 
       ELSE IF  ( ( ( THMIN .EQ. TH3 ) .AND. 
     &       ( MIN ( TH1, TH2, TH4 ) .NE. TH2 ) )  .OR.                
     &            ( ( THMIN .EQ. TH4 ) .AND. 
     &       ( MAX ( TH1, TH2, TH3 ) .EQ. TH2 ) ) ) THEN             
        THA = TWOPI - TH2                                                  
        THB = TH3                                                         
        APA = UVA + ACA                                         
        APB = UVB - ACB                                           
        EPS1 = EPS(1)                                                      
        DLGA = ABS ( ELONG ( B_BELT(1), B_BELT(2), B_BELT(3), 
     &                        EPS1, THA ) )                                 
        DLGB = ABS ( ELONG ( B_BELT(1), B_BELT(2), B_BELT(3),
     &                        EPS1, THB ) )                                
       END IF
      END IF
!C                                                                          
!C    Calculate belt lengths and unit vectors                             
!C     from tangent points to anchor points.                                
!C                                                                          
      UAA = D_0                                                  
      UBB = D_0                                                           
      DO  K=1,3                                                            
       APA(K) = APA(K) + XE(K)                                             
       APB(K) = APB(K) + XE(K)                                             
       UVA(K) = ZA(K) - APA(K)                                             
       UVB(K) = ZB(K) - APB(K)                                             
       APA(K) = APA(K) + BD_BELTG(K+3)                                     
       APB(K) = APB(K) + BD_BELTG(K+3)                                     
       UAA = UAA + UVA(K)**2                                               
       UBB = UBB + UVB(K)**2                                               
      END DO                                                               
      UAA = SQRT ( UAA )                                                   
      UBB = SQRT ( UBB )                                                   
      UVA = UVA / UAA                                                
      UVB = UVB / UBB                                                
!C                                                                        
!C    Optional output                                                     
!C                                                                         
      IF ( NPRT(15) .NE. I_0 ) THEN                                      
       WRITE ( LUAOU, 150 )                                               
  150  FORMAT ( 1X, 'Belt Restraint' )                                     
       WRITE ( LUAOU, 160 )  APA, UVA, DLGA, UAA                          
       WRITE ( LUAOU, 160 )  APB, UVB, DLGB, UBB                          
  160  FORMAT ( 1X, 8( 1PD15.5 ) )                                      
      END IF
!C
      RETURN                                                              
      END                                                                 
