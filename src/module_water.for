      MODULE  MODULE_WATER
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This MODULE contains the water force related COMMON BLOCKs.
!C
      USE  MODULE_STANDARD,  ONLY: 
     &        INTEGER_STD, IREAL_HIGH, MAXELP, MAXSEG   ! parameters
!C
      IMPLICIT  NONE
!C
!C    SAVE all variables, since MODULE_WATER is not referenced by
!C     .MAIN, making it possible for these variables to become 
!C     undefined during the execution of the program, when no
!C     subroutines are being executed that reference this module.
!C
      SAVE
!C
!C********
!C
!C     /ELPDAT/
!C
      INTEGER  ( KIND = INTEGER_STD )  NELPS
!C
      REAL  ( KIND = IREAL_HIGH )  DELP
      DIMENSION  DELP(3,3,MAXELP)
!C
!C      COMMON /ELPDAT/  DELP, NELPS                                      
!C
!C********
!C
!C     /WATGRD/
!C
      REAL  ( KIND = IREAL_HIGH )  RPH, RNX
!C
!C     COMMON /WATGRD/  RPH, RNX                                        
!C
!C********
!C
!C    /WATINF1/
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         MOUTHS, MOUTHE, NEBODY, NSBODY, NWATER, 
     &         NUM_PER_FLOAT_DEV, NUM_ELLIP_WATER_CT,
     &         NWSE, NELPFD, KPFD
      DIMENSION  NWSE(2,MAXELP), NELPFD(5), KPFD(25)
!C
      REAL  ( KIND = IREAL_HIGH )
     &           BDPFD, PFDWT, DMOUTH, COED, TBDV, COEL, CADDM
      DIMENSION  BDPFD(30,25), PFDWT(5,5), DMOUTH(3),
     &           COED(MAXELP+25), COEL(MAXELP+25), CADDM(6,MAXELP+25)
!C
!C      COMMON /WATINF1/  BDPFD, PFDWT, DMOUTH, COED, TBDV, COEL,             
!C     *                  CADDM, MOUTHS, MOUTHE, NEBODY, NSBODY, 
!C     *                  NWATER, NPFD, NEW, NWSE, NELPFD, KPFD
!C
!C********
!C
!C     /WATINF2/
!C
      INTEGER  ( KIND = INTEGER_STD )  NPE
!C
      REAL  ( KIND = IREAL_HIGH )   DPFD
      DIMENSION  DPFD(3,3,25)
!C
!C      COMMON /WATINF2/  DPFD, NPE                                   
!C
!C********
!C
!C     /WAVEDAT/
!C
      INTEGER  ( KIND = INTEGER_STD )  ISPD, NWAVES
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  WOFSET, WFRAME, WD, WDEP, WNUM, WAMP, WDIR,
     &                  WPHS, FREQ, SWKH, WGAM, WSPD
      DIMENSION  WOFSET(3), WFRAME(3), WD(3,3), WNUM(10), WAMP(10),
     &           WDIR(10), WPHS(10), FREQ(10), SWKH(10)
!C
!C      COMMON /WAVEDAT/ WOFSET, WFRAME, WD, WDEP, WNUM, WAMP, WDIR,     
!C     *                 WPHS, FREQ, SWKH, WGAM, WSPD, ISPD, NWAVES        
!C
!C********
!C
!C     /WFACOP/
!C
      INTEGER  ( KIND = INTEGER_STD )  NSEQN, NELL, NELOUT, ITYPE
      DIMENSION  NELL(5), NELOUT(5,2,MAXELP+25), ITYPE(6)
!C
      REAL  ( KIND = IREAL_HIGH )  BRI, TENY, WAREA, 
     &                             DIST_MOUTH_TO_WATER, ALFA1, ALFA2
!C
!C      COMMON /WFACOP/  BRI, TENY, WAREA, DISTM, ALFA1, ALFA2, NSEQN,   
!C     *                 NELL, NELOUT, ITYPE                             
!C
!C********
!C
!C     /WMASS/
!C             This COMMON BLOCK was in Subroutine ADDMAS and DAUX
!C             but not in BLOCK_DATA of version V.1.
!C
      REAL  ( KIND = IREAL_HIGH )  WX, RWX, WXX, RWXX
      DIMENSION  WX(3,MAXSEG), RWX(3,MAXSEG), WXX(MAXSEG), RWXX(MAXSEG)
!C
!C      common /wmass/   wx(3,MAXSEG),rwx(3,MAXSEG),wxx(MAXSEG),       
!C    *                 rwxx(MAXSEG)                                      
!C
!C*********
!C
!C     /WRESLTS/
!C
      REAL  ( KIND = IREAL_HIGH )  BUOY, WEXF, ADDM, DRAG, BVL, AREA
      DIMENSION   BUOY(6,MAXELP+25), WEXF(6,MAXELP+25),                
     &            ADDM(3,MAXELP+25), DRAG(6,MAXELP+25),                   
     &            BVL(MAXELP+25), AREA(MAXELP+25)                       
!C 
!C      COMMON /WRESLTS/  BUOY, WEXF, ADDM, DRAG, BVL, AREA            
!C
!C
!C*********
!C
!C    This is a temporary module, which contains the /TEMPFD/ 
!C     variables used by the water subroutines ADDMAS, BOYCTR, 
!C     and WATINP.
!C
!C    Was  /TEMPFD/
!C
      INTEGER  ( KIND = INTEGER_STD )  KSEG_WATER, KELT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  T2, T5, P1, CENTW, FL, F1, FF_WATER, WDSE, 
     &                  TSN, TN, BET, BTE, E11, E12, E22, C1, S1, 
     &                  UU_WATER, VV
      DIMENSION  T2(3), T5(3), P1(3), CENTW(3), FL(100,6), F1(100,6),    
     &           FF_WATER(6), WDSE(3,3,MAXELP+25), TSN(3), TN(3), 
     &           UU_WATER(3), VV(3)
!C
!C
      END MODULE  MODULE_WATER
      