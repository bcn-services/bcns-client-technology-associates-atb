      SUBROUTINE DRCQUA ( DC, Q )                                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes direction cosine matrix from quaternions.                   
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH,   ! parameters
     &        D_1, D_2, I_1, I_3         ! parameters
!C
      IMPLICIT  NONE                                                      
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K
!C
      REAL  ( KIND = IREAL_HIGH )   C_LCL, D_LCL, DC, E_LCL, Q
      DIMENSION  DC(3,3), Q(4)                                            
!C
      INTENT (  IN )  Q
      INTENT ( OUT )  DC
!C
!C    Compute the diagonal terms, and parts of the off-diagonal
!C     terms of the direction cosine matrix.
!C
      C_LCL = Q(1)**2 - Q(2)**2 - Q(3)**2 - Q(4)**2                       
      DO  I = 1,3                                                         
       DO  J = 1,3                                                        
        DC(I,J) = D_2 * Q(I+1) * Q(J+1)                                  
       END DO
       DC(I,I) = DC(I,I) + C_LCL                                          
      END DO
!C
!C    Compute the off-diagonal terms of the direction cosine matrix.
!C
      E_LCL = Q(1) + Q(1)                                                 
      DO  I = 1,3                                                         
       J = I_1 + MOD( I, I_3 )                                
       K = I_1 + MOD( ( I + I_1 ), I_3 )             
       D_LCL = E_LCL * Q(I+1)                                             
       DC(K,J) = DC(K,J) - D_LCL                                          
       DC(J,K) = DC(J,K) + D_LCL                                          
      END DO
!C
!C    Limit the magnitude of the components of the dirction cosine
!C     matrix, DC(I,J) to 1.0.  Magnitudes with values greater than
!C     could only occur because of numerical round-off errors.
!C
      DO  I =1,3                                                          
       DO  J = 1,3                                                        
        IF( ABS( DC(I,J) ) .GT. D_1 )  THEN
         DC(I,J) = SIGN( D_1, DC(I,J) )                    
        END IF
       END DO
      END DO
!C
      RETURN                                                              
      END                                                                 
