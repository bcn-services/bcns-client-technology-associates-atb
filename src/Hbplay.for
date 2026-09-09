      SUBROUTINE HBPLAY                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD, ONLY: 
     &       BD,                                          ! /CNTSRF/
     &       NHRNSS, TIME,                                ! /CONTRL/
     &       NBLTPH, NPTSPB, IBAR, BAR, NL, NPTPLY,       ! /HRNESS/
     &       PLOSS, NTHRNS, XLONG, BB, KEEP,              ! /HRNESS/
     &       PTLOSS, OLDBB, NOLD_HRN, ZR_HRN,             ! /HRN_TEMPVS/
     &       BL_HRN, T1_HRN, T2_HRN, R_HRN, U_HRN,        ! /HRN_TEMPVS/
     &       SEG,                                         ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU, LUTERM_OUT,  ! parameters
     &       D_0, D_1, D_1000, I_0, I_1, I_100, MAXHPT    ! parameters
!C
!C    SEG%DIR_COS, SEG%LIN_DISP
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &        I, J, J1, J2, JB, JE, JJ, JNL, JPOINT, JS, 
     &        K, K1, K2, KB, KS, L1, L2, L3, LL, 
     &        NB, NBPASS, NH, NHPASS, NPTS
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  DPR, DSS, USEC, XLG
!C
      IF  ( NHRNSS .LE. I_0 )  RETURN                                  
!C                                                                        
!C    Save previous NL,BB and PLOSS arrays.                               
!C    Use NOLD_HRN, OLDBB and PTLOSS as temp storage.                      
!C                                                                        
      DO  I=1,MAXHPT                                                         
       NOLD_HRN(1,I) = NL(1,I)                                             
       NOLD_HRN(2,I) = NL(2,I)                                             
       PTLOSS(1,I) = PLOSS(1,I)                                            
       OLDBB(I) = BB(I)                                                   
      END DO
!C
      JNL = I_1                                                       
      J1 = I_1                                                        
      K1 = I_1                                                        
      LL = I_0                                                        
      DO  20  NH=1,NHRNSS                                                 
       NHPASS = NH
       IF  ( NBLTPH(NH) .LE. I_0 )  CYCLE                              
       J2 = J1 + NBLTPH(NH) - I_1                                    
       DO  30  NB=J1,J2                                                    
        NBPASS = NB
        L1 = LL                                                             
        IF  ( NPTSPB(NB) .LE. I_0 )  THEN
         NPTPLY(NB) = LL - L1                                                
         CYCLE
        END IF
        K2 = K1 + NPTSPB(NB) - I_1                                       
        KB = I_0                                                        
!C
        DO  K=K1,K2                                                    
         KB = KB + I_1
!C                                                                        
!C       Here K is index of all points                                       
!C           KB is index of points on a single belt                          
!C           LL is index of all points in play                               
!C           JB is index of previous point on belt in play                   
!C                                                                         
         KS = ABS ( IBAR(1,K) )                                              
         IF  ( KS .GT. I_100 )  KS = MOD ( KS, I_100 )         
         CALL DOT31 ( SEG(KS)%DIR_COS, BAR(4,K), T1_HRN )                   
         CALL DOT31 ( SEG(KS)%DIR_COS, BAR(7,K), T2_HRN )                   
         DO  J=1,3                                                           
          U_HRN(J,KB) = SEG(KS)%LIN_DISP(J) + T1_HRN(J) + T2_HRN(J)    
         END DO
         IF  ( K .NE. K1 )   THEN                                            
          LL = LL + I_1                                                  
          LOOP_A : DO
           JJ = NL(1,LL)                                                      
           JB = JJ - K1 + I_1                                              
           DSS = D_0                                                     
           DO  J=1,3                                                          
            ZR_HRN(J,KB) = U_HRN(J,KB) - U_HRN(J,JB)                          
            DSS = DSS + ZR_HRN(J,KB)**2                                       
           END DO
           BL_HRN(LL) = SQRT ( DSS )                                          
           IF  ( ( JJ .EQ. K1 ) .OR. 
     &           ( ABS ( IBAR(1,JJ) ) .GT. I_100 ) )  THEN
            EXIT   LOOP_A
           END IF
           JS = IBAR(1,JJ)                                                    
           JE = IBAR(2,JJ)                                                    
           IF  ( JE .LE. I_0 )  THEN
            EXIT  LOOP_A
           END IF
           CALL MAT31 ( BD(7,JE), BAR(4,JJ), T2_HRN )                         
           CALL DOT31 ( SEG(JS)%DIR_COS, T2_HRN, R_HRN )                    
           DPR = D_0                                                      
           DO  J=1,3                                                          
            DPR = DPR +  R_HRN(J) * ( ZR_HRN(J,KB) / BL_HRN(LL)
     &                              - ZR_HRN(J,JB) / BL_HRN(LL-1) )  
           END DO
!C                                                                        
!C         If the next test is true a point is dropped from the belt        
!C                                                                        
           IF ( ( DPR .GE. D_0 ) .AND. ( KEEP(K-1) .EQ. I_0 ) )  THEN    
            LL = LL - I_1                                                
           ELSE
            EXIT  LOOP_A
           END IF                                                           
          END DO  LOOP_A
         END IF
         NL(1,LL+1) = K                                                      
        END DO
        L2 = L1 + I_1                                                     
        LL = LL + I_1                                                     
        L3 = LL - I_1                                                    
!C                                                                        
!C      The variable "JPOINT" has been added to address the separate      
!C       storage that is now provided for each belt segment's force/strain 
!C       load history.  See comment in FDINIT. (E. Sieveka, UVA - 11/28/92)
!C                                                                                      
        DO  J=L2,LL                                                       
         JPOINT = NL(1,J) - K1 + I_1                                  
         NL(2,J) = NTHRNS(NB,JPOINT)                                      
        END DO
!C                                                                          
!C      First time in routine, set initial BB array.                       
!C      Input XLONG must be non-zero to trigger this test.                 
!C                                                                        
        IF  ( XLONG(NB) .NE. D_0 )   THEN                               
         XLG = D_0                                                        
         DO  J=L2,L3                                                        
          XLG = XLG + BL_HRN(J)                                             
         END DO
         XLG = D_1 + XLONG(NB) / XLG                                     
         DO  J=L2,L3                                                        
          BB(J) = XLG * BL_HRN(J)                                           
         END DO
         XLONG(NB) = D_0                                                  
!C                                                                         
!C       Print new point array if different.                                 
!C                                                                        
         NPTS = LL - L1                                                      
         USEC = D_1000 * TIME                                    
         WRITE  ( LUAOU, 100 )  USEC, NH, NB, NPTS, NTHRNS(NB,1)              
  100    FORMAT ( '0 HBPLAY Time =', F10.3, 
     &            ' msec. NH,NB,NPTS NT=', 4I6 )  
         WRITE  ( LUAOU, 105 )  ( NL(1,J), J=L2,LL )                          
  105    FORMAT ( '  NL(1)=', 15I8 / ( 8X, 15I8 ) )                          
         WRITE  ( LUAOU, 110 )  ( BB(J), J=L2,L3 )                            
  110    FORMAT ('  BB   =', 6X, 14F8.3, /, ( 6X, 15F8.3 ) )                 
         K1 = K2 + I_1                                                   
         NPTPLY(NB) = LL - L1                                                
         CYCLE                                                           
        END IF
!C                                                                        
!C      Determine if new NL array is different from previous NL array.      
!C      If so, recompute BB elements for points that are different.         
!C                                                                          
        IF  ( NL(1,L2) .EQ. NOLD_HRN(1,JNL) )  THEN                          
         CALL HBPLAY_POINTS ( JNL, K1, K2, L1, L2, L3, LL, 
     &                        NBPASS, NHPASS ) 
        ELSE
         WRITE ( LUTERM_OUT, 115 )
         WRITE ( LUAOU, 115 )                                                
  115    FORMAT ( '0 Logic error in Sub HBPLAY. Program terminated.' )      
         STOP ' STOP 42 in Subroutine HBPLAY '                                                            
        END IF
   30  CONTINUE
       J1 = J2 + I_1                                                    
   20 CONTINUE                                                            
!C
      RETURN                                                              
      END                                                                 
