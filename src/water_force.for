      SUBROUTINE WATER_FORCE
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This routine performs the following: 
!C    finds position of segments and PFD ellipsoids w.r.t water surface
!C    calls routine WATER_ELLIP_FORCE to find buoyancy and wave-excitation forces
!C
!C
!C    DISTM = distance between mouth and water surface
!C    WN    = normal to the mean water surface from water to air in the 
!C            inertial system
!C    IE    = 0: for body ellipsoid
!C    IE    = 1: for PFD ellipsoid
!C    BRI   = The ratio of body in water to total body volume
!C    KENY  = The net kinetic energy of the body
!C    WBD   = Point (1,0,0) if NEBODY in the ellipsoid frame
!C    ALFA1  = The azimuth of WBD w.r.t the x-axis of the tangent plane to water
!C    ALFA2  = The elevation of WBD w.r.t the z-axis of the water tangent plane 
!C
!C    TMP1 = DELP(-1)*(0,0,1)
!C
      USE  MODULE_STANDARD,  ONLY:
     &       G, PI,                           ! /CNSNTS/
     &       BD,                              ! /CNTSRF/
     &       SEG,                             ! structures
     &       INTEGER_STD, IREAL_HIGH, MAXELP, ! parameters
     &       I_0, D_0, D_HALF, D_180          ! parameters
!C
!C    ANG_VEL, DIR_COS, EXT_ANG_ACL, EXT_LIN_ACL, LIN_DISP,  ! SEG%
!C    LIN_VEL, PHI,     WEIGHT                               ! SEG% 
!C
      USE MODULE_WATER,  ONLY:
     &      DELP,                                         ! /ELPDAT/
     &      KELT, KSEG_WATER, UU_WATER, VV, WDSE,         ! /TEMPFD/
     &      BDPFD, DMOUTH, KPFD, MOUTHS,                  ! /WATINF1/
     &      NEBODY, NUM_ELLIP_WATER_CT,                   ! /WATINF1/
     &      NUM_PER_FLOAT_DEV, NSBODY, NWSE, PFDWT, TBDV, ! /WATINF1/
     &      DPFD, NPE,                                    ! /WATINF2/
     &      WD, WOFSET,                                   ! /WAVEDAT/
     &      ALFA1, ALFA2, BRI, DIST_MOUTH_TO_WATER,       ! /WFACOP/ 
     &      TENY, WAREA,                                  ! /WFACOP/
     &      AREA, BVL                                     ! /WRESLTS/
!C     
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, KE, KELL, KK
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AREA1, DEL, DT1, DT2, DT3, ENY, TBDW, 
     &                  TMP1_LCL, TMP2, TMP3, WBD, WN, WSURF
      DIMENSION         DEL(3,3), TMP1_LCL(3), TMP2(3), TMP3(3), 
     &                  WBD(3), WN(3)
!C
      REAL  ( KIND = IREAL_HIGH )  WAVE_HEIGHT
      EXTERNAL                     WAVE_HEIGHT
!C
      DO  J=1,3
       WN(J) = -WD(3,J)
       WBD(J) = DELP(1,J,NEBODY)
      END DO
!C
!C    Compute the forces from ellipsoids contacting the water.
!C
      IF ( NUM_ELLIP_WATER_CT .GT. I_0 ) THEN
       WAREA = D_0                                                              
       TBDW  = D_0
       TENY  = D_0
       DO  I=1,NUM_ELLIP_WATER_CT
        KELL = NWSE(1,I)
        KELT = KELL
        KSEG_WATER = NWSE(2,I)
        CALL DOTT33 ( WD, SEG(KSEG_WATER)%DIR_COS, DEL )
        CALL DOTT33 ( DEL, DELP(1,1,KELL), WDSE(1,1,KELL) )
        CALL WATER_ELLIP_FORCE ( WN, DELP(1,1,KELL), BD(1,KELL), 
     &                           BD(16,KELL), BD(7,KELL) )
        AREA1 = AREA(KELL)
        IF ( KSEG_WATER .EQ. NSBODY ) THEN
         CALL CROSS ( UU_WATER, VV, TMP1_LCL )
         DT1 = DOT_PRODUCT ( UU_WATER, WBD )
         DT2 = DOT_PRODUCT ( VV, WBD )
         DT3 = DOT_PRODUCT ( TMP1_LCL, WBD )
         ALFA1 = ATAN2 ( DT2, DT1 ) * D_180 / PI
         ALFA2 = ACOS ( DT3 ) * D_180 / PI
        END IF
        IF ( AREA1 .LT. D_0 )  AREA1 = D_0
        WAREA = WAREA + AREA1                                            
        TBDW = TBDW + BVL(KELL)
        ENY  = D_HALF * SEG(KSEG_WATER)%WEIGHT * 
     &  DOT_PRODUCT ( SEG(KSEG_WATER)%LIN_VEL, SEG(KSEG_WATER)%LIN_VEL ) 
     &                              / G
        DO  J=1,3
         ENY  = ENY + D_HALF * SEG(KSEG_WATER)%PHI(J) 
     &                     *  (SEG(KSEG_WATER)%ANG_VEL(J) )**2
        END DO
        TENY = TENY + ENY
       END DO
       BRI = TBDW / TBDV
      END IF
!C
!C    Compute forces from the personal floation devices.
!C
      IF ( NUM_PER_FLOAT_DEV .GT. I_0 ) THEN
       TMP1_LCL(1) = D_0
       TMP1_LCL(2) = D_0
       DO  I = 1,NUM_PER_FLOAT_DEV
        TMP1_LCL(3) = PFDWT(1,I)
        KK = NINT ( PFDWT(5,I) )
        CALL DOT31 ( WD,              TMP1_LCL, TMP2 )
        CALL MAT31 ( SEG(KK)%DIR_COS, TMP2,     TMP1_LCL )
        CALL CROSS ( PFDWT(2,I),      TMP1_LCL, TMP3 )
        SEG(KK)%EXT_LIN_ACL = SEG(KK)%EXT_LIN_ACL + TMP2
        SEG(KK)%EXT_ANG_ACL = SEG(KK)%EXT_ANG_ACL + TMP3
       END DO
       DO  KE=1,NPE
        KELL = KE
        KSEG_WATER = KPFD(KE) 
        KELT = KE + MAXELP 
        CALL DOTT33 ( WD,  SEG(KSEG_WATER)%DIR_COS, DEL            )
        CALL DOTT33 ( DEL, DPFD(1,1,KE),            WDSE(1,1,KELT) )
        CALL WATER_ELLIP_FORCE ( WN, DPFD(1,1,KE), BDPFD(1,KE), 
     &                           BDPFD(22,KE), BDPFD(13,KE) )
       END DO
      END IF
!C
!C    Compute the distance from the mouth to the water surface.
!C
      TMP1_LCL = SEG(MOUTHS)%LIN_DISP + DMOUTH - WOFSET
      CALL MAT31 ( WD, TMP1_LCL, TMP2 )
      WSURF =  WAVE_HEIGHT ( TMP2(1), TMP2(2) )
      DIST_MOUTH_TO_WATER = - TMP2(3) - WSURF
!C
      RETURN
      END
