      SUBROUTINE FSETUP                                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Sets up B1A and B2A matrices and revise V1 & V2 for deformable 
!C     bodies. 
!C    Called by DAUX                                                       
!C    Calls TILDE, MAT33, DOT33, DOT31, CROSS                              
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        A11, A22, V1, V2,                      ! /CMATRX/   
     &        NJNT,                                  ! /CONTRL/
     &        SEG, JNT,                              ! structures
     &        INTEGER_STD, IREAL_HIGH,               ! parameters  
     &        LOGICAL_STD, TRUE, FALSE,              ! parameters
     &        D_0, D_1, D_2, I_0, I_1, I_2, I_6      ! parameters
!C
!C    ANG_VEL, DIR_COS                     ! SEG%
!C    PROX_SEG, JTYPE, PROX_HB, DSTL_HB    ! JNT%
!C
      USE  MODULE_FLEXIBLE,  
     &       ONLY:  FMODES,                            ! /FXBODY/
     &              A11F, A22F, B1A, B2A,              ! /FXCOEF/
     &              CN,                                ! /FXJROT/
     &              WNP,                               ! /FXNVEL/
     &              AMV, NODJ, IBODN, NFBOD, NMOD,     ! /FXVAR/
     &              FMODM, DBN                         ! /FXXTRA/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &             I, II, J, J1, J2, JJ, K, KK, L0, NJ 
!C
      REAL  ( KIND = IREAL_HIGH )  BASN, T1, T2_LCL, T3, T4, TT1
      DIMENSION         T1(3), T2_LCL(3), T3(3), T4(3), TT1(3,3)     
!C
      LOGICAL  ( KIND = LOGICAL_STD )  PROXIMAL_JNT
!C
      IF ( ( NFBOD .EQ. I_0 ) .OR. ( NJNT .EQ. I_0 ) ) RETURN
!C
      DO 60 J=1,NJNT
!C
       I = ABS ( JNT(J)%PROX_SEG )
!C
!C.......A11F=A11 & A22F=A22 but converted to appropriate joint form
!C
       DO  K=1,3
        DO  KK=1,3
         A11F(K,KK,2*J-1) =  A11(K,KK,J)
         A11F(K,KK,2*J)   = -A11(K,KK,J)
         A22F(K,KK,2*J-1) =  A22(K,KK,2*J-1)
         A22F(K,KK,2*J)   = -A22(K,KK,2*J)
        END DO
       END DO
       IF ( I .EQ. I_0 )  CYCLE
       NJ = I_0
       DO 65 II=1,NFBOD
        IF (IBODN(II).EQ.I) THEN
         NJ = I_1
         J2 = I_2 * J - I_1
         BASN =     + D_1
        ELSE IF ( IBODN(II) .EQ. ( J + I_1 ) )   THEN
         NJ = I_2
         J2 = I_2 * J
         BASN = -D_1
        END IF
        IF ( ( IBODN(II) .EQ. I ) .OR. 
     &       ( IBODN(II) .EQ. ( J + I_1 ) ) ) THEN
!C
!C.......B1A & V1 for all joints
!C
         J1 = IBODN(II)
         L0 = I_6 * ( NODJ(1,NJ,J) - I_1 )
         DO  K=1,3
          T1(K) = D_0
          DO  JJ=1,NMOD(II)
           T1(K) = T1(K) + FMODES(K+L0,JJ,II) * AMV(JJ,II)
           B1A(K,JJ,J2) = D_0
           DO  KK=1,3
            B1A(K,JJ,J2) = B1A(K,JJ,J2) + BASN * SEG(J1)%DIR_COS(KK,K) *
     &                     FMODES(KK+L0,JJ,II)
           END DO
          END DO
         END DO
         CALL CROSS ( SEG(J1)%ANG_VEL, T1,     T2_LCL )
         CALL DOT31 ( SEG(J1)%DIR_COS, T2_LCL, T1     )
         DO  K=1,3
          V1(K,J) = V1(K,J) - D_2 * BASN * T1(K)
         END DO
!C
!C.......B2A for fixed and pin joints
!C
         IF ( ( JNT(J)%JTYPE .EQ. I_0 ) .OR. 
     &        ( JNT(J)%JTYPE .GT. I_1 ) )   CYCLE
         CALL DOT33 ( SEG(J1)%DIR_COS, DBN(1,1,J2), TT1 )
         IF ( NODJ(2,NJ,J) .EQ. I_0 )  THEN                          
          DO  K=1,3                                                     
           DO  JJ=1,NMOD(II)                                            
            B2A(K,JJ,J2) = D_0                                       
            DO  KK=1,3                                                  
             B2A(K,JJ,J2) = B2A(K,JJ,J2) + BASN * TT1(K,KK)             
     &                                     * FMODES(L0+3+KK,JJ,II)      
            END DO
           END DO
          END DO
         ELSE                                                            
          DO  K=1,3                                                     
           DO  JJ=1,NMOD(II)                                            
            B2A(K,JJ,J2) = D_0                                        
            DO  KK=1,3                                                  
             B2A(K,JJ,J2) = B2A(K,JJ,J2) + BASN * TT1(K,KK) *           
     &                                     FMODM(KK,JJ,J2)              
            END DO
           END DO
          END DO
         END IF                                                          
        END IF
   65  CONTINUE
!C
!C.....V2 for pin and fixed joints
!C
       IF ( ( NJ .EQ. I_0 ) .OR. 
     &      ( JNT(J)%JTYPE .EQ. I_0 ) )  CYCLE
       IF ( ( JNT(J)%JTYPE .GT. I_1 ) .AND. 
     &      ( JNT(J)%JTYPE .LT. I_6 ) )  CYCLE
       DO  K=1,3
        V2(K,J) = D_0
       END DO
       DO 70 II=1,2
        IF ( II .EQ. I_1 ) THEN
         J1 = I
         J2 = I_2 * J - I_1
         PROXIMAL_JNT = TRUE
         BASN = +D_1
        ELSE
         J1 = J + I_1
         J2 = I_2 * J
         PROXIMAL_JNT = FALSE
         BASN = -D_1
        END IF
        IF ( JNT(J)%JTYPE .EQ. I_1 )  THEN
!C
!C......Pin joints               
!C
         IF ( PROXIMAL_JNT )  THEN
          CALL CROSS ( JNT(J)%PROX_HB, SEG(J1)%ANG_VEL, T1     )
          CALL CROSS ( JNT(J)%PROX_HB, WNP(1,J2),       T2_LCL )
         ELSE
          CALL CROSS ( JNT(J)%DSTL_HB, SEG(J1)%ANG_VEL, T1     )
          CALL CROSS ( JNT(J)%DSTL_HB, WNP(1,J2),       T2_LCL )
         END IF
         T3 = T1 + D_2 * T2_LCL
         CALL CROSS ( SEG(J1)%ANG_VEL, T3,       T1     )
         CALL CROSS ( WNP(1,J2),       T2_LCL,   T3     )
         IF ( PROXIMAL_JNT )  THEN
          CALL CROSS ( JNT(J)%PROX_HB,        CN(1,J2), T2_LCL )
          T4 = T1 + T2_LCL + T3
          CALL CROSS ( JNT(J)%PROX_HB,  T4, T3 )
         ELSE
          CALL CROSS ( JNT(J)%DSTL_HB,        CN(1,J2), T2_LCL )
          T4 = T1 + T2_LCL + T3
          CALL CROSS ( JNT(J)%DSTL_HB,  T4, T3 )
         END IF
         CALL DOT31 ( SEG(J1)%DIR_COS, T3, T1 )
        ELSE
!C
!C.......Fixed joints: RHS of acceleration equations
!C
         CALL CROSS ( SEG(J1)%ANG_VEL, WNP(1,J2), T1 )      
         DO  K=1,3
          T3(K) = -T1(K) - CN(K,J2)
         END DO
         CALL DOT31 ( SEG(J1)%DIR_COS, T3, T1 )
        END IF
        DO  K =1,3
         V2(K,J) = V2(K,J) + BASN * T1(K)
        END DO
   70  CONTINUE
   60 CONTINUE
!C
       RETURN
       END
