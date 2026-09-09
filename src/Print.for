      SUBROUTINE PRINT ( SUB )                                             
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Subroutine to print segment linear and angular                       
!C    positions, velocities and accelerations for a given time.            
!C                                                                         
!C    Arguments                                                            
!C       SUB: calling subroutine name                                      
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &        NRTORQ,                                      ! /ACTFR/
     &        IEULER,                                      ! /CEULER/
     &        WJ,                                          ! /CMATRX/
     &        G, UNITM, UNITL, UNITT,                      ! /CNSNTS/
     &        NBAG, NJNT, NVEH, NPG, NPRT, NQ, NSEG, TIME, ! /CONTRL/
     &        KQ1, KQ2, KQTYPE, QQ, RK1, RK2,              ! /CSTRNT/
     &        ACT, SEG, JNT, OUT_TIMES,                    ! structures
     &        ICHAR_STD, INTEGER_STD, IREAL_HIGH,          ! parameters
     &        LOGICAL_STD, LUAOU, MAXJNT, NUM_OUT_TIMES,   ! parameters
     &        FALSE, TRUE, D_0, D_HALF, D_1, D_1000,       ! parameters
     &        I_0, I_1, I_2, I_4, I_5, I_6                 ! parameters
!C
!C    ACT_JNT, BASE_SEG, TOR_AXIS, ACT_TORQ                   ! ACT%
!C    ANG_ACCEL,   ANG_VEL,   DIR_COS,  DRC_PHI, EXT_ANG_ACL, ! SEG%
!C    EXT_LIN_ACL, LIN_ACCEL, LIN_DISP, LIN_VEL, NAME,        ! SEG%
!C    PHI,         ROT_PHI,     WEIGHT                        ! SEG%
!C
!C    JFORCE, JNT_NAME, JTORQUE, PROX_SEG, JTYPE              ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, ICH, II, IPC, IPINJ, J, JJ, K, M, MBAG_LCL,
     &         N, NRS1
C
      REAL  ( KIND = IREAL_HIGH )
     &                  HH, SKE, SQS1, T1, T2_LCL, T3,
     &                  T4, TKE, TMSEC, TT, V, YPR
      DIMENSION         HH(3), SKE(3), TKE(3), T1(3), T2_LCL(3),
     &                  T3(3,3), T4(3,MAXJNT), YPR(3)
!C  
      REAL ( KIND = IREAL_HIGH )  VECMAG
      EXTERNAL                    VECMAG
!C
      CHARACTER ( LEN = 6, KIND = ICHAR_STD  )  SUB
!C
      LOGICAL  ( KIND = LOGICAL_STD )  RETURN_STATE
!C
      INTENT ( IN )  SUB
!C
!C    Check if time windowing is in effect, and if so, will there
!C     be a output from PRINT on this call.
!C
      IF ( NUM_OUT_TIMES .EQ. I_0 )  THEN
       CONTINUE
      ELSE
       RETURN_STATE = TRUE
       DO I=1,NUM_OUT_TIMES
        IF ( .NOT. OUT_TIMES(I)%PRINT ) THEN
         RETURN_STATE = FALSE
         CYCLE
        ELSE 
         IF ( ( TIME .GE. OUT_TIMES(I)%START ) .AND.
     &        ( TIME. LE. OUT_TIMES(I)%END ) )  THEN
          RETURN_STATE = FALSE
         END IF
        END IF
       END DO
       IF ( RETURN_STATE )  RETURN
      END IF
!C     
!C    Output segment info.
!C
      IPC = I_1                                                        
      TMSEC = D_1000 * TIME                                      
      WRITE ( LUAOU, 100 )  IPC, SUB, TMSEC, NPG                         
  100 FORMAT ( I1, 6X, A6, ' Functions for Time=',                        
     &         G10.3, ' msec', 75X, 'Page', I5, / )                        
      NPG = NPG + I_1                                                    
      WRITE ( LUAOU, 105 )                                               
  105 FORMAT ( 1X, 23X, '(Inertial)', 29X, '(Local)', 35X, '(Local)' )   
      WRITE ( LUAOU, 110 )  UNITT, UNITT                                   
  110 FORMAT ( 19X, 'Angular Rotation (DEG)',                            
     &         12X, 'Angular Velocity (RAD/', A4, ')',                   
     &         12X, 'Angular Acceleration (RAD/', A4, '**2)', /,          
     &         ' Segment',9X,'Yaw' ,7X,'Pitch',7X,'Roll',                  
     &         11X, 'X', 11X, 'Y', 11X, 'Z', 15X, 'X', 13X,
     &         'Y', 13X, 'Z', / )                                          
      MBAG_LCL = NVEH + NBAG                                               
!C
      DO  I=1,MBAG_LCL                                                     
       IF  ( .NOT. SEG(I)%ROT_PHI )   THEN                              
        CALL YPRDEG ( SEG(I)%DIR_COS, YPR )                               
        WRITE  ( LUAOU, 112 )    I, SEG(I)%NAME, YPR,
     &                          ( SEG(I)%ANG_VEL(K),   K=1,3 ),
     &                          ( SEG(I)%ANG_ACCEL(K), K=1,3 )   
  112   FORMAT ( I3, 1X, A4, 3X, 3F11.4, 3X, 3F12.5, 3X, 3F14.6 )          
       ELSE
        CALL DOT33 ( SEG(I)%DRC_PHI, SEG(I)%DIR_COS,   T3 )                  
        CALL DOT31 ( SEG(I)%DRC_PHI, SEG(I)%ANG_VEL,   T1 )               
        CALL DOT31 ( SEG(I)%DRC_Phi, SEG(I)%ANG_ACCEL, T2_LCL )        
        CALL YPRDEG ( T3, YPR )                                            
        WRITE ( LUAOU, 115 )   I, SEG(I)%NAME, YPR, 
     &                        ( T1(K), K=1,3 ),
     &                        ( T2_LCL(K), K=1,3 )                        
  115  FORMAT ( I3, 1X, A4, 3X, 3F11.4, 3X, 3F12.5, 3X, 3F14.6 )          
       END IF                                                              
      END DO                                                              
!C
      WRITE ( LUAOU, 120 )                                                
  120 FORMAT ( //, 1X, 23X, '(Inertial)', 27X, '(Inertial)',
     &         32X, '(Inertial)' )                                        
      WRITE  ( LUAOU, 125 )   UNITL, UNITL, UNITT                         
  125 FORMAT ( 18X, 'Linear Position (', A4, ')',                         
     &         13X, 'Linear Velocity (', A4, '/', A4, ')',                 
     &         16X, 'Linear Accelerations (G''S)', /,                      
     &         ' Segment', 10X, 'X', 10X, 'Y', 10X, 'Z',                  
     &         13X, 'X', 11X, 'Y', 11X, 'Z', 15X, 'X', 13X, 'Y',
     &         13X, 'Z', / )                                              
      DO  I=1,MBAG_LCL                                                    
       T1 = SEG(I)%LIN_ACCEL / G                                 
       WRITE ( LUAOU, 130 )  I, SEG(I)%NAME, 
     &                      ( SEG(I)%LIN_DISP(K), K=1,3 ),
     &                      ( SEG(I)%LIN_VEL(K),  K=1,3 ), T1              
  130  FORMAT ( I3, 1X, A4, 3X, 3F11.4, 3X, 3F12.5, 3X, 3F14.6 )           
      END DO
!C
      IF  ( NSEG .GT. I_6 )   THEN
       WRITE ( LUAOU, 135 )   NPG                                          
  135  FORMAT ( '1', 122X, 'Page', I5 )                                    
       NPG = NPG + I_1                                                   
      END IF
      WRITE ( LUAOU, 140 )                                               
  140 FORMAT ( //, 1X, 23X, '(Inertial)', 29X, '(Local)' )                
      WRITE ( LUAOU, 145 ) UNITL, UNITT, UNITT, UNITM, UNITL             
  145 FORMAT ( 18X, 'U1 Array (', A4, '/', A4, '**2)',                   
     &         14X, 'U2 Array (RAD/', A4, '**2)',                       
     &         25X, 'Kinetic Energy', /,                                 
     &         15X, 'External Linear Accelerations',                     
     &          8X, 'External Angular Accelerations',                    
     &         22X, '(', A4, '-', A4, ')', /,                            
     &         ' Segment', 10X, 'X', 10X, 'Y', 10X, 'Z', 13X, 
     &         'X', 11X, 'Y', 11X, 'Z',                                  
     &         14X, 'Linear', 7X, 'Angular', 7X, 'Total', / )            
!C
      TKE = D_0                                                       
      DO  I=1,NSEG                                                         
       V = ( VECMAG ( SEG(I)%LIN_VEL ) )**2
       SKE(1) = D_HALF * SEG(I)%WEIGHT * V / G                            
       SKE(2) = D_0                                                 
       DO  J=1,3                                                         
        SKE(2) = SKE(2) + D_HALF * SEG(I)%PHI(J) * 
     &                      ( SEG(I)%ANG_VEL(J) )**2    
       END DO
       SKE(3) = SKE(1) + SKE(2)                                          
       TKE = TKE + SKE                                   
       IF  ( .NOT. SEG(I)%ROT_PHI )   THEN                               
        WRITE ( LUAOU, 150 )  I,   SEG(I)%NAME, 
     &                          ( SEG(I)%EXT_LIN_ACL(K), K=1,3 ),  
     &                          ( SEG(I)%EXT_ANG_ACL(K), K=1,3 ), 
     &                          ( SKE(K), K=1,3 )  
  150   FORMAT ( I3, 1X, A4, 3X, 3( D11.4, 1X ), 3X, 3( D12.5, 1X ),
     &           3X, 3( D12.5, 1X ) )                                  
       ELSE
        CALL DOT31 ( SEG(I)%DRC_PHI, SEG(I)%EXT_ANG_ACL, T1 )         
        WRITE ( LUAOU, 150 )  I,   SEG(I)%NAME, 
     &                          ( SEG(I)%EXT_LIN_ACL(K), K=1,3 ),    
     &                          ( T1(K), K=1,3 ), 
     &                          ( SKE(K), K=1,3 )      
       END IF                                                              
      END DO                                                              
      WRITE ( LUAOU, 155 )  ( TKE(K), K=1,3 )                            
  155 FORMAT ( 1X, 98X, 'Total Body Kinetic Energy', /,                 
     &         1X, 90X, 3( 1X, D12.5 ) )                                
!C
!C    Output joint info.
!C
      IF ( NJNT .GT. I_0 )   THEN                                  
       WRITE ( LUAOU, 160 )                                               
  160  FORMAT ( //, 1X, 27X, '(Inertial)', 27X, '(Inertial)' )            
       WRITE ( LUAOU, 165 )  UNITM, UNITL, UNITM, UNITT                     
  165  FORMAT ( 24X, 'Joint Forces (', A4, ')',                           
     &          15X, 'Joint Torques (', 2A4, ')',                          
     &           9X, 'Relative Angular', /,                                
     &          '  Joint JTYPE', 9X, 'X', 10X, 'Y', 10X, 'Z', 13X,
     &          'X', 11X, 'Y', 11X, 'Z', 7X, 'Velocity (RAD/', A4, 
     &          ')', / )                                                  
!C
       DO J=1,NJNT
        DO I=1,3
         T4(I,J) = JNT(J)%JTORQUE(I)                                          
        END DO
       END DO
!C
       IF ( NRTORQ .GT. I_0 )   THEN                                  
        DO  J=1,NRTORQ                                                     
         JJ = ACT(J)%ACT_JNT                                                     
         NRS1 = JNT(JJ)%PROX_SEG                                           
         CALL DOT31 ( SEG(NRS1)%DIR_COS, ACT(J)%TOR_AXIS(1), T2_LCL )         
         TT = D_1                                                         
         IF ( NRS1 .NE. ACT(J)%BASE_SEG )  TT = -D_1                              
         DO  II=1,3                                                       
          T4(II,JJ) = T4(II,JJ) - TT * ACT(J)%ACT_TORQ * T2_LCL(II)            
         END DO
        END DO                                                             
       END IF
!C
       DO  J=1,NJNT                                                        
        IPINJ = JNT(J)%JTYPE                                                 
        IF  ( ABS ( JNT(J)%JTYPE ) .EQ. I_4 )  IPINJ = IEULER(J)               
        WRITE ( LUAOU, 170 )  J, JNT(J)%JNT_NAME, IPINJ, 
     &                       ( JNT(J)%JFORCE(K), K=1,3 ),
     &                       ( T4(K,J), K=1,3 ), WJ(J)                    
  170   FORMAT ( I3, 1X, A4, I4, 7X, 3( D10.3, 1X ), 3X, 
     &           3( D11.4, 1X ), 3X, F13.3 )                               
       END DO                                                              
      END IF
!C
!C    Output constraint info.
!C
      IF  ( NQ .GT. I_0 )  THEN                                       
       WRITE ( LUAOU, 175 )                                                
  175  FORMAT ( ///, ' Other Constraint Forces', / )                      
       WRITE ( LUAOU, 180 )                                            
  180  FORMAT ( 1X, 45X, '(Inertial)' )                                   
       WRITE ( LUAOU, 185 )  UNITM, UNITL                               
  185  FORMAT ( 1X, ' NO.  TYPE   SEG1  SEG2',                            
     &          15X, 'Constraint Force (', A4, ')',                        
     &          16X, 'Distance (', A4, ')', / )                           
!C
       ICH = I_0                                                        
       DO  J=1,NQ                                                           
        IF ( KQTYPE(J) .NE. I_5 )  ICH = I_0                             
        IF ( KQTYPE(J) .GE. I_0 )  THEN                                 
         IF ( KQTYPE(J) .EQ. I_5 )  ICH = ICH + I_1                   
         IF ( ICH .NE. I_2 )  THEN                                     
          M = KQ1(J)                                                        
          N = KQ2(J)                                                        
          CALL DOT31 ( SEG(M)%DIR_COS, RK1(1,J), T1 )                       
          CALL DOT31 ( SEG(N)%DIR_COS, RK2(1,J), T2_LCL )             
          HH = SEG(M)%LIN_DISP + T1 - SEG(N)%LIN_DISP - T2_LCL    
          SQS1 = VECMAG ( HH )                           
          WRITE ( LUAOU, 190 )  J, KQTYPE(J), SEG(M)%NAME, SEG(N)%NAME,
     &                    ( QQ(I,J), I=1,3 ), SQS1                         
  190     FORMAT ( I4, I6, 4X, A4, 2X, A4, 3X, 3G15.7, 6X, G15.7 )          
         END IF
        END IF
       END DO                                                               
      END IF
!C
      IF  ( NPRT(28) .LE. I_0 )    NPRT(28) = -I_1                      
!C
      RETURN                                                               
      END                                                                 
