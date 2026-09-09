      SUBROUTINE DOT31 ( A, B_LCL, C_LCL )                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Performs matrix multiplication C = A'B                               
!C    where A is a 3X3 matrix, and B and C are vectors of length 3.        
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       IREAL_HIGH      ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )  A, B_LCL, C_LCL
      DIMENSION  A(3,3) , B_LCL(3) , C_LCL(3)                              
!C
      INTENT ( IN )   A, B_LCL
      INTENT ( OUT )  C_LCL
!C
      C_LCL(1) = A(1,1) * B_LCL(1) + A(2,1) * B_LCL(2)
     &                             + A(3,1) * B_LCL(3)                     
      C_LCL(2) = A(1,2) * B_LCL(1) + A(2,2) * B_LCL(2) 
     &                             + A(3,2) * B_LCL(3)                     
      C_LCL(3) = A(1,3) * B_LCL(1) + A(2,3) * B_LCL(2) 
     &                             + A(3,3) * B_LCL(3)                     
!C
      RETURN                                                               
      END                                                                  
