      SUBROUTINE DINTG                                                  
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       TPRINT, ICNT, IDBL, GG, H, HPRINT,    ! /CDINT/
     &       HS=>TSAVE, TSTART, FF, U, Y,          ! /CDINT/
     &       EPS,                                  ! /CNSNTS/
     &       ISTEP, DT, H0, VAR, DER, NEQ, HMIN,   ! /COMAIN/
     &       NDINT, HMAX,                          ! /COMAIN/
     &       TIME, NPRT,                           ! /CONTRL/
     &       REGT_SNGL, SEGT,                      ! /INTEST/
     &       XTEST, XTEST_SNGL,                    ! /INTEST/
     &       INTEGER_STD, IREAL_HIGH, LUTERM_OUT,  ! parameters
     &       LOGICAL_STD, LUAOU, TRUE, FALSE,      ! parameters
     &       D_0, D_HALF, D_1, D_2, D_1000,        ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5          ! parameters
!C
      USE  MODULE_FLEXIBLE,  ONLY:  NEQP           ! /FXINT/
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &               I, INRT, J, K, M, NQUAT
!C
      REAL  ( KIND = IREAL_HIGH )  GG4, GG5, XPRINT
      REAL  ( KIND = IREAL_HIGH )  DINT_PARM 
      PARAMETER  ( DINT_PARM = -1600.0_IREAL_HIGH )
!C
      LOGICAL ( KIND = LOGICAL_STD )  LNRT                                 
!C
      CALL ELTIME ( I_1, I_3)                                                  
!C
      IF  ( ISTEP .EQ. I_0 )  THEN                              
!C                                                                      
!C     IN=0: initial call to integrator - initialize and reset parameters    
!C     Note: for earlier versions of CVS, the variable 'IN'(ISTEP in the 
!C           calling program) ran fron 1 to NSTEPS + 1, now it runs from   
!C           0 to NSTEPS.                                                
!C                                                                      
       TPRINT = TIME                                                   
       IDBL = I_2                                                        
       K = I_0                                                     
!C                                                                      
!C     Initialize integrator.                                  
!C                                                                      
       H = H0                                                            
       HPRINT = H0                                                       
       HS = D_0                                                        
       ICNT = -I_2                                                    
       CALL OUTPUT ( I_0 )           
       CALL PDAUX ( VAR, DER, NEQ, K )                                   
       DO  I=1,NEQ                                                       
        FF(1,I) = VAR(I)                                                 
        FF(2,I) = DER(I)                                                 
        DO  J=3,5                                                        
         FF(J,I) = D_0                                             
         U(J,I) = D_0                                                  
         Y(J,I) = D_0                                                
        END DO
       END DO
!C
       CALL UPDATE ( I_2 )                                             
       LNRT = FALSE                                                   
       IF ( NPRT(26) .GE. I_0 )  THEN
        LNRT = TRUE                     
       ELSE  
        INRT = ABS ( NPRT(26) )         
        LNRT = ( MOD ( ISTEP, INRT ) .EQ. I_0 )     
       END IF
       IF ( LNRT )  CALL OUTPUT ( I_1 )                                 
!C
       CALL ELTIME ( I_2, I_3 )                                              
!C
       RETURN                                                            
      END IF
!C                                                                      
!C    IN#0: advance TPRINT - TIME to return to calling program.         
!C                                                                      
      TPRINT = TPRINT + DT                                              
      H = HPRINT                                                        
!C                                                                      
!C    Entry to advance integrator.                                       
!C                                                                      
      DO
       K = I_1                                                       
       CALL UPDATE ( K )                                                 
!C                                                                      
!C     Negative K from UPDATE is indicator to reset integrator.         
!C                                                                      
       IF  ( K .NE. I_1 )   THEN                                 
!C                                                                      
!C      Reset or initialize integrator.                                  
!C                                                                      
        H = H0                                                            
        HPRINT = H0                                                       
        HS = D_0                                                        
        ICNT = -I_2                                                    
        IF  ( NPRT(26) .EQ. I_2 )  CALL OUTPUT ( I_0 )           
        CALL PDAUX ( VAR, DER, NEQ, K )                                   
        IF  ( NPRT(26) .EQ. I_2 )  CALL OUTPUT ( I_1 )            
        DO  I=1,NEQ                                                       
         FF(1,I) = VAR(I)                                                 
         FF(2,I) = DER(I)                                                 
         DO  J=3,5                                                        
          FF(J,I) = D_0                                             
          U(J,I) = D_0                                                  
          Y(J,I) = D_0                                                
         END DO
        END DO
        K = I_1                                                         
       END IF
!C                                                                      
!C     Adjust H (current time step) if it will advance T beyond TPRINT.  
!C                                                                       
       IF  ( ( H + EPS(8) ) .GE. ( TPRINT - TIME ) ) H = TPRINT - TIME                    
!C                                                                       
!C     Backup entry point if H has been halved.                          
!C                                                                       
       CALL DINTG_BACKUP ( K, M, NQUAT )
!C
       K = I_4                                                       
       M = I_0                                                       
       IF  ( ( H .GT. HMIN ) .AND. ( IDBL .GT. I_2 ) ) 
     &                IDBL = IDBL - I_1    
       GG4 = D_2 * H                                                     
       GG5 = EXP ( DINT_PARM * H )                                    
!C
       DO  I=1,NEQ                                                       
        FF(3,I) = GG(3,I) + GG4 * GG(4,I)                                
        FF(4,I) = GG(4,I)                                                
        FF(5,I) = GG(5,I)                                                
        Y(3,I)  = Y(1,I)                                                 
        Y(4,I)  = Y(2,I)                                                 
        Y(5,I)  = GG5 * U(3,I)                                           
        U(5,I)  = GG5 * U(4,I)                                           
       END DO
!C
       CALL QSET ( FF, Y, VAR, DER, NQUAT )                              
       CALL PDAUX ( VAR, DER, M, K )                                     
       DO  I=1,NEQ                                                       
        FF(1,I) = VAR(I)                                                 
        FF(2,I) = DER(I)                                                 
       END DO
       HS = H                                                            
       IF  ( ICNT .GE. IDBL )  THEN                                  
        ICNT = I_0                                                   
        H = MIN ( ( D_2 * H ), HMAX )                                    
        HPRINT = MIN ( ( D_2 * HPRINT ), HMAX )                          
       END IF
!C
       CALL UPDATE ( I_2 )                                             
       XPRINT = TPRINT - TIME                                              
       IF ( ( XPRINT .GE. EPS(8) ) .AND. ( NPRT(26) .NE. I_3 )
     &                             .AND. ( NPRT(26) .GE. I_0 ) )      
     &  CALL OUTPUT ( I_1 )                                            
!C
       IF ( XPRINT .LT. EPS(8) )   EXIT                                 
      END DO
!C
      LNRT = FALSE                                                   
      IF ( NPRT(26) .GE. I_0 )  THEN
       LNRT = TRUE                     
      ELSE  
       INRT = ABS ( NPRT(26) )         
       LNRT = ( MOD ( ISTEP, INRT ) .EQ. I_0 )     
      END IF
      IF ( LNRT )  CALL OUTPUT ( I_1 )                                 
!C
      CALL ELTIME ( I_2, I_3 )                                              
!C
      RETURN                                                            
      END                                                               
