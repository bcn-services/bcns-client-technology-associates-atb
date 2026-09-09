      SUBROUTINE HYREA ( L, H_LCL, AREA_LCL, AB_LCL, BB_LCL )              
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH, D_0, D_3, I_2  ! parameters
!C
      IMPLICIT  NONE
!C                                                                         
      INTEGER  ( KIND = INTEGER_STD )  I, L
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  H_LCL, AREA_LCL, AB_LCL, BB_LCL, AR
      DIMENSION         H_LCL(2,2,5)                                       
!C
      INTENT (  IN )  L, H_LCL
      INTENT ( OUT )  AREA_LCL, AB_LCL, BB_LCL
!C
      AREA_LCL = D_0                                                      
      AB_LCL = D_0                                                       
      BB_LCL = D_0                                                       
      IF ( L .LT. I_2 )   THEN                                          
       RETURN
      END IF
!C
      DO  I = 1,L                                                          
       AR =   H_LCL(1,1,I) * H_LCL(2,2,I)
     &      - H_LCL(1,2,I) * H_LCL(2,1,I)                                  
       IF ( AR .NE. D_0 )   THEN                                         
        AB_LCL = AB_LCL + AR * ( H_LCL(1,1,I) + H_LCL(1,2,I) )             
        BB_LCL = BB_LCL + AR * ( H_LCL(2,1,I) + H_LCL(2,2,I) )             
        AREA_LCL = AREA_LCL + AR                                           
       END IF
!C
       AR =   H_LCL(1,2,I)   * H_LCL(2,1,I+1) 
     &      - H_LCL(1,1,I+1) * H_LCL(2,2,I)                                
       IF ( AR .NE. D_0 )  THEN                                         
        AB_LCL = AB_LCL + AR * ( H_LCL(1,1,I+1) + H_LCL(1,2,I) )           
        BB_LCL = BB_LCL + AR * ( H_LCL(2,1,I+1) + H_LCL(2,2,I) )           
        AREA_LCL = AREA_LCL + AR                                           
       END IF
      END DO                                                               
!C
      IF ( AREA_LCL .LE. D_0 )   THEN                                   
       RETURN
      END IF
      AREA_LCL = D_3 * AREA_LCL                                         
      AB_LCL = AB_LCL / AREA_LCL                                           
      BB_LCL = BB_LCL / AREA_LCL                                           
!C
!C    AREA_LCL = AREA_LCL / 6.0                                            
!C
      RETURN                                                               
      END                                                                  
