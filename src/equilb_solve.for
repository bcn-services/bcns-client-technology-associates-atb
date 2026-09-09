      SUBROUTINE  EQUILB_SOLVE  ( NVAR, NCON, NTV, NI1, NSGE,
     &                            GX, XDEV, JPL, NAV, KSGE, 
     &                            IPL, ISG, LTYPE, INDGX,
     &                            M1, M2, M3, MT, JX, DXP, X, DPN, 
     &                            IYPR, NQORG, JITTER, PENDOT, 
     &                            EQUILB_CONVERGE, SX, YPR )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                        
!C    Adjusts initial input position parameters supplied on Cards G.2     
!C    and G.3 such that initial normal contact forces are equal to        
!C    either supplied values or those computed by constraint forces.     
!C                                                                        
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                           ! /CNSNTS/
     &       PL,                                            ! /CNTSRF/
     &       NQ, NPRT, NVEH,                                ! /CONTRL/
     &       KQTYPE, KQ1, KQ2, QQ, RK1, RK2,                ! /CSTRNT/
     &       HT,                                            ! /DESCRP/
     &       NPSF, PSF,                                     ! /FORCES/
     &       MPL, NTPL,                                     ! /JBARTZ/
     &       TAB, NTAB,                                     ! /TABLES/
     &       SEG,                                           ! structures
     &       INTEGER_STD, IREAL_HIGH,                       ! parameters
     &       LUAOU, MAXSEG, LOGICAL_STD,                    ! parameters
     &       I_0, I_1, I_2, I_3, I_10, I_50,                ! parameters
     &       D_0, D_HALF, D_1, D_2, TRUE                    ! parameters
!C
!C    DIR_COS, LIN_DISP        ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, I1, I2, IAV, ITER, J, J2, JPASS,
     &           JITTER, K, L, LT, M, MQ, MVAR, N, N1, N2, N3, 
     &           NCON, NITER, NP, NQORG, NT, NVAR, MAXEQ_ITER 
      PARAMETER  ( MAXEQ_ITER = I_50 )
      INTEGER  ( KIND = INTEGER_STD )
     &           IYPR, JPL, JX, M1, M2, M3, MT, NTV, NI1, NSGE, NAV,
     &           KSGE, ISG, IPL, LTYPE, INDGX, NTNQ
      DIMENSION  IYPR(4, MAXSEG), JPL(10), JX(10), M1(10),
     &           M2(10), M3(10), MT(10),
     &           NTV(10), NI1(10), NSGE(10), NAV(10), KSGE(5,10),          
     &           ISG(5), IPL(5), LTYPE(5), INDGX(5), NTNQ(5)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  CONV, ELOSS, F1_LCL, F2, FXJ, PEN, PEN1, 
     &                  PENDOT, PARM_EQ1
      PARAMETER  ( PARM_EQ1 = 0.25_IREAL_HIGH )
      REAL  ( KIND = IREAL_HIGH )
     &                  YPR, TEMP, T, T3,
     &                  FX, FX1, X, GX, DX, DXP, DPN, XDEV, SX
!C
      DIMENSION  YPR(3,MAXSEG),  TEMP(3), T(5), T3(3), FX(10), 
     &           FX1(10), X(10), GX(10), DX(10), DXP(10), DPN(5,10), 
     &           XDEV(10), SX(10)            
!C
      REAL  ( KIND = IREAL_HIGH )   VECMAG, XDY
      EXTERNAL                      VECMAG, XDY
!C
      LOGICAL  ( KIND = LOGICAL_STD )  EQUILB_CONVERGE
!C
      INTENT (    IN )  M1, M2, M3, MT, IYPR, JITTER, NCON, NQORG, 
     &                  NVAR, KSGE, NSGE, JPL, NAV, NI1, NTV, XDEV, 
     &                  IPL, ISG, LTYPE, INDGX
      INTENT (   OUT )  EQUILB_CONVERGE
      INTENT ( INOUT )  JX, DXP, X, GX, DPN, YPR
!C                                                                        
!C    Iterate input (X) such that F(X) = G(X)                            
!C                                                                        
      MVAR = I_2                                                        
      IF  ( NVAR .EQ. I_1 )  MVAR = I_1                                  
      DO  20  M=1,2                                                     
       DO  30  I=MVAR,NVAR                                               
        DO  40  J=1,I                                                     
         JPASS = J
         NITER = I_10                                                    
         IF  ( DXP(J) .EQ. D_0 )  NITER = MAXEQ_ITER                           
         DX(J) = PARM_EQ1                                         
         N1 = M1(J)                                                       
         N2 = M2(J)                                                       
         N3 = M3(J)                                                       
         NP = JPL(J)                                                      
         NT = MT(J)                                                       
         I1 = NI1(J)                                                    
         I2 = NSGE(J)                                                      
         IAV = NAV(J)                                                    
!C
         IF  ( NTV(J) .EQ. I_2 )  THEN                             
          CALL DRCIJK ( YPR, IYPR, HT, I2 )                
          IF  ( NAV(J) .GT. I_0 )  THEN                         
           DO  K=1,IAV                                                      
            J2 = KSGE(K,J)                                                  
            CALL DRCIJK ( YPR, IYPR, HT, J2 )              
           END DO
          END IF
         END IF
!C
         DO  50  ITER=1,NITER                                             
          CALL CHAIN ( I_0 )                                         
          PEN1 = PEN                                                       
          NPSF = I_1                                                     
          CALL PLELP ( N2, N3, N1, NP, NT )                                
          PEN = PSF(1,1)                                                     
!C
!C        It appears that FX is used before it is defined??
!C
          FX1(J) = FX(J)                                                  
          FXJ = D_0                                                     
          IF ( PEN .GT. D_0 )  THEN
           FXJ = PSF(2,1)                                                   
           CALL FRCDFL ( PEN, PENDOT, NT, I_1, FXJ, ELOSS )              
          END IF
          FX(J) = FXJ                                                      
!C
          IF  ( ( JX(J) - I_2 ) .LT. I_0 )  THEN 
           JX(J) = I_1                                                 
           IF  ( PEN .GT. D_0 )  JX(J) = I_2                              
           IF  ( ( ITER .GT. I_1 ) .AND. ( PEN .LT. D_0  )
     &                             .AND. ( PEN .LT. PEN1 ) )  THEN
            FX(J) = FX1(J)                                                   
            DX(J) = -DX(J)                                                   
            PEN = PEN1                                                       
            X(J) = X(J) + D_2 * DX(J)                                       
           ELSE                                                         
            X(J) = X(J) + DX(J)                                              
           END IF
!C
          ELSE IF ( ( JX(J) - I_2 ) .EQ. I_0 )  THEN
           IF  ( ( FX(J) * FX1(J) ) .LE. D_0 )   THEN               
            IF  ( FX1(J) .EQ. D_0 )  JX(J) = I_1                            
            FX(J) = FX1(J)                                                   
            PEN = PEN1                                                       
            DX(J) = D_HALF * DX(J)                                         
            X(J)  = X(J) - DX(J)                                             
            CALL EQUILB_SOLVE_SUB ( I1, I2, IAV, JPASS, NAV, NTV, X, 
     &                               DPN, XDEV, SX, IYPR, YPR )
            CYCLE                                                         
           END IF
!C
           F2 = FX(J) - GX(J)                                               
           F1_LCL = FX1(J) - GX(J)                                          
           IF  ( ( F1_LCL * F2 ) .LE. D_0 )  THEN                
            DXP(J) = DX(J) / ( FX(J) - FX1(J) )                              
            JX(J) = I_3                                                  
            IF  ( ABS ( FX(J) - GX(J) ) .LT. EPS(6) )  EXIT              
            IF  ( PEN .LT. D_0 )  THEN
             CALL FRCDFL ( -PEN, PENDOT, NT, 1, FXJ, ELOSS )                 
             FX(J) = -FXJ                                                    
            END IF
            X(J) = X(J) - DXP(J) * ( FX(J) - GX(J) )                         
            CALL EQUILB_SOLVE_SUB ( I1, I2, IAV, JPASS, NAV, NTV, X, 
     &                               DPN, XDEV, SX, IYPR, YPR )
            CYCLE
           END IF
!C
           IF  ( ABS ( F2 ) .LT. ABS ( F1_LCL ) )  THEN                 
            JX(J) = I_1                                                 
            IF  ( PEN .GT. D_0 )  JX(J) = I_2                              
            IF  ( ( ITER .GT. I_1 ) .AND. ( PEN .LT. D_0  )
     &                              .AND. ( PEN .LT. PEN1 ) )  THEN
             FX(J) = FX1(J)                                                   
             DX(J) = -DX(J)                                                   
             PEN = PEN1                                                       
             X(J) = X(J) + D_2 * DX(J)                                       
            ELSE                                                         
             X(J) = X(J) + DX(J)                                              
            END IF
           ELSE
            FX(J) = FX1(J)                                                   
            DX(J) = -DX(J)                                                   
            PEN = PEN1                                                       
            X(J) = X(J) + D_2 * DX(J)                                       
           END IF
!C
          ELSE
           IF  ( ABS ( FX(J) - GX(J) ) .LT. EPS(6) )  EXIT              
           IF  ( PEN .LT. D_0 )  THEN
            CALL FRCDFL ( -PEN, PENDOT, NT, 1, FXJ, ELOSS )                 
            FX(J) = -FXJ                                                    
           END IF
           X(J) = X(J) - DXP(J) * ( FX(J) - GX(J) )                         
          END IF
!C
          CALL EQUILB_SOLVE_SUB ( I1, I2, IAV, JPASS, NAV, NTV, X, 
     &                               DPN, XDEV, SX, IYPR, YPR )
   50    CONTINUE                                                        
!C
         IF  ( NPRT(27) .NE. I_0 )  THEN  
          WRITE  ( LUAOU, 105 )  M, I, J, ITER,X(J), FX(J)                 
  105     FORMAT ( 4I3, 4X, 2F12.6 )                                      
         END IF
!C
   40   CONTINUE
   30  CONTINUE
   20 CONTINUE                                                            
!C                                                                       
!C    Compute vehicle coordinates for fixed point constraints.           
!C                                                                        
      IF  ( NQ .GT. I_0 )  THEN                                      
       DO  K=1,NQ                                                         
        IF  ( KQTYPE(K) .NE. I_1 )   CYCLE                           
        IF  ( KQ2(K)    .NE. NVEH )   CYCLE                               
        L = KQ1(K)                                                        
        CALL DOT31 ( SEG(L)%DIR_COS, RK1(1,K), T3 )                
        T3 = T3 + SEG(L)%LIN_DISP - SEG(NVEH)%LIN_DISP                  
        CALL MAT31 ( SEG(NVEH)%DIR_COS, T3, RK2(1,K) )                     
       END DO                                                             
      END IF
!C                                                                        
!C     Solve system equations with constraints off.                      
!C                                                                        
      IF  ( NPRT(27) .NE. I_0 )  THEN                                
       CALL OUTPUT ( I_0 )                                          
       CALL DAUX ( I_0 )                                             
       CALL PRINT ( 'EQUIL2' )                                          
       CALL OUTPUT ( I_1 )                                             
      END IF
!C                                                                        
!C    Set up constraints to produce zero accelerations.                   
!C                                                                        
      NQ = NQORG                                                          
      IF  ( NCON .LE. I_0 )  EQUILB_CONVERGE = TRUE                             
      DO  I=1,NCON                                                        
       NQ = NQ + I_1                                                    
       J = IPL(I)                                                        
       K = ISG(I)                                                         
       NT = NTPL(K,J)                                                     
       NTNQ(I) = NTAB(NT+1)                                               
       NTAB(NT+1) = -NQ                                                   
       KQ1(NQ) = MPL(2,K,J)                                               
       KQ2(NQ) = MPL(1,K,J)                                               
       KQTYPE(NQ) = LTYPE(I)                                             
      END DO
!C                                                                        
!C    Solve system equations with constraints on.                         
!C                                                                        
      CALL OUTPUT ( I_0 )                                            
      CALL DAUX ( I_0 )                                             
      IF  ( ( NPRT(27) .NE. I_0 ) .AND. ( JITTER .EQ. I_1 ) ) THEN
       CALL PRINT ( 'EQUIL1' )                                            
      END IF
!C                                                                        
!C    Fetch constraints forces normal to plane surfaces.                  
!C    Store friction force and turn off constraints.                      
!C                                                                        
      CONV = D_1                                                         
      DO  I=1,NCON                                                        
       MQ = NQORG + I                                                     
       J = IPL(I)                                                         
       K = ISG(I)                                                         
       NT = NTPL(K,J)                                                     
       NTAB(NT+1) = NTNQ(I)                                               
       M = MPL(2,K,J)                                                     
       N = MPL(1,K,J)                                                     
       CALL DOT31 ( SEG(N)%DIR_COS, PL(1,J), TEMP )                   
       T(I) = TEMP(1) * QQ(1,MQ) + TEMP(2) * QQ(2,MQ) 
     &                           + TEMP(3) * QQ(3,MQ)                     
       I1 = INDGX(I)                                                      
       IF  ( ( I1 .GT. I_0 ) .AND. 
     &       ( ABS ( GX(I1) + T(I) ) .GT. EPS(2) ) )   CONV = D_0    
       IF  ( I1 .GT. I_0 )  GX(I1) = D_HALF * ( GX(I1) - T(I) )         
       DO  L=1,3                                                          
        TEMP(L) = QQ(L,MQ) - T(I) * TEMP(L)                               
       END DO
       LT = NTAB(NT)                                                      
       CALL MAT31 ( SEG(M)%DIR_COS, TEMP, TAB(LT+19) )                  
      END DO
      NQ = NQORG                                                          
      IF  ( CONV .EQ. D_1 )  EQUILB_CONVERGE = TRUE                                
!C
      RETURN
      END