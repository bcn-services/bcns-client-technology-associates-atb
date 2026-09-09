      FUNCTION ELAREA ( XMIN, XMAX, A, B_LCL, C_LCL, PHI1, PHI2, NPHI,
     &                  NX, FUNC )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    Evalutes function over area of an ellipse with semi-axes A, B & C 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH,    ! parameters
     &        I_0, I_1, I_2, D_0          ! parameters
!C
      IMPLICIT  NONE                                                    
!C
!C    Passed arguments.
!C
      INTEGER  ( KIND = INTEGER_STD )  NPHI, NX
!C
      REAL  ( KIND = IREAL_HIGH )  ELAREA  
      REAL  ( KIND = IREAL_HIGH ) 
     &              XMIN, XMAX, A, B_LCL, C_LCL, PHI1, PHI2
!C
      REAL  ( KIND = IREAL_HIGH )  FUNC
      EXTERNAL FUNC                                                     
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, NN_LCL, NP
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A1SS, AREA, A2, B2, BP, BP2, C2, CH, CP, 
     &                  CP2, CS, CS2, DA, DH, DPHI, DPSI, DS, DSH, 
     &                  FF_LCL, PHI_LCL, PSI, PSI1, PSI2, SH, SS, 
     &                  SS2, X1, X2, XX  
      REAL  ( KIND = IREAL_HIGH )   FL_LCL, F_LCL
      DIMENSION                     FL_LCL(100), F_LCL(100)
!C
      REAL  ( KIND = IREAL_HIGH )  ELAR_PARM1
      PARAMETER  ( ELAR_PARM1 = 0.9999999E0_IREAL_HIGH )
!C
      REAL  ( KIND = IREAL_HIGH )  SIMPSN
      EXTERNAL  SIMPSN
!C
      NN_LCL = NX
      IF ( MOD ( NN_LCL, I_2 ) .EQ. I_0 )  NN_LCL = NN_LCL - I_1
      NP = NPHI
      IF ( MOD ( NP, I_2 ) .EQ. I_0 )  NP = NP - I_1
      IF ( A .GT. D_0 ) THEN
       A2 = A * A
       B2 = B_LCL * B_LCL
       C2 = C_LCL * C_LCL
       X1 = XMIN / A
       X2 = XMAX / A
       IF ( ABS ( X1 ) .GT. D_0 )  X1 = SIGN ( ELAR_PARM1, X1 )
       IF ( ABS ( X2 ) .GT. D_0 )  X2 = SIGN ( ELAR_PARM1, X2 )
       PSI1 = ACOS ( X1 )
       PSI2 = ACOS ( X2 )
!C
!C     IF ( X1 .LT. 0.0 ) PSI1 = -PSI1
!C     IF ( X2 .LT. 0.0 ) PSI2 = -PSI2
!C
       DPSI = ( PSI2 - PSI1 ) / ( NN_LCL - I_1 )
       DPHI = ( PHI2 - PHI1 ) / ( NP - I_1 )
       PSI = PSI1
       XX = XMIN
       DO  I = 1,NN_LCL
        CS      = COS ( PSI )
        SS      = SIN ( PSI )
        CS2     = CS * CS
        SS2     = SS * SS
        A1SS     = ABS ( SS )
        XX      = A * CS
        BP      = B_LCL * A1SS
        CP      = C_LCL * A1SS
        BP2     = BP * BP
        CP2     = CP * CP
        PHI_LCL = PHI1
        DO  J = 1,NP                                                    
         FF_LCL = FUNC ( XX, BP, CP, PHI_LCL )                          
         SH = SIN ( PHI_LCL )
         CH = COS ( PHI_LCL )
         DS = A2 * SS2 + CS2 * ( B2 * CH * CH + C2 * SH * SH ) 
         DH = BP2 * SH * SH + CP2 * CH * CH
         DSH = ( C2 - B2 ) * SS * CS * SH * CH
         DA = DS * DH - DSH * DSH
         IF ( DA .LT. D_0 )  DA = D_0
         DA = SQRT ( DA )
         F_LCL(J) = FF_LCL * DA
         PHI_LCL = PHI_LCL + DPHI                                       
        END DO                                                          
        FL_LCL(I) = SIMPSN ( F_LCL, NP, PHI1, PHI2 )
        PSI = PSI + DPSI
       END DO
       AREA = SIMPSN ( FL_LCL, NN_LCL, PSI1, PSI2 )
      ELSE
       AREA = D_0
      END IF
      ELAREA = AREA                                                     
!C
      RETURN                                                            
      END                                                               
