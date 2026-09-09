      SUBROUTINE  UPDATE ( I )                                            
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Called by Subroutine DINTG                                        
!C                                                                        
!C      (I=1)  at the start of a new step to setup any new conditions     
!C             to be valid for entire integration step                    
!C               a. update force deflection functions with
!C                     Subroutine UPDATE_FRC_DEF_CURVE  
!C               b. test for locked joints                               
!C      Note: argument I will be set to -1 to reset integrator.           
!C                                                                        
!C      (I=2)  at the end of each successful integration step to          
!C             complete calculations for output (Subroutine AIRBG3),
!C             update joint actuator parameters and array ROTVJ.      
!C                                                                        
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       ACT_THETA_CUR, ACT_THETA_PREV, ACT_TIME_PREV,          ! /ACTFR1/
     &       NBAG, NBLT, NHRNSS, NJNT, NPL, NPRT, NQ, NSEG, TIME,   ! /CONTRL/
     &       NPSF, NSSF,                                            ! /FORCES/
     &       IBAR, NBLTPH, NL, NPTPLY, NPTSPB, NTHRNS,              ! /HRNESS/
     &       MNBLT, MNPL, MNSEG, NTBLT, NTPL, NTSEG,                ! /JBARTZ/
     &       NTAB, TAB,                                             ! /TABLES/
     &       SEG, JNT,                                              ! structures
     &       INTEGER_STD, D_0, I_0, I_1, I_2, I_6, I_7              ! parameters
!C
!C    DIR_COS     ! SEG%
!C    PROX_SEG    ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &       IBODN, NFBOD, NODJ  ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, II, IJ, J, J1, J2, K, K1, K2, KHRNS, KI, KTOT, 
     &           M, NF, NK, NT, NT6 
!C
      INTENT ( INOUT )  I
!C                                                                        
!C    Call AIRBG3 for airbag, if any.                                     
!C                                                                        
      IF  ( NBAG .NE. I_0 )  CALL AIRBG3 ( I )                          
!C
!C    If at the end of the integration.
!C
      IF  ( I .EQ. I_2 )  THEN                                        
!C
!C     Update time and angle for the joint actuator functions.
!C
       ACT_TIME_PREV = TIME                                                       
       ACT_THETA_PREV = ACT_THETA_CUR                                              
!C
!C    Update ROTVJ() for Subroutine JNTROT.  
!C
       DO  J = 1,NJNT                                                    
        IF ( ( NODJ(2,1,J) .NE. I_0 ) .OR. 
     &       ( NODJ(2,2,J) .NE. I_0 ) ) THEN  
         DO  M = 1,NFBOD                                                 
          IF ( IBODN(M) .EQ. JNT(J)%PROX_SEG ) THEN                 
           CALL JNTROT(1,J,M,2)                                          
          ELSE IF ( IBODN(M) .EQ. ( J + I_1 ) ) THEN                   
           CALL JNTROT(2,J,M,2)                                           
          ELSE                                                           
          END IF                                                         
         END DO                                                          
        END IF                                                           
       END DO                                                            
!C                                                                       
       RETURN                                                             
      END IF
!C
      CALL ELTIME ( I_1, I_7 )                                                
      IF  ( NPL .GT. I_0 )  THEN                                     
!C                                                                        
!C    Call UPDATE_FRC_DEF_CURVE for each allowed plane-segment contact.               
!C                                                                        
       NPSF = I_0                                                    
       DO  J=1,NPL                                                      
        NK = MNPL(J)                                                      
        IF ( NK .GT. I_0 )   THEN                                      
         DO  K = 1, NK                                                    
          NPSF = NPSF + I_1                                            
          NT = NTPL(K,J)                                                  
          NF = NTAB(NT+5)                                                 
          CALL UPDATE_FRC_DEF_CURVE ( NT )                                              
          IF ( ( NT .LE. I_0 ) .AND. ( TAB(NF+3) .NE. D_0 ) )  THEN        
           CALL IMPULS ( 1, K, J )                                        
           I = -I_1                                                     
          END IF                                                          
         END DO
        END IF
       END DO                                                             
      END IF
      IF ( NBLT .GT. I_0 )  THEN                                      
!C                                                                       
!C     Call UPDATE_FRC_DEF_CURVE for each allowed belt-segment contact.                 
!C                                                                        
       DO  J=1,NBLT                                                       
        NK = MNBLT(J)                                                     
        IF ( NK .GT. I_0 )  THEN                                      
         DO  K = 1,NK                                                    
          NT = NTBLT(K,J)                                                 
          NF = NTAB(NT+5)                                                 
          NT6 = NT + I_6                                                
          CALL UPDATE_FRC_DEF_CURVE ( NT )                                             
!C                                                                        
!C        And for 2nd function, if full belt friction.                    
!C                                                                        
          IF  ( NF .NE. I_0 )  CALL UPDATE_FRC_DEF_CURVE ( NT6 )                    
         END DO
        END IF
       END DO                                                             
      END IF
!C                                                                        
!C    Call UPDATE_FRC_DEF_CURVE for each allowed segment-segment contact.               
!C                                                                       
      NSSF = I_0                                                      
      DO  J=1,NSEG                                                        
       NK = MNSEG(J)                                                      
       IF ( NK .GT. I_0 )  THEN                                       
        DO  K = 1,NK                                                      
         NSSF = NSSF + I_1                                              
         NT = NTSEG(K,J)                                                 
         NF = NTAB(NT+5)                                                
         CALL UPDATE_FRC_DEF_CURVE ( NT )                                             
         IF ( ( NT .LE. I_0 ) .AND. ( TAB(NF+3) .NE. D_0 ) )  THEN      
          CALL IMPULS ( 3, K, J )                                         
          I = -I_1                                                      
         END IF
        END DO                                                            
       END IF
      END DO                                                              
      IF ( NHRNSS .GT. I_0 )  THEN                                     
!C                                                                        
!C     Call UPDATE_FRC_DEF_CURVE for each belt of harness-belt systems.                
!C                                                                       
       CALL HPTURB                                                       
       J1 = I_1                                                         
       K1 = I_1                                                       
       DO  II=1,NHRNSS                                                    
        IF ( NBLTPH(II) .GT. I_0 )  THEN                           
         J2 = J1 + NBLTPH(II) - I_1                                   
         DO  J=J1,J2                                                     
          IF  ( NPTPLY(J) .GT. I_0 )  THEN                         
           K2 = K1 + NPTPLY(J) - I_1                                 
           DO  K=K1,K2                                                  
            KI = NL(1,K)                                                
            IF ( J .EQ. I_1 )  THEN                                  
             KHRNS = KI                                                 
            ELSE                                                        
             KTOT = I_0                                             
             DO  IJ=1,J-1                                               
              KTOT = KTOT + NPTSPB(IJ)                                  
             END DO                                                     
             KHRNS = KI - KTOT                                          
            END IF                                                      
            NT = NTHRNS(J,KHRNS)                                        
            CALL UPDATE_FRC_DEF_CURVE ( NT )                                          
            NT = IBAR(3,KI)                                             
            CALL UPDATE_FRC_DEF_CURVE ( NT )                                          
           END DO                                                         
           K1 = K2 + I_1                                             
          END IF
         END DO                                                          
         J1 = J2 + I_1                                               
        END IF
       END DO                                                             
      END IF
!C
!C    Update the joints.
!C
      IF ( NJNT .GT. I_0 )  THEN                                      
       CALL UPDATE_JOINTS ( I )
      END IF
!C
!C    Update the constraint forces.
!C
      IF  ( NQ .GT. I_0 )  THEN                                       
       CALL UPDATE_CONSTRAINTS ( I )
      END IF
!C
      CALL ELTIME ( I_2, I_7 )                                                
!C
      RETURN                                                              
      END                                                                 
