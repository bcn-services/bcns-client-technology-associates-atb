      SUBROUTINE  UPDATE_TAB ( L, LC, A0, A1, A2, A3, 
     &                         DCUBIC, DC0, D_LCL )
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C    This subroutine updates the TAB array.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       TIME,                                ! /CONTRL/
     &       TAB,                                 ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH              ! parameters 
!C   
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  L, LC 
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A0, A1, A2, A3, D_LCL, DC0, DCUBIC
!C
      INTENT ( IN )  L, LC, A0, A1, A2, A3, DCUBIC, DC0, D_LCL
!C
!C    Update the TAB array for the functions.
!C
      TAB(LC)   = A0                                                        
      TAB(LC+1) = A1                                                      
      TAB(LC+2) = A2                                                      
      TAB(LC+3) = A3                                                      
      TAB(L +6) = DCUBIC                                                  
      TAB(L+18) = DC0                                                     
      TAB(L+1)  = D_LCL                                                    
      TAB(L+30) = TIME
!C
      RETURN
      END                                                     
