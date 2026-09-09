      SUBROUTINE EULRAD ( D_LCL, A, IC )                                  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes Euler angles precession, nutation, and spin in radians     
!C    and places them into the A array for given direction cosine matrix   
!C                                                                        
!C      Assumes  D = D(S)D(N)D(P) , where                                 
!C                                                                        
!C          CS SS 0          1  0  0           CP SP 0                    
!C    D(S)=-SS CS 0  , D(N)= 0  CN SN  , D(P)=-SP CP 0                    
!C          0  0  1          0 -SN CN          0  0  1                    
!C                                                                        
!C    and P=A(1),  N=A(2), S=A(3)                                         
!C                                                                        
!C    Routine will always work in the memory mode, i.e., will produce a   
!C    new set of A'S that differ the least from the inputted A array.     
!C    To use in non-memory mode, set all A'S to zero, call with IC = 8.   
!C                                                                        
!C    New N is always computed.                                           
!C    If N or PI-N < 10**-6, IC is used to resolve ambiguites on P & S,   
!C    except for IC = 2 or 8 where they are not changed.                  
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS, PI, TWOPI,                     ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH,            ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_3,       ! parameters
     &       I_4, I_5, I_6, I_7, I_8             ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IC, IJ_LCL, J
!C
      REAL  ( KIND = IREAL_HIGH )   A, B_LCL, D_LCL, T, TMAX, Z
      DIMENSION  A(3), D_LCL(3,3), T(6)                                   
!C
      IF  ( D_LCL(3,3) .GT.  D_1 )  D_LCL(3,3) =  D_1                    
      IF  ( D_LCL(3,3) .LT. -D_1 )  D_LCL(3,3) = -D_1                    
      B_LCL = ACOS ( D_LCL(3,3) )                                         
      T(2) =  B_LCL - A(2)                                                
      T(5) = -B_LCL - A(2)                                                
      Z = D_0                                                           
      IF  (   B_LCL .LT. EPS(6) )       Z =  D_1                         
      IF  ( ( PI -B_LCL ) .LT. EPS(6) ) Z = -D_1                         
!C
      IF  ( Z .EQ. D_0 )  THEN                                          
       T(1) = ATAN2 ( D_LCL(3,1), -D_LCL(3,2) ) - A(1)                    
       T(4) = T(1) + PI                                                   
       T(3) = ATAN2 ( D_LCL(1,3),  D_LCL(2,3) ) - A(3)                    
       T(6) = T(3) + PI                                                   
      ELSE
       T(1) = ATAN2 ( D_LCL(1,2) - Z * D_LCL(2,1), 
     &                D_LCL(1,1) + Z * D_LCL(2,2) ) - A(1) - Z * A(3)     
       T(3) = T(1)                                                        
!C
!C     Set T(1) = 0 except for IC = 3, 4                                     
!C     Set T(3) = 0 except for IC = 1, 6                                     
!C                                                                        
       IF ( ( IC .EQ. I_1 ) .OR. ( IC .EQ. I_6 ) )  THEN
        T(1) = D_0                                                        
       ELSE IF  ( ( IC .EQ. I_2 ) .OR. ( IC .EQ. I_5 ) .OR.
     &            ( IC .EQ. I_7 ) .OR. ( IC .EQ. I_8 ) )  THEN
        T(1) = D_0                                                        
        T(3) = D_0                                                        
       ELSE IF  ( ( IC .EQ. I_3 ) .OR. ( IC .EQ. I_4 ) )  THEN
        T(3) = D_0                                                        
       END IF
!C                                                                        
       T(4) = T(1)                                                       
       T(6) = T(3)                                                      
      END IF
!C
      TMAX = D_0                                                        
      J    = I_3                                                            
      DO  I=1,6                                                           
       T(I) = MOD ( T(I), TWOPI )                                         
       IF   ( ABS ( T(I)) .GT. PI  )  THEN 
        T(I) = T(I) - SIGN ( TWOPI, T(I) )                                
       END IF
       IF  ( ABS ( T(I) ) .LT. TMAX )  CYCLE                              
       TMAX = ABS ( T(I) )                                                
       IF  ( I .GT. I_3 )  J = I_0                                      
      END DO                                                              
      IF  ( Z .LT. D_0 )  T(J+3) = -T(J+3)                            
      DO  I=1,3                                                           
       IJ_LCL = I + J                                                     
       A(I) = A(I) + T(IJ_LCL)                                            
      END DO
!C
      RETURN                                                              
      END                                                                 
