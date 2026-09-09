      SUBROUTINE HYSOL ( A, N, ND )                                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH, D_0, I_1  ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( INTEGER_STD )   I, J, L, L1, N, N1, ND
!C
      REAL  ( KIND = IREAL_HIGH )    A
      DIMENSION          A(ND,6)                                          
!C
      INTENT (    IN )  N, ND
      INTENT ( INOUT )  A
!C
!C    Assumes pivot on diagonal , bypass 0's.                               
!C
      N1 = N + I_1                                                      
      DO  L = 1,N                                                          
       IF ( A(L,L) .EQ. D_0 )   CYCLE                                     
       L1 = L + I_1                                                     
       DO  J = L1,N1                                                       
        A(L,J) = A(L,J) / A(L,L)                                           
       END DO
       IF ( L .EQ. N )  CYCLE                                              
       DO  I = L1,N                                                        
        IF ( A(I,L) .EQ. D_0 )  CYCLE                                    
        DO  J = L1,N1                                                      
         A(I,J) = A(I,J) - A(I,L) * A(L,J)                                 
        END DO
       END DO                                                              
      END DO                                                               
      IF ( N .EQ. I_1 )  THEN
       RETURN
      END IF                                                               
!C
!C    Backup                                                               
!C
      DO  L = 2,N                                                          
       I = N1 - L                                                          
       L1 = I + I_1                                                     
       DO  J = L1,N                                                        
        A(I,N1) = A(I,N1) - A(I,J) * A(J,N1)                               
       END DO
      END DO
!C
      RETURN                                                               
      END                                                                  
