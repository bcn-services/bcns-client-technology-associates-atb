      SUBROUTINE  INPUT_VEHICLE                                            
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                         
!C    Performs card input and computes data and tables required by         
!C    Subroutine VEHPOS to integrate the crash vehicle motion for one     
!C    of four permissible options:                                         
!C      (1) Half Sine-Wave linear deceleration impulse,                    
!C      (2) Unidirectional linear deceleration tabular input,              
!C      (3) Omnidirectional linear and angular acceleration tabular        
!C          input (6 degrees-of-freedom vehicle motion),                   
!C      (4) Spline-fit linear and angular acceleration obtained from       
!C          tabular velocity or displacement data.                         
!C                                                                         
!C                                                                         
!C     Subroutines called by:   .MAIN                                      
!C                                                                         
!C                                                                         
!C     STOPS: 6, 7A, 7B, 263, 264, 265, 266                                
!C                                                                         
!C     Parameters used: MAXSEG, MAXVEH                                     
!C                                                                         
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       NGRND, NPG, NSEG, NVEH,                  ! /CONTRL/
     &       VPSTTL,                                  ! /TITLES/
     &       NUMVEH,                                  ! /VPOSTN/
     &       ANGLE, ATAB, AX, DVEH, VMEG, VMEGD,      ! /VIN_TEMPVS/
     &       X0, XACOMP, XDOT0,                       ! /VIN_TEMPVS/
     &       RINIT_SEGLP, RINIT_SEGLV, RINIT_SEGLA,   ! new global
     &       RINIT_D, RINIT_WMEG, RINIT_WMEGD,        ! new global
     &       SEG, VEH,                                ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,      ! parameters
     &       LUAIN, LUAOU, MAXSEG, MAXVEH, LULIN,     ! parameters
     &       D_0, D_1, I_0, I_1, I_2,                 ! parameters
     &       AIN_CONVERT, LIN_FLAG                    ! parameters
!C
!C    ANG_ACL_CONV, ANG_VEL_CONV, LIN_ACL_CONV, LIN_VEL_CONV,       ! SEG%
!C    ANG_ACCEL,    ANG_VEL,      DIR_COS,      LIN_ACCEL,          ! SEG% 
!C    LIN_DISP,     LIN_VEL,      NAME,         PHI                 ! SEG%
!C    RECIP_MASS,   RECIP_PHI,    SINGULAR,     WEIGHT              ! SEG%
!C
!C    IVFLG, IVSEG, IVREF, VNAME, VTITLE,  LIN_DATA, ANG_DATA,      ! VEH%
!C    TIMEV, VOMEGA, NUM_VTAB, VINIT_TIME, VDELTA_TIME, VNORMAL     ! VEH%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, I1, I2, I3, IMAX, IQ, IVSAVE, J, K, L, 
     &           NATAB, NJ, NUMVEH_P, NVT
      DIMENSION  IVSAVE(6)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ADT, AT0, OMEG,  TAXV, VIPS, 
     &                  VTEMP1, VTEMP2, VTEMP3, VTEMP4, VTEMP5, VTIME
!C
      DIMENSION    TAXV(3)                                             
!C
      CHARACTER  ( LEN =   4, KIND = ICHAR_STD )  GRND
      CHARACTER  ( LEN =  80, KIND = ICHAR_STD )  ATEMP80              
      CHARACTER  ( LEN =  82, KIND = ICHAR_STD )  ATEMP82              
!C
      DATA GRND / ICHAR_STD_'GRND' /                                      
!C
!C    Initialize vehicle names.
!C
      VEH(1)%VNAME = ICHAR_STD_'VEH1'
      VEH(2)%VNAME = ICHAR_STD_'VEH2'
      VEH(3)%VNAME = ICHAR_STD_'VEH3'
      VEH(4)%VNAME = ICHAR_STD_'VEH4'
      VEH(5)%VNAME = ICHAR_STD_'VEH5'
      VEH(6)%VNAME = ICHAR_STD_'VEH '
!C                                                                        
!C    Read contents of Cards C.1 and C.2.                                 
!C                                                                        
      NVEH = NSEG                                                         
      DO NUMVEH=1,MAXVEH+1                                                
       NUMVEH_P = NUMVEH
!C                                                                         
!C     Test to ensure the maximum number of vehicles is not                 
!C     exceeded.                                                            
!C                                                                        
       IF ( NUMVEH .GT. MAXVEH )  THEN                                    
        WRITE ( LUAOU, 100 ) NUMVEH, MAXVEH                             
  100   FORMAT ( 1X, 'Vehicle number', I4,
     &           ' exceeds the maximum number',                          
     &           ' of vehicles which is currently ', I4, '.', // )         
        STOP ' STOP 7 in Subroutine INPUT_VEHICLE'                               
       END IF                                                              
!C
!C     Read in the description of the vehicle.
!C
       CALL CHECK_COMMENT
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  VEH(NUMVEH)%VTITLE                           
       ELSE
        READ ( LUAIN, 102 )  VEH(NUMVEH)%VTITLE                           
  102   FORMAT ( A80 )                                                      
        IF ( AIN_CONVERT )  THEN
         ATEMP80 = ADJUSTL ( VEH(NUMVEH)%VTITLE )
         L = LEN_TRIM ( ATEMP80 )
         ATEMP82(1:L+2) = '"' // ATEMP80(1:L) // '"'
         WRITE ( LULIN, 103 )  ATEMP82(1:L+2), 'Card C.1'                           
  103    FORMAT ( 1X, A, 2X, A )                                                      
        END IF
       END IF
       VPSTTL = VEH(NUMVEH)%VTITLE
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ANGLE, VIPS, VTIME, X0, NATAB, AT0, 
     &                     ADT, I1, I3, I2                                 
       ELSE
        READ ( LUAIN, 105 )  ANGLE, VIPS, VTIME, X0, NATAB, AT0, 
     &                       ADT, I1, I3, I2                                 
  105   FORMAT ( 8F6.0, I6, 2F6.0, 3( I2 ) )                                 
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 106 )  ANGLE, VIPS, VTIME, X0, NATAB, AT0, 
     &                        ADT, I1, I3, I2, 'Card C.2.a'                                 
  106    FORMAT ( 1X, 8( F15.7, 1X ), I6, 1X, 2( F15.7, 1X ), 
     &            3( I2, 1X ), 1X, A )                                 
        END IF
       END IF
!C
       VEH(NUMVEH)%IVFLG = I1                                                 
       VEH(NUMVEH)%IVSEG = I2                                                
       VEH(NUMVEH)%IVREF = I3                                                 
       IVSAVE(NUMVEH)  = I2                                                 
!C                                                                          
!C      Test for proper values for I1, I2 and I3.                         
!C                                                                          
       IF ( ( I1 .GT. I_2 ) .OR. ( I1 .LT. -I_2 ) )  THEN               
        WRITE ( LUAOU, 110 )  I1, NUMVEH                                   
  110   FORMAT ( 1X, 'I1 = ', I4, ' for vehicle number ', I4, '.',         
     &           '  This is not in the range -2 to 2.', // )              
        STOP ' STOP 263 in Subroutine INPUT_VEHICLE'                             
       END IF                                                               
!C
       IF ( ( I2 .LT. I_0 ) .OR. 
     &      ( I2 .GT. ( MAXSEG - I_1 ) ) )  THEN         
        WRITE ( LUAOU, 115 )  I2, NUMVEH                                    
  115   FORMAT ( 1X, 'MSEG = ', I4, ' for vehicle number ', I4, '.',       
     &           '  This value for the vehicle segment is not',            
     &          ' allowed.', // )                                          
        STOP ' STOP 264 in Subroutine INPUT_VEHICLE'                               
       END IF                                                              
!C
       IF ( ( I3 .LT. I_0 ) .OR. ( I3 .GT. MAXSEG ) )  THEN             
        WRITE ( LUAOU, 120 )  I3, NUMVEH                                    
  120   FORMAT ( 1X, 'I3 = ', I4, ' for vehicle number ', I4, '.',         
     &           '  This value for the vehicle reference segment',         
     &           ' is not allowed.', // )                                  
        STOP ' STOP 265 in Subroutine INPUT_VEHICLE'                               
       END IF                                                              
!C
       IF  ( ( I3 .NE. I_0 ) .AND. ( I1 .EQ. I_0 ) )  THEN           
        WRITE ( LUAOU, 125 )  NUMVEH                                       
  125   FORMAT ( 1X, 'I1= 0 and I3 is not equal to 0 for vehicle',         
     &           ' NUMBER', I4, '.  I1 must be 1, 2 or 3 if I3',           
     &           ' is not equal to zero.', // )                            
        STOP ' STOP 266 in Subroutine INPUT_VEHICLE'                              
       END IF                                                              
!C                                                                         
!C     Print contents of Cards C.1 and C.2.                                
!C                                                                          
       WRITE ( LUAOU, 130 )  NPG, VPSTTL, ANGLE, VIPS, VTIME, X0, 
     &                       NATAB, AT0, ADT, I1, I3, I2                    
       NPG = NPG + I_1                                                  
  130  FORMAT ( '1 Vehicle Deceleration Inputs', 94X, 'Page', I5, 
     &          /, 120X, 'Cards C', /, 3X, A80, //,                     
     &          7X, 'Yaw', 9X, 'Pitch', 7X, 'Roll', 8X, 'VIPS', 8X,       
     &          'VTIME', 7X, 'X0(X)', 7X, 'X0(Y)', 7X, 'X0(Z)',
     &          2X, 'NATAB',4X, 'AT0', 6X, 'ADT', 3X, 'I1', 1X, 'I3',
     &          1X, 'MSEG', /, 8F12.3, I5, 2X, 2F9.5, 1X, 
     &          I2, 1X, I2, 2X, I2 )                                     
!C                                                                        
!C     Compute relative vehicle motion for Option 1, 2, 3 or 4.             
!C                                                                         
       OMEG = D_0                                                          
       IF ( NATAB .GE. I_0 )  THEN                                     
        CALL VINO12 ( NATAB, OMEG, ADT, AT0, VTIME, VIPS, NUMVEH_P )       
       ELSE                                                               
        CALL VINO34 ( NATAB, ADT, AT0, VTIME, VIPS, NUMVEH_P, I2 )         
       END IF                                                               
!C                                                                         
!C     Determine if the current vehicle is the primary vehicle and          
!C     if the vehicle number is in the proper sequence if the vehicle       
!C     is a vehicle segment rather than a body segment.                    
!C                                                                          
       J = I2                                                              
       IF ( I2 .EQ. I_0 ) THEN                                           
        NVEH = NVEH + I_1                                                 
        J = NVEH                                                           
       ELSE IF ( ( I2 .GT. NSEG ) .AND. 
     &           ( I2 .NE. ( NVEH + I_1 ) ) )  THEN   
        WRITE ( LUAOU, 135 )  NUMVEH, I2, NVEH                              
  135   FORMAT ( 1X, 'Vehicle number', I4, ' is not a body segment ',    
     &           ' yet vehicle segment number', I4, /, 1X, 'is not in ', 
     &           'ascending order.  It should be segment',                
     &           ' number', I4, '.', // )                                 
        STOP ' STOP 6 in Subroutine INPUT_VEHICLE'                                
       ELSE IF ( I2 .GT. NSEG )  THEN                                       
        NVEH = NVEH + I_1                                                 
       END IF                                                              
!C                                                                      
!C     Store initial conditions for the prescribed motion for all           
!C     vehicle segments.  Redefine (if body segment) or define (if         
!C     nonbody segment and hence a new segment) certain body properties.   
!C                                                                          
       SEG(J)%SINGULAR = -I_1                                                 
       IF ( I2 .GT. NSEG )  SEG(J)%NAME = VEH(NUMVEH)%VNAME                      
       SEG(J)%RECIP_MASS = D_0                                  
       DO   I=1,3                                                         
        VEH(NUMVEH)%VNORMAL(I) = AX(I)                                               
!C                                                                        
!C      Initial position, linear and angular.                              
!C                                                                         
        RINIT_SEGLP(I,J) = X0(I)                                              
        DO  K=1,3                                                          
         RINIT_D(I,K,J) = DVEH(I,K)                                            
        END DO
!C                                                                        
!C      Initial velocity, linear and angular.                               
!C                                                                        
        RINIT_SEGLV(I,J) = XDOT0(I)                                              
        RINIT_WMEG(I,J)  = VMEG(I)                                              
!C                                                                       
!C      Initial acceleration, linear and angular.                        
!C                                                                       
        RINIT_SEGLA(I,J) = XACOMP(I)                                           
        RINIT_WMEGD(I,J) = VMEGD(I)                                             
        SEG(J)%RECIP_PHI(I) = D_0                                        
       END DO
       VEH(NUMVEH)%VINIT_TIME  = AT0                                               
       VEH(NUMVEH)%VDELTA_TIME = ADT                                                 
       VEH(NUMVEH)%VOMEGA      = OMEG                                               
       VEH(NUMVEH)%TIMEV       = VTIME                                               
       VEH(NUMVEH)%NUM_VTAB    = NATAB                                              
!C                                                                         
!C     Store vehicle relative tabular data for Options 2, 3 or 4.       
!C                                                                        
       NJ = ABS ( NATAB )                                                  
       IF  ( NJ .GT. I_0 )  THEN                                         
        DO  K=1,NJ                                                         
         DO  I=1,3                                                         
          VEH(NUMVEH)%LIN_DATA(I,K) = ATAB(I,K)                                   
          VEH(NUMVEH)%ANG_DATA(I,K) = ATAB(I+9,K)                                
         END DO
        END DO
       END IF                                                             
!C                                                                        
!C     Define body properties for new vehicle (nonbody) segment.           
!C                                                                        
       IF ( J .GT. NSEG ) THEN                                            
        SEG(J)%ANG_ACL_CONV = D_0
        SEG(J)%ANG_VEL_CONV = D_0
        SEG(J)%LIN_ACL_CONV = D_0
        SEG(J)%LIN_VEL_CONV = D_0
        SEG(J)%PHI          = D_0
        SEG(J)%RECIP_MASS   = D_0                         
        SEG(J)%RECIP_PHI    = D_0                                                  
        SEG(J)%WEIGHT       = D_0                                               
       END IF
!C                                                                        
!C     If the last vehicle, set the segment name and vehicle description
!C      that will appear in the output to the primary vehicle description.      
!C                                                                        
       IF  ( I2 .EQ. I_0 )  THEN                                         
        SEG(NVEH)%NAME = VEH(MAXVEH)%VNAME                                             
        VPSTTL = VEH(NUMVEH)%VTITLE
        EXIT
       END IF
!C
!C    End of DO loop to input vehicle data.                                                                          
!C
      END DO                                                              
!C
!C    Test for the ground segment number and set up segment data           
!C    for the ground segment.                                              
!C                                                                        
      NGRND = NVEH + I_1                                                
      IF  ( NGRND .GT. MAXSEG )  THEN                                      
       WRITE ( LUAOU, 145 )  NGRND, MAXSEG                                 
  145  FORMAT ( 1X, 'Vehicle number',I4,' has resulted in the maximum', 
     &          ' number of segments, currently ', I4, ', to be',         
     &          ' exceeded.', // )                                        
       STOP ' STOP 8 in Subroutine INPUT_VEHICLE'                         
      END IF                                                               
!C
      SEG(NGRND)%ANG_ACCEL    = D_0                                  
      SEG(NGRND)%ANG_ACL_CONV = D_0
      SEG(NGRND)%ANG_VEL      = D_0                                     
      SEG(NGRND)%ANG_VEL_CONV = D_0
      SEG(NGRND)%DIR_COS      = D_0                                   
      DO  I=1,3                                                       
       SEG(NGRND)%DIR_COS(I,I) = D_1                                         
      END DO
      SEG(NGRND)%LIN_ACCEL    = D_0                      
      SEG(NGRND)%LIN_ACL_CONV = D_0
      SEG(NGRND)%LIN_DISP     = D_0                                       
      SEG(NGRND)%LIN_VEL      = D_0
      SEG(NGRND)%LIN_VEL_CONV = D_0
      SEG(NGRND)%NAME         = GRND                                              
      SEG(NGRND)%PHI          = D_0                                                   
      SEG(NGRND)%RECIP_MASS   = D_0                             
      SEG(NGRND)%RECIP_PHI    = D_0                                      
      SEG(NGRND)%SINGULAR     = -I_1
      SEG(NGRND)%WEIGHT       = D_0                                               
!C                                                                         
!C    Compute reference paths to the ground (inertial) coordinate          
!C     system and print out result.                                        
!C                                                                         
!C     IVREF's altered by VPATH, other variables used but not altered.    
!C                                                                         
      CALL VPATH ( NUMVEH, NVEH, NGRND, NPG )         
!C                                                                         
!C    Reorder the variables in /VPOSTN/ so that they correspond to         
!C    the order of the vehicles in IVFLG, IVSEG, IVREF.                 
!C                                                                         
      IMAX = I_0                                                        
      DO  I=1,NUMVEH                                                       
       IF ( IVSAVE(I) .EQ. I_0 )  IVSAVE(I) = NVEH                      
       NVT = ABS ( VEH(I)%NUM_VTAB )                                              
       IMAX = MAX ( IMAX, NVT )                                           
      END DO
      DO 36 I=1,NUMVEH-1                                                   
       I2 = VEH(I)%IVSEG                                                 
       DO 38 J=I,NUMVEH                                                  
        IQ = IVSAVE(J)                                                    
        VTEMP1 = VEH(J)%VINIT_TIME                                                    
        VTEMP2 = VEH(J)%VDELTA_TIME                                                    
        VTEMP3 = VEH(J)%TIMEV                                            
        VTEMP4 = VEH(J)%VOMEGA                                                  
        VTEMP5 = VEH(J)%NUM_VTAB                                                  
        DO  K=1,3                                                          
         TAXV(K) = VEH(J)%VNORMAL(K)                                                 
        END DO
        DO  L=1,IMAX                                                       
         DO  K=1,3                                                        
          ATAB(K,L) = VEH(J)%LIN_DATA(K,L)   
         END DO
         DO  K=4,6
          ATAB(K,L) = VEH(J)%ANG_DATA(K-3,L)
         END DO
        END DO
        IF ( ( IQ .EQ. I2 ) .AND. ( J .NE. I ) )  THEN                    
         IVSAVE(J) = IVSAVE(I)                                             
         IVSAVE(I) = IQ                                                    
         VEH(J)%VINIT_TIME  = VEH(I)%VINIT_TIME                                                   
         VEH(I)%VINIT_TIME  = VTEMP1                                                   
         VEH(J)%VDELTA_TIME = VEH(I)%VDELTA_TIME                                                   
         VEH(I)%VDELTA_TIME = VTEMP2                                                   
         VEH(J)%TIMEV       = VEH(I)%TIMEV 
         VEH(I)%TIMEV       = VTEMP3
         VEH(J)%VOMEGA      = VEH(I)%VOMEGA                                               
         VEH(I)%VOMEGA      = VTEMP4                                                 
         VEH(J)%NUM_VTAB    = VEH(I)%NUM_VTAB                                               
         VEH(I)%NUM_VTAB    = VTEMP5                                                 
         DO  K=1,3                                                         
          VEH(J)%VNORMAL(K) = VEH(I)%VNORMAL(K)                                              
          VEH(I)%VNORMAL(K) = TAXV(K)                                               
         END DO
         DO  L=1,IMAX                                                      
          DO  K=1,3                                                        
           VEH(J)%LIN_DATA(K,L) = VEH(I)%LIN_DATA(K,L)
           VEH(J)%ANG_DATA(K,L) = VEH(I)%ANG_DATA(K,L)
           VEH(I)%LIN_DATA(K,L) = ATAB(K,L)
           VEH(I)%ANG_DATA(K,L) = ATAB(K+3,L)
          END DO
         END DO
        END IF                                                             
   38  CONTINUE
   36 CONTINUE                                                            
!C
      RETURN                                                              
      END                                                                 
