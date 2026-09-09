      SUBROUTINE FXMASS                                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    Computes the elements of the deformable equations of motion.           
!C    Symmetric mass matrix (MTT,MTR,MTA), (MRT,MRR,MRA), (MAT,MAR,MAA).     
!C    RHS vectors: translational = UT, rotational = UR, and MODAL = UA.      
!C    Called by DAUX.                                                        
!C    Calls INVERS, MULPLY, TILDE, TRNPOS,                                  
!C        MAT33, MAT31, DOT33, DOT31, CROSS                               
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       B12,                                     ! /CMATRX/
     &       EPS, GRAVTY,                             ! /CNSNTS/
     &       NJNT,                                    ! /CONTRL/
     &       SEG, JNT,                                ! structures
     &       INTEGER_STD, IREAL_HIGH, MXMOD,          ! parameters
     &       D_0, D_1, D_2,                           ! parameters
     &       I_0, I_1, I_2, I_3, I_5, I_6             ! parameters
!C
!C    ANG_VEL, DIR_COS, PHI, SINGULAR      ! SEG%
!C    JTORQUE, PROX_SEG, JTYPE             ! JNT%
!C
      USE  MODULE_FLEXIBLE,  
     &        ONLY:  FIK, FMODES,  WNOD,  QNOD,            ! /FXBODY/
     &               A11F, A11P, A12P, A21P, A22F, A22P,   ! /FXCOEF/
     &               AA1P, AA2P, B1A, B2A, PHPI, U1P,      ! /FXCOEF/
     &               U2P, UAP, WPI,                        ! /FXCOEF/
     &               PURTQ,                                ! /FXFRC/
     &               TAM, RAM,                             ! /FXSING/
     &               NNOD, NMOD, RDMP, AMP, RSTF,          ! /FXVAR/
     &               SAIM, NFBOD, IBODN, AMV, TTM          ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  
     &              I, II, IORD, J, J2, JJ, K, KK, L, M
      DIMENSION  IORD(3)
!C
      REAL  ( KIND = IREAL_HIGH )  FACT
      REAL  ( KIND = IREAL_HIGH ) 
     &                  RHO, ROT, ROM, WWMR, WP, PHP, UT, RRM, ATM, 
     &                  ARM, D11, D12, D22, D11I, D22I, D12T, TM3,
     &                  TM4, TM5, T1, T2_LCL, T3, T4, TT1, TT2, TT3,
     &                  TT4, TMT1, TRM, UR, TMT2, AA1, UA, AA2
      DIMENSION   RHO(3), ROT(3,3), ROM(3,3), WWMR(3), WP(3,3),
     &            PHP(3,3), UT(3), RRM(3,3), ATM(MXMOD,3),
     &            ARM(MXMOD,3), D11(3,3), D12(3,3), D22(3,3),
     &            D11I(3,3), D22I(3,3), D12T(3,3), TM3(3,3),
     &            TM4(3,3), TM5(3,3), T1(3), T2_LCL(3), T3(3), T4(3),
     &            TT1(3,3), TT2(3,3), TT3(3,3), TT4(3,3),
     &            TMT1(MXMOD,3),TRM(3,3),UR(3), TMT2(MXMOD,3),
     &            AA1(MXMOD,3), UA(MXMOD), AA2(MXMOD,3)      
!C
      IF ( NFBOD .EQ. I_0 )  RETURN

      DO 10 I=1,NFBOD
       II = IBODN(I)
!C
!C.....Initialize
!C
       DO  J=1,3
        WWMR(J) = D_0
        UT(J) = D_0
        UR(J) = PURTQ(J,I)
        DO  JJ=1,3
         ROM(J,JJ) = D_0
         RRM(J,JJ) = D_0
        END DO
        DO  JJ=1,NMOD(I)
         RAM(J,JJ,I) = D_0
        END DO
!C
!C......Add force due to gravity to nodal contact forces
!C
        DO  K=1,NNOD(I)
         FIK(J,K,I) = FIK(J,K,I) + WNOD(K,I) * GRAVTY(J)
        END DO
       END DO
!C
!C.....Force from strain energy
!C
       DO  J=1,NMOD(I) 
        UA(J) = -RSTF(J,I) * AMP(J,I) - RDMP(J,I) * AMV(J,I)
       END DO
       DO 20 K=1,NNOD(I)
        L = I_6 * ( K - I_1 )
        DO  J=1,3
         RHO(J) = QNOD(J,K,I)
         T1(J) = D_0
         DO  JJ=1,3
          T1(J) = T1(J) + SEG(II)%DIR_COS(J,JJ) * FIK(JJ,K,I)
         END DO
         DO  JJ=1,NMOD(I)
          RHO(J) = RHO(J) + FMODES(L+J,JJ,I) * AMP(JJ,I)
         END DO
        END DO
        CALL TILDE ( RHO, ROT )
        CALL CROSS ( SEG(II)%ANG_VEL, RHO, T3     )
        CALL CROSS ( SEG(II)%ANG_VEL, T3,  T2_LCL )
        DO  J=1,3
         T4(J) = D_0
         DO  JJ=1,NMOD(I)
          T4(J) = T4(J) + FMODES(L+J,JJ,I) * AMV(JJ,I)
         END DO
        END DO
        CALL CROSS ( SEG(II)%ANG_VEL, T4, T3 )
        DO  J=1,3
         WWMR(J) = WWMR(J) + WNOD(K,I) * T2_LCL(J)
         UT(J) = UT(J) + FIK(J,K,I)
         DO  JJ=1,3
          UR(J) = UR(J) + ROT(J,JJ) *
     &            ( T1(JJ) - WNOD(K,I) * ( T2_LCL(JJ) + 2 * T3(JJ) ) )
         END DO
        END DO
        DO  J=1,NMOD(I)
         DO  JJ=1,3
          UA(J) = UA(J) + FMODES(L+JJ,J,I) *
     &            ( T1(JJ) - WNOD(K,I) * ( T2_LCL(JJ) + 2 * T3(JJ) ) )
         END DO
        END DO
        DO  J=1,3
         DO  JJ=1,3
           ROM(J,JJ) = ROM(J,JJ) - WNOD(K,I) * ROT(J,JJ)
          DO  KK=1,3
           RRM(J,JJ) = RRM(J,JJ) - WNOD(K,I) * ROT(J,KK) * ROT(KK,JJ)
          END DO
         END DO
        END DO
        DO  J=1,3
         DO  JJ=1,NMOD(I)
          DO  KK=1,3
           RAM(J,JJ,I) = RAM(J,JJ,I) +
     &                   WNOD(K,I) * ROT(J,KK) * FMODES(L+KK,JJ,I)
          END DO
         END DO
        END DO
   20  CONTINUE
!C
       CALL MULPLY ( SAIM(1,1,I), AMV(1,I), T1, I_3, NMOD(I), 
     &               I_1, I_3, MXMOD, I_1 )
       CALL CROSS ( SEG(II)%ANG_VEL, T1, T2_LCL )
       DO  J=1,3
        IF ( RRM(J,J) .LT. ( EPS(1) * SEG(II)%PHI(J) ) )  THEN
         RRM(J,J) = RRM(J,J) + SEG(II)%PHI(J)
        END IF
        DO  JJ=1,3
         UT(J) = UT(J) - SEG(II)%DIR_COS(JJ,J) * 
     &                   ( WWMR(JJ) + D_2 * T2_LCL(JJ) )
        END DO
       END DO
       CALL DOT33 ( SEG(II)%DIR_COS, ROM, TRM )
       DO  J=1,NMOD(I)
        CALL DOT31 ( SEG(II)%DIR_COS, SAIM(1,J,I), TAM(1,J,I) )
       END DO
!C
!C.....Add joint torques to rotational eqs.
!C
       DO  J=1,NJNT
        M = ABS ( JNT(J)%PROX_SEG )
        IF ( II .EQ. M )               FACT =  D_1
        IF ( II .EQ. ( J + I_1 ) )   FACT = -D_1
        IF ( ( II .EQ. M ) .OR. ( II .EQ. ( J + I_1 ) ) )  THEN
         DO  L=1,3
          DO  K=1,3
           UR(L) = UR(L) + 
     &             FACT * SEG(II)%DIR_COS(L,K) * JNT(J)%JTORQUE(K)
          END DO
         END DO
        END IF
       END DO
!C
       DO  L=1,NMOD(I)
        UAP(L,I) = UA(L)
       END DO
       IF ( SEG(II)%SINGULAR .GE. I_0 )   THEN
!C
!C.. .. D11, D12, D21, D22
!C
        CALL TRNPOS ( TAM(1,1,I), ATM, I_3,   
     &                NMOD(I), I_3, MXMOD )
        CALL MULPLY ( TAM(1,1,I), ATM, D11, I_3, 
     &                NMOD(I), I_3, I_3, MXMOD, I_3 )
        CALL TRNPOS ( RAM(1,1,I), ARM, I_3,   
     &                NMOD(I), I_3, MXMOD )
        CALL MULPLY ( TAM(1,1,I), ARM, D12, I_3, NMOD(I), 
     &                I_3, I_3, MXMOD, I_3 )
        CALL MULPLY ( RAM(1,1,I), ARM, D22, I_3, NMOD(I), 
     &                I_3, I_3, MXMOD, I_3 )
        DO  J=1,3
         DO  K=1,3
          D11(J,K) = -D11(J,K)
          D12(J,K) = TRM(J,K) - D12(J,K)
          D22(J,K) = RRM(J,K) - D22(J,K)
         END DO
         D11(J,J) = TTM(I) + D11(J,J)
        END DO
!C
!C..... M'**-1, PHI'**-1
!C
        CALL INVERS ( D22, D22I, TM5,IORD, I_3, I_3 )
        CALL MAT33 (  D12, D22I, TM3 )
        CALL TRNPOS ( D12, D12T, I_3, I_3, I_3, I_3 )
        CALL MAT33 (  TM3, D12T, WP )
        CALL INVERS ( D11, D11I, TM5,IORD, I_3, I_3 )
        CALL MAT33 (  D12T,D11I, TM4 )
        CALL MAT33 (  TM4, D12,  PHP )
        DO  J=1,3
         DO  K=1,3
          WP(J,K)  = D11(J,K) - WP(J,K)
          PHP(J,K) = D22(J,K) - PHP(J,K)
         END DO
        END DO
        CALL INVERS ( WP,  WPI(1,1,I), TM5, IORD, I_3, I_3 )
        CALL INVERS ( PHP, PHPI(1,1,I),TM5, IORD, I_3, I_3 )
!C
!C..... U1', U2', UA'
!C
        CALL MULPLY ( RAM(1,1,I), UA, T1, I_3, NMOD(I), 
     &                I_1, I_3, MXMOD, I_1 )
        CALL MULPLY ( TAM(1,1,I), UA, T3, I_3, NMOD(I), 
     &                I_1, I_3, MXMOD, I_1 )
        T2_LCL = UR - T1
        T4 = UT - T3
        CALL MAT31 ( TM3, T2_LCL, T1 )
        CALL MAT31 ( TM4, T4,     T3 )
        DO  L=1,3
         U1P(L,I) = T4(L) - T1(L)
         U2P(L,I) = T2_LCL(L) - T3(L)
        END DO
        CALL MULPLY ( ATM, WPI(1,1,I),  TMT1, NMOD(I), 
     &                I_3, I_3, MXMOD, I_3, I_3 )
        CALL MULPLY ( ARM, PHPI(1,1,I), TMT2, NMOD(I), 
     &                I_3, I_3, MXMOD, I_3, I_3 )
        DO  L=1,NMOD(I)
         DO  K=1,3
          UAP(L,I) = UAP(L,I) - TMT1(L,K) * U1P(K,I)
     &                        - TMT2(L,K) * U2P(K,I)
         END DO
        END DO
       END IF
       DO 50 J=1,NJNT
        M = ABS ( JNT(J)%PROX_SEG )
        IF ( II .EQ. M )  THEN
         J2 = I_2 * J - I_1
        ELSE IF ( II .EQ. ( J + I_1 ) )   THEN
         J2 = I_2 * J
        END IF
!C
        IF ( ( II .EQ. M ) .OR. ( II .EQ. ( J + I_1 ) ) )  THEN
         CALL TRNPOS ( B1A(1,1,J2), AA1, I_3, NMOD(I), 
     &                 I_3, MXMOD )
         DO  L=1,NMOD(I)
          DO  K=1,3
           AA1P(L,K,J2) = AA1(L,K)
          END DO
         END DO
         IF ( SEG(II)%SINGULAR .GE. I_0 )  THEN
!C
!C....... A11', A21', AA1' For all joints
!C
          CALL MULPLY ( RAM(1,1,I), AA1, TT1, I_3, NMOD(I), 
     &                  I_3, I_3, MXMOD, I_3 )
          CALL MULPLY ( TAM(1,1,I), AA1, TT3, 3, NMOD(I), 
     &                  I_3, I_3, MXMOD, I_3 )
          DO  L=1,3
           DO  K=1,3
            TT2(L,K) = B12(K,L,J2) - TT1(L,K)
            TT4(L,K) = A11F(L,K,J2) - TT3(L,K)
           END DO
          END DO
          CALL MAT33 ( TM3, TT2, TT1 )
          CALL MAT33 ( TM4, TT4, TT3 )
          DO  L=1,3
           DO  K=1,3
            A11P(L,K,J2) = TT4(L,K) - TT1(L,K)
            A21P(L,K,J2) = TT2(L,K) - TT3(L,K)
           END DO
          END DO
          DO  L=1,NMOD(I)
           DO  K=1,3
            DO  KK=1,3
             AA1P(L,K,J2) = AA1P(L,K,J2) - TMT1(L,KK)  * 
     &                      A11P(KK,K,J2) - TMT2(L,KK) * A21P(KK,K,J2)
            END DO
           END DO
          END DO
         END IF
!C
!C....... A12', A22', AA2' for pin joints
!C
         IF ( JNT(J)%JTYPE .EQ. I_0 )   CYCLE
         IF ( ( JNT(J)%JTYPE .GE. I_2 ) .AND. 
     &        ( JNT(J)%JTYPE .LE. I_5 ) )  CYCLE
         CALL TRNPOS ( B2A(1,1,J2), AA2, I_3, NMOD(I), 
     &                 I_3, MXMOD )
         DO  L=1,NMOD(I)
          DO  K=1,3
           AA2P(L,K,J2) = AA2(L,K)
          END DO
         END DO
         IF ( SEG(II)%SINGULAR .GE. I_0 )  THEN
          CALL MULPLY ( RAM(1,1,I), AA2, TT1, I_3, NMOD(I), 
     &                  I_3, I_3, MXMOD, I_3 )
          CALL MULPLY ( TAM(1,1,I), AA2, TT3, I_3, NMOD(I), 
     &                  I_3, I_3, MXMOD, I_3 )
          DO  L=1,3
           DO  K=1,3
            TT2(L,K) = A22F(L,K,J2) - TT1(L,K)
            TT4(L,K) = - TT3(L,K)
           END DO
          END DO
          CALL MAT33 (TM3,TT2,TT1)
          CALL MAT33 (TM4,TT4,TT3)
          DO  L=1,3
           DO  K=1,3
            A12P(L,K,J2) = TT4(L,K) - TT1(L,K)
            A22P(L,K,J2) = TT2(L,K) - TT3(L,K)
           END DO
          END DO
          DO  L=1,NMOD(I)
           DO  K=1,3
            DO  KK=1,3
             AA2P(L,K,J2) = AA2P(L,K,J2)  - TMT1(L,KK) *
     &                      A12P(KK,K,J2) - TMT2(L,KK) * A22P(KK,K,J2)
            END DO
           END DO
          END DO
         END IF
        END IF
!C
   50  CONTINUE

   10 CONTINUE
!C
      RETURN
      END
