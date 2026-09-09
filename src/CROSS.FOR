      SUBROUTINE CROSS ( A, B_LCL, C_LCL )                                
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes vector cross product  C = A X B.                            
!C                                                                         
!C      Arguments                                                          
!C        A,B,C: vectors of length 3 where C=AXB.                          
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       IREAL_HIGH      ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )  A, B_LCL, C_LCL
      DIMENSION  A(3), B_LCL(3), C_LCL(3)                                  
!C
      INTENT (  IN ) A, B_LCL
      INTENT ( OUT ) C_LCL
!C
       C_LCL(1) = A(2) * B_LCL(3) - A(3) * B_LCL(2)                        
       C_LCL(2) = A(3) * B_LCL(1) - A(1) * B_LCL(3)                        
       C_LCL(3) = A(1) * B_LCL(2) - A(2) * B_LCL(1)                        
!C
      RETURN                                                               
      END                                                                 
