      SUBROUTINE DAUX44                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,
     &       ONLY:  A22, B12,                      ! /CMATRX/
     &              NFLX, NS, NJNT, NQ,            ! /CONTRL/
     &              KQ1, KQ2, KQTYPE, A23, B32,    ! /CSTRNT/
     &              V4, B42, NFLEX,                ! /FLXBLE/
     &              IJ, IJK, C, RHS,               ! /DAUX_TEMPVS/
     &              SEG, JNT,                      ! structures
     &              INTEGER_STD, IREAL_HIGH,       ! parameters 
     &              D_0, D_1, I_0, I_1, I_2, I_3   ! parameters
!C
!C    EXT_ANG_ACL, RECIP_PHI, SINGULAR     ! SEG%
!C    SLIP_FREE                            ! JNT%
!C
      IMPLICIT  NONE
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, II, IL, J, JJ, JK, K, KJ, L, LI,
     &          LM, LP1, M, MJ, N1, N2, N3, NSL, NSM
!C
      REAL  ( KIND = IREAL_HIGH )  SET
!C
      IF ( NFLX .EQ. I_0 )  RETURN                                   
!C
      CALL ELTIME ( I_1, 33_INTEGER_STD )                                               
!C
      DO 20 L=1,NFLX                                                      
       N1 = NFLEX(1,L)                                                     
       N2 = NFLEX(2,L)                                                     
       N3 = NFLEX(3,L)                                                     
       IJ = IJ + I_1                                                   
       DO  I=1,3                                                           
        DO  J=1,3                                                          
         C(I,J,IJ) = D_0                                             
         DO  K=1,3                                                         
          C(I,J,IJ) = C(I,J,IJ) 
     &          + B42(I,K,3*L-2) * SEG(N1)%RECIP_PHI(K) * B42(J,K,3*L-2)    
     &          + B42(I,K,3*L-1) * SEG(N2)%RECIP_PHI(K) * B42(J,K,3*L-1)    
     &          + B42(I,K,3*L  ) * SEG(N3)%RECIP_PHI(K) * B42(J,K,3*L  )   
         END DO
        END DO
       END DO
       NSL = I_2 * NS + L                                                 
       IJK(NSL,NSL) = IJ                                                   
       DO  I=1,3                                                           
        RHS(I,NSL) = -V4(I,L)                                              
        DO  J=1,3                                                          
         RHS(I,NSL) = RHS(I,NSL) 
     &                 + B42(I,J,3*L-2) * SEG(N1)%EXT_ANG_ACL(I)   
     &                 + B42(I,J,3*L-1) * SEG(N2)%EXT_ANG_ACL(I)    
     &                 + B42(I,J,3*L  ) * SEG(N3)%EXT_ANG_ACL(I)   
        END DO
       END DO
!C
       IF ( L .NE. NFLX )  THEN                                        
        LP1 = L + I_1                                                   
        DO  M=LP1,NFLX                                                    
         DO  II=1,3,2                                                     
          IL = NFLEX(II,L)                                                  
          IF  ( SEG(IL)%SINGULAR .NE. I_0 )  CYCLE                         
          DO  JJ=1,3,2                                                    
           IF ( NFLEX(II,L) .NE. NFLEX(JJ,M) )  CYCLE                    
           NSM = I_2 * NS + M                                            
           JK = IJK(NSL,NSM)                                                
           KJ = IJK(NSM,NSL)                                                
           IF ( JK .LE. I_0 )  THEN                                      
            IJK(NSL,NSM) = IJ + I_1                                      
            IJK(NSM,NSL) = IJ + I_2                                       
            JK = IJ + I_1                                                 
            KJ = IJ + I_2                                                  
            IJ = IJ + I_2                                                  
            DO  I=1,3                                                       
             DO  J=1,3                                                      
              C(I,J,JK) = D_0                                         
             END DO
            END DO
           END IF
           LI = I_3 * L + II - I_3                                 
           MJ = I_3 * M + JJ - I_3                                  
           DO  I=1,3                                                        
            DO  J=1,3                                                       
             DO  K=1,3                                                      
              C(I,J,JK) = C(I,J,JK) 
     &           + B42(I,K,LI) * SEG(IL)%RECIP_PHI(K) * B42(J,K,MJ)   
             END DO
             C(J,I,KJ) = C(I,J,JK)                                          
            END DO
           END DO
          END DO                                                          
         END DO                                                           
        END DO                                                            
       END IF
!C
       IF ( NQ .NE. I_0 )  THEN                                         
        DO  M=1,NQ                                                       
         IF ( KQTYPE(M) .LT. I_0 )  CYCLE                             
         DO  II=1,3                                                      
          LM = I_0                                                       
          IF ( NFLEX(II,L) .EQ. KQ1(M) ) LM = I_2 * M - I_1           
          IF ( NFLEX(II,L) .EQ. KQ2(M) ) LM = I_2 * M                   
          IF ( LM .EQ. I_0 )  CYCLE                                   
          IL = NFLEX(II,L)                                                 
          IF  ( SEG(IL)%SINGULAR .NE. I_0 )  CYCLE                       
          NSM = I_2 * NS + NFLX + M                                        
          JK = IJK(NSL,NSM)                                                
          KJ = IJK(NSM,NSL)                                                
          IF ( JK .LE. I_0 )   THEN                                    
           IJK(NSL,NSM) = IJ + I_1                                     
           IJK(NSM,NSL) = IJ + I_2                                      
           JK = IJ + I_1                                                
           KJ = IJ + I_2                                              
           IJ = IJ + I_2                                               
           DO  I=1,3                                                       
            DO  J=1,3                                                      
             C(I,J,JK) = D_0                                            
             C(I,J,KJ) = D_0                                         
            END DO
           END DO
          END IF
          LI = 3 * L + II - I_3                                       
          DO  I=1,3                                                        
           DO  J=1,3                                                       
            DO  K=1,3                                                      
             C(I,J,JK) = C(I,J,JK) 
     &       + B42(I,K,LI) * SEG(IL)%RECIP_PHI(K) * A23(K,J,LM)  
             C(I,J,KJ) = C(I,J,KJ) 
     &       + B32(I,K,LM) * SEG(IL)%RECIP_PHI(K) * B42(J,K,LI)  
            END DO
           END DO
          END DO
         END DO                                                          
        END DO                                                           
       END IF
!C
       IF ( NJNT .EQ. I_0 )  CYCLE                                   
       DO 30 M=1,NJNT                                                      
        IF ( JNT(M)%PROX_SEG .EQ. I_0 )  CYCLE                                    
!C
        DO 40 II=1,3                                                       
         LM = I_0                                                       
         IF      ( NFLEX(II,L) .EQ. ABS ( JNT(M)%PROX_SEG ) )  THEN
          LM = I_2 * M - I_1         
         ELSE IF ( NFLEX(II,L) .EQ. ( M + I_1 ) )   THEN  
          LM = I_2 * M              
         END IF
         IF ( LM .EQ. I_0 )  CYCLE                                      
         IL = NFLEX(II,L)                                                  
         IF  ( SEG(IL)%SINGULAR .NE. I_0 )   CYCLE                        
         NSM = I_2 * NS + NFLX + NQ + M                                  
         JK = IJK(NSL,NSM)                                                 
         KJ = IJK(NSM,NSL)                                                 
         IF ( JK .LE. I_0 )   THEN                                    
          IJK(NSL,NSM) = IJ + I_1                                       
          IJK(NSM,NSL) = IJ + I_2                                        
          JK = IJ + I_1                                                 
          KJ = IJ + I_2                                                
          IJ = IJ + I_2                                                 
          DO  I=1,3                                                        
           DO  J=1,3                                                       
            C(I,J,JK) = D_0                                             
           END DO
          END DO
         END IF
         LI = I_3 * L + II - I_3                                  
         DO  I=1,3                                                         
          DO  J=1,3                                                        
           DO  K=1,3                                                       
            C(I,J,JK) = C(I,J,JK) + B42(I,K,LI) * SEG(IL)%RECIP_PHI(K) 
     &                                          * B12(J,K,LM)  
           END DO
           C(J,I,KJ) = C(I,J,JK)                                           
          END DO
         END DO
!C
         IF ( .NOT. JNT(M)%SLIP_FREE )  THEN                                 
          NSM = I_2 * NS + NFLX + NQ + NJNT + M                         
          JK = IJK(NSL,NSM)                                                
          KJ = IJK(NSM,NSL)                                                
          IF ( JK .LE. I_0 )   THEN                                  
           IJK(NSL,NSM) = IJ + I_1                                      
           IJK(NSM,NSL) = IJ + I_2                                      
           JK = IJ + I_1                                              
           KJ = IJ + I_2                                                 
           IJ = IJ + I_2                                                
           DO  I=1,3                                                       
            DO  J=1,3                                                      
             C(I,J,JK) = D_0                                           
            END DO
           END DO
          END IF
          SET = D_1                                                        
          IF ( IL .EQ. ( M + I_1 ) )   SET = -D_1                         
          DO  I=1,3                                                        
           DO  J=1,3                                                       
            DO  K=1,3                                                      
             C(I,J,JK) = C(I,J,JK) + SET * B42(I,K,LI)
     &                             * SEG(IL)%RECIP_PHI(K) * A22(K,J,LM)    
            END DO
            C(J,I,KJ) = C(I,J,JK)                                          
           END DO
          END DO
         END IF
   40   CONTINUE                                                           
   30  CONTINUE                                                            
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, 33_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
