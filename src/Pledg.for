      SUBROUTINE PLEDG ( AREAL, BD_LCL, PL_LCL )                           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       AMR_PLP, DMNT_PLP, FM_PLP, PEN_DIST, RM_PLP, ! /PLELP_TEMPVS/
     &       RMD_PLP, TH_PLP, TM_PLP, VP=>VR_PLP,         ! /PLELP_TEMPVS/
     &       XH_PLP, XNC_PLP,                             ! /PLELP_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,        ! parameters
     &       TRUE, FALSE,                                 ! parameters
     &       I_0, I_1, I_2, I_3, I_6, D_0, D_1, D_2       ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, IV, J, K, L, M, MB
      DIMENSION  IV(14)
!C
      REAL  ( KIND = IREAL_HIGH )  
     &                  A0, A1, A2, AA1, AA2, AB_LCL, AB1, AB2, AC, AFP, 
     &                  ALIM, AMAX, AMIN, APT, AREA_LCL, 
     &                  B_LCL, BA1, BA2, BB_LCL, BB1, BB2, BC, BD_LCL, 
     &                  BMAX, BMIN, BT,  
     &                  CA, CL, CM, DELT, DHNT, DIS, DISC, 
     &                  E_LCL, ET, EU, EV, 
     &                  HAREA, PL_LCL, R2D, T4, U_LCL, UP, UV, V, X, ZC
      DIMENSION         AC(2,2), ALIM(2,2), APT(2,2,2), B_LCL(2), 
     &                  BC(2,2), BD_LCL(24), BT(2), DHNT(3,3), 
     &                  E_LCL(2,2), ET(3), EU(3), 
     &                  EV(3), HAREA(2,2,5), PL_LCL(24), T4(3), 
     &                  U_LCL(3), UP(3), UV(3,2), V(3), X(3), ZC(3,14)
!C  
      LOGICAL  ( KIND = LOGICAL_STD )  AREAL                               
!C
      EQUIVALENCE ( UV(1,1),   U_LCL(1) )                                  
      EQUIVALENCE ( ALIM(1,1), BMIN     ),  ( ALIM(1,2), AMIN )            
      EQUIVALENCE ( ALIM(2,1), BMAX     ),  ( ALIM(2,2), AMAX )            
      EQUIVALENCE ( AC(1,1),   BB1      ),  ( AC(1,2),   AA1  )            
      EQUIVALENCE ( AC(2,1),   BB2      ),  ( AC(2,2),   AA2  )            
      EQUIVALENCE ( BC(1,1),   AB1      ),  ( BC(1,2),   BA1  )            
      EQUIVALENCE ( BC(2,1),   AB2      ),  ( BC(2,2),   BA2  )            
!C                                                                        
      AREA_LCL = D_0                                                    
      AREAL = FALSE                                                     
!C
!C    Calculate center of ellipse in plane                                
!C    T4 is vector from center of ellipsoid to center of ellipse          
!C
      DO  I = 1,3                                                          
       T4(I)      = FM_PLP * XH_PLP(I)                                     
       XNC_PLP(I) = XNC_PLP(I) + T4(I)                                     
      END DO
!C
!C    XNC_PLP P1 to center of ellipse                                      
!C    Put plane vectors in ellipse system   TH_PLP is plane vector         
!C
      IF ( BD_LCL(1) .LT. D_0 )  THEN 
       CALL MAT33 ( BD_LCL(8), DMNT_PLP, DHNT )                           
      ELSE
       DO  I = 1,3                                                         
        DO  J = 1,3                                                        
         DHNT(I,J) = DMNT_PLP(I,J)                                         
        END DO
       END DO
      END IF
      CALL MAT31 ( DHNT, PL_LCL( 8), UP    )                               
      CALL MAT31 ( DHNT, PL_LCL(13), VP    )                               
      CALL MAT31 ( DHNT, PL_LCL(18), U_LCL )                               
      CALL MAT31 ( DHNT, PL_LCL(21), V     )                               
!C
!C    U_LCL is P2 - P1, V is P3 - P1, plane vector is TM_PLP               
!C    Calculate center from P1 in U, V coordinates                        
!C
      B_LCL(1) = ( UP(1) * XNC_PLP(1) + UP(2) * XNC_PLP(2) 
     &                                + UP(3) * XNC_PLP(3) )
     &                            / PL_LCL(12)                             
      B_LCL(2) = ( VP(1) * XNC_PLP(1) + VP(2) * XNC_PLP(2) 
     &                                + VP(3) * XNC_PLP(3) )
     &                            / PL_LCL(17)                             
      AMIN =     - B_LCL(1)                                                
      AMAX = D_1 - B_LCL(1)                                               
      BMIN =     - B_LCL(2)                                               
      BMAX = D_1 - B_LCL(2)                                             
!C
!C    Get ellipse equation                                                 
!C
      DO  I = 1,2                                                          
       DO  J = I,2                                                         
        E_LCL(I,J) = D_0                                               
       END DO
      END DO
      IF ( BD_LCL(1) .LE. D_0 )  THEN                                    
!C
!C     Treat hyper as ellipse for first guess                              
!C
       DO  I = 1,3                                                        
        EU(I) = U_LCL(I) * BD_LCL(I+16)                                    
        EV(I) = V(I)     * BD_LCL(I+16)                                   
       END DO
!C
!C     Get intersection of plane with box                                 
!C
       CALL HYBOX ( BD_LCL(2), TH_PLP, T4, MB, ZC, IV )                   
       IF  ( MB .LT. I_6 )  THEN                                        
        RETURN
       END IF
      ELSE
       CALL MAT31 ( BD_LCL(7), U_LCL, EU )                                 
       CALL MAT31 ( BD_LCL(7), V,     EV )                              
      END IF
      DO  K = 1,3                                                          
       E_LCL(1,1) = E_LCL(1,1) + U_LCL(K) * EU(K)                          
       E_LCL(1,2) = E_LCL(1,2) + V(K)     * EU(K)                          
       E_LCL(2,2) = E_LCL(2,2) + V(K)     * EV(K)                          
      END DO
      DELT = E_LCL(1,1) * E_LCL(2,2) - E_LCL(1,2)**2                       
!C
!C    What about AMR_PLP for hyper??   1 - FM_PLP**P ?                     
!C
      R2D = AMR_PLP / DELT                                                 
!C
!C    Compute bounds of ellipsoid location of max and min alpha            
!C
      AA2 =  SQRT ( E_LCL(2,2) * R2D )                                     
      AA1 = -AA2                                                           
!C
!C    BA is value of beta at alpha max                            
!C
      BA1 =  E_LCL(1,2) * AA2 / E_LCL(2,2)                                
      BA2 = -BA1                                                          
      IF  ( BD_LCL(1) .LT. -D_2 )  THEN                                   
      CALL HYBND ( MB, ZC, IV, UP, -D_1, X )                             
      CALL HYLIM ( AA1, U_LCL, BA1, V, FM_PLP, XH_PLP, X, BD_LCL )        
      END IF
      AMIN = MAX ( AA1, AMIN )                                             
      IF  ( AMIN .GE. AMAX )  THEN                                       
       RETURN
      END IF
      IF ( BD_LCL(1) .LT. -D_2 )   THEN                                  
      CALL HYBND ( MB, ZC, IV, UP,  D_1, X )                              
      CALL HYLIM ( AA2, U_LCL, BA2, V, FM_PLP, XH_PLP, X, BD_LCL )        
      END IF
      AMAX = MIN ( AA2, AMAX )                                             
      IF ( AMIN .GE. AMAX )   THEN
       RETURN
      END IF                                                               
!C
!C    Compute bounds of ellipsoid location of max and min beta            
!C
      BB2 =  SQRT ( E_LCL(1,1) * R2D )                                    
      BB1 = -BB2                                                          
!C
!C    AB_LCL is value of alpha at beta max                       
!C
      AB1 =  E_LCL(1,2) * BB2 / E_LCL(1,1)                                 
      AB2 = -AB1                                                          
      IF  ( BD_LCL(1) .LT. -D_2 )   THEN                                  
       CALL HYBND ( MB, ZC, IV, VP, -D_1, X )                            
       CALL HYLIM ( BB1, V, AB1, U_LCL, FM_PLP, XH_PLP, X, BD_LCL )       
      END IF
      BMIN = MAX ( BB1, BMIN )                                            
      IF  ( BMIN .GE. BMAX )   THEN
       RETURN
      END IF                                                              
      IF ( BD_LCL(1) .LT. -D_2 )  THEN                                  
       CALL HYBND ( MB, ZC, IV, VP, D_1, X )                             
       CALL HYLIM ( BB2, V, AB2, U_LCL, FM_PLP, XH_PLP, X, BD_LCL )        
      END IF
      BMAX = MIN ( BB2, BMAX )                                            
      IF  ( BMIN .GE. BMAX )  THEN
       RETURN
      END IF
!C
!C    Compute alpha's at bmin and bmax; beta's at AMIN and AMAX 
!C    if not on ellipsoid.                                                 
!C 
      IF ( BD_LCL(1) .GE. -D_2 )  THEN                                   
       DO  L = 1,2                                                         
        K = 3 - L                                                          
        DO  J = 1,2                                                        
         DIS = D_0                                                     
         AFP = BC(J,L)                                                     
         IF  ( ALIM(J,L) .NE. AC(J,L) )   THEN                             
          AFP = ALIM(J,L) / E_LCL(L,L)                                     
          DISC =  AMR_PLP / E_LCL(L,L) - DELT * AFP**2                     
          DIS = D_0                                                   
          IF ( DISC .GT. D_0 )  DIS = SQRT ( DISC )                     
          AFP =  -AFP * E_LCL(1,2)                                         
         END IF
         APT(1,J,L) = MAX ( ( AFP - DIS ), ALIM(1,K) )                     
         APT(2,J,L) = MIN ( ( AFP + DIS ), ALIM(2,K) )                     
        END DO                                                            
       END DO                                                             
      ELSE
       DO  L = 1,2                                                         
        K = I_3 - L                                                   
        DO  J = 1,2                                                       
         DIS = D_0                                                   
         BT(1) = BC(J,L)                                                  
         BT(2) = BC(J,L)                                                   
         IF ( ALIM(J,L) .NE. AC(J,L) )  THEN                              
          M = I_2                                                        
          IF  ( ALIM(J,L) .LT. D_0 )   M = I_1                           
          CM = BC(M,L) / AC(M,L)                                          
          CL = ALIM(J,L) * CM                                             
          DO  I = 1,3                                                      
           RM_PLP(I) = T4(I) + ALIM(J,L) * ( UV(I,K) + CM * UV(I,L) )      
          END DO
          DO  I = 1,2                                                      
           CALL HYVAL ( BT(I), UV(1,L), RM_PLP, BD_LCL, I )               
           BT(I) = BT(I) + CL                                             
          END DO
         END IF
         APT(1,J,L) = MAX ( BT(1), ALIM(1,K) )                            
         APT(2,J,L) = MIN ( BT(2), ALIM(2,K) )                             
        END DO                                                             
       END DO                                                             
      END IF
!C
!C    Set up legal boundaries                                             
!C    APT         L = 1                   L = 2                            
!C          A-(BMIN)   A-(BMAX)     B-(AMIN)   B-(AMAX)                    
!C          A+(BMIN)   A+(BMAX)     B+(AMIN)   B+(AMAX)                   
!C    Set up HAREA (line segments) clockwise starting with AMIN           
!C
      L = I_0                                                          
      HAREA(1,1,L+1) = AMIN                                               
      HAREA(2,1,L+1) = APT(2,1,2)                                         
      HAREA(1,2,L+1) = AMIN                                                
      HAREA(2,2,L+1) = APT(1,1,2)                                          
      IF  ( APT(2,1,2) .GE. APT(1,1,2) )    L = L + I_1                  
      HAREA(1,1,L+1) = APT(1,1,1)                                         
      HAREA(2,1,L+1) = BMIN                                                
      HAREA(1,2,L+1) = APT(2,1,1)                                          
      HAREA(2,2,L+1) = BMIN                                               
      IF  ( APT(2,1,1) .GE. APT(1,1,1) )    L = L + I_1                  
      HAREA(1,1,L+1) = AMAX                                                
      HAREA(2,1,L+1) = APT(1,2,2)                                          
      HAREA(1,2,L+1) = AMAX                                               
      HAREA(2,2,L+1) = APT(2,2,2)                                          
      IF  ( APT(2,2,2) .GE. APT(1,2,2) )    L = L + I_1                 
      HAREA(1,1,L+1) = APT(2,2,1)                                          
      HAREA(2,1,L+1) = BMAX                                                
      HAREA(1,2,L+1) = APT(1,2,1)                                         
      HAREA(2,2,L+1) = BMAX                                                
      IF  ( APT(2,2,1) .GE. APT(1,2,1) )     L = L + I_1                 
      IF ( L .LE. I_1 )  THEN
       RETURN
      END IF                                                               
      HAREA(1,1,L+1) = HAREA(1,1,1)                                        
      HAREA(2,1,L+1) = HAREA(2,1,1)                                        
      IF ( BD_LCL(1) .GE. -I_2 )  THEN
       CALL PLREA ( L, HAREA, AREA_LCL, AB_LCL,
     &              BB_LCL, E_LCL, DELT, AMR_PLP )                         
      ELSE
       CALL HYREA ( L, HAREA, AREA_LCL, AB_LCL, BB_LCL )                   
      END IF
      IF ( AREA_LCL .GT. D_0 )  THEN
       AREAL = TRUE
      END IF
      IF ( .NOT. AREAL )  THEN                                             
        RETURN
      END IF
!C                                                                         
      RM_PLP = AB_LCL * U_LCL + BB_LCL * V + T4             
      RMD_PLP = RM_PLP                                             
!C
!C    Compute point on ellipsoid below centroid          
!C    Convert plane vector, ET = E * TM_PLP                                  
!C    Try to use other logic                                               
!C
      IF  ( BD_LCL(1) .GE. D_0 )   THEN                                 
       CALL MAT31 ( BD_LCL(7), TM_PLP, ET )                                
       A2 = TM_PLP(1) * ET(1) + TM_PLP(2) * ET(2) + TM_PLP(3) * ET(3)      
       A1 = AB_LCL * ( TM_PLP(1) * EU(1) + TM_PLP(2) * EU(2)
     &                                   + TM_PLP(3) * EU(3) )            
     &                    + FM_PLP + 
     &      BB_LCL * ( TM_PLP(1) * EV(1) + TM_PLP(2) * EV(2)
     &                                   + TM_PLP(3) * EV(3) )            
       A1 = A1 / A2                                                        
       A0 = (             AB_LCL**2 * E_LCL(1,1) 
     &            + D_2 * AB_LCL * BB_LCL * E_LCL(1,2) 
     &                  + BB_LCL**2 * E_LCL(2,2) - AMR_PLP ) / A2         
       DISC = A1**2 - A0                                                  
       IF  ( DISC .LT. D_0 )    DISC = D_0                            
       PEN_DIST = A1 + SQRT ( DISC )                                          
      ELSE
!C
!C     Compute for hyperellipsoid.                                                  
!C
       CALL HYVAL ( CA, TH_PLP, RM_PLP, BD_LCL, 1 )                        
       PEN_DIST = -CA                                                        
       CALL DOT31 ( BD_LCL(8), RMD_PLP, RM_PLP )                           
      END IF
!C
      RETURN                                                              
      END                                                                  
