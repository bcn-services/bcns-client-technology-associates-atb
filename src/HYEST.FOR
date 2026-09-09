      SUBROUTINE HYEST ( BM, BN, TAB_LCL )                                 
!C
!C                                                   Rev. V.3 12/15/2003 
!C
!C    Linear program                                                       
!C
      USE  MODULE_STANDARD,  ONLY:
     &       D12=>DMNT_PLP, R_PLP,        ! /PLELP_TEMPVS/
     &       TM_PLP, RM_PLP,              ! /PLELP_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH,     ! parameters
     &       D_0, D_1, D_2, I_1, I_2      ! parameters  
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( INTEGER_STD )  I, M, N
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A, BM, BN, TAB_LCL, AA, ALP, C_LCL, BE, PM, PN, 
     &                  BB_LCL, RA, RB, RR, F1_LCL, F2, B_LCL, T, V
      DIMENSION         A(3,3), B_LCL(3,3), BM(24), BN(24), 
     &                  C_LCL(3,3), T(3), TAB_LCL(8), V(7)                 
!C
!C    R goes from M to N   D12 = DM*DN'                                    
!C    R = 0 cannot be solved with this method                              
!C
      BE = D_1                                                             
      RR = DOT_PRODUCT ( R_PLP, R_PLP )
      IF ( RR .EQ. D_0 )  THEN                                          
       TAB_LCL(2) = BE                                                     
       RETURN                                                              
      END IF
!C
!C    R.R = 0 invalid                                                      
!C
      M = I_1                                                           
      N = I_1                                                            
      IF ( BM(1) .LT. D_0 )  M = I_2                                     
      IF ( BN(1) .LT. D_0 )  N = I_2                                   
      PM = D_2                                                            
      PN = D_2                                                           
      IF ( M .EQ. I_2 )  PM = -BM(1)                                    
      IF ( N .EQ. I_2 )  PN = -BN(1)                                     
      T = R_PLP                                                            
      B_LCL = D12                                                          
      IF ( N .EQ. I_2 )  CALL DOTT33 ( D12, BN(8), B_LCL )             
      C_LCL = B_LCL                                                        
      IF ( M .EQ. I_2 )   CALL MAT33 ( BM(8), B_LCL, C_LCL )             
!C
!C    C will transform from NN to MM                                       
!C
      IF ( M .EQ. I_2 )  CALL MAT31 ( BM(8), R_PLP, T )                 
      CALL HYLPX ( BM(M), BN(N), T, C_LCL, V )                             
      BE = V(7)                                                            
      IF ( V(7) .LE. D_1 )   THEN                                          
       TAB_LCL(2) = BE                                                     
       TM_PLP = T
       DO I = 1,3
        RM_PLP(I) = C_LCL(I,1)
       END DO
       RETURN                                                              
      END IF
      CALL HYABF ( BM(1), V(1), A,     F1_LCL )                            
      CALL HYABF ( BN(1), V(4), B_LCL, F2     )                            
!C
!C    Estimate alpha                                                       
!C
      AA = A(1,2)**2 + A(2,2)**2 + A(3,2)**2                               
      BB_LCL = B_LCL(1,2)**2 + B_LCL(2,2)**2 + B_LCL(3,2)**2               
      ALP = SQRT ( AA / BB_LCL )                                           
      RA = F1_LCL**( D_1 / PM )                                          
      RB =     F2**( D_1 / PN )                                           
      ALP = ALP * RA * F2 / ( RB * F1_LCL )                                
!C
!C    Scale points to ellipsoids                                           
!C
      DO  I = 1,3                                                          
       V(I)   = V(I) / RA                                                  
       V(I+3) = V(I+3) / RB                                                
      END DO
!C
!C    Estimate beta                                                        
!C
      CALL MAT31 ( C_LCL, V(4), T )                                        
      BE =    ( V(1) - T(1) )**2 
     &      + ( V(2) - T(2) )**2  
     &      + ( V(3) - T(3) )**2                                           
      BE = SQRT ( BE / RR )                                                
!C
!C    Store values in TAB_LCL array for CONTACT                            
!C
      TM_PLP = T
      DO I = 1,3
       RM_PLP(I) = C_LCL(I,1)
      END DO
      TAB_LCL(1) = ALP                                                     
      DO  I = 1,6                                                          
       TAB_LCL(I+2) = V(I)                                                 
      END DO
      TAB_LCL(2) = BE                                                      
!C
      RETURN                                                               
      END                                                                  
