      SUBROUTINE PFDFRC ( XC, BP, CP, PHI_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This function will calculate the force and torque components 
!C    due to buoyancy and wave excitation forces.  R(I) is a point on the 
!C    ellipsiod in the ellipsiod system.  XX is the Z direction componment of
!C    the point in the inertial system.  UNORM is the normal vector of this 
!C    point.
!C
!C
      USE  MODULE_STANDARD, ONLY: 
     &        INTEGER_STD, IREAL_HIGH, D_0, I_0  ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &       CENTW, FF_WATER, KELT, T2, T5, WDSE,  ! /TEMPFD/
     &       NWAVES, WGAM                          ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BP, CP, R, PHI_LCL, UNORM, TMP1_LCL, 
     &                  XC, WZ, WPHI
      DIMENSION         R(3), UNORM(3), TMP1_LCL(3)                 
!C
      REAL  ( KIND = IREAL_HIGH )   WAVE_HEIGHT, WEXPHI
      EXTERNAL          WAVE_HEIGHT, WEXPHI
!C
      R(1)  = XC
      R(2)  = BP * COS ( PHI_LCL )
      R(3)  = CP * SIN ( PHI_LCL )
!C
      FF_WATER  = D_0
      CALL MAT31 ( WDSE(1,1,KELT), R, T5 ) 
      T5 = T5 + CENTW
      WZ = T5(3)
      IF ( NWAVES .GT. I_0 ) THEN
       WZ = WZ + WAVE_HEIGHT ( T5(1), T5(2) )
      END IF
      IF ( WZ .GE. D_0 ) THEN
       DO  I = 1,3
        UNORM(I) = R(I) * T2(I)
       END DO
       CALL UNTVEC ( UNORM, UNORM )
       CALL CROSS ( R, UNORM, TMP1_LCL )
       DO  I = 1,3
        FF_WATER(I) = -WGAM * WZ * UNORM(I)
       END DO
       IF ( NWAVES .GT. I_0 ) THEN
        DO  I = 1,NWAVES
         WPHI = -WEXPHI(I)
         DO  J = 1,3
          FF_WATER(J) = FF_WATER(J) + WPHI * UNORM(J)
         END DO
        END DO
        CALL CROSS ( R, FF_WATER(1), FF_WATER(4) )
       END IF
      END IF
!C
      RETURN
      END
