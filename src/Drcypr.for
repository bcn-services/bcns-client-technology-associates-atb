      SUBROUTINE DRCYPR ( D_LCL, A, ID )                                  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Sets up 3X3 direction cosine matrix for given yaw,pitch and roll.   
!C                                                                        
!C      Arguments:                                                        
!C    D_LCL: 3X3 direction cosine matrix to be computed.                  
!C        A: array of length 3 containing rotatation angles (degrees).    
!C       I1: axis of rotation for 1st angle (1,2,3 = X,Y,Z)               
!C       I2: axis of rotation for 2nd angle (1,2,3 = X,Y,Z)               
!C       I3: axis of rotation for 3rd angle (1,2,3 = X,Y,Z)               
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &        RADIAN,                   ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,  ! parameters 
     &        D_0, D_1, I_0, I_2        ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, ID, IDN, IDSUM, J, K, M, N
      DIMENSION  ID(3)
!C
      REAL  ( KIND = IREAL_HIGH )   D_LCL, A, T, B_LCL, S
      DIMENSION  D_LCL(3,3), A(3), T(3,3), B_LCL(3), S(3)                 
!C
      INTENT  (  IN )  A, ID
      INTENT  ( OUT )  D_LCL
!C
      IDSUM = ID(1) + ID(2) + ID(3)                                       
      DO  I=1,3                                                           
       B_LCL(I) = A(I) * RADIAN                                           
       DO  J=1,3                                                          
        D_LCL(I,J) = D_0                                              
       END DO
       D_LCL(I,I) = D_1                                                   
      END DO
!C
      DO  N=1,3                                                           
       IDN = ABS( ID(N) )                                                 
       M = 4 - IDN                                                        
       IF  ( ID(N) .LT. I_0 )  M = IDSUM - ID(N) - I_2              
       IF  ( B_LCL(M) .NE. D_0 )   THEN                              
        CALL ROT ( T, IDN, B_LCL(M) )                                     
        DO  J=1,3                                                         
         DO  K=1,3                                                        
          S(K) = D_LCL(K,J)                                               
          D_LCL(K,J) = D_0                                             
         END DO
         DO  I=1,3                                                        
          DO  K=1,3                                                       
           D_LCL(I,J) = D_LCL(I,J) + T(I,K) * S(K)                        
          END DO
         END DO
        END DO                                                            
       END IF                                                             
      END DO
!C
      RETURN                                                              
      END                                                                 
