      FUNCTION VISCOS ( ZD, VISC_LCL, HA_LCL )           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes sum of Coulomb and viscous torques                         
!C     at joints as a function of THETA DOT.                               
!C
!C    Subroutine actually returns SUM/ZD.                                    
!C                                                                       
!C        Arguments:                                                      
!C         ZD  : !THETA DOT! where THETA is the angle of the joint.       
!C         VISC: array of 5 values describing function evaluation.       
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:
     &       IREAL_HIGH, D_2              ! parameters
!C                                                                      
      IMPLICIT  NONE                                                     
!C
      REAL  ( KIND = IREAL_HIGH )   VISCOS
      REAL  ( KIND = IREAL_HIGH )   HA_LCL, VISC_LCL, Z, ZD 
      DIMENSION         VISC_LCL(7)                                       
!C
      INTENT (  IN )  ZD, VISC_LCL
      INTENT ( OUT )  HA_LCL
!C
      Z = ZD                                                             
      IF ( ZD .LT. VISC_LCL(3) )  THEN
       Z = VISC_LCL(3) / ( D_2 - ZD / VISC_LCL(3) )    
      END IF
      HA_LCL = ( Z - ZD ) / Z                                            
      VISCOS = VISC_LCL(1) + VISC_LCL(2) / Z                                  
!C
      RETURN                                                            
      END                                                                
