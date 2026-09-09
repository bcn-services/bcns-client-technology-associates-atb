      SUBROUTINE UNTVEC ( X, UX )                                       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the unit vector, UX of the vector X.                          
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH, D_0  ! parameters
!C
      IMPLICIT  NONE                                                    
!C
      INTEGER  ( KIND = INTEGER_STD )  I
!C
      REAL  ( KIND = IREAL_HIGH )  UX, X, XM
      DIMENSION         X(3), UX(3)
!C
      REAL  ( KIND = IREAL_HIGH )  VECMAG
      EXTERNAL          VECMAG
!C
      INTENT (  IN )  X
      INTENT ( OUT )  UX
!C
      XM = VECMAG ( X )
      IF (XM .GT. D_0 ) THEN
       DO  I = 1,3
        UX(I) = X(I) / XM
       END DO
      ELSE
       DO  I = 1,3
        UX(I) = X(I)
       END DO
      END IF
!C
      RETURN
      END
