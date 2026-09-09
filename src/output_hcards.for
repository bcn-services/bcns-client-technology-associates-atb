      SUBROUTINE  OUTPUT_HCARDS ( LTAPE8, LTHIST, NT, USEC_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:   
     &       NGRND, NVEH,                            ! /CONTRL/
     &       G, GRAVTY, PI, RADIAN,                  ! /CNSNTS/
     &       PRJNT,                                  ! /FORCES/
     &       KREF, MSG, NSG, XSG,                    ! /RSAVE/
     &       WF,                                     ! /WINDFR/
     &       TDATA,                                  ! /HEDING_TEMPVS/
     &       ACT, SEG,                               ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,   ! parameters
     &       NUM_TTH_OFFSET,                         ! parameters
     &       D_0, D_HALF, D_1, D_2,                  ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_7, ! parameters
     &       I_8, I_9, I_10                          ! parameters
!C 
!C    ACT_TORQ, PROP_TORQ, DERIV_TORQ, INTEGRAL_TORQ,   ! ACT%
!C     ACT_JNT_ANGLE, ACT_JNT_VEL                       ! ACT%
!C    ANG_ACCEL, ANG_VEL, DIR_COS, DRC_PHI, LIN_ACCEL,  ! SEG%
!C    LIN_DISP,  LIN_VEL, ROT_PHI                       ! SEG%
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &       FMODES, QNOD,                  ! /FXBODY/
     &       IDJNT, JROUT, NTDEF, ROTJ,     ! /FXJROT/
     &       NFBPR, NODPR, T91, T92,        ! /FXOUT/
     &       AMA, AMP, AMV, NMOD            ! /FXVAR/ 
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, I2, II, J, J1, J2, J3, JJ, JL, JM,   
     &         K, KJL, KK, KRF, KSG, L, L0, NT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                ACC,   
     &                REL_ANG, RESJ, T1, T2_LCL, T3, 
     &                T4, T5_LCL, T6, T7, T9, T13,
     &                TRACE, USEC_LCL
      DIMENSION       ACC(7,20), REL_ANG(3,3), RESJ(2),
     &                T1(3), T2_LCL(3), T3(3), T4(9), T5_LCL(3,3), 
     &                T6(3,3), T7(3), T9(3), T13(3)
!C
!C    Variables for compiler fix.
!C
      REAL  ( KIND = IREAL_HIGH )
     &               W_T
      DIMENSION    W_T(3,1)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTAPE8, LTHIST
!C
      INTENT  ( IN )     LTAPE8, LTHIST, USEC_LCL
      INTENT  ( INOUT )  NT
!C                                                                        
!C    Compute and print data for 9 types of output above.                  
!C                                                                       
      DO 20 K=1,10                                                        
       IF ( NSG(K) .LE. I_0 )   CYCLE                                 
       KSG = NSG(K)                                                       
       IF ( K .EQ. I_9 )  THEN            
        CALL OUTPUT_H9_CARDS ( LTAPE8, LTHIST, NT, USEC_LCL )
        CYCLE
       END IF
!C
       J3  = I_3                                                     
       IF ( ( K .EQ. I_7 ) .OR. ( K .EQ. I_10 ) )  J3 = I_2                  
       DO 30 J1=1,KSG,J3                                                  
        J2 = MIN ( ( J1 + J3 - I_1 ), KSG )                       
        NT = NT + I_1                                                  
        DO 40 J=J1,J2                                                     
         L = ABS ( MSG(J,K) )                                             
!C
!C       Compute small deformation adjustments                          
!C
         T13 = D_0                                                  
         T92 = D_0                                                  
         T91 = D_0                                                 
         IF ( K .LE. I_3 ) THEN                                     
          IF ( NFBPR(J,K) .GT. I_0 )  THEN                           
           II = NFBPR(J,K)
           L0 = I_6 * ( NODPR(J,K) - I_1 )                              
           DO  I=1,3                                                    
            XSG(I,J,K) = QNOD(I,NODPR(J,K),NFBPR(J,K))                      
            T9(I) = D_0                                         
            DO  JJ=1,NMOD(II)                                           
             XSG(I,J,K) = XSG(I,J,K) + FMODES(L0+I,JJ,II) * AMP(JJ,II)  
             T9(I) = T9(I) + FMODES(L0+I,JJ,II) * AMV(JJ,II)            
             T13(I) = T13(I) + FMODES(L0+I,JJ,II) * AMA(JJ,II)          
            END DO                                                      
           END DO
           CALL DOT31 ( SEG(L)%DIR_COS,  T9, T91 )                     
           CALL CROSS ( SEG(L)%ANG_VEL,  T9, T92 )               
          END IF                                                        
         END IF                                                         
!C
         H_CARD_TYPE:  SELECT CASE ( K )
!C                                                                        
!C       1. Point total acceleration in KREF(1) reference                 
!C                                                                        
          CASE ( I_1 )  H_CARD_TYPE
           IF ( SEG(L)%ROT_PHI )   THEN                       
            CALL MAT31 ( SEG(L)%DRC_PHI, XSG(1,J,K), T7 )           
           ELSE                                                           
            DO  JL=1,3                                                    
             T7(JL) = XSG(JL,J,K)                                         
            END DO
           END IF
           CALL CROSS ( SEG(L)%ANG_VEL, T7, T1     )              
           CALL CROSS ( SEG(L)%ANG_VEL, T1, T2_LCL )             
           CALL CROSS ( SEG(L)%ANG_ACCEL, T7, T3    )                  
           CALL MAT31 ( SEG(L)%DIR_COS, GRAVTY, T7 )                       
           CALL MAT31 ( SEG(L)%DIR_COS, SEG(L)%LIN_ACCEL, T4 )                 
           DO  I=1,3                                                     
            IF ( MSG(J,K) .LT. I_0 )   THEN
             T4(I) = T4(I) - T7(I)                              
            END IF
            ACC(I,J) = ( T4(I) + T3(I) + T2_LCL(I) ) / G                  
     &               + ( T13(I) + D_2 * T92(I) )     / G               
            T1(I) = ACC(I,J)                                             
           END DO
           IF ( MSG(J,K) .GE. I_0 )   THEN                              
            IF ( KREF(J,K) .EQ. I_0 )   THEN                          
             KRF = L                                                     
             IF ( SEG(KRF)%ROT_PHI )   THEN
              CALL DOT31 ( SEG(KRF)%DRC_PHI, T1, ACC(1,J) )        
             END IF
            ELSE
             KRF = KREF(J,K)                                             
             IF ( .NOT. SEG(KRF)%ROT_PHI )   THEN                         
              CALL DOTT33 ( SEG(KRF)%DIR_COS, SEG(L)%DIR_COS, T6 )        
              CALL MAT31 ( T6, T1, ACC(1,J) )                            
             ELSE
              CALL DOT33 ( SEG(KRF)%DRC_PHI, SEG(KRF)%DIR_COS, T5_LCL )      
              CALL DOTT33 ( T5_LCL, SEG(L)%DIR_COS, T6 )                  
              CALL MAT31 ( T6, T1, ACC(1,J) )                             
             END IF
            END IF
           ELSE
            KRF = L                                                       
            IF ( SEG(KRF)%ROT_PHI  )  THEN
             CALL DOT31 ( SEG(KRF)%DRC_PHI, T1, ACC(1,J) )             
            END IF
           END IF
           ACC(4,J) = SQRT ( ACC(1,J)**2 + ACC(2,J)**2 + ACC(3,J)**2 )   
!C                                                                        
!C       2. Point rel. velocity in KREF(2) reference                      
!C                                                                       
          CASE ( I_2 )  H_CARD_TYPE
           IF ( KREF(J,2) .EQ. I_0 )   THEN
            KRF = NVEH                                                   
           ELSE
            KRF = KREF(J,2)                                             
           END IF
           IF ( SEG(L)%ROT_PHI )  THEN                        
            CALL MAT31 ( SEG(L)%DRC_PHI, XSG(1,J,K), T7 )             
           ELSE
            DO  JL=1,3                                                   
             T7(JL) = XSG(JL,J,K)                                         
            END DO
           END IF
           CALL CROSS ( SEG(L)%ANG_VEL, T7, T1 )                    
           CALL DOT31 ( SEG(L)%DIR_COS, T1, T2_LCL )                    
           T3 = T2_LCL + SEG(L)%LIN_VEL - SEG(KRF)%LIN_VEL + T91     
           IF ( SEG(KRF)%ROT_PHI )  THEN                            
            CALL DOT33 ( SEG(KRF)%DRC_PHI, SEG(KRF)%DIR_COS, T5_LCL )       
            CALL MAT31 ( T5_LCL, T3, ACC(1,J) )                           
           ELSE                                                          
            CALL MAT31 ( SEG(KRF)%DIR_COS, T3, ACC(1,J) )                  
           END IF
           ACC(4,J) = SQRT ( ACC(1,J)**2 + ACC(2,J)**2 + ACC(3,J)**2 )    
C                                                                         
C        3. Point rel. linear displacement in KREF(3) reference           
C                                                                         
          CASE ( I_3 )   H_CARD_TYPE
           IF ( KREF(J,3) .EQ. I_0 )  THEN 
            KRF = NVEH                                                   
           ELSE
            KRF = KREF(J,3)                                             
           END IF
           IF  ( SEG(L)%ROT_PHI )  THEN                              
            CALL DOT33 ( SEG(L)%DRC_PHI, SEG(L)%DIR_COS, T4 )              
            CALL DOT31 ( T4, XSG(1,J,K), T1 )                             
           ELSE                                                          
            CALL DOT31 ( SEG(L)%DIR_COS, XSG(1,J,K), T1 )                
           END IF
           T3 = T1 + SEG(L)%LIN_DISP - SEG(KRF)%LIN_DISP   
           IF ( SEG(KRF)%ROT_PHI )  THEN                              
            CALL DOT33 ( SEG(KRF)%DRC_PHI, SEG(KRF)%DIR_COS, T5_LCL )        
            CALL MAT31 ( T5_LCL, T3, ACC(1,J) )                           
           ELSE                                                           
            CALL MAT31 ( SEG(KRF)%DIR_COS, T3, ACC(1,J) )               
           END IF
           ACC(4,J) = SQRT ( ACC(1,J)**2 + ACC(2,J)**2 + ACC(3,J)**2 )    
!C                                                                        
!C       4. Segment angular acceleration in KREF(4) reference             
!C                                                                        
          CASE ( I_4 )   H_CARD_TYPE
           DO  I=1,3                                                      
            ACC(I,J) = SEG(L)%ANG_ACCEL(I) / ( D_2 * PI )          
            T1(I) = ACC(I,J)                                              
           END DO
           IF ( KREF(J,K) .EQ. I_0 )   THEN                           
            KRF = L                                                      
            IF ( SEG(KRF)%ROT_PHI )   THEN
             CALL DOT31 ( SEG(KRF)%DRC_PHI, T1, ACC(1,J) )             
            END IF
           ELSE
            KRF = KREF(J,K)                                              
            IF ( .NOT. SEG(KRF)%ROT_PHI )   THEN                         
             CALL DOTT33 ( SEG(KRF)%DIR_COS, SEG(L)%DIR_COS, T6 )         
             CALL MAT31 ( T6, T1, ACC(1,J) )                              
            ELSE
             CALL DOT33 ( SEG(KRF)%DRC_PHI, SEG(KRF)%DIR_COS, T5_LCL )      
             CALL DOTT33 ( T5_LCL, SEG(L)%DIR_COS, T6 )                  
             CALL MAT31 ( T6, T1, ACC(1,J) )                              
            END IF
           END IF
           ACC(4,J) = SQRT ( ACC(1,J)**2 + ACC(2,J)**2 + ACC(3,J)**2 )    
!C                                                                        
!C       5. Segment rel. angular velocity in KREF(5) reference            
!C                                                                        
          CASE ( I_5 )   H_CARD_TYPE
           IF ( KREF(J,5) .EQ. I_0 )   THEN
            KRF = NVEH                                                   
           ELSE 
            KRF = KREF(J,5)                                              
           END IF
           CALL DOT31 ( SEG(L)%DIR_COS, SEG(L)%ANG_VEL, T1 )                 
           CALL MAT31 ( SEG(KRF)%DIR_COS, T1, T2_LCL  )                  
           IF  ( KRF .NE. L )  T2_LCL = T2_LCL - SEG(KRF)%ANG_VEL  
           T3 = T2_LCL / ( D_2 * PI )                          
           IF ( SEG(KRF)%ROT_PHI )  THEN                                
            CALL DOT31 ( SEG(KRF)%DRC_PHI, T3, ACC(1,J) )             
           ELSE
            DO  KJL=1,3                                                   
             ACC(KJL,J) = T3(KJL)                                         
            END DO
           END IF
           ACC(4,J) = SQRT ( ACC(1,J)**2 + ACC(2,J)**2 + ACC(3,J)**2 )    
!C                                                                        
!C       6. Segment rel. angular displacement in KREF(6) reference        
!C                                                                        
          CASE ( I_6 )   H_CARD_TYPE
           IF  ( KREF(J,6) .EQ. I_0 )   THEN
            KRF = NVEH                                                  
           ELSE
            KRF = KREF(J,6)                                             
           END IF
           IF      ( ( .NOT. SEG(KRF)%ROT_PHI ) .AND. 
     &               ( .NOT. SEG(L)%ROT_PHI ) )            THEN 
            CALL DOTT33 ( SEG(L)%DIR_COS, SEG(KRF)%DIR_COS, REL_ANG )                 
           ELSE IF ( SEG(KRF)%ROT_PHI .AND. 
     &               ( .NOT. SEG(L)%ROT_PHI ) )            THEN 
            CALL DOT33  ( SEG(KRF)%DRC_PHI, SEG(KRF)%DIR_COS, T5_LCL )        
            CALL DOTT33 ( SEG(L)%DIR_COS, T5_LCL, REL_ANG )                    
           ELSE IF ( ( .NOT. SEG(KRF)%ROT_PHI ) .AND. 
     &                 SEG(L)%ROT_PHI )            THEN 
            CALL DOT33  ( SEG(L)%DRC_PHI, SEG(L)%DIR_COS, T4 )               
            CALL DOTT33 ( T4, SEG(KRF)%DIR_COS, REL_ANG )                       
           ELSE IF ( SEG(KRF)%ROT_PHI .AND.  SEG(L)%ROT_PHI  )  THEN 
            CALL DOT33  ( SEG(KRF)%DRC_PHI, SEG(KRF)%DIR_COS, T5_LCL )        
            CALL DOT33  ( SEG(L)%DRC_PHI,   SEG(L)%DIR_COS,   T4 )               
            CALL DOTT33 ( T4, T5_LCL, REL_ANG )                       
           END IF
           CALL YPRDEG ( REL_ANG, ACC(1,J) )                            
           TRACE = D_HALF * ( REL_ANG(1,1) + REL_ANG(2,2) 
     &                                  + REL_ANG(3,3) - D_1 )          
           IF      ( TRACE .GT.  D_1 )  THEN
            TRACE =  D_1                                                  
           ELSE IF ( TRACE .LT. -D_1 )  THEN
            TRACE = -D_1                                                  
           END IF
           ACC(4,J) = ACOS ( TRACE ) / RADIAN                             
!C                                                                        
!C       7. Joint parameters                                              
!C                                                                        
          CASE ( I_7 )   H_CARD_TYPE
           ACC(1,J) = PRJNT(1,L)                                          
           ACC(2,J) = PRJNT(2,L) / RADIAN                                 
           ACC(3,J) = PRJNT(3,L) / RADIAN                                 
           ACC(4,J) = PRJNT(4,L) / RADIAN                                
           ACC(5,J) = SQRT ( PRJNT(5,L) )                                
           ACC(6,J) = SQRT ( PRJNT(6,L) )                                 
           ACC(7,J) = SQRT ( PRJNT(7,L) )                                
!C                                                                        
!C       8. Segment wind force in KREF(8) reference                       
!C                                                                       
          CASE ( I_8 )   H_CARD_TYPE
           IF ( KREF(J,8) .EQ. I_0 )   THEN
            KRF = NGRND                                                  
           ELSE
            KRF = KREF(J,8)                                             
           END IF
!C
!C         Fix to overcome a compiler problem.
!C
           W_T = WF(:,L:L)
           CALL MAT31 ( SEG(KRF)%DIR_COS, W_T, T2_LCL )
           IF ( SEG(KRF)%ROT_PHI )   THEN                            
            CALL DOT31 ( SEG(KRF)%DRC_PHI, T2_LCL, ACC(1,J) )         
           ELSE                                                          
            DO  KJL=1,3                                                   
             ACC(KJL,J) = T2_LCL(KJL)                                    
            END DO
           END IF
           ACC(4,J) = SQRT ( ACC(1,J)**2 + ACC(2,J)**2 + ACC(3,J)**2 )    
!C                                                                        
!C       11. Actuator joint torques                                       
!C                                                                        
          CASE ( I_10 )   H_CARD_TYPE
           ACC(1,J) = ACT(L)%ACT_TORQ            
           ACC(2,J) = ACT(L)%PROP_TORQ
           ACC(3,J) = ACT(L)%DERIV_TORQ            
           ACC(4,J) = ACT(L)%INTEGRAL_TORQ
           ACC(5,J) = ACT(L)%ACT_JNT_ANGLE            
           ACC(6,J) = ACT(L)%ACT_JNT_VEL
!C
         END SELECT   H_CARD_TYPE
!C
   40   CONTINUE
!C
        IF  ( LTAPE8 )  THEN                                              
         KK = I_0                                                      
         I2 = I_4                                                      
         IF       ( K .EQ.  I_7 )   THEN  
          I2 = 7                                                          
         ELSE IF  ( K .EQ. I_10 )   THEN
          I2 = 6                                                          
         END IF
         DO  J=J1,J2                                                    
          DO  I=1,I2                                                      
           KK = KK + I_1                                               
           TDATA(KK,NT-NUM_TTH_OFFSET) = ACC(I,J)                         
          END DO
         END DO
        END IF
        IF  ( LTHIST )   THEN                                             
         IF      ( K .LE.  I_6 )   THEN
          WRITE ( NT, 100 )  USEC_LCL, ( ( ACC(I,J), I=1,4 ), J=J1,J2 )   
  100     FORMAT ( F9.3, 3( 3X, 4F9.3 ) )                                 
         ELSE IF ( K .EQ.  I_7 )   THEN
          WRITE ( NT, 105 )  USEC_LCL, ( ( ACC(I,J), I=1,7 ), J=J1,J2 )   
  105     FORMAT ( F9.3, 2( F5.0, 3F9.3, 2X, 3F9.3 ) )                    
         ELSE IF ( K .EQ.  I_8 )   THEN 
          WRITE ( NT, 100 )  USEC_LCL, ( ( ACC(I,J), I=1,4 ), J=J1,J2 )   
         ELSE IF ( K .EQ. I_10 )   THEN 
          WRITE ( NT, 110 )  USEC_LCL, ( ( ACC(I,J), I=1,6 ), J=J1,J2 )   
  110     FORMAT ( F9.3, 2( 3X, 6F9.1 ) )                                 
         END IF
        END IF                                                            
!C
   30  CONTINUE
!C
!C     Output of angular deformation of deformable segments              
!C
       IF ( ( K .EQ. I_6 ) .AND. ( NTDEF .GT. I_0 ) ) THEN         
        J3 = 2
        DO  JM = 1,NTDEF                                                
         DO  J1 = 1,JROUT(JM),J3
          NT = NT + I_1                                                
          J2 = MIN ( ( J1 + J3 - I_1 ), JROUT(JM) )
          DO  J = J1,J2
           RESJ(J-J1+1) = D_0
           DO I = 1,3
            RESJ(J-J1+1) = RESJ(J-J1+1) + ( ROTJ(I,IDJNT(J,JM)) /
     &                                      RADIAN )**2
           END DO
           RESJ(J-J1+1) = SQRT ( RESJ(J-J1+1) )
          END DO
          WRITE ( NT, 115 ) USEC_LCL, 
     &                     ( ( ROTJ(I,IDJNT(J,JM)) / RADIAN, I=1,3 ),   
     &                        RESJ(J-J1+1), J=J1,J2 )         
  115     FORMAT ( F9.3, 2( 4X, 4F9.3, 2X ) )                            
         END DO
        END DO                                                           
       END IF                                                           
!C                                                                       
   20 CONTINUE                                                            
!C
      RETURN
      END
      
      