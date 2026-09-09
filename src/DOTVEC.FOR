      FUNCTION  DOTVEC ( A, B_LCL)
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Performs vector multiplication DOTVEC = A.B            
!C
      USE  MODULE_STANDARD,  ONLY:
     &       IREAL_HIGH      ! parameters
!C
      IMPLICIT  NONE                                                    
!C
      REAL ( KIND = IREAL_HIGH )  DOTVEC       
      REAL ( KIND = IREAL_HIGH )   A, B_LCL
      DIMENSION  A(3), B_LCL(3)                                         
!C
      INTENT ( IN )  A, B_LCL
!C
      DOTVEC = A(1) * B_LCL(1) + A(2) * B_LCL(2) + A(3) * B_LCL(3)           
!C
      RETURN                                                            
      END                                                               
