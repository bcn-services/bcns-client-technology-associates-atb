      SUBROUTINE DAUX11                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Called by Subroutine DAUX to compute                                
!C                                                                        
!C                        -1                  -1                          
!C        (C11) = (B11)(M)  (A11) + (B12)(PHI)  (A21)                     
!C                                                                        
!C                       -1                 -1                            
!C        (R1) = (B11)(M)  (U1) + (B12)(PHI)  (U2) - (V1)                 
!C                                                                        
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       A11, B12, V1,                                 ! /CMATRX/
     &       NJNT,                                         ! /CONTRL/
     &       NQ2S, IJ, IJK, C, RHS,                        ! /DAUX_TEMPVS/
     &       SEG, JNT,                                     ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,         ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_14, TRUE, FALSE    ! parameters
!C
!C    EXT_ANG_ACL, EXT_LIN_ACL, RECIP_MASS, RECIP_PHI, SINGULAR  ! SEG%
!C    PROX_SEG                                                   ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:  NFBOD, IBODN  ! /FXVAR/
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &            I, II, J, K, KJNT, L, M, M1, M2, MB, MM, MQ, N, NB
!C
      REAL  ( KIND = IREAL_HIGH )  CT1, CT2, VT1, VT2, T1, T2 
      DIMENSION  CT1(3,3), CT2(3,3), VT1(3), VT2(3)                     
!C
      LOGICAL ( KIND = LOGICAL_STD )  NFLG, MFLG                        
!C
      CALL ELTIME ( I_1, I_14 )                                               
!C
      DO 20 M=1,NJNT                                                      
       N = ABS ( JNT(M)%PROX_SEG )                                        
       MQ = NQ2S + M                                                      
       IJ = IJ + I_1                                                    
       IJK(MQ,MQ) = IJ                                                    
       IF ( N .LE. I_0 )  THEN                                         
!C                                                                        
!C      If (N < 1)  set  C11(M,M) = I                                     
!C                                                                        
!C                  and  RHS(M)   = V1(M)                                 
!C                                                                        
        DO  I=1,3                                                         
         DO  J=1,3                                                        
          C(I,J,IJ) = D_0                                       
         END DO
         C(I,I,IJ) = D_1                                               
         RHS(I,MQ) = V1(I,M)                                              
        END DO
        IJK(MQ,MQ) = -IJ                                                  
        CYCLE                                                             
       END IF
!C                                                                        
!C     If (N > 0)  set  RHS(M)   = U1(N) - U1(M+1) - V1(M)                
!C                              + B12(M,N)U2(N) + B12(M,M+1)U2(M+1)       
!C                                                                        
!C                  and  C11(M,N) = RW(N) + RW(M+1)                       
!C                              + B12(M,N  )PHI(N  )'A21(N  ,M)           
!C                                + B12(M,M+1)PHI(M+1)'A21(M+1,M)         
!C                                                                        
!C                                                                      
!C     Check to see if N and/or M+1 are deformable                      
!C
       NFLG = FALSE                                                  
       MFLG = FALSE                                                  
       IF ( NFBOD .NE. I_0 )   THEN                               
        DO  II=1,NFBOD                                                   
         IF ( IBODN(II) .EQ. N ) THEN                                    
          NFLG = TRUE                                                 
          NB = II                                                        
         ELSE IF ( IBODN(II) .EQ. ( M + I_1 ) )  THEN                  
          MFLG = TRUE                                                 
          MB = II                                                        
         END IF                                                          
        END DO                                                           
!C
!C....  calculate C11 & R1 if N or M+1 or both are deformable            
!C
        IF ( NFLG ) THEN                                                 
         M2 = I_2 * M - I_1                                              
         CALL FDUX11 ( M2, M2, NB, CT1, VT1 )                            
        END IF                                                           
        IF ( MFLG ) THEN                                                 
         M2 = I_2 * M                                               
         CALL FDUX11 ( M2, M2, MB, CT2, VT2 )                            
        END IF                                                           
        IF ( NFLG .AND. MFLG ) THEN                                      
         DO  I=1,3                                                       
          RHS(I,MQ) = VT1(I) + VT2(I) - V1(I,M)                          
          DO  J=1,3                                                      
           C(I,J,IJ) = CT1(I,J) + CT2(I,J)                               
          END DO
         END DO
        ELSE IF ( NFLG .AND. ( .NOT. MFLG ) ) THEN                       
         DO  I=1,3                                                       
          RHS(I,MQ) = VT1(I) - V1(I,M)                                   
          DO  J=1,3                                                      
           RHS(I,MQ) = RHS(I,MQ) 
     &               + B12(I,J,2*M) * SEG(M+1)%EXT_ANG_ACL(J)      
     &               - A11(I,J,M)   * SEG(M+1)%EXT_LIN_ACL(J)            
           C(I,J,IJ) = CT1(I,J)                                          
           DO  K=1,3                                                     
            C(I,J,IJ) = C(I,J,IJ) + B12(I,K,2*M) *                       
     &                              SEG(M+1)%RECIP_PHI(K) * B12(J,K,2*M)          
           END DO
          END DO
          C(I,I,IJ) = C(I,I,IJ) + SEG(M+1)%RECIP_MASS            
         END DO                                                          
        ELSE IF ( ( .NOT. NFLG ) .AND. MFLG ) THEN                       
         DO  I=1,3                                                       
          RHS(I,MQ) = VT2(I) - V1(I,M)                                   
          DO  J=1,3                                                      
           RHS(I,MQ) = RHS(I,MQ)
     &          + B12(I,J,2*M-1) * SEG(N)%EXT_ANG_ACL(J) 
     &          + A11(I,J,M)     * SEG(N)%EXT_LIN_ACL(J)          
           C(I,J,IJ) = CT2(I,J)                                          
           DO  K=1,3                                                     
            C(I,J,IJ) = C(I,J,IJ) + B12(I,K,2*M-1) *                     
     &                  SEG(N)%RECIP_PHI(K) * B12(J,K,2*M-1)           
           END DO
          END DO
          C(I,I,IJ) = C(I,I,IJ) + SEG(N)%RECIP_MASS   
         END DO                                                          
        ELSE                                                             
         DO  I=1,3                                                          
          T1 = -V1(I,M)                                                       
          DO  J = 1,3                                                       
           T1 = T1 + B12(I,J,2*M-1) * SEG(N)%EXT_ANG_ACL(J) 
     &             + B12(I,J,2*M)   * SEG(M+1)%EXT_ANG_ACL(J) 
     &             + A11(I,J,M) * (   SEG(N)%EXT_LIN_ACL(J) 
     &                              - SEG(M+1)%EXT_LIN_ACL(J) )        
           IF ( J .LT. I )  THEN                                          
            RHS(I,MQ) = T1
            CYCLE
           END IF
           T2 = D_0                                                       
           IF ( J .EQ. I )  T2 = SEG(N)%RECIP_MASS + SEG(M+1)%RECIP_MASS    
           DO  K=1,3                                                        
            T2 = T2 
     &          + B12(I,K,2*M-1) * SEG(N  )%RECIP_PHI(K) 
     &                           * B12(J,K,2*M-1)    
     &          + B12(I,K,2*M  ) * SEG(M+1)%RECIP_PHI(K) 
     &                           * B12(J,K,2*M  )    
           END DO
           C(I,J,IJ) = T2                                                   
           C(J,I,IJ) = T2                                                   
           RHS(I,MQ) = T1                                                   
          END DO 
         END DO
        END IF                                                           
       ELSE
        DO  I=1,3                                                          
         T1 = -V1(I,M)                                                       
         DO  J = 1,3                                                       
          T1 = T1 + B12(I,J,2*M-1) * SEG(N)%EXT_ANG_ACL(J) 
     &            + B12(I,J,2*M)   * SEG(M+1)%EXT_ANG_ACL(J) 
     &            + A11(I,J,M) * (   SEG(N)%EXT_LIN_ACL(J) 
     &                             - SEG(M+1)%EXT_LIN_ACL(J) )        
          IF ( J .LT. I )  THEN                                          
           RHS(I,MQ) = T1
           CYCLE
          END IF
          T2 = D_0                                                       
          IF ( J .EQ. I )  T2 = SEG(N)%RECIP_MASS + SEG(M+1)%RECIP_MASS    
          DO  K=1,3                                                        
           T2 = T2 
     &         + B12(I,K,2*M-1) * SEG(N  )%RECIP_PHI(K) * B12(J,K,2*M-1)    
     &         + B12(I,K,2*M  ) * SEG(M+1)%RECIP_PHI(K) * B12(J,K,2*M  )    
          END DO
          C(I,J,IJ) = T2                                                   
          C(J,I,IJ) = T2                                                   
          RHS(I,MQ) = T1                                                   
         END DO 
        END DO
       END IF
!C
       IF  ( SEG(N)%SINGULAR .NE. I_0 )  CYCLE                             
       L = I_0                                                         
       IF ( N .GT. I_1 )  L = ABS ( JNT(N-1)%PROX_SEG )                    
       IF ( L .NE. I_0 )  THEN                                     
!C                                                                        
!C      If (N > 1) and (L = JNT(N-1) > 0)                                  
!C                                                                         
!C          set  C11(M,N-1) =  -RW(N) + B12(M,N)PHI(N)'A21(N,N-1)          
!C                                                                         
!C                                    T                                    
!C          and  C11(N-1,M) = C(M,N-1)                                     
!C                                                                         
        KJNT = NQ2S + N - I_1                                           
        IJ = IJ + I_1                                                    
        IJK(MQ,KJNT) = IJ                                                  
        IJK(KJNT,MQ) = IJ + I_1                                          
!C                                                                       
!C*...  calculate C11 if N is deformable                                 
!C
        IF ( NFLG ) THEN                                                 
         MM = I_2 * M - I_1                                             
         M2 = I_2 * N - I_2                                      
         CALL FDUX11 ( MM, M2, NB, CT1, VT1 )                            
         CALL FDUX11 ( M2, MM, NB, CT2, VT2 )                            
         DO  I=1,3                                                       
          DO  J=1,3                                                      
           C(I,J,IJ) = CT1(I,J)                                          
           C(I,J,IJ+1) = CT2(I,J)                                        
          END DO
         END DO                                                          
        ELSE                                                           
         DO  I=1,3                                                          
          DO  J=1,3                                                         
          C(I,J,IJ) = D_0                                        
          DO  K=1,3                                                         
           C(I,J,IJ) = C(I,J,IJ) 
     &             + B12(I,K,2*M-1) * SEG(N)%RECIP_PHI(K) 
     &                              * B12(J,K,2*N-2)      
     &             - A11(I,K,M)     * SEG(N)%RECIP_MASS   
     &                              * A11(J,K,N-1)      
          END DO
           C(J,I,IJ+1) = C(I,J,IJ)                                          
          END DO
         END DO
        END IF
        IJ = IJ + I_1                                                    
       END IF
       IF ( M .EQ. NJNT )  CYCLE                                          
       M1 = M + I_1                                                     
       DO  L=M1,NJNT                                                    
        IF ( ABS ( JNT(L)%PROX_SEG ) .NE. N ) CYCLE                      
!C                                                                        
!C      If (L > M) and (JNT(L) = N)                                       
!C                             -1                                       
!C          set  C11(M,L) = MASS(N) + B12(M,N)PHI(N)'A21(N,L)         
!C                                                                        
!C                                  T                                     
!C          and  C11(L,M) = C11(M,L)                                      
!C                                                                        
        KJNT = NQ2S + L                                                   
        IJ = IJ + I_1                                                   
        IJK(MQ,KJNT) = IJ                                                 
        IJK(KJNT,MQ) = IJ + I_1                                         
!C                                                                      
!C....  Calculate C11 if N is deformable                                
!C
        IF ( NFLG ) THEN                                                
         MM = I_2 * M - I_1                                             
         M2 = I_2 * L - I_1                                             
         CALL FDUX11 ( MM, M2, NB, CT1, VT1 )                           
         CALL FDUX11 ( M2, MM, NB, CT2, VT2 )                           
         DO  I=1,3                                                      
          DO  J=1,3                                                     
           C(I,J,IJ) = CT1(I,J)                                         
           C(I,J,IJ+1) = CT2(I,J)                                       
          END DO                                                        
         END DO
         IJ = IJ + I_1                                              
         CYCLE                                                          
        END IF                                                          
!C                                                                      
        DO  I=1,3                                                         
         DO  J=1,3                                                        
          C(I,J,IJ) = D_0                                        
          DO  K=1,3                                                       
           C(I,J,IJ) = C(I,J,IJ) 
     &           + B12(I,K,2*M-1) * SEG(N)%RECIP_PHI(K) * B12(J,K,2*L-1)   
     &           + A11(I,K,M)     * SEG(N)%RECIP_MASS   * A11(J,K,L)     
          END DO
          C(J,I,IJ+1) = C(I,J,IJ)                                         
         END DO
        END DO
        IJ = IJ + I_1                                                   
       END DO                                                           
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, I_14 )                                               
!C
      RETURN                                                              
      END                                                                 
