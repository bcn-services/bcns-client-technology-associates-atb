      FUNCTION  VECMAG ( X )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Evaluates vector magnitude of the vector X.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       IREAL_HIGH    ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )   X, VECMAG 
      DIMENSION         X(3)                                       
!C
      INTENT ( IN )  X
!C
      VECMAG = SQRT ( X(1) * X(1) + X(2) * X(2) + X(3) * X(3) )
!C
      RETURN
      END
