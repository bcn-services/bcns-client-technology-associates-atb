      SUBROUTINE CHAIN ( ISKIP )                                          
C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the linear position and velocity in inertial reference     
!C    of body segments from those of the reference segments                
!C    (i.e., segment no. 1 and each segment J for which JNT(J)=0).         
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &                IEULER,                         ! /CEULER/
     &                NJNT, NPRT, NSEG, TIME,         ! /CONTRL/
     &                HT,                             ! /DESCRP/
     &                SEG, JNT,                       ! structures
     &                INTEGER_STD, IREAL_HIGH, LUAOU, ! parameter
     &                I_0, I_1, I_2, I_5, I_11        ! parameter
!C
!C    ANG_VEL, DIR_COS, LIN_DISP, LIN_VEL, SINGULAR        ! SEG%
!C    PROX_SEG, DSTL_LOC, PROX_LOC, DSTL_CNST, PROX_CNST,  ! JNT%
!C    JTYPE                                                ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:  ASAD              ! /FXNVEL/
!C
      IMPLICIT  NONE
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IFIRST, ISKIP, J, K
!C
      REAL  ( KIND = IREAL_HIGH )  T1, T2, T3, T4, T5, T6, T7
      DIMENSION   T1(3), T2(3), T3(3), T4(3), T5(3), T6(3), T7(3)           
!C
      DATA IFIRST / I_1 /                                        
!C
      INTENT ( IN )  ISKIP
!C
      CALL ELTIME ( I_1, I_11 )                                              
!C
      IF ( NJNT .NE. I_0 )  THEN                                       
       IF ( ISKIP .NE. I_0 )  CALL DRIFT                                
       DO 70 J=1,NJNT                                                     
        K = ABS ( JNT(J)%PROX_SEG )                                      
        IF ( K .EQ. I_0 )  CYCLE                                    
        IF ( SEG(J+1)%SINGULAR .LT. I_0 )  CYCLE                           
!C                                                                        
!C      Compute segment positions by                                      
!C       P(J+1) = P(K) + D(K)' * R(K,J) - D(J+1)'* R(J+1,J)                  
!C                                                                        
!C      Compute segment velocities by                                     
!C       V(J+1) = V(K) + D(K)' * W(K) X R(K,J) 
!C                 - D(J+1)' * W(J+1) X R(J+1,J)    
!C                                                                        
        CALL CROSS ( SEG(K)%ANG_VEL, JNT(J)%PROX_LOC, T1 )                  
        CALL DOT31 ( SEG(K)%DIR_COS, T1, T3 )                          
        CALL CROSS ( SEG(J+1)%ANG_VEL, JNT(J)%DSTL_LOC, T2 )                   
        CALL DOT31 ( SEG(J+1)%DIR_COS, T2, T4 )                           
        CALL DOT31 ( SEG(K)%DIR_COS, JNT(J)%PROX_LOC, T1 )                    
        CALL DOT31 ( SEG(J+1)%DIR_COS, JNT(J)%DSTL_LOC, T2 )                   
        IF ( ( ABS ( JNT(J)%JTYPE ) .GE. I_5 ) .AND.                           
     &       ( IEULER(J) .NE. -I_1 )  .AND.                             
     &       ( IFIRST .NE. I_1 ) )  THEN                                 
         T5 = SEG(J+1)%LIN_DISP + T2 - SEG(K)%LIN_DISP - T1       
         T6 = SEG(J+1)%LIN_VEL  + T4 - SEG(K)%LIN_VEL  - T3        
         CALL DOT31 ( SEG(K)%DIR_COS, HT(1,3,2*J-1), T7 )               
         JNT(J)%PROX_CNST = DOT_PRODUCT ( T5, T7 )
         JNT(J)%DSTL_CNST = DOT_PRODUCT ( T6, T7 )
         CALL CROSS ( SEG(K)%ANG_VEL, HT(1,3,2*J-1), T5 )         
         CALL DOT31 ( SEG(K)%DIR_COS, T5, T6 )                             
         T1 = T1 + JNT(J)%PROX_CNST * T7                      
         T3 = T3 + JNT(J)%DSTL_CNST * T7 + JNT(J)%PROX_CNST * T6      
        END IF
!C
        SEG(J+1)%LIN_DISP = SEG(K)%LIN_DISP + T1 - T2             
        DO  I=1,3                                                           
         SEG(J+1)%LIN_VEL(I) = SEG(K)%LIN_VEL(I) + T3(I) - T4(I)          
     &                         + ASAD(I,2*J-1) - ASAD(I,2*J)               
        END DO                                                          
   70  CONTINUE                                                            
       IFIRST = I_0                                                     
      END IF
!C                                                                         
!C    Optional output                                                      
!C                                                                         
      IF  (NPRT(20) .NE. I_0 )  THEN
       WRITE ( LUAOU, 100 )  TIME, 
     &                      ( ( SEG(J)%LIN_DISP(I), I=1,3 ), J=1,NSEG ),             
     &                      ( ( SEG(J)%LIN_VEL(I),  I=1,3 ), J=1,NSEG )      
  100  FORMAT ( '0 Linear positions and velocities of body segments ',
     &          'from CHAIN for time =', F12.6, /, ( 9F13.5 ) )            
      END IF
!C
      CALL ELTIME ( I_2, I_11 )                                                
!C
      RETURN                                                               
      END                                                                  
