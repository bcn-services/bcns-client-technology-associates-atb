      SUBROUTINE  INITIALIZE ( INTEGRATE_RUN )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine performs all the initialization and setup 
!C     needed for the simulation prior to integration.  It was
!C     created from .MAIN and called only by .MAIN.
!C
!C    The argument INTEGRATE_RUN is true if the run is be integrated
!C     in time.
!C
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:  
     &        NPG, NPRT, TIME, NJNTF, NSD, NWINDF,                  ! /CONTRL/
     &        NFORCE,                                               ! /WINDFR/
     &        LUAOU,                                                ! parameters
     &        PROGRAM_NAME, VERSION_NUMBER, VERSION_DATE,           ! parameters
     &        I_0, I_2, D_0, R_100, LOGICAL_STD, TRUE, FALSE        ! parameters
!C
      IMPLICIT  NONE
!C
      LOGICAL  ( KIND = LOGICAL_STD )  INTEGRATE_RUN           
!C
      INTENT ( OUT )  INTEGRATE_RUN
!C                                                                      
!C    Call subroutine to open input and output files.                   
!C
      CALL INPUT_FILES                                              
!C                                                                      
!C    Write prologue on primary output unit.                               
!C                                                                      
      NPG = I_2                                                       
!C                                                                      
      WRITE ( LUAOU, 110 )                                               
  110 FORMAT ( '1', 30X, 'AAMRL Articulated Total Body (ATB) Model',    
     &        52X, 'PAGE    1', ////,                                      
     &        31X,
     &  'Developed by CALSPAN Corp., P.O. Box 400, Buffalo NY 14225', /, 
     &        31X,
     &  'and by J&J Technologies Inc., Orchard Park, NY 14127',      //,   
     &        31X, 
     &  'For the Armstrong Aerospace Medical Research Laboratory ',   /,  
     &        31X, 'Wright-Patterson Air Force Base            ',     /, 
     &        31X,
     &  'Under contracts F33615-75C-5002,-78C-0516 and -80C-05117',  //, 
     &        31X,
     &  'and for the National Highway Traffic Safety Administration,',   
     &     /, 31X,
     &  'U.S. Department of Transportation, under contracts',         /,
     &  31X, 'FH-11-7592, HS-053-2-485, HS-6-01300 and HS-6-01410,', //,  
     &  31X, 'Modified by GESAC, Inc. to incorporate water forces,', /,
     &  31X, 'by Armstrong Lab. for robotic motion simulation,', /,
     &  31X, 'and finite element models of deformable segments,', /,
     &  31X, 'and by BlackRock Dynamics, Inc. to convert the', /,
     &  31X, 'code to Fortran 90/95.', ///   )              
      WRITE ( LUAOU, 111 ) PROGRAM_NAME, VERSION_NUMBER, VERSION_DATE  
111   FORMAT (                                                       
     & 31X,'Program documentation: NHTSA Report Nos. DOT-HS-801-507', /, 
     & 31X,'through 510 (formerly CALSPAN Report No. ZQ-5180-L-1),', /,  
     & 31X,'Available from NTIS (accession nos. PB-241692,3,4 and 5),', 
     &       /,                                                          
     & 31X,'Appendixes A-J to the above (Available from CALSPAN),', /,   
     & 31X,'and report nos. AMRL-TR-75-14 (NTIS NO. AD-A014 816),', /,     
     & 31X,'AFAMRL-TR-80-14 (NTIS NO. AD-A088 029), and', /,              
     & 31X,'AFAMRL-TR-83-073 (NTIS NO. AD-B079 184).', //,                
     & 31X,'The most recent documentation is in report nos.', /,         
     & 31X, 'AFRL-HE-WP-TR-1998-0015.', /,
     & 31X,'PROGRAM ', A4, 1X, A14, 1X, '(', A17, ')  ', /// )
      WRITE ( LUAOU, 112)
112   FORMAT ( 31X, 'The Government makes no express or implied', /,                                      
     & 31X, 'warranty as to any matter whatsoever including the',/, 
     & 31X, 'conditions of the research or any product agreement',/, 
     & 31X, 'or of the merchantability, validity, suitability, ',/,
     & 31X, 'or fitness for a particular ',/,
     & 31X, 'purpose of the research or product developed from',/,
     & 31X, 'the use of this software.  In no event will the',/,
     & 31X, 'Government be liable to any other party for',/,
     & 31X, 'compensatory, punitive, exemplary or consequential',/,
     & 31X, 'damages.  The Government is neither liable nor',/,
     & 31X, 'responsible for maintenance, updating or correcting',/,
     & 31X, 'any errors in the provided software.  The user  ',/,
     & 31X, 'accepts all risks and responsibilities from the ',/,
     & 31X, 'following analysis.  Please see the ATB  Users   ',/,
     & 31X, 'guide for information on suppressing this startup',/,
     & 31X, 'message in the future.  The user has accepted these',/,
     & 31X, 'terms by executing the following analysis. ',///)

!C
!C    Initialize some of the constants used by the program.
!C                                                                      
      CALL BLKDTA
!C
!C   Input the A cards.                                                  
!C                                                                        
      CALL INPUT_ACARDS                                                   
!C
!C    If the run is a postprocessing run only, i.e. NPRT(4) negative,
!C     skip over the integration related code.
!C 
      IF ( NPRT(4) .LT. I_0 ) THEN
       INTEGRATE_RUN = FALSE
       RETURN
      ELSE
       INTEGRATE_RUN = TRUE
      END IF
!C                                                                      
!C    Call input subroutines need for integration.                         
!C                                                                         
      CALL INPUT_BCARDS                                                
      CALL INPUT_VEHICLE                                                 
      CALL INPUT_DCARDS                                                  
      CALL INPUT_FUNCTIONS                                                   
!C
!C    Read in the wind force data if NWINDF is greater than 0.
!C
      IF ( NWINDF .GT. I_0 )  CALL INPUT_WIND                                 
!C
!C    Read in the joint restoring torque functions, if specified.
!C
      IF ( NJNTF .GT. I_0 )  CALL INPUT_JOINT_TORQUE                                  
!C                                                                     
!C    If spring-dampers, forces, or joint functions are used, call    
!C    FUNCHK to make sure all functions used are defined in the E cards. 
!C                                                                    
      IF ( ( NFORCE .NE. I_0 ) .OR. ( NSD   .NE. I_0 )
     &          .OR. ( NJNTF .NE. I_0 ) )   CALL FUNCHK
!C
      CALL INPUT_FCARDS                                                
!C                                                                      
!C....Calculate ASAD for Subroutine CHAIN which is called by 
!C    INPUT_INITIAL to re-compute joint locations and velocities 
!C    to account for flexible segments.
!C
      CALL FJNTVC ( I_0 )                                            
!C                                                                         
!C    Program initialization.
!C                                                                        
      TIME = D_0                                                        
!C
!C    Read in and setup the initial conditions ( linear and angular
!C     positions and velocities ) for the segments.
!C
      CALL  INPUT_INITIAL_CONDITIONS
!C
      RETURN
      END                                              