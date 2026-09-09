      SUBROUTINE DOT33 ( A, B_LCL, C_LCL )                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Performs matrix multiplication C = A'B                               
!C    where A, B and C are all 3X3 matrices.                               
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH      ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  (KIND = INTEGER_STD )  I, J
!C
      REAL  ( KIND = IREAL_HIGH )   A, B_LCL, C_LCL
      DIMENSION  A(3,3) , B_LCL(3,3) , C_LCL(3,3)                          
!C
      INTENT (  IN )  A, B_LCL
      INTENT ( OUT )  C_LCL
!C
      DO  I=1,3                                                            
       DO  J=1,3                                                           
        C_LCL(I,J) =    A(1,I) * B_LCL(1,J) 
     &                + A(2,I) * B_LCL(2,J)
     &                + A(3,I) * B_LCL(3,J)                                
       END DO
      END DO
!C
      RETURN                                                               
      END                                                                  
