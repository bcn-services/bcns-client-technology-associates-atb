      SUBROUTINE  INPUT_PER_FLOAT_DEV ( ECOED, ECOEL )
!C
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Controls the input of cards F.9.h - F.9.j containing the setup 
!C    and control of the water force personal floation devices.                
!C    This subroutine is called only by Subroutine INPUT_WATER.
!C                                                                      
!C
!C    NUM_PER_FLOAT_DEV = no.of PFDs 
!C
!C    NELPFD(J)   = no. of ellipsoids used to describe Jth PFD
!C   
!C    BDPFD(1-9,K),BDPFD(10-12,K) 
!C                = for PFD ellipsoid K, the semi axes, offset of the center,
!C                  and yaw, pitch and roll w.r.t segment local coords.
!C    PFDWT(1,J)  = weight of Jth PFD ellipsoid
!C    PFDWT(2,J)  = x coordinate of c.g in PFDWT(2,J)
!C    PFDWT(3,J)  = y  "                     "
!C    PFDWT(4,J)  = z  "                     "
!C    PFDWT(5,J)  = ref seg. frame of Jth PFD 0 wtr frame,-1 inertl frm
!C    KPFD(K)     = no. of segment associated with PFD ellipsoid K
!C
!C
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH, ICHAR_STD, ! parameters
     &       LUAIN, LUAOU, MAXELP,               ! parameters
     &       I_1, I_2, I_3, I_9, D_0,            ! parameters
     &       AIN_CONVERT, LIN_FLAG, LULIN        ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &       BDPFD, CADDM, COED, COEL, KPFD,     ! /WATINF1/
     &       NELPFD, NUM_PER_FLOAT_DEV, PFDWT,   ! /WATINF1/
     &       DPFD, NPE                           ! /WATINF2/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              I, IDYPR, J, K, K1, K2, KK, L, N
      DIMENSION  IDYPR(3)
!C
      REAL  ( KIND = IREAL_HIGH )
     &              EADDM, ECOED, ECOEL, SUM1, SUM2
      DIMENSION     EADDM(6)                              
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =  26, KIND = ICHAR_STD )  A_FRMT_26
!C
      DATA             IDYPR / I_3, I_2, I_1 /
!C
      INTENT  ( IN ) ECOED, ECOEL
!C
!C    Read and echo Card F.9.h.
!C
      K1 = I_1
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )   ( NELPFD(I), I=1,NUM_PER_FLOAT_DEV )
      ELSE
       READ ( LUAIN, 100 )   ( NELPFD(I), I=1,NUM_PER_FLOAT_DEV )
  100  FORMAT ( 10I5 )
       IF ( AIN_CONVERT )  THEN
        WRITE ( ALEN1, 105 )  NUM_PER_FLOAT_DEV
  105   FORMAT ( I1 )
        READ ( ALEN1, 110 ) AL1
  110   FORMAT ( A1 )
        A_FRMT_26 = '( 1X, ' // AL1 // '( I5, 1X ), 1X, A )'        
        WRITE ( LULIN, A_FRMT_26 ) ( NELPFD(I), I=1,NUM_PER_FLOAT_DEV ),
     &                               'Card F.9.h'
       END IF
      END IF
      WRITE ( LUAOU, 115 )
  115 FORMAT ( /, 1X, 'PFD', 4X, 'No. of', 6X, 'Weight', 6X,
     &         'Location of C.G', 8X, 'Reference', /, 6X,
     &         'Ellipsoids', 5X, '(LB.)', 11X, '(IN)', 16X,
     &         'Frame', /, 31X, 'X', 7X, 'Y', 7X, 'Z' )
!C
!C    Test to ensure that each personal floation device has at least 1
!C     ellipsoid associated with it.
!C
      DO I=1,NUM_PER_FLOAT_DEV
       IF ( NELPFD(I) .LT. I_1 )  THEN
        WRITE ( LUAOU, 116 )  I, NELPFD(I)
  116   FORMAT ( 1X, ' The number of ellipsoids specified for the ', I3, 
     &               ' personal floation device, ', I3, ' is invalid.' )
        STOP ' STOP 594 in Subroutine INPUT_PER_FLOAT_DEV. '
       END IF
      END DO
!C
!C    Read in and echo Card F.9.i.
!C
      DO 20 I=1,NUM_PER_FLOAT_DEV
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( PFDWT(L,I), L=1,5 )
       ELSE
        READ ( LUAIN, 120 )  ( PFDWT(L,I), L=1,5 )
  120   FORMAT ( 4F10.6, F5.0 )
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 125 )  ( PFDWT(L,I), L=1,5 ), 'Card F.9.i'
  125    FORMAT ( 1X, 5( F17.9, 1X ), 1X, A )
        END IF
       END IF
       KK = NINT ( PFDWT(5,I) )
       WRITE ( LUAOU, 130 ) I, NELPFD(I),( PFDWT(L,I), L=1,4 ), KK
  130  FORMAT ( 1X, I2, 6X, I2, 7X, F6.2, 4X, F6.3, 2X, F6.3, 2X,
     &          F6.3, 7X, I2 )
!C
!C     Read in and echo Cards F.9.j.
!C
       IF ( NELPFD(I) .GE. I_1 )  THEN
        K2 = K1 + NELPFD(I) - I_1
        DO 30 K=K1,K2
         IF ( LIN_FLAG )  THEN
          READ ( LULIN, * )  KPFD(K), ( BDPFD(L,K), L=1,6 )
          READ ( LULIN, * )  ( BDPFD(L,K), L=10,12 )
          READ ( LULIN, * )  COED(K+MAXELP), COEL(K+MAXELP),      
     &                       ( CADDM(J,K+MAXELP), J=1,6 )
         ELSE
          READ ( LUAIN, 135 )  KPFD(K), ( BDPFD(L,K), L=1,6 ),
     &                                  ( BDPFD(L,K), L=10,12 ),
     &                        COED(K+MAXELP), COEL(K+MAXELP),      
     &                       ( CADDM(J,K+MAXELP), J=1,6 )
  135     FORMAT ( I2, 6F10.6, /, 3F10.6, /, 8F10.6 )
          IF ( AIN_CONVERT )  THEN
           WRITE ( LULIN, 140 )  KPFD(K), ( BDPFD(L,K), L=1,6 ),
     &                           'Card F.9.j.1'
  140      FORMAT ( 1X, I4, 1X, 6( F17.9, 1X ), 1X, A )
           WRITE ( LULIN, 145 ) ( BDPFD(L,K), L=10,12 ), 
     &                          'Card F.9.j.2'
  145      FORMAT ( 1X, 3( F15.7, 1X ), 1X, A )
           WRITE ( LULIN, 150 ) COED(K+MAXELP), COEL(K+MAXELP),      
     &                 ( CADDM(J,K+MAXELP), J=1,6 ), 'Card F.9.j.3'
  150      FORMAT ( 1X, 8( F17.9, 1X ), 1X, A )
          END IF
         END IF
         IF ( COED(K+MAXELP) .EQ. D_0 )  THEN
          COED(K+MAXELP) = ECOED                 
         ELSE IF ( COED(K+MAXELP) .LT. D_0 )  THEN
          COED(K+MAXELP) = D_0                   
         END IF
         IF ( COEL(K+MAXELP) .EQ. D_0 )  THEN
          COEL(K+MAXELP) = ECOEL                
         ELSE IF ( COEL(K+MAXELP) .LT. D_0 )  THEN
          COEL(K+MAXELP) = D_0                  
         END IF
         DO  J=1,6
          IF ( CADDM(J,K+MAXELP) .EQ. D_0 )  THEN 
           CADDM(J,K+MAXELP) = EADDM(J)
          ELSE IF ( CADDM(J,K+MAXELP) .LT. D_0 )  THEN 
           CADDM(J,K+MAXELP) = D_0
          END IF
         END DO
         CALL DRCYPR ( DPFD(1,1,K), BDPFD(10,K), IDYPR )
         DO  N=1,3
          DO  J=1,3
           SUM1 = D_0
           SUM2 = D_0
           DO  L=1,3
            SUM1 = SUM1 + DPFD(L,N,K) / BDPFD(L,K)**2
     &                  * DPFD(L,J,K)
            SUM2 = SUM2 + DPFD(L,N,K) * BDPFD(L,K)**2
     &                  * DPFD(L,J,K)
           END DO
           KK = I_3 * N + J + I_9
           BDPFD(KK,K) = SUM1
           BDPFD(KK+9,K) = SUM2
          END DO
         END DO
   30   CONTINUE
        K1 = K2 + I_1
       END IF 
   20 CONTINUE
!C
      NPE = K2          
      WRITE ( LUAOU, 155 )
  155 FORMAT ( /, 1X, 'PFD', 16X, 'Semiaxes (in)', 16X,
     &         'Offset (in)',16X, '    Rotation (deg)',
     &         /, 1X, 'ELL.', 9X, '1', 9X, '2', 9X, '3', 6X,
     &        ' Segment Coordinate System', 6X, ' Yaw', 7X,
     &        'Pitch', 5X, 'Roll', /, 1X )
      DO  K=1,NPE
       WRITE ( LUAOU, 160 )  K, ( BDPFD(L,K), L=1,6 ),
     &                          ( BDPFD(L,K), L=10,12 )
  160  FORMAT ( 1X, I2, 3X, 3( 3F10.3, 1X ) )             
      END DO
      WRITE  ( LUAOU, 165 )
  165 FORMAT ( /, 3X, 'Coef. of', 4X, 'Coef. of', 6X,
     &        'Added Mass Coefficients', 6X,
     &        'Added Damping Coefficients', /, 5X, 'Drag', 8X,
     &        'Lift', 7X, '(Water Frame Coordinates)', 6X,
     &        '(Water Frame Coordinates)', /, 30X, 'X', 9X, 'Y',
     &        9X, 'Z', 9X, 'X', 9X, 'Y', 9X, 'Z', / )
      DO  K=1,K2
       WRITE ( LUAOU, 170 )  COED(K+MAXELP), COEL(K+MAXELP),
     &                     ( CADDM(J,K+MAXELP), J=1,6 )
  170  FORMAT ( 1X, F10.3, 2X, 7F10.3 )
      END DO
!C
      RETURN
      END