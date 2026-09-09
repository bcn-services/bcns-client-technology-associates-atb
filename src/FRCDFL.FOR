      SUBROUTINE FRCDFL ( D_LCL, RATE, M, N, FRCDF, ELOSS )               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Evaluate force deflection function at point D, where definition     
!C    of function is controlled by M index of NTAB array.                 
!C    Derivative, function or integral is evaluated as N = 0,1 or 2.      
!C       NTAB(M)    -  index to TAB array for real data                   
!C       NTAB(M+1)  -  index to TAB array for base function               
!C       NTAB(M+2)  -  index to TAB array for inertial function, if any   
!C                                                                        
!C    Assumes  0 < DG < DCUBIC < DREF < DMAX                              
!C              but any < may be less than or equal to                    
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:   
     &       NTAB, TAB,                            ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH,              ! parameters
     &       I_0 , I_1, I_11, I_14, D_0, D_2, D_3  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              L, LC, LQ, M, N, NB,  NI 
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  D_LCL, DC0, DCUBIC, DG, DMAX, DREF, ELOSS, 
     &                  F_LCL, FDMAX, FRCDF, RATE, X
!C
      REAL  ( KIND = IREAL_HIGH )   EVALFD
      EXTERNAL  EVALFD
!C
      F_LCL = D_0                                                       
      ELOSS = D_0                                                       
      L = NTAB(M)                                                         
      TAB(L) = D_LCL                                                      
      IF ( D_LCL .LT. D_0 )  THEN
       FRCDF = F_LCL                                                      
       RETURN
      END IF
      DMAX = TAB(L+8)                                                     
      IF ( D_LCL .GE. DMAX )  THEN                                        
!C                                                                        
!C     DMAX < D , use max value                                           
!C                                                                        
       IF ( ( ( N - I_1 ) .LT. I_0 ) .OR. 
     &      ( ( N - I_1 ) .GT. I_0 ) )  THEN
        FRCDF = F_LCL                                                     
       ELSE
        FDMAX = TAB(L+10)                                                 
        F_LCL = FDMAX                                                     
        CALL  FUNC_RATE_DEP ( D_LCL, F_LCL, RATE, M, N, FRCDF, ELOSS )
       END IF
       RETURN
      END IF
!C
      DREF = TAB(L+7)                                                     
      IF ( D_LCL .GE. DREF )  THEN
!C                                                                        
!C     DREF < D < DMAX, use base function                                  
!C                                                                        
       IF ( ( N - I_1 ) .GT. I_0 )  THEN                                      
        FRCDF = F_LCL                                                      
        RETURN
       END IF
       NB = NTAB(M+1)                                                      
!C                                                                         
!C     Evaluate base function                                              
!C                                                                         
       IF ( NB .GT. I_0 )  F_LCL = EVALFD ( D_LCL, NB, N )                                    
       NI = NTAB(M+2)                                                      
!C                                                                         
!C     Add inertial function , if any                                      
!C                                                                         
       IF ( NI .GT. I_0 )  F_LCL = F_LCL + EVALFD ( D_LCL, NI, N )               
       CALL  FUNC_RATE_DEP ( D_LCL, F_LCL, RATE, M, N, FRCDF, ELOSS )
       RETURN                                    
      END IF
!C
      DCUBIC = TAB(L+6)                                                   
      IF ( ( DCUBIC .GE. DREF )  .OR. ( D_LCL .LE. DCUBIC ) )  THEN
       DG = TAB(L+5)                                                       
       IF ( D_LCL .LE. DG )  THEN 
        CALL  FUNC_RATE_DEP ( D_LCL, F_LCL, RATE, M, N, FRCDF, ELOSS )
        RETURN
       END IF
!C                                                                         
!C     DG < D < DCUBIC , use quadratic                                     
!C                                                                         
       LQ = L + I_11                                           
       X = D_LCL - DG                                                      
       IF ( ( N - I_1 ) .EQ. I_0 )  THEN                              
!C                                                                         
!C      Use quadratic definition                                           
!C                                                                         
        F_LCL = TAB(LQ) + X * ( TAB(LQ+1) + X * TAB(LQ+2) )                
        CALL  FUNC_RATE_DEP ( D_LCL, F_LCL, RATE, M, N, FRCDF, ELOSS )
       ELSE IF ( ( N - I_1 ) .LT. I_0 )  THEN
!C                                                                         
!C      Use derivative of quadratic.                                       
!C                                                                         
        F_LCL = TAB(LQ+1) + X * D_2 * TAB(LQ+2)                        
        FRCDF = F_LCL                                                      
       ELSE
        FRCDF = F_LCL                                                      
       END IF
       RETURN
      END IF
!C                                                                        
!C    DCUBIC < D < DREF , use cubic                                       
!C                                                                        
      LC = L + I_14                                             
      DC0 = TAB(L+18)                                                     
      X = D_LCL - DC0                                                     
      IF ( ( N - I_1 ) .LT. I_0 )  THEN                                  
!C                                                                        
!C     Use derivative of cubic                                            
!C                                                                        
       F_LCL = TAB(LC+1) + X * ( D_2 * TAB(LC+2) +
     &                     X * D_3 * TAB(LC+3) )               
       FRCDF = F_LCL                                                      
      ELSE IF ( ( N - I_1 ) .EQ. I_0 )  THEN
!C                                                                        
!C     Use cubic definition                                               
!C                                                                        
       F_LCL = TAB(LC) + X * ( TAB(LC+1) + X * ( TAB(LC+2) + 
     &                                     X *   TAB(LC+3) ) )            
       CALL  FUNC_RATE_DEP ( D_LCL, F_LCL, RATE, M, N, FRCDF, ELOSS )
      ELSE
       FRCDF = F_LCL                                                      
      END IF
!C
      RETURN                                                              
      END                                                                 
