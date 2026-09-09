      SUBROUTINE U1OLD                                                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine replaces the program code that previously was        
!C    near the end of the MAIN program to write on UNIT 1 that data        
!C    used for various plotting programs (e.g. bubble man plot).           
!C                                                                         
!C    This subroutine is written to generate UNIT 1 in such a manner       
!C    to be compatible with the input requirements for the AAMRL VIEW      
!C    Program that is now being distributed on the CVS program tapes.      
!C                                                                         
!C    Arguments:                                                           
!C         IND = 0: call is from the MAIN program                          
!C             # 0: call is from Subroutine EQUILB                         
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:  
     &       BD, PL,                                 ! /CNTSRF/
     &       NHRNSS, NPL, NPRT, NSEG, TIME,          ! /CONTRL/
     &       BAR, IBAR, NBLTPH, NL, NPTPLY, NPTSPB,  ! /HRNESS/
     &       MPL,                                    ! /JBARTZ/
     &       SEG,                                    ! structures
     &       INTEGER_STD, IREAL_HIGH, IREAL_STD,     ! parameters
     &       LUVIEW, MAXELP, MAXPLN, MAXSEG,         ! parameters
     &       D_0, I_0, I_1, I_2                      ! parameters
!C
!C    DIR_COS, DRC_PHI, LIN_DISP, ROT_PHI    ! SEG%
!C
      USE  MODULE_WATER,  ONLY:
     &       BDPFD, KPFD, NELPFD, NUM_PER_FLOAT_DEV, NWATER, ! /WATINF1/
     &       FREQ, NWAVES, WAMP, WD, WDEP, WDIR, WNUM,       ! /WAVEDAT/
     &       WOFSET, WPHS                                    ! /WAVEDAT/
     
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, IFIRST, IMPL, J, K, KS, NTEPFD, NTOBLT, NTOPTS 
      DIMENSION  IMPL(3,5,MAXPLN)
!C
      REAL  ( KIND = IREAL_HIGH )   T3, T4, T5
      DIMENSION         T3(3,3), T4(3), T5(3)
!C
      REAL   ( KIND = IREAL_STD )
     &           XTIME, XD, XSEGLP, XPL, XBD, XBAR, XWOF, XWD,
     &           XWDEP, XWNUM, XWAMP, XWDIR, XWPHS, XFREQ, XBDPFD       
      DIMENSION  XD(3,3,MAXSEG), XSEGLP(3,MAXSEG), XPL(17,MAXPLN),      
     &           XBD(24,MAXELP), XBAR(9,100), XWOF(3), XWD(3,3),
     &           XWNUM(10), XWAMP(10), XWDIR(10), 
     &           XWPHS(10), XFREQ(10), XBDPFD(30,25)                    
!C
      REAL ( KIND = IREAL_STD ) CHECK_HIGH_VALUE
      EXTERNAL  CHECK_HIGH_VALUE
!C
      DATA  IFIRST / I_0 /                           
!C
      SAVE  IFIRST
!C
      IF  ( NPRT(1) .EQ. I_0 )   THEN                                  
       RETURN
      END IF
      IF  ( IFIRST .EQ. I_0 )  THEN                                    
       IFIRST = I_1                                                     
!C                                                                        
!C     First time in routine, write static data on output UNIT 1.          
!C     Data must be converted to single precision for VIEW Program.        
!C                                                                         
       DO  J=1,MAXPLN                                                      
        DO  I=1,17                                                       
         XPL(I,J) = CHECK_HIGH_VALUE ( PL(I,J) )                          
        END DO
       END DO
       DO  J=1,MAXELP                                                        
        K = I_1                                                          
        IF ( BD(1,J) .LT. D_0 )   K = I_2                       
        DO  I=1,23                                                        
         XBD(I,J) = CHECK_HIGH_VALUE ( BD(K,J)  )                          
         K = K + I_1                                                     
        END DO
        XBD(24,J) = D_0                                       
       END DO
       DO  J=1,MAXPLN                                                     
        DO  I=1,5                                                         
         IMPL(1,I,J) = MPL(1,I,J)                                         
         IMPL(2,I,J) = MPL(2,I,J)                                         
         IMPL(3,I,J) = ABS ( MPL(3,I,J) )                           
        END DO
       END DO                                                            
!C
       IF ( NPRT(35) .EQ. I_1 )  THEN                                       
        WRITE ( LUVIEW )  NSEG, NPL, XPL, XBD, IMPL                                                                                                 WFAC
       ELSE                                                                  
        WRITE  ( LUVIEW, * )  NSEG, NPL, XPL, XBD, IMPL                      
!C
!C     Write out the harness data.
!C
        NTOBLT = I_0                                                   
        DO  I=1,NHRNSS                                                    
         NTOBLT = NTOBLT + NBLTPH(I)                                      
        END DO
        NTOPTS = I_0                                                  
        DO  I=1,NTOBLT                                                   
         NTOPTS = NTOPTS + NPTSPB(I)                                      
        END DO
        WRITE ( LUVIEW, * ) NHRNSS, NTOBLT, NTOPTS                           
        WRITE ( LUVIEW, * )  ( NBLTPH(I), I=1,NHRNSS ), 
     &                       ( NPTSPB(I), I=1,NTOBLT ),                       
     &                       ( ( IBAR(I,J), I=1,2 ), J=1,NTOPTS )         
       END IF
!C                                                                      
       IF ( NWATER .EQ. I_0 )  THEN                                                                                                           WFAC
        RETURN                                                              
       ELSE
!C                                                                      
!C      Write information for water forces                              
!C                                                                      
        NTEPFD = I_0                                                    
        IF ( NUM_PER_FLOAT_DEV .GT. I_0 )  THEN
         DO  I = 1,NUM_PER_FLOAT_DEV                                                   
          NTEPFD = NTEPFD + NELPFD(I)                                     
         END DO
        END IF
        IF ( NPRT(35) .EQ. I_1 ) THEN                                 
         WRITE ( LUVIEW ) NWATER, NWAVES, NUM_PER_FLOAT_DEV, NTEPFD                   
        ELSE                                                            
         WRITE ( LUVIEW, * ) NWATER, NWAVES, NUM_PER_FLOAT_DEV, NTEPFD               
        END IF                                                          
        XWDEP = WDEP                                                      
        DO  I = 1,3                                                      
         XWOF(I) = CHECK_HIGH_VALUE ( WOFSET(I) )                        
         DO  J = 1,3                                                     
          XWD(J,I) = CHECK_HIGH_VALUE ( WD(J,I) )                     
         END DO
        END DO
        DO  I = 1,NWAVES                                                 
         XWNUM(I) = CHECK_HIGH_VALUE ( WNUM(I) )                         
         XWAMP(I) = CHECK_HIGH_VALUE ( WAMP(I) )                          
         XWDIR(I) = CHECK_HIGH_VALUE ( WDIR(I) )                           
         XWPHS(I) = CHECK_HIGH_VALUE ( WPHS(I) )                        
         XFREQ(I) = CHECK_HIGH_VALUE ( FREQ(I) )                        
        END DO                                                           
        IF ( NUM_PER_FLOAT_DEV .GT. I_0 )  THEN
         DO  I = 1,NTEPFD                                                
          DO  J = 1,30                                                    
           XBDPFD(J,I) = CHECK_HIGH_VALUE ( BDPFD(J,I) )               
          END DO
         END DO
        END IF
        IF ( NPRT(35) .EQ. I_1 )  THEN                                 
         WRITE ( LUVIEW ) XWOF, XWD, XWDEP, ( XWNUM(I), I=1,NWAVES ),     
     &                                      ( XWAMP(I), I=1,NWAVES ),
     &                                      ( XWDIR(I), I=1,NWAVES ),     
     &                                      ( XWPHS(I), I=1,NWAVES ),
     &                                      ( XFREQ(I), I=1,NWAVES )     
         IF ( NUM_PER_FLOAT_DEV .GT. I_0 )  THEN
          WRITE ( LUVIEW )  ( NELPFD(I), I=1,NUM_PER_FLOAT_DEV ),
     &                      ( KPFD(I),   I=1,NTEPFD ),                     
     &                    ( ( XBDPFD(J,I), J=1,30 ), I=1,NTEPFD )         
         END IF
        ELSE                                                            
         WRITE ( LUVIEW, * )  XWOF, XWD, XWDEP,
     &                        ( XWNUM(I), I=1,NWAVES ),   
     &                        ( XWAMP(I), I=1,NWAVES ),
     &                        ( XWDIR(I), I=1,NWAVES ),    
     &                        ( XWPHS(I), I=1,NWAVES ), 
     &                        ( XFREQ(I), I=1,NWAVES )    
         IF ( NUM_PER_FLOAT_DEV .GT. I_0 )  THEN
          WRITE ( LUVIEW, * )  ( NELPFD(I), I=1,NUM_PER_FLOAT_DEV ),
     &                         ( KPFD(I), I=1,NTEPFD ),                  
     &                       ( ( XBDPFD(J,I), J=1,30 ), I=1,NTEPFD )     
         END IF
        END IF                                                          
       END IF
      ELSE                                                              
!C                                                                        
!C     Write time point data on output UNIT 1.                             
!C     Data must be converted to single precision for VIEW Program.        
!C                                                                        
       XTIME = TIME                                                       
       DO  K=1,MAXSEG                                                      
        DO  J=1,3                                                          
         DO  I=1,3                                                         
          XD(I,J,K) = CHECK_HIGH_VALUE ( SEG(K)%DIR_COS(I,J) )                            
         END DO
         XSEGLP(J,K) = CHECK_HIGH_VALUE ( SEG(K)%LIN_DISP(J) )                         
        END DO
       END DO
       DO  K=1,NSEG                                                       
        IF  ( .NOT. SEG(K)%ROT_PHI )  THEN
         CYCLE                                                            
        ELSE
         CALL DOT33 ( SEG(K)%DRC_PHI, SEG(K)%DIR_COS, T3 )                   
         DO  I=1,3                                                        
          DO  J=1,3                                                        
            XD(I,J,K) = CHECK_HIGH_VALUE ( T3(I,J) )                      
          END DO
         END DO
        END IF
       END DO
       IF ( NPRT(35) .EQ. I_1 )  THEN                                      
        WRITE ( LUVIEW ) XTIME, XSEGLP, XD                                    
        RETURN                                                            
       ELSE                                                                  
        WRITE ( LUVIEW, * )  XTIME, XSEGLP, XD                               
       END IF                                                                 
       IF ( NPRT(35) .EQ. I_1 ) THEN
        RETURN
       END IF                                                             
       NTOBLT = I_0                                                   
       DO  I=1,5                                                          
        NTOBLT = NTOBLT + NBLTPH(I)                                      
       END DO
       NTOPTS = I_0                                                   
       DO  I=1,NTOBLT                                                    
        NTOPTS = NTOPTS + NPTSPB(I)                                       
       END DO
       DO  I = 1,9                                                        
        DO  J = 1,NTOPTS                                                 
         XBAR(I,J) = CHECK_HIGH_VALUE ( BAR(I,J) )                        
        END DO
       END DO
       DO  K = 1,NTOPTS                                                   
        KS = IBAR(1,K)                                                    
        IF ( KS .EQ. I_0 ) THEN
         CYCLE                                                            
        ELSE IF ( .NOT. SEG(KS)%ROT_PHI )  THEN                        
         CYCLE
        END IF
        CALL DOT31 ( SEG(KS)%DRC_PHI, BAR(4,K), T4 )                   
        CALL DOT31 ( SEG(KS)%DRC_PHI, BAR(7,K), T5 )                   
        DO  I = 1,3                                                       
         XBAR(I+3,K) = CHECK_HIGH_VALUE ( T4(I) )                         
         XBAR(I+6,K) = CHECK_HIGH_VALUE ( T5(I) )                        
        END DO
       END DO                                                             
       WRITE ( LUVIEW, * )  ( ( XBAR(I,J), I=1,9 ), J=1,NTOPTS ),
     &                    ( ( NL(I,J), I=1,2 ), J=1,NTOPTS ),
     &                      ( NPTPLY(I), I=1,NTOBLT )                     
      END IF  
!C
      RETURN                                                              
      END                                                                 
