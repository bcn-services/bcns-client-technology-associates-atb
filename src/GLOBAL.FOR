      SUBROUTINE GLOBAL ( J, HD3, DH1, TQC, T9, ANGL )                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:   
     &       EPS,                       ! /CNSNTS/
     &       IGLOB,                     ! /DESCRP/
     &       NTAB, TAB,                 ! /TABLES/
     &       CREST, JSTOP,              ! /TEMPVI/
     &       INTEGER_STD, IREAL_HIGH,   ! parameters
     &       D_0, D_1, I_0, I_1         ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  J, L, LT, MT, NT, NT1
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  CST, CTH, DR, DRDOT, ELOSS, STH, STH2,
     &                  THET0, THET0P, TQC, TQF, 
     &                  HD3, DH1, T9, ANGL, CC
      DIMENSION         HD3(3), DH1(3,3), T9(3), ANGL(3), CC(3)           
!C
      INTENT (  IN )  J, HD3, DH1
      INTENT ( OUT )  TQC, T9, ANGL
!C
      IF ( ABS ( HD3(3) ) .GT. ( D_1 - EPS(6) ) )   RETURN               
      ANGL(1) = ACOS ( HD3(3) )                                           
      NT = IGLOB(J)                                                       
      NT1 = NTAB(NT+2)                                                    
      CALL HERRON ( HD3, NT1, THET0, THET0P )                             
      JSTOP(4,1,J) = I_0                                              
      IF ( ANGL(1) .LE. THET0 )  RETURN                                   
      JSTOP(4,1,J) = I_1                                                
      MT = NTAB(NT+5)                                                     
      CREST = TAB(MT+3)                                                   
      STH2 = D_1 - HD3(3)**2                                              
      STH = SQRT ( STH2 )                                                 
      CTH = HD3(3) / STH                                                  
      CST = SQRT ( STH2 + THET0P**2 )                                     
      DR  = ( ANGL(1) - THET0 ) * STH / CST                               
      LT  = NTAB(NT)                                                      
      TAB(LT) = DR                                                        
      NTAB(NT+2) = I_0                                                
      DRDOT = D_0                                                        
      CALL FRCDFL ( DR, DRDOT, NT, I_1, TQF, ELOSS )                   
      NTAB(NT+2) = NT1                                                    
      TQC = TQF / CST                                                     
      CC(1) = -HD3(2) + HD3(1) * CTH * THET0P                             
      CC(2) =  HD3(1) + HD3(2) * CTH * THET0P                             
      CC(3) =                   -STH * THET0P                             
      DO  L=1,3                                                           
       T9(L) = CC(1) * DH1(L,1) + CC(2) * DH1(L,2) + CC(3) * DH1(L,3)     
      END DO
!C
      RETURN                                                              
      END                                                                 
