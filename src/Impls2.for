      SUBROUTINE IMPLS2 ( MODE, J, H_LCL )                                
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Called by Subroutine UPDATE when joint J locks to apply impulse     
!C    to set P.(D(M)'W(M) - D(N)'W(N)) = 0                                
!C                                                                        
!C    Arguments:                                                          
!C         MODE -  0: full lock        P = I                              
!C                 1: axis (H) free    P = I - HH'                          
!C                -1: axis (H) locked  P = HH'                            
!C                                                                        
!C         J        - joint identification number                         
!C                                                                        
!C         H_LCL    - axis vector                                         
!C                                                                        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY: 
     &       V1, V2, V3,                            ! /CMATRX/
     &       NJNT, NQ, NFLX, NGRND, NPRT,           ! /CONTRL/
     &       V4,                                    ! /FLXBLE/
     &       SEG, JNT,                              ! structures
     &       INTEGER_STD, IREAL_HIGH, MAXSEG,       ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_3           ! parameters
!C
!C    ANG_ACCEL, ANG_VEL, DIR_COS,  EXT_ANG_ACL, EXT_LIN_ACL,  ! SEG%
!C    LIN_ACCEL, LIN_VEL, RECIP_PHI                            ! SEG%
!C    PROX_SEG                                                 ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) I, J, K, L, M, MODE, N
!C
      REAL  ( KIND = IREAL_HIGH )  
     &                  TWA, TLA, H_LCL, ST, STT, SM, SN, TM,
     &                  TN_LCL, T, TT
      DIMENSION         TWA(3,3,MAXSEG), TLA(3,3,MAXSEG), H_LCL(3),       
     &                  SM(3), SN(3), TM(3,3),TN_LCL(3,3),T(3,4),
     &                  TT(3,4)                                           
!C
      REAL  ( KIND = IREAL_HIGH )  XDY
      EXTERNAL                     XDY
!C
      INTENT ( IN )  MODE, J, H_LCL
!C
      CALL ELTIME ( I_1, 28_INTEGER_STD )                                               
!C
      M = JNT(J)%PROX_SEG                                               
      N = J + I_1                                                       
      DO 20 L=1,3                                                         
       DO  K=1,NGRND                                                      
        SEG(K)%EXT_LIN_ACL = D_0
        SEG(K)%EXT_ANG_ACL = D_0                                            
       END DO
       DO  K=1,NJNT                                                       
        DO  I=1,3                                                         
         V1(I,K) = D_0                                          
         V2(I,K) = D_0                                              
        END DO
       END DO
!C
       IF ( NQ .GT. I_0 )  THEN                                      
        DO  K=1,NQ                                                        
         DO  I=1,3                                                        
          V3(I,K) = D_0                                           
         END DO
        END DO
       END IF
!C
       IF ( NFLX .NE. I_0 )  THEN                                      
        DO  K=1,NFLX                                                      
         DO  I=1,3                                                        
          V4(I,K) = D_0                                         
         END DO
        END DO
       END IF
!C
       DO  I=1,3                                                          
        SEG(M)%EXT_ANG_ACL(I) = 
     &                        SEG(M)%RECIP_PHI(I) * SEG(M)%DIR_COS(I,L)                        
        SEG(N)%EXT_ANG_ACL(I) =
     &                       -SEG(N)%RECIP_PHI(I) * SEG(N)%DIR_COS(I,L)                         
       END DO
       CALL DAUX ( L )                                                    
       DO  K=1,NGRND                                                      
        DO  I=1,3                                                         
         TLA(I,L,K) = SEG(K)%LIN_ACCEL(I)                        
         TWA(I,L,K) = SEG(K)%ANG_ACCEL(I)                         
        END DO
       END DO
   20 CONTINUE                                                            
!C
      CALL DOT33 ( SEG(M)%DIR_COS, TWA(1,1,M),     TM     )                  
      CALL DOT33 ( SEG(N)%DIR_COS, TWA(1,1,N),     TN_LCL )                   
      CALL DOT31 ( SEG(M)%DIR_COS, SEG(M)%ANG_VEL, SM     )                  
      CALL DOT31 ( SEG(N)%DIR_COS, SEG(N)%ANG_VEL, SN     )                   
      DO  I=1,3                                                           
       DO  K=1,3                                                          
        T(I,K) = TM(I,K) - TN_LCL(I,K)                                    
        TT(I,K) = T(I,K)                                                  
       END DO
       T(I,4) = SN(I) - SM(I)                                             
       TT(I,4) = H_LCL(I)                                                 
      END DO
      IF ( MODE .GE. I_0 ) THEN
       CALL DSMSOL (  T, I_3 )                 
      ELSE
       CALL DSMSOL ( TT, I_3 )             
      END IF
!C
      IF ( MODE .LT. I_0 )  THEN
       ST = D_0                                                       
       STT = XDY ( H_LCL, T, H_LCL )                                      
       STT =  (   H_LCL(1) *  T(1,4) + H_LCL(2) *  T(2,4) 
     &          + H_LCL(3) *  T(3,4) ) / STT                               
       DO  I=1,3                                                           
        T(I,4) = ST * T(I,4) + STT * TT(I,4)                               
       END DO
      ELSE IF ( MODE .GT. I_0 )  THEN
       ST = D_1                                                           
       STT = -(   H_LCL(1) * TT(1,4) + H_LCL(2) * TT(2,4)
     &          + H_LCL(3) * TT(3,4) )                                     
       STT =  (   H_LCL(1) *  T(1,4) + H_LCL(2) *  T(2,4) 
     &          + H_LCL(3) *  T(3,4) ) / STT                               
       DO  I=1,3                                                           
        T(I,4) = ST * T(I,4) + STT * TT(I,4)                               
       END DO
      END IF
!C
      DO  K=1,NGRND                                                       
       DO  I=1,3                                                          
        DO  L=1,3                                                         
         SEG(K)%LIN_VEL(I) = SEG(K)%LIN_VEL(I) + T(L,4) * TLA(I,L,K)  
         SEG(K)%ANG_VEL(I) = SEG(K)%ANG_VEL(I) + T(L,4) * TWA(I,L,K)       
        END DO
       END DO
      END DO
      IF  ( NPRT(3) .NE. I_0 )    CALL PRINT ( 'IMPLS2' )            
!C
      CALL ELTIME ( I_2, 28_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
