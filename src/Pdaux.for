      SUBROUTINE PDAUX ( VAR_LCL, DER_LCL, NEQ_LCL, KDINT )                          
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Purpose is to act as interface between integrator and DAUX to        
!C    accomodate variable number of functions to be integrated.            
!C                                                                         
!C    Arguments:                                                           
!C       VAR - array of NEQ state variables updated by DINTG.            
!C       DER - array of NEQ derivatives to be supplied by DAUX.            
!C       NEQ - number of state variables and derivatives.                  
!C       KDINT - integration step number in DINTG.                      
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &        IEULER,                                         ! /CEULER/
     &        NFLX, NGRND,                                    ! /CONTRL/
     &        NFLEX,                                          ! /FLXBLE/
     &        REGT_SNGL, SEGT, XTEST,                         ! /INTEST/
     &        SEG, JNT,                                       ! structures
     &        ICHAR_STD, INTEGER_STD, IREAL_HIGH,             ! parameters
     &        LOGICAL_STD, MAXEQN, MAXSEG, TRUE, FALSE,       ! parameters
     &        I_0, I_1, I_2, I_3, I_4, I_5, I_6,              ! parameters
     &        D_0, D_HALF, D_1                                ! parameters
!C
!C    ANG_ACL_CONV, ANG_VEL_CONV, LIN_ACL_CONV, LIN_VEL_CONV,  ! SEG%
!C    ANG_ACCEL, ANG_VEL, DIR_COS, LIN_ACCEL, LIN_DISP,        ! SEG% 
!C    LIN_VEL,   NAME,    SINGULAR                             ! SEG%
!C
!C    PROX_SEG, JTYPE                                          ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &         I, J, KDINT, M, MBAG_LCL, N, NEQ_LCL, NQUAT, NTST
      DIMENSION  NTST(MAXSEG)
!C
      REAL  ( KIND = IREAL_HIGH )
     &             DER_LCL, SD, E1, EDOTE, VAR_LCL, VXT
!C
      DIMENSION         DER_LCL(3,MAXEQN), SD(3,3,MAXSEG), E1(MAXSEG),  
     &                  VAR_LCL(3,MAXEQN), VXT(3)                         
!C
      CHARACTER ( LEN = 8, KIND = ICHAR_STD )  RGTTL
      DIMENSION      RGTTL(4)
!C
      LOGICAL   ( KIND = LOGICAL_STD )  LSEG                                        
      DIMENSION  LSEG(MAXSEG)
!C
      DATA NTST / MAXSEG * I_0 /                   
      DATA RGTTL / ICHAR_STD_'ANG VEL ', ICHAR_STD_'LIN VEL ', 
     &             ICHAR_STD_'ANG ACC ', ICHAR_STD_'LIN ACC '/       
!C
      CALL ELTIME ( I_1, I_6 )                                       
!C
      MBAG_LCL = NGRND                                                    
      IF ( KDINT .LE. I_0 )  THEN                                      
       LSEG(1) = FALSE                                                 
       NTST(1) = I_1                                                  
       DO  M=2,MBAG_LCL                                                   
        LSEG(M) = ( SEG(M)%SINGULAR .GE. I_0 ) .AND. 
     &            ( JNT(M-1)%PROX_SEG .NE. I_0 )    
        IF ( ( ABS( JNT(M-1)%JTYPE ) .GE. I_5 ) .AND. 
     &             ( IEULER(M-1) .GE. I_0 )  )  LSEG(M) = FALSE       
        NTST(M) = M                                                        
       END DO
       NTST(NGRND) = -NGRND                                               
       LSEG(NGRND) = TRUE                                              
       IF ( NFLX .NE. I_0 )  THEN                                      
        DO  J=1,NFLX                                                       
         M = NFLEX(2,J)                                                    
         NTST(M) = -M                                                     
        END DO
       END IF
      END IF
!C
      IF  ( KDINT .EQ. I_4 )  THEN                                
       N = I_0                                                          
       DO  M=1,MBAG_LCL                                                    
        IF ( NTST(M) .GE. I_0 )  THEN                                     
         N = N + I_1                                                      
         E1(N) = D_1                                                     
         DO  I=1,3                                                        
          DER_LCL(I,N) = D_HALF * SEG(M)%ANG_VEL(I)                       
          VAR_LCL(I,N) = D_0                                              
         END DO
        END IF                                                             
       END DO
       IF  ( KDINT .EQ. I_2 )   KDINT = NQUAT                          
       CALL ELTIME ( I_2, I_6 )                                         
       RETURN                                                            
      END IF
!C
      IF  ( KDINT .LE. I_0 )   THEN                                 
!C                                                                         
!C     KDINT=0 implies initial call from DINTG. PDAUX to supply initial     
!C     values to state variables and compute value of NEQ.                  
!C                                                                         
!C                                                                         
!C       (A) Set Q to identity QUATERNION                                   
!C                                                                         
       N = I_0                                                          
       DO  M=1,MBAG_LCL                                                     
        IF ( NTST(M) .GE. I_0 )   THEN                                  
         N = N + I_1                                                    
         REGT_SNGL(N) = RGTTL(1)                                            
         SEGT(N) = SEG(M)%NAME                                            
         E1(N) = D_1                                                  
         DO  I=1,3                                                          
          XTEST(I,N) = SEG(M)%ANG_VEL_CONV(I)**2                            
          VAR_LCL(I,N) = D_0                                                
         END DO
        END IF                                                              
       END DO
!C                                                                          
!C       (B) Linear displacement of reference segments             
!C                                                                          
       DO  M=1,MBAG_LCL                                                    
        IF  ( .NOT. LSEG(M) )  THEN                                         
         N = N + I_1                                                     
         REGT_SNGL(N) = RGTTL(2)                                            
         SEGT(N) = SEG(M)%NAME                                            
         DO  I=1,3                                                          
          XTEST(I,N) = SEG(M)%LIN_VEL_CONV(I)**2                          
          VAR_LCL(I,N) = SEG(M)%LIN_DISP(I)                            
         END DO
        END IF                                                             
       END DO
!C                                                                          
!C       (C) WMEG                                                           
!C                                                                          
       DO  M=1,MBAG_LCL                                                    
        IF ( NTST(M) .GE. I_0 )   THEN                                   
         N = N + I_1                                                     
         REGT_SNGL(N) = RGTTL(3)                                            
         SEGT(N) = SEG(M)%NAME                                            
         DO  I=1,3                                                         
          XTEST(I,N) = SEG(M)%ANG_ACL_CONV(I)**2                          
          VAR_LCL(I,N) = SEG(M)%ANG_VEL(I)                              
         END DO
        END IF                                                             
       END DO
!C                                                                         
!C       (D) Linear velocity of reference segments                        
!C                                                                          
       DO  M=1,MBAG_LCL                                                     
        IF  ( .NOT. LSEG(M) )  THEN                                        
        N = N + I_1                                                    
        REGT_SNGL(N) = RGTTL(4)                                            
        SEGT(N) = SEG(M)%NAME                                             
         DO  I=1,3                                                         
          VAR_LCL(I,N) = SEG(M)%LIN_VEL(I)
          XTEST(I,N) = SEG(M)%LIN_ACL_CONV(I)**2                                 
         END DO
        END IF                                                             
       END DO
       NEQ_LCL = I_3 * N                                            
!C
!C     Transfer initial modal pos. & vel. to var                        
!C
       CALL FMODV0 ( VAR_LCL, NEQ_LCL )                                  
      ELSE
       IF ( KDINT .EQ. I_1 )  THEN                                       
!C                                                                         
!C      KDINT = 1, 1st step in advancing integrating interval,              
!C                    save DC matrices if time has advanced.               
!C                                                                          
        N = I_0                                                         
        DO  M=1,MBAG_LCL                                                    
         IF ( NTST(M) .GE. I_0 )  THEN                                 
          N = N + I_1                                                     
          DO  J=1,3                                                         
           DO  I=1,3                                                        
            SD(I,J,N) = SEG(M)%DIR_COS(I,J)                               
           END DO
          END DO
         END IF                                                             
        END DO
       END IF
!C                                                                         
!C     KDINT > 0,1 - fetch saved DC MATRICES and update by 
!C      current THETA.  
!C                                                                          
!C       (A) Update D by Q                                                 
!C                                                                          
       N = I_0                                                           
       DO  M=1,MBAG_LCL                                                    
        IF ( NTST(M) .GE. I_0 )  THEN                                    
         N = N + I_1                                                   
         EDOTE = VAR_LCL(1,N)**2 + VAR_LCL(2,N)**2 + VAR_LCL(3,N)**2        
         IF ( EDOTE .GE. D_1 )  KDINT = -KDINT                            
         IF ( KDINT .LE. I_0 )   THEN                                   
          CALL ELTIME ( I_2, I_6 )                                              
          RETURN
         END IF
         E1(N) = SQRT ( D_1 - EDOTE )                                       
         CALL DSETQ ( SD(1,1,N), VAR_LCL(1,N), EDOTE, E1(N), 
     &                SEG(M)%DIR_COS )  
        END IF                                                              
       END DO
!C                                                                         
!C     KDINT > 0 - store state variables into program arrays.             
!C                                                                         
!C       (B) Linear displacment of reference segments                  
!C                                                                         
       DO  M=1,MBAG_LCL                                                     
        IF  ( .NOT. LSEG(M) )  THEN                                         
         N = N + I_1                                                      
         DO  I=1,3                                                          
          SEG(M)%LIN_DISP(I) = VAR_LCL(I,N)                            
         END DO
        END IF                                                              
       END DO
!C                                                                          
!C       (C) WMEG                                                           
!C                                                                          
       DO  M=1,MBAG_LCL                                                    
        IF ( NTST(M) .GE. I_0 )  THEN                                   
        N = N + I_1                                                       
         DO  I=1,3                                                         
          SEG(M)%ANG_VEL(I) = VAR_LCL(I,N)                                
         END DO
        END IF                                                              
       END DO
!C                                                                          
!C       (D) Linear velocity of reference segments                       
!C                                                                          
       DO  M=1,MBAG_LCL                                                    
        IF  ( .NOT. LSEG(M) )  THEN                                       
         N = N + I_1                                                     
         DO I=1,3
          SEG(M)%LIN_VEL(I) = VAR_LCL(I,N)                                    
         END DO
        END IF                                                             
       END DO
!C
!C     Transfer VAR into modal pos. & vel.                              
!C
       CALL FXMODV ( VAR_LCL, N )                                       
      END IF
!C                                                                         
!C    Call DAUX routine to compute derivatives                            
!C                                                                       
      CALL DAUX ( I_0 )                                                 
!C                                                                         
!C    Store derivatives for integrating subroutine.                        
!C                                                                         
!C      (A) Derivative of Q                                                
!C                                                                         
      N = I_0                                                          
      DO  M=1,MBAG_LCL                                                     
       IF  ( NTST(M) .GE. I_0 )   THEN                               
        N = N + I_1                                                     
        CALL CROSS ( VAR_LCL(1,N), SEG(M)%ANG_VEL, VXT )             
        DO  I=1,3                                                          
         DER_LCL(I,N) = D_HALF * ( E1(N) * SEG(M)%ANG_VEL(I) + VXT(I) )   
        END DO
       END IF                                                              
      END DO
      NQUAT = N                                                            
!C                                                                         
!C      (B) Linear velocity of reference segments                      
!C                                                                         
      DO  M=1,MBAG_LCL                                                     
       IF  ( .NOT. LSEG(M) )  THEN                                         
        N = N + I_1                                                     
        DO I=1,3
         DER_LCL(I,N) = SEG(M)%LIN_VEL(I)                                 
        END DO
       END IF                                                              
      END DO
!C                                                                         
!C      (C) WMEGD                                                          
!C                                                                         
      DO  M=1,MBAG_LCL                                                     
       IF ( NTST(M) .GE. I_0 )  THEN                                    
        N = N + I_1                                                    
        DO  I=1,3                                                          
         DER_LCL(I,N) = SEG(M)%ANG_ACCEL(I)                         
        END DO
       END IF                                                              
      END DO  
!C                                                                         
!C      (D) Linear acceleration of reference segments.                     
!C                                                                         
      DO  M=1,MBAG_LCL                                                    
       IF  ( .NOT. LSEG(M) )   THEN                                        
        N = N + I_1                                                     
        DO  I=1,3                                                          
         DER_LCL(I,N) = SEG(M)%LIN_ACCEL(I)                          
        END DO
       END IF                                                              
      END DO
!C
!C    Transfer modal accelerations to DER.                               
!C
      CALL FXMODD ( DER_LCL, N )                                        
      IF ( KDINT .NE. I_4 )  THEN                                     
       IF  ( KDINT .EQ. I_2 )   KDINT = NQUAT                          
       CALL ELTIME ( I_2, I_6 )                                        
       RETURN
      END IF
!C
      N = I_0                                                          
      DO  M=1,MBAG_LCL                                                    
       IF ( NTST(M) .GE. I_0 )  THEN                                     
        N = N + I_1                                                   
        E1(N) = D_1                                                     
        DO  I=1,3                                                          
         DER_LCL(I,N) = D_HALF * SEG(M)%ANG_VEL(I)                       
         VAR_LCL(I,N) = D_0                                              
        END DO
       END IF                                                              
      END DO
      IF  ( KDINT .EQ. I_2 )   KDINT = NQUAT                             
!C
      CALL ELTIME ( I_2, I_6 )                                       
!C
      RETURN                                                               
      END                                                                 
