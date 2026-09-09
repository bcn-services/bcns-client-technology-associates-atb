      SUBROUTINE HERRON ( HD3, NT1, THET0, THET0P )                       
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C     Computes THET0 - angle of joint stop                               
!C              THET0P- derivative of THET0 with respect to PHI_LCL       
!C                                                                        
!C         from HD3   - components of vector defining PHI_LCL             
!C              NT1   - index to TAB array defining function              
!C                                                                        
      USE  MODULE_STANDARD,  ONLY: 
     &         TWOPI,                                 ! /CNSNTS/
     &         TAB,                                   ! /TABLES/
     &         INTEGER_STD, IREAL_HIGH,               ! parameters
     &         D_0, D_1, D_2, D_3, D_4, D_5, I_0, I_1 ! parameters                  
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  NT1
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  CP, HD3, P1_LCL, P1P, P2_LCL, P2P, PHI_LCL,
     &                  SP, STH, STH2, THET0, THET0P
      DIMENSION         HD3(3)                                            
!C
      REAL  ( KIND = IREAL_HIGH )    EVALFD
      EXTERNAL          EVALFD
!C
      INTENT (  IN )  HD3, NT1
      INTENT ( OUT )  THET0, THET0P
!C
      IF ( ( TAB(NT1+1) .LE. D_0 )  .OR.                              
     &     ( TAB(NT1+2) .LE. D_0 ) )   THEN                             
!C                                                                        
!C     Evaluate THET0 and THET0P from regular function definition where   
!C     THET0 (ordinate) is a function of PHI (abscissa)  
!c     (0 < PHI < 2*PI)  
!C                                                                        
       PHI_LCL = ATAN2 ( HD3(2), HD3(1) )                                 
       IF ( PHI_LCL .LT. D_0 )  PHI_LCL = PHI_LCL + TWOPI                 
       THET0  = EVALFD ( PHI_LCL, NT1, I_1 )                            
       THET0P = EVALFD ( PHI_LCL, NT1, I_0 )                         
       RETURN                                                             
      END IF
!C                                                                        
!C    THET0 = P1_LCL(CP) + SP*P2_LCL(CP)                                  
!C                                                                        
!C    THET0P = -SP*P1_LCL'(CP) + CP*P2_LCL(CP) - SP**2*P2_LCL'(CP)        
!C                                                                        
!C        where P1_LCL(X),P2_LCL(X) are the D_2 5th order polynomials     
!C                  defined in TAB(NT1+5) and TAB(NT1+11)                 
!C              P1_LCL'(X),P2_LCL'(X) are their derivatives with          
!C                  respect to PHI_LCL and SP,CP are SIN(PHI) 
!C                  and COS(PHI)                                          
!C                                                                        
      STH2 = D_1 - HD3(3)**2                                             
      STH  = SQRT ( STH2 )                                                
      CP   = HD3(1) / STH                                                 
      SP   = HD3(2) / STH                                                 
      P1_LCL   = TAB(NT1+5 ) + CP * ( TAB(NT1+6 )                         
     &                       + CP * ( TAB(NT1+7 )                         
     &                       + CP * ( TAB(NT1+8 )                         
     &                       + CP * ( TAB(NT1+9 )                         
     &                       + CP * ( TAB(NT1+10) ) ) ) ) )               
      P2_LCL   = TAB(NT1+11) + CP * ( TAB(NT1+12)                         
     &                       + CP * ( TAB(NT1+13)                         
     &                       + CP * ( TAB(NT1+14)                         
     &                       + CP * ( TAB(NT1+15)                         
     &                       + CP * ( TAB(NT1+16) ) ) ) ) )               
      P1P      = TAB(NT1+6 ) + CP * ( D_2   * TAB(NT1+7 )                
     &                       + CP * ( D_3 * TAB(NT1+8 )                
     &                       + CP * ( D_4  * TAB(NT1+9 )                
     &                       + CP * ( D_5  * TAB(NT1+10) ) ) ) )        
      P2P      = TAB(NT1+12) + CP * ( D_2   * TAB(NT1+13)               
     &                       + CP * ( D_3 * TAB(NT1+14)                
     &                       + CP * ( D_4  * TAB(NT1+15)                 
     &                       + CP * ( D_5  * TAB(NT1+16) ) ) ) )         
      THET0  = P1_LCL + SP * P2_LCL                                       
      THET0P = CP * P2_LCL - SP * ( P1P + SP * P2P )                      
!C
      RETURN                                                              
      END                                                                 
