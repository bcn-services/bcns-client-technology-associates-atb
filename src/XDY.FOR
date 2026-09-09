      FUNCTION XDY ( X, D_LCL, Y )                              
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Function routine to compute X.DY or Y.D'X                       
!C                                                                 
      USE  MODULE_STANDARD,  ONLY:  
     &      INTEGER_STD, IREAL_HIGH, D_0  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I
!C
      REAL  ( KIND = IREAL_HIGH )  XDY 
      REAL  ( KIND = IREAL_HIGH )  D_LCL, X, Y
      DIMENSION         D_LCL(3,3), X(3), Y(3)                            
!C
      INTENT  (  IN )  X, D_LCL, Y
!C
      XDY = D_0                                                        
      DO  I=1,3                                                       
       XDY = XDY + X(I) * (   D_LCL(I,1) * Y(1) + D_LCL(I,2) * Y(2)
     &                      + D_LCL(I,3) * Y(3) )                          
      END DO
!C
      RETURN                                                      
      END                                                           
