      SUBROUTINE WBAREA ( DELP3, DELP4, AMR )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine calculates the area of ellipsoid cut by water
!C    plane. 
!C
!C    Find the water surface elevation on the line perpendicular to the
!C     mean water surface from the center of the ellipsoid.  Then find the 
!C     tangential plane to the water surface through this point.  Calculate
!C     the area of the ellipse cut by this tangential plane
!C
      USE  MODULE_STANDARD,  ONLY:
     &       EPS,                           ! /CNSNTS/
     &       SEG,                           ! structures
     &       INTEGER_STD, IREAL_HIGH,       ! parameters 
     &       I_0, D_0, D_1, D_2             ! parameters
!C
!C    SEG%DIR_COS
!C
      USE  MODULE_WATER,  ONLY:
     &       BET, BTE, CENTW, KELT, KSEG_WATER, P1, ! /TEMPFD/
     &       TN, TSN, UU_WATER, VV,                 ! /TEMPFD/
     &       NWAVES, WD,                            ! /WAVEDAT/
     &       AREA                                   ! /WRESTLS/
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AMR, DEDX, DEDY, DELP3, DELP4, DMNT,  
     &                  TMP1_LCL, TP, U3, UV1, UV2, V3_LCL, 
     &                  XBETA, XBETA11, XBETA12, XBETA21, XBETA22,
     &                  XCN, XX, XX1, XX2, YY, YY1, YY2 
!C
      DIMENSION         DELP3(9), DELP4(9), DMNT(3,3), 
     &                  TMP1_LCL(3), TP(3), UV1(3), UV2(3), XCN(3)
!C
      REAL  ( KIND = IREAL_HIGH )   WAVE_HEIGHT
      EXTERNAL                      WAVE_HEIGHT
!C
!C    UV1,UV2: vectors in the plane tangential to the free-water surface
!C          expressed in the water frame
!C    TN:  unit normal to the free-water surface, expressed in the 
!C          water frame
!C
!C    P1 : point on the plane in water frame
!C    BET: the distance from the center ot the plane
!C
!C
!C    TP:  normal to plane in inertial system
!C    TS:  normal to plane in segment system
!C    BTE: the component, normal to the plane, of the vector from the point
!C          of maximum penetration to the ellipsoid center
!C    AMR: if AMR less or equal zero, the ellipsoid does not intersect
!C         the plane, AREA is zero.
!C
!C      
      XBETA = D_0
      U3 = D_0
      V3_LCL = D_0
      IF ( NWAVES .GT. I_0 )  THEN
       XBETA =  WAVE_HEIGHT ( CENTW(1), CENTW(2) )
!C
       XX1 = CENTW(1) + EPS(3)
       XX2 = CENTW(1) - EPS(3)
       YY  = CENTW(2)
       XBETA11 =  WAVE_HEIGHT ( XX1, YY )
       XBETA12 =  WAVE_HEIGHT ( XX2, YY )
!C
       XX  = CENTW(1)
       YY1 = CENTW(2) + EPS(3)
       YY2 = CENTW(2) - EPS(3)
       XBETA21 =  WAVE_HEIGHT ( XX, YY1 )
       XBETA22 =  WAVE_HEIGHT ( XX, YY2 )
!C
       DEDX = ( XBETA11 - XBETA12 ) / ( D_2 * EPS(3) )
       DEDY = ( XBETA21 - XBETA22 ) / ( D_2 * EPS(3) )
       U3 = DEDX
       V3_LCL = DEDY
      END IF
      UV1(1) = D_1
      UV1(2) = D_0
      UV1(3) = -U3
      UV2(1) = D_0
      UV2(2) = D_1
      UV2(3) = -V3_LCL
      CALL CROSS ( UV1, UV2, TMP1_LCL )
      CALL UNTVEC ( TMP1_LCL, TMP1_LCL )
!C
      TN(1) = -U3 
      TN(2) = -V3_LCL
      TN(3) = -D_1
      CALL UNTVEC ( TN, TN )
      P1(1) = CENTW(1)
      P1(2) = CENTW(2)
      P1(3) = -XBETA
      XCN(1) = D_0
      XCN(2) = D_0
      XCN(3) = - XBETA - CENTW(3)
      BET = -DOT_PRODUCT ( XCN, TMP1_LCL )
      CALL DOT31 ( WD, TN, TP )
      CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, TP, TSN )
      CALL MAT31 ( DELP3, TSN, TMP1_LCL )
      BTE = DOT_PRODUCT ( TSN, TMP1_LCL )
      BTE = SQRT ( BTE )
      AMR = D_1 - ( BET / BTE ) * ( BET / BTE )
      CALL UNTVEC ( TSN, TSN )
!C
!C    Transfer UV1, UV2 in water system to UU,VV in segment system
!C
      CALL DOTT33 ( SEG(KSEG_WATER)%DIR_COS, WD, DMNT )
      CALL MAT31 ( DMNT, UV1, UU_WATER )
      CALL MAT31 ( DMNT, UV2, VV )
      CALL UNTVEC ( UU_WATER, UU_WATER )
      CALL UNTVEC ( VV, VV )
      IF ( ( BET .GT. D_0 ) .AND. ( BET .GE. BTE) ) THEN
       AREA(KELT) = -D_1
      ELSE IF ( ( BET .LT. D_0 ) .AND. ( ABS ( BET ) .GE. BTE ) ) THEN
       AREA(KELT) =  D_0
      ELSE
       CALL CUTARE ( AREA(KELT), UU_WATER, VV, DELP4, AMR )
      END IF
!C
      RETURN
      END
