      SUBROUTINE  INPUT_WATER_OUTPUT
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Controls the input of cards F.9.k - F.9.m containing the setup 
!C    and control of the water force output data.                
!C    This subroutine is called only by Subroutine INPUT_WATER.
!C
!C
!C    output parameters:
!C    NSEQN         = number of output sequences to be generated
!C    NELL(I)       = number of ellipsoids in sequence I
!C    NELOUT(I,1,J) = reference of number of ellipsoid J in sequence I
!C    NELOUT(I,2,J) = reference number of the segment to which NELOUT(I,1,J)
!C                    is attached
!C
!C    ITYPE(1) =  1  Output total force and torque acting on the sequence
!C         (2) =  1  Output buoyancy forces and torques  "    "    "
!C         (3) =  1  Output Wave-Excitation forces and torques "   "
!C         (4) =  1  Output added-mass and damping forces       "  "
!C         (5) =  1  Output drag and lift forces acting on the  "  "
!C         (6) = -1  Output is in inertial system
!C                0               local coordinate system
!C                1               ellipsoid system 
!C                   Note: ITYPE(6) is considered only when NELL(I) = 1
!C    WDSE          = WD.D-1(seg).D-1(elp)
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD,                        ! parameters
     &       LUAIN, LUAOU, MAXELP, I_0, I_1,     ! parameters 
     &       AIN_CONVERT, LIN_FLAG, LULIN        ! parameters
!C  
      USE  MODULE_WATER,  ONLY:
     &       KPFD, NUM_ELLIP_WATER_CT, NUM_PER_FLOAT_DEV, NWSE, ! /WATINF1/
     &       ITYPE, NELL, NELOUT, NSEQN                         ! /WFACOP/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              I, II, J, K, K1, L, L1, L2

!C
!C    Read and echo Card F.9.k.
!C
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )  NSEQN, ( ITYPE(J), J=1,6 )
      ELSE
       READ  ( LUAIN, 100 )  NSEQN, ( ITYPE(J), J=1,6 )
  100  FORMAT ( 7I5 )
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 105 )  NSEQN, ( ITYPE(J), J=1,6 ), 'Card F.9.k'
  105   FORMAT ( 1X, 7( I6, 1X ), 1X, A )
       END IF
      END IF
      WRITE ( LUAOU, 110 )  ( ITYPE(J), J=1,6 )
  110 FORMAT ( /, 1X, 'ITYPE Array', /, 6I5 )
      IF ( NSEQN .GT. I_0 )  THEN
       WRITE ( LUAOU, 115 )
  115  FORMAT ( /, 3X, 'Output', 4X, 'NO. OF', 4X, 'Ellipsoid',  
     &          /, 2X, 'Sequence', 2X, 'Ellipsoids' )
!C
!C     Read in Card F.9.l.
!C
       L2 = I_0
       DO  I=1,NSEQN
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  NELL(I)
        ELSE
         READ ( LUAIN, 120 )  NELL(I)
  120    FORMAT ( I5 )
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 125 )  NELL(I), 'Card F.9.l'
  125     FORMAT ( 1X, I6, 2X, A )
         END IF
        END IF
        L1 = L2 + I_1
        DO  K=1,NELL(I)
         K1 = K1 + I_1
!C
!C       Read in Card F.9.m.
!C
         IF ( LIN_FLAG )  THEN
          READ ( LULIN, * )  NELOUT(I,1,K1)
         ELSE
          READ ( LUAIN, 130 )  NELOUT(I,1,K1)
  130     FORMAT ( 10I5 )
          IF ( AIN_CONVERT )  THEN
           WRITE ( LULIN, 135 )  NELOUT(I,1,K1), 'Card F.9.m'
  135      FORMAT ( 1X, I5, 2X, A )
          END IF
         END IF
!C
         IF ( NELOUT(I,1,K1) .LE. MAXELP )  THEN
          IF ( NUM_ELLIP_WATER_CT .LE. I_0 )  THEN
           WRITE ( LUAOU, 140 ) NELOUT(I,1,K1)
  140      FORMAT ( 1X, ' Invalid ellipsoid number, ', I3, 
     &                  'for water output data. ', /, 
     &            ' No body segments specified to contact the water. ' )
           STOP ' STOP 595 in Subroutine INPUT_WATER_OUTPUT '
          END IF
          DO  L=1,NUM_ELLIP_WATER_CT
           IF ( NELOUT(I,1,K1) .EQ. NWSE(1,L) ) THEN
            NELOUT(I,2,K1) = NWSE(2,L)
           END IF
          END DO
         ELSE 
          IF ( NUM_PER_FLOAT_DEV .LE. I_0 )  THEN
           WRITE ( LUAOU, 145 ) NELOUT(I,1,K1)
  145      FORMAT ( 1X, ' Invalid ellipsoid number, ', I3, 
     &                  'for water output data. ', /, 
     &            ' No personal floation devices specified. ' )
           STOP ' STOP 596 in Subroutine INPUT_WATER_OUTPUT '
          END IF
          II = NELOUT(I,1,K1) - MAXELP     
          NELOUT(I,2,K1) = KPFD(II)
         END IF
        END DO
        L2 = K1
        WRITE ( LUAOU, 150 ) I, NELL(I), ( NELOUT(I,1,L), L=L1,L2 )
  150   FORMAT ( 5X, I2, 8X, I2, 6X, 20I3, /, 23X, 20I3 )
       END DO
      END IF
!C
      RETURN
      END