      SUBROUTINE VPATH ( NUMVEH_LCL, NVEH_LCL, NGRND_LCL, NPG_LCL )       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine ascertains the paths of reference to the             
!C     inertial (ground) coordinate system for all vehicles.               
!C     If no path to ground is found, an error message is printed         
!C     and the program terminated.                                         
!C                                                                        
!C    Subroutines called by: INPUT_VEHICLE                           
!C    STOPS: 280, 281, 282                                                 
!C                                                                        
!C    Global variables altered: VEH%IVREF, VEH%IVSEG, VEH%IVREF                                            
!C                                                                         
!C    Global variables used but not altered SEG%NAME.                              
!C                                                                       
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:  
     &       SEG, VEH,                  ! structures
     &       ICHAR_STD, INTEGER_STD,    ! parameters
     &       LUAOU, MAXSEG, MAXVEH,     ! parameters
     &       I_0, I_1, I_2              ! parameters
!C
!C           NAME                      SEG%
!C           IVFLG, IVSEG, IVREF       VEH%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, I1, I2, I3, I4, I5, IA, IC, IL, IREF, ITEMP, 
     &           ITEMP2, J, K, L, NGRND_LCL, NPG_LCL, 
     &           NUMVEH_LCL, NVEH_LCL 
      DIMENSION  ITEMP(MAXVEH+3,MAXVEH), ITEMP2(MAXVEH+3,MAXVEH)       
!C                                                                         
      CHARACTER ( LEN = 4, KIND = ICHAR_STD )  RSEG, TSEG
      DIMENSION     TSEG(MAXVEH)
!C
      INTENT (    IN )  NUMVEH_LCL, NVEH_LCL, NGRND_LCL
      INTENT ( INOUT )  NPG_LCL
!C
!C    Set first three rows of ITEMP equal to IVFLG, IVSEG, IVREF.      
!C                                                                         
      DO  I=1,NUMVEH_LCL                                                   
       ITEMP(1,I) = VEH(I)%IVFLG                                       
       ITEMP(2,I) = VEH(I)%IVSEG                                        
       ITEMP(3,I) = VEH(I)%IVREF                               
      END DO                                                              
!C                                                                        
!C    Initialize remainder of ITEMP with -1's.                            
!C                                                                         
      DO  I=1,NUMVEH_LCL                                                   
       DO  J=4,NUMVEH_LCL+3                                               
        ITEMP(J,I) = -I_1                                              
       END DO
      END DO                                                              
!C                                                                        
!C    Check for duplicate vehicle segment number.  This can                
!C    only occur for segments with segment numbers less than NSEG.         
!C                                                                         
      DO  I=1,NUMVEH_LCL                                                   
       I1 = ITEMP(2,I)                                                     
       DO  J=1,NUMVEH_LCL                                                  
        I2 = ITEMP(2,J)                                                    
        IF ( ( I2 .EQ. I1 ) .AND. ( J .NE. I ) )  THEN                     
         WRITE ( LUAOU, 100 )  J, I, I2                                   
  100    FORMAT ( /, 1X, 'Vehicle number', I4, ' and vehicle number',
     &            I4, ' both have segment number', I4, /,
     &            ' as their segment number.', // )                       
         STOP  ' STOP 280 in Subroutine VPATH '                           
        END IF                                                            
       END DO
      END DO                                                               
!C                                                                         
!C    Insert the vehicle number for the primary vehicle.                   
!C                                                                        
      DO  I=1,NUMVEH_LCL                                                   
       IF ( ITEMP(2,I) .EQ. I_0 ) THEN                                  
        ITEMP(2,I) = NVEH_LCL                                              
       END IF                                                             
      END DO                                                               
!C                                                                         
!C    Determine paths of vehicles and store in ITEMP.                      
!C                                                                         
      DO  I=0,NUMVEH_LCL-1                                                 
       DO  J=1,NUMVEH_LCL                                                  
        I1 = ITEMP(2+I,J)                                                  
        I2 = ITEMP(3+I,J)                                                  
        IF ( I2 .GT. I_0 ) THEN                                       
         DO  K=1,NUMVEH_LCL                                                
          I3 = ITEMP(2+I,K)                                                
          I4 = ITEMP(3+I,K)                                                
          IF ( I3 .EQ. I2 ) THEN                                          
           ITEMP(I+4,J) = I4                                              
          END IF                                                           
         END DO                                                            
        END IF                                                             
       END DO
      END DO                                                               
!C                                                                         
!C    Determine the number of reference coordinate systems for            
!C     each vehicle.                                                       
!C                                                                         
      DO  I=1,NUMVEH_LCL                                                   
       DO  J=3,NUMVEH_LCL+2                                                
        IC = ITEMP(J,I)                                                   
        IF ( IC .EQ. I_0 )  THEN                                        
         ITEMP(NUMVEH_LCL+3,I) = J - I_2                                
        END IF                                                             
       END DO
      END DO                                                              
!C                                                                        
!C    Check to ensure that every vehicle has a path to the ground.         
!C                                                                        
      DO  I=1,NUMVEH_LCL                                                   
       IL = ITEMP(NUMVEH_LCL+3,I)                                          
       IA = ITEMP(IL+2,I)                                                  
       I2 = ITEMP(2,I)                                                    
       I3 = ITEMP(3,I)                                                     
       IF ( I3 .GT. NVEH_LCL ) THEN                                        
        WRITE ( LUAOU, 105 ) NUMVEH_LCL, I3, NVEH_LCL                      
  105   FORMAT ( /, 1X, 'Reference segment for vehicle number ', I4,
     &           ' is ', I4, '.', /, 
     &           ' This is greater than the primary vehicle',             
     &           ' segment number, which is segment number ', I4, /,     
     &           ' If the ground is desired as the reference segment,',   
     &           ' use 0.', // )                                          
        STOP ' STOP 281 in Subroutine VPATH '                            
       END IF                                                             
       IF ( IA .NE. I_0 )  THEN                                        
        WRITE ( LUAOU, 110 ) I, I2                                         
  110   FORMAT ( /, 1X, 'No path exists to ground for vehicle number',
     &           I4, ' (segment number', I4, ').', // )                  
        STOP ' STOP 282 in Subroutine VPATH '                             
       END IF                                                             
      END DO                                                               
!C                                                                         
!C    Reorder ITEMP and store in ITEMP2 and IVREF's so that the           
!C     reference(s) to the ground segment are first.                       
!C                                                                         
      L = I_1                                                         
      DO  I=1,NUMVEH_LCL                                                  
       IF ( L .LE. NUMVEH_LCL ) THEN                                       
        DO  J=1,NUMVEH_LCL                                                 
         I1 = ITEMP(NUMVEH_LCL+3,J)                                        
         IF ( I1 .EQ. I ) THEN                                             
          VEH(L)%IVFLG = ITEMP(1,J)                                     
          VEH(L)%IVSEG = ITEMP(2,J)                                    
          VEH(L)%IVREF = ITEMP(3,J)                                   
          DO  K=1,NUMVEH_LCL+3                                             
           ITEMP2(K,L) = ITEMP(K,J)                                        
          END DO                                                           
          L = L + I_1                                                   
         END IF                                                           
        END DO                                                             
       END IF                                                             
      END DO                                                               
!C                                                                        
!C    Print out vehicle paths.                                             
!C                                                                         
      WRITE ( LUAOU, 115 )  NPG_LCL                                        
  115 FORMAT ( '1', 2X, 'Vehicle Paths to Ground', 97X, 'Page', I5, / )  
      NPG_LCL = NPG_LCL + I_1                                           
      WRITE ( LUAOU, 120 )                                                
  120 FORMAT ( 1X, 'The ground (inertial) segment is represented here',   
     &         ' by a 0.',/,1X,'The coord category refers to the',       
     &         ' coordinate system in which the vehicle data are',        
     &         ' specified.', /, 1X,
     &         'A negative value for coord indicates',  
     &         ' that the data represent accelerometer data.', / )        
      WRITE ( LUAOU, 125 )                                                
  125 FORMAT ( 4X, 'Veh', 2X, 'Coord', 4X, 'Vehicle Path to Ground' )     
!C
      DO 42 I=1,NUMVEH_LCL                                                 
       I1 = ITEMP2(1,I)                                                    
       I2 = ITEMP2(2,I)                                                    
       I3 = ITEMP2(3,I)                                                    
       I4 = ITEMP2(NUMVEH_LCL+3,I)                                        
!C                                                                        
!C     Determine in which segment the vehicle data are specified           
!C      and whether the data represents accelerometer data.               
!C                                                                         
       IF ( ABS ( I1 ) .EQ. I_2 ) THEN                                   
        IREF = I3                                                        
        IF ( I1 .LT. I_0 ) THEN                                         
         IREF = -IREF                                                     
        END IF                                                             
       ELSE IF ( ABS ( I1 ) .EQ. I_1 )  THEN                            
        IREF = I2                                                          
        IF ( I1 .LT. I_0 ) THEN                                        
         IREF = -IREF                                                      
        END IF                                                             
       ELSE                                                             
        IREF = I_0                                                      
       END IF                                                              
!C                                                                         
!C     Determine vehicle data coordinate system.                           
!C                                                                         
       I5 = ABS ( IREF )                                                 
       IF ( I5 .NE. I_0 ) THEN                                          
        RSEG = SEG(I5)%NAME                                        
       ELSE                                                                
        RSEG = SEG(NGRND_LCL)%NAME                                      
       END IF                                                              
!C                                                                         
!C     Determine reference coordinate systems.                             
!C                                                                         
       DO  J=1,I4                                                         
        I5 = ITEMP2(J+2,I)                                                
        IF ( I5 .NE. I_0 )  THEN                                        
         TSEG(J) = SEG(I5)%NAME                                           
        ELSE                                                               
         TSEG(J) = SEG(NGRND_LCL)%NAME                                  
        END IF                                                             
       END DO                                                              
       WRITE ( LUAOU, 130 ) SEG(I2)%NAME, RSEG, ( TSEG(J), J=1,I4 )  
  130  FORMAT ( 2X, 2( 2X, A4 ), 2X, 19( 2X, A4 ) )                        
       WRITE ( LUAOU, 135 ) I2, IREF, (ITEMP2(J+2,I), J=1,I4 )             
  135  FORMAT ( 2X, 2( 2X, I4 ), 2X, 19( 2X, I4 ) )                        
       WRITE ( LUAOU, 140 )                                                
  140  FORMAT ( 1X )                                                       
   42 CONTINUE                                                             
C                                                                          
      RETURN                                                               
      END                                                                  
