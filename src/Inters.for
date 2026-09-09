      SUBROUTINE INTERS ( A, B_LCL, XM, T, X, V, AX )                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Determines intersection of ellipsoids                               
!C        X'AX = 1                                                        
!C        (X'-M')B(X-M) = 1                                               
!C    where A and B are ellipsoid matrices                                
!C    If T enters as +1.0 , A is external to B and                        
!C                as -1.0 , A is internal to B.                           
!C                                                                        
!C    If V enters as non-zero, will use previous value for start.         
!C    (AX) returns as (A)*(X).                                            
!C                                                                        
!C    Returns T>1 - no intersection                                       
!C            T<1 - intersection in which case X will                     
!C                  contain coordinates of contact of                     
!C                  contracted ellipsoids.                                
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,      logical_std,                          ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,     ! parameters
     $       D_0, D_HALF, D_1, I_0, I_1, I_3, I_50    ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IDONE, ITER, J, MAX_INTERS, N
!C
      REAL  ( KIND = IREAL_HIGH ) 
     &                  A, B_LCL, XM, X, C_LCL, Z, BM, AX, AM,
     &                  AMM, BMM, FA, FB, V, T
      DIMENSION         A(3,3), B_LCL(3,3), XM(3), X(3),                  
     &                  C_LCL(3,4), Z(3), BM(3), AX(3), AM(3)             
!C
      EQUIVALENCE ( Z(1), C_LCL(1,4) )                                    
!C
      PARAMETER ( MAX_INTERS = I_50 )
!C
!C
      LOGICAL  ( KIND = LOGICAL_STD )  ITER_FAIL
!C
!C    Initialization                        
!C     evaluate BM, M'AM, M'BM             
!C     set N = 0, V = M'BM / M'AM              
!C
      N = I_0                                                          
      DO  I=1,3                                                           
       BM(I) = D_0                                                       
       AM(I) = D_0                                                     
       DO  J=1,3                                                          
        IF ( ABS ( A(I,J) ) .LT. EPS(20) )  A(I,J) = D_0             
        AM(I) = AM(I) + A(I,J) * XM(J)                                    
        IF ( ABS ( B_LCL(I,J) ) .LT. EPS(20) )  B_LCL(I,J) = D_0       
        BM(I) = BM(I) + B_LCL(I,J) * XM(J)                                
       END DO
      END DO
      BMM = DOT_PRODUCT ( XM, BM )
      AMM = DOT_PRODUCT ( XM, AM )
      IF ( V .EQ. D_0 )  V = T * SQRT ( BMM / AMM )                      
      IDONE = I_0                                                      
!C
!C    Newton-Raphson iteration for G(V) = FA(V) - FB(V) = 0.               
!C    Solve ( VA + B )X = BM  for X.         
!C
      ITER = I_0                                                        
      DO
       ITER = ITER + I_1                                                  
       DO I=1,3
        DO J=1,3
         C_LCL(I,J) = V * A(I,J) + B_LCL(I,J)                        
        END DO
       END DO
       Z   = BM                                                
       CALL DSMSOL ( C_LCL, I_3 )                                            
!C
!C     Evaluate AX                       
!C     FA(V) = X'AX             
!C     FB(V) = -V(X' - M')AX      
!C
       CALL MAT31 ( A, Z, AX )                                             
       X = Z
       FA = DOT_PRODUCT ( X, AX )
       FB = -V * DOT_PRODUCT ( ( X - XM ), AX ) 
       IF ( T .LT. D_0 )  FA = D_1 / FA                               
       IF ( IDONE .EQ. I_1 )  EXIT                                  
!C
!C     Test for intersection             
!C
       IF ( ( FA - FB ) .LT. D_0 )  THEN                                   
!C
!C      If FA < FB < 1 , intersection         
!C
        IF ( ( T .GT. D_0 ) .AND. ( FB .LE. D_1 ) )  N = I_1                  
        IF ( ( T .LT. D_0 ) .AND. ( FA .GE. D_1 ) )  N = I_1              
!C
!C      Solve ( VA + B )Z = AX  for Z         
!C
        CALL INTERS_SOLVE ( IDONE, ITER, FA, FB, T, X, A, AX, B_LCL, 
     &                      V, ITER_FAIL )
        IF ( ITER_FAIL )  RETURN
        CYCLE
       ELSE IF ( ( FA - FB ) .EQ. D_0 )  THEN
        EXIT
       END IF
!C
!C     If FA > FB > 1, no intersection       
!C
       IF ( ( T .GT. D_0 ) .AND. ( FB .LT. D_1 ) )   THEN
!C
!C      Solve ( VA + B )Z = AX  for Z         
!C
        CALL INTERS_SOLVE ( IDONE, ITER, FA, FB, T, X, A, AX, B_LCL, 
     &                      V, ITER_FAIL )
        IF ( ITER_FAIL )  RETURN
        CYCLE
       ELSE IF ( ( T .LT. D_0 ) .AND. ( FA .GT. D_1 ) )  THEN
        CALL INTERS_SOLVE ( IDONE, ITER, FA, FB, T, X, A, AX, B_LCL, 
     &                      V, ITER_FAIL )
        IF ( ITER_FAIL )  RETURN
        CYCLE           
       END IF
!C
       IF ( N .EQ. I_0 ) THEN
        EXIT                                   
       ELSE
        WRITE ( LUAOU, 100 )                                                
  100   FORMAT ( ' INTERS Iteration did not converge!' )                   
        RETURN                                                             
       END IF
      END DO                                                          
!C
!C    FA(V) = FB(B), return                 
!C
      IF ( T .LT. D_0 )  FA = D_1 / FB                                
      T = SQRT ( FA )                                                     
      IF ( FA .LE. D_1 )   THEN                                         
       N = I_1                                                           
       RETURN                                                             
      END IF
      IF  ( N .NE. I_0 )  THEN                                        
       WRITE ( LUAOU, 110 )                                              
  110  FORMAT ( ' INTERS iteration did not converge!' )                 
      END IF
!C
      RETURN                                                              
      END                                                                 
