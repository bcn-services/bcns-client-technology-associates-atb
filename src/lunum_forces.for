      SUBROUTINE  LUNUM_FORCES ( NT )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine computes the total number of tabular time
!C     files needed, checks to be sure the maximum allowable number
!C     of tabular time histories is not exceeded.
!C    It is called only by Subroutine INPUT_HCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NBAG, NBLT, NHRNSS, NPL, NPRT, NSD, NSEG,          ! /CONTRL/
     &       NOUTPS, NOUTSS,                                    ! /COUT/  
     &       NPANEL,                                            ! /FORCES/
     &       NBLTPH,                                            ! /HRNESS/
     &       MNBAG, MNBLT, MNPL, MNSEG,                         ! /JBARTZ/
     &       AIRBAG_TTH, BELT_TTH, HARNESS_TTH, PLANE_SEG_TTH,  ! structures
     &       SEG_SEG_TTH, SPRING_DAMP_TTH, WATER_TTH,           ! structures
     &       INTEGER_STD, LUAOU, MAX_NUM_TTH, NUM_TTH_OFFSET,   ! parameters
     &       TRUE, FALSE,                                       ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_7, I_8, I_9,  ! parameters
     &       I_10, I_11, I_12, I_13, I_14, I_15, I_16           ! parameters
!C
      USE  MODULE_WATER,   ONLY:
     &       NWATER,              ! /WATINF1/
     &       ITYPE, NSEQN         ! /WFACOP/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &             I, J, JX, KBAG, KPS, KSS, MPSF, MSSF, NT, NTT
!C
      INTENT ( INOUT )  NT
!C
!C    Compute the number of plane/segment tabular time history files
!C     and initialize the belt tabular time history descriptor 
!C     structure, PLANE_SEG_TTH.
!C
      IF  ( ( NPL .NE. I_0 )  .AND.                           
     &      ( NPRT(18) .NE.  I_1 ) .AND.
     &      ( NPRT(18) .NE.  I_7 ) .AND.                           
     &      ( NPRT(18) .NE. I_10 ) .AND.
     &      ( NPRT(18) .NE. I_11 ) .AND.                        
     &      ( NPRT(18) .LT. I_14 )  )   THEN                
       NTT = I_0                                                     
       MPSF = I_0                                                   
       KPS = I_0                                                    
       DO  J=1,NPL                                                       
        IF ( MNPL(J) .GT. I_0 )   THEN                               
         DO  JX = 1,MNPL(J)                                             
          MPSF = MPSF + I_1                                           
          IF ( NOUTPS(MPSF) .EQ. I_1 )  THEN                         
           KPS = KPS + I_1                                           
          END IF                                                        
         END DO                                                         
        END IF                                                          
       END DO                                                           
       NTT = NTT + KPS                                                   
       IF ( NTT .GT. I_0 )  THEN
        PLANE_SEG_TTH%PRINT = TRUE
        PLANE_SEG_TTH%BEGIN_LUNUM = NT + I_1
        NT = NT + ( I_1 + NTT ) / I_2                                
        PLANE_SEG_TTH%END_LUNUM = NT
       ELSE
        PLANE_SEG_TTH%PRINT = FALSE
        PLANE_SEG_TTH%BEGIN_LUNUM = I_0
        PLANE_SEG_TTH%END_LUNUM = I_0
       END IF
!C
       IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
        WRITE ( LUAOU, 125 )
  125   FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &               'exceeded by the plane/seg contacts. ' )
        STOP ' STOP 2025 in Subroutine LUNUM_FORCES '
       END IF
!C
      ELSE
       PLANE_SEG_TTH%PRINT = FALSE
       PLANE_SEG_TTH%BEGIN_LUNUM = I_0
       PLANE_SEG_TTH%END_LUNUM = I_0
      END IF
!C
!C    Compute the number of simple belt tabular time history files
!C     and initialize the belt tabular time history descriptor 
!C     structure, BELT_TTH.
!C
      IF (  ( NBLT .NE. I_0 )  .AND.                              
     &      ( NPRT(18) .NE.  I_2 )  .AND.
     &      ( NPRT(18) .NE.  I_7 )  .AND.
     &      ( NPRT(18) .NE.  I_8  )  .AND.
     &      ( NPRT(18) .NE.  I_9  )  .AND. 
     &      ( NPRT(18) .LT.  I_13 )  )       THEN
       BELT_TTH%PRINT = TRUE
       NTT = I_0                                                  
       DO  J=1,NBLT                                                 
        NTT = NTT + MNBLT(J)                                      
       END DO
       BELT_TTH%BEGIN_LUNUM = NT + I_1
       NT = NT + ( I_1 + NTT ) / I_2                                    
       BELT_TTH%END_LUNUM = NT
!C
       IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
        WRITE ( LUAOU, 130 )
  130   FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &               'exceeded by the simple belts. ' )
        STOP ' STOP 2030 in Subroutine LUNUM_FORCES '
       END IF
!C
      ELSE
       BELT_TTH%PRINT = FALSE
       BELT_TTH%BEGIN_LUNUM = I_0
       BELT_TTH%END_LUNUM = I_0
      END IF
!C
!C    Compute number of harness force tabular time history files
!C     and initialize the belt tabular time history descriptor 
!C     structure, HARNESS_TTH.
!C
      IF (  ( NHRNSS .GT. I_0 ) .AND.                                             
     &      ( NPRT(18) .NE.  I_3 )   .AND.
     &      ( NPRT(18) .NE.  I_8 )   .AND.
     &      ( NPRT(18) .NE.  I_9 )    .AND.
     &      ( NPRT(18) .NE.  I_11 )   .AND.
     &      ( NPRT(18) .NE.  I_13 )   .AND.
     &      ( NPRT(18) .NE.  I_14 )   .AND.
     &      ( NPRT(18) .LT.  I_16 )  )      THEN             
       HARNESS_TTH%PRINT = TRUE
       NTT = I_0                                                     
       DO  I=1,NHRNSS                                                   
        NTT = NTT + NBLTPH(I)                                           
       END DO
       HARNESS_TTH%BEGIN_LUNUM = NT + I_1
       NT = NT + ( I_1 + NTT ) / 2                                  
       HARNESS_TTH%END_LUNUM = NT
!C
       IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
        WRITE ( LUAOU, 135 )
  135   FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &               'exceeded by the harnesses. ' )
        STOP ' STOP 2035 in Subroutine LUNUM_FORCES '
       END IF
!C
      ELSE
       HARNESS_TTH%PRINT = FALSE
       HARNESS_TTH%BEGIN_LUNUM = I_0
       HARNESS_TTH%END_LUNUM = I_0
      END IF                                                      
!C
!C    Compute the number of spring damper tabular time history files
!C     and initialize the belt tabular time history descriptor 
!C     structure, SPRING_DAMP_TTH.
!C
      IF (  ( NSD .GT. I_0  )  .AND.                              
     &      ( NPRT(18) .NE.  I_4 )  .AND.
     &      ( NPRT(18) .NE.  I_9  )  .AND.
     &      ( NPRT(18) .LT.  I_12 )  )    THEN               
       SPRING_DAMP_TTH%PRINT = TRUE
       SPRING_DAMP_TTH%BEGIN_LUNUM = NT + I_1
       NT = NT + ( I_1 + NSD ) / I_2                         
       SPRING_DAMP_TTH%END_LUNUM = NT
!C
       IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
        WRITE ( LUAOU, 140 )
  140   FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &               'exceeded by the spring dampers. ' )
        STOP ' STOP 2040 in Subroutine LUNUM_FORCES '
       END IF
!C
      ELSE
       SPRING_DAMP_TTH%PRINT = FALSE
       SPRING_DAMP_TTH%BEGIN_LUNUM = I_0
       SPRING_DAMP_TTH%END_LUNUM = I_0
      END IF                                                            
!C
!C    Compute the number of seg/seg tabular time history files
!C     and initialize the belt tabular time history descriptor 
!C     structure, SEG_SEG_TTH.
!C
      IF  ( ( NPRT(18) .NE.  I_5 )  .AND.
     &      ( NPRT(18) .NE. I_10 )  .AND.
     &      ( NPRT(18) .NE. I_11 )  .AND.                  
     &      ( NPRT(18) .NE. I_13 )  .AND.                   
     &      ( NPRT(18) .LT. I_15 )  )      THEN                
       NTT = I_0                                                     
       MSSF = I_0                                                   
       KSS = I_0                                                    
       DO  J=1,NSEG                                                      
        IF ( MNSEG(J) .GT. I_0 )  THEN                            
         DO  JX = 1,MNSEG(J)                                            
          MSSF = MSSF + I_1                                         
          IF ( NOUTSS(MSSF) .EQ. I_1 )   THEN                        
           KSS = KSS + I_1                                            
          END IF                                                        
         END DO                                                         
        END IF                                                          
       END DO                                                           
       NTT = NTT + KSS                                                   
       IF ( NTT .GT. I_0 )  THEN
        SEG_SEG_TTH%BEGIN_LUNUM = NT + I_1
        SEG_SEG_TTH%PRINT = TRUE
        NT = NT + NTT                                                 
        SEG_SEG_TTH%END_LUNUM = NT
       ELSE  
        SEG_SEG_TTH%PRINT = FALSE
        SEG_SEG_TTH%BEGIN_LUNUM = I_0
        SEG_SEG_TTH%END_LUNUM  = I_0
       END IF
!C
       IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
        WRITE ( LUAOU, 145 )
  145   FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &               'exceeded by the seg/seg contacts. ' )
        STOP ' STOP 2045 in Subroutine LUNUM_FORCES '
       END IF
!C
      ELSE
       SEG_SEG_TTH%PRINT = FALSE
       SEG_SEG_TTH%BEGIN_LUNUM = I_0
       SEG_SEG_TTH%END_LUNUM = I_0
      END IF
!C
!C    Compute the number of airbag tabular time history files
!C     and initialize the belt tabular time history descriptor 
!C     structure, AIRBAG_TTH.
!C
      IF  (  ( NBAG .NE. I_0 ) .AND.                         
     &       ( NPRT(18) .NE.  I_6 ) .AND.
     &       ( NPRT(18) .NE.  I_9 ) .AND.
     &       ( NPRT(18) .LT.  I_12 )  )   THEN              
       AIRBAG_TTH%PRINT = TRUE
       NTT = I_0                                                     
       DO  J=1,NBAG                                                     
        IF ( MNBAG(J) .NE. I_0 )  THEN                              
         KBAG = MNBAG(J) + NPANEL(J) + I_5                       
         NTT = NTT + ( I_3 + KBAG ) / I_4                      
        END IF                                                          
       END DO                                                           
       AIRBAG_TTH%BEGIN_LUNUM = NT + I_1
       NT = NT + NTT                                                    
       AIRBAG_TTH%END_LUNUM = NT
!C
       IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
        WRITE ( LUAOU, 150 )
  150   FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &               'exceeded by the airbags. ' )
        STOP ' STOP 2050 in Subroutine LUNUM_FORCES '
       END IF
!C
      ELSE
       AIRBAG_TTH%PRINT = FALSE
       AIRBAG_TTH%BEGIN_LUNUM = I_0
       AIRBAG_TTH%END_LUNUM = I_0
      END IF
!C                                                                      
!C    Compute the number of water force tabular time history files.
!C
      IF ( NWATER .NE. I_0 )   THEN                                 
       WATER_TTH%PRINT = TRUE
       NTT = I_0                                                      
       DO  J=1,5                                                         
        NTT = NTT + ITYPE(J)                                             
       END DO
       WATER_TTH%BEGIN_LUNUM = NT + I_1
       NT = NT + I_1 + NTT * NSEQN                                     
       WATER_TTH%END_LUNUM = NT
!C
       IF ( NT .GT. ( MAX_NUM_TTH + NUM_TTH_OFFSET ) )  THEN
        WRITE ( LUAOU, 155 )
  155   FORMAT ( 1X, ' Maximum number of tabular time histories ',
     &               'exceeded by the water forces. ' )
        STOP ' STOP 2055 in Subroutine LUNUM_FORCES '
       END IF
!C
      ELSE
       WATER_TTH%PRINT = FALSE
       WATER_TTH%BEGIN_LUNUM = I_0
       WATER_TTH%END_LUNUM = I_0
      END IF                                                       
!C
      RETURN
      END
      