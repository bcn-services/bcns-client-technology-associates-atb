      SUBROUTINE CUTARE ( AREAC, U1_LCL, V1_LCL, DELL, AMR )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       PI,                            ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH,       ! parameters
     &       D_0, D_1, D_2                  ! parameters
!C
      USE  MODULE_WATER,     ONLY:  C1, S1, E11, E12, E22   ! /TEMPFD/
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )   XDY
      EXTERNAL  XDY
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AREAC, AMR, U1_LCL, V1_LCL, DELL, THTA, 
     &                  AA2, BB2
      DIMENSION        U1_LCL(3), V1_LCL(3), DELL(3,3)
!C
      INTENT (  IN )  AMR, DELL, U1_LCL, V1_LCL
      INTENT ( OUT )  AREAC
!C
      E11 = XDY ( U1_LCL, DELL, U1_LCL )
      E12 = XDY ( U1_LCL, DELL, V1_LCL )
      E22 = XDY ( V1_LCL, DELL, V1_LCL )
      IF ( E12 .EQ. D_0 ) THEN
       THTA = D_0
      ELSE
       THTA = ATAN2 ( D_2 * E12, ( E11 - E22 ) )
       THTA = THTA / D_2
      END IF
      S1 = SIN ( THTA )
      C1 = COS ( THTA )
      AA2 = ( E11 * C1 * C1 + D_2 * E12 * S1 * C1 + E22 * S1 * S1 )
     &                            / AMR
      BB2 = ( E11 * S1 * S1 - D_2 * E12 * S1 * C1 + E22 * C1 * C1 )
     &                            / AMR
      AA2 = SQRT ( D_1 / AA2 )
      BB2 = SQRT ( D_1 / BB2 )
      AREAC = PI * AA2 * BB2
!C
      RETURN
      END
