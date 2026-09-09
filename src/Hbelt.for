      SUBROUTINE HBELT ( J1, J2, KNL0, IND )                               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Arguments:                                                           
!C        J1,J2 - first and last index for belts.                          
!C         KNL0 - zero value for KNL index.                                
!C         IND  - 0: call is from Subroutine CONTCT                        
!C                1: call is from Subroutine UPDATE                        
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                  ! /CNSNTS/
     &       BD,                                   ! /CNTSRF/
     &       HARNESS_FORCE, NBSF,                  ! /FORCES/
     &       BAR, BB, BBDOT, IBAR, NL, NPTPLY,     ! /HRNESS/
     &       NTAB, TAB,                            ! /TABLES/
     &       T1_HRN, T2_HRN, R_HRN, V_HRN, TR_HRN, ! /HRN_TEMPVS/
     &       ZR_HRN, S_HRN, E_HRN, EDOT, PTLOSS,   ! /HRN_TEMPVS/
     &       U_HRN, BL_HRN, FCE_HRN, FB_HRN,       ! /HRN_TEMPVS/
     &       FP_HRN, FR_HRN, T_HRN,                ! /HRN_TEMPVS/
     &       SEG,                                  ! structures
     &       INTEGER_STD, IREAL_HIGH,              ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_100        ! parameters
!C
!C    ANG_VEL, DIR_COS, EXT_ANG_ACL, EXT_LIN_ACL, LIN_DISP,  ! SEG%
!C    LIN_VEL                                                ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, IND, J, J1, J2, JB, JH, JNL, K, K1, K2, KE, 
     &         KH, KI, KNL, KNL0, KNL1, KNL2, KS, KS1, KS2, MH, 
     &         NF, NT, NTP
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BLDOT, ELOSS, FBK, FPK, FR1, FR2, STRAIN,
     &                  STRDOT, ZRP
      DIMENSION  ZRP(3)                                                 
!C
      CALL ELTIME ( I_1, 38_INTEGER_STD )                                                
!C
      NTP = I_0                                                        
      K2 = I_0                                                         
!C
!C    Do loop for belts.
!C
      DO  JB=J1,J2                                                   
       IF  ( IND .EQ. I_0 )  NBSF = NBSF + I_1                        
       IF  ( NPTPLY(JB) .LE. I_0 )  CYCLE                             
!C                                                                         
!C     First loop on K                                                     
!C     compute Z(K),ZR(K),E3(K),U(K-1),BL(K-1),FB(K-1)                     
!C     Need    NL(K),BB(K-1)                                               
!C     Note: an index K-1 refers to belt segment between K-1 and K.        
!C                                                                         
       K1 = K2 + I_1                                                  
       K2 = K2 + NPTPLY(JB)                                                
       DO  20  K=K1,K2                                                     
        KNL = KNL0 + K                                                     
        KI = NL(1,KNL)                                                     
!C                                                                         
!C      Here K   is index of points in play on each harness                
!C           KNL is index of all points in play                            
!C           KI  is index of all points                                    
!C                                                                         
        KS   = ABS ( IBAR(1,KI) )                                          
        IF  ( KS .GT. I_100 )  THEN  
         NTP = 1                                                           
         KS = MOD ( KS, I_100 )                               
        END IF
        KE = IBAR(2,KI)                                                    
        CALL DOT31 ( SEG(KS)%DIR_COS, BAR(4,KI), T1_HRN )                
        CALL DOT31 ( SEG(KS)%DIR_COS, BAR(7,KI), T2_HRN )                  
        DO  J=1,3                                                          
         R_HRN(J) = V_HRN(J)                                               
         V_HRN(J) = BAR(J+3,KI) + BAR(J+6,KI)                              
         TR_HRN(J,K) = T1_HRN(J)                                           
         ZR_HRN(J,K) = T1_HRN(J) + T2_HRN(J)                               
         S_HRN (J,2) = S_HRN(J,1)                                          
         S_HRN (J,1) = SEG(KS)%LIN_DISP(J) + ZR_HRN(J,K)               
        END DO
        CALL CROSS ( SEG(KS)%ANG_VEL, V_HRN, T_HRN )                  
        IF  ( KE .NE. I_0 )  THEN                                      
         CALL MAT31 ( BD(7,KE), BAR(4,KI), T2_HRN )                        
         CALL DOT31 ( SEG(KS)%DIR_COS, T2_HRN, T1_HRN )              
        END IF
        DO  J=1,3                                                          
         T_HRN(J) = T_HRN(J) + BAR(J+12,KI)                                
         E_HRN(J,3,K) = T1_HRN(J)                                          
        END DO
        CALL DOT31 ( SEG(KS)%DIR_COS, T_HRN, V_HRN )                      
        V_HRN = V_HRN + SEG(KS)%LIN_VEL                             
        FB_HRN(K) = D_0                                                   
        FP_HRN(K) = D_0                                                   
        IF  ( K .EQ. K1 )   CYCLE                                          
        DO  J=1,3                                                          
         U_HRN(J,K-1) = S_HRN(J,1) - S_HRN(J,2)                            
        END DO
        BL_HRN(K-1) = SQRT ( U_HRN(1,K-1)**2 + U_HRN(2,K-1)**2
     &                                       + U_HRN(3,K-1)**2 )           
        DO  J=1,3                                                          
         U_HRN(J,K-1) = U_HRN(J,K-1) / BL_HRN(K-1)                         
        END DO
        STRAIN = ( BL_HRN(K-1) / BB(KNL-1) ) - D_1                        
        IF  ( STRAIN .LT. EPS(12) )   STRAIN = D_0                      
        NT = NL(2,KNL)                                                     
        BLDOT =    U_HRN(1,K-1) * ( V_HRN(1) - R_HRN(1) )                  
     &           + U_HRN(2,K-1) * ( V_HRN(2) - R_HRN(2) )                  
     &           + U_HRN(3,K-1) * ( V_HRN(3) - R_HRN(3) )                  
        STRDOT = ( BB(KNL-1) * BLDOT - BL_HRN(K-1) * BBDOT(KNL-1) ) 
     &                               / BB(KNL-1)**2                        
!C
        CALL FRCDFL ( STRAIN, STRDOT, NT, I_0, FPK, ELOSS )              
        CALL FRCDFL ( STRAIN, STRDOT, NT, I_1,  FBK, ELOSS )              
        PTLOSS(1,K-1) = BB(KNL-1) * ELOSS                                  
        FP_HRN(K-1) = FPK                                                  
        FB_HRN(K-1) = FBK                                                  
        IF  ( IND .EQ. I_0 )   THEN                                     
         IF ( K .EQ. ( K1 + I_1 ) )  THEN                               
          HARNESS_FORCE(1,NBSF) = STRAIN                                       
          HARNESS_FORCE(2,NBSF) = FBK                                   
         END IF
         IF ( K .EQ. K2 )   THEN                                          
          HARNESS_FORCE(3,NBSF) = STRAIN                                  
          HARNESS_FORCE(4,NBSF) = FBK                                    
         END IF
        END IF                                                             
   20  CONTINUE
!C                                                                         
!C     Second loop on K                                                    
!C     Compute FCE(K),E1(K),E2(K),EDOT(K),FR(K),U1(KS),U2(KS)              
!C     Need    FB(K&K-1),U(K&K-1),ZR(K),E3(K)                              
!C                                                                         
       DO  30  K=K1,K2                                                     
        KNL = KNL0 + K                                                     
        KI = NL(1,KNL)                                                     
        KS   = ABS ( IBAR(1,KI) )                                          
        IF  ( KS .GT. I_100 ) 
     &       KS = MOD ( KS, I_100 )            
        DO  J=1,3                                                          
         FCE_HRN(J,K) = D_0                                            
         IF ( K .NE. K2 ) FCE_HRN(J,K) = FB_HRN(K) * U_HRN(J,K)          
         IF ( K .NE. K1 )   THEN  
          FCE_HRN(J,K) = FCE_HRN(J,K) - FB_HRN(K-1) * U_HRN(J,K-1)         
         END IF
        END DO
        NT = IBAR(3,KI)                                                    
        NF = NTAB(NT+5)                                                    
        IF  ( ( NF .EQ. I_0 ) .AND. ( IND .EQ. I_0 ) )   CYCLE      
        IF  ( IBAR(4,KI) .NE. I_0 )  THEN                               
         CALL DOT31 ( SEG(KS)%DIR_COS, BAR(10,KI), T1_HRN )              
        ELSE                                                               
         DO  J=1,3                                                         
          T1_HRN(J) = D_0                                               
          IF  ( K .NE. K2 )  T1_HRN(J) = U_HRN(J,K)                        
          IF  ( K .NE. K1 )  T1_HRN(J) = T1_HRN(J) + U_HRN(J,K-1)          
         END DO
        END IF
        CALL CROSS ( T1_HRN, E_HRN(1,3,K), E_HRN(1,1,K) )                  
        CALL CROSS ( E_HRN(1,3,K), E_HRN(1,1,K), E_HRN(1,2,K) )            
        DO  J=1,3                                                          
         EDOT(J,K) = SQRT (   E_HRN(1,J,K)**2 + E_HRN(2,J,K)**2 
     &                      + E_HRN(3,J,K)**2)                            
         DO  I=1,3                                                         
          E_HRN(I,J,K) = E_HRN(I,J,K) / EDOT(J,K)                          
         END DO
        END DO
        CALL DOT31 ( E_HRN(1,1,K), FCE_HRN(1,K), FR_HRN(1,K) )            
  30   CONTINUE                                                          
      END DO                                                       
!C
      IF  ( NTP .GT. I_0 )  THEN                                       
!C                                                                         
!C     Sum FCE,FR for tie-points                                           
!C                                                                         
       KNL1 = KNL0 + I_2                                               
       KNL2 = KNL0 + K2                                                    
       DO  KNL=KNL1,KNL2                                               
        KI = NL(1,KNL)                                                     
        KS   = ABS ( IBAR(1,KI) )                                          
        IF  ( KS .LT. I_100 )  CYCLE                             
        KS1 = KS / I_100                                         
        KH = KNL - KNL0                                                    
        MH = I_0                                                        
        DO  JNL=KNL1,KNL                                                   
         KI = NL(1,JNL-1)                                                  
         KS   = ABS ( IBAR(1,KI) )                                         
         IF  ( KS .LT. I_100 )  CYCLE                            
         KS2 = KS / I_100                                        
         IF  ( KS2 .NE. KS1 )  CYCLE                                       
         JH = JNL - I_1 - KNL0                                         
         IF  ( MH .EQ. I_0 )  MH = JH                                  
         DO  J=1,3                                                         
          IF  ( MH .EQ. JH )  THEN
           FCE_HRN(J,MH) = FCE_HRN(J,MH) + FCE_HRN(J,KH)                   
          END IF
          FCE_HRN(J,JH) = FCE_HRN(J,MH)                                    
         END DO
         CALL DOT31 ( E_HRN(1,1,JH), FCE_HRN(1,JH), FR_HRN(1,JH) )         
        END DO                                                             
        IF  ( MH .EQ. I_0 )  CYCLE                                    
        KI = NL(1,KNL)                                                     
        IBAR(1,KI) = -ABS ( IBAR(1,KI) )                                   
        DO  J=1,3                                                          
         FCE_HRN(J,KH) = FCE_HRN(J,MH)                                     
        END DO
        CALL DOT31 ( E_HRN(1,1,KH), FCE_HRN(1,KH), FR_HRN(1,KH) )          
       END DO                                                            
      END IF
!C
!C    If call to Subroutine HBELT is from Subroutine HPTURB
!C     ( IND = 1 ) then return at this point.
!C
      IF  ( IND .NE. I_0 )  THEN                                      
       KNL0 = KNL0 + K2                                                    
       CALL ELTIME ( I_2, 38_INTEGER_STD )                                               
       RETURN                                                              
      END IF
!C                                                                         
!C    If call is from Subroutine CONTCT,                                   
!C    add forces (FCE) modified by friction to U1,U2 arrays.               
!C                                                                         
      K2 = I_0                                                          
      DO  50  JB=J1,J2                                                     
       IF  ( NPTPLY(JB) .LE. I_0 )  CYCLE                               
       K1 = K2 + I_1                                                    
       K2 = K2 + NPTPLY(JB)                                                
       DO  60  K=K1,K2                                                     
        KNL = KNL0 + K                                                     
        KI = NL(1,KNL)                                                     
        IF  ( IBAR(1,KI) .LT. I_0 )  CYCLE                             
        KS = IBAR(1,KI)                                                    
        IF  ( KS .GT. I_100 )  THEN
         KS = MOD ( KS, I_100 )            
        END IF
        NT = IBAR(3,KI)                                                    
        NF = NTAB(NT+5)                                                    
        IF  ( NF .NE. I_0 )  THEN                                       
         DO  J=1,3                                                         
          T1_HRN(J) = FR_HRN(J,K)                                          
         END DO
         FR1 = TAB(NF+2) * ABS ( T1_HRN(3) )                               
         FR2 = TAB(NF+4) * ABS ( T1_HRN(3) )                               
         IF  ( ABS ( T1_HRN(1) ) .GT. FR1 )  THEN
          T1_HRN(1) = SIGN ( FR1, T1_HRN(1) )                              
         END IF
         IF  ( ABS ( T1_HRN(2) ) .GT. FR2 )  THEN
          T1_HRN(2) = SIGN ( FR2, T1_HRN(2) )                              
         END IF
         CALL MAT31 ( E_HRN(1,1,K), T1_HRN, FCE_HRN(1,K) )                 
        END IF
        CALL CROSS ( ZR_HRN(1,K), FCE_HRN(1,K), T2_HRN )                   
        CALL MAT31 ( SEG(KS)%DIR_COS, T2_HRN, T1_HRN )                    
        DO  J=1,3                                                          
         SEG(KS)%EXT_LIN_ACL(J) = SEG(KS)%EXT_LIN_ACL(J) + FCE_HRN(J,K)    
         SEG(KS)%EXT_ANG_ACL(J) = SEG(KS)%EXT_ANG_ACL(J) + T1_HRN(J)       
        END DO
!C
!C      Add to the nodal forces for deformable body KS                  
!C
        CALL MAT31 ( SEG(KS)%DIR_COS, ZR_HRN, ZRP )                     
        CALL FXCAHW ( KS, ZRP, FCE_HRN(1,K), D_1 )                     
   60  CONTINUE                                                            
   50 CONTINUE                                                             
      KNL0 = KNL0 + K2                                                     
!C
      CALL ELTIME ( I_2, 38_INTEGER_STD )                                                
!C
      RETURN                                                               
      END                                                                  
