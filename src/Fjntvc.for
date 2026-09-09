      SUBROUTINE FJNTVC ( I0 )                                          
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    Revises joint pos. and axes SR, HB & HT for deformable bodies         
!C    Computes joint linear modal vel. in iner. ref. "ASAD" for Subr. CHAIN 
!C    Computes joint rot. modal disp. & vel. "RSA" & "RSAD"                 
!C    Computes joint nodal angular vel. "WNP" for Subs. VISPR & DRIFT       
!C    Called by MAIN program and DAUX                                       
!C    Calls TILDE, MAT33, MAT31, DOT31, DOT33                               
!C
      USE  MODULE_STANDARD,  ONLY:
     &       EPS,                                          ! /CNSNTS/
     &       NJNT,                                         ! /CONTRL/
     &       HT,                                           ! /DESCRP/
     &       SEG, JNT,                                     ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, MXMOD,  ! parameters
     &       TRUE, FALSE,                                  ! parameters
     &       I_0, I_1, I_2, I_3, I_6, D_0, D_1, D_180      ! parameters
!C
!C    ANG_VEL, DIR_COS, DRC_PHI, ROT_PHI, SINGULAR                ! SEG%
!C    PROX_SEG, DSTL_LOC, PROX_LOC, JTYPE, PROX_HB, DSTL_HB       ! JNT%
!C
      USE  MODULE_FLEXIBLE,  
     &        ONLY:  FIK, QNOD, FMODES,                        ! /FXBODY/
     &               PURTQ,                                    ! /FXFRC/
     &               DNP, ROTJ, ROTVJ, CN,                     ! /FXJROT/
     &               ASAD, WNP,                                ! /FXNVEL/
     &               NFBOD, IBODN, NNOD, NODJ, NMOD, AMP, AMV, ! /FXVAR/
     &               HB0, HT0, DBN, FMODM,                     ! /FXXTRA/
     &               AMPOLD, FMODO, ROTOLD                     ! /OLDDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, I0, IDIR, II, II0, J, J2, JJ, K, K3, KK, 
     &           L0, M, NJ 
      DIMENSION  IDIR(3)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  T1, T2_LCL, T3, TT1, TT2, TT3, RSA,
     &                  RSAD, BN, TMP1_LCL, TMP2, DEG
      DIMENSION T1(3), T2_LCL(3), T3(3), TT1(3,3), TT2(3,3), TT3(3,3),     
     &          RSA(3), RSAD(3), BN(3,3), TMP1_LCL(3,MXMOD,MXMOD),
     &          TMP2(3,MXMOD)                                           
!C
      LOGICAL  ( KIND = LOGICAL_STD )  PROXIMAL_JNT
!C
      IF ( NFBOD .EQ. I_0 )  RETURN
      DEG = D_180 / ACOS ( -D_1 )
!C
!C....I0 = 0 : initial conditions, I0 # 0 normal call
!C
      IF ( I0 .EQ. I_0 ) THEN
!C
!C.....Save undeformed joint principal axes
!C
       DO  J=1,NJNT
        DO  I=1,3
         HB0(I,2*J-1) = JNT(J)%PROX_HB(I)
         HB0(I,2*J)   = JNT(J)%DSTL_HB(I)
         DO  K=1,3
          HT0(I,K,2*J-1) = HT(I,K,2*J-1)
          HT0(I,K,2*J) = HT(I,K,2*J)
          DNP(I,K,2*J-1) = D_0
          DNP(I,I,2*J-1) = D_1
          DNP(I,K,2*J) = D_0
          DNP(I,I,2*J) = D_1
         END DO
        END DO
       END DO
!C
!C... .There is no need for principal axes for deformable segments
!C
       II0 = I_0
       DO  I=1,NFBOD
        SEG(IBODN(I))%ROT_PHI = FALSE
       END DO
      ELSE
!C
!C.....Initialize nodal forces and applied pure torques for new iteration
!C
       DO  I=1,NFBOD
        DO  J=1,3
         PURTQ(J,I) = D_0
         DO  K=1,NNOD(I)
          FIK(J,K,I) = D_0
         END DO
        END DO
       END DO
      END IF
!C
      DO 20 J=1,NJNT 
       K = ABS ( JNT(J)%PROX_SEG )
       IF ( K .EQ. I_0 )  CYCLE
       IF ( SEG(J+1)%SINGULAR .LT. I_0 ) CYCLE
       DO 30 I=1,NFBOD
        II = IBODN(I)
        IF ( II .EQ. K ) THEN
         NJ = I_1
         J2 = I_2 * J - I_1
         PROXIMAL_JNT = TRUE
        ELSE IF ( II .EQ. ( J + I_1 ) )  THEN
         NJ = I_2
         J2 = I_2 * J
         PROXIMAL_JNT = FALSE
        END IF
        IF ( ( II .EQ. K ) .OR. ( II .EQ. ( J + I_1 ) ) )  THEN                                                              
         L0 = I_6 * ( NODJ(1,NJ,J) - I_1 )                          
         DO  KK=1,3                                                     
          IF ( NJ .EQ. I_1 )  THEN
           JNT(J)%PROX_LOC(KK) = QNOD(KK,NODJ(1,NJ,J),I)
          ELSE
           JNT(J)%DSTL_LOC(KK) = QNOD(KK,NODJ(1,NJ,J),I)
          END IF
          T1(KK) = D_0
          IDIR(KK) = KK
          RSA(KK) = D_0
          RSAD(KK) = D_0
          K3 = KK + I_3 + L0
          DO  JJ=1,NMOD(I)
           IF ( NJ .EQ. I_1 )  THEN
            JNT(J)%PROX_LOC(KK) = JNT(J)%PROX_LOC(KK) +
     &                             FMODES(L0+KK,JJ,I) * AMP(JJ,I)
           ELSE
            JNT(J)%DSTL_LOC(KK) = JNT(J)%DSTL_LOC(KK) +
     &                             FMODES(L0+KK,JJ,I) * AMP(JJ,I)
           END IF
           T1(KK)    = T1(KK)    + FMODES(L0+KK,JJ,I) * AMV(JJ,I)
           RSA(KK)   = RSA(KK)   + FMODES(K3,JJ,I)    * AMP(JJ,I)
           RSAD(KK)  = RSAD(KK)  + FMODES(K3,JJ,I)    * AMV(JJ,I)
          END DO
         END DO
         CALL DOT31 ( SEG(II)%DIR_COS, T1, ASAD(1,J2) )
!C
!C       If no rotational dof from fea model, compute joint rotation     
!C       due to deformation by Subroutine JNTROT                        
!C
         IF ( NODJ(2,NJ,J) .NE. I_0 ) THEN                             
          IF ( I0 .EQ. I_0 ) THEN                                    
           CALL JNTROT ( NJ, J, I, I_0 )                              
          ELSE                                                           
           CALL JNTROT ( NJ, J, I, I_1 )                              
          END IF                                                         
          DO  M = 1,3                                                    
           RSA(M)  = ROTJ(4-M,J2)                                        
           RSAD(M) = ROTVJ(4-M,J2)                                      
          END DO                                                        
          IF ( I0 .NE. I_0 )  THEN                                   
           DO  M=1,3                                                    
            DO  JJ=1,NMOD(I)                                            
             IF ( ABS ( AMP(JJ,I) - AMPOLD(JJ,I) ) .GT. EPS(5) )        
     &          FMODM(M,JJ,J2) = ( ROTJ(4-M,J2) - ROTOLD(4-M,J2) )      
     &              / ( AMP(JJ,I) - AMPOLD(JJ,I) )                      
            END DO
           END DO                                                       
           II0 = II0 + I_1                                           
          ELSE                                                           
           DO  M=1,3                                                    
            DO  JJ=1,NMOD(I)                                            
             FMODM(M,JJ,J2) = D_0                               
            END DO
           END DO
          END IF                                                         
         END IF                                                          
!C                                                                        
         DO  KK=1,3                                         
          T2_LCL(KK) = RSA(KK) * DEG                             
         END DO
         CALL DRCYPR ( DNP(1,1,J2), T2_LCL,      IDIR       ) 
         IF  ( PROXIMAL_JNT )  THEN
          CALL DOT31  ( DNP(1,1,J2), HB0(1,J2),   JNT(J)%PROX_HB   )
         ELSE
          CALL DOT31  ( DNP(1,1,J2), HB0(1,J2),   JNT(J)%DSTL_HB   )
         END IF
         CALL DOT33  ( DNP(1,1,J2), HT0(1,1,J2), HT(1,1,J2) )
         IF ( I0 .EQ. I_0 )  CYCLE                               
!C                                                                      
!C    Compute, WNP(), the joint angular velocity due to deformation      
!C    FEA model, rotation is RSA(1), RSA(2), RSA(3)                       
!C
         IF ( NODJ(2,NJ,J) .EQ. I_0 )  THEN                             
          BN(1,1) =  COS ( RSA(2) ) * COS ( RSA(3) )
          BN(1,2) =  SIN ( RSA(3) )
          BN(1,3) =  D_0
          BN(2,1) = -COS ( RSA(2) ) * SIN ( RSA(3) )
          BN(2,2) =  COS ( RSA(3) )
          BN(2,3) =  D_0
          BN(3,1) =  SIN ( RSA(2) )
          BN(3,2) =  D_0
          BN(3,3) =  D_1
          IF ( ( JNT(J)%JTYPE .LT. I_0 ) .OR. 
     &         ( JNT(J)%JTYPE .EQ. I_1 ) )  THEN
           T1(1) = - SIN ( RSA(2) ) * COS ( RSA(3) ) * RSAD(1) * RSAD(2)
     &             - COS ( RSA(2) ) * SIN ( RSA(3) ) * RSAD(1) * RSAD(3) 
     &             + COS ( RSA(3) )                  * RSAD(2) * RSAD(3)
           T1(2) =   SIN ( RSA(2) ) * SIN ( RSA(3) ) * RSAD(1) * RSAD(2)
     &             - COS ( RSA(2) ) * COS ( RSA(3) ) * RSAD(1) * RSAD(3)
     &             - SIN ( RSA(3) )                  * RSAD(2) * RSAD(3)
           T1(3) =   COS ( RSA(2) )                  * RSAD(1) * RSAD(2)
          END IF 
!C
!C       Use DNP() from Sub. 'JNTROT', the rotation is RSA(3), RSA(2), 
!C        RSA(1) 
!C
         ELSE                                                           
          BN(1,1) =   D_1                                              
          BN(1,2) =   D_0                                             
          BN(1,3) = - SIN ( RSA(2) )                                     
          BN(2,1) =   D_0                                              
          BN(2,2) =   COS ( RSA(3) )                                     
          BN(2,3) =   SIN ( RSA(3) ) * COS ( RSA(2) )                    
          BN(3,1) =   D_0                                              
          BN(3,2) = - SIN ( RSA(3) )                                     
          BN(3,3) =   COS ( RSA(3) ) * COS ( RSA(2) )                    
          IF ( ( JNT(J)%JTYPE .LT. I_0 ) .OR. 
     &         ( JNT(J)%JTYPE .EQ. I_1 ) )  THEN       
           T1(1) = - COS ( RSA(2) ) * RSAD(2) * RSAD(3)                  
           T1(2) = - SIN ( RSA(1) ) * RSAD(1) * RSAD(2)                  
     &             + COS ( RSA(1) ) * COS ( RSA(2) ) * RSAD(1) * RSAD(3) 
     &             - SIN ( RSA(2) ) * SIN ( RSA(1) ) * RSAD(2) * RSAD(3) 
           T1(3) = - COS ( RSA(1) )                  * RSAD(1) * RSAD(2) 
     &             - SIN ( RSA(1) ) * COS ( RSA(2) ) * RSAD(1) * RSAD(3) 
     &             - SIN ( RSA(2) ) * COS ( RSA(1) ) * RSAD(2) * RSAD(3) 
           IF ( II0 .GT. I_1 )  THEN                                 
            DO  M=1,3                                                   
             DO  JJ=1,NMOD(I)                                           
              DO  KK=1,NMOD(I)                                          
               IF ( ABS ( AMP(KK,I) - AMPOLD(KK,I) ) .GT. EPS(5) )  THEN 
                TMP1_LCL(M,JJ,KK) = ( FMODM(M,JJ,J2) - FMODO(M,JJ,J2) ) 
     &                                / ( AMP(KK,I) - AMPOLD(KK,I) )    
               ELSE                                                     
                TMP1_LCL(M,JJ,KK) = D_0                             
               END IF                                                   
              END DO                                                    
              TMP2(M,JJ) = D_0                                     
              DO  KK=1,NMOD(I)                                          
               TMP2(M,JJ) = TMP2(M,JJ) +                                
     &                      TMP1_LCL(M,JJ,KK) * AMV(KK,I)               
              END DO                                                    
             END DO                                                     
             DO  JJ=1,NMOD(I)                                           
              T1(M) = T1(M) + TMP2(M,JJ) * AMV(JJ,I)                    
             END DO
            END DO                                                      
           END IF                                                       
          END IF                                                         
         END IF                                                          
!C                                                                       
         CALL DOT33 ( DNP(1,1,J2), BN, TT3 )
         CALL MAT31 ( TT3, RSAD, WNP(1,J2) )
         CALL DOT31 ( DNP(1,1,J2), T1, CN(1,J2) )
!C
!C....Deformation parameters to set up B2A for fixed and pin joints
!C
         IF ( JNT(J)%JTYPE .EQ. I_1 )  THEN
          IF ( PROXIMAL_JNT )  THEN
           CALL TILDE ( JNT(J)%PROX_HB, TT1 )
          ELSE
           CALL TILDE ( JNT(J)%DSTL_HB, TT1 )
          END IF
          CALL MAT33 ( TT1, TT3, TT2 )
          CALL MAT33 ( TT1, TT2, TT3 )
          DO  KK=1,3
           DO  JJ=1,3
            DBN(KK,JJ,J2) = -TT3(KK,JJ)
           END DO
          END DO
         ELSE
          DO  KK=1,3
           DO  JJ=1,3
            DBN(KK,JJ,J2) = TT3(KK,JJ)
           END DO
          END DO
         END IF
        END IF
   30  CONTINUE
   20 CONTINUE
!C
!C....Fixed joints: orientation and angular velocity corrections
!C
      IF ( I0 .EQ. I_0 )  RETURN
      DO  J=1,NJNT
       IF ( JNT(J)%JTYPE .GE. I_0 )  CYCLE
       I = ABS ( JNT(J)%PROX_SEG )
       IF ( .NOT. SEG(I)%ROT_PHI )  THEN
        CALL MAT33 ( DNP(1,1,2*J-1), SEG(I)%DIR_COS, TT1 )
       ELSE
        CALL DOT33 ( SEG(I)%DRC_PHI, SEG(I)%DIR_COS, TT2 )
        CALL MAT33 ( DNP(1,1,2*J-1), TT2,      TT1 )
       END IF
       IF  ( .NOT. SEG(J+1)%ROT_PHI )  THEN
        CALL DOT33 ( DNP(1,1,2*J),  TT1, SEG(J+1)%DIR_COS )
       ELSE
        CALL DOT33 ( DNP(1,1,2*J),  TT1, TT2        )
        CALL MAT33 ( SEG(J+1)%DRC_PHI, TT2, SEG(J+1)%DIR_COS )
       END IF
       CALL DOT31 ( SEG(I)%DIR_COS,   SEG(I)%ANG_VEL, T3     )
       CALL MAT31 ( SEG(J+1)%DIR_COS, T3,             T1     )
       CALL DOT31 ( SEG(I)%DIR_COS,   WNP(1,2*J-1),   T3     )
       CALL MAT31 ( SEG(J+1)%DIR_COS, T3,             T2_LCL )
       DO  K=1,3
        SEG(J+1)%ANG_VEL(K) = T1(K) + T2_LCL(K) - WNP(K,2*J)
       END DO
      END DO
!C
      RETURN
      END
