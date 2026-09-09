      SUBROUTINE VINO12 ( NATAB, OMEG, ADT, AT0, VTIME, VIPS,             
     &                    NUMVEH_LCL )                                     
!C
!C                                                   Rev. V.3 012/15/2002 
!C
!C    This subroutine computes vehicle motion data for;                   
!C     Option 1: D_HALF Sine-wave linear deceleration impulse,           
!C     Option 2: Unidirectional linear and angular acceleration           
!C               tabular input.                                           
!C                                                                        
!C     Subroutines called by:  INPUT_VEHICLE                              
!C                                                                        
!C     Subroutines called:  VINTST                                        
!C                                                                        
!C     STOPS: none                                                        
!C                                                                        
!C     Common block and passed variables altered:                         
!C           /TEMPVS/: AX, XACOMP, XDOT0, ATAB, DVEH, VMEGD, VMEG         
!C                                                                        
!C     Common block and passed variables used but not altered:            
!C           /CNSNTS/: G, PI, RADIAN, UNITL, UNITT                        
!C           /TEMPVS/: ANGLE                                              
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:
     &       G, PI, RADIAN, UNITL, UNITT,                        ! /CNSNTS/
     &       ANGLE, ATAB, AX, DVEH, VMEG, VMEGD, XACOMP, XDOT0,  ! /VIN_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH, LUAIN, LUAOU, LULIN,       ! parameters
     &       D_0, D_HALF, D_1, D_3, D_4, D_5, D_8, D_12, D_1000, ! parameters
     &       I_0, I_1, I_2, I_50, AIN_CONVERT, LIN_FLAG          ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IREM, J, NATAB, NUMVEH_LCL
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ADT, AT, AT0, DA1, DA2, 
     &                  F1_LCL, F2, F3, OMEG, T1, T2, UNITS,
     &                  VIPS, VTIME
!C
      INTENT (    IN )  ADT, AT0, NUMVEH_LCL
      INTENT (   OUT )  OMEG
      INTENT ( INOUT )  NATAB, VIPS, VTIME
!C                                                                      
!C    Compute vehicle orientation.                                        
!C                                                                        
      DA1 = ANGLE(1) * RADIAN                                             
      DA2 = ANGLE(2) * RADIAN                                             
      AX(3) = COS ( DA2 )                                                 
      AX(1) = COS ( DA1 ) * AX(3)                                         
      AX(2) = SIN ( DA1 ) * AX(3)                                         
      AX(3) = SIN ( DA2 )                                                
!C                                                                        
!C    D_HALF-sine wave deceleration (Option 1).                        
!C                                                                       
      IF ( NATAB .EQ. I_0 )  THEN                                      
!C                                                                        
!C     Perform Option 1 specific tests on input data.                     
!C                                                                        
       CALL VINTST ( 1, AT0, ADT, VTIME, NATAB, NUMVEH_LCL, 
     &               I_0, I_0, I_0, VIPS )                      
!C                                                                        
!C     Compute Option 1 coefficients.                                     
!C                                                                        
       OMEG = PI / VTIME                                                 
       AT = D_HALF * VIPS / OMEG                                            
       IF ( VIPS .LT. D_0 ) VIPS = D_0                                 
!C                                                                        
!C     Compute initial linear deceleration, initial linear velocity       
!C     and the components of the magnitude of the deceleration for        
!C     Option 1.                                                          
!C                                                                        
       XACOMP = D_0                                                    
       XDOT0 = VIPS * AX                                                  
       AX = AT * AX                                                       
       WRITE ( LUAOU, 100 )  VIPS, UNITL, UNITT, ANGLE, VTIME, UNITT      
  100  FORMAT ( '0 Passenger Compartment Displacement History', /,        
     &          '  Analytical Half-Sine Wave Deceleration', /,         
     &          '  V0=', F8.3, 1X, A4, '/', A4, 
     &          ', Oblique Angles =', 3F7.2,                              
     &          ' Degrees, Time Duration =', F7.3, 1X, A4, // )           
!C                                                                        
!C     If NATAB is postive, vehicle input data is for Option 2,           
!C     unidirectional vehicle motion.                                     
!C                                                                        
      ELSE IF ( NATAB .GT. I_0 )  THEN                                
!C                                                                        
!C     Perform Option 2 specific tests on input data.                     
!C                                                                        
       CALL VINTST ( 2, AT0, ADT, VTIME, NATAB, NUMVEH_LCL,
     &               I_0, I_0, I_0, VIPS )                       
!C                                                                        
!C    For unidirectional vehicle motion, (Option 2),                      
!C    read linear deceleration tables from Cards C.3.                     
!C                                                                        
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( ATAB(1,I), I=1,NATAB )                   
       ELSE
        READ ( LUAIN, 105 )  ( ATAB(1,I), I=1,NATAB )                   
  105   FORMAT ( 12F6.0 )                                                
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 106 )  ( ATAB(1,I), I=1,NATAB )                   
  106    FORMAT ( 1X, 12( F15.7, 1X ) )                                                
        END IF
       END IF
!C                                                                        
!C     Extend table if necessary such that NATAB is odd and               
!C     last entry need not be zero.  If table size is exceeded on time,   
!C     the value of the last entry will be used.                          
!C                                                                        
       IREM = MOD ( NATAB, I_2 )                                
       IF ( IREM .NE. I_1 ) THEN                                        
        ATAB(1,NATAB+1) = ATAB(1,NATAB)                                   
        NATAB = NATAB + I_1                                             
       END IF                                                             
       VTIME = ADT * REAL ( ( NATAB - I_1 ), IREAL_HIGH )                    
!C                                                                        
!C      Using Simpson's integration, compute velocity and displacement    
!C      table for NATAB equally spaced (ADT) time points.                 
!C      For I=1,NATAB                                                     
!C        ATAB(1,I) = Linear deceleration (G's)                           
!C        ATAB(2,I) = Linear velocity (L Units/T Units)                   
!C        ATAB(3,I) = Linear displacement (L Units)                       
!C                                                                        
       ATAB(2,1) = VIPS                                                  
       ATAB(3,1) = D_0                                                   
       DA1 = ADT / D_3                                                 
       DA2 = ADT / D_12                                                 
       UNITS = -G                                                         
       DO  J=2,3                                                          
        DO  I=2,NATAB,2                                                   
         F1_LCL = ATAB(J-1,I-1) * UNITS                                   
         F2     = ATAB(J-1,I  ) * UNITS                                   
         F3     = ATAB(J-1,I+1) * UNITS                                   
         ATAB(J,I)  =   ATAB(J,I-1) 
     &                + DA2 * ( D_5 * F1_LCL + D_8 * F2 - F3)          
         ATAB(J,I+1) =  ATAB(J,I-1) 
     &                + DA1 * (    F1_LCL + D_4 * F2 + F3)              
        END DO
        UNITS = D_1                                                       
       END DO
!C                                                                        
!C     Print table of time points, acceleration, velocity and             
!C     position for Option 2.                                             
!C                                                                        
       WRITE ( LUAOU, 110 )  ( UNITL, UNITT, UNITL, I=1,2 )               
  110  FORMAT ( '0 Unidirectional Vehicle Position Tables', //,           
     &    2( '      Time       Acc      Velocity     Position   ' ), /,   
     &    2( '     (msec)      (G)    (', A4, '/', A4, ')',
     &       5X, '(', A4, ')', 4X ), / )                                  
!C                                                                        
!C     If there are 50 or fewer time points, print one column.  If        
!C     there are more than 50 time points, print two columns.             
!C                                                                        
       DO  J=1,50                                                         
        IF ( J .LE. NATAB )  THEN                                         
         T1 = ( AT0 + REAL ( ( J - I_1 ), IREAL_HIGH ) * ADT )
     &                   * D_1000  
         IF ( ( J + I_50 ) .GT. NATAB ) THEN                   
          WRITE ( LUAOU, 115 )  T1, ( ATAB(I,J), I=1,3 )                  
  115     FORMAT ( 2( F11.5, F10.2, F13.4, F13.5, 3X ) )                  
         ELSE                                                             
          T2 = ( AT0 + 
     &           REAL ( ( J + 49_INTEGER_STD ), IREAL_HIGH ) * ADT )
     &                                                 * D_1000     
          WRITE ( LUAOU, 115 ) T1, ( ATAB(I,J), I=1,3 ), T2,
     &                        ( ATAB(I,J+50), I=1,3 )                     
         END IF                                                           
        END IF                                                            
       END DO                                                             
!C                                                                        
!C     Compute initial linear acceleration and velocity for Option 2.     
!C                                                                        
       XACOMP = -G * AX * ATAB(1,1)                                      
       XDOT0  = VIPS * AX                                                 
!C
!C    End of Option 2 IF block.                                          
!C
      END IF                                                              
!C                                                                       
!C    Initialize vehicle direction cosine matrix, angular acceleration    
!C    and angular velocity for either Option 1 or 2.                      
!C                                                                        
      DVEH = D_0
      DO  I=1,3                                                           
       DVEH(I,I) = D_1                                                   
      END DO
      VMEGD  = D_0                                                      
      VMEG   = D_0                                                      
!C
      RETURN                                                              
      END                                                                 
