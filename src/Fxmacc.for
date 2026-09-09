      SUBROUTINE FXMACC                                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes accelerations (from joint forces) for deformable bodies.     
!C    Called by DAUX                                                       
!C    Calls MULPLY, MAT31                                                  
!C
      USE  MODULE_STANDARD,  ONLY:
     &       NSEG, NJNT,                      ! /CONTRL/
     &       NQ2S, RHS,                       ! /DAUX_TEMPVS/
     &       SEG, JNT,                        ! structures
     &       INTEGER_STD, IREAL_HIGH, MXMOD,  ! parameters
     &       I_0, I_1, I_2, I_3               ! parameters
!C
!C    ANG_ACCEL, LIN_ACCEL, SYMMETRY   ! SEG%
!C    JFORCE, PROX_SEG, SLIP_FREE      ! JNT%
!C
      USE  MODULE_FLEXIBLE,  
     &        ONLY:   A11P, A12P, A21P, A22P, AA1P, AA2P,  ! /FXCOEF/ 
     &                PHPI, U1P, U2P, UAP, WPI,            ! /FXCOEF/
     &                RAM, TAM,                            ! /FXSING/
     &                NFBOD, AMA, IBODN, NMOD              ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) 
     &                   I, II, J, L, M, M1, M2, N, NM
!C
      REAL  ( KIND = IREAL_HIGH )  T1, T2_LCL, T3, T4, T5_LCL
      DIMENSION         T1(3), T2_LCL(3), T3(3), T4(3), T5_LCL(MXMOD)   
!C
      IF ( NFBOD .EQ. I_0 )  RETURN
      DO  M=1,NSEG
       DO  II=1,NFBOD
        IF ( IBODN(II) .EQ. M )  THEN
         DO  I=1,NMOD(II)
          AMA(I,II) = UAP(I,II)
         END DO
         IF ( SEG(IBODN(II))%SINGULAR .GE. I_0 )  THEN
          CALL MAT31 ( WPI(1,1,II),  U1P(1,II), SEG(M)%LIN_ACCEL )
          CALL MAT31 ( PHPI(1,1,II), U2P(1,II), SEG(M)%ANG_ACCEL )
         ELSE
          DO  I=1,NMOD(II)
           DO  J=1,3
            AMA(I,II) = AMA(I,II) - TAM(J,I,II) * SEG(M)%LIN_ACCEL(J)
     &                            - RAM(J,I,II) * SEG(M)%ANG_ACCEL(J)
           END DO
          END DO
         END IF
        END IF
       END DO
      END DO
!C
      DO 10 M=1,NJNT
       N = ABS ( JNT(M)%PROX_SEG )
       DO  II=1,NFBOD
        IF ( IBODN(II) .EQ. N )  THEN
         M2 = I_2 * M - I_1
        ELSE IF ( IBODN(II) .EQ. ( M + I_1 ) )  THEN
         M2 = I_2 * M
        END IF
        IF ( ( IBODN(II) .EQ. N ) .OR. 
     &       ( IBODN(II) .EQ. ( M + I_1 ) ) )  THEN
!C
!C........All joints
!C
         M1 = IBODN(II)
         NM = NMOD(II)
         IF ( N .NE. I_0 )  THEN
          IF ( SEG(M1)%SINGULAR .GE. I_0 )  THEN
           CALL MAT31 ( A11P(1,1,M2), JNT(M)%JFORCE, T1     )
           CALL MAT31 ( A21P(1,1,M2), JNT(M)%JFORCE, T2_LCL )
           CALL MAT31 ( WPI(1,1,II),  T1,     T3     )
           CALL MAT31 ( PHPI(1,1,II), T2_LCL, T4     )
           SEG(M1)%LIN_ACCEL = SEG(M1)%LIN_ACCEL - T3
           SEG(M1)%ANG_ACCEL = SEG(M1)%ANG_ACCEL - T4
          END IF
!C
!C........ Modal accelerations
!C
          CALL MULPLY ( AA1P(1,1,M2), JNT(M)%JFORCE, T5_LCL, NM, 
     &                  I_3, I_1, MXMOD, I_3, I_1 )
          DO  I=1,NM
           AMA(I,II) = AMA(I,II) - T5_LCL(I)
          END DO
         END IF
!C
!C........Pin and fixed joints
!C
         IF ( .NOT. JNT(M)%SLIP_FREE )  THEN
          L = NQ2S + NJNT + M
          IF ( SEG(M1)%SINGULAR .GE. I_0 )  THEN
           CALL MAT31 ( A12P(1,1,M2), RHS(1,L), T1 )
           CALL MAT31 ( A22P(1,1,M2), RHS(1,L), T2_LCL )
           CALL MAT31 ( WPI(1,1,II), T1, T3)
           CALL MAT31 ( PHPI(1,1,II), T2_LCL, T4 )
           SEG(M1)%LIN_ACCEL = SEG(M1)%LIN_ACCEL - T3
           SEG(M1)%ANG_ACCEL = SEG(M1)%ANG_ACCEL - T4
          END IF
!C
!C........ Modal accelerations
!C
          CALL MULPLY ( AA2P(1,1,M2), RHS(1,L),
     &      T5_LCL, NM, I_3, I_1, MXMOD, I_3, I_1 )
          DO  I=1,NM
           AMA(I,II) = AMA(I,II) - T5_LCL(I)
          END DO
         END IF
        END IF
       END DO
   10 CONTINUE
!C
      RETURN
      END
