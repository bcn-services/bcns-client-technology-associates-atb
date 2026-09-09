      SUBROUTINE INPUT_WATER
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Controls the input of cards F.9.A - F.9.K containing the setup 
!C    and control of the water force analysis capability.                
!C    This subroutine is called only by Subroutine INITIALIZE.
!C
!C    If water depth is negative or zero, infinite depth is assumed.
!C
!C    WOFSET = offset to water reference frame from the inertial frame
!C
!C    WFRAME = yaw, pitch and roll of the water frame w.r.t the inertial frame
!C             define water frame such that z-axis points down into the water
!C             normal to the water surface.
!C
!C    WD =     direction cosine matrix of the water surface (w.r.t inertial
!C                                                           frame)
!C
!C    NWATER    = 1 water force calculations will be done irrespective of the
!C                no. of PFDs.
!C
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:
     &       NSEG,                               ! /CONTRL/
     &       SEG,                                ! structures
     &       INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LUAIN, LUAOU,                       ! parameters
     &       I_0, I_1, I_2, I_3,                 ! parameters 
     &       AIN_CONVERT, LIN_FLAG, LULIN        ! parameters
!C  
!C    DIR_COS, RECIP_MASS, WEIGHT   ! SEG%
!C
      USE  MODULE_WATER,  ONLY:
     &       NUM_PER_FLOAT_DEV,                           ! /WATINF1/
     &       ISPD, WD, WDEP, WFRAME, WGAM,  WOFSET,       ! /WAVEDAT/
     &       RWX, RWXX, WX, WXX                           ! /WMASS/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )    I, IDYPR, J 
      DIMENSION  IDYPR(3)
!C
      REAL  ( KIND = IREAL_HIGH )        ECOED, ECOEL
!C
      DATA             IDYPR / I_3, I_2, I_1 /
!C
!C
      WRITE ( LUAOU, 100 )
  100 FORMAT ( /, 1X, 'Water Force Input Parameters' )
!C
!C    Read in and echo Card F.9.a.
!C
      IF ( LIN_FLAG )  THEN
      READ  ( LULIN, * ) ( WOFSET(J), J=1,3 ), ( WFRAME(J), J=1,3 ),
     &                     WDEP, WGAM, ISPD
      ELSE
       READ  ( LUAIN, 105) ( WOFSET(J), J=1,3 ), ( WFRAME(J), J=1,3 ),
     &                       WDEP, WGAM, ISPD
  105  FORMAT ( 8F10.6, I2 )
       IF ( AIN_CONVERT )  THEN 
        WRITE  ( LULIN, 110) ( WOFSET(J), J=1,3 ), ( WFRAME(J), J=1,3 ),
     &                       WDEP, WGAM, ISPD, 'Card F.9.a'
  110   FORMAT ( 1X, 8( F17.9, 1X ), I4, 2X, A )
       END IF
      END IF
      WRITE ( LUAOU, 115 )  ( WOFSET(J), J=1,3 ), ( WFRAME(J), J=1,3 ),
     &                        WDEP, WGAM, ISPD
  115 FORMAT ( /, 1X,
     &         'Origin of Water Surface Frame W.R.T. the Inertial',
     &         ' Frame (in)', 1X, 3F10.2, /, 1X,
     &         'Yaw, Pitch & Roll (deg) of Water Frame', 1X, 3F7.2,
     &         /, 1X, 'Water Depth (in)', 18X, '= ', F10.2, /, 1X,
     &         'Specific Weight of Water (lb/in3) = ', F10.2, /,
     &         1X, 'Wind Speed Indicator', 14X, '= ', 8X, I2 )
      CALL DRCYPR ( WD, WFRAME, IDYPR )
!C
!C    Input the water wave descriptions, Cards F.b-d.
!C
      CALL CHECK_COMMENT
      CALL INPUT_WAVES 
!C
!C    Input the ellipsoids associated with water contact, Cards F.e-g.
!C
      CALL CHECK_COMMENT
      CALL INPUT_WATER_ELLIPSOIDS ( ECOED, ECOEL )
!C
!C    Input the personal floation device information, Cards F.h-j.
!C
      WRITE ( LUAOU, 120 )  NUM_PER_FLOAT_DEV
  120 FORMAT ( /, 1X, 'No. of Personal Flotation Devices (PFDs) =',
     &         1X, I2 )
      IF ( NUM_PER_FLOAT_DEV .GT. I_0 )  THEN
       CALL INPUT_PER_FLOAT_DEV ( ECOED, ECOEL )
      END IF
!C
!C    Input control information for water output, Cards F.k-m.
!C
      CALL CHECK_COMMENT
      CALL INPUT_WATER_OUTPUT
!C
!C    Store masses and weights of segments.
!C
      DO  I=1,NSEG
       WXX(I)  = SEG(I)%WEIGHT
       RWXX(I) = SEG(I)%RECIP_MASS
       DO  J=1,3
        WX(J,I)  = SEG(I)%WEIGHT
        RWX(J,I) = SEG(I)%RECIP_MASS
       END DO
      END DO
!C
      RETURN
      END
