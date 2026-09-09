      SUBROUTINE EQUILB ( YPR, IYPR )                                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                        
!C    Adjusts initial input position parameters supplied on Cards G.2     
!C    and G.3 such that initial normal contact forces are equal to        
!C    either supplied values or those computed by constraint forces.     
!C                                                                        
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NQ, NPRT, NJNT, NVEH,                          ! /CONTRL/
     &       KQTYPE, KQ1, KQ2,  RK2,                        ! /CSTRNT/
     &       VISC,                                          ! /DESCRP/
     &       MPL, NTPL,                                     ! /JBARTZ/
     &       SEG, JNT,                                      ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH,            ! parameters
     &       LUAOU, LOGICAL_STD, MAXSEG, FALSE,             ! parameters
     &       I_0, I_1, I_2, D_0                             ! parameters
!C
!C    DIR_COS, LIN_DISP                              ! SEG%
!C    JNT_NAME, JTORQUE, JTYPE, PROX_HB, DSTL_HB     ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, I0, I1, I2, IAV, IPRINT, J, J2, 
     &           JITTER, K, L, NCON, NQORG, NVAR 
      INTEGER  ( KIND = INTEGER_STD )
     &           IYPR, JPL, JSG, JX, M1, M2, M3, MT, NTV, NI1, NSGE,
     &           NAV, KSGE, ISG, IPL, LTYPE, INDGX 
      DIMENSION  IYPR(4, MAXSEG), JPL(10), JSG(10), JX(10), M1(10),
     &           M2(10), M3(10), MT(10),
     &           NTV(10), NI1(10), NSGE(10), NAV(10), KSGE(5,10),          
     &           ISG(5), IPL(5), LTYPE(5), INDGX(5)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  PENDOT, T1, ZSX, ZXX 
      REAL  ( KIND = IREAL_HIGH )
     &                  YPR, X, GX, DXP, DPN,
     &                  SX, SGX, XDEV
!C
      DIMENSION  YPR(3,MAXSEG),  
     &           X(10), GX(10), DXP(10), DPN(5,10),               
     &           SX(10), SGX(10), XDEV(10)
!C
      REAL  ( KIND = IREAL_HIGH )   VECMAG, XDY
      EXTERNAL                      VECMAG, XDY
!C
      LOGICAL  ( KIND = LOGICAL_STD )  EQUILB_CONVERGE
!C
      CHARACTER ( LEN = 4, KIND = ICHAR_STD )  BLANK
      CHARACTER ( LEN = 6, KIND = ICHAR_STD )   WORD
      DIMENSION       WORD(2)
!C
      DATA       BLANK / ICHAR_STD_'    ' /                                
      DATA       WORD / ICHAR_STD_' SEGLP', ICHAR_STD_'   YPR' /
!C
      CALL ELTIME ( I_1, 35_INTEGER_STD )                                               
!C
!C    Read in the parameters for the equilbrium calculations
!C     from Cards G.4, G.5, and G.6.
!C
      CALL  INPUT_EQUILB ( NVAR, NCON, NTV, NI1, NSGE,
     &                     GX, XDEV, JPL, NAV, KSGE, 
     &                     IPL, ISG, LTYPE, INDGX, JSG )
!C                                                                        
!C    Data initialization.                                                
!C                                                                       
      NQORG = NQ                                                          
      DO  K=1,NVAR                                                        
       J = JPL(K)                                                         
       I = JSG(K)                                                         
       M1(K) = MPL(1,I,J)                                                 
       M2(K) = MPL(2,I,J)                                                 
       M3(K) = ABS ( MPL(3,I,J) )                                         
       MT(K) = NTPL (I,J)                                                 
       JX(K) = I_1                                                    
       DXP(K) = D_0                                                    
       I1 = NI1(K)                                                        
       I2 = NSGE(K)                                                        
       IF  ( NTV(K) .EQ. I_1 )  X(K) = SEG(I2)%LIN_DISP(I1)     
       IF  ( NTV(K) .EQ. I_2 )  X(K) =   YPR(I1,I2)                  
       SX (K) =   X(K)                                                    
       SGX(K) =  GX(K)                                                    
       IF  ( NAV(K) .LE. I_0 )  CYCLE                               
       IAV = NAV(K)                                                      
       DO  L=1,IAV                                                        
        J2 = KSGE(L,K)                                                    
        IF  ( NTV(K) .EQ. I_1 )  DPN(L,K) =   SEG(I2)%LIN_DISP(I1) 
     &                                        - SEG(J2)%LIN_DISP(I1)   
        IF  ( NTV(K) .EQ. I_2 )  
     &       DPN(L,K) =   YPR(I1,I2) -   YPR(I1,J2)     
       END DO
      END DO                                                              
      IF  ( NPRT(27) .NE. I_0 )  THEN                                  
!C                                                                        
!C     See what user input looks like.                              
!C                                                                       
       CALL OUTPUT ( I_0 )                                          
       CALL DAUX ( I_0 )                                               
       CALL PRINT ( ' USER ' )                                            
       CALL OUTPUT ( I_1 )                                              
      END IF
!C                                                                       
!C    Start FDF force -> constraint force iteration                       
!C                                                                        
      PENDOT = D_0                                                   
      EQUILB_CONVERGE = FALSE
      DO  J=1,10                                                 
       JITTER = J
       CALL  EQUILB_SOLVE  ( NVAR, NCON, NTV, NI1, NSGE,
     &                       GX, XDEV, JPL, NAV, KSGE, 
     &                       IPL, ISG, LTYPE, INDGX,
     &                       M1, M2, M3, MT, JX, DXP, X, DPN, 
     &                       IYPR, NQORG, JITTER, PENDOT, 
     &                       EQUILB_CONVERGE, SX, YPR )
       IF ( EQUILB_CONVERGE )  EXIT
      END DO                                                            
!C                                                                        
!C    Print input and changes made.                                       
!C                                                                       
      IF  ( NJNT .GT. I_0 )  THEN                                    
       CALL OUTPUT ( I_0 )                                          
       CALL DAUX ( I_0 )                                             
       IPRINT = I_0                                                 
       DO  J=1,NJNT                                                       
        IF  ( JNT(J)%JTYPE       .GE. I_0   )  CYCLE                      
        IF  ( VISC(4,3*J-2) .GT. D_0 )  CYCLE                           
        IF  ( JNT(J)%JTYPE .EQ. -I_1 )  THEN
         T1 = ABS ( XDY ( JNT(J)%DSTL_HB, SEG(J+1)%DIR_COS, 
     &                               JNT(J)%JTORQUE ) )   
        END IF
        IF  ( JNT(J)%JTYPE .LE. -I_2 )  THEN
         T1 = VECMAG ( JNT(J)%JTORQUE ) 
        END IF
        VISC(4,3*J-2) = 1.5_IREAL_HIGH * T1                               
        IF  ( IPRINT .EQ. I_0 )  THEN
         WRITE  ( LUAOU, 100 )
  100    FORMAT( '0  The following values for the max torque for a ',
     &           'locked joint on Cards B.5 have been set up by ',
     &           'Subroutine EQUILB:', //, 
     &           '     J SYM    JTYPE   T1=VISC(4)', / )                  
        END IF
        IPRINT = I_1                                                  
        WRITE  ( LUAOU, 105 )  J, JNT(J)%JNT_NAME, JNT(J)%JTYPE, 
     &                        VISC(4,3*J-2)    
  105   FORMAT ( I6, 1X, A4, I6, F15.6 )                                 
       END DO                                                             
      END IF
!C
      IF  ( NQ .GT. I_0 )  THEN                                     
       IPRINT = I_0                                                   
       DO  K=1,NQ                                                         
        IF  ( KQTYPE(K) .NE. I_1 )  CYCLE                               
        IF  ( KQ2(K) .NE. NVEH )  CYCLE                                   
        IF  ( IPRINT .EQ. I_0 )  THEN  
         WRITE  ( LUAOU, 110 )                                             
  110    FORMAT ( '0  The following values for RK2 on Cards D.6 for ',
     &            'fixed point constraints have been changed by ',
     &            'Subroutine EQUILB:', //, 5X, 'K', 3X, 'KQTYPE',
     &            4X, 'KQ1', 5X, 'KQ2', 8X, 'RK2(X)', 
     &            9X, 'RK2(Y)', 9X, 'RK2(Z)', / )                         
        END IF
        IPRINT = I_1                                                    
        WRITE  ( LUAOU, 115 )  K, KQTYPE(K), KQ1(K), KQ2(K), 
     &                       ( RK2(I,K), I=1,3 )                          
  115 FORMAT ( I6, 3I8, 3F15.6 )                                        
       END DO                                                             
      END IF
!C
      WRITE  ( LUAOU, 120 )                                               
  120 FORMAT ( '0    The following variables on Cards G.2 and G.3 ',      
     &         'have been changed by Subroutine EQUILB:', // )            
      DO  J=1,NVAR                                                        
       I0 = NTV(J)                                                        
       I1 = NI1(J)                                                        
       I2 = NSGE(J)                                                        
       WRITE  ( LUAOU, 125 )  WORD(I0), I1, I2, SX(J), X(J), BLANK,
     &                       J, SGX(J), GX(J)                             
  125  FORMAT ( 4X, A6, '(', I2, ',' , I2, ') from', F12.6, ' to', 
     &          F12.6, A4,  'and GX(', I2, ') from', F12.6, ' to', 
     &          F12.6 )                                                   
       IF  ( NAV(J) .LE. I_0 )  CYCLE                                
       IAV = NAV(J)                                                       
       DO  I=1,IAV                                                        
        J2 = KSGE(I,J)                                                     
        ZSX = SX(J) - DPN(I,J)                                            
        ZXX =  X(J) - DPN(I,J)                                            
        WRITE  ( LUAOU, 125 )  WORD(I0), I1, J2, ZSX, ZXX                  
       END DO
      END DO                                                              
!C
      CALL ELTIME ( I_2, 35_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                
