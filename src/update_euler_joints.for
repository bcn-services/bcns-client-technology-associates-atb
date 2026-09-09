      SUBROUTINE  UPDATE_EULER_JOINTS ( I )
!C
!C                                                 Rev. V.3 12/15/2002 
!C   
!C    This subroutine tests whether to lock or unlock the
!C     Euler joint axes.  It was created from Subroutine UPDATE_JOINTS.
!C
!C    It uses same test as in Subroutine UPDATE_JOINTS, but on 
!C     each axis of the Euler joint serarately.                 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       ANG, ANGD, HIR, IEULER,                         ! /CEULER/
     &       NJNT, TIME,                                     ! /CONTRL/
     &       VISC,                                           ! /DESCRP/
     &       JNT,                                            ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU, D_0, D_1000,    ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_7, I_8     ! parameters 
!C
!C    COS_NUTA, SIN_NUTA, JTYPE, JTORQUE, PROX_HA, DSTL_HA  ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, J, JEULER, K, K3J, K4, LOCK, MODE, NLOCK
      DIMENSION  LOCK(8,3)
!C
      REAL  ( KIND = IREAL_HIGH )
     &           T, TMSEC, TQM, TQTEST
      DIMENSION         T(3), TQTEST(3)                                  
!C
      DATA LOCK / -8,   6,    5,
     &             7,  -3,   -2,
     &            -4,   1,    6,  
     &            -8,   4,   -3, 
     &             7,  -1,   -5,                                
     &             2,   5,    4,
     &            -8,  -2,   -1,
     &             7,  -6,    3 /                             
!C
      INTENT ( OUT )  I
!C
!C    If LOCK(IEULER,K) is negative, axis K is locked;                   
!C      to unlock axis set IEULER to -LOCK(IEULER,K).                   
!C                                                                       
!C    If LOCK(IEULER,K) is positive, axis K is unlocked;                  
!C      to lock axis set IEULER to LOCK(IEULER,K).                        
!C                                                                        
      DO 20 J=1,NJNT                                                     
       IF ( ABS ( JNT(J)%JTYPE ) .NE. I_4 )  CYCLE                             
       JEULER = IEULER(J)                                                 
       CALL DOT31 ( HIR(1,1,J), JNT(J)%JTORQUE, TQTEST )                         
       DO  K=1,3                                                         
        K3J = I_3 * J - I_3 + K                                               
        NLOCK = LOCK(JEULER,K)                                            
        IF ( NLOCK .LE. I_0 )  THEN                                         
         IF ( VISC(4,K3J) .EQ. D_0 )  CYCLE                               
         IF ( ABS ( TQTEST(K) ) .LE. VISC(4,K3J) ) CYCLE                  
         JEULER = -NLOCK                                                  
         JNT(J)%PROX_HA(K) = TQTEST(K)                                        
         CYCLE                                                            
        END IF
        IF  ( JNT(J)%DSTL_HA(K) .EQ. D_0 )  JNT(J)%PROX_HA(K) = D_0                       
        IF ( VISC(5,K3J) .NE. D_0 )  THEN                                 
         IF ( ABS ( TQTEST(K) ) .LT. VISC(5,K3J) )  JEULER =  NLOCK      
         CYCLE                                                         
        END IF
        IF ( VISC(6,K3J) .EQ. D_0 )  CYCLE                             
        IF ( ABS ( ANGD(K,J) ) .LT. VISC(6,K3J) )  JEULER =  NLOCK       
       END DO                                                             
!C
       IF ( JEULER .EQ. IEULER(J) )  CYCLE                                 
       TMSEC = D_1000 * TIME                                               
       WRITE ( LUAOU, 110 )  TMSEC, J, IEULER(J), JEULER                   
  110  FORMAT ( '0 At time =', F9.3, ' msec, IEULER(', I2,                   
     &          ') has been changed from', I3, ' to', I3 )                   
       IF  ( ( JEULER .EQ. I_8 )             .OR.                             
     &       ( IEULER(J) .EQ. I_7 )          .OR.                              
     &       ( ( IEULER(J) .EQ. I_6 ) .AND. 
     &         ( ( JEULER .EQ. I_2 ) .OR. 
     &         ( JEULER .EQ. I_1 ) ) )       .OR.  
     &       ( ( IEULER(J) .EQ. I_5 ) .AND. 
     &         ( ( JEULER .EQ. I_3 ) .OR. 
     &         ( JEULER .EQ. I_1 ) ) )       .OR.    
     &       ( ( IEULER(J) .EQ. I_4 ) .AND. 
     &         ( ( JEULER .EQ. I_3 ) .OR. 
     &         ( JEULER .EQ. I_2 ) ) ) )   THEN
        IEULER(J) = JEULER                                                 
        JNT(J)%JTYPE = I_4                                                    
        IF ( IEULER(J) .NE. I_8 )  JNT(J)%JTYPE = -I_4                             
!C
!C      Get sine and cosine of nutation if IEULER goes to state 2.          
!C
        CALL EJOINT ( -I_1, J )                                                 
        IF ( JEULER .EQ. I_2 )  THEN                                           
         TQM = ANG(2,J) + JNT(J)%CNTR_SYM(2)                                        
         JNT(J)%COS_NUTA = COS ( TQM )
         JNT(J)%SIN_NUTA = SIN ( TQM )
        END IF
        CYCLE
       END IF
!C
       MODE = -I_1                                                      
       K = JEULER                                                      
       IF  ( K .LE. I_3 )   THEN                                       
        IF  ( K .NE. I_2 )   THEN                                  
         K4 = I_4 - K                                                    
         CALL CROSS ( HIR(1,K4,J), HIR(1,2,J), T )                       
         IEULER(J) = I_8                                            
         JNT(J)%JTYPE   = I_4                                                
         CALL IMPLS2 ( MODE, J, T )                                        
         I = -I_1                                                         
        ELSE
         IEULER(J) = I_8                                              
         JNT(J)%JTYPE   = I_4                                                  
         CALL IMPLS2 ( MODE, J, HIR(1,K,J) )                               
         I = -I_1                                                         
        END IF
       ELSE
        MODE =  I_1                                                      
        K = K - I_3                                                          
        IF ( K .GT. 3 )  MODE = I_0                                           
        IEULER(J) = I_8                                              
        JNT(J)%JTYPE   = I_4                                                  
        CALL IMPLS2 ( MODE, J, HIR(1,K,J) )                               
        I = -I_1                                                         
       END IF
       IEULER(J) = JEULER                                                 
       JNT(J)%JTYPE = I_4                                                    
       IF ( IEULER(J) .NE. I_8 )  JNT(J)%JTYPE = -I_4                             
!C
!C     Get sine and cosine of nutation if IEULER goes to state 2.          
!C
       CALL EJOINT ( -I_1, J )                                                 
       IF ( JEULER .EQ. I_2 )  THEN                                           
        TQM = ANG(2,J) + JNT(J)%CNTR_SYM(2)                                        
        JNT(J)%COS_NUTA = COS ( TQM )
        JNT(J)%SIN_NUTA = SIN ( TQM )
       END IF
   20 CONTINUE                                                          
!C
      RETURN
      END