      SUBROUTINE INTERS_SOLVE ( IDONE, ITER, FA, FB, T, X,
     &                          A, AX, B_LCL, V, ITER_FAIL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C    
!C    This subroutine is called only by Subroutine INTERS.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                  ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,       ! parameters
     &       LOGICAL_STD, TRUE, FALSE,             ! parameters
     $       D_0, D_HALF, D_1, I_1, I_3, I_50      ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IDONE, ITER, J, MAX_INTERS
!C
      REAL  ( KIND = IREAL_HIGH ) 
     &            A, B_LCL, X, C_LCL, Z, AX, DV, FA, FB, FPA, V, T
      DIMENSION   A(3,3), B_LCL(3,3), X(3), C_LCL(3,4), Z(3), AX(3)
!C
      EQUIVALENCE ( Z(1), C_LCL(1,4) )                                    
!C
      PARAMETER ( MAX_INTERS = I_50 )
!C
      LOGICAL  ( KIND = LOGICAL_STD )  ITER_FAIL
!C
      INTENT (    IN )  ITER, FA, FB, T, X, A, AX, B_LCL
      INTENT (   OUT )  IDONE, ITER_FAIL
      INTENT ( INOUT )  V
!C
!C           Solve (VA + B)Z = AX  for Z         
!C
      DO  I=1,3                                                           
       DO  J=1,3                                                          
        C_LCL(I,J) = V * A(I,J) + B_LCL(I,J)                              
       END DO
      END DO
      Z = AX
      CALL DSMSOL ( C_LCL, I_3 )                                            
!C   
!C           F'A(V) = -2X'AZ                   
!C
      CALL MAT31 ( A, Z, AX )                                             
      FPA = X(1) * AX(1)                                                  
     &    + X(2) * AX(2)                                                  
     &    + X(3) * AX(3)                                                  
      FPA = -( FPA + FPA )                                                
!C
!C           DV = -G(V) / G'(V)                  
!C
      DV = D_1 + V                                                      
      IF ( T .LT. D_0 )  DV = V - FA**2                               
      DV = ( FB - FA ) / ( DV * FPA )                                     
      IF ( ITER .GE. MAX_INTERS )   THEN                                  
       WRITE ( LUAOU, 110 )                                           
  110  FORMAT ( ' INTERS iteration did not converge!' )                 
       ITER_FAIL = TRUE
       RETURN
      ELSE
       ITER_FAIL = FALSE
      END IF
!C
!C           Test for convergence             
!C 
      IF ( T * ( V + DV ) .LE. D_0 )  DV = -D_HALF * V                      
      V   = V + DV                                                        
      DV = ABS ( DV / V )                                                 
      IF ( DV .LE. EPS(12) )   IDONE = I_1                              
!C
      RETURN
      END