      SUBROUTINE SETUP2                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Called by DAUX after contact routines and by UPDATE prior to        
!C    DAUX to set up A2 array and (for NQ # 0) the A13, A23 and V3 arrays.   
!C                                                                       
      USE  MODULE_STANDARD,  ONLY: 
     &       A22, V3,                                      ! /CMATRX/
     &       EPS,                                          ! /CNSNTS/
     &       NJNT, NQ,                                     ! /CONTRL/
     &       A13, A23, B31, B32, HHT, HQQ, KQ1, KQ2, SQQ,  ! /CSTRNT/ 
     &       KQTYPE, RK1, RK2, RQQ, TQQ,                   ! /CSTRNT/
     &       SEG, JNT,                                     ! structures
     &       INTEGER_STD, IREAL_HIGH, FALSE, TRUE,         ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_4, I_5, I_6        ! parameters
!C
!C    ANG_VEL, DIR_COS, LIN_DISP, LIN_VEL             ! SEG%
!C    PROX_SEG, SLIP_FREE, JTYPE, PROX_HB, DSTL_HB    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K, M, N, N1, N2
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BA, FORCE_LCL, HH, RBA, RBAD, RM, RN,
     &                  S2, S3, S4, SQS1,
     &                  T, T1, T2_LCL, T3, T4, T5_LCL, T6, 
     &                  T7, T8, T9, T10, T11, TT1, TT2, VQQ,
     &                  WCRM, WCM, WWCM, WWM,
     &                  WCRN, WCN, WWCN, WWN
!C
      DIMENSION         HH(3), RBA(3), RBAD(3), RM(3), RN(3), 
     &                  T(3), T1(3), T2_LCL(3), T3(3), T4(3),
     &                  T5_LCL(3), T6(3), T7(3), T8(3), T9(3),
     &                  T10(3), T11(3), TT1(3,3), TT2(3,3),
     &                  WCRM(3), WCM(3), WWCM(3), WWM(3),
     &                  WCRN(3), WCN(3), WWCN(3), WWN(3)
!C                                                                        
      REAL ( KIND = IREAL_HIGH ) VECMAG
      EXTERNAL                   VECMAG
!C
      CALL ELTIME ( I_1, 26_INTEGER_STD )                                              
!C                                                                        
!C    Compute A22 array via DHHPIN for DAUX2 routines.                   
!C                                                                       
      IF ( NJNT .NE. I_0 )  THEN                                      
       DO  M=1,NJNT                                                       
        JNT(M)%SLIP_FREE = TRUE                                           
        N = ABS ( JNT(M)%PROX_SEG )                                      
        IF ( N .NE. I_0 )   THEN                                   
         IF ( JNT(M)%JTYPE .NE. I_0 )  THEN                              
          IF ( ( JNT(M)%JTYPE .LT. I_2 ) .OR. 
     &         ( JNT(M)%JTYPE .GT. I_5 ) )  THEN       
           JNT(M)%SLIP_FREE = FALSE                                         
           CALL DHHPIN ( A22(1,1,2*M-1), T, N  , M, JNT(M)%PROX_HB )              
           CALL DHHPIN ( A22(1,1,2*M  ), T, M+1, M, JNT(M)%DSTL_HB )              
          END IF
         END IF
        END IF
       END DO                                                            
      END IF
!C                                                                      
!C    Set up A13,A23 and V3 arrays for DAUX33.                            
!C                                                                       
      IF ( NQ .EQ. I_0 )  THEN                                        
       CALL ELTIME ( I_2, 26_INTEGER_STD )                                              
       RETURN                                                             
      END IF
      DO 70 K=1,NQ                                                       
       IF ( KQTYPE(K) .LT. I_0 )  CYCLE                               
       IF ( KQTYPE(K) .EQ. I_5 )  CYCLE                             
       M = KQ1(K)                                                        
       N = KQ2(K)                                                         
!C                                                                        
!C     For KQTYPE = 1 or 3, set HHT = I                                   
!C                                                                       
       IF ( ( KQTYPE(K) .NE. I_2 ) .AND. 
     &      ( KQTYPE(K) .NE. I_4 ) )  THEN   
        DO  J=1,3                                                          
         DO  I=1,3                                                         
          HHT(I,J,K) = D_0                                              
         END DO
         HHT(J,J,K) = D_1                                                
        END DO
!C                                                                         
!C      For KQTYPE = 6, set HHT= I-TT'                                       
!C                                                                         
        IF ( KQTYPE(K) .EQ. I_6 ) THEN                                   
         DO  J=1,3                                                          
          DO  I=1,3                                                         
           HHT(I,J,K) = HHT(I,J,K) - TQQ(I,K) * TQQ(J,K)                   
          END DO
         END DO
        END IF
       ELSE
        IF ( KQTYPE(K) .EQ. I_2 )  THEN                                  
!C                                                                         
!C       For KQTYPE = 2, compute HH and HHT.                                 
!C                                                                         
         CALL DOT31 ( SEG(M)%DIR_COS, RK1(1,K), T1     )                   
         CALL DOT31 ( SEG(N)%DIR_COS, RK2(1,K), T2_LCL )                   
         HH = SEG(M)%LIN_DISP + T1 - SEG(N)%LIN_DISP - T2_LCL         
         SQS1 = VECMAG ( HH )                                       
         DO  I=1,3                                                         
          HH(I) = HH(I) / SQS1                                             
          IF ( ABS ( HH(I) ) .LE. EPS(12) )   HH(I) = D_0               
         END DO
         CALL DOTT31 ( HH, HH, HHT(1,1,K) )                                
        END IF
!C                                                                        
!C      For KQTYPE = 4, set HHT = HHT                                     
!C                                                                        
        IF ( KQTYPE(K) .EQ. I_4 )  THEN                                 
         CALL DOTT31 ( HQQ(1,K), HQQ(1,K), HHT(1,1,K) )                   
        END IF
       END IF
!C                                                                        
!C      Set A13(2K-1) =  HHT                                              
!C      and A13(2K)   = -HHT                                              
!C                                                                        
       DO  J=1,3                                                          
        DO  I=1,3                                                         
         A13(I,J,2*K-1) =  HHT(I,J,K)                                   
         A13(I,J,2*K  ) = -HHT(I,J,K)                                    
        END DO
       END DO
!C                                                                      
!C     Set A23(2K-1) = (R1X) (D1) A13(2K-1)                              
!C     and A23(2K)   = (R2X) (D2) A13(2K)                                
!C                                                                      
       CALL MAT33 ( SEG(M)%DIR_COS, A13(1,1,2*K-1), TT1 )                
       CALL MAT33 ( SEG(N)%DIR_COS, A13(1,1,2*K  ), TT2 )              
       DO  J=1,3                                                          
        CALL CROSS ( RK1(1,K), TT1(1,J), A23(1,J,2*K-1) )                 
        CALL CROSS ( RK2(1,K), TT2(1,J), A23(1,J,2*K  ) )                 
       END DO
       IF ( KQTYPE(K) .EQ. I_4 )  THEN                               
!C                                                                        
!C      For KQTYPE = 4, set B31(2K-1) =  HTT                              
!C                          B31(2K  ) = -HTT                              
!C                          B32       = (B31)(D')(RX)'                    
!C                                                                        
        CALL DOTT31 ( HQQ(1,K), TQQ(1,K), B31(1,1,2*K-1) )                
        DO  I=1,3                                                         
         DO  J=1,3                                                       
          B31(I,J,2*K) = -B31(I,J,2*K-1)                                  
         END DO
        END DO
        CALL DOTT33 ( SEG(M)%DIR_COS, B31(1,1,2*K-1), B32(1,1,2*K-1) )    
        CALL DOTT33 ( SEG(N)%DIR_COS, B31(1,1,2*K  ), B32(1,1,2*K  ) )    
        DO  J=1,3                                                         
         CALL CROSS ( RK1(1,K), B32(1,J,2*K-1), TT1(1,J) )                
         CALL CROSS ( RK2(1,K), B32(1,J,2*K  ), TT2(1,J) )                
        END DO
        DO  I=1,3                                                         
         DO  J=1,3                                                        
          B32(I,J,2*K-1) = TT1(J,I)                                       
          B32(I,J,2*K  ) = TT2(J,I)                                      
         END DO
        END DO
       ELSE
!C                                                                       
!C      For KQTYPE = 1,2 or 3, set B31 = A13' and B32 = A23'             
!C                                                                        
        DO  I=1,3                                                         
         DO  J=1,3                                                        
          B31(I,J,2*K-1) = A13(J,I,2*K-1)                                
          B31(I,J,2*K  ) = A13(J,I,2*K  )                                 
          B32(I,J,2*K-1) = A23(J,I,2*K-1)                                 
          B32(I,J,2*K  ) = A23(J,I,2*K  )                                
         END DO
        END DO
       END IF                                                             
!C                                                                        
!C     Compute V3 = D2'(W2X(W2XR2)) - D1'(W1X(W1XR1))                    
!C                                                                       
       CALL CROSS ( SEG(M)%ANG_VEL, RK1(1,K), T3     )                   
       CALL CROSS ( SEG(M)%ANG_VEL, T3,       T4     )                    
       CALL DOT31 ( SEG(M)%DIR_COS, T4,       T5_LCL )                 
       CALL CROSS ( SEG(N)%ANG_VEL, RK2(1,K), T6     )                  
       CALL CROSS ( SEG(N)%ANG_VEL, T6,       T7     )                   
       CALL DOT31 ( SEG(N)%DIR_COS, T7,       T8     )                 
       DO  I=1,3                                                          
        V3(I,K) = T8(I) - T5_LCL(I)                                       
       END DO
       IF ( KQTYPE(K) .EQ. I_2 )  THEN                                  
!C                                                                        
!C      Recompute V3 for KQTYPE=2.                                        
!C                                                                        
        CALL DOT31 ( SEG(M)%DIR_COS, T3, T9  )                            
        CALL DOT31 ( SEG(N)%DIR_COS, T6, T10 )                            
        T11 = SEG(M)%LIN_VEL + T9 - SEG(N)%LIN_VEL - T10    
        S2 =  ( VECMAG ( T11 ) )**2
        S3 = HH(1) * V3(1,K) + HH(2) * V3(2,K) + HH(3) * V3(3,K)          
        S4 = S3 - S2 / SQS1                                               
        DO  I=1,3                                                         
         V3(I,K) = S4 * HH(I)                                            
        END DO
       END IF
       IF ( ( KQTYPE(K) .EQ. 3 ) .OR. ( KQTYPE(K) .EQ. 6 ) )  THEN        
!C                                                                       
!C      For KQTYPE=3 or 6, add R dot term from PLELP or SEGSEG to V3.     
!C                                                                       
        DO  I=1,3                                                         
         V3(I,K) = V3(I,K) + RQQ(I,K)                                    
        END DO
        IF ( KQTYPE(K) .NE. I_6 )   CYCLE                           
!C                                                                        
!C      For KQTYPE=6, set V3 = ( I - TT' ) ( V3 + RQQ )                 
!C                                                                       
        VQQ = V3(1,K) * TQQ(1,K) + V3(2,K) * TQQ(2,K)
     &                           + V3(3,K) * TQQ(3,K)                     
        DO  I=1,3                                                       
         V3(I,K) = V3(I,K) - VQQ * TQQ(I,K)                               
        END DO
       END IF
       IF ( KQTYPE(K) .EQ. I_4 )  THEN                               
!C                                                                        
!C      For KQTYPE = 4, add R term from PLELP or SEGSEG to V3.            
!C                                                                        
        S3 = TQQ(1,K) * V3(1,K) + TQQ(2,K) * V3(2,K)
     &                          + TQQ(3,K) * V3(3,K)                      
        S4 = S3 + SQQ(K)                                                  
        DO  I=1,3                                                         
         V3(I,K) = S4 * HQQ(I,K)                                          
        END DO
       END IF
   70 CONTINUE                                                            
!C                                                                        
!C    Special setup for tension elements (KQTYPE = 5).                    
!C                                                                        
      N = I_0                                                         
      DO
       N = N + I_1                                                      
       IF ( N .GE. NQ )  THEN                                              
        CALL ELTIME ( I_2, 26_INTEGER_STD )                                              
        RETURN                                                             
       END IF
       IF ( KQTYPE(N) .NE. I_5 )   CYCLE                           
       DO  I=1,3                                                           
        DO  J=1,3                                                         
         A13(I,J,2*N-1) = D_0                                             
         A13(I,J,2*N  ) = D_0                                            
         A23(I,J,2*N  ) = D_0                                            
         B31(I,J,2*N-1) = D_0                                            
         B31(I,J,2*N  ) = D_0                                            
         A13(I,J,2*N+1) = D_0                                         
         A13(I,J,2*N+2) = D_0                                           
         A23(I,J,2*N+1) = D_0                                        
         B31(I,J,2*N+1) = D_0                                          
         B31(I,J,2*N+2) = D_0                                           
         HHT(I,J,N    ) = D_0                                           
         HHT(I,J,N+1  ) = D_0                                         
        END DO
        A13(I,I,2*N-1) = D_1                                          
        B31(I,I,2*N-1) = RK1(1,N+1)                                        
        B31(I,I,2*N  ) = RK1(3,N+1)                                        
        A13(I,I,2*N+2) = D_1                          
        B31(I,I,2*N+1) = RK1(3,N+1)                                       
        B31(I,I,2*N+2) = RK1(2,N+1)                                        
       END DO
       N1 = KQ1(N)                                                         
       N2 = KQ2(N)                                                        
       DO  K=1,3                                                           
        CALL CROSS ( RK1(1,N), SEG(N1)%DIR_COS(1,K), A23(1,K,2*N-1) )      
        CALL CROSS ( RK2(1,N), SEG(N2)%DIR_COS(1,K), A23(1,K,2*N+2) )     
       END DO
       DO  I=1,3                                                         
        DO  J=1,3                                                         
         B32(I,J,2*N-1) = RK1(1,N+1) * A23(J,I,2*N-1)                     
         B32(I,J,2*N  ) = RK1(3,N+1) * A23(J,I,2*N+2)                      
         B32(I,J,2*N+1) = RK1(3,N+1) * A23(J,I,2*N-1)                      
         B32(I,J,2*N+2) = RK1(2,N+1) * A23(J,I,2*N+2)                      
        END DO
       END DO
       CALL CROSS ( SEG(N1)%ANG_VEL, RK1(1,N), WCRM )                     
       CALL CROSS ( SEG(N2)%ANG_VEL, RK2(1,N), WCRN )                   
       CALL DOT31 ( SEG(N1)%DIR_COS, RK1(1,N), RM )                        
       CALL DOT31 ( SEG(N2)%DIR_COS, RK2(1,N), RN )                        
       CALL DOT31 ( SEG(N1)%DIR_COS, WCRM, WCM )                          
       CALL DOT31 ( SEG(N2)%DIR_COS, WCRN, WCN )                          
       RBAD = SEG(N2)%LIN_VEL + WCN - SEG(N1)%LIN_VEL  - WCM    
       RBA  = SEG(N2)%LIN_DISP + RN - SEG(N1)%LIN_DISP - RM    
       BA = VECMAG ( RBA )                                          
       FORCE_LCL = D_0                                              
       IF  ( BA .GT. RK2(3,N+1) )  THEN
        FORCE_LCL = RK2(1,N+1) * ( D_1 - RK2(3,N+1) / BA )               
       END IF
       DO  I=1,3                                                           
        V3(I,N) = RK2(2,N+1) * RBAD(I) + FORCE_LCL * RBA(I)               
        V3(I,N+1) = -V3(I,N)                                               
       END DO
       CALL CROSS ( SEG(N1)%ANG_VEL, WCRM, WWCM )                     
       CALL CROSS ( SEG(N2)%ANG_VEL, WCRN, WWCN )                     
       CALL DOT31 ( SEG(N1)%DIR_COS, WWCM, WWM )                          
       CALL DOT31 ( SEG(N2)%DIR_COS, WWCN, WWN )                           
       DO  I=1,3                                                           
        V3(I,N  ) = V3(I,N  ) - RK1(1,N+1) * WWM(I)
     &                        - RK1(3,N+1) * WWN(I)                        
        V3(I,N+1) = V3(I,N+1) - RK1(3,N+1) * WWM(I)
     &                        - RK1(2,N+1) * WWN(I)                       
       END DO
       N = N + I_1                                                      
      END DO                                                           
!C
      RETURN                                                             
      END                                                                
