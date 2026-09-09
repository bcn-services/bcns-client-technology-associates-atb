      SUBROUTINE FORCE_TORQUE
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine calculates the force and torque functions
!C     specified in Cards D.9.
!C
!C    It is called only by Subroutine CONTCT.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       TIME,                            ! /CONTRL/
     &       NTI,                             ! /TABLES/
     &       NFVNT, NFVSEG, QFU, QFV, NFORCE, ! /WINDFR/
     &       SEG,                             ! structures
     &       INTEGER_STD, IREAL_HIGH,         ! parameters
     &       I_0, I_1, MAX_FOR_TORQ           ! parameters
!C
!C    SEG%DIR_COS, SEG%EXT_ANG_ACL, SEG%EXT_LIN_ACL
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &       FIK,            ! /FXBODY/
     &       NODFR, PURTQ,   ! /FXFRC/
     &       IBODN, NFBOD    ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &          I, II, J, KFT, NFS, NFT
!C
      REAL  ( KIND = IREAL_HIGH )  FRCE, TM
      DIMENSION     TM(3)
!C 
      REAL  ( KIND = IREAL_HIGH )  EVALFD
      EXTERNAL                     EVALFD
!C
      DO  J=1,NFORCE                                                    
       NFS = ABS ( NFVSEG(J) )                                           
       NFT = ABS ( NFVNT(J) )                                             
       KFT = NTI(NFT)                                                    
       FRCE = EVALFD ( TIME, KFT, I_1 )                                    
       IF  ( NFVSEG(J) .GT. I_0 )   THEN                                   
        CALL DOT31 ( SEG(NFS)%DIR_COS, QFU(1,J), TM )                         
        SEG(NFS)%EXT_LIN_ACL = SEG(NFS)%EXT_LIN_ACL + FRCE * TM
        DO  I=1,3                                                         
         SEG(NFS)%EXT_ANG_ACL(I) = SEG(NFS)%EXT_ANG_ACL(I)
     &                                + FRCE * QFV(I,J)                         
        END DO
!C
!C      Add to the nodal forces for deformable body NFS               
!C
        DO  II=1,NFBOD                                                 
         IF ( IBODN(II) .EQ. NFS )  THEN                               
          DO  I=1,3                                                   
           FIK(I,NODFR(J),II) = FIK(I,NODFR(J),II) + FRCE * TM(I)      
          END DO
         END IF                                                       
        END DO                                                       
       ELSE
        DO  I=1,3                                                         
         SEG(NFS)%EXT_ANG_ACL(I) = SEG(NFS)%EXT_ANG_ACL(I) 
     &                                + FRCE * QFU(I,J)                         
        END DO
!C
!C      Compute applied pure torques for deformable body NFS          
!C
        DO  II=1,NFBOD                                               
         IF (IBODN(II).EQ.NFS) THEN                                 
          DO  I=1,3                                                  
           PURTQ(I,II) = PURTQ(I,II) + FRCE * QFU(I,J)                 
          END DO
         END IF                                                       
        END DO                                                       
       END IF                                                            
      END DO                                                       
!C
      RETURN                                                             
      END
       