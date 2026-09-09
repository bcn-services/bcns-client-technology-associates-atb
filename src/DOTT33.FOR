      SUBROUTINE DOTT33 ( A, B_LCL, C_LCL )                               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C     Performs matrix multiplication C = AB'                             
!C     where A, B and C are all 3X3 matrices.                             
!C                                                                        
      IMPLICIT  NONE                                                      
!C
      INTEGER  I, J
!C
      DOUBLE PRECISION  A, B_LCL, C_LCL
      DIMENSION  A(3,3), B_LCL(3,3), C_LCL(3,3)                           
!C
      INTENT  (  IN )  A, B_LCL
      INTENT  ( OUT )  C_LCL
!C
      DO  I=1,3                                                           
       DO  J=1,3                                                          
        C_LCL(I,J) =   A(I,1) * B_LCL(J,1) 
     &               + A(I,2) * B_LCL(J,2)
     &               + A(I,3) * B_LCL(J,3)                                
       END DO
      END DO
!C
      RETURN                                                              
      END                                                                 
