      SUBROUTINE HYLPR_PIVOT ( ID, J, JMP_OUT, C_LCL, E_LCL, S, Z  )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH,     ! parameters
     &       LOGICAL_STD, TRUE, FALSE,    ! parameters
     &       I_0, D_0, D_1                ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER   ( KIND = INTEGER_STD )  I, ID, J, K, L, M
      DIMENSION  ID(16)
!C
      REAL  ( KIND = IREAL_HIGH )  C_LCL, S, E_LCL, P, Q, Z 
      DIMENSION         C_LCL(16), S(9,8), E_LCL(9)                
!C
      LOGICAL  ( KIND = LOGICAL_STD )  JMP_OUT
!C
      INTENT (    IN ) J
      INTENT (   OUT ) E_LCL, JMP_OUT
      INTENT ( INOUT ) ID, C_LCL, S, Z
!C
!C
!C    Find pivot row                                                       
!C
      K = I_0                                                           
      DO  I = 1,9                                                          
!C
!C     Save pivot column                                                   
!C
       E_LCL(I) = S(I,J)                                                   
       IF ( S(I,J) .LE. D_0 )  CYCLE                                     
       IF ( K .NE. I_0 )   THEN                                         
        IF ( S(I,8) .GE. ( Z * S(I,J) ) )   CYCLE                          
       END IF
       K = I                                                               
       Z = S(I,8) / S(I,J)                                                 
      END DO                                                               
!C
!C    Replace columns                                                      
!C
      IF ( K .EQ. I_0 )  THEN
       JMP_OUT = TRUE
       RETURN
      ELSE
       JMP_OUT = FALSE
      END IF
!C                                      
      M = ID(J)                                                            
      ID(J) = ID(K+7)                                                      
      ID(K+7) = M                                                          
      Q = C_LCL(J)                                                         
      C_LCL(J) = C_LCL(K+7)                                                
      C_LCL(K+7) = Q                                                       
      P = S(K,J)                                                           
!C
      DO  I = 1,9                                                          
       S(I,J) = D_0                                                      
      END DO
      S(K,J) = D_1                                                         
!C
      DO  L = 1,8                                                          
       S(K,L) = S(K,L) / P                                                 
      END DO
      E_LCL(K) = D_1                                                     
!C
      DO  I = 1,9                                                          
       IF ( I .EQ. K )  CYCLE                                              
       IF ( E_LCL(I) .EQ. D_0 )  CYCLE                                  
       DO  M = 1,8                                                         
        S(I,M) = S(I,M) - E_LCL(I) * S(K,M)                                
       END DO
      END DO                                                               
!C
      RETURN
      END