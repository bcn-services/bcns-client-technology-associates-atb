      FUNCTION  WEXPHI ( KWAVE )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C     This function calculates the partial time derivative of the 
!C     Potential function PHI(I) for wave KWAVE.  X,Y and Z are coordinates
!C     of the point in water reference frame.
!C
!C              gA.cosh(k(h-z))
!C     PHI(I) = --------------- (sin(k(x.cos(B)+y.sin(B))-S.time)
!C                (S.cosh(kh))
!C
!C     Where, S = SQRT(gk.tanh(kh))     for finite depths
!C
!C     and
!C     
!C               gA
!C     PHI(I) = --- exp(-kz) (sin(k(x.cos(B)+y.sin(B))-S.time)
!C               S 
!C
!C     and    
!C               = SQRT(gk)            for large depths (h>0.5 wavelength)
!C
!C
      USE  MODULE_STANDARD,  ONLY:
     &       TIME,                          ! /CONTRL/
     &       INTEGER_STD, IREAL_HIGH, D_0   ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &       T5,                                             ! /TEMPFD/
     &       FREQ, SWKH, WAMP, WDEP, WDIR, WGAM, WNUM, WPHS  ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  KWAVE
!C
      REAL  ( KIND = IREAL_HIGH )    WEXPHI 
      REAL  ( KIND = IREAL_HIGH )    SARG, WKY1
!C
      INTENT ( IN )  KWAVE
!C
!C    T2 1/a^2, 1/b^2, 1/c^2
!C    CENTW center of ellipsoid in water frame
!C    T5 point R in water frame
!C
      SARG   =    T5(1) * COS ( WDIR(KWAVE) )
     &          - T5(2) * SIN ( WDIR(KWAVE) )
      SARG   = WNUM(KWAVE) * SARG - FREQ(KWAVE) * TIME + WPHS(KWAVE)
      IF ( WDEP .GT. D_0 ) THEN
       WKY1   =  WNUM(KWAVE) * ( -T5(3) + WDEP )
       WEXPHI = -WGAM * WAMP(KWAVE) * COSH ( WKY1 ) 
     &                * COS ( SARG ) / SWKH(KWAVE)
      ELSE
       WEXPHI = -WGAM * WAMP(KWAVE) * COS ( SARG )
      END IF
!C
      RETURN
      END
