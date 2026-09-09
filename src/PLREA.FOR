      SUBROUTINE PLREA ( L, H_LCL, AREA_LCL, AB_LCL, BB_LCL, 
     &                   E_LCL, D_LCL, R )                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes AREA and centroid (true area = AREA*|UxV|/6)                
!C     |UxV| is never computed    |UxV| = UxV.T = area of parallelogram    
!C     This routine will only be called if there is an intersection        
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS,                          ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,      ! parameters
     &        D_0, D_1, D_2, D_3, I_1       ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      INTEGER  ( KIND = INTEGER_STD )  I, L
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AREA_LCL, AB_LCL, AR, ARC, BB_LCL, D_LCL, 
     &                  C_LCL, C11, C12, C22, H_LCL, E_LCL, R, 
     &                  X21, Y21
      DIMENSION         H_LCL(2,2,5), E_LCL(2,2)                           
!C
      INTENT (  IN )  L, E_LCL, D_LCL, R
      INTENT ( OUT )  AREA_LCL, AB_LCL, BB_LCL
!C
      AREA_LCL = D_0                                                     
      AB_LCL = D_0                                                      
      BB_LCL = D_0                                                       
      IF ( L .LE. I_1 )  THEN 
       RETURN
      END IF
      C_LCL = R / SQRT ( D_LCL )                                           
      C12 = D_2 * R / D_LCL                                                
      C11 = C12 * E_LCL(1,1)                                               
      C22 = C12 * E_LCL(2,2)                                               
      C12 = C12 * E_LCL(1,2)                                               
      DO  I = 1,L                                                        
!C
!C     Compute for straight line segments                                  
!C
       AR = H_LCL(1,1,I) * H_LCL(2,2,I) - 
     &      H_LCL(1,2,I) * H_LCL(2,1,I)                                    
       IF ( AR .NE. D_0 )   THEN                                          
        AB_LCL = AB_LCL + AR * ( H_LCL(1,1,I) + H_LCL(1,2,I) )             
        BB_LCL = BB_LCL + AR * ( H_LCL(2,1,I) + H_LCL(2,2,I) )             
        AREA_LCL = AREA_LCL + AR                                           
       END IF
!C
!C     Compute for ellipse                                                 
!C
       AR = H_LCL(1,2,I)   * H_LCL(2,1,I+1) - 
     &      H_LCL(1,1,I+1) * H_LCL(2,2,I)                                  
       IF ( AR .NE. D_0 )   THEN                                         
        ARC = AR / C_LCL                                                   
        IF ( ABS ( ARC ) .GT. D_1 )  THEN
         ARC = SIGN ( D_1, ARC )   
        END IF
        AR = C_LCL * ASIN ( ARC )                                          
        X21 = H_LCL(1,1,I+1) - H_LCL(1,2,I)                                
        Y21 = H_LCL(2,1,I+1) - H_LCL(2,2,I)                                
        AB_LCL = AB_LCL + C12 * X21 + C22 * Y21                            
        IF ( ABS ( AB_LCL ) .LT. EPS(16) )   AB_LCL = D_0
        BB_LCL = BB_LCL - C11 * X21 - C12 * Y21                            
        IF ( ABS ( BB_LCL ) .LT. EPS(16) )   BB_LCL = D_0
        AREA_LCL = AREA_LCL + AR                                           
       END IF
      END DO                                                             
!C
      IF  ( AREA_LCL .LE. D_0 )  THEN
       RETURN
      END IF                                                               
!C
      AREA_LCL = D_3 * AREA_LCL                                         
      AB_LCL = AB_LCL / AREA_LCL                                           
      BB_LCL = BB_LCL / AREA_LCL                                           
!C
!C    AREA = AREA/6.0                                                      
!C
      RETURN                                                               
      END                                                                  
