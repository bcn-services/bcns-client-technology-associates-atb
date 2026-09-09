      SUBROUTINE TILDE ( A, AT )                                        
!C
!C                                                     Rev. V.3 12/15/02 
!C
!C    Construct a skew-symmetric matrix A~ from vector A.                  
!C    Called by FJNTVC, FXMASS, FSETUP.                                    
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       IREAL_HIGH, D_0  ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH ) A(3), AT(3,3)                        
!C
      INTENT (  IN )  A
      INTENT ( OUT )  AT
!C
      AT(1,1) = D_0
      AT(2,2) = D_0
      AT(3,3) = D_0
      AT(1,2) = -A(3)
      AT(2,1) =  A(3)
      AT(1,3) =  A(2)
      AT(3,1) = -A(2)
      AT(2,3) = -A(1)
      AT(3,2) =  A(1)
!C
      RETURN
      END
