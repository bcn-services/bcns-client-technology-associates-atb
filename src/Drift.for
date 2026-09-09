      SUBROUTINE DRIFT                                                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Corrects for drift in constrained joints                             
!C                                                                         
!C                                                                         
      USE  MODULE_STANDARD,  ONLY: 
     &        IEULER, HIR,                             ! /CEULER/
     &        EPS,                                     ! /CNSNTS/
     &        NJNT, TIME,                              ! /CONTRL/
     &        SEG, JNT,                                ! structures
     &        INTEGER_STD, IREAL_HIGH,                 ! parameters
     &        LOGICAL_STD, LUAOU, MAXJNT,              ! parameters
     &        FALSE, TRUE,                             ! parameters   
     &        I_0, I_1, I_2, I_3,                      ! parameters
     &        I_4, I_5, I_6, I_7, I_10,                ! parameters
     &        D_0, D_HALF, D_1                         ! parameters
!C
!C    ANG_VEL, DIR_COS, SINGULAR                              ! SEG%
!C    COS_NUTA, PROX_SEG, SIN_NUTA, JTYPE, PROX_HB, DSTL_HB   ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:  NFBOD, IBODN,         ! /FXVAR/
     &                              WNP                   ! /NODVEL/ = /FXNVEL/ 
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, ITER, J, K, L, M, MAX_RENORM
      PARAMETER ( MAX_RENORM = I_10 )
!C
      REAL  ( KIND = IREAL_HIGH )  CT, DET, HW, HXA, HYA, HZA, ST
      REAL  ( KIND = IREAL_HIGH )  T1, T2, T3, T4, TP, H1, H2, HDIF
      DIMENSION  T1(3), T2(3), T3(3), T4(3), TP(3,3), H1(3), H2(3),
     &           HDIF(3)         
!C
      LOGICAL  ( KIND = LOGICAL_STD )  FFLG, CONVERGED                                
!C
      IF ( NJNT .EQ. I_0 )  RETURN                                      
      DO 50 J=1,NJNT                                                      
       K = ABS ( JNT(J)%PROX_SEG )                                        
       IF ( K .EQ. I_0 )  CYCLE                                          
       IF ( SEG(J+1)%SINGULAR .LT. I_0 )  CYCLE                                
!C                                                                       
       M = I_0                                                          
       IF ( JNT(J)%JTYPE .EQ. I_1 )  M = I_4                                    
       IF ( JNT(J)%JTYPE .EQ. I_6 )  M = I_4                                      
       IF ( JNT(J)%JTYPE .EQ. I_7 )  M = I_4                                      
       IF ( ABS ( JNT(J)%JTYPE ) .EQ. I_4 )  THEN                           
        IF ( IEULER(J) .EQ. I_1 )    M = I_2                                
        IF ( IEULER(J) .EQ. I_2 )    M = I_3                               
        IF ( IEULER(J) .EQ. I_3 )    M = I_1                                 
        IF ( IEULER(J) .EQ. I_4 )    M = I_4                               
        IF ( IEULER(J) .EQ. I_5 )    M = I_4                            
        IF ( IEULER(J) .EQ. I_6 )    M = I_4                             
       END IF
!C
       IF ( M .EQ. I_0 )  CYCLE                                       
       IF ( M .EQ. I_4 )  THEN                                     
        H1 = JNT(J)%PROX_HB                                            
        H2 = JNT(J)%DSTL_HB                                             
       ELSE IF ( M .NE. I_3 )  THEN                                     
        DO  I = 1,3                                                        
         H1(I) = HIR(I,M,2*J+MAXJNT-1)                                    
         H2(I) = HIR(I,M+1,2*J+MAXJNT)                                     
        END DO
       ELSE
        CALL EJOINT ( -I_1, J )                                            
        CALL CROSS ( HIR(1,2,2*J+MAXJNT-1), HIR(1,1,2*J+MAXJNT-1), T1 )      
        DO  I = 1,3                                                        
         H1(I) =    JNT(J)%COS_NUTA * HIR(I,1,2*J+MAXJNT-1)
     &            + JNT(J)%SIN_NUTA * T1(I)   
         H2(I) = HIR(I,3,2*J+MAXJNT)                                      
        END DO
       END IF                                                       
!C                                                                      
!C     **  Adjust dc matrix for constrained joints  **                   
!C                                                                      
       CALL DOT31 ( SEG(K)%DIR_COS, H1, T1 )                               
       CALL MAT31 ( SEG(J+1)%DIR_COS, T1, T2 )                          
       CT = T2(1) * H2(1) + T2(2) * H2(2) + T2(3) * H2(3)                   
       IF ( M .LT. I_3 )  THEN                                          
        ST = D_1 / SQRT ( ( D_1 - CT ) * ( D_1 + CT ) )                    
        DO  I = 1,3                                                        
        T2(I) = ( H2(I) - CT * T2(I) ) * ST                                
        END DO
        CT = D_1 / ST                                                    
       END IF
       CALL CROSS ( H2, T2, T3 )                                           
       DO  L=1,3                                                            
        CALL CROSS ( T3, SEG(J+1)%DIR_COS(1,L), T4 )                            
        ST =   T3(1) * SEG(J+1)%DIR_COS(1,L) 
     &       + T3(2) * SEG(J+1)%DIR_COS(2,L) 
     &       + T3(3) * SEG(J+1)%DIR_COS(3,L)                   
        ST = ST / ( D_1 + CT )                                           
        DO  I=1,3                                                          
         SEG(J+1)%DIR_COS(I,L) = 
     &             CT * SEG(J+1)%DIR_COS(I,L) - T4(I) + ST * T3(I)                  
        END DO
       END DO
!C                                                                      
!C     **  Renormalization of direction cosine matrix by **                
!C     **  averaging matrix and transpose of its inverse **                
!C                                                                       
       DO  ITER= 1,MAX_RENORM                                               
        CALL CFACTT ( SEG(J+1)%DIR_COS, TP, DET )                     
        DO  L = 1,3                                                        
         DO  I = 1,3                                                      
          SEG(J+1)%DIR_COS(I,L) = 
     &          D_HALF * ( SEG(J+1)%DIR_COS(I,L) + TP(L,I) / DET )           
          IF ( ABS ( SEG(J+1)%DIR_COS(I,L) ) .LT. EPS(15) )
     &               SEG(J+1)%DIR_COS(I,L) = D_0     
         END DO
        END DO
        IF ( ABS ( DET - D_1 ) .LT. EPS(6) )  THEN
         CONVERGED = TRUE
         EXIT          
        ELSE
         CONVERGED = FALSE
        END IF
       END DO                                                             
!C
       IF ( .NOT. CONVERGED )  THEN
        WRITE ( LUAOU, 105 )  J, TIME, DET                                     
  105   FORMAT ( '0 DRIFT renormalization did not converge for',          
     &           ' Joint no.', I3, ' TIME =', F10.6, ' DET =', F10.6 )        
       END IF
!C                                                                         
!C     **  Adjust WMEG for constrained joints  **                        
!C                                                                       
       IF ( M .EQ. I_4 )  THEN                                            
!C
!C      If K or J+1 is deformable use indep. coord. criteria for drift    
!C
        FFLG = FALSE                                                   
        DO  I=1,NFBOD                                                     
         IF ( ( IBODN(I) .EQ. K ) .OR. ( IBODN(I) .EQ. ( J + I_1 ) ) )
     &                FFLG = TRUE                                    
        END DO
        IF ( FFLG ) THEN                                                  
         CALL CROSS ( JNT(J)%PROX_HB, WNP(1,2*J-1), T1 )       
         CALL CROSS ( H1,SEG(K)%ANG_VEL, T2 )                       
         T3 = T1 + T2                                       
         CALL DOT31 ( SEG(K)%DIR_COS, T3, T2 )                            
         CALL MAT31 ( SEG(J+1)%DIR_COS, T2, T1 )                         
         CALL CROSS ( JNT(J)%DSTL_HB, WNP(1,2*J), T2 )                   
         T3 = T1 - T2                                
         HXA = ABS ( H2(1) )                                             
         HYA = ABS ( H2(2) )                                              
         HZA = ABS ( H2(3) )                                              
         IF ( ( HXA .GT. HYA ) .AND. ( HXA .GT. HZA ) ) THEN                
          SEG(J+1)%ANG_VEL(2) = ( H2(2) * SEG(J+1)%ANG_VEL(1) + T3(3) ) 
     &                                            / H2(1)    
          SEG(J+1)%ANG_VEL(3) = ( H2(3) * SEG(J+1)%ANG_VEL(1) - T3(2) ) 
     &                                            / H2(1)      
         ELSE IF ( ( HZA .GT. HXA ) .AND. ( HZA .GT. HYA ) ) THEN         
          SEG(J+1)%ANG_VEL(1) = ( H2(1) * SEG(J+1)%ANG_VEL(3) + T3(2) ) 
     &                                            / H2(3)     
          SEG(J+1)%ANG_VEL(2) = ( H2(2) * SEG(J+1)%ANG_VEL(3) - T3(1) ) 
     &                                            / H2(3)     
         ELSE                                                             
          SEG(J+1)%ANG_VEL(1) = ( H2(1) * SEG(J+1)%ANG_VEL(2) - T3(3) )
     &                                           / H2(2)  
          SEG(J+1)%ANG_VEL(3) = ( H2(3) * SEG(J+1)%ANG_VEL(2) + T3(1) ) 
     &                                           / H2(2)      
         END IF                                                           
         CYCLE                                                     
        END IF                                                            
        HW =  DOT_PRODUCT ( H2, SEG(J+1)%ANG_VEL ) 
     &      - DOT_PRODUCT ( H1, SEG(K  )%ANG_VEL )
        CALL DOT31 ( SEG(K)%DIR_COS, SEG(K)%ANG_VEL, T1 )                       
        CALL MAT31 ( SEG(J+1)%DIR_COS, T1, SEG(J+1)%ANG_VEL )                    
        SEG(J+1)%ANG_VEL = SEG(J+1)%ANG_VEL + HW * H2                  
        CYCLE                                                           
!C
       ELSE IF ( M .NE. I_3 )  THEN                                       
        CALL MAT31 ( SEG(J+1)%DIR_COS, T1, T2 )                                    
        CALL CROSS ( T2, H2, H1 )                                            
       ELSE
        CALL DOT31 ( SEG(K)%DIR_COS, HIR(1,2,2*J+MAXJNT-1), T1 )            
        CALL MAT31 ( SEG(J+1)%DIR_COS, T1, H1 )                           
       END IF
!C
       CALL DOT31 ( SEG(K)%DIR_COS, SEG(K)%ANG_VEL, T1 )                       
       CALL MAT31 ( SEG(J+1)%DIR_COS, T1, T2 )                           
       HDIF = T2 - SEG(J+1)%ANG_VEL
       HW = DOT_PRODUCT ( H1, HDIF )
       SEG(J+1)%ANG_VEL = SEG(J+1)%ANG_VEL + HW * H1    
   50 CONTINUE                                                             
!C
      RETURN                                                            
      END                                                                  
