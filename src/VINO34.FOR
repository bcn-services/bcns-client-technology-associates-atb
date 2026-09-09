      SUBROUTINE VINO34 ( NATAB, ADT, AT0, VTIME, VIPS,
     &                    NUMVEH_LCL, MSEG_LCL )                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                        
!C    This subroutine computes vehicle motion data for;                   
!C      Option 3: Omnidirectional linear and angular acceleration         
!C                tabular input (6 degrees-of-freedom vehicle motion),    
!C      Option 4: Spline fit omnidirectional linear and angular           
!C                acceleration tabular data.                              
!C                                                                        
!C    The resulting accelerations are integrated to obtain linear         
!C    and angular velocities and displacements which are then printed.   
!C                                                                        
!C    Comments in this subroutine refer to the linear and angular         
!C    accelerations, velocities and displacements.                      
!C                                                                      
!C    Subroutines called by:  INPUT_VEHICLE                               
!C                                                                        
!C    Subroutines called:  VSPLIN, VINTST, DSETD, YPRDEG, DRCYPR          
!C                                                                        
!C    STOPS:  270                                                         
!C                                                                        
!C    Common block and passed variables altered:                          
!C           /CONTRL/:  NPG                                               
!C           /TEMPVS/:  XDOT0, ATAB, DVEH, VMEG, VMEGD, XACOMP, AX,       
!C                      THET                                              
!C                                                                        
!C    Common block and passed variables used but not altered:             
!C           /CONTRL/:  NSEG, NGRND                                      
!C           /CNSNTS/:  RADIAN, G, UNITL, UNITT                          
!C           /TITLES/:  VPSTTL                                            
!C           /TEMPVS/:  X0, ANGLE                                         
!C             passed:  NATAB, ADT, AT0, VTIME, VIPS, NUMVEH            
!C                                                                        
!C                                                                       
      USE MODULE_STANDARD,  ONLY:
     &      G, RADIAN, UNITL, UNITT,                         ! /CNSNTS/
     &      NPG,                                             ! /CONTRL/
     &      VPSTTL,                                          ! /TITLES/
     &      ANGLE, ATAB, AX, DVEH, VMEG, VMEGD,              ! /VIN_TEMPVS/
     &      X0, XACOMP, XDOT0,                               ! /VIN_TEMPVS/
     &      INTEGER_STD, IREAL_HIGH, LUAIN, LUAOU, LULIN,    ! parameters
     &      D_0, D_2, D_6, D_1000, I_0, I_1, I_2, I_3, I_45, ! parameters
     &      AIN_CONVERT, LIN_FLAG
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &          I, IDYPR, ISKIP, J, LFIT, LPTS, LTYPE, 
     &          MATAB, MSEG_LCL, NATAB, NPTS, NUMVEH_LCL 
      DIMENSION IDYPR(3)                                                
!C
      REAL  ( KIND = IREAL_HIGH )
     &                ADT, AT0, T1, THET, THT, VIPS, VTIME
      DIMENSION         THET(3)
!C
      DATA IDYPR / I_3, I_2, I_1 /                                
!C                                                                        
!C    For omnidirectional (6 degrees-of-freedom) vehicle motion,          
!C    read Card C.2.b for both Option 3 and Option 4.                     
!C                                                                        
      MATAB = -NATAB                                                      
      IF ( LIN_FLAG )  THEN
       READ ( LULIN, * )   LTYPE, LFIT, NPTS, ( VMEG(I), I=1,3 )        
      ELSE
       READ ( LUAIN, 100 )   LTYPE, LFIT, NPTS, ( VMEG(I), I=1,3 )        
  100  FORMAT ( 3I6, 22X, 3F10.0 )                                         
       IF ( AIN_CONVERT )  THEN
        WRITE ( LULIN, 102 )   LTYPE, LFIT, NPTS, ( VMEG(I), I=1,3 ),
     &                         'Card C.2.b'        
  102   FORMAT ( 1X, 3( I6, 1X ), 1X, 3( F20.9, 1X ), 1X, A )                                         
       END IF
      END IF
!C
      IF ( ( LTYPE .LT. I_0 ) .OR. ( LTYPE .GT. I_3 ) )  THEN      
       WRITE ( LUAOU, 105 )  LTYPE                                       
  105  FORMAT ( 1X, 'LTYPE =', I4, 
     &          ' from Card C.2.b is not permitted for',                  
     &          ' vehicle input option 3 or 4.', // )                     
       STOP ' STOP 270 in Subroutine VINO34.'                            
      END IF                                                              
!C                                                                        
!C    Read tabular linear deceleration and angular acceleration           
!C    data for Option 3 from Cards C.4 or if Option 4 is desired,         
!C    call Subroutine VSPLIN to read in Cards C.5 and spline-fit          
!C    the data.                                                           
!C                                                                        
      IF ( LTYPE .LE. I_0 )  THEN                                      
!C                                                                        
!C     Perform checks on input data for Option 3.                         
!C                                                                        
       CALL VINTST ( 3, AT0, ADT, VTIME, NATAB, NUMVEH_LCL,
     &               LTYPE, LFIT, NPTS, VIPS )                            
       IF ( LIN_FLAG )  THEN
        DO J = 1, MATAB
         READ ( LULIN, * )  ( ATAB(I,J), I=1,3 ),
     &                      ( ATAB(I,J), I=10,12 )
        END DO             
       ELSE
        READ ( LUAIN, 110 )  ( ( ATAB(I,J), I=1,3 ),
     &                     ( ATAB(I,J), I=10,12 ), J=1,MATAB )             
  110   FORMAT ( 10X, 6F10.0 )                                             
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 112 )  ( ( ATAB(I,J), I=1,3 ),
     &                        ( ATAB(I,J), I=10,12 ), J=1,MATAB )             
  112    FORMAT ( 1X, 6( F20.9, 1X ) )                                             
        END IF
       END IF
       ISKIP = I_0                                                     
      ELSE                                                                
!C                                                                        
!C     Test logic of input data for Option 4.                             
!C                                                                        
       CALL VINTST ( 4, AT0, ADT, VTIME, NATAB, NUMVEH_LCL,
     &               LTYPE, LFIT, NPTS, VIPS )                            
!C                                                                        
!C     Read in data from Cards C.5 and spline-fit data for Option 4.      
!C                                                                        
       LPTS = LTYPE - I_1 + NPTS                                        
       CALL VSPLIN ( LPTS, LTYPE, LFIT, NPTS, MATAB, AT0, ADT )          
       ISKIP = I_1                                                     
      END IF                                                             
!C                                                                        
!C    Integrate the linear deceleration data (either read from            
!C    Cards C.4 or computed from Cards C.5) to obtain linear              
!C    velocities and displacements.  Then print the linear                
!C    accelerations, velocities and displacements on logical unit 6.      
!C                                                                       
      DO 20  J=1,MATAB                                                   
       IF ( MOD ( J, I_45 ) .EQ. I_1 )  THEN                      
!C                                                                        
!C      Print page heading for linear output at the start of              
!C      each 45 time points.                                              
!C                                                                        
        IF ( ISKIP .EQ. I_1 )  THEN                                   
         WRITE ( LUAOU, 115 )  NPG                                        
  115    FORMAT ( '1', 122X, 'Page', I5 )                                 
         NPG = NPG + I_1                                                
        END IF                                                            
        WRITE ( LUAOU, 120 )  VPSTTL, MSEG_LCL, UNITL, UNITT, UNITL       
  120   FORMAT ( '0  Vehicle Linear Time History', 3X, A80, 3X,          
     &           'MSEG =', I3, //,                                        
     &           4X, 'Time', 12X, 'Linear Decelerations (G''s)',          
     &           11X, 'Linear Velocities (', A4, '/', A4, ')',           
     &           11X, 'Linear Displacements (', A4, ')', /,               
     &           3X, '(msec)', 
     &           3( 11X, 'X', 11X, 'Y', 11X, 'Z', 3X ), / )              
        ISKIP = I_1                                                      
       END IF                                                             
!C                                                                        
!C    Initialize vehicle linear integration parameters with I.C.         
!C                                                                        
       IF ( J .LE. I_1 )  THEN                                           
        AX = D_0
        DO  I=1,3                                                         
         ATAB(I+6,J) = X0(I)                                              
         ATAB(I+12,J) = VMEG(I)                                           
        END DO
        CALL DRCYPR ( DVEH, ANGLE, IDYPR )                                
        DO  I=1,3                                                        
!C                                                                        
!C       Set the initial linear velocity of the vehicle equal to a        
!C       velocity vector in the x direction of the vehicle with a         
!C       magnitude of VIPS for vehicle input Option 3.                    
!C                                                                       
         IF ( LTYPE .EQ. I_0 )   XDOT0(I) = VIPS * DVEH(1,I)           
         ATAB(I+3,J) = XDOT0(I)                                          
        END DO
       ELSE                                                               
!C                                                                        
!C      Integrate linear deceleration to obtain linear velocity and       
!C      linear displacement.                                              
!C                                                                       
        DO  I=1,3                                                         
         ATAB(I+3,J) =   ATAB(I+3,J-1) - G * ADT 
     &                 / D_2 *( ATAB(I,J-1) + ATAB(I,J) )              
         ATAB(I+6,J) =   ATAB(I+6,J-1)                                    
     &                 + ADT * (ATAB(I+3,J-1) - G * ADT
     &                 / D_6 * ( D_2 * ATAB(I,J-1) + ATAB(I,J) ) )        
        END DO
       END IF                                                           
       T1 = ( AT0 + REAL ( ( J - I_1 ), IREAL_HIGH ) * ADT )
     &           * D_1000     
!C                                                                       
!C      Print time and linear deceleration, velocity and displacement.    
!C                                                                        
       WRITE  ( LUAOU, 125 ) T1, ( ATAB(I,J), I=1,9 )                     
  125  FORMAT ( F9.3, 3( 3X, 3F12.3 ) )                                   
   20 CONTINUE                                                            
!C                                                                        
!C    Print out page headings and integrate angular acceleration          
!C    to obtain angular velocity and angular displacement, then print     
!C    angular acceleration, angular velocity and angular displacement.    
!C    The angular acceleration data comes either from Cards C.4 (Option   
!C    3) or spline-fit from Cards C.5 (Option 4).                         
!C                                                                        
      DO 28 J=1,MATAB                                                     
       IF ( MOD ( J, I_45 ) .EQ. I_1 )  THEN                      
!C                                                                        
!C       Print page heading for angular output at the start of          
!C       each 45 time points.                                             
!C                                                                        
        WRITE ( LUAOU, 130 )  VPSTTL, NPG, MSEG_LCL, UNITT, UNITT         
        NPG = NPG + I_1                                                 
  130   FORMAT ( '1 Vehicle Angular Time History', 3X, A80, 10X,
     &           'Page',I5, /, 116X, 'MSEG =', I3, /,                     
     &           4X, 'Time', 7X, 'Angular Accelerations (deg/',
     &           A4, '**2)', 7X, 'Angular Velocities (deg/', A4, ')',     
     &           11X, 'Angular Displacements (deg)', /, 3X,
     &           '(msec)', 2( 11X, 'X', 11X, 'Y', 11X, 'Z', 3X ),        
     &           10X, 'Yaw', 8X, 'Pitch', 8X, 'Roll', / )                 
       END IF                                                             
!C                                                                        
!C     Integrate angular acceleration to obtain angular velocity and      
!C     angular displacement.                                            
!C                                                                       
       IF ( J .NE. I_1 ) THEN                                           
        DO  I=1,3                                                         
         ATAB(I+12,J) = ATAB(I+12,J-1) + ( ATAB(I+9,J-1) + ATAB(I+9,J) )
     &                  * ADT / D_2                                      
         THET(I) = ADT * ( ATAB(I+12,J-1) 
     &             + ( D_2 * ATAB(I+9,J-1) + ATAB(I+9,J) ) *   
     &             ADT / D_6 ) * RADIAN                                  
        END DO
        CALL DSETD ( DVEH, THET, THT )                                    
       END IF                                                             
       CALL YPRDEG ( DVEH, THET )                                         
       T1 = ( AT0 + REAL ( ( J - I_1 ), IREAL_HIGH ) * ADT ) 
     &           * D_1000     
!C                                                                        
!C     Print time and angular acceleration, velocity and displacement.    
!C                                                                       
       WRITE ( LUAOU, 125 )  T1, ( ATAB(I,J), I=10,15 ), THET              
   28 CONTINUE                                                           
!C                                                                        
!C    Compute initial direction cosine matrix of vehicle.                 
!C                                                                       
      CALL DRCYPR ( DVEH, ANGLE, IDYPR )                                  
!C                                                                       
!C    Store the initial linear deceleration, angular velocity and         
!C    angular acceleration.                                               
!C                                                                       
      DO  I=1,3                                                           
       XACOMP(I) = -G * ATAB(I,1)                                        
       VMEG(I)  = ATAB(I+12,1) * RADIAN                                   
       VMEGD(I) = ATAB(I+9 ,1) * RADIAN                                   
      END DO
!C
      RETURN                                                              
      END                                                                 
