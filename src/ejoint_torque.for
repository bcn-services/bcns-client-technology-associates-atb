      SUBROUTINE EJOINT_TORQUE ( ISKIP, LSKIP, J, NJ, IJ_LCL, M, TH )
!C
!C                                                  Rev V.3  12/15/2002  
!C    Computes the torques acting on an Euler joint                       
!C    and adds them to the U2 array using the results
!C    of Subroutine EJOINT.
!C
!C    This subroutine is called only by Subroutine EJOINT.                                      
!C
!C                                                                        
      USE  MODULE_STANDARD, ONLY:
     &               ANG, ANGD, IEULER, HIR, FE, TQE,        ! /CEULER/
     &               PI,                                     ! /CNSNTS/
     &               JOINTF, IGLOB,                          ! /DESCRP/
     &               SPRING, VISC,                           ! /DESCRP/
     &               PRJNT,                                  ! /FORCES/
     &               TTI, JSTOP,                             ! /TEMPVI/
     &               SEG, JNT,                               ! structures
     &               INTEGER_STD, IREAL_HIGH, LOGICAL_STD,   ! parameters
     &               D_0, D_2, I_0, I_3                      ! parameters
!C
!C    DIR_COS, EXT_ANG_ACL          ! SEG%
!C    PROX_HA, DSTL_HA, JTORQUE     ! JNT%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &             I, IJ_LCL, J, K, K3J, M, NJ, ISKIP
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  TQC, ANG2, DH1, TH, CV, CS, ANGL, HD3, T9
      DIMENSION  DH1(3,3), TH(3,3), CV(3), CS(3), ANGL(3), HD3(3), T9(3)            
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LSKIP                                   
      DIMENSION  LSKIP(3)
!C
      REAL  ( KIND = IREAL_HIGH )   VECMAG, VISCOS, EFUNCT, FNTERP
      EXTERNAL                      VECMAG, VISCOS, EFUNCT, FNTERP
!C
      INTENT ( IN )  ISKIP, LSKIP, J, NJ, TH, M
!C
      IF ( ISKIP .LT. I_0 )  THEN 
!C                                                                         
!C     Store data into PRJNT array for output routine.                      
!C                                                                         
       PRJNT(1,J) = IEULER(J)                                              
       PRJNT(2,J) = ANG(1,J)                                               
       PRJNT(3,J) = ANG(2,J)                                               
       PRJNT(4,J) = ANG(3,J)                                               
       PRJNT(5,J) = CS(1)**2 + CS(3)**2 + 
     &              D_2 * CS(1) * CS(3) * TH(3,3) + CS(2)**2            
       PRJNT(6,J) = CV(1)**2 + CV(3)**2 + 
     &              D_2 * CV(1) * CV(3) * TH(3,3) + CV(2)**2             
       PRJNT(7,J) = ( VECMAG ( JNT(J)%JTORQUE ) )**2
       RETURN
!C
      ELSE IF ( ISKIP .EQ. I_0 )  THEN
       IF  ( IJ_LCL .NE. I_0 )   RETURN                             
!C
       DO  I=1,3                                                           
        IF  ( LSKIP(I) )   CYCLE                                           
        K3J = I_3 * J - I_3 + I                                   
        CV(I) = ANGD(I,J)*
     &      VISCOS ( ABS ( ANGD(I,J) ), VISC(1,K3J), 
     &                     JNT(J)%DSTL_HA(I) )   
        IF ( JOINTF(I,J) .EQ. I_0 )  THEN                             
          CS(I) = EFUNCT ( ANG(I,J), ANGD(I,J), SPRING(1,K3J),
     &                     JSTOP(I,1,J) )                                
        ELSE                                                             
         ANG2 = D_0                                                  
         IF ( ANG(I,J) .LT. D_0 )   ANG2 = -PI                        
         CS(I) = SIGN ( FNTERP ( ABS ( ANG(I,J) ), ANG2,
     &                  JOINTF(I,J) ), ANG(I,J) )                       
        END IF                                                           
        FE(I,J) = CS(I) + CV(I) + 
     &            JNT(J)%DSTL_HA(I) * JNT(J)%PROX_HA(I)              
       END DO                                                              
!C
       CALL MAT31 ( HIR(1,1,J), FE(1,J), TQE(1,J) )                        
!C
       IF ( NJ .LE. I_0 )  THEN                                    
        IF ( IGLOB(J) .NE. I_0 )  THEN                                   
         HD3(1) = TH(3,1)                                                   
         HD3(2) = TH(3,2)                                                   
         HD3(3) = TH(3,3)                                                   
         CALL GLOBAL ( J, HD3, DH1, TQC, T9, ANGL )                         
        END IF
       END IF
      END IF
!C                                                                          
!C    Add torque converted to local reference to U2 array by              
!C     U2(M  ) = U2(M  ) + DIR_COS(M  ) * TQ                              
!C     U2(J+1) = U2(J+1) - DIR_COS(J+1) * TQ                             
!C                                                                         
      DO  I=1,3                                                           
       JNT(J)%JTORQUE(I) = TQE(I,J) + TQC * T9(I)
       TTI(I) = JNT(J)%JTORQUE(I)
       DO  K=1,3                                                          
        SEG(M  )%EXT_ANG_ACL(K) = SEG(M  )%EXT_ANG_ACL(K) 
     &                    + SEG(M)%DIR_COS(K,I)   * JNT(J)%JTORQUE(I)         
        SEG(J+1)%EXT_ANG_ACL(K) = SEG(J+1)%EXT_ANG_ACL(K)
     &                    - SEG(J+1)%DIR_COS(K,I) * JNT(J)%JTORQUE(I)          
       END DO
      END DO
!C                                                                         
!C    Store data into PRJNT array for output routine.                      
!C                                                                         
      PRJNT(1,J) = IEULER(J)                                              
      PRJNT(2,J) = ANG(1,J)                                               
      PRJNT(3,J) = ANG(2,J)                                               
      PRJNT(4,J) = ANG(3,J)                                               
      PRJNT(5,J) = CS(1)**2 + CS(3)**2 + 
     &             D_2 * CS(1) * CS(3) * TH(3,3) + CS(2)**2            
      PRJNT(6,J) = CV(1)**2 + CV(3)**2 + 
     &             D_2 * CV(1) * CV(3) * TH(3,3) + CV(2)**2             
      PRJNT(7,J) = ( VECMAG ( JNT(J)%JTORQUE ) )**2
!C
      RETURN
      END