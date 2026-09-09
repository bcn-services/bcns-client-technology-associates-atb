      SUBROUTINE FXCAHW ( M, XM, FRC, FRCSN )                           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    Finds node of contact for airbag/hbelt/windy & adds to nodal forces 
!C    called by AIRBAG, HBELT, WINDY                                     
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, I_0, D_0      ! parameters  
!C
      USE  MODULE_FLEXIBLE,  ONLY:   FIK, QNOD,          ! /FXBODY/
     &                               NNOD, IBODN, NFBOD, ! /FXVAR/
     &                               SMALL_START         ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K, M, NCNT
!C
      REAL  ( KIND = IREAL_HIGH )   FRC, FRCSN, XM, CV, SMALL
      DIMENSION         XM(3), FRC(3)                               
!C
      IF ( NFBOD .EQ. I_0 ) RETURN

      DO  I=1,NFBOD
       IF ( IBODN(I) .EQ. M ) THEN
        SMALL = SMALL_START
        DO  K=1,NNOD(I)
         CV = D_0
         DO  J=1,3
          CV = CV + ( XM(J) - QNOD(J,K,I) )**2
         END DO
         IF ( CV .LT. SMALL ) THEN
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
