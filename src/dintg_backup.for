      SUBROUTINE DINTG_BACKUP ( K, M, NQUAT )                                                
!C
!C                                                   Rev. V.3 12/15/2002 
!C                                                                       
!C    This subroutine computes the backup entry point if 
!C     H has been halved.  It was created from Subroutine
!C     DINTG and is called only by that subroutine.                          
!C                                                                       
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       ICNT,  GG, H, HPRINT, TSTART, FF, U, Y,  ! /CDINT/
     &       ISTEP, DT, H0, VAR, DER, NEQ, HMIN,      ! /COMAIN/
     &       NDINT,                                   ! /COMAIN/
     &       TIME, NPRT,                              ! /CONTRL/
     &       REGT_SNGL, SEGT,                         ! /INTEST/
     &       XTEST, XTEST_SNGL,                       ! /INTEST/
     &       INTEGER_STD, IREAL_HIGH, LUTERM_OUT,     ! parameters
     &       LOGICAL_STD, LUAOU, TRUE, FALSE,         ! parameters
     &       D_0, D_HALF, D_1, D_1000,                ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5             ! parameters
!C
      USE  MODULE_FLEXIBLE,  ONLY:  NEQP              ! /FXINT/
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &               I, I2, II, J, JJ, K, L, M, NQUAT
!C
      REAL  ( KIND = IREAL_HIGH )
     &             D1, FAIL, TE, TM, TT, TX, TY, TYD, Z
      REAL  ( KIND = IREAL_HIGH )  PARM_1
      PARAMETER  ( PARM_1 = 0.74_IREAL_HIGH )
!C
      LOGICAL ( KIND = LOGICAL_STD )   CONVERGE, SKIP_FAIL                                
!C
      INTENT  (   OUT )  M, NQUAT
      INTENT  ( INOUT )  K
!C
      LOOP_BACK : DO
       D1 = D_HALF * H                                                   
       CALL TRIGFS                                                       
       TSTART = TIME                                                     
       DO  I=1,NEQ                                                       
        U(3,I) = Y(5,I)                                                  
        U(4,I) = U(5,I)                                                  
        DO  J=1,5                                                        
         GG(J,I) = FF(J,I)                                               
        END DO
       END DO
!C
       CALL CMPUTE ( K, I_1, D1 )                                     
       IF ( K .LT. I_0 )  THEN
        CALL DINTG_HALF ( K, CONVERGE )
        IF ( CONVERGE ) RETURN
        CYCLE  LOOP_BACK
       END IF
!C
       CALL ADJUST ( I_1 )                                            
       K = I_2                                                         
       CALL CMPUTE ( K, I_0, D1 )                                  
       IF ( K .LT. I_0 )  THEN
        CALL DINTG_HALF ( K, CONVERGE )
        IF ( CONVERGE )  RETURN
        CYCLE  LOOP_BACK
       END IF
!C
       CALL ADJUST ( I_2 )                                                 
       NQUAT = K                                                         
       K = I_3                                                       
       CALL CMPUTE ( K, I_1, H )                                     
       IF ( K .LT. I_0 )  THEN
        CALL DINTG_HALF ( K, CONVERGE )
        IF ( CONVERGE )  RETURN
        CYCLE  LOOP_BACK
       END IF
!C
       CALL ADJUST ( I_3 )                                           
       DO  20  L=1,NDINT                                                 
        M = I_1                                                        
        IF  ( L .EQ. I_1 )  M = I_0                                     
        IF  ( NPRT(26) .NE. I_2 )  CALL OUTPUT ( I_0 )                
!C
        CALL CMPUTE ( K, M, H )                                          
        IF ( K .LT. I_0 )  THEN
         CALL DINTG_HALF ( K, CONVERGE )
         IF ( CONVERGE )  RETURN
         CYCLE  LOOP_BACK
        END IF
        FAIL = D_1                                                     
        JJ = I_0                                                      
!C
!C      Exclude the deformation modes from rigid body motion checks.      
!C
        SKIP_FAIL = FALSE
        DO  II=1,NEQP,3                                             
         JJ = JJ + I_1                                                   
         IF  ( XTEST_SNGL(II) .LE. D_0 )  CYCLE                     
         TT = DER(II)**2 + DER(II+1)**2 + DER(II+2)**2                   
         TX = VAR(II)**2 + VAR(II+1)**2 + VAR(II+2)**2                    
         TE = D_0                                                       
         TY = D_0                                                      
         I2 = II + I_2                                                      
         DO  I=II,I2                                                      
          Z = GG(5,I) * ( VAR(I) - GG(1,I) ) + GG(2,I) 
     &                             + H * ( GG(3,I) + H * GG(4,I) )      
          TE = TE + ( DER(I) - Z )**2                                     
          TYD = TT + TX * GG(5,I)**2                                      
          IF  ( TYD .EQ. D_0 )  TYD = D_1                               
          TY = TY + ( DER(I) - Z )**2 / TYD                                
         END DO
         TM = D_1000 * TIME                                 
         IF  ( NPRT(25) .NE. I_0 )  THEN  
          WRITE ( LUAOU, 100 )  TM, SEGT(JJ), REGT_SNGL(JJ), 
     &                          TT, TE, TY,                 
     &                         ( XTEST_SNGL(I), I = II,I2 )  
  100     FORMAT ( '0 DINTG Conv. Test', F10.3, 2X, A4, 2X, 
     &              A8, 6G12.4 )  
         END IF
         IF  ( TT .LT. XTEST_SNGL(II) )  CYCLE                        
         IF  ( ( XTEST_SNGL(II+1) .GT. D_0 ) .AND.
     &         ( TE .LT. XTEST_SNGL(II+1) ) )    CYCLE                 
         IF  ( TY .GT. XTEST_SNGL(II+2) )  THEN
          SKIP_FAIL = TRUE
          EXIT               
         END IF
        END DO                                                      
!C 
        IF ( .NOT. SKIP_FAIL )  THEN
         FAIL = D_0                                                   
        END IF
        CALL ADJUST ( I_4 )                                               
!C
        IF  ( FAIL .EQ. D_0 )  THEN
         IF  ( H .GT. ( PARM_1 * HPRINT ) )  ICNT = ICNT + I_1                 
         RETURN                               
        END IF
        IF  ( L .EQ. NDINT )   CYCLE                                  
!C
        CALL CMPUTE ( K, I_1, D1 )                                    
        IF  ( K .LT. I_0 )   THEN
         CALL DINTG_HALF ( K, CONVERGE )
         IF ( CONVERGE )  RETURN
         CYCLE  LOOP_BACK
        END IF
        CALL ADJUST ( I_5 )                                                
   20  CONTINUE                                                          
!C
       IF  ( NPRT(25) .EQ. I_0 )  THEN   
        WRITE ( LUAOU, 100 )  TM, SEGT(JJ), REGT_SNGL(JJ), TT, TE, TY,      
     &                           ( XTEST_SNGL(I), I=II,I2 )            
       END IF
       CALL DINTG_HALF ( K, CONVERGE )
       IF ( CONVERGE )  RETURN
      END DO  LOOP_BACK
!C
      END
