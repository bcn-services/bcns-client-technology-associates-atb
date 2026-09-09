      SUBROUTINE INPUT_SEG_SEG_FORCE                                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Input Cards F.3 specifying the allowed contacts of the crash    
!C    victim body segments with other body segments along with the 
!C    associated functions to be used for each contact.                                                       
!C    Also sets up tables to control time history information for         
!C    each function for each allowed contact,                     
!C                                                                        
!C    This subroutine is called only by Subroutine INPUT_FCARDS.
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &               NSEG, NGRND, NQ,                       ! /CONTRL/
     &               NOUTSS,                                ! /COUT/
     &               KQTYPE, KQ1, KQ2,                      ! /CSTRNT/
     &               MNSEG, MSEG, NTSEG,                    ! /JBARTZ/
     &               MXNTB, MXTB1, NTAB,                    ! /TABLES/
     &               KTITLE, MS_SEG, NF_FUNCT,              ! /CINPUT_TEMPVS/
     &               SEG,                                   ! structures
     &               ICHAR_STD, INTEGER_STD, LUAIN, LUAOU,  ! parameters
     &               I_0, I_1, I_4, I_10, I_18,  LULIN ,    ! parameters
     &               LOGICAL_STD, TRUE, FALSE, LIN_FLAG,    ! parameters
     &               AIN_CONVERT
!C
!C    NAME        ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) 
     &       I, J, J1, J2, JJ, K, LT, MC, N, NFJ, NJ, NJJ, NK, NLT, 
     &       NOUT, NREM, NSEG1
!C
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   2, KIND = ICHAR_STD )  AL2, ALEN2
      CHARACTER ( LEN =   4, KIND = ICHAR_STD )  BLANK
      CHARACTER ( LEN =  26, KIND = ICHAR_STD )  A_FRMT_26
      CHARACTER ( LEN =  27, KIND = ICHAR_STD )  A_FRMT_27
!C
      LOGICAL  ( KIND = LOGICAL_STD ) BEGIN_LOOP
!C
      DATA  BLANK / ICHAR_STD_'    ' /                                       
!C                                                                        
!C    Input allowed contacts and functions by ref. no.                    
!C                                                                        
!C                                                                        
!C    Input no. of segments to contact each segment.                   
!C     Input Card F.3.a                                                  
!C                                                                        
      N = NSEG / I_18
      NREM = MOD ( NSEG, I_18 )
      IF ( LIN_FLAG )  THEN
       IF ( N .NE. I_0 )  THEN 
        J1 = I_1
        J2 = I_18
        DO I=1,N
         READ ( LULIN, * ) ( MNSEG(J), J=J1,J2 )                
         J1 = J1 + I_18
         J2 = J2 + I_18
        END DO
        J1 = N * I_18 + I_1
        J2 = J1 + NREM - I_1
        IF ( NREM .NE. I_0 )  THEN
         READ ( LULIN, * ) ( MNSEG(J), J=J1,J2 )
        END IF
       ELSE
        READ ( LULIN, * ) ( MNSEG(J), J=1,NSEG )                
       END IF
      ELSE
       READ  ( LUAIN, 100 )  ( MNSEG(J), J=1,NSEG )                       
  100  FORMAT ( 18I4 )                                                   
       IF ( AIN_CONVERT )  THEN
!C
!C      Determine the number of F.3.a cards needed and the
!C       number of elements for a "non-full" card.
!C
        IF ( NREM .NE. I_0 )  THEN 
         IF ( NREM .LT. I_10 ) THEN
          WRITE ( ALEN1, 105 ) NREM
  105     FORMAT ( I1 )
          READ ( ALEN1, 110 ) AL1
  110     FORMAT ( A1 )
          A_FRMT_26 = '( 1X, ' // AL1 // '( I4, 1X ), 1X, A )'
         ELSE
          WRITE ( ALEN2, 115 ) NREM
  115     FORMAT ( I2 )
          READ ( ALEN2, 120 ) AL2
  120     FORMAT ( A2 )
          A_FRMT_27 = '( 1X, ' // AL2 // '( I4, 1X ), 1X, A )'
         END IF
        END IF
!C
!C      Write out the F.3.a cards with a variable number of elements.
!C
        IF ( N .NE. I_0 )  THEN
         J1 = I_1
         J2 = I_18
         DO I=1,N
          WRITE ( LULIN, 125 ) ( MNSEG(J), J=J1,J2 ), 'Card F.3.a'                
  125     FORMAT ( 1X, 18( I4, 1X ), 1X, A )                                                  
          J1 = J1 + I_18
          J2 = J2 + I_18
         END DO
         J1 = N * I_18 + I_1
         J2 = J1 + NREM - I_1
         IF ( NREM .NE. I_0 )  THEN
          IF ( NREM .LT. I_10 )  THEN
           WRITE ( LULIN, A_FRMT_26 ) ( MNSEG(J), J=J1,J2 ), 
     &                                'Card F.3.a'
          ELSE
           WRITE ( LULIN, A_FRMT_27 ) ( MNSEG(J), J=J1,J2 ), 
     &                                'Card F.3.a'
          END IF
         END IF
        ELSE
         IF ( NSEG .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_26 ) ( MNSEG(J), J=1,NSEG ), 
     &                               'Card F.3.a'
         ELSE
          WRITE ( LULIN, A_FRMT_27 ) ( MNSEG(J), J=1,NSEG ), 
     &                               'Card F.3.a'
         END IF
        END IF
       END IF
      END IF
!C
      NJJ = NSEG                                                        
      NSEG1 = NSEG + I_1                                              
      DO  J=NSEG1,NGRND                                                 
       MNSEG(J) = I_0                                               
      END DO
!C                                                                        
!C     Start of loop to read contacts for segments.       
!C                                                                        
      MC = I_0                                                     
      BEGIN_LOOP = TRUE                                                
      DO  J=1,NJJ                                                      
       NK = MNSEG(J)                               
       IF ( NK .LE. I_0 )  CYCLE                                    
!C
!C     Write header to output file for the seg-seg force functions.
!C
       IF ( BEGIN_LOOP )  THEN
        WRITE ( LUAOU, 130 )                      
  130   FORMAT ( '0', 119X, 'Cards F.3' )                             
        WRITE ( LUAOU, 135 )                                 
  135   FORMAT ( '0', 3X, ' Segment', 8X, 'Segment', 
     &           2X, 'Force Deflection',
     &           6X, 'Inertial Spike', 5X, 'R Factor', 8X, 'G Factor',
     &           5X, 'Friction Coef. Opt', 5X, 'Output' )               
        BEGIN_LOOP = FALSE
       END IF
!C
       DO  K=1,NK                                                      
!C                                                                        
!C      Input contact surface no., segment no., and function nos. from        
!C       Card F.3.b.                                             
!C                                                                        
        IF ( LIN_FLAG )  THEN
         READ  ( LULIN, * )  NJ, MS_SEG, NF_FUNCT, NOUT             
        ELSE
         READ  ( LUAIN, 140 )  NJ, MS_SEG, NF_FUNCT, NOUT             
  140    FORMAT ( 9I4, 4X, I4 )                                                   
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 145 )  NJ, MS_SEG, NF_FUNCT, NOUT,
     &                          'Cards F.3.b'             
  145     FORMAT ( 1X, 10( I4, 1X ), 1X, A )                                                   
         END IF
        END IF
!C
        WRITE ( LUAOU, 150 )  NJ, MS_SEG, NF_FUNCT, NOUT             
  150   FORMAT ( '0', I7, '-', I3, I11, '-', I3, I8, 4I16, I12 )   
        MC = MC + I_1                                               
        NOUTSS(MC) = NOUT                      
        IF ( NJ .NE. J ) THEN
         WRITE ( LUAOU, 155 )                                             
  155    FORMAT ( ' Contact input error. Program terminated.' )          
         STOP ' STOP 14 in Subroutine INPUT_SEG_SEG_FORCE '                                     
        END IF
        IF (  NF_FUNCT(5) .EQ. I_0  )  THEN
         WRITE ( LUAOU, 160 )  
  160    FORMAT ( ' Friction function number can not be zero for this '
     &            , 'type of contact.' )                                 
         STOP  ' STOP 105 in Subroutine INPUT_SEG_SEG_FORCE'
        END IF
        NLT = I_1                                                    
        DO  JJ = 1,31                                                    
         KTITLE(JJ) = BLANK                                              
        END DO
!C                                                                        
!C      Place segment no. and index to NTAB array into M- and 
!C       NT- arrays. 
!C                                                                        
        MSEG(1,K,J) = MS_SEG(1)                                         
        MSEG(2,K,J) = MS_SEG(2)                                         
        MSEG(3,K,J) = MS_SEG(3)                                         
        NTSEG(K,J) = MXNTB + I_1                                      
        KTITLE (3) = SEG(J)%NAME                                        
!C                                                                        
!C      Set up pointers to TAB array in NTAB array.                      
!C                                                                        
        NFJ = MS_SEG(2)                                                  
        IF ( NFJ .GT. I_0 )  KTITLE(6) = SEG(NFJ)%NAME                      
        DO  JJ=1,NLT                                                     
         CALL FDINIT ( I_1 )                                        
        END DO
        WRITE ( LUAOU, 165 )  KTITLE                                      
  165   FORMAT ( 1X, 5A4, 1X, A4, 5( 1X, 5A4 ) )                         
        LT = NTAB(MXNTB-5)                                                 
!C                                                                        
!C      If force deflection function no. is zero,                       
!C        set up for rolling constraint.                                   
!C                                                                        
        IF  ( NF_FUNCT(1) .EQ. I_0 )  THEN                              
         NQ = NQ + I_1                                               
         NTAB(MXNTB-4) = -NQ                                             
         KQTYPE(NQ) = -I_4                                           
         KQ1(NQ) = MS_SEG(2)                                             
         KQ2(NQ) = MS_SEG(1)                                             
         KQ1(NQ) = J                                                    
         KQ2(NQ) = MS_SEG(2)                                           
        END IF
       END DO                                                          
      END DO                                                          
!C
      RETURN                                                              
      END                                                                 
