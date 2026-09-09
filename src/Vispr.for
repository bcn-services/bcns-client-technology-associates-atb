      SUBROUTINE VISPR ( IJ_LCL, NJ )                                      
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes VISCOS and SPRING torques at the joints                     
!C    and adds them to the U2 array.                                      
!C                                                                         
!C    Arguments:                                                           
!C       NJ = 0 - regular computation for all joints                       
!C          # 0 - compute only for joint NJ impulse                        
!C                                                                         
!C       IJ = 1 impulse for flexure only                                   
!C          = 2 impulse for torsion only                                   
!C          = 4 impulse for globalgraphic only                             
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       HIR,                                              ! /CEULER/
     &       WJ,                                               ! /CMATRX/
     &       EPS, PI,                                          ! /CNSNTS/
     &       NJNT, NPG, NPRT, TIME,                            ! /CONTRL/
     &       HT, JOINTF, SPRING, VISC,                         ! /DESCRP/
     &       PRJNT,                                            ! /FORCES/
     &       CREST, JSTOP, TTI,                                ! /TEMPVI/
     &       SEG, JNT,                                         ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU,                   ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_3, I_4, I_6, I_7, I_13 ! parameters
!C
!C    ANG_VEL, DIR_COS, EXT_ANG_ACL                     ! SEG%
!C    JTORQUE, PROX_SEG, JTYPE, PROX_HA, DSTL_HA        ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:   WNP                ! /FXNVEL/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &                  I, IJ_LCL, J, J1, J2, JPASS, JSTP, K, L, M, NJ
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ANG2, ANGL, DH1, CSA, CSB, CV, HA2, HAC, 
     &                  HAD, HD3, RA, RB, T3, T6, T7, T9, 
     &                  TQC, WIJ, WIJM
      DIMENSION         ANGL(3), DH1(3,3), HD3(3,3), T3(3), T6(3),
     &                  T7(3), T9(3), WIJ(3)
!C
      REAL  ( KIND = IREAL_HIGH )  EFUNCT, FNTERP, VECMAG, VISCOS
      EXTERNAL                     EFUNCT, FNTERP, VECMAG, VISCOS
!C
      IF ( NJNT .LE. I_0 )   RETURN                                     
      CALL ELTIME ( I_1, I_13 )                                                
      IF ( NPRT(12) .NE. I_0 )  THEN
       WRITE ( LUAOU, 100 )   TIME, NPG                                      
  100  FORMAT ( '1 VISPR computations for time =', F12.6, 80X,
     &          'Page', I5 )                                               
       NPG = NPG + I_1                                                    
      END IF
      J1 = I_1                                                          
      J2 = NJNT                                                            
      IF ( NJ .NE. I_0 )   THEN                                         
       J1 = NJ                                                             
       J2 = NJ                                                            
      END IF
      DO 20 J=J1,J2                                                        
       JPASS = J
       T3 = D_0
       T6 = D_0
       T9 = D_0
       ANGL = D_0
       JNT(J)%JTORQUE = D_0
       WJ(J) = D_0                                                     
!C                                                                         
!C     Do not compute torques for null, locked or euler joints.            
!C                                                                         
       I = ABS ( JNT(J)%PROX_SEG )                                      
       IF ( I .LE. I_0 )  CYCLE                                      
       CALL DOT33 ( SEG(J+1)%DIR_COS, HT(1,1,2*J), HIR(1,1,J) )            
       IF  ( ABS ( JNT(J)%JTYPE ) .EQ. I_4 )  CYCLE                            
!C                                                                         
!C     Zero T1-T9 arrays and HAD, HBD, WIJM, CV, CS4, CSB and TQC.     
!C                                                                         
       WIJM = D_0                                           
       HAC  = D_0                                            
       CV   = D_0                                           
       CSA  = D_0                                         
       CSB  = D_0                                               
       TQC  = D_0                                          
       CALL DOT33 ( SEG(I)%DIR_COS, HT(1,1,2*J-1), DH1 )                
       CALL DOT33 ( DH1, HIR(1,1,J), HD3 )                                 
       DO  L=1,3                                                          
        DO  K=1,3                                                         
         IF ( ABS ( HD3(L,K) ) .LT. EPS(10) )  HD3(L,K) = D_0   
        END DO
       END DO                                                             
       HAD  = HD3(3,3)                                                    
       IF  ( HAD .GT.  D_1 )  HAD =  D_1                       
       IF  ( HAD .LT. -D_1 )  HAD = -D_1                       
       ANGL(1) = ACOS ( HAD )                                              
       IF  ( ( ( HD3(2,3) .NE. D_0 ) .OR. ( HD3(1,3) .NE. D_0 ) )
     &            .AND. ( ABS ( JNT(J)%JTYPE ) .NE. 7 ) )  THEN    
        ANGL(2) = ATAN2 ( HD3(2,3), HD3(1,3) )                             
       END IF
       ANGL(3) = ATAN2 ( ( HD3(2,1) - HD3(1,2) ), 
     &                   ( HD3(1,1) + HD3(2,2) )  )                       
       IF ( ( NPRT(12) .NE. I_0 ) .AND. 
     &      ( JNT(J)%JTYPE .LT. I_0 ) )  THEN
        WRITE ( LUAOU, 110 )  J, I, ANGL,     
     &                   ( ( SEG(J+1)%DIR_COS(L,K), K=1,3 ),
     &                     ( HT(L,K,2*J), K=1,3 ),
     &                     ( HIR(L,K,J), K=1,3 ), L=1,3 ),                
     &                   ( ( SEG(I)%DIR_COS(L,K), K=1,3 ),
     &                     ( HT(L,K,2*J-1), K=1,3 ), 
     &                     ( DH1(L,K), K=1,3 ), L=1,3 ),                  
     &                   ( ( HD3(L,K), K=1,3), L=1,3)                    
  110   FORMAT ( '0', 'J= ', I2, 1X, 'I= ', I2, 3( 2X, D14.7 ), /,        
     &           2( 3( 9( 1X, D13.6 ), / ), / ),
     &           3( 3( 2X, D18.12 ), / ) )                                
       END IF
       IF  ( JNT(J)%JTYPE .LT. I_0 )  THEN                                  
C                                                                          
C       Store data for OUTPUT routine into PRJNT array.                    
C                                                                          
        PRJNT(1,J) = JNT(J)%JTYPE                                           
        PRJNT(2,J) = ANGL(1)                                               
        PRJNT(3,J) = ANGL(2)                                               
        PRJNT(4,J) = ANGL(3)                                               
        PRJNT(5,J) = ( CSA * HAC )**2 + CSB**2                            
        PRJNT(6,J) = ( CV * WIJM )**2                                      
        PRJNT(7,J) = JNT(J)%JTORQUE(1)**2 + JNT(J)%JTORQUE(2)**2 
     &             + JNT(J)%JTORQUE(3)**2            
        CYCLE
       END IF
       IF  ( ( NJ .NE. I_0 ) .AND. 
     &       ( IJ_LCL .EQ. I_4 ) )  THEN
!C                                                                      
!C      Compute effect of globalgraphic joint stop ( JTYPE = 3 )             
!C                                                                         
        IF ( JNT(J)%JTYPE .EQ. I_3 )  THEN                                    
         CALL GLOBAL ( J, HD3(1,3), DH1, TQC, T9, ANGL )                    
        END IF
        CALL VISPR_TORQUE  ( I, IJ_LCL, JPASS, NJ, ANGL, HAC, RA, RB,
     &                       WIJ, WIJM, DH1, HD3, T7, T9, 
     &                       CSA, CSB, CV, TQC )                    

        CYCLE
       END IF
!C                                                                         
!C     Convert to inertial reference system                                
!C        T1= D(I)'*HA(NJ)     T4=D(J+1)'*HA(MJ)                           
!C        T3= D(I)'*WMEG(I)    T6=D(J+1)'*WMEG(J+1)                        
!C                                                                         
!C     HAD = COS TA = T1.T4                                                
!C     WIJ = T3-T6                                                         
!C     WJ  = !WIJ!                                                         
!C                                                                         
       DO  L=1,3                                                           
        DO  M=1,3                                                          
         T3(L) = T3(L) + 
     &   SEG(I)%DIR_COS(M,L)   * ( SEG(I)%ANG_VEL(M)   + WNP(M,2*J-1) )    
         T6(L) = T6(L) + 
     &   SEG(J+1)%DIR_COS(M,L) * ( SEG(J+1)%ANG_VEL(M) + WNP(M,2*J)   )    
        END DO
       END DO
       WIJ= T3 - T6                                      
       WIJM = VECMAG ( WIJ )                                           
       IF ( WIJM .LE. EPS(12) )  WIJM = D_0                          
       WJ(J) = WIJM                                                        
!C                                                                         
!C     T7 = T1 X T4                                                        
!C     HAC = !T7!                                                         
!C                                                                         
       CALL CROSS ( DH1(1,3), HIR(1,3,J), T7 )                             
       HAC = VECMAG ( T7 )                                                 
!C                                                                         
!C     Compute CV, the magnitude of viscous and coulomb torque/WIJM        
!C             RA = +SGN TA DOT = -WIJ.T7                                  
!C        and CSA, the magnitude of flexure torque/HAC                     
!C                                                                         
       CV = VISCOS ( WIJM, VISC(1,3*J-2), HA2 )                           
       IF  ( NJ .EQ. I_0 )  JNT(J)%DSTL_HA(2) = HA2                        
       CREST = VISC(7,3*J-2)                                               
       RA = -DOT_PRODUCT ( WIJ, T7 )
       IF ( HAC .LT. EPS(12) )  THEN
        RA = D_0                                                      
       ELSE
        RA = RA / HAC                                                     
       END IF
       JSTP = I_0                                                      
       IF ( JNT(J)%JTYPE .NE. I_7 )  THEN                                    
        IF ( JOINTF(1,J) .EQ. I_0 )  THEN
         CSA = EFUNCT ( ANGL(1), RA, SPRING(1,3*J-2), JSTP )            
        ELSE 
         CSA = FNTERP ( ANGL(1), ANGL(2), JOINTF(1,J) )                 
        END IF
        IF ( HAC .LT. EPS(12) )  THEN
         CSA = D_0                                                     
        ELSE
         CSA = CSA / HAC                                                  
        END IF
       END IF
       IF ( NJ .EQ. I_0 )  JSTOP(1,1,J) = JSTP                         
       IF ( ( JNT(J)%JTYPE .EQ. I_1 ) .OR. 
     &      ( JNT(J)%JTYPE .EQ. I_6 ) )  THEN
        CALL VISPR_TORQUE  ( I, IJ_LCL, JPASS, NJ, ANGL, HAC, RA, RB,
     &                       WIJ, WIJM, DH1, HD3, T7, T9, 
     &                       CSA, CSB, CV, TQC )                    
        CYCLE
       END IF
!C                                                                         
!C     RB = +SGN TB DOT = -WIJ.T8                                          
!C     Compute CSB, The magnitude of torsional torque/HBC                 
!C                                                                         
       RB  = -(   WIJ(1) * HIR(1,3,J) + WIJ(2) * HIR(2,3,J) 
     &          + WIJ(3) * HIR(3,3,J) )                                   
       IF ( JOINTF(2,J) .EQ. I_0 ) THEN                        
        CSB = EFUNCT ( ANGL(3), RB, SPRING(1,3*J-1), JSTP )             
       ELSE                                                             
        ANG2 = D_0                                                  
        IF ( ANGL(3) .LT. D_0 )  ANG2 = -PI                        
        CSB = SIGN ( FNTERP ( ABS ( ANGL(3) ), ANG2, JOINTF(2,J) ),
     &                ANGL(3) )                                         
       END IF                                                           
!C
       IF ( NJ .EQ. I_0 )  THEN
        JSTOP(2,1,J) = JSTP                                             
       END IF
!C
       IF ( NJ .LE. I_0 )  THEN
!C                                                                      
!C      Compute effect of globalgraphic joint stop ( JTYPE = 3 ).             
!C                                                                         
        IF ( JNT(J)%JTYPE .EQ. I_3 )  THEN                                    
         CALL GLOBAL ( J, HD3(1,3), DH1, TQC, T9, ANGL )                    
        END IF
       END IF
!C
       CALL VISPR_TORQUE  ( I, IJ_LCL, J, NJ, ANGL, HAC, RA, RB,
     &                      WIJ, WIJM, DH1, HD3, T7, T9, 
     &                      CSA, CSB, CV, TQC )                    
   20 CONTINUE                                                             
!C
      CALL ELTIME ( I_2, I_13 )                                                
!C
      RETURN                                                               
      END                                                                  
