      FUNCTION RCRT ( A, PL_LCL, Z, IP )                
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the radius of curvature at point Z of ellipsoid A            
!C    in the plane PL(I,IP) where                                           
!C                                                                          
!C         A: 3X3 matrix defining ellipsoid.                                
!C        PL: 4X3 matrix containing three orthonormal vectors.              
!C         Z: 3 coordinates of point on the ellipsoid                       
!C            as measured from center of ellipsoid                         
!C        IP: identifies the normal vector of plane in which the            
!C            radius of curvature is desired.                               
!C                                                                          
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, I_1, I_2, I_3, D_0, D_2  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IP, J, M, N
!C
      REAL  ( KIND = IREAL_HIGH )  RCRT
      REAL  ( KIND = IREAL_HIGH )
     &                  A, PL_LCL, S1_LCL, S2, T, W_LCL, Z
      DIMENSION         A(3,3), PL_LCL(4,3), Z(3), T(5)                     
!C
      T = D_0 
      M = IP + I_1                                                       
      N = IP + I_2                                                       
      IF ( M .GT. I_3 )  M = M - I_3                               
      IF ( N .GT. I_3 )  N = N - I_3                                
      DO  I=1,3                                                             
       S1_LCL = D_0                                                       
       S2     = D_0                                                       
       DO  J=1,3                                                            
        S1_LCL = S1_LCL + A(I,J) * PL_LCL(J,M)                              
        S2     = S2     + A(I,J) * PL_LCL(J,N)                              
       END DO
       T(1) = T(1) + S1_LCL * Z(I)                                          
       T(2) = T(2) + S2     * Z(I)                                          
       T(3) = T(3) + S1_LCL * PL_LCL(I,M)                                   
       T(4) = T(4) + S2     * PL_LCL(I,N)                                   
       T(5) = T(5) + S1_LCL * PL_LCL(I,N)                                   
      END DO
      W_LCL = SQRT ( T(1)**2 + T(2)**2 )                                    
      T(1) = T(1) / W_LCL                                                   
      T(2) = T(2) / W_LCL                                                   
      RCRT = W_LCL / (   T(3) * T(2)**2 - D_2 * T(1) * T(2) * T(5)
     &                 + T(4) * T(1)**2 )                                   
      IF ( RCRT .LT. D_0 )  RCRT = -RCRT                                  
!C
      RETURN                                                                
      END                                                                  
