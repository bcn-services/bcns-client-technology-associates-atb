      SUBROUTINE  CONVERT_TIME ( RTIME, NDAYS, NHOURS, NMINU, RSECND )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine converts an elapsed time, as provided
!C     by RTIME into a day, hour, minute, second representation.
!C
!C     Arguments:  RTIME  - delta time in seconds - used, not altered;
!C                 NDAYS  - number of days - defined;
!C                 NHOURS - number of hours - defined;
!C                 NMINU  - number of minutes - defined;
!C                 RSECND - number of seconds - defined.
!C
      USE  MODULE_STANDARD,  ONLY:
     &        INTEGER_STD, IREAL_STD ! parameters
!C
      IMPLICIT  NONE
!C
      INTENT ( IN  )  RTIME
      INTENT ( OUT )  NDAYS, NHOURS, NMINU, RSECND
!C
      INTEGER  ( KIND = INTEGER_STD )  NDAYS, NHOURS, NMINU
!C
      REAL  ( KIND = IREAL_STD ) RTIME, RDAYS, RHOURS, RSECND
!C
!C    Perform the conversion.
!C
      NDAYS   = INT ( RTIME / 86400.0_IREAL_STD )
      RDAYS   = MOD ( RTIME , 86400.0_IREAL_STD )
!C
      NHOURS  = INT ( RDAYS / 3600.0_IREAL_STD )
      RHOURS  = MOD ( RDAYS , 3600.0_IREAL_STD )
!C
      NMINU   = INT ( RHOURS / 60.0_IREAL_STD )
      RSECND  = MOD ( RHOURS , 60.0_IREAL_STD )
!C
      RETURN
      END
