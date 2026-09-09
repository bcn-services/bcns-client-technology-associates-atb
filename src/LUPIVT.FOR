      SUBROUTINE LUPIVT ( A, N, I_ORDER, JCOL, ND )                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Row pivoting subroutine.                                           
!C    Called by LUDCMP.                                                  
!C
      USE  MODULE_STANDARD,   ONLY: 
     &       INTEGER_STD, IREAL_HIGH, I_1    ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              N, ND, I_ORDER, JCOL, KCOL, IPVT, JP1, IROW, ISAVE 
      DIMENSION  I_ORDER(ND)
!C
      REAL  ( KIND = IREAL_HIGH  )  A, BIG, RSAVE, ANEXT              
      DIMENSION         A(ND,ND)
!C
      IPVT = JCOL
      BIG = ABS ( A(JCOL,JCOL) )
      JP1 = JCOL + I_1
!C
      DO  IROW = JP1,N
       ANEXT = ABS ( A(IROW,JCOL) )
       IF ( ANEXT .GT. BIG )  IPVT = IROW
      END DO
!C
      IF ( IPVT .EQ. JCOL )  RETURN
!C
      DO  KCOL=1,N
       RSAVE = A(JCOL,KCOL)
       A(JCOL,KCOL) = A(IPVT,KCOL)
       A(IPVT,KCOL) = RSAVE
      END DO
!C
      ISAVE = I_ORDER(JCOL)
      I_ORDER(JCOL) = I_ORDER(IPVT)
      I_ORDER(IPVT) = ISAVE
!C
      RETURN
      END
