      SUBROUTINE VSPLIN ( LPTS, LTYPE, LFIT, NPTS, MATAB,
     &                    AT0, ADT )                                      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                        
!C    This subroutine reads in vehicle data for Option 4 (spline-fit      
!C    vehicle data) from Cards C.5.  The input data are echoed and       
!C    then spline-fit to obtain linear and angular acceleration data      
!C    that are stored in the ATAB array.                                  
!C                                                                        
!C     Subroutines called by:  VINO34                                     
!C                                                                        
!C     Subroutines called:  SPLINE, QUAT, CROSS, DRCQUA, YPRDEG           
!C                                                                        
!C     Logical unit(s) read from/written to: 5, 6                         
!C                                                                       
!C     STOPS: 290, 291, 292, 293                                          
!C                                                                        
!C     Parameters used:   MAXTV4                                          
!C                                                                        
!C     Common block and passed variables altered:                       
!C            /CONTRL/:  NPG                                              
!C            /TEMPVS/:  X0, XDOT0, ANGLE, ATAB, DVEH, VMEG,             
!C                       F, XYZ, TT, SP, Q1, A1, W1, QD, QC              
!C                                                                        
!C     Common block and passed variables used but not altered:           
!C            /CNSNTS/:  RADIAN, G, UNTIL, UNITT                         
!C            /TITLES/:  VPSTTL                                          
!C              passed:  LPTS, LTYPE, LFIT, NPTS, MATAB, AT0, ADT        
!C                                                                        
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:
     &       G, RADIAN, UNITL, UNITT,              ! /CNSNTS/
     &       NPG,                                  ! /CONTRL/
     &       VPSTTL,                               ! /TITLES/
     &       ANGLE, ATAB, DVEH, VMEG, X0, XDOT0,   ! /VIN_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH,              ! parameters
     &       LUAIN, LUAOU, MAXVT4, LULIN,          ! parameters
     &       D_0, D_1, D_2, D_3, D_6,              ! parameters
     &       I_0, I_1, I_2, I_3, I_6, I_45,        ! parameters
     &       AIN_CONVERT, LIN_FLAG                 ! parameters
!C
      IMPLICIT  NONE
!C                                                                    
      INTEGER  ( KIND = INTEGER_STD )
     &           I, II, IMJ, IOFFST, IPAGE, J, K, K1, 
     &           L, LFIT, LPTS, LTYPE, MATAB, NPTS
!C
      REAL  ( KIND = IREAL_HIGH )
     &                   A1, ACC, ADT, AT0, CCC, DX, F_LCL, 
     &                   Q1, QC, QD, SP, TA, TB, TSV, TT, TTT, 
     &                   UNITS, W1, XYZ
      DIMENSION       A1(3), F_LCL(:,:), Q1(:,:), 
     &                QC(4), QD(4), SP(:,:,:), TT(:), 
     &                W1(4), XYZ(:,:)
      ALLOCATABLE     F_LCL, Q1, SP, TT, XYZ
!C
!C    Dimension the large allocatable arrays.
!C
      ALLOCATE   ( F_LCL(5,MAXVT4), Q1(MAXVT4,4), SP(5,MAXVT4,4),
     &             TT(MAXVT4+2), XYZ(MAXVT4+2,6) )
!C                                                                      
!C    For spline fit vehicle motion (Option 4), read data from            
!C     Cards C.5 and test time points to be sure that they are            
!C     greater than zero and increasing.                                  
!C                                                                        
      TSV = D_0                                                         
      DO  I=1,MAXVT4+2                                                  
       TT(I) = D_0                                                     
      END DO                                                            
      DO  I=1,LPTS                                                      
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  TT(I),(XYZ(I,J),J=1,6)                     
       ELSE
        READ  ( LUAIN, 100 )  TT(I),(XYZ(I,J),J=1,6)                     
  100   FORMAT ( 7F10.0 )                                                  
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 102 )  TT(I),(XYZ(I,J),J=1,6)                     
  102    FORMAT ( 1X, 7( F20.9, 1X ) )                                                  
        END IF
       END IF
!C
       IF ( TT(I) .LT. D_0 )  THEN                                       
        WRITE  ( LUAOU, 105 )  I, TT(I)                                   
  105   FORMAT ( 1X, 'TT(', I4, ') = ', F12.6, ' from Card C.5.', /,      
     &           ' Negative time points are not permitted.', // )         
        STOP ' STOP 290 in Subroutine VSPLIN'                            
       END IF                                                            
!C
       IF ( ( TT(I) .LE. TSV ) .AND. ( TT(I) .GT. D_0 ) )  THEN         
        WRITE ( LUAOU, 120 )   I, TT(I)                                   
  120   FORMAT ( 1X, 'T(', I4, ') = ', F12.6, ' From Card C.5.', /,       
     &           ' This value was less than or equal to the previous',    
     &           ' time point.',/,' Time points must be in ascending',    
     &           ' order for vehicle input option 4.', // )               
        STOP ' STOP 291 in Subroutine VSPLIN'                             
       END IF                                                             
       TSV = TT(I)                                                        
      END DO                                                              
!C                                                                     
!C     Enforce requirement that T(I) equal 0 for initial condition      
!C      cards.                                                          
!C                                                                      
       IF ( ( ( LTYPE .EQ. I_2 ) .OR. ( LTYPE .EQ. I_3 ) ) 
     &           .AND. ( TT(1) .NE. D_0 ) )   THEN                    
        WRITE ( LUAOU, 110 )  TT(1), LTYPE                              
  110   FORMAT ( 1X, 'A nonzero value for T(1), ', F12.6,
     &           ', was supplied when LTYPE = ', I4, '.', // )          
        STOP ' STOP 292 in Subroutine VSPLIN'                           
       END IF                                                           
C
       IF ( ( LTYPE .EQ. 3 ) .AND. ( TT(2) .NE. D_0 ) )  THEN           
        WRITE ( LUAOU, 115 )  TT(2)                                     
  115   FORMAT ( 1X, 'A nonzero value for T(2), ', F12.6,
     &           ', was supplied when LTYPE = 3.', // )                 
        STOP ' STOP 293 in Subroutine VSPLIN'                           
       END IF                                                           
!C                                                                      
!C    Print the control parameters.  Also, print the initial              
!C     conditions if the spline-fit data are velocity or acceleration     
!C     data.                                                              
!C                                                                       
      WRITE ( LUAOU, 125 )  LTYPE, LFIT, NPTS                            
  125 FORMAT ( '0 Spline-Fit Tabular Input', //,                          
     &         3X, 'LTYPE =', I6, '  LFIT =', I6, '  NPTS =', I6, / )     
      IF ( LTYPE .EQ. 2 )  THEN                                           
       WRITE ( LUAOU, 130 ) UNITL, ( XYZ(1,J), J=1,6 )                    
  130  FORMAT ( 32X , 'Initial Linear Position (', A4, ')', 17X,
     &          'Initial Angular Position (deg)', /, 21X,               
     &          'X=', F10.3, 2X, 'Y=', F10.3, 2X, 'Z=', F10.3, 8X,      
     &          'Yaw=', F10.3, 2X, 'Pitch=', F10.3, 2X, 'Roll=', F10.3 )
      ELSE IF ( LTYPE .EQ. 3 )  THEN                                      
       WRITE ( LUAOU, 135 )  UNITL, ( XYZ(1,J), J=1,6 ), UNITL, UNITT,
     &                       UNITT, ( XYZ(2,J), J=1,6 )                  
  135  FORMAT ( 32X, 'Initial Linear Position (', A4, ')', 17X,
     &          'Initial Angular Position (deg)', /, 21X,               
     &          'X=', F10.3, 2X, 'Y=', F10.3, 2X, 'Z=', F10.3, 8X,      
     &          'Yaw=', F10.3, 2X, 'Pitch=', F10.3, 2X, 'Roll=',
     &          F10.3, //, 30X, 'Initial Linear Velocity (', A4, '/',
     &          A4, ')', 12X, 'Initial Angular Velocity (deg/', A4, 
     &          ')', /, 26X, 
     &          2 ( 'X=', F10.2, 2X, 'Y=', F10.2, 2X, 
     &          'Z=', F10.2, 8X ), / )                                    
      END IF                                                              
!C                                                                        
!C     Print out input data with the beginning point dependent on         
!C      the type of input data.  Print heading at the top of each         
!C      page and 45 points per page.                                      
!C                                                                        
      DO 22 I=LTYPE,LPTS                                                  
!C                                                                        
!C     Print heading at the top of each page.                            
!C                                                                        
       IF ( LTYPE .EQ. I_1 ) THEN                                      
        IOFFST = I                                                        
       ELSE IF ( LTYPE .EQ. I_2 ) THEN                                  
        IOFFST = I - I_1                                               
       ELSE IF ( LTYPE .EQ. I_3 ) THEN                              
        IOFFST = I - I_2                                               
       END IF                                                             
       IF ( MOD ( IOFFST, I_45 ) .EQ. I_1 )  THEN                
        IPAGE = ( IOFFST - I_1 ) / I_45 + I_1                           
        WRITE ( LUAOU, 140 )  NPG                                         
  140   FORMAT ( '1', 122X, 'Page', I5 )                                  
        NPG = NPG + I_1                                                
        WRITE ( LUAOU, 145 )  VPSTTL, IPAGE                               
  145   FORMAT ( '0   Spline-Fit Input Data for: ', A80, 3X,           
     &           'Input Page No.', I3, // )                               
        IF ( LTYPE .EQ. I_1 )  THEN                                    
         WRITE ( LUAOU, 150 )  UNITL, UNITT                              
  150    FORMAT ( 29X, 'Linear Position (', A4, ')', 21X,
     &            'Angular Position (deg)',  /, 5X, 'Time(', A4, ')',
     &            11X, 'X', 11X, 'Y', 11X, 'Z', 18X, 'Yaw', 8X,
     &            'Pitch', 8X, 'Roll' )                                  
        ELSE IF ( LTYPE .EQ. I_2 )  THEN                                   
         WRITE ( LUAOU, 155 )  UNITL, UNITT, UNITT, UNITT                
  155    FORMAT ( 26X, 'Linear Velocity (', A4, '/', A4, ')', 16X,       
     &            'Angular Velocity (deg/', A4, ')', /, 5X, 'Time(',
     &            A4, ')', 11X, 2( 'X', 11X, 'Y', 11X, 'Z', 19X ) )       
        ELSE IF ( LTYPE .EQ. I_3 )  THEN                                   
         WRITE ( LUAOU, 160 )  UNITT, UNITT                               
  160    FORMAT ( 26X, 'Linear Deceleration (G''s)', 15X,                
     &            'Angular Acceleration (deg/', A4, '**2)', /,
     &            5X, 'Time(', A4, ')', 11X, 
     &            2( 'X', 11X, 'Y', 11X, 'Z', 19X ) )                     
        END IF                                                           
       END IF                                                             
!C                                                                        
!C     Print out the linear and angular input quantities.                 
!C                                                                       
       WRITE ( LUAOU, 165 )  TT(I), ( XYZ(I,J), J=1,6 )                   
  165  FORMAT ( 1X, F12.5, 6X, 3F12.3, 8X, 3F12.3 )                       
   22 CONTINUE                                                            
!C                                                                      
!C    The remainder of the subroutine spline-fits the input data          
!C     to obtain the vehicle's linear and angular accelerations as       
!C     a function of time.                                               
!C                                                                      
!C    Store the initial linear position, linear velocity, angular        
!C     displacement and angular velocity.                               
!C                                                                        
      DO  I=1,3                                                          
       X0(I)    = XYZ(1,I)                                                
       XDOT0(I) = XYZ(2,I)                                               
       ANGLE(I) = XYZ(1,I+3)                                             
       VMEG(I)   = XYZ(2,I+3)                                            
      END DO
!C                                                                        
!C    If the input data are displacement data, compute only the          
!C     linear deceleration in this section and the angular acceleration   
!C     in the following section.  Otherwise, compute both the linear      
!C     and angular accelerations in this section and then return to       
!C     Subroutine VINO34.                                                 
!C                                                                        
!C    Determine whether both linear and angular accelerations are to      
!C     be computed in this section or just linear decelerations.          
!C                                                                       
      IF ( LTYPE .EQ. I_1 )  THEN                                      
       IMJ = I_3                                                     
      ELSE                                                               
       IMJ = I_6                                                      
      END IF                                                              
!C                                                                      
!C    Compute the coefficients of the splines.                           
!C                                                                        
      DO 26 II=1,IMJ                                                      
       CALL SPLINE ( TT(LTYPE), XYZ(LTYPE,II), F_LCL, NPTS, LFIT )        
       I = II                                                            
       IF  ( II .GT. I_3 )  I = II + I_6                            
!C                                                                       
!C      Get the linear velocity from the spline if input data are         
!C       displacement data.                                               
!C                                                                        
       IF ( LTYPE .EQ. I_1 )   XDOT0(I) = F_LCL(3,1)                  
!C                                                                       
!C     Select linear units if input data are not deceleration data.       
!C                                                                       
       IF  ( ( LTYPE .LT. I_3 ) .AND. ( II .LE. I_3 ) )  THEN     
        UNITS = -D_1 / G                                                 
       ELSE                                                               
        UNITS = D_1                                                      
       END IF                                                             
!C                                                                       
!C     Compute the time step for interpolation of linear                  
!C      decelerations, and angular accelerations if input data are       
!C      not displacement data.                                            
!C                                                                       
       K1 = I_1                                                         
       DO  J=1,MATAB                                                      
        TTT = AT0 + REAL ( ( J - I_1 ), IREAL_HIGH ) * ADT                     
        DO  L=K1,NPTS-1                                                    
         K = L                                                            
         IF ( TTT .LT. F_LCL(1,L+1) )  EXIT                               
        END DO                                                           
        K1 = K                                                            
        DX = TTT - F_LCL(1,K)                                            
!C                                                                        
!C      Compute the acceleration by interpolation.  If input data are    
!C       displacement data then will only be for linear decelerations.    
!C       If velocity or acceleration data, the computation will be for    
!C       both linear and angular accelerations.                           
!C                                                                        
        IF ( LTYPE .EQ. I_1 )  THEN                                     
         ACC = D_2 * F_LCL(4,K) + D_6 * DX * F_LCL(5,K)                 
        ELSE IF ( LTYPE .EQ. I_2 )  THEN                              
         ACC =   F_LCL(3,K) 
     &         + DX * ( D_2 * F_LCL(4,K) + D_3 * DX * F_LCL(5,K) )     
        ELSE IF ( LTYPE .EQ. I_3 )  THEN                              
         ACC = F_LCL(2,K) + DX * ( F_LCL(3,K) 
     &                    + DX * ( F_LCL(4,K) + DX * F_LCL(5,K) ) )      
        END IF                                                            
        ATAB(I,J) = ACC * UNITS                                           
       END DO                                                            
   26 CONTINUE
!C                                                                        
!C    Return if input data are velocity or acceleration data since        
!C     both linear and angular accelerations have been computed.          
!C                                                                        
      IF ( LTYPE .NE. I_1 )  THEN                                       
!C     (gfortran port) release the work arrays on this early return too;
!C      with -fno-automatic they persist and the next vehicle's ALLOCATE fails.
       DEALLOCATE  ( F_LCL, Q1, SP, TT, XYZ )                          
       RETURN                                                           
      END IF                                                             
!C                                                                        
!C    If input data are displacement data, only the linear                
!C     decelerations have been computed so far.  Now compute the         
!C     angular accelerations.                                             
!C                                                                        
!C    Initialize rotational variables.                                   
!C                                                                        
      DO  I = 1,NPTS                                                      
       DO  K = 1,3                                                       
        A1(K) = XYZ(I,K+3)                                               
       END DO
       CALL QUAT ( A1, W1 )                                               
       DO  K = 1,4                                                        
        Q1(I,K) = W1(K)                                                  
       END DO
       IF ( I .NE. I_1 ) THEN                                           
        TA = D_0                                                       
        TB = D_0                                                      
        DO  K = 1,4                                                       
         TA = TA + ABS ( Q1(I,K) - Q1(I-1,K) )                            
         TB = TB + ABS ( Q1(I,K) + Q1(I-1,K) )                            
        END DO
        IF ( TA .GT. TB )  THEN                                           
         DO  K = 1,4                                                      
          Q1(I,K) = -Q1(I,K)                                             
         END DO
        END IF                                                           
       END IF                                                            
      END DO                                                              
!C                                                                        
!C    Compute the spline coefficients for the angular functions          
!C     when the input data are displacement data.                         
!C                                                                       
      DO  K = 1,4                                                        
       CALL SPLINE ( TT, Q1(1,K), SP(1,1,K), NPTS, LFIT )                 
      END DO
!C                                                                        
!C    Compute the time step for interpolation of the angular functions   
!C     when the input data are displacement data.                        
!C                                                                        
      DO 42 J = 1,MATAB                                                   
       TTT = AT0 + REAL ( ( J - I_1 ), IREAL_HIGH ) * ADT                   
       K1 = I_1                                                        
       DO  L = K1,NPTS                                                    
        K = L                                                           
        IF ( TTT .LT. SP(1,L+1,1) ) EXIT                                  
       END DO                                                             
       K1 = K                                                             
       DX = TTT - SP(1,K,1)                                               
!C                                                                       
!C     Interpolate for the quaternions (W1), the second time              
!C      derivative of the quaternions (QD), and, for the first point,     
!C      the first time derivative of the quaternions (QC).               
!C                                                                        
       DO  L = 1,4                                                        
        W1(L) = SP(2,K,L) + DX * ( SP(3,K,L) 
     &                    + DX * ( SP(4,K,L)
     &                    + DX *   SP(5,K,L) ) )                          
        QD(L) = D_2 * SP(4,K,L) + D_6 * DX * SP(5,K,L)                 
        IF ( J .EQ. I_1 )  THEN                                         
         QC(L) = SP(3,K,L) + DX * ( D_2   * SP(4,K,L)
     &                     + DX *   D_3 * SP(5,K,L) )                   
        END IF                                                            
       END DO                                                             
       CCC = D_2 / RADIAN                                               
!C                                                                       
!C     Compute the initial angular velocity , direction cosine matrix    
!C      and rotation angles for the vehicle when the vehicle input        
!C      data are displacements.                                          
!C                                                                      
       IF ( J .LE. I_1 ) THEN                                           
        CALL CROSS ( QC(2), W1(2), A1 )                                   
        DO  K = 1,3                                                       
         VMEG(K) = CCC * ( W1(1) * QC(K+1) - QC(1) * W1(K+1) + A1(K) )  
        END DO
        CALL DRCQUA ( DVEH, W1 )                                         
        CALL YPRDEG ( DVEH, ANGLE )                                       
       END IF                                                             
!C                                                                       
!C     Compute the angular accelerations of the vehicle from the          
!C      quaternions and their derivatives when the vehicle input data     
!C      are displacements.                                                
!C                                                                        
       CALL CROSS ( QD(2), W1(2), QC(2) )                                 
       DO  K = 2,4                                                        
        ATAB(K+8,J) = CCC * ( W1(1) * QD(K) - QD(1) * W1(K) + QC(K) )     
       END DO
   42 CONTINUE                                                            
!C
!C    Release the memory from the large arrays used by the subroutine.
!C
      DEALLOCATE  ( F_LCL, Q1, SP, TT, XYZ ) 
!C
      RETURN                                                              
      END                                                                 
