      SUBROUTINE  INPUT_BELT_FORCE                                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Input Cards F.1-F.4 specifying the allowed contacts of the crash    
!C    victim body segments with vehicle panels, belts, airbags and other  
!C    body segments along with the associated functions to be used for    
!C    each contact.                                                       
!C    Also sets up tables to control time history information for         
!C    each function for each allowed contact, as well as inputting
!C    the airbag and wind force functions.                       
!C                                                                        
!C    This subroutine is called only by Subroutine INITIALIZE.
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:
     &               NPG, NBLT,                             ! /CONTRL/
     &               NQ,                                    ! /CONTRL/
     &               KQTYPE, KQ1, KQ2,                      ! /CSTRNT/
     &               MNBLT, MNSEG, MBLT, NTBLT,             ! /JBARTZ/
     &               MXNTB, NTAB,                           ! /TABLES/
     &               KTITLE, MS_SEG, NF_FUNCT,              ! /CINPUT_TEMPVS/
     &               BLTTTL,                                ! /TITLES/
     &               SEG,                                   ! structures
     &               ICHAR_STD, INTEGER_STD, LUAIN, LUAOU,  ! parameters
     &               I_0, I_1, I_2, I_4, AIN_CONVERT,       ! parameters
     &               LOGICAL_STD, TRUE, FALSE, LULIN,       ! parameters
     &               LIN_FLAG                               ! parameters
!C
!C    NAME        ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) 
     &         J, JJ, K, LT, MC, NFJ, NJ, NJJ, NK, NLT, NOUT, NX
!C
      CHARACTER ( LEN =   1, KIND = ICHAR_STD )  AL1, ALEN1
      CHARACTER ( LEN =   4, KIND = ICHAR_STD )  BLANK
      CHARACTER ( LEN =  26, KIND = ICHAR_STD )  A_FRMT_26
!C
      LOGICAL  ( KIND = LOGICAL_STD ) BEGIN_LOOP
!C
      DATA  BLANK / ICHAR_STD_'    ' /                                       
!C                                                                    
!C    Input no. of segments to contact each belt.                     
!C     Input Card F.2.a                                                
!C                                                                      
      IF ( LIN_FLAG )  THEN
       READ  ( LULIN, * )  ( MNBLT(J), J=1,NBLT )                      
      ELSE
       READ  ( LUAIN, 100 )  ( MNBLT(J), J=1,NBLT )                      
  100  FORMAT (  8I4 )                                                
       IF ( AIN_CONVERT )  THEN
!C
!C      Compute the number of output files.  Note that
!C       the logic must be changed if the current program
!C       limit of 8 belts is changed to > 9.
!C
        WRITE ( ALEN1, 105 ) NBLT
  105   FORMAT ( I1 )
        READ ( ALEN1, 110 ) AL1
  110   FORMAT ( A1 )
          A_FRMT_26 = '( 1X, ' // AL1 // '( I4, 1X ), 1X, A )'
        WRITE  ( LULIN, A_FRMT_26 )  
     &                  ( MNBLT(J), J=1,NBLT ),  'Card F.2.a'                    
       END IF
      END IF
      NJJ = NBLT                                                      
!C                                                                      
!C    Read contacts for belts.   
!C                                                                      
      MC = I_0                                                     
      BEGIN_LOOP = TRUE                                                
      DO  J=1,NJJ                                                   
       NK = MNBLT(J)                             
       IF ( NK .LE. I_0 )  CYCLE                                    
!C
!C     Write header for the belt forces to the standard output file.
!C
       IF ( BEGIN_LOOP )  THEN
        WRITE ( LUAOU, 115 )                      
  115   FORMAT ( '0', 119X, 'Cards F.2'  )                           
        WRITE ( LUAOU, 120 )                                  
  120   FORMAT ( '0', 3X, '  Belt  ', 8X, 'Segment', 
     &           2X, 'Force Deflection',
     &           6X, 'Inertial Spike', 5X, 'R Factor', 8X, 'G Factor',
     &           5X, 'Friction Coef. Opt', 5X, 'Output' )               
        BEGIN_LOOP = FALSE                                                 
       END IF
!C                                                                       
!C     Input contact surface no., segment no., and function nos.       
!C      Input Card F.2.b.                                           
!C                                                                     
       DO  K=1,NK                                                    
        IF ( LIN_FLAG )  THEN
         READ  ( LULIN, * )  NJ, MS_SEG, NF_FUNCT, NX, NOUT            
        ELSE
         READ  ( LUAIN, 125 )  NJ, MS_SEG, NF_FUNCT, NX, NOUT            
  125    FORMAT ( 9I4 )                                                
         IF ( AIN_CONVERT )  THEN
          WRITE  ( LULIN, 127 )  NJ, MS_SEG, NF_FUNCT, NX, NOUT, 
     &                           'Card F.2.b'            
  127     FORMAT ( 1X, 9( I4, 1X ), 1X, A )                                                
         END IF
        END IF
!C
        WRITE ( LUAOU, 130 )  NJ, MS_SEG, NF_FUNCT, NX, NOUT           
  130   FORMAT ( '0', I7, '-', I3, I11, '-', I3, I8, 4I16, I12, I12 )  
        MC = MC + I_1                                               
        IF ( NJ .NE. J ) THEN
         WRITE ( LUAOU, 135 )                                            
  135    FORMAT ( ' Contact input error. Program terminated.' )         
         STOP ' STOP 14 in Subroutine INPUT_BELT_FORCE '                                      
        END IF
        NLT = I_1                                                    
        DO  JJ = 1,31                                                   
         KTITLE(JJ) = BLANK                                            
        END DO
!C                                                                      
!C       Place segment no. and index to NTAB array into M- and 
!C        NT- arrays. 
!C                                                                     
         MBLT(1,K,J) = MS_SEG(1)                                         
         MBLT(2,K,J) = MS_SEG(2)                                         
         MBLT(3,K,J) = MS_SEG(3)                                         
         NTBLT(K,J) = MXNTB + I_1                                    
         DO  JJ = 1,5                                                    
          KTITLE(JJ) = BLTTTL (J)( ( JJ*4 - 3 ) : JJ*4 )                   
         END DO
!C                                                                       
!C       Set up two tables for full belt friction                       
!C                                                                     
         IF ( NF_FUNCT(5) .NE. I_0 )  NLT = I_2                           
!C                                                                     
!C      Set up pointers to TAB array in NTAB array.                      
!C                                                                       
        NFJ = MS_SEG(2)                                                  
        IF ( NFJ .GT. I_0 )  KTITLE(6) = SEG(NFJ)%NAME                      
        DO  JJ=1,NLT                                                    
         CALL FDINIT ( I_1 )                                        
        END DO
        WRITE ( LUAOU, 140 )  KTITLE                                      
  140   FORMAT ( 1X, 5A4, 1X, A4, 5( 1X, 5A4 ) )                       
        LT = NTAB(MXNTB-5)                                                 
!C                                                                      
!C      If force deflection function no. is zero,                       
!C       set up for rolling constraint                                  
!C                                                                      
        IF  ( NF_FUNCT(1) .EQ. I_0 )  THEN                              
         NQ = NQ + I_1                                               
         NTAB(MXNTB-4) = -NQ                                             
         KQTYPE(NQ) = -I_4                                           
         KQ1(NQ) = MS_SEG(2)                                           
         KQ2(NQ) = MS_SEG(1)                                             
        END IF
       END DO                                                        
      END DO                                                          
!C
      RETURN                                                              
      END                                                                 
