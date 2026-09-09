      SUBROUTINE  INPUT_WATER_ELLIPSOIDS ( ECOED, ECOEL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Controls the input of cards F.9.e - F.9.g containing the setup 
!C    and control of the water force ellipsoid data.                
!C    This subroutine is called only by Subroutine INPUT_WATER.
!C
!C    NWSE(1,I) = ellipsoid number of ellipsoid I
!C    NWSE(2,I) = number of the segment the ellipsoid is attached to
!C
!C    BCOED       = general drag coefficent of body ellipsoid 
!C    ECOED       = general drag coefficent of PFD ellipsoid     
!C    BCOEL       = general lift coefficent of body ellipsoid      
!C    ECOEL       = general lift coefficent of pfd ellipsoid
!C    BADDM(6)    = general translational added-mass and damping coefficents of
!C                  body ellipsoids
!C                  BADDM(1-3): added-mass coefficients
!C                  BADDM(4-6): damping coefficients
!C    EADDM(6)    = general translational added-mass and damping coefficents of 
!C                  pfd ellipsoids
!C                  EADDM(1-3):coefficents due to acceleration 
!C                  EADDM(4-6):coefficents due to velocity
!C
!C    NOTE: The WAFAC module uses only the BADDM(1) and EADDM(1) in its
!C          added-mass computations.  The arrays are dimensioned for future 
!C          enhancements.
!C    COED(K)     = drag coefficent of each ellipsoid (body and pfd)     
!C    COEL(K)     = lift coefficent of each ellipsoid (body and pfd)      
!C    TBDV        = total body volume
!C    DMOUTH(3)   = the position of the mouth is given on the ellipsoid
!C                  MOUTHE attached to the segment MOUTHS
!C    NEBODY      = the body repose angle is assumed to be the
!C                  inclination to the vertcal of this ellipsoid
!C    NSBODY      = the reference number of the segment to which 
!C                  ellipsoid NEBODY is attached.
!C    DPFD(1,1,K) = the cosine matrix of pfd ellipsoid K w.r.t. the segment
!C    NPE         = the number of pfd ellipsoids
!C
!C    NUM_ELLIP_WATER_CT = no. of ellipsoids contacting water
!C
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:
     &       PI,                                 ! /CNSNTS/
     &       BD,                                 ! /CNTSRF/
     &       SEG,                                ! structures
     &       INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LUAIN, LUAOU, LUTERM_OUT, MAXELP,   ! parameters
     &       I_0, I_5, D_0, D_3, D_4,            ! parameters
     &       AIN_CONVERT, LIN_FLAG, LULIN        ! parameters
!C  
!C     DIR_COS    ! SEG%
!C
      USE  MODULE_WATER,  ONLY:
     &       DELP,                                       ! /ELPDAT/
     &       KSEG_WATER,                                 ! /TEMPFD/
     &       CADDM, COED, COEL, DMOUTH, MOUTHE,          ! /WATINF1/
     &       MOUTHS, NEBODY, NUM_ELLIP_WATER_CT,         ! /WATINF1/
     &       NUM_PER_FLOAT_DEV, NSBODY, NWSE, TBDV       ! /WATINF1/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )   I, J, KELL
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BADDM, BCOED, BCOEL, BDV,
     &                  EADDM, ECOED, ECOEL, TMP1_LCL
      DIMENSION         BADDM(6), EADDM(6), TMP1_LCL(3)                               
!C
      INTENT ( OUT )  ECOED, ECOEL
!C
!C    Read in and echo Card F.9.e.
!C
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )  NUM_ELLIP_WATER_CT, NUM_PER_FLOAT_DEV,
     &                     BCOED, BCOEL, ( BADDM(J), J=1,6 )
       READ ( LULIN, * )  ECOED, ECOEL, ( EADDM(J), J=1,6 )                    
      ELSE
       READ ( LUAIN, 100 )  NUM_ELLIP_WATER_CT, NUM_PER_FLOAT_DEV, 
     &                      BCOED, BCOEL, ( BADDM(J), J=1,6 ),
     &                      ECOED, ECOEL, ( EADDM(J), J=1,6 )                    
  100  FORMAT ( 2I5, 8F6.4, /, 8F6.4 )
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 105 )  NUM_ELLIP_WATER_CT, NUM_PER_FLOAT_DEV, 
     &                         BCOED, BCOEL, 
     &                        ( BADDM(J), J=1,6 ), 'Card F.9.e.1'
  105   FORMAT ( 1X, 2( I5, 1X ),  8( F15.7, 1X ), 1X, A )
        WRITE ( LULIN, 110 )  ECOED, ECOEL, ( EADDM(J), J=1,6 ),
     &                        'Card F.9.e.2'                    
  110    FORMAT ( 1X, 8( F15.7, 1X ), 1X, A )
       END IF
      END IF
      WRITE ( LUAOU, 115 ) NUM_ELLIP_WATER_CT
  115 FORMAT ( /, 1X, 'No. of Ellipsoids Contacting Water =', 1X, I2 )
!C
!C    Check the input values.
!C
      IF ( NUM_ELLIP_WATER_CT .LT. I_0 ) THEN
       WRITE ( LUTERM_OUT, 120 ) NUM_ELLIP_WATER_CT
       WRITE ( LUAOU, 120 )  NUM_ELLIP_WATER_CT
  120  FORMAT ( /, 1X, 'The number of body ellipsoids contacting water '
     &          , I5,' cannot be negative. Program is terminated.' )
       STOP ' STOP 592 in Subroutine INPUT_WATER_ELLIPSOIDS'
      ELSE IF ( NUM_ELLIP_WATER_CT .GT. MAXELP )  THEN
       WRITE ( LUTERM_OUT, 122 ) NUM_ELLIP_WATER_CT
       WRITE ( LUAOU, 120 )  NUM_ELLIP_WATER_CT
  122  FORMAT ( /, 1X, 'The number of body ellipsoids contacting water '
     &          , I5,' is too large. Program is terminated.' )
       STOP ' STOP 593 in Subroutine INPUT_WATER_ELLIPSOIDS'
      END IF
!C
      IF ( NUM_PER_FLOAT_DEV .GT. I_5 ) THEN
       WRITE ( LUAOU, 125 )  NUM_PER_FLOAT_DEV
  125  FORMAT ( /, 1X, 'The number of PFDs ', I5,
     &          ' is too large.  The program is terminated.' )
       STOP ' STOP 598 in Subroutine INPUT_WATER_ELLIPSOIDS '
      ELSE IF ( NUM_PER_FLOAT_DEV .LT. I_0 )  THEN
       WRITE ( LUAOU, 130 )  NUM_PER_FLOAT_DEV
  130  FORMAT ( /, 1X, 'The number of PFDs ', I5,
     &          ' can not be negative.  The program is terminated.' )
       STOP ' STOP 599 in Subroutine INPUT_WATER_ELLIPSOIDS '
      ELSE IF ( ( NUM_PER_FLOAT_DEV .EQ. I_0 ) .AND.
     &          ( NUM_ELLIP_WATER_CT .EQ. I_0 ) )  THEN
       WRITE ( LUAOU, 135 ) 
  135  FORMAT ( /, 1X, 'Both the number of PFDs and ellipsoids ',
     & 'contacting the water cannot be 0.  The program is terminated.' )
       STOP ' STOP 591 in Subroutine INPUT_WATER_ELLIPSOIDS '
      END IF
!C
!C    Read in and echo Card F.9.f.
!C
      IF ( NUM_ELLIP_WATER_CT .GT. I_0 )  THEN
       WRITE ( LUAOU, 140 )
  140  FORMAT ( /, 1X, 'Ellipsoid', 2X, 'Segment', 3X, 'Coef. of', 4X,
     &          'Coef. of',6X,'Added Mass Coefficients', 6X,
     &          'Added Damping Coefficients', /, 24X, 'Drag', 8X, 'Lift'
     &          , 8X, '(Water Frame Coordinates)', 5X,
     &          '(Water Frame Coordinates)', /, 49X, 'X', 9X, 'Y', 9X,
     &          'Z', 9X, 'X', 9X, 'Y', 9X, 'Z' )               
       TBDV = D_0
       DO  I = 1,NUM_ELLIP_WATER_CT
        IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  NWSE(1,I), NWSE(2,I), COED(I), COEL(I),
     &                     ( CADDM(J,I), J=1,6 ) 
        ELSE
         READ ( LUAIN, 145 )  NWSE(1,I), NWSE(2,I), COED(I), COEL(I),
     &                      ( CADDM(J,I), J=1,6 ) 
  145    FORMAT ( 2I5, 8F6.4 )
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 150 )  NWSE(1,I), NWSE(2,I), COED(I), COEL(I),
     &                       ( CADDM(J,I), J=1,6 ), 'Card F.9.f' 
  150    FORMAT ( 1X, 2( I5, 1X ), 8( F15.7, 1X ), 1X, A )
        END IF
        END IF
!C
        IF ( COED(I) .EQ. D_0 )  THEN
         COED(I) = BCOED
        ELSE IF ( COED(I) .LT. D_0 )  THEN
         COED(I) = D_0
        END IF
        IF ( COEL(I) .EQ. D_0 )  THEN
         COEL(I) = BCOEL
        ELSE IF ( COEL(I) .LT. D_0 )  THEN
         COEL(I) = D_0
        END IF
        DO  J=1,6
         IF ( CADDM(J,I) .EQ. D_0 )  THEN
          CADDM(J,I) = BADDM(J)
         ELSE IF ( CADDM(J,I) .LT. D_0 )  THEN
          CADDM(J,I) = D_0
         END IF
        END DO
        WRITE ( LUAOU, 155 )  NWSE(1,I), NWSE(2,I), COED(I), COEL(I),
     &                       ( CADDM(J,I), J=1,6 )       
  155   FORMAT ( 5X, I2, 7X, I2, 4X, F10.3, 2X, 7F10.3 )
        KELL = NWSE(1,I)
        KSEG_WATER = NWSE(2,I)
        BDV = BD(1,KELL) * BD(2,KELL) * BD(3,KELL) * PI * D_4 / D_3
        TBDV = TBDV + BDV
       END DO
      END IF
!C
!C    Read in and echo Card F.9.g.
!C
      IF ( LIN_FLAG )  THEN
       READ  ( LULIN, * )  MOUTHS, MOUTHE, ( DMOUTH(J), J=1,3 ),
     &                     NEBODY
      ELSE
       READ  ( LUAIN, 160 )  MOUTHS, MOUTHE, ( DMOUTH(J), J=1,3 ),
     &                       NEBODY
  160  FORMAT ( 2I5, 3F10.6, I5 )
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 165 )  MOUTHS, MOUTHE, ( DMOUTH(J), J=1,3 ),
     &                        NEBODY, 'Card F.9.g'
  165   FORMAT ( 1X, 2( I5, 1X ), 3( F17.9, 1X ), I5, 2X, A )
       END IF
      END IF
!C
!C    Check to see if the ellipsoid for the angle of repose has been
!C     defined as an ellipsoid that contacts the water.
!C
      IF ( NUM_ELLIP_WATER_CT .GT. I_0 )  THEN
       DO  I=1,NUM_ELLIP_WATER_CT
        KELL = NWSE(1,I)
        IF ( KELL .EQ. NEBODY )  THEN
         NSBODY = NWSE(2,I)
         EXIT
        END IF
       END DO
      END IF
!C
      IF ( ( NUM_ELLIP_WATER_CT .GT. I_0 ) .AND. 
     &     ( I .GT. NUM_ELLIP_WATER_CT ) ) THEN
       WRITE ( LUTERM_OUT, 170 )
       WRITE ( LUAOU, 170 )
  170  FORMAT ( /, 
     &          '*** INPUT ERROR *** Ellipsoid "NEBODY" is not defined!',
     &          / )
       STOP 'STOP 597 in Subroutine INPUT_WATER_ELLIPSOIDS'
      END IF
!C
!C    Output the location of the mouth relative to an ellipsoid.
!C 
      WRITE ( LUAOU, 175 )  MOUTHE, MOUTHS, ( DMOUTH(J), J=1,3 ),
     &                      NEBODY, NSBODY
  175 FORMAT ( /, 1X, 'The Mouth is on Ell. ', I2, ' Seg. ', I2, /, 1X,
     &        'Location of Mouth in the Ellipsoid Frame: ', 3F10.4, /,
     &        1X, 'Angle of Body Repose = Inclination to ',
     &        'the Vertical of Ell. ', I2, ' on Seg. ', I2 )
      CALL DOT31 ( DELP(1,1,MOUTHE), DMOUTH, TMP1_LCL )
      CALL DOT31 ( SEG(MOUTHS)%DIR_COS, TMP1_LCL, DMOUTH )
!C
      RETURN
      END