      SUBROUTINE TRNPOS ( A, AT, N, M, ND, MD )                         
!C
!C                                                   Rev. V.2 03/15/2002 
!C
!C**********************************************************************
!C*   Transpose of A matrix: AT = transpose(A)                          
!C*   Called by FXMASS                                                  
!C**********************************************************************
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, J, N, M, ND, MD                                             DEFORM
!C
      REAL   ( KIND = IREAL_HIGH )   A, AT  
      DIMENSION  A(ND,MD), AT(MD,ND)                                    
!C
      INTENT (  IN )  A, N, M, ND, MD
      INTENT ( OUT )  AT
!C
      DO  I=1,N
       DO  J=1,M
        AT(J,I) = A(I,J)
       END DO
      END DO
!C
      RETURN
      END
