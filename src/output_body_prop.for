      SUBROUTINE  OUTPUT_BODY_PROP ( LTAPE8, LTHIST, NT, USEC_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine outputs the total body property time history
!C     data specified by Cards H.10.
!C
!C    It is called only by Subroutine OUTPUT.
!C
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       IDCG, ORIGIN,                         ! /CDH10C/
     &       G,                                    ! /CNSNTS/
     &       MCG, MCGIN,                           ! /RSAVE/
     &       TDATA,                                ! /HEDING_TEMPVS/
     &       SEG,                                  ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, ! parameters
     &       NUM_TTH_OFFSET,                       ! parameters
     &       D_0, D_HALF, I_0, I_1, I_2            ! parameters
!C
!C    ANG_VEL, DIR_COS, DRC_COS, LIN_DISP, LIN_VEL,        ! SEG%
!C    PHI,     ROT_PHI, WEIGHT                             ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, K, M, N, NCG, 
     &                                 NT, NTA, NTB
!C
      REAL  ( KIND = IREAL_HIGH )
     &                 PI1, PI2, PI3, PTOT, PRNAXS, SUMW, 
     &                 T1, T2_LCL, T3, T4, T5_LCL, T7, USEC_LCL, 
     &                 V, VEL_DIF, WG
      DIMENSION        PRNAXS(3), PTOT(3,3), T1(3), T2_LCL(3),
     &                 T3(3), T4(9), T5_LCL(3,3), T7(3), VEL_DIF(3) 
!C
      REAL  ( KIND = IREAL_HIGH )  VECMAG
      EXTERNAL                     VECMAG
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTAPE8, LTHIST
!C
      INTENT  (    IN )  LTAPE8, LTHIST, USEC_LCL
      INTENT  ( INOUT )  NT
!C
      IF ( MCG .EQ. I_0 )  THEN
       RETURN
      END IF  
!C
      DO  NCG=1,MCG                                                     
       M = MCGIN(1,NCG)                                                   
       N = MCGIN(2,NCG)                                                   
       T4 = D_0                                                       
       SUMW = D_0                                                      
       T7(1) = D_0                                                   
       T7(2) = D_0                                                  
       DO  I=1,N                                                          
        K = MCGIN(I+2,NCG)                                                
        WG = SEG(K)%WEIGHT / G                                           
        VEL_DIF = SEG(K)%LIN_VEL - SEG(M)%LIN_VEL
        V = ( VECMAG ( VEL_DIF ) )**2
        T7(1) = T7(1) + D_HALF * WG * V                                    
        SUMW = SUMW + WG                                                  
        DO  J=1,3                                                         
         T7(2) = T7(2) + D_HALF * SEG(K)%PHI(J) 
     &           * ( SEG(K)%ANG_VEL(J) - SEG(M)%ANG_VEL(J) )**2  
         T1(J) = SEG(K)%PHI(J) * SEG(K)%ANG_VEL(J)                             
        END DO
        CALL DOT31 ( SEG(K)%DIR_COS, T1, T2_LCL )                         
        CALL CROSS ( SEG(K)%LIN_DISP, SEG(K)%LIN_VEL, T1 )              
        DO  J=1,3                                                         
         T4(J  ) = T4(J  ) + WG * SEG(K)%LIN_DISP(J)                 
         T4(J+3) = T4(J+3) + WG * SEG(K)%LIN_VEL(J)               
         T4(J+6) = T4(J+6) + WG * T1(J) + T2_LCL(J)                       
        END DO
       END DO                                                             
       T7(3) = T7(1) + T7(2)                                             
       DO J=1,3
        T4(J) = T4(J) / SUMW - SEG(M)%LIN_DISP(J)                           
       END DO
!C                                                                        
!C     Transform from principal axes to local axes                        
!C                                                                        
       IF ( SEG(M)%ROT_PHI  )   THEN                                
        CALL DOT33 ( SEG(M)%DRC_PHI, SEG(M)%DIR_COS, T5_LCL )            
        CALL MAT31 ( T5_LCL, T4(1), T1     )                              
        CALL MAT31 ( T5_LCL, T4(4), T2_LCL )                              
        CALL MAT31 ( T5_LCL, T4(7), T3     )                              
       ELSE                                                               
        CALL MAT31 ( SEG(M)%DIR_COS, T4(1), T1     )                      
        CALL MAT31 ( SEG(M)%DIR_COS, T4(4), T2_LCL )                     
        CALL MAT31 ( SEG(M)%DIR_COS, T4(7), T3     )                     
       END IF                                                             
!C
!C     Print inertia tensor                                             
!C
       IF ( IDCG(NCG) .NE. I_0 )  THEN                                
        DO  J=1,3                                                       
         ORIGIN(J,NCG) = T1(J)                                          
        END DO
       END IF                                                           
       CALL INRTIA ( NCG, PTOT )                                        
       IF ( IDCG(NCG) .EQ. I_2 )  THEN                               
        CALL PRNCIPAL ( PTOT, PI1, PI2, PI3, PRNAXS )                   
       END IF                                                           
       NT = NT + I_2                                                   
       NTA = NT - I_1                                                  
       NTB = NT                                                         
       IF ( LTAPE8 )  THEN                                                
        DO  J=1,3                                                         
         TDATA (J  ,NTA-NUM_TTH_OFFSET)  = T1(J)                          
         TDATA (J+3,NTA-NUM_TTH_OFFSET)  = T2_LCL(J)                      
         TDATA(J+9,NTA-NUM_TTH_OFFSET)   = T7(J)                         
         TDATA(J+6,NTA-NUM_TTH_OFFSET)   = T3(J)                          
         TDATA(J,NTB-NUM_TTH_OFFSET)     = PTOT(J,J)                    
        END DO
        TDATA(4,NTB-NUM_TTH_OFFSET) = PTOT(1,2)                         
        TDATA(5,NTB-NUM_TTH_OFFSET) = PTOT(2,3)                         
        TDATA(6,NTB-NUM_TTH_OFFSET) = PTOT(3,1)                         
       END IF
       IF ( LTHIST )  THEN                                              
        WRITE ( NTA, 100 )  USEC_LCL, T1, T2_LCL, T3, T7                  
  100   FORMAT ( F9.3, 3F8.3, 9( 1X, D10.3 ) )                           
        IF ( IDCG(NCG) .NE. I_2 )  THEN                               
         WRITE ( NTB, 105 ) USEC_LCL, ( PTOT(J,J), J=1,3 ), PTOT(1,2),  
     &                      PTOT(2,3), PTOT(3,1)                        
  105    FORMAT ( F9.3, 6( 2X, D12.5 ) )                                
        ELSE                                                            
         WRITE ( NTB, 105 ) USEC_LCL, PI1, PI2, PI3,
     &                      ( PRNAXS(J), J=1,3 )                        
        END IF                                                          
       END IF                                                           
!C
      END DO                                                            
!
      RETURN
      END
    