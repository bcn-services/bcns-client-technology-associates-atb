      SUBROUTINE INPUT_DCARDS                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine controls the subroutines that read and print
!C    the input cards that describe the physical dimensions of the 
!C    planes representing the vehicle panels and of the restraint 
!C    belts. Also processes those data cards that describe  
!C    additional contact ellipsoids, constraints, body segment symmetry    
!C    options and spring damper functions.                                
!C                                                                         
!C    This subroutine is called only by Subroutine INITIALIZE.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       NRTORQ,                                 ! /ACTFR/
     &       NBAG, NBLT, NGRND, NHRNSS, NPG, NJNT,   ! /CONTRL/
     &       NPL, NQ, NSD, NSEG, NVEH, NWINDF,       ! /CONTRL/
     &       NFORCE,                                 ! /WINDFR/
     &       NELP,                                   ! /XTRA/
     &       INTEGER_STD, I_0, I_1, MAX_FOR_TORQ,    ! parameters
     &       LUAIN, LUAOU, MAXELP, MAXPLN,           ! parameters
     &       MAX_NUM_BELTS, MAX_NUM_DAMPERS, MAXCST, ! parameters
     &       MAXHRN, MAX_FUNC, MAXBAG,               ! parameters
     &       LULIN, AIN_CONVERT, LIN_FLAG            ! parameters
!C
      USE  MODULE_WATER,  ONLY:   NWATER     ! /WATINF1/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           NEXTCD, NJNTFOLD
!C                                                                        
!C    Input Card D.1                                                      
!C                                                                        
      CALL CHECK_COMMENT
      IF ( LIN_FLAG )  THEN
       READ  ( LULIN, * )   NPL, NBLT, NBAG, NELP, NQ, NSD, NHRNSS,
     &                      NWINDF, NJNTFOLD, NFORCE, NWATER, NEXTCD     
      ELSE
       READ  ( LUAIN, 100 )  NPL, NBLT, NBAG, NELP, NQ, NSD, NHRNSS,
     &                       NWINDF, NJNTFOLD, NFORCE, NWATER, NEXTCD     
  100  FORMAT ( 12I6 )                                                     
       IF ( AIN_CONVERT )  THEN
        WRITE  ( LULIN, 105 )  NPL, NBLT, NBAG, NELP, NQ, NSD, NHRNSS,
     &                         NWINDF, NJNTFOLD, NFORCE, NWATER, NEXTCD,
     &                         'Card D.1.a'   
  105   FORMAT ( 1X, 12( I6, 1X ), 1X, A )                                                     
       END IF
      END IF
!C
      WRITE ( LUAOU, 110 ) NPG, NPL, NBLT, NBAG, NELP, NQ, NSD, NHRNSS,
     &                     NWINDF, NJNTFOLD, NFORCE, NWATER, NEXTCD      
      NPG = NPG + I_1                                                     
  110 FORMAT ( '1    NPL    NBLT    NBAG    NELP      NQ     NSD',
     &         '  NHRNSS  NWINDF  NJNTFOLD  NFORCE   NWATER   NEXTCD',
     &         24X, 'Page', I5, /, 12I8, 24X, 'Card D.1a' )               
      IF ( NEXTCD .NE. I_0 )  THEN                                   
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )   NRTORQ                                     
       ELSE
        READ  ( LUAIN, 115 )   NRTORQ                                     
  115   FORMAT ( 12I6 )                                                     
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 120 )   NRTORQ, 'Card D.1.b'                                     
  120    FORMAT ( 1X, I6, 2X, A )
        END IF
       END IF
!C
       WRITE ( LUAOU, 125 ) NRTORQ                                      
  125  FORMAT ( //, '1 NRTORQ', /, I8, 112X, 'Card D.1b' )              
      ELSE                                                              
       NRTORQ = I_0                                                  
      END IF                                                            
!C                                                                       
      IF ( NPL    .GT. MAXPLN ) STOP 65                                 
      IF ( NBLT   .GT. MAX_NUM_BELTS ) STOP 66                            
      IF ( NBAG   .GT. MAXBAG ) STOP 67                                    
      IF ( NELP   .GT. MAXELP ) STOP 68                                    
      IF ( NQ     .GT. MAXCST ) STOP 69                                   
      IF ( NSD    .GT. MAX_NUM_DAMPERS ) STOP 70                          
      IF ( NHRNSS .GT. MAXHRN ) STOP 71                                    
      IF ( NWINDF .GT. MAX_FUNC ) STOP 72                                     
      IF ( NFORCE .GT. MAX_FOR_TORQ ) STOP 74                                 
!C                                                                      
!C     Check if Cards F.5 are input - no longer used                    
!C                                                                      
      IF  ( NJNTFOLD .NE. I_0 ) THEN                                 
       WRITE ( LUAOU, 130 )                                             
  130  FORMAT ( ' Nonzero value assigned to NJNTF, which is no longer ',
     & 'used.  Joint functions', /, ' are now defined similarly to ',   
     & 'regular functions and are assigned to joints on', /,
     & ' Cards B.4.  See ATB Input Description for more information.' ) 
       STOP 9                                                           
      END IF                                                            
!C
!C    Though the array limitation for the maximum number of joint
!C     actuators is equal to the maximum number of joints, for a 
!C     specific simulation, the maximum number of joint actuators
!C     can not exceed the number of joints specified for that run.
!C
      IF ( NRTORQ .GT. NJNT )   STOP 110                             
!C
!C    Input the contact plane parameters.
!C     Data are supplied on the D.2 cards.
!C
      IF ( NPL .NE. I_0 )   CALL INPUT_PLANES                                 
!C
!C    Input the simple belt parameters.
!C     Data are supplied on the D.3 cards.
!C
      IF ( NBLT .NE. I_0 )  CALL INPUT_BELTS                                       
!C                                                                        
!C    Call INPUT_AIRBAGS routine if required for airbag input.
!C     Data are supplied on the D.4 cards.            
!C                                                                        
      IF ( NBAG .NE. I_0 )   CALL INPUT_AIRBAGS                     
!C
!C    Input additional contact ellipsoid data, or data to change
!C     the default contact ellipsoid data.  Data are supplied on the
!C     D.5 cards.
!C
      IF ( NELP .GT. I_0 )   CALL INPUT_ELLIPSOIDS                                 
!C                                                                       
!C    Input the constraint parameters, from the D.6 cards.
!C                                                                        
      IF ( NQ .GT. I_0 )  CALL INPUT_CONSTRAINTS                                         
!C
!C    Input the symmetry options for the segments,the D.7 cards.
!C
      CALL INPUT_SYMMETRY
!C                                                                        
!C    Input the spring dampers from the D.8 Cards.
!C                                                                        
      IF  ( NSD .GT. I_0 )  CALL INPUT_SPRING_DAMPERS                                     
!C
!C    Input the force/torque parameters from the D.9 cards.
!C
      IF  ( NFORCE .GT. I_0 )  CALL INPUT_FORCE_TORQUE                                   
!C
      RETURN                                                              
      END                                                                