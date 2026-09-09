      SUBROUTINE ELARE3 ( SEMI, RPH_LCL, RNX, FRC, TQE_LCL, FUNC )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Integrates force and torque components due to buoyancy effects
!C    over area of an ellipsoid with semi-axes SEMI(1,2,3) = A, B & C 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        PI, TWOPI,                       ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,         ! parameters
     &        D_0, I_0, I_1, I_2, I_12, I_100  ! parameters
!C
      USE  MODULE_WATER,     ONLY:  F1, FF_WATER, FL      ! /TEMPFD/
!C
      IMPLICIT  NONE
!C
!C    Passed variables.
!C
      REAL  ( KIND = IREAL_HIGH ) SEMI, RPH_LCL, RNX, FRC, TQE_LCL
      DIMENSION   FRC(3), TQE_LCL(3), SEMI(3)
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K, NN_LCL, NP
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A1SS, A2, A2SS, B2, BP, BP2, C2, CB2, CH, CH2, 
     &                  CP, CP2, CS, CS2, DA, DH, DS, DSH, DPHI, 
     &                  DPSI, PHI_LCL, PSI, PSI1, PSI2, SS, SS2,
     &                  SH, XX, ZZERO
!C
      REAL  ( KIND = IREAL_HIGH )  SIMPSN
      EXTERNAL          FUNC, SIMPSN
!C
      ZZERO = D_0                                                      
      NN_LCL = NINT ( SEMI(1) * RNX )
      NP = NINT ( PI * ( SEMI(2) + SEMI(3) ) * RPH_LCL )
      IF ( NN_LCL .GT. I_100 )  NN_LCL = I_100
      IF ( NN_LCL .LT. I_12 )   NN_LCL = I_12
      IF ( NP .GT. I_100)   NP = I_100
      IF ( NP .LT. I_12 )   NP = I_12
      IF ( MOD ( NN_LCL, I_2 ) .EQ. I_0 )  NN_LCL = NN_LCL - I_1
      IF ( MOD ( NP, I_2 ) .EQ. I_0 )    NP = NP - I_1
      ZZERO = D_0
      IF ( SEMI(1) .GT. D_0 )  THEN
       A2 = SEMI(1) * SEMI(1)
       B2 = SEMI(2) * SEMI(2)
       C2 = SEMI(3) * SEMI(3)
       CB2 = C2 - B2
       PSI1 = ZZERO
       PSI2 = PI
       DPSI = PI / ( NN_LCL - I_1 )
       DPHI = TWOPI / ( NP - I_1 )
       PSI  = ZZERO
       DO I = 1,NN_LCL
        CS       = COS ( PSI )
        SS       = SIN ( PSI )
        CS2      = CS * CS
        SS2      = SS * SS
        A1SS     = ABS ( SS )
        XX       = SEMI(1) * CS
        BP       = SEMI(2) * A1SS
        CP       = SEMI(3) * A1SS
        BP2      = BP * BP
        CP2      = CP * CP
        A2SS     = A2 * SS2
        PHI_LCL  = D_0
!C
        DO  J = 1,NP                                          
         SH  = SIN ( PHI_LCL )
         CH  = COS ( PHI_LCL )
         CH2 = CH * CH
         DS  = A2SS + CS2 * ( ( B2 - C2 ) * CH2 + C2 ) 
         DH  = ( CP2 - BP2 ) * CH2 + BP2
         DSH = CB2 * SS * CS * SH * CH
         DA  = DS * DH - DSH * DSH
         IF ( DA .LT. 0.)  DA = ZZERO
         DA  = SQRT ( DA )
         CALL FUNC ( XX, BP, CP, PHI_LCL )                         
         DO  K=1,6
          F1(J,K) = FF_WATER(K) * DA
         END DO
         PHI_LCL = PHI_LCL + DPHI                                         
        END DO
        DO  K=1,6
         FL(I,K) = SIMPSN ( F1(1,K), NP, ZZERO, TWOPI )
        END DO
        PSI = PSI + DPSI
       END DO
       DO  K=1,3
        FRC(K)     = SIMPSN ( FL(1,K),   NN_LCL, PSI1, PSI2 )
        TQE_LCL(K) = SIMPSN ( FL(1,K+3), NN_LCL, PSI1, PSI2 )
       END DO
      ELSE
       FRC = D_0
       TQE_LCL = D_0
      END IF
!C
      RETURN                                                           
      END                                                              
