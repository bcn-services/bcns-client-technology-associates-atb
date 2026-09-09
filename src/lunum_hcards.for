      SUBROUTINE  LUNUM_HCARDS ( JRNUM, NT )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine computes the logical unit numbers for the
!C     tabular time histories associated with H Cards.
!C    It is called ony by Subroutine INPUT_HCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       MCG, NSG,                                        ! /RSAVE/
     &       INTEGER_STD, LUAOU, MAX_NUM_TTH, NUM_TTH_OFFSET, ! parameters
     &       ACUATOR_TTH, ANG_ACCEL_TTH, ANG_ROT_TTH,         ! structures
     &       ANG_VEL_TTH, CG_TTH, JOINT_FORCE_TTH,            ! structures
     &       JOINT_PARM_TTH, LIN_ACCEL_TTH,                   ! structures
     &       LIN_DISP_TTH, LIN_VEL_TTH, WIND_TTH,             ! structures
     &       TRUE, FALSE,                                     ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6                ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, JRNUM, NT
!C
      INTENT (    IN )  JRNUM
      INTENT ( INOUT )  NT
!C
!C    Initialize the logical unit number for the tabular time 
!C     histories.
!C
      NT = NUM_TTH_OFFSET
!C
!C    Check the 1st 6 types of H Card input.
!C
      DO  I=1,6                                                   
       IF ( NSG(I) .GT. I_0 )  THEN
        IF ( I .EQ. I_1 )  THEN
         LIN_ACCEL_TTH%BEGIN_LUNUM = NT + I_1
         LIN_ACCEL_TTH%PRINT = TRUE
         NT = NT + ( I_2 + NSG(I) ) / I_3                        
         LIN_ACCEL_TTH%END_LUNUM = NT
        ELSE IF ( I .EQ. I_2 )  THEN
         LIN_VEL_TTH%BEGIN_LUNUM = NT + I_1
         LIN_VEL_TTH%PRINT = TRUE
         NT = NT + ( I_2 + NSG(I) ) / I_3                      
         LIN_VEL_TTH%END_LUNUM = NT
        ELSE IF ( I .EQ. I_3 )  THEN
         LIN_DISP_TTH%BEGIN_LUNUM = NT + I_1
         LIN_DISP_TTH%PRINT = TRUE
         NT = NT + ( I_2 + NSG(I) ) / I_3                      
         LIN_DISP_TTH%END_LUNUM = NT
        ELSE IF ( I .EQ. I_4 )  THEN
         ANG_ACCEL_TTH%BEGIN_LUNUM = NT + I_1
         ANG_ACCEL_TTH%PRINT = TRUE
         NT = NT + ( I_2 + NSG(I) ) / I_3                        
         ANG_ACCEL_TTH%END_LUNUM = NT
        ELSE IF ( I .EQ. I_5 )  THEN
         ANG_VEL_TTH%BEGIN_LUNUM = NT + I_1
         ANG_VEL_TTH%PRINT = TRUE
         NT = NT + ( I_2 + NSG(I) ) / I_3                     
         ANG_VEL_TTH%END_LUNUM = NT
        ELSE IF ( I .EQ. I_6 )  THEN
         ANG_ROT_TTH%BEGIN_LUNUM = NT + I_1
         ANG_ROT_TTH%PRINT = TRUE
         NT = NT + ( I_2 + NSG(I) ) / I_3 + JRNUM          
         ANG_ROT_TTH%END_LUNUM = NT
        END IF
       ELSE
        IF ( I .EQ. I_1 )  THEN
         LIN_ACCEL_TTH%BEGIN_LUNUM = I_0
         LIN_ACCEL_TTH%PRINT = FALSE
         LIN_ACCEL_TTH%END_LUNUM = I_0
        ELSE IF ( I .EQ. I_2 )  THEN
         LIN_VEL_TTH%BEGIN_LUNUM = I_0
         LIN_VEL_TTH%PRINT = FALSE
         LIN_VEL_TTH%END_LUNUM = I_0
        ELSE IF ( I .EQ. I_3 )  THEN
         LIN_DISP_TTH%BEGIN_LUNUM = I_0
         LIN_DISP_TTH%PRINT = FALSE
         LIN_DISP_TTH%END_LUNUM = I_0
        ELSE IF ( I .EQ. I_4 )  THEN
         ANG_ACCEL_TTH%BEGIN_LUNUM = I_0
         ANG_ACCEL_TTH%PRINT = FALSE
         ANG_ACCEL_TTH%END_LUNUM = I_0
        ELSE IF ( I .EQ. I_5 )  THEN
         ANG_VEL_TTH%BEGIN_LUNUM = I_0
         ANG_VEL_TTH%PRINT = FALSE
         ANG_VEL_TTH%END_LUNUM = I_0
        ELSE IF ( I .EQ. I_6 )  THEN
         ANG_ROT_TTH%BEGIN_LUNUM = I_0
         ANG_ROT_TTH%PRINT = FALSE
         ANG_ROT_TTH%END_LUNUM = I_0
        END IF
       END IF
      END DO
!C
!C    Check the joint parameter output (H.7 Cards).
!C
      IF ( NSG(7) .GT. I_0 )  THEN
       JOINT_PARM_TTH%BEGIN_LUNUM = NT + I_1
       JOINT_PARM_TTH%PRINT = TRUE
       NT = NT + ( I_1 + NSG(7) ) / I_2                           
       JOINT_PARM_TTH%END_LUNUM = NT
      ELSE
       JOINT_PARM_TTH%BEGIN_LUNUM = I_0
       JOINT_PARM_TTH%PRINT = FALSE
       JOINT_PARM_TTH%END_LUNUM = I_0
      END IF
!C
!C    Check the wind parameter output (H.8 Cards).
!C
      IF ( NSG(8) .GT. I_0 )  THEN
       WIND_TTH%BEGIN_LUNUM = NT + I_1
       WIND_TTH%PRINT = TRUE
       NT = NT + ( I_2 + NSG(8) ) / I_3
       WIND_TTH%END_LUNUM = NT
      ELSE
       WIND_TTH%BEGIN_LUNUM = I_0
       WIND_TTH%PRINT = FALSE
       WIND_TTH%END_LUNUM = I_0
      END IF
!C
!C    Check the joint force output (H.9 Cards).
!C
      IF ( NSG(9) .GT. I_0 )  THEN
       JOINT_FORCE_TTH%BEGIN_LUNUM = NT + I_1
       JOINT_FORCE_TTH%PRINT = TRUE
       NT = NT + NSG(9)                                           
       JOINT_FORCE_TTH%END_LUNUM = NT
      ELSE
       JOINT_FORCE_TTH%BEGIN_LUNUM = I_0
       JOINT_FORCE_TTH%PRINT = FALSE
       JOINT_FORCE_TTH%END_LUNUM = I_0
      END IF
!C
!C    Check the acuator output (H.11 Cards).
!C
      IF ( NSG(10) .GT. I_0 )  THEN
       ACUATOR_TTH%BEGIN_LUNUM = NT + I_1
       ACUATOR_TTH%PRINT = TRUE
       NT = NT + ( I_1 + NSG(10) ) / I_2                       
       ACUATOR_TTH%END_LUNUM = NT
      ELSE
       ACUATOR_TTH%BEGIN_LUNUM = I_0
       ACUATOR_TTH%PRINT = FALSE
       ACUATOR_TTH%END_LUNUM = I_0
      END IF
!C
!C    Check the c.g. and body output (H.10 Cards).
!C    Note that even though H.10 comes before H.11 in the input,
!C     the tabular time histories for H.11 are printed before
!C     the tabular time histories for H.10.
!C
      IF ( MCG .GT. I_0 )  THEN
       CG_TTH%BEGIN_LUNUM = NT + I_1
       CG_TTH%PRINT = TRUE
       NT = NT + I_2 * MCG                             
       CG_TTH%END_LUNUM = NT
      ELSE
       CG_TTH%BEGIN_LUNUM = I_0
       CG_TTH%PRINT = FALSE
       CG_TTH%END_LUNUM = I_0
      END IF
!C
!C*********
!C
!C    Check to see if the number of logical units exceeds the maximum
!C     number allowed.
!C 
      IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
       WRITE ( LUAOU, 120 )
  120  FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &              'exceeded by the H Cards. ' )
       STOP ' STOP 2020 in Subroutine LUNUM_HCARDS '
      END IF
!C
      RETURN
      END
       