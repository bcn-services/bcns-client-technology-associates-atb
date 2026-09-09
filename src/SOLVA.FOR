      SUBROUTINE SOLVA ( R, AA11, AA22, AA12 )                             
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       IREAL_HIGH, D_2  ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      REAL  ( KIND = IREAL_HIGH )
     &            A11_LCL, A12, A13_LCL, A21, A22_LCL,
     &            A23_LCL, A31, A32, A33, AA11, AA12, AA22, DEL, R
      DIMENSION R(2,3)                                                     
!C
      INTENT (  IN )  R
      INTENT ( OUT )  AA11, AA22, AA12
!C
      A11_LCL = R(1,1)**2                                                  
      A12     = D_2 * R(2,1) * R(1,1)                                     
      A13_LCL = R(2,1)**2                                                  
      A21     = R(1,2)**2                                                  
      A22_LCL = D_2 * R(2,2) * R(1,2)                                     
      A23_LCL = R(2,2)**2                                                  
      A31     = R(1,3)**2                                                 
      A32     = D_2 * R(2,3) * R(1,3)                                      
      A33     = R(2,3)**2                                                 
!C
      DEL =   A11_LCL * ( A22_LCL * A33 - A23_LCL * A32 ) 
     &      - A12     * ( A21     * A33 - A23_LCL * A31 )                  
     &      + A13_LCL * ( A21     * A32 - A22_LCL * A31 )                
!C
      AA11 = (  ( A22_LCL - A12     ) * ( A33 - A23_LCL ) 
     &        - ( A23_LCL - A13_LCL ) * ( A32 - A22_LCL ) ) / DEL          
      AA12 = (  ( A23_LCL - A13_LCL ) * ( A31 - A21     )
     &        - ( A21     - A11_LCL ) * ( A33 - A23_LCL ) ) / DEL         
      AA22 = (  ( A21     - A11_LCL ) * ( A32 - A22_LCL ) 
     &        - ( A22_LCL - A12     ) * ( A31 - A21     ) ) / DEL         
!C
      RETURN                                                               
      END                                                                 
