      SUBROUTINE  DEF_NEW_CUBIC ( L, M, D_LCL )
!C
!C                                               Rev. V.3 12/15/2002 
!C
!C    This subroutine defines a new 
!C     cubic function.
!C
!C    Was created from Subroutine UPDFDC.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       TIME,                                ! /CONTRL/
     &       NTAB, TAB,                           ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH, I_11, I_14, ! parameters 
     &       I_0, D_0, D_HALF, D_1, D_2 , D_3     ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  L, LC, LQ, M, NI 
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A0, A1, A2, A3, A33, D_LCL, DC0, 
     &                  DCUBIC, DG, DISC, DREF, DX,
     &                  ELOSS, FR1, FR2, R1, R13, R2, R23,  
     &                  SQDISC, X, X1, X2, X2DOT, 
     &                  Y1, Y1P, Y2, Y2P
!C
      INTENT (    IN ) L, M, D_LCL
!C
!C    Retrieve function values.
!C
      DG     = TAB(L+5)                                                   
      DREF   = TAB(L+7)                                                   
      DC0    = TAB(L+18)                                                  
      LQ     = L + I_11                                                     
      LC     = L + I_14                                                     
!C                                                                        
!C    D < DCUBIC, define new cubic:                                        
!C    Y(X) = A0 + A1*(X-X1) + A2*(X-X1)**2 + A3*(X-X1)**3                 
!C    whose derivative is:                                                 
!C    Y'(X) = A1 + 2*A2*(X-X1) + 3*A3+(X-X1)**2                           
!C                                                                        
      X1 = MAX ( D_LCL, DG )                                              
      X2 = DREF                                                           
!C                                                                        
!C    If inertial spike exists and if DIMAX < DREF , drop 
!C     inertial spike  
!C
      NI = NTAB(M+2)                                                      
      IF ( ( NI .GT. I_0 ) .AND. ( TAB(NI+3) .GT. D_0 ) .AND.
     &     ( DREF .GT. TAB(NI+3) ) )  NTAB(M+2) = I_0  
      DX = X2 - X1                                                        
      X = X1 - DG                                                         
      Y1 = TAB(LQ) + X * ( TAB(LQ+1) + X * TAB(LQ+2) )                    
      Y1P = TAB(LQ+1) + D_2 * X * TAB(LQ+2)                             
      X2DOT = D_0                                                      
      CALL FRCDFL ( X2, X2DOT, M, 0, Y2P, ELOSS )                         
      CALL FRCDFL ( X2, X2DOT, M, 1, Y2 , ELOSS )                         
      DCUBIC = X1                                                         
      DC0    = DCUBIC                                                     
!C                                                                        
!C    A0 = Y(X1)   (the value of the quadratic at X1)                     
!C    A1 = Y'(X1)  (the derivative of the quadratic at X1)                
!C                                                                        
      A0 = Y1                                                             
      A1 = Y1P                                                            
!C                                                                        
!C    Solve simultaneously for A2 and A3                                  
!C       A2*(X2-X1)**2 +    A3*(X2-X1)**3 = Y(X2)-A0-A1*(X2-X1)           
!C     2*A2*(X2-X1)    +  3*A3*(X2-X1)**2 = Y'(X2)-A1                     
!C                                                                        
      R13 = (  Y2 - Y1 - Y1P * DX ) / DX**2                               
      R23 = ( Y2P -  Y1P ) / DX                                           
      A2  = D_3 * R13 - R23                                            
      A3  = ( R23 - D_2 * R13 ) / DX                                     
!C                                                                        
!C    If local minimun of cubic (abscissa value where Y'(X) = 0)          
!C    lies between DCUBIC and DREF and is negative, then replace          
!C    cubic definition with straight line between (X1,Y1) and (X2,Y2).    
!C                                                                        
      IF ( A3 .NE. D_0 )  THEN                                         
       A33 = D_3 * A3                                                  
       DISC = A2**2 - A1 * A33                                            
       IF ( DISC .LT. D_0 )  THEN                                   
        CALL  UPDATE_TAB ( L, LC, A0, A1, A2, A3, DCUBIC, DC0, D_LCL )
        RETURN                                                               
       END IF
!C
       SQDISC = SQRT ( DISC )                                             
       R1 = ( -A2 + SQDISC ) / A33                                        
       IF ( ( R1 .GT. D_0 ) .AND. ( R1 .LT. DX ) )  THEN             
        FR1 = A0 + R1 * ( A1 + R1 * ( A2 + R1 * A3 ) )                    
        IF ( FR1 .LT. D_0 )  THEN                            
         A0 = Y1                                                             
         A1 = ( Y2 - Y1 ) / DX                                               
         A2 = D_0                                                           
         A3 = D_0                                                          
         CALL UPDATE_TAB ( L, LC, A0, A1, A2, A3, DCUBIC, DC0, D_LCL )
         RETURN
        END IF
       END IF
       R2 = ( -A2 - SQDISC ) / A33                                        
      ELSE
       IF ( A2 .EQ. D_0 )  THEN                                    
        R2 = D_0                                                 
       ELSE                                                             
        R2 = -D_HALF * A1 / A2                                              
       END IF                                                           
      END IF
!C
      IF ( ( R2 .LE. D_0 ) .OR. ( R2 .GE. DX ) )  THEN                  
       CALL  UPDATE_TAB ( L, LC, A0, A1, A2, A3, DCUBIC, DC0, D_LCL )
       RETURN                                                               
      END IF
!C
      FR2 = A0 + R2 * ( A1 + R2 * ( A2 + R2 * A3 ) )                      
      IF ( FR2 .LT. D_0 )  THEN                                    
       A0 = Y1                                                             
       A1 = ( Y2 - Y1 ) / DX                                               
       A2 = D_0                                                           
       A3 = D_0                                                          
      END IF
      CALL UPDATE_TAB ( L, LC, A0, A1, A2, A3, DCUBIC, DC0, D_LCL )
!C
      RETURN                                                               
!C
      END