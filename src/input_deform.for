      SUBROUTINE  INPUT_DEFORM                                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Input data for (max. of 1) deformable bodies                          
!C    Max. # of nodes(NNOD)=MXNOD, max. # of modes(NMOD)=MXMOD for each body.
!C    Normalizes the mode shapes with respect to mass such that MAA = I.     
!C    Computes the constants of equations of motion.                         
!C    Called by Subroutine INPUT_BCARDS.                                     
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       WORK_DIRECTORY,                             ! /FILEN/, new variable
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,         ! parameters
     &       LOGICAL_STD, LUAIN, LUAOU, LUFLEX, LULIN,   ! parameters
     &       LUTERM_OUT, MXMOD, MXNOD, FALSE,            ! parameters
     &       D_0, D_1, D_2, D_4, I_1, I_6,               ! parameters
     &       AIN_CONVERT, LIN_FLAG                       ! parameters
!C
      USE  MODULE_FLEXIBLE,  
     &       ONLY:   QNOD, WNOD, FMODES,             ! /FXBODY/
     &               NMOD, NNOD, NFBOD, IBODN, TTM,  ! /FXVAR/
     &               AMP, AMV, RSTF, RDMP, SAIM      ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, JJ, K, KK, 
     &                                 L, LEN, LEN_FLXFIL, NN6
!C
      REAL  ( KIND = IREAL_HIGH )  AAM, HZ, ZETA, PI_LCL
      DIMENSION  AAM(MXMOD), HZ(MXMOD), ZETA(MXMOD)                     
!C
      CHARACTER  ( LEN =  32, KIND = ICHAR_STD )  FLXFIL, TEMP_FLXFIL, 
     &                                            ATEMP32
      CHARACTER  ( LEN =  34, KIND = ICHAR_STD )  ATEMP34
      CHARACTER  ( LEN = 116, KIND = ICHAR_STD )  FLEX_FILE
!C
      CHARACTER ( LEN = 116, KIND = ICHAR_STD )  FNAME
      EXTERNAL  FNAME
!C
      LOGICAL ( KIND = LOGICAL_STD )  LFILE_EXISTS
!C
      PI_LCL = ACOS ( -D_1 )
      WRITE ( LUAOU, 100 ) NFBOD
  100 FORMAT ( 10X, 'Number of Deformable Segments:', 5X, I5 )
      DO 10 I=1,NFBOD
!C
!C.....Segment number of the deformable body and its data file name         
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  IBODN(I), FLXFIL
       ELSE
        READ ( LUAIN, 105 )  IBODN(I), FLXFIL
  105   FORMAT ( I5, 5X, A32 )
        IF ( AIN_CONVERT )  THEN
         ATEMP32 = ADJUSTL ( FLXFIL )
         LEN = LEN_TRIM ( ATEMP32 )
         ATEMP34(1:LEN+2) = '"' // ATEMP32(1:LEN) // '"'       
         WRITE ( LULIN, 110 )  IBODN(I), ATEMP34(1:LEN+2), 
     &                         'Card B.1.b'
  110    FORMAT ( 1X, I5, 1X, A, 2X, A )
        END IF
       END IF
       WRITE ( LUAOU, 115 )  IBODN(I), FLXFIL
  115  FORMAT ( 10X, 'Deform Seg Num',  10X, 'Data File Name', /,
     &          14X, I5, 16X, A32 )
!C
!C     To be capatible with old input decks, strip off the
!C      ".DAT" extension.
!C
       FLXFIL = ADJUSTL ( FLXFIL )
       LEN_FLXFIL = INDEX ( FLXFIL, '.', BACK = FALSE )
       TEMP_FLXFIL = FLXFIL(1:LEN_FLXFIL-1)
       FLEX_FILE = FNAME ( WORK_DIRECTORY, TEMP_FLXFIL, '.dat' )                  
       INQUIRE ( FILE = FLEX_FILE, ERR = 30, EXIST = LFILE_EXISTS )
       IF  ( LFILE_EXISTS )  THEN
        OPEN ( UNIT = LUFLEX, FILE = FLEX_FILE, ERR = 35,
     &         ACCESS = 'SEQUENTIAL', ACTION = 'READ',
     &         FORM = 'FORMATTED', POSITION = 'REWIND', 
     &         STATUS = 'OLD' )
       ELSE
        WRITE ( LUTERM_OUT, 120 ) FLEX_FILE
  120   FORMAT ( 1X, ' Input file for deformable segment does not ',
     &           'exist: ', / 1X, A116 )
        STOP ' STOP 451 in Subroutine INPUT_DEFORM. '
       END IF
       READ ( LUFLEX, * )  NNOD(I), NMOD(I)
       IF ( NNOD(I) .GT. MXNOD )   STOP 300
       IF ( NMOD(I) .GT. MXMOD )   STOP 301
!C
!C.....Modal damping values
!C
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  ( ZETA(J), J=1,NMOD(I) )
       ELSE
        READ  ( LUAIN, 125 )  ( ZETA(J), J=1,NMOD(I) )
  125   FORMAT ( 12F6.0 )
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 130 )  ( ZETA(J), J=1,NMOD(I) )
  130    FORMAT ( 1X, 12( F15.7, 1X ) )  
        END IF
       END IF
       WRITE ( LUAOU, 135 )  ( ZETA(J), J=1,NMOD(I) )
  135  FORMAT ( 10X, 'Modal Damping Values:', /, 10X, 12( F6.0, 3X ) )
!C
!C.....Initial values of modal displacements and velocities
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( AMP(J,I), J=1,NMOD(I) )
       ELSE
        READ ( LUAIN, 140 )  ( AMP(J,I), J=1,NMOD(I) )
  140   FORMAT ( 12( F6.0 ) )
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 145 )  ( AMP(J,I), J=1,NMOD(I) )
  145    FORMAT ( 1X, 12( F15.7, 1X ) )
        END IF
       END IF
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( AMV(J,I), J=1,NMOD(I) )
       ELSE
        READ ( LUAIN, 150 )  ( AMV(J,I), J=1,NMOD(I) )
  150   FORMAT ( 12( F6.0 ) )
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 155 )  ( AMV(J,I), J=1,NMOD(I) )
  155    FORMAT ( 1X, 12( F15.7, 1X ) )
        END IF
       END IF
       WRITE ( LUAOU, 160 )
  160  FORMAT ( 10X, 'Initial Modal Displacements' )
       WRITE ( LUAOU, 165 )  ( AMP(J,I), J=1,NMOD(I) )
  165  FORMAT ( 10X, 12( F6.0, 3X ) )
       WRITE ( LUAOU, 170 )
  170  FORMAT ( 10X, 'Initial Modal Velocities' )
       WRITE ( LUAOU, 175 )  ( AMV(J,I), J=1,NMOD(I) )
  175  FORMAT ( 10X, 12( F6.0, 3X ) )
!C
!C.....Nodal positions
!C
       DO  J=1,NNOD(I)
        READ ( LUFLEX, * )  ( QNOD(K,J,I), K=1,3 )
       END DO
!C
!C.....Nodal masses
!C
       READ ( LUFLEX, * )  ( WNOD(J,I),  J=1,NNOD(I) )
!C
!C.....Modal stiffness & damping matrix (diagonals only)
!C
       READ ( LUFLEX, * ) ( HZ(J), J=1,NMOD(I) )
       DO  J=1,NMOD(I)
        RSTF(J,I) = ( D_2 * PI_LCL * HZ(J) )**2
        RDMP(J,I) = D_4 * PI_LCL * ZETA(J) * HZ(J)
       END DO
!C   
!C.....Mode shapes (eigenvectors)
!C
       NN6 = I_6 * NNOD(I)
       DO  J=1,NMOD(I)
        READ ( LUFLEX, * ) ( FMODES(K,J,I), K=1,NN6 )
       END DO
       CLOSE ( LUFLEX )
   10 CONTINUE
!C
!C....Calculate constants of the equations of motion
!C
      DO 20 I=1,NFBOD
!C
!C. ...Initialize
!C
       TTM(I) = D_0
       DO  J=1,NMOD(I)
        AAM(J) = D_0
        DO  JJ=1,3
         SAIM(JJ,J,I) = D_0
        END DO
       END DO
!C
!C.....Normalize mode shapes such that MAA = I
!C
       DO  K=1,NNOD(I)
        L = I_6 * ( K - I_1 )
        DO  J=1,NMOD(I)
         DO  KK=1,3
          AAM(J) = AAM(J) +
     &             WNOD(K,I) * FMODES(L+KK,J,I) * FMODES(L+KK,J,I)
         END DO
        END DO
       END DO
       DO  J=1,NMOD(I)
        AAM(J) = SQRT ( AAM(J) )
       END DO
       DO  K=1,NNOD(I)
        L = I_6 * ( K - I_1 )
        DO  J=1,NMOD(I)
         DO  KK=1,3
          FMODES(L+KK,J,I) = FMODES(L+KK,J,I) / AAM(J)
         END DO
        END DO
       END DO
!C
!C.....MTT and SAIM = SUM(MK*SAIK)
!C
       DO  K=1,NNOD(I)
        TTM(I) = TTM(I) + WNOD(K,I)
        L = I_6 * ( K - I_1 )
        DO  J=1,3
         DO  JJ=1,NMOD(I)
          SAIM(J,JJ,I) = SAIM(J,JJ,I)  + WNOD(K,I) * FMODES(L+J,JJ,I)
         END DO
        END DO
       END DO
!C
   20 CONTINUE
!C
      RETURN
!C
!C    File handling messages.
!C
   30 WRITE ( LUTERM_OUT, 330 )  FLEX_FILE
  330 FORMAT ( 1X, ' INQUIRE statement error for file: ', /, 1X, A116 )
      STOP ' STOP 452 in Subroutine INPUT_DEFORM. '
!C
   35 WRITE ( LUTERM_OUT, 335 )  FLEX_FILE
  335 FORMAT ( 1X, ' Error opening file: ', /, 1X, A116 )
      STOP ' STOP 453 in Subroutine INPUT_DEFORM '
!C
      END
