      SUBROUTINE BOYCTR ( BCTR, DELP3 ) 
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C    This routine finds the volume of water displaced by a partially
!C    submerged elipsoid.  This routine also finds the center of mass
!C    of the displaced fluid
!C
      USE  MODULE_STANDARD, ONLY:  
     &        PI,                              ! /CNSNTS/
     &        SEG,                             ! structures
     &        INTEGER_STD, IREAL_HIGH, I_4,    ! parameters 
     &        D_0, D_HALF, D_1, D_2            ! parameters             
!C
!C    SEG%DIR_COS
!C
      USE  MODULE_WATER,  ONLY:
     &       KELT, KSEG_WATER, E11, E12, E22,     ! /TEMPFD/
     &       C1, S1, TSN, BET, BTE, CENTW,        ! /TEMPFD/
     &       WD,                                  ! /WAVEDAT/
     &       AREA, BVL                            ! /WRESLTS/
!C 
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, LDIV, NN
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AA2, BB2, AREA1, BB_LCL, PENET, BET1, DZ,
     &                  AA1, BB1, AREA2, VOL, DVOL, AMR,
     &                  TP, BTQE, BCTR, DELP3, CTR1, CTR2
      DIMENSION   TP(3), BTQE(3), BCTR(3), DELP3(9), CTR1(3), CTR2(3)
!C
!C    TSN  normal to the water plane in segment frame
!C    VOL : the volume submerged in water.
!C    BCTR: the center of mass of the displaced volume. in water frame
!C    DVOL = (AREA1+AREA2)/2*DZ
!C    VOL  = sum of each DVOL
!C    BCTR(1) = (sum of (CTR(1)*DVOL))/VOL 
!C    BCTR(2) = (sum of (CTR(2)*DVOL))/VOL 
!C    BCTR(3) = (sum of (CTR(3)*DVOL))/VOL 
!C
      BVL(KELT) = D_0
      VOL = D_0
      AREA1 = AREA(KELT)
      AA1 = ( E11 * C1 * C1 + D_2 * E12 * S1 * C1 + E22 * S1 * S1 )
      BB1 = ( E11 * S1 * S1 - D_2 * E12 * S1 * C1 + E22 * C1 * C1 )
      BB_LCL = BET / ( BTE * BTE )
      CALL MAT31 ( DELP3, TSN, TP )
!C
!C    Ctr in segment frame
!C
      DO  I=1,3
       CTR1(I) = TP(I) * BB_LCL
       BTQE(I) = D_0
      END DO
      PENET = BET + BTE
      IF ( PENET .GT. D_0 )  THEN
       LDIV = NINT ( PENET / D_HALF )
       IF ( LDIV .LT. I_4 )  LDIV = I_4
       DZ = PENET / REAL ( LDIV, IREAL_HIGH )
       BET1 = BET
       DO  NN = 1,LDIV
        BET1 = BET1 - DZ
        BB_LCL = BET1 / ( BTE * BTE )
        AMR = D_1 - ( BET1 / BTE ) * ( BET1 / BTE )
        IF ( AMR .LE. D_0 ) THEN
         AREA2 = D_0
        ELSE
         DO  I=1,3
          CTR2(I) = TP(I) * BB_LCL
         END DO
         AA2 = AA1 / AMR
         BB2 = BB1 / AMR
         AA2 = SQRT ( D_1 / AA2 )
         BB2 = SQRT ( D_1 / BB2 )
         AREA2 = PI * AA2 * BB2
        END IF
        DVOL = ( AREA1 + AREA2 ) * DZ / D_2
        AREA1 = AREA2
        DO  J=1,3
         BTQE(J) = D_HALF * ( CTR1(J) + CTR2(J) ) * DVOL + BTQE(J)
        END DO   
        VOL = VOL + DVOL
        DO  I=1,3
         CTR1(I) = CTR2(I)
        END DO
        PENET = BET1 + BTE 
       END DO
       DO  I=1,3
        BCTR(I) = BTQE(I)/VOL
       END DO
       BVL(KELT) = VOL
      END IF
!C     
!C    Express bctr in the water frame.
!C
      CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, BCTR, TP )
      CALL MAT31 ( WD, TP, BCTR )
      DO  I=1,3
       BCTR(I) = BCTR(I) + CENTW(I)
      END DO
!C
      RETURN
      END
