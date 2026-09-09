       SUBROUTINE  OUTPUT_WATER ( LTHIST, LTAPE8, NT, USEC_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C     Note: this program is called only by Subroutine OUTPUT_FORCES,
!C      after printing the airbag forces.
!C
!C
      USE  MODULE_STANDARD,  ONLY:
     &       TDATA,                                  ! /HEDING_TEMPVS/
     &       SEG,                                    ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,   ! parameters
     &       NUM_TTH_OFFSET,                         ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, D_0       ! parameters
!C
!C    DIR_COS, DRC_PHI, ROT_PHI      ! SEG%
!C
      USE  MODULE_WATER,  ONLY:
     &       DELP,                                     ! /ELPDAT/
     &       ALFA1, ALFA2, BRI, DIST_MOUTH_TO_WATER,   ! /WFACOP/
     &       ITYPE, NELL,  NELOUT, NSEQN, TENY, WAREA, ! /WFACOP/
     &       ADDM, BUOY, DRAG, WEXF                    ! /WRESLTS/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &                  I, II, J, J1, K, KELL_LCL, KSEG, NT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AF, BF, BT, DF, F_LCL, FF_LCL, TMP_LCL, 
     &                  USEC_LCL, WEF, WF_LCL, WT 
      DIMENSION         AF(3), BF(6), BT(3), DF(6), F_LCL(6),
     &                  FF_LCL(7), TMP_LCL(7), WEF(6), WF_LCL(8), WT(3)
!C
      REAL  ( KIND = IREAL_HIGH )  VECMAG
      EXTERNAL          VECMAG
!C
      LOGICAL  ( KIND = LOGICAL_STD )   LTHIST, LTAPE8
!C
      INTENT (    IN )  LTHIST, LTAPE8, USEC_LCL
      INTENT ( INOUT )  NT
!C
!C
!C    NELL = output is reqested for NHYP ellipsoids
!C    NELOUT(1,J) = ellipsoid no. for which output is requested
!C    NELOUT(2,J) = segment to which ellipsoid J is attached
!C
!C    ITYPE(1) =  1  O/P total force
!C         (2) =  1  O/P byouancy force
!C         (3) =  1  O/P wave excitation force
!C         (4) =  1  O/P added mass force
!C         (5) =  1  O/P drag force          
!C         (6) = -1  O/P forces w.r.t inertial system
!C                0                   local coordinate system
!C                1                   ellipsoid system
!C
!C
      NT = NT + I_1
      IF ( LTAPE8 ) THEN
       IF ( WAREA .LT. D_0 )  WAREA = D_0
        TDATA(1,NT-NUM_TTH_OFFSET) = DIST_MOUTH_TO_WATER
        TDATA(2,NT-NUM_TTH_OFFSET) = BRI
        TDATA(3,NT-NUM_TTH_OFFSET) = WAREA
        TDATA(4,NT-NUM_TTH_OFFSET) = TENY
        TDATA(5,NT-NUM_TTH_OFFSET) = ALFA1
        TDATA(6,NT-NUM_TTH_OFFSET) = ALFA2
      END IF
      IF ( LTHIST )  THEN 
       WRITE ( NT, 100 ) USEC_LCL, DIST_MOUTH_TO_WATER, BRI,
     &                   WAREA, TENY, ALFA1, ALFA2   
  100   FORMAT ( F10.3, 6X, F10.3, 17X, G10.3, 12X, G10.3, 10X, G10.3,
     &          4X, F10.3, 4X, F10.3 )
      END IF
!C 
      BF  = D_0
      WEF = D_0
      DF  = D_0
      AF  = D_0
!C    
      J1 = I_0
      DO 20 I=1,NSEQN
       DO  J=1,NELL(I)
        J1 = J1 + I_1
        KELL_LCL = NELOUT(I,1,J1)
        KSEG = NELOUT(I,2,J1)
        IF ( NELL(I) .GT. 1 ) THEN
         CALL DOT31 ( SEG(KSEG)%DIR_COS, BUOY(4,KELL_LCL), BT )
         CALL DOT31 ( SEG(KSEG)%DIR_COS, WEXF(4,KELL_LCL), WT )
        ELSE 
         DO  K=1,3
          BT(K) = BUOY(K+3,KELL_LCL)
          WT(K) = WEXF(K+3,KELL_LCL)
         END DO
        END IF
        DO  K=1,3 
         BF(K)   = BF(K)    + BUOY(K,KELL_LCL)
         BF(3+K) = BF(3+K)  + BT(K)
         WEF(K)  = WEF(K)   + WEXF(K,KELL_LCL)
         WEF(3+K)= WEF(3+K) + WT(K)
         DF(K)   = DF(K)    + DRAG(K,KELL_LCL)
         DF(3+K) = DF(3+K)  + DRAG(3+K,KELL_LCL)
         AF(K)   = AF(K)    + ADDM(K,KELL_LCL)
        END DO
       END DO
!C
       DO  30 K=1,5
        IF ( ITYPE(K) .EQ. I_1 )  THEN
         NT = NT + I_1
         IF ( K .EQ. I_1 ) THEN
          DO  J=1,3
           F_LCL(J) = BF(J) + WEF(J) + AF(J) + DF(J) + DF(J+3)
          END DO 
          DO  J= 4,6
           F_LCL(J) = BF(J) + WEF(J)
          END DO
         ELSE IF ( K .EQ. I_2 )  THEN
          F_LCL = BF 
         ELSE IF ( K .EQ. I_3 )  THEN
          F_LCL = WEF 
         ELSE IF ( K .EQ. I_4 ) THEN
          DO  J=1,3
           F_LCL(J) = AF(J)
          END DO
         ELSE
          F_LCL = DF
         END IF
!C
         WF_LCL(4) = VECMAG(F_LCL(1))
         DO  J = 1,3
          WF_LCL(J)   = F_LCL(J)
          WF_LCL(J+4) = F_LCL(J+3)
         END DO               
         IF ( NELL(I) .EQ. I_1 )  THEN
          IF ( ITYPE(6) .EQ. I_1 ) THEN
           CALL MAT31 ( SEG(KSEG)%DIR_COS, F_LCL(1), FF_LCL(1) )
           CALL MAT31 ( DELP(1,1,KELL_LCL), FF_LCL(1), WF_LCL(1) )
           IF ( K .EQ. I_5 )  THEN
            CALL MAT31 ( SEG(KSEG)%DIR_COS, F_LCL(4), FF_LCL(1) )
            CALL MAT31 ( DELP(1,1,KELL_LCL), FF_LCL(1), WF_LCL(5) )
           END IF
          ELSE IF ( ITYPE(6) .EQ. I_0 ) THEN
           CALL MAT31 ( SEG(KSEG)%DIR_COS, F_LCL(1), WF_LCL(1) )
           IF ( K. EQ. I_5 ) THEN
            CALL MAT31 ( SEG(KSEG)%DIR_COS, F_LCL(4), WF_LCL(5) )
           END IF
           IF ( SEG(KSEG)%ROT_PHI ) THEN
            DO  J = 1,7
             TMP_LCL(J) = WF_LCL(J)
            END DO
            CALL DOT31 ( SEG(KSEG)%DRC_PHI, TMP_LCL(1), WF_LCL(1) )
            CALL DOT31 ( SEG(KSEG)%DRC_PHI, TMP_LCL(5), WF_LCL(5) )
           END IF
          END IF
         END IF
         IF ( K .EQ. I_5 )   WF_LCL(8)= VECMAG ( F_LCL(4) ) 
!C
         IF ( LTAPE8 ) THEN
          IF ( K .EQ. I_4 ) THEN
           DO  J=1,4
            TDATA(J,NT-NUM_TTH_OFFSET) = WF_LCL(J)
           END DO
          ELSE IF ( K .EQ. I_5 ) THEN   
           DO  J=1,8
            TDATA(J,NT-NUM_TTH_OFFSET) = WF_LCL(J)
           END DO
          ELSE   
           DO  J=1,7
            TDATA(J,NT-NUM_TTH_OFFSET) = WF_LCL(J)
           END DO
          END IF   
         END IF
         IF ( LTHIST ) THEN
          IF ( K .EQ. I_4 )  THEN
           WRITE ( NT, 120 ) USEC_LCL, ( WF_LCL(II), II=1,4 )   
  120      FORMAT ( F10.3, 4( 10X, F10.3 ) )
          ELSE IF ( K .EQ. I_5 )  THEN   
           WRITE ( NT, 130 ) USEC_LCL, ( WF_LCL(II), II=1,8 )
  130      FORMAT ( F10.3, 2X, 4F10.3, 8X, 4F10.3 )
          ELSE   
           WRITE ( NT, 140 ) USEC_LCL,( WF_LCL(II), II=1,7 )
  140      FORMAT ( F10.3, 2X, 4F10.3, 8X, 3F10.3 ) 
          END IF
         END IF   
        END IF
   30  CONTINUE
   20 CONTINUE
!C
      RETURN
      END 
