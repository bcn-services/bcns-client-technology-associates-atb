      SUBROUTINE PFDWXC ( XC, BP, CP, PHI_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD, ONLY: 
     &        INTEGER_STD, IREAL_HIGH, D_0       ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &       CENTW, FF_WATER, KELT, T2, T5, WDSE,   ! /TEMPFD/
     &       NWAVES                                 ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BP, CP, PHI_LCL, R, UNORM, TMP1_LCL, 
     &                  WPHI, WZ, XC
      DIMENSION         R(3), UNORM(3), TMP1_LCL(3)               
!C
      REAL  ( KIND = IREAL_HIGH )   WAVE_HEIGHT, WEXPHI
      EXTERNAL          WAVE_HEIGHT, WEXPHI
!C
      R(1) = XC
      R(2) = BP * COS ( PHI_LCL )
      R(3) = CP * SIN ( PHI_LCL )
!C
      FF_WATER = D_0
      CALL MAT31 ( WDSE(1,1,KELT), R, T5 )
      T5 = T5 + CENTW
      WZ = T5(3) + WAVE_HEIGHT ( T5(1), T5(2) )
      IF ( WZ .GE. D_0 ) THEN
       DO  J = 1,3
        UNORM(J) = R(J) * T2(J)
       END DO
       CALL UNTVEC ( UNORM, UNORM )
       CALL CROSS ( R, UNORM, TMP1_LCL ) 
       DO  I = 1,NWAVES
        WPHI = -WEXPHI(I)
        DO  J = 1,3
         FF_WATER(J) = WPHI * UNORM(J)
        END DO
        CALL CROSS ( R, FF_WATER(1), FF_WATER(4) )
       END DO
      END IF
!C
      RETURN
      END
