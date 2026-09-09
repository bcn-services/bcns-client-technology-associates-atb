      SUBROUTINE  OUTPUT_SETUP ( LINES, LTAPE8, LTHIST, LTABH )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine sets up the files for output for
!C     tabular time histories, Tape 8 output, or both.
!C    It is called only by Subroutine OUTPUT.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NRTORQ,                                              ! /ACTFR/
     &       UNITL,  UNITM, UNITT,                                ! /CNSNTS/
     &       NBAG, NBLT, NGRND, NHRNSS, NJNT, NPL, NPRT, NSD,     ! /CONTRL/
     &       NSEG, NVEH,                                          ! /CONTRL/
     &       NOUTPS, NOUTSS,                                      ! /COUT/  
     &       MSDM, MSDN,                                          ! /DAMPER/
     &       WORK_DIRECTORY, OUTFIL,                              ! /FILEN/, new
     &       NPANEL,                                              ! /FORCES/
     &       NBLTPH, NPTSPB,                                      ! /HRNESS/
     &       MBAG, MBLT, MNBAG, MNBLT, MNPL, MNSEG, MPL, MSEG,    ! /JBARTZ/ 
     &       KREF, MCG, MCGIN, MJS, MSG, NSG, XSG,                ! /RSAVE/
     &       BAGTTL, BDYTTL, BLTTTL, COMENT, DATE, PLTTL, VPSTTL, ! /TITLES/ 
     &       SEG, JNT,                                            ! structures
     &       ICHAR_STD, INTEGER_STD, LOGICAL_STD, I_0,            ! parameters 
     &       LUTP8, MAX_LN_PPAGE, NUM_TTH_OFFSET, LUTERM_OUT      ! parameters
!C
!C    NAME       ! SEG%
!C    JNT_NAME   ! JNT%
!C
      USE  MODULE_WATER,   ONLY:
     &       NUM_ELLIP_WATER_CT, NWATER,     ! /WATINF1/
     &       ITYPE, NELL, NELOUT, NSEQN      ! /WFACOP/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )   I, J, JRNUM,
     &                                   K, LINES, NT
!C
      CHARACTER  ( LEN =   3, KIND = ICHAR_STD )  
     &        CHAR_NT, FL_CONVERT, CHAR_NT_LEFT  
      CHARACTER  ( LEN =   4, KIND = ICHAR_STD )  EXT                    
      CHARACTER  ( LEN = 116, KIND = ICHAR_STD )  TTHFIL                
!C
      CHARACTER  ( LEN = 116, KIND = ICHAR_STD )  FNAME                          
      EXTERNAL         FNAME
!C
      LOGICAL  LTAPE8, LTHIST, LTABH
!C
      INTENT ( IN )  LINES, LTAPE8, LTHIST, LTABH 
!C
!C    Call Subroutine INPUT_HCARDS to read in the H Cards, except
!C     for the postprocessing information used by Subroutine
!C     POSTPR.
!C
      CALL INPUT_HCARDS ( JRNUM )
!C                                                                      
!C    If there are to be individual tabular time history files
!C     ( LTHIST = .true. ), first check to be sure that the
!C     tabular time histories for the HCARDS has not exceeded
!C     the maximum, then call Subroutine OPEN_TTH to open them.
!C
      IF ( LTHIST )   THEN                                              
!C                                                                      
!C     Compute the number of tabular time history files needed
!C      for the H Card output.
!C
       CALL LUNUM_HCARDS ( JRNUM, NT )
!C
!C     Compute the tabular time history files needed for the 
!C      forces.
!C
       CALL LUNUM_FORCES ( NT )
!C                                                                      
!C    Open the files for the individual logical units.
!C
       DO  I = (NUM_TTH_OFFSET+1),NT                                    
!C                                                                      
!C      Convert the integer counter to a character for the extension.
!C
        WRITE ( FL_CONVERT, 105 ) I
  105   FORMAT ( I3 )
        READ ( FL_CONVERT, 110 ) CHAR_NT
  110   FORMAT ( A3 )
        CHAR_NT_LEFT = ADJUSTL(CHAR_NT)
        IF ( I .LE. 99 ) THEN
         EXT = '.t' // CHAR_NT_LEFT(1:2)
        ELSE
         EXT = 't' // CHAR_NT_LEFT
        END IF                                           
        TTHFIL = FNAME ( WORK_DIRECTORY, OUTFIL, EXT )                 
!C                                                                      
!C      Open the Ith tabular time history file.
!C
        OPEN ( I, FILE = TTHFIL, STATUS = 'UNKNOWN', ERR = 30,         
     &         ACCESS = 'SEQUENTIAL', FORM = 'FORMATTED' )              
       END DO
!C
!C     ?? Call Subroutine HEDING to print the initial and
!C      only heading for each of the tabular time history files.
!C
       IF ( NPRT(19) .NE. I_0 )   THEN
        CALL HEDING ( LINES, MAX_LN_PPAGE )  
       END IF
      END IF                                                            
!C
      IF ( LTABH ) THEN
       CALL LUNUM_FORCES ( NT )
      END IF

!C    Print out the filenames used for this simulation.
!C
      CALL OUTPUT_LUNUM ( LTHIST )
!C
!C    If Tape8 is to be used ( LTAPE8 = .true. ), write all the 
!C     initial data to it in unformatted form.
!C
      IF  ( LTAPE8 )   THEN                                             
       WRITE  ( LUTP8 )  NSEG, NJNT, NPL, NBLT, NBAG, NVEH, NGRND,        
     &                   NPANEL, MNPL, MNBLT, MNSEG, MNBAG, MPL, MBLT,    
     &                   MSEG, MBAG, NOUTPS, NOUTSS                     
       IF ( ( NWATER .EQ. I_0 ) .AND. ( NRTORQ .EQ. I_0 ) )   THEN  
        WRITE  ( LUTP8 ) DATE, COMENT, VPSTTL, BDYTTL, BLTTTL, PLTTL,
     &                   BAGTTL, SEG%NAME, JNT%JNT_NAME, UNITL, UNITM,
     &                   UNITT, NSG,
     &                   MSG, XSG, MCG, MCGIN, KREF, NHRNSS, NBLTPH,
     &                   NPTSPB, NSD, MSDM, MSDN                          
       ELSE IF ( NRTORQ .GT. I_0 )   THEN                            
        WRITE  ( LUTP8 ) DATE, COMENT, VPSTTL, BDYTTL, BLTTTL, PLTTL,
     &                   BAGTTL, SEG%NAME, JNT%JNT_NAME, UNITL, UNITM,  
     &                   UNITT, NSG,
     &                   MSG, XSG, MCG, MJS, MCGIN, KREF, NHRNSS,
     &                   NBLTPH, NPTSPB, NSD, MSDM, MSDN                  
       ELSE                                                             
        WRITE  ( LUTP8 ) DATE, COMENT, VPSTTL, BDYTTL, BLTTTL, PLTTL,
     &                   BAGTTL, SEG%NAME, JNT%JNT_NAME, UNITL, UNITM,  
     &                   UNITT, NSG,
     &                   MSG, XSG, MCG, MCGIN, KREF, NHRNSS, NBLTPH,
     &                   NPTSPB, NSD, MSDM, MSDN, NUM_ELLIP_WATER_CT, 
     &                   NELL, ITYPE, NSEQN, 
     &         ( ( ( NELOUT(K,J,I), I=1,NELL(K) ), J=1,2 ), K=1,NSEQN )  
       END IF                                                           
      END IF
!C
      RETURN
!C
!C    File handling error messages.
!C
   30 WRITE ( LUTERM_OUT, 330 )  TTHFIL
  330 FORMAT ( 1X, ' Error opening file: ', A116 )
      STOP ' STOP 435 in Subroutine OUTPUT_SETUP '
!C
      END
      