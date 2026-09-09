      SUBROUTINE WATER_ADDED_MASS ( DELP2 )
!C                                             Rev. V.3 12/15/2002 
!C
!C    This routine calculates the added mass and damping forces acting
!C    on ellipsoid KELT associated with the water force option.
!C    ADDM(1-3,KELT) is the resulting force in the inertial system  
!C
      USE  MODULE_STANDARD,  
     &       ONLY: G,                                    ! /CNSNTS/
     &             SEG,                                  ! structures
     &             INTEGER_STD, IREAL_HIGH, MAXSEG       ! parameters
!C                                              
!C    SEG%DIR_COS,   SEG%ANG_ACCEL, SEG%ANG_VEL
!C    SEG%LIN_ACCEL, SEG%LIN_VEL,   SEG%RECIP_MASS, SEG%WEIGHT
!C
      USE  MODULE_WATER,  ONLY:  KELT, KSEG_WATER,       ! /TEMPFD/
     &                           CADDM,                  ! /WATINF1/
     &                           WGAM, WD,               ! /WAVEDAT/
     &                           RWX, WX, WXX,           ! /WMASS/
     &                           ADDM, BVL               ! /WRESLTS/
!C
      IMPLICIT  NONE
!C      
!C     Local Variables
!C
      INTEGER  ( KIND = INTEGER_STD )   J
!C
      REAL  ( KIND = IREAL_HIGH  )  ACC, VEL, TMP1, TMP2, DELP2, TMP3
      DIMENSION     ACC(3), VEL(3), TMP1(3), TMP2(3), DELP2(6), TMP3(3)
!C
      INTENT ( IN )  DELP2
!C
!C    CADDM(6,KELT) = array containing added-mass and damping coefficients
!C    CADDM(1-3,KELT) = added-mass coefficients
!C    CADDM(4-6,KELT) = damping coefficients
!C
!C    transfer SEG%LIN_ACCEL from inertial frame to water frame
!C    transfer SEG%LIN_VEL from inertial frame to water frame
!C                   
      CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, SEG(KSEG_WATER)%LIN_ACCEL,
     &             ACC )    
      CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, SEG(KSEG_WATER)%LIN_VEL,
     &             VEL )
      CALL CROSS ( SEG(KSEG_WATER)%ANG_VEL, DELP2(4), TMP1 )
      CALL CROSS ( SEG(KSEG_WATER)%ANG_VEL, TMP1, TMP2 )
      CALL CROSS ( SEG(KSEG_WATER)%ANG_ACCEL, DELP2(4), TMP3 )
      VEL = VEL + TMP1
      ACC = ACC + TMP2 + TMP3
      CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, VEL, TMP1 )
      CALL MAT31 ( WD, TMP1, VEL )
      CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, ACC, TMP1 )
      CALL MAT31 ( WD, TMP1, ACC )
!C
      SEG(KSEG_WATER)%WEIGHT = WXX(KSEG_WATER) + 
     &                         WGAM * BVL(KELT) * CADDM(1,KELT)
      SEG(KSEG_WATER)%RECIP_MASS = G / SEG(KSEG_WATER)%WEIGHT
      DO  J=1,3
       WX(J,KSEG_WATER) = WXX(KSEG_WATER) +
     &                    WGAM * BVL(KELT) * CADDM(J,KELT) 
       RWX(J,KSEG_WATER) = G / WX(J,KSEG_WATER)
       TMP1(J) = - WGAM * BVL(KELT) / G * ( CADDM(J,KELT) * ACC(J) + 
     &             CADDM(J+3,KELT) * VEL(J) )
      END DO
!C
!C    Transfer added-mass and damping force TMP1 in water system to inertial
!C    system.
!C
      CALL DOT31 ( WD, TMP1, ADDM(1,KELT) )
!C
      RETURN
      END
