      FUNCTION  ELONG ( A, B_LCL, C_LCL, D_LCL, E_LCL )  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C     Computes arc length of ellipse       AX**2 + 2BXY + CY**2 = 1       
!C      from THETA = 0 (positive X axis) to THETA = E (radians)                 
!C      where D is nominal increment of integration.                        
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:  
     &        INTEGER_STD, IREAL_HIGH, 
     &        D_0, D_1, D_2, D_3, I_0, I_2  ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )  I, N
!C
      REAL  ( KIND = IREAL_HIGH )  ELONG 
      REAL  ( KIND = IREAL_HIGH )
     &                  A, AC, B_LCL, BAC, C_LCL, CS, CSS, D_LCL, 
     &                  DCS, DSN, E_LCL, F_LCL, G_LCL, S, SN, T, Z
!C
      N = ABS ( E_LCL / D_LCL)                                             
      N = N + N                                                            
      IF ( N .EQ. I_0 )  N = I_2                                   
      Z = REAL ( N, IREAL_HIGH )                                                               
      T = E_LCL / Z                                                        
      F_LCL = SQRT ( ( D_1 + ( B_LCL / A )**2 ) / A )                       
      CS = D_1                                                             
      SN = D_0                                                            
      DCS = COS ( T )                                                      
      DSN = SIN ( T )                                                      
      S = F_LCL / D_2                                                      
      AC = A + C_LCL                                                       
      BAC = B_LCL * B_LCL - A * C_LCL                                      
      DO  I=1,N,2                                                          
       CSS = CS * DCS - SN * DSN                                           
       SN  = SN * DCS + CS * DSN                                           
       CS  = CSS                                                           
       G_LCL = ( A * CS     + B_LCL * SN ) * CS +
     &         ( B_LCL * CS + C_LCL * SN ) * SN                            
       G_LCL = G_LCL**2 / ( AC + BAC / G_LCL )                             
       F_LCL = ( F_LCL + D_1 / ( F_LCL * G_LCL ) ) / D_2                  
       S = S + F_LCL + F_LCL                                               
       CSS = CS * DCS - SN * DSN                                           
       SN = SN * DCS + CS * DSN                                            
       CS = CSS                                                            
       G_LCL = ( A * CS + B_LCL * SN ) * CS 
     &       + ( B_LCL * CS + C_LCL * SN ) * SN                            
       G_LCL = G_LCL**2 / ( AC + BAC / G_LCL )                             
       F_LCL = ( F_LCL + D_1 / ( F_LCL * G_LCL ) ) / D_2                 
       S     = S + F_LCL                                                   
      END DO                                                               
      ELONG = ( S + S - F_LCL) * T / D_3                              
!C
      RETURN                                                               
      END                                                                  
