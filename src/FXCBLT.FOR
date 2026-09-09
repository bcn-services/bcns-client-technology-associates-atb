      SUBROUTINE FXCBLT ( MA, MB, N, XA, XB, XN1, XN2, FRC1, FRC2 )      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    Finds nodes of contact and adds the belt force to nodal forces       
!C     called by BELTRT.                                                     
!C
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, LOGICAL_STD,  ! parameters  
     &        D_0, D_1, I_0, I_1, I_2, TRUE, FALSE   ! parameters
!C
      USE  MODULE_FLEXIBLE,  ONLY:  FIK, QNOD,          ! /FXBODY/
     &                              NFBOD, NNOD, IBODN, ! /FXVAR/
     &                              SMALL_START         ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                  I, II, J, K, MA, MB, N, NCNT, NN_LCL
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  XA, XB, XN1, XN2, FRC1, FRC2, X, FRC,
     &                  FRCSN, CV, SMALL
      DIMENSION         XA(3), XB(3), XN1(3), XN2(3), FRC1(3),
     &                  FRC2(3), X(3,2), FRC(3)               
!C
      LOGICAL  ( KIND = LOGICAL_STD )  FFLG                       
!C
      IF ( NFBOD .EQ. I_0 ) RETURN

      DO  I=1,NFBOD
       FFLG = TRUE
       FRCSN = -D_1
       NN_LCL = I_1
       IF ( IBODN(I) .EQ. MA )  THEN
        DO  J=1,3
         X(J,1) = XA(J)
         FRC(J) = FRC1(J)
        END DO
       ELSE IF ( IBODN(I) .EQ. MB )  THEN
        DO  J=1,3
         X(J,1) = XB(J)
         FRC(J) = FRC2(J)
        END DO
       ELSE IF ( IBODN(I) .EQ. N )  THEN
        DO  J=1,3
         X(J,1) = XN1(J)
         X(J,2) = XN2(J)
         FRC(J) = FRC1(J) + FRC2(J)
        END DO
        FRCSN =  +D_1
        NN_LCL = I_2
       ELSE
        FFLG = FALSE
       END IF
       IF ( FFLG ) THEN
        DO  II=1,NN_LCL
         SMALL = SMALL_START
         DO  K=1,NNOD(I)
          CV = D_0
          DO  J=1,3
           CV = CV + ( X(J,II) - QNOD(J,K,I) )**2
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
        END DO
       END IF
      END DO
!C
      RETURN
      END
