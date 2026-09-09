      SUBROUTINE DAUX32                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Called by Subroutine DAUX to compute                                
!C                                                                        
!C                      -1                                                
!C    (C23) = (B22)(PHI)  (A23)                                           
!C                                                                        
!C                      -1                                                
!C    (C32) = (B32)(PHI)  (A22)                                           
!C                                                                        
!C
      USE  MODULE_STANDARD,  
     &        ONLY:  A22,                           ! /CMATRX/
     &               NJNT, NQ,                      ! /CONTRL/
     &               KQ1, KQ2, KQTYPE, A23, B32,    ! /CSTRNT/
     &               C, IJ, IJK, NQ2S,              ! /DAUX_TEMPVS/
     &               SEG, JNT,                      ! structures
     &               INTEGER_STD, IREAL_HIGH,       ! parameters
     &               D_0, I_0, I_1, I_2, I_18       ! parameters
!C
!C    RECIP_PHI, SINGULAR          ! SEG%
!C    PROX_SEG, SLIP_FREE          ! JNT%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                I, J, JJ, K, K1, K2, KJNT, L, N, NNS, NQSJNT
!C
      REAL  ( KIND = IREAL_HIGH )  SUM, TUM
!C
      CALL ELTIME ( I_1, I_18 )                                               
!C
      NQSJNT = NQ2S + NJNT                                                
      DO 60 N=1,NQ                                                        
       IF ( KQTYPE(N) .LT. I_0 )  CYCLE                                
       K1 = KQ1(N)                                                         
       K2 = KQ2(N)                                                         
       NNS = NQ2S - NQ + N                                                 
       IF ( K1 .GT. I_1 )   THEN                               
        IF ( ABS ( JNT(K1-1)%PROX_SEG ) .NE. I_0 )  THEN                      
         IF ( .NOT. JNT(K1-1)%SLIP_FREE )  THEN                                   
          IF ( SEG(K1)%SINGULAR .EQ. I_0 )  THEN                            
!C                                                                             
!C                                      -1                                    
!C         C23(K1-1,N) = B22(K1-1,K1)PHI  (K1)A23(K1,N)                        
!C                                                                             
!C                                   -1                                       
!C         C32(N,K1-1) = B32(N,K1)PHI  (K1)A22(K1,K1-1)                        
!C                                                                           
           KJNT = NQSJNT + K1 - I_1                                          
           IJ = IJ + I_1                                                    
           IJK(KJNT,NNS) = IJ                                                  
           IJK(NNS,KJNT) = IJ + I_1                                       
           DO  I=1,3                                                           
            DO  J=1,3                                                          
             SUM = D_0                                                       
             TUM = D_0                                                     
             DO  K=1,3                                                         
              SUM = SUM 
     &          + A22(K,I,2*K1-2) * SEG(K1)%RECIP_PHI(K) 
     &                            * A23(K,J,2*N-1 )   
              TUM = TUM 
     &          + B32(I,K,2*N-1 ) * SEG(K1)%RECIP_PHI(K) 
     &                            * A22(K,J,2*K1-2)    
             END DO
             C(I,J,IJ  ) = -SUM                                                
             C(I,J,IJ+1) = -TUM                                                
            END DO
           END DO
           IJ = IJ + I_1                                                     
          END IF
         END IF
        END IF
       END IF
       IF ( K2 .GT. I_1 )  THEN                               
        IF ( ABS ( JNT(K2-1)%PROX_SEG ) .NE. I_0 )  THEN                     
         IF ( .NOT. JNT(K2-1)%SLIP_FREE )  THEN                                  
          IF ( SEG(K2)%SINGULAR .EQ. I_0 )  THEN                         
!C                                                                           
!C                                      -1                                    
!C         C23(K2-1,N) = B22(K2-1,K2)PHI  (K2)A23(K2,N)                        
!C                                                                             
!C                                   -1                                       
!C         C32(N,K2-1) = B32(N,K2)PHI  (K2)A22(K2,K2-1)                        
!C                                                                           
           KJNT = NQSJNT + K2 - I_1                                         
           IJ = IJ + I_1                                                   
           IJK(KJNT,NNS) = IJ                                                  
           IJK(NNS,KJNT) = IJ + I_1                                         
           DO  I=1,3                                                           
            DO  J=1,3                                                          
             SUM = D_0                                                  
             TUM = D_0                                                 
             DO  K=1,3                                                         
              SUM = SUM 
     &            + A22(K,I,2*K2-2) * SEG(K2)%RECIP_PHI(K) 
     &                              * A23(K,J,2*N   )   
              TUM = TUM 
     &            + B32(I,K,2*N   ) * SEG(K2)%RECIP_PHI(K) 
     &                              * A22(K,J,2*K2-2)  
             END DO
             C(I,J,IJ  ) = -SUM                                                
             C(I,J,IJ+1) = -TUM                                                
            END DO
           END DO
           IJ = IJ + I_1                                                   
          END IF
         END IF
        END IF
       END IF
       IF ( NJNT .LE. I_0 )   CYCLE                              
!C 
       DO 56 L=1,NJNT                                                      
        IF ( JNT(L)%SLIP_FREE )   CYCLE                                     
        IF ( ABS ( JNT(L)%PROX_SEG ) .EQ. K1 )  THEN                    
         IF ( SEG(K1)%SINGULAR .EQ. I_0 )   THEN                        
!C                                                                          
!C        For any L such that JNT(L) = K1                                     
!C                                                                            
!C                               -1                                           
!C        C23(L,N) = B22(L,K1)PHI  (K1)A23(K1,N)                              
!C                                                                            
!C                               -1                                           
!C        C32(N,L) = B32(N,K1)PHI  (K1)A22(K1,L)                              
!C                                                                            
          KJNT = NQSJNT + L                                                   
          IF ( IJK(KJNT,NNS) .EQ. I_0 )   THEN                          
           IJ = IJ + I_1                                                   
           IJK(KJNT,NNS) = IJ                                                 
           IJK(NNS,KJNT) = IJ + I_1                                       
           DO  J=1,3                                                          
            DO  I=1,3                                                         
             C(I,J,IJ  ) = D_0                                           
             C(I,J,IJ+1) = D_0                                          
            END DO
           END DO
           IJ = IJ + I_1                                                  
          END IF
          JJ = IJK(KJNT,NNS)                                                  
          DO  I=1,3                                                           
           DO  J=1,3                                                          
            SUM = C(I,J,JJ)                                                   
            TUM = C(I,J,JJ+1)                                                 
            DO  K=1,3                                                         
             SUM = SUM 
     &        + A22(K,I,2*L-1 ) * SEG(K1)%RECIP_PHI(K) 
     &                          * A23(K,J,2*N-1 )   
             TUM = TUM 
     &        + B32(I,K,2*N-1 ) * SEG(K1)%RECIP_PHI(K) 
     &                          * A22(K,J,2*L-1 )     
            END DO
            C(I,J,JJ)   = SUM                                                 
            C(I,J,JJ+1) = TUM                                                 
           END DO
          END DO
         END IF
        END IF
        IF ( ABS ( JNT(L)%PROX_SEG ) .NE. K2 )  CYCLE                 
        IF ( SEG(K2)%SINGULAR .NE. I_0 )  CYCLE                        
!C                                                                          
!C      For any L such that JNT(L) = K2                                     
!C                                                                          
!C                             -1                                           
!C      C23(L,N) = B22(L,K2)PHI  (K2)A23(K2,N)                              
!C                                                                          
!C                             -1                                           
!C      C32(N,L) = B32(N,K2)PHI  (K2)A22(K2,L)                              
!C                                                                          
        KJNT = NQSJNT + L                                                   
        IF ( IJK(KJNT,NNS) .EQ. I_0 )  THEN                             
         IJ = IJ + I_1                                                  
         IJK(KJNT,NNS) = IJ                                                 
         IJK(NNS,KJNT) = IJ + I_1                                         
         DO  J=1,3                                                          
          DO  I=1,3                                                         
           C(I,J,IJ  ) = D_0                                               
           C(I,J,IJ+1) = D_0                                              
          END DO
         END DO
         IJ = IJ + I_1                                                    
        END IF
        JJ = IJK(KJNT,NNS)                                                  
        DO  I=1,3                                                           
         DO  J=1,3                                                          
          SUM = C(I,J,JJ)                                                   
          TUM = C(I,J,JJ+1)                                                 
          DO  K=1,3                                                         
          SUM = SUM 
     &         + A22(K,I,2*L-1 ) * SEG(K2)%RECIP_PHI(K) 
     &                           * A23(K,J,2*N   )   
           TUM = TUM 
     &         + B32(I,K,2*N   ) * SEG(K2)%RECIP_PHI(K) 
     &                           * A22(K,J,2*L-1 )   
          END DO
          C(I,J,JJ)   = SUM                                                 
          C(I,J,JJ+1) = TUM                                                 
         END DO
        END DO
   56  CONTINUE                                                            
   60 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, I_18 )                                               
!C
      RETURN                                                              
      END                                                                 
