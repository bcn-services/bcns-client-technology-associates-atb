      SUBROUTINE UNIT1
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine controls the output for logical unit 1,
!C     which is the graphical output used by the various 
!C     programs, such as the VIEW program.
!C
!C    The format of the output is controlled by the value of NPRT(35),
!C     which is specified by the A.5 card.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NPRT, TIME,                               ! /CONTRL/
     &       OUT_TIMES,                                ! structures
     &       NUM_OUT_TIMES,                            ! parameters
     &       LOGICAL_STD, INTEGER_STD, FALSE, TRUE,    ! parameters
     &       LUAOU, I_0, I_1, I_2, I_3                 ! parameters
!C
!C     END, START, VIEW        ! OUT_TIMES%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I
!C
      LOGICAL  ( KIND = LOGICAL_STD )  RETURN_STATE
!C
      IF ( NPRT(1) .EQ. I_0 )  THEN
       RETURN
      END IF
!C
!C    Check if time windowing is in effect, and if so, will there
!C     be a output from UNIT1 on this call.
!C
      IF ( NUM_OUT_TIMES .EQ. I_0 )  THEN
       CONTINUE
      ELSE
       RETURN_STATE = TRUE
       DO I=1,NUM_OUT_TIMES
        IF ( .NOT. OUT_TIMES(I)%VIEW ) THEN
         RETURN_STATE = FALSE
         CYCLE
        ELSE 
         IF ( ( TIME .GE. OUT_TIMES(I)%START ) .AND.
     &        ( TIME. LE. OUT_TIMES(I)%END ) )  THEN
          RETURN_STATE = FALSE
         END IF
        END IF
       END DO
       IF ( RETURN_STATE )  RETURN
      END IF
!C
!C    For version V.3 of ATB, the following values for NPRT(35) are
!C    supported:
!C       NPRT(35) =0  - new structured ASCII format, extension .SA1
!C
!C       NPRT(35) =1  - old binary format, extension .UF1 (not supported
!C                      in view)
!C       NPRT(35) =2  - old ASCII format, extension .TP1
!C       NPRT(35) >=3 - new structured ASCII format, extension
!C                      .SA1, with warning printed in UNIT 6 .AOU file
!C
      IF ( NPRT(35) .EQ. I_0) THEN
       CALL U1ASC
      ELSE IF ( ( NPRT(35) .EQ. I_1 ) .OR. 
     &          ( NPRT(35) .EQ. I_2 ) ) THEN
       CALL U1OLD
      ELSE IF ( NPRT(35) .GE. I_3 )  THEN
       WRITE ( LUAOU, 100 )
  100  FORMAT ( 1X, 'WARNING:  Invalid value for NPRT(35) used.' )
       CALL U1ASC
      END IF
!C
      RETURN
      END
