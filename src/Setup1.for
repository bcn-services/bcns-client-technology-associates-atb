      SUBROUTINE SETUP1                                                   
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C    For KK=1 (before CONTACT routine in DAUX)                           
!C    Set up initial values of A2 and B2 arrays for this time point.      
!C    Set up initial values of arrays U1,U2 and V1.                       
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:   
     &        IEULER,                                 ! /CEULER/
     &        A11, B12, V1, V2,                       ! /CMATRX/
     &        NGRND, NJNT, NPRT, NSEG,                ! /CONTRL/
     &        HT,                                     ! /DESCRP/
     &        SEG, JNT,                               ! structures
     &        INTEGER_STD, IREAL_HIGH, LUAOU,         ! parameters
     &        I_0, I_1, I_2, I_5, I_6, I_10,          ! parameters
     &        D_0, D_1, D_2                           ! parameters
!C
!C    ANG_VEL, DIR_COS, EXT_ANG_ACL, EXT_LIN_ACL, PHI   ! SEG%
!C    PROX_SEG, DSTL_LOC, PROX_LOC, PROX_CNST, JTYPE,   ! JNT%
!C    PROX_HB, DSTL_HB, DSTL_CNST                       ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IFIRST, J, K, L
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  S, S1, S2, SR2, T, T1, T2_LCL, T4,
     &                  T5_LCL, T6, V1T 
      DIMENSION         S(3), T(3), T1(3), T2_LCL(3), T4(3), 
     &                  T5_LCL(3), T6(3)
!C
      DATA IFIRST / I_1 /                                         
!C                                                                        
      CALL ELTIME ( I_1, I_10 )                                              
!C
      IF ( IFIRST .NE. I_0 )  THEN                                      
       IF ( NJNT .NE. I_0 )  THEN                                        
        DO  I = 1,NJNT                                                    
         DO  J = 1,3                                                       
          DO  K = 1,3                                                     
           A11(J,K,I) = D_0                                       
          END DO
          A11(J,J,I) = D_1                                                
         END DO
        END DO
        IFIRST = I_0                                                   
       END IF
      END IF
!C
      DO  I=1,NGRND                                                        
!C                                                                        
!C     Set each external linear acceleration to = 0.                 
!C                                                                        
       SEG(I)%EXT_LIN_ACL = D_0                                           
!C                                                                       
!C     Set each external angular acceleration N to WN X ( PHIN * WN ).   
!C                                                                        
       SEG(I)%EXT_ANG_ACL(1) = SEG(I)%ANG_VEL(2) * SEG(I)%ANG_VEL(3) 
     &                         * ( SEG(I)%PHI(2) - SEG(I)%PHI(3) )   
       SEG(I)%EXT_ANG_ACL(2) = SEG(I)%ANG_VEL(1) * SEG(I)%ANG_VEL(3)
     &                         * ( SEG(I)%PHI(3) - SEG(I)%PHI(1) )  
       SEG(I)%EXT_ANG_ACL(3) = SEG(I)%ANG_VEL(1) * SEG(I)%ANG_VEL(2) 
     &                         * ( SEG(I)%PHI(1) - SEG(I)%PHI(2) )    
      END DO
      IF ( NPRT(11) .NE. I_0 )  THEN 
       WRITE ( LUAOU, 121 )  
     &         ( ( SEG(J)%EXT_ANG_ACL(I), I=1,3 ), J=1,NSEG )     
  121  FORMAT ( 1X 'EXT_ANG_ACL array', /, ( 1X, 9( 1PD14.4 ) ) )       
      END IF
      IF ( NJNT .LE. I_0 )  THEN                                       
       CALL ELTIME ( I_2, I_10 )                                              
       RETURN                                                           
      END IF
!C
      DO 40 J=1,NJNT                                                      
       DO  K=1,3                                                         
        T1(K)     = JNT(J)%PROX_LOC(K)
        T2_LCL(K) = JNT(J)%DSTL_LOC(K)
        IF ( ABS ( JNT(J)%JTYPE ) .GE. I_5 )  THEN                            
         IF ( IEULER(J) .NE. -I_1 )  THEN                                    
          T1(K) = T1(K) + JNT(J)%PROX_CNST * HT(K,3,2*J-1)
          V1(K,J) = D_0                                               
         END IF
        END IF
       END DO
       I = ABS ( JNT(J)%PROX_SEG )                                       
       IF ( I .LE. I_0 )   CYCLE                                      
!C                                                                        
!C     For each joint set                                                 
!C     B12(2J-1) = B12(J,I  ) = -D(I)'   * JNT(J)%PROX_LOC X            
!C     B12(2J  ) = B12(J,J+1) =  D(J+1)' * JNT(J)%DSTL_LOC X             
!C                                                                        
       B12(1,1,2*J-1) =   SEG(I)%DIR_COS(3,1) * T1(2) 
     &                  - SEG(I)%DIR_COS(2,1) * T1(3)        
       B12(2,1,2*J-1) =   SEG(I)%DIR_COS(3,2) * T1(2) 
     &                  - SEG(I)%DIR_COS(2,2) * T1(3)       
       B12(3,1,2*J-1) =   SEG(I)%DIR_COS(3,3) * T1(2) 
     &                  - SEG(I)%DIR_COS(2,3) * T1(3)          
       B12(1,2,2*J-1) =   SEG(I)%DIR_COS(1,1) * T1(3) 
     &                  - SEG(I)%DIR_COS(3,1) * T1(1)        
       B12(2,2,2*J-1) =   SEG(I)%DIR_COS(1,2) * T1(3) 
     &                  - SEG(I)%DIR_COS(3,2) * T1(1)         
       B12(3,2,2*J-1) =   SEG(I)%DIR_COS(1,3) * T1(3) 
     &                  - SEG(I)%DIR_COS(3,3) * T1(1)      
       B12(1,3,2*J-1) =   SEG(I)%DIR_COS(2,1) * T1(1) 
     &                  - SEG(I)%DIR_COS(1,1) * T1(2)       
       B12(2,3,2*J-1) =   SEG(I)%DIR_COS(2,2) * T1(1) 
     &                  - SEG(I)%DIR_COS(1,2) * T1(2)           
       B12(3,3,2*J-1) =   SEG(I)%DIR_COS(2,3) * T1(1)
     &                  - SEG(I)%DIR_COS(1,3) * T1(2)         
!C                                                                        
       B12(1,1,2*J  ) =   SEG(J+1)%DIR_COS(2,1) * T2_LCL(3) 
     &                  - SEG(J+1)%DIR_COS(3,1) * T2_LCL(2)     
       B12(2,1,2*J  ) =   SEG(J+1)%DIR_COS(2,2) * T2_LCL(3) 
     &                  - SEG(J+1)%DIR_COS(3,2) * T2_LCL(2)    
       B12(3,1,2*J  ) =   SEG(J+1)%DIR_COS(2,3) * T2_LCL(3) 
     &                  - SEG(J+1)%DIR_COS(3,3) * T2_LCL(2)    
       B12(1,2,2*J  ) =   SEG(J+1)%DIR_COS(3,1) * T2_LCL(1) 
     &                  - SEG(J+1)%DIR_COS(1,1) * T2_LCL(3)    
       B12(2,2,2*J  ) =   SEG(J+1)%DIR_COS(3,2) * T2_LCL(1) 
     &                  - SEG(J+1)%DIR_COS(1,2) * T2_LCL(3)     
       B12(3,2,2*J  ) =   SEG(J+1)%DIR_COS(3,3) * T2_LCL(1) 
     &                  - SEG(J+1)%DIR_COS(1,3) * T2_LCL(3)     
       B12(1,3,2*J  ) =   SEG(J+1)%DIR_COS(1,1) * T2_LCL(2) 
     &                  - SEG(J+1)%DIR_COS(2,1) * T2_LCL(1)     
       B12(2,3,2*J  ) =   SEG(J+1)%DIR_COS(1,2) * T2_LCL(2) 
     &                  - SEG(J+1)%DIR_COS(2,2) * T2_LCL(1)     
       B12(3,3,2*J  ) =   SEG(J+1)%DIR_COS(1,3) * T2_LCL(2) 
     &                  - SEG(J+1)%DIR_COS(2,3) * T2_LCL(1)    
!C                                                                       
!C     Note that for each joint                                           
!C      A21(M,N) = B12(N,M)                                               
!C                                                                       
!C     For each joint set                                                 
!C      V1(J) = - D(I)'   * W(I)   X ( W(I)   X SR(2J-1) )               
!C              + D(J+1)' * W(J+1) X ( W(J+1) X SR(2J) )                 
!C                                                                       
       CALL CROSS ( SEG(I)%ANG_VEL,   T1,     T       )                  
       CALL CROSS ( SEG(I)%ANG_VEL,   T,      S       )                 
       CALL DOT31 ( SEG(I)%DIR_COS,   S,      V1(1,J) )                    
       CALL CROSS ( SEG(J+1)%ANG_VEL, T2_LCL, T       )                    
       CALL CROSS ( SEG(J+1)%ANG_VEL, T,      S       )                 
       CALL DOT31 ( SEG(J+1)%DIR_COS, S,      T       )                  
       DO  K=1,3                                                          
        V1(K,J) = T(K) - V1(K,J)                                           
       END DO
       IF ( ABS ( JNT(J)%JTYPE ) .GE. I_5 )  THEN                           
        IF ( IEULER(J) .NE. -1 )  THEN                                     
         CALL DOT31 ( SEG(I)%DIR_COS, HT(1,3,2*J-1), T4     )             
         CALL CROSS ( SEG(I)%ANG_VEL, HT(1,3,2*J-1), T5_LCL )               
         CALL DOT31 ( SEG(I)%DIR_COS, T5_LCL,        T6     )               
         V1T = V1(1,J) * T4(1) + V1(2,J) * T4(2) + V1(3,J) * T4(3)          
         SR2 = D_2 * JNT(J)%DSTL_CNST                                     
         DO  K = 1,3                                                        
          V1(K,J) = V1(K,J) - V1T * T4(K) - SR2 * T6(K)                   
          S1 =   T4(1) * B12(1,K,2*J-1) + T4(2) * B12(2,K,2*J-1)
     &         + T4(3) * B12(3,K,2*J-1)                                   
          S2 =   T4(1) * B12(1,K,2*J  ) + T4(2) * B12(2,K,2*J  )
     &         + T4(3) * B12(3,K,2*J  )                                  
          DO  L = 1,3                                                      
           A11(K,L,J)     =               -T4(K) * T4(L)                    
           B12(L,K,2*J-1) =  B12(L,K,2*J-1) - S1 * T4(L)                  
           B12(L,K,2*J  ) =  B12(L,K,2*J  ) - S2 * T4(L)                   
          END DO
          A11(K,K,J) = D_1 + A11(K,K,J)                                    
         END DO
        END IF
       END IF
   40 CONTINUE                                                            
      IF  ( NPRT(11) .NE. I_0 )  THEN
       WRITE ( LUAOU, 141 )  ( ( V1(I,J), I=1,3 ), J=1,NJNT )         
  141  FORMAT ( ' V1 Array', /, ( 1X, 9(1PD14.4 ) ) )                     
      END IF
!C                                                                       
!C    If JTYPE(M)=1, set V2(M)=(WN.HN-WM.HM)DN'WNXHN                     
!C                                                                        
      DO  J=1,NJNT                                                       
       DO  K=1,3                                                          
        V2(K,J) = D_0                           
       END DO
       IF ( JNT(J)%JTYPE .GE. I_1 )  THEN                                     
        IF ( ( JNT(J)%JTYPE .LE. I_1 ) .OR. 
     &       ( JNT(J)%JTYPE .GE. I_6 ) )  THEN         
         I = ABS ( JNT(J)%PROX_SEG )                                        
         CALL CROSS ( SEG(I)%ANG_VEL, JNT(J)%PROX_HB, T  )              
         CALL DOT31 ( SEG(I)%DIR_COS, T,              T1 )                
!C
!C       Call CROSS ( WMEG(1,J+1), HB(1,2*J  ), T  )                      
!C       Call DOT31 ( D(1,1,J+1),  T,           T2 )                      
!C 
         S1 = DOT_PRODUCT ( SEG(I)%ANG_VEL,   JNT(J)%PROX_HB )
         S2 = DOT_PRODUCT ( SEG(J+1)%ANG_VEL, JNT(J)%DSTL_HB )
         DO  K=1,3                                                       
!C        V2(K,J) = S1*T1(K) - S2*T2(K)                                   
          V2(K,J) = ( S1 - S2 ) * T1(K)                                  
         END DO
        END IF
       END IF                                                            
      END DO
!C
      CALL ELTIME ( I_2, I_10 )                                              
!C
      RETURN                                                              
      END                                                               
