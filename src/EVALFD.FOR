      FUNCTION  EVALFD ( D_ABSCISSA, N, L )         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Evaluate function that is defined at location N of tab array        
!C    for abscissa value D.  Evaluates derivative, function or integral   
!C    as L equals 0, 1, or 2. TAB array is defined as follows:            
!C       TAB(N)    -  D0 (no restrictions on D0)                          
!C       TAB(N+1)  -  D1 (F1 defined for D0 < D < |D1|)                   
!C       TAB(N+2)  -  D2 (F2 defined for |D1| < D < |D2|)                 
!C       TAB(N+3)  -  (not currently used)                                
!C       TAB(N+4)  -  (not currently used)                                
!C       TAB(N+5)  -  start of definition of 1st part of function (F1)    
!C       which is followed by definition of 2nd part of function (F2),    
!C                               if any.                                  
!C       2nd part of function exists if D2 is non-zero.                   
!C       Sign of D1 determines form of definition for 1st part of         
!C                              the function.                             
!C                                                                        
!C            D1 zero indicates that function is constant D2 for all D.   
!C                                                                        
!C            D1 positive indicates that TAB(N+5)-TAB(N+10) contains      
!C            A0,A1,...A5.   the coefficients of A 5th order polynomial.  
!C                                                                        
!C            D1 negative indicates that TAB(N+5) contains NP (REAL)      
!C            followed by   D(1), F(1), D(2), F(2) ..., D(NP), F(NP)      
!C                                                                        
!C            Warning- tabular function must be defined for whole range,  
!C            that is, from D0 to D1 inclusive, or D1 to D2 inclusive.    
!C                                                                        
!C                                                                        
!C       Similarly, the sign of D2 (if non-zero) determines form of       
!C       definition of 2nd part of function, if any.                      
!C                                                                        
!C                                                                        
!C    If D < D0    and  D1#0, derivative = 0 or function = F1(D0)         
!C    If D > !D1!  and  D2=0, derivative = 0 or function = F1(|D1|)       
!C    If D > !D2!  and  D2#0, derivative = 0 or function = F2(|D2|)       
!C                                                                        
!C    Note: previous versions assumed that D0 was non-negative and        
!C          that F = 0 for D < D0.                                        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       TAB,                                ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH,            ! parameters
     &       I_0, I_1, I_2, I_5, I_6,            ! parameters
     &       D_0, D_1, D_2                       ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                  IOUTR, L, MB, MP, N, NB, NP
!C
      REAL  ( KIND = IREAL_HIGH )  EVALFD
      REAL  ( KIND = IREAL_HIGH )
     &                D_ABSCISSA, D0, D1, D2, FUNC_VAL, X
!C
      INTENT  ( IN )   D_ABSCISSA, N, L
!C
      FUNC_VAL = D_0                                                        
      IOUTR = I_0                                                     
      D0 = TAB(N)                                                         
      D1 = TAB(N+1)                                                       
      D2 = TAB(N+2)                                                       
      IF  ( D1 .EQ. D_0 )  THEN                                         
       IF  ( ( L - I_1 ) .LT. I_0 )  THEN
        CONTINUE                                         
       ELSE IF ( ( L - I_1 ) .EQ. I_0 )  THEN
        FUNC_VAL = D2                                                        
       ELSE
        FUNC_VAL = ( D_ABSCISSA - D0 ) * D2                                       
       END IF
       EVALFD = FUNC_VAL                                                     
       RETURN
      END IF
!C                                                                        
!C    Compute index of F1 definition                                      
!C                                                                        
      NP = N + I_5                                                    
      IF ( L .EQ. I_2 )  THEN                                      
       IF  ( D_ABSCISSA .NE. D0 )  THEN
        CALL EVALFD_INTEGRAL ( NP, D_ABSCISSA, D0, D1, D2, FUNC_VAL )
       END IF
       EVALFD = FUNC_VAL                                                      
       RETURN
      END IF
!C                                                                        
!C    Derivatives and functions here, integrals have other logic          
!C                                                                        
      IF ( D_ABSCISSA .LT. D0 )  THEN                                       
!C                                                                        
!C     D < D0, return F = 0 for L = 0, or F = F1(D0) for L = 1.                    
!C                                                                        
       IF ( L .EQ. I_0 )  THEN                                      
        EVALFD = FUNC_VAL                                                      
        RETURN
       END IF
       X = D0                                                              
       IF ( D1 .GT. D_0 )  THEN
        CALL EVALFD_POLY ( IOUTR, L, NP, X, FUNC_VAL )
       ELSE
        FUNC_VAL = TAB(NP+2)                                                   
       END IF
       EVALFD = FUNC_VAL                                                      
       RETURN                                                            
      END IF
!C
      IF ( D_ABSCISSA .GE. ABS ( D1 ) )  THEN                              
       IF ( D2 .NE. D_0 )  THEN                                      
!C                                                                        
!C      D .GE. !D1!,  D2 non-zero,  use F2                                  
!C                                                                        
        MP = I_6                                                              
!C                                                                        
!C      Compute index of F2 definition                                      
!C                                                                        
        IF ( D1 .LT. D_0 )  MP = D_2 * TAB(NP) + D_1                      
        NP = NP + MP                                                        
        IF ( D_ABSCISSA .LT. ABS ( D2 ) )  THEN
!C                                                                        
!C       !D1! .LE. D < !D2!                                                  
!C                                                                        
         IF ( D2 .GE. D_0 )  THEN                                     
          X = D_ABSCISSA                                                           
          CALL EVALFD_POLY ( IOUTR, L, NP, X, FUNC_VAL )
         ELSE
!C                                                                         
!C        Evaluate F from tabular definition                                  
!C                                                                         
          CALL EVALFD_TABLE  ( L, NP, D_ABSCISSA, FUNC_VAL ) 
         END IF
!C
         EVALFD = FUNC_VAL                                                      
         RETURN                              
        END IF
!C
        IF ( D2 .GE. D_0 )  THEN                                      
!C                                                                        
!C       IOUTR = 1 indicates D Beyond range. Derivative = 0.                
!C       IOUTR = 0 indicates D.LE.!D2!. Compute poly derivative             
!C                                                                        
         IF ( D_ABSCISSA .GT. ABS ( D2 ) )  IOUTR = I_1                        
!C                                                                        
!C       D .GE. D2 (positive), evaluate F2 for D2                            
!C                                                                         
         X = D2                                                              
         CALL EVALFD_POLY ( IOUTR, L, NP, X, FUNC_VAL )
         EVALFD = FUNC_VAL
         RETURN
        END IF
!C                                                                        
!C      D exceeds tabular definition, set F = F(NP)                         
!C      If table definition extends beyond range, use table values          
!C                                                                        
        MB = TAB(NP)                                                        
        NB = NP + MB + MB                                                   
        IF ( D_ABSCISSA .LE. TAB(NB-1) )  THEN
         CALL EVALFD_TABLE  ( L, NP, D_ABSCISSA, FUNC_VAL ) 
        ELSE IF ( L .EQ. I_1 )  THEN
         FUNC_VAL = TAB(NB)                              
        END IF
        EVALFD = FUNC_VAL
        RETURN
       END IF
!C                                                                        
!C     D  .GE. !D1!, D2 = 0                                                 
!C                                                                        
       IF ( D1 .LE. D_0 )  THEN                                     
!C                                                                        
!C      D exceeds tabular definition, set F = F(NP)                         
!C      If table definition extends beyond range, use table values          
!C                                                                        
        MB = TAB(NP)                                                        
        NB = NP + MB + MB                                                   
        IF ( D_ABSCISSA .LE. TAB(NB-1) )  THEN
         CALL EVALFD_TABLE  ( L, NP, D_ABSCISSA, FUNC_VAL ) 
        ELSE IF ( L .EQ. I_1 )  THEN
         FUNC_VAL = TAB(NB)                              
        END IF
       ELSE
!C                                                                        
!C     IOUTR = 1 indicates D beyond range. derivative = 0.                
!C     IOUTR = 0 indicates D .LE. !D1!. Compute poly derivative.             
!C                                                                        
        IF ( D_ABSCISSA .GT. ABS ( D1 ) )  IOUTR = I_1                         
        X = D1                                                              
        CALL EVALFD_POLY ( IOUTR, L, NP, X, FUNC_VAL )
       END IF
       EVALFD = FUNC_VAL
       RETURN
      END IF
!C                                                                        
!C    D0 < D < !D1!                                                       
!C                                                                        
      IF ( D1 .LT. D_0 )  THEN
       CALL EVALFD_TABLE  ( L, NP, D_ABSCISSA, FUNC_VAL ) 
      ELSE                                      
       X = D_ABSCISSA                                                           
       CALL EVALFD_POLY ( IOUTR, L, NP, X, FUNC_VAL )
      END IF
      EVALFD = FUNC_VAL
!C
      RETURN                                                              
      END                                                                 
