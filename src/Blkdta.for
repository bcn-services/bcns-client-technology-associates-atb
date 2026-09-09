      SUBROUTINE BLKDTA                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine replaces the BLOCK DATA subprogram of previous      
!C    versions of CVS-III to initialize variables in a manner     
!C    that is independent of the computer system being utilized.          
!C                                                                        
!C                                                                      
      USE  MODULE_STANDARD,  
     &        ONLY:  G, UNITL, UNITM, UNITT, PI, RADIAN,   ! /CNSNTS/
     &               TWOPI, EPS, GRAVTY,                   ! /CNSNTS/
     &               ICHAR_STD, INTEGER_STD, IREAL_HIGH,   ! parameters
     &               D_0, D_1, D_2, D_10, D_180            ! parameters
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I
!C
!C
      UNITM = ICHAR_STD_' LBS    '                                                       
      UNITT = ICHAR_STD_' SEC    '                                                        
      UNITL = ICHAR_STD_' IN     '                                                        
      G     = 386.088E0_IREAL_HIGH                                      
      GRAVTY(1) = D_0                                                   
      GRAVTY(2) = D_0                                                   
      GRAVTY(3) = G                                                      
      PI = ATAN2 ( D_0, -D_1 )                                          
      TWOPI = D_2 * PI                                    
      RADIAN = PI / D_180                                          
      EPS(1) = D_1 / D_10                                              
      DO  I=2,24                                                         
       EPS(I) = EPS(I-1) / D_10                                          
      END DO
!C
      RETURN                                                             
      END                                                               
