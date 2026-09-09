      SUBROUTINE PANEL ( DRR, ZR, JB )                                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C     Computes airbag parameters during inflation of bag.                 
!C                                                                         
!C         Given: DRR - DC matrix relative to vehicle                      
!C                 ZR - CG location in vehicle reference                   
!C                                                                         
!C       Compute: SEGLP,SEGLV,SEGLA,D,WMEG & WMEGD for segment JB.         
!C                                                                        
      USE  MODULE_STANDARD, ONLY: 
     &        NVEH,                          ! /CONTRL/
     &        SEG,                           ! structures
     &        INTEGER_STD, IREAL_HIGH        ! parameters
!C
!C    ANG_ACCEL, ANG_VEL, DIR_COS, LIN_ACCEL,   %SEG
!C    LIN_DISP,  LIN_VEL                        %SEG
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  JB
!C
      REAL  ( KIND = IREAL_HIGH )  DRR, T1, T2_LCL, ZR
      DIMENSION         DRR(3,3), ZR(3), T1(3), T2_LCL(3)              
!C
      INTENT ( IN )  DRR, ZR, JB
!C
      CALL MAT33 ( DRR, SEG(NVEH)%DIR_COS,    SEG(JB)%DIR_COS )            
      CALL MAT31 ( DRR, SEG(NVEH)%ANG_VEL,    SEG(JB)%ANG_VEL )         
      CALL DOT31 ( SEG(NVEH)%DIR_COS, ZR,     SEG(JB)%LIN_DISP )                
      CALL CROSS ( SEG(NVEH)%ANG_VEL, ZR,     T1 )                          
      CALL DOT31 ( SEG(NVEH)%DIR_COS, T1,     SEG(JB)%LIN_VEL )                 
      CALL CROSS ( SEG(NVEH)%ANG_VEL, T1,     T2_LCL )                   
      CALL DOT31 ( SEG(NVEH)%DIR_COS, T2_LCL, SEG(JB)%LIN_ACCEL )              
      SEG(JB)%ANG_ACCEL = SEG(NVEH)%ANG_ACCEL                         
      SEG(JB)%LIN_ACCEL = SEG(JB)%LIN_ACCEL   + SEG(NVEH)%LIN_ACCEL       
      SEG(JB)%LIN_DISP  = SEG(JB)%LIN_DISP    + SEG(NVEH)%LIN_DISP     
      SEG(JB)%LIN_VEL   = SEG(JB)%LIN_VEL     + SEG(NVEH)%LIN_VEL            
!C
      RETURN                                                             
      END                                                                 
