      SUBROUTINE OUTPUT ( IJK_LCL )                                       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Controls tabulated output on fortran units (starting with no. 21)   
!C    of selected optional segment linear and angular accelerations,      
!C    velocities and displacements, joint parameters and selected data    
!C    from all allowed contact force computations between body segments   
!C    and vehicle components.                                             
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       EPS,                                   ! /CNSNTS/
     &       BELT_FORCE,                            ! /CNTSRF/
     &       DT,                                    ! /COMAIN/
     &       NPRT, TIME,                            ! /CONTRL/
     &       DAMP_FORCE,                            ! /DAMPER/
     &       BAGSF, HARNESS_FORCE, PRJNT, PSF, SSF, ! /FORCES/        
     &       OUT_TIMES,                             ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,  ! parameters
     &       MAXJNT, MAXPSF, MAXSSF,                ! parameters
     &       MAX_LN_PPAGE, NUM_TTH_OFFSET,          ! parameters
     &       NUM_OUT_TIMES, FALSE, TRUE,            ! parameters
     &       D_0, D_1000,                           ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_8 ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, IJK_LCL, LINES, NT
!C
      REAL  ( KIND = IREAL_HIGH )   TEST, USEC_LCL
!C
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTAPE8, LTHIST, RETURN_STATE,
     &                                 LTABH     
!C
      DATA  LINES / -1 /   
!C                                                                        
      INTENT ( IN )  IJK_LCL
!C
      IF ( IJK_LCL .EQ. I_0 )  THEN                             
!C                                                                        
!C     If LJK_LCL = 0, set all the force arrays to zero, then return.
!C                                                                        
       PSF =           D_0
       HARNESS_FORCE = D_0
       BELT_FORCE =    D_0
       DAMP_FORCE =    D_0
       SSF =           D_0
       BAGSF =         D_0
       PRJNT =         D_0
       RETURN
      END IF
!C                                                                       
!C    LTHIST = .TRUE. Means print line of time history data for this      
!C                        time point on each output unit (NT).            
!C                                                                        
!C    LTAPE8 = .TRUE. means write time history data on Tape 8.            
!C                                                                        
!C    Check the logic for NPRT(4) plus NPRT(26) to see where the
!C     data will be written to.
!C
      LTABH = FALSE
      IF  ( ( NPRT(4) .LT. -I_3 ) .OR. 
     &      ( NPRT(4) .GT. I_4 )  )  STOP 37    
      IF ( NPRT(26) .EQ. I_6 )  THEN                            
       RETURN
      END IF
      IF ( NPRT(4) .EQ. -I_1 )  THEN
       RETURN
      ELSE IF ( NPRT(4) .EQ. I_0 )  THEN
       LTAPE8 = FALSE                                                
       TEST = MOD ( TIME, DT )                                           
       TEST = MIN ( TEST, ABS ( DT - TEST ) )                             
       IF ( ( ( NPRT(26) .EQ. I_0 ) .OR. ( NPRT(26) .EQ. I_3 ) ) 
     &    .AND. ( TEST .GE. EPS(8) ) )  THEN                              
        LTHIST = FALSE                                                
        RETURN
       ELSE
        LTHIST = TRUE
       END IF
      ELSE IF ( ( NPRT(4) .EQ. I_1 ) .OR. 
     &          ( NPRT(4) .EQ. I_4 ) )  THEN
       LTAPE8 = TRUE                                                  
       TEST = MOD ( TIME, DT )                                            
       TEST = MIN ( TEST, ABS ( DT - TEST ) )                             
       IF ( ( ( NPRT(26) .EQ. I_0 ) .OR. ( NPRT(26) .EQ. I_3 ) ) 
     &    .AND. ( TEST .GE. EPS(8) ) )    THEN                            
        LTHIST = FALSE                                             
       ELSE
        LTHIST = TRUE
       END IF
      ELSE IF ( ( NPRT(4) .EQ. I_2 ) .OR. ( NPRT(4) .EQ. I_3 ) ) THEN
       LTHIST = FALSE                                                  
       LTAPE8 = TRUE 
       LTABH = TRUE 
      END IF
!C
      IF ( NPRT(26) .EQ. I_4 )   LTHIST = FALSE                     
      IF ( NPRT(26) .EQ. I_5 )   LTAPE8 = FALSE
      IF ( LTABH .AND. (NPRT(26) .GE. I_4) ) LTABH = FALSE                       
      IF  ( ( .NOT. LTAPE8 ) .AND. ( .NOT. LTHIST ) )  THEN               
       RETURN
      END IF
!C
      CALL ELTIME ( I_1, I_8 )                                                
!C
!C    If it is the first time in the subroutine ( LINES < 0 ),
!C     call Subroutine HCARD_INPUT to read the H card control data
!C     associated with Cards H.1 throught H.11.
!C
      IF  ( LINES .LT. I_0 )  THEN                                    
       CALL OUTPUT_SETUP ( LINES, LTAPE8, LTHIST, LTABH ) 
       LINES = I_0
      END IF
!C
      IF ( LTHIST ) LINES = LINES + I_1                               
!C
!C    Call Subroutine HEDING to write a heading on the beginning
!C     of a new page of tabular time history data if the previous 
!C     page was filled, and the output is to be in page form
!C     ( NPRT(19) = 0 ).  If NPRT(19) # 0, the tabular time history
!C     data will be in a continous columnar form, with a heading only
!C     at the beginning of the file.
!C
      IF  ( ( MOD ( LINES, MAX_LN_PPAGE ) .EQ. I_1 ) .AND. LTHIST
     &                              .AND. ( NPRT(19) .EQ. I_0 ) )  
     &  CALL HEDING ( LINES, MAX_LN_PPAGE )                             
!C
      NT = NUM_TTH_OFFSET                                                 
!C
!C    Check if time windowing is in effect, and if so, will there
!C     be a output from Subroutine OUTPUT on this call.
!C
      IF ( NUM_OUT_TIMES .EQ. I_0 )  THEN
       CONTINUE
      ELSE
       RETURN_STATE = TRUE
       DO I=1,NUM_OUT_TIMES
        IF ( .NOT. OUT_TIMES(I)%TTH ) THEN
         RETURN_STATE = FALSE
         CYCLE
        ELSE 
         IF ( ( TIME .GE. OUT_TIMES(I)%START ) .AND.
     &        ( TIME. LE. OUT_TIMES(I)%END ) )  THEN
          RETURN_STATE = FALSE
         END IF
        END IF
       END DO
       IF ( RETURN_STATE )  THEN
        CALL ELTIME ( I_2, I_8 )                            
        RETURN
       END IF
      END IF
!C
!C    Convert the time from seconds to milliseconds.
!C
      USEC_LCL = D_1000 * TIME                             
!C
!C    Output the data associated with Cards H.1 through H.11
!C
      CALL OUTPUT_HCARDS ( LTAPE8, LTHIST, NT, USEC_LCL )
!C                                                                        
!C    Print body properties                                          
!C                                                                        
      CALL OUTPUT_BODY_PROP (LTAPE8, LTHIST, NT, USEC_LCL )
!C
!C    Output the force data.
!C
      CALL OUTPUT_FORCES ( LTAPE8, LTHIST, NT, USEC_LCL )
!C
      CALL ELTIME ( I_2, I_8 )                                               
!C
      RETURN                                                              
      END                                                                
