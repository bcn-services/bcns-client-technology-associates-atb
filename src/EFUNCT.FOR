      FUNCTION EFUNCT ( TH, THD, SPR, JSTOP_LCL )        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes nonlinear srring torque for Euler joints.                  
!C                                                                        
!C    Arguments:                                                          
!C         TH    - THETA is the angle of the Euler axis                   
!C         THD   - THETA dot                                              
!C         SPR   - array of 5 values describing function evaluation       
!C     JSTOP_LCL - indicator to be set to one if in stop                  
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH,               ! parameters
     &       I_0, I_1, D_0, D_HALF, D_1,  D_10      ! parameters 
!C
      IMPLICIT  NONE                                                      
!C
      INTEGER  ( KIND = INTEGER_STD )  JSTOP_LCL
!C
      REAL  ( KIND = IREAL_HIGH )  EFUNCT
      REAL  ( KIND = IREAL_HIGH )  TH, THD, Q, X, SPR, Z
      DIMENSION SPR(5)                                                    
!C
      INTENT (  IN )  TH, THD, SPR
      INTENT ( OUT )  JSTOP_LCL
!C
      JSTOP_LCL = I_0                                                  
      EFUNCT = TH * SPR(1)                                                
      Q = SIGN ( D_10 * THD, TH * THD )                                   
      IF ( Q .GT.  D_1 )  Q =  D_1                                  
      IF ( Q .LT. -D_1 )  Q = -D_1                                  
      X = D_HALF * ( D_1 + SPR(4) + Q * ( D_1 - SPR(4) ) )                   
      IF ( SPR(5) .LE. D_0 )  THEN                                     
       EFUNCT = X * EFUNCT                                                
       RETURN                                                             
      END IF
      IF ( ABS ( TH ) .LT. SPR(5) )  RETURN                               
      JSTOP_LCL = I_1                                                   
      Z = ABS ( TH )  - SPR(5)                                            
      EFUNCT = EFUNCT + 
     &         SIGN ( X * ( SPR(2) + Z * SPR(3) ) * Z**2, TH )            
!C
      RETURN                                                              
      END                                                                 
