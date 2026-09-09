      SUBROUTINE  HEDING_WATER ( LNEW, MT, NT, NLINES, XPAGE )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine is called by Subroutine HEDING.
!C     
!C
      USE  MODULE_STANDARD,  ONLY:
     &       USEC, ZTTH,                                    ! /HEDING_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, LUAOU,   ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5                   ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &       ITYPE, NELL, NSEQN ! /WFACOP/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IT, J, JJ, K, MT, NLINES, NT
!C
      REAL  ( KIND = IREAL_HIGH )   XPAGE
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LNEW
!C
!C    NELL = output is reqested for NHYP ellipsoids
!C    NELOUT(1,J) = ellipsoid no. for which output is requested
!C    NELOUT(2,J) = segment to which ellipsoid J is attached
!C
!C    ITYPE(1) =  1  O/P total force + % volume submerged
!C         (2) =  1  O/P bouyancy force
!C         (3) =  1  O/P wave excitation force
!C         (4) =  1  O/P added mass force
!C         (5) =  1  O/P drag force          
!C         (6) = -1  O/P forces w.r.t inertial system
!C                0                   local coordinate system
!C                1                   ellipsoid system
!C 
!C
      CALL LUNUM_WATER ( LNEW, MT, NT, IT, XPAGE )
      WRITE ( NT, 100 )
  100 FORMAT ( /, 6X, 'TIME', 5X, 'DISTANCE BETWEEN', 8X, 
     &         'RATIO OF BODY IN WATER', 3X, 'AREA OF BODY CUT', 7X,
     &         'NET KINETIC', 5X, 'ANGLE OF BODY REPOSE', /, 13X,
     &         'MOUTH AND WATER SURFACE',4X, 'TO TOTAL BODY VOLUME',
     &         4X, 'BY WATER SURFACE', 6X, 'ENERGY',
     &         ' OF BODY    AZIMUTH     ELEV.  ', /, 5X, '(MSEC)',
     &         10X, '(IN)', 43X, '(IN**2)', 13X, ' (LB INS)', 11X,
     &         '(DEGREE)', / )
      IF ( LNEW ) THEN
       DO  J=1,NLINES
        WRITE ( NT, 105 )  USEC(J), ( ZTTH(JJ,J,IT), JJ=1,6 )  
  105   FORMAT ( F10.3, 6X, F10.3, 17X, F10.3, 12X, F10.3, 10X, F10.3,
     &           7X, F8.2, F10.2 )
       END DO
      END IF
!C
      DO 20 I = 1, NSEQN
       DO 40 K=1,5
        IF ( ITYPE(K) .EQ. I_1 ) THEN
         CALL LUNUM_WATER ( LNEW, MT, NT, IT, XPAGE )
         WRITE ( NT, 110 ) I
  110     FORMAT ( /, 36X, 'Output Sequence', I3 )
         IF ( K .EQ. I_1 )  THEN
          WRITE ( NT, 115 )
  115     FORMAT ( 26X, 'Total Force', 32X, 'Total Torque' )
         ELSE IF ( K .EQ. I_2 ) THEN
          WRITE ( NT, 120 )
  120     FORMAT ( 25X, 'Buoyancy Force', 29X, 'Buoyancy Torque' )
         ELSE IF ( K .EQ. I_3 ) THEN
          WRITE ( NT, 125 )
  125     FORMAT ( 22X, 'Wave Excitation Force', 21X,
     &             'Wave Excitation Torque' )
         ELSE IF ( K .EQ. I_4 )  THEN
          WRITE ( NT, 130 )
  130     FORMAT ( 24X, 'Added Mass Force' )
         ELSE
          WRITE ( NT, 135 )
  135     FORMAT ( 29X, 'Drag Force', 31X, 'Lift Force' )
         END IF
         IF  ( NELL(I) .EQ. I_1 )  THEN
          IF  ( ITYPE(6) .EQ. I_1 )  THEN
           IF ( K .EQ. I_4 )  THEN
            WRITE ( NT, 140 )
  140       FORMAT ( 45X, 'in Ellipsoid System' )
           ELSE IF ( K .EQ. I_5 )  THEN
            WRITE ( NT, 145 )
  145       FORMAT ( 24X, 'in Ellipsoid System', 28X,
     &               'in Ellipsoid System' )
           ELSE
            WRITE  ( NT, 150 )
  150       FORMAT ( 23X, 'in Ellipsoid System', 27X, 
     &               'in Local System' )
           END IF
          ELSE IF  ( ITYPE(6) .EQ. I_0 )  THEN
           IF ( K .EQ. I_4 )  THEN
            WRITE ( NT, 155 )
  155       FORMAT ( 45X, 'in  Segment  System' )
           ELSE IF ( K .EQ. I_5 )  THEN
            WRITE ( NT, 160 )
  160       FORMAT ( 26X, 'in Segment System', 29X, 
     &               'in Segment System' )
           ELSE
            WRITE ( NT, 165 )
  165       FORMAT ( 23X, 'in Segment System', 28X, 
     &               'in Local System')
           END IF
          ELSE
           IF ( K .EQ. I_4 )  THEN
            WRITE ( NT, 170 )
  170       FORMAT ( 45X, 'in Inertial System' )
           ELSE IF ( K .EQ. I_5 )  THEN
            WRITE ( NT, 175 )
  175       FORMAT ( 26X, 'in Inertial System', 28X,
     &               'in Inertial System' )
           ELSE
            WRITE ( NT, 180 ) 
  180       FORMAT ( 23X, 'in Inertial System', 27X,
     &               'in Local System' )
           END IF
          END IF
         ELSE
          IF ( K .EQ. I_4 ) THEN
           WRITE ( LUAOU, 170 )
          ELSE
           WRITE ( LUAOU, 175 )
          END IF
         END IF
         IF ( K .EQ. I_4 )  THEN
          WRITE ( NT, 185 )
  185     FORMAT ( 6X, 'Time', 17X, 'FX', 18X, 'FY', 18X, 'FZ',
     &             13X, 'Resultant', /, 5X, '(msec)', 15X, '(lbs)',
     &             15X, '(lbs)', 15X, '(lbs)', 13X, '(lbs)' )
         ELSE IF ( K .EQ. I_5 )  THEN
          WRITE ( NT, 190 )
  190     FORMAT ( 6X, 'Time', 9X, 'FX', 7X, 'FY', 7X, 'FZ', 5X,
     &             'Resultant', 13X, 'FX', 8X, 'FY', 8X, 'FZ', 4X,
     &             'Resultant', /, 5X, '(msec)', 7X, '(lbs)', 4X,
     &             '(lbs)', 4X, '(lbs)', 5X, '(lbs)', 14X, '(lbs)',
     &             5X, '(lbs)', 5X, '(lbs)', 4X, '(lbs)' )
         ELSE
          WRITE ( NT, 195 )
  195     FORMAT ( 6X, 'Time', 9X, 'FX', 7X, 'FY', 7X, 'FZ', 5X,
     &             'Resultant', 13X, 'TX', 8X, 'TY', 8X, 'TZ', /,
     &             5X,'(msec)', 7X, '(lbs)', 4X, '(lbs)', 4X,
     &             '(lbs)', 5X, '(lbs)', 12X, '(in lbs)', 2X,
     &             '(in lbs)', 2X, '(in lbs)' )
         END IF
         IF ( LNEW ) THEN
          IF  ( K .EQ. I_4 ) THEN
           DO  J=1,NLINES
            WRITE ( NT, 200 )  USEC(J), ( ZTTH(JJ,J,IT), JJ=1,4 )
  200       FORMAT ( F10.3, 4( 10X, F10.3 ) )
           END DO
          ELSE IF ( K .EQ. I_5 ) THEN
           DO  J=1,NLINES
            WRITE ( NT, 205 )  USEC(J), ( ZTTH(JJ,J,IT), JJ=1,8 )
  205       FORMAT ( F10.3, 2X, 4F10.3, 8X, 4F10.3 )  
           END DO
          ELSE
           DO  J=1,NLINES
            WRITE ( NT, 210 ) USEC(J), ( ZTTH(JJ,J,IT), JJ=1,7 )
  210       FORMAT ( F10.3, 2X, 4F10.3, 8X, 3F10.3 )
           END DO
          END IF
         END IF
        END IF
   40  CONTINUE
   20 CONTINUE
!C
      RETURN
      END
