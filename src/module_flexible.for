      MODULE  MODULE_FLEXIBLE
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This module contains the COMMON BLOCKs related to the flexible
!C     segment option.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       INTEGER_STD, IREAL_HIGH, MAXSEG, MAXJNT, MAXDEF, 
     &       MXMOD, MXNOD, MAX_NUM_DAMPERS, MAX_HCARD_TTH,
     &       MAX_FOR_TORQ
!C
      IMPLICIT  NONE
!C
!C
!C*******
!C
!C    /FXBODY/
!C
      REAL  ( KIND = IREAL_HIGH )  QNOD, WNOD, FMODES, FIK
      DIMENSION  QNOD(3,MXNOD,3*MAXDEF), WNOD(MXNOD,MAXDEF),   
     &           FMODES(6*MXNOD,MXMOD,3*MAXDEF), FIK(3,MXNOD,MAXDEF)    
!C
!C      COMMON /FXBODY/  QNOD, WNOD, FMODES, FIK                        
!C
!C
!C*******
!C
!C    /FXCOEF/
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  WPI, PHPI, U1P, A21P, U2P, UAP, A11P, A12P,
     &                  A22P, AA1P, AA2P, B1A, B2A, A11F, A22F
      DIMENSION   WPI(3,3,MAXDEF), PHPI(3,3,MAXDEF), U1P(3,MAXDEF),     
     &            A21P(3,3,2*MAXJNT), U2P(3,MAXDEF), UAP(MXMOD,MAXDEF), 
     &            A11P(3,3,2*MAXJNT), A12P(3,3,2*MAXJNT),               
     &            A22P(3,3,2*MAXJNT), AA1P(MXMOD,3,2*MAXJNT),           
     &            AA2P(MXMOD,3,2*MAXJNT), B1A(3,MXMOD,2*MAXJNT),        
     &            B2A(3,MXMOD,2*MAXJNT), A11F(3,3,2*MAXJNT),            
     &            A22F(3,3,2*MAXJNT)                                    
!C
!C      COMMON /FXCOEF/  WPI, PHPI, U1P, A21P, U2P, UAP, A11P, A12P,
!C     *                 A22P, AA1P, AA2P, B1A, B2A, A11F, A22F
!C
!C
!C********
!C
!C     /FXFRC/
!C
      INTEGER  ( KIND = INTEGER_STD )  NODSD, NODFR
      DIMENSION  NODSD(2,MAX_NUM_DAMPERS), NODFR(MAX_FOR_TORQ)
!C
      REAL  ( KIND = IREAL_HIGH )  PURTQ, YFB
      DIMENSION  PURTQ(3,MAXDEF), YFB(3,MAXDEF)
!C
!C    COMMON /FXFRC /  PURTQ, YFB, NODSD, NODFR                         
!C
!C********
!C
!C     /FXINT/
!C
      INTEGER  ( KIND = INTEGER_STD )  NEQP
!C
!C      COMMON /FXINT /  NEQP                                            
!C
!C********
!C
!C    /FXJROT/
!C
      INTEGER  ( KIND = INTEGER_STD )  NTDEF, IDSEG, IDJNT, JROUT
      DIMENSION  IDSEG(MAXDEF), IDJNT(2,MAXDEF), JROUT(MAXDEF)
!C
      REAL  ( KIND = IREAL_HIGH )  ROTJ, ROTVJ, DNP, ANF, CN
      DIMENSION  ROTJ(3,2*MAXJNT), ROTVJ(3,2*MAXJNT),           
     &           DNP(3,3,2*MAXJNT), ANF(3,3,2*MAXJNT),                   
     &           CN(3,2*MAXJNT)
!C                     
!C     COMMON /FXJROT/  ROTJ, ROTVJ, DNP, ANF, CN, NTDEF, IDSEG, IDJNT    
!C
!C*******
!C
!C     /FXNVEL/
!C
      REAL  ( KIND = IREAL_HIGH )   ASAD,  WNP
      DIMENSION  ASAD(3,2*MAXJNT), WNP(3,2*MAXJNT)
!C
!C      COMMON /FXNVEL/  ASAD, WNP                                    
!C
!C*******
!C
!C    /FXOUT/
!C
      INTEGER  ( KIND = INTEGER_STD )   NFBPR, NODPR
      DIMENSION  NFBPR(MAX_HCARD_TTH,3), NODPR(MAX_HCARD_TTH,3)
!C
      REAL  ( KIND = IREAL_HIGH )   T91, T92
      DIMENSION  T91(3), T92(3)
!C
!C      COMMON /FXOUT /  T91, T92, NFBPR, NODPR                      
!C
!C*******
!C
!C    /FXSING/
!C
      REAL  ( KIND = IREAL_HIGH )   TAM, RAM
      DIMENSION  TAM(3,MXMOD,MAXDEF), RAM(3,MXMOD,MAXDEF)
!C
!C     COMMON /FXSING/  TAM, RAM                                    
!C
!C********
!C
!C     /FXVAR/
!C
      INTEGER  ( KIND = INTEGER_STD )  NFBOD, IBODN, NNOD, NMOD, NODJ
      DIMENSION  IBODN(MAXDEF), NNOD(MAXDEF), NMOD(3*MAXDEF),
     &           NODJ(3,2,MAXSEG)
!C
      REAL  ( KIND =IREAL_HIGH )  RSTF, RDMP, TTM, SAIM, AMP, AMV, AMA
      DIMENSION  RSTF(MXMOD,MAXDEF), RDMP(MXMOD,MAXDEF), TTM(MAXDEF), 
     &           SAIM(3,MXMOD,MAXDEF), AMP(MXMOD,3*MAXDEF),               
     &           AMV(MXMOD,3*MAXDEF), AMA(MXMOD,3*MAXDEF)                
!C 
!C     COMMON /FXVAR/  RSTF, RDMP, TTM, SAIM, AMP, AMV, AMA, NFBOD,     
!C    *                IBODN, NNOD, NMOD, NODJ                          
!C
!C********
!C
!C     /FXXTRA/
!C
      REAL  ( KIND = IREAL_HIGH )  HB0, HT0, DBN, FMODM
      DIMENSION  HB0(3,2*MAXJNT), HT0(3,3,2*MAXJNT),             
     &           DBN(3,3,2*MAXJNT), FMODM(3,MXMOD,2*MAXJNT)    
!C
!C     COMMON /FXXTRA/  HB0, HT0, DBN, FMODM                        
!C
!C
!C********
!C
!C      /OLDDAT/
!C
      REAL  ( KIND = IREAL_HIGH )   AMPOLD, FMODO, ROTOLD
      DIMENSION         AMPOLD(MXMOD,MAXDEF), FMODO(3,MXMOD,2*MAXJNT), 
     &                  ROTOLD(3,2*MAXJNT)                             
!C
!c      COMMON /OLDDAT/ AMPOLD(MXMOD,MAXDEF), FMODO(3,MXMOD,2*MAXJNT),    
!c     &                ROTOLD(3,2*MAXJNT)                               
!C
!C
!C*********************
!C*********************
!C 
!C    Parameters associated with the flexible/deformable segments.
!C
      REAL  ( KIND = IREAL_HIGH )  SMALL_START
      PARAMETER ( SMALL_START = 1.0E12_IREAL_HIGH )
!C
      END MODULE  MODULE_FLEXIBLE
      