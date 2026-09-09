      SUBROUTINE  CHECK_COMMENT
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the first character of a line from 
!C     the .lin file to see if the line is a comment.  If it is,
!C     it goes on to the next line.  Once a noncomment line is 
!C     reached, the file record is backspaced and the subroutine
!C     returns to the calling subroutine.  The same is done
!C     for the .ain file.
!C
      USE  MODULE_STANDARD, ONLY:
     &       ICHAR_STD, LIN_FLAG,              ! parameters
     &       LUAOU, LUTERM_OUT, LULIN, LUAIN   ! parameters
!C
      CHARACTER   ( LEN = 1, KIND = ICHAR_STD )  CHECK_INPUT, 
     &                                           COMMENT_FLAG
      PARAMETER  ( COMMENT_FLAG = ICHAR_STD_'#' )
!C
      DO
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, *, END=20 )  CHECK_INPUT
        IF ( CHECK_INPUT .NE. COMMENT_FLAG )  THEN
         BACKSPACE ( UNIT = LULIN, ERR = 30 )
         RETURN
        END IF
       ELSE
        READ  ( LUAIN, *, END=20 )  CHECK_INPUT
        IF ( CHECK_INPUT .NE. COMMENT_FLAG )  THEN
         BACKSPACE ( UNIT = LUAIN, ERR = 30 )
         RETURN
        END IF
       END IF
      END DO
!C
!C    Handle reaching the end of the file.
!C
   20 CONTINUE
      RETURN
!C
!C    Error handling.
!C
   30 WRITE ( LUAOU, 130 ) 
      WRITE ( LUTERM_OUT, 130 )
  130 FORMAT ( 1X, 'Error backspacing in Subroutine CHECK_COMMENT' )
      STOP ' STOP 4005 in Subroutine CHECK_COMMENT '
!C
      END
