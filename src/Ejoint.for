      SUBROUTINE EJOINT ( IJ_LCL, NK )                                    
!C                                                  Rev V.2  03/15/2002  
!C    Computes the torques acting on an Euler joint                       
!C    and adds them to the U2 array.                                      
!C                                                                        
!C    Arguments:                                                          
!C       NK = 0 - regular computation for all Euler joints                
!C          # 0 - compute only for joint NJ impulse                       
!C                                                                        
!C       IJ_LCL = 1 impulse on precession axis only                           
!C              = 2 impulse on nutation axis only                             
!C              = 3 impulse on spin axis only                                 
!C              = 4 impulse on globalgraphic axis                             
!C       NK = 0, IJ # 0, special computations of HIR and HB only          
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &               ANG, ANGD, IEULER, HIR, FE, TQE,        ! /CEULER/
     &               V2, WJ,                                 ! /CMATRX/
     &               EPS,                                    ! /CNSNTS/
     &               NJNT,                                   ! /CONTRL/
     &               HT, IGLOB,                              ! /DESCRP/
     &               VISC,                                   ! /DESCRP/
     &               CREST,                                  ! /TEMPVI/
     &               SEG, JNT,                               ! structures
     &               INTEGER_STD, IREAL_HIGH, LOGICAL_STD,   ! parameters
     &               MAXJNT, FALSE, TRUE, D_0,               ! parameters
     &               I_0, I_1, I_2, I_3, I_4, I_6, I_7, I_8  ! parameters 
!C
!C    ANG_VEL, DIR_COS,                     ! SEG%
!C    CNTR_SYM, JTORQUE, PROX_SEG, JTYPE,   ! JNT%
!C    PROX_HB, DSTL_HB                      ! JNT%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &             I, IC, IJ_LCL, J, J1, J2, K, K3J, M, N, N4, NJ, NK, 
     &             ISKIP, JPASS
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  SWJ, TQC, HX, AHDT, 
     &                  DH1, DH4, TH, HIM, HIJ, HDT, H2, SH, TM, TJ,
     &                  WMJ, AD, CV, CS, ANGL, HD3, T9
      DIMENSION  DH1(3,3), DH4(3,3), TH(3,3), HIM(3,3), HIJ(3,3),         
     &           HDT(3,3), H2(3,3), SH(3), TM(3), TJ(3), WMJ(3), AD(3),   
     &           CV(3), CS(3), ANGL(3), HD3(3), T9(3)            
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LSKIP, SKIP_HX                                      
      DIMENSION  LSKIP(3)
!C
      IF ( NJNT .LE. I_0 )  RETURN                                     
!C
      CALL ELTIME ( I_1, 31_INTEGER_STD )                                               
!C
      J1 = I_1                                                          
      J2 = NJNT                                                           
      NJ = NK                                                             
      IF ( NJ .NE. I_0 )  THEN                                         
       J1 = NJ                                                            
       J2 = NJ                                                            
       IF ( IJ_LCL .LT. I_0 )   NJ = I_0                            
      END IF
!C
      DO 20 J=J1,J2                                                       
       JPASS = J
       IF ( ABS ( JNT(J)%JTYPE ) .NE. I_4 )   CYCLE                         
       M = ABS ( JNT(J)%PROX_SEG )                                        
       CALL DOT33 ( SEG(M)%DIR_COS, HT(1,1,2*J-1), DH1 )                   
       CALL DOT33 ( SEG(J+1)%DIR_COS, HT(1,1,2*J), DH4 )                
       CALL DOT33 ( DH4, DH1, TH )                                         
       DO  I=1,3                                                           
        ANG(I,J) = ANG(I,J) + JNT(J)%CNTR_SYM(I)
       END DO
       IC = IEULER(J)                                                      
       CALL EULRAD ( TH, ANG(1,J), IC )                                    
       CALL ROT ( H2, I_3, -ANG(1,J) )                                
!C
       DO  I=1,3                                                           
        ANG(I,J) = ANG(I,J) - JNT(J)%CNTR_SYM(I)              
        HIR(I,1,J) = DH1(I,3)                                              
        HIR(I,3,J) = DH4(I,3)                                              
        HIM(I,1) = HT(I,3,2*J-1)                                           
        HIJ(I,3) = HT(I,3,2*J)                                             
        LSKIP(I) = FALSE                                              
        FE(I,J) = D_0                                                  
        CV(I)   = D_0                                                 
        CS(I)   = D_0                                                   
        V2(I,J) = D_0                                                     
        TQE(I,J) = D_0                                                   
       END DO
!C
       JNT(J)%JTORQUE = D_0
       WJ(J)          = D_0                                                    
       TQC            = D_0                                                        
!C
       IF  ( IJ_LCL .EQ. I_4 )  THEN                               
        IF ( IGLOB(J) .NE. I_0 )  THEN                                   
         HD3(1) = TH(3,1)                                                   
         HD3(2) = TH(3,2)                                                   
         HD3(3) = TH(3,3)                                                   
         CALL GLOBAL ( J, HD3, DH1, TQC, T9, ANGL )                         
        END IF
        ISKIP = I_1
        CALL EJOINT_TORQUE ( ISKIP, LSKIP, JPASS, NJ, IJ_LCL, M, TH )
        CYCLE
       END IF
!C
       CALL MAT31 ( HT(1,1,2*J-1), H2(1,1), HIM(1,2) )                     
       CALL MAT31 ( HT(1,1,2*J-1), H2(1,2), HIM(1,3) )                     
       CALL DOT31 ( SEG(M)%DIR_COS, HIM(1,2), H2(1,2) )                 
       CALL DOT31 ( SEG(M)%DIR_COS, HIM(1,3), H2(1,3) )                   
       CALL CROSS ( H2(1,2), HIR(1,3,J), H2(1,1) )                         
       CALL DOT31 ( SEG(M  )%DIR_COS, SEG(M  )%ANG_VEL, TM )                 
       CALL DOT31 ( SEG(J+1)%DIR_COS, SEG(J+1)%ANG_VEL, TJ )                   
       SWJ = D_0                                                        
!C
       DO  I=1,3                                                           
        HIR(I,2,J) = H2(I,2)                                               
        WMJ(I) = TJ(I) - TM(I)                                             
        SWJ = SWJ + WMJ(I)**2                                              
       END DO
!C
       WJ(J) = SQRT ( SWJ )                                                
       CALL DOT31 ( HIR(1,1,J), WMJ, AD )                                  
       CALL CROSS ( TM, HIR(1,1,J), HDT(1,1) )                             
       CALL CROSS ( TM, HIR(1,2,J), HDT(1,2) )                             
       CALL CROSS ( TJ, HIR(1,3,J), HDT(1,3) )                             
       CALL MAT31 ( SEG(J+1)%DIR_COS, HIR(1,1,J), HIJ(1,1) )         
       CALL MAT31 ( SEG(J+1)%DIR_COS, HIR(1,2,J), HIJ(1,2) )        
       CALL MAT31 ( SEG(M  )%DIR_COS, HIR(1,3,J), HIM(1,3) )        
       N = IEULER(J)                                                       
!C
       DO  I=1,3                                                           
        SH(I) = AD(I)                                                      
        DO  K=1,3                                                          
         HIR(I,K,2*J+MAXJNT-1) = HIM(I,K)                                  
         HIR(I,K,2*J+MAXJNT)   = HIJ(I,K)                                  
        END DO
       END DO
!C
       SKIP_HX = FALSE
       IF ( N .NE. I_8 )  THEN                                   
        IF ( N .GT. I_3 )  THEN                                      
         DO  I=1,3                                                         
          IF ( I .NE. ( N - I_3 ) )   SH(I) = D_0                            
         END DO
        ELSE
         SH(N) = D_0                                                    
        END IF
        IF ( N .NE. I_2 )  THEN                                  
         SKIP_HX = TRUE
        END IF
       END IF
!C
       IF ( .NOT. SKIP_HX  )  THEN
        HX = H2(1,1) * HIR(1,1,J) + H2(2,1) * HIR(2,1,J) 
     &                            + H2(3,1) * HIR(3,1,J)                    
        IF ( ABS ( HX ) .GE. EPS(6) )  THEN                                 
         CALL DOT31 ( H2, WMJ, SH )                                         
         SH(1) = SH(1) / HX                                                 
         IF  ( N .EQ. I_2 )   SH(2) = D_0                                   
         SH(3) = SH(3) / HX                                                 
        ELSE
         SH(1) = ANGD(1,J)                                                  
         SH(3) = ANGD(3,J)                                                  
        END IF
       END IF
!C
       DO  I=1,3                                                           
        ANGD(I,J) = SH(I)                                                  
        HDT(I,2) = HDT(I,2) + SH(1) * H2(I,3)                              
       END DO
!C
       IF  ( NJ .NE. I_0 )   N = IJ_LCL + I_3                          
!C
       IF  ( N .LE. I_3 )  THEN                                       
        N4 = I_4 - N                                                  
        IF ( N .EQ. I_2 )  AHDT = HDT(1,2) * WMJ(1) + HDT(2,2) * WMJ(2)
     &                                              + HDT(3,2) * WMJ(3)      
        IF ( N .NE. I_2 )  THEN  
         AHDT = -( SH(2) * HDT(1,2) + SH(N4) * HDT(1,N4) ) * H2(1,N)       
     &          -( SH(2) * HDT(2,2) + SH(N4) * HDT(2,N4) ) * H2(2,N)       
     &          -( SH(2) * HDT(3,2) + SH(N4) * HDT(3,N4) ) * H2(3,N)       
        END IF
        CALL MAT31 ( SEG(M  )%DIR_COS, H2(1,N), JNT(J)%PROX_HB )              
        CALL MAT31 ( SEG(J+1)%DIR_COS, H2(1,N), JNT(J)%DSTL_HB )            
         DO  I=1,3                                                          
         V2(I,J) = AHDT * H2(I,N)                                          
         IF ( N .EQ. I )  LSKIP(I) = TRUE                              
        END DO
!C
        ISKIP = I_0
        CALL EJOINT_TORQUE ( ISKIP, LSKIP, JPASS, NJ, IJ_LCL, M, TH )                                              
        CYCLE
       END IF
!C
       IF ( N .LE. I_6 )  THEN                                          
        K3J = I_3 * J - I_2                                       
        DO  I=1,3                                                          
         IF ( NJ .EQ. I_0 )   THEN                                    
          V2(I,J) = -HDT(I,N-3) * AD(N-3)                                  
          JNT(J)%PROX_HB(I) = HIM(I,N-3)                                   
          JNT(J)%DSTL_HB(I) = HIJ(I,N-3)                                    
          IF ( I .NE. ( N - I_3 ) )    LSKIP(I) = TRUE                 
         ELSE
          IF  ( I .EQ. ( N - I_3 ) )  CREST = VISC(7,K3J)            
          TQE(I,J) = H2(I,N-3)                                             
         END IF
         K3J = K3J + I_1                                                 
        END DO
!C
        IF ( NJ .EQ. I_0 )  THEN
         ISKIP = I_0
        ELSE
         ISKIP = I_1
        END IF
        CALL EJOINT_TORQUE ( ISKIP, LSKIP, JPASS, NJ, IJ_LCL, M, TH )
        CYCLE
       END IF
!C
       IF  ( N .EQ. I_7 )  THEN
        ISKIP = -I_1
       ELSE
        ISKIP = I_0
       END IF
       CALL EJOINT_TORQUE ( ISKIP, LSKIP, JPASS, NJ, IJ_LCL, M, TH )
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, 31_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
