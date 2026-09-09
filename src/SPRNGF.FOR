      FUNCTION SPRNGF ( T, D_LCL, ZD, SPR, JSTOP_LCL )  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes nonlinear spring torque for joints as a function of angle  
!C    actually routine returns TORQUE/ABS(SIN THETA)                     
!C                                                                       
!C    Arguments:                                                          
!C         T     : COS THETA where THETA is angle of joint (0<THETA<PI)   
!C         D     : ABS(SIN THETA)                                        
!C         ZD    : -THETA DOT * SIN THETA                                 
!C         SPR   : array of 5 values describing function evaluation       
!C         JSTOP : indicator to be set to one if joint is in stop         
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS,                         ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,     ! parameters
     &        I_0, I_1, D_0, D_HALF, D_1   ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  JSTOP_LCL 
!C
      REAL  ( KIND = IREAL_HIGH )  SPRNGF
      REAL  ( KIND = IREAL_HIGH )
     &                D_LCL, Q, SPR, T, U_LCL, X, Y_LCL, Z, ZD 
      DIMENSION         SPR(5)                                            
!C
      INTENT (     IN )  D_LCL, ZD, SPR
      INTENT (    OUT )  JSTOP_LCL
      INTENT (  INOUT )  T
!C                                                                       
!C     Reset T = 1 IF T > 1 ( HAD & HBD in VISPR )                            
!C                                                                        
      IF  ( T .GT.  D_1 )  T =  D_1                                     
      IF  ( T .LT. -D_1 )  T = -D_1                                      
      Z = ACOS ( T )                                                      
      U_LCL = EPS(1) * D_LCL                                             
      Q = D_0                                                           
      IF ( D_LCL .NE. D_0 )  Q = -ZD / U_LCL                           
      IF ( Q .GT.  D_1 )  THEN
       Q =  D_1                                    
      ELSE IF ( Q .LT. -D_1 )  THEN
       Q = -D_1                                 
      END IF
      X = D_HALF * ( D_1 + SPR(4) + Q * ( D_1 - SPR(4) ) )                  
      Y_LCL = D_0                                                       
      IF ( D_LCL .NE. D_0 )  Y_LCL = Z / D_LCL                          
      Q = D_1                                                           
      IF ( ABS ( Z ) .LT. EPS(4) )  Y_LCL = SIGN ( Q, Z )                
      SPRNGF = Y_LCL * SPR(1)                                             
      JSTOP_LCL = I_0                                                  
      IF  ( SPR(5) .GT. D_0 )  THEN                                     
       IF ( Z .LT. SPR(5) )  THEN 
        RETURN                                                            
       ELSE
        JSTOP_LCL = I_1                                                
        Z = Z - SPR(5)                                                    
        SPRNGF = SPRNGF + X / D_LCL * ( SPR(2) + Z * SPR(3) ) * Z**2     
       END IF
      ELSE
       SPRNGF = X * SPRNGF                                                
      END IF                                                              
!C                                                                        
      RETURN                                                              
      END                                                                
