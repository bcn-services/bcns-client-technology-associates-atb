      SUBROUTINE BELTRT ( I, II, MM, M, NT )                              
!C                                                   Rev. V.3 12/15/2002 
!C
!C    The routine calls Subroutine BELTG to compute the tangent points    
!C    and belt lengths and applies the restraint forces to the U1 array   
!C    and belt torques to the U2 array for ellipsoid(II) attached to      
!C    body segment (I) by BELT (M) attached to segment (MM).              
!C                                                                        
!C
      USE  MODULE_STANDARD,  ONLY:   
     &       UNITL,                                      ! /CNSNTS/
     &       BELT, BD, TPTS, BELT_FORCE,                 ! /CNTSRF/
     &       TIME,                                       ! /CONTRL/
     &       NTAB,                                       ! /TABLES/
     &       APA, APB, UAA, UBB, DLGA, DLGB, UVA, UVB,   ! /BELT_TEMPVS/
     &       SEG,                                        ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU,             ! parameters 
     &       D_0, I_0, I_1, I_2, I_100                   ! parameters
!C
!C    DIR_COS, DRC_PHI, EXT_ANG_ACL, EXT_LIN_ACL, LIN_DISP,  ! SEG%
!C    ROT_PHI
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &                   I, II, K, M, MA, MB, MM, NCF, NT
!C
      REAL  ( KIND = IREAL_HIGH ) 
     &                  TA, TB, ZA, ZB, TT, TTT, TA1, TB1,
     &                  TLA, TLB, TL, B1213, SDOT, S, SA, SB,
     &                  FA, FB, ELOSS
      DIMENSION  TA(3), TB(3), ZA(3), ZB(3), TT(3), TTT(3),
     &           TA1(3), TB1(3)                                           
!C                                                                        
      INTENT ( IN )  I, II, MM, M, NT 
!C
      CALL ELTIME ( I_1, 22_INTEGER_STD )                                               
!C                                                                        
!C    Convert segment position to segment reference.                     
!C                                                                        
      MA = MOD ( MM, I_100 )                                  
      MB = MM / I_100                                           
      IF ( MB .EQ. I_0 )  MB = MA                                     
      CALL DOT31 ( SEG(MA)%DIR_COS, BELT(1,M), TA )                       
      CALL DOT31 ( SEG(MB)%DIR_COS, BELT(4,M), TB )                       
      TA = SEG(MA)%LIN_DISP + TA - SEG(I)%LIN_DISP               
      TB = SEG(MB)%LIN_DISP + TB - SEG(I)%LIN_DISP                
      CALL MAT31 ( SEG(I)%DIR_COS, TA, ZA )                              
      CALL MAT31 ( SEG(I)%DIR_COS, TB, ZB )                               
      DO  K=1,3                                                          
       ZA(K) = ZA(K) - BD(K+3,II)                                         
       ZB(K) = ZB(K) - BD(K+3,II)                                        
      END DO
!C                                                                        
!C    Compute new belt lengths and expansion.                            
!C                                                                        
      CALL BELTG ( ZA, ZB, BELT(7,M), BD(1,II) )                          
      TLA = DLGA + UAA                                                    
      TLB = DLGB + UBB                                                  
      TL  = TLA + TLB                                                     
      IF  ( TIME .EQ. D_0 )  THEN                                       
!C                                                                        
!C    If TIME=0, compute initial belt lengths                             
!C    and store results in BELT array.                                  
!C                                                                      
       IF ( BELT(11,M) .LT. D_0 ) BELT(11,M) = -BELT(11,M) - TL         
       IF ( BELT(11,M) .LT. D_0 ) BELT(11,M) = D_0                    
       BELT(12,M) = TLA + TLA / TL * BELT(11,M)                           
       BELT(13,M) = TLB + TLB / TL * BELT(11,M)                           
       B1213 = BELT(12,M) + BELT(13,M)                                    
       BELT(10,M) = B1213                                                
!C
       TA1 = APA                                        
       TB1 = APB                                            
       IF ( SEG(I)%ROT_PHI )  THEN                                 
        CALL DOT31 ( SEG(I)%DRC_PHI, APA, TA1 )                      
        CALL DOT31 ( SEG(I)%DRC_PHI, APB, TB1 )                       
       END IF                                                            
       WRITE ( LUAOU, 100 ) M, B1213, BELT(12,M), BELT(13,M), 
     &                     UNITL,I,TA1, TB1    
  100  FORMAT ( '0 Initial lengths of belt no.', I3,
     &          ' and its segments are', 3F12.4, 1X, A4, /, 
     &          '0 Initial tangent points in local reference of ', 
     &          'segment ', I2, ' are:', /, 2( 3X, 3F12.3 ) )             
      END IF
!C                                                                        
!C    Convert tangent points to inertial reference and store.             
!C                                                                        
      CALL DOT31 ( SEG(I)%DIR_COS, APA, TPTS(1,M) )                             
      CALL DOT31 ( SEG(I)%DIR_COS, APB, TPTS(4,M) )                      
      DO  K=1,3                                                           
       TPTS(K  ,M) = TPTS(K  ,M) + SEG(I)%LIN_DISP(K)                
       TPTS(K+3,M) = TPTS(K+3,M) + SEG(I)%LIN_DISP(K)              
      END DO
      SDOT = D_0                                                      
      NCF = NTAB(NT+5)                                                    
      IF  ( NCF .EQ. I_0 )  THEN                                      
!C                                                                        
!C    Zero belt friction, compute strain and force of entire belt.        
!C                                                                        
       B1213 = BELT(12,M) + BELT(13,M)                                    
       S = ( TL - B1213 ) / B1213                                         
       SA = S                                                            
       SB = S                                                             
       IF  ( S .LT. D_0 )   S = D_0                                   
       CALL FRCDFL ( S, SDOT, NT, 1, FA, ELOSS )                         
       FB = FA                                                            
!C                                                                        
!C    Full belt friction, compute strain and force of each part of belt.  
!C                                                                        
      ELSE
       IF  ( TL .LE. BELT(10,M) )  THEN                                  
        FA = D_0                                                        
        FB = D_0                                                        
        SA = ( TL - BELT(10,M) ) / BELT(10,M)                             
        SB = SA                                                          
        BELT(12,M) = TLA                                                 
        BELT(13,M) = TLB                                                  
       ELSE                                                              
        S = ( TLA - BELT(12,M) ) / BELT(12,M)                             
        SA = S                                                            
        IF  ( S .LT. D_0 )  S = D_0                              
        CALL FRCDFL ( S, SDOT, NT, I_1, FA, ELOSS )                     
        S = ( TLB - BELT(13,M) ) / BELT(13,M)                            
        SB = S                                                            
        IF  ( S .LT. D_0 )   S = D_0                               
        CALL FRCDFL ( S, SDOT, (NT + 6), I_1, FB, ELOSS )              
        BELT(10,M) = D_0                                               
       END IF
      END IF
      BELT_FORCE(1,M) = SA                                             
      BELT_FORCE(2,M) = FA                                           
      BELT_FORCE(3,M) = SB                                            
      BELT_FORCE(4,M) = FB                                             
      IF  ( ( FA + FB ) .LE. D_0 )   THEN                           
       CALL ELTIME ( I_2, 22_INTEGER_STD )                                              
       RETURN                                                             
      END IF
!C                                                                        
!C    Compute force vectors.                                             
!C                                                                        
      UVA = FA * UVA                                      
      UVB = FB * UVB                                       
!C                                                                        
!C    Convert forces to inertial reference and add to U1 array.           
!C                                                                        
      CALL DOT31 ( SEG(I)%DIR_COS, UVA, TT  )                                   
      CALL DOT31 ( SEG(I)%DIR_COS, UVB, TTT )                             
      SEG(MA)%EXT_LIN_ACL = SEG(MA)%EXT_LIN_ACL - TT               
      SEG(MB)%EXT_LIN_ACL = SEG(MB)%EXT_LIN_ACL - TTT                           
      SEG(I)%EXT_LIN_ACL  = SEG(I)%EXT_LIN_ACL  + TTT + TT                    
!C
!C    Add to nodal forces for deformable bodies MA, MB, I                 
!C
      CALL FXCBLT ( MA, MB, I, BELT(1,M), BELT(4,M), APA, 
     &              APB, TT, TTT )       
!C                                                                      
!C    Convert torques to local reference and add to external 
!C     angular acceleration array.  
!C                                                                       
      CALL MAT31 ( SEG(MA)%DIR_COS, TT, ZA )                              
      CALL MAT31 ( SEG(MB)%DIR_COS, TTT, ZB )                            
      CALL CROSS ( BELT(1,M), ZA, TA )                                    
      CALL CROSS ( BELT(4,M), ZB, TB )                                    
      CALL CROSS ( APA, UVA, TT )                                         
      CALL CROSS ( APB, UVB, TTT )                                        
      SEG(MA)%EXT_ANG_ACL = SEG(MA)%EXT_ANG_ACL - TA                    
      SEG(MB)%EXT_ANG_ACL = SEG(MB)%EXT_ANG_ACL - TB                 
      SEG(I)%EXT_ANG_ACL  = SEG(I)%EXT_ANG_ACL  + ( TT + TTT )        
!C
      CALL ELTIME ( I_2, 22_INTEGER_STD )                                               
!C
      RETURN                                                            
      END                                                                
