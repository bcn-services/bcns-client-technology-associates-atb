      MODULE MODULE_STANDARD
!C
!C                                                   Rev. V.3 7/10/2004 
!C
!C    This module contains all the COMMON BLOCKs and PARAMETERS
!C     found in BLOCKDATA in version ATBV_1.
!C
      IMPLICIT NONE
!C
!C****************************************************************************
!C    Define the KIND parameters for use throughout the program.
!C****************************************************************************
!C
      INTEGER      ICHAR_STD, INTEGER_STD,  IREAL_HIGH, IREAL_STD, 
     &             LOGICAL_STD
      PARAMETER  ( ICHAR_STD = 1, INTEGER_STD = 4, IREAL_HIGH = 8, 
     &             IREAL_STD = 4, LOGICAL_STD = 4 )
!C
!C****************************************************************************
!C    Define the numerical constants for the program.
!C****************************************************************************
!C
      INTEGER ( KIND = INTEGER_STD )  I_0, I_1, I_2, I_3, I_4, I_5, 
     &                                I_6, I_7, I_8, I_9, I_10, I_11, 
     &                                I_12, I_13, I_14, I_15, I_16,
     &                                I_18, I_20, I_45, I_50, I_100
      PARAMETER  ( I_0     =   0_INTEGER_STD,
     &             I_1     =   1_INTEGER_STD,
     &             I_2     =   2_INTEGER_STD,
     &             I_3     =   3_INTEGER_STD,
     &             I_4     =   4_INTEGER_STD,
     &             I_5     =   5_INTEGER_STD, 
     &             I_6     =   6_INTEGER_STD,
     &             I_7     =   7_INTEGER_STD,
     &             I_8     =   8_INTEGER_STD,
     &             I_9     =   9_INTEGER_STD,
     &             I_10    =  10_INTEGER_STD,
     &             I_11    =  11_INTEGER_STD,
     &             I_12    =  12_INTEGER_STD,
     &             I_13    =  13_INTEGER_STD,
     &             I_14    =  14_INTEGER_STD,
     &             I_15    =  15_INTEGER_STD,
     &             I_16    =  16_INTEGER_STD,
     &             I_18    =  18_INTEGER_STD,
     &             I_20    =  20_INTEGER_STD,
     &             I_45    =  45_INTEGER_STD,
     &             I_50    =  50_INTEGER_STD,
     &             I_100   = 100_INTEGER_STD  )

!C
      REAL   ( KIND = IREAL_STD )  R_0, R_HALF, R_100, R_1000
      PARAMETER ( R_0          =    0.0E0_IREAL_STD,
     &            R_HALF       =    0.5E0_IREAL_STD,
     &            R_100        =  100.0E0_IREAL_STD,
     &            R_1000       = 1000.0E0_IREAL_STD )
!C
      REAL   ( KIND = IREAL_HIGH )   D_0, D_THIRD, D_HALF, D_1, 
     &                               D_2, D_3, D_4, D_5, D_6, D_8,
     &                               D_9, D_10, D_12, 
     &                               D_100, D_180, D_1000
      PARAMETER ( D_0        =    0.0E0_IREAL_HIGH,
     &            D_THIRD    =    1.0E0_IREAL_HIGH / 3.0E0_IREAL_HIGH,
     &            D_HALF     =    0.5E0_IREAL_HIGH,
     &            D_1        =    1.0E0_IREAL_HIGH,                            
     &            D_2        =    2.0E0_IREAL_HIGH,
     &            D_3        =    3.0E0_IREAL_HIGH,
     &            D_4        =    4.0E0_IREAL_HIGH,
     &            D_5        =    5.0E0_IREAL_HIGH,
     &            D_6        =    6.0E0_IREAL_HIGH,
     &            D_8        =    8.0E0_IREAL_HIGH,
     &            D_9        =    9.0E0_IREAL_HIGH,
     &            D_10       =   10.0E0_IREAL_HIGH, 
     &            D_12       =   12.0E0_IREAL_HIGH,
     &            D_100      =  100.0E0_IREAL_HIGH,
     &            D_180      =  180.0E0_IREAL_HIGH,
     &            D_1000     = 1000.0E0_IREAL_HIGH  )
!C
!C****************************************************************************
!C    Define the program name, version number and version date.
!C****************************************************************************
!C
      CHARACTER ( LEN = 4, KIND = ICHAR_STD ) PROGRAM_NAME
      PARAMETER ( PROGRAM_NAME = ICHAR_STD_'ATB' )
      CHARACTER ( LEN = 14, KIND = ICHAR_STD ) VERSION_NUMBER
      PARAMETER ( VERSION_NUMBER = ICHAR_STD_'Version 5.3.1 ' )
      CHARACTER ( LEN = 17, KIND = ICHAR_STD ) VERSION_DATE
      PARAMETER ( VERSION_DATE = ICHAR_STD_'July 10, 2004' )
!C
!C****************************************************************************
!C    Define the global constants used in ATB Model version V_3.
!C****************************************************************************
!C
!C    MAXSEG  = Maximum no. of segments
!C    MAXJNT  = Maximum no. of joints
!C    MAXELP  = Maximum no. of ellipsoids
!C    MAXXELP = maximun no. of additional ellipsoids beyond the default
!C              of one contact ellipsoid per segment
!C
      INTEGER  ( KIND = INTEGER_STD ) MAXSEG, MAXJNT, MAXELP, MAXXELP
      PARAMETER ( MAXXELP = I_20 )
      PARAMETER ( MAXSEG = 60_INTEGER_STD, MAXJNT = MAXSEG, 
     &            MAXELP = MAXSEG + MAXXELP )     
!C
!C    MAXPLN = Maximum no. of contact planes
!C    MAXPSF = maximum no. of plane/segment contacts
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXPLN, MAXPSF
      PARAMETER ( MAXPLN = I_50, MAXPSF = 200_INTEGER_STD )               
!C
!C    MAX_NUM_BELTS = Maximum no. of simple belts
!C
      INTEGER  ( KIND = INTEGER_STD ) MAX_NUM_BELTS
      PARAMETER ( MAX_NUM_BELTS = I_20 )
!C
!C    MAX_NUM_DAMPERS = Maximum no. of spring dampers
!C
      INTEGER  ( KIND = INTEGER_STD )  MAX_NUM_DAMPERS
      PARAMETER ( MAX_NUM_DAMPERS = I_20 )
!C
!C    MAXSSF = maximum no. of segment/segment contacts
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXSSF
      PARAMETER ( MAXSSF = 150_INTEGER_STD )  
!C
!C    MAXHRN  = maximum no. of harness belt systems
!C    MAXHBLT = maximum no. of harness belts from all of the harnesses combined
!C    MAXHPH  = maximum no. of belt points per harness belt system
!C    MAXHPT  = maxinum no. of belt points from all of the harnesses combined
!C	MULHRN  = multiplier used for tie point
!C    
      INTEGER  ( KIND = INTEGER_STD ) MAXHRN, MAXHBLT, MAXHPH, MAXHPT
      INTEGER  ( KIND = INTEGER_STD ) MULHRN
      PARAMETER ( MAXHRN = I_5,  MAXHBLT = I_20, 
     &            MAXHPH = I_50, MAXHPT = I_100, MULHRN = I_100 )
!C
!C    MAX_FOR_TORQ = maximum number of force/torque functions that are
!C     specified by the D.9 cards.
!C
      INTEGER  ( KIND = INTEGER_STD ) MAX_FOR_TORQ
      PARAMETER ( MAX_FOR_TORQ = I_5 )
!C
!C    MAXREF = maximun no. of reference segments, i.e. segments for which full
!C             6 degree of freedom motion is computed
!C    MAXEQN = maximum no. of vector state variables
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXREF, MAXEQN
      PARAMETER ( MAXREF = I_20 )
      PARAMETER ( MAXEQN = I_2 * ( MAXSEG + MAXREF ) )                
!C
!C    MAX_FUNC = maximum no. of functions
!C    MAXNTB   = maximum no. of elements in the NTAB array.  The scale factor
!C               of 75 * MAX_FUNC is based on previous experience and may need
!C               to be increased.
!C    MAXTAB   = maximum no. of elements in the TAB array. The scale factor
!C               of 270 * MAX_FUNC is based on previous experience and may need
!C               to be increased.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAX_FUNC, MAXNTB, MAXTAB
      PARAMETER ( MAX_FUNC = 98_INTEGER_STD,
     &            MAXNTB   = 75_INTEGER_STD * MAX_FUNC, 
     &            MAXTAB   = 270_INTEGER_STD * MAX_FUNC )                
!C
!C    MHEDNG = number of elements needed by arrays NOPL, MOPL, and M1PL
!C             during postprocessing
!C             In the following expression, The 1st '20' refers to maximum 
!C             no. of simple belt and harness belt endpoint strains and 
!C             forces.  The 2nd '20' refers to maximum amount of 
!C             airbag/contact force information. 
!C
      INTEGER  ( KIND = INTEGER_STD )  MHEDNG
      PARAMETER ( MHEDNG = MAXPSF + I_20 + MAXSSF + I_20 )           
!C
!C    MAXCST = maximum no. of constraints.
!C
      INTEGER  ( KIND = INTEGER_STD )   MAXCST
      PARAMETER ( MAXCST = I_12 )
!C
!C    MAXFLX = maximum no. of flexible elements.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXFLX
      PARAMETER ( MAXFLX = I_8 )
!C
!C    MAXRHS = maximum no. of equations which can be solved by the program.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXRHS
      PARAMETER ( MAXRHS = I_2 * MAXJNT + MAXFLX + MAXCST )                
!C                                                                        
!C    MAXCMX = maximum size of the solution matrix, C.
!C             Set the maximum size of the solution matrix, C, to approximately 
!C             20.5% of the fully populated matrix that corresponds to the     
!C             full length of the known vector, RHS.  The 20.5% populated size  
!C             for the C matrix was selected from previous experience with      
!C             how populated C was for various ATB simulations.  Approximate
!C             it generously by 1/4.                
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXCMX
      PARAMETER ( MAXCMX = ( MAXRHS**I_2 / I_4 ) )                              
!C
!C    MXMOD = maximum no. of mode shapes used for deformable segments.
!C    MXNOD = maximum no. of nodes in a deformable segment.
!C    MAXDEF = maximum no. of deformable segments
!C
      INTEGER  ( KIND = INTEGER_STD )  MXNOD, MXMOD, MAXDEF
      PARAMETER ( MXNOD = 4000_INTEGER_STD, MXMOD = I_4,
     &            MAXDEF = I_1 )
!C
!C    MXHIC = maximum no. of time points stored for HIC computation
!C
      INTEGER  ( KIND = INTEGER_STD )  MXHIC
      PARAMETER ( MXHIC = 6000_INTEGER_STD )
!C
!C    MAXBAG = maximum no. of airbags.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXBAG
      PARAMETER ( MAXBAG = I_5 )
!C
!C    MAXBDP =  ??????
!C    MAXBDT =  ??????
!C    MAXBSH =  ??????
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXBDP, MAXBDT, MAXBSH
      PARAMETER ( MAXBDP = 400_INTEGER_STD, MAXBDT = I_20,
     &            MAXBSH = I_20 )
!C
!C    MAXVEH = maximum no. of vehicles.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXVEH
      PARAMETER ( MAXVEH = I_6 )
!C
!C    MAXVT2 = maximum number of time points for vehicle input option 2.
!C    MAXVT3 = maximum number of time points for vehicle input option 3.
!C    MAXVT4 = maximum number of time points for vehicle input option 4.
!C    MAXVDT = maximum number of time (data) points for vehicle motion.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAXVT2, MAXVT3, MAXVT4, MAXVDT
      PARAMETER ( MAXVT2 = 99_INTEGER_STD, MAXVT3 = 5001_INTEGER_STD, 
     &            MAXVT4 = 5001_INTEGER_STD, MAXVDT = 5001_INTEGER_STD )   
!C
!C    MAX_NUM_TTH = maximum number of tabular time history files.
!C
      INTEGER  ( KIND = INTEGER_STD)  MAX_NUM_TTH
      PARAMETER ( MAX_NUM_TTH = 200_INTEGER_STD )
!C
!C    MAX_HCARD_TTH = maximum number of tabular time histories for 
!C     H.1 through H.9 and H.11 cards.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAX_HCARD_TTH
      PARAMETER ( MAX_HCARD_TTH = I_20 )
!C
!C    MAX_TOTAL_BODY = maximum number of bodies for the total body
!C     properties specified by the H.10 cards.
!C
      INTEGER  ( KIND = INTEGER_STD )  MAX_TOTAL_BODY
      PARAMETER ( MAX_TOTAL_BODY = I_5 )
!C
!C    MAX_LN_PPAGE = maximum number of lines of data per page of
!C     the tabular time history, when it is outputted in "paged"
!C     format, i.e. it has a heading for each page.
!C
      INTEGER  ( KIND = INTEGER_STD ) MAX_LN_PPAGE
      PARAMETER ( MAX_LN_PPAGE = I_45 )
!C
!C    Offset value after which the tabular time history logical units
!C     start.
!C
      INTEGER  ( KIND = INTEGER_STD)  NUM_TTH_OFFSET
      PARAMETER ( NUM_TTH_OFFSET = I_20 )
!C
!C    Define the logical unit numbers where:
!C       LUAIN      is the standard input unit;
!C       LUAOU      is the standard output unit;
!C       LUDEBUG    is the debug output unit;
!C       LUTP8      is the unformatted file used for postprocessing;
!C       LUVIEW     is the VIEW output unit;
!C       LUFLEX     is for the flexible segment input unit;
!C       LU_MEM     is the memory (run parameters) input/output unit;
!C       LUFACET    is for the faceted surface input unit;
!C       LUTERM_IN  is for terminal/console input;
!C       LUTERM_OUT is for terminal/console output.
!C
      INTEGER  ( KIND = INTEGER_STD )  LUAIN, LUAOU, LUTP8, LUDEBUG,
     &                                 LUVIEW, LUFLEX, LUFACET, LULIN,
     &                                 LUTERM_IN, LUTERM_OUT, LU_MEM
      PARAMETER ( LUTERM_OUT =  I_0,
     &            LUVIEW     =  I_1,
     &            LU_MEM     =  I_2,
     &            LULIN      =  I_3,
     &            LUAIN      =  I_4, 
     &            LUTERM_IN  =  I_5, 
     &            LUAOU      =  I_6, 
     &            LUDEBUG    =  I_7,
     &            LUTP8      =  I_8, 
     &            LUFLEX     =  I_11, 
     &            LUFACET    =  I_12 )
!C
!C    Define logical constants for program.
!C
      LOGICAL ( KIND = LOGICAL_STD )  FALSE, TRUE
      PARAMETER ( FALSE = .FALSE._LOGICAL_STD, 
     &            TRUE  = .TRUE._LOGICAL_STD )
!C
!C    Define the logical control parameters for the type
!C     of input to be supplied:
!C       LIN_FLAG - true for list-directed input, i.e. .LIN;
!C                - false for explicitly formatted input, i.e. .AIN
!C     and whether a .LIN file is to be created from a .AIN file:
!C       AIN_CONVERT - true to create a .LIN file
!C                   - false, no .LIN file will be created.
!C
      LOGICAL ( KIND = LOGICAL_STD )  LIN_FLAG, AIN_CONVERT
!C
!C
!C****************************************************************************
!C    Define the Structures
!C****************************************************************************
!C-----------------------------------------------------------------------------
!C    Define the structure type for tabular time histories.
!C          BEGIN_LUNUM - beginning logical unit number for a particular type 
!C                        of tabular time history output;
!C          END_LUNUM   - ending logical unit number for a particular type
!C                        of tabular time history output;
!C          PRINT       - logical flag; if true, the tabular time history
!C                        is to be outputted, if false, the tabular time
!C                        will not be outputted.
!C
      TYPE  TTH_DESCRIP
       INTEGER  ( KIND = INTEGER_STD )  BEGIN_LUNUM
       INTEGER  ( KIND = INTEGER_STD )  END_LUNUM
       LOGICAL  ( KIND = LOGICAL_STD )  PRINT
      END TYPE  TTH_DESCRIP
!C
!C    Define the tabular time history descriptors - the names are self-explanatory.
!C
      TYPE ( TTH_DESCRIP )  ACUATOR_TTH
      TYPE ( TTH_DESCRIP )  AIRBAG_TTH
      TYPE ( TTH_DESCRIP )  ANG_ACCEL_TTH
      TYPE ( TTH_DESCRIP )  ANG_ROT_TTH
      TYPE ( TTH_DESCRIP )  ANG_VEL_TTH
      TYPE ( TTH_DESCRIP )  BELT_TTH
      TYPE ( TTH_DESCRIP )  CG_TTH
      TYPE ( TTH_DESCRIP )  HARNESS_TTH
      TYPE ( TTH_DESCRIP )  JOINT_FORCE_TTH
      TYPE ( TTH_DESCRIP )  JOINT_PARM_TTH
      TYPE ( TTH_DESCRIP )  LIN_ACCEL_TTH
      TYPE ( TTH_DESCRIP )  LIN_DISP_TTH
      TYPE ( TTH_DESCRIP )  LIN_VEL_TTH
      TYPE ( TTH_DESCRIP )  PLANE_SEG_TTH
      TYPE ( TTH_DESCRIP )  SEG_SEG_TTH
      TYPE ( TTH_DESCRIP )  SPRING_DAMP_TTH
      TYPE ( TTH_DESCRIP )  WATER_TTH
      TYPE ( TTH_DESCRIP )  WIND_TTH
!C
!C-----------------------------------------------------------------------------
!C    Define the structure and parameters for 
!C     time-windowing the output.
!C
!C     MAX_NUM_OUT_TIMES - the maximun number of time windows permitted,
!C     NUM_OUT_TIMES     - the number of time windows for a particular run.
!C
      INTEGER  ( KIND = INTEGER_STD)  MAX_NUM_OUT_TIMES
      INTEGER  ( KIND = INTEGER_STD)  NUM_OUT_TIMES
      PARAMETER ( MAX_NUM_OUT_TIMES = I_3 )
!C
!C      For this structure:
!C            PRINT - a logical flag; if true, the time windowing option
!C                    applies to output from Subroutine PRINT, if false,
!C                    time windowing is ignored by Subroutine PRINT
!C            TTH   - a logical flag; if true, the time windowing option
!C                    applies to the tabular time history output, if false,
!C                    time windowing is ignored for the tabular time histories
!C            VIEW  - a logical flag; if true, the time windowing option
!C                    applies to output for VIEW output, if false, time
!C                    windowing is ignored for VIEW output
!C
!C            START - the time, in seconds, when the time window begins
!C                    for data to be outputted, this time is the simulation
!C                    time, i.e. relative to time = 0.0 when the integration
!C                    begins for a particular simulation
!C            END   - the time, in seconds, when the time window stops, this
!C                    time is the simulation time
!C
      TYPE OUTPUT_TIMES
       LOGICAL  ( KIND = LOGICAL_STD )  PRINT
       LOGICAL  ( KIND = LOGICAL_STD )  TTH
       LOGICAL  ( KIND = LOGICAL_STD )  VIEW
       REAL ( KIND = IREAL_HIGH )  START
       REAL ( KIND = IREAL_HIGH )  END
      END TYPE OUTPUT_TIMES
!C
!C    Define the time control structure.
!C
      TYPE ( OUTPUT_TIMES) OUT_TIMES(MAX_NUM_OUT_TIMES)
!C
!C-----------------------------------------------------------------------------
!C    Define the segment structure.
!C
      TYPE SEGMENT
       REAL      ( KIND = IREAL_HIGH )          ANG_ACCEL(3)   ! was WMEGD
       REAL      ( KIND = IREAL_HIGH )          ANG_ACL_CONV(3)! was SGTEST(,3,)
       REAL      ( KIND = IREAL_HIGH )          ANG_VEL(3)     ! was WMEG
       REAL      ( KIND = IREAL_HIGH )          ANG_VEL_CONV(3)! was SGTEST(,1,)
       REAL      ( KIND = IREAL_HIGH )          DIR_COS(3,3)   ! was D
       REAL      ( KIND = IREAL_HIGH )          DRC_PHI(3,3)   ! was DPMI 
       REAL      ( KIND = IREAL_HIGH )          EXT_ANG_ACL(3) ! was U2
       REAL      ( KIND = IREAL_HIGH )          EXT_LIN_ACL(3) ! was U1
       REAL      ( KIND = IREAL_HIGH )          LIN_ACCEL(3)   ! was SEGLA
       REAL      ( KIND = IREAL_HIGH )          LIN_ACL_CONV(3)! was SGTEST(,4,)
       REAL      ( KIND = IREAL_HIGH )          LIN_DISP(3)    ! was SEGLP
       REAL      ( KIND = IREAL_HIGH )          LIN_VEL(3)     ! was SEGLV
       REAL      ( KIND = IREAL_HIGH )          LIN_VEL_CONV(3)! was SGTEST(,2,)
       CHARACTER ( LEN = 4, KIND = ICHAR_STD )  NAME           ! was SEG
       REAL      ( KIND = IREAL_HIGH )          PHI(3)         ! was PHI
       REAL      ( KIND = IREAL_HIGH )          RECIP_MASS     ! was RW
       REAL      ( KIND = IREAL_HIGH )          RECIP_PHI(3)   ! was RPHI
       LOGICAL   ( KIND = LOGICAL_STD )         ROT_PHI        ! was LPMI
       INTEGER   ( KIND = INTEGER_STD )         SINGULAR       ! was ISING
       REAL      ( KIND = IREAL_HIGH )          WEIGHT         ! was W
      END TYPE SEGMENT
!C
      TYPE ( SEGMENT ) SEG
      DIMENSION        SEG(MAXSEG)
!C
!C-----------------------------------------------------------------------------
!C    Define the joint structure.  Commented out items within the
!C     structure have not yet been implemented.
!C
      TYPE JOINT
       CHARACTER ( LEN = 4, 
     &             KIND = ICHAR_STD )     JNT_NAME        ! was JOINT
       INTEGER   ( KIND = INTEGER_STD )   PROX_SEG        ! was JNT
       LOGICAL   ( KIND = LOGICAL_STD )   EULER           ! was EULER
       LOGICAL   ( KIND = LOGICAL_STD )   SLIP_FREE       ! was FREE
!c       INTEGER   ( KIND = INTEGER_STD )   DSTL_SEG        ! new J+1
       REAL      ( KIND = IREAL_HIGH )    PROX_LOC(3)     ! was SR(1-3,2*J-1)
       REAL      ( KIND = IREAL_HIGH )    DSTL_LOC(3)     ! was SR(1-3,2*J)
       REAL      ( KIND = IREAL_HIGH )    PROX_CNST       ! was SR(4,2*J-1)
       REAL      ( KIND = IREAL_HIGH )    DSTL_CNST       ! was SR(4,2*J)
       INTEGER   ( KIND = INTEGER_STD )   JTYPE           ! was IPIN
!c       INTEGER   ( KIND = INTEGER_STD )   IEULER          ! was IEULER
!c       INTEGER   ( KIND = INTEGER_STD )   ISLIP           ! was ISLIP
       REAL      ( KIND = IREAL_HIGH )    TENS_MAX        ! was CONST(1,)
       REAL      ( KIND = IREAL_HIGH )    COMP_MAX        ! was CONST(2,)
!c       REAL      ( KIND = IREAL_HIGH )    PROX_COORD(3,3) ! was HT(3,3,2*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    DSTL_COORD(3,3) ! was HT(3,3,2*J)
!c       INTEGER   ( KIND = INTEGER_STD )   PROX_NODE(3)    ! was NODJ(,1)
       REAL      ( KIND = IREAL_HIGH )    PROX_HA(3)         ! was HA(3,2*J-1)
       REAL      ( KIND = IREAL_HIGH )    DSTL_HA(3)         ! was HA(3,2*J)
       REAL      ( KIND = IREAL_HIGH )    PROX_HB(3)         ! was HB(3,2*J-1)
       REAL      ( KIND = IREAL_HIGH )    DSTL_HB(3)         ! was HB(3,2*J)
!c       INTEGER   ( KIND = INTEGER_STD )   DSTL_NODE(3)    ! was NODJ(,2)
!C
!c       REAL      ( KIND = IREAL_HIGH )    PROX_ROT(3)     ! was YPR1
!c       REAL      ( KIND = IREAL_HIGH )    DSTL_ROT(3)     ! was YPR2
!c       INTEGER   ( KIND = INTEGER_STD )   PROX_SEQ(3)     ! was IDYPR(1-3)
!c       INTEGER   ( KIND = INTEGER_STD )   DSTL_SEQ(3)     ! was IDYPR(4-6)
!c       REAL      ( KIND = IREAL_HIGH )    INIT_ROT_ANG(3) ! was ANG(3)
       REAL      ( KIND = IREAL_HIGH )    CNTR_SYM(3)     ! was CONST(1-3,)
       REAL      ( KIND = IREAL_HIGH )    COS_NUTA        ! was CONST(4,)
       REAL      ( KIND = IREAL_HIGH )    SIN_NUTA        ! was CONST(5,)
!C
!c       REAL      ( KIND = IREAL_HIGH )    FLX_LIN_COEF    ! was SPRING(,1,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    FLX_QUA_COEF    ! was SPRING(,2,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    FLX_CUB_COEF    ! was SPRING(,3,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    FLX_ENRG_DIS    ! was SPRING(,4,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    FLX_JNT_STOP    ! was SPRING(,5,3*J-2)
!C
!c       REAL      ( KIND = IREAL_HIGH )    TRQ_LIN_COEF    ! was SPRING(,1,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    TRQ_QUA_COEF    ! was SPRING(,2,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    TRQ_CUB_COEF    ! was SPRING(,3,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    TRQ_ENRG_DIS    ! was SPRING(,4,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    TRQ_JNT_STOP    ! was SPRING(,5,3*J-1)
!C
!c       REAL      ( KIND = IREAL_HIGH )    SPN_LIN_COEF    ! was SPRING(,1,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_QUA_COEF    ! was SPRING(,2,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_CUB_COEF    ! was SPRING(,3,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_ENRG_DIS    ! was SPRING(,4,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_JNT_STOP    ! was SPRING(,5,3*J)
!C
!c       REAL      ( KIND = IREAL_HIGH )    PRE_VIS_COEF    ! was VISC(1,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    PRE_COU_FRIC    ! was VISC(2,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    PRE_REL_ANG_VEL ! was VISC(3,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    PRE_MAX_TORQ    ! was VISC(4,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    PRE_MIN_TORQ    ! was VISC(5,3*J-2) 
!c       REAL      ( KIND = IREAL_HIGH )    PRE_MIN_ANG_VEL ! was VISC(6,3*J-2)
!c       REAL      ( KIND = IREAL_HIGH )    PRE_COEF_RST    ! was VISC(7,3*J-2)
!C
!c       REAL      ( KIND = IREAL_HIGH )    NUT_VIS_COEF    ! was VISC(1,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    NUT_COU_FRIC    ! was VISC(2,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    NUT_REL_ANG_VEL ! was VISC(3,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    NUT_MAX_TORQ    ! was VISC(4,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    NUT_MIN_TORQ    ! was VISC(5,3*J-1) 
!c       REAL      ( KIND = IREAL_HIGH )    NUT_MIN_ANG_VEL ! was VISC(6,3*J-1)
!c       REAL      ( KIND = IREAL_HIGH )    NUT_COEF_RST    ! was VISC(7,3*J-1)
!C
!c       REAL      ( KIND = IREAL_HIGH )    SPN_VIS_COEF    ! was VISC(1,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_COU_FRIC    ! was VISC(2,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_REL_ANG_VEL ! was VISC(3,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_MAX_TORQ    ! was VISC(4,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_MIN_TORQ    ! was VISC(5,3*J) 
!c       REAL      ( KIND = IREAL_HIGH )    SPN_MIN_ANG_VEL ! was VISC(6,3*J)
!c       REAL      ( KIND = IREAL_HIGH )    SPN_COEF_RST    ! was VISC(7,3*J)
!C
       REAL      ( KIND = IREAL_HIGH )    JFORCE(3)       ! was F
       REAL      ( KIND = IREAL_HIGH )    JTORQUE(3)      ! was TQ
      END TYPE JOINT
!C
      TYPE ( JOINT ) JNT
      DIMENSION      JNT(MAXJNT)
!C
!C-----------------------------------------------------------------------------
!C    Define the vehicle structure:  
!C
!C      VNAME       = name of the vehicle
!C      VTITLE      = description of the vehicle
!C      IVFLG       = flag denoting whether the prescribed motion is
!C                    relative to the ground (0) or a segment (1 or 2)
!C      IVSEG       = vehicle segment number
!C      IVREF       = segment number to which the prescribed motion 
!C                    is relative to
!C      NUM_VTAB    = number of time points of the vehicle acceleration
!C                    profile for options 2, 3, 4
!C      VNORMAL     = normal vector for the direction of the acceleration
!C                    pulse for options 1 and 2
!C      LIN_DATA    = linear vector acceleration time profile for the vehicle
!C      ANG_DATA    = angular vector acceleration time profile for the vehicle
!C      VOMEGA      = frequency for the half-sine wave option
!C      VINIT_TIME  = initial time of the vehicle acceleration profile for
!C                    options 2, 3, 4
!C      VDELTA_TIME = time interval of the vehicle acceleration profile data
!C                    for options 2, 3, 4
!C      TIMEV       = time duration of the half-sine wave deceleration for
!C                    option 1 of the vehicle input
!C
      TYPE VEHICLE
       CHARACTER ( LEN = 4,  KIND = ICHAR_STD )    VNAME      ! was VEH
       CHARACTER ( LEN = 80, KIND = ICHAR_STD )    VTITLE     ! was VPSTTL
       INTEGER   ( KIND = INTEGER_STD )   IVFLG               ! was IVREF(1,)
       INTEGER   ( KIND = INTEGER_STD )   IVSEG               ! was IVREF(2,)
       INTEGER   ( KIND = INTEGER_STD )   IVREF               ! was IVREF(3,)
       INTEGER   ( KIND = INTEGER_STD )   NUM_VTAB            ! was NVTAB(6)
       REAL      ( KIND = IREAL_HIGH )    VNORMAL(3)          ! was AXV(3,6)
       REAL      ( KIND = IREAL_HIGH )    LIN_DATA(3,MAXVDT)  ! was VATAB(1-3,,)
       REAL      ( KIND = IREAL_HIGH )    ANG_DATA(3,MAXVDT)  ! was VATAB(4-6,,)
       REAL      ( KIND = IREAL_HIGH )    VOMEGA              ! was OMEGV(6)
       REAL      ( KIND = IREAL_HIGH )    VINIT_TIME          ! was VT0(6)
       REAL      ( KIND = IREAL_HIGH )    VDELTA_TIME         ! was VTD(6)
       REAL      ( KIND = IREAL_HIGH )    TIMEV               ! was TIMEV(6)
      END TYPE VEHICLE
!C
      TYPE ( VEHICLE )  VEH
      DIMENSION         VEH(MAXVEH)
!C
!C-----------------------------------------------------------------------------
!C    Define the joint actuator structure:  
!C
!C      ACT_JNT            = joint number the actuator is associated with
!C      BASE_SEG           = segment number to be the base segment for the 
!C                            actuator
!C      TARGET_ANGLE_FUNCT = function number for the target joint angle for  
!C                            joint ACT_JNT, which the desired angle between 
!C                            the two joint coordinate systems associated with
!C                            joint ACT_JNT
!C      PROPOR_FUNCT       = function number for the proportional gain control 
!C                            variable in the actuator torque control equation  
!C      DERIV_FUNCT        = function number for the derivative gain control
!C                            variable in the actuator torque control equation
!C      INTEGRAL_FUNCT     = function number for the integral gain control
!C                            variable in the actuator torque control equation
!C      TOR_AXIS           = vector for the torque axis of the actuator joint,
!C                            which is equal to the pin axis of the joint the
!C                            actuator is associated with
!C      ACT_TORQ           = magnitude of actuator torque based on PID control
!C      PROP_TORQ          = proportional component of actuator torque
!C      DERIV_TORQ         = derivative component of actuator torque
!C      INTEGRAL_TORQ      = integral component of actuator torque
!C      ACT_JNT_ANGLE      = angle of joint associated with actuator
!C      ACT_JNT_VEL        = velocity of joint associated with actuator      
!C
      TYPE ACTUATOR
       INTEGER   ( KIND = INTEGER_STD )   ACT_JNT             ! was NRJNT
       INTEGER   ( KIND = INTEGER_STD )   BASE_SEG            ! was NRS
       INTEGER   ( KIND = INTEGER_STD )   TARGET_ANGLE_FUNCT  ! was NRF(1,)
       INTEGER   ( KIND = INTEGER_STD )   PROPOR_FUNCT        ! was NRF(2,)
       INTEGER   ( KIND = INTEGER_STD )   DERIV_FUNCT         ! was NRF(3,)
       INTEGER   ( KIND = INTEGER_STD )   INTEGRAL_FUNCT      ! was NRF(4,)
       REAL      ( KIND = IREAL_HIGH )    TOR_AXIS(3)         ! was QRU(1-3,)
       REAL      ( KIND = IREAL_HIGH )    ACT_TORQ            ! was TORQUE(1,)
       REAL      ( KIND = IREAL_HIGH )    PROP_TORQ           ! was TORQUE(2,)
       REAL      ( KIND = IREAL_HIGH )    DERIV_TORQ          ! was TORQUE(3,)
       REAL      ( KIND = IREAL_HIGH )    INTEGRAL_TORQ       ! was TORQUE(4,)
       REAL      ( KIND = IREAL_HIGH )    ACT_JNT_ANGLE       ! was TORQUE(5,)
       REAL      ( KIND = IREAL_HIGH )    ACT_JNT_VEL         ! was TORQUE(6,)
      END TYPE ACTUATOR
!C
      TYPE ( ACTUATOR )  ACT
      DIMENSION         ACT(MAXJNT)
!C
!C
!C****************************************************************************
!C    Define the global variables.
!C****************************************************************************
!C
!C    /ABDATA/
!C
      INTEGER  ( KIND = INTEGER_STD)  IFULL
      DIMENSION  IFULL(6)
!C
      REAL ( KIND = IREAL_HIGH)  
     &                  ZDEP, DBR, DPVCTR, DEPLOY, AB, B, ZR, BFB,
     &                  DRR, VBAGG, VSCS, SPRK, CK, CMASS, CYMIN,
     &                  CYMOUT, BAGPV, PD, VBAG, VOLBP, PCYV, 
     &                  PCYMIN, PVBAG, TV1, TV2, SWITCH, PYMOUT,
     &                  SCALEX, PREVT
      DIMENSION  ZDEP(3,5), DBR(3,3,5), DPVCTR(3,5), DEPLOY(3,5),          
     &           AB(3,5), B(9,4,5), ZR(3,4,5), BFB(3,4,5), DRR(9,4,5),     
     &           VBAGG(5), VSCS(5), SPRK(5), CK(5), CMASS(5), CYMIN(5),    
     &          CYMOUT(5), BAGPV(5), PD(5), VBAG(5), VOLBP(5),             
     &         PCYV(5), PCYMIN(5), PVBAG(5), TV1(3,4,5), TV2(3,10,5),      
     &          SWITCH(5), PYMOUT(5), SCALEX(5)                           
!C
!C     COMMON /ABDATA/  ZDEP, DBR, DPVCTR, DEPLOY, AB, B, ZR, BFB,
!C    *                 DRR, VBAGG, VSCS, SPRK, CK, CMASS, CYMIN,
!C    *                 CYMOUT, BAGPV, PD, VBAG, VOLBP, PCYV, 
!C    *                 PCYMIN, PVBAG, TV1, TV2, SWITCH, PYMOUT,
!C    *                 SCALE, PREVT, IFULL
!C
!C****************************************************************************
!C
!C     /ACTFR/
!C
      INTEGER  ( KIND = INTEGER_STD )  NRTORQ
!C
!C      COMMON /ACTFR/  QRU, TORQUE, NRTORQ, NRJNT, NRS                   
!C
!C****************************************************************************
!C
!C     /ACTFR1/
!C
      REAL  ( KIND = IREAL_HIGH )  ACT_TIME_PREV, ACT_THETA_CUR, 
     &                                            ACT_THETA_PREV
!C
!C      COMMON /ACTFR1/  NRF, TIMEI, THETAI                                
!C
!C****************************************************************************
!C
!C     /BAGDIM/
!C
!C    This common block was in Subroutine U1ASCD in V.1, but not in
!C     BLOCK DATA.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           IBMODL, IBSHP, IBATT, IBFOLD, IBDPLY, IBMOV, IBSEG,
     &           NBSEG, NDPLT, NDPLPT
      DIMENSION  IBMODL(MAXBAG), IBSHP(MAXBAG), IBATT(MAXBAG),
     &           IBFOLD(MAXBAG), IBDPLY(MAXBAG), IBMOV(MAXBAG),
     &           IBSEG(MAXBAG), NBSEG(MAXBAG), NDPLT(MAXBAG),
     &           NDPLPT(MAXBDT,MAXBAG)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  BAGSHP, BAGAXS, DPLX, DPLA, DPLTIM, ATTDIM, 
     &                  FOLDX, DPLYT, DPLYPT, PNL1, PNL2, PNL3,
     &                  BLEN, BAREA, BVOL, BWGT
      DIMENSION        BAGSHP(3,MAXBSH,MAXBAG), BAGAXS(MAXBSH,MAXBAG),
     &                 DPLX(3,MAXBAG), DPLA(3,MAXBAG), DPLTIM(MAXBAG),
     &                 ATTDIM(2,MAXBAG), FOLDX(4,MAXBAG),
     &                 DPLYT(MAXBDT,MAXBAG), DPLYPT(MAXBDP,MAXBAG),
     &                 PNL1(3), PNL2(3), PNL3(3), BLEN(MAXBAG),
     &                 BAREA(MAXBAG), BVOL(MAXBAG), BWGT(MAXBAG)
!C
!C*******
!C
!C    /CDH10C/
!C
      INTEGER  ( KIND = INTEGER_STD )  ISEQ, IDCG
      DIMENSION  ISEQ(3,5), IDCG(5)
!C
      REAL  ( KIND = IREAL_HIGH )  ORIGIN, XYZANG
      DIMENSION  ORIGIN(3,5), XYZANG(3,5)
!C
!C     COMMON /CDH10C/ ORIGIN, XYZANG, ISEQ, IDCG               
!C
!C****************************************************************************
!C
!C    /CDINT/
!C
!C    NOTE:  FF REPLACES F.                                                
!C
      INTEGER  ( KIND = INTEGER_STD )  ICNT, IDBL, IFLAG
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  UU, GH, E, FF, GG, Y, U, H, HPRINT, TSAVE,
     &                  TPRINT, TSTART
      DIMENSION  UU(4), GH(3,4), E(3,3*MAXEQN), FF(5,3*MAXEQN),
     &           GG(5,3*MAXEQN), Y(5,3*MAXEQN), U(5,3*MAXEQN)
!C
!C     COMMON/CDINT/  UU, GH, E, FF, GG, Y, U, H, HPRINT, TSAVE,
!C    *               TPRINT, TSTART, ICNT, IDBL, IFLAG                     
!C
!C****************************************************************************
!C
!C    /CEULER/
!C
      INTEGER  ( KIND = INTEGER_STD )  IEULER
      DIMENSION  IEULER(MAXJNT)
!C
      REAL  ( KIND = IREAL_HIGH )  HIR, ANG, ANGD, FE, TQE
      DIMENSION  HIR(3,3,3*MAXJNT), ANG(3,MAXJNT), ANGD(3,MAXJNT),
     &           FE(3,MAXJNT), TQE(3,MAXJNT)
!C
!C    COMMON/CEULER/ IEULER, HIR, ANG, ANGD, FE, TQE, CONST
!C
!C****************************************************************************
!C
!C    /CMATRX/
!C
      REAL  ( KIND = IREAL_HIGH )  
     &           V1, V2, V3, B12, A22, WJ, A11
      DIMENSION  V1(3,MAXJNT), V2(3,MAXJNT), V3(3,MAXCST),
     &           B12(3,3,2*MAXJNT), A22(3,3,2*MAXJNT),
     &           WJ(MAXJNT), A11(3,3,MAXJNT)
!C
!C    COMMON /CMATRX/ V1, V2, V3, B12, A22, F, TQ, WJ, A11
!C
!C****************************************************************************
!C
!C    /CNSNTS/   
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  PI, RADIAN, G, EPS, GRAVTY, TWOPI
      DIMENSION         EPS(24), GRAVTY(3)
!C
      CHARACTER ( LEN = 8, KIND = ICHAR_STD )  UNITL, UNITM, UNITT
!C
!C    COMMON /CNSNTS/ PI, RADIAN, G, THIRD, EPS,                              
!C   *                UNITL, UNITM, UNITT, GRAVTY, TWOPI                     
!C    Note:  added the constant ZERO to this grouping.
!C
!C****************************************************************************
!C
!C    /CNTSRF/
!C
      REAL  ( KIND = IREAL_HIGH )  PL, BELT, TPTS, BD, BELT_FORCE
      DIMENSION  PL(24,MAXPLN), BELT(20,MAX_NUM_BELTS), 
     &           TPTS(6,MAX_NUM_BELTS), BD(24,MAXELP), 
     &           BELT_FORCE(4,MAX_NUM_BELTS)
!C
!C    COMMON /CNTSRF/ PL, BELT, TPTS, BD  
!C
!C****************************************************************************
!C
!C    /COMAIN/
!C
      INTEGER  ( KIND = INTEGER_STD )  ISTEP, NSTEPS, NDINT, NEQ
!C
      REAL  ( KIND = IREAL_HIGH )  VAR, DER, DT, H0, HMAX, HMIN
      DIMENSION  VAR(3*MAXEQN), DER(3*MAXEQN)
!C
!C     COMMON /COMAIN/  VAR, DER, DT, H0, HMAX, HMIN, ISTEP, NSTEPS,        
!C    *                 NDINT, NEQ                                          
!C
!C****************************************************************************
!C
!C    /CONTRL/
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         NSEG, NJNT, NPL, NBLT, NBAG, NVEH, NGRND,
     &         NS, NQ, NSD, NFLX, NHRNSS, NWINDF, NJNTF, NPRT,
     &         NPG
      DIMENSION  NPRT(36)
!C
      REAL  ( KIND = IREAL_HIGH )  TIME
!C
!C    COMMON /CONTRL/ TIME, NSEG, NJNT, NPL, NBLT, NBAG, NVEH, NGRND,      
!C   *                NS, NQ, NSD, NFLX, NHRNSS, NWINDF, NJNTF, NPRT,
!C   *                NPG                                                    
!C
!C****************************************************************************
!C
!C    /COUT/  
!C
!C    Was in Subroutine FINPUT, HEDING in Release V.1, but was not
!C     included in the BLOCK DATA routine.
!C 
      INTEGER  ( KIND = INTEGER_STD )   NOUTPS, NOUTSS 
      DIMENSION  NOUTPS(MAXPSF), NOUTSS(MAXSSF)
!C
!C      COMMON/COUT/ NOUTPS(MAXPSF), NOUTSS(MAXSSF)                       
!C
!C
!C****************************************************************************
!C
!C      /COUTFMT/
!C
!C    This common was in Subroutine U1ASCD in V.1, but not in the BLOCK 
!C     DATA.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         IBAGFM, IBAGTY, IHARFM, IHARTY, IRGDFM, IRGDTY,
     &         ITIMFM, ITIMTY
!C
!C	COMMON/COUTFMT/  ITIMTY,ITIMFM,IRGDTY,IRGDFM,
!C     *                 IBAGTY,IBAGFM,IHARTY,IHARFM
!C
!C****************************************************************************
!C
!C      /COUTN/
!C
!C    This common was in Subroutine U1ASCD in V.1, but not in the BLOCK
!C     DATA statement.
!C
      INTEGER  ( KIND = INTEGER_STD )  NTOBLT, NTOPTS, LDUM, LPREV
!C      
!C	COMMON/COUTN/    NTOBLT,NTOPTS,LDUM,LPREV
!C
!C
!C****************************************************************************
!C
!C    /CSTRNT/
!C
      INTEGER   ( KIND = INTEGER_STD )  KQ1, KQ2, KQTYPE
      DIMENSION  KQ1(MAXCST), KQ2(MAXCST), KQTYPE(MAXCST)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A13, A23, B31, B32, HHT, RK1, RK2, QQ, TQQ,
     &                  RQQ, HQQ, SQQ, CFQQ
      DIMENSION  A13(3,3,I_2*MAXCST), A23(3,3,I_2*MAXCST), 
     &           B31(3,3,I_2*MAXCST), B32(3,3,I_2*MAXCST),
     &           HHT(3,3,MAXCST), RK1(3,MAXCST), RK2(3,MAXCST), 
     &           QQ(3,MAXCST), TQQ(3,MAXCST), RQQ(3,MAXCST), 
     &           HQQ(3,MAXCST), SQQ(MAXCST), CFQQ(MAXCST)     
!C
!C     COMMON /CSTRNT/ A13, A23, B31, B32, HHT, RK1, RK2, QQ, TQQ,
!C    *                RQQ, HQQ, SQQ, CFQQ, KQ1, KQ2, KQTYPE
!C
!C****************************************************************************
!C
!C    /CYDATA/
!C
      REAL ( KIND = IREAL_HIGH )
     &                CYTD, CYPA, CYSP, CYT0, CYV0, CYCD, CYK, CYR,
     &                 CYAT, CYPV, CYCD0, CYP0, CYSS, CYL0, CYC, CYA0,
     &                 CYRHO0, CYVMAX, CYORFC, CYRHO, CYT, CYP, CYV
      DIMENSION   CYTD(MAXBAG), CYPA(MAXBAG), CYSP(MAXBAG),
     &            CYT0(MAXBAG), CYV0(MAXBAG), CYCD(MAXBAG),    
     &            CYK(MAXBAG), CYR(MAXBAG), CYAT(MAXBAG), 
     &            CYPV(MAXBAG), CYCD0(MAXBAG), CYP0(MAXBAG),     
     &            CYSS(MAXBAG), CYL0(MAXBAG), CYC(MAXBAG), 
     &            CYRHO0(MAXBAG), CYVMAX(MAXBAG), CYORFC(MAXBAG), 
     &            CYRHO(MAXBAG), CYT(MAXBAG), CYP(MAXBAG), 
     &            CYV(MAXBAG), CYA0(MAXBAG)     
!C
!C      COMMON /CYDATA/   CYTD, CYPA, CYSP, CYT0, CYV0, CYCD, CYK, CYR,
!C     *                  CYAT, CYPV, CYCD0, CYA0, CYP0, CYSS, CYL0, CYC, 
!C     *                  CYRHO0, CYVMAX, CYORFC, CYRHO, CYT, CYP, CYV
!C
!C****************************************************************************
!C
!C    /DAMPER/
!C
      INTEGER  ( KIND = INTEGER_STD )  MSDM, MSDN
      DIMENSION  MSDM(MAX_NUM_DAMPERS), MSDN(MAX_NUM_DAMPERS)
!C
      REAL ( KIND = IREAL_HIGH )  APSDM, APSDN, ASD, DAMP_FORCE
      DIMENSION  APSDM(3,MAX_NUM_DAMPERS), APSDN(3,MAX_NUM_DAMPERS), 
     &           ASD(5,MAX_NUM_DAMPERS), DAMP_FORCE(4,MAX_NUM_DAMPERS)
!C
!C    COMMON/DAMPER/ APSDM, APSDN, ASD, MSDM, MSDN   
!C
!C****************************************************************************
!C
!C    /DESCRP/
!C
      INTEGER  ( KIND = INTEGER_STD ) IGLOB, JOINTF
      DIMENSION  IGLOB(MAXJNT), JOINTF(3,MAXJNT)
!C
      REAL  ( KIND = IREAL_HIGH )  
     &            HT, SPRING, VISC
      DIMENSION  HT(3,3,2*MAXJNT), SPRING(5,3*MAXJNT),
     &           VISC(7,3*MAXJNT)
!C
!C     COMMON /DESCRP/ PHI, W, RW, SR, HA, HB, RPHI, HT, SPRING,
!C    *                VISC, JNT, IPIN, ISING, IGLOB, JOINTF
!C
!C****************************************************************************
!C
!C    /FILEN/
!C
      CHARACTER ( LEN = 32, KIND = ICHAR_STD )  INFIL, OUTFIL
      CHARACTER ( LEN = 80, KIND = ICHAR_STD )  WORK_DIRECTORY
!C
!C    COMMON/FILEN/  OUTFIL                                             
!C
!C****************************************************************************
!C
!C    /FLXBLE/
!C
      INTEGER  ( KIND = INTEGER_STD )  NFLEX
      DIMENSION  NFLEX(3,MAXFLX)
!C
      REAL  ( KIND = IREAL_HIGH )   HF, B42, V4
      DIMENSION  HF(4,12,MAXFLX), B42(3,3,I_3*MAXFLX), V4(3,MAXFLX)
!C
!C    COMMON /FLXBLE/  HF, B42, V4, NFLEX                                 
!C
!C****************************************************************************
!C
!C    /FORCES/ 
!C
!C    NBGSF         = number of airbag-segment tabular time histories
!C    NBSF          = number of harness belt tabular time histories
!C    NPANEL        =
!C    NPSF          = number of plane-segment tabular time histories
!C    NSSF          = number of segment-segment tabular time histories
!C    
!C    BAGSF         = array containing airbag-segment tabular time history data
!C    HARNESS_FORCE = array containing harness belt tabular time history data
!C    PRJNT         = array containing joint tabular time history data
!C    PSF           = array containing plane-segment tabular time history data
!C    SSF           = array containing segment-segment tabular time history data
!C
      INTEGER  ( KIND = INTEGER_STD )   NPANEL, NPSF, NBSF, NSSF, NBGSF
      DIMENSION  NPANEL(MAXBAG)
!C
      REAL  ( KIND = IREAL_HIGH )   PSF, HARNESS_FORCE, SSF, BAGSF, 
     &                              PRJNT
      DIMENSION  PSF(7,MAXPSF), HARNESS_FORCE(4,MAXHBLT), 
     &           SSF(10, MAXSSF), BAGSF(3,20), PRJNT(7,MAXJNT)
!C 
!C     COMMON /FORCES/ PSF, BSF, SSF, BAGSF, PRJNT, NPANEL, NPSF, NBSF, 
!C    *                NSSF, NBGSF                                          
!C
!C****************************************************************************
!C
!C    /HBPTRB/
!C
!C    HRN_EPSDEL  = maximum strain convergence criterion used for balancing
!C                  the harness belts
!C    HRN_MAX_ITR = maximum number of iterations used to meet the maximum
!C                  strain convergence criterion for the harness belts
!C
      INTEGER  ( KIND = INTEGER_STD )  HRN_MAX_ITR
!C
      REAL  ( KIND = IREAL_HIGH )   HRN_EPSDEL
!C
!C    COMMON /HBPTRB/  EPSDEL, MAXITR                                   
!C
!C****************************************************************************
!C
!C    /HRNESS/
!C
      INTEGER  ( KIND = INTEGER_STD ) 
     &           IBAR, NL, NPTSPB, NPTPLY, NTHRNS, NBLTPH, KEEP
      DIMENSION  IBAR(5,MAXHPT), NL(2,MAXHPT), NPTSPB(MAXHBLT),
     &           NPTPLY(MAXHBLT), NTHRNS(MAXHBLT,25), NBLTPH(MAXHRN), 
     &           KEEP(MAXHPT)
!C
      REAL  ( KIND = IREAL_HIGH )  BAR, BB, BBDOT, PLOSS, XLONG, HTIME
      DIMENSION  BAR(15,MAXHPT), BB(MAXHPT), BBDOT(MAXHPT), 
     &           PLOSS(2,MAXHPT), XLONG(MAXHBLT), HTIME(2)
!C
!C     COMMON /HRNESS/ BAR, BB, BBDOT, PLOSS, XLONG, HTIME, IBAR, NL,   
!C    *                NPTSPB, NPTPLY, NTHRNS, NBLTPH, KEEP   
!C
!C****************************************************************************
!C
!C    /INTEST/
!C
      CHARACTER ( LEN = 4, KIND = ICHAR_STD )  SEGT
      DIMENSION      SEGT(4*MAXSEG)
!C
      REAL  ( KIND = IREAL_HIGH )  XTEST
      DIMENSION  XTEST(3,4*MAXSEG)
!C
!C    Create single dimensioned versions of the XTEST and REGT arrays
!C     for Subroutines DINTG and PDAUX.
!C
      CHARACTER ( LEN = 8, KIND = ICHAR_STD )  REGT_SNGL
      DIMENSION      REGT_SNGL(4*MAXSEG)
!C
      REAL  ( KIND = IREAL_HIGH )  XTEST_SNGL
      DIMENSION  XTEST_SNGL(3*4*MAXSEG)
!C
      EQUIVALENCE  ( XTEST, XTEST_SNGL )
!C
!C    COMMON /INTEST/  SGTEST, XTEST, SEGT, REGT
!C
!C****************************************************************************
!C
!C    /JBARTZ/
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         MNPL, MNBLT, MNSEG, MNBAG, MPL, MBLT, MSEG, MBAG,
     &         NTPL, NTBLT, NTSEG
      DIMENSION  MNPL(MAXPLN), MNBLT(MAX_NUM_BELTS), MNSEG(MAXSEG),
     &           MNBAG(6), MPL(3,5,MAXPLN), MBLT(3,5,MAX_NUM_BELTS),
     &           MSEG(3,5,MAXSEG), MBAG(3,10,6), NTPL(5,MAXPLN),
     &           NTBLT(5,MAX_NUM_BELTS), NTSEG(5,MAXSEG)
!C
!C     COMMON/JBARTZ/ MNPL, MNBLT, MNSEG, MNBAG, MPL, MBLT, MSEG,  
!C    *               MBAG, NTPL, NTBLT, NTSEG                              
!C
!C****************************************************************************
!C
!C    /RSAVE/
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &           NSG, MSG, MCG, MCGIN, KREF, MJS
      DIMENSION  NSG(10), MSG(MAX_HCARD_TTH,10), 
     &           MCGIN(24,MAX_TOTAL_BODY),
     &           KREF(MAX_HCARD_TTH,10), MJS(MAX_HCARD_TTH,2) 
!C
      REAL  ( KIND = IREAL_HIGH )  XSG
      DIMENSION  XSG(3,MAX_HCARD_TTH,3)
!C
!C    COMMON /RSAVE/  XSG, DPMI, LPMI, NSG, MSG, MCG, MCGIN, KREF, MJS   
!C
!C****************************************************************************
!C
!C    /SGMNTS/
!C
       INTEGER   ( KIND = INTEGER_STD )   SYMMETRY          ! was NSYM
       DIMENSION                          SYMMETRY(MAXSEG)
!C
!C    COMMON /SGMNTS/ D, WMEG, WMEGD, U1, U2, SEGLP, SEGLV, SEGLA, NSYM
!C
!C****************************************************************************
!C
!C    /TABLES/
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                       MXNTB, MXTB1, MXTB2, NTI, NTAB
      DIMENSION  NTI(MAX_FUNC), NTAB(MAXNTB)
!C
      REAL  ( KIND = IREAL_HIGH )   TAB
      DIMENSION  TAB(MAXTAB)
!C
!C    COMMON /TABLES/ MXNTI, MXNTB, MXTB1, MXTB2, NTI, NTAB, TAB        
!C
!C****************************************************************************
!C
!C     /TEMPVI/
!C
      INTEGER   ( KIND = INTEGER_STD )  JSTOP
      DIMENSION  JSTOP(4,2,MAXJNT)
!C
      REAL  ( KIND = IREAL_HIGH  )   CREST, TTI, R1I, R2I
      DIMENSION  TTI(3), R1I(3), R2I(3)
!C
!C    COMMON /TEMPVI/  CREST, TTI, R1I, R2I, JSTOP                         
!C
!C****************************************************************************
!C
!C    /TITLES/
!C
      CHARACTER  ( LEN = 12,  KIND = ICHAR_STD )   DATE
      CHARACTER  ( LEN = 20,  KIND = ICHAR_STD )   
     &                  BAGTTL, BDYTTL, BLTTTL, PLTTL
      DIMENSION         BAGTTL(6), BLTTTL(MAX_NUM_BELTS), PLTTL(MAXPLN)
      CHARACTER  ( LEN = 80,  KIND = ICHAR_STD )   VPSTTL
      CHARACTER  ( LEN = 160, KIND = ICHAR_STD)   COMENT
!C
!C      REAL  DATE, COMENT, VPSTTL, BDYTTL, BLTTTL, PLTTL, BAGTTL,
!C    &      SEG, JOINT
!C      DIMENSION  DATE(3), COMENT(40), VPSTTL(20), BDYTTL(5),
!C     &           BLTTTL(5,8), PLTTL(5,MAXPLN), BAGTTL(5,6),
!C     &          SEG(MAXSEG), JOINT(MAXJNT) 
!C
!C 
!C    COMMON /TITLES/ DATE, COMENT, VPSTTL, BDYTTL, BLTTTL, PLTTL,    
!C   *                BAGTTL, SEG, JOINT, CGS, JS     
!C
!C****************************************************************************
!C
!C    /TMPVS2/
!C
!C    COMMON/TMPVS2/ FREE                                               
!C
!C
!C****************************************************************************
!C
!C    /VPOSTN/
!C
!C    NUMVEH = number of vehicles
!C
      INTEGER  ( KIND = INTEGER_STD ) NUMVEH
!C
!C     COMMON /VPOSTN/ ZPLT, SPLT, AXV, VATAB, VT0, VDT, TIMEV, OMEGV,
!C    *                NVTAB, NUMVEH, IVREF
!C
!C****************************************************************************
!C
!C    /WINDFR/
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &           IWIND, MWSEG, NFVSEG, NFVNT, MOWSEG, MOWELP,
     &           NFORCE
      DIMENSION  IWIND(MAXSEG), MWSEG(7,MAXSEG), 
     &           NFVSEG(MAX_FOR_TORQ),
     &           NFVNT(MAX_FOR_TORQ), MOWSEG(MAXSEG,MAXSEG), 
     &           MOWELP(MAXSEG,MAXSEG)
!C
      REAL  ( KIND = IREAL_HIGH )   WTIME, QFU, QFV, WF
      DIMENSION  WTIME(MAXSEG), QFU(3,MAX_FOR_TORQ), 
     &           QFV(3,MAX_FOR_TORQ), WF(3,MAXSEG)
!C
!C      COMMON /WINDFR/  WTIME, QFU, QFV, WF, IWIND, MWSEG, NFVSEG,       
!C     *                 NFVNT, MOWSEG 
!C
!C****************************************************************************
!C
!C    /XTRA/
!C
      INTEGER  ( KIND = INTEGER_STD )   NN, NELP, MELL
      DIMENSION  MELL(MAXELP)
!C
      REAL  ( KIND = IREAL_STD )   P1S, P2S, P3S, P4S
      DIMENSION  P1S(3,MAXELP), P2S(3,MAXELP), P3S(3,MAXELP),
     &           P4S(3,MAXELP)
!C
!C    COMMON /XTRA/  NN, NELP, MELL, P1S, P2S, P3S, P4S                 
!C
!C
!C****************************************************************************
!C****************************************************************************
!C
!C    This module contains variables that are shared amongst the 
!C     following Airbag subroutines:
!C
!C       /AIRBAG_TEMPVS/
!C
      REAL  ( KIND = IREAL_STD )
     &                  TMP, TMP1, TORQ, FORCE, TORA,
     &                  TQB, FRB, VOL, DELF, VOLP, FRA
      DIMENSION TMP(9), TMP1(3),TORQ(3), FORCE(3,5), TORA(3,5),           
     &          TQB(3,10), FRB(3,10), VOL(10), DELF(3),
     &          VOLP(4,5), FRA(4,5)                                       
!C 
!C     COMMON/TEMPVS/ TMP, TMP1, TORQ, FORCE, TORA,                     
!C    *                  TQB, FRB, VOL, DELF, VOLP, FRAC               
!C
!C     COMMON/TEMPVS/ TMP(9),TMP1(3),TORQ(3),FORCE(3,5),TORA(3,5),         
!C    *            TQB(3,10),FRB(3,10),VOL(10),DELF(3),VOLP(4,5),FRA(4,5)  
!C     NOTE: THIS COMMON/TEMPVS/ IS SHARED BY AIRBAG AND AIRBGG.           
!C
!C****************************************************************************
!C
!C     /BELT_TEMPVS/
!C
!C     This module replaces the /TEMPVS/ shared by Subroutines
!C      BELTRT and BELTG
!C                                                                         
!C     NOTE: BELTRT AND BELTG SHARE FIRST PART OF TEMPVS                   
!C
      REAL  ( KIND = IREAL_HIGH )
     &           APA, UVA, DLGA, UAA, APB, UVB, DLGB, UBB
      DIMENSION  APA(3), UVA(3), APB(3), UVB(3)                            
!C
!C      COMMON/TEMPVS/ APA(3),UVA(3),DLGA,UAA,APB(3),UVB(3),DLGB,UBB         
!C     *              ,TA(3),TB(3),TC(3),UP(3),B(3)                          
!C     *              ,UC(3),AX(3),XE(3),BX(3),ACA(3),ACB(3)                 
!C
!C****************************************************************************
!C
!C      /CINPUT_TEMPVS/
!C
!C    These variables were in a /TEMPVS/ that was shared by Subroutines
!C      CINPUT, FDINIT, FINPUT, HINPUT.  NF is renamed to NF_FUNCT and
!C      MS is renamed to MS_SEG.
!C 
      INTEGER  ( KIND = INTEGER_STD )  NF_FUNCT, MS_SEG
      DIMENSION  NF_FUNCT(5), MS_SEG(3)
!C
      CHARACTER ( LEN = 4,  KIND = ICHAR_STD )   KTITLE
      CHARACTER ( LEN = 20, KIND = ICHAR_STD )   FUNC_TITLE
      DIMENSION       FUNC_TITLE(MAX_FUNC+1), KTITLE(31)
!C
!C    NOTE: THIS IS SHARED BY SUBS CINPUT, FINPUT, HINPUT AND FDINIT.     
!C          also used by Subroutine KINPUT
!C
!C    COMMON/TEMPVS/ JTITLE(5,51),NF(5),MS(3),KTITLE(31)                  
!C    REAL JTITLE,KTITLE                                                 
!C
!C****************************************************************************
!C
!C       /DAUX_TEMPVS/
!C                                                                           
!C    Note: this /TEMPVS/ is shared by DAUX11, DAUX12, DAUX22,
!C          DAUX31, DAUX32, and DAUX33.
!C                                                                          
      INTEGER  ( KIND = INTEGER_STD )  IJK, IJ, NQ2S
      DIMENSION  IJK(MAXRHS,MAXRHS)
!C
      REAL  ( KIND = IREAL_HIGH )   C, RHS
      DIMENSION  C(3,3,MAXCMX), RHS(3,MAXRHS)
!C
!C    LOGICAL*1 FREE                                                        
!C    COMMON/TEMPVS/ C(3,3,MAXCMX),RHS(3,MAXRHS),IJK(MAXRHS,MAXRHS),    
!C   *               IJ,NQ2S                                                
!C    COMMON/TMPVS2/ FREE(MAXJNT)                                       
!C
!C    /TEMPVS/ 
!C
!C    INTEGER  JTMPVS
!C    DIMENSION  JTMPVS(MAXTMP)
!C
!C    COMMON /TEMPVS/ JTMPVS                                                
!C
!C****************************************************************************
!C
!C     /HEDING_TEMPVS/
!C
!C     Note: Subroutines POSTPR, HEDING, and HEDINGX shared this
!C           COMMON /TEMPVS/. 
!C
!C     SEE COMMENT IN POSTPR ABOUT FIRST DIMENSION OF PLDATA.              
!C
      INTEGER  ( KIND = INTEGER_STD )    NOPL, MOPL, M1PL, M2PL
      DIMENSION  NOPL(MHEDNG), MOPL(MHEDNG), M1PL(MHEDNG), M2PL(MHEDNG)
!C
      REAL  ( KIND = IREAL_HIGH )   TDATA
      DIMENSION          TDATA(14,MAX_NUM_TTH)
!C
      REAL  ( KIND = IREAL_STD )   USEC, ZTTH                            
      DIMENSION  USEC(MAX_LN_PPAGE), ZTTH(14,MAX_LN_PPAGE,MAX_NUM_TTH)
!C
      CHARACTER ( LEN = 4, KIND = ICHAR_STD )  HEAD
      DIMENSION      HEAD(20)
!C
!C      As was in Subroutine HEDING.
!C      COMMON/TEMPVS/ TDATA(14,65),HEAD(20),NOPL(MHEDNG),MOPL(MHEDNG),     
!C     *               M1PL(MHEDNG),USEC(45),ZTTH(14,45,65),                
!C     *               M2PL(MHEDNG)                                         
!C
!C      As was in Subroutine POSTPR.
!C      COMMON/TEMPVS/ TDATA(14,65),HEDATA(3*MHEDNG+20),                   
!C     *               USEC(45),ZTTH(14,45,65),M2PL(MHEDNG)                 
!C
!C****************************************************************************
!C
!C       /HRN_TEMPVS/
!C 
!C    The variables were in a /TEMPVS/ that was shared by Subroutines
!C     HPTURB, HBPLAY, HBELT, and HSETC.  The following variables
!C     were renamed:
!C
!C          B  to B_HRN     E   to E_HRN        FP   to FP_HRN
!C          S  to S_HRN     FCE to FCE_HRN      RHS  to RHS_HRN
!C          T  to T_HRN	  FR  to FR_HRN       C    to C_HRN
!C          R  to R_HRN     ZR  to ZR_HRN       IJK  to IJK_HRN
!C          V  to V_HRN     TR  to TR_HRN       NOLD to NOLD_HRN
!C          T1 to T1_HRN    BL  to BL_HRN
!C          T2 to T2_HRN    FB  to FB_HRN
!C
      INTEGER  ( KIND = INTEGER_STD )  IJK_HRN, NOLD_HRN
      DIMENSION  IJK_HRN(54,54), NOLD_HRN(2,MAXHPT)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  B_HRN, S_HRN, T_HRN, R_HRN, V_HRN, T1_HRN,
     &                  T2_HRN, E_HRN, EDOT, FCE_HRN, FR_HRN, ZR_HRN,
     &                  TR_HRN, U_HRN, PTLOSS, BL_HRN, FB_HRN, FP_HRN,
     &                  OLDBB, RHS_HRN, C_HRN
      DIMENSION  B_HRN(3,3,3), S_HRN(3,3), T_HRN(3), R_HRN(3),
     &           V_HRN(3), T1_HRN(3), T2_HRN(3), E_HRN(3,3,MAXHPH),
     &           EDOT(3,MAXHPH), FCE_HRN(3,MAXHPH), FR_HRN(3,MAXHPH), 
     &           ZR_HRN(3,MAXHPH), TR_HRN(3,MAXHPH), U_HRN(3,MAXHPH), 
     &           PTLOSS(2,MAXHPT), BL_HRN(MAXHPH), FB_HRN(MAXHPH), 
     &           FP_HRN(MAXHPH), OLDBB(MAXHPT), RHS_HRN(3,54),
     &           C_HRN(3,3,200)
!C
!C     THIS COMMON/TEMPVS/ IS SHARED BY HPTURB, HBPLAY, HBELT AND HSETC.    
!C
!C
!C     COMMON/TEMPVS/ B(3,3,3),S(3,3),T(3),R(3),V(3),T1(3),T2(3),           
!C    *               E(3,3,50),EDOT(3,50),FCE(3,50),FR(3,50),ZR(3,50),    
!C    *              TR(3,50),U(3,50),PTLOSS(2,100),BL(50),FB(50),FP(50),  
!C    *            OLDBB(100),RHS(3,54),C(3,3,200),IJK(54,54),NOLD(2,100)   
!C
!C    BLOSS and HLOSS are defined as equivalenced with C for Subroutine
!C     HPTURB.
!C
      REAL  ( KIND = IREAL_HIGH )   BLOSS, HLOSS
      DIMENSION         BLOSS(2,MAXHBLT), HLOSS(2,MAXHRN)                           
!C
      EQUIVALENCE  ( BLOSS(1,1), C_HRN(1,1, 1) ), 
     &             ( HLOSS(1,1), C_HRN(1,1,10) )                          
!C
!C****************************************************************************
!C
!C       /PLELP_TEMPVS/
!C
!C     This COMMON/TEMPVS/ is shared by PLEDG, PLELP, PLSEGF, and
!C                                      SEGSEG.   
!C
      INTEGER  ( KIND = INTEGER_STD )  MCF_PLP, NCF_PLP
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  AMR_PLP, DMNT_PLP, DMNWN_PLP, FM_PLP, PEN_DIST, 
     &                  R_PLP, RLM_PLP, RLN_PLP,
     &                  RM_PLP, RMD_PLP, RN_PLP, RND_PLP, 
     &                  T_PLP, TF_PLP, TH_PLP, TM_PLP, VR_PLP,
     &                  WNM_PLP, XH_PLP, XMM_PLP, XMN_PLP, XNC_PLP
      DIMENSION         R_PLP(3), DMNT_PLP(3,3), DMNWN_PLP(3),
     &                  RLM_PLP(3), RLN_PLP(3), RM_PLP(3), 
     &                  RMD_PLP(3), RN_PLP(3), RND_PLP(3), 
     &                  T_PLP(3), TH_PLP(3), TM_PLP(3), VR_PLP(3),
     &                  WNM_PLP(3), XH_PLP(3), XMM_PLP(3), 
     &                  XMN_PLP(3), XNC_PLP(3)
!C
!C      As found in PLEDG; shared with PLELP-PLSEGF                           
!C        COMMON/TEMPVS/DMNT(3,3),DHNT(3,3),DUM1(18),TM(3),R(3),RM(3),       
!C     X            DUM2(9),UP(3),VP(3),U(3),V(3),EU(3),EV(3),ET(3),         
!C     X            A(2),B(2),CC(2),DUM4(12),TH(3),XH(3),RMD(3),RND(3),      
!C     X            APT(2,2,2),AC(2,2),BC(2,2),AFP,E(2,2),DELT,AREA,         
!C     X            AB,BB,BT(2),XNC(3),UH(3),P,AMR,FM,T4(3),ALIM(2,2)       
!C
!C      
!C      As found in PLELP
!C      COMMON/TEMPVS/DMNT(3,3),TEMP(3,3),B(3,3),XMN(3),RLN(3),XMM(3),       
!C     *              TM(3),R(3),RM(3),DMNWN(3),RLM(3),RN(3),VMN(3),VR(3),     
!C     *              WNM(3),WCM(3),WCN(3),VREL(3),FFM(3),FR(3),TQM(3),        
!C     *              TQN(3),TQNT(3),T(3),H(3),TH(3),XH(3),RMD(3),RND(3),       
!C     *              TD(3),TT4(3,4),TT5(3,4),XNC(3),UH(3),P,AMR,FM,CF,        
!C     *              VRM,VRT,VRTS,VRTEST,TF,ELOSS,MCF,NCF                   
!C
!C     As found in PLSEGF; is shared by PLELP, PLSEGF and SEGSEG.           
!C      DIMENSION     DMNT(3,3),TEMP(3,3),B(3,3),XMN(3),RLN(3),XMM(3),      
!C     *              TM(3),R(3),RM(3),DMNWN(3),RLM(3),RN(3),VMN(3),VR(3),  
!C     *              WMN(3),WCM(3),WCN(3),VREL(3),FFM(3),FR(3),TQM(3),     
!C     *              TQN(3),TQNT(3),T(3),H(3),T1(3),T2(3),RMD(3),RND(3)    
!C     *              TD(3),TT4(3,4),TT5(3,4),T3(3),T4(3),P,AMR,FM,CF,      
!C     *              VRM,VRT,VRTS,VRTEST,TF,ELOSS,MCF,NCF,T5(3),T6(3)      
!C     As found in SEGSEG
!C      COMMON/TEMPVS/DMNT(3,3),TEMP(3,3),B(3,3),XMN(3),RLN(3),XMM(3),      
!C     *              TM(3),R(3),RM(3),DMNWN(3),RLM(3),RN(3),VMN(3),VR(3),    
!C     *              WNM(3),WCM(3),WCN(3),VREL(3),FFM(3),FR(3),TQM(3),       
!C     *              TQN(3),TQNT(3),T(3),H(3),T1(3),T2(3),RMD(3),RND(3),     
!C     *              TD(3),TT4(3,4),TT5(3,4),T3(3),T4(3),P,AMR,FM,CF,        
!C     *              VRM,VRT,VRTS,VRTEST,TF,ELOSS,MCF,NCF,T5(3),T6(3)        
!C
!C     As found in HYEST.
!C      COMMON/TEMPVS/D12(3,3),A(3,3),B(3,3),XMN(3),RLN(3),XMM(3),           
!C     *              T(3),R(3),C(3,3),V(7)                                  
!C
!C     As found in HYLPX.
!C      COMMON/TEMPVS/D12(3,3),P(3,3),Q(3,3),XMN(3),RLN(3),XMM(3),          
!C     *              R(3),H(3),D(3,3),V(7)                                 
!C
!C     As found in HYNTR.
!C      COMMON/TEMPVS/D12(3,3),A(3,3),B(3,3),XMN(3),RLN(3),XMM(3),         
!C     *              AZ(3),R(3)
!C
!C
!C****************************************************************************
!C                                                                        
!C    /VIN_TEMPVS/
!C
!C    The first 2 lines of /TEMPVS/ were shared by VINPUT, VINO12,        
!C     VINO34, VSPLIN and VINTST.                                         
!C                                                                      
      REAL  ( KIND = IREAL_HIGH )
     &                  ANGLE, ATAB, AX, DVEH, VMEG, VMEGD,
     &                  X0, XACOMP, XDOT0
      DIMENSION         ANGLE(3), ATAB(15,MAXVT3), AX(3), DVEH(3,3),
     &                  VMEG(3), VMEGD(3), X0(3), XACOMP(3),
     &                  XDOT0(3)
!C 
!C    COMMON/TEMPVS/ X0(3),XDOT0(3),XACOMP(3),AX(3),ANGLE(3),           
!C   *               ATAB(15,MAXVT3),DVEH(3,3),VMEG(3),VMEGD(3)          
!C
!C
!C****************************************************************************
!C
!C    New global variables that had been local variables in Subroutine
!C     INPUT_VEHICLE.  They are the linear and angular initial
!C     parameters for segments that have been specified to be vehicles.
!C
      REAL  ( KIND = IREAL_HIGH )
     &              RINIT_SEGLP, RINIT_SEGLV, RINIT_SEGLA, 
     &              RINIT_D, RINIT_WMEG, RINIT_WMEGD
      DIMENSION  RINIT_D(3,3,MAXSEG), RINIT_SEGLA(3,MAXSEG), 
     &           RINIT_SEGLP(3,MAXSEG), RINIT_SEGLV(3,MAXSEG), 
     &           RINIT_WMEG(3,MAXSEG), RINIT_WMEGD(3,MAXSEG)   

!C
!C****************************************************************************
!C
!C    Global variable used in subroutine MSC_DERIVS to indicate whether 
!C    it is a lateral or longitudinal human head model
!C    MSC_DIRECTION = 0: LONGITUDINAL
!C    MSC_DIRECTION = 1: LATERAL
!C    MSC_INT_EPS = Fractional error tolerance 
!C    MSC_INT_NEAR_ZERO = Small value used to test whether there is near zero 
!C                        crossing situation in integration.
!C    MSC_INT_MAX_SCALE = A value used to set the scale in integration accuracy
!C                        tests for those near zero crossing dependent variables.
!C                        The value of 0.0022 is the injury threshold from Phillips.
!C
      INTEGER ( KIND = INTEGER_STD ) MSC_DIRECTION
      REAL ( KIND = IREAL_HIGH ) MSC_INT_EPS, MSC_INT_NEAR_ZERO, 
     &                           MSC_INT_MAX_SCALE
      PARAMETER ( MSC_INT_EPS = 1.0E-3_IREAL_HIGH,
     &            MSC_INT_NEAR_ZERO = 1.0E-5_IREAL_HIGH,
     &            MSC_INT_MAX_SCALE = 0.0022 ) 
!C
!C****************************************************************************   
      END MODULE MODULE_STANDARD
