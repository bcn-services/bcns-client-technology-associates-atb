      SUBROUTINE VINITL ( NUMVEH_LCL )  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the absolute initial conditions from the relative          
!C    initial conditions computed by VINO12 and VINO34 for all the        
!C    segments specified as vehicles. In this subroutine, the word        
!C    "absolute" refers to the quantity in question being with respect    
!C    to the inertial coordinate system.  For example, RWMEG              
!C    is the angular velocity of the vehicle with respect to the          
!C    reference segment for the vehicle (I3), whereas WMEG is the         
!C    angular velocity of the vehicle with respect to the ground.         
!C                                                                        
!C    Called by INPUT_INITIAL_CONDITIONS.
!C
!C     Subroutines called:  MAT33, MAT31, DOT33, DOT31, CROSS             
!C                                                                        
!C     Logical unit(s) read from/written to:  none                        
!C                                                                        
!C     STOPS: none                                                        
!C                                                                        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       RINIT_SEGLP, RINIT_SEGLV, RINIT_SEGLA,   ! new global
     &       RINIT_D, RINIT_WMEG, RINIT_WMEGD,        ! new global
     &       SEG, VEH,                                ! structures
     &       INTEGER_STD, IREAL_HIGH,                 ! parameters
     &       MAXSEG, MAXVEH,                          ! parameters
     &       D_0, D_1, D_2, I_0, I_1, I_2             ! parameters
!C                                                                     
!C    ANG_ACCEL, ANG_VEL, DIR_COS, LIN_ACCEL, LIN_DISP, LIN_VEL  ! SEG%
!C    IVFLG, IVSEG, IVREF                                        ! VEH%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &                 I, I1, I2, I3, K, M, NUMVEH_LCL
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AIDENT, RAACC, RLACC, RPOS, RVEL, 
     &                  RWMEGI, TCRS1, TCRS2, TCRS3, TCRS4, 
     &                  TCRS5, WMEGDI, WMEGIR, WMEGIV, WMGDIR
      DIMENSION         AIDENT(3,3), RAACC(3),  
     &                  RLACC(3), RPOS(3), RVEL(3), RWMEGI(3),  
     &                  TCRS1(3), TCRS2(3), TCRS3(3), TCRS4(3), 
     &                  TCRS5(3), WMEGDI(3), WMEGIR(3), WMEGIV(3),
     &                  WMGDIR(3)                                         
!C
      INTENT ( IN )  NUMVEH_LCL
!C 
!C                                                                        
!C    Compute the absolute initial conditions for all segments            
!C    defined as vehicles.                                                
!C                                                                        
      DO 20 M=1,NUMVEH_LCL                                                
       I1 = ABS ( VEH(M)%IVFLG )                                        
       I2 = VEH(M)%IVSEG                                                
       I3 = VEH(M)%IVREF                                                
!C                                                                        
!C    If I1 = 0, all quantites for this vehicle are absolute              
!C     quantities and are relative to the ground and are in               
!C     inertial or local coordinates.  Equate the relative               
!C     quantities to the absolute quantities, then skip to the next      
!C     vehicle.  The same applies if I1 = 2 and I3 = 0, which means     
!C     that the input for vehicle M is with respect to the ground.      
!C                                                                        
       IF (( I1 .EQ. I_0 ) .OR. 
     &            ( ( I1 .EQ. I_2 ) .AND. ( I3 .EQ. I_0 ) ) ) THEN  
        DO  I=1,3                                                         
         SEG(I2)%LIN_DISP(I)  = RINIT_SEGLP(I,I2)                          
         SEG(I2)%LIN_VEL(I)   = RINIT_SEGLV(I,I2)                         
         SEG(I2)%ANG_VEL(I)   = RINIT_WMEG(I,I2)                               
         SEG(I2)%LIN_ACCEL(I) = RINIT_SEGLA(I,I2)                       
         SEG(I2)%ANG_ACCEL(I) = RINIT_WMEGD(I,I2)                           
         DO  K=1,3                                                      
          SEG(I2)%DIR_COS(I,K)   = RINIT_D(I,K,I2)                       
         END DO
        END DO                                                            
       ELSE                                                               
!C                                                                        
!C     If I1 # 0, then the absolute quantities must be computed from      
!C     the relative quantities.  Same applies if I3 # 0.                  
!C                                                                        
!C     If I1 = 1, the input quantities are with respect to the vehicle    
!C     coordinate system.  Transform all quantities to the inertial      
!C     system, then compute the desired intermediate quantities.          
!C                                                                        
        IF ( I1 .EQ. I_1 ) THEN                                           
         IF ( I3 .EQ. I_0 ) THEN                                       
          DO  I=1,3                                                     
           DO  K=1,3                                                    
            IF ( I .EQ. K ) THEN                                        
             AIDENT(I,K) = D_1                                       
            ELSE                                                        
             AIDENT(I,K) = D_0                                         
            END IF                                                      
           END DO                                                       
          END DO                                                        
          CALL DOT33 ( RINIT_D(1,1,I2), AIDENT, SEG(I2)%DIR_COS )         
         ELSE                                                           
          CALL DOT33 ( RINIT_D(1,1,I2), SEG(I3)%DIR_COS, 
     &                 SEG(I2)%DIR_COS )     
         END IF                                                         
         CALL DOT31 ( SEG(I2)%DIR_COS, RINIT_SEGLP(1,I2), RPOS )             
         CALL DOT31 ( SEG(I2)%DIR_COS, RINIT_WMEG(1,I2),  RWMEGI )             
         CALL DOT31 ( SEG(I2)%DIR_COS, RINIT_SEGLV(1,I2), RVEL )                
         CALL DOT31 ( SEG(I2)%DIR_COS, RINIT_SEGLA(1,I2), RLACC )           
         CALL DOT31 ( SEG(I2)%DIR_COS, RINIT_WMEGD(1,I2), RAACC )          
        ELSE                                                              
!C                                                                        
!C      If I1 = 2, the input quantities are with respect to the           
!C      reference coordinate system.  Transform all quantities to the     
!C      inertial system and compute the desired intermediate quantities. 
!C                                                                       
         CALL MAT33 ( RINIT_D(1,1,I2), SEG(I3)%DIR_COS, 
     &                SEG(I2)%DIR_COS )      
         CALL DOT31 ( SEG(I3)%DIR_COS, RINIT_SEGLP(1,I2), RPOS )               
         CALL DOT31 ( SEG(I3)%DIR_COS, RINIT_WMEG(1,I2), RWMEGI )              
         CALL DOT31 ( SEG(I3)%DIR_COS, RINIT_SEGLV(1,I2), RVEL )               
         CALL DOT31 ( SEG(I3)%DIR_COS, RINIT_SEGLA(1,I2), RLACC )         
         CALL DOT31 ( SEG(I3)%DIR_COS, RINIT_WMEGD(1,I2), RAACC )              
        END IF                                                            
!C                                                                        
!C      Transform the angular velocity of the reference segment           
!C      from local to inertial coordinates.  Do the same for the         
!C      angular acceleration of the reference segment.                    
!C                                                                        
        CALL DOT31 ( SEG(I3)%DIR_COS, SEG(I3)%ANG_VEL, WMEGIR )                
        CALL DOT31 ( SEG(I3)%DIR_COS, SEG(I3)%ANG_ACCEL, WMGDIR )                
!C                                                                        
!C      Compute the absolute linear position and angular velocity         
!C      of the vehicle segment in inertial coordinates.                   
!C      Note that for I1 = 1, the input is viewed as from an observer     
!C      standing on the vehicle segment and observing the motion of       
!C      reference segment.  If I1 = 2, the input is viewed as from an   
!C      observer standing on the reference segment and observing the      
!C      motion of the vehicle with respect to the reference segment.      
!C      Hence the need for different signs for the relative quantity,     
!C      depending on the value of I1.                                     
!C                                                                       
        IF ( I1 .EQ. I_1 ) THEN                                        
         SEG(I2)%LIN_DISP = SEG(I3)%LIN_DISP - RPOS                
         WMEGIV           = WMEGIR  - RWMEGI                        
        ELSE                                                          
         SEG(I2)%LIN_DISP = SEG(I3)%LIN_DISP + RPOS                           
         WMEGIV           = WMEGIR  + RWMEGI                        
        END IF                                                      
!C                                                                        
!C      Transform the absolute angular velocity from inertial to          
!C      the local coordinates of the vehicle segment. Also, compute       
!C      the various cross product terms needed to compute the             
!C      absolute accelerations and absolute linear velocity.              
                                                                          
        CALL MAT31 ( SEG(I2)%DIR_COS, WMEGIV, SEG(I2)%ANG_VEL )                
        CALL CROSS ( WMEGIR, RPOS, TCRS1 )                                
        CALL CROSS ( WMEGIR, WMEGIV, TCRS2 )                              
        CALL CROSS ( WMEGIR, TCRS1, TCRS3 )                               
        CALL CROSS ( WMEGIR, RVEL, TCRS4 )                              
        CALL CROSS ( WMGDIR, RPOS, TCRS5 )                                
!C                                                                        
!C      Compute the absolute angular acceleration, the absolute           
!C      linear velocity and the absolute linear deceleration for          
!C      the vehicle segment, all in inertial coordinates.                 
!C                                                                        
        IF ( I1 .EQ. I_1 )  THEN
          SEG(I2)%LIN_VEL   = SEG(I3)%LIN_VEL   - TCRS1 - RVEL    
          SEG(I2)%LIN_ACCEL = SEG(I3)%LIN_ACCEL - TCRS5 - TCRS3 
     &                         - D_2 * TCRS4 - RLACC                 
        ELSE
          SEG(I2)%LIN_VEL   = SEG(I3)%LIN_VEL + TCRS1 + RVEL    
          SEG(I2)%LIN_ACCEL = SEG(I3)%LIN_ACCEL + TCRS5 + TCRS3 
     &                         + D_2 * TCRS4 + RLACC                    
        END IF
        DO  I=1,3                                                         
         IF ( I1 .EQ. I_1 ) THEN                                       
          WMEGDI(I) = WMGDIR(I) + TCRS2(I) - RAACC(I)                     
         ELSE                                                             
          WMEGDI(I) = WMGDIR(I) + TCRS2(I) + RAACC(I)                     
         END IF                                                           
        END DO                                                           
!C                                                                        
!C      Transform the absolute angular acceleration from inertial         
!C      coordinates to the local coordinates of the vehicle.              
!C                                                                        
        CALL MAT31 ( SEG(I2)%DIR_COS, WMEGDI, SEG(I2)%ANG_ACCEL )              
       END IF                                                             
   20 CONTINUE                                                            
!C
      RETURN                                                              
      END                                                                 
