      SUBROUTINE WATER_DRAG_CHK ( BCTR, DELP2, DELP3, DELP4 )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine computes the drag and lift forces on
!C     ellipsoids associated with the water force option.
!C
      USE  MODULE_STANDARD,  ONLY:   
     &        EPS, G,                                     ! /CNSNTS/
     &        SEG,                                        ! structures
     &        INTEGER_STD, IREAL_HIGH, LUAOU, LUTERM_OUT, ! parameters
     &        I_1, I_2, I_3, I_4, I_50,                   ! parameters
     &        D_0, D_HALF, D_1, D_2, D_4                  ! parameters
!C
!C    SEG%ANG_VEL, SEG%DIR_COS, SEG%LIN_VEL
!C
      USE  MODULE_WATER,  ONLY:  
     &       KSEG_WATER, KELT, CENTW,  BET, BTE, ! /TEMPFD/
     &       UU_WATER, VV, TSN,                  ! /TEMPFD/
     &       COED, COEL,                         ! /WATINF1/
     &       WD, WGAM,                           ! /WAVEDAT/
     &       AREA, DRAG                          ! /WRESLTS/
!C 
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  J, J1, KCH, NCHD
!C
      REAL  ( KIND = IREAL_HIGH )   VECMAG, XDY
      EXTERNAL                      VECMAG, XDY
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ADDR, AREAP, COEA, COEB, COEC,
     &                  COSANG, D1, D2, DBET, DBTE, DDL, DELT, DR, 
     &                  DSCR, DST, DTMP1, DTMP2, DVREL, DX1, 
     &                  FCOEF, FDRAG, FLIFT, H_LCL,
     &                  PAP, PAT, PT1, PT12, PT2,  QQ_LCL,
     &                  ROOT1, ROOT2, RR, RT, SIGN_LCL, SUM, TAT,
     &                  THETA, TT, UNIT, YY, ZZ
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BCTR, CHORD, DELP2, DELP3, DELP4, PN, PT,
     &                  TL, TMP1, TMP2, TMP3, TMP4, UV1, UV2, VEL, 
     &                  VEREL, WVEL
      DIMENSION     VEL(3), TMP1(3), TMP2(3), TMP3(3), TMP4(3),  
     &              VEREL(3),
     &              WVEL(3), PN(3), TL(3), UV1(3), UV2(3), PT(3),
     &              BCTR(3), DELP2(6), DELP3(9), DELP4(9), CHORD(50)
!C
      REAL  ( KIND = IREAL_HIGH )  DRAG_VEL, TEST_1, DRAG_PRM1,
     &                             DRAG_PRM2, DRAG_PRM3
      PARAMETER ( DRAG_VEL = 0.1_IREAL_HIGH, 
     &            TEST_1 = 0.005_IREAL_HIGH,
     &            DRAG_PRM1 = 0.24_IREAL_HIGH,
     &            DRAG_PRM2 = -0.53_IREAL_HIGH,
     &            DRAG_PRM3 = 1.25_IREAL_HIGH )
!C
      UNIT = D_1
      DELT = D_HALF
!C       
!C    Find the velocity of the ellipsoid at the point corresponding to the 
!C    center of mass of the displaced water.
!C       
      CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, 
     &             SEG(KSEG_WATER)%LIN_VEL, VEL )  
      IF ( AREA(KELT) .LT. D_0 ) THEN
       CALL CROSS ( SEG(KSEG_WATER)%ANG_VEL, DELP2(4), TMP1 )
      ELSE
       TMP1 = BCTR - CENTW
       CALL DOT31 ( WD, TMP1, TMP2 )
       CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, TMP2, TMP1 )
       DO  J=1,3
        TMP2(J) = TMP1(J) + DELP2(J+3)
       END DO
       CALL CROSS ( SEG(KSEG_WATER)%ANG_VEL, TMP2, TMP1 )
      END IF
      VEL = VEL + TMP1
!C                
!C    VEL = relative velocity of the center of buoyancy of ellipsoid
!C          in segment system          
!C      
      CALL WATER_PNT_VELOCITY ( BCTR, WVEL )
      VEL = WVEL - VEL 
      DVREL = VECMAG ( VEL )
      CALL UNTVEC ( VEL, VEREL )
!C       
!C    if VEL < 0.1 in/sec do not calculate drag forces    
!C       
      IF ( DVREL .LT. DRAG_VEL ) RETURN
!C          
!C     Find V(T)A
!C       
      DO  J=1,3
       J1 = I_3 * J - I_2
       TMP4(1) = DELP4(J1)
       TMP4(2) = DELP4(J1+1)
       TMP4(3) = DELP4(J1+2)
       TMP1(J) = DOT_PRODUCT ( VEL, TMP4 )
       TL(J) = D_0
      END DO
!C       
!C    TMP1 = V(T)A (SEG FRAME)  PN= UNTVEC TMP1
!C        
      CALL UNTVEC ( TMP1, PN )
      CALL CROSS ( VEREL, PN, UV1 )
      ZZ = VECMAG ( UV1 )
      CALL UNTVEC ( UV1, UV1 )
!C       
!C     ZZ = 0 Then PN // VEL
!C       
      IF ( ZZ .GT. EPS(3) )  THEN
       CALL CROSS ( UV1, PN, UV2 )
       CALL UNTVEC ( UV2, UV2 )
      ELSE
       CALL CROSS ( PN, TSN, TMP1 )
       YY = VECMAG ( TMP1 )
!C         
!C     YY = 0 Then PN // TSN
!C          
       IF ( YY .GT. EPS(3) )  THEN
        CALL CROSS ( PN, TSN, UV1 )
        CALL UNTVEC ( UV1, UV1 )
        CALL CROSS ( UV1, PN, UV2 )
        CALL UNTVEC ( UV2, UV2 )
       ELSE
        UV1 = UU_WATER
        UV2 = VV
        IF ( BET .GT. D_0 )  THEN 
         CALL CUTARE ( AREAP, UV1, UV2, DELP4, UNIT )
        ELSE IF ( BET .LE. D_0 )  THEN
         AREAP = AREA(KELT)
        END IF
        COSANG = D_1
        FCOEF = D_HALF * WGAM / G * AREAP * DVREL * DVREL
        FDRAG = FCOEF * COED(KELT)
        IF ( ( ABS ( BTE ) - BET ) .GT. TEST_1 )  THEN
         H_LCL = ABS ( BTE ) / ( ABS ( BTE ) - BET )                             
         FDRAG = FDRAG + DRAG_PRM1 * 
     &           ( D_1 - EXP ( DRAG_PRM2 * H_LCL ) ) * WGAM
     &           * AREAP**DRAG_PRM3 * DVREL / SQRT ( G )                        
        END IF
        IF ( ( ABS ( COSANG ) .GT. D_1 ) .AND.  
     &       ( ABS ( COSANG ). LT. ( D_1 + EPS (4) ) ) ) THEN 
         COSANG = SIGN ( D_1, COSANG )
        END IF
        THETA = D_2 * ACOS ( COSANG )
        FLIFT = FCOEF * COEL(KELT) * SIN ( THETA )
        TMP1 = FDRAG * VEREL
        CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, TMP1, DRAG(1,KELT) )
        TMP2 = FLIFT * TL
        CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, TMP2, DRAG(4,KELT) )
!C
!C      DRAG(1-3,KELL) : drag force in inertial system
!C      DRAG(4-6,KELL) : lift force in inertial system
!C 
        RETURN
       END IF
      END IF
!C          
!C    Ellipsoid is totally submerged
!C           
      IF ( AREA(KELT) .LT. D_0 ) THEN
       CALL CUTARE ( AREAP, UV1, UV2, DELP4, UNIT )
       COSANG = ABS ( DOT_PRODUCT ( VEREL, PN ) )
       AREAP = AREAP * COSANG
      ELSE
!C          
!C     Ellipsoid is partially submerged.  Find the points on UV2 such
!C     that qUV2 + sVEREL lie on the ellipsoid and on the water surface.
!C                    
       QQ_LCL = XDY ( UV2, DELP4, UV2 )
       RR     = XDY ( UV2, DELP4, VEREL )
       TT     = XDY ( VEREL, DELP4, VEREL )
       D1     = DOT_PRODUCT ( UV2, TSN )
       D2     = DOT_PRODUCT ( VEREL, TSN )
       IF ( D2 .NE. D_0 )THEN
        DR = D1 / D2
        COEA = QQ_LCL - D_2 * DR * RR + DR * DR * TT
        COEB = D_2 * BET * ( RR - DR * TT ) / D2
        COEC = ( BET * BET * TT / ( D2 * D2 ) ) - D_1
        DSCR = COEB * COEB - D_4 * COEA * COEC
        IF ( ( ABS ( DSCR ) .LT. TEST_1 ) .AND. 
     &       ( DSCR .LT. D_0 ) ) THEN
         DSCR = D_0
        END IF
!C             
!C      Check if DSCR < 0.0.
!C              
        IF ( DSCR .LT. D_0 )  THEN
         CALL CUTARE ( AREAP, UV1, UV2, DELP4, UNIT )
         COSANG = ABS ( DOT_PRODUCT ( VEREL, PN ) )
         AREAP = AREAP * COSANG
         FCOEF = D_HALF * WGAM / G * AREAP * DVREL * DVREL
         FDRAG = FCOEF * COED(KELT)
         IF ( ( ABS ( BTE ) - BET ) .GT. TEST_1 )  THEN
          H_LCL = ABS ( BTE ) / ( ABS ( BTE ) - BET )                             
          FDRAG = FDRAG + DRAG_PRM1 * 
     &            ( D_1 - EXP ( DRAG_PRM2 * H_LCL ) ) * WGAM
     &            * AREAP**DRAG_PRM3 * DVREL / SQRT ( G )                        
         END IF
         IF ( ( ABS ( COSANG ) .GT. D_1 ) .AND.  
     &        ( ABS ( COSANG ). LT. ( D_1 + EPS (4) ) ) ) THEN 
          COSANG = SIGN ( D_1, COSANG )
         END IF
         THETA = D_2 * ACOS ( COSANG )
         FLIFT = FCOEF * COEL(KELT) * SIN ( THETA )
         TMP1 = FDRAG * VEREL
         CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, TMP1, DRAG(1,KELT) )
         TMP2 = FLIFT * TL
         CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, TMP2, DRAG(4,KELT) )
!C   
!C        DRAG(1-3,KELL) : drag force in inertial system
!C        DRAG(4-6,KELL) : lift force in inertial system
!C 
         RETURN
        END IF
        DSCR  = SQRT ( DSCR ) / ( D_2 * COEA )
        ADDR  = -COEB / ( D_2 * COEA )
        ROOT1 = ADDR + DSCR
        ROOT2 = ADDR - DSCR
       ELSE
        ROOT1 = BET / D1
        ROOT2 = ROOT1
       END IF
       DTMP1 = D1 * ROOT1
       DTMP2 = D1 * ROOT2
       PT1   = D_0
       PT2   = D_0
       IF ( BET .GT. D_0 ) THEN
        IF ( ( DTMP1 .LE. D_0 ) .OR. ( DTMP1 .LE. BET ) )  PT1 = D_1
        IF ( ( DTMP2 .LE. D_0 ) .OR. ( DTMP2 .LE. BET)  )  PT2 = D_1
       ELSE IF ( BET .LE. D_0 ) THEN
        IF ( DTMP1 .LT. BET ) PT1 = D_1
        IF ( DTMP2 .LT. BET ) PT2 = D_1
       END IF
       PT12 = D_HALF * ( PT1 + PT2 )
       IF ( PT12 .EQ. D_1 ) THEN
!C             
!C      Ellipse V(T)A is inside water.
!C      Ellipsoid is treated as fully submerged.
!C              
        CALL CUTARE ( AREAP, UV1, UV2, DELP4, UNIT )
        COSANG = ABS ( DOT_PRODUCT ( VEREL, PN ) )
        AREAP = AREAP * COSANG
       ELSE IF ( PT12 .EQ. D_0 ) THEN
!C         
!C      Ellipse V(T)A is outside water.
!C              
        AREAP = AREA(KELT)
        COSANG = ABS ( DOT_PRODUCT ( VEREL, TSN ) )
        AREAP = AREAP * COSANG
       ELSE
!C            
!C      Ellipse V(T)A is cut by water plane. 
!C            
        CALL CROSS ( PN, TSN, TMP1 )
        CALL UNTVEC ( TMP1, TMP1 )
        IF ( PT1 .EQ. D_0 )  RT = ROOT1
        IF ( PT2 .EQ. D_0 )  RT = ROOT2
        PT = RT * UV2
        CALL CROSS ( TMP1, PN, TMP2 )
        DX1 = DOT_PRODUCT ( TMP2, TSN )
        IF ( DX1 .LT. D_0 ) THEN
         TMP2 = -TMP2
         CALL UNTVEC ( TMP2, TMP2 )
        END IF
        DBET = DOT_PRODUCT ( PT, TMP2 )
        CALL MAT31 ( DELP3, TMP2, TMP3 )
        DBTE = DOT_PRODUCT ( TMP2, TMP3 )
        DBTE = SQRT ( DBTE )
        DST  = DBTE + DBET
        NCHD = INT ( DST / DELT )
        IF ( NCHD .LT. I_4 ) THEN
         NCHD = I_4
        ELSE IF ( NCHD .GT. I_50 ) THEN
         NCHD = I_50
        END IF
        DELT = DST / REAL ( NCHD, IREAL_HIGH )
        PAP  = XDY ( PT, DELP4, PT )
        PAT  = XDY ( PT, DELP4, TMP1 )
        TAT  = XDY ( TMP1, DELP4, TMP1 )
        COEA = TAT
        COEB = D_2 * PAT
        COEC = PAP - D_1
        DSCR = COEB * COEB - D_4 * COEA * COEC
!C        
!C      Check if dcsr < 0.0.
!C              
        IF ( ( ABS ( DSCR ) .LT. TEST_1 ) .AND.
     &       ( DSCR .LT. D_0 ) )   DSCR = D_0
        IF ( DSCR .LT. D_0 )  THEN
         WRITE ( LUTERM_OUT, 100 ) KELT
         WRITE ( LUAOU, 100 ) KELT
  100    FORMAT('  Drag routines failed: cannot find ',
     &          'projected area for ellipsoid ',I4,
     &           ' program terminated')
         STOP  ' STOP 402 in Subroutine DRGCHK '
        END IF
        DSCR = SQRT ( DSCR ) / ( D_2 * COEA )
        CHORD(1) = ( D_2 * DSCR )
        KCH = I_1
        DO  J=1,( NCHD - I_2 )
         PT = PT - DELT * TMP2
         PAP  = XDY ( PT, DELP4, PT )
         PAT  = XDY ( PT, DELP4, TMP1 ) 
         COEB = D_2 * PAT
         COEC = PAP - D_1
         DSCR = COEB * COEB - D_4 * COEA * COEC
!C                  
!C       check if dcsr < 0.0
!C               
         IF ( DSCR .LT. D_0 )  EXIT
         KCH = KCH + I_1
         DSCR = SQRT ( DSCR ) / ( D_2 * COEA )
         CHORD(KCH) = D_2 * DSCR
        END DO
        SUM = D_HALF * CHORD(1)
        DO  J = 2,KCH
         SUM = SUM + CHORD(J)
        END DO
        AREAP = SUM * DELT
        COSANG = ABS ( DOT_PRODUCT ( PN, VEREL ) )
       END IF
      END IF
      DDL = DOT_PRODUCT ( VEREL, UV2 )
      IF ( ABS ( DDL ) .GT. EPS(3) )  THEN
       SIGN_LCL = D_1
       IF ( DDL .LT. D_0 ) SIGN_LCL = -D_1
       CALL CROSS ( VEREL, UV2, TMP1 )
       CALL CROSS ( VEREL, TMP1, TMP2 )
       CALL UNTVEC ( TMP2, TMP2 )
       TL = SIGN_LCL * TMP2
      END IF
!C
      FCOEF = D_HALF * WGAM / G * AREAP * DVREL * DVREL
      FDRAG = FCOEF * COED(KELT)
      IF ( ( ABS ( BTE ) - BET ) .GT. TEST_1 )  THEN
       H_LCL = ABS ( BTE ) / ( ABS ( BTE ) - BET )                             
       FDRAG = FDRAG + DRAG_PRM1 * 
     &         ( D_1 - EXP ( DRAG_PRM2 * H_LCL ) ) * WGAM
     &         * AREAP**DRAG_PRM3 * DVREL / SQRT ( G )                        
      END IF
      IF ( ( ABS ( COSANG ) .GT. D_1 ) .AND.  
     &     ( ABS ( COSANG ). LT. ( D_1 + EPS (4) ) ) ) THEN 
       COSANG = SIGN ( D_1, COSANG )
      END IF
      THETA = D_2 * ACOS ( COSANG )
      FLIFT = FCOEF * COEL(KELT) * SIN ( THETA )
      TMP1 = FDRAG * VEREL
      CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, TMP1, DRAG(1,KELT) )
      TMP2 = FLIFT * TL
      CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, TMP2, DRAG(4,KELT) )
!C
!C     DRAG(1-3,KELL) : drag force in inertial system
!C     DRAG(4-6,KELL) : lift force in inertial system
!C 
      RETURN
      END
