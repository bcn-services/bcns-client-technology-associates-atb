      SUBROUTINE WATER_PNT_VELOCITY ( POINT, WVEL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C   This routine finds the velocity of water "WVEL", at the location 
!C    given by "POINT" in the water frame.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       G,                             ! /CNSNTS/
     &       TIME,                          ! /CONTRL/
     &       SEG,                           ! structures
     &       INTEGER_STD, IREAL_HIGH, D_0   ! parameters
!C
!C    SEG%DIR_COS
!C
      USE  MODULE_WATER,  ONLY:
     &       KSEG_WATER,                ! /TEMPFD/
     &       FREQ, NWAVES, SWKH, WAMP,  ! /WAVEDAT/ 
     &       WD, WDEP, WDIR, WNUM, WPHS ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  CC1, CC2, CC3, POINT, TMP1_LCL, WVEL
!C
      DIMENSION         POINT(3), TMP1_LCL(3), WVEL(3)
!C
      INTENT (  IN )  POINT
      INTENT ( OUT )  WVEL
!C
!C    TMP1 point in inertial frame.
!C    TMP2 point in water frame.
!C
      WVEL(1) = D_0
      WVEL(2) = D_0
      WVEL(3) = D_0
      DO  I = 1,NWAVES
       IF ( WDEP .LT. D_0 )  THEN
        CC1 = FREQ(I) * WAMP(I) * EXP ( -POINT(3) * WNUM(I) )
        CC3 = -CC1
       ELSE
        CC1 =  G * WAMP(I) * WNUM(I) / FREQ(I)
        CC1 =  CC1 / SWKH(I)
        CC3 = -CC1 * SINH ( WNUM(I) * ( -POINT(3) + WDEP ) )
        CC1 =  CC1 * COSH ( WNUM(I) * ( -POINT(3) + WDEP ) )
       END IF
       CC2 = WNUM(I) * (   POINT(1) * COS ( WDIR(I) )
     &                   + POINT(2) * SIN ( WDIR(I) ) )
       CC2 = CC2 - FREQ(I) * TIME + WPHS(I)
       WVEL(1) = WVEL(1) + CC1 * COS ( CC2 ) * COS ( WDIR(I) )
       WVEL(2) = WVEL(2) + CC1 * SIN ( CC2 ) * SIN ( WDIR(I) )
       WVEL(3) = WVEL(3) + CC3 * SIN ( CC2 )
      END DO
      CALL DOT31 ( WD, WVEL, TMP1_LCL ) 
      CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, TMP1_LCL, WVEL )
!C
!C    WVEL in segment frame
!C
      RETURN
      END
