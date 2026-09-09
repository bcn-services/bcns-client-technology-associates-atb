      SUBROUTINE DAUX33                                                   
!C
!C                                                   Rev V.3  12/15/2002  
!C    Called by Subroutine DAUX to compute                                
!C                                                                        
!C                    -1                  -1                              
!C    (C33) = (B31)(M)  (A13) + (B32)(PHI)  (A23) - (B35)                 
!C                                                                        
!C                    -1                  -1                              
!C    (R3)  = (B31)(M)  (U1)  + (B32)(PHI)  (U2)  - (V3)                  
!C                                                                        
!C
      USE  MODULE_STANDARD,  
     &     ONLY:  V3,                                        ! /CMATRX/
     &            NQ,                                        ! /CONTRL/
     &            KQTYPE, KQ1, KQ2, B31, B32, HHT, A13, A23, ! /CSTRNT/
     &            NQ2S, RHS, IJ, IJK, C,                     ! /DAUX_TEMPVS/
     &            SEG,                                       ! structures
     &            INTEGER_STD, IREAL_HIGH, D_0, D_1,         ! parameters 
     &            I_0, I_1, I_2, I_4                         ! parameters
!C
!C    EXT_ANG_ACL, EXT_LIN_ACL, RECIP_MASS, RECIP_PHI, SINGULAR   ! SEG%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              I, J, JJ, K, K1, K2, M, MNS, N, N1, NNS
!C
      REAL  ( KIND = IREAL_HIGH )   SUM, TUM
!C
      CALL ELTIME ( I_1, 19_INTEGER_STD )                                 
!C
      DO 20 N=1,NQ                                                        
       IF ( KQTYPE(N) .LT. I_0 ) CYCLE                                  
       K1 = KQ1(N)                                                         
       K2 = KQ2(N)                                                         
       NNS = NQ2S - NQ + N                                                 
!C                                                                         
!C                        -1                         -1                    
!C     RHS(N) = B31(N,K1)M  (K1)U1(K1) + B32(N,K1)PHI  (K1)U2(K1)          
!C                        -1                         -1                    
!C            + B31(N,K2)M  (K2)U1(K2) + B32(N,K2)PHI  (K2)U2(K2)          
!C                                                                         
!C            - V3(N)                                                      
!C                                                                         
       DO  I=1,3                                                           
        SUM = D_0                                                     
        DO  K=1,3                                                          
         SUM = SUM + B31(I,K,2*N-1) * SEG(K1)%EXT_LIN_ACL(K) 
     &             + B32(I,K,2*N-1) * SEG(K1)%EXT_ANG_ACL(K)    
     &             + B31(I,K,2*N  ) * SEG(K2)%EXT_LIN_ACL(K) 
     &             + B32(I,K,2*N  ) * SEG(K2)%EXT_ANG_ACL(K)    
        END DO
        RHS(I,NNS) = SUM - V3(I,N)                                         
       END DO
!C                                                                         
!C                          -1                            -1               
!C     C33(N,N) = B31(N,K1)M  (K1)A13(K1,N) + B32(N,K1)PHI  (K1)A23(K1,N)  
!C                          -1                            -1               
!C              + B31(N,K2)M  (K2)A13(K2,N) + B32(N,K2)PHI  (K2)A23(K2,N)  
!C                                                                         
!C              - B35(N,N)                                                 
!C                                                                         
       IJ = IJ + I_1                                                
       IJK(NNS,NNS) = IJ                                                   
       IF  ( ( KQTYPE(N) .EQ. I_2 )  .OR.                               
     &       ( KQTYPE(N) .EQ. I_4 )  )  THEN                            
!C                                                                         
!C     For KQTYPE = 2 OR 4, set C33(N,N) = B*I                             
!C     where B = sum of diagonal elements of                               
!C             -1                  -1                                      
!C     (B31)(M)  (A13) + (B32)(PHI)  (A23)                                 
!C                                                                         
        SUM = D_0                                                   
        DO  I=1,3                                                          
         DO  K=1,3                                                         
          SUM = SUM 
     &      + B31(I,K,2*N-1) * SEG(  K1)%RECIP_MASS   * A13(K,I,2*N-1)      
     &      + B31(I,K,2*N  ) * SEG(  K2)%RECIP_MASS   * A13(K,I,2*N  )      
     &      + B32(I,K,2*N-1) * SEG(K1)%RECIP_PHI(K)   * A23(K,I,2*N-1)     
     &      + B32(I,K,2*N  ) * SEG(K2)%RECIP_PHI(K)   * A23(K,I,2*N  )      
         END DO
        END DO
        DO  I=1,3                                                          
         DO  J=1,3                                                         
          C(I,J,IJ) = D_0                                              
         END DO
         C(I,I,IJ) = SUM                                                   
        END DO
       ELSE
        DO  I=1,3                                                          
         DO  J=1,3                                                         
          SUM = -HHT(I,J,N)                                                
          IF ( I .EQ. J )  SUM = D_1 + SUM                              
          DO  K=1,3                                                        
           SUM = SUM
     &      + B31(I,K,2*N-1) *  SEG(K1)%RECIP_MASS   * A13(K,J,2*N-1)   
     &      + B31(I,K,2*N  ) *  SEG(K2)%RECIP_MASS   * A13(K,J,2*N  )    
     &      + B32(I,K,2*N-1) *  SEG(K1)%RECIP_PHI(K) * A23(K,J,2*N-1)    
     &      + B32(I,K,2*N  ) *  SEG(K2)%RECIP_PHI(K) * A23(K,J,2*N  )    
          END DO
          C(I,J,IJ) = SUM                                                  
         END DO
        END DO
       END IF                                                              
!C
       IF ( N .EQ. NQ )  CYCLE                                          
       N1 = N + I_1                                                     
!C
       DO 30 M=N1,NQ                                                       
        IF ( KQTYPE(M) .LT. I_0 )   CYCLE                            
        MNS = NQ2S - NQ + M                                                 
        IF ( SEG(K1)%SINGULAR .EQ. I_0 )  THEN                         
         IF ( K1 .EQ. KQ1(M) )   THEN                                 
          IF ( IJK(MNS,NNS) .EQ. I_0 )  THEN                         
!C                                                                            
!C         For any M > N such that K1(N) = K1(M)                                 
!C                                                                             
!C                                         -1                                  
!C         C33(N,M) = C(N,M) + B31(N,K1)  M  (K1)A13(K1,M)                     
!C                                         -1                                  
!C                           + B32(N,K1)PHI  (K1)A23(K1,M)                     
!C                                                                          
!C                                         -1                                  
!C         C33(M,N) = C(M,N) + B31(M,K1)  M  (K1)A13(K1,N)                     
!C                                         -1                                  
!C                           + B32(M,K1)PHI  (K1)A23(K1,N)                     
!C                                                                         
           IJ = IJ + I_1                                                     
           IJK(MNS,NNS) = IJ                                                   
           IJK(NNS,MNS) = IJ + I_1                                          
           DO  J=1,3                                                           
            DO  I=1,3                                                          
             C(I,J,IJ  ) = D_0                                             
             C(I,J,IJ+1) = D_0                                             
            END DO
           END DO
           IJ = IJ + I_1                                                  
          END IF
!C
          JJ = IJK(MNS,NNS)                                                   
          DO  I=1,3                                                           
           DO  J=1,3                                                          
            SUM = C(I,J,JJ)                                                   
            TUM = C(I,J,JJ+1)                                                 
            DO  K=1,3                                                         
             SUM = SUM 
     &        + B31(I,K,2*N-1) * SEG(K1)%RECIP_MASS   * A13(K,J,2*M-1)   
     &        + B32(I,K,2*N-1) * SEG(K1)%RECIP_PHI(K) * A23(K,J,2*M-1)   
              TUM = TUM 
     &        + B31(I,K,2*M-1) * SEG(K1)%RECIP_MASS   * A13(K,J,2*N-1)      
     &        + B32(I,K,2*M-1) * SEG(K1)%RECIP_PHI(K) * A23(K,J,2*N-1)      
            END DO
           END DO
          END DO
          C(I,J,JJ  ) = SUM                                                  
          C(I,J,JJ+1) = TUM                                                   
         END IF
!C
         IF ( K1 .EQ. KQ2(M) )   THEN                               
          IF ( IJK(MNS,NNS) .EQ. I_0 )   THEN                         
!C                                                                            
!C         For any M>N such that K1(N) = K2(M)                                 
!C                                                                             
!C                                         -1                                  
!C         C33(N,M) = C(N,M) + B31(N,K1)  M  (K1)A13(K2,M)                     
!C                                         -1                                  
!C                           + B32(N,K1)PHI  (K1)A23(K2,M)                     
!C                                                                          
!C                                         -1                                  
!C         C33(M,N) = C(M,N) + B31(M,K2)  M  (K1)A13(K1,N)                     
!C                                        -1                                  
!C                           + B32(M,K2)PHI  (K1)A23(K1,N)                     
!C                                                                         
           IJ = IJ + I_1                                                    
           IJK(MNS,NNS) = IJ                                                   
           IJK(NNS,MNS) = IJ + I_1                                         
           DO  J=1,3                                                           
            DO  I=1,3                                                          
             C(I,J,IJ  ) = D_0                                            
             C(I,J,IJ+1) = D_0                                              
            END DO
           END DO
           IJ = IJ + I_1                                                     
          END IF
          JJ = IJK(MNS,NNS)                                                   
          DO  I=1,3                                                           
           DO  J=1,3                                                          
            SUM = C(I,J,JJ)                                                   
            TUM = C(I,J,JJ+1)                                                 
            DO  K=1,3                                                         
             SUM = SUM 
     &       + B31(I,K,2*N-1) * SEG(K1)%RECIP_MASS   * A13(K,J,2*M  )    
     &       + B32(I,K,2*N-1) * SEG(K1)%RECIP_PHI(K) * A23(K,J,2*M  )   
             TUM = TUM 
     &       + B31(I,K,2*M  ) * SEG(K1)%RECIP_MASS   * A13(K,J,2*N-1)   
     &       + B32(I,K,2*M  ) * SEG(K1)%RECIP_PHI(K) * A23(K,J,2*N-1)   
            END DO
            C(I,J,JJ  ) = SUM                                                 
            C(I,J,JJ+1) = TUM                                                 
           END DO
          END DO
         END IF
        END IF
        IF  ( SEG(K2)%SINGULAR .NE. I_0 )  CYCLE                     
!C
        IF  ( K2 .EQ. KQ1(M) )   THEN                              
         IF  ( IJK(MNS,NNS) .EQ. I_0 )  THEN                             
!C                                                                           
!C        For any M>N such that K2(N) = K1(M)                                
!C                                                                           
!C                                        -1                                 
!C        C33(N,M) = C(N,M) + B31(N,K2)  M  (K2)A13(K1,M)                    
!C                                        -1                                 
!C                          + B32(N,K2)PHI  (K2)A23(K1,M)                    
!C                                                                          
!C                                        -1                                 
!C        C33(M,N) = C(M,N) + B31(M,K1)  M  (K2)A13(K2,N)                    
!C                                        -1                                 
!C                          + B32(M,K1)PHI  (K2)A23(K2,N)                    
!C                                                                         
          IJ = IJ + I_1                                                   
          IJK(MNS,NNS) = IJ                                                  
          IJK(NNS,MNS) = IJ + I_1                                         
          DO  J=1,3                                                          
           DO  I=1,3                                                         
            C(I,J,IJ  ) = D_0                                             
            C(I,J,IJ+1) = D_0                                             
           END DO
          END DO
          IJ = IJ + I_1                                                  
         END IF
!C
         JJ = IJK(MNS,NNS)                                                   
         DO  I=1,3                                                           
          DO  J=1,3                                                         
           SUM = C(I,J,JJ)                                                   
           TUM = C(I,J,JJ+1)                                                 
           DO  K=1,3                                                         
            SUM = SUM 
     &      + B31(I,K,2*N  ) * SEG(K2)%RECIP_MASS   * A13(K,J,2*M-1)     
     &      + B32(I,K,2*N  ) * SEG(K2)%RECIP_PHI(K) * A23(K,J,2*M-1)      
            TUM = TUM 
     &      + B31(I,K,2*M-1) * SEG(K2)%RECIP_MASS   * A13(K,J,2*N  )    
     &      + B32(I,K,2*M-1) * SEG(K2)%RECIP_PHI(K) * A23(K,J,2*N  )  
           END DO
           C(I,J,JJ  ) = SUM                                                 
           C(I,J,JJ+1) = TUM                                                 
          END DO
         END DO
        END IF
!C
        IF ( K2 .EQ. KQ2(M) )   THEN                                        
         IF ( IJK(MNS,NNS) .EQ. I_0 )  THEN                            
!C                                                                          
!C        For any M>N such that K2(N) = K2(M)                               
!C                                                                          
!C                                        -1                                
!C        C33(N,M) = C(N,M) + B31(N,K2)  M  (K2)A13(K2,M)                   
!C                                        -1                                
!C                          + B32(N,K2)PHI  (K2)A23(K2,M)                   
!C                                                                         
!C                                        -1                                
!C        C33(M,N) = C(M,N) + B31(M,K2)  M  (K2)A13(K2,N)                  
!C                                        -1                                
!C                          + B32(M,K2)PHI  (K2)A23(K2,N)                   
!C                                                                         
          IJ = IJ + I_1                                                 
          IJK(MNS,NNS) = IJ                                                 
          IJK(NNS,MNS) = IJ + I_1                                       
          DO  J=1,3                                                         
           DO  I=1,3                                                        
            C(I,J,IJ  ) = D_0                                             
            C(I,J,IJ+1) = D_0                                              
           END DO
          END DO
          IJ = IJ + I_1                                                
         END IF
         JJ = IJK(MNS,NNS)                                                  
         DO  I=1,3                                                          
          DO  J=1,3                                                         
           SUM = C(I,J,JJ)                                                  
           TUM = C(I,J,JJ+1)                                                
           DO  K=1,3                                                        
            SUM = SUM
     &       + B31(I,K,2*N  ) * SEG(K2)%RECIP_MASS   * A13(K,J,2*M  )    
     &       + B32(I,K,2*N  ) * SEG(K2)%RECIP_PHI(K) * A23(K,J,2*M  )    
            TUM = TUM 
     &       + B31(I,K,2*M  ) * SEG(K2)%RECIP_MASS   * A13(K,J,2*N  )       
     &       + B32(I,K,2*M  ) * SEG(K2)%RECIP_PHI(K) * A23(K,J,2*N  )    
           END DO
           C(I,J,JJ  ) = SUM                                                
           C(I,J,JJ+1) = TUM                                                
          END DO
         END DO
        END IF
   30  CONTINUE                                                            
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, 19_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
