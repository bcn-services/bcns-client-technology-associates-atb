      SUBROUTINE FSPDMP ( I0, M, N, TM1, TM2, TOTF, IOP )               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C   Computes location & vel. of spring damper nodes if IOP = 0         
!C   Computes nodal forces if IOP # 0   
!C        (for deformable bodies M and/or N)                            
!C   Called by SPDAMP                                                   
!C
      USE  MODULE_STANDARD,  ONLY:   
     &        APSDM, APSDN,             ! /DAMPER/
     &        INTEGER_STD, IREAL_HIGH,  ! parameters
     &        D_0, I_0, I_1, I_6        ! parameters
!C
      USE  MODULE_FLEXIBLE,  
     &       ONLY:   FMODES, FIK, QNOD,             ! /FXBODY/
     &               NODSD,                         ! /FXFRC/
     &               AMP, AMV, NMOD, IBODN, NFBOD   ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) I, I0, IOP, J, K, L0, M, N
!C
      REAL  ( KIND = IREAL_HIGH )  TM1, TM2, TOTF
      DIMENSION         TM1(3), TM2(3), TOTF(3)               
!C
      IF ( NFBOD .EQ. I_0 )  RETURN
      DO  I=1,NFBOD
       IF ( IBODN(I) .EQ. M ) THEN
        IF ( IOP .EQ. I_0 ) THEN
         L0 = I_6 * ( NODSD(1,I0) - I_1 )
         DO  K=1,3
          APSDM(K,I0) = QNOD(K,NODSD(1,I0),I)
          TM1(K) = D_0
          DO  J=1,NMOD(I)
           APSDM(K,I0) = APSDM(K,I0) + FMODES(L0+K,J,I) * AMP(J,I)
           TM1(K) = TM1(K) + FMODES(L0+K,J,I) * AMV(J,I)
          END DO
         END DO
        ELSE
         DO  K=1,3
          FIK(K,NODSD(1,I0),I) = FIK(K,NODSD(1,I0),I) - TOTF(K)
         END DO
        END IF
       ELSE IF ( IBODN(I) .EQ. N ) THEN
        IF ( IOP .EQ. I_0 ) THEN
         L0 = I_6 * ( NODSD(2,I0) - I_1 )
         DO  K=1,3
          APSDN(K,I0) = QNOD(K,NODSD(2,I0),I)
          TM2(K) = D_0
          DO  J=1,NMOD(I)
           APSDN(K,I0) = APSDN(K,I0) + FMODES(L0+K,J,I) * AMP(J,I)
           TM2(K) = TM2(K) + FMODES(L0+K,J,I) * AMV(J,I)
          END DO
         END DO
        ELSE
         DO  K=1,3
          FIK(K,NODSD(2,I0),I) = FIK(K,NODSD(2,I0),I) + TOTF(K)
         END DO
        END IF
       END IF
      END DO
!C
      RETURN
      END
