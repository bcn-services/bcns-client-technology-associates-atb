      SUBROUTINE INPUT_WAVES 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Controls the input of cards F.9.b - F.9.d containing the setup 
!C    and control of the water force waves option.                
!C    This subroutine is called only by Subroutine INPUT_WATER.
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:
     &       G, PI, TWOPI,                       ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LUAIN, LUAOU,                       ! parameters
     &       I_0, I_1, D_0, D_2, D_12, D_180,    ! parameters
     &       AIN_CONVERT, LIN_FLAG, LULIN        ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &       RNX, RPH,                                    ! /WATGRD/
     &       FREQ, ISPD, NWAVES, SWKH, WAMP, WDEP, WDIR,  ! /WAVEDAT/ 
     &       WNUM, WPHS, WSPD                             ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )   I 
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  CNVRT_KNOTS, PMCOEF1, PMCOEF2, 
     &                  WFREQNC, WHEIGHT, WINDVEL, WKH, WLENGTH 
!C
      PARAMETER  ( PMCOEF1  = 0.0081_IREAL_HIGH, 
     &             PMCOEF2  = 0.74_IREAL_HIGH,
     &             CNVRT_KNOTS = 0.515_IREAL_HIGH * 3.281_IREAL_HIGH
     &                           * D_12 )
!C
      IF ( ISPD .EQ. I_0 )  THEN
!C
!C     Read in and echo Card F.9.b.
!C
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  NWAVES, RPH, RNX
       ELSE
        READ  ( LUAIN, 100 )  NWAVES, RPH, RNX
  100   FORMAT ( I5, 2F10.5 )
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 105 )  NWAVES, RPH, RNX, 'Card F.9.b'
  105    FORMAT ( 1X, I5, 1X, 2( F17.9, 1X ), A )
        END IF
       END IF
!C
       WRITE ( LUAOU, 110 ) NWAVES, RPH, RNX
  110  FORMAT ( /, 1X, 'No. of Regular Waves Describing the Surface = ',
     &          I2, /, 1X,
     &          'Grid Size to be Used in Calculations (lines per inch)',
     &          2( 1X, F8.2 ) )
       IF ( NWAVES .GT. I_0 )  THEN
        WRITE ( LUAOU, 115 )
  115   FORMAT ( /, 1X,
     &           'Wave    Wave Length   Amplitude   Phase Angle  Wave ',
     &           'Direction', /, 3X, 2( 9X, '(in)' ), 2( 9X, '(deg)' ) )
!C
!C      Read in and echo Card F.9.c.
!C
        DO  I=1,NWAVES
         IF ( LIN_FLAG )  THEN
          READ ( LULIN, * )  WNUM(I), WAMP(I), WPHS(I), WDIR(I)
         ELSE
          READ ( LUAIN, 120 )  WNUM(I), WAMP(I), WPHS(I), WDIR(I)
  120     FORMAT ( 4F10.6, I2 )
          IF ( AIN_CONVERT )  THEN
           WRITE ( LULIN, 125 )  WNUM(I), WAMP(I), WPHS(I), WDIR(I), 
     &                         'Card F.9.c'
  125      FORMAT ( 1X, 4( F17.9, 1X ), 2X, A )
          END IF
         END IF
         WRITE ( LUAOU, 130 )  I, WNUM(I), WAMP(I), WPHS(I), WDIR(I)
  130    FORMAT ( 2X, I2, 4( 5X, F8.2 ) )
         WNUM(I) = TWOPI / WNUM(I)
         WPHS(I) = WPHS(I) * PI / D_180
         WDIR(I) = WDIR(I) * PI / D_180
         WKH     = WNUM(I) * WDEP
         IF ( WDEP .GT. I_0 )  THEN
          SWKH(I) = COSH ( WKH ) 
          FREQ(I) = SQRT ( G * WNUM(I) * TANH ( WKH ) )
         ELSE
          FREQ(I) = SQRT ( WNUM(I) * G )
         END IF
        END DO
       END IF
      ELSE 
!C
!C     Read in and echo Card F.9.d.
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  WSPD
       ELSE
        READ ( LUAIN, 135 )  WSPD
  135   FORMAT ( F10.6 )
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 140 )  WSPD, 'Card F.9.d'
  140    FORMAT ( 1X, F17.9, 2X, A )
        END IF
       END IF
       NWAVES   = I_1
!C
!C     Convert wind speed from knots to in/sec
!C
       WINDVEL =  CNVRT_KNOTS * WSPD
       WHEIGHT = D_2 * WINDVEL * WINDVEL 
     &               * SQRT ( PMCOEF1 / PMCOEF2 ) / G
       WFREQNC = ( PI * PMCOEF2 )**( 0.25_IREAL_HIGH ) * ( G / WINDVEL )
       WDIR(1) = D_0
       WPHS(1) = D_0
       FREQ(1) = WFREQNC
       WNUM(1) = WFREQNC * WFREQNC / G
       WLENGTH = TWOPI / WNUM(1)
       WAMP(1) = WHEIGHT
       WRITE ( LUAOU, 145 )  WSPD, WHEIGHT, WLENGTH
  145  FORMAT ( /, 1X, 'Wind Speed  = ', F8.2, 
     &          'knots, Corresponding Wave ',
     &          'Height = ', F8.2, ' in., Wavelength = ', F8.2, ' IN.' )
      END IF
!C
      RETURN
      END