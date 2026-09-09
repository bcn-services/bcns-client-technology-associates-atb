      SUBROUTINE INPUT_ORIENT (I3S, IREF, IVEH, YPR, IYPR, WMGDEG )        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in and determines the initial angular        
!C    orientations and angular velocities of the body segments.          
!C                                                                        
!C                                                                        
!C    Subroutines called by:  INPUT_INITIAL_CONDITIONS.                         
!C                                                                        
!C    Subroutines called:  INPROJ, DRCIJK, DOT31, MAT31, YPRDEG         
!C                                                                        
!C                                                                       
!C    Global variables altered: SEG%DIR_COS, SEG%                         
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS, RADIAN,                         ! /CNSNTS/
     &        NGRND, NSEG, NVEH,                   ! /CONTRL/
     &        HT,                                  ! /DESCRP/
     &        SEG, JNT,                            ! structures
     &        INTEGER_STD, IREAL_HIGH,             ! parameters
     &        LUAIN, LUAOU, MAXSEG,                ! parameters
     &        I_0, I_1, I_3, I_4, D_0, D_3,        ! parameters 
     &        AIN_CONVERT, LIN_FLAG, LULIN         ! parameters
!C
!C    DIR_COS                                          ! SEG%
!C    CNTR_SYM, COMP_MAX, PROX_SEG, TENS_MAX, JTYPE    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I3S, IREF, IVEH, IBOD, IYPR, I, I1, I3, IAJNT,
     &           IC, ID1, ID2, ID3, ID4, J, JPASS, L, NID4
      DIMENSION  I3S(MAXSEG), IREF(4,MAXSEG), IVEH(MAXSEG), 
     &           IBOD(MAXSEG), IYPR(4,MAXSEG)                            
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  WMGDEG, YPR, DSAVE, DIDEN,
     &                  TYPR, ADIFTR, DIFTR, FIRST, TRACE, YPRT
      DIMENSION         WMGDEG(3,MAXSEG), YPR(3,MAXSEG), DSAVE(3,3),
     &                  DIDEN(3,3), TYPR(3,MAXSEG)           
!C
      INTENT (    IN )  IREF, IVEH
      INTENT (   OUT )  YPR, IYPR, WMGDEG
      INTENT ( INOUT )  I3S
!C                                                                        
!C    Determine which segments belong to each of the reference segments.
!C    Also, determine the value of I3 for each of the nonreference       
!C    segments so that it corresponds with the value of I3 for the        
!C    reference segment to which segment I is attached.                   
!C                                                                        
      IC = I_0                                                         
      DO  I=1,NGRND                                                       
       I1 = IREF(1,I)                                                     
       IF ( ( I1 .NE. I_0 ) .OR. ( I .GT. NSEG ) )  THEN              
        IC = I                                                            
        IBOD(I) = IC                                                      
       ELSE                                                               
        IBOD(I) = IC                                                      
!C                                                                        
!C      Set I3 for all the segments of a body equal to the value of I3    
!C      for the reference (base) segment of the body.                     
!C                                                                        
        I3S(I) = I3S(IC)                                                  
       END IF                                                             
      END DO                                                              
!C                                                                        
!C    For each body segment supply yaw, pitch and roll (degrees)          
!C    and (if I3=1) the angular velocity in local reference (deg/sec).    
!C    If I3=0 the angular velocity (blank on input cards) will be        
!C    set equal to the initial angular velocity of the primary vehicle.   
!C                                                                        
      FIRST = D_0                                                      
      DO 22 J=1,NSEG                                                      
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * ) ( YPR(I,J), I=1,3 ), ( WMGDEG(I,J), I=1,3 ),   
     &                    ( IYPR(I,J), I=1,4 )                           
       ELSE
        READ ( LUAIN, 100 ) ( YPR(I,J), I=1,3 ), ( WMGDEG(I,J), I=1,3 ),   
     &                      ( IYPR(I,J), I=1,4 )                           
  100   FORMAT ( 6F10.0, 4I3 )                                             
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 102 ) ( YPR(I,J), I=1,3 ), 
     &                        ( WMGDEG(I,J), I=1,3 ),   
     &                        ( IYPR(I,J), I=1,4 ), 'Card G.3.a'                           
  102    FORMAT ( 1X, 6( F17.9, 1X ), 4( I3, 1X ), 1X, A )                                             
        END IF
       END IF
       I3 = I3S(J)                                                        
       YPRT = YPR(1,J)**2 + YPR(2,J)**2 + YPR(3,J)**2                     
!C                                                                        
!C     Check for proper values of IYPR(I,J).                              
!C                                                                        
       JPASS = J
       CALL CHECK_ROTATION_ORDER ( IYPR, JPASS )
!C                                                                      
!C     Ensure a proper rotation reference for the orientations of         
!C     the segments.                                                      
!C                                                                        
       ID1 = IYPR(1,J)                                                    
       ID2 = ABS ( IYPR(2,J) )                                            
       ID3 = ABS ( IYPR(3,J) )                                            
       ID4 = IYPR(4,J)                                                    
       IF ( ID4 .EQ. I_0 )  THEN                                       
        IYPR(4,J) = NGRND                                                 
        ID4 = NGRND                                                       
       END IF                                                             
       IF ( ( ID4 .GE. J ) .AND. ( ID4 .LE. NSEG ) 
     &                     .AND. ( IVEH(ID4) .EQ. I_0 ) )   THEN     
        WRITE ( LUAOU, 125 )  J, ID4                                     
  125   FORMAT ( /, 1X, 'ID(4,', I4, ') = ', I4,
     &           ' from Card G.3.a.  This is',                            
     &        ' not allowed because a body segment without prescribed', 
     &           ' motion', /, ' with a segment',                       
     &        ' number greater than or equal to the current segment',    
     &        ' number is',/,' specified as the reference segment.',
     &        // )                                                        
        STOP  ' STOP 24 in Subroutine INPUT_ORIENT '               
       END IF                                                            
       IF ( J .NE. I_1 )  THEN                                         
        IAJNT = ABS ( JNT(J-1)%PROX_SEG )                                 
        NID4 = -ID4                                                       
        IF ( ( ID4 .LT. I_0 ) .AND. ( NID4 .NE. IAJNT ) )   THEN       
         WRITE ( LUAOU, 130 )  J, J, NID4, IAJNT                          
  130    FORMAT ( /, 1X, 'Rotation of angles ypr for segment number ',
     &            I4, ' were to be about the joint axes.', /,
     &            '  However,' ,                                        
     &            ' the proximal segment was specified as ID(4,',         
     &            I4, ') = ', I4, '.', /, '  It should have been ',
     &            I4, '.', // )                                           
         STOP  ' STOP 25 in Subroutine INPUT_ORIENT '               
        END IF                                                            
       END IF                                                             
!C                                                                        
!C     If ID1 = 0, compute the default value of IYPR.                     
!C                                                                        
       DO  I=1,3                                                          
        IF ( ID1 .EQ. I_0 )  IYPR(I,J) = I                          
       END DO
!C                                                                        
!C     If ID1 is negative, compute the initial angular                    
!C     orientation of the body segment from projections.  The             
!C     output from INPROJ (IYPR and YPR) will only be used if             
!C     the body segment is not a vehicle segment.                         
!C     Subroutine INPROJ is always called, whether its output is          
!C     used or not, to ensure that previous input decks are compatible    
!C     with the new version of INITAL.                                  
!C                                                                        
       IF ( ID1 .LT. I_0 )  THEN                                     
        IF ( YPRT .NE. D_0 )  THEN                                  
         WRITE ( LUAOU, 135 )  ( YPR(1,L), L=1,3 ), J                    
  135    FORMAT ( /, 1X, 'YPR(1,L) = ', F10.4, 1X, 'YPR(2,L) = ',
     &            F10.4, 1X, 'YPR(3,L) = ', F10.4,
     &            ' from Card G.3.a for segment number ', I4, '.',
     &            /, '  These values are overwritten',                  
     &            ' by the values computed by the projection data',      
     &            ' from card G.3.b.', / )                                
        END IF                                                            
        CALL CHECK_COMMENT
        CALL INPUT_PROJANG ( JPASS, IYPR, YPR, FIRST )                     
       END IF                                                             
!C                                                                        
!C     Save value of direction cosine if the segment is a vehicle.       
!C                                                                        
       IF ( IVEH(J) .EQ. I_1 )  THEN                                
        DSAVE = SEG(J)%DIR_COS
       END IF                                                             
!C                                                                        
!C     Compute the segment initial angular orientation.                   
!C     If joint J-1 is Euler joint and YPR are joint angles, precession,
!C     nutation, and spin, add CNTR_SYM to YPR.                        
!C                                                                        
       IF ( J .NE. I_1 )  THEN                                       
        IF ( ( ABS ( JNT(J-1)%JTYPE ) .EQ. I_4 ) 
     &        .AND. ( ID1 .EQ. I_3 ) 
     &        .AND. ( ID2 .EQ. I_1 ) .AND. ( ID3 .EQ. I_3 ) 
     &        .AND. ( ID4 .LT. I_0 ) )  THEN                       
         TYPR(1,J) = YPR(1,J) + JNT(J-1)%CNTR_SYM(1) / RADIAN
!C ????????????????
         TYPR(2,J) = YPR(2,J) + JNT(J-1)%CNTR_SYM(3) / RADIAN
         TYPR(3,J) = YPR(3,J) + JNT(J-1)%CNTR_SYM(2) / RADIAN
         CALL DRCIJK ( TYPR, IYPR, HT, JPASS )               
        ELSE                                                            
         CALL DRCIJK ( YPR, IYPR, HT, JPASS )                  
        END IF                                                          
       ELSE                                                             
        CALL DRCIJK ( YPR, IYPR, HT, JPASS )              
       END IF                                                           
!C                                                                      
!C     Ensure that D from the G.3 cards (DSAVE) is equal to the initial   
!C     orientation from the C card data unless a blank G.3 card was       
!C     supplied if the segment is a vehicle. Note that the values of      
!C     I3 and IREF are ignored for the vehicle segments.                  
!C                                                                       
       IF ( IVEH(J) .EQ. I_1 )  THEN                                  
        IF ( YPRT .NE. I_0 )  THEN                                    
         CALL DOTT33 ( DSAVE, SEG(J)%DIR_COS, DIDEN )                    
         TRACE = DIDEN(1,1) + DIDEN(2,2) + DIDEN(3,3)                     
         DIFTR = TRACE - D_3                                            
         ADIFTR = ABS ( DIFTR )                                           
         IF ( ADIFTR .GT. EPS(15) )  THEN                                 
          WRITE ( LUAOU, 140 )  J                                         
  140     FORMAT ( /, 1X, 'An orientation for body segment number ',      
     &             I4, ', which is a vehicle, was supplied that',
     &             /, 1X,                                                 
     &            'differs from the initial orientation computed',        
     &            ' from the C card data.  This is not allowed.', // )    
          STOP  ' STOP 233 in Subroutine INPUT_ORIENT '              
         END IF                                                           
        END IF                                                            
!C                                                                        
!C      Use the original direction cosine as computed from the C cards
!C       and compute YPR for this direction cosine.                      
!C                                                                        
        SEG(J)%DIR_COS = DSAVE
        CALL YPRDEG ( SEG(J)%DIR_COS, YPR(1,J) )                        
        WRITE ( LUAOU, 145 )  J                                           
  145   FORMAT ( /, 1X, 'Body segment number ', I4,
     &           ' is a vehicle whose',   
     &           ' initial orientation is supplied by the C card',         
     &           ' data.', / )                                            
       END IF                                                            
!C
!C     Compute the initial angular velocity for the segment.
!C
       CALL COMPUTE_INIT_ANG_VEL ( I3, JPASS, WMGDEG, IREF, IBOD, IVEH )
!C                                                                       
!C    End of the DO loop to compute the initial angular position 
!C     and velocity of each segment.                                 
!C                                                                        
   22 CONTINUE                                                            
!C
      RETURN                                                              
      END                                                                 
