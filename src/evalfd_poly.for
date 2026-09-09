      SUBROUTINE  EVALFD_POLY ( IOUTR, L, NP, X, FUNC_VAL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine computes the 5th order polynomial
!C     or derivative of the the 5th order polynomial.  It 
!C     is called only by Function EVALFD.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       TAB,                           ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH,       ! parameters
     &       I_0, I_1, D_2, D_3, D_4, D_5   ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )   IOUTR, L, NP
!C
      REAL  ( KIND = IREAL_HIGH )       FUNC_VAL, X
!C
      INTENT  (  IN )  IOUTR, L, NP, X
      INTENT  ( OUT )  FUNC_VAL
!C
      IF ( ( IOUTR .EQ. I_1 ) .AND. ( L .EQ. I_0 ) )  THEN     
       RETURN
      END IF
!C
      IF ( ( L - I_1 ) .LT. I_0 )  THEN                            
!C                                                                        
!C     Evaluate derivative of 5th degree polynomial.                       
!C                                                                        
       FUNC_VAL = TAB(NP+1) + X * ( D_2   * TAB(NP+2) +
     &                        X * ( D_3   * TAB(NP+3) + 
     &                        X * ( D_4   * TAB(NP+4) + 
     &                        X *   D_5   * TAB(NP+5) ) ) )                 
      ELSE IF ( ( L - I_1 ) .EQ. I_0 )  THEN
!C                                                                        
!C     Evaluate 5th degree polynomial.                                     
!C                                                                        
       FUNC_VAL = TAB(NP) + X * ( TAB(NP+1) + 
     &                      X * ( TAB(NP+2) +                                
     &                      X * ( TAB(NP+3) + 
     &                      X * ( TAB(NP+4) + 
     &                      X *   TAB(NP+5) ) ) ) )                          
      END IF
!C
      RETURN
      END 