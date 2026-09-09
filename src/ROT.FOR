      SUBROUTINE ROT ( A, L, TH )                                            
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes rotation matrix A for angle TH                                
!C    about X,Y or Z axis as L = 1,2, or 3.                                  
!C                                                                           
!C      Arguments:                                                          
!C        A: 3X3 rotation matrix to be computed.                             
!C        L: 1,2 or 3 to rotate about X,Y or Z axis.                        
!C        TH: angle of rotation in radians.                                  
!C                                                                           
      USE  MODULE_STANDARD,  ONLY:   
     &       EPS,                             ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH,         ! parameters 
     &       D_0, D_1, I_2, I_3, I_5          ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )  I, J, L
!C
      REAL  ( KIND = IREAL_HIGH )   A, C_LCL, S, TH
      DIMENSION         A(3,3)                                               
!C
      INTENT (  IN )  L, TH
      INTENT ( OUT )  A
!C
      C_LCL = COS ( TH )                                                     
      S     = SIN ( TH )                                                     
      IF  ( ABS ( C_LCL ) .LT. EPS(8) )  C_LCL = D_0                     
      IF  ( ABS ( S     ) .LT. EPS(8) )  S     = D_0                    
      IF  ( ( D_1 - ABS ( C_LCL ) ) .LT. EPS(8) )   THEN
       C_LCL = SIGN ( D_1, C_LCL )                                        
      END IF
      IF  ( ( D_1 - ABS(S) ) .LT. EPS(8) )  S = SIGN ( D_1, S )        
      IF ( L .EQ. I_2 )   S = -S                                       
      DO  I=1,3                                                             
       IF ( I .NE. I_3 )   THEN                                     
        DO  J=I,2                                                           
         A(I,J+1) = D_0                                                    
         A(J+1,I) = D_0                                                     
         IF ( ( I + J + L ) .EQ. I_5 )  THEN                     
          A(I,J+1) =  S                                                     
          A(J+1,I) = -S                                                     
         END IF                                                              
        END DO
       END IF
       A(I,I)= C_LCL                                                           
       IF ( I .EQ. L )    A(I,I) = D_1                                       
      END DO                                                                
!C
      RETURN                                                                
      END                                                                   
