      SUBROUTINE INPUT_LINEAR ( I3S, IREF, IVEH, TSEGLP )                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                        
!C    This subroutine reads in and determines the initial linear          
!C    positions and linear velocities of the body segments.               
!C                                                                       
!C                                                                        
!C    Subroutines called by:  INPUT_INITIAL_CONDITIONS                   
!C                                                                        
!C    Subroutines called:  none                                          
!C                                                                        
!C                                                                        
!C    STOPS: 220, 221, 222, 223, 224, 225, 226, 227, 228                       
!C                                                                       
!C                                                                       
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                          ! /CNSNTS/
     &       NGRND, NSEG, NVEH,            ! /CONTRL/
     &       NUMVEH,                       ! /VPOSTN/
     &       SEG, JNT, VEH,                ! structures
     &       LUAIN, LUAOU, MAXSEG, MAXREF, ! parameters
     &       INTEGER_STD, IREAL_HIGH,      ! parameters
     &       D_0, I_0, I_1, I_2,           ! parameters 
     &       AIN_CONVERT, LIN_FLAG, LULIN  ! parameters
!C
!C    ANG_VEL, DIR_COS, LIN_DISP, LIN_VEL    SEG%
!C    IVSEG                                  VEH%
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I3S, IREF, IVEH, I, I2, I3, I5, I6, I8, IR8, J, L,
     &          NUM_REF_SEG
      DIMENSION I3S(MAXSEG), IREF(4,MAXSEG), IVEH(MAXSEG)               
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  TSEGLP, TSEGLV, R, T1, WXR, T2_LCL,
     &                  ADIFP, ADIFV, DIFV, DOTP, DOTV, 
     &                  DIFP, SUMDOT 
      DIMENSION         TSEGLP(3,MAXSEG), TSEGLV(3),                      
     &                  R(3), T1(3), WXR(3), T2_LCL(3)                    
!C
      INTENT (   OUT )  IREF, IVEH, TSEGLP
      INTENT ( INOUT )  I3S
!C                                                                        
!C    Initialize reference arrays to be used to check for the             
!C    consistency of the input.                                           
!C                                                                        
      IREF = I_0
      IVEH = I_0
!C
      IREF(1,NGRND) = NGRND                                               
      IREF(2,NGRND) = NGRND                                               
      IREF(3,NGRND) = NGRND                                             
      IREF(4,NGRND) = NGRND                                             
      DO  I=1,NUMVEH                                                     
       I2 = VEH(I)%IVSEG                                               
       IVEH(I2) = I_1                                                   
      END DO                                                              
!C                                                                        
!C    Read in segment initial position and initial velocity               
!C    for the reference segments.  Data are with respect to the          
!C    inertial coordinate system.                                         
!C                                                                        
      NUM_REF_SEG = I_0
      LOOP_20 : DO  I=1,NSEG                                                      
       IF ( ( I .EQ. I_1 ) .OR. 
     &      ( JNT(I-1)%PROX_SEG .EQ. I_0 ) )  THEN 
        NUM_REF_SEG = NUM_REF_SEG + I_1
        IF ( NUM_REF_SEG .GT. MAXREF )  THEN
         WRITE ( LUAOU, 100 )  MAXREF
  100    FORMAT ( 1X, ' Maximum number of reference segments, ', I3,
     &            ' has been exceeded. ' )
         STOP ' STOP 228 in Subroutine INPUT_LINEAR '
        END IF
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * ) ( TSEGLP(J,I), J=1,3 ), 
     &                     ( TSEGLV(J), J=1,3 ), I5, I6                  
        ELSE
         READ ( LUAIN, 103 ) ( TSEGLP(J,I), J=1,3 ), 
     &                       ( TSEGLV(J), J=1,3 ), I5, I6                  
  103    FORMAT ( 6F10.0, 2I3 )                                            
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 105 ) ( TSEGLP(J,I), J=1,3 ), 
     &                         ( TSEGLV(J), J=1,3 ), I5, I6,
     &                         'Card G.2'                  
  105     FORMAT ( 1X, 6( F17.9, 1X ), 2( I3, 1X ), 1X, A )                                            
         END IF
        END IF
       ELSE                                                               
        CYCLE LOOP_20                                                       
       END IF                                                             
!C                                                                        
!C     Save the reference segments for each base segment.  Also,          
!C     determine the value of I3S(I) and hence I3.                        
!C     IREF(1,I) and IREF(3,I) contain the actual reference segment     
!C     numbers, whereas IREF(2,I) and IREF(4,I) contain the input value  
!C     of the reference segments.                                       
!C                                                                        
       IF ( I5 .EQ. I_0 )  THEN                                       
        IREF(1,I) = NVEH                                                 
       ELSE                                                              
        IREF(1,I) = I5                                                    
       END IF                                                             
       IREF(2,I) = I5                                                    
       IF ( I6 .EQ. I_0 ) THEN                                    
        IREF(3,I) = NGRND                                               
       ELSE                                                             
        IREF(3,I) = I6                                                  
       END IF                                                           
       IREF(4,I) = I6                                                   
       I3 = I3S(I)                                                        
       IF ( I3 .EQ. I_2 )  THEN                                        
        IF ( I5 .NE. I_0 )  THEN                                     
         I3 = I_0                                                    
        ELSE                                                              
         I3 = I_1                                                      
        END IF                                                           
       END IF                                                             
       I3S(I) = I3                                                        
!C                                                                        
!C     Test for properly specified vehicle reference segment (I5)         
!C     for the Ith reference segment's initial linear position and        
!C     linear velocity.                                                   
!C                                                                        
       IF ( I5 .LT. I_0 ) THEN                                      
        WRITE ( LUAOU, 107 ) I5, I                                        
  107   FORMAT ( /, 1X, 'IREF2 = ', I4,
     &           ' from Card G.2 for segment number ', I4, '.', /,        
     &           ' the reference segment number must be a',               
     &           ' positive number.', // )                                
        STOP ' STOP 220 in Subroutine INPUT_LINEAR '                  
       END IF                                                             
       IF ( ( I5 .GT. NVEH ) .AND. ( I5 .NE. NGRND ) ) THEN               
        WRITE ( LUAOU, 110 ) I5, I                                        
  110   FORMAT ( /, 2X, 'IREF2 =', I4,
     &           ' from Card G.2 for segment number ', I4, '.', /,        
     &           '  This segment is either an airbag ',                   
     &           'segment or does not exist.', // )                       
        STOP ' STOP 221 in Subroutine INPUT_LINEAR '                     
       END IF                                                            
       IF ( ( I5 .NE. I_0 ) .AND. ( I3 .NE. I_0 ) ) THEN            
        WRITE ( LUAOU, 115 )  I5, I                                       
  115   FORMAT ( /, 1X, 'I3 = 1 on Card G.1.a and IREF2 =', I4,
     &           ' on Card G.2 for segment number ', I4, '.  ',           
     &           'IREF2 must be 0 if I3 is equal to 1.', // )            
        STOP ' STOP 222 in Subroutine INPUT_LINEAR '                      
       END IF                                                             
       IF ( ( I5 .NE. I_0 ) .OR. ( I6 .NE. I_0 ) )  THEN        
        IF ( IVEH(I) .EQ. I_1 )  THEN                                  
         WRITE ( LUAOU, 125 ) I                                           
  125    FORMAT ( /, 1X, 'A reference segment has been specified for ',   
     &            'body segment number ', I4,
     &            ' which has been designated as a vehicle.', /, 
     &            ' This is not allowed.', // )                         
         STOP ' STOP 224 in Subroutine INPUT_LINEAR '                  
        END IF                                                            
       END IF                                                           
       IF ( ( I5 .NE. I_0 ) .AND. ( IVEH(I5) .EQ. I_0 ) )  THEN     
        WRITE ( LUAOU, 130 ) I5, I, I5                                    
  130   FORMAT ( /, 1X, 'IREF2 = ', I4,
     &           ' on Card G.2 for segment number ', I4,                  
     &           '.  Segment ', I4, ' does not have prescribed motion.'   
     &           // )                                                     
        STOP ' STOP 225 in Subroutine INPUT_LINEAR '                  
       END IF                                                             
       IF ( ( I6 .NE. I_0 ) .AND. ( IVEH(I6) .EQ. I_0 ) )  THEN   
        WRITE ( LUAOU, 132 ) I6, I, I6                                  
  132   FORMAT ( /, 1X, 'IREF4 = ', I4,
     &           ' on Card G.2 for segment number ', I4,                
     &           '.  Segment ', I4, ' does not have prescribed motion.' 
     &           // )                                                   
        STOP ' STOP 223 in Subroutine INPUT_LINEAR '                    
       END IF                                                           
!C                                                                        
!C     If reference segment is a vehicle, make sure that G card data      
!C     are either blank or are exactly the same as the C card results.    
!C                                                                        
       DOTP = D_0                                                      
       DO  J=1,3                                                          
        DOTP = DOTP + TSEGLP(J,I) * TSEGLP(J,I)                          
       END DO
       DOTV = DOT_PRODUCT ( TSEGLV, TSEGLV )
       SUMDOT = DOTP + DOTV                                               
       IF ( IVEH(I) .EQ. I_1 )  THEN                                   
        IF ( SUMDOT .NE. D_0 ) THEN                                     
         DO  J=1,3                                                      
          DIFP = SEG(I)%LIN_DISP(J) - TSEGLP(J,I)                      
          DIFV = SEG(I)%LIN_VEL(J)  - TSEGLV(J)                   
          ADIFP = ABS ( DIFP )                                            
          ADIFV = ABS ( DIFV )                                            
          IF ( ( ADIFP .GT. EPS(15) ) .OR. ( ADIFV .GT. EPS(15) ) ) THEN 
           WRITE ( LUAOU, 135 )  I                                        
  135      FORMAT ( /, 1X, 'Segment number ', I4,
     &              ' is a body segment that',                            
     &              ' has been designated as a vehicle.', /, 1X, 
     &              'Nonblank G card',                                    
     &              ' data have been supplied that are not equal to',     
     &              ' the initial conditions as determined from the',     
     &              ' C card data.', /, 1X, 'This is not allowed.', 
     &              // )                                                  
           STOP ' STOP 226 in Subroutine INPUT_LINEAR '                 
          ELSE                                                           
           CYCLE  LOOP_20                                                     
          END IF                                                          
         END DO                                                       
        ELSE                                                             
         WRITE ( LUAOU, 140 )  I                                          
  140    FORMAT ( /, 1X, 'Segment number ', I4,
     &            ' is a body segment that has been designated',          
     &            ' as a vehicle.', /, 1X, 'Initial ',                    
     &            'conditions supplied by the C card data.' )             
         CYCLE                                                       
        END IF                                                            
       END IF                                                             
!C                                                                      
!C     Set the linear position of the base segment equal to the linear  
!C     displacement of the reference segment I6 plus the supplied values
!C     of TSEGLP.                                                       
!C                                                                      
       CALL DOT31 ( SEG(IREF(3,I))%DIR_COS, TSEGLP(1,I), T2_LCL )      
        SEG(I)%LIN_DISP = SEG(IREF(3,I))%LIN_DISP + T2_LCL            
!C                                                                        
!C     Select the source of the reference segment's initial linear        
!C     velocity based on the values of I3 and I5.                         
!C                                                                        
!C     Default value, I3 = 0 and I5 = 0.  Primary vehicle initial         
!C     linear velocity used.                                              
!C                                                                        
       IF ( ( I3 .EQ. I_0 ) .AND. ( I5 .EQ. I_0 ) )  THEN           
        R = SEG(I)%LIN_DISP - SEG(NVEH)%LIN_DISP                
        CALL DOT31 ( SEG(NVEH)%DIR_COS, SEG(NVEH)%ANG_VEL, T1 )                
        CALL CROSS ( T1, R, WXR )                                         
        SEG(I)%LIN_VEL = SEG(NVEH)%LIN_VEL + WXR              
        IF ( DOTV .NE. D_0 )  THEN                                       
         WRITE ( LUAOU, 145 )  ( TSEGLV(L), L=1,3 ), I                   
  145    FORMAT ( /, 1X, 'TSEGLV(1) = ', F10.4, 1X, 'TSEGLV(2) = ',
     &            F10.4, 1X, 'TSEGLV(3) = ', F10.4,
     &            ' for segment number', I4, '.', /,                      
     &            '  values ignored since primary vehicle initial',       
     &            ' linear velocities used instead.', / )                 
        END IF                                                            
!C                                                                        
!C     Supplied values of initial linear velocity used from Card G.2.     
!C                                                                        
       ELSE IF ( I3 .EQ. I_1 ) THEN                                        
        SEG(I)%LIN_VEL = TSEGLV                                     
!C                                                                        
!C     Initial velocity of reference segment number I5 used.             
!C                                                                        
       ELSE IF ( ( I3 .EQ. I_0 ) .AND. ( I5 .NE. I ) )  THEN           
        R = SEG(I)%LIN_DISP - SEG(I5)%LIN_DISP                  
        CALL DOT31 ( SEG(I5)%DIR_COS, SEG(I5)%ANG_VEL, T1 )                   
        CALL CROSS ( T1, R, WXR )                                         
        SEG(I)%LIN_VEL  = SEG(I5)%LIN_VEL + WXR                
        IF ( DOTV .NE. D_0 )  THEN                                   
         WRITE ( LUAOU, 150 ) TSEGLV(1), TSEGLV(2), TSEGLV(3), I, I5      
  150    FORMAT ( /, 1X, 'TSEGLV(1) = ', F12.4, 1X, 'TSEGLV(2) = ',
     &            F12.4, 1X, 'TSEGLV(3) = ', F12.4, 
     &            ' for segment number', I4, '.', /,                      
     &            '  values ignored since initial linear velocities',     
     &            ' of reference segment ', I4, ' used instead.', / )     
        END IF                                                            
       END IF                                                             
      END DO  LOOP_20                                                            
!C                                                                        
!C    Check to see if any nonreference body segments were specified       
!C    as vehicles.                                                        
!C                                                                        
      DO  I=1,NUMVEH                                                      
       I8 = VEH(I)%IVSEG                                                
       IR8 = IREF(1,I8)                                                   
       IF ( ( I8 .LE. NSEG ) .AND. ( IR8 .EQ. I_0 ) )  THEN            
        WRITE ( LUAOU, 155 )  I8                                          
  155   FORMAT ( /, 1X, 'Body segment number ', I4,
     &           ' was specified as a',                                   
     &           ' vehicle but it is not a reference segment.', /,        
     &           '  This is not allowed.', // )                           
        STOP '  STOP 227 in Subroutine INPUT_LINEAR '               
       END IF                                                             
      END DO
!C                                                                        
      RETURN                                                              
      END                                                                 
