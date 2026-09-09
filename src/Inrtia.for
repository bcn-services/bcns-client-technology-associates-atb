      SUBROUTINE INRTIA ( NCG, PTOT )                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine computes the combined inertia tensor for
!C    groups of segments specified in H.10 Card.  
!C    NCG:       number of the total body group
!C    ORIGIN(3,5): X,Y,Z coordinates in the ref. system for the origin 
!C                 of the target system to which combined inertia tensor 
!C                 are given.  
!C    XYZANG(3,5): X,Y,Z axes orientation w.r.t. ref. system in yaw, 
!C                 pitch, row. 
!C    ISEQ(3,5): sequence of yaw, pitch and row.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       ISEQ, ORIGIN, XYZANG,                 ! /CDH10C/    
     &       G,                                    ! /CNSNTS/
     &       MCGIN,                                ! /RSAVE/
     &       SEG,                                  ! structures
     &       INTEGER_STD, IREAL_HIGH, MAXSEG,      ! parameters
     &       D_0, D_1, I_3                         ! parameters 
!C
!C   DIR_COS, DRC_PHI, LIN_DISP, PHI, ROT_PHI, WEIGHT   ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )   I, J, K, L, MREF, N, NCG
!C
      REAL  ( KIND = IREAL_HIGH )
     &                    DSYS, CMSEG, T1_LCL, T2_LCL, T3, PRIN, 
     &                    PSEG, CMVEC, T4, PTOT, T5_LCL, T6, T7
      DIMENSION DSYS(3,3), CMSEG(3,MAXSEG), T1_LCL(3,3), T2_LCL(3,3), 
     &          T3(3,3), PRIN(3,3), PSEG(3,3), CMVEC(3,3), T4(3,3), 
     &          PTOT(3,3), T5_LCL(3), T6(3,3), T7(3)
!C
      INTENT (  IN )  NCG
      INTENT ( OUT )  PTOT
!C
!C    Initialization.
!C
      PTOT = D_0
!C
      MREF = MCGIN(1,NCG)
      N = MCGIN(2,NCG)
!C
!C    Find C.M. coord. in target system for each segment.  
!C
      IF ( ( XYZANG(1,NCG) .EQ. D_0 ) .AND. ( XYZANG(2,NCG) .EQ. D_0 )
     &                        .AND. ( XYZANG(3,NCG) .EQ. D_0 )  ) THEN
       DO  I = 1,3
        DO  J = 1,3
         IF ( I .EQ. J )  THEN
          DSYS(I,J) = D_1
         ELSE
          DSYS(I,J) = D_0
         END IF
        END DO
       END DO
      ELSE
         CALL DRCYPR ( DSYS, XYZANG(1,NCG), ISEQ(1,NCG) )
      END IF
!C
!C    T6 is a transform from inertia to target system
!C
      IF ( .NOT. SEG(MREF)%ROT_PHI )  THEN
         CALL MAT33 ( DSYS, SEG(MREF)%DIR_COS, T6 )
      ELSE
         CALL DOT33 ( SEG(MREF)%DRC_PHI, SEG(MREF)%DIR_COS, T1_LCL )
         CALL MAT33 ( DSYS, T1_LCL, T6 )
      END IF
         CALL MAT31 ( T6, SEG(MREF)%LIN_DISP, T7 )
         CALL MAT31 ( DSYS, ORIGIN(1,NCG), T5_LCL )
      DO  I = 1,N
       L = MCGIN(I+2,NCG)
       CALL MAT31 ( T6, SEG(L)%LIN_DISP, CMSEG(1,L) )
       DO  J = 1,3
        CMSEG(J,L) = CMSEG(J,L) - (T5_LCL(J) + T7(J))
       END DO         
      END DO
!C     
!C    Compute the total body inertia tensor.
!C
      DO 50 I = 1,N
!C
!C     Cosine matrix T1_LCL corresponding a transform from segment's 
!C      principal axes to target system
!C
       L = MCGIN(I+2,NCG)
       CALL DOTT33 ( T6, SEG(L)%DIR_COS, T1_LCL )
       CALL TRNPOS ( T1_LCL, T2_LCL, I_3, I_3, I_3, I_3)
!C
!C     Segment's pricipal moment of inertia tensor.         
!C
       DO  J = 1,3
        DO  K = 1,3
         IF ( J .EQ. K )  THEN
          PRIN(J,K) = SEG(L)%PHI(J)
         ELSE               
          PRIN(J,K) = D_0
         END IF
         CMVEC(J,K) = D_0
        END DO
       END DO
!C
!C     CM vector in target system represented by skew matrix.
!C
       CMVEC(1,2) = -CMSEG(3,L)
       CMVEC(1,3) =  CMSEG(2,L)
       CMVEC(2,1) = -CMVEC(1,2)
       CMVEC(2,3) = -CMSEG(1,L)
       CMVEC(3,1) = -CMVEC(1,3)
       CMVEC(3,2) = -CMVEC(2,3)
!C
!C     Segment's inertia tensor given in target system.      
!C
       CALL MAT33 ( T1_LCL, PRIN, T3 ) 
       CALL MAT33 ( T3, T2_LCL, PSEG )
       CALL MAT33 ( CMVEC, CMVEC, T4 )
       DO  K = 1,3
        DO  J = 1,3
         PSEG(K,J) = PSEG(K,J) - SEG(L)%WEIGHT * T4(K,J) / G
        END DO
       END DO
       DO  K = 1,3
        DO  J =1,3
         PTOT(K,J) = PTOT(K,J) + PSEG(K,J)
        END DO
       END DO
   50 CONTINUE
!C
      RETURN
      END
