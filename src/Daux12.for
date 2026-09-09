      SUBROUTINE DAUX12                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C     Called by Subroutine DAUX to compute                               
!C                                                                        
!C                           -1                                           
!C         (C12) = (B12)(PHI)  (A22)                                      
!C                                                                        
!C                      T                                                 
!C         (C21) = (C12)                                                  
!C                                                                        
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        A22, B12,                                   ! /CMATRX/
     &        NJNT,                                       ! /CONTRL/
     &        IJ, IJK, C, NQ2S,                           ! /DAUX_TEMPVS/
     &        SEG, JNT,                                   ! structures
     &        INTEGER_STD, IREAL_HIGH, LOGICAL_STD,       ! parameters
     &        TRUE, FALSE, I_0, I_1, I_2, I_15, D_0       ! parameters
!C
!C    RECIP_PHI, SINGULAR                ! SEG%
!C    PROX_SEG, SLIP_FREE                ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:  NFBOD, IBODN         ! /FXVAR/
!C
      IMPLICIT  NONE
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, II, J, K, L, M, M1, M2, MB, MJNT, MM, 
     &         MQ, N, NB, NQSJNT
!C
      REAL  ( KIND = IREAL_HIGH )  CT1, CT1T, CT2, CT2T, SN, SM
      DIMENSION        CT1(3,3), CT1T(3,3), CT2(3,3), CT2T(3,3),        
     &                 SN(3,3), SM(3,3)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  NFLG, MFLG                
!C
      CALL ELTIME ( I_1, I_15 )                                               
!C
      NQSJNT = NQ2S + NJNT                                                
      DO 60 M=1,NJNT                                                      
       N = ABS ( JNT(M)%PROX_SEG )                                        
       IF ( N .EQ. I_0 )  CYCLE                                      
       MQ = NQ2S + M                                                      
!C
!C     Check to see if N or M+1 are deformable                          
!C
       NFLG = FALSE                                                 
       MFLG = FALSE                                                   
       IF ( NFBOD .NE. I_0 )  THEN                                   
        DO  II=1,NFBOD                                                  
         IF ( IBODN(II) .EQ. N )  THEN                                  
          NFLG = TRUE                                              
          NB = II                                                       
         ELSE IF ( IBODN(II) .EQ. ( M + I_1 ) )  THEN                
          MFLG = TRUE                                                
          MB = II                                                       
         END IF                                                         
        END DO                                                          
       END IF
       IF ( .NOT. JNT(M)%SLIP_FREE )  THEN                                  
        MJNT = NQSJNT + M                                                  
        IJ = IJ + I_1                                                   
        IJK(MQ,MJNT) = IJ                                                  
        IJK(MJNT,MQ) = IJ + I_1                                           
!C                                                                       
!C      Calculate C12 & C21 for deformable N and/or M+1                  
!C
        IF ( NFLG ) THEN                                                 
         M2 = I_2 * M - I_1                                        
         CALL FDUX12 ( M2, M2, NB, CT1, CT1T )                           
        END IF                                                           
        IF ( MFLG )  THEN                                                
         M2 = I_2 * M                                                 
         CALL FDUX12 ( M2, M2, MB, CT2, CT2T )                           
        END IF                                                           
!C
        IF ( NFLG .AND. MFLG ) THEN                                      
         DO  I=1,3                                                       
          DO  J=1,3                                                      
           C(I,J,IJ) = CT1(I,J) + CT2(I,J)                               
           C(I,J,IJ+1) = CT1T(I,J) + CT2T(I,J)                           
          END DO                                                         
         END DO
        ELSE IF ( NFLG .AND. ( .NOT. MFLG ) )  THEN                      
         DO  I=1,3                                                       
          DO  J=1,3                                                      
           SM(I,J) = D_0                                            
           DO  K=1,3                                                     
            SM(I,J) = SM(I,J) + B12(I,K,2*M) * SEG(M+1)%RECIP_PHI(K)
     &                                       * A22(K,J,2*M)              
           END DO
           C(I,J,IJ) = CT1(I,J) - SM(I,J)                                
           C(J,I,IJ+1) = CT1T(J,I) - SM(I,J)                             
          END DO                                                         
         END DO
        ELSE IF  ( ( .NOT. NFLG ) .AND. MFLG )    THEN                   
         DO  I=1,3                                                       
          DO  J=1,3                                                      
           SN(I,J) = D_0                                              
           DO  K=1,3                                                     
            SN(I,J) = SN(I,J) + B12(I,K,2*M-1) * SEG(N)%RECIP_PHI(K) 
     &                                         * A22(K,J,2*M-1)          
           END DO
           C(I,J,IJ)   = SN(I,J) + CT2(I,J)                              
           C(J,I,IJ+1) = SN(I,J) + CT2T(J,I)                             
          END DO
         END DO                                                          
        ELSE                                                             
         DO  I=1,3                                                          
          DO  J=1,3                                                         
           SN(I,J) = D_0                                                 
           SM(I,J) = D_0                                                 
           DO  K=1,3                                                        
            SN(I,J) = SN(I,J) + B12(I,K,2*M-1) * SEG(N  )%RECIP_PHI(K) 
     &                                         * A22(K,J,2*M-1)             
            SM(I,J) = SM(I,J) + B12(I,K,2*M  ) * SEG(M+1)%RECIP_PHI(K) 
     &                                         * A22(K,J,2*M  )             
           END DO
           C(I,J,IJ  ) = SN(I,J) - SM(I,J)                                  
           C(J,I,IJ+1) = C(I,J,IJ)                                          
          END DO
         END DO
        END IF                                                           
        IJ = IJ + I_1                                                     
       END IF
!C
       IF  ( SEG(N)%SINGULAR .EQ. I_0 )   THEN                           
        IF  ( N .NE. I_1 )   THEN                                    
         IF ( .NOT. JNT(N-1)%SLIP_FREE )  THEN                                  
          MJNT = NQSJNT + N - I_1                                         
          IJ = IJ + I_1                                                    
          IJK(MQ,MJNT) = IJ                                                  
          IJK(MJNT,MQ) = IJ + I_1                                          
!C                                                                         
!C        Calculte C12 & C21 if N is deformable                            
!C
          IF ( NFLG ) THEN                                                 
           MM = I_2 * M - I_1                                           
           M2 = I_2 * N - I_2                                     
           CALL FDUX12 ( MM, M2, NB, CT1, CT1T )                           
           DO  I=1,3                                                       
            DO  J=1,3                                                      
             C(I,J,IJ) = CT1(I,J)                                          
             C(I,J,IJ+1) = CT1T(I,J)                                       
            END DO                                                         
           END DO
           IJ = IJ + I_1                                              
          ELSE                                                           
!C                                                                       
           DO  I=1,3                                                          
            DO  J=1,3                                                         
             SN(I,J) = D_0                                             
             DO  K=1,3                                                        
              SN(I,J) = SN(I,J) + B12(I,K,2*M-1) * SEG(N  )%RECIP_PHI(K) 
     &                                           * A22(K,J,2*N-2)             
             END DO
             C(I,J,IJ  ) = -SN(I,J)                                           
             C(J,I,IJ+1) = -SN(I,J)                                           
            END DO
           END DO
           IJ = IJ + I_1                                                    
          END IF
         END IF
        END IF
        DO  L=N,NJNT                                                     
         IF ( L .EQ. M )  CYCLE                                            
         IF ( ABS ( JNT(L)%PROX_SEG ) .NE. N  )  CYCLE                  
         IF ( JNT(L)%SLIP_FREE )  CYCLE                                      
         MJNT = NQSJNT + L                                                 
         IJ = IJ + I_1                                                  
         IJK(MQ,MJNT) = IJ                                                 
         IJK(MJNT,MQ) = IJ + I_1                                         
!C                                                                       
!C       Calculate C12 & C21 if N is deformable                          
!C
         IF ( NFLG ) THEN                                                
          MM = I_2 * M - I_1                                             
          M2 = I_2 * L - I_1                                           
          CALL FDUX12 ( MM, M2, NB, CT1, CT1T )                          
          DO  I=1,3                                                      
           DO  J=1,3                                                     
            C(I,J,IJ)   = CT1(I,J)                                       
            C(I,J,IJ+1) = CT1T(I,J)                                      
           END DO
          END DO                                                         
          IJ = IJ + I_1                                                
          CYCLE                                                          
         END IF                                                          
!C                                                                       
         DO  I=1,3                                                         
          DO  J=1,3                                                        
           SN(I,J) = D_0                                              
           DO  K=1,3                                                       
            SN(I,J) = SN(I,J) + B12(I,K,2*M-1) * SEG(N  )%RECIP_PHI(K)
     &                                         * A22(K,J,2*L-1)            
           END DO
           C(I,J,IJ  ) = SN(I,J)                                           
           C(J,I,IJ+1) = SN(I,J)                                           
          END DO
         END DO
         IJ = IJ + I_1                                                   
        END DO                                                           
       END IF
!C
       IF   ( ( M .NE. NJNT ) .AND.                                       
     &        ( SEG(M+1)%SINGULAR .EQ. I_0 ) )   THEN                   
        M1 = M + I_1                                                  
        DO  L=M1,NJNT                                                   
         IF ( ABS ( JNT(L)%PROX_SEG ) .NE. M1 )  CYCLE                    
         IF ( JNT(L)%SLIP_FREE )  CYCLE                                    
         MJNT = NQSJNT + L                                                
         IJ = IJ + I_1                                                 
         IJK(MQ,MJNT) = IJ                                                
         IJK(MJNT,MQ) = IJ + I_1                                       
!C                                                                      
!C       Calculate C12 & C21 if M+1 is deformable.                       
!C
         IF ( MFLG ) THEN                                               
          MM = I_2 * M                                              
          M2 = I_2 * L - I_1                                           
          CALL FDUX12 ( MM, M2, MB, CT1, CT1T )                         
          DO  I=1,3                                                     
           DO  J=1,3                                                    
            C(I,J,IJ) = CT1(I,J)                                        
            C(I,J,IJ+1) = CT1T(I,J)                                     
           END DO
          END DO
          IJ = IJ + I_1                                              
          CYCLE                                                         
         END IF                                                         
!C                                                                      
         DO  I=1,3                                                        
          DO  J=1,3                                                       
           SM(I,J) = D_0                                             
           DO  K=1,3                                                      
            SM(I,J) = SM(I,J) + B12(I,K,2*M  ) * SEG(M+1)%RECIP_PHI(K) 
     &                                         * A22(K,J,2*L-1)           
           END DO
           C(I,J,IJ  ) = SM(I,J)                                          
           C(J,I,IJ+1) = SM(I,J)                                          
          END DO
         END DO
         IJ = IJ + I_1                                                  
        END DO                                                          
       END IF
   60 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, I_15 )                                               
!C
      RETURN                                                              
      END                                                                 
