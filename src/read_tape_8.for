      SUBROUTINE READ_TAPE_8 ( PRDT, LPP, NDPT, NPTS, LNUM_TTH, LTABH, 
     &                         JDTPTS, Z_LCL, ZM_LCL )
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in data from the Tape 8 file.  The
!C     was created from the original POSTPR subroutine.
!C
!C    Arguments:
!C
!C        PRDT      = the time increment used to output the data
!C        LPP       = number of lines of tabular time history data per
!C                     page of output
!C        NDPT      = number of specified points for which injury criteria
!C                     are to be computed
!C        NPTS      = number of data points to be used to compute the 
!C                     injury criteria
!C        LNUM_TTH  = current line number of the tabular time histories
!C        LTABH     = logical flag, if true, tabular time history files
!C                     are to be printed
!C        JDTPTS(1) = the number of points for which the HIC and HSI are
!C                     to be computed
!C        JDTPTS(2) = the number of points for which the CSI is to be 
!C                     computed
!C        Z_LCL     = array containing the data to be used to compute
!C                     the injury criteria
!C        ZM_LCL  =	array containing longitudinal and lateral head acceleration
!C                     data used to compute MSC.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       NRTORQ,                                           ! /ACTFR/
     &       EPS, UNITL, UNITM, UNITT,                         ! /CNSNTS/
     &       NBAG, NBLT, NGRND, NHRNSS, NJNT, NPG, NPL,        ! /CONTRL/
     &       NPRT, NSD, NSEG, NVEH,                            ! /CONTRL/
     &       NOUTPS, NOUTSS,                                   ! /COUT/
     &       MSDM, MSDN,                                       ! /DAMPER/
     &       NPANEL,                                           ! /FORCES/
     &       NBLTPH, NPTSPB,                                   ! /HRNESS/
     &       MBAG, MBLT, MNBAG, MNBLT, MNPL, MNSEG, MPL, MSEG, ! /JBARTZ/
     &       KREF, MCG, MCGIN, MJS, MSG, NSG, XSG,             ! /RSAVE/
     &       BAGTTL, BDYTTL, BLTTTL, COMENT, DATE,             ! /TITLES/
     &       PLTTL, VPSTTL,                                    ! /TITLES/
     &       TDATA, USEC, ZTTH,                                ! /HEDING_TEMPVS/
     &       SEG, JNT,                                         ! structures
     &       INTEGER_STD, IREAL_HIGH, IREAL_STD, LOGICAL_STD,  ! parameters
     &       LUAIN, LUAOU, LUTP8, MXHIC, NUM_TTH_OFFSET,       ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, R_0                 ! parameters
!C
!C    NAME,      ! SEG%
!C    JNT_NAME   ! JNT%
!C
      USE  MODULE_WATER,  ONLY:
     &       NUM_ELLIP_WATER_CT, NWATER,  ! /WATINF1/
     &       ITYPE, NELL, NELOUT, NSEQN   ! /WFACOP/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, J, JD, JDTPTS, JE, JJ, JP, K,
     &          LINES, LPP, NDPT, NPTS, NT, LNUM_TTH, IT  
!C
      DIMENSION  JDTPTS(2)                            
!C
      REAL   ( KIND = IREAL_STD ) Z_LCL, ZM_LCL
      DIMENSION   Z_LCL(MXHIC,3), ZM_LCL(MXHIC,3)         
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  PRDT, TEST1, TEST2, UMSEC, VDT1, VDT2
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTABH                                
!C
      INTENT ( IN  )   PRDT, LPP, LTABH, NDPT, JDTPTS
      INTENT ( OUT )   NPTS, Z_LCL, LNUM_TTH
!C
!C                                                                        
!C    Read time history data from TAPE 8 (LUTP8).                               
!C                                                                        
      NPTS = I_0                                                     
      LINES = I_0                                                     
!C
!C    Only initialize the array to store the data to be used
!C     for the injury criteria if the injury criteria are to be
!C     computed, otherwise the array is not defined because it
!C     was not allocated in the calling subroutine.
!C
      IF ( NDPT .NE. I_0 )  THEN
       Z_LCL = R_0
       ZM_LCL = R_0
      END IF
!C
!C    If  ( NPRT(4) .GT. 0 )  rewind LUTP8                                        
!C
      REWIND ( UNIT = LUTP8 )                                                          
!C
!C    Read in all the control data from the unformatted
!C     Tape 8 file.
!C
      READ  ( LUTP8, END=20 )  NSEG, NJNT, NPL, NBLT, NBAG, NVEH, NGRND,
     &                         NPANEL, MNPL, MNBLT, MNSEG, MNBAG, MPL,
     &                         MBLT, MSEG, MBAG, NOUTPS, NOUTSS           
!C
      IF ( ( NWATER .EQ. I_0 ) .AND. ( NRTORQ .LE. I_0 ) ) THEN         
       READ  ( LUTP8, END=20 )  DATE, COMENT, VPSTTL, BDYTTL, BLTTTL,
     &                          PLTTL,BAGTTL, SEG%NAME, JNT%JNT_NAME, 
     &                          UNITL, UNITM,
     &                          UNITT, NSG, MSG, XSG, MCG, MCGIN, KREF,
     &                          NHRNSS, NBLTPH, NPTSPB, NSD, MSDM, MSDN    
      ELSE IF ( NRTORQ .GT. I_0 )  THEN                           
       READ  ( LUTP8, END=20 )  DATE, COMENT, VPSTTL, BDYTTL, BLTTTL,
     &                          PLTTL, BAGTTL, SEG%NAME, JNT%JNT_NAME, 
     &                          UNITL, UNITM,
     &                          UNITT, NSG, MSG, XSG, MCG, MJS, MCGIN,
     &                          KREF, NHRNSS, NBLTPH, NPTSPB, NSD, 
     &                          MSDM, MSDN                                
      ELSE                                                                
       READ  ( LUTP8, END=20 )  DATE, COMENT, VPSTTL, BDYTTL, BLTTTL,
     &                          PLTTL, BAGTTL, SEG%NAME, JNT%JNT_NAME, 
     &                          UNITL, UNITM,
     &                          UNITT, NSG, MSG, XSG, MCG, MCGIN, KREF,
     &                          NHRNSS, NBLTPH, NPTSPB, NSD, MSDM, MSDN,   
     &                          NUM_ELLIP_WATER_CT, NELL, ITYPE, NSEQN,                
     &                          ( ( ( NELOUT(K,J,I), I=1,NELL(K) ),
     &                                 J=1,2 ), K=1,NSEQN )               
      END IF                                                            
!C
!C    Compute the parameters to test whether to skip over time
!C     points for the injury criteria, as specified by NPRT(30).
!C
      IF ( NPRT(30) .GT. I_0 )  THEN
       VDT1 = REAL ( NPRT(30), IREAL_HIGH ) * PRDT      
      ELSE
       VDT1 = PRDT
      END IF
!C
!C    Compute the parameters to test whether to skip over time
!C     points for the frequency of output, as contolled by NPRT(26).
!C
      IF ( NPRT(26) .LT. I_0 )  THEN
       VDT2 = REAL ( ABS ( NPRT(26) ), IREAL_HIGH ) * PRDT                                            
      ELSE
       VDT2 = PRDT
      END IF
!C
      IF ( LTABH ) THEN
!C     Compute the number of tabular time history files needed
!C     for the H Card output.  Supply JRNUM=I_0 for normal nondeformable 
!C     segments  
!C
       IT = NUM_TTH_OFFSET
       CALL LUNUM_HCARDS ( I_0, IT )
!C
!C     Compute the tabular time history files needed for the 
!C     forces.
!C
       CALL LUNUM_FORCES ( IT )
      END IF
!C    Read in the tabular time history data from the unformatted
!C     Tape 8 file.
!C
      DO
       READ ( LUTP8, END=20 )  NT, UMSEC, 
     &                         ( ( TDATA(I,J), I=1,14 ), J=1,NT )          
       TEST1 = MOD ( UMSEC, VDT1 )                                         
       TEST1 = MIN ( TEST1, ABS ( VDT1 - TEST1 ) )                         
       IF ( ( NPRT(30) .GT. I_0 ) .AND. 
     &      ( TEST1 .GT. EPS(4) ) ) THEN  
!C                                                                        
!C      Store data to print tabular time histories in primary output 
!C       for the case when not all tabular time history points will
!C       be used in the injury criteria computations.      
!C                                                                         
        IF  ( LTABH )  THEN                                     
         TEST2 = MOD ( UMSEC, VDT2 )                                        
         TEST2 = MIN ( TEST2, ABS ( VDT2 - TEST2 ) )                        
         IF  ( ( NPRT(26) .LE. I_0 ) .AND. 
     &         ( TEST2 .GT. EPS(4) ) )  CYCLE 
         LINES = LINES + I_1                                             
         LNUM_TTH = MOD ( ( LINES - I_1 ), LPP ) + I_1                 
         USEC(LNUM_TTH) = UMSEC                                                  
         DO  J=1,NT                                                          
          DO  I=1,14                                                        
           ZTTH(I,LNUM_TTH,J) = TDATA(I,J)                                      
          END DO
         END DO
         IF  ( LNUM_TTH .EQ. LPP )  CALL HEDING ( LINES, LPP )                  
        END IF
        CYCLE                                                          
       END IF
!C
       NPTS = NPTS + I_1                                                
       IF   ( ( NPTS .GT. MXHIC ) .AND. ( NDPT .NE. I_0 ) ) STOP 52     
!C
       IF  ( NDPT .NE. I_0 )   THEN                                    
!C                                                                       
!C      Store data for HIC, HSI, CSI, and MSC.                                   
!C                                                                        
        IF ( JDTPTS(1) .GT. I_0 )	THEN
          ZM_LCL(NPTS,1) = UMSEC * 0.001
          JD = JDTPTS(1) - I_1
          JE = I_4 * MOD (JD, I_3) + I_1
          JP = JD / I_3 + I_1
          ZM_LCL(NPTS, 2) = TDATA(JE, JP) 
          ZM_LCL(NPTS, 3) = TDATA(JE + 1, JP) 
        END IF                                                 
        Z_LCL(NPTS,1) = UMSEC 
        JJ = I_1                                                         
        DO  I=1,2                                                          
         IF  ( JDTPTS(I) .EQ. I_0 )  CYCLE                           
         JJ = JJ + I_1                                                  
         JD = JDTPTS(I) - I_1                                           
         JE = I_4 * MOD ( JD, I_3 ) + I_4                            
         JP = JD / I_3 + I_1                                         
         Z_LCL(NPTS,JJ) = TDATA(JE,JP)                                        
        END DO 
       END IF
!C                                                                       
!C     Store data to print tabular time histories in primary output when
!C      data points are not being skipped for the computatin of the 
!C      injury criteria.      
!C                                                                        
       IF  ( LTABH )  THEN                                     
        TEST2 = MOD ( UMSEC, VDT2 )                                        
        TEST2 = MIN ( TEST2, ABS ( VDT2 - TEST2 ) )                        
        IF  ( ( NPRT(26) .LE. I_0 ) .AND. 
     &        ( TEST2 .GT. EPS(4) ) )  CYCLE 
        LINES = LINES + I_1                                             
        LNUM_TTH = MOD ( ( LINES - I_1 ), LPP ) + I_1                 
        USEC(LNUM_TTH) = UMSEC                                                  
        DO  J=1,NT                                                          
         DO  I=1,14                                                        
          ZTTH(I,LNUM_TTH,J) = TDATA(I,J)                                      
         END DO
        END DO
!C
!C      If a full page of data has been reached, print it out.
!C
        IF  ( LNUM_TTH .EQ. LPP )  CALL HEDING ( LINES, LPP )                  
       END IF
      END DO
!C
!C    Print out any remaining lines of tabular time history data that
!C     were not enough to make a full page.
!C
   20 CONTINUE
      IF ( LTABH )  THEN
       CALL HEDING ( LINES, LPP )
      END IF
!C
      RETURN
!C
      END