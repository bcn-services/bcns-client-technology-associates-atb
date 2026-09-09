      SUBROUTINE QSET ( F_LCL, Y_LCL, X, DER_LCL, N )                       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, MAXEQN, D_1 ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, J, N
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  DER_LCL, E1, E1D, E2, E2D, EB, EC, F_LCL, 
     &                  T1, T2_LCL, T3, T4, UDB, UDD, UHB, UHC, X,
     &                  Y_LCL
!C
      DIMENSION F_LCL(5,3,MAXEQN), Y_LCL(5,3,MAXEQN), X(3,MAXEQN),
     &          DER_LCL(3,MAXEQN), T1(3), T2_LCL(3), T3(3), T4(3)           
!C
      DO  I=1,N                                                             
       E1  = SQRT ( D_1 - X(1,I)**2 - X(2,I)**2 - X(3,I)**2 )             
       E1D = -( X(1,I) * DER_LCL(1,I) + 
     &          X(2,I) * DER_LCL(2,I) +
     &          X(3,I) * DER_LCL(3,I) ) / E1                               
       E2 = SQRT (   D_1 - Y_LCL(1,1,I)**2 - Y_LCL(1,2,I)**2 
     &              - Y_LCL(1,3,I)**2 )                                     
       E2D = -( Y_LCL(1,1,I) * Y_LCL(2,1,I) + 
     &          Y_LCL(1,2,I) * Y_LCL(2,2,I) + 
     &          Y_LCL(1,3,I) * Y_LCL(2,3,I) ) / E2                          
       UHB = X(1,I) * F_LCL(3,1,I) + X(2,I) * F_LCL(3,2,I) +
     &       X(3,I) * F_LCL(3,3,I)                                         
       UHC = X(1,I) * F_LCL(4,1,I) + X(2,I) * F_LCL(4,2,I) + 
     &       X(3,I) * F_LCL(4,3,I)                                         
       UDB = DER_LCL(1,I) * F_LCL(3,1,I) +
     &       DER_LCL(2,I) * F_LCL(3,2,I) +
     &       DER_LCL(3,I) * F_LCL(3,3,I)                                   
       UDD = DER_LCL(1,I)**2 + DER_LCL(2,I)**2 + DER_LCL(3,I)**2            
       EB = ( E1D**2 + UDD + UHB ) / E1                                    
       EC = ( 1.5_IREAL_HIGH * ( UDB - E1D * EB ) + UHC 
     &        + F_LCL(5,1,I) * ( E1D**2 + UDD ) ) / E1                      
       T1(1)     = X(2,I) * F_LCL(3,3,I) - X(3,I) * F_LCL(3,2,I)           
       T2_LCL(1) = X(2,I) * F_LCL(4,3,I) - X(3,I) * F_LCL(4,2,I)            
       T3(1)     = X(2,I) * Y_LCL(1,3,I) - X(3,I) * Y_LCL(1,2,I)            
       T4(1)     = X(2,I) * Y_LCL(2,3,I) - X(3,I) * Y_LCL(2,2,I)            
       T1(2)     = X(3,I) * F_LCL(3,1,I) - X(1,I) * F_LCL(3,3,I)            
       T2_LCL(2) = X(3,I) * F_LCL(4,1,I) - X(1,I) * F_LCL(4,3,I)            
       T3(2)     = X(3,I) * Y_LCL(1,1,I) - X(1,I) * Y_LCL(1,3,I)            
       T4(2)     = X(3,I) * Y_LCL(2,1,I) - X(1,I) * Y_LCL(2,3,I)            
       T1(3)     = X(1,I) * F_LCL(3,2,I) - X(2,I) * F_LCL(3,1,I)            
       T2_LCL(3) = X(1,I) * F_LCL(4,2,I) - X(2,I) * F_LCL(4,1,I)            
       T3(3)     = X(1,I) * Y_LCL(1,2,I) - X(2,I) * Y_LCL(1,1,I)            
       T4(3)     = X(1,I) * Y_LCL(2,2,I) - X(2,I) * Y_LCL(2,1,I)            
       DO  J=1,3                                                           
        F_LCL(3,J,I) = E1 * F_LCL(3,J,I) - T1(J)     + EB  * X(J,I)      
        F_LCL(4,J,I) = E1 * F_LCL(4,J,I) - T2_LCL(J) + EC  * X(J,I)      
        Y_LCL(3,J,I) = E1 * Y_LCL(1,J,I) - T3(J)     - E2  * X(J,I)       
        Y_LCL(4,J,I) = E1 * Y_LCL(2,J,I) - T4(J)     - E2D * X(J,I)       
       END DO
      END DO
!C
      RETURN                                                                
      END                                                                  
