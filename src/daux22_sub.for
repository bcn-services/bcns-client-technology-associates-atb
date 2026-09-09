      SUBROUTINE DAUX22_SUB ( M, MB, MJNT, MFLG, N, NB, NFLG, NQSJNT,
     &                        SKIP, TEST,  HH )                                                  
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C     Called by Subroutine DAUX to compute                               
!C                                                                        
!C                                                                        
!C                           -1                                           
!C         (C22) = (B22)(PHI)  (A22) - (B24)                              
!C                                                                        
!C                           -1                                           
!C         (R2)  = (B22)(PHI)  (U2)  - (V2)                               
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       V2, A22,                                     ! /CMATRX/
     &       NJNT,                                        ! /CONTRL/
     &       RHS, IJ, IJK, C,                             ! /DAUX_TEMPVS/
     &       SEG, JNT,                                    ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,        ! parameters
     &       D_0, I_0, I_1, I_2                           ! parameters
!C
!C    DIR_COS, EXT_ANG_ACL, RECIP_PHI, SINGULAR        ! SEG%
!C    PROX_SEG, SLIP_FREE, PROX_HB, DSTL_HB            ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:   PHPI,          ! /FXCOEF/
     &                               NFBOD, IBODN   ! /FXVAR/
!C
      IMPLICIT  NONE
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, J, K, L, LJNT, M, M1, M2, MB, 
     &         MJNT, MM, N, N1JNT, NB, NQSJNT
!C
      REAL  ( KIND = IREAL_HIGH )
     &           CT1, CT2, VT1, VT2, AN, BN, HH, SN
      DIMENSION  CT1(3,3), CT2(3,3), VT1(3), VT2(3),                    
     &           SN(3,3), HH(3,3), BN(3)                                  
!C
      LOGICAL  ( KIND = LOGICAL_STD )  MFLG, NFLG, TEST, SKIP                 
!C
      INTENT (    IN )  M, MB, MFLG, MJNT, N, NB, NFLG, NQSJNT, 
     &                  SKIP, TEST
      INTENT ( INOUT )  HH
!C
!C
      IF ( .NOT. SKIP  )  THEN
       AN = D_0                                                         
!C
!C     If N and/or M+1 are deformable calculate lambda(=AN) 
!C                  = -H**2*RPHI                                         
!C
       IF ( NFLG ) THEN                                                  
        CALL MAT31 ( PHPI(1,1,NB), JNT(M)%PROX_HB, VT1 )                 
        AN = DOT_PRODUCT ( JNT(M)%PROX_HB, VT1 )
       END IF                                                            
!C
       IF ( MFLG ) THEN                                                  
        CALL MAT31 ( PHPI(1,1,MB), JNT(M)%DSTL_HB, VT2 )                 
        AN = AN + DOT_PRODUCT ( JNT(M)%DSTL_HB, VT2 )
       END IF                                                            
!C
       IF ( NFLG .AND. ( .NOT. MFLG ) )  THEN                            
        DO  I=1,3                                                        
         AN = AN + JNT(M)%DSTL_HB(I)**2 * SEG(M+1)%RECIP_PHI(I)                 
        END DO
       ELSE IF ( ( .NOT. NFLG ) .AND. MFLG )  THEN                       
        DO  I=1,3                                                        
         AN = AN + JNT(M)%PROX_HB(I)**2 * SEG(N)%RECIP_PHI(I)               
        END DO
       ELSE IF ( ( .NOT. NFLG ) .AND. ( .NOT. MFLG ) )  THEN             
        DO  J=1,3                                                          
         AN = AN + JNT(M)%PROX_HB(J)**2 * SEG(N  )%RECIP_PHI(J)                    
     &           + JNT(M)%DSTL_HB(J)**2 * SEG(M+1)%RECIP_PHI(J)                 
        END DO
       END IF                                                            
!C
       IF ( .NOT. TEST )  THEN                                             
        CALL DOT31 ( SEG(N)%DIR_COS, JNT(M)%PROX_HB, BN )                     
        DO  J=1,3                                                          
         DO  I=1,3                                                         
          HH(I,J) = AN * BN(I) * BN(J)                                     
         END DO
        END DO
       END IF
      END IF
!C
!C    Calculate C22 and R2 if N and/or M+1 are deformable.              
!C
      IF ( NFLG ) THEN                                                  
       M2 = 2 * M - I_1                                             
       CALL FDUX22 ( M2, M2, NB, CT1, VT1 )                             
      END IF                                                            
      IF ( MFLG ) THEN                                                  
       M2 = 2 * M                                                       
       CALL FDUX22 ( M2, M2, MB, CT2, VT2 )                             
      END IF                                                            
!C
      IF ( NFLG .AND. MFLG ) THEN                                       
       DO  I=1,3                                                        
        RHS(I,MJNT) = VT1(I) + VT2(I) - V2(I,M)                         
        DO  J=1,3                                                       
         C(I,J,IJ) = CT1(I,J) + CT2(I,J) + HH(I,J)                      
        END DO
       END DO
      ELSE IF ( NFLG .AND. ( .NOT. MFLG ) ) THEN                        
       DO  I=1,3                                                        
        RHS(I,MJNT) = VT1(I) - V2(I,M)                                  
        DO  J=1,3                                                       
         RHS(I,MJNT) =    RHS(I,MJNT) 
     &                  - A22(J,I,2*M) * SEG(M+1)%EXT_ANG_ACL(J)  
         C(I,J,IJ) = CT1(I,J) + HH(I,J)                                 
         DO  K=1,3                                                      
          C(I,J,IJ) =   C(I,J,IJ)
     &         + A22(K,I,2*M) * SEG(M+1)%RECIP_PHI(K) * A22(K,J,2*M)    
         END DO
        END DO
       END DO                                                           
      ELSE IF ( ( .NOT. NFLG ) .AND. MFLG ) THEN                        
       DO  I=1,3                                                        
        RHS(I,MJNT) = VT2(I) - V2(I,M)                                  
        DO  J=1,3                                                       
         RHS(I,MJNT) =     RHS(I,MJNT) 
     &                   + A22(J,I,2*M-1) * SEG(N)%EXT_ANG_ACL(J)
         C(I,J,IJ) = CT2(I,J) + HH(I,J)                                 
         DO  K=1,3                                                      
          C(I,J,IJ) = C(I,J,IJ) + 
     &         A22(K,I,2*M-1) * SEG(N)%RECIP_PHI(K) * A22(K,J,2*M-1)   
         END DO
        END DO
       END DO                                                           
      ELSE                                                              
       DO  I=1,3                                                           
        RHS(I,MJNT) = -V2(I,M)                                             
        DO  J=1,3                                                          
         RHS(I,MJNT) =   RHS(I,MJNT) 
     &                 + A22(J,I,2*M-1) * SEG(N  )%EXT_ANG_ACL(J)  
     &                 - A22(J,I,2*M  ) * SEG(M+1)%EXT_ANG_ACL(J)   
         SN(I,J) = D_0                                                    
         IF ( .NOT. TEST )  THEN                                        
          DO  K=1,3                                                         
           SN(I,J) = SN(I,J)
     &      + A22(K,I,2*M-1) * SEG(N  )%RECIP_PHI(K) * A22(K,J,2*M-1) 
     &      + A22(K,I,2*M  ) * SEG(M+1)%RECIP_PHI(K) * A22(K,J,2*M  )  
          END DO
         END IF
         C(I,J,IJ) = SN(I,J) + HH(I,J)                                     
        END DO
        IF ( TEST )  C(I,I,IJ) = AN                                        
       END DO
      END IF                                                            
!C
      IF  ( SEG(N)%SINGULAR .NE. I_0 )  RETURN                         
      IF ( N .NE. I_1 )  THEN                                        
       IF ( .NOT. JNT(N-1)%SLIP_FREE )  THEN                                    
        N1JNT = NQSJNT + N - I_1                                       
        IJ = IJ + I_1                                                   
        IJK(MJNT,N1JNT) = IJ                                                
        IJK(N1JNT,MJNT) = IJ + I_1                                        
!C
!C      Calculate C22 if N is deformable.                                 
!C
        IF ( NFLG ) THEN                                                  
         MM = I_2 * M - I_1                                                 
         M2 = I_2 * N - I_2                                                 
         CALL FDUX22 ( MM, M2, NB, CT1, VT1 )                           
         CALL FDUX22 ( M2, MM, NB, CT2, VT2 )                           
         DO  I=1,3                                                      
          DO  J=1,3                                                     
           C(I,J,IJ) = CT1(I,J)                                         
           C(I,J,IJ+1) = CT2(I,J)                                       
          END DO
         END DO                                                         
        ELSE
         DO  I=1,3                                                           
          DO  J=1,3                                                          
           SN(I,J) = D_0                                                  
           DO  K=1,3                                                         
            SN(I,J) = SN(I,J) + A22(K,I,2*M-1) * SEG(N  )%RECIP_PHI(K) 
     &                                         * A22(K,J,2*N-2)              
           END DO
           C(I,J,IJ)   = -SN(I,J)                                            
           C(J,I,IJ+1) = -SN(I,J)                                            
          END DO
         END DO
        END IF
        IJ = IJ + I_1                                                    
       END IF
      END IF
      IF ( M .EQ. NJNT ) RETURN                                      
      M1 = M + I_1                                                      
!C
      DO  L=M1,NJNT                                                    
       IF ( ABS ( JNT(L)%PROX_SEG ) .NE. N )  CYCLE                        
       IF ( JNT(L)%SLIP_FREE )  CYCLE                                       
       LJNT = NQSJNT + L                                                 
       IJ = IJ + I_1                                                   
       IJK(MJNT,LJNT) = IJ                                               
       IJK(LJNT,MJNT) = IJ + I_1                                       
!C
!C     Calculate C22 if N is deformable.                                 
!C
       IF ( NFLG ) THEN                                                  
        MM = I_2 * M - I_1                                                 
        M2 = I_2 * L - I_1                                                 
        CALL FDUX22 ( MM, M2, NB, CT1, VT1 )                           
        CALL FDUX22 ( M2, MM, NB, CT2, VT2 )                           
        DO  I=1,3                                                      
         DO  J=1,3                                                     
          C(I,J,IJ)   = CT1(I,J)                                       
          C(I,J,IJ+1) = CT2(I,J)                                       
         END DO
        END DO
        IJ = IJ + I_1                                                   
        CYCLE                                                       
       END IF                                                           
       DO  I=1,3                                                          
        DO  J=1,3                                                         
         SN(I,J) = D_0                                                 
         DO  K=1,3                                                         
          SN(I,J) = SN(I,J) + A22(K,I,2*M-1) * SEG(N  )%RECIP_PHI(K) 
     &                      * A22(K,J,2*L-1)                             
         END DO
         C(I,J,IJ)   = SN(I,J)                                            
         C(J,I,IJ+1) = SN(I,J)                                             
        END DO
       END DO
       IJ = IJ + I_1                                                      
      END DO                                                            
!C
      RETURN
      END