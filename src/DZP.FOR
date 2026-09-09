      SUBROUTINE DZP ( N, STATE_VAR, GG_LCL, EXP_WGHT, R, M )                           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the state variables ( STATE_VAR ) from the parametric form     
!C     assumed in the integration routine DINTG. Also evaluates the       
!C     exponential weights ( EXP_WGHT ) if M is not zero.                                          
!C                                                                           
      USE  MODULE_STANDARD,  ONLY:   
     &        INTEGER_STD, IREAL_HIGH,               ! parameters
     &        D_0, D_THIRD, D_HALF, D_1, D_2, D_4,   ! parameters
     &        I_0, I_1, I_2, I_5                     ! parameters
!C    
      IMPLICIT  NONE                                                         
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, M, N
!C
      REAL  ( KIND = IREAL_HIGH )  A, EXP_WGHT, GG_LCL, R, W_LCL, 
     &                             STATE_VAR, Z
      DIMENSION  STATE_VAR(N), GG_LCL(5,N), EXP_WGHT(3,N)                           
!C 
      REAL  ( KIND = IREAL_HIGH )  DZP_PARAM1, DZP_PARAM2
      PARAMETER ( DZP_PARAM1 = 0.004_IREAL_HIGH, 
     &            DZP_PARAM2 = -40.0_IREAL_HIGH )
!C
      INTENT (    IN )  N, GG_LCL, R, M
      INTENT (   OUT )  STATE_VAR 
      INTENT ( INOUT )  EXP_WGHT
!C                                                                           
      CALL ELTIME ( I_1, I_5 )                                         
!C
      IF ( M .EQ. I_0 )  THEN                                          
!C                                                                           
!C     Compute state variables only.                                         
!C                                                                           
       DO  I=1,N                                                             
        STATE_VAR(I) = 
     &       GG_LCL(1,I) + R * ( GG_LCL(2,I) * EXP_WGHT(1,I)                  
     &                   + R * ( GG_LCL(3,I) * EXP_WGHT(2,I)                 
     &                   + R * ( GG_LCL(4,I) * EXP_WGHT(3,I) ) ) )            
       END DO
       CALL ELTIME ( I_2, I_5 )                                        
       RETURN                                                                
      END IF
!C                                                                           
!C    Compute exponential weights and state variables.                       
!C                                                                           
      DO  I=1,N                                                              
       EXP_WGHT(1,I) = D_1                                                  
       EXP_WGHT(2,I) = D_HALF                                      
       EXP_WGHT(3,I) = D_THIRD                                                
!C
       IF ( GG_LCL(5,I) .NE. D_0 )  THEN                                   
        Z = R * GG_LCL(5,I)                                                  
        W_LCL = D_0                                                         
        IF ( ABS ( Z ) .LE. DZP_PARAM1 )  THEN                               
         W_LCL = D_4                                            
         A = EXP_WGHT(3,I)                                                      
         EXP_WGHT(3,I) = D_0                                                
!C
         DO
          EXP_WGHT(3,I) = EXP_WGHT(3,I) + A                                       
          A = A * Z / W_LCL                                                  
          W_LCL = W_LCL + D_1                                         
          IF ( ( EXP_WGHT(3,I) + A ) .NE. EXP_WGHT(3,I) )  THEN
           CYCLE     
          ELSE
           EXIT
          END IF
         END DO
!C
         EXP_WGHT(2,I) = D_HALF + D_HALF * Z * EXP_WGHT(3,I)      
         EXP_WGHT(1,I) = D_1 + Z * EXP_WGHT(2,I)                               
        ELSE
         IF ( Z .GT. DZP_PARAM2 )   W_LCL = EXP ( Z )                        
         EXP_WGHT(1,I) = ( W_LCL - D_1 ) / Z                                 
         EXP_WGHT(2,I) = ( EXP_WGHT(1,I) - D_1 ) / Z                      
         EXP_WGHT(3,I) = ( D_2 * EXP_WGHT(2,I) - D_1 ) / Z                       
        END IF
       END IF
!C
       STATE_VAR(I) = 
     &        GG_LCL(1,I) + R * ( GG_LCL(2,I) * EXP_WGHT(1,I)                   
     &                    + R * ( GG_LCL(3,I) * EXP_WGHT(2,I)                   
     &                    + R * ( GG_LCL(4,I) * EXP_WGHT(3,I) ) ) )             
      END DO  
!C                                                                           
      CALL ELTIME ( I_2, I_5 )                                          
!C
      RETURN                                                                 
      END                                                                    
