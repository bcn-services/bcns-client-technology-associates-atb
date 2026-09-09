      SUBROUTINE U1ASCH
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE MODULE_STANDARD,  ONLY:
     &      BD, PL,                                        ! /CONTRL/
     &      NHRNSS, NGRND, NPL, NSEG, NVEH,                ! /CONTRL/
     &      IHARFM, IHARTY, IRGDFM, IRGDTY,                ! /COUTFMT/
     &      ITIMFM, ITIMTY,                                ! /COUTFMT/
     &      NTOBLT, NTOPTS,                                ! /COUTN/
     &      IBAR, NBLTPH, NPTSPB,                          ! /HRNESS/
     &      MBLT,                                          ! /JBARTZ/
     &      BDYTTL, COMENT, DATE, PLTTL,                   ! /TITLES/
     &      VPSTTL,                                        ! /TITLES/
     &      MELL, NELP, P1S, P2S, P3S, P4S,                ! /XTRA/
     &      SEG,                                           ! structures
     &      ICHAR_STD, INTEGER_STD, IREAL_STD,             ! parameters
     &      LUVIEW, MAXELP, MAXPLN,                        ! parameters
     &      PROGRAM_NAME, VERSION_NUMBER, VERSION_DATE,    ! parameters
     &      D_0, R_0, I_0, I_1, I_2, I_3,I_4, I_5, I_6,    ! parameters
     &      I_7, I_8, I_9, I_10, I_12                      ! parameters
!C
!C     SEG%NAME,
!C
      USE MODULE_WATER, ONLY:     
     &      BDPFD, KPFD, NELPFD, NUM_PER_FLOAT_DEV,          ! /WATINF1/
     &      NWATER, NWAVES,                                  ! /WATINF1/
     &      FREQ, WAMP, WD, WDEP, WDIR, WNUM, WOFSET, WPHS   ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, IELATB, IELL, IOBJTY, IOTYP, 
     &           IPLTYP, IREFEL, IREFPL, 
     &           J, JOTYP, K, KK, NC, NDYN, NTEPFD, NTIME, NTITLE
      DIMENSION  IOBJTY(10), IREFPL(MAXPLN), IREFEL(MAXELP)            
!C
      INTEGER   ( KIND = INTEGER_STD )  NUMCHR
      EXTERNAL   NUMCHR
!C
      CHARACTER ( LEN =  4, KIND = ICHAR_STD )  ENDSTR
      CHARACTER ( LEN =  2, KIND = ICHAR_STD )  CHRN
      CHARACTER ( LEN =  8, KIND = ICHAR_STD )  ELLNAM
      CHARACTER ( LEN = 32, KIND = ICHAR_STD )  OBJDES, ENDOBJ
      DIMENSION       OBJDES(10)

!C
      REAL  ( KIND = IREAL_STD )
     &            XBD, XPL, XPL1, XPL2, XPL3, XP1, XP2, XP3,
     &            XP4, XWDEP, XWOF, XWD,XWNUM,                
     &            XWAMP, XWDIR, XFREQ, XWPHS, XBDPFD
      DIMENSION   XBD(24), XPL1(3), XPL2(3), 
     &            XPL3(3), XPL(17,MAXPLN), XP1(3), XP2(3),
     &            XP3(3), XP4(3), XWOF(3),
     &            XWD(3,3), XWNUM(10), XWAMP(10), XWDIR(10),
     &            XFREQ(10), XWPHS(10), XBDPFD(30,25)

!C
      REAL   ( KIND = IREAL_STD ) CHECK_HIGH_VALUE
      EXTERNAL CHECK_HIGH_VALUE
!C                                                                  
      DATA  IOBJTY /  I_1,  I_2,   I_3,  
     &                I_4, I_5,  I_6,  
     &                I_7, 21_INTEGER_STD, 101_INTEGER_STD,
     &               41_INTEGER_STD /
      DATA  OBJDES / ICHAR_STD_'Segment Ellipsoids',
     &               ICHAR_STD_'Planes', 
     &               ICHAR_STD_'Belts',
     &               ICHAR_STD_'Airbags',
     &               ICHAR_STD_'Additional Ellipsoids',
     &               ICHAR_STD_'Harness Belts', 
     &               ICHAR_STD_'Springs',
     &               ICHAR_STD_'Water Forces',
     &               ICHAR_STD_'Dynamic Data Header', 
     &               ICHAR_STD_'PL Array' /
      DATA           ENDSTR / ICHAR_STD_'End' /, 
     &               ENDOBJ / ICHAR_STD_'End Objects' /
      DATA           NTITLE / I_5 /
!C
      CALL CHKREF ( IREFPL, IREFEL )
!C
!C    Write header titles
!C
      WRITE ( LUVIEW, 101 )  PROGRAM_NAME, VERSION_NUMBER, 
     &                       VERSION_DATE
  101 FORMAT ( 1X, 'Program = ', A4, ';  ', 'Version = ', A12, ';  ',
     &         'Date = ', A17 )
      WRITE ( LUVIEW, 103 )  NTITLE
  103 FORMAT ( I5 )
      WRITE ( LUVIEW, 104 ) DATE 
  104 FORMAT ( A12 )
      WRITE ( LUVIEW, 105 ) COMENT
  105 FORMAT ( A80, /, A80 )
      WRITE ( LUVIEW, 106)  VPSTTL
  106 FORMAT ( A80 )
      WRITE ( LUVIEW, 107 ) BDYTTL
  107 FORMAT ( A20 )
!C
      IF ( NSEG .GT. I_0 ) THEN
       IOTYP = I_1
       JOTYP = IOBJTY(IOTYP)
       WRITE ( LUVIEW, 110 ) OBJDES(IOTYP), JOTYP, NSEG
  110  FORMAT ( A32, 2I5 )
       DO  I = 1,NSEG
!C
!C      K = 2 is a hyperellipsoid.
!C
        K = I_1
        IF ( BD(1,I) .LT. D_0 )  K = I_2
        IELATB = K
        DO  J=1,23
         XBD(J) = CHECK_HIGH_VALUE ( BD(K,I) )
         K = K + I_1
        END DO
        XBD(24) = R_0
        WRITE ( LUVIEW, 112 ) SEG(I)%NAME, IELATB, IREFEL(I), XBD
  112   FORMAT ( A8, 2X, 2I5, /, ( 3( G16.9, 2X ) ) )
       END DO
       WRITE ( LUVIEW, 114 )  ENDSTR, OBJDES(IOTYP)
  114  FORMAT ( A4, 2X, A32 )
      END IF
!C
!C
      IF ( NPL .GT. I_0 )  THEN
       IOTYP = I_2
       JOTYP = IOBJTY(IOTYP)
       WRITE ( LUVIEW, 110 )  OBJDES(IOTYP), JOTYP, NPL
       IPLTYP = I_0
       DO  I = 1,NPL
        DO  J = 1,3
         XPL1(J) = CHECK_HIGH_VALUE ( PL(J+4,I) )
         XPL2(J) = CHECK_HIGH_VALUE ( PL(J+17,I) ) + XPL1(J)
         XPL3(J) = CHECK_HIGH_VALUE ( PL(J+20,I) ) + XPL1(J)
        END DO
        WRITE ( LUVIEW, 121 )  PLTTL(I), IPLTYP, IREFPL(I), 
     &                    XPL1, XPL2, XPL3
  121   FORMAT ( A20, 2X, 2I5, /, ( 3( G16.9, 2X ) ) )
       END DO
       WRITE ( LUVIEW, 114 )  ENDSTR, OBJDES(IOTYP)
!C
!C     Add printout for PL array elements 1- 17 for each plane
!C
       IOTYP = I_10
       JOTYP = IOBJTY(IOTYP)
       WRITE ( LUVIEW, 110 )  OBJDES(IOTYP), JOTYP, NPL
!C
!C     Data must be converted to single precision for view program.     
!C     Write only for planes used=NPL, not to MAXPLN                  
!C
       DO  J=1,NPL                                                       
        DO  I=1,17
         XPL(I,J) = CHECK_HIGH_VALUE ( PL(I,J) )
        END DO
       END DO
       WRITE ( LUVIEW, 122 )  ( ( XPL(I,J), I=1,17 ), J=1,NPL )
  122  FORMAT ( 6( G16.9, 2X ) )
       WRITE ( LUVIEW, 114 ) ENDSTR, OBJDES(IOTYP)
      END IF
!C
      IF ( NELP .GT. I_0 ) THEN
       IOTYP = I_5
       JOTYP = IOBJTY(IOTYP)
       WRITE ( LUVIEW, 110 )  OBJDES(IOTYP), JOTYP, NELP
       DO  I = 1,NELP
        NC = NUMCHR(MELL(I),CHRN)
        ELLNAM = 'ELL'//CHRN(1:NC)
        IELL = MELL(I)
!C
!C      KK = 2 is a hyperellipsoid.
!C
        KK = I_1
        IF ( BD(1,MELL(I)) .LT. D_0 )  KK = I_2
        IELATB = KK
        DO  J=1,23
         XBD(J) = CHECK_HIGH_VALUE ( BD(KK,MELL(I)) )
         KK = KK + I_1
        END DO
        XBD(24) = R_0
        DO  J = 1,3
         XP1(J) = P1S(J,I)
         XP2(J) = P2S(J,I)
         XP3(J) = P3S(J,I) 
         XP4(J) = P4S(J,I)
        END DO
        WRITE ( LUVIEW, 142 ) ELLNAM, IELATB, IREFEL(IELL), IELL, XBD
  142   FORMAT ( A8, 3I5, /, ( 6( G16.9, 2X ) ) )
        WRITE ( LUVIEW, 151 )  XP1, XP2, XP3, XP4
  151   FORMAT ( ( 3( G16.9, 2X ) ) )
       END DO
       WRITE ( LUVIEW, 114 )  ENDSTR, OBJDES(IOTYP)
      END IF
!C
!C
      IF ( NHRNSS .GT. I_0 )  THEN
       IOTYP = I_6
       JOTYP = IOBJTY(IOTYP)
       NTOBLT = I_0
       DO  I = 1,NHRNSS
        NTOBLT = NTOBLT + NBLTPH(I)
       END DO
       NTOPTS = I_0
       DO  I = 1,NTOBLT
        NTOPTS = NTOPTS + NPTSPB(I)
       END DO
!C
       WRITE ( LUVIEW, 110 )  OBJDES(IOTYP), JOTYP, NHRNSS
       WRITE ( LUVIEW, 161 )  NTOBLT, NTOPTS
  161  FORMAT ( 2I5 )
       WRITE ( LUVIEW, 162 )  ( NBLTPH(I), I=1,NHRNSS ),
     &                        ( NPTSPB(I), I=1,NTOBLT ),
     &                      ( ( IBAR(I,J), I=1,2 ), J=1,NTOPTS )
  162  FORMAT ( 10I5 )
       WRITE ( LUVIEW,114 )  ENDSTR, OBJDES(IOTYP)
      END IF
!C
!C    Print out water force info.
!C
      IF ( NWATER .GT. I_0 ) THEN
       IOTYP = I_8
       JOTYP = IOBJTY(IOTYP)
       WRITE ( LUVIEW, 110 )  OBJDES(IOTYP), JOTYP, NWATER
       NTEPFD = I_0
       IF ( NUM_PER_FLOAT_DEV .GT. I_0 )  THEN
        DO  I = 1,NUM_PER_FLOAT_DEV
         NTEPFD = NTEPFD + NELPFD(I)
        END DO
       END IF
!C
       WRITE ( LUVIEW, 181 )  NWATER, NWAVES, NUM_PER_FLOAT_DEV, NTEPFD
  181  FORMAT ( 4I5 )
       XWDEP = CHECK_HIGH_VALUE ( WDEP )
       DO  I = 1,3
        XWOF(I) = CHECK_HIGH_VALUE ( WOFSET(I) ) 
        DO  J = 1,3
         XWD(J,I) = CHECK_HIGH_VALUE ( WD(J,I) )
        END DO
       END DO
       DO  I = 1,NWAVES
        XWNUM(I) = CHECK_HIGH_VALUE ( WNUM(I) )
        XWAMP(I) = CHECK_HIGH_VALUE ( WAMP(I) )
        XWDIR(I) = CHECK_HIGH_VALUE ( WDIR(I) )
        XWPHS(I) = CHECK_HIGH_VALUE ( WPHS(I) )
        XFREQ(I) = CHECK_HIGH_VALUE ( FREQ(I) )
       END DO
       WRITE ( LUVIEW, 182 )  XWOF, XWD, XWDEP
  182  FORMAT ( 3( G16.9, 2X ) )
       DO  I = 1,NWAVES
        WRITE ( LUVIEW, 183 )  XWNUM(I), XWAMP(I), XWDIR(I), XWPHS(I),
     &                    XFREQ(I)
  183   FORMAT ( 5( G16.9, 2X ) )
       END DO
       IF ( NUM_PER_FLOAT_DEV .GT. I_0 )  THEN
        WRITE ( LUVIEW, 184 )  ( NELPFD(I), I=1,NUM_PER_FLOAT_DEV )
  184   FORMAT ( 10I5 )
        DO  I = 1,NTEPFD
         DO  J = 1,30
          XBDPFD(J,I) = CHECK_HIGH_VALUE ( BDPFD(J,I) )
         END DO
         IELATB = I_1
         NC = NUMCHR ( I, CHRN )
         ELLNAM = 'PFDELL' // CHRN(1:NC)
         WRITE ( LUVIEW, 185 ) ELLNAM, IELATB, KPFD(I), 
     &                    ( XBDPFD(J,I), J=1,30 )
  185    FORMAT ( A8, 2X, 2I5, /, ( 6( G16.9, 2X ) ) )
        END DO
       END IF
       WRITE ( LUVIEW,114 )  ENDSTR, OBJDES(IOTYP)
      END IF
!C
!C    Setup data header for dynamic records
!C
      NDYN = I_0
      IF ( NGRND .GT. I_0 ) THEN
       NDYN = I_2
      END IF
      IF ( NHRNSS .GT. I_0 ) THEN
       NDYN = NDYN + I_1
      END IF
!C
      IF ( NDYN .GT. I_0 ) THEN
       IOTYP = I_9
       JOTYP = IOBJTY(IOTYP)
       WRITE ( LUVIEW, 110 )  OBJDES(IOTYP), JOTYP, NDYN
!C
       ITIMTY = I_0
       NTIME = I_1
       ITIMFM = I_2
       WRITE ( LUVIEW, 191 )  ITIMTY, NTIME, ITIMFM
  191  FORMAT ( 3I5 )
!C
       IF ( NGRND .GT. I_0 ) THEN
        IRGDTY =I_2
        IRGDFM = I_2
        WRITE ( LUVIEW, 191 ) IRGDTY,NGRND,IRGDFM
       END IF
!C
       IF ( NHRNSS .GT. I_0 ) THEN
        IHARTY = I_12
        IHARFM = I_1
        WRITE ( LUVIEW, 191 ) IHARTY, NHRNSS, IHARFM
       END IF
       WRITE ( LUVIEW, 114 )  ENDSTR, OBJDES(IOTYP)
      END IF
!C
      WRITE ( LUVIEW, 110 ) ENDOBJ
!C
      RETURN
      END
