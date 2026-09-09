      SUBROUTINE  LUDCMP ( A, N, I_ORDER, ND )                           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    LU decomposition subroutine                                       
!C    Calls LUPIVT                                                      
!C    Called by INVERS                                                  
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                         ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH,     ! parameters
     &       D_0, I_0, I_1                ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           N, ND, I_ORDER(ND), I, NM1, JM1, JP1, IROW, JCOL, KCOL   
!C
      REAL  ( KIND = IREAL_HIGH )   A, SUM                                   
      DIMENSION          A(ND,ND)
!C
      DO  I=1,N
       I_ORDER(I) = I
      END DO
!C
      CALL LUPIVT ( A, N, I_ORDER, I_1, ND )
      IF ( ABS ( A(1,1) ) .LT. EPS(14) )  STOP 302
!C
      DO  KCOL=2,N
       A(1,KCOL) = A(1,KCOL) / A(1,1)
      END DO
!C
      NM1 = N - I_1
!C
      DO  JCOL=2,NM1
       JM1 = JCOL - I_1
       DO  IROW=JCOL,N
        SUM = D_0
        DO  KCOL=1,JM1
         SUM = SUM + A(IROW,KCOL) * A(KCOL,JCOL)
        END DO
        A(IROW,JCOL) = A(IROW,JCOL) - SUM
       END DO
!C
       CALL LUPIVT ( A, N, I_ORDER, JCOL, ND )
       IF ( ABS ( A(JCOL,JCOL) ) .LT. EPS(13) )  STOP 303
!C
       JP1 = JCOL + I_1
       DO  KCOL=JP1,N
        SUM = D_0
        DO  IROW=1,JM1
         SUM = SUM + A(JCOL,IROW) * A(IROW,KCOL)
        END DO
        A(JCOL,KCOL) = ( A(JCOL,KCOL) - SUM ) / A(JCOL,JCOL)
       END DO
!C
      END DO
!C
      SUM = I_0
      DO  KCOL = 1,NM1
       SUM = SUM + A(N,KCOL) * A(KCOL,N)
      END DO
      A(N,N) = A(N,N) - SUM
!C
      RETURN
      END
