      SUBROUTINE INPUT_BCARDS                                      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Reads the input cards that contain the physical dimensions and      
!C    characteristics of the test subject's body segments and joints.     
!C                                                                        
!C    This subroutine is called only by .MAIN
!C
      USE  MODULE_STANDARD, ONLY:
     &              UNITL, UNITM, UNITT, G,                       ! /CNSNTS/
     &              BD,                                           ! /CNTSRF/
     &              NFLX, NSEG, NJNT, NPG, NS,                    ! /CONTRL/
     &              BDYTTL,                                       ! /TITLES/
     &              SEG,                                          ! structures
     &              INTEGER_STD, IREAL_HIGH, LOGICAL_STD,         ! parameters
     &              LUAIN, LUAOU, MAXDEF,  MAXJNT, MAXSEG, LULIN, ! parameters
     &              FALSE, TRUE, D_0, D_1, I_0, I_1, I_2, I_4,    ! parameters 
     &              AIN_CONVERT, LIN_FLAG, ICHAR_STD              ! parameters
!C
!C    ANG_VEL_CONV, ANG_ACL_CONV, LIN_ACL_CONV, LIN_VEL_CONV, ! SEG%
!C    DRC_PHI,      NAME,         PHI,          RECIP_MASS,   ! SEG%
!C    RECIP_PHI,    ROT_PHI,      SINGULAR,     WEIGHT        ! SEG%
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &              ASAD, WNP,                               ! /FXNVEL/
     &              NFBOD,                                   ! /FXVAR/  
     &              DBN, HB0, HT0                            ! /FXXTRA/
!C
      USE  MODULE_WATER,     ONLY:   DELP                    ! /ELPDAT/
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &              I, IDYPR, IDYPRT, J, K, L, LEN, LPMI  
      DIMENSION  IDYPR(6,MAXSEG) 

!C
      REAL  ( KIND = IREAL_HIGH )  YPR1, YPR2, YPR3, YPRPMI
      DIMENSION  YPR1(3,MAXJNT), YPR2(3,MAXJNT), YPR3(3,MAXJNT),       
     &           YPRPMI(3,MAXJNT)                     
!C
      CHARACTER  ( LEN =   4, KIND = ICHAR_STD )  ATEMP4
      CHARACTER  ( LEN =   6, KIND = ICHAR_STD )  ATEMP6
      CHARACTER  ( LEN =  20, KIND = ICHAR_STD )  ATEMP20
      CHARACTER  ( LEN =  22, KIND = ICHAR_STD )  ATEMP22
!C
      LOGICAL ( KIND = LOGICAL_STD )   SLIP                                             
!C
      CALL ELTIME ( I_1, I_2 )                                           
!C                                                                        
!C    Input Card B.1                                                      
!C                                                                        
      CALL CHECK_COMMENT
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * ) NSEG, NJNT, BDYTTL, NFBOD                     
      ELSE
       READ ( LUAIN, 102 ) NSEG, NJNT, BDYTTL, NFBOD                     
  102  FORMAT ( 2I6, 8X, A20, I5 )                                         
       IF ( AIN_CONVERT )  THEN
        ATEMP20 = ADJUSTL ( BDYTTL )
        LEN = LEN_TRIM ( ATEMP20 )
        ATEMP22(1:LEN+2) = '"' // ATEMP20(1:LEN) // '"'       
        WRITE ( LULIN, 104 ) NSEG, NJNT, ATEMP22(1:LEN+2),
     &                       NFBOD, 'Card B.1'
  104   FORMAT ( 1X, 2( I6, 1X ), A, 1X, I5, 2X, A ) 
       END IF
      END IF
!C
!C    Deformable body numbers and their finite element data file names  
!C
      IF ( NFBOD .GT. I_0 )  THEN                                  
       IF ( NFBOD .GT. MAXDEF ) STOP 106                                
       CALL CHECK_COMMENT
       CALL INPUT_DEFORM                                              
      ELSE
!C
!C     Initialize selected deformable body joint arrays.
!C
       ASAD = D_0
       WNP  = D_0
       DBN  = D_0 
       HB0  = D_0
       HT0  = D_0
      END IF                                                            
!C                                                                      
      IF ( NSEG .GT. MAXSEG )  STOP 77                                      
      IF ( NJNT .GT. MAXJNT )  STOP 78                                      
!C                                                                        
!C    Input Cards  B.2 for each segment.                                 
!C                                                                        
      DO  I=1,NSEG                                                        
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  SEG(I)%NAME, SEG(I)%WEIGHT, 
     &                      ( SEG(I)%PHI(J), J=1,3 ),      
     &                      ( BD(J,I), J=1,6 ), LPMI                
       ELSE
        READ ( LUAIN, 100 )  SEG(I)%NAME, SEG(I)%WEIGHT, 
     &                      ( SEG(I)%PHI(J), J=1,3 ),      
     &                      ( BD(J,I), J=1,6 ), LPMI                
  100   FORMAT ( A4, 2X, 10F6.0, I4 )                                     
        IF ( AIN_CONVERT )  THEN
         ATEMP4 = ADJUSTL ( SEG(I)%NAME )
         LEN = LEN_TRIM ( ATEMP4 )
         ATEMP6(1:LEN+2) = '"' // ATEMP4(1:LEN)  // '"'       
         WRITE ( LULIN, 105 )  ATEMP6(1:LEN+2), SEG(I)%WEIGHT, 
     &                      ( SEG(I)%PHI(J), J=1,3 ),      
     &                      ( BD(J,I), J=1,6 ), LPMI, 'Card B.2.a'                
  105    FORMAT ( 1X, A, 2X, 10( F15.7, 1X ), I4, 2X, A )                                     
        END IF 
       END IF
       IF ( LPMI .EQ. I_1 )  THEN
        SEG(I)%ROT_PHI = TRUE
       ELSE IF ( LPMI .EQ. I_0 )  THEN
        SEG(I)%ROT_PHI = FALSE
       ELSE
        WRITE ( LUAOU, 110 ) LPMI
  110   FORMAT ( 1X, ' LPMI = ', I4, ' must be 0 or 1. ' )
        STOP ' STOP 789 in Subroutine INPUT_BCARDS '
       END IF
       DO  J=1,3                                                         
        IDYPR(J,I) = I_4 - J                                         
        YPRPMI(J,I) = D_0                                 
       END DO
       IF  ( SEG(I)%ROT_PHI )  THEN                                
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * ) ( YPRPMI(J,I), J=1,3 )                         
        ELSE
         READ ( LUAIN, 115 ) ( YPRPMI(J,I), J=1,3 )                         
  115    FORMAT ( 12X, 3F6.0 )                                             
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 120 ) ( YPRPMI(J,I), J=1,3 ), 'Card B.2.b'                         
  120     FORMAT ( 1X, 3( F15.7, 1X ), A )                                             
         END IF
        END IF
       END IF
       CALL DRCYPR ( SEG(I)%DRC_PHI, YPRPMI(1,I), IDYPR(1,I) )       
      END DO
      NFLX = I_0                                                    
!C
!C    If there are joints, input their data.
!C
      IF ( NJNT .NE. I_0 )  THEN                                   
       CALL  CHECK_COMMENT
       CALL INPUT_JOINTS ( IDYPR, IDYPRT, SLIP,
     &                     YPR1, YPR2, YPR3 )
      END IF
!C                                                                        
!C    Input Cards  B.6  for each segment.                                 
!C                                                                        
      CALL  CHECK_COMMENT
      DO  I=1,NSEG                                                        
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )   ( SEG(I)%ANG_VEL_CONV(J), J=1,3 ),                 
     &                      ( SEG(I)%LIN_VEL_CONV(J), J=1,3 ),
     &                      ( SEG(I)%ANG_ACL_CONV(J), J=1,3 ),
     &                      ( SEG(I)%LIN_ACL_CONV(J), J=1,3 )
       ELSE
        READ ( LUAIN, 125 ) ( SEG(I)%ANG_VEL_CONV(J), J=1,3 ),                 
     &                      ( SEG(I)%LIN_VEL_CONV(J), J=1,3 ),
     &                      ( SEG(I)%ANG_ACL_CONV(J), J=1,3 ),
     &                      ( SEG(I)%LIN_ACL_CONV(J), J=1,3 )
  125   FORMAT ( 12F6.0 )                                                  
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 130 ) ( SEG(I)%ANG_VEL_CONV(J), J=1,3 ),                 
     &                        ( SEG(I)%LIN_VEL_CONV(J), J=1,3 ),
     &                        ( SEG(I)%ANG_ACL_CONV(J), J=1,3 ),
     &                        ( SEG(I)%LIN_ACL_CONV(J), J=1,3 ),
     &                        'Card B.6'
  130    FORMAT ( 1X, 12( F15.7, 1X ), A )                                                  
        END IF
       END IF
      END DO
!C                                                                        
!C    Print Card B.1                                                     
!C                                                                        
      WRITE ( LUAOU, 135 ) BDYTTL, NSEG, NJNT, NPG, UNITM, UNITT,
     &                    UNITL, UNITL, UNITL, UNITM                       
      NPG = NPG + I_1                                                    
  135 FORMAT ( '1 Test Subject', 5X, A20, I5, ' Segments', I5,
     &         ' Joints', 58X, 'Page', I5, /, 120X, 'Card  B.1',
     &         /, 25X, 'Principal Moments of Inertia',    
     &         14X, 'Segment Contact Ellipsoid', 28X, 'Cards B.2', /,       
     &         3X, 'Segment', 6X, 'Weight', 7X, '(', A4, '-', A4,
     &         '**2-',A4,')', 11X, 'Semiaxes (', A4, ')', 12X,
     &         'Center (', A4, ')', 11X, 'Principal Axes (DEG)', /,          
     &         '  I  SYM        (', A4, ')', 7X, 'X', 8X, 'Y', 8X,
     &         'Z ', 2( 9X, 'X', 7X, 'Y', 7X, 'Z' ), 8X, 'Yaw',
     &         5X, 'Pitch', 5X, 'Roll', / )   
!C                                                                        
!C    Print Cards  B.2  for each segment.                                 
!C                                                                        
      DO  I=1,NSEG                                                        
       WRITE ( LUAOU, 140 )  I, SEG(I)%NAME, SEG(I)%WEIGHT, 
     &                      ( SEG(I)%PHI(J), J=1,3 ),   
     &                      ( BD(J,I), J=1,6 ), ( YPRPMI(J,I), J=1,3 )    
  140  FORMAT ( I3, 1X, A4, 3X, F11.3, 2X, 3F9.4, 2( 2X, 3F8.3 ),
     &          1X, 3F9.2 )    
      END DO
!C
!C    If there are joints, echo their input parameters and convert
!C     the functions from degrees to radians.
!C
      IF ( NJNT .NE. I_0 )   THEN                                   
       CALL OUTPUT_JOINTS ( IDYPR, IDYPRT, SLIP,
     &                      YPR1, YPR2, YPR3 )
      END IF
!C                                                                        
!C    Print Cards  B.6  for each segment.                                 
!C                                                                        
      WRITE ( LUAOU, 145 )  NPG, ( UNITT, UNITL, UNITT, I=1,2 )                    
  145 FORMAT ( '1', 122X, 'Page', I5, /, 20X,                             
     &         'Segment Integration Convergence Test Input', 58X,
     &         'Cards B.6', //, 17X, 'Angular Velocities', 11X,
     &         'Linear Velocities', 10X, 'Angular Accelerations',
     &         9X, 'Linear Accelerations', /, 21X, '(rad/', A4, ')',
     &         18X, '(', A4, '/', A4, ')', 17X, '(rad/', A4, '**2)', 
     &         16X, '(', A4, '/', A4,'**2)', /, ' Segment',
     &         4('       Mag.     Abs.     Rel.' ), /,  
     &         ' No. Sym', 4('       Test    Error    Error' ), / )      
      NPG = NPG + I_1                                                    
      DO  I=1,NSEG                                                        
       WRITE ( LUAOU, 150 )  I, SEG(I)%NAME, 
     &                      ( SEG(I)%ANG_VEL_CONV(J), J=1,3),
     &                      ( SEG(I)%LIN_VEL_CONV(J), J=1,3),
     &                      ( SEG(I)%ANG_ACL_CONV(J), J=1,3),
     &                      ( SEG(I)%LIN_ACL_CONV(J), J=1,3)    
  150  FORMAT ( I3, 1X, A4, 4( F11.3, F9.3, F9.4 ) )                      
      END DO
!C
!C    Input and echo the flexible element info, if necessary.
!C
      IF ( NFLX .NE. I_0 )  THEN                                       
       CALL CHECK_COMMENT
       CALL INPUT_FLEX 
      END IF
!C                                                                        
!C    W array has been supplied in lbs. Set up reciprocal mass (RW)       
!C    and moment of inertia (RPHI) arrays. However, if W or any element   
!C    of PHI is zero, segment will be considered singular (ISING=1) and   
!C    all reciprocals will be zero so as to nullify computations in the   
!C    DAUX routines. NS is the number of singular segments.               
!C                                                                        
      NS = I_0                                             
      SEG%RECIP_MASS = D_0                                      
      DO  I=1,NSEG                                                        
       SEG(I)%SINGULAR = I_0                                           
       IF ( SEG(I)%WEIGHT .EQ. D_0 ) SEG(I)%SINGULAR = I_1                        
       DO  K=1,3                                                          
        IF ( SEG(I)%PHI(K) .EQ. D_0 )  SEG(I)%SINGULAR = I_1                       
        SEG(I)%RECIP_PHI(K) = D_0                                               
       END DO
       IF ( SEG(I)%SINGULAR .EQ. I_1  )  THEN
        NS = NS + I_1                                   
        CYCLE
       END IF
       SEG(I)%RECIP_MASS =   G / SEG(I)%WEIGHT                                         
       SEG(I)%RECIP_PHI  = D_1 / SEG(I)%PHI                         
      END DO                                                              
!C                                                                        
!C    Set up ellipsoid matrix and inverse (assume yaw,pitch,roll = 0)     
!C    for 1st NSEG ellipsoids in BD(7-15) and BD(16-24).                  
!C                                                                        
      DO  J=1,NSEG                                                        
       DO  I=7,24                                                         
        BD(I,J) = D_0                                              
       END DO
       DO  I=1,3                                                          
        BD(4*I+3,J) = D_1 / BD(I,J)**2                               
        BD(4*I+12,J) = BD(I,J)**2                                         
       END DO
      END DO
!C                                                                        
!C    Set up DELP matrix for segment ellipsoids                          
!C                                                                       
      DO  J=1,NSEG                                                       
       DO  K=1,3                                                         
        DO  L=1,3                                                        
         DELP(K,L,J) = D_0                                           
        END DO                                                           
        DELP(K,K,J) = D_1                                            
       END DO                                                            
      END DO                                                              
!C                                                                        
      RETURN                                                              
      END                                                                 
