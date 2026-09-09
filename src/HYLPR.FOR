      SUBROUTINE HYLPR ( J1, J2, ID, C_LCL, S, E_LCL, T )                  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Linear program routine using simplex method                          
!C    J1 = J2 forced pivot on column J1                                    
!C    Calculate costs.                                                      
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, ! parameters
     &       I_0, I_1, D_0, D_1, D_10              ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER   ( KIND = INTEGER_STD )  I, ID, J, J1, J2, L 
      DIMENSION  ID(16)
!C
      REAL  ( KIND = IREAL_HIGH )  C_LCL, E_LCL, S, T, Z, PARM_1
      DIMENSION         C_LCL(16), E_LCL(9), S(9,8), T(7)                  
      PARAMETER ( PARM_1 = D_10 )
!C
      LOGICAL  ( KIND = LOGICAL_STD )  JMP_OUT
!C
      J = J1                                                               
      IF ( J .EQ. J2 )  CALL HYLPR_PIVOT ( ID, J, JMP_OUT, C_LCL, 
     &                                     E_LCL, S, Z )                                          
      IF ( JMP_OUT ) RETURN
!C
      LOOP_10 : DO 
       DO  L = 1,7                                                          
        T(L) = -C_LCL(L)                                                    
        IF ( C_LCL(L) .EQ. PARM_1 )   CYCLE                               
        DO  I = 1,9                                                         
         T(L) = T(L) + S(I,L) * C_LCL(I+7)                                  
        END DO
       END DO                                                               
!C
       IF ( J1 .EQ. J2 )   RETURN                                           
!C
!C     Find pivot column                                                    
!C
       DO  L = 1,7                                                          
        J = L                                                               
        IF ( T(L) .GT. D_0 )  THEN
         CALL HYLPR_PIVOT ( ID, J, JMP_OUT, C_LCL, E_LCL, S, Z  )
         IF ( JMP_OUT )  RETURN
         CYCLE  LOOP_10                                    
        END IF
       END DO
       RETURN
      END DO  LOOP_10
!C
      END                                                                  
