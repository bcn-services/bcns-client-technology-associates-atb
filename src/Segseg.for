      SUBROUTINE SEGSEG ( M, MM, N, NS_LCL, NT )                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       BD,                                     ! /CNTRSF/
     &       CFQQ, RQQ, SQQ,                         ! /CSTRNT/
     &       NSSF, SSF,                              ! /FORCES/
     &       NTAB, TAB,                              ! /TABLES/
     &       AMR_PLP, DMNT_PLP, DMNWN_PLP, FM_PLP,   ! /PLELP_TEMPVS/
     &       MCF_PLP, NCF_PLP, PEN_DIST, R_PLP,      ! /PLELP_TEMPVS/ 
     &       RLM_PLP, RLN_PLP, RM_PLP, RMD_PLP,      ! /PLELP_TEMPVS/
     &       RN_PLP, RND_PLP, T_PLP, TF_PLP, TM_PLP, ! /PLELP_TEMPVS/
     &       VR_PLP, WNM_PLP, XMM_PLP, XMN_PLP,      ! /PLELP_TEMPVS/
     &       SEG,                                    ! structures
     &       INTEGER_STD, IREAL_HIGH,                ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_3, I_4       ! parameters
!C
!C    ANG_VEL, DIR_COS, DRC_PHI, LIN_DISP, ROT_PHI    ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &             I, J, K, LT, M, MM, N, NN_LCL, NS_LCL, NT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ANR, B_LCL, BET_LCL, RI, S1_LCL, S2, 
     &                  T1_LCL, T2_LCL, T3_LCL, T4_LCL, TB, 
     &                  TEMP_LCL, TF2FM2, TT4_LCL, TT5_LCL
      DIMENSION         B_LCL(3,3), T1_LCL(3), T2_LCL(3), T3_LCL(3), 
     &                  T4_LCL(3), TEMP_LCL(3,3), TT4_LCL(3,4),
     &                  TT5_LCL(3,4)
!C
      REAL  ( KIND = IREAL_HIGH )  XDY
      EXTERNAL          XDY
!C
      CALL ELTIME ( I_1, 23_INTEGER_STD )                                               
!C                                                                         
!C    Computations are done in M'S reference system                         
!C
      NN_LCL = ABS ( NS_LCL )                                            
      CALL DOTT33 ( SEG(M)%DIR_COS, SEG(N)%DIR_COS, DMNT_PLP )           
      XMN_PLP = SEG(M)%LIN_DISP - SEG(N)%LIN_DISP                        
      CALL MAT31 ( SEG(M)%DIR_COS, XMN_PLP, XMM_PLP )                   
      J = I_3                                                        
      IF ( BD(1,NN_LCL) .LT. D_0 )   J = I_4                           
      CALL MAT31 ( DMNT_PLP, BD(J+1,NN_LCL), RLN_PLP )                    
      J = I_3                                                         
      IF ( BD(1,MM) .LT. D_0 )  J = I_4                                 
      DO  I = 1,3                                                          
       J = J + I_1                                                      
       R_PLP(I) = RLN_PLP(I) - XMM_PLP(I) - BD(J,MM)                      
      END DO
      LT = NTAB(NT)                                                       
      TB = D_1                                                             
      IF ( ( BD(1,MM)     .GT. D_0 ) .AND. 
     &     ( BD(1,NN_LCL) .GT. D_0 ) )   THEN                          
!C
!C     Old ellipsoids                                                      
!C
       IF ( NS_LCL .LT. D_0 )    TB = -TB                          
       CALL DOTT33 ( BD(7,NN_LCL), DMNT_PLP, TEMP_LCL )
       CALL MAT33 ( DMNT_PLP, TEMP_LCL, B_LCL )                           
       CALL INTERS ( BD(7,MM), B_LCL, R_PLP, TB, RM_PLP,
     &              TAB(LT+22), TM_PLP )                                 
      ELSE
!C
!C     New hyperellipsoid - at least one surface is a hyperellipsoid       
!C
       IF ( ( BD(1,MM)  .LT. D_0 ) .AND. 
     &      ( BD(23,MM) .NE. D_0 ) )   STOP 23                           
       IF ( ( BD(1,NN_LCL) .LT. D_0 ) .AND. 
     &      ( BD(23,NN_LCL) .NE. D_0 ) )   STOP 23                      
!C
!C     A hyperellipsoid must have identical powers.                        
!C     If(NS.LT.0)   stop - interior intersection not operational          
!C
       IF ( NS_LCL .LT. I_0 )  STOP 38                                  
       IF ( TAB(LT+23) .LE. D_1 )  THEN
        CALL HYEST ( BD(1,MM), BD(1,NN_LCL), TAB(LT+22) )                  
       ELSE
        CALL HYNTR ( BD(1,MM), BD(1,NN_LCL), TAB(LT+22) )                 
       END IF
       BET_LCL = TAB(LT+23)                                                
       IF ( BET_LCL .GT. D_1 )    TB = D_1 / BET_LCL                      
      END IF                                                              
!C
!C                    A    B R    Z      C      AZ                         
!C    INTERS solves (CA + B)Z = BR,   TB = SQRT(Z.AZ)                      
!C                                                                        
      MCF_PLP = NTAB(NT+1)                                                
      NCF_PLP = -MCF_PLP                                                 
      IF ( NCF_PLP .GT. I_0 )  CFQQ(NCF_PLP) = -999._IREAL_HIGH                  
!C                                                                         
!C    Check for intersection                                               
!C                                                                        
      IF ( TB .GE. D_1 )  THEN                                             
       CALL ELTIME ( I_2, 23_INTEGER_STD )                                              
       RETURN                                                            
      END IF
!C
      S1_LCL = D_0                                                  
      S2 = D_0                                                       
      DO  I = 1,3                                                          
       RI = R_PLP(I)                                                      
       IF ( NS_LCL .LT. I_0 )  THEN
        RI = RM_PLP(I) + TB * ( RM_PLP(I) - R_PLP(I) )                    
       END IF
       S1_LCL = S1_LCL + RI**2                                           
       S2 = S2 + TM_PLP(I)**2                                              
      END DO
      AMR_PLP = SQRT ( S2 )                                              
      PEN_DIST = ( D_1 / TB - D_1 ) * SQRT ( S1_LCL )                       
      J = I_3                                                         
      IF ( BD(1,MM) .LT. D_0 )  J = I_4                                
      DO  I = 1,3                                                        
       J = J + I_1                                                       
       IF ( ( BD(1,MM) .LT. D_0 ) .OR. 
     &      ( BD(1,NN_LCL) .LT. D_0 ) )  THEN
         RM_PLP(I) = TB * RM_PLP(I)
       END IF                                                              
       TM_PLP(I)  = -TM_PLP(I) / AMR_PLP                                  
       T2_LCL(I)  = RM_PLP(I) - R_PLP(I)                                 
       RN_PLP(I)  = T2_LCL(I) + RLN_PLP(I)                               
       RLM_PLP(I) = RM_PLP(I) + BD(J,MM)                                 
      END DO
      CALL DOT31 ( DMNT_PLP, RN_PLP, RLN_PLP )                            
      CALL PLSEGF ( M, N, NT )                                           
!C                                                                          
!C    Store print data                                                      
!C                                                                          
      SSF(1,NSSF) = PEN_DIST                                                 
      DO  I = 1,3                                                          
       SSF(I+4,NSSF) = RLM_PLP(I)                                           
       SSF(I+7,NSSF) = RLN_PLP(I)                                          
      END DO
      IF ( SEG(M)%ROT_PHI )  THEN
       CALL DOT31 ( SEG(M)%DRC_PHI, RLM_PLP, SSF(5,NSSF) )              
      END IF
      IF ( SEG(N)%ROT_PHI )  THEN
       CALL DOT31 ( SEG(N)%DRC_PHI, RLN_PLP, SSF(8,NSSF) )                
      END IF
!C
      IF ( MCF_PLP .GE. I_0 )  THEN                                     
       SSF(2,NSSF) = FM_PLP                                               
       TF2FM2 = TF_PLP**2 - FM_PLP**2                                     
       IF ( TF2FM2 .LT. D_0 )  TF2FM2 = D_0                        
       SSF(3,NSSF) = SQRT ( TF2FM2 )                                      
       SSF(4,NSSF) = TF_PLP                                               
       CALL ELTIME ( I_2, 23_INTEGER_STD )                                               
       RETURN                                                             
      END IF
!C                                                                          
!C    Roll-slide                                                           
!C
      DO  I = 1,3                                                          
       SSF(I+1,NSSF) = T_PLP(I)                                          
      END DO
      IF ( ( BD(1,MM)     .LT. D_0 ) .OR. 
     &     ( BD(1,NN_LCL) .LT. D_0 ) )  STOP 29                    
      ANR = XDY ( TM_PLP, B_LCL, T2_LCL )                                 
      CALL CROSS ( TM_PLP, WNM_PLP, T2_LCL )                              
      CALL MAT31 ( B_LCL, VR_PLP, T1_LCL )                                
      TB = TM_PLP(1) * T1_LCL(1) + TM_PLP(2) * T1_LCL(2) 
     &                           + TM_PLP(3) * T1_LCL(3)                   
      DO  I = 1,3                                                          
       DO  J = 1,3                                                         
        K = I + I_3 * ( J + I_1 )                                   
        TT4_LCL(I,J) = BD(K,MM) / AMR_PLP + B_LCL(I,J) / ANR              
        TT5_LCL(I,J) = TT4_LCL(I,J)                                       
       END DO
       TT4_LCL(I,4) = T2_LCL(I) - ( T1_LCL(I) - TB * TM_PLP(I) ) / ANR      
       TT5_LCL(I,4) = TM_PLP(I)                                           
      END DO
      CALL DSMSOL ( TT4_LCL, 3 )                                         
      CALL DSMSOL ( TT5_LCL, 3 )                                          
!C
      S1_LCL =   TM_PLP(1) * TT4_LCL(1,4) + TM_PLP(2) * TT4_LCL(2,4)
     &                                    + TM_PLP(3) * TT4_LCL(3,4)       
      S2     = ( TM_PLP(1) * TT5_LCL(1,4) + TM_PLP(2) * TT5_LCL(2,4)
     &                                    + TM_PLP(3) * TT5_LCL(3,4) )
     &                                  / S1_LCL                           
      DO  I = 1,3                                                          
       RMD_PLP(I) = TT4_LCL(I,4) - S2 * TT5_LCL(I,4)                        
      END DO
      RND_PLP = RND_PLP + VR_PLP                            
!C
      CALL CROSS ( DMNWN_PLP,       RND_PLP, T1_LCL )                 
      CALL CROSS ( SEG(MM)%ANG_VEL, RMD_PLP, T2_LCL )                 
      CALL MAT31 ( B_LCL,           RND_PLP, T3_LCL )            
      CALL CROSS ( DMNWN_PLP,       TM_PLP,  T4_LCL )                     
      S1_LCL = DOT_PRODUCT ( TM_PLP, T3_LCL )
      T1_LCL = T1_LCL - T2_LCL
      SQQ(NCF_PLP) = DOT_PRODUCT ( TM_PLP, T1_LCL ) - 
     &  DOT_PRODUCT ( VR_PLP, ( T4_LCL + ( T3_LCL - S1_LCL * TM_PLP )
     &                                                 / ANR ) )
      CALL DOT31 ( SEG(M)%DIR_COS, T1_LCL, RQQ(1,NCF_PLP) )                 
!C
      CALL ELTIME ( I_2, 23_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                
