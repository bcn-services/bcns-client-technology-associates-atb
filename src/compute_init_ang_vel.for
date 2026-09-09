      SUBROUTINE  COMPUTE_INIT_ANG_VEL (I3, J, WMGDEG, IREF, IBOD, IVEH)
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in and determines the angular velocities 
!C     of the body segments.        
!C                                                                        
!C                                                                        
!C    Subroutines called by:  INPUT_ORIENT                         
!C                                                                        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS, RADIAN,                         ! /CNSNTS/
     &        NVEH,                                ! /CONTRL/
     &        SEG,                                 ! structures
     &        INTEGER_STD, IREAL_HIGH,             ! parameters
     &        LUAOU, MAXSEG, I_0, I_1              ! parameters 
!C
!C    ANG_VEL                        ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           IREF, IVEH, IBOD, I, I3, 
     &           IREF1, IREF2, IRF, J, L, NREF
      DIMENSION  IREF(4,MAXSEG), IVEH(MAXSEG), IBOD(MAXSEG)               
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  WMGDEG, TWMEG, TMPWMG, 
     &                  ADFWMG, DIFWMG, T, WMGT
      DIMENSION         WMGDEG(3,MAXSEG), TWMEG(3,MAXSEG),
     &                  T(3), TMPWMG(3)   
!C
      INTENT ( IN  )   I3, J, IREF, IBOD
      INTENT ( INOUT )   WMGDEG
!C
      WMGT = WMGDEG(1,J)**2 + WMGDEG(2,J)**2 + WMGDEG(3,J)**2          
!C                                                                        
!C    Change the angular velocity from degrees to radians.             
!C                                                                        
      DO  I=1,3                                                         
       TWMEG(I,J) = WMGDEG(I,J) * RADIAN                                
      END DO
!C                                                                       
!C    Compute the initial angular velocities of the segments based on    
!C     the values of I3 and IREF(1,J).  Where appropriate, the           
!C     reference angular velocities are first transformed from local      
!C     coordinates to inertial and then from inertial to the Jth         
!C     segment's local coordinate system.                                 
!C                                                                       
      IRF = IBOD(J)                                                   
      IREF1 = IREF(1,IRF)                                                
      IREF2 = IREF(2,IRF)                                               
      IF ( I3 .EQ. I_0 )  THEN                                        
!C                                                                       
!C     If I3 = 0 and IREF2 = 0, use the primary vehicle's angular        
!C      velocity unless the body segment is a vehicle, in which case      
!C      the C card data are used.                                        
!C                                                                     
       IF ( IREF2 .EQ. I_0 ) THEN                                     
        NREF = NVEH                                                      
!C                                                                        
!C      If I3 = 0 and IREF2 # 0, use the initial angular velocity        
!C       of segment IREF1, which is the segment supplied by Card G.2      
!C       for the reference segment if segment J is a reference segment     
!C       or the reference segment of segment J if segment J is a          
!C       nonreference segment.  If segment J is a vehicle, the C Card    
!C       data will be used.                                               
!C                                                                        
       ELSE IF ( IREF2 .NE. I_0 ) THEN                                
        NREF = IREF1                                                    
       END IF                                                            
!C                                                                      
!C     If the reference segment for a nonreference body segment is      
!C      a vehicle, use the initial angular velocity of the vehicle        
!C      reference segment, regardless of the value of IREF.              
!C                                                                       
       IF  ( ( IVEH(IRF) .EQ. I_1 ) .AND. 
     &       ( IREF(1,J) .EQ. I_0 ) )  THEN    
        NREF = IRF                                                     
       END IF                                                          
       CALL DOT31 ( SEG(NREF)%DIR_COS, SEG(NREF)%ANG_VEL, T      )              
       CALL MAT31 ( SEG(J)%DIR_COS,    T,                 TMPWMG )                       
      ELSE                                                             
!C                                                                      
!C     If I3 = 1, the angular velocities supplied by Card G.3            
!C      are used unless the body segment is a vehicle, in which case the   
!C      initial conditions computed from C Card data will be used.        
!C                                                                       
       DO  I=1,3                                                        
        TMPWMG(I) = TWMEG(I,J)                                          
       END DO
      END IF                                                           
!C                                                                        
!C     For nonvehicles, equate TMPWMG to the segment angular velocity.    
!C     If the segment is a vehicle, use the C card supplied initial      
!C     velocity.  Ensure that the data supplied by the G.3 card are       
!C     blanks or equal to the C card data.                                
!C                                                                        
       IF ( IVEH(J) .EQ. I_0 ) THEN                                   
        SEG(J)%ANG_VEL = TMPWMG                                  
!C                                                                        
!C      If nonzero values supplied for the angular velocity on            
!C      Card G.3 when I3 = 0, print message that they will not            
!C      be used.                                                          
!C                                                                        
        IF ( ( I3 .EQ. I_0 ) .AND. ( WMGT .NE. I_0 ) )  THEN         
         WRITE ( LUAOU, 150 ) J, J, J, J                                  
  150    FORMAT ( /, 1X, 'Nonzero values of angular velocity supplied',   
     &            ' for segment ', I4, ' on Card G.3.a.', /, 1X,          
     &            'These values will be ignored because I3 = 0 or',       
     &            ' I3 = 2 and IREF(2,J) # 0 for either segment ', I4,    
     &            /, 1X, ' or, if segment ', I4, ' is not a reference',   
     &            ' segment, the reference segment of segment ',
     &            I4, '.', / )                                            
        END IF                                                            
       ELSE                                                               
        IF ( WMGT .NE. I_0 )  THEN                                     
         DO  L=1,3                                                       
          DIFWMG = SEG(J)%ANG_VEL(L) - TMPWMG(L)               
          ADFWMG = ABS ( DIFWMG )                                         
          IF ( ADFWMG .GT. EPS(15) )  THEN                                
           WRITE ( LUAOU, 155 )  J                                        
  155      FORMAT ( /, 1X, 'An initial angular velocity for segment',    
     &              ' number ', I4, ', which is a vehicle, was ',         
     &              'supplied by the G.3 cards which differs ', /,        
     &             1X,'from the initial angular velocity supplied',       
     &             ' by the C cards.  This is not allowed.', // )         
           STOP ' STOP 234 in Subroutine INPUT_ANGULAR_VELOCITY '              
          END IF                                                          
         END DO                                                           
        ELSE                                                              
         WRITE ( LUAOU, 160 )  J                                          
  160    FORMAT ( /, 1X, 'Body segment number ', I4,
     &            ' is a vehicle whose',                                  
     &           ' initial angular velocity is supplied by the C',        
     &           ' card data.', /, 1X, 'Nonzero values of initial',       
     &           ' angular velocity supplied on Card G.3.a ignored.' )    
        END IF                                                            
       END IF                                                             
!C                                                                        
!C      Convert the angular velocity to units of degrees for output       
!C      purposes for the Jth segment.                                     
!C                                                                        
       DO  I=1,3                                                          
        WMGDEG(I,J) = SEG(J)%ANG_VEL(I) / RADIAN         
       END DO
!C
      RETURN
      END