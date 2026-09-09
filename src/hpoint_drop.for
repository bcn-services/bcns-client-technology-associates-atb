      SUBROUTINE  HPOINT_DROP ( CYCLE_M, CYCLE_N, HBPLAY_RETURN,
     &                          K1, K2, JNL, L1, L2, L3, LL, LTEST, 
     &                          M, M0, N, N0, NB, NH )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    It is called only by Subroutine HBPLAY_POINTS.
!C
!C
      USE  MODULE_STANDARD, ONLY: 
     &       TIME,                                        ! /CONTRL/
     &       NL, NPTPLY,                                  ! /HRNESS/
     &       PLOSS, NTHRNS, BB,                           ! /HRNESS/
     &       NTAB, TAB,                                   ! /TABLES/
     &       PTLOSS, OLDBB, NOLD_HRN, BL_HRN,             ! /HRN_TEMPVS/
     &       SEG,                                         ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU,              ! parameters
     &       LOGICAL_STD, TRUE, FALSE,                    ! parameters
     &       D_0, D_1000, I_0, I_1                        ! parameters
!C
!C    SEG%DIR_COS, SEG%LIN_DISP
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, ITNEW, ITOLD, J, JNL, K1, K2, L1, L2, L3, LL, LTEST, 
     &         M, M0, N, N0, NB, NH, NPTS
!C
      REAL  ( KIND = IREAL_HIGH )
     &        RATIO, RATPL, SUMBB, SUMBL, SUMPL, USEC
!C
      LOGICAL  ( KIND = LOGICAL_STD )  CYCLE_M, CYCLE_N, HBPLAY_RETURN                                
!C
      INTENT (    IN )  K2, L1, L2, L3, LL, NB, NH
      INTENT (   OUT )  JNL, CYCLE_M, CYCLE_N, HBPLAY_RETURN
      INTENT ( INOUT )  K1, M, M0, N, N0
!C                                                                        
!C     Point N+1 is dropped.                                              
!C                                                                        
      DO
       IF  ( ( NL(1,M+1) - NOLD_HRN(1,N+1) ) .LT. I_0 )  THEN
        HBPLAY_RETURN = FALSE
        CYCLE_M = TRUE
        CYCLE_N = FALSE
        RETURN
       ELSE IF  ( ( NL(1,M+1) - NOLD_HRN(1,N+1) ) .EQ. I_0 )  THEN
!C                                                                         
!C      Points N0 to N+1 are being replaced with points M0 to M+1.          
!C                                                                       
        SUMBL = D_0                                                       
        DO  J=M0,M                                                          
        SUMBL = SUMBL + BL_HRN(J)                                          
        END DO
        SUMPL = D_0                                                       
        SUMBB = D_0                                                        
        DO  J=N0,N                                                          
         SUMPL = SUMPL + PTLOSS(1,J)                                         
         SUMBB = SUMBB + OLDBB(J)                                           
        END DO
        RATPL = SUMPL / SUMBL                                               
        RATIO = SUMBB / SUMBL                                               
        DO  J=M0,M                                                          
         PLOSS(1,J) = RATPL * BL_HRN(J)                                     
         BB(J) = RATIO * BL_HRN(J)                                          
        END DO
        M = M + I_1                                                      
        N = N + I_1                                                     
!C
        IF  ( ( M - LL ) .LT. I_0 )  THEN                                
         HBPLAY_RETURN = FALSE
         CYCLE_M = FALSE
         CYCLE_N = TRUE
         RETURN
        ELSE
         HBPLAY_RETURN = TRUE
         CYCLE_M = FALSE
         CYCLE_N = FALSE
         JNL = N + I_1
         IF  ( LTEST .NE. I_0 )  THEN                                   
!C                                                                          
!C        Print new point array if different.                                 
!C                                                                          
          NPTS = LL - L1                                                      
          USEC = D_1000 * TIME                                    
          WRITE  ( LUAOU, 100 )  USEC, NH, NB, NPTS, NTHRNS(NB,1)              
  100     FORMAT ( '0 HPOINT_DROP Time =', F10.3, 
     &             ' msec. NH,NB,NPTS NT=', 4I6 )  
          WRITE  ( LUAOU, 105 )  ( NL(1,J), J=L2,LL )                          
  105     FORMAT ( '  NL(1)=', 15I8 / ( 8X, 15I8 ) )                          
          WRITE  ( LUAOU, 115 )  ( BB(J), J=L2,L3 )                            
  115     FORMAT ('  BB   =', 6X, 14F8.3, /, ( 6X, 15F8.3 ) )                 
         END IF
         K1 = K2 + I_1                                                   
         NPTPLY(NB) = LL - L1                                                
         RETURN
        END IF
!C                                                                        
!C      Point M+1 is new.                                                   
!C                                                                         
        M0 = M                                                              
        N0 = N                                                              
        LTEST = I_1                                                      
        ITNEW = NTAB(NL(2,M+1)) - I_1                                   
        ITOLD = NTAB(NOLD_HRN(2,N+1)) - I_1                            
        DO  I=1,31                                                        
         TAB(ITNEW+I) = TAB(ITOLD+I)                                    
        END DO                                                            
        HBPLAY_RETURN = FALSE
        CYCLE_M = TRUE
        CYCLE_N = FALSE
        RETURN
       ELSE
        N = N + I_1
        CYCLE
       END IF
      END DO
!C
      RETURN
      END