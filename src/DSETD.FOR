      SUBROUTINE DSETD ( D_LCL, TH, T )                                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Updates a direction cosine matrix (D)                                
!C    using an incremental angular motion (TH).                            
!C        Arguments D: 3X3 direction cosine matrix to be updated.          
!C                 TH: 3 components of incremental angular motion          
!C                     about local X,Y and Z axis respectively.            
!C                  T: magnitude of vector TH computed by routine.         
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                       ! /CNSNTS/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,            ! parameters 
     &       D_0, D_HALF, D_1                           ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )  I, ITER, J, K
!C
      REAL  ( KIND = IREAL_HIGH )  CT, CTT, DET, DTT, ST, STT, T
      REAL  ( KIND = IREAL_HIGH )  D_LCL, TH, S, TEMP
      DIMENSION D_LCL(3,3), TH(3), S(3), TEMP(3,3)                         
!C
      REAL  ( KIND = IREAL_HIGH )  VECMAG
      EXTERNAL                     VECMAG
!C
      INTENT (    IN )  TH
      INTENT (   OUT )  T
      INTENT ( INOUT )  D_LCL
!C
      T = VECMAG ( TH )                      
      IF ( T .EQ. D_0 )   RETURN                                         
      ST = SIN ( T )                                                       
      CT = COS ( T )                                                       
      STT = ST / T                                                         
      CTT = STT**2 / ( D_1 + CT )                                       
      DO J=1,3                                                             
       S(1) = -TH(3) * D_LCL(2,J) + TH(2) * D_LCL(3,J)                     
       S(2) =  TH(3) * D_LCL(1,J) - TH(1) * D_LCL(3,J)                     
       S(3) = -TH(2) * D_LCL(1,J) + TH(1) * D_LCL(2,J)                     
       DTT = ( TH(1) * D_LCL(1,J) + TH(2) * D_LCL(2,J) 
     &       + TH(3) * D_LCL(3,J) ) * CTT                                  
       DO  K=1,3                                                           
        D_LCL(K,J) = D_LCL(K,J) * CT - STT * S(K) + TH(K) * DTT            
       END DO
      END DO                                                               
!C                                                                         
!C    Renormalization of direction cosine matrix                           
!C    by averaging matrix and transpose of its inverse.                    
!C                                                                         
      DO  ITER=1,10                                                        
       CALL CFACTT ( D_LCL, TEMP, DET )                                    
        DO  I=1,3                                                          
         DO  J=1,3                                                         
          D_LCL(I,J) = D_HALF * ( D_LCL(I,J) + TEMP(J,I) / DET )   
          IF ( ABS ( D_LCL(I,J)) .LT. EPS(15) )  D_LCL(I,J) = D_0         
         END DO
        END DO
       IF ( ABS ( DET - D_1 ) .LT. EPS(6) )  RETURN                      
      END DO                                                               
      WRITE ( LUAOU, 105 )  DET                                             
  105 FORMAT ( '0 DSETD renormalization did not converge, DET =',
     &          1PD25.15 )   
!C
      RETURN                                                               
      END                                                                  
