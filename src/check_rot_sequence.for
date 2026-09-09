      SUBROUTINE CHECK_ROT_SEQUENCE ( ISEQUENCE, L_VALID )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutines checks the validity of a rotation
!C     sequence.
!C
!C    ISEQUENCE is the inputted sequence of rotation.
!C    L_VALID is a logical variable designating if the sequence
!C     is valid (.TRUE.) or is incorrect (.FALSE.).
!C
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, LOGICAL_STD, FALSE, TRUE,   ! parameters
     &       I_0, I_1, I_3                            ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )   I, ISEQUENCE
      DIMENSION  ISEQUENCE(3)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  L_VALID
!C
      INTENT  (  IN )  ISEQUENCE
      INTENT  ( OUT )  L_VALID
!C
!C    Check if default, i.e. all values must be 0.
!C
      IF ( ISEQUENCE(1) .EQ. I_0 )  THEN
       IF ( ( ISEQUENCE(2) .EQ. I_0 ) .AND. 
     &      ( ISEQUENCE(3) .EQ. I_0 ) ) THEN
        L_VALID = TRUE
       ELSE
        L_VALID = FALSE
       END IF
       RETURN
      END IF
!C
!C    Check the range of the values if not default.
!C
      DO I=1,3
       IF ( ( ISEQUENCE(I) .LT. I_1 ) .OR. 
     &      ( ISEQUENCE(I) .GT. I_3 ) ) THEN
        L_VALID = FALSE
        RETURN
       END IF
      END DO
!C
!C    Check if the sequence is valid, now that the value of
!C     input is known to be within range.
!C
      DO I=1,2
       IF ( ISEQUENCE(I) .EQ. ISEQUENCE(I+1) ) THEN
        L_VALID = FALSE
        RETURN
       END IF
      END DO
      L_VALID = TRUE
!C
      RETURN
      END
     
