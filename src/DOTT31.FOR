      SUBROUTINE DOTT31 ( A, B_LCL, C_LCL )                               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Performs matrix multiplication C = AB'                              
!C    where C is a 3X3 matrix, and A and B are vectors of length 3.       
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       IREAL_HIGH      ! parameters
!C
      IMPLICIT  NONE                                                      
!C
      INTEGER  I, J
!C
      REAL  ( KIND = IREAL_HIGH )  A, B_LCL, C_LCL
      DIMENSION  A(3), B_LCL(3), C_LCL(3,3)                               
!C
      INTENT (  IN )  A, B_LCL
      INTENT ( OUT )  C_LCL
!C
      DO  I=1,3                                                           
       DO  J=1,3                                                          
        C_LCL(I,J) = A(I) * B_LCL(J)                                      
       END DO
      END DO
!C
      RETURN                                                              
      END                                                                 
