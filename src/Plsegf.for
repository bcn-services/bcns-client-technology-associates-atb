      SUBROUTINE PLSEGF ( M, N, NT )                                      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       TIME,                                    ! /CONTRL/
     &       CFQQ, HQQ, KQTYPE, RK1, RK2, TQQ,        ! /CSTRNT/
     &       NTAB, TAB,                               ! /TABLES/
     &       CREST, R1I, R2I, TTI,                    ! /TEMPVI/
     &       DMNT_PLP, DMNWN_PLP, FM_PLP,             ! /PLELP_TEMPVS/
     &       MCF_PLP, NCF_PLP, PEN_DIST,              ! /PLELP_TEMPVS/
     &       RLM_PLP, RLN_PLP, RN_PLP,                ! /PLELP_TEMPVS/
     &       T_PLP, TF_PLP, TM_PLP, VR_PLP,           ! /PLELP_TEMPVS/
     &       WMN_PLP=>WNM_PLP,                        ! /PLELP_TEMPVS/
     &       SEG,                                     ! structures       
     &       INTEGER_STD, IREAL_HIGH,                 ! parameters
     &       I_0, I_1, I_3, I_6, I_18, D_0, D_1, D_2, ! parameters
     &       ludebug
!C
!C    ANG_VEL, DIR_COS, EXT_ANG_ACL, EXT_LIN_ACL, LIN_VEL  ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, L, LT, M, MT, N, NT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  CF, ELOSS, FRIC_FORCE, FFM, FR_LCL, FS, 
     &                  PEN_RATE, RNP, TQM, TQN, TQNT, VMN, VREL,
     &                  VRM, VRT, VRTS, VRTEST, WCM, WCN, 
     &                  PEN_RATE_PREVIOUS
      DIMENSION         FFM(3), FR_LCL(3), RNP(3), 
     &                  TQM(3), TQN(3), TQNT(3),
     &                  VMN(3), VREL(3), WCM(3), WCN(3)                 
!C
      SAVE  PEN_RATE_PREVIOUS
!C
      REAL  ( KIND = IREAL_HIGH )  EVALFD, VECMAG
      EXTERNAL                     EVALFD, VECMAG
!C
      INTENT ( IN )  M, N, NT
!C
      VRTEST = D_2                                                       
      CALL MAT31 ( DMNT_PLP, SEG(N)%ANG_VEL, DMNWN_PLP )                
      VMN = SEG(M)%LIN_VEL - SEG(N)%LIN_VEL                   
      WMN_PLP = DMNWN_PLP - SEG(M)%ANG_VEL                   
!C
      CALL DOT31 ( SEG(M)%DIR_COS, TM_PLP, T_PLP )                       
      CALL MAT31 ( SEG(M)%DIR_COS, VMN, VR_PLP )                        
      CALL CROSS ( SEG(M)%ANG_VEL, RLM_PLP, WCM )                     
      CALL CROSS ( DMNWN_PLP, RN_PLP, WCN )                               
      VR_PLP = VR_PLP + WCM - WCN                      
      VRM = DOT_PRODUCT ( VR_PLP, TM_PLP )                       
      VREL = VR_PLP - VRM * TM_PLP                     
      VRT = VECMAG ( VREL )                                          
!C
!C    Compute the coefficient of friction.
!C
      CF = EVALFD ( PEN_DIST, NTAB(NT+5), I_1 )                           
      LT = NTAB(NT)                                                       
      TAB(LT) = PEN_DIST                                                     
      FM_PLP = D_1                                                        
!C
!C    Compute the rate of penetration.
!C
      PEN_RATE = -VRM                                                         
      IF  ( TIME .GT. D_0 )  THEN
       IF ( TIME .NE. TAB(LT+30) ) THEN
        PEN_RATE = ( PEN_DIST - TAB(LT+1) ) / ( TIME - TAB(LT+30) )            
        PEN_RATE_PREVIOUS = PEN_RATE
       ELSE
        PEN_RATE = PEN_RATE_PREVIOUS
       END IF
      ELSE 
       PEN_RATE_PREVIOUS = D_0
      END IF
!C
      ELOSS = D_0                                                      
      IF ( MCF_PLP .GT. I_0 )  THEN
       CALL FRCDFL ( PEN_DIST, PEN_RATE, NT, I_1, FM_PLP, ELOSS )             
      END IF
      VRTS = VRT                                                          
      IF ( VRT .LT. VRTEST )    VRT = VRTEST / ( D_2 - VRT / VRTEST )    
      FRIC_FORCE = -ABS ( FM_PLP ) * CF / VRT                                 
      IF  ( ( NCF_PLP .GT. I_0 ) .AND. 
     &      ( KQTYPE(NCF_PLP) .EQ. I_6 ) )  THEN
       FRIC_FORCE = D_0                                                  
      END IF
      FS =  ( VRTS - VRT ) / VRT                                          
      IF ( ( NCF_PLP .GT. I_0 ) .AND. 
     &     ( KQTYPE(NCF_PLP) .EQ. I_6 ) ) FS = D_0  
      TF_PLP = D_0                                                      
      L = LT + I_18                                           
      DO  I=1,3                                                           
       L = L + I_1                                                      
       FFM(I) = FM_PLP * TM_PLP(I) + FRIC_FORCE * VREL(I) + FS * TAB(L)       
       TF_PLP = TF_PLP + FFM(I)**2                                        
       TTI(I) = T_PLP(I)                                                  
       R1I(I) = RLM_PLP(I)                                                
       R2I(I) = RLN_PLP(I)                                                
      END DO
!C
      TF_PLP = SQRT ( TF_PLP )                                            
      MT = NTAB(NT+5)                                                     
      CREST = TAB(MT+3)                                                   
      CALL DOT31 ( SEG(M)%DIR_COS, FFM, FR_LCL )                      
      IF ( MCF_PLP .LE. I_0 )  THEN                                    
       DO  I=1,3                                                          
        HQQ(I,NCF_PLP) = FR_LCL(I) / TF_PLP                               
        TQQ(I,NCF_PLP) = T_PLP(I)                                         
        RK1(I,NCF_PLP) = RLM_PLP(I)                                       
        RK2(I,NCF_PLP) = RLN_PLP(I)                                       
       END DO
       CFQQ(NCF_PLP)  = CF                                                
       MT = NTAB(NT+5)                                                    
       IF ( KQTYPE(NCF_PLP) .EQ. I_3 )  CFQQ(NCF_PLP) = TAB(MT+4)     
       RETURN
      END IF
!C
      CALL CROSS ( RLM_PLP, FFM, TQM )                                    
      CALL CROSS ( RN_PLP, FFM, TQNT )                                    
      CALL DOT31 ( DMNT_PLP, TQNT, TQN )                                  
!C
      SEG(M)%EXT_LIN_ACL = SEG(M)%EXT_LIN_ACL + FR_LCL                 
      SEG(N)%EXT_LIN_ACL = SEG(N)%EXT_LIN_ACL - FR_LCL                 
      SEG(M)%EXT_ANG_ACL = SEG(M)%EXT_ANG_ACL + TQM                       
      SEG(N)%EXT_ANG_ACL = SEG(N)%EXT_ANG_ACL - TQN                       
!C
!C    Compute nodal forces if M and/or N are deformable.                 
!C
      CALL DOT31 ( DMNT_PLP, RN_PLP, RNP )                              
      CALL FXCPLS ( M, N, RLM_PLP, RNP, FR_LCL )                        
      IF ( NCF_PLP .GT. I_0 ) THEN                                     
       DO  I=1,3                                                          
        HQQ(I,NCF_PLP) = FR_LCL(I) / TF_PLP                               
        TQQ(I,NCF_PLP) = T_PLP(I)                                         
        RK1(I,NCF_PLP) = RLM_PLP(I)                                       
        RK2(I,NCF_PLP) = RLN_PLP(I)                                       
       END DO
       CFQQ(NCF_PLP)  = CF                                                
       MT = NTAB(NT+5)                                                    
       IF ( KQTYPE(NCF_PLP) .EQ. I_3 ) CFQQ(NCF_PLP) = TAB(MT+4)                
      END IF
!C
      RETURN                                                              
      END                                                                 
