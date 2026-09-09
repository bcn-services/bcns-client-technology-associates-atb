       SUBROUTINE PFDBOY ( XC, BP, CP, PHI_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This function will calculate the force and torque components 
!C    Due to buoyancy force.  R(I) is a point on the ellipsiod  
!C    in the ellipsiod system. XX is the Z direction componment of the 
!C    point in the inertial system.  UNORM Is the normal vector of this point.
!C
!C
      USE  MODULE_STANDARD, ONLY: 
     &        INTEGER_STD, IREAL_HIGH, D_0, I_0   ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &          KELT, CENTW, FF_WATER, T2, T5, WDSE, ! /TEMPFD/
     &          NWAVES, WGAM                         ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I
!C
      REAL  ( KIND = IREAL_HIGH )  BP, CP, R, UNORM, PHI_LCL, XC, WZ
      DIMENSION         R(3), UNORM(3)                 
!C
      REAL  ( KIND = IREAL_HIGH )  WAVE_HEIGHT
      EXTERNAL          WAVE_HEIGHT
!C
      R(1)  = XC
      R(2)  = BP * COS ( PHI_LCL )
      R(3)  = CP * SIN ( PHI_LCL )
      CALL MAT31 ( WDSE(1,1,KELT), R, T5 )
      DO  I=1,3
       T5(I) = T5(I) + CENTW(I)
      END DO
      WZ = T5(3)
      IF ( NWAVES .GT. I_0 )  THEN
       WZ = WZ + WAVE_HEIGHT ( T5(1), T5(2) )
      END IF
      IF  ( WZ .GE. D_0 )  THEN
       DO  I=1,3
        UNORM(I) = R(I) * T2(I)
       END DO
       CALL UNTVEC ( UNORM, UNORM )
        DO  I = 1,3
         FF_WATER(I) = -WGAM * WZ * UNORM(I)
        END DO
        CALL CROSS ( R, FF_WATER(1), FF_WATER(4) )
      ELSE
       DO  I = 1,6
        FF_WATER(I) = D_0
       END DO
      END IF
!C
      RETURN
      END
