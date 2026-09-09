      PROGRAM ATB_V3
!C                                                                         
!C    AAMRL Articulated Total Body (ATB_V.3) Model computer program       
!C    Developed by CALSPAN Corp. and J&J Technologies Inc.               
!C    Modified by GESAC,Inc. for incorporating water forces.             
!C    Converted to Fortran 95 by BlackRock Dynamics, Inc.
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    MAIN PROGRAM                                                         
!C                                                                         
!C    Performs card input, program initialization,                         
!C    control of integration loop and optional output.                     
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:  
     &        DT,                                              ! /COMAIN/
     &        NPG, NPRT,                                       ! /CONTRL/
     &        IREAL_HIGH, LOGICAL_STD, I_0, I_1, D_1000,       ! parameters
     &        INTEGER_STD, LUAOU, LUTP8, LUTERM_OUT            ! parameters
!C
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )   PRDT
!C
!C
      LOGICAL  ( KIND = LOGICAL_STD )  INTEGRATE_RUN           
      LOGICAL  ( KIND = LOGICAL_STD ) LR
!C
      INTEGER ( KIND = INTEGER_STD) IR
!C
!C
!C    Initialize the CPU counter for the run.
!C
      CALL ELTIME ( I_1, I_1 )                                      
!C
!C    Input and initialize all data needed for the simulation.
!C
      CALL INITIALIZE ( INTEGRATE_RUN )
!C
!C    Integrate the dynamics forward in time.
!C
      IF ( INTEGRATE_RUN ) CALL INTEGRATE_TIME
!C                                                                         
!C    Subroutine POSTPR on primary output unit controlled by NPRT(4).      
!C                                                                         
      IF  ( NPRT(4) .GT. I_0 )   ENDFILE LUTP8                          
      IF  ( ( NPRT(4) .NE. I_0 ) .AND. ( NPRT(4) .NE. 4 ) )  THEN       
       PRDT = D_1000 * DT                                                
       CALL POSTPR ( PRDT )                                                
       IF  ( NPRT(2) .EQ. I_1 )  CALL ELTIME ( NPG, I_1 )                         
      END IF
!C                                                                         
!C    End of run - call ELTIME if not called above.                       
!C                                                                         
      IF  ( NPRT(2) .NE. I_1 )   CALL ELTIME ( NPG, I_1 )                   
!C
      WRITE ( LUTERM_OUT, 110 )                                          
  110 FORMAT ( 1X, ' ATB Simulation completed! ' )
!C 
      STOP 1                                                            
!C
      END PROGRAM  ATB_V3                                      
