      SUBROUTINE WATER_ELLIP_FORCE ( WN, DELP1, DELP2, DELP3, DELP4 ) 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine computes the force on the ellipsoids associated
!C     with the water force option.  It calls WATER_DRAG_CHK to find 
!C     the frictional drag and lift forces and calls WATER_ADDED_MASS to 
!C     find the added-mass and damping forces.
!C
      USE  MODULE_STANDARD, ONLY:
     &       EPS, PI,                     ! /CNSNTS/
     &       SEG,                         ! structures
     &       INTEGER_STD, IREAL_HIGH,     ! parameters
     &       D_0, D_1, D_3, D_4, I_0      ! parameters
!C
!C    DIR_COS, DRC_PHI, EXT_ANG_ACL, EXT_LIN_ACL, LIN_DISP,   ! SEG%
!C    ROT_PHI                                                 ! SEG%
!C
      USE  MODULE_WATER,  ONLY:
     &       CENTW, KELT, KSEG_WATER, T2,        ! /TEMPFD/
     &       RNX, RPH,                           ! /WATGRD/
     &       CADDM, COED, COEL,                  ! /WATINF1/
     &       NWAVES, WD, WOFSET,                 ! /WAVEDAT/
     &       NSEQN,                              ! /WFACOP/
     &       ADDM, AREA, BUOY, BVL, DRAG, WEXF   ! /WRSELTS/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  J
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ADMSUM, AMR, BCTR, DELP1, DELP2, DELP3, DELP4, 
     &                  FRC, RM, RMU, T1, TFRC, TM, TMP1_LCL, TMP2, 
     &                  TQE_LCL, TSEG, WN
      DIMENSION         BCTR(3), DELP1(3,3), DELP2(6), DELP3(9), 
     &                  DELP4(9), FRC(3), RM(3), T1(3), TM(3), 
     &                  TMP1_LCL(3), TMP2(3), TQE_LCL(3), TSEG(3), WN(3)
!C
      EXTERNAL         PFDBOY, PFDFRC, PFDWXC
!C
      REAL  ( KIND = IREAL_HIGH )  VECMAG
      EXTERNAL                     VECMAG
!C
!C       TSEG = normal to water surface in segment coords (from water-to air)
!C       tm    = A-1.TSEG
!C       mu    = sqrt(TSEG.A-1TSEG)
!C       rm    = -A-1.TSEG/mu
!C       tmp2  = lm + rm
!C
!C       penet = -TSEG.(lm + rm) - wn.(Xseg - Xwater)
!C
!C
!C    CENTW  =  Center of ellipsoid in water frame
!C
!C    T1     = normal to water surface in ellipsoid system
!C            
      CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, WN, TSEG )
      CALL MAT31 ( DELP3, TSEG, TM )
      RMU = DOT_PRODUCT ( TSEG, TM )
      RMU = SQRT ( RMU )
      T1   =  SEG(KSEG_WATER)%LIN_DISP - WOFSET
      RM   = -TM / RMU
      DO  J=1,3
       TMP2(J) =  DELP2(J+3) + RM(J) 
      END DO
!C
      CALL DOT31 ( SEG(KSEG_WATER)%DIR_COS, DELP2(4), TMP1_LCL )
      TMP2 = T1 + TMP1_LCL
      CALL MAT31 ( WD, TMP2, CENTW )
      DO  J=1,3
       T2(J) = D_1 / ( DELP2(J) * DELP2(J) )
      END DO
      BCTR = CENTW
!C
      IF ( NSEQN .GT. I_0 ) THEN
       DO  J=1,3
        BUOY(J,KELT)   = D_0
        WEXF(J,KELT)   = D_0
        DRAG(J,KELT)   = D_0
        ADDM(J,KELT)   = D_0
        WEXF(J+3,KELT) = D_0
        DRAG(J+3,KELT) = D_0
        BUOY(J+3,KELT) = D_0
       END DO
      END IF
      CALL WBAREA ( DELP3, DELP4, AMR )
!C      
      DO 
       IF ( AREA(KELT) .EQ. D_0 ) THEN
        BVL(KELT) = D_0
        DO  J=1,3
         FRC(J) = D_0
         TQE_LCL(J) = D_0
        END DO
       ELSE
        IF ( AREA(KELT) .LT. D_0 )  THEN
         BVL(KELT) = D_4 / D_3 * PI * DELP2(1) * DELP2(2) * DELP2(3)
        ELSE IF ( AREA(KELT) .GT. D_0 )  THEN
         CALL BOYCTR ( BCTR, DELP3 )
        END IF
        IF ( NSEQN .GT. I_0 ) THEN
         CALL ELARE3 ( DELP2, RPH, RNX, FRC, TQE_LCL, PFDBOY )
         TFRC = VECMAG ( FRC )
         IF ( TFRC .LT. EPS(1) )  THEN
          AREA(KELT) = D_0
          CYCLE
         END IF
         CALL UPDATE_PFD ( KSEG_WATER,FRC, TQE_LCL, DELP1, DELP2(4) )
         DO  J = 1,3
          BUOY(J,KELT)   = FRC(J)
          BUOY(J+3,KELT) = TQE_LCL(J)
         END DO
         IF ( SEG(KSEG_WATER)%ROT_PHI ) THEN
          CALL DOT31 ( SEG(KSEG_WATER)%DRC_PHI, TQE_LCL,BUOY(4,KELT) )
         END IF
         IF ( NWAVES .GT. I_0 ) THEN
          CALL ELARE3 ( DELP2, RPH, RNX, FRC, TQE_LCL, PFDWXC ) 
          CALL UPDATE_PFD ( KSEG_WATER, FRC, TQE_LCL, DELP1, DELP2(4) )
          DO  J = 1,3
           WEXF(J,KELT)   = FRC(J)
           WEXF(J+3,KELT) = TQE_LCL(J)
          END DO
          IF ( SEG(KSEG_WATER)%ROT_PHI ) THEN
            CALL DOT31 ( SEG(KSEG_WATER)%DRC_PHI, TQE_LCL, 
     &                   WEXF(4,KELT) )
          END IF
         END IF
        ELSE
         CALL ELARE3 ( DELP2, RPH, RNX, FRC, TQE_LCL, PFDFRC )
         CALL UPDATE_PFD ( KSEG_WATER, FRC, TQE_LCL, DELP1, DELP2(4) )
        END IF
       END IF
       EXIT
      END DO
!C
!C    Drag force calculations
!C
      IF ( ( AREA(KELT) .NE. D_0 ) .AND. 
     &     ( COED(KELT) .NE. D_0 ) ) THEN
       CALL WATER_DRAG_CHK ( BCTR, DELP2, DELP3, DELP4 )                 
!C
!C     Apply drag forces to segment
!C
       TMP2 = BCTR - CENTW
       CALL DOT31 ( WD, TMP2, TMP1_LCL )
       CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, TMP1_LCL, TMP2 )
!C
!C     TMP2 = BCTR - CENTW in segment frame
!C
       DO  J = 1,3
        SEG(KSEG_WATER)%EXT_LIN_ACL(J) = 
     &               SEG(KSEG_WATER)%EXT_LIN_ACL(J) + DRAG(J,KELT)
        TMP2(J)    = DELP2(3+J) + TMP2(J)
       END DO
!C
!C     TMP2 = distance from c.g. to centroid of displaced volume
!C            in segment frame
!C
       CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, DRAG(1,KELT), TMP1_LCL )
       CALL CROSS ( TMP2,                    TMP1_LCL,     TQE_LCL )
       SEG(KSEG_WATER)%EXT_ANG_ACL = SEG(KSEG_WATER)%EXT_ANG_ACL 
     &                               + TQE_LCL
!C     
!C     Apply Lift forces to segment.
!C      
       IF ( COEL(KELT) .NE. D_0 ) THEN
        DO  J = 1,3
         SEG(KSEG_WATER)%EXT_LIN_ACL(J) = 
     &             SEG(KSEG_WATER)%EXT_LIN_ACL(J) + DRAG(J+3,KELT)
        END DO
        CALL MAT31 ( SEG(KSEG_WATER)%DIR_COS, DRAG(4,KELT), TMP1_LCL )
        CALL CROSS ( TMP2,                    TMP1_LCL,     TQE_LCL )
        SEG(KSEG_WATER)%EXT_ANG_ACL = SEG(KSEG_WATER)%EXT_ANG_ACL 
     &                                + TQE_LCL
       END IF
      END IF       
      IF ( AREA(KELT) .NE. D_0 ) THEN
!C
!C     Added-mass and damping calculations.
!C
       ADMSUM = CADDM(1,KELT) + CADDM(2,KELT) + CADDM(3,KELT)
       IF ( ADMSUM .GT. D_0 )  THEN
        CALL WATER_ADDED_MASS ( DELP2 )
       END IF
      END IF
!C
      RETURN
      END 
