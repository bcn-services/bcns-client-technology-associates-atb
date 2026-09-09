      FUNCTION HYVFN ( A, U_LCL, R, B_LCL, P )      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH, LUAOU, D_0, D_1 ! parameters
!C 
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )   I
!C
      REAL  ( KIND = IREAL_HIGH )   HYVFN
      REAL  ( KIND = IREAL_HIGH )
     &                  A, U_LCL, R, B_LCL, P, C_LCL, F_LCL, Z
      DIMENSION         U_LCL(3), R(3), B_LCL(24)                          
!C
      REAL  ( KIND = IREAL_HIGH )  HYFCN
      EXTERNAL                     HYFCN
!C
      INTENT (  IN )  A, U_LCL, R, B_LCL, P
!C
      F_LCL = -D_1                                                         
      DO  I = 1,3                                                          
       Z = A * U_LCL(I) + R(I)                                             
       C_LCL = B_LCL(I+16)                                                 
       IF ( P .GT. D_0 )  THEN
        C_LCL = HYFCN ( C_LCL, Z, B_LCL(I+1), P )                          
       END IF
       F_LCL = F_LCL + C_LCL * Z**2                                        
      END DO
      HYVFN = F_LCL                                                        
!C
      RETURN                                                               
      END                                                                  
