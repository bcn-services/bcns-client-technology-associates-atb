      SUBROUTINE SOLVR ( A1, A2, A3, A4, A5, A6, A7, A8, P, RX, RZ )       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine solves a set of simultaneous equations to     
!C     find componets of vector R that satisfy the properties needed
!C     to determine the equation of the projected ellipse.              
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       IREAL_HIGH, D_1, D_2, D_4  ! parameters
!C
      IMPLICIT  NONE                                                      
!C                                                                         
      REAL  ( KIND = IREAL_HIGH )
     &                  A1, A2, A3, A4, A5, A6, A7, A8, B_LCL,
     &                  D_LCL, P, RX, RZ, T1, T2_LCL, T3
      DIMENSION P(3)                                                       
!C
      INTENT (  IN )  A1, A2, A3, A4, A5, A6, A7, A8, P
      INTENT ( OUT )  RX, RZ
!C
      B_LCL  = A1 * P(1) + A2 * P(2) + A3 * P(3)                           
      D_LCL  = A4 * P(1) + A5 * P(2) + A6 * P(3)                           
      T1     = A7 * ( D_LCL / B_LCL)**2 + A6 - D_2 * A8 * D_LCL / B_LCL    
      T2_LCL = D_2 * A7 * D_LCL / ( B_LCL )**2 - D_2 * A8 / B_LCL          
      T3     = A7 * ( D_1 / B_LCL)**2 - D_1                               
      RZ     = ( -T2_LCL + SQRT ( T2_LCL**2 - D_4 * T1 * T3 ) ) 
     &                         / ( D_2 * T1 )                            
      RX     = -D_LCL * RZ / B_LCL - ( D_1 / B_LCL )                      
!C
      RETURN                                                              
      END                                                                 
