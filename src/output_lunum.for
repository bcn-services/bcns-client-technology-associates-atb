      SUBROUTINE  OUTPUT_LUNUM ( LTHIST )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine outputs the names of the files opened and/or
!C     used for the simulation.  It also lists which type of 
!C     data are in the tabular time history files that were opened.
!C    Only called by Subroutine OUTPUT_SETUP
!C    
      USE  MODULE_STANDARD,  ONLY:  
     &       NPG, NPRT,                                      ! /CONTRL/
     &       INFIL, OUTFIL,  WORK_DIRECTORY,                 ! /FILEN/
     &       ICHAR_STD, LOGICAL_STD, LUAOU,                   ! parameters
     &       I_0, I_1, INTEGER_STD, AIN_CONVERT, LIN_FLAG,    ! parameters
     &       ACUATOR_TTH, AIRBAG_TTH, ANG_ACCEL_TTH,          ! structures
     &       ANG_ROT_TTH, ANG_VEL_TTH, BELT_TTH,              ! structures
     &       CG_TTH, HARNESS_TTH, JOINT_FORCE_TTH,            ! structures
     &       JOINT_PARM_TTH, LIN_ACCEL_TTH, LIN_DISP_TTH,     ! structures
     &       LIN_VEL_TTH, PLANE_SEG_TTH, SEG_SEG_TTH,         ! structures
     &       SPRING_DAMP_TTH, WATER_TTH, WIND_TTH             ! structures
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  LTH
!C
      CHARACTER ( LEN = 32, KIND = ICHAR_STD )   FILE_NM
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTHIST
!C                                                                      
      INTENT (  IN )  LTHIST
!C                                                                      
!C    Print out the names of the files that were opened and update      
!C     the .AOU page count, NPG                                         
!C                                                                      
      WRITE ( LUAOU, 100 )  NPG, WORK_DIRECTORY                         
  100 FORMAT ( '1', ' The various files used for this run are in',   
     &         ' the directory: ', 64X,  'Page', I5, /,  1X, 10X, A79  )                                    
      NPG = NPG + I_1                                                    
!C
!C    The .ain and .aou or .lin and .aou files are always open.
!C
      IF ( LIN_FLAG )  THEN
       FILE_NM = TRIM ( INFIL ) // '.lin'
       FILE_NM = ADJUSTL (FILE_NM)
       LTH = LEN_TRIM ( FILE_NM )
       WRITE ( LUAOU, 102 )  FILE_NM(1:LTH)                               
  102  FORMAT ( 1X, 'The input file name for this run is: ', A )                
      ELSE
       FILE_NM = TRIM ( INFIL ) // '.ain'
       FILE_NM = ADJUSTL (FILE_NM)
       LTH = LEN_TRIM ( FILE_NM )
       WRITE ( LUAOU, 105 )  FILE_NM(1:LTH)                               
  105  FORMAT ( 1X, 'The input file name for this run is: ', A )                
       IF ( AIN_CONVERT )  THEN
!C
!C    The .lin file is open if the .ain file is to be converted.
!C
        FILE_NM = TRIM ( INFIL ) // '.lin'
        FILE_NM = ADJUSTL (FILE_NM)
        LTH = LEN_TRIM ( FILE_NM )
        WRITE ( LUAOU, 107 )  FILE_NM(1:LTH)                               
  107   FORMAT ( 1X, 'The list-directed file name created is: ', A )                
       END IF
      END IF
!C
!C    The .out file is always open.
!C
      FILE_NM = TRIM ( OUTFIL ) // '.aou'
      FILE_NM = ADJUSTL (FILE_NM)
      LTH = LEN_TRIM ( FILE_NM )
      WRITE ( LUAOU, 110 )  FILE_NM(1:LTH)                     
  110 FORMAT ( 1X, 'The standard output is in file: ', A )                
!C
!C    If there is VIEW output, list the filename with the appropriate
!C     extension.
!C
      IF ( NPRT(1) .NE. I_0 ) THEN
       IF ( NPRT(35) .EQ. I_0)  THEN
        FILE_NM = TRIM ( OUTFIL ) // '.sa1'
        FILE_NM = ADJUSTL (FILE_NM)
        LTH = LEN_TRIM ( FILE_NM )
        WRITE ( LUAOU, 115 )  FILE_NM(1:LTH) 
  115   FORMAT ( 1X, 'Output data for VIEW are in structured file: ',
     &           A, / )                 
       ELSE IF ( NPRT(35) .EQ. I_1 )  THEN
        FILE_NM = TRIM ( OUTFIL ) // '.uf1'
        FILE_NM = ADJUSTL (FILE_NM)
        LTH = LEN_TRIM ( FILE_NM )
        WRITE ( LUAOU, 120 )  FILE_NM(1:LTH)
  120   FORMAT ( 1X, 'Output data for VIEWPE are in binary file: ', 
     &           A, / )                  
       ELSE
        FILE_NM = TRIM ( OUTFIL ) // '.tp1'
        FILE_NM = ADJUSTL (FILE_NM)
        LTH = LEN_TRIM ( FILE_NM )
        WRITE ( LUAOU, 125 )  FILE_NM(1:LTH)
  125   FORMAT ( 1X, 'Output data for old VIEW are in ASCII file: ', 
     &           A, / )                  
       END IF
      END IF
!C
!C    Print out the name of the Tape 8 file, if it was used.
!C
      IF ( NPRT(4) .EQ. I_0 )  THEN
       WRITE ( LUAOU, 130 )
  130  FORMAT ( 1X, 'There was no Tape 8 file for this run. ', / )
      ELSE IF ( NPRT(4) .GT. I_0 )  THEN
       FILE_NM = TRIM ( OUTFIL ) // '.tp8'
       FILE_NM = ADJUSTL (FILE_NM)
       LTH = LEN_TRIM ( FILE_NM )
       WRITE ( LUAOU, 135 )  FILE_NM(1:LTH) 
  135  FORMAT ( 1X, 'Tape 8 output is saved in: ', 8X, A, / )                 
      ELSE
       FILE_NM = TRIM ( OUTFIL ) // '.tp8'
       FILE_NM = ADJUSTL (FILE_NM)
       LTH = LEN_TRIM ( FILE_NM )
       WRITE  ( LUAOU, 140 )  FILE_NM(1:LTH)
  140  FORMAT ( 1X, 'Input for postprocessing read from: ', A, / )      
      END IF  
!C                                                                      
!C     Print out the extension numbers (or "page" numbers), associated 
!C     with the various types of tabular time history output if there
!C     were individual tabular time histories.  Otherwise, return.
!C                                                                      
      IF ( .NOT. LTHIST ) THEN                                          
       WRITE ( LUAOU, 150 )
  150  FORMAT ( 1X, 'There were no individual tabular time history',
     &              ' files for this run.', / )
       RETURN
      END IF
!C
      FILE_NM = ADJUSTL (OUTFIL)
      LTH = LEN_TRIM ( FILE_NM )
      WRITE ( LUAOU, 155 )  FILE_NM(1:LTH)                             
  155 FORMAT ( 1X, 'Tabular time history data have the file name: ',
     &         A, /, 1X,
     &         'The range of the file name extension which',
     &         ' corresponds to a specific type of tabular time',
     &         ' history is given below.', / ) 
!C
!C
!C**************************************
!C
!C    Print the extensions for the H Card output.
!C                                                                      
!C    Print the range of tabular time histories for total linear        
!C     accelerations.                                                   
!C                                                                      
      IF ( LIN_ACCEL_TTH%PRINT ) THEN                                   
       WRITE ( LUAOU, 160 ) LIN_ACCEL_TTH%BEGIN_LUNUM, 
     &                      LIN_ACCEL_TTH%END_LUNUM                     
  160  FORMAT ( 1X, 'Point total acceleration ', 5X,                    
     &              'data are in files with extensions .t',
     &              I2,' through .t', I2 ) 
      END IF                                                            
!C                                                                      
!C    Print out the range of tabular time histories for linear          
!C     velocities.                                                      
!C                                                                      
      IF ( LIN_VEL_TTH%PRINT ) THEN                                     
       WRITE ( LUAOU, 165 ) LIN_VEL_TTH%BEGIN_LUNUM, 
     &                      LIN_VEL_TTH%END_LUNUM                       
  165  FORMAT ( 1X, 'Relative linear velocity ', 5X,                    
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time histories for linear              
!C     displacements.                                                   
!C                                                                      
      IF ( LIN_DISP_TTH%PRINT ) THEN                                    
       WRITE ( LUAOU, 170 ) LIN_DISP_TTH%BEGIN_LUNUM, 
     &                      LIN_DISP_TTH%END_LUNUM                      
  170  FORMAT ( 1X, 'Relative linear displacement ', 1X,                
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )                             
      END IF                                                            
!C                                                                      
!C    Print out the range of tabular time histories for angular         
!C     accelerations.                                                   
!C                                                                      
      IF ( ANG_ACCEL_TTH%PRINT ) THEN                                   
       WRITE ( LUAOU, 175 ) ANG_ACCEL_TTH%BEGIN_LUNUM, 
     &                      ANG_ACCEL_TTH%END_LUNUM                     
  175  FORMAT ( 1X, 'Angular acceleration data ', 4X,                   
     &               'data are in files with extensions .t',
     &               I2,' through .t', I2 )   
      END IF                                                            
!C                                                                      
!C    Print out the range of tabular time histories for angular         
!C     velocity.                                                        
!C                                                                      
      IF ( ANG_VEL_TTH%PRINT ) THEN                                     
       WRITE ( LUAOU, 180 ) ANG_VEL_TTH%BEGIN_LUNUM, 
     &                      ANG_VEL_TTH%END_LUNUM                       
  180  FORMAT ( 1X, 'Relative angular velocity ', 4X,                   
     &              'data are in files with extensions .t',
     &              I2,' through .t',I2)   
      END IF                                                            
!C                                                                      
!C    Print out the range of tabular time histories for angular         
!C     displacement.                                                    
!C                                                                      
      IF ( ANG_ROT_TTH%PRINT ) THEN                                     
        WRITE ( LUAOU, 185 ) ANG_ROT_TTH%BEGIN_LUNUM, 
     &                      ANG_ROT_TTH%END_LUNUM                       
  185  FORMAT ( 1X, 'Relative angular displacement ',                   
     &               'data are in files with extensions .t',
     &               I2, ' through .t', I2 )  
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time history files for the joint       
!C     parameters.                                                      
!C                                                                      
      IF ( JOINT_PARM_TTH%PRINT ) THEN                                  
        WRITE ( LUAOU, 190 ) JOINT_PARM_TTH%BEGIN_LUNUM, 
     &                       JOINT_PARM_TTH%END_LUNUM                   
  190  FORMAT ( 1X, 'Joint parameter ', 14X,                            
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )   
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time history files for wind forces.    
!C                                                                      
      IF ( WIND_TTH%PRINT ) THEN                                        
       WRITE ( LUAOU, 195 ) WIND_TTH%BEGIN_LUNUM, 
     &                      WIND_TTH%END_LUNUM                          
  195  FORMAT ( 1X, 'Wind force ', 19X,                                 
     &              'data are in files with extensions .t',
     &              I2,' through .t', I2 )    
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time history files for joint forces    
!C     and torques.                                                     
!C                                                                      
      IF ( JOINT_FORCE_TTH%PRINT ) THEN                                 
       WRITE ( LUAOU, 200 ) JOINT_FORCE_TTH%BEGIN_LUNUM, 
     &                      JOINT_FORCE_TTH%END_LUNUM                   
  200  FORMAT ( 1X, 'Joint force and torque ', 7X,                      
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 ) 
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time history files for                 
!C     the acuator forces.                                              
!C                                                                      
      IF ( ACUATOR_TTH%PRINT ) THEN                                     
       WRITE ( LUAOU, 205 ) ACUATOR_TTH%BEGIN_LUNUM, 
     &                      ACUATOR_TTH%END_LUNUM                       
  205  FORMAT ( 1X, 'Acuator ', 22X,                                    
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )   
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time history files for                 
!C     center-of-mass, etc.  Note that the acuator 
!C     tabular time histories are printed and number before
!C     the c.g. data, even though the acuator cards are the H.11
!C     cards and the c.g. data are the H.10 cards.
!C                                                                      
      IF ( CG_TTH%PRINT ) THEN                                          
       WRITE ( LUAOU, 210 ) CG_TTH%BEGIN_LUNUM, 
     &                      CG_TTH%END_LUNUM                            
  210  FORMAT ( 1X, 'Center of mass ', 15X,                             
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )   
      END IF                                                            
!C
!C***********************************
!C
!C    Print extensions for force output files.
!C                                                                      
!C    Print the range of tabular time history files for plane/segment   
!C     forces.                                                          
!C                                                                      
      IF ( PLANE_SEG_TTH%PRINT ) THEN                                   
       WRITE ( LUAOU, 215 ) PLANE_SEG_TTH%BEGIN_LUNUM, 
     &                      PLANE_SEG_TTH%END_LUNUM                     
  215  FORMAT ( 1X, 'Plane/segment force ', 10X,                         
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )  
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time histories for belt/segment        
!C     forces.                                                          
!C                                                                      
      IF ( BELT_TTH%PRINT ) THEN                                        
       WRITE ( LUAOU, 220 ) BELT_TTH%BEGIN_LUNUM, 
     &                      BELT_TTH%END_LUNUM                          
  220  FORMAT ( 1X, 'Belt/segment force ', 11X,                         
     &              'data are in files with extensions .t',
     &              I2, ' through ', I2 )   
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time histories for harness-belt        
!C     endpoint forces.                                                 
!C                                                                      
      IF ( HARNESS_TTH%PRINT ) THEN                                     
       WRITE ( LUAOU, 225 ) HARNESS_TTH%BEGIN_LUNUM, 
     &                      HARNESS_TTH%END_LUNUM                       
  225  FORMAT ( 1X, 'Harness-belt endpoint ', 8X,                       
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 ) 
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time histories for the                 
!C     spring-dampers.                                                   
!C                                                                      
      IF ( SPRING_DAMP_TTH%PRINT ) THEN                                 
       WRITE ( LUAOU, 230 ) SPRING_DAMP_TTH%BEGIN_LUNUM, 
     &                      SPRING_DAMP_TTH%END_LUNUM                   
  230  FORMAT ( 1X, 'Spring-damper ', 16X,                              
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )
      END IF                                                            
!C                                                                      
!C     Print the range of tabular time histories for the seg/seg forces.
!C                                                                      
      IF ( SEG_SEG_TTH%PRINT ) THEN                                     
       WRITE ( LUAOU, 235 ) SEG_SEG_TTH%BEGIN_LUNUM, 
     &                      SEG_SEG_TTH%END_LUNUM                       
  235  FORMAT ( 1X, 'Seg/seg force ', 16X,                              
     &              'data are in files with extensions .t',
     &              I2,' through .t',I2)    
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time histories for the airbag          
!C     information.                                                     
!C                                                                      
      IF ( AIRBAG_TTH%PRINT ) THEN                                      
       WRITE ( LUAOU, 240 ) AIRBAG_TTH%BEGIN_LUNUM, 
     &                      AIRBAG_TTH%END_LUNUM                        
  240  FORMAT ( 1X, 'Airbag ', 23X,                                     
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )   
      END IF                                                            
!C                                                                      
!C    Print the range of tabular time histories for the water           
!C     information.                                                     
!C                                                                      
      IF ( WATER_TTH%PRINT ) THEN                                       
       WRITE ( LUAOU, 245 ) WATER_TTH%BEGIN_LUNUM, 
     &                      WATER_TTH%END_LUNUM                         
  245  FORMAT ( 1X, 'Water ', 24X,                                      
     &              'data are in files with extensions .t',
     &              I2, ' through .t', I2 )   
      END IF                                                            
!C
!C    Insert a blank line for appearance.
!C
      WRITE ( LUAOU, 250 )
  250 FORMAT ( 1X )
!C
      RETURN                                                            
      END                                                               
