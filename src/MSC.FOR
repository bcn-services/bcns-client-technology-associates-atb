      SUBROUTINE MSC(ZZ, MPTS, MSC_DIRECTION_LCL)
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, LUAOU, H0, HMIN, HMAX,                  ! PARAMETER
     &       MSC_DIRECTION, MSC_INT_EPS, LUDEBUG, MXHIC,
     &       IREAL_HIGH, MSC_INT_NEAR_ZERO, MSC_INT_MAX_SCALE
!C
      IMPLICIT  NONE
!C
      INTEGER ( KIND = INTEGER_STD ) NBAD, NOK, MPTS, I, NZ, 
     &  MSC_DIRECTION_LCL, NSTP
      REAL ( KIND = IREAL_HIGH ) DMSC(2), TINY, LH, H, HDID, 
     &  HNEXT, X, DYDX(2), Y(2), YSCAL(2), ZZ(MXHIC,2)
      EXTERNAL MSC_DERIVS
      PARAMETER (TINY=1.E-10)
!C    
!C    RUNGE-KUTTA DRIVER WITH ADAPTIVE STEPSIZE CONTROL TO CALCULATE MSC BY
!C    SOLVING ODEINT WITH A TABULAR ACCELERATION INPUT ZZ(MPTS,2). 
!C    FROM TIME POINT ZERO TO TIME POINT MPTS WITH ACCURACY MSC_INT_EPS.
!C    ON OUTPUT NOK AND NBAD ARE THE NUMBER OF GOOD AND BAD (BUT RETRIED AND FIXED) 
!C    STEPS TAKEN. DMSC(2) HAS THE MSC OCCURED AT TIME OF DMSC(1). DERIVS IS THE 
!C    SUBROUTINE FOR CALCULATING THE RIGHT-HAND SIDE DERIVATIVE, WHILE RKQS IS 
!C    THE NAME OF THE STEPPER ROUTINE TO BE USED.
!C
      MSC_DIRECTION = MSC_DIRECTION_LCL
      X = 0
      H = H0
      NOK = 0
      NBAD = 0
      NSTP = 0
!C    NZ TRACKS CURRENT PIONT INDEX OF ZZ
      NZ = 1
      IF (MSC_DIRECTION .EQ. 0) THEN
        LH = 5.78
      ELSE
        LH = 4.718
      END IF
      DO I = 1,2
        DMSC(I) = 0.0
!C      ASSUMING ZERO DEFORMATION AND VELOCITY BETWEEN BRAIN AND SKULL AT TIME ZERO
        Y(I) = 0.0
      END DO
      DO
        CALL MSC_DERIVS(NZ,ZZ,MPTS,X,Y,DYDX)
        DO I = 1,2
!C        SCALING USED TO MONITOR ACCURACY
          YSCAL(I) = ABS(Y(I)) + ABS(H*DYDX(I)) + TINY
          IF ( YSCAL(I) .LT. MSC_INT_NEAR_ZERO ) THEN
!C          HANDLE NEAR ZERO CROSSING SITUATION
            YSCAL(I) = MSC_INT_MAX_SCALE
          END IF
        END DO
        CALL RKQS(Y,DYDX,2,X,H,MSC_INT_EPS,YSCAL,HDID,HNEXT,NZ,ZZ,MPTS,
     &    MSC_DERIVS)
        IF (HDID .EQ. H)THEN
          NOK = NOK + 1
        ELSE
          NBAD = NBAD + 1
        ENDIF
        IF(ABS(Y(1) / LH) .GT. DMSC(2)) THEN 
          DMSC(1) = X
          DMSC(2) = ABS(Y(1) / LH )
        ENDIF
        NSTP = NSTP + 1
        IF (X .GE. ZZ(NZ+1,1)) THEN
          NZ = NZ + 1
        END IF
        IF ((NZ + 1) .GE. MPTS) THEN
!C        To simplify exit, the last time step may not integrated.
          IF ( MSC_DIRECTION .EQ. 0 ) THEN
            WRITE ( LUAOU, 10) DMSC(2), DMSC(1) * 1000.0
   10       FORMAT ( '0', '   Head Maximum Strain Criterion', //,                        
     &               '    Longitudinal MSC = ', F12.9, ' at ',
     &               F10.4, ' msec' )                                           
          ELSE
            WRITE ( LUAOU, 20) DMSC(2), DMSC(1) * 1000.0
   20       FORMAT ( '         Lateral MSC = ', F12.9, ' at ',
     &               F10.4, ' msec', // )                                           
          END IF
          RETURN                                          !Normal Exit                    
        END IF
        IF (HNEXT .LT. HMIN) THEN
          WRITE ( LUAOU, 30 ) HNEXT, HMIN   
   30     FORMAT('STOP 95 Integration step size HNEXT=', 1PD25.15, 
     &           ' is smaller than the minimum HMIN=', 1PD25.15, 
     &           ' in subroutine MSC.') 
          STOP ' STOP 95 in Subroutine MSC '
        END IF
        IF (HNEXT .GT. HMAX) THEN
          HNEXT = HMAX
        END IF
        IF (HNEXT .GT. (ZZ(NZ+2,1) - ZZ(NZ+1,1))) THEN
!C        The step won't exceed the next output interval of acceleration time history
          HNEXT = ZZ(NZ+2,1) - ZZ(NZ+1,1)
        END IF
        H = HNEXT
      END DO
      END