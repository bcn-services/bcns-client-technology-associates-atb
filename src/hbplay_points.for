      SUBROUTINE HBPLAY_POINTS ( JNL, K1, K2, L1, L2, L3, LL, 
     &                           NB, NH)                                                
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine was created from Subroutine HBPLAY.  It
!C     determines if new NL array is different from previous NL array.      
!C     If so, it recomputes the BB elements for points that are different.         
!C
!C    It is called only by Subroutine HBPLAY.
!C
!C
      USE  MODULE_STANDARD, ONLY: 
     &       BD,                                          ! /CNTSRF/
     &       TIME,                                        ! /CONTRL/
     &       IBAR, BAR, NL, NPTPLY,                       ! /HRNESS/
     &       PLOSS, NTHRNS, BB,                           ! /HRNESS/
     &       NTAB, TAB,                                   ! /TABLES/
     &       PTLOSS, OLDBB, NOLD_HRN, V_HRN,              ! /HRN_TEMPVS/
     &       T1_HRN, T2_HRN, R_HRN, S_HRN,                ! /HRN_TEMPVS/
     &       SEG,                                         ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU, LOGICAL_STD, ! parameters
     &       D_0, D_1, D_1000, I_0, I_1, I_100            ! parameters
!C
!C    SEG%DIR_COS, SEG%LIN_DISP
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, IP, IP1, ITNEW, ITOLD, J, JNL, K1, K2, 
     &         L1, L2, L3, LL, LTEST, M, M0, ME, MI, MS, 
     &         N, N0, NB, NH, NI, NPTS, NSI
!C
      REAL  ( KIND = IREAL_HIGH )
     &        ABST, AX, BX, D1, D2, D3, D4, DD, TTEMP, USEC
!C
      REAL  ( KIND = IREAL_HIGH )  XDY
      EXTERNAL                     XDY
!C
      LOGICAL  ( KIND = LOGICAL_STD )  CYCLE_M, CYCLE_N, HBPLAY_RETURN                                
!C
      INTENT (    IN )  K2, L1, L2, L3, LL, NB, NH
      INTENT ( INOUT )  K1, JNL
!C
      LTEST = I_0                                                     
      M = L2                                                              
      N = JNL                                                             
!C
      LOOP_OUTER :  DO
       DO
        IF  ( ( NL(1,M+1) - NOLD_HRN(1,N+1) ) .LT. I_0 ) THEN             
         EXIT
        ELSE IF  ( ( NL(1,M+1) - NOLD_HRN(1,N+1) ) .EQ. I_0 )  THEN       
         BB(M) = OLDBB(N)                                                    
         PLOSS(1,M) = PTLOSS(1,N)                                             
         M = M + I_1                                                      
         N = N + I_1                                                     
!C
         IF  ( ( M - LL ) .LT. I_0 )  THEN                                
          CYCLE
         ELSE
          JNL = N + I_1
          IF  ( LTEST .NE. I_0 )  THEN                                   
!C                                                                            
!C        Print new point array if different.                                 
!C                                                                            
          NPTS = LL - L1                                                      
          USEC = D_1000 * TIME                                    
          WRITE  ( LUAOU, 100 )  USEC, NH, NB, NPTS, NTHRNS(NB,1)              
  100     FORMAT ( '0 HBPLAY_POINTS Time =', F10.3, 
     &             ' msec. NH,NB,NPTS NT=', 4I6 )  
          WRITE  ( LUAOU, 105 )  ( NL(1,J), J=L2,LL )                          
  105     FORMAT ( '  NL(1)=', 15I8 / ( 8X, 15I8 ) )                          
          WRITE  ( LUAOU, 110 )  ( BB(J), J=L2,L3 )                            
  110     FORMAT ('  BB   =', 6X, 14F8.3, /, ( 6X, 15F8.3 ) )                 
          END IF
          K1 = K2 + I_1                                                   
          NPTPLY(NB) = LL - L1                                                
          RETURN
         END IF
        ELSE
         M0 = M                                                              
         N0 = N                                                              
         LTEST = I_1                                                      
         N = N + I_1                                                      
         CALL HPOINT_DROP ( CYCLE_M, CYCLE_N, HBPLAY_RETURN,
     &                           K1, K2, JNL, L1, L2, L3, LL, LTEST, 
     &                           M, M0, N, N0, NB, NH )
         IF ( HBPLAY_RETURN )  THEN
          RETURN
         ELSE IF ( CYCLE_N )  THEN
          CYCLE
         ELSE
          EXIT
         END IF
        END IF
       END DO
!C
       IF ( .NOT. CYCLE_M )  THEN
!C                                                                         
!C      Point M+1 is new.                                                   
!C                                                                          
        M0 = M                                                              
        N0 = N                                                              
        LTEST = I_1                                                      
!C                                                                       
!C      The following do-loop has been added to update the force/strain   
!C       load history of a newly activated belt point.  (E. Sieveka,       
!C       UVA - 11/28/93)                                                   
!C                                                                        
        ITNEW = NTAB(NL(2,M+1)) - I_1                                   
        ITOLD = NTAB(NOLD_HRN(2,N+1)) - I_1                            
        DO  I=1,31                                                        
         TAB(ITNEW+I) = TAB(ITOLD+I)                                    
        END DO                                                            
       END IF
!C                                                                       
       LOOP_M : DO
        M = M + I_1                                                     
!C                                                                         
!C      Modify new point to lie in belt plane.                               
!C                                                                         
        IP1 = N - I_1                                                  
        IF  ( N .LE. JNL )   THEN                                           
         IP1 = N                                                            
!C
!C       (Is the third point available from old points in play?)                
!C
         IF  ( NOLD_HRN(1,N+1) .EQ. NL(1,LL) )  THEN
          CALL HPOINT_DROP ( CYCLE_M, CYCLE_N, HBPLAY_RETURN,
     &                           K1, K2, JNL, L1, L2, L3, LL, LTEST, 
     &                           M, M0, N, N0, NB, NH )
          IF ( HBPLAY_RETURN )  THEN
           RETURN
          ELSE IF ( CYCLE_N )  THEN
           CYCLE  LOOP_OUTER
          END IF
          CYCLE  LOOP_M
         END IF
        END IF
!C
!C       (Use old points IP = N-1,N,N+1 if N > JNL                          
!C                    or IP = N,N+1,N+2 if N = JNL and N+2 exists)          
!C
        DO  I=1,3                                                           
         IP = IP1 + I - I_1                                             
         NI = NOLD_HRN(1,IP)                                                 
         NSI= ABS ( IBAR(1,NI) )                                             
         IF ( NSI .GT. I_100 )  
     &        NSI = MOD ( NSI, I_100 )        
         CALL DOT31 ( SEG(NSI)%DIR_COS, BAR(4,NI), T1_HRN )                  
         CALL DOT31 ( SEG(NSI)%DIR_COS, BAR(7,NI), T2_HRN )                 
         DO  J=1,3                                                          
          S_HRN(J,I) = SEG(NSI)%LIN_DISP(J)+ T1_HRN(J) + T2_HRN(J)        
         END DO
        END DO
        DO  J=1,3                                                           
         S_HRN(J,3) = S_HRN(J,3) - S_HRN(J,2)                               
         S_HRN(J,2) = S_HRN(J,2) - S_HRN(J,1)                               
        END DO
!C
!C      (S_HRN(*,1) is point P1 in inertial reference)                      
!C      (S_HRN(*,2) is vector (P2-P1) in inertial reference)                
!C      (S_HRN(*,3) is vector (P3-P2) in inertial reference)                
!C
        CALL CROSS ( S_HRN(1,3), S_HRN(1,2), T2_HRN )                       
        ABST = SQRT( T2_HRN(1)**2 + T2_HRN(2)**2 + T2_HRN(3)**2 )           
        DO  J=1,3                                                           
         T2_HRN(J) = T2_HRN(J) / ABST                                       
        END DO
!C
!C      (T2_HRN is T, the normalized plane vector in inertial reference)    
!C
        MI = NL(1,M)                                                        
        MS = ABS ( IBAR(1,MI) )                                             
        IF ( MS .GT. I_100 )   MS = MOD ( MS, I_100 )          
        ME = IBAR(2,MI)                                                     
        CALL MAT31 ( SEG(MS)%DIR_COS, T2_HRN, T1_HRN )                     
!C
!C      (T1_HRN is T in ellipsoid reference of new point M)                 
!C
        D1 =   T2_HRN(1) * S_HRN(1,1) + T2_HRN(2) * S_HRN(2,1)
     &       + T2_HRN(3) * S_HRN(3,1)                                       
        D2 =   T1_HRN(1) * BAR(7,MI) + T1_HRN(2) * BAR(8,MI) 
     &       + T1_HRN(3) * BAR(9,MI)                                        
        D3 = DOT_PRODUCT ( T2_HRN, SEG(MS)%LIN_DISP )
        DD = D1 - D2 - D3                                                   
!C
!C      (DD is D, the distance of ellipsoid center to plane)                
!C
        CALL MAT31 ( BD(16,ME), T1_HRN, R_HRN )                             
        BX = DD / ( T1_HRN(1) * R_HRN(1) + T1_HRN(2) * R_HRN(2)
     &            + T1_HRN(3) * R_HRN(3) )                                  
        D4 =   T1_HRN(1) * BAR(4,MI) + T1_HRN(2) * BAR(5,MI) 
     &       + T1_HRN(3) * BAR(6,MI)                                        
        DO  J=1,3                                                           
         R_HRN(J) = BX * R_HRN(J)                                           
!C
!C       (R is S, the center of the ellipse)                                
!C
         V_HRN(J) = BAR(J+3,MI) + ( DD - D4 ) * T1_HRN(J)                   
        END DO
!C
!C      (BAR(J+3,MI) is P, the new point to be added)                       
!C      (V is Q, the projection of point P onto the plane)                  
!C
        TTEMP = ( BX * DD - D_1 ) / 
     &          ( BX * DD - XDY ( V_HRN, BD(7,ME), V_HRN ) )              
        IF ( TTEMP .LT. D_0 ) THEN                                   
         AX = D_1                                                     
        ELSE                                                              
         AX = SQRT ( TTEMP )                                            
        END IF                                                            
!C
!C      (BAR(J+3,MI) is R = S + A(Q - S), Q extended to ellipsoid)          
!C
        DO  J=1,3                                                         
         BAR(J+3,MI) = R_HRN(J) + AX * ( V_HRN(J) - R_HRN(J) )              
        END DO
!C
        CALL HPOINT_DROP ( CYCLE_M, CYCLE_N, HBPLAY_RETURN,
     &                     K1, K2, JNL, L1, L2, L3, LL, LTEST, 
     &                     M, M0, N, N0, NB, NH )
!C
        IF ( HBPLAY_RETURN )  THEN
         RETURN
        ELSE IF ( CYCLE_N )  THEN
         CYCLE LOOP_OUTER
        END IF
       END DO  LOOP_M
      END DO LOOP_OUTER
!C
      RETURN
      END