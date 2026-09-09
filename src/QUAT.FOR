      SUBROUTINE QUAT ( ANG_LCL, Q )                                       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes quaternions from yaw, pitch, roll angles in degrees          
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        RADIAN,                        ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,       ! parameters 
     &        D_0, D_HALF, I_2, I_3          ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K
!C
      REAL  ( KIND = IREAL_HIGH )
     &            A, ANG_LCL, DOT_LCL, Q, R_LCL, SUM, T
!C
      DIMENSION  ANG_LCL(3), Q(4), R_LCL(4), T(3)                           
!C
      INTENT (  IN )  ANG_LCL
      INTENT ( OUT )  Q
!C
      A = D_HALF * ANG_LCL(1) * RADIAN                                       
      Q(1) = COS ( A )                                                     
      Q(2) = D_0                                                          
      Q(3) = D_0                                                           
      Q(4) = SIN ( A )                                                      
      K = I_3                                                          
      DO  I = 2,3                                                           
       A = D_HALF * ANG_LCL(I) * RADIAN                                     
       R_LCL(1) = COS ( A )                                                
       R_LCL(2) = D_0                                                    
       R_LCL(3) = D_0                                                      
       R_LCL(4) = D_0                                                      
       R_LCL(K) = SIN ( A )                                                
       DOT_LCL = Q(2) * R_LCL(2) + Q(3) * R_LCL(3) + Q(4) * R_LCL(4)       
       CALL CROSS ( Q(2), R_LCL(2), T )                                     
       DO  J = 2,4                                                          
        Q(J) = Q(1) * R_LCL(J) + R_LCL(1) * Q(J) + T(J-1)                   
       END DO
       Q(1) = Q(1) * R_LCL(1) - DOT_LCL                                    
       K = I_2                                                           
      END DO
      SUM = SQRT ( Q(1)**2 + Q(2)**2 + Q(3)**2 + Q(4)**2 )                  
      DO  I = 1,4                                                           
       Q(I) = Q(I) / SUM                                                   
      END DO
!C
      RETURN                                                                
      END                                                                  
