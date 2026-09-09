      SUBROUTINE VEHPOS                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes components of vehicle accelerations only as a function    
!C    of time using data and tables produced by Subroutine VINPUT.        
!C                                                                        
!C    Subroutines called: CROSS, DOT31, MAT31                             
!C   
!C    Called by Subroutines INPUT_INITIAL_CONDITIONS and DAUX_SETUP.
!C                                                                         
!C    Logical unit(s) read from/written to: none                          
!C                                                                         
!C    STOPS: none                                                          
!C                                                                         
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &        G, RADIAN,                                      ! /CNSNTS/
     &        NGRND, TIME,                                    ! /CONTRL/
     &        NUMVEH,                                         ! /VPOSTN/
     &        SEG, VEH,                                       ! structures
     &        INTEGER_STD, IREAL_HIGH, MAXSEG,                ! parameters
     &        I_0, I_1, I_2, I_8, D_0, D_HALF, D_1, D_2       ! parameters
!C
!C    ANG_ACCEL, ANG_VEL, DIR_COS, LIN_ACCEL, LIN_DISP, LIN_VEL    SEG%
!C    IVFLG, IVSEG, IVREF, LIN_DATA, ANG_DATA, VOMEGA, TIMEV,      VEH% 
!C    VINIT_TIME, VDELTA_TIME, NUM_VTAB, VNORMAL                   VEH%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, I1, I2, I3, J, M, NATAB
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AC0, ADT, AT0, AW, AX, DLT, OMEG, 
     &                  R1, R2, RISGLA, RIWMGD, RLDISP, RSEGLA, 
     &                  RLVEL, RWMEGD, SWT, T, TJ, VTIME, 
     &                  WGDXRD, WGXXRD, WIMGD, WIMGDV, WMGI, WMGIV, 
     &                  WMGXRD, WMGXRV, WT, WMXWM, X1, X3, XK
!C
      DIMENSION         AX(3), RISGLA(3), RIWMGD(3), RLDISP(3), 
     &                  RSEGLA(3,MAXSEG), RLVEL(3), RWMEGD(3,MAXSEG),
     &                  WGDXRD(3), WGXXRD(3), WIMGD(3), WIMGDV(3),
     &                  WMGI(3), WMGIV(3), WMGXRD(3), WMGXRV(3),
     &                  WMXWM(3)
!C
      T = TIME                                                            
!C                                                                         
!C    Compute the relative linear and angular acceleration for each        
!C    vehicle.                                                             
!C                                                                         
      DO 20 M=1,NUMVEH                                                     
!C                                                                         
!C     Get parameters for vehicle M.                                       
!C                                                                         
       DO  I=1,3                                                           
        AX(I) = VEH(M)%VNORMAL(I)                                                  
       END DO
       I2    = VEH(M)%IVSEG                                                 
       AT0   = VEH(M)%VINIT_TIME                                                        
       ADT   = VEH(M)%VDELTA_TIME                                                       
       VTIME = VEH(M)%TIMEV                                               
       NATAB = VEH(M)%NUM_VTAB                                                    
!C                                                                         
!C     Half-sine wave deceleration (option 1).                          
!C                                                                         
       IF ( NATAB .EQ. I_0 )  THEN                                     
        OMEG  = VEH(M)%VOMEGA                                                   
        IF ( T .GT. VTIME )  T = VTIME                                     
        WT = OMEG * T                                                    
        SWT = SIN ( WT )                                                   
        DO  I=1,3                                                          
         AW = AX(I) * OMEG                                                 
         RSEGLA(I,I2) = -AW * OMEG * SWT                                   
         RWMEGD(I,I2) = D_0                                            
        END DO
!C                                                                        
!C      Unidirectional deceleration (option 2).                           
!C                                                                        
       ELSE IF ( NATAB .GT. I_0 ) THEN                                 
        IF ( T .LT. VTIME )  THEN                                         
!C                                                                         
!C       Use quadratic interpolation from tables for current value of      
!C       time to be consistent with Simpson integration of tables.         
!C                                                                         
         J = D_HALF * ( T - AT0 ) / ADT + D_1                               
         XK = T / ADT - REAL ( ( I_2 * J - I_1 ), IREAL_HIGH )           
         X1 = XK + D_1                                                    
         X3 = XK - D_1                                                    
         AC0 = D_HALF * XK * X3 * VEH(M)%LIN_DATA(1,2*J-1)                       
     &       -          X3 * X1 * VEH(M)%LIN_DATA(1,2*J  )                        
     &       + D_HALF * XK * X1 * VEH(M)%LIN_DATA(1,2*J+1)                        
        ELSE                                                               
!C                                                                        
!C      Time point exceeds table, use last values of acceleration.        
!C                                                                         
         AC0 = VEH(M)%LIN_DATA(1,NATAB)        
        END IF                                                             
!C                                                                        
!C      Components of vehicle acceleration for option 2.                  
!C                                                                         
        DO  I=1,3                                                         
         RSEGLA(I,I2) = -G * AX(I) * AC0                                  
         RWMEGD(I,I2) = D_0                                            
        END DO
       ELSE                                                                
!C                                                                         
!C      Omnidirectional deceleration (options 3 and 4).                   
!C                                                                        
        J = ( TIME - AT0 ) / ADT + D_1                                   
        IF ( J .LT. -NATAB ) THEN                                          
!C                                                                       
!C       Linear interpolation from VINPUT tables of components             
!C       of vehicle linear and angular acceleration.                       
!C                                                                         
         TJ  = AT0 + REAL ( ( J - I_1 ), IREAL_HIGH ) * ADT                
         DLT = TIME - TJ                                                  
         R1  = DLT / ADT                                                  
         R2  = D_1 - R1                                                   
         DO  I=1,3                                                    
          RSEGLA(I,I2) =  -G * ( VEH(M)%LIN_DATA(I,J+1) * R1 
     &                         + VEH(M)%LIN_DATA(I,J  ) * R2 )        
          RWMEGD(I,I2) = RADIAN * ( VEH(M)%ANG_DATA(I,J+1) * R1
     &                            + VEH(M)%ANG_DATA(I,J  ) * R2 )      
         END DO
        ELSE                                                              
!C                                                                         
!C       Time point exceeds table, use last values of acceleration.       
!C                                                                         
         J = - NATAB                                                       
         DO  I=1,3                                                        
          RSEGLA(I,I2) =    -G  * VEH(M)%LIN_DATA(I,J)  
          RWMEGD(I,I2) = RADIAN * VEH(M)%ANG_DATA(I,J)  
         END DO
        END IF                                                            
       END IF                                                             
   20 CONTINUE                                                            
!C                                                                        
!C    Compute the absolute acceleration of each vehicle.                  
!C                                                                         
      DO 32 M=1,NUMVEH                                                    
       I1 = ABS ( VEH(M)%IVFLG )                                          
       I2 = VEH(M)%IVSEG                                                   
       I3 = VEH(M)%IVREF                                                 
!C                                                                         
!C     If I1 = 0 or I3 = NGRND, the relative accelerations are equal       
!C     to the absolute accelerations.  Equate and skip to the next         
!C     vehicle.                                                            
!C                                                                         
       IF ( ( I1 .EQ. I_0 ) .OR. ( ( I1 .EQ. I_2 ) .AND.
     &                                ( I3 .EQ. NGRND ) ) )   THEN     
        DO  I=1,3                                                         
         SEG(I2)%LIN_ACCEL(I) = RSEGLA(I,I2)                           
         SEG(I2)%ANG_ACCEL(I) = RWMEGD(I,I2)                        
        END DO
       ELSE                                                               
!C                                                                        
!C      Compute the relative displacement and velocity in inertial        
!C      coordinates.                                                      
!C                                                                      
        RLVEL = SEG(I2)%LIN_VEL - SEG(I3)%LIN_VEL
        RLDISP = SEG(I2)%LIN_DISP - SEG(I3)%LIN_DISP               
!C                                                                         
!C      Compute the various angular velocity cross product terms           
!C      in inertial coordinates.                                           
!C                                                                        
        CALL DOT31 ( SEG(I2)%DIR_COS, SEG(I2)%ANG_VEL, WMGIV )                 
        CALL DOT31 ( SEG(I3)%DIR_COS, SEG(I3)%ANG_VEL, WMGI )                
        CALL CROSS ( WMGI, RLDISP, WMGXRD )                               
        CALL CROSS ( WMGI, WMGXRD, WGXXRD )                                
!C                                                                       
!C      Subtract off the w x r term from the relative linear velocity    
!C                                                                        
        RLVEL = RLVEL - WMGXRD                                 
        CALL CROSS ( WMGI, RLVEL, WMGXRV )                               
!C                                                                         
!C      Compute the relative acceleration in inertial coordinates          
!C      and convert the vehicle relative angular acceleration from         
!C      principal to inertial coordinates.  Also, reverse the             
!C      relative quantities if they were supplied with respect             
!C      to the vehicle rather than the reference segment.                 
!C                                                                        
        IF ( I1 .EQ. I_1 )  THEN                                         
         CALL DOT31 ( SEG(I2)%DIR_COS, RSEGLA(1,I2), RISGLA )             
         CALL DOT31 ( SEG(I2)%DIR_COS, RWMEGD(1,I2), RIWMGD )            
         RISGLA = -RISGLA                                           
         RIWMGD = -RIWMGD                                           
        ELSE IF ( I1 .EQ. I_2 ) THEN                                    
         CALL DOT31 ( SEG(I3)%DIR_COS, RSEGLA(1,I2), RISGLA )            
         CALL DOT31 ( SEG(I3)%DIR_COS, RWMEGD(1,I2), RIWMGD )            
        END IF                                                             
!C                                                                         
!C      Compute the angular acceleration of the vehicle with respect     
!C      to the inertial coordinate system in inertial coordinates.        
!C                                                                        
        CALL CROSS ( WMGI, WMGIV, WMXWM )                                  
        CALL DOT31 ( SEG(I3)%DIR_COS, SEG(I3)%ANG_ACCEL, WIMGD )              
        WIMGDV = WIMGD + RIWMGD + WMXWM                       
!C                                                                         
!C      Transform vehicle angular acceleration from inertial to            
!C      principal coordinates and save.                                   
!C                                                                         
        CALL MAT31 ( SEG(I2)%DIR_COS, WIMGDV, SEG(I2)%ANG_ACCEL )                
!C                                                                        
!C      Compute the total acceleration of the vehicle in inertial          
!C      coordinates and save.                                              
!C                                                                         
        CALL CROSS ( WIMGD, RLDISP, WGDXRD )                               
        SEG(I2)%LIN_ACCEL = SEG(I3)%LIN_ACCEL + WGDXRD + WGXXRD +       
     &                      D_2 * WMGXRV + RISGLA                        
       END IF                                                          
   32 CONTINUE                                                             
!C
      RETURN                                                              
      END                                                                 
