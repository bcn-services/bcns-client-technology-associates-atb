      FUNCTION FNTERP ( THETA, PHI_LCL, NT )                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the restoring torque of a joint as a function of the     
!C    flexure angle (THETA) and the azimuth angle (PHI) as defined by     
!C    function No. NT                                                     
!C                                                                        
!C    Assumes  0  < THETA < PI                                            
!C            -PI <  PHI  < PI                                            
!C             data in TAB array contains NTHETA,NPHI followed by         
!C             two dimensional array of functional values (NTHETA > 0)    
!C             or polynomial coefficients (NTHETA < 0) for equally        
!C             spaced values of PHI.                                      
!C                                                                        
!C                  THETA(I) = (I-1)*PI/(NTHETA-1) for I=1,NTHETA         
!C                  PHI(J) = -PI + (J-1)*2*PI/NPHI for J=1,NPHI           
!C                      F(THETA,PI) = F(THETA,-PI)                        
!C                                                                        
!C    Subroutine evaluates G1(THETA) = F(THETA,PHI(J)  )                  
!C                         G2(THETA) = F(THETA,PHI(J+1))                  
!C               for  PHI(J) < PHI < PHI(J+1)                             
!C    by linear interpolation or polynomial evaluation and then linear    
!C    interpolates between G1 and G2 to obtain F(THETA,PHI).              
!C    If F < 0, F is set to zero, therefore a dead band is obtained       
!C    by negative values in the table.                                    
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS, PI, TWOPI,                     ! /CNSNTS/
     &        TAB, NTI,                           ! /TABLES/
     &        INTEGER_STD, IREAL_HIGH, LUAOU,     ! parameters 
     &        D_0, D_1, I_0, I_1, I_2, I_3, I_5   ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, IERROR, IP1, IP2, IT1, IT2, NF, NP1, NP2, NPHI, 
     &         NPOLY, NT, NT1, NTH, NTHETA
!C
      REAL  ( KIND = IREAL_HIGH )  FNTERP
      REAL  ( KIND = IREAL_HIGH )
     &                  G1, G2, PHI_LCL, RP1, RP2, RT1, RT2,
     &                  THETA, THETA1, THETA2, XNP, XNT 
!C
      IERROR = I_0                                                    
      IF ( PHI_LCL .LT. -PI )   IERROR = I_1                          
      IF ( PHI_LCL .GT.  PI )   IERROR = I_2                       
      IF ( THETA .LT. D_0 )     IERROR = I_3                             
!C
!C    If (THETA.GT.PI ) IERROR = 4                                        
!C
      IF ( IERROR .NE. I_0 )  THEN  
       WRITE ( LUAOU, 110 ) IERROR, THETA, PHI_LCL, NT             
  110  FORMAT ( '0 Improper arguments to Function FNTERP. error code =',
     &          I4, /, '0 THETA =', G25.15, ' PHI =', G25.15, ' NT =',
     &          I6 )                                                      
       STOP 36                         
      END IF
      NF = NTI(NT) + I_5                                               
      NTHETA = TAB(NF)                                                    
      NPHI   = TAB(NF+1)                                                  
!C                                                                        
!C    Determine index and interpolation parameters for PHI.               
!C                                                                        
      IF ( PHI_LCL .GE. ( PI - EPS(15) ) )  PHI_LCL = D_0 - PI          
      XNP = ( PHI_LCL + PI ) / TWOPI * TAB(NF+1)                           
      NP1 = XNP                                                           
      NP2 = NP1 + I_1                                                   
      IF ( NP2 .GE. NPHI )   NP2 = I_0                               
      RP2 = XNP - REAL ( NP1, IREAL_HIGH )                          
      RP1 = D_1 - RP2                                                     
      NTH = ABS ( NTHETA )                                                
      IP1 = NF + I_1 + NP1 * NTH                                       
      IP2 = NF + I_1 + NP2 * NTH                                       
!C                                                                        
!C    Determine index and interpolation parameters for THETA.             
!C                                                                        
      IF ( NTHETA .GE. I_0 )  THEN                                    
       XNT = THETA / PI * ( TAB(NF) - D_1 )                               
       NT1 = XNT                                                          
       RT2 = XNT - REAL ( NT1, IREAL_HIGH )                             
       RT1 = D_1 - RT2                                                    
       IT1 = IP1 + NT1                                                    
       IT2 = IP2 + NT1                                                    
       G1  = RT1 * TAB(IT1+1) + RT2 * TAB(IT1+2)                          
       G2  = RT1 * TAB(IT2+1) + RT2 * TAB(IT2+2)                          
      ELSE                                                                
!C                                                                        
!C     Compute for polynomials in THETA for fixed PHI.                    
!C                                                                        
       NPOLY = -NTHETA - I_1                                           
       IT1 = IP1 + NPOLY + I_2                                         
       IT2 = IP2 + NPOLY + I_2                                          
       THETA1 = THETA - TAB(IP1+1)                                        
       THETA2 = THETA - TAB(IP2+1)                                        
       G1 = D_0                                                         
       G2 = D_0                                                        
       DO  I=1,NPOLY                                                      
        IT1 = IT1 - I_1                                                
        IT2 = IT2 - I_1                                                 
        G1 = THETA1 * ( TAB(IT1) + G1 )                                   
        G2 = THETA2 * ( TAB(IT2) + G2 )                                   
       END DO
       IF ( THETA1 .LT. D_0 )  G1 = D_0                                
       IF ( THETA2 .LT. D_0 )  G2 = D_0                                
      END IF
      FNTERP = RP1 * G1 + RP2 * G2                                        
      IF ( FNTERP .LT. D_0 )   FNTERP = D_0                           
!C
      RETURN                                                              
      END                                                                 
