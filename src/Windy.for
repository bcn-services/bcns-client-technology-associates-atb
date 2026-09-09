      SUBROUTINE WINDY ( MMM, MM, N, NN_LCL, NT )                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes forces and torques adding them to the U1 and U2 arrays     
!C    of wind blast forces determined by function stored in TAB(NT)        
!C    on ellipsoid (MM) attached to body segment (M) which extends         
!C    through the intersecting plane (NN) attached to segment (N).        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &       BD, PL,                               ! /CNTSRF/
     &       TIME,                                 ! /CONTRL/
     &       NTI, TAB,                             ! /TABLES/
     &       IWIND, MWSEG, WF, WTIME,              ! /WINDFR/
     &       SEG,                                  ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, ! parameters
     &       D_0, D_1, D_HALF,                     ! parameters
     &       I_0, I_1, I_2, I_4, I_10              ! parameters
!C
!C    DIR_COS, EXT_ANG_ACL, EXT_LIN_ACL, LIN_DISP, LIN_VEL  ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I,  K, K1, K2, KK, KT, M, MM, MMM, 
     &         N, NENTRY, NN_LCL, NSR, NSV, NT, NTC
!C
      REAL  ( KIND = IREAL_HIGH )
     &             BET_LCL, BTE_LCL, BTS, 
     &             C_LCL, CD, DMNT, FF_LCL, FT, FTIME, 
     &             P, PR, R1, R22, RK, RM, 
     &             TM, TQM, TTF, V, XMM, XMN 
!C
      DIMENSION    DMNT(3,3), FF_LCL(3), FT(3), RM(3),
     &             TM(3), TQM(3), TTF(3), XMM(3), XMN(3)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LOGI_RETURN
!C                                                                      
      CALL ELTIME ( I_1, 37_INTEGER_STD )                                                
!C
      M = ABS ( MMM )                                                     
!C                                                                         
!C    Compute penetration distance; if negative, return.                   
!C                                                                         
      CALL DOTT33 ( SEG(M)%DIR_COS, SEG(N)%DIR_COS, DMNT )                 
      XMN = SEG(M)%LIN_DISP - SEG(N)%LIN_DISP                        
      CALL MAT31 ( SEG(M)%DIR_COS, XMN, XMM )                          
      CALL MAT31 ( DMNT, PL(1,NN_LCL), TM )                                
      BET_LCL = PL(4,NN_LCL)                                             
      DO  I=1,3                                                            
       BET_LCL = BET_LCL - TM(I) * ( BD(I+3,MM) + XMM(I) )                
      END DO
      CALL MAT31 ( BD(16,MM), TM, RM )                                     
      BTS = DOT_PRODUCT ( TM, RM )
      BTE_LCL = -SQRT ( BTS )                                             
      P   = BET_LCL - BTE_LCL                                              
      IF ( P .LT. D_0 )  THEN                                   
       CALL ELTIME ( I_2, 37_INTEGER_STD )                                               
       RETURN
      END IF
!C                                                                         
!C    Fetch or store initial penetration time.                             
!C                                                                         
      IWIND(M) = M                                                         
      IF ( TIME .LE. WTIME(M) )  WTIME(M) = TIME                          
      FTIME = TIME - WTIME(M)                                              
!C                                                                         
!C    Get drag coefficient CD from table NTC for TIME = FTIME.            
!C                                                                        
      CD = D_1                                                            
      NTC = MWSEG(6,M)                                                   
      IF ( NTC .NE. I_0 )  THEN                                       
       KT = NTI(NTC)                                                      
       NENTRY = TAB(KT+5)                                                 
       K1 = KT + I_10                                                   
       K2 = I_4 * NENTRY + KT + I_2                                 
       IF ( NENTRY .NE. I_1 )  THEN                                    
        DO  K=K1,K2,4                                                     
         IF ( FTIME .GT. TAB(K) )  THEN
          CYCLE                                                         
         ELSE
          KK = K                                                           
          R1 = ( TAB(K) - FTIME ) / ( TAB(K) - TAB(K-4) )                  
          EXIT                                                         
         END IF
        END DO                                                           
       ELSE
        KK = K2                                                            
        R1 = D_0                                                     
       END IF
       R22 = D_1 - R1                                                   
       K = KK + I_1                                                    
       CD = R22 * TAB(K) + R1 * TAB(K-4)                                  
      END IF
!C                                                                        
!C    Get force vector FT                                                 
!C                                                                        
!C         RK=0   time dependent wind force from table                    
!C         RK#0   velocity dependent wind force                           
!C                                                                        
      KT = NTI(NT)                                                        
      RK = TAB(KT)                                                        
      IF ( RK .NE. D_0 )  THEN                                  
       C_LCL = TAB(KT+1)                                                  
       PR = TAB(KT+2)                                                     
       NSV = INT ( TAB(KT+3) )                                            
       NSR = INT ( TAB(KT+4) )                                            
       DO  I=1,3                                                          
        V = SEG(NSV)%LIN_VEL(I) - SEG(NSR)%LIN_VEL(I)            
        FT(I) = SIGN ( D_HALF, -V ) * CD * RK * PR * V**2 / C_LCL**2     
       END DO
      ELSE
       NSR = INT ( TAB(KT+4) )                                            
       NENTRY = TAB(KT+5)                                                 
       K1 = KT + I_10                                                     
       K2 = 4 * NENTRY + KT + I_2                                      
       IF ( NENTRY .NE. I_1 ) THEN                                    
        DO  K=K1,K2,4                                                      
         IF ( FTIME .GT. TAB(K) )  THEN
          CYCLE                                                            
         ELSE 
          KK = K                                                            
          R1 = ( TAB(K) - FTIME ) / ( TAB(K) - TAB(K-4) )                   
          EXIT                                                         
         END IF
        END DO                                                             
       ELSE
        KK = K2                                                             
        R1  = D_0                          
       END IF
       R22 = D_1 - R1                                                    
       DO  I=1,3                                                           
        K = KK + I                                                         
        FT(I) = ( R22 * TAB(K) + R1 * TAB(K-4) ) * CD                   
       END DO
       IF ( NSR .NE. I_0 )  THEN                                    
        CALL DOT31 ( SEG(NSR)%DIR_COS, FT, FF_LCL )                       
        FT = FF_LCL                                                        
       END IF
      END IF
!C
!C    Compute the wind force by one of two methods.
!C
      IF ( MMM .GT. I_0 )  THEN                                            
!C
!C     Calculate the wind force calculated using entire area method,
!C        MMM > 0            
!C
       CALL WIND_AREA ( BET_LCL, BTE_LCL, BTS, FT, LOGI_RETURN,
     &                  M, MM, P, RM, TM, TQM, TTF )
      ELSE IF ( MMM .LT. I_0 )  THEN
!C
!C    MMM<0   wind force calculated using grid method                     
!C                        (allows blocking segments)                      
!C
       CALL WIND_GRID ( FT, LOGI_RETURN, M, MM, N, NN_LCL, TQM, TTF )
      END IF
!C                                                                        
!C    Add force & torque to U1 & U2 arrays for segment M                  
!C                                                                        
      IF ( .NOT. LOGI_RETURN )  THEN
       SEG(M)%EXT_LIN_ACL = SEG(M)%EXT_LIN_ACL + TTF                                      
       SEG(M)%EXT_ANG_ACL = SEG(M)%EXT_ANG_ACL + TQM                     
       DO  I=1,3                                                        
        WF(I,M) = TTF(I)                                                 
       END DO
      END IF
!C
      CALL ELTIME ( I_2, 37_INTEGER_STD )                                                
!C
      RETURN 
      END                                                                 
