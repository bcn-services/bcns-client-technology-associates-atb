      SUBROUTINE U1ASCD
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       BD,                                     ! /CNTSRF/
     &       NGRND, NHRNSS, NVEH, TIME,              ! /COUTFMT/
     &       IRGDFM,                                 ! /COUTFMT/
     &       NTOBLT, NTOPTS,                         ! /COUTN/
     &       BAR, IBAR, NBLTPH, NL, NPTPLY, NPTSPB,  ! /HRNSESS/
     &       SEG,                                    ! structures
     &       INTEGER_STD, IREAL_HIGH, IREAL_STD,     ! parameters
     &       LUVIEW, MAXSEG, MULHRN,                 ! parameters
     &       R_0, D_0, I_0, I_2                      ! parameters
!C
!C    DIR_COS, DRC_PHI, LIN_DISP, ROT_PHI     ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K, KS
!C
      REAL  ( KIND = IREAL_STD )
     &          XTIME, XD, XSEGLP, XBAR
!C
      REAL  ( KIND = IREAL_HIGH )    T3, T4, T5
      DIMENSION  XD(3,3,MAXSEG), XSEGLP(3,MAXSEG), T3(3,3),
     &           T4(3), T5(3), XBAR(9,100)
!C
      REAL ( KIND = IREAL_STD ) CHECK_HIGH_VALUE
      EXTERNAL  CHECK_HIGH_VALUE
!C
!C
!C    Modification to allow for general output of objects
!C                                                                       
!C    Write dynamic data
!C
      XTIME = TIME
      WRITE ( LUVIEW, 100 )  XTIME
  100 FORMAT ( G16.9 )
      IF ( NGRND .GT. I_0 ) THEN
       IF (IRGDFM .EQ. I_2 ) THEN
        DO  I = 1,NGRND
         DO  J = 1,3
          DO  K = 1,3
           XD(K,J,I) = CHECK_HIGH_VALUE ( SEG(I)%DIR_COS(K,J) )
          END DO
          XSEGLP(J,I) = CHECK_HIGH_VALUE ( SEG(I)%LIN_DISP(J) )
         END DO
         IF ( SEG(I)%ROT_PHI )  THEN
          CALL DOT33 ( SEG(I)%DRC_PHI, SEG(I)%DIR_COS, T3 )
          DO  K=1,3
           DO  J=1,3
            XD(K,J,I) = CHECK_HIGH_VALUE ( T3(K,J) )
           END DO
          END DO
         END IF
         WRITE ( LUVIEW, 110 ) ( XSEGLP(J,I), J=1,3 ),
     &                    ( ( XD(K,J,I), K=1,3 ), J=1,3 )
  110    FORMAT ( 6( G16.9, 2X ) )
        END DO
       END IF
      END IF
!C
!C
!C    Section added to correspond to U1OLD dynamic output.
!C
      NTOBLT = I_0
      DO  I=1,5
       NTOBLT = NTOBLT + NBLTPH(I)
      END DO
      NTOPTS = I_0
      DO  I=1,NTOBLT
       NTOPTS = NTOPTS + NPTSPB(I)
      END DO
!C
!C    End section added
!C
      IF ( NHRNSS .NE. I_0 )  THEN
       DO  I = 1,NTOPTS
        DO  J = 1,9
         XBAR(J,I) = CHECK_HIGH_VALUE ( BAR(J,I) )
        END DO
       END DO
       DO  K=1,NTOPTS
        KS = ABS(IBAR(1,K))
        IF(KS .GT. MULHRN) THEN
         KS = MOD(KS,MULHRN)
        END IF
        IF ( KS .EQ. I_0 )  THEN
         CYCLE
        ELSE IF ( .NOT. SEG(KS)%ROT_PHI ) THEN
         CYCLE
        END IF
        CALL DOT31 ( SEG(KS)%DRC_PHI, BAR(4,K), T4 )
        CALL DOT31 ( SEG(KS)%DRC_PHI, BAR(7,K), T5 )
        DO  I=1,3
         XBAR(I+3,K) = CHECK_HIGH_VALUE ( T4(I) )
         XBAR(I+6,K) = CHECK_HIGH_VALUE ( T5(I) )
        END DO
       END DO
!C
       WRITE ( LUVIEW, 110 )  ( ( XBAR(I,J), I=1,9 ), J=1,NTOPTS )
       WRITE ( LUVIEW, 120 )  ( ( NL(I,J), I=1,2 ), J=1,NTOPTS )
  120  FORMAT ( 10I5 )
       WRITE ( LUVIEW,120 )   ( NPTPLY(I), I=1,NTOBLT )
      END IF
!C
      RETURN
      END
