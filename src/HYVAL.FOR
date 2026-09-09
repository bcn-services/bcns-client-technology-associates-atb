      SUBROUTINE HYVAL ( A, U_LCL, R, BD_LCL, L )                          
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                      ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,           ! parameters
     &       D_1, D_0, D_2, D_4, D_5, I_0, I_1, I_100  ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )  L, M, MAXITER_HYVAL, NSTEP_LCL
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BD_LCL, U_LCL, R, RM, A, POW, DEL,
     &                  DL, TESD, TEST, F1_LCL, F2
      DIMENSION         BD_LCL(24), U_LCL(3), R(3), RM(2)                  
!C
      REAL  ( KIND = IREAL_HIGH )  HYVFN
      EXTERNAL          HYVFN
!C
      PARAMETER ( MAXITER_HYVAL = I_100 )
!C
!C     Given A, U_LCL, R: compute A        Z = A*U_LCL + R                 
!C
      POW = -BD_LCL(1) - D_2                                            
!C
!C    Are these the correct tests??                                        
!C
      TEST = -BD_LCL(1) * EPS(6)                                           
      TESD = EPS(6)                                                        
      CALL HYVBX ( U_LCL, R, BD_LCL(2), M, RM )                            
      A = D_0                                                           
      IF ( M .LT. L )  RETURN                                              
!C
!C    This should never happen  - implies R is outside box                 
!C
      A = RM(L)                                                            
      IF ( ABS ( A ) .LT. TESD )  RETURN                                   
      DEL = A / D_5                                                      
      NSTEP_LCL = I_0                                                
!C
!C    Iteration loop                                                       
!C
      LOOP_1 : DO
       DEL = DEL / D_4                                                   
!C
       NSTEP_LCL = NSTEP_LCL + I_1                                        
!C
!C     Stop program if the number of iterations exceeds the
!C      maximum allowed.
!C
       IF  ( NSTEP_LCL .GE. MAXITER_HYVAL )   THEN                          
        WRITE ( LUAOU, 100 )  M, A, DEL, F1_LCL, F2, L, RM(1), RM(2),
     &                   U_LCL, R, BD_LCL                                   
  100   FORMAT ( ' HYV ', I4, 4F11.6, I3, 2F11.6, /, 4X, 3F11.6,
     &           4X, 3F11.6, /, 4( 2X, 7F10.4, / ) )                        
        STOP 102                                                            
       END IF
!C
       F2 = HYVFN ( A, U_LCL, R, BD_LCL, POW )                              
       IF ( ABS ( F2 ) .LT. TEST )  EXIT LOOP_1                                 
!C
       IF ( F2 .LT. D_0 )  THEN
        IF ( SIGN ( D_1, A ) .NE. SIGN ( D_1, ( A + DEL ) ) )  THEN      
         A = A / D_2                                                          
         DL = -A                                                              
        ELSE                                                             
         DL = DEL                                                             
         A = A + DEL                                                          
        END IF
        F1_LCL = F2                                                          
!C
        DO
         F2 = HYVFN ( A, U_LCL, R, BD_LCL, POW )                              
         NSTEP_LCL = NSTEP_LCL + I_1                                        
!C
!C       Stop program if the number of iterations exceeds the
!C        maximum allowed.
!C
         IF  ( NSTEP_LCL .GE. MAXITER_HYVAL )   THEN                          
          IF ( F1_LCL .EQ. F2 )  EXIT LOOP_1                                     
          WRITE ( LUAOU, 100 ) M, A, DEL, F1_LCL, F2, L, RM(1), RM(2), 
     &                    U_LCL, R, BD_LCL                                    
          STOP 103                                                            
         END IF
!C
         IF ( ABS ( F2 ) .LT. TEST )  EXIT LOOP_1                                 
         IF ( F2 .LT. D_0 )  THEN
          IF ( SIGN ( D_1, A ) .NE. SIGN ( D_1, ( A + DEL ) ) )  THEN      
           A = A / D_2                                                          
           DL = -A                                                              
          ELSE                                                             
           DL = DEL                                                             
           A = A + DEL                                                          
          END IF
          F1_LCL = F2                                                          
         ELSE IF ( F2 .EQ. D_0 )  THEN
          EXIT LOOP_1
         ELSE
          A = A + F2 * DL / ( F1_LCL - F2 )                                    
          IF ( ABS ( DEL ) .LE. TESD )  THEN
           EXIT LOOP_1
          ELSE
           CYCLE LOOP_1
          END IF                              
         END IF
!C
        END DO
       ELSE IF ( F2 .EQ. D_0 )  THEN
        EXIT LOOP_1
       ELSE
        IF ( SIGN ( D_1, A ) .NE. SIGN ( D_1, ( A - DEL ) ) )  THEN      
         A = A / D_2                                                          
         DL = -A                                                              
        ELSE
         DL = -DEL                                                            
         A = A - DEL                                                          
        END IF
        F1_LCL = F2                                                          
!C
        DO
         F2 = HYVFN ( A, U_LCL, R, BD_LCL, POW )                              
         NSTEP_LCL = NSTEP_LCL + I_1                                     
!C
!C       Stop program if the number of iterations exceeds the
!C        maximum allowed.
!C
         IF ( NSTEP_LCL .GE. MAXITER_HYVAL )  THEN                            
          IF ( F1_LCL .EQ. F2 )  EXIT LOOP_1                                      
          WRITE ( LUAOU, 100 )  M, A, DEL, F1_LCL, F2, L, RM(1), RM(2),
     &                     U_LCL, R, BD_LCL                                   
          STOP 104                                                            
         END IF
!C
         IF ( ABS ( F2 ) .LT. TEST )  EXIT LOOP_1                                  
         IF ( F2 .LT. D_0 )  THEN
          A = A + F2 * DL / ( F1_LCL - F2 )                                    
          IF ( ABS ( DEL ) .LE. TESD )  THEN                              
           EXIT LOOP_1
          ELSE
           CYCLE LOOP_1
          END IF
         ELSE IF ( F2 .EQ. D_0 ) THEN
          EXIT LOOP_1
         ELSE
          IF ( SIGN ( D_1, A ) .NE. SIGN ( D_1, ( A - DEL ) ) )  THEN      
           A = A / D_2                                                          
           DL = -A                                                              
          ELSE
           DL = -DEL                                                            
           A = A - DEL                                                          
          END IF
          F1_LCL = F2                                                          
         END IF
        END DO                                                            
       END IF
!C
      END DO LOOP_1
!C                                                                         
      RETURN                                                               
      END                                                                  
