      SUBROUTINE HSETC ( NPTS, KH0, KNL0, NTP, IJ_LCL )                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &        NL, BAR, BB, IBAR,                  ! /HRNESS/
     &        NTAB, TAB,                          ! /TABLES/
     &        EDOT, IJK_HRN, PTLOSS, RHS_HRN,     ! /HRN_TEMPVS/
     &        TR_HRN, FR_HRN, FB_HRN, FP_HRN,     ! /HRN_TEMPVS/
     &        BL_HRN, R_HRN, T_HRN,               ! /HRN_TEMPVS/
     &        S_HRN, E_HRN, B_HRN, U_HRN,         ! /HRN_TEMPVS/
     &        BLOSS, HLOSS, C_HRN,                ! /HRN_TEMPVS/
     &        SEG,                                ! structures
     &        INTEGER_STD, IREAL_HIGH,            ! parameters
     &        D_0, D_1, I_0, I_1, I_3, I_100      ! parameters
!C
!C    SEG%DIR_COS
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, IJ_LCL, J, K, K1, K2, KH, KH0, KI, 
     &           KIM, KK, KM, KNL, KNL0, KS, L, M, 
     &           MK, NFD, NFDZ, NFR, NPTS, NTP
      DIMENSION  KM(3), MK(2)                                              
!C
      REAL  ( KIND = IREAL_HIGH )
     &            C1_LCL, C2, CNORM, ELOSS, ERDOT, FB1, FB2, FB3, 
     &            FD, FDP, FR3, PDOT, PEN, RER, RER2, RH, 
     &            RMAG, RMAG2, RRDOT, SGN, SGNB3
!C
      KNL = KNL0                                                           
      KH = KH0                                                             
      K1 = KH0 + NTP + I_1                                              
      K2 = KH0 + NTP + NPTS                                                
      DO  60  K=K1,K2                                                      
!C                                                                         
!C     Here K   is index of IJK_HRN and RHS_HRN arrays                      
!C          KH  is index of points in play on each harness                  
!C          KNL is index of all points in play                              
!C          KI  is index of all points                                      
!C                                                                          
       KH = KH + I_1                                                      
       KNL = KNL + I_1                                                    
!C                                                                          
!C     Zero C_HRN(K,K) , C_HRN(K,K-1) , C_HRN(K,K+1) & RHS_HRN(K); 
!C      Set IJK_HRN(K,K) = IJ_LCL                                           
!C                                                                         
       KM(1) = K + I_1                                                   
       KM(2) = K - I_1                                                   
       KM(3) = K                                                            
       IF  ( K .EQ. K2 )  KM(1) = I_0                                    
       IF  ( K .EQ. K1 )  KM(2) = I_0                                   
       KK = IJ_LCL                                                          
       DO  L=1,3                                                            
        RHS_HRN(L,K) = D_0                                                
        IF  ( KM(L) .EQ. I_0 )  CYCLE                                   
        KK = KK + I_1                                                    
        DO  I=1,3                                                           
         DO  J=1,3                                                          
          C_HRN(I,J,KK) = D_0                                           
         END DO
        END DO 
       END DO                                                               
       IJ_LCL = IJ_LCL + I_1                                            
       IJK_HRN(K,K  ) = IJ_LCL                                              
!C                                                                         
!C     Compute CNORM; if zero, set C_HRN(K,K) = I                           
!C                                                                         
       CNORM = D_0                                                       
       IF  ( K .NE. K2 )  CNORM = FB_HRN(KH) / BL_HRN(KH)                   
       IF  ( K .NE. K1 )  CNORM = CNORM + FB_HRN(KH-1) / BL_HRN(KH-1)       
       KI = NL(1,KNL)                                                       
       IF  ( ABS ( IBAR(1,KI) ) .LE. I_100 )  THEN               
!C
!C      If  (CNORM.NE.0.0)  skip                                          
!C
        KK = IJK_HRN(K,K)                                                   
        DO  I=1,3                                                           
         C_HRN(I,I,KK) = D_1                                                
        END DO
        IF ( CNORM .EQ. D_0 )  CYCLE                                
       END IF
       KK = IBAR(3,KI)                                                      
       NFD = NTAB(KK+1)                                                     
       NFR = NTAB(KK+5)                                                     
!C                                                                          
!C     Set up B(3,3,3) and S_HRN(3,3)                                       
!C                                                                          
       MK(1) = KH                                                           
       MK(2) = KH - I_1                                                 
       IF  ( K .EQ. K2 )  MK(1) = I_0                                
       IF  ( K .EQ. K1 )  MK(2) = I_0                                
       DO  M=1,2                                                            
        KK = MK(M)                                                          
        IF  ( ( KK .NE. I_0 ) .AND. ( CNORM .NE. D_0 ) )   THEN            
         CALL DOT31 ( E_HRN(1,1,KH), U_HRN(1,KK), T_HRN )                   
         KIM = KNL + I_1 - M                                            
         FB1 = FB_HRN(KK) / BL_HRN(KK)                                      
         FB2 = FP_HRN(KK) / BB(KIM) - FB1                                   
         FB3 = FP_HRN(KK) * BL_HRN(KK) / BB(KIM)**2                         
         DO  I=1,3                                                          
          SGN = D_1                                                         
          IF  ( FR_HRN(I,KH) .LT. D_0 )  SGN = -D_1                   
          S_HRN(I,M) = SGN * ( FB3 * T_HRN(I) )                             
          DO  J=1,3                                                         
           B_HRN(I,J,M) = SGN * (   FB1 * E_HRN(J,I,KH) 
     &                            + FB2 * T_HRN(I) * U_HRN(J,KK) )          
          END DO
         END DO
        ELSE
         DO  I=1,3                                                          
          S_HRN(I,M) = D_0                                               
          DO  J=1,3                                                         
           B_HRN(I,J,M) = D_0                                           
          END DO
         END DO
        END IF
       END DO                                                               
!C
       DO  I=1,3                                                            
        S_HRN(I,3) = -( S_HRN(I,1) + S_HRN(I,2) )                           
        DO  J=1,3                                                           
         B_HRN(I,J,3) = -( B_HRN(I,J,1) + B_HRN(I,J,2) )                    
        END DO
       END DO
       IF  ( NFR .NE. I_0 )    THEN                                     
        R_HRN(1) = TAB(NFR+2)                                               
        R_HRN(2) = TAB(NFR+4)                                               
       END IF
       R_HRN(3) = D_0                                                   
!C
       DO  50  M=1,3                                                        
        RH = D_0                                                         
        IF  ( M .NE. I_3 )  THEN                                 
!C                                                                           
!C       Constraints 1 and 2                                                  
!C                                                                           
         IF  ( NFR .EQ. I_0 )  THEN
          IF  ( IBAR(1,KI) .GT. I_0 )   THEN                                
           KK = IJK_HRN(K,K)                                                   
           DO  I=1,3                                                           
            DO  J=1,3                                                          
             C_HRN(I,J,KK) = C_HRN(I,J,KK) + 
     &                       E_HRN(I,M,KH) * E_HRN(J,M,KH)     
            END DO
           END DO
          END IF
          CYCLE                                 
         END IF
!C
         SGN   = -D_1                                                         
         FR3   = ABS ( FR_HRN(M,KH) ) - R_HRN(M) * ABS ( FR_HRN(3,KH) )       
         IF  ( IBAR(1,KI) .GT. I_0 )  RH = FR3                            
         IF  ( FR3 .LE. D_0 )  THEN
          IF  ( IBAR(1,KI) .GT. I_0 )   THEN                                
           KK = IJK_HRN(K,K)                                                   
           DO  I=1,3                                                           
            DO  J=1,3                                                          
             C_HRN(I,J,KK) = C_HRN(I,J,KK) + 
     &                       E_HRN(I,M,KH) * E_HRN(J,M,KH)     
            END DO
           END DO
          END IF
         ELSE
          CALL HSETC_SUB ( IJ_LCL, K, KH, KI, KM, KNL, M, RH, SGN )
         END IF
         CYCLE
        END IF
!C                                                                           
!C      Constraint no. 3                                                     
!C                                                                           
        IF  ( NFD .EQ. I_0 )  THEN
         IF  ( IBAR(1,KI) .GT. I_0 )   THEN                                
          KK = IJK_HRN(K,K)                                                   
          DO  I=1,3                                                           
           DO  J=1,3                                                          
            C_HRN(I,J,KK) = C_HRN(I,J,KK) + 
     &                      E_HRN(I,M,KH) * E_HRN(J,M,KH)     
           END DO
          END DO
         END IF
         CYCLE
        END IF
!C
        IF  ( IBAR(1,KI) .GE. I_0 )  THEN                           
         SGN   = D_1                                                          
         RMAG2 = TR_HRN(1,KH)**2 + TR_HRN(2,KH)**2 + TR_HRN(3,KH)**2          
         RMAG  = SQRT ( RMAG2 )                                               
         RER2  =   TR_HRN(1,KH) * E_HRN(1,3,KH)
     &           + TR_HRN(2,KH) * E_HRN(2,3,KH) 
     &           + TR_HRN(3,KH) * E_HRN(3,3,KH)                               
         RER2  = EDOT(3,KH) * RER2                                            
         RER   = SQRT ( RER2 )                                                
         PEN   = RMAG / RER - RMAG                                            
         RRDOT =   BAR(4,KI) * BAR(13,KI)                                     
     &           + BAR(5,KI) * BAR(14,KI)                                     
     &           + BAR(6,KI) * BAR(15,KI)                                     
         KS = ABS ( IBAR(1,KI) )                                              
         IF  ( KS .GT. I_100 )  KS = MOD ( KS, I_100 )               
         CALL DOT31 ( SEG(KS)%DIR_COS, BAR(13,KI), T_HRN )                   
         ERDOT =   E_HRN(1,3,KH) * T_HRN(1)
     &           + E_HRN(2,3,KH) * T_HRN(2)
     &           + E_HRN(3,3,KH) * T_HRN(3)                                   
         C1_LCL    = PEN / RMAG2                                              
         C2    = RMAG * EDOT(3,KH) / ( RER * RER2 )                           
         PDOT  = C1_LCL * RRDOT - C2 * ERDOT                                  
         NFDZ = IBAR(3,KI)                                                   
         CALL FRCDFL ( PEN, PDOT, NFDZ, I_0, FDP, ELOSS )                 
         CALL FRCDFL ( PEN, PDOT, NFDZ, I_1, FD , ELOSS )                
         RH    = FD + FR_HRN(3,KH)                                            
         PTLOSS(2,KH) = ELOSS                                                 
         C1_LCL    = FDP * C1_LCL                                             
         C2        = FDP * C2                                                 
         SGNB3 = -SIGN ( D_1, FR_HRN(3,KH) )                                  
         DO  J=1,3                                                            
          B_HRN(3,J,3) =   SGNB3 * B_HRN(3,J,3) - C1_LCL * TR_HRN(J,KH)
     &                   + C2 * E_HRN(J,3,KH)                                 
         END DO
        END IF
!C
        CALL HSETC_SUB ( IJ_LCL, K, KH, KI, KM, KNL, M, RH, SGN )
  50   CONTINUE                                                             
  60  CONTINUE                                                             
!C
      RETURN                                                               
      END                                                                  
