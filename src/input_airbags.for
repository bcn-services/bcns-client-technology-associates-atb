      SUBROUTINE INPUT_AIRBAGS                                         
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Reads and prints the input cards that describe the physical         
!C    dimensions and gas dynamics of the airbag restraints and            
!C    performs initialization required by the AIRBAG routine.             
!C    This subroutine is called only by Subroutine INPUT_DCARDS.
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       AB, ZDEP, SPRK, VSCS, CK, CMASS, B,            ! /ABDATA/
     &       BFB, ZR, DRR, DEPLOY, DPVCTR, IFULL,           ! /ABDATA/
     &       TV1, TV2, CYMOUT, PYMOUT, PREVT,               ! /ABDATA/
     &       DBR, VBAGG,                                    ! /ABDATA/
     &       G, PI,                                         ! /CNSNTS/
     &       BD,                                            ! /CNTSRF/
     &       CYTD, CYPA, CYSP, CYT0, CYV0, CYCD,            ! /CYDATA/
     &       CYK, CYR, CYAT, CYPV, CYCD0, CYA0, CYC,        ! /CYDATA/
     &       CYP0, CYSS, CYRHO0, CYVMAX, CYORFC, CYL0,      ! /CYDATA/
     &       NVEH, NSEG, NBAG, NJNT, NGRND, NPG, NPRT,      ! /CONTRL/     
     &       NPANEL,                                        ! /FORCES/
     &       BAGTTL,                                        ! /TITLES/
     &       SEG, JNT,                                      ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LUAIN, LUAOU, MAXSEG, LULIN, LIN_FLAG,         ! parameters
     &       D_0, D_HALF, D_1, D_2, D_3, D_4, D_5,          ! parameters 
     &       I_0, I_1, I_2, I_3, I_4, AIN_CONVERT           ! parameters
!C
!C    ANG_ACL_CONV, ANG_VEL_CONV, LIN_ACL_CONV, LIN_VEL_CONV, ! SEG%
!C    ANG_ACCEL,    ANG_VEL,      DIR_COS,      LIN_ACCEL,    ! SEG% 
!C    LIN_DISP,     LIN_VEL,      NAME,         PHI,          ! SEG%
!C    RECIP_MASS,   RECIP_PHI,    SINGULAR,     WEIGHT        ! SEG%
!C
!C    PROX_SEG, JTYPE                                         ! JNT%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER   ( KIND = INTEGER_STD )
     &                I, J, JB, K, KP, L, LEN, IDYPR, MAXNPL, MSEGL
      DIMENSION  IDYPR(3)
!C
      CHARACTER  ( LEN = 4, KIND = ICHAR_STD )  BAG 
      DIMENSION      BAG(6)                                               
      CHARACTER  ( LEN =  20, KIND = ICHAR_STD )  ATEMP20
      CHARACTER  ( LEN =  22, KIND = ICHAR_STD )  ATEMP22
!C
      REAL  ( KIND = IREAL_HIGH )   TMP, YB, YP, CYK1, CYK2, CYK3
      DIMENSION         TMP(9), YB(3), YP(3)
!C
      DATA BAG / ICHAR_STD_'Bag1', ICHAR_STD_'Bag2', 
     &           ICHAR_STD_'Bag3', ICHAR_STD_'Bag4', 
     &           ICHAR_STD_'Bag5', ICHAR_STD_'Bag ' /    
      DATA IDYPR / I_3, I_2, I_1 /          
      DATA MAXNPL / I_4 /                                       
!C                                                                        
!C    Make room for bag data in segment arrays between VEH and GRND.      
!C                                                                        
      MSEGL = I_0                                                      
      IF ( NVEH .GT. NSEG )  MSEGL = NVEH - NSEG                         
      L = NSEG + NBAG + MSEGL + I_1                                      
      K = NSEG + MSEGL + I_1                                          
      IF  ( ( L - I_1 ) .GT. NJNT )  THEN
       JNT(L-1)%PROX_SEG = I_0                                                 
       JNT(L-1)%JTYPE    = I_0                                                 
      END IF
      SEG(L)%ANG_ACCEL    = SEG(K)%ANG_ACCEL                            
      SEG(L)%ANG_ACL_CONV = SEG(K)%ANG_ACL_CONV
      SEG(L)%ANG_VEL_CONV = SEG(K)%ANG_VEL_CONV
      SEG(L)%ANG_VEL      = SEG(K)%ANG_VEL                           
      SEG(L)%DIR_COS      = SEG(K)%DIR_COS
      SEG(L)%LIN_ACCEL    = SEG(K)%LIN_ACCEL                      
      SEG(L)%LIN_ACL_CONV = SEG(K)%LIN_ACL_CONV
      SEG(L)%LIN_VEL_CONV = SEG(K)%LIN_VEL_CONV
      SEG(L)%LIN_DISP     = SEG(K)%LIN_DISP
      SEG(L)%LIN_VEL      = SEG(K)%LIN_VEL
      SEG(L)%NAME         = SEG(K)%NAME                                       
      SEG(L)%PHI          = SEG(K)%PHI
      SEG(L)%RECIP_MASS   = SEG(K)%RECIP_MASS                             
      SEG(L)%RECIP_PHI    = SEG(K)%RECIP_PHI                           
      SEG(L)%SINGULAR     = SEG(K)%SINGULAR                                            
      SEG(L)%WEIGHT       = SEG(K)%WEIGHT                               
!C
      NGRND = NSEG + NBAG + MSEGL + I_1                                 
      IF ( NGRND .GT. MAXSEG ) STOP 75                                    
      DO 40 J=1,NBAG                                                      
!C
!C     Check for comments.
!C
       CALL  CHECK_COMMENT
!C
       JB = NVEH + J                                                      
!C                                                                        
!C     Read and print cards D.4.a -D.4.f for the Jth airbag.              
!C                                                                        
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )   BAGTTL(J), NPANEL(J)                          
        READ ( LULIN, * )  ( AB(I,J), I=1,3 ), ( BD(I,JB), I=4,6 )        
        READ ( LULIN, * )  YB, ( ZDEP(I,J), I=1,3 )
        READ ( LULIN, * )  SEG(JB)%WEIGHT, CYTD(J), CYPA(J), CYSP(J), 
     &                     CYT0(J), CYV0(J)    
        READ ( LULIN, * )  CYCD(J), CYK(J), CYR(J), CYAT(J), CYPV(J),
     &                     CYCD0(J) 
        READ ( LULIN, * )  CYA0(J), SPRK(J), VSCS(J), CK(J),
     &                     CMASS(J)          
       ELSE
        READ ( LUAIN, 100 )  BAGTTL(J), NPANEL(J),                          
     &                       ( AB(I,J), I=1,3 ), ( BD(I,JB), I=4,6 ),        
     &                       YB, ( ZDEP(I,J), I=1,3 ), SEG(JB)%WEIGHT,    
     &                       CYTD(J), CYPA(J), CYSP(J), CYT0(J), 
     &                       CYV0(J), CYCD(J), CYK(J), CYR(J), CYAT(J), 
     &                       CYPV(J), CYCD0(J), CYA0(J), SPRK(J), 
     &                       VSCS(J), CK(J), CMASS(J)          
  100   FORMAT ( A20, I4, /, ( 6F12.0 ) )                                  
        IF ( AIN_CONVERT )  THEN
         ATEMP20 = ADJUSTL ( BAGTTL(J) )
         LEN = LEN_TRIM ( ATEMP20 )
         ATEMP22(1:LEN+2) = '"' // ATEMP20(1:LEN) // '"'       
         WRITE ( LULIN, 105 )  ATEMP22(1:LEN+2), NPANEL(J), 'Card D.4.a'                          
  105    FORMAT ( 1X, A, 2X, I6, 2X, A )
         WRITE ( LULIN, 110 )   ( AB(I,J), I=1,3 ), ( BD(I,JB), I=4,6 ),
     &                        'Card D.4.b'        
  110    FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )  
         WRITE ( LULIN, 115 )  YB, ( ZDEP(I,J), I=1,3 ), 'Card D.4.c'
  115    FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )
         WRITE ( LULIN, 120 )  SEG(JB)%WEIGHT, CYTD(J), CYPA(J), 
     &                         CYSP(J), CYT0(J), CYV0(J), 'Card D.4.d'    
  120    FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )
         WRITE ( LULIN, 125 )  CYCD(J), CYK(J), CYR(J), CYAT(J), 
     &                         CYPV(J), CYCD0(J), 'Card D.4.e' 
  125    FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )
         WRITE ( LULIN, 130 )  CYA0(J), SPRK(J), VSCS(J), CK(J),
     &                         CMASS(J), 'Card D.4.f'          
  130    FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )
        END IF
       END IF
       IF ( NPANEL(J) .GT. MAXNPL ) STOP 76                               
       IF ( MOD ( J, I_2 ) .EQ. I_1 )  THEN
        WRITE ( LUAOU, 135 )  NPG                                  
  135   FORMAT ( '1', 122X, 'Page', I5, /,
     &           '  Airbag Inputs', 105X, 'Cards D.4' )      
        NPG = NPG + I_1                                         
       END IF
       WRITE ( LUAOU, 140 )  J, BAGTTL(J),                               
     &                       ( AB(I,J), I=1,3 ), ( BD(I,JB), I=4,6 ),      
     &                       YB, ( ZDEP(I,J), I=1,3 ),                     
     &                       SEG(JB)%WEIGHT, CYTD(J), CYPA(J), CYSP(J), 
     &                       CYT0(J),
     &                       CYV0(J), CYCD(J), CYK(J), CYR(J), CYAT(J),
     &                       CYPV(J), CYCD0(J), CYA0(J), SPRK(J),
     &                       VSCS(J), CK(J), CMASS(J)             
  140  FORMAT ( '0 Airbag No.', I4, 4X, A20, //,                          
     &          29X, 'Airbag Semiaxes', 47X, 'C.G. Offset', /, 6X,
     &          6G20.9, //, 15X, 'Yaw', 16X, 'Pitch', 15X, 'Roll',
     &          30X, 'Deployment Point', /, 6X, 6G20.9, //,               
     &          15X, 'XBM', 16X, 'CYTD', 16X, 'CYPA', 16X, 'CYSP',
     &          16X, 'CYT0', 16X, 'CYV0', /, 6X, 6G20.9, //,              
     &          14X, 'CYCD', 17X, 'CYK', 17X, 'CYR', 16X, 'CYAT',
     &          16X, 'CYPV', 16X, 'CYCD0', /, 6X, 6G20.9, //,             
     &          14X, 'CYA0', 16X, 'SPRK', 16X, 'VSCS', 17X, 'CK',
     &          17X, 'CMASS', /, 6X, 5G20.9 )  
       KP = NPANEL(J)                                                     
       DO  25  K=1,KP                                                     
!C                                                                        
!C      Read and print cards D.4.G and D.4.H for the Kth panel to         
!C      contact the Jth airbag. These panels are approximated by          
!C      ellipsoids. The first panel (K=1) is the reaction panel that      
!C      includes the deployment point.                                    
!C                                                                        
        IF  ( LIN_FLAG )  THEN
         READ ( LULIN, * )  ( B(I,K,J), I=1,3 ), ( BFB(I,K,J), I=1,3 )   
         READ ( LULIN, * )  ( ZR(I,K,J), I=1,3 ), YP                      
        ELSE
         READ ( LUAIN, 145 )  ( B(I,K,J), I=1,3 ), 
     &                        ( BFB(I,K,J), I=1,3 ),   
     &                        ( ZR(I,K,J), I=1,3 ), YP                      
  145    FORMAT ( 6F12.0 )                                                
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 150 )  ( B(I,K,J), I=1,3 ), 
     &                          ( BFB(I,K,J), I=1,3 ), 'Card D.4.g'   
  150     FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )
          WRITE ( LULIN, 155 )  ( ZR(I,K,J), I=1,3 ), YP, 'Card D.4.h'                      
  155     FORMAT ( 1X, 6( F19.11, 1X ), 1X, A )
         END IF
        END IF
        WRITE ( LUAOU, 160 )  K, ( B(I,K,J), I=1,3 ), 
     &                           ( BFB(I,K,J), I=1,3 ),                    
     &                           ( ZR(I,K,J), I=1,3 ), YP                  
  160   FORMAT ( '0 Panel No.', I4, //,                                   
     &           24X, 'Panel Ellipsoid Semiaxes', 43X, 
     &           'C.G. Offset', /, 6X, 6G20.9, //,     
     &           29X, 'Panel Location', 32X, 'Yaw', 16X, 
     &           'Pitch', 15X, 'Roll', /, 6X, 6G20.9 ) 
!C                                                                        
!C      Convert B from ellipsoid semiaxes to matrix                       
!C                                                                       
        DO I=1,3                                                          
         TMP(I) = B(I,K,J)                                                
        END DO
        DO I=1,9                                                        
         B(I,K,J) = D_0                                                  
        END DO
        DO I=1,3                                                          
         B(4*I-3,K,J) = D_1 / TMP(I)**2                                  
        END DO
        CALL DRCYPR ( DRR(1,K,J), YP, IDYPR )                             
        CALL MAT33 ( B(1,K,J), DRR(1,K,J), TMP )                          
        CALL DOT33 ( DRR(1,K,J), TMP, B(1,K,J) )                          
        CALL DOT31 ( DRR(1,K,J), BFB(1,K,J), TMP )                       
        DO  I=1,3                                                         
         BFB(I,K,J) = TMP(I) + ZR(I,K,J)                                  
        END DO
  25   CONTINUE                                                           
!C                                                                        
!C     Compute geometry of deployment point on first panel.               
!C                                                                        
       CALL DRCYPR ( DBR(1,1,J), YB, IDYPR )                              
       CALL DOT31 ( DRR(1,1,J), ZDEP(1,J), DEPLOY(1,J) )                  
       DO  I=1,3                                                          
        DPVCTR(I,J) = -DBR(1,I,J)                                         
        DEPLOY(I,J) = DEPLOY(I,J) + BFB(I,1,J)                            
       END DO
       CALL PANEL ( DBR(1,1,J), DEPLOY(1,J), JB )                         
!C                                                                        
!C     Initialization of airbag geometry.                                 
!C                                                                        
       VBAGG(J) = D_4 / D_3 
     &             * PI * AB(1,J) * AB(2,J) * AB(3,J)     
       SEG(JB)%PHI(1) = ( AB(2,J)**2 + AB(3,J)**2 ) / D_5               
       SEG(JB)%PHI(2) = ( AB(3,J)**2 + AB(1,J)**2 ) / D_5               
       SEG(JB)%PHI(3) = ( AB(1,J)**2 + AB(2,J)**2 ) / D_5              
       JNT(JB-1)%PROX_SEG = I_0                                                 
       JNT(JB-1)%JTYPE    = I_0                                                
       SEG(JB)%NAME = BAG(J)                                            
       IF  ( NBAG .EQ. I_1 )  SEG(JB)%NAME = BAG(6)                       
       SEG(JB)%ANG_ACL_CONV = D_0
       SEG(JB)%ANG_VEL_CONV = D_0
       SEG(JB)%LIN_ACL_CONV = D_0
       SEG(JB)%LIN_VEL_CONV = D_0
       SEG(JB)%SINGULAR = -I_1                                            
       SEG(JB)%RECIP_PHI = D_1 / SEG(JB)%PHI                            
       SEG(JB)%RECIP_MASS = G / SEG(JB)%WEIGHT                                     
       DO  I=1,3                                                          
        BD(I,JB) = D_0                                                 
       END DO
       DO  I=7,24                                                         
        BD(I,JB) = D_0                                                  
       END DO
       IFULL(J) = I_0                                              
       CYMOUT(J) = D_0                                                  
       PYMOUT(J) = D_0                                                  
       DO  I=1,3                                                          
        DO  K=1,4                                                         
         TV1(I,K,J) = D_0                                              
        END DO
        DO  K=1,10                                                        
         TV2(I,K,J) = D_0                                               
        END DO
       END DO
!C                                                                        
!C     Air cylinder initialization                                        
!C                                                                        
       CYP0(J) = CYSP(J)  +CYPA(J)                                        
       CYSS(J) = SQRT ( CYK(J) * CYR(J) * CYT0(J) * G )                   
       CYL0(J) = CYV0(J) / CYAT(J)                                        
       CYK1    = CYK(J) - D_1                                             
       CYK2    = D_HALF * ( CYK(J) + D_1 )                               
       CYK3    = CYK2**( -CYK2 / CYK1 )                                  
       CYC(J)  = D_HALF * CYK1 * CYSS(J) * CYCD(J) / CYL0(J) * CYK3        
       CYRHO0(J) = CYP0(J) / ( CYR(J) * CYT0(J) )                         
       CYVMAX(J) = CYV0(J) / CYK(J) * CYP0(J) / CYPA(J)                   
       CYORFC(J) = CYCD0(J) * CYA0(J) * G * 
     &             SQRT ( D_2 * CYPA(J) * CYK(J) ) / CYSS(J)    
       IF  ( NPRT(22) .NE. I_0 )  THEN
        WRITE ( LUAOU, 165 )  ( SEG(JB)%LIN_DISP(I), I=1,3 ),
     &                        ( SEG(JB)%LIN_VEL(I),  I=1,3 ), 
     &                        ( SEG(JB)%ANG_VEL(I),  I=1,3 ), 
     &                        VBAGG(J), CYP0(J), CYSS(J), CYC(J),
     &                        CYRHO0(J), CYVMAX(J), CYORFC(J)  
  165   FORMAT ( '0 INPUT_AIRBAGS', /, ( 1X, 9G14.6 ) )                  
       END IF
   40 CONTINUE                                                            
!C
      PREVT = D_0                                                    
!C
      RETURN                                                              
      END                                                                
