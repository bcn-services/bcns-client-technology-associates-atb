      SUBROUTINE  FUNC_RATE_DEP ( D_LCL, F_LCL, RATE, 
     &                            M, N, FRCDF, ELOSS )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:   
     &       NTAB,                         ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH,      ! parameters
     &       I_0, I_1, D_0                 ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              M, N, N2, N3, N4
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  D_LCL, ELOSS, 
     &                  F_LCL, F2, F3, F4, FRCDF, RATE
!C
      REAL  ( KIND = IREAL_HIGH )   EVALFD
      EXTERNAL  EVALFD
!C
      INTENT   ( IN )   D_LCL, M, N, RATE  
      INTENT  ( OUT )   F_LCL, FRCDF, ELOSS
!C
      IF ( N .NE. I_1 )  THEN                                           
       FRCDF = F_LCL                                                      
      ELSE
!C                                                                        
!C    Compute and add rate dependent functions, if any.                   
!C                                                                        
!C    Current restrictions:                                               
!C                                                                        
!C       1) computed for N=1 (function) only.                             
!C                                                                        
!C       2) function nos. M+2,M+3 and M+4 (used for inertial spike,       
!C          R factor and G factor functions) must be negative or zero,    
!C          i.e., these functions cannot be used in conjunction with      
!C          the rate dependent functions.                                 
!C                                                                        
!C       3) assumes the functional form                                   
!C                                                                        
!C                F(D,D') = F1(D) + F2(D)*F3(D') + F4(D')                 
!C                                                                        
!C          where F1(D ) is defined by function NTAB(M+1)>0,              
!C                       i.e., normal force deflection function with no   
!C                       inertial spike function and default values       
!C                       R=1 and G=0 (unloading and reloading same as     
!C                       original loading);                               
!C                                                                        
!C                F2(D ) is defined by function NTAB(M+2)<0,              
!C                       if NTAB(M+2)=0, F2(D )=0;                        
!C                                                                        
!C                F3(D') is defined by function NTAB(M+3)<0,              
!C                       if NTAB(M+3)=0, F3(D')=0;                        
!C                                                                        
!C           and  F4(D') is defined by function NTAB(M+4)<0,              
!C                       if NTAB(M+4)=0, F4(D')=0.                        
!C                                                                        
!C          Note: functional form can be changed by revising program      
!C          between statements 40 and last statement.                     
!C                                                                        
       F2 = D_0                                                          
       F3 = D_0                                                          
       F4 = D_0                                                        
       N2 = -NTAB(M+2)                                                     
       N3 = -NTAB(M+3)                                                     
       N4 = -NTAB(M+4)                                                     
       IF  ( N2 .GT. I_0 )  F2 = EVALFD ( D_LCL, N2, N )                
       IF  ( N3 .GT. I_0 )  F3 = EVALFD ( RATE,  N3, N )                
       IF  ( N4 .GT. I_0 )  F4 = EVALFD ( RATE,  N4, N )              
       F_LCL = F_LCL + F2 * F3 + F4                                        
       ELOSS = RATE * ( F2 * F3 + F4 )                                     
       FRCDF = F_LCL                                                       
      END IF
!C
      RETURN
      END 