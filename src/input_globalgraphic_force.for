      SUBROUTINE INPUT_GLOBALGRAPHIC_FORCE                                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Input Cards F.4 which specify the allowed contacts of the 
!C     globalgraphic joints.
!C            
!C    Also sets up tables to control time history information for         
!C    each function for the globalgraphic joints.                
!C                                                                        
!C    This subroutine is called only by Subroutine INPUT_FCARDS.
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &               NJNT, NQ,                             ! /CONTRL/
     &               KQTYPE, KQ1, KQ2,                     ! /CSTRNT/
     &               IGLOB,                                ! /DESCRP/
     &               MXNTB, MXTB1, MXTB2, NTAB,            ! /TABLES/
     &               KTITLE, MS_SEG, NF_FUNCT,             ! /CINPUT_TEMPVS/
     &               SEG, JNT,                             ! structures
     &               ICHAR_STD, INTEGER_STD, LUAIN, LUAOU, ! parameters
     &               I_0, I_1, I_4, I_10, I_18, LIN_FLAG,  ! parameters
     &               LOGICAL_STD, TRUE, FALSE,             ! parameters
     &               LULIN, AIN_CONVERT                    ! parameters
!C
!C    NAME        ! SEG%
!C    JNT_NAME    ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) 
     &         I, J, J1, J2, JJ, K, LT, 
     &         MC, N, NFJ, NJ, NJJ, NK, NLT, NOUT, NREM, NX
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
!C    Input Card F.4.a                                                  
!C    Supply IGLOB(J)=1 for each globalgraphic joint J=1,NJNT           
!C                                                                      
!C
      N = NJNT / I_18
      NREM = MOD ( NJNT, I_18 )
      IF ( LIN_FLAG )  THEN
       IF ( N .NE. I_0 )  THEN 
        J1 = I_1
        J2 = I_18
        DO I=1,N
         READ ( LULIN, * ) ( IGLOB(J), J=J1,J2 )                
         J1 = J1 + I_18
         J2 = J2 + I_18
        END DO
        IF ( NREM .GT. I_0 )  THEN
         J1 = N * I_18 + I_1
         J2 = J1 + NREM - I_1
         READ ( LULIN, * ) ( IGLOB(J), J=J1,J2 )
        END IF
       ELSE
        READ ( LULIN, * ) ( IGLOB(J), J=1,NJNT )                
       END IF
      ELSE
       READ ( LUAIN, 100 )  ( IGLOB(J), J=1,NJNT )                        
  100  FORMAT ( 18I4 )                                                   
       IF ( AIN_CONVERT )  THEN
!C
!C      Determine the number of F.4.a cards needed and the
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
!C      Write out the F.4.a cards with a variable number of elements.
!C
        IF ( N .NE. I_0 )  THEN
         J1 = I_1
         J2 = I_18
         DO I=1,N
          WRITE ( LULIN, 125 ) ( IGLOB(J), J=J1,J2 ), 'Card F.4.a'                
  125     FORMAT ( 1X, 18( I4, 1X ), 1X, A )                                                  
          J1 = J1 + I_18
          J2 = J2 + I_18
         END DO
         IF ( NREM .NE. I_0 )  THEN
          J1 = N * I_18 + I_1
          J2 = J1 + NREM - I_1
          IF ( NREM .LT. I_10 )  THEN
           WRITE ( LULIN, A_FRMT_26 ) ( IGLOB(J), J=J1,J2 ), 
     &                                'Card F.4.a'
          ELSE
           WRITE ( LULIN, A_FRMT_27 ) ( IGLOB(J), J=J1,J2 ), 
     &                                'Card F.4.a'
          END IF
         END IF
        ELSE
         IF ( NJNT .LT. I_10 )  THEN
          WRITE ( LULIN, A_FRMT_26 ) ( IGLOB(J), J=1,NJNT ), 
     &                               'Card F.4.a'
         ELSE
          WRITE ( LULIN, A_FRMT_27 ) ( IGLOB(J), J=1,NJNT ), 
     &                               'Card F.4.a'
         END IF
        END IF
       END IF
      END IF
!C                                                                        
!C    Start of loop to read functions for globalgraphic joints.      
!C                                                                       
      NJJ = NJNT                                                        
      MC = I_0                                                     
      BEGIN_LOOP = TRUE
      DO  J=1,NJJ                                                     
       NK = IGLOB(J)                              
       IF ( NK .LE. I_0 )  CYCLE                                    
!C
!C     Write header for globalgraphic joints to the standard
!C      output file.
!C
       IF ( BEGIN_LOOP )  THEN
        WRITE ( LUAOU, 130 )                     
  130   FORMAT ( '0', 119X, 'Cards F.4' )                             
        WRITE ( LUAOU, 135 )    
  135   FORMAT ( '0', 5X, 'Joint (Globalgraphic)', 2X, 
     &           'Torque Deflection', 6X, 'Herron Formula',10X,
     &           'R Factor', 13X, 'G Factor', 10X, 'Friction Coef.' )   
        BEGIN_LOOP = FALSE
       END IF
!C                                                                       
!C     Input Card F.4.b.                                          
!C                                                                       
       DO  K=1,NK                                                     
        IF ( LIN_FLAG )  THEN
         READ  ( LULIN, * )  NJ, MS_SEG, NF_FUNCT, NX, NOUT             
        ELSE
         READ  ( LUAIN, 140 )  NJ, MS_SEG, NF_FUNCT, NX, NOUT             
  140    FORMAT ( 18I4 )                                                   
         IF ( AIN_CONVERT )  THEN
          WRITE  ( LULIN, 145 )  NJ, MS_SEG, NF_FUNCT, NX, NOUT, 
     &                           'Card F.4.b'             
  145     FORMAT ( 1X, 9( I4, 1X ), 1X, A )                                                   
         END IF
        END IF
        WRITE ( LUAOU, 150 )  NJ, MS_SEG, NF_FUNCT, NX, NOUT             
  150   FORMAT ( '0', I7, '-', I3, I11, '-', I3, I8, 4I16, I12, I12 )   
        MC = MC + I_1                                               
        IF ( NJ .NE. J ) THEN
         WRITE ( LUAOU, 155 )                                             
  155    FORMAT ( ' Contact input error. Program terminated.' )          
         STOP ' STOP 14 in Subroutine INPUT_GLOBALGRAPHIC_FORCE '                                      
        END IF
        IF (   NF_FUNCT(5) .EQ. I_0 )   THEN
         WRITE ( LUAOU, 160 )  
  160    FORMAT ( ' Friction function number can not be zero for this '
     &            , 'type of contact.' )                                 
         STOP  ' STOP 105 in Subroutine INPUT_GLOBALGRAPHIC_FORCE '
        END IF
        NLT = I_1                                                    
        DO  JJ = 1,31                                                    
         KTITLE(JJ) = BLANK                                              
        END DO
!C                                                                       
!C       Note: globalgraphic joint will save NT in IGLOB array.          
!C                                                                       
         IGLOB(J)   = MXNTB + I_1                                    
         KTITLE(2)  = JNT(J)%JNT_NAME                                      
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
