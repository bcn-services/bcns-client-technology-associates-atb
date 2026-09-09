      SUBROUTINE HPTURB_SETUP ( ITER, J1, J2, K0, K1, KNL0, KNL1, KNLN, 
     &                          NH, DHT, DELMAX, SCALE_LCL  )                                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This program was created from Subroutine HPTURB
!C     to improve program flow.  It is called only by 
!C     Subroutine HPTURB.
!C 
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       EPS, UNITL, UNITM,                           ! /CNSNTS/
     &       BD,                                          ! /CNTSRF/
     &       NHRNSS, TIME, NPRT, NPG,                     ! /CONTRL/
     &       HRN_EPSDEL, HRN_MAX_ITR,                     ! /HPTRB/
     &       BB, BAR, IBAR, HTIME, NBLTPH,                ! /HRNESS/ 
     &       NL, NPTPLY, BBDOT, PLOSS,                    ! /HRNESS/
     &       PTLOSS, OLDBB, IJK_HRN, RHS_HRN,             ! /HRN_TEMPVS/
     &       FCE_HRN, C_HRN, T1_HRN, T2_HRN,              ! /HRN_TEMPVS/
     &       T_HRN, E_HRN, R_HRN,                         ! /HRN_TEMPVS/
     &       BLOSS, HLOSS,                                ! equivalenced
     &       SEG,                                         ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, LUAOU, ! parameters
     &       D_0, D_1, D_1000, I_0, I_1, I_2, I_3, I_100  ! parameters
!C
!C    DIR_COS, DRC_PHI, ROT_PHI            ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, IJ_LCL, IQ, IQ1, IQ2, IT, ITER, J, J1, J2,
     &          K, K0, K1, K2, KE, KH, KJ, KH0, KI, KK, KK1, KK2,
     &          KLM, KNL, KNL0, KNL1, KNLK, KNLN, KR, KS, KS1, KS2, 
     &          MJ2, NB, NH, NJ2, NPTS, NTP 
!C
      REAL  ( KIND = IREAL_HIGH )
     &          BK, DELMAX, DHT, PLS, RER, SCALE_LCL, SQRER
!C
      REAL  ( KIND = IREAL_HIGH )  XDY
      EXTERNAL  XDY
!C
      LOGICAL  ( KIND  = LOGICAL_STD )  LAST                 
!C
      INTENT  (    IN )  J1, NH
      INTENT  ( INOUT )  ITER, J2, K0, K1, KNL0, KNL1, KNLN,
     &                   DHT, DELMAX, SCALE_LCL 
!C                                                                         
!C                                                                         
      DO
       NJ2 = 54_INTEGER_STD                                              
       DO  I=1,NJ2                                                         
        DO  J=1,NJ2                                                        
         IJK_HRN(I,J) = I_0                                           
        END DO
       END DO
       KNL0 = KNL1                                                         
       J2   = J1 + NBLTPH(NH) - I_1                                    
       NTP  = I_0                                                    
       IJ_LCL   = I_0                                                
       CALL HBELT ( J1, J2, KNL0, I_1 )                              
       KH0  = I_0                                                    
       KNL0 = KNL1                                                         
       DO  NB=J1,J2                                                        
        IF  ( NPTPLY(NB) .LE. I_0 )  CYCLE                            
        NPTS = NPTPLY(NB)                                                  
        CALL HSETC ( NPTS, KH0, KNL0, NTP, IJ_LCL )                        
        KH0 = KH0 + NPTS                                                   
        KNL0 = KNL0 + NPTS                                                 
       END DO                                                              
       KNLN = KNL0                                                         
!C                                                                         
!C     Set up C and IJK_HRN elements for tie-points.                       
!C                                                                         
       KNL0 = KNL1                                                         
       KNLK = KNL0 + I_1                                                 
       K1   = KNLK                                                         
       DO  NB=J1,J2                                                    
        IF  ( NPTPLY(NB) .LE. I_0 )  CYCLE                              
        K2   = K1 + NPTPLY(NB) - I_1                                    
        DO  KNL=K1,K2                                                  
         KI   = NL(1,KNL)                                                  
         KS   = ABS ( IBAR(1,KI) )                                        
         IF  ( KS .LT. I_100 )  CYCLE                           
         KS1  = KS / I_100                                    
         DO  K=KNLK,KNL                                                    
          KK   = K                                                         
          KI   = NL(1,K)                                                   
          KS   = ABS ( IBAR(1,KI) )                                        
          IF  ( KS .LT. I_100 )  CYCLE                         
          KS2  = KS / I_100                                   
          IF  ( KS2 .EQ. KS1 )  EXIT                                       
         END DO                                                            
         IF  ( KK .EQ. KNL )  CYCLE                                        
         KK1 = KK  - KNL0                                                  
         KK2 = KNL - KNL0                                                  
         IQ1 = MAX ( 1, ( KK2 - I_1 ) )                               
         IQ2 = MIN ( ( KK2 + I_1 ), KH0 )                       
         DO  IQ=IQ1,IQ2                                                    
          IF  ( IJK_HRN(KK2,IQ) .EQ. I_0 )  CYCLE                      
          IJK_HRN(KK1,IQ) = IJK_HRN(KK2,IQ)                                
          IJK_HRN(KK2,IQ) = I_0                                       
         END DO                                                            
         IJK_HRN(KK2,KK2) = IJ_LCL + I_1                                 
         IJK_HRN(KK2,KK1) = IJ_LCL + I_2                                
         DO  J=1,3                                                         
          DO  I=1,3                                                       
           C_HRN(I,J,IJ_LCL+1) =  D_0                                   
           C_HRN(I,J,IJ_LCL+2) =  D_0                                  
          END DO
          C_HRN(J,J,IJ_LCL+1) =  D_1                                       
          C_HRN(J,J,IJ_LCL+2) = -D_1                                       
         END DO
         IJ_LCL   = IJ_LCL + I_2                                         
        END DO                                                           
        K1   = K2 + I_1                                                  
       END DO                                                            
!C
       MJ2 = -( KH0 + NTP )                                                
       IF  ( NPRT(28) .GE. I_3 )   THEN                                
        NJ2 = -MJ2                                                         
        DO  J=1,NJ2                                                        
         WRITE  ( LUAOU, 105 )  J, ( RHS_HRN(I,J), I=1,3 ),
     &                        ( IJK_HRN(J,I), I=1,NJ2 )                    
  105    FORMAT ( I6, 3F12.6, 20I4, /, ( 42X, 20I4 ) )                     
        END DO
        DO  KLM=1,IJ_LCL                                                   
         WRITE  ( LUAOU, 110 )  KLM, 
     &                         ( ( C_HRN(J,I,KLM), I=1,3 ), J=1,3 )  
  110    FORMAT ( I6, 9F12.6 )                                             
        END DO
       END IF
       CALL FSMSOL ( C_HRN, RHS_HRN, IJK_HRN, MJ2, 
     &               IJ_LCL, 54_INTEGER_STD, 200_INTEGER_STD )       
       IF  ( NPRT(28) .GE. I_3 )  THEN                                 
        DO  J=1,NJ2                                                        
         WRITE  ( LUAOU, 105 )  J, ( RHS_HRN(I,J) ,I=1,3 ),
     &                            ( IJK_HRN(J,I), I=1,NJ2 )             
        END DO
       END IF
       DELMAX = D_0                                                    
       SCALE_LCL = D_1                                                     
       DO  44  IT=1,2                                                     
        K1 = K0                                                            
        KH = I_0                                                            
        KR = NTP                                                          
        DO  43  NB=J1,J2                                                   
         IF  ( NPTPLY(NB) .LE. I_0 )  CYCLE                                   
         K2 = K1 + NPTPLY(NB) - I_1                                           
         DO  42  K=K1,K2                                                   
          KH = KH + I_1                                                        
          KR = KR + I_1                                                        
!C                                                                       
!C        Here K is index of all points in play                             
!C            KH is index of all points in play on a single harness          
!C            KR is index of RHS_HRN array elements                        
!C                                                                        
          KI = NL(1,K)                                                       
          KS   = ABS ( IBAR(1,KI) )                                        
          IF  ( KS .GT. I_100 )  
     &          KS = MOD ( KS, I_100 )               
          IF  ( IBAR(5,KI) .NE. I_0 )   THEN                           
           CALL MAT31 ( SEG(KS)%DIR_COS, RHS_HRN(1,KR), R_HRN )                   
          ELSE                                                       
!C                                                                         
!C         Note: endpoints (K = K1 & K2) must be type 5.                   
!C                                                                        
           CALL DOT31 ( E_HRN(1,1,KH), RHS_HRN(1,KR), T1_HRN )               
           IF  ( IT .EQ. I_2 )  THEN                                          
            BB(K  ) = BB(K  ) + SCALE_LCL * T1_HRN(2)                      
            BB(K-1) = BB(K-1) - SCALE_LCL * T1_HRN(2)                       
           ELSE
            DELMAX = MAX ( DELMAX, ABS ( T1_HRN(2) / 
     &                             MIN ( BB(K), BB(K-1) ) ) )                
           END IF
           DO  J=1,3                                                        
            T2_HRN(J) =   T1_HRN(1) * E_HRN(J,1,KH) 
     &                  + T1_HRN(3) * E_HRN(J,3,KH)                         
           END DO
           CALL MAT31 ( SEG(KS)%DIR_COS, T2_HRN, R_HRN )                          
           IF  ( NPRT(28) .GE. I_3 )   THEN  
            WRITE ( LUAOU, 115 ) K, T1_HRN, T2_HRN, R_HRN                  
  115       FORMAT ( '0', I6, 3( 3X, 3F12.6 ) )                             
           END IF
          END IF
!C
          IF  ( IT .EQ. I_2 )  THEN                                           
           DO  J=1,3                                                       
            BAR(J+3,KI) = BAR(J+3,KI) + SCALE_LCL * R_HRN(J)              
           END DO
           KE = IBAR(2,KI)                                                
           IF  ( KE .EQ. I_0 )  CYCLE                                    
           RER = XDY ( BAR(4,KI), BD(7,KE), BAR(4,KI) )                    
           IF  ( RER .LE. D_1 ) CYCLE                                 
           SQRER = D_1 / SQRT ( RER )                                       
           DO  J=1,3                                                        
            BAR(J+3,KI) = SQRER * BAR(J+3,KI)                               
           END DO
          ELSE
           DO  J=1,3                                                     
            DELMAX = MAX ( DELMAX, ABS ( R_HRN(J) /
     &               MAX ( EPS(1), ABS ( BAR(J+3,KI) ) ) ) )      
           END DO
          END IF
   42    CONTINUE                                                           
         K1 = K2 + I_1                                                      
   43   CONTINUE                                                         
        IF  ( IT .NE. I_2 )  THEN                                          
         IF  ( DELMAX .NE. D_0 )  THEN  
          SCALE_LCL = MIN ( D_1, ( EPS(1) / DELMAX ) )                        
         END IF
        END IF
   44  CONTINUE
! C
       IF  ( NPRT(28) .GE. I_2 )  THEN
        WRITE  ( LUAOU, 120 )  ITER, DELMAX, SCALE_LCL                      
  120   FORMAT ( '0  ITER =', I6, '  DELMAX =', F15.6,
     &           '  SCALE_LCL =', F15.6 )                                  
       END IF
       LAST = ( DELMAX .LE. HRN_EPSDEL ) .OR. ( ITER .EQ. HRN_MAX_ITR )             
       IF  ( LAST )   THEN                                      
        KH = I_0                                                       
        K1 = K0                                                            
        HLOSS(1,NH) = D_0                                               
        HLOSS(2,NH) = D_0                                             
        DO  NB=J1,J2                                                   
         BLOSS(1,NB) = D_0                                             
         BLOSS(2,NB) = D_0                                               
         IF  ( NPTPLY(NB) .LE. I_0 )  CYCLE                             
         K2 = K1 + NPTPLY(NB) - I_1                                     
         KK1 = NL(1,K1)                                                    
         KK2 = NL(1,K2)                                                  
         DO  K=KK1,KK2                                                     
          DO  J=1,3                                                        
           BAR(J+12,K) = D_0                                             
          END DO
         END DO
         IF  ( DHT .NE. D_0 ) THEN                                    
          DO  K=K1,K2                                                     
           KH = KH + I_1                                               
           KI = NL(1,K)                                                    
           PLOSS(2,KI ) = PLOSS(2,KI ) + DHT * PTLOSS(2,KH)                
           IF  ( K .NE. K1 )  THEN                                         
            BBDOT(K-1) = ( BB(K-1) - OLDBB(K-1) ) / DHT                   
            PLOSS(1,K-1) = PLOSS(1,K-1) + DHT * PTLOSS(1,KH-1)             
            BLOSS(1,NB) = BLOSS(1,NB) + PLOSS(1,K-1)                       
           END IF
           DO  J=1,3                                                       
            BAR(J+12,KI) = ( BAR(J+3,KI) - BAR(J,KI) ) / DHT               
           END DO
          END DO
          BBDOT(K2) = D_0                                                
          PLOSS(1,K2) = D_0                                             
         END IF
         K1 = K2 + I_1                                                    
         DO  K=KK1,KK2                                                     
          BLOSS(2,NB) = BLOSS(2,NB) + PLOSS(2,K)                           
         END DO
         HLOSS(1,NH) = HLOSS(1,NH) + BLOSS(1,NB)                           
         HLOSS(2,NH) = HLOSS(2,NH) + BLOSS(2,NB)                          
        END DO                                                          
       END IF
       IF  ( NPRT(28) .EQ. I_0 )  THEN
        ITER = ITER + I_1                                                 
        IF  ( LAST )  THEN
         EXIT                                        
        ELSE
         CYCLE
        END IF                              
       END IF
       IF  ( ( .NOT. LAST ) .AND. 
     &       ( ABS ( NPRT(28) ) .EQ. I_1 ) )  THEN
        ITER = ITER + I_1                                                 
        CYCLE                                        
       END IF
       K1 = K0                                                             
       KH = I_0                                                       
       DO   NB=J1,J2                                                    
        IF  ( NPTPLY(NB) .LE. I_0 )  CYCLE                              
        WRITE ( LUAOU, 125 )  NB,NH                                         
  125   FORMAT ( '0  Belt No.', I4, ' OF Harness No.', I4 )                
        K2 = K1 + NPTPLY(NB) - I_1                                      
        DO  K=K1,K2                                                        
         KH = KH + I_1                                                 
         KI = NL(1,K)                                                      
         KS = IBAR(1,KI)                                                  
         BK = D_0                                                      
         IF  ( K .NE. K1 )  BK = BB(K-1)                                   
         PLS = D_0                                                    
         IF  ( K .NE. K1 )   PLS = PLOSS(1,K-1)                            
         T_HRN(1) = BAR(4,KI)                                              
         T_HRN(2) = BAR(5,KI)                                              
         T_HRN(3) = BAR(6,KI)                                              
         KJ = MOD ( ABS ( KS ), I_100 )                         
         IF  ( SEG(KJ)%ROT_PHI  ) 
     &         CALL DOT31 ( SEG(KJ)%DRC_PHI, BAR(4,KI), T_HRN )        
         WRITE ( LUAOU, 130 )  K, KI, KS, BK, PLS, ( T_HRN(J), J=1,3 ),     
     &                   ( FCE_HRN(J,KH), J=1,3 ), PLOSS(2,KI)            
  130    FORMAT ( 3I8, F10.3, F12.3, 2X, 3F9.3, 3X, 3F11.3, 3X, F12.3 )    
        END DO
        IF  ( LAST )  WRITE ( LUAOU, 135 )  BLOSS(1,NB), BLOSS(2,NB)        
  135   FORMAT ( '0    Total Belt Energy Loss', 7X, F12.3, 68X, F12.3 )    
        K1 = K2 + I_1                                                    
       END DO                                                            
       IF  ( LAST )  WRITE ( LUAOU, 140 )  HLOSS(1,NH), HLOSS(2,NH)         
  140  FORMAT ( '0 Total Harness Energy Loss', 7X, F12.3, 68X, F12.3 )     
       ITER = ITER + I_1                                                 
       IF  ( LAST )  EXIT                                        
      END DO
!C
      RETURN
      END 