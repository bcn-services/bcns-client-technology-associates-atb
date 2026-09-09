      SUBROUTINE VPATH2 ( NUMVEH_LCL, NGRND_LCL )           
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Enter subroutine from Subroutine INPUT_INITIAL_CONDITIONS
!C     to change the ground segment number from 0 to NGRND.  
!C     This was not done during     
!C     the call to Subroutine VPATH because the value of NGRND            
!C     determined in Subroutine VINPUT could have been increased if       
!C     air bags were specified by the D cards.                            
!C                                                                       
      USE  MODULE_STANDARD, ONLY:  
     &       VEH,                      ! structures
     &       INTEGER_STD, I_0          ! parameters
!C          
!C           IVREF           VEH%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &              I, NGRND_LCL, NUMVEH_LCL
!C
      INTENT ( IN )  NUMVEH_LCL, NGRND_LCL
!C                                                                       
      DO  I=1,NUMVEH_LCL                                                 
       IF ( VEH(I)%IVREF .EQ. I_0 )  THEN                         
        VEH(I)%IVREF = NGRND_LCL                                      
       END IF                                                            
      END DO                                                            
!C
      RETURN                                                              
      END                                                                
