      SUBROUTINE  DATE_TIME ( LBEGIN, LUOUT )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine computes the start time and date, and the end
!C     time and date, as well as the elapsed CPU time of a run.
!C
!C    arguments:  LBEGIN - logical flag
!C                          .TRUE.  = beginning of the run;
!C                          .FALSE. = end of the run;   
!C                             used - not altered. 
!C                LUOUT  - logical unit number to write
!C                          time information to;
!C                             used - not altered.
!C
!C    Local variables.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       ICHAR_STD, INTEGER_STD,             ! parameters
     &       IREAL_STD, LOGICAL_STD, I_11, I_12, ! parameters
     &       LUTERM_OUT
!C
      IMPLICIT  NONE
!C
      INTENT ( IN )  LBEGIN, LUOUT
!C
!C    Intrinsic subroutines.  Note that "CPU_TIME" is a f95, not a
!C     f90, intrinsic subroutines.
!C
      INTRINSIC  CPU_TIME, DATE_AND_TIME
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         LUOUT, NDAYS, NHOURS, NMINU, 
     &         ITIME_WALL_START, ITIME_WALL_STOP,
     &         ITIME_OFFSET_START, ITIME_OFFSET_STOP
      DIMENSION  ITIME_WALL_START(8), ITIME_WALL_STOP(8)
!C
!C    The KIND for ITIME_WALL must be default INTEGER KIND.
!C
      INTEGER    ITIME_WALL
      DIMENSION  ITIME_WALL(8)

      REAL  ( KIND = IREAL_STD ) 
     &      TIME_CPU, TIME_CPU_START, TIME_CPU_STOP,
     &      TIME_CPU_ELAPSED, RSECND
!C
      CHARACTER ( LEN =  2, KIND = ICHAR_STD ) MERID_START, MERID_END
      CHARACTER ( LEN =  4, KIND = ICHAR_STD ) MONTH_NAME_START,
     &                                         MONTH_NAME_END
      CHARACTER ( LEN =  5, KIND = ICHAR_STD ) ZONE
      CHARACTER ( LEN =  8, KIND = ICHAR_STD ) DATE, DATE_START, 
     &                                         DATE_END
      CHARACTER ( LEN = 10, KIND = ICHAR_STD ) TIME_WALL, 
     &                        TIME_WALL_START, TIME_WALL_STOP
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LBEGIN
!C
!C    Variable(s) to save upon exiting the subroutine.
!C
      SAVE  TIME_CPU_START, TIME_WALL_START, DATE_START,
     &      MONTH_NAME_START, MERID_START, ITIME_OFFSET_START
!C
      IF ( LBEGIN )  THEN  
!C
       CALL CPU_TIME ( TIME_CPU )
       TIME_CPU_START = TIME_CPU
!C
       CALL DATE_AND_TIME ( DATE, TIME_WALL, ZONE, ITIME_WALL )
       TIME_WALL_START = TIME_WALL
       ITIME_WALL_START = ITIME_WALL
       DATE_START = DATE
!C
!C     Get the name of the month for the starting time.
!C
       CALL GET_MONTH_NAME ( ITIME_WALL_START(2), MONTH_NAME_START )
!C
!C    Determine if the start time was in the AM or the PM.
!C
       IF ( ITIME_WALL_START(5) .GT. I_11 )  THEN
        MERID_START = 'pm'
        ITIME_OFFSET_START = ITIME_WALL_START(5)
        IF ( ITIME_WALL_START(5) .GT. 12 )  THEN
         ITIME_OFFSET_START = ITIME_WALL_START(5) - I_12
        END IF
       ELSE
        MERID_START = 'am'
        ITIME_OFFSET_START = ITIME_WALL_START(5)
       END IF 
!C
!C     Print the starting time to the terminal/console.
!C
       WRITE ( LUTERM_OUT, 100 )  ITIME_OFFSET_START,
     &                           TIME_WALL_START(3:4),
     &                           TIME_WALL_START(5:6),
     &                           MERID_START,
     &                           MONTH_NAME_START,
     &                           DATE_START(7:8), DATE_START(1:4)
  100 FORMAT ( 1X, 'The was run started at: ', 
     &              I2, ':', A2, ':', A2, A2, ';', 1X,
     &              A4, 1X, A2, ',',  1X, A4, / )
!C
       RETURN
      END IF
!C
!C****************************
!C
!C    Remainder of the subroutine is entered at the completion
!C     of the run.
!C
      CALL CPU_TIME ( TIME_CPU )
      TIME_CPU_STOP = TIME_CPU
      TIME_CPU_ELAPSED = TIME_CPU_STOP - TIME_CPU_START
!C
      CALL DATE_AND_TIME ( DATE, TIME_WALL, ZONE, ITIME_WALL )
      TIME_WALL_STOP = TIME_WALL
      ITIME_WALL_STOP = ITIME_WALL
      DATE_END = DATE
!C
!C    Determine if the stop time was in the AM or the PM.
!C
      IF ( ITIME_WALL_STOP(5) .GT. I_11 )  THEN
       MERID_END = 'pm'
       ITIME_OFFSET_STOP = ITIME_WALL_STOP(5)
       IF ( ITIME_WALL_STOP(5) .GT. 12 )  THEN
        ITIME_OFFSET_STOP = ITIME_WALL_STOP(5) - I_12
       END IF
      ELSE
       MERID_END = 'am'
       ITIME_OFFSET_STOP = ITIME_WALL_STOP(5)
      END IF 
!C
!C    Print a spacing after the list of subroutines.
!C
      WRITE ( LUOUT, 105 )
  105 FORMAT ( 1X, /, / )
!C
!C    Print out the starting and ending date.
!C
      WRITE ( LUOUT, 110 )  ITIME_OFFSET_START,
     &                      TIME_WALL_START(3:4),
     &                      TIME_WALL_START(5:6),
     &                      MERID_START,
     &                      MONTH_NAME_START,
     &                      DATE_START(7:8), DATE_START(1:4)
  110 FORMAT ( 1X, 'The run started at: ', 
     &              I2, ':', A2, ':', A2, A2, ';', 1X,
     &              A4, 1X, A2, ',',  1X, A4 )
!C
!C    Get the name of the month for the ending time.
!C
      CALL GET_MONTH_NAME ( ITIME_WALL_STOP(2), MONTH_NAME_END )
!C
!C
      WRITE ( LUOUT, 115 )  ITIME_OFFSET_STOP,
     &                      TIME_WALL_STOP(3:4),
     &                      TIME_WALL_STOP(5:6),
     &                      MERID_END,
     &                      MONTH_NAME_END,
     &                      DATE_END(7:8), DATE_END(1:4)
      
      WRITE ( LUTERM_OUT, 115 )  ITIME_OFFSET_STOP,
     &                           TIME_WALL_STOP(3:4),
     &                           TIME_WALL_STOP(5:6),
     &                           MERID_END,
     &                           MONTH_NAME_END,
     &                           DATE_END(7:8), DATE_END(1:4)
      
  115 FORMAT ( 1X, 'The run ended at: ', 2X, 
     &              I2, ':', A2, ':', A2, A2, ';', 1X,
     &              A4, 1X, A2, ',',  1X, A4, / )
!C
!C     Convert the elapsed CPU time to days, hours, minutes, seconds.
!C
      CALL CONVERT_TIME ( TIME_CPU_ELAPSED, NDAYS, 
     &                    NHOURS, NMINU, RSECND )
!C
      WRITE ( LUOUT, 120 )      NDAYS, NHOURS, NMINU, RSECND
      WRITE ( LUTERM_OUT, 120 ) NDAYS, NHOURS, NMINU, RSECND
  120 FORMAT ( 1X, ' Elapsed CPU time:   ', I2, '(days)', 1X,
     &                                      I2, '(hr)',   1X,
     &                                      I2, '(min)',  1X,
     &                                    F6.3, '(sec)', /,/ )
!C
      RETURN
      END
