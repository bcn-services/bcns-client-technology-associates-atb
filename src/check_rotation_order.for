      SUBROUTINE  CHECK_ROTATION_ORDER ( IYPR, JPASS )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine checks the rotation order of the
!C     axes of rotation given for the initial rotation
!C     angles for the JPASS segment specified by the
!C     G.3 card.
!C
!C    It is called only by Subroutine INPUT_ORIENT.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, LUAOU, MAXSEG,       ! parameters
     &        I_0, I_1, I_3                     ! parameters 
!C
      INTEGER   ( KIND = INTEGER_STD )
     &            IYPR, ID1, ID2, ID3, JPASS
      DIMENSION   IYPR(4,MAXSEG)                            
!C
      INTENT  ( IN )  IYPR, JPASS
!C
!C
      ID1 = IYPR(1,JPASS)                                                    
      ID2 = ABS ( IYPR(2,JPASS) )                                            
      ID3 = ABS ( IYPR(3,JPASS) )                                            
!C
      IF ( ( ID1 .GT. I_3 ) .OR. ( ID2 .GT. I_3 ) 
     &                    .OR. ( ID3 .GT. I_3 ) )   THEN             
       WRITE ( LUAOU, 105 )  ID1, IYPR(2,JPASS), IYPR(3,JPASS),JPASS                 
  105  FORMAT ( /, 1X, 'ID(1,J) = ', I4, ', ID(2,J) = ', I4, 
     &          ', ID(3,J)', ' = ', I4, ' for segment J = ', I4,
     &          ' from Card G.3.A.', /,                                  
     &          '  only magnitudes of 1, 2 or 3 are allowed if the',     
     &          ' default order of 1, 2, 3 is not to be used.', // )     
       STOP ' STOP 230 in Subroutine CHECK_ROTATION_ORDER '                     
      END IF                                                             
!C
      IF ( ( ID1 .LT. I_0 ) .AND. 
     &     ( ( ID2 .NE. I_0 ) .OR. ( ID3 .NE. I_0 ) ) )  THEN      
       WRITE ( LUAOU, 110 )  ID1, IYPR(2,JPASS), IYPR(3,JPASS), JPASS                
  110  FORMAT ( /, 1X, 'ID(1,J) = ', I4, ', ID(2,J) = ', I4,
     &          ', ID(3,J) = ', I4, ' for segment J = ', I4,
     &          ' from Card G.3.a.', /,   
     &         ' The values of ID(2,J) and ID(3,J) are not',             
     &         ' needed when the projection data are used.', /,          
     &         ' Input value(s) ignored.', / )                           
      END IF                                                             
!C
      IF ( ID1 .GT. I_0 ) THEN                                      
       IF ( ( ID1 .EQ. ID2 ) .OR. ( ID2 .EQ. ID3 ) )  THEN              
        WRITE ( LUAOU, 115 )  ID1, ID2, ID3, JPASS                           
  115   FORMAT ( /, 1X, 'ID(1,J) = ', I4, ', IYD2,J) = ', I4,
     &           ', ID(3,J) = ', I4, ' for segment J = ', I4,
     &           ' from Card G.3.a.', /,                                 
     &           ' two consecutive axes of rotation can not be the',     
     &           ' same.', // )                                          
        STOP ' STOP 231 in Subroutine CHECK_ROTATION_ORDER '                
       END IF                                                            
       IF ( ( ID1 .EQ. ID3 ) .AND. ( ID1 .NE. -IYPR(3,JPASS) ) )  THEN      
        WRITE ( LUAOU, 120 )  ID1, ID2, ID3, JPASS                           
  120   FORMAT ( /, 1X, 'ID(1,J) = ', I4, ', ID(2,J) = ', I4,
     &           ', ID(3,J) = ', I4, ' for segment J = ', I4,
     &           ' from Card G.3.a.', /,                                 
     &        ' If the first and third magnitudes are the same,',        
     &        ' the third rotation must be negative.', // )              
        STOP ' STOP 232 in Subroutine CHECK_ROTATION_ORDER '                         
       END IF                                                            
      END IF                                                            
!C
      RETURN
      END