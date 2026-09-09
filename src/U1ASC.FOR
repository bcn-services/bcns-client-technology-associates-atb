      SUBROUTINE U1ASC
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Modification to allow for general output of objects.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       LOGICAL_STD, TRUE, FALSE   ! parameters
!C
      LOGICAL  (KIND = LOGICAL_STD )  START
!C
      DATA     START / TRUE /
!C
      SAVE     START
!C
      IF ( START ) THEN
       CALL U1ASCH
       START = FALSE
      ELSE
       CALL U1ASCD
      END IF
!C
      RETURN
      END
