      SUBROUTINE DSETQ ( E_LCL, TH, ES, EC, D_LCL )                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes new direction matrix (D), given original matrix (E)         
!C    and incremental motion expressed in quaternion form.                 
!C                                                                         
!C      Arguments:                                                         
!C                                                                         
!C        E_LCL : original direction cosine matrix.                        
!C           TH : components of Q ( UX SIN A/2, UY SIN A/2, UZ SIN A/2)    
!C           ES : SIN**2(A/2)                                              
!C           EC : COS (A/2)                                                
!C        D_LCL : new direction cosine matrix.                             
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                  ! CNSNTS/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,       ! parameter
     &       I_10, D_0, D_HALF, D_1, D_2           ! parameter
!C
      INTEGER  ( KIND = INTEGER_STD )  I, ITER, J, K, NUM_ITER
!C
      PARAMETER ( NUM_ITER = I_10 )
!C
      REAL  ( KIND = IREAL_HIGH )   CT, DET, DTT, EC, ES
      REAL  ( KIND = IREAL_HIGH )  D_LCL, TH, S, TEMP, E_LCL
      DIMENSION  D_LCL(3,3), TH(3), S(3), TEMP(3,3), E_LCL(3,3)            
!C
      INTENT (  IN )  E_LCL, TH, ES, EC
      INTENT ( OUT )  D_LCL
!C
      CT = D_1 - D_2 * ES                                                
      DO  J=1,3                                                            
       S(1) = TH(2) * E_LCL(3,J) - TH(3) * E_LCL(2,J)                      
       S(2) = TH(3) * E_LCL(1,J) - TH(1) * E_LCL(3,J)                      
       S(3) = TH(1) * E_LCL(2,J) - TH(2) * E_LCL(1,J)                      
       DTT  = TH(1) * E_LCL(1,J) + TH(2) * E_LCL(2,J) 
     &      + TH(3) * E_LCL(3,J)                                           
       DO  K=1,3                                                           
        D_LCL(K,J) = E_LCL(K,J) * CT + 
     &                           D_2 * ( TH(K) * DTT - EC * S(K) )   
       END DO
      END DO                                                               
!C                                                                         
!C    Renormalization of direction cosine matrix                           
!C    by averaging matrix and transpose of its inverse.                    
!C                                                                         
      DO  ITER=1,NUM_ITER                                                        
       CALL CFACTT ( D_LCL, TEMP, DET )                                    
       DO  I=1,3                                                           
        DO  J=1,3                                                          
         D_LCL(I,J) = D_HALF * ( D_LCL(I,J) + TEMP(J,I) / DET )               
         IF ( ABS ( D_LCL(I,J) ) .LT. EPS(15) )  D_LCL(I,J) = D_0        
        END DO
       END DO
       IF ( ABS ( DET - D_1 ) .LT. EPS(6) )  THEN  
        RETURN
       END IF                              
      END DO                                                               
      WRITE ( LUAOU, 100 ) DET                                              
  100 FORMAT('0 DSETQ Renormalization did not converge, DET =',
     &        1PD25.15 )                                                   
!C
      RETURN                                                               
      END                                                                  
