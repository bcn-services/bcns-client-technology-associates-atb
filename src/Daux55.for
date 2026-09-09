      SUBROUTINE DAUX55                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &        A11, A22, B12,                             ! /CMATRX/
     &        GRAVTY, G, D_0,                            ! /CNSNTS/
     &        NGRND, NFLX, NS, NQ, NJNT,                 ! /CONTRL/
     &        KQTYPE, KQ1, KQ2, A13, A23, B31, B32,      ! /CSTRNT/
     &        NFLEX, B42,                                ! /FLXBLE/
     &        C, IJ, IJK, RHS, NQ2S,                     ! /DAUX_TEMPVS/
     &        SEG, JNT,                                  ! structures
     &        INTEGER_STD, IREAL_HIGH,                   ! parameters
     &        D_1, I_0, I_1, I_2, I_3, I_4               ! parameters
!C
!C    EXT_ANG_ACL, EXT_LIN_ACL, PHI, SINGULAR, WEIGHT    ! SEG%
!C    PROX_SEG, SLIP_FREE                                ! JNT%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IS, J, K, LN, N, NNS
!C
      REAL  ( KIND = IREAL_HIGH )  SET
!C
      CALL ELTIME ( I_1, 30_INTEGER_STD )                               
!C
      IS = I_0                                                       
      DO 20  I=1,NGRND                                                   
       IF  ( SEG(I)%SINGULAR .LE. I_0 )  CYCLE                              
       IS = IS + I_1                                                     
       IJ = IJ + I_1                                                     
       IJK(IS  ,IS  ) = IJ                                                 
       IJK(IS+1,IS+1) = IJ + I_1                                         
       DO  J=1,3                                                           
        RHS(J,IS  ) =   SEG(I)%EXT_LIN_ACL(J) 
     &                + SEG(I)%WEIGHT * GRAVTY(J) / G             
        RHS(J,IS+1) = SEG(I)%EXT_ANG_ACL(J)                              
        SEG(I)%EXT_LIN_ACL(J) = D_0                                               
        SEG(I)%EXT_ANG_ACL(J) = D_0                                                
        DO  K=1,3                                                          
         C(J,K,IJ  ) = D_0                                         
         C(J,K,IJ+1) = D_0                                            
        END DO
        C(J,J,IJ  ) = SEG(I)%WEIGHT / G                                     
        C(J,J,IJ+1) = SEG(I)%PHI(J)                                    
       END DO
       IJ = IJ + I_1                                                        
       IF ( NFLX .NE. I_0 )  THEN                                      
        DO  N=1,NFLX                                                       
         LN = I_0                                                      
         IF ( NFLEX(1,N) .EQ. I )  LN = I_3 * N - I_2               
         IF ( NFLEX(2,N) .EQ. I )  LN = I_3 * N - I_1               
         IF ( NFLEX(3,N) .EQ. I )  LN = I_3 * N                       
         IF ( LN .NE. I_0 )  THEN                                      
          DO  J=1,3                                                        
           DO  K=1,3                                                       
            C(J,K,IJ+1) =  B42(K,J,LN)                                     
            C(J,K,IJ+2) =  B42(J,K,LN)                                       
           END DO
          END DO
          NNS = I_2 * NS + N                                           
          IJK(IS+1,NNS) = IJ + I_1                                      
          IJK(NNS,IS+1) = IJ + I_2                                      
          IJ = IJ + I_2                                                 
         END IF
        END DO
       END IF
!C
       IF ( NQ .NE. I_0 )  THEN                                       
        DO  N=1,NQ                                                         
         IF ( KQTYPE(N) .LT. I_0 )  CYCLE                               
         LN = I_0                                                       
         IF ( I .EQ. KQ1(N) )  LN = I_2 * N - I_1                      
         IF ( I .EQ. KQ2(N) )  LN = I_2 * N                           
         IF ( LN .EQ. I_0 )  CYCLE                                     
         DO  J=1,3                                                         
          DO  K=1,3                                                        
           C(J,K,IJ+1) =  A13(J,K,LN)                                      
           C(J,K,IJ+2) =  A23(J,K,LN)                                      
           C(J,K,IJ+3) =  B31(J,K,LN)                                        
           C(J,K,IJ+4) =  B32(J,K,LN)                                        
          END DO
         END DO
         NNS = I_2 * NS + NFLX + N                                    
         IJK(IS  ,NNS) = IJ + I_1                                       
         IJK(IS+1,NNS) = IJ + I_2                                      
         IJK(NNS,IS  ) = IJ + I_3                                   
         IJK(NNS,IS+1) = IJ + I_4                                      
         IJ = IJ + I_4                                               
        END DO                                                             
       END IF
!C
       IF ( NJNT .NE. I_0 )  THEN                                        
        DO  N=1,NJNT                                                       
         IF ( JNT(N)%PROX_SEG .EQ. I_0 )  CYCLE                             
         LN = I_0                                                       
         IF ( I .EQ. ABS ( JNT(N)%PROX_SEG ) ) LN = I_2 * N - I_1         
         IF ( I .EQ. ( N + I_1 ) )          LN = I_2 * N              
         IF ( LN .EQ. I_0 )  CYCLE                                     
         SET = D_1                                                         
         IF ( I .EQ. ( N + I_1 ) )   SET = -D_1                          
         DO  J=1,3                                                         
          DO  K=1,3                                                          
           C(J,K,IJ+1) = SET * A11(J,K,N)                                    
           C(J,K,IJ+3) = SET * A11(K,J,N)                                    
           C(J,K,IJ+2) =  B12(K,J,LN)                                      
           C(J,J,IJ+4) = B12(J,K,LN)                                         
          END DO
         END DO
         NNS = NQ2S + N                                                    
         IJK(IS  ,NNS) = IJ + I_1                                    
         IJK(IS+1,NNS) = IJ + I_2                                       
         IJK(NNS,IS  ) = IJ + I_3                                     
         IJK(NNS,IS+1) = IJ + I_4                                  
         IJ = IJ + I_4                                               
         IF ( JNT(N)%SLIP_FREE )  CYCLE                                      
         DO  J=1,3                                                         
          DO  K=1,3                                                        
           C(J,K,IJ+1) =  SET * A22(J,K,LN)                                
           C(J,K,IJ+2) =  SET * A22(K,J,LN)                                 
          END DO
         END DO
         NNS = NQ2S + NJNT + N                                             
         IJK(IS+1,NNS) = IJ + I_1                                        
         IJK(NNS,IS+1) = IJ + I_2                                       
         IJ = IJ + I_2                                                  
        END DO                                                             
       END IF
       IS = IS + I_1                                                     
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, 30_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
