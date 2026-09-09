      SUBROUTINE HYBND ( M, Z, IV, U_LCL, C_LCL, X )                       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH,    ! parameters 
     &       I_1, D_0, D_HALF, D_1000    ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER   ( KIND = INTEGER_STD)   I, IV, J, J1, J2, M
      DIMENSION  IV(12)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  Z, U_LCL, C_LCL, X, COMP, TEST, 
     &                  AMAX, ATST
      DIMENSION         Z(3,12), U_LCL(3), X(3)
!C
      REAL  ( KIND = IREAL_HIGH )  PREC_TEST
      PARAMETER  ( PREC_TEST = D_1000 )
!C                                                                         
!C    Searches for point nearest corner - direction C * U.                    
!C                                                                         
      DO  I = 1,M,2                                                        
       J = IV(I)                                                           
       ATST =   C_LCL * ( U_LCL(1) * Z(1,J) + U_LCL(2) * Z(2,J) 
     &        + U_LCL(3) * Z(3,J) )                                        
       IF ( I .EQ. I_1 )  THEN                                        
        AMAX = ATST                                                        
        J1 = J                                                             
        J2 = J                                                             
        CYCLE
       END IF
       TEST = AMAX - ATST                                                  
       COMP = MAX ( ABS ( AMAX ), ABS ( ATST ) )                           
!C
!C     Precision test -  try > PREC_TEST ?                  
!C
       IF ( PREC_TEST * ABS ( TEST ) .LT. COMP )  TEST = D_0          
!C
       IF ( TEST .LT. D_0 )  THEN
        AMAX = ATST                                                        
        J1 = J                                                             
        J2 = J                                                             
       ELSE IF ( TEST .EQ. D_0 )  THEN
        J2 = J
       END IF
      END DO                                                               
      DO  I = 1,3                                                          
       X(I) = D_HALF * ( Z(I,J1) + Z(I,J2) )                                 
      END DO
!C
      RETURN                                                               
      END                                                                  
