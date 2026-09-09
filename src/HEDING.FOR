      SUBROUTINE HEDING ( LINES, LPP )                                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       EPS,                                   ! /CNSNTS/
     &       NPRT,                                  ! /CONTRL/
     &       MCG, NSG,                              ! /RSAVE/
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,  ! parameters 
     &       NUM_TTH_OFFSET, TRUE, FALSE,           ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_6, I_7,     ! parameters
     &       I_8, I_9, I_10                         ! parameters
!C
      USE  MODULE_WATER,  ONLY:  NWATER   ! /WATINF1/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )   
     &                 KSG, LINES, LPP, MT, NLINES, NT
!C
      REAL  ( KIND = IREAL_HIGH )   XPAGE
!C
      LOGICAL ( KIND = LOGICAL_STD )   LNEW
!C
      INTENT ( IN )  LINES, LPP
!C
      IF      ( NPRT(4) .EQ. -I_3 )  THEN
       LNEW = TRUE
      ELSE IF ( NPRT(4) .EQ. -I_2 )  THEN
       LNEW = TRUE
      ELSE IF ( NPRT(4) .EQ. -I_1 )  THEN 
       RETURN
      ELSE IF ( NPRT(4) .EQ.  I_0 )  THEN
       LNEW = FALSE
      ELSE IF ( NPRT(4) .EQ.  I_1 )  THEN
       LNEW = FALSE    
      ELSE IF ( NPRT(4) .EQ.  I_2 )  THEN
       LNEW = TRUE
      ELSE IF ( NPRT(4) .EQ.  I_3 )  THEN
       LNEW = TRUE
      ELSE IF ( NPRT(4) .EQ.  I_4 )  THEN
       LNEW = FALSE
      END IF
!C
      MT = NUM_TTH_OFFSET                                                 
      NLINES = MOD ( ( LINES - I_1 ), LPP ) + I_1             
      XPAGE = EPS(2) * 
     &        REAL ( ( ( LINES + LPP - I_1 ) / LPP ), IREAL_HIGH )   
!C                                                                        
!C    Note: MT will be the page or output unit counter                    
!C          NT will be the actual output unit number                      
!C          IT will be the index to the data array                        
!C          NLINES will be the number of lines to be printed              
!C                                                                        
!C    Print the H Card related tabular time history headings for
!C     cards H.1 through H.5.
!C
      CALL HEDING_HCARDS ( LNEW, MT, NT, NLINES, XPAGE )
!C
!C    Print the angular displacement tabular time histories ( Cards H.6).
!C
      KSG = NSG(I_6)
      IF ( KSG .GT. I_0 )  THEN
       CALL HEDING_ANG_DISPL ( LNEW, MT, NT, NLINES, XPAGE, KSG ) 
      END IF
!C
!C    Print the joint parameter tabular time histories ( Cards H.7).
!C
      KSG = NSG(I_7)
      IF ( KSG .GT. I_0 )  THEN
        CALL HEDING_JNT_PARM ( LNEW, MT, NT, NLINES, XPAGE, KSG ) 
      END IF
!C
!C    Print the wind force tabular time histories ( Cards H.8 ).
!C
      KSG = NSG(I_8)
      IF ( KSG .GT. I_0 )  THEN
       CALL HEDING_WIND ( LNEW, MT, NT, NLINES, XPAGE, KSG ) 
      END IF
!C
!C    Print the joint force tabular time histories ( Cards H.9 ).
!C
      KSG = NSG(I_9)
      IF ( KSG .GT. I_0 )  THEN
       CALL HEDING_JOINT_FORCES ( LNEW, MT, NT, NLINES, XPAGE, KSG ) 
      END IF
!C
!C    Print the actuator tabular time histories ( Cards H.11 ).
!C     Note that this card is referred to as Card H.11 in the input
!C     description but it is placed in the 10th position in the
!C     arrays containing the tabular time histories.
!C
      KSG = NSG(I_10)
      IF ( KSG .GT. I_0 )  THEN                                      
       CALL HEDING_ACTUATORS ( LNEW, MT, NT, NLINES, XPAGE, KSG )
      END IF        
!C
!C    Print the tabular time history headings for the 
!C     body property data ( Cards H.10 ).
!C
      IF ( MCG .NE. I_0 )  THEN
       CALL HEDING_BODY_PROP ( LNEW, MT, NT, NLINES, XPAGE ) 
      END IF                                
!C
!C    Print the forces related tabular time history headings.
!C
      CALL HEDING_FORCES ( LNEW, MT, NT, NLINES, XPAGE )
!C                                                                        
!C    Print the water force headings.
!C                                                                      
      IF ( NWATER .GT. I_0 )  THEN
       CALL HEDING_WATER ( LNEW, MT, NT, NLINES, XPAGE )   
      END IF
!C                                                                       
      RETURN                                                            
      END                                                                 
