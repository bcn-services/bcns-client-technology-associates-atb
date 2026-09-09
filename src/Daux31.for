      SUBROUTINE DAUX31                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Called by Subroutine DAUX to compute                                
!C                                                                        
!C                    -1                  -1                              
!C    (C13) = (B11)(M)  (A13) + (B12)(PHI)  (A23)                         
!C                                                                        
!C                    -1                  -1                              
!C    (C31) = (B31)(M)  (A11) + (B32)(PHI)  (A21)                         
!C                                                                        
!C
      USE  MODULE_STANDARD, 
     &         ONLY:  A11, B12,                             ! /CMATRX/
     &                NQ, NJNT,                             ! /CONTRL/
     &                KQ1, KQ2, KQTYPE, A23, A13, B32, B31, ! /CSTRNT/
     &                IJ, IJK, NQ2S, C,                     ! /DAUX_TEMPVS/
     &                SEG, JNT,                             ! structures
     &                INTEGER_STD, IREAL_HIGH,              ! parameters
     &                D_0, I_0, I_1, I_2                    ! parameters
!C
!C    RECIP_MASS, RECIP_PHI, SINGULAR       ! SEG%
!C    PROX_SEG                              ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &             I, J, JJ, K, K1, K2, L, MQ, N, NNS
!C
      REAL  ( KIND = IREAL_HIGH )   SUM, TUM
!C
      CALL ELTIME ( I_1, 17_INTEGER_STD )                                               
!C
      DO 20 N=1,NQ                                                        
       IF ( KQTYPE(N) .LT. I_0 ) CYCLE                                  
       K1 = KQ1(N)                                                         
       K2 = KQ2(N)                                                         
       NNS = NQ2S - NQ + N                                                 
       IF ( K1 .GT. 1 )  THEN                                          
        IF ( ABS ( JNT(K1-1)%PROX_SEG ) .NE. I_0 )  THEN                      
         IF  ( SEG(K1)%SINGULAR .EQ. I_0 )  THEN                          
!C                                                                            
!C                                    -1                                      
!C         C13(K1-1,N) = B11(K1-1,K1)M    (K1)A13(K1,N)                       
!C                                      -1                                    
!C                     + B12(K1-1,K1)PHI  (K1)A23(K1,N)                       
!C                                                                            
!C                                 -1                                         
!C         C31(N,K1-1) = B31(N,K1)M    (K1)A11(K1,K1-1)                       
!C                                   -1                                       
!C                     + B32(N,K1)PHI  (K1)A21(K1,K1-1)                       
!C                                                                           
          MQ = NQ2S + K1 - I_1                                              
          IJ = IJ + I_1                                                    
          IJK(MQ,NNS) = IJ                                                    
          IJK(NNS,MQ) = IJ + I_1                                          
          DO  I=1,3                                                           
           DO  J=1,3                                                          
            SUM = D_0                                                          
            TUM = D_0                                                        
            DO  K=1,3                                                         
             SUM = SUM 
     &        + B12(I,K,2*K1-2) * SEG(K1)%RECIP_PHI(K)   
     &                          * A23(K,J,2*N-1 )  
     &        - A11(I,K,K1-1)   * SEG(K1)%RECIP_MASS     
     &                          * A13(K,J,2*N-1)    
             TUM = TUM 
     &        + B32(I,K,2*N-1 ) * SEG(K1)%RECIP_PHI(K)   
     &                          * B12(J,K,2*K1-2)  
     &        - B31(I,K,2*N-1)  * SEG(K1)%RECIP_MASS     
     &                          * A11(K,J,K1-1)     
            END DO
            C(I,J,IJ)   = SUM                                                 
            C(I,J,IJ+1) = TUM                                                 
           END DO
          END DO
          IJ = IJ + I_1                                                   
         END IF
        END IF
       END IF
!C
       IF ( K2 .GT. I_1 )  THEN                                     
        IF ( ABS ( JNT(K2-1)%PROX_SEG ) .NE. I_0 )  THEN                      
         IF ( SEG(K2)%SINGULAR .EQ. I_0 )  THEN                           
!C                                                                           
!C                                   -1                                      
!C        C13(K2-1,N) = B11(K2-1,K2)M    (K2)A13(K2,N)                       
!C                                     -1                                    
!C                    + B12(K2-1,K2)PHI  (K2)A23(K2,N)                       
!C                                                                           
!C                                -1                                         
!C        C31(N,K2-1) = B31(N,K2)M    (K2)A11(K2,K2-1)                       
!C                                  -1                                       
!C                    + B32(N,K2)PHI  (K2)A21(K2,K2-1)                       
!C                                                                           
          MQ = NQ2S + K2 - I_1                                             
          IJ = IJ + I_1                                                  
          IJK(MQ,NNS) = IJ                                                    
          IJK(NNS,MQ) = IJ + I_1                                          
          DO  I=1,3                                                           
           DO  J=1,3                                                          
            SUM = D_0                                                      
            TUM = D_0                                                       
            DO  K=1,3                                                         
             SUM = SUM 
     &         + B12(I,K,2*K2-2) * SEG(K2)%RECIP_PHI(K)   
     &                           * A23(K,J,2*N   )     
     &         - A11(I,K,K2-1)   * SEG(K2)%RECIP_MASS     
     &                           * A13(K,J,2*N)       
             TUM = TUM 
     &         + B32(I,K,2*N   ) * SEG(K2)%RECIP_PHI(K)   
     &                           * B12(J,K,2*K2-2)   
     &         - B31(I,K,2*N)    * SEG(K2)%RECIP_MASS     
     &                           * A11(K,J,K2-1)     
            END DO
            C(I,J,IJ)   = SUM                                                 
            C(I,J,IJ+1) = TUM                                                 
           END DO
          END DO
          IJ = IJ + I_1                                                   
         END IF
        END IF
       END IF
!C
       IF ( NJNT .LE. I_0 )  CYCLE                                   
       DO 30 L=1,NJNT                                                      
        IF  ( ABS ( JNT(L)%PROX_SEG ) .EQ. K1 )   THEN                   
         IF  ( SEG(K1)%SINGULAR .EQ. I_0 )  THEN                        
!C                                                                           
!C        For any L such that JNT(L) = K1                                    
!C                                                                           
!C                             -1                                            
!C        C13(L,N) = B11(L,K1)M    (K1)A13(K1,N)                             
!C                               -1                                          
!C                 + B12(L,K1)PHI  (K1)A23(K1,N)                             
!C                                                                          
!C                             -1                                            
!C        C31(N,L) = B31(N,K1)M    (K1)A11(K1,L)                             
!C                               -1                                          
!C                 + B32(N,K1)PHI  (K1)A21(K1,L)                             
!C                                                                         
          MQ = NQ2S + L                                                       
          IF ( IJK(MQ,NNS) .EQ. I_0 )   THEN                               
           IJ = IJ + I_1                                                   
           IJK(MQ,NNS) = IJ                                                   
           IJK(NNS,MQ) = IJ + I_1                                        
           DO  J=1,3                                                          
            DO  I=1,3                                                         
             C(I,J,IJ  ) = D_0                                        
             C(I,J,IJ+1) = D_0                                            
            END DO
           END DO
           IJ = IJ + I_1                                                   
          END IF
          JJ = IJK(MQ,NNS)                                                    
          DO  I=1,3                                                           
           DO  J=1,3                                                          
            SUM = C(I,J,JJ)                                                     
            TUM = C(I,J,JJ+1)                                                   
            DO  K=1,3                                                         
             SUM = SUM 
     &       + B12(I,K,2*L-1)   * SEG(K1)%RECIP_PHI(K)   
     &                          * A23(K,J,2*N-1) 
     &       + A11(I,K,L)       * SEG(K1)%RECIP_MASS     
     &                          * A13(K,J,2*N-1)    
             TUM = TUM 
     &       + B32(I,K,2*N-1)   * SEG(K1)%RECIP_PHI(K)   
     &                          * B12(J,K,2*L-1) 
     &       + B31(I,K,2*N-1)   * SEG(K1)%RECIP_MASS     
     &                          * A11(J,K,L)      
            END DO
            C(I,J,JJ)   = SUM                                                 
            C(I,J,JJ+1) = TUM                                                 
           END DO
          END DO
         END IF
        END IF
!C
        IF ( ( ABS ( JNT(L)%PROX_SEG ) .EQ. K2 )  .AND.                     
     &       ( SEG(K2)%SINGULAR .EQ. I_0 ) )  THEN                       
!C                                                                         
!C       For any L such that JNT(L) = K2                                    
!C                                                                         
!C                            -1                                            
!C       C13(L,N) = B11(L,K2)M    (K2)A13(K2,N)                             
!C                              -1                                          
!C                + B12(L,K2)PHI  (K2)A23(K2,N)                             
!C                                                                         
!C                            -1                                            
!C       C31(N,L) = B31(N,K2)M    (K2)A11(K2,L)                             
!C                              -1                                          
!C                + B32(N,K2)PHI  (K2)A21(K2,L)                             
!C                                                                         
         MQ = NQ2S + L                                                      
         IF ( IJK(MQ,NNS) .EQ. I_0 )   THEN                              
          IJ = IJ + I_1                                                 
          IJK(MQ,NNS) = IJ                                                  
          IJK(NNS,MQ) = IJ + I_1                                        
          DO  J=1,3                                                         
           DO  I=1,3                                                        
            C(I,J,IJ  ) = D_0                                          
            C(I,J,IJ+1) = D_0                                           
           END DO
          END DO
          IJ = IJ + I_1                                                  
         END IF
         JJ = IJK(MQ,NNS)                                                   
         DO  I=1,3                                                          
          DO  J=1,3                                                         
           SUM = C(I,J,JJ)                                                    
           TUM = C(I,J,JJ+1)                                                  
           DO  K=1,3                                                        
            SUM = SUM 
     &         + B12(I,K,2*L-1) * SEG(K2)%RECIP_PHI(K)   
     &                          * A23(K,J,2*N  )   
     &         + A11(I,K,L)     * SEG(K2)%RECIP_MASS     
     &                          * A13(K,J,2*N)      
            TUM = TUM 
     &         + B32(I,K,2*N  ) * SEG(K2)%RECIP_PHI(K)   
     &                          * B12(J,K,2*L-1)   
     &         + B31(I,K,2*N)   * SEG(K2)%RECIP_MASS     
     &                          * A11(J,K,L)         
           END DO
           C(I,J,JJ)   = SUM                                                
           C(I,J,JJ+1) = TUM                                                
          END DO
         END DO
        END IF
   30  CONTINUE                                                            
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, 17_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
      