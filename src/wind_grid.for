      SUBROUTINE WIND_GRID  ( FT, LOGI_RETURN, M, MM, N, NN_LCL,
     &                        TQM, TTF )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                         
!C    This subroutne uses the grid method to calculate 
!C     the wind force.                                  
!C
!C    It is called only by Subroutine WINDY.
!C
!C           VP - origin of wind                                          
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       EPS,                                    ! /CNSNTS/
     &       BD, PL,                                 ! /CNTSRF/
     &       NPRT, TIME,                             ! /CONTRL/
     &       MOWSEG, MWSEG, MOWELP,                  ! /WINDFR/
     &       SEG,                                    ! structures
     &       INTEGER_STD, IREAL_HIGH,                ! parameters
     &       LOGICAL_STD, LUAOU, TRUE, FALSE,        ! parameters 
     &       D_0, D_1, D_2, D_4, I_0, I_1, I_2, I_10 ! parameters
!C
!C    DIR_COS, LIN_DISP     ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &            I, II, IM, IN, J, K, M, MI, MM, MOELP,
     &            N, NN_LCL, NSTEPS_LCL
!C
      REAL  ( KIND = IREAL_HIGH )
     &            AI, AM, AMDA1, AMDA2, AREA_LCL, AREAT, AS, 
     &            B1, B2, BET_LCL, BTS, 
     &            DD, DDD, DVP, FF_LCL, FFT, FT, FTAREA, FT_SCALE, 
     &            PARM_STEP, R, R2, RM, RXC, RYC,  
     &            SI, SM, SN1, SNZ, SS, TEMP, TM, TQM, TTF,
     &            VP, X, XMM, XMN, XNORM, Y_LCL
      DIMENSION   AI(3,3,15), AM(3,3), AS(3), 
     &            DD(3,3), DDD(3,3), DVP(3,3),
     &            FF_LCL(3), FFT(3), FT(3), FTAREA(3), 
     &            R(3,3), R2(2,3), RM(3),  
     &            SI(3,15), SM(3), SN1(3), SS(3), 
     &            TM(3), TQM(3), TTF(3), 
     &            VP(3), XMM(3), XMN(3)
!C
      REAL  ( KIND = IREAL_HIGH ) VECMAG
      EXTERNAL                    VECMAG
!C                                                                       
      LOGICAL  ( KIND = LOGICAL_STD )  LOGI_RETURN
!C
      PARAMETER  ( FT_SCALE = 10000.0_IREAL_HIGH )
      PARAMETER  ( PARM_STEP = 0.999_IREAL_HIGH )
!C
      DATA  NSTEPS_LCL / I_10 /                                   
!C
      INTENT  (  IN )  FT, M, MM, N, NN_LCL
      INTENT  ( OUT )  LOGI_RETURN, TQM, TTF
!C
      LOGI_RETURN = FALSE
      AREAT = D_0                                                       
      TTF = D_0                                                         
      TQM = D_0                                                         
      VP = -FT * FT_SCALE                                                 
      IF ( VECMAG ( FT ) .EQ. D_0 )  THEN                           
       LOGI_RETURN = TRUE
       RETURN
      END IF
      CALL MAT31 ( SEG(M)%DIR_COS, FT, FF_LCL )                      
      TEMP = D_0                                                       
      IF ( ( FT(1) .NE. D_0 ) .OR. ( FT(2) .NE. D_0 ) )  THEN          
!C                                                                        
!C     Calculate direction cosine matrix for VP coord. sys.               
!C                                                                        
       TEMP = VECMAG ( FT )                                             
       XNORM = SQRT (   FT(1) * FT(1) / TEMP**2 
     &                 + FT(2) * FT(2) / TEMP**2 )                        
       DVP(1,1) =  FT(2) / ( XNORM * TEMP )                               
       DVP(1,2) = -FT(1) / ( XNORM * TEMP )                               
       DVP(1,3) =  D_0                                                 
       DVP(2,1) = FT(1) * FT(3) / ( XNORM * TEMP * TEMP )                 
       DVP(2,2) = FT(2) * FT(3) / ( XNORM * TEMP * TEMP )                 
       DVP(2,3) = -XNORM                                                  
       DO  I=1,3                                                        
        DVP(3,I) = FT(I) / TEMP                                          
       END DO
      ELSE                                                                
       DVP = D_0                                                       
       DVP(1,2) =  D_1                                                   
       DVP(2,1) =  D_1                                                   
       DVP(3,3) = -D_1                                                   
      END IF
!C                                                                        
!C    Project MM ellipsoid onto VP-plane                                  
!C         as - projected ellipse matrix                                  
!C                                                                        
      CALL DOTT33 ( SEG(M)%DIR_COS, DVP, DD )                            
      CALL MAT33 ( BD(7,MM), DD, DDD )                                    
      CALL DOT33 ( SEG(M)%DIR_COS, DDD, DD )                           
      CALL MAT33 ( DVP, DD, AM )                                          
      CALL DOT31(SEG(M)%DIR_COS, BD(4,MM), TM) 
      DO  K=1,3                                                           
       SS(K) = SEG(M)%LIN_DISP(K) + TM(K) - VP(K)            
      END DO
      CALL MAT31 ( DVP, SS, SM )                                          
      DO  K=1,3                                                           
       IF ( ABS ( SM(K) ) .LT. EPS(5) )  THEN
        SM(K) = SIGN ( EPS(5), SM(K) )                                    
       END IF
      END DO                                                              
      CALL SOLVR ( AM(1,1), AM(2,1), AM(3,1), AM(1,3), AM(2,3), 
     &             AM(3,3), AM(1,1), AM(1,3), SM, R(1,1), R(3,1) )        
      CALL SOLVR ( AM(1,2), AM(2,2), AM(3,2), AM(1,3), AM(2,3),
     &             AM(3,3), AM(2,2), AM(2,3), SM, R(2,2), R(3,2) )        
      CALL SOLVR ( ( AM(1,1) + AM(1,2) ), ( AM(2,1) + AM(2,2) ), 
     &             ( AM(3,1) + AM(3,2) ),                                 
     &               AM(1,3), AM(2,3), AM(3,3), 
     &            ( AM(1,1) + D_2 * AM(1,2) + AM(2,2) ),                 
     &            ( AM(1,3) + AM(2,3) ), SM, R(1,3), R(3,3) )            
      R(2,1) = D_0                                                        
      R(1,2) = D_0                                                      
      R(2,3) = R(1,3)                                                    
      DO  K=1,3                                                           
       DO  J=1,2                                                          
        R2(J,K)=R(J,K)                                                    
       END DO
      END DO
      CALL SOLVA ( R2, AS(1), AS(2), AS(3) )                              
!C                                                                        
!C    Get major & minor axes of projected ellipse                         
!C                                                                        
      TEMP = ( AS(1) + AS(2) )**2 - 
     &          D_4 * ( AS(1) * AS(2) - AS(3)**2 )   
      IF ( TEMP .LT. D_0 )  TEMP = D_0                                  
      TEMP = SQRT ( TEMP )                                                
      AMDA1 = ( AS(1) + AS(2) + TEMP ) / D_2                             
      AMDA2 = ( AS(1) + AS(2) - TEMP ) / D_2                             
      R2(1,1) = AS(3)                                                    
      R2(2,1) = AMDA1 - AS(1)                                            
      R2(1,2) = AMDA2 - AS(2)                                             
      R2(2,2) = AS(3)                                                    
      AMDA1 = ABS ( AMDA1 )                                               
      AMDA2 = ABS ( AMDA2 )                                               
      B1 = SQRT ( D_1 / ( AMDA1 * ( R2(1,1)**2 + R2(1,2)**2) ) )         
      B2 = SQRT ( D_1 / ( AMDA2 * ( R2(2,1)**2 + R2(2,2)**2) ) )         
      R2(1,1) = R2(1,1) * B1                                             
      R2(1,2) = R2(1,2) * B2                                              
      R2(2,1) = R2(2,1) * B1                                              
      R2(2,2) = R2(2,2) * B2                                              
!C                                                                        
!C    Get blocking ellipsoids in VP coord. sys.                           
!C                                                                        
      MOELP = MWSEG(7,M)                                                 
      DO  MI=1,MOELP                                                      
       I  = MOWSEG(MI,M)                                             
       II = MOWELP(MI,M)                                              
       CALL DOTT33 ( SEG(I)%DIR_COS, DVP, DD )                            
       CALL MAT33 ( BD(7,II), DD, DDD )                                  
       CALL DOT33 ( SEG(I)%DIR_COS, DDD, DD )                           
       CALL MAT33 ( DVP, DD, AI(1,1,MI) )                                 
       CALL DOT31 (SEG(I)%DIR_COS, BD(4,II), TM) 
       DO  K=1,3                                                          
        SS(K) = SEG(I)%LIN_DISP(K) + TM(K) - VP(K)           
       END DO
       CALL MAT31 ( DVP, SS, SI(1,MI) )                                   
       DO  K=1,3                                                          
        IF ( ABS ( SI(K,MI) ) .LT. EPS(6) )  THEN
         SI(K,MI) = SIGN ( EPS(6), SI(K,MI) )                             
        END IF
       END DO                                                            
      END DO                                                             
!C                                                                       
!C    Set-up grid and check each rectangle center point                   
!C                                                                        
      AREA_LCL = SQRT (  ( R2(1,1)**2 + R2(2,1)**2 )
     &                   *( R2(1,2)**2 + R2(2,2)**2) )                   
      AREA_LCL = AREA_LCL / NSTEPS_LCL**2                               
      IN = I_2 * NSTEPS_LCL + I_1                                     
      DO  I=1,IN                                                
       RXC = R2(1,1) - R2(1,1) * ( I - I_1 ) / NSTEPS_LCL             
       RYC = R2(2,1) - R2(2,1) * ( I - I_1 ) / NSTEPS_LCL               
!C
       LOOP_2 : DO  J=1,IN                                                
        RM(1) = ( RXC - R2(1,2) * ( NSTEPS_LCL - J + I_1 ) 
     &                   / NSTEPS_LCL ) * PARM_STEP                      
        RM(2) = ( RYC - R2(2,2) * ( NSTEPS_LCL - J + I_1 )
     &                   / NSTEPS_LCL ) * PARM_STEP                    
        TM(1) = AM(3,3)                                                   
        TM(2) = D_2 * ( RM(1) * AM(1,3) + RM(2) * AM(2,3) )              
        TM(3) =   RM(1)**2 * AM(1,1) + RM(2)**2 * AM(2,2) 
     &          + D_2 * RM(1) * RM(2) * AM(1,2) - D_1                     
        TEMP = TM(2)**2 - D_4 * TM(1) * TM(3)                   
        IF  ( TEMP .LT. D_0 ) CYCLE LOOP_2                                     
        B1 =  ( SQRT ( TEMP ) - TM(2) ) / ( D_2 * TM(1) )                 
        B2 = -( SQRT ( TEMP ) + TM(2) ) / ( D_2 * TM(1) )                 
        RM(3) = B1                                                        
        IF ( B2 .LT. B1 )  RM(3) = B2                                     
        SN1 = RM + SM                                          
        CALL DOT31 ( DVP, SN1, XMM )                                      
!C                                                                        
!C      Check for penetration                                             
!C                                                                        
        XMN = VP - SEG(N)%LIN_DISP + XMM                       
        CALL MAT31 ( SEG(N)%DIR_COS, XMN, XMM )                         
        BET_LCL = PL(4,NN_LCL)                                            
        BTS =   PL(1,NN_LCL) * XMM(1) + PL(2,NN_LCL) * XMM(2)
     &        + PL(3,NN_LCL) * XMM(3)                                     
        IF ( BTS .GT. BET_LCL )  CYCLE LOOP_2                           
!C                                                                        
!C      Check for blocking ellipsoids                                     
!C                                                                        
        DO  IM=1,MOELP                                                    
         X     = SN1(1) - SI(1,IM)                                        
         Y_LCL = SN1(2) - SI(2,IM)                                        
         TM(1) = AI(3,3,IM)                                               
         TM(2) = D_2 * ( AI(1,3,IM) * X    + AI(2,3,IM) * Y_LCL )         
         TM(3) =         AI(1,1,IM) * X**2 + AI(2,2,IM) * Y_LCL**2
     &           + D_2 * AI(1,2,IM) * X * Y_LCL - D_1                   
         TEMP = TM(2)**2 - D_4 * TM(1) * TM(3)                           
         IF  ( TEMP .LT. D_0 )  CYCLE                                 
         B1 = ( -TM(2) + SQRT ( TEMP ) ) / ( D_2 * TM(1) )                
         B2 = ( -TM(2) - SQRT ( TEMP ) ) / ( D_2 * TM(1) )               
         IF  ( B2 .LT. B1 )  B1 = B2                                      
         SNZ = B1 + SI(3,IM)                                             
         IF  ( SNZ .LT. SN1(3) )  CYCLE LOOP_2                         
        END DO                                                            
!C
        CALL DOT31 ( DVP, RM, SS )                                        
        CALL MAT31 ( SEG(M)%DIR_COS, SS, RM )                          
!C                                                                        
!C      Sum forces & torques                                              
!C                                                                        
        AREAT = AREAT + AREA_LCL                                          
        DO  K=1,3                                                         
         FTAREA(K) = FT(K) * AREA_LCL                                   
         TTF(K)    = FT(K) * AREA_LCL + TTF(K)                           
         RM(K)     = RM(K) + BD(K+3,MM)                                 
         FFT(K)    = FF_LCL(K) * AREA_LCL                               
        END DO
        CALL CROSS ( RM, FFT, TM )                                        
        TQM = TQM + TM                                                   
!C
!C      Add to the nodal forces for deformable body M                   
!C
        CALL FXCAHW ( M, RM, FTAREA, +D_1 )                             
       END DO  LOOP_2
!C
      END DO                                                        
!C
       IF ( NPRT(14) .NE. I_0 ) THEN
        WRITE ( LUAOU, 100 )  TIME, M, AREAT, TTF, TQM                    
  100   FORMAT ( ' WIND FORCE', F14.6, I6, 13X, F10.3, 3F12.5, 3X,
     &           3F12.5 )                                                
       END IF
!C
      RETURN
      END
  
