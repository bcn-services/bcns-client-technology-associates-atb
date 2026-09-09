      SUBROUTINE DRCIJK ( ANG_LCL, ID, HT_LCL, J )              
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                        
!C     This subroutine computes the direction cosine matrix of segment    
!C     J from the angles in the ANG array and, possibly, relative to      
!C     proximal joint axes as specified by the HT array.                  
!C                                                                        
!C                                                                        
!C     Subroutines called by:  EQUILB, INTANG                             
!C                                                                        
!C     Subroutines called:  DRCYPR, MAT33, DOT33                          
!C                                                                        
!C     Logical units read from/written to:  none                          
!C                                                                        
!C    STOPS:  none                                                        
!C                                                                        
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:  
     &        SEG,                                              ! structures
     &        INTEGER_STD, IREAL_HIGH, MAXSEG, MAXJNT, I_0      ! parameters
!C
!C    SEG%DIR_COS
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD)  ID, J, M
      DIMENSION  ID(4,MAXJNT)
!C
      REAL  ( KIND = IREAL_HIGH )   HT_LCL, ANG_LCL, T1, T2
      DIMENSION  HT_LCL(9,2*MAXJNT),                   
     &           ANG_LCL(3,MAXJNT), T1(3,3), T2(3,3)             
!C
      INTENT (  IN )  ANG_LCL, J, HT_LCL, ID 
!C
      M = ID(4,J)                                                         
!C                                                                        
!C    If M is 0, the rotations are with respect to the ground.            
!C                                                                        
      IF (M .EQ. I_0 ) THEN                                            
       CALL DRCYPR ( SEG(J)%DIR_COS, ANG_LCL(1,J), ID(1,J) )                      
       RETURN                                                             
      ELSE                                                                
       CALL DRCYPR ( T1, ANG_LCL(1,J), ID(1,J) )                          
      END IF                                                              
!C                                                                        
!C    If M is positive, the rotations are with respect to segment M.      
!C                                                                        
      IF ( M .GT. I_0 )  THEN                                          
       CALL MAT33 ( T1, SEG(M)%DIR_COS, SEG(J)%DIR_COS )                                 
      ELSE                                                                
!C                                                                        
!C    If M is negative, the angles in ANG are with respect to             
!C    rotations of the proximal joint axes.                               
!C                                                                        
       M = -M                                                             
       CALL DOT33 ( HT_LCL(1,2*J-3), SEG(M)%DIR_COS, SEG(J)%DIR_COS )     
       CALL MAT33 ( T1, SEG(J)%DIR_COS, T2 )                             
       CALL MAT33 ( HT_LCL(1,2*J-2), T2, SEG(J)%DIR_COS )               
      END IF                                                              
!C
      RETURN                                                              
      END                                                                 
