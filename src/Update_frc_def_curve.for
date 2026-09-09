      SUBROUTINE  UPDATE_FRC_DEF_CURVE  ( M )                                          
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Update force deflection curve definition that is defined            
!C    in location M of NTAB array.  Subroutine assumes that               
!C    a successful integration step has just been completed and           
!C    will compute entire curve definition to be valid for next step.    
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       TIME,                              ! /CONTRL/
     &       NTAB, TAB,                         ! /TABLES/
     &       INTEGER_STD, IREAL_HIGH,           ! parameters 
     &       I_0, D_0                           ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  L, M
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  D_LCL, DCUBIC, DG0, DLAST 
!C 
      REAL  ( KIND = IREAL_HIGH )   EVALFD
      EXTERNAL          EVALFD
!C
      INTENT ( INOUT )  M
!C
!C
      L     = NTAB(M)                                                   
      IF  ( L .EQ. I_0 )  THEN
       TAB(L+30) = TIME                                                  
       RETURN                                                             
      END IF
!C
      D_LCL      = TAB(L)                                                
      IF ( D_LCL .LT. D_0 )   D_LCL = D_0                               
      DLAST  = TAB(L+1)                                                   
      IF ( D_LCL .EQ. DLAST )  THEN                                       
       TAB(L+30) = TIME                                                    
       RETURN                                                             
      END IF
!C
!C    Retrieve function values.
!C
      DCUBIC = TAB(L+6)                                                   
      DG0    = TAB(L+5)                                                   
!C
      IF  ( ( D_LCL .EQ. DCUBIC ) .OR. ( NTAB(M+1) .LT. I_0 ) )  THEN                                      
       TAB(L+1) = D_LCL                                                   
       IF ( ( D_LCL .GT. DG0 ) .AND. ( DLAST .LE. DG0 ) ) M = -M          
       TAB(L+30) = TIME                                                    
       RETURN                                                             
      END IF
!C
      IF  ( ( D_LCL - DCUBIC ) .LT. D_0 ) THEN                          
       CALL DEF_NEW_CUBIC ( L, M, D_LCL )
      ELSE IF ( ( D_LCL - DCUBIC ) .EQ. D_0 ) THEN
       TAB(L+1) = D_LCL                                                   
       TAB(L+30) = TIME                                                   
      ELSE
       CALL DEF_NEW_QUADRATIC ( L, M, D_LCL, DCUBIC )
      END IF       
!C
      IF ( ( D_LCL .GT. DG0 ) .AND.  ( DLAST .LE. DG0 ) )  M = -M         
!C
      RETURN                                                              
      END                                                                
