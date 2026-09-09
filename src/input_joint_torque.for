      SUBROUTINE INPUT_JOINT_TORQUE                                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the joint restoring torque ( force )
!C     functions specified on Cards E.7. 
!C                                                                   
!C
      USE  MODULE_STANDARD,   ONLY: 
     &       EPS, RADIAN,                                      ! /CNSNTS/
     &       NPG, NGRND, NJNTF,                                ! /CONTRL/
     &       MXTB1, NTI, TAB,                                  ! /TABLES/
     &       FUNC_TITLE,                                       ! /CINPUT_TEMPVS/
     &       SEG,                                              ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH, LUAIN, LUAOU, ! parameters
     &       I_1, I_0, I_2, I_3, I_4, I_50, LULIN, MAX_FUNC,   ! parameters
     &       D_0, D_1, D_2, D_180, LIN_FLAG, AIN_CONVERT       ! parameters
!C
!C    SEG%NAME
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, IERROR, J, J1, J1J, J2, JJ, JJ1, L,
     &           NPHI, NPOLY, NTHETA, MAX_THETA
      PARAMETER ( MAX_THETA = I_50 )
!C
      REAL  ( KIND = IREAL_HIGH )  PHIDEG, TH, THETA0
      DIMENSION         TH(MAX_THETA)
!C
      CHARACTER ( LEN =   4, KIND = ICHAR_STD )  BLANK_4
      CHARACTER ( LEN =  20, KIND = ICHAR_STD )  IN_TITLE, ATEMP20
      CHARACTER ( LEN =  22, KIND = ICHAR_STD )  ATEMP22
!C
      DATA   BLANK_4 / ICHAR_STD_'    ' /                     
!C
      J1 = MXTB1 + I_1                                                 
!C
!C    Continuous DO loop, exited when the last joint force
!C     function is encountered.
!C
      DO
!C                                                                       
!C     Input Card E.7.a - function no. and title                           
!C                                                                        
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  I, IN_TITLE                                  
       ELSE
        READ  ( LUAIN, 100 )  I, IN_TITLE                                  
  100   FORMAT ( I4, 4X, A20 )                                            
        IF ( AIN_CONVERT )  THEN
         ATEMP20 = ADJUSTL ( IN_TITLE )
         L = LEN_TRIM ( ATEMP20 )
         ATEMP22(1:L+2) = '"' // ATEMP20(1:L) // '"'       
         WRITE  ( LULIN, 105 )  I, ATEMP22(1:L+2), 'Card E.7.a'                                  
  105    FORMAT ( 1X, I4, 1X, A, 2X, A )                                            
        END IF
       END IF
!C
!C     Return if no more joint torque functions (I > MAX_FUNC )
!C
       IF ( I .GT. MAX_FUNC )  THEN                              
        MXTB1 = J1 - I_1                                                 
        RETURN
       END IF
!C
       WRITE ( LUAOU, 110 )   I, IN_TITLE, I, J1, NPG                     
       NPG = NPG + I_1                                                    
  110  FORMAT ( '1 Joint Force Function No.', I4, 4X, A20, 10X,
     &          'NTI(', I2, ') =', I5, 45X, 'Page', I5, /, 120X,
     &          'Cards E.7', / )                                            
!C
       IF ( I .LE. I_0 )  THEN
        WRITE ( LUAOU, 115)                          
  115   FORMAT ( '0 Improper function no. Program terminated.' )           
        STOP 12                                        
       END IF
!C
       IF ( NTI(I) .NE. I_0 )  WRITE ( LUAOU, 120 )   I                 
  120  FORMAT ( '0 Function no.', I4, 
     &          ' has already been inputted and will be replaced',        
     &          ' by this function.' )                                    
       NTI(I) = J1                                                       
       FUNC_TITLE(I) = IN_TITLE                                               
!C                                                                         
!C     Input Card E.7.b - D0, D1, D2, D3, D4 (for now a blank card).           
!C                                                                       
       J2 = J1 + I_4                                                    
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  ( TAB(J), J=J1,J2 )                            
       ELSE
        READ  ( LUAIN, 125 )  ( TAB(J), J=J1,J2 )                            
  125   FORMAT ( 6F12.0 )                                                  
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 130 )  ( TAB(J), J=J1,J2 ), 'Card E.7.b'                            
  130    FORMAT ( 1X, 5( E17.10, 1X ), 1X, A )                                                  
        END IF
       END IF
!C
       WRITE ( LUAOU, 135 )  ( TAB(J), J=J1,J2 )                           
  135  FORMAT ( 10X, 'D0', 13X, 'D1', 13X, 'D2', 13X, 'D3', 8X,
     &           'Ref. Segment', /, 5F15.4, // )                           
       J1 = J2 + I_1                                                      
!C                                                                         
!C     Input Card E.7.c - NTHETA,NPHI                                      
!C                                                                         
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  NTHETA, NPHI                                 
       ELSE
        READ  ( LUAIN, 140 )  NTHETA, NPHI                                 
  140   FORMAT( 2I6 )                                                     
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 145 )  NTHETA, NPHI, 'Card E.7.c'                                 
  145    FORMAT ( 1X, 2( I6, 1X ), 1X, A )                                                     
        END IF
       END IF
!C
!C     Test the supplied values of NTHETA and NPHI.
!C
       IF ( ABS ( NTHETA ) .LT. I_2 )  THEN
        WRITE ( LUAOU, 146 )  NTHETA
  146   FORMAT ( 1X, ' Magnitude of inputted NTHETA, ', I4, 
     &               ' must be 2 or greater. ' )
        STOP  ' STOP 121 in Subroutine INPUT_JOINT_TORQUE '
       END IF
       IF ( ABS ( NTHETA ) .GT. MAX_THETA )  THEN
        WRITE ( LUAOU, 147 )  NTHETA, MAX_THETA
  147   FORMAT ( 1X, ' Magnitude of inputted NTHETA, ', I4, 
     &               ' can not exceed , ', I4, '. ' )
        STOP  ' STOP 122 in Subroutine INPUT_JOINT_TORQUE '
       END IF
       IF ( NPHI .LE. I_0 )  THEN
        WRITE ( LUAOU, 148 ) NPHI
  148   FORMAT ( 1X, ' Supplied value for NPHI, ', I4, 
     &               ' must be greater than 0' ) 
        STOP  ' STOP 123 in Subroutine INPUT_JOINT_TORQUE '
       END IF
!C
       TAB(J1  ) = NTHETA                                                  
       TAB(J1+1) = NPHI                                                   
       J1 = J1 + I_2                                                    
       IF ( NTHETA .GE. I_0 )  THEN                                     
        DO  J=1,NTHETA                                                    
         TH(J) = REAL ( ( J - I_1 ), IREAL_HIGH ) * D_180 / 
     &           REAL ( ( NTHETA - I_1 ), IREAL_HIGH )  
        END DO
        WRITE ( LUAOU, 150 )  NTHETA, NPHI, ( TH(J), J=2,NTHETA )           
  150   FORMAT ( '0 Function is tabular for', I3, ' X', I3,
     &           ' values of THETA and PHI', //, 30X, 'THETA', /, 5X,
     &           'PHI', 5X, 'THETA0', F16.3, 4F20.3, /, 
     &           ( 15X, 5F20.3 ) )  
       ELSE
        NPOLY = -NTHETA - I_1                                           
        WRITE ( LUAOU, 155 )  NPOLY, NPHI, ( BLANK_4, J, J=1,NPOLY )        
  155   FORMAT( '0 Function is coefficients of', I3,
     &          ' order polynomials in (THETA-THETA0) for', I3,
     &          ' values of PHI.', //, 27X,
     &          'coefficients of (THETA-THETA0)**N', /, 5X, 'PHI',
     &          5X, 'THETA0', 7X, 5( A4, 'N =', I2, 11X ),
     &          /, ( 26X, A4, 'N =', I2, 11X, A4, 'N =', I2, 11X,
     &          A4, 'N =', I2, 11X, A4, 'N =', I2, 11X, A4,
     &          'N =',I2 ) )                                               
       END IF
!C
       WRITE ( LUAOU, 160 )                                              
  160  FORMAT ( 3X, F12.6, 3G20.6 )                                      
       DO  I=1,NPHI                                                      
        PHIDEG = REAL ( ( I - I_1 ), IREAL_HIGH ) * D_2 * D_180 / 
     &           REAL ( NPHI, IREAL_HIGH ) - D_180     
!C                                                                        
!C      Input Cards E.7.d NPHI sets with NTHETA items per set.             
!C         Each set I is for PHI(I) = -180 +(I-1)*360/NPHI degrees and     
!C         assumes data for PHI(NPHI+1) = 180 is same as PHI(1) = -180.    
!C                                                                         
        J2 = J1 + ABS ( NTHETA ) - I_1                                  
        IF ( LIN_FLAG )  THEN
         READ  ( LULIN, * ) ( TAB(J), J=J1,J2 )                         
        ELSE
         READ  ( LUAIN, 165 ) ( TAB(J), J=J1,J2 )                         
  165    FORMAT ( 6F12.0 )                                                  
         IF ( AIN_CONVERT )  THEN
          WRITE  ( LULIN, 170 ) ( TAB(J), J=J1,J2 )                         
  170     FORMAT ( 1X, 6( E17.10, 1X ) )                                                  
         END IF
        END IF
!C
        WRITE ( LUAOU,175)  PHIDEG,(TAB(J),J=J1,J2)                              
  175   FORMAT ( F9.2, F10.3, 5G20.7, /, ( 19X, 5G20.7 ) )               
!C
        IF ( NTHETA .LT. I_0 )  THEN
         TAB(J1) = TAB(J1) * RADIAN               
         J1 = J2 + I_1                                                    
         CYCLE
        END IF
!C                                                                        
!C      For tabular data, fill in zero values with interpolated negative  
!C      values. Overwrite value in first column (supplied as THETA0)   
!C      with value for THETA = 0 and all other zero values.                
!C                                                                        
        THETA0 = TAB(J1)                                                  
        IF ( THETA0 .NE. D_0 )  THEN                                     
         JJ = THETA0 * REAL ( ( NTHETA - I_1 ), IREAL_HIGH ) / 
     &        D_180 + D_1 + EPS(6)     
         JJ1 = J1 + JJ                                                     
         IERROR = I_0                                                   
         IF ( JJ1 .GT. J2 )       IERROR = I_1                          
         IF ( TAB(JJ1) .LE. D_0 ) IERROR = I_2                             
         IF ( IERROR .EQ. I_0 )   THEN                                  
          DO  J=1,JJ                                                      
           J1J = J1 + J - I_1                                            
           IF ( ( J .NE. I_1 ) .AND. 
     &          ( TAB(J1J) .GT. D_0 ) )  IERROR = I_3    
           TAB(J1J) = TAB(JJ1) * ( TH(J) - THETA0 ) /
     &                           ( TH(JJ+1) - THETA0 )  
          END DO
         END IF
         IF ( IERROR .NE. I_0 )  THEN
          WRITE ( LUAOU, 180 ) IERROR                                       
  180     FORMAT ( '0 Input error. Inconsistent value of ',
     &             'THETA0. IERROR =', I2, ' Program terminated.' )         
         END IF
         IF ( IERROR .NE. I_0 )   STOP 13                                
        END IF
        J1 = J2 + I_1                                                    
       END DO
!C
      END DO                                                         
!C
      END                                                                 
