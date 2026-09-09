      SUBROUTINE HYVBX ( Q, S, B_LCL, M, RM )                              
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,   ! parameters
     &       TRUE, FALSE, D_0, D_1, I_0, I_1         ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K, L, M
!C
      REAL  ( KIND = IREAL_HIGH )  Q, S, B_LCL, RM, C_LCL, D_LCL, R
      DIMENSION         Q(3), S(3), B_LCL(3), RM(2)                        
!C
      LOGICAL  ( KIND = LOGICAL_STD )  VAL                              
!C
      INTENT (    IN ) Q, S, B_LCL 
      INTENT (   OUT ) M
      INTENT ( INOUT ) RM
!C
!C    Finds limits of box in direction Q,  Z = R*Q + S.                     
!C
      M = I_0                                                          
      C_LCL = -D_1                                                         
      DO  I = 1,3                                                          
       IF ( Q(I) .EQ. D_0 )   CYCLE                                     
!C
       LOOP_2 : DO  K = 1,2                                                
        VAL = TRUE                                                       
        D_LCL = C_LCL * B_LCL(I) - S(I)                                    
        DO  J = 1,3                                                        
         IF ( J .EQ. I )  CYCLE                                            
         IF ( ABS ( D_LCL * Q(J) + S(J) * Q(I) ) .GT. 
     &        ABS ( B_LCL(J) * Q(I) ) )      VAL = FALSE             
!C
!C       If ( ABS( R*Q(J) + S(J) ).GT. B(J) )  VAL = .FALSE.                      
!C
        END DO                                                             
        IF ( VAL )   THEN                                                  
         R = D_LCL / Q(I)                                                  
         IF ( M .NE. I_0 )   THEN                                      
          DO  L = 1,M                                                      
           IF ( R .EQ. RM(L) )  THEN
            C_LCL = -C_LCL                                              
            CYCLE LOOP_2                               
           END IF
          END DO                                                           
         END IF
         M = M + I_1                                                   
         RM(M) = R                                                         
        END IF
        C_LCL = -C_LCL                                                    
       END DO LOOP_2
!C
      END DO                                                               
      IF ( M .EQ. I_0 )   RETURN                                       
      IF ( RM(1) .LT. RM(2) )  RETURN                                      
      R = RM(1)                                                            
      RM(1) = RM(2)                                                        
      RM(2) = R                                                            
!C
      RETURN                                                               
      END                                                                  
