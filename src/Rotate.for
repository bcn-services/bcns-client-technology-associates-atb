      SUBROUTINE ROTATE                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    The purpose of this routine is to transform those variables that    
!C    have been supplied in local geometric coordinates to principal      
!C    axes coordinates as indicated by LPMI(I) # 0 for I = 1 to NSEG.     
!C                                                                        
      USE  MODULE_STANDARD,  ONLY: 
     &        NRTORQ,                                            ! /ACTFR/
     &        HIR,                                               ! /CEULER/
     &        BD, BELT, PL,                                      ! /CNTSRF/
     &        NBAG, NBLT, NGRND, NHRNSS, NJNT, NPL, NQ,          ! /CONTRL/ 
     &        NSD, NSEG, NWINDF,                                 ! /CONTRL/
     &        KQ1, KQ2, KQTYPE, RK1, RK2,                        ! /CSTRNT/
     &        APSDM, APSDN, MSDM, MSDN,                          ! /DAMPER/
     &        HT,                                                ! /DESCRP/
     &        BAR, IBAR, NBLTPH, NPTSPB,                         ! /HRNESS/
     &        MBAG, MBLT, MNBAG, MNBLT, MNPL, MNSEG, MPL, MSEG,  ! /JBARTZ/
     &        NTI, TAB,                                          ! /TABLES/
     &        NUMVEH,                                            ! /VPOSTN/
     &        MOWSEG, MWSEG, NFVSEG, QFU, QFV, MOWELP, NFORCE,   ! /WINDFR/
     &        ACT, SEG, JNT, VEH,                                ! structures
     &        INTEGER_STD, IREAL_HIGH, LOGICAL_STD, FALSE,       ! parameters
     &        LUAOU, MAXELP, MAXJNT, MAXSEG,                     ! parameters 
     &        D_0, I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_8, I_100 ! parameters
!C
!C    BASE_SEG, TOR_AXIS                                         ! ACT%
!C    ANG_VEL, DIR_COS, DRC_PHI, ROT_PHI                         ! SEG%
!C    PROX_SEG, DSTL_LOC, PROX_LOC, JTYPE, PROX_HB, DSTL_HB      ! JNT%
!C    IVFLG, IVSEG, IVREF, LIN_DATA, ANG_DATA, NUM_VTAB, VNORMAL ! VEH%
!C
      USE  MODULE_WATER,  ONLY:
     &        DELP,                                   ! /ELPDAT/
     &        BDPFD, KPFD, NUM_PER_FLOAT_DEV, NWATER, ! /WATINF1/
     &        DPFD, NPE                               ! /WATINF2/
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, I1, I2, I3, II, IJ_LCL, INATAB, 
     &           IQ, IREF, IV, IZX, J, J1, J2, JJ, 
     &           K, K1, K2, K5, KBAG, KBLT, KPL, KSEG, KT, 
     &           L, LBD, LI, LJ, LPL, LTEST, M, M1, M2, M3, M4, M7, 
     &           NATAB, NENTRY, NSR, NT 
      DIMENSION  LBD(MAXELP)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  RK, T1, T2_LCL, T3, T4, T5_LCL 
      DIMENSION         T1(3), T3(3,3), T2_LCL(3), T4(3,3), 
     &                  T5_LCL(3,3)                               
!C
      LOGICAL ( KIND = LOGICAL_STD )  ILP
!C                                                                        
!C    Transform direction cosine matrices D from input Cards G.3.          
!C                                                                        
      LTEST = I_0                                                      
      DO  J=1,MAXSEG                                                      
       IF  ( J .GT. NSEG )  SEG(J)%ROT_PHI = FALSE                   
       IF  ( SEG(J)%ROT_PHI )   THEN                                  
        LTEST = 1                                                    
        T3 = SEG(J)%DIR_COS
        T1 = SEG(J)%ANG_VEL                                      
        CALL MAT33 ( SEG(J)%DRC_PHI, T3, SEG(J)%DIR_COS  )                   
        CALL MAT31 ( SEG(J)%DRC_PHI, T1, SEG(J)%ANG_VEL )                  
       END IF
      END DO                                                              
      IF  ( LTEST .EQ. I_0 )  THEN
       RETURN
      END IF                                                              
!C                                                                        
!C    Transform SR, HT and HB from input Cards B.3.                       
!C                                                                        
      IF  ( NJNT .GT. I_0 )  THEN                                     
       DO  J=1,NJNT                                                       
        I = ABS ( JNT(J)%PROX_SEG )                                       
        M = I_2                                                          
        IF ( ABS ( JNT(J)%JTYPE ) .GT. I_4 )  M = I_3                           
        DO  K=1,2                                                         
         IF  ( ( I .NE. I_0 ) .AND. SEG(I)%ROT_PHI  )  THEN         
          IJ_LCL = I_2 * J - I_2 + K                                 
          IF ( K .EQ. I_1 ) THEN
           T1     = JNT(J)%PROX_LOC      
           T2_LCL = JNT(J)%PROX_HB                                   
          ELSE
           T1     = JNT(J)%DSTL_LOC
           T2_LCL = JNT(J)%DSTL_HB                           
          END IF
          DO  LI=1,3                                                      
           DO  LJ=1,3                                                     
            T4(LI,LJ) = HIR(LI,LJ,IJ_LCL+MAXJNT)                          
            T3(LI,LJ) = HT(LI,LJ,IJ_LCL)                                  
           END DO
          END DO
          IF ( K .EQ. I_1 )  THEN
           CALL MAT31 ( SEG(I)%DRC_PHI, T1,     JNT(J)%PROX_LOC  )    
           CALL MAT31 ( SEG(I)%DRC_PHI, T2_LCL, JNT(J)%PROX_HB   )   
          ELSE
           CALL MAT31 ( SEG(I)%DRC_PHI, T1,     JNT(J)%DSTL_LOC  )
           CALL MAT31 ( SEG(I)%DRC_PHI, T2_LCL, JNT(J)%DSTL_HB   )   
          END IF
          CALL MAT33 ( SEG(I)%DRC_PHI, T3,     HT(1,1,IJ_LCL)         )    
          CALL MAT33 ( SEG(I)%DRC_PHI, T4,     HIR(1,1,IJ_LCL+MAXJNT) )   
         END IF
         I = J + I_1                                                   
        END DO
       END DO                                                             
      END IF
!C                                                                         
!C    Rotate vehicle accelerations computed by VINPUT.                    
!C                                                                         
      IF ( NUMVEH .NE. I_0 )  THEN                                      
       DO 300 IV=1,NUMVEH                                                 
        I1     = ABS ( VEH(IV)%IVFLG )                                       
        I2     = VEH(IV)%IVSEG                                                  
        I3     = VEH(IV)%IVREF                                                
        NATAB  = VEH(IV)%NUM_VTAB                                                 
        INATAB = ABS ( NATAB )                                            
!C                                                                        
!C      Current version does not permit segments with rotated              
!C       principal axes to be used as a vehicle unless its motion         
!C       is specified with respect to the ground.                         
!C                                                                        
        ILP = SEG(I2)%ROT_PHI                                    
        IF ( ILP .AND. ( I3 .NE. NGRND ) )  THEN          
         WRITE ( LUAOU, 389 ) I2                                           
  389    FORMAT ( /, '  Segment number ', I4, ' has rotated ',            
     &            'principal axes and is associated with a vehicle',     
     &            /, '  with motion that is not defined with respect ',   
     &            'to the ground.  This is not allowed.', // )            
         STOP ' STOP 567 in Subroutine ROTATE '                           
        END IF                                                            
!C                                                                      
!C      Determine if data are in vehicle (I1 = 1), reference (I1 = 2)      
!C      or ground (I1 = 0) coordinate system.  For linear quantities,      
!C      use the reference coordinate system DRC_PHI.  For angular         
!C      acceleration, the data are in local coordinates, hence            
!C      use the segment's DRC_PHI.                                       
!C                                                                        
        IREF = I_0                                                    
        IF ( I1 .EQ. I_0 ) THEN                                   
         IREF = NGRND                                                     
        ELSE IF ( I1 .EQ. I_1 ) THEN                                     
         IREF = I2                                                         
        ELSE                                                               
         IREF = I3                                                        
        END IF                                                             
!C                                                                         
!C      Check to see if the segment in which the data are has              
!C      rotated principal axes.  If not, skip to next vehicle.           
!C      Note that the only possible vehicles with rotated principal       
!C      axes are those that are also body segments.                       
!C                                                                        
!C      First rotate linear quantities.                                    
!C                                                                        
        IF ( SEG(IREF)%ROT_PHI )  THEN                              
!C                                                                         
!C       If IVth vehicle option is 1 or 2, transform only AXV.             
!C                                                                       
         IF ( NATAB .GE. I_0 ) THEN                                   
          T1 = VEH(IV)%VNORMAL
          CALL MAT31 ( SEG(IREF)%DRC_PHI, T1, VEH(IV)%VNORMAL(1) )           
         ELSE                                                             
!C                                                                         
!C        If IVth vehicle option is 3 or 4, transform all                 
!C         the linear deceleration time histories.   
!C                                                                        
          DO  IZX=1,INATAB                                                
           DO  IQ=1,3                                                    
            T1(IQ) = VEH(IV)%LIN_DATA(IQ,IZX)
           END DO
           CALL MAT31 ( SEG(IREF)%DRC_PHI, T1, VEH(IV)%LIN_DATA(1,IZX) )        
          END DO                                                           
         END IF                                                            
        END IF                                                             
  300  CONTINUE                                                           
!C                                                                        
!C     Rotate angular accelerations                                        
!C                                                                         
       IF ( SEG(I2)%ROT_PHI )   THEN                                  
        DO  IZX=1,INATAB                                                   
         DO  IQ=1,3                                                        
          T1(IQ) = VEH(IV)%ANG_DATA(IQ,IZX)
         END DO
         CALL MAT31 ( SEG(I2)%DRC_PHI, T1, VEH(IV)%ANG_DATA(1,IZX) )         
        END DO                                                            
       END IF                                                             
      END IF                                                               
!C                                                                       
!C    Transform RK1, RK2 from input Cards D.6.                           
!C                                                                       
      IF  ( NQ .GT. I_0 )  THEN                                        
       K5 = I_0                                                       
       DO  K=1,NQ                                                         
        IF  ( K5 .EQ. I_1 )   THEN                                      
         IF ( KQTYPE(K) .EQ. I_5)  K5 = I_1 - K5
        ELSE
         KSEG = KQ1(K)                                                    
         IF  ( SEG(KSEG)%ROT_PHI )  THEN      
          DO  I=1,3                                                       
           T1(I) = RK1(I,K)                                              
          END DO
          CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1, RK1(1,K) )            
         END IF
         KSEG = KQ2(K)                                                    
         IF  ( SEG(KSEG)%ROT_PHI )  THEN                          
          DO  I=1,3                                                       
           T1(I) = RK2(I,K)                                              
          END DO
          CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1, RK2(1,K) )               
          IF  ( KQTYPE(K) .EQ. I_5 )  K5 = I_1 - K5                 
         END IF
        END IF
       END DO                                                            
      END IF
!C                                                                        
!C    Transform APSDM,APSDN from input Cards D.8.                        
!C                                                                        
      IF  ( NSD .GT. I_0 )   THEN                                       
       DO  J=1,NSD                                                        
        KSEG = MSDM(J)                                                    
        IF  ( SEG(KSEG)%ROT_PHI )  THEN                              
         DO  I=1,3                                                    
          T1(I) = APSDM(I,J)                                             
         END DO
         CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1, APSDM(1,J) )            
        END IF
        KSEG = MSDN(J)                                                    
        IF  ( SEG(KSEG)%ROT_PHI )  THEN                         
         DO  I=1,3                                                        
          T1(I) = APSDN(I,J)                                              
         END DO
         CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1, APSDN(1,J) )           
        END IF
       END DO                                                             
      END IF
!C                                                                        
!C    Transform QFU and QFV from input Cards D.9.                         
!C                                                                        
      IF ( NFORCE .GT. I_0 )   THEN                                    
       DO  J=1,NFORCE                                                     
        KSEG = ABS ( NFVSEG(J) )                                          
        IF ( SEG(KSEG)%ROT_PHI )  THEN                           
         DO  I=1,3                                                        
          T1(I)     = QFU(I,J)                                            
          T2_LCL(I) = QFV(I,J)                                            
         END DO
         CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1,     QFU(1,J) )            
         CALL MAT31 ( SEG(KSEG)%DRC_PHI, T2_LCL, QFV(1,J) )            
        END IF                                                            
       END DO
      END IF
!C                                                                        
!C    Transform QRU from input Cards F.10                                 
!C                                                                        
      IF ( NRTORQ .GT. I_0 )  THEN                                     
       DO  J=1,NRTORQ                                                     
        KSEG = ACT(J)%BASE_SEG                                                     
        IF ( SEG(KSEG)%ROT_PHI )  THEN                              
         T1 = ACT(J)%TOR_AXIS
         CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1, ACT(J)%TOR_AXIS(1) )                 
        END IF                                                            
       END DO
      END IF
!C                                                                       
!C    Rotate wind force functions                                        
!C                                                                       
      IF ( NWINDF .NE. I_0 )  THEN                                  
       LOOP_WIND : DO  I=1,NSEG                                          
        IF ( MWSEG(1,I) .NE. I_0 ) THEN                              
         NT = MWSEG(5,I)                                                 
         DO  J=1,I-1                                                    
          IF  ( NT .EQ. MWSEG(5,J) )  CYCLE LOOP_WIND                   
         END DO                                                          
         KT = NTI(NT)                                                   
         RK = TAB(KT)                                                    
         IF ( RK .EQ. D_0 )   THEN                              
          NSR = INT ( TAB(KT+4) )                                      
          IF ( ( NSR .NE. I_0 ) .AND. SEG(NSR)%ROT_PHI )  THEN     
           NENTRY = TAB(KT+5)                                           
           K1 = KT + I_6                                               
           K2 = I_4 * NENTRY + KT + I_2                                  
           DO  K=K1,K2,4                                                 
            DO  J=1,3                                                    
             T1(J) = TAB(K+J)                                            
            END DO
            CALL MAT31 ( SEG(NSR)%DRC_PHI, T1, TAB(K+1) )             
           END DO
          END IF
         END IF
        END IF
       END DO LOOP_WIND
      END IF
!C                                                                        
!C    Check plane and ellipsoid assignments on input Cards F.1.          
!C    transform plane arrays set up from input Card D.1.               
!C                                                                        
      DO  J=1,MAXELP                                                     
       LBD(J) = I_0                                                   
       IF  ( J .LE. NSEG )  LBD(J) = J                                   
      END DO
      IF  ( NPL .GT. I_0 )  THEN                                      
       DO  60  J=1,NPL                                                    
        IF  ( MNPL(J) .NE. I_0 )  THEN                                 
         LPL = I_0                                                     
         KPL = MNPL(J)                                                  
         DO  I=1,KPL                                                     
          M1 = MPL (1,I,J)                                                
          M2 = MPL (2,I,J)                                                
          M3 = ABS ( MPL(3,I,J) )                                        
          IF  ( ( LPL .NE. M1 ) .AND. ( LPL .NE. I_0 ) )  THEN        
           WRITE  ( LUAOU, 53 ) J, M1, LPL                                
   53      FORMAT ( '0 Input error has been detected in ', 
     &              'Subroutine ROTATE.', /, '  Plane no.', I3,
     &              ' has been assigned to both segments no.', I3,  
     &              ' and no.', I3, '.', /, 
     &              '  Program is being terminated.' )                    
           STOP 43                                                        
          END IF
          LPL = M1                                                      
          IF  ( ( LBD(M3) .NE. M2 ) .AND. 
     &          ( LBD(M3) .NE. I_0 ) ) THEN    
           WRITE  ( LUAOU, 68 )  M3, M2, LBD(M3)                         
           STOP 44                                                        
          END IF
          LBD(M3) = M2                                                   
         END DO                                                           
         IF  ( SEG(LPL)%ROT_PHI )   THEN                             
          L = I_1                                                         
          DO  K=1,6                                                       
           IF  ( ( K .EQ. I_3 ) .OR. ( K .EQ. I_6 ) )  
     &               L = L - I_1      
           IF  ( ( K .EQ. I_4 ) .OR. ( K .EQ. I_5 ) )   
     &               L = L + I_1     
           DO  I=1,3                                                     
            T1(I) = PL(L,J)                                                
            L = L + I_1                                                 
           END DO
           CALL MAT31 ( SEG(LPL)%DRC_PHI, T1, PL(L-3,J) )               
           L = L + I_1                                                  
          END DO
         END IF
        END IF
   60  CONTINUE                                                         
      END IF
!C                                                                       
!C    Check ellipsoid assignments on input Cards F.2.                    
!C    transform BELT(L,J) for L=1,9 from input Cards D.3.                
!C                                                                        
      IF  ( NBLT .GT. I_0 )  THEN                                     
       DO  65  J=1,NBLT                                                   
        IF  ( MNBLT(J) .NE. I_0 )  THEN                              
         KBLT = MNBLT(J)                                                  
         DO  I=1,KBLT                                                     
          M1 = MBLT(1,I,J)                                                
          M2 = MBLT(2,I,J)                                                
          M3 = MBLT(3,I,J)                                                
          IF  ( ( LBD(M3) .NE. M2 ) .AND. 
     &          ( LBD(M3) .NE. I_0 ) )  THEN   
           WRITE  ( LUAOU, 68 )  M3, M2, LBD(M3)                         
           STOP 45                                                        
          END IF
          LBD(M3) = M2                                                   
         END DO
         IF  ( SEG(M1)%ROT_PHI )   THEN                              
          DO  I=1,3                                                      
           T3(I,1) = BELT(I  ,J)                                          
           T3(I,2) = BELT(I+3,J)                                          
          END DO
          CALL MAT31 ( SEG(M1)%DRC_PHI, T3(1,1), BELT(1,J) )              
          CALL MAT31 ( SEG(M1)%DRC_PHI, T3(1,2), BELT(4,J) )             
         END IF
         IF  ( SEG(M2)%ROT_PHI )   THEN                          
          DO  I=1,3                                                      
           T3(I,3) = BELT(I+6,J)                                          
          END DO
          CALL MAT31 ( SEG(M2)%DRC_PHI, T3(1,3), BELT(7,J) )            
         END IF
        END IF
   65  CONTINUE                                                           
      END IF
!C                                                                       
!C    Check ellipsoid assignments on input Cards F.3.                     
!C                                                                       
      DO  J=1,NSEG                                                        
       IF  ( MNSEG(J) .NE. I_0 )  THEN                                 
        KSEG = MNSEG(J)                                                   
        DO  I=1,KSEG                                                     
         M1 = MSEG(1,I,J)                                                 
         M2 = MSEG(2,I,J)                                                
         M3 = MSEG(3,I,J)                                                
         IF  ( ( LBD(M1) .NE. J ) .AND. ( LBD(M1) .NE. I_0 ) )  THEN   
          WRITE  ( LUAOU, 68 )  M1, J, LBD(M1)                          
          STOP 46                                                         
         END IF
         LBD(M1) = J                                                     
         IF  ( ( LBD(M3) .NE. M2 ) .AND. 
     &         ( LBD(M3) .NE. I_0 ) )  THEN  
          WRITE  ( LUAOU, 68 )  M3, M2, LBD(M3)                           
   68     FORMAT ( '0 Input error has been detected in ',
     &             'Subroutine ROTATE.', /, '  Ellipsoid no.', I3,
     &             ' has been assigned to both segments no.', I3,         
     &             ' and no.', I3, '.', /,
     &             '  Program is being terminated.' )                     
          STOP 47                                                         
         END IF
         LBD(M3) = M2                                                    
        END DO
       END IF
      END DO                                                             
!C                                                                        
!C    Check ellipsoid assignments on input Cards F.6.                     
!C                                                                        
      IF  ( NBAG .NE. I_0 )  THEN                                      
       DO  J=1,NBAG                                                     
        IF  ( MNBAG(J) .NE. I_0 )  THEN                                
         KBAG = MNBAG(J)                                                  
         DO  I=1,KBAG                                                     
          M2 = MBAG(2,I,J)                                                
          M3 = MBAG(3,I,J)                                                
          IF  ( ( LBD(M3) .NE. M2 ) .AND. 
     &          ( LBD(M3) .NE. I_0 ) )  THEN   
           WRITE  ( LUAOU, 68 )  M3, M2, LBD(M3)                          
           STOP 50                                                        
          END IF
          LBD(M3) = M2                                                   
         END DO
        END IF
       END DO                                                             
      END IF
!C                                                                        
!C    Check ellipsoid assignments on input Cards F.7.                     
!C                                                                       
      IF ( NWINDF .NE. I_0 )  THEN                                     
       DO  J=1,NSEG                                                      
        M1 = ABS ( MWSEG(1,J) )                                           
        IF ( M1 .NE. I_0 )  THEN                                      
         M2 = MWSEG(2,J)                                                 
         IF  ( ( LBD(M2) .NE. M1 ) .AND. 
     &         ( LBD(M2) .NE. I_0 ) )  THEN  
          WRITE ( LUAOU, 68 )  M2, M1, LBD(M2)                            
          STOP 48                                                         
         END IF
         LBD(M2) = M1                                                     
         IF ( MWSEG(1,J) .LT. I_0 )  THEN                          
          M7 = MWSEG(7,J)                                               
          DO  K=1,M7                                                    
           M3 = MOWSEG(K,J)                                         
           M4 = MOWELP(K,J)                                           
           IF ( ( LBD(M4) .NE. M3 ) .AND. 
     &          ( LBD(M4) .NE. I_0 ) ) THEN  
            WRITE ( LUAOU, 68 )  M4, M3, LBD(M4)                        
            STOP 2                                                      
           ELSE                                                         
            LBD(M4) = M3                                                
           END IF                                                       
          END DO                                                        
         END IF                                                         
        END IF
       END DO                                                             
      END IF
!C                                                                        
!C    Check ellipsoid assignments on input Cards F.8.                     
!C    Transform BAR(L,K) for L=4,12 from input Cards F.8.D.               
!C                                                                        
      IF  ( NHRNSS .NE. I_0 )  THEN                                    
       J1 = I_1                                                        
       K1 = I_1                                                       
       DO  II=1,NHRNSS                                                  
        IF  ( NBLTPH(II) .GT. I_0 )  THEN                              
         J2 = J1 + NBLTPH(II) - I_1                                   
         DO  JJ=J1,J2                                                   
          IF  ( NPTSPB(JJ) .GT. I_0 )  THEN                            
           K2 = K1 + NPTSPB(JJ) - I_1                                 
           DO  K=K1,K2                                                    
            M2 = MOD ( IBAR(1,K), I_100 )                       
            M3 = IBAR(2,K)                                               
            IF  ( M3 .NE. I_0 )  THEN                                
             IF  ( ( LBD(M3) .NE. M2 ) .AND. 
     &             ( LBD(M3) .NE. I_0 ) )  THEN
              WRITE  ( LUAOU, 68 )  M3, M2, LBD(M3)                      
              STOP 51                                                    
             END IF
             LBD(M3) = M2                                                
            END IF
            IF  ( SEG(M2)%ROT_PHI )  THEN                        
             DO  J=3,9,3                                                  
              DO  I=1,3                                                   
               IJ_LCL = I + J                                             
               T1(I) = BAR(IJ_LCL,K)                                      
              END DO
              CALL MAT31 ( SEG(M2)%DRC_PHI, T1, BAR(J+1,K) )          
             END DO
            END IF                                                        
           END DO
           K1 = K2 + I_1                                             
          END IF
         END DO                                                           
         J1 = J2 + I_1                                                
        END IF
       END DO                                                             
      END IF
!C                                                                        
!C    Transform data in BD arrays for ellipsoids that have been assigned. 
!C                                                                       
      DO  90  J=1,MAXELP                                                  
       IF  ( LBD(J) .NE. I_0 )   THEN                               
        KSEG = LBD(J)                                                     
        IF  ( SEG(KSEG)%ROT_PHI )  THEN                             
         L = I_4                                                        
         IF ( BD(1,J) .EQ. D_0 )  THEN                                
          WRITE ( LUAOU, 180 )  J                                         
  180     FORMAT ( 'O Input error has been detected in ',
     &             'Subroutine ROTATE.', /, 'Ellipsoid no.', I3,
     &             ' has been assigned to a segment on',                 
     &             ' Card F.1, F.2, F.3, F.6, F.7, or F.8,', /,
     &             'and has not',   
     &             ' been defined on the B.2 or D.5 cards.' )             
          STOP ' STOP 49 in Subroutine ROTATE'                            
         END IF                                                           
         IF  ( BD(1,J) .LT. D_0 )  L = I_5                              
         M = I_8                                                     
         DO  I=1,3                                                        
          T1(I) = BD(L,J)                                                  
          L = L + I_1                                                  
          DO  K = 1,3                                                      
           T3(K,I)     = BD(M,J)                                           
           T5_LCL(K,I) = DELP(K,I,J)                                      
           M = M + I_1                                                 
          END DO
         END DO
         CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1, BD(L-3,J) )                
         IF  ( BD(1,J) .GT. D_0 )  THEN                               
          CALL DOTT33 ( BD( 7,J), SEG(KSEG)%DRC_PHI, T3 )                 
          CALL MAT33  ( SEG(KSEG)%DRC_PHI, T3, BD( 7,J) )                
          CALL DOTT33 ( BD(16,J), SEG(KSEG)%DRC_PHI, T3 )                
          CALL MAT33  ( SEG(KSEG)%DRC_PHI, T3, BD(16,J) )               
          IF ( NWATER .NE. I_0 )  THEN                              
           CALL MAT33 ( SEG(KSEG)%DRC_PHI, T5_LCL, DELP(1,1,J) )        
          END IF                                                        
         ELSE
          CALL MAT33 ( SEG(KSEG)%DRC_PHI, T3, BD(8,J) )                   
         END IF
        END IF
       END IF
   90 CONTINUE                                                            
!C                                                                      
      IF ( NWATER .NE. I_0 )  THEN                                  
       IF ( NUM_PER_FLOAT_DEV .GE. I_1 )  THEN
        DO J=1,NPE                                                       
         KSEG = KPFD(J)
         IF ( SEG(KSEG)%ROT_PHI )  THEN
          L = I_4                                                   
          DO  I=1,3                                                       
           T1(I) = BDPFD(L,J)
           L = L + I_1                                                 
           DO  K = 1,3                                                   
            T5_LCL(K,I) = DPFD(K,I,J)
           END DO                                                       
          END DO                                                          
          CALL MAT31 ( SEG(KSEG)%DRC_PHI, T1, BDPFD(L-3,J) )
          CALL DOTT33 ( BDPFD(13,J), SEG(KSEG)%DRC_PHI, T3 )
          CALL MAT33 ( SEG(KSEG)%DRC_PHI, T3, BDPFD(13,J) )
          CALL DOTT33 ( BDPFD(22,J), SEG(KSEG)%DRC_PHI, T3 )
          CALL MAT33 ( SEG(KSEG)%DRC_PHI, T3, BDPFD(22,J) )
          CALL MAT33 ( SEG(KSEG)%DRC_PHI, T5_LCL, DPFD(1,1,J) )
         END IF                                                          
        END DO                                                           
       END IF                                                            
      END IF                                                              
!C                                                                       
      RETURN                                                              
      END                                                                 
