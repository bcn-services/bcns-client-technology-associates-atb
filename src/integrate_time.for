      SUBROUTINE  INTEGRATE_TIME
!C
!C    This subroutine does the forward integeration in
!C     time to compute the dynamic response of the simulation.
!C     It was created from .MAIN and is called only by .MAIN
!C
!C                                                   Rev. V.3 12/15/2002 
!C

      USE  MODULE_STANDARD,  ONLY:  
     &        ISTEP, NSTEPS,                                  ! /COMAIN/
     &        NPG, NPRT, TIME,                                ! /CONTRL/
     &        IREAL_STD, LOGICAL_STD, LUTERM_OUT,             ! parameters
     &        I_0, I_1, D_0, R_100                            ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_STD )   PERCENT_TIME
!C
      LOGICAL  ( KIND = LOGICAL_STD )  L_NPRT1, L_NPRT2, L_NPRT3           

!C                                                                         
!C   Integration loop - advance time by integrating through Subroutine  
!C    DINTG.
!C                                                                         
      TIME = D_0                                                        
      DO  ISTEP=0,NSTEPS
       CALL DINTG                                                       
!C                                                                         
!C     1. Subroutine PRINT on primary output unit controlled 
!C        be NPRT(3). 
!C                                                                         
       IF ( NPRT(3) .GT. I_1 )   THEN
        L_NPRT3 = ( MOD ( ISTEP, NPRT(3) ) .EQ. I_0 )                    
       END IF
       IF ( L_NPRT3 )  CALL PRINT ( 'MAIN3D' )
!C                                                                         
!C     2. Program VIEW plot data on UNIT 1 controlled by NPRT(1).          
!C                                                                         
       L_NPRT1 = ( NPRT(1) .EQ. I_1 )                                   
       IF ( NPRT(1) .GT. I_1 )  THEN
        L_NPRT1 = ( MOD ( ISTEP, NPRT(1) ) .EQ. I_0 )                   
       END IF
       IF  ( L_NPRT1 )  CALL UNIT1                                      
!C                                                                         
!C     3. Subroutine ELTIME on primary output unit controlled 
!C         by NPRT(2).
!C                                                                         
       L_NPRT2 = ( NPRT(2) .EQ. I_1 )                                  
       IF ( NPRT(2) .GT. I_1 )  THEN
        L_NPRT2 = ( MOD ( ISTEP, NPRT(2) ) .EQ. I_0 )                   
       END IF
       IF ( L_NPRT2 )  CALL ELTIME ( NPG, I_1 )                        
!C
!C     Print out when each integration step is completed to show that
!C      the program is still functioning.
!C
       IF ( NSTEPS .GT. I_0 )  THEN
        PERCENT_TIME = R_100 * ( REAL ( ISTEP,  IREAL_STD ) / 
     &                                 REAL ( NSTEPS, IREAL_STD ) )
        WRITE  ( LUTERM_OUT, 125 )  ISTEP, NSTEPS, PERCENT_TIME
  125   FORMAT ( 1X, ' Step ', I6, ' of ', I6, ' ( ',
     &           F5.1, '% ) completed. ' )
       END IF
!C                                                                         
!C     End of integration loop.                                            
!C                                                                         
      END DO
!C
      RETURN
      END