      SUBROUTINE HYNTR ( BM, BN, TAB_LCL )                                 
!C
!C                                                   Rev. V.3 12/15/2003 
!C
!C
!C    Calculations in segment M'S reference                                
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                   ! /CNSNTS/
     &       D12=>DMNT_PLP, R_PLP,                  ! /PLELP_TEMPVS/
     &       TM_PLP, RM_PLP,                        ! /PLELP_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH,               ! parameters
     &       I_1, I_2, I_8, I_100, D_0, D_1, D_2    ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD  )  I, ITER, ITER_HYNTR, J, K, L
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A, AZ, BM, BN, TAB_LCL, P1_LCL, P2, C1_LCL, C2, 
     &                  CN_LCL, BET_LCL, SS, TALP, TBET, ZZ, DAD,
     &                  DBD, BMD, S, ALP, V, BZV, ZM, VN, ZVR, BV,
     &                  F_LCL, DNM, Z, B_LCL
      DIMENSION         AZ(3), BM(24), BN(24), TAB_LCL(8), DAD(3,3),        
     &                  DBD(3,3), BMD(3,3), S(5,6), V(3), A(3,3),
     &                  BZV(3), ZM(3), VN(3), ZVR(3), BV(3),
     &                  F_LCL(2), DNM(3,3), Z(3), B_LCL(3,3)                 
!C
      PARAMETER (  ITER_HYNTR = I_100 )
!C
      P1_LCL = D_2                                                       
      P2     = D_2                                                      
      IF ( BM(1) .LT. -D_2 )  P1_LCL = -BM(1)                            
      IF ( BN(1) .LT. -D_2 )  P2     = -BN(1)                              
      C1_LCL =  P1_LCL - D_1                                             
      CN_LCL =  P2     - D_1                                             
!C
!C    DNM transforms from M to NN.                                          
!C
      K = I_8                                                          
      DO  J = 1,3                                                          
       DO  I = 1,3                                                         
        BMD(I,J) = D_0                                                  
        IF ( BM(1) .LT. D_0 )   BMD(I,J) = BM(K)                         
        DNM(I,J) = D12(I,J)                                                
        K = K + I_1                                                    
       END DO
       IF ( BM(1) .GT. D_0 )    BMD(J,J) = D_1                       
      END DO
      IF ( BN(1) .LT. D_0 )    CALL DOTT33 ( BN(8), D12, DNM )        
      ALP     = TAB_LCL(1)                                                 
      BET_LCL = TAB_LCL(2)                                                 
      DO  I = 1,3                                                          
       ZM(I) = TAB_LCL(I+2)                                                
       VN(I) = TAB_LCL(I+5)                                                
      END DO
!C
!C    Put vectors into M'S reference.                                       
!C
      CALL DOT31 ( BMD, ZM, Z )                                            
      CALL DOT31 ( DNM, VN, V )                                            
      DO  I = 1,3                                                          
       ZVR(I) = Z(I) - V(I) - BET_LCL * R_PLP(I)                        
      END DO
!C                                                                         
      DO 40 ITER = 1,ITER_HYNTR                                            
       CALL HYABF ( BM, ZM, A, F_LCL(1) )                                   
       CALL HYABF ( BN, VN, B_LCL, F_LCL(2) )                             
       CALL DOT31 ( BMD, A(1,2), AZ )                                       
       CALL DOT31 ( DNM, B_LCL(1,2), BV )                                  
       CALL HYDAD ( BMD, A, DAD )                                           
       CALL HYDAD ( DNM, B_LCL, DBD )                                     
       CALL MAT31 ( DBD, R_PLP, S(1,5) )                                  
       CALL MAT31 ( DBD, ZVR, BZV )                                         
       C2 = CN_LCL * ALP                                                    
!C
!C     Set up S matrix                                                      
!C
       S(4,4) = D_0                                                       
       S(5,5) = D_0                                                        
       S(4,6) = ( D_1 - F_LCL(2) ) / P2 - V(1) * BZV(1)
     &           - V(2) * BZV(2) -V(3) * BZV(3)                             
       S(5,6) = ( D_1 - F_LCL(1) ) / P1_LCL                                 
       S(4,5) = -BV(1) * R_PLP(1) - BV(2) * R_PLP(2) - BV(3) * R_PLP(3)           
       S(5,4) = D_0                                                       
       DO  I = 1,3                                                          
        S(I,4) =  BV(I)                                                     
        S(4,I) =  BV(I)                                                     
        S(I,5) = -C2 * S(I,5)                                               
        S(5,I) =  AZ(I)                                                     
        S(I,6) = -AZ(I) - ALP * BV(I) - C2 * BZV(I)                         
        DO  J = 1,3                                                         
         S(I,J) = C1_LCL * DAD(I,J) + C2 * DBD(I,J)                         
        END DO
       END DO
       CALL HYSOL ( S, 5, 5 )                                               
       TALP = ALP + S(4,6)                                                  
       IF ( TALP .LE. D_0 )  TALP = ALP / D_2                              
       ALP = TALP                                                           
       TBET = BET_LCL + S(5,6)                                              
       IF ( TBET .LE. D_0 )   TBET = BET_LCL / D_2                       
       BET_LCL = TBET                                                       
       SS = D_0                                                           
       ZZ = D_0                                                           
       DO  I = 1,3                                                          
        SS   = SS + ABS ( S(I,6) )                                          
        Z(I) = Z(I) + S(I,6)                                                
        ZZ   = ZZ + ABS ( Z(I) )                                            
        V(I) = Z(I) - BET_LCL * R_PLP(I)                                    
        ZVR(I) = D_0                                                      
       END DO
       CALL MAT31 ( BMD, Z, ZM )                                            
       CALL MAT31 ( DNM, V, VN )                                            
!C
!C     Convergence test depends on REAL*4 (1.0E-5) or REAL*8 (??)          
!C
       IF ( SS .LT. ( EPS(10) * ZZ ) )  THEN
        TAB_LCL(1) = ALP                                                  
        TAB_LCL(2) = BET_LCL                                                
        DO  I = 1,3                                                         
         TAB_LCL(I+2) = ZM(I)                                               
         TAB_LCL(I+5) = VN(I)                                               
        END DO
        TM_PLP = AZ
        RM_PLP = Z
        RETURN                                                            
       END IF
!C
       K = I_1                                                            
       L = I_1                                                             
       IF ( BM(1) .LT. D_0 )   K = I_2                                   
       IF ( BN(1) .LT. D_0 )   L = I_2                                  
       DO  I = 1,3                                                          
        IF ( ABS ( ZM(I) ) .GT. BM(K) )  ZM(I) = SIGN ( BM(K), ZM(I) )      
        IF ( ABS ( VN(I) ) .GT. BN(L) )  VN(I) = SIGN ( BN(L), VN(I) )      
        K = K + I_1                                                     
        L = L + I_1                                                       
       END DO
       CALL DOT31 ( BMD, ZM, Z )                                            
       CALL DOT31 ( DNM, VN, V )                                            
       DO   I = 1,3                                                         
        ZVR(I) = Z(I) - V(I) - BET_LCL * R_PLP(I)                          
       END DO
   40 CONTINUE                                                             
!C
!C    WRITE(6,45)                                                          
!C 45 FORMAT(' HYNTR did not converge, contact ignored.')                  
!C
      BET_LCL = D_1                                                        
      TAB_LCL(1) = ALP                                                  
      TAB_LCL(2) = BET_LCL                                                 
      DO  I = 1,3                                                          
       TAB_LCL(I+2) = ZM(I)                                               
       TAB_LCL(I+5) = VN(I)                                                
      END DO
      TM_PLP = AZ
      RM_PLP = Z
!C
      RETURN                                                               
      END                                                                  
