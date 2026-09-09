      SUBROUTINE CMPUTE ( K, M, FT )                                      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &             E, GG, TSTART,           ! /CDINT/
     &             DER, NEQ, VAR,           ! /COMAIN/
     &             NPRT, TIME,              ! /CONTRL/
     &             INTEGER_STD, IREAL_HIGH, ! parameters
     &             I_0, I_1, I_2            ! parameters
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C   
      INTEGER  ( KIND = INTEGER_STD ) K, M
!C
      REAL  ( KIND = IREAL_HIGH )  FT
!C
      INTENT ( IN )     M, FT
      INTENT ( INOUT )  K
!C
      TIME = TSTART + FT                                                 
!C
      CALL DZP ( NEQ, VAR, GG, E, FT, M )                                
      IF  ( NPRT(26) .EQ. I_2 )  CALL OUTPUT( I_0 )                 
!C
      CALL PDAUX ( VAR, DER, NEQ, K )                                     
      IF  ( NPRT(26) .EQ. I_2 )  CALL OUTPUT( I_1 )                
!C
      RETURN                                                              
      END                                                                
