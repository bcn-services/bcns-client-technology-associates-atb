      SUBROUTINE  INPUT_INITIAL_CONDITIONS                                              
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine performs input and computations for the             
!C    positioning of the test subject's body segments.                   
!C                                                                        
!C                                                                        
!C    Subroutines called by:  INITIALIZE                                 
!C                                                                        
!C                                                                        
!C    STOPS:  250                                                         
!C                                                                        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       ANG, IEULER,                                   ! /CEULER/
     &       UNITL, UNITT,                                  ! /CNSNTS/
     &       NPG, NGRND, NJNT, NSEG, NHRNSS,                ! /CONTRL/
     &       NUMVEH,                                        ! /VPOSTN/
     &       SEG, JNT,                                      ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAIN, LUAOU, MAXSEG, ! parameters
     &       I_0, I_1, I_2, I_4, I_15,                      ! parameters 
     &       LIN_FLAG, LULIN, AIN_CONVERT                   ! parameters
!C
!C    NAME, LIN_DISP, LIN_VEL                          ! SEG%
!C    CNTR_SYM, COS_NUTA, PROX_SEG, SIN_NUTA, JTYPE    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, I1, I3, I3S, IREF, IVEH, IYPR,
     &           J, J1, JDUM
      DIMENSION  IREF(4,MAXSEG), IVEH(MAXSEG), IYPR(4,MAXSEG),
     &           I3S(MAXSEG)                                              
!C
      REAL  ( KIND = IREAL_HIGH )  YPR, WMGDEG, TSEGLP, DA1 
      DIMENSION         YPR(3,MAXSEG), WMGDEG(3,MAXSEG),
     &                  TSEGLP(3,MAXSEG)           
!C                                                                        
!C    Input Card G.1.a (the plot coordinates of the origin of the         
!C    primary vehicle reference system) and test for proper value         
!C    for I3.  The plot data are no longer used. 
!C                                                                        
      CALL CHECK_COMMENT
      J1 = I_0
      IF ( LIN_FLAG )  THEN 
       READ ( LULIN, * ) I1, I3                        
      ELSE
       J1 = I_0
       READ ( LUAIN, 100 ) I1, J1, I3                        
  100  FORMAT ( 30X, 2I4, 8X, I4 )                                              
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 103 ) I1, I3, 'Card G.1.a'                        
  103   FORMAT ( 1X, 2( I4, 1X ), 1X, A )                                              
       END IF
      END IF
!C
      IF ( ( I3 .LT. I_0 ) .OR. ( I3 .GT. I_2 ) )  THEN              
       WRITE ( LUAOU, 105 ) I3                                            
  105  FORMAT ( /, 1X, ' I3 = ', I4, 
     &          ' on Card G.1.a.  The value of I3',                     
     &          ' must be 0, 1 OR 2.', // )                               
       STOP ' STOP 250 in Subroutine INPUT_INITIAL_CONDITIONS'                       
      END IF                                                              
!C                                                                        
!C    If J1 # 0, input Card G.1.b (was plot scaling input).                   
!C
!C    Card G.1.b is eliminated beginning with Version V.3.  No .LIN
!C     output is provided. .AIN decks that contain it can be 
!C     read, but any data contained on the card will be ignored.
!C                                                                        
      IF  ( J1 .NE. I_0 )  THEN
       READ ( LUAIN, 106 )  JDUM                      
  106  FORMAT ( I1 )                                              
      END IF
!C
      WRITE ( LUAOU, 110 )  I1, J1, I3, NPG              
      NPG = NPG + I_1                                             
  110 FORMAT ( '1 Subroutine INPUT_INITIAL Input', 
     &         '  I1 = ', I4, ',  J1 = ', I4, ',  I3 = ', I4, 
     &          56X, 'Page', I5, /, 120X,'Card G.1' )                                       
!C
      IF ( J1 .NE. I_0 )  THEN
       WRITE ( LUAOU, 111 )
  111  FORMAT ( 1X, 'The G.1b card is no longer used.  Any data ',
     &              ' contained on it will be ignored.' )
      END IF   
!C                                                                       
!C    Update the segment for the ground segment in VEH%IVREF1,2,3 now    
!C    that NGRND has possibly been modified to include air bags.     
!C                                                                        
      CALL VPATH2 ( NUMVEH, NGRND )                             
!C                                                                         
!C    Compute the absolute initial conditions for all segments             
!C    defined as vehicles.                                                 
!C                                                                         
      CALL VINITL ( NUMVEH )             
!C                                                                        
!C    Initialize the I3S array for later use in Subroutines 
!C     INPUT_LINEAR and INPUT_ORIENT.      
!C                                                                        
      DO  I=1,NGRND                                                       
       I3S(I) = I3                                                   
      END DO
!C
!C    Check for comments.
!C
      CALL  CHECK_COMMENT
!C                                                                        
!C    Determine the initial linear position (in) and velocity (in/sec)    
!C    of each reference body segment.                                     
!C                                                                        
      CALL INPUT_LINEAR ( I3S, IREF, IVEH, TSEGLP )                        
!C
!C    Check for comments.
!C
      CALL  CHECK_COMMENT
!C                                                                        
!C    Determine the initial angular orientation (degrees) and angular     
!C    velocity (deg/sec) for all body segments.                           
!C                                                                        
      CALL INPUT_ORIENT ( I3S, IREF, IVEH, YPR, IYPR, WMGDEG )           
!C                                                                        
!C    Compute initial positions of the vehicles.                          
!C                                                                        
      CALL VEHPOS                                                         
!C                                                                      
!C    Compute initial postions of body segments that are linked to the    
!C    reference body segments.                                           
!C                                                                        
      IF ( NJNT .NE. I_0 ) THEN                                        
       CALL CHAIN ( I_0 )                                              
       CALL EJOINT ( I_1, I_0 )                                          
       DO  J=1,NJNT                                                       
        IF ( ( ABS ( JNT(J)%JTYPE ) .EQ. I_4 ) .AND.
     &         ( IEULER(J) .EQ. I_2 ) )   THEN                         
         DA1 = ANG(2,J) + JNT(J)%CNTR_SYM(2)  
         JNT(J)%COS_NUTA = COS ( DA1 )
         JNT(J)%SIN_NUTA = SIN ( DA1 )
        END IF                                                            
       END DO                                                             
      END IF                                                              
!C                                                                        
!C    Output the initial body segment positions.                        
!C                                                                        
      WRITE ( LUAOU, 115 )  UNITL, UNITL, UNITT                         
  115 FORMAT ( '0 Initial Positions',  //,                              
     &         '  Segment', 11X, 'Linear Position (', A4, ')',            
     &         14X, 'Linear Velocity (', A4, '/', A4, ')', 41X,
     &         'Cards G.2', /, 22X, '(IREF4 Reference)', 26X,
     &         '(Inertial)', /, '  No. Seg', 2( 9X, 'X', 11X, 'Y',
     &         11X, 'Z', 5X ), 3X, 'IREF2', 2X, 'IREF4' )               
      DO  J=1,NSEG                                                      
       IF ( ( J .EQ. I_1 ) .OR. 
     &      ( JNT(J-1)%PROX_SEG .EQ. I_0 ) )  THEN         
        WRITE ( LUAOU, 120 )  J, SEG(J)%NAME, ( TSEGLP(I,J), I=1,3 ),
     &                   ( SEG(J)%LIN_VEL(I), I=1,3 ), 
     &                      IREF(2,J), IREF(4,J)   
  120   FORMAT ( I4, 1X, A4, 3X, 3F12.5, 3X, 3F12.5, 3X, I4, 3X, I4 )   
       ELSE                                                             
        WRITE ( LUAOU, 120 )  J, SEG(J)%NAME, 
     &                   ( SEG(J)%LIN_DISP(I), I=1,3 ), 
     &                   ( SEG(J)%LIN_VEL(I),  I=1,3 ), 
     &                       IREF(2,J), IREF(4,J)  
       END IF                                                           
      END DO                                                            
      WRITE ( LUAOU, 125 ) UNITT                                          
  125 FORMAT ( '0 Initial Angular Rotation and Velocity', 71X, 
     &         'Cards G.3', //, 
     &         '  Segment',11X,'Angular Rotation (deg)',                  
     &         14X, 'Angular Velocity (deg/', A4, ')', /,                 
     &         22X, '(IYPR4 Reference)', 27X, '(Local)', /,             
     &         '  No. Seg', 8X, 'Yaw', 8X, 'Pitch', 7X, 'Roll',           
     &         13X, 'X', 11X, 'Y', 11X, 'Z', 15X, 'IYPR' )                
      WRITE ( LUAOU, 130 )  ( J, SEG(J)%NAME, ( YPR(I,J), I=1,3 ),
     &                      ( WMGDEG(I,J), I=1,3 ),   
     &                      ( IYPR(I,J), I=1,4 ), J=1,NSEG )              
  130 FORMAT ( I4, 1X, A4, 3X, 3F12.5, 3X, 3F12.5, 3X, 4I4 )              
!C                                                                        
!C    Print note explaining how the initial conditions were determined.   
!C                                                                       
      IF ( I3 .EQ. I_0 ) THEN                                         
       WRITE ( LUAOU, 135 )                                               
  135  FORMAT('0 Linear and angular velocities have been set equal to ',  
     &        'the initial velocities of the primary vehicle ',/,         
     &        ' for all nonvehicle body segments with IREF2 = 0.',        
     &        '  For nonvehicle segments with IREF2 # 0, the linear ',    
     &        /, ' and angular velocities were determined by the ',       
     &        'values of IREF2.', / )                                     
      ELSE IF ( I3 .EQ. I_1 ) THEN                                      
       WRITE ( LUAOU, 140 )                                               
  140  FORMAT ( '0 Linear and angular velocities for all nonvehicle',     
     &          ' segments were determined by the values supplied by',    
     &          ' the G cards.', / )                                      
      ELSE IF ( I3 .EQ. 2 ) THEN                                          
       WRITE ( LUAOU, 145 )                                               
  145  FORMAT ( '0  Linear and angular velocities were determined',       
     &          ' by the values supplied by the G cards for all', /,      
     &          '  nonvehicle segments with IREF2 = 0.  For nonvehicle',  
     &          ' segments with IREF2 # 0,',                            
     &          ' The linear and angular velocities' /, '  were',         
     &          ' determined by the value of IREF2.', / )                 
      END IF                                                              
!C                                                                        
!C    If there are harnesses, compute the initial distances between       
!C    the belt points for the harness belts.                              
!C    Then, if I1 = 15, use Subroutine EQUILB to compute the initial      
!C    configuration of the body.                                          
!C                                                                        
      IF  ( NHRNSS .NE. I_0 )  CALL HBPLAY                            
      IF  ( I1 .EQ. I_15 )     THEN
       CALL  CHECK_COMMENT
       CALL EQUILB ( YPR, IYPR )       
      END IF
!C                                                                        
!C    Output the constant data for the VIEW program.                      
!C                                                                        
      CALL UNIT1                                                  
!C                                                                        
!C    Transform all affected data from local coordinates to principal     
!C    coordinates for those segments that have rotated principal axes.    
!C                                                                        
      CALL ROTATE                                                         
!C
      CALL ELTIME ( I_2, I_2 )                                                
!C
      RETURN                                                              
      END                                                                 
