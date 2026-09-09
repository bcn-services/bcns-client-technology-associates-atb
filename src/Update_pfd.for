      SUBROUTINE UPDATE_PFD ( KSEG, FRC, TQE_LCL, DELP1, DARM )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        SEG,                     ! structures
     &        INTEGER_STD, IREAL_HIGH  ! parameters 
!C
!C    DIR_COS, EXT_ANG_ACL, EXT_LIN_ACL          ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  KSEG
!C
      REAL  ( KIND = IREAL_HIGH )
     &                 DARM, DELP1, FRC, TM3, TM4, TQE_LCL
      DIMENSION         TM3(3), TM4(3), FRC(3), TQE_LCL(3), 
     &                  DELP1(3,3), DARM(3)
!C
!C    Convert force to segment frame = TM3
!C    Find torque due to TMP3 at the c.g of segment = TM4 (seg frame)
!C    Find force in inertial frame = FRC
!C    Convert torque at the center of ellipsoid in its frame to seg fr.= TM3
!C    Add TM3 and TM4 to find the total torque at the c.g in local frame.
!C
      CALL DOT31 ( DELP1,             FRC,     TM3 )
      CALL CROSS ( DARM,              TM3,     TM4 )
      CALL DOT31 ( SEG(KSEG)%DIR_COS, TM3,     FRC )
      CALL DOT31 ( DELP1,             TQE_LCL, TM3 )
!C
      TQE_LCL = TM3 + TM4
!c
      SEG(KSEG)%EXT_LIN_ACL = SEG(KSEG)%EXT_LIN_ACL + FRC
      SEG(KSEG)%EXT_ANG_ACL = SEG(KSEG)%EXT_ANG_ACL + TQE_LCL                      
!C
      RETURN
      END
