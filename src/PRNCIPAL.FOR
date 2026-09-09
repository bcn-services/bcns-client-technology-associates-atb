      SUBROUTINE PRNCIPAL ( PTOT, X1, X2, X3, PRNAXS )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Subroutine PRNCIPLE computes the principal moments of inertia (X1,X2,X3)
!C     for the whole-body based upon the previously calculated whole-body 
!C     moments of inertia.  It also calculates the principal directions 
!C     with the utilization of the computed direction cosine matrix.  
!C
!C    The previous whole body axes are rotated in an order of yaw, pitch,  
!C     and roll (PRNAXS(J),J=1,3) to give the principal axis system.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        PI,                               ! /CNSNTS/
     &        IREAL_HIGH, LUAOU,                ! parameters
     &        D_0, D_1, D_2, D_3, D_4, D_9      ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A, CHECK, PRNAXS, PTOT, Q, R, 
     &                  R_I1, R_I2, R_I3, R_I, R_L, R_M, R_N,  
     &                  R_IXX, R_IYY, R_IZZ, R_IXY, R_IYZ, R_IXZ,
     &                  TEMP, THETA, X1, X2, X3, Z
      DIMENSION         A(3,3), PTOT(3,3), PRNAXS(3)
!C
      INTENT (  IN )  PTOT
      INTENT ( OUT )  X1, X2, X3, PRNAXS
!C
!C    Characteristic equation element computation.
!C  
      R_IXX = PTOT(1,1) 
      R_IYY = PTOT(2,2)
      R_IZZ = PTOT(3,3)
      R_IXY = PTOT(1,2)
      R_IYZ = PTOT(2,3)
      R_IXZ = PTOT(3,1)
!C     
!C    Determine the inertial invarients, I1, I2, I3, which are
!C    the coefficients to the cubic equation [(X**3)-I1*(X**2)+I2*(X)-I3=0].  
!C
!C    Perform transformations of I1 and I3 in order to satisfy the 
!C    aforementioned cubic equation.  
!C
      R_I1 = ( -D_1 ) * ( R_IXX + R_IYY + R_IZZ )
      R_I2 =    R_IXX * R_IYY + R_IYY * R_IZZ + R_IZZ * R_IXX 
     &                        - R_IXY**2 - R_IYZ**2 - R_IXZ**2 
      R_I3 = (-D_1) * (       ( R_IXX * R_IYY * R_IZZ) 
     &                + D_2 * ( R_IXY * R_IYZ * R_IXZ)
     &                      - R_IXX * R_IYZ**2
     &                      - R_IYY * R_IXZ**2 
     &                      - R_IZZ * R_IXY**2  )
!C 
!C    In order to solve the cubic equations, determin constants Q and R. 
!C
!C    Solution to characteristic equation for eigenvalues (= principal 
!C    moments)
!C
      Q = ( R_I1**2 - D_3 * R_I2 ) / D_9
      R = ( ( D_2 * R_I1**3 ) - ( D_9 * R_I1 * R_I2 ) 
     &      + ( 27.0_IREAL_HIGH * R_I3) ) / 54.0_IREAL_HIGH
!C                           
!C    Q and R are variables with no relation to the inertial values 
!C    that are used during the solution of the cubic equation.        
!C
!C    Check that (Q**3) - (R**2) is greater than or equal to zero.  If 
!C    this holds, then the cubic equation has D_3 real roots.  
!C
      CHECK = Q**3 - R**2
      IF ( CHECK .GE. D_0 ) THEN
       THETA = ACOS ( R / Q**1.5_IREAL_HIGH ) 
!C
!C     The D_3 roots to the characteristic equation are determined
!C     from the following.  
!C
       X1 = -D_2 * SQRT ( Q ) * COS ( THETA / D_3 ) 
     &                               - ( R_I1 / D_3 )
       X2 = -D_2 * SQRT ( Q ) * COS ( ( THETA + ( D_2 * PI ) ) / D_3 )
     &                               - ( R_I1 / D_3 )
       X3 = -D_2 * SQRT ( Q ) * COS ( ( THETA + ( D_4 * PI ) ) / D_3)
     &                               - ( R_I1 / D_3 )  
      ELSE
       WRITE ( LUAOU, 120 ) 
  120  FORMAT ( 1X, 'Only one root for inertia matrix. ' )
      END IF
!C                     
!C    X1, X2, X3 are the principal moments of inertia.  
!C  
!C    This routine will perform a bubble sort (the values bubble up through
!C    the array) of the principal moments of inertia.  It will compare 
!C    the elements in the first D_2 positions; if they are out of 
!C    order, it will then swap them.  The benefit of the bubble 
!C    sort is that other large elements will tend to move along 
!C    the list--not just the largest.  
!C
      IF ( X1 .GT. X2 ) THEN
       TEMP = X1
       X1   = X2
       X2   = TEMP
      ELSE IF ( X2 .GT. X3 ) THEN
       TEMP = X2
       X2 = X3
       X3 = TEMP
      END IF                    
!C
!C    Computation of eigenvalues for principal moments of inertia.  
!C    Determine direction cosine matrix letting
!C    R_L, R_M, R_N be the eigenvectors corresponding to each
!C    eigenvalue.  
!C
!C    Let R_L = 1.0 
!C    Let R_I = X1
!C
      R_L = D_1
      R_I = X1
      R_N =   ( R_IXZ * ( R_IYY - R_I ) +  R_IYZ * R_IXY ) 
     &      / ( ( R_IYY - R_I ) * ( R_IZZ - R_I ) - R_IYZ**2 )
      R_M = ( R_IXY * R_L  + R_IYZ * R_N ) / ( R_IYY - R_I )
!C
!C    (R_L**2) + (R_M**2) + (R_N**2) = 1.0  This relation must be satisfied
!C    by the direction cosines.  
!C
!C    Normalize the vector
!C
      Z = SQRT ( R_L**2 + R_M**2 + R_N**2 )
      A(1,1) = R_L / Z
      A(1,2) = R_M / Z
      A(1,3) = R_N / Z
!C
!C    Then, the values of R_L, R_M, and R_N may be directly determined.   
!C
!C    LET R_M = 1
!C    LET R_I = X2
!C
      R_M = D_1
      R_I = X2
      R_L = ( R_IXY * ( R_IZZ - R_I ) + R_IXZ * R_IYZ ) /
     &      ( ( R_IXX - R_I ) * ( R_IZZ - R_I ) - R_IXZ**2 )
      R_N = ( R_IXZ * R_L + R_IYZ * R_M ) / ( R_IZZ - R_I )
!C
!C    Normalize the vector
!C
      Z = SQRT ( R_L**2 + R_M**2 + R_N**2 )
!C
      A(2,1) = R_L / Z
      A(2,2) = R_M / Z
      A(2,3) = R_N / Z
!C
!C    Let R_N = 1
!C    Let R_I = X3
!C
      R_N = D_1
      R_I = X3
      R_M = ( R_IXY * R_IXZ + R_IYZ * ( R_IXX - R_I ) ) /
     &      ( ( R_IXX - R_I ) * ( R_IYY - R_I ) - R_IXY**2 )
      R_L = ( R_IXY * R_M + R_IXZ * R_N ) / ( R_IXX - R_I )
!C
!C    Normalize the vector
!C
      Z = SQRT ( R_L**2 + R_M**2 + R_N**2 )
!C
      A(3,1) = R_L / Z
      A(3,2) = R_M / Z
      A(3,3) = R_N / Z
!C
!C    Compute yaw, pitch, and roll (deg) from the direction consine matrix.
!C    
      CALL YPRDEG ( A, PRNAXS )
!C
      RETURN
      END
