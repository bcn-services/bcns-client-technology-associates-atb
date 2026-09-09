      SUBROUTINE  OUTPUT_H9_CARDS ( LTAPE8, LTHIST, NT, USEC_LCL )
!C
!C                                                  Rev. V.3 12/15/2002 
!C                                                                    
!C    This subroutine outputs the joint forces & torques in 
!C     KREF(9) geometric coordinate system, as specified by the
!C     H.9 cards.  
!C                                                                       
!C    It is called only by Subroutine OUTPUT_HCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NRTORQ,                               ! /ACTFR/
     &       NJNT, NVEH,                           ! /CONTRL/
     &       KREF, MSG, NSG,                       ! /RSAVE/
     &       TDATA,                                ! /HEDING_TEMPVS/
     &       ACT, SEG, JNT,                        ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, ! parameters
     &       MAXJNT, NUM_TTH_OFFSET,               ! parameters
     &       I_0, I_1, I_9, D_1, D_100             ! parameters
!C
!C    ACT_JNT, BASE_SEG, TOR_AXIS, ACT_TORQ   ! ACT%
!C    DIR_COS, DRC_PHI, ROT_PHI               ! SEG%
!C    JFORCE, JTORQUE, PROX_SEG               ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, J, JJ, JL, K, KRF, KSG, L, LL, NRS1, NT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                 T1, T2_LCL, T3, T5_LCL, 
     &                 TQQ, TT, USEC_LCL
      DIMENSION        T1(3), T2_LCL(3), T3(3), T5_LCL(3,3), 
     &                 TQQ(3,MAXJNT)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTAPE8, LTHIST
!C
      REAL  ( KIND = IREAL_HIGH )  TORQ_SCALE
      PARAMETER  ( TORQ_SCALE = D_100 )
!C
      INTENT  ( IN )     LTAPE8, LTHIST, USEC_LCL
      INTENT  ( INOUT )  NT
!C
      K = I_9
      KSG = NSG(K)                                                    
!C
!C    Get the joint torque.
!C
      DO  J=1,NJNT                                                       
       DO  I=1,3                                                       
        TQQ(I,J) = JNT(J)%JTORQUE(I)                                               
       END DO
      END DO
!C
!C    Get the torque from the actuator joint functions, if any.
!C
      IF ( NRTORQ .GT. I_0 )  THEN                                         
       DO  J=1,NRTORQ                                                    
        JJ = ACT(J)%ACT_JNT                                                   
        NRS1 = JNT(JJ)%PROX_SEG                                                  
        CALL DOT31 ( SEG(NRS1)%DIR_COS, ACT(J)%TOR_AXIS(1), T3 )                        
        TT = D_1                                                        
       IF ( NRS1 .NE. ACT(J)%BASE_SEG )  TT = -D_1                               
        DO  I=1,3                                                       
         TQQ(I,JJ) = TQQ(I,JJ) + TT * ACT(J)%ACT_TORQ * T3(I)              
        END DO
       END DO                                                            
      END IF
!C
      DO  L=1,KSG                                                  
       KRF = NVEH                                                       
       IF ( KREF(L,K) .NE. I_0 )  KRF = KREF(L,K)                         
       LL = MSG(L,K)                                                     
       IF  ( SEG(KRF)%ROT_PHI )  THEN                                   
        CALL DOT33 ( SEG(KRF)%DRC_PHI, SEG(KRF)%DIR_COS, T5_LCL )                
        CALL MAT31 ( T5_LCL, JNT(LL)%JFORCE, T1 )                             
        CALL MAT31 ( T5_LCL, TQQ(1,LL), T2_LCL )                        
        DO  JJ=1,3                                                    
         T1(JJ)     =  T1(JJ)     / TORQ_SCALE                           
         T2_LCL(JJ) = -T2_LCL(JJ) / TORQ_SCALE                           
        END DO
       ELSE                                                            

        CALL MAT31 ( SEG(KRF)%DIR_COS, JNT(LL)%JFORCE,   T1 )                       
        CALL MAT31 ( SEG(KRF)%DIR_COS, TQQ(1,LL), T2_LCL )                     
        DO  JJ=1,3                                                     
         T1(JJ)     =  T1(JJ)     / TORQ_SCALE                          
         T2_LCL(JJ) = -T2_LCL(JJ) / TORQ_SCALE                           
        END DO
       END IF
       NT = NT + I_1                                                       
       IF ( LTAPE8 )   THEN                                              
        DO  JL=1,3                                                     
         TDATA (JL  ,NT-NUM_TTH_OFFSET) = T1(JL)                         
         TDATA (JL+3,NT-NUM_TTH_OFFSET) = T2_LCL(JL)                    
        END DO
       END IF
       IF ( LTHIST )   THEN
        WRITE ( NT, 100 )    USEC_LCL, T1, T2_LCL                      
  100   FORMAT ( F9.3, 3X, 3F9.3, 3X, 3( 2X, G10.3 ) )                 
       END IF
      END DO                                                          
!C
      RETURN
      END
      