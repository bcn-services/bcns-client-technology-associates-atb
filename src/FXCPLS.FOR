      SUBROUTINE FXCPLS ( M, N, XM, XN, FRC )                           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    Finds nodes of contact and adds the contact force to nodal forces.   
!C    Called by PLSEGF.                                                     
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, D_0, D_1, I_0    ! parameters  
!C
      USE  MODULE_FLEXIBLE,  ONLY:  FIK, QNOD,          ! /FXBODY/
     &                              NFBOD, NNOD, IBODN, ! /FXVAR/
     &                              SMALL_START         ! parameters
!C 
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K, M, N, NCNT
!C
      REAL  ( KIND = IREAL_HIGH )  XM, XN, FRC, X, CV, FRCSN, SMALL
      DIMENSION         XM(3), XN(3), FRC(3), X(3)                      
!C
      IF ( NFBOD .EQ. I_0 )  RETURN
!C
      DO  I=1,NFBOD
       IF ( IBODN(I) .EQ. M )  THEN
        DO  J=1,3
         X(J) = XM(J)
        END DO
        FRCSN = +D_1
       ELSE IF ( IBODN(I) .EQ. N )  THEN
        DO  J=1,3
         X(J) = XN(J)
        END DO
        FRCSN = -D_1
       END IF
       IF ( ( IBODN(I) .EQ. M ) .OR. ( IBODN(I) .EQ. N )  )  THEN
        SMALL = SMALL_START
        DO  K=1,NNOD(I)
         CV = D_0
         DO  J=1,3
          CV = CV + ( X(J) - QNOD(J,K,I) )**2
         END DO
         IF ( CV .LT. SMALL )  THEN
          SMALL = CV
          NCNT = K
         END IF
        END DO
        SMALL = SQRT ( SMALL )
        DO  J=1,3
         FIK(J,NCNT,I) = FIK(J,NCNT,I) + FRCSN * FRC(J)
        END DO
       END IF
      END DO
!C
      RETURN
      END
