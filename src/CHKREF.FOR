      SUBROUTINE CHKREF ( IREFPL, IREFEL )
!C
!C                                                     Rev. V.3 12/15/2002 
!C
!C    This subroutine checks all the contact planes and contact 
!C     ellipsoids defined for a simulation to see if they have
!C     been assigned to a segment.  Any contact planes or contact
!C     ellipsoids that have not been assigned to a segment are
!C     assigned to the primary vehicle segment.   This check
!C     and assignment are done so that these objects will move
!C     and be displayed properly in graphical output, even if they
!C     serve no purpose in the physics of the simulation.
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       IBMODL,                                  ! /BAGDIM/
     &       NBAG, NBLT, NHRNSS, NPL, NSEG, NVEH,     ! /CONTRL/
     &       NPANEL,                                  ! /FORCES/
     &       IBAR, NBLTPH, NPTSPB,                    ! /HRNESS/
     &       MNPL, MPL, MNSEG, MNBLT, MNBAG,          ! /JBARTZ/
     &       MSEG, MBAG, MBLT,                        ! /JBARTZ/
     &       MOWSEG, MWSEG, MOWELP,                   ! /WINDFR/
     &       MELL, NELP, NN,                          ! /XTRA/
     &       INTEGER_STD, IREAL_HIGH, MAXELP, MAXPLN, ! parameters
     &       I_0, I_1                                 ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &            I, IEL, IEL1, IEL2, IPL, IREFEL, IREFPL, J, J1, J2, 
     &            K, K1, K2, NOT_DEF, NN1, NN2, NOS
      DIMENSION   IREFPL(MAXPLN), IREFEL(MAXELP)
!C
      INTENT ( OUT )  IREFPL, IREFEL
!C
!C    Initialize the IREFPL array to -1, indicating
!C     that no reference segment was assigned to the
!C     contact plane.
!C
      DO  I = 1,NPL
       IREFPL(I) = -I_1
      END DO
!C
!C    Define the first NSEG contact ellipsoids to be have the
!C     the same reference segment as the contact ellipsoid number
!C     (the default).
!C
      DO  I = 1,NSEG
       IREFEL(I) = I
      END DO
!C
!C    Initialize the reference segment numbers for the extra
!C     contact ellipsoids to -1 in the reference segment array.
!C
      DO  I = 1,NELP
       IF ( MELL(I) .GT. NSEG ) THEN
        IREFEL(MELL(I)) = -I_1
       END IF
      END DO
!C
!C    If no reference segment has been assigned for the Ith plane,
!C     IREFPL(I) < 0, and contacts have been specified for the plane,
!C     MNPL(I) > 0, assign the value of the segment to which the
!C     plane is attached, MPL(1,1,I), to the IREFPL array.
!C
      DO  I = 1,NPL
       IF ( ( IREFPL(I) .LT. I_0 ) .AND. 
     &      ( MNPL(I) .GT. I_0 ) ) THEN
        IREFPL(I) = MPL(1,1,I)
       END IF
      END DO
!C
!C    For each contact ellipsoid allowed to contact the Ith plane
!C     (1,NN), check if a reference segment has been specified
!C     for that contact ellipsoid (IREFEL(IEL) > 0 ), if not,
!C     set the reference segment to be the one specified in the 
!C     F.1 cards (MPL(2,J,I).
!C
      DO  I = 1,NPL
       NN = MNPL(I)
       DO  J = 1,NN
        IEL = ABS ( MPL(3,J,I) )
        IF ( IREFEL(IEL) .LT. I_0 ) THEN
         IREFEL(IEL) = MPL(2,J,I)
        END IF
       END DO
      END DO
!C
!C    For each segment, check every contact that is specified
!C     for the Ith segmet ( 1, NN ) check every contact ellipsoid that
!C     is either attached to it ( IEL1 ) or that can contact it
!C     ( IEL2 ) to see if a reference segment has
!C     been specified for that contact ellipsoid ( IREFEL(IEL1) > 0 ).
!C     If one has not been specified yet, assign the reference 
!C     segment that was specified for it by the F.3 cards ( IEL1 ) for the
!C     contact ellipsoids that are attached to the segment, or for 
!C     contact ellipsoids that are to contact the segment, specify
!C     the reference segment that was provided for that contact ellipsoid
!C     in the F.3 cards ( MNSEG(2,J,I) ).
!C
      DO  I = 1,NSEG
       NN = MNSEG(I)
       DO  J = 1,NN
        IEL1 = MSEG(1,J,I)
        IEL2 = ABS ( MSEG(3,J,I) )
        IF ( IREFEL(IEL1) .LT. I_0 ) THEN
         IREFEL(IEL1) = I
        END IF
        IF ( IREFEL(IEL2) .LT. I_0 ) THEN
         IREFEL(IEL2) = MSEG(2,J,I)
        END IF
       END DO
      END DO
!C
!C    For each belt, assign the ellipsoids that the belt contacts
!C     (1,NN) to the segments that were specified for these 
!C     ellipsoids in the F.2 cards.
!C
      DO  I = 1,NBLT
       NN = MNBLT(I)
       DO  J = 1,NN
        IEL = MBLT(3,J,I)
        IF ( IREFEL(IEL) .LT. I_0 ) THEN
         IREFEL(IEL) = MBLT(2,J,I)
        END IF
       END DO
      END DO
!C
!C    Assign the contact ellipsoids associated with the airbag
!C     contacts to segments.
!C
      DO  I = 1,NBAG
       NN1 = MNBAG(I)
       DO  J = 1,NN1
        IEL = MBAG(2,J,I)
        IF ( IREFEL(IEL) .LT. I_0 ) THEN
         IREFEL(IEL) = MBAG(1,J,I)
        END IF
       END DO
       IF ( IBMODL(I) .NE. I_0 ) THEN
        NN2 = NPANEL(I)
        DO  J = 1,NN2
         IPL = MBAG(2,J,I)
         IF ( IREFPL(IPL) .LT. I_0 ) THEN
          IREFPL(IPL) = MBAG(1,J,I)
         END IF
        END DO
       END IF
      END DO
!C
!C    Assign the contact ellipsoids and the contact planes associated
!C     with the wind forces to segments.
!C
      DO  I = 1,NSEG
       NN = ABS(MWSEG(1,I))
       IF (NN .NE. 0) THEN          
        IEL = MWSEG(2,I)
        IPL = MWSEG(4,I)
        IF ( IREFEL(IEL) .LT. I_0 ) THEN
         IREFEL(IEL) = NN
        END IF
        IF ( IREFPL(IPL) .LT. I_0 ) THEN
         IREFPL(IPL) = MWSEG(3,I)
        END IF
        NOS = MWSEG(7,I)
        DO  K = 1,NOS
         IEL = MOWELP(K,I)
         IF ( IREFEL(IEL) .LT. I_0 )  THEN
          IREFEL(IEL) = MOWSEG(K,I)
         END IF
        END DO
       END IF
      END DO
!C
!C    Assign the contact ellipsoids associated with the harness
!C     belts to segments.
!C
      J2 = I_0
      K2 = I_0
      DO  I = 1,NHRNSS
       IF ( NBLTPH(I) .NE. I_0 ) THEN
        J1 = J2 + I_1
        J2 = J1 + NBLTPH(I) - I_1
        DO  J = J1,J2
         IF ( NPTSPB(J) .NE. I_0 ) THEN
          K1 = K2 + I_1
          K2 = K1 + NPTSPB(J) - I_1
          DO  K = K1,K2
!C
!C         Get the identification number of the contact ellipsoid
!C          associated with Kth reference point.
!C
           IEL = IBAR(2,K)
!C
!C         Deal with the option that KE (see Card F.8.d1) can be 0.
!C
           IF ( IEL .NE. I_0 )  THEN
            IF ( IREFEL(IEL) .LT. I_0 ) THEN
             IREFEL(IEL) = IBAR(1,K)
            END IF
           END IF
          END DO
         END IF
        END DO
       END IF
      END DO
!C
!C    Assign all contact ellipsoids and contact planes that
!C     have not been assigned to a segment to the primary
!C     vehicle segment.
!C
      NOT_DEF = NVEH
      DO  I = 1,NPL
       IF ( IREFPL(I) .LT. I_0 ) THEN
        IREFPL(I) = NOT_DEF
       END IF
      END DO
      DO  I = 1,NELP
       IF ( IREFEL(MELL(I)) .LT. I_0 ) THEN
        IREFEL(MELL(I)) = NOT_DEF
       END IF
      END DO
!C
      RETURN
      END
