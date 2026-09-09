      SUBROUTINE HYABF ( B_LCL, Z, A, F_LCL )                              
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                         
!C    Calculates A, AZ, Z.AZ:  old form must be diagonal.                   
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH, D_0, D_1, D_2, I_1   ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J
!C
      REAL  ( KIND = IREAL_HIGH )  B_LCL, Z, A, F_LCL, P2
      DIMENSION         B_LCL(24), Z(3), A(3,3)                            
!C
      REAL  ( KIND = IREAL_HIGH )   HYFCN
      EXTERNAL          HYFCN
!C
      P2 = D_0                                                          
      IF ( B_LCL(1) .LT. D_0 )   P2 = -B_LCL(1) - D_2                   
      F_LCL = D_0                                                         
      DO  I = 1,3                                                          
       J = I                                                               
       IF ( B_LCL(1) .LT. D_0 )  THEN                                   
        A(I,1) = B_LCL(I+16)                                               
        J = J + I_1                                                    
        A(I,1) = HYFCN ( A(I,1), Z(I), B_LCL(J), P2 )                      
       ELSE
        A(I,1) = D_1 / B_LCL(I)**2                                       
       END IF
!C
!C     If ( P2 .GT. 0.0 )A(I,1) = A(I,1) * DABS( Z(I) / B(J) )**P2                    
!C
       DO  J = 2,3                                                         
        A(I,J) = A(I,J-1) * Z(I)                                           
       END DO
       F_LCL = F_LCL + A(I,3)                                              
      END DO
!C
      RETURN                                                               
      END                                                                  
