      SUBROUTINE PLELP ( M, MM, N, NN_LCL, NT )                            
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       BD, PL,                                    ! /CNTSRF/
     &       CFQQ, RQQ, SQQ,                            ! /CSTRNT/
     &       PSF, NPSF,                                 ! /FORCES/
     &       NTAB, TAB,                                 ! /TABLES/
     &       AMR_PLP, DMNT_PLP, DMNWN_PLP,              ! /PLELP_TEMPVS/
     &       FM_PLP, MCF_PLP, NCF_PLP, PEN_DIST,           ! /PLELP_TEMPVS/
     &       R_PLP, RLM_PLP, RLN_PLP, RM_PLP, RMD_PLP,  ! /PLELP_TEMPVS/ 
     &       RN_PLP, RND_PLP, T_PLP, TH_PLP, TF_PLP,    ! /PLELP_TEMPVS/
     &       TM_PLP, WNM_PLP, VR_PLP,                   ! /PLELP_TEMPVS/
     &       XH_PLP, XMM_PLP, XMN_PLP, XNC_PLP,         ! /PLELP_TEMPVS/
     &       SEG,                                       ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,      ! parameters
     &       D_0, D_1, D_2, D_3,                        ! parameters
     &       I_0, I_1, I_2, I_3, I_4                    ! parameters
!C
!C    DIR_COS, DRC_PHI, LIN_DISP, ROT_PHI          ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, LT, M, MM, N, NN_LCL, NT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ALP, BET_LCL, BETE, BTE_LCL, BTS, DIST, 
     &                  POW, RHO, TD_LCL, TRT, UH_LCL
      DIMENSION         TD_LCL(3), UH_LCL(3)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  AREAL       
!C
      REAL  ( KIND = IREAL_HIGH )   HYPEN
      EXTERNAL          HYPEN
!C
      CALL ELTIME ( I_1, 21_INTEGER_STD )                                               
      CALL DOTT33 ( SEG(M)%DIR_COS, SEG(N)%DIR_COS, DMNT_PLP )           
      XMN_PLP = SEG(M)%LIN_DISP - SEG(N)%LIN_DISP              
      CALL MAT31 ( SEG(M)%DIR_COS, XMN_PLP, XMM_PLP )                     
      CALL MAT31 ( DMNT_PLP, PL(1,NN_LCL), TM_PLP )                        
      CALL MAT31 ( DMNT_PLP, PL(5,NN_LCL), TD_LCL )                         
      BET_LCL = D_0                                                      
      J = I_3                                                         
      IF ( BD(1,MM) .LT. D_0 )  J = I_4                               
      DO  I=1,3                                                             
       J = J + I_1                                                     
       XNC_PLP(I) = XMM_PLP(I) + BD(J,MM) - TD_LCL(I)                      
       BET_LCL = BET_LCL - TM_PLP(I) * XNC_PLP(I)                           
      END DO
!C                                                                          
!C    BET is from center of figure to plane.                                 
!C
      IF ( BD(1,MM) .LE. D_0 )  THEN                                     
!C
!C     Put plane vector into HYPER                                         
!C
       CALL MAT31 ( BD(8,MM), TM_PLP, TH_PLP )                             
       CALL MAT31 ( BD(8,MM), XNC_PLP, UH_LCL )                            
       DO  I = 1,3                                                         
        XNC_PLP(I) = UH_LCL(I)                                             
        UH_LCL(I) = ABS ( TH_PLP(I) ) * BD(I+1,MM) / BD(I+19,MM)           
        R_PLP(I)  = BD(I+19,MM) / ( BD(I+19,MM) - D_1 )                
        RND_PLP(I)= UH_LCL(I)**R_PLP(I)                                    
       END DO
       ALP = HYPEN ( R_PLP, RND_PLP )                                   
       DO  I = 1,3                                                         
        POW = D_1 / ( BD(I+19,MM) - D_1 )                             
        XH_PLP(I) = -SIGN ( BD(I+1,MM) *
     &                       ( UH_LCL(I) * ALP )**POW, TH_PLP(I) )         
        RND_PLP(I) = XH_PLP(I)                                             
       END DO
       BTE_LCL = DOT_PRODUCT ( TH_PLP, XH_PLP )
       FM_PLP = BET_LCL / BTE_LCL                                          
       AMR_PLP = D_1 - ABS ( FM_PLP )**( -BD(1,MM) )                    
      ELSE                                                                 
!C
!C     Code for ellipse        XH_PLP = E'T                                 
!C                                                                          
       CALL MAT31 ( BD(16,MM), TM_PLP, XH_PLP )                            
       BTS = DOT_PRODUCT ( TM_PLP, XH_PLP )
       BTE_LCL = - SQRT ( BTS )                                            
       FM_PLP = BET_LCL / BTS                                               
       AMR_PLP = D_1 - BET_LCL * FM_PLP                                   
      END IF
!C                                                                          
!C    Compute penetration distance.
!C
      PEN_DIST = BET_LCL - BTE_LCL                                            
      PSF(1,NPSF) = PEN_DIST                                                  
      MCF_PLP = NTAB(NT+1)                                                 
      NCF_PLP = -MCF_PLP                                                   
      IF ( NCF_PLP .GT. I_0 )  CFQQ(NCF_PLP) = -999.0E0_IREAL_HIGH     
!C
!C    If no penetration, i.e. penetration is 0 or negative, exit the
!C     subroutine.
!C
      IF ( PEN_DIST .LE. D_0 )  THEN                                       
       CALL ELTIME ( I_2, 21_INTEGER_STD )                                               
       RETURN                                                              
      END IF
!C                                                                          
!C    Call edge routine to find if ellipsoid intersects finite plane        
!C    if it does; AREAL will be true, P will be penetration at centroid     
!C    and RM will be location of centroid                                   
!C    RM is referenced to center of ellipsoid                               
!C    use old formula for roll-slide?, i.e. roll-slide shouldn't            
!C    call PLEDG                                                            
!C                                                                          
      LT = NTAB(NT)                                                         
      IF  ( TAB(LT+22) .GT. D_0 )  THEN                                 
!C                                                                          
       IF  ( AMR_PLP .LE. D_0 )  THEN                                
        CALL ELTIME ( I_2, 21_INTEGER_STD )                                              
        RETURN                                                             
       END IF
!C
       IF ( ( BD(1,MM) .LT. D_0 ) .AND. ( BD(23,MM) .NE. D_0 ) ) THEN
        STOP 22                                                            
       END IF
       CALL PLEDG ( AREAL, BD(1,MM), PL(1,NN_LCL) )                         
       IF  ( .NOT. AREAL )  THEN                                           
        CALL ELTIME ( I_2, 21_INTEGER_STD )                                              
        RETURN                                                             
       END IF
       PSF(1,NPSF) = PEN_DIST                                                  
      END IF
!C                                                                          
      IF ( ( TAB(LT+22) .GT. -D_2 ) .AND. ( AMR_PLP .LE. D_0 ) )  THEN    
       CALL ELTIME ( I_2, 21_INTEGER_STD )                                               
       RETURN                                                              
      END IF
      RHO = D_0                                                         
      IF  ( MCF_PLP .GT. I_0 )  RHO = TAB(MCF_PLP+4)                  
      BETE =  D_1 + RHO * PEN_DIST / BTE_LCL                               
      IF  ( BD(1,MM) .GT. D_0 )  THEN
       BETE = BETE / BTE_LCL                                               
      ELSE IF ( BD(1,MM) .LT. D_0 )  THEN     
       CALL DOT31 ( BD(8,MM), RND_PLP, XH_PLP )                            
      END IF
      TRT = PEN_DIST * ( D_1 - RHO )                                           
      J = I_3                                                         
!C
      IF ( BD(1,MM) .LT. D_0 )  J = I_4                                
      DO  I = 1,3                                                          
       J = J + I_1                                                      
       IF ( TAB(LT+22) .LE. D_0 )  THEN  
        RM_PLP(I) = BETE * XH_PLP(I)                                        
       ELSE
        RM_PLP(I) = RM_PLP(I) - TRT * TM_PLP(I)                             
       END IF
       RLM_PLP(I) = RM_PLP(I)  + BD(J,MM)                                  
       RN_PLP(I)  = RLM_PLP(I) + XMM_PLP(I)                                
      END DO
      CALL DOT31 ( DMNT_PLP, RN_PLP, RLN_PLP )                             
      IF ( ( TAB(LT+22) .EQ. D_0   ) .OR. 
     &     ( TAB(LT+22) .LE. -D_3 ) )  THEN
!C                                                                          
!C     Check boundary using old method                                      
!C
       DO  I = 8,13,5                                                      
        IF ( PL(I+4,NN_LCL) .LE. D_0 )   CYCLE                     
        DIST =   RLN_PLP(1) * PL(I  ,NN_LCL)                               
     &         + RLN_PLP(2) * PL(I+1,NN_LCL)                               
     &         + RLN_PLP(3) * PL(I+2,NN_LCL) - PL(I+3,NN_LCL)              
        IF ( ( DIST .LE. D_0 ) .OR. 
     &       ( DIST .GT. PL(I+4,NN_LCL) ) ) THEN
         CALL ELTIME ( I_2, 21_INTEGER_STD )                                             
         RETURN                                                            
        END IF
       END DO                                                              
      END IF
!C                                                                          
      CALL PLSEGF ( M, N, NT )                                             
!C
!C    DMNWN_PLP, VMN, VR_PLP, WNM_PLP, WCM, WCN, VREL, FFM, FR, 
!C    TQM, TQN, TQNT, T, FM_PLP, CF, VRM, VRT, VRTS, 
!C    VRTEST, TF_PLP, ELOSS                            
!C                                                                          
!C    Store results.                                                         
!C
      DO  I = 1,3                                                          
       PSF(I+4,NPSF) = RLN_PLP(I)                                          
      END DO
      IF ( SEG(N)%ROT_PHI )   THEN
       CALL DOT31  ( SEG(N)%DRC_PHI, RLN_PLP, PSF(5,NPSF) )            
      END IF
      IF ( MCF_PLP .GE. I_0 )  THEN                                     
       PSF(2,NPSF) = FM_PLP                                                
       PSF(3,NPSF) = D_0                                        
       TRT = TF_PLP**2 - FM_PLP**2                                         
       IF ( TRT .GT. D_0 )  PSF(3,NPSF) = SQRT ( TRT )             
       PSF(4,NPSF) = TF_PLP                                                
       CALL ELTIME ( I_2, 21_INTEGER_STD )                                               
       RETURN                                                              
      END IF                                                               
!C                                                                         
!C     Roll-slide                                   
!C
      DO  I = 1,3                                                          
       PSF(I+1,NPSF) = T_PLP(I)                                            
      END DO
      IF  ( BD(1,MM) .LT. D_0 )   STOP 28                           
      CALL CROSS ( TM_PLP, WNM_PLP, TH_PLP )                                
      CALL MAT31 ( BD(16,MM), TH_PLP, UH_LCL )                              
      TRT = ( TM_PLP(1) * UH_LCL(1) + TM_PLP(2) * UH_LCL(2)
     &                              + TM_PLP(3) * UH_LCL(3) ) / BTS         
      DO  I = 1,3                                                          
       RMD_PLP(I) = ABS ( BETE ) * ( UH_LCL(I) - TRT * XH_PLP(I) )         
      END DO
      CALL CROSS ( DMNWN_PLP, TM_PLP, TH_PLP )                              
      CALL CROSS ( WNM_PLP, RMD_PLP, XNC_PLP )                              
      SQQ(NCF_PLP) = D_0                                             
      DO  I = 1,3                                                          
       SQQ(NCF_PLP) = SQQ(NCF_PLP) + TM_PLP(I) * XNC_PLP(I) 
     &                       - D_2 * TH_PLP(I) * VR_PLP(I)                
      END DO
      CALL DOT31 ( SEG(M)%DIR_COS, XNC_PLP, RQQ(1,NCF_PLP) )             
C
      CALL ELTIME ( I_2, 21_INTEGER_STD )                                                
C
      RETURN                                                               
      END                                                                  
