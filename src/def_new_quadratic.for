      SUBROUTINE  DEF_NEW_QUADRATIC ( L, M, D_LCL, DCUBIC )
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C    This subroutine defines a new quadratic function.
!C
!C    It was created from Subroutine UPDFDC.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       TIME,                                   ! /CONTRL/
     &       NTAB, TAB,                              ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH, I_11, I_14,    ! parameters 
     &       I_0, I_1, I_2, D_0, D_1, D_2 ,D_3, D_4  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  L, LC, LQ, M, NB, NG, NI, NR  
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A0, A1, A2,  AREA_LCL, D_LCL, D0, DC0, 
     &                  DCUBIC, DG, DINER, DREF, DX,
     &                  GLAST, RAREA, RLAST, X, X1, X2, Y1, Y2
!C 
      REAL  ( KIND = IREAL_HIGH )   EVALFD
      EXTERNAL          EVALFD
!C
      INTENT (    IN )  L, D_LCL
      INTENT ( INOUT )  M, DCUBIC
!C
!C    Retrieve function values.
!C
      AREA_LCL   = TAB(L+2)                                               
      RLAST  = TAB(L+3)                                                   
      GLAST  = TAB(L+4)                                                   
      DG     = TAB(L+5)                                                   
      DREF   = TAB(L+7)                                                   
      DINER  = TAB(L+9)                                                   
      DC0    = TAB(L+18)                                                  
      LQ     = L + I_11                                                     
      LC     = L + I_14                                                     
!C
      IF ( ( D_LCL - DREF ) .LE.  D_0  ) THEN
!C                                                                        
!C     DCUBIC < D < DREF, define new quadratic from cubic curve.           
!C                                                                        
       X = D_LCL - DC0                                                     
       Y2 = TAB(LC) + X * ( TAB(LC+1) +
     &                X * ( TAB(LC+2) + X * TAB(LC+3) ) )         
       X1 = DCUBIC - DG                                                    
       AREA_LCL = X1 * ( TAB(LQ) + X1 * ( TAB(LQ+1) / D_2
     &                           + X1 * TAB(LQ+2) / D_3 ) )       
     &                           + X * ( TAB(LC) 
     &                           + X * ( TAB(LC+1) / D_2
     &                           + X * ( TAB(LC+2) / D_3 
     &                           + X * TAB(LC+3) / D_4 ) ) )     
       X = DCUBIC - DC0                                                    
!C
       IF ( X .NE. D_0 )   THEN
         AREA_LCL =   AREA_LCL  - X * ( TAB(LC) 
     &                          + X * ( TAB(LC+1) / D_2
     &                          + X * ( TAB(LC+2) / D_3
     &                          + X * TAB(LC+3) / D_4 ) ) )                                                             
       END IF
      ELSE
!C                                                                        
!C     DREF < D, define new quadratic from base curve.                     
!C                                                                        
!C     If DINER < D , remove inertial spike                                
!C                                                                        
       IF  ( ( NTAB(M+2) .GT. I_0 ) .AND. 
     &       ( D_LCL .GE. DINER ) )    NTAB(M+2) = I_0        
       NR = NTAB(M+3)                                                      
       RLAST = D_1                                                         
       IF ( NR .GT. I_0 )    RLAST = EVALFD ( D_LCL, NR, I_1 )            
       IF ( RLAST .EQ. D_1 )  THEN                                        
!C                                                                        
!C      R = 1,  use base curve for unloading                               
!C                                                                        
        DG = D_0                                                         
        DCUBIC = D_0                                                     
        DREF = D_0                                                         
        A0 = D_0                                                       
        A1 = D_0                                                      
        A2 = D_0                                                        
!C                                                                        
!C      Restore TAB values that may have been changed.                       
!C                                                                        
        TAB(L+2) = AREA_LCL                                                 
        TAB(L+3) = RLAST                                                    
        TAB(L+4) = GLAST                                                    
        TAB(L+5) = DG                                                       
        TAB(L+6) = DCUBIC                                                   
        TAB(L+7) = DREF                                                     
        TAB(LQ)   = A0                                                      
        TAB(LQ+1) = A1                                                      
        TAB(LQ+2) = A2                                                     
        TAB(L+1) = D_LCL                                                    
        TAB(L+30) = TIME                                                     
        RETURN
       END IF
!C
       NG = NTAB(M+4)                                                      
       GLAST = D_0                                                     
       IF ( NG .GT. I_0  )  GLAST = EVALFD ( D_LCL, NG, I_1 )        
       NB =  NTAB(M+1)                                                     
       D0 = TAB(NB)                                                        
       DG = D0 + GLAST * ( D_LCL - D0 )                                    
       Y2 = EVALFD ( D_LCL, NB, I_1 )                                  
       NI = NTAB(M+2)                                                      
       IF  ( NI .GT. I_0 )  Y2 = Y2 + EVALFD ( D_LCL, NI, I_1 )      
       AREA_LCL = EVALFD ( D_LCL, NB, I_2 )                             
       DREF = D_LCL                                                        
      END IF
!C
      DCUBIC = D_LCL                                                      
      X1 = DG                                                             
      X2 = D_LCL                                                          
      DX = X2 - X1                                                      
      Y1 = D_0                                                     
      RAREA = RLAST * AREA_LCL                                            
!C                                                                        
!C    Compute unloading quadratic coefficients such that                  
!C    endpoint derivates are non-negative.                                
!C                                                                        
      A0  = D_0                                                      
      A1  = D_2 / DX * ( D_3 * RAREA / DX - Y2 )    
      IF  ( A1 .LT. D_0 )   A1 = D_0                                    
      A2 = ( Y2 / DX - A1 ) / DX                                          
      IF ( A2 .LT. D_0 )  THEN                                          
       A1 = Y2 / DX                                                       
       A2 = D_0                                                        
      END IF
!C                                                                        
!C    Restore TAB values that may have been changed.                       
!C                                                                        
      TAB(L+2)  = AREA_LCL                                                 
      TAB(L+3)  = RLAST                                                    
      TAB(L+4)  = GLAST                                                    
      TAB(L+5)  = DG                                                       
      TAB(L+6)  = DCUBIC                                                   
      TAB(L+7)  = DREF                                                     
      TAB(LQ)   = A0                                                      
      TAB(LQ+1) = A1                                                      
      TAB(LQ+2) = A2                                                     
      TAB(L+1)  = D_LCL                                                    
      TAB(L+30) = TIME                                                     
!C
      RETURN
      END