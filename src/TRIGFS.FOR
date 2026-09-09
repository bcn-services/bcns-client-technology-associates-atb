      SUBROUTINE TRIGFS                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        GH, H, HS=>TSAVE, UU,              ! /CDINT/
     &        IREAL_HIGH,                        ! parameters
     &        D_0, D_HALF, D_1, D_2, D_3, D_4    ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )   BETA, R1, R2, UAU
!C
      BETA = D_0                                                         
      IF ( HS .NE. D_0 )  BETA = ( H / HS )**2                         
      R1 = HS / H                                                         
      R2 = D_1 + BETA * R1                                               
!C
      GH(3,1) = D_2 / ( H * R2 )                                          
      GH(2,1) = GH(3,1) * ( BETA - D_1 )                                 
      GH(1,1) = GH(3,1) * BETA                                            
      GH(1,2) = D_4 * BETA / ( R2 * H**2 )                              
      GH(3,2) = GH(1,2) * R1                                              
      GH(2,2) = GH(1,2) * ( R1 + D_1 )                                   
      GH(3,3) = D_1 / H                                                   
      GH(2,3) = D_4 * GH(3,3)                                             
      GH(1,3) = D_3 * GH(3,3)                                            
      GH(3,4) = D_2 / H**2                                               
      GH(2,4) = D_2 * GH(3,4)                                            
      GH(1,4) =       GH(3,4)                                             
!C
      UU(1) = D_2 / H                                                     
      UU(2) = D_0                                                        
      UU(3) = D_HALF * H                                                  
      UU(4) = 0.25_IREAL_HIGH * H**2                                    
      IF  ( HS .NE. D_0 )  THEN                                         
       UU(1) = BETA * ( 4.25_IREAL_HIGH + 2.25_IREAL_HIGH / R1 )         
       UU(2) = BETA * ( 2.25_IREAL_HIGH + 1.25_IREAL_HIGH / R1 ) / R1     
       UAU   = D_1 + UU(1) + UU(2)                                        
       UU(1) = D_2 * UU(1) / ( UAU * H )                                  
       UU(2) = D_4 * UU(2) / ( UAU * H**2 )                            
      END IF
!C
      RETURN                                                              
      END                                                                
