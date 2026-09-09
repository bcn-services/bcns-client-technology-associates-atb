      SUBROUTINE HYDAD ( D_LCL, A, DAD )                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes D_LCL'A(*,1)D_LCL                                           
!C
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH, D_0      ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( INTEGER_STD )  I, J, K
!C
      REAL  ( KIND = IREAL_HIGH )   A, D_LCL, DAD
      DIMENSION         D_LCL(3,3), A(3), DAD(3,3)                         
!C
      INTENT (  IN )  D_LCL, A
      INTENT ( OUT )  DAD
!C
      DO  I = 1,3                                                          
       DO  J = 1,3                                                         
        DAD(I,J) = D_0                                                  
        DO  K = 1,3                                                        
         DAD(I,J) = DAD(I,J) + D_LCL(K,I) * A(K) * D_LCL(K,J)              
        END DO
       END DO
      END DO
!C
      RETURN                                                               
      END                                                                  
