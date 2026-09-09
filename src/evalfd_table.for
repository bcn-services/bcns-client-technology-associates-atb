      SUBROUTINE  EVALFD_TABLE ( L, NP, D_ABSCISSA, FUNC_VAL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C    
!C    This subroutine evaluates a tabular function.
!C     It is called only by Function EVALFD.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       TAB,                                ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH,            ! parameters
     &       I_0, I_1, I_3                       ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  K, K1, K2, L, MB, NP
!C
      REAL  ( KIND = IREAL_HIGH )  D_ABSCISSA, FUNC_VAL, R1, R2
!C
      INTENT (  IN )  L, NP, D_ABSCISSA
      INTENT ( OUT )  FUNC_VAL
!C
      MB = TAB(NP)                                                        
      K1 = NP + I_3                                                  
      K2 = NP + MB + MB                                                   
      DO  K=K1,K2,2                                                       
       IF  ( D_ABSCISSA .GT. TAB(K) )  CYCLE                                   
       IF  ( ( L - I_1 ) .LT. I_0 )  THEN                               
!C                                                                        
!C      Evaluate derivative from table                                    
!C                                                                        
        FUNC_VAL = ( TAB(K+1) - TAB(K-1) ) / ( TAB(K) - TAB(K-2) )           
        RETURN
       ELSE IF ( ( L - I_1 ) .EQ. I_0 )  THEN
!C                                                                        
!C      Evaluate function from table                                      
!C                                                                        
        R2 = TAB(K) - TAB(K-2)                                            
        R1 = ( D_ABSCISSA - TAB(K-2) ) / R2                                    
        R2 = (TAB(K) - D_ABSCISSA ) / R2                                       
        FUNC_VAL = R1 * TAB(K+1) + R2 * TAB(K-1)                             
        RETURN
       ELSE
        RETURN
       END IF
      END DO                                                              
      IF  ( L .EQ. I_1 )  FUNC_VAL = TAB(K2)                              
!C
      RETURN
      END