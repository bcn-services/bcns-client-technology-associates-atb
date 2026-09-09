      SUBROUTINE VISPR_TORQUE ( I, IJ_LCL, J, NJ, ANGL, HAC, RA, RB,
     &                          WIJ, WIJM, DH1, HD3, T7, T9, 
     &                          CSA, CSB, CV, TQC )                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                         
      USE  MODULE_STANDARD,  ONLY:
     &       HIR,                                              ! /CEULER/
     &       NPRT,                                             ! /CONTRL/
     &       PRJNT,                                            ! /FORCES/
     &       TTI,                                              ! /TEMPVI/
     &       SEG, JNT,                                         ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU,                   ! parameters
     &       D_0, I_0, I_1, I_2, I_4                           ! parameters
!C
!C    DIR_COS, EXT_ANG_ACL                              ! SEG%
!C    JTORQUE, JTYPE, PROX_HA, DSTL_HA                  ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &                  I, IJ_LCL, J, K, L, M, NJ
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  ANGL, DH1, CSA, CSB, CV, HAC, 
     &                  HD3, RA, RB, T7, T9, 
     &                  TQC, WIJ, WIJM
      DIMENSION         ANGL(3), DH1(3,3), HD3(3,3), T7(3), 
     &                  T9(3), WIJ(3)
!C
      INTENT  (    IN )    I, IJ_LCL, J, NJ, ANGL, RA, RB, WIJ, WIJM, 
     &                     DH1, HD3, T7, T9
      INTENT  ( INOUT )    CSA, CSB, CV, TQC
!C                                                                         
!C    Compute total torque in inertial reference by                       
!C    TQ = -CV*WIJ + CSA*T7 + CSB*T8 + TQC*T9                             
!C                                                                         
      IF ( NJ .NE. I_0 )  THEN                                       
       CV = D_0                                                         
       IF ( IJ_LCL .NE. I_1 )  CSA = D_0                                   
       IF ( IJ_LCL .NE. I_2 )  CSB = D_0                                 
       IF ( IJ_LCL .NE. I_4 )  TQC = D_0                                   
      END IF
!C
      IF ( JNT(J)%DSTL_HA(2) .NE. D_0 ) THEN                                     
       CALL MAT31 ( HIR(1,1,J), JNT(J)%PROX_HA, JNT(J)%JTORQUE )           
       DO  L=1,3                                                          
        JNT(J)%JTORQUE(L) = JNT(J)%DSTL_HA(2) * JNT(J)%JTORQUE(L)               
       END DO
      END IF
!C
      DO  L=1,3                                                           
       JNT(J)%JTORQUE(L) = JNT(J)%JTORQUE(L) - CV * WIJ(L)    
     &                     + CSA * T7(L) 
     &                     + CSB * HIR(L,3,J) + TQC * T9(L)           
!C        TTI(L) = TQ(L,J)                                                   
      END DO
      TTI = JNT(J)%JTORQUE
      IF ( NPRT(12) .NE. I_0 )  THEN
       WRITE ( LUAOU, 100 )  J, CV, CSA, CSB, HAC, RA, RB,
     &                      ( JNT(J)%JTORQUE(L), L=1,3 ),
     &                       WIJ, T7, ANGL, DH1, HD3,   
     &                      ( ( HIR(L,K,J), L=1,3 ), K=1,3 )         
  100  FORMAT ( '0', I3, 3F14.3, 6F14.6, /, ( 4X, 9F14.6 ) )             
      END IF
!C                                                                          
!C    Add torque converted to local reference by                         
!C     EXT_ANG_ACL%I = EXT_ANG_ACL%I + DI*TQ                         
!C     EXT_ANG_ACL%J = EXT_ANG_ACL%J - DJ*TQ                            
!C                                                                          
      DO  L=1,3                                                           
       DO  M=1,3                                                          
        SEG(I  )%EXT_ANG_ACL(L) =   SEG(I  )%EXT_ANG_ACL(L)
     &                     + SEG(I  )%DIR_COS(L,M) * JNT(J)%JTORQUE(M)          
        SEG(J+1)%EXT_ANG_ACL(L) =   SEG(J+1)%EXT_ANG_ACL(L) 
     &                     - SEG(J+1)%DIR_COS(L,M) * JNT(J)%JTORQUE(M)          
       END DO
      END DO
!C                                                                          
!C    Store data for OUTPUT routine into PRJNT array.                     
!C                                                                         
      PRJNT(1,J) = JNT(J)%JTYPE                                            
      PRJNT(2,J) = ANGL(1)                                                
      PRJNT(3,J) = ANGL(2)                                               
      PRJNT(4,J) = ANGL(3)                                                
      PRJNT(5,J) = ( CSA * HAC )**2 + CSB**2                              
      PRJNT(6,J) = ( CV * WIJM )**2                                       
      PRJNT(7,J) = JNT(J)%JTORQUE(1)**2 + JNT(J)%JTORQUE(2)**2 
     &           + JNT(J)%JTORQUE(3)**2            
!C
      RETURN
      END