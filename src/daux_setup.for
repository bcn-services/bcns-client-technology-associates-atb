      SUBROUTINE  DAUX_SETUP
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Set up initial values of A & B arrays and U & V vectors.              
!C    Modify U1 & U2 arrays by contact and joint forces.                    
!C
      USE  MODULE_STANDARD,  ONLY: 
     &               GRAVTY,                          ! /CNSNTS/
     &               NPRT, NGRND,                     ! /CONTRL/
     &               NFLX, NFLEX,                     ! /FLXBLE/
     &               SYMMETRY,                        ! /SGMNTS/ 
     &               SEG,                             ! structures
     &               INTEGER_STD, IREAL_HIGH,         ! parameters
     &               D_0, D_HALF, I_0, I_1            ! parameters
!C
!C    ANG_ACCEL,  DRC_PHI,   EXT_ANG_ACL, EXT_LIN_ACL, LIN_ACCEL,  ! SEG%
!C    RECIP_MASS, RECIP_PHI, ROT_PHI,     SINGULAR,    WEIGHT      ! SEG%  
!C
      USE  MODULE_WATER,  ONLY:  NWATER,              ! /WATINF1/
     &                           WXX                  ! /WMASS/
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  J, K
!C
      REAL  ( KIND = IREAL_HIGH )   T1, T2_LCL, T3
      DIMENSION                     T1(3), T2_LCL(3), T3(3)          
!C                                                                          
!C    Set up initial values of A & B arrays and U & V vectors.              
!C    Modify U1 & U2 arrays by contact and joint forces.                    
!C                                                                          
!C    Recompute joint locations and velocities to include flexibility   
!C 
      CALL FJNTVC ( I_1 )                                            
!C                                                                      
      CALL CHAIN ( NPRT(36) )                                             
      CALL SETUP1                                                           
      CALL VEHPOS                                                           
      CALL CONTCT                                                           
      CALL VISPR ( I_0, I_0 )                                        
      CALL EJOINT ( I_0, I_0 )                                        
      CALL SETUP2                                                           
      IF ( NFLX .GT. I_0 )  CALL FLXSEG                                  
!C                                                                      
!C    Set up B1A & B2A matrices and revise V1 & V2.                      
!C
      CALL FSETUP                                                       
!C                                                                          
!C    Modify U1, U2 and add G to U1.                                        
!C                                                                          
      DO  J=1,NGRND                                                         
       IF  ( SEG(J)%SINGULAR .LT. I_0 )  THEN                                        
        SEG(J)%EXT_LIN_ACL = SEG(J)%LIN_ACCEL                             
        SEG(J)%EXT_ANG_ACL = SEG(J)%ANG_ACCEL                   
       ELSE IF ( SEG(J)%SINGULAR .EQ. I_0 )  THEN
        IF ( NWATER .EQ. I_0 ) THEN                                    
         SEG(J)%EXT_LIN_ACL =   SEG(J)%EXT_LIN_ACL 
     &                        * SEG(J)%RECIP_MASS + GRAVTY       
        ELSE                                                         
         SEG(J)%EXT_LIN_ACL =   SEG(J)%EXT_LIN_ACL
     &                        * SEG(J)%RECIP_MASS 
     &                        + WXX(J) / SEG(J)%WEIGHT * GRAVTY        
        END IF                                                     
        SEG(J)%EXT_ANG_ACL = SEG(J)%EXT_ANG_ACL * SEG(J)%RECIP_PHI     
       END IF
      END DO                                                                
!C                                                                       
!C    Setup deformable body equations of motion.                        
!C
      CALL FXMASS                                                       
!C                                                                          
!C    Set up body segment symmetry:                                         
!C        SYM(J) = 0    3D motion                                           
!C        SYM(J) = J    central segment 2D motion, no lateral motion        
!C        SYM(J) = K    segment J symmetric to segment K, all motion        
!C                       in the X-Z plane, no lateral motion                
!C        SYM(J) = -K   segment J mirror symmetric to segment K, equal      
!C                       but opposite lateral motion permitted              
!C                                                                          
      DO  20  J=1,NGRND                                                     
       IF ( SYMMETRY(J) .EQ. I_0 )  CYCLE                           
       K = ABS ( SYMMETRY(J) )                                          
       T1     = SEG(J)%EXT_ANG_ACL                               
       T2_LCL = SEG(K)%EXT_ANG_ACL                                  
       T3     = SEG(J)%EXT_ANG_ACL                                       
!C
!C     Adjust for rotated principal axes.
!C
       IF ( SEG(J)%ROT_PHI .AND. ( .NOT. SEG(K)%ROT_PHI ) )  THEN         
        CALL DOT31 ( SEG(J)%DRC_PHI, SEG(J)%EXT_ANG_ACL, T1 )                           
       ELSE IF ( ( .NOT. SEG(J)%ROT_PHI ) .AND. SEG(K)%ROT_PHI ) THEN           
        CALL DOT31 ( SEG(K)%DRC_PHI, SEG(K)%EXT_ANG_ACL, T2_LCL)            
       ELSE IF ( SEG(J)%ROT_PHI .AND. SEG(K)%ROT_PHI )  THEN
        CALL DOT31 ( SEG(J)%ROT_PHI, SEG(J)%EXT_ANG_ACL, T1 )                  
        CALL DOT31 ( SEG(K)%ROT_PHI, SEG(K)%EXT_ANG_ACL, T2_LCL )             
       END IF
!C
       IF ( SYMMETRY(J) .EQ. J )  THEN                               
        SEG(J)%EXT_LIN_ACL(2) = D_0                                    
        T3(1)   = D_0                                             
        T3(3)   = D_0                                                    
!C
        IF ( SEG(J)%ROT_PHI )  THEN                                  
         CALL MAT31 ( SEG(J)%DRC_PHI, T3, SEG(J)%EXT_ANG_ACL )         
        ELSE                                                              
         SEG(J)%EXT_ANG_ACL = T3
        END IF
        CYCLE
       END IF
!C
       IF ( K .GE. J )  THEN                                                
        SEG(J)%EXT_LIN_ACL(1) = 
     &     D_HALF * ( SEG(J)%EXT_LIN_ACL(1) + SEG(K)%EXT_LIN_ACL(1) )                 
        SEG(J)%EXT_LIN_ACL(3) = 
     &     D_HALF * ( SEG(J)%EXT_LIN_ACL(3) + SEG(K)%EXT_LIN_ACL(3) )           
        T3(2) =   D_HALF * ( T1(2)   + T2_LCL(2) )                         
       ELSE
        SEG(J)%EXT_LIN_ACL(1) = SEG(K)%EXT_LIN_ACL(1)                                           
        SEG(J)%EXT_LIN_ACL(3) = SEG(K)%EXT_LIN_ACL(3)                       
        T3(2)   = T2_LCL(2)                                                 
       END IF
!C
       IF ( SYMMETRY(J) .LE. I_0 )  THEN                                   
        IF ( K .GE. J )  THEN                                               
         SEG(J)%EXT_LIN_ACL(2) = 
     &     D_HALF * ( SEG(J)%EXT_LIN_ACL(2) - SEG(K)%EXT_LIN_ACL(2)   )       
         T3(1)   = D_HALF * ( T1(1)   - T2_LCL(1) )                         
         T3(3)   = D_HALF * ( T1(3)   - T2_LCL(3) )                          
        ELSE
         SEG(J)%EXT_LIN_ACL(2) = -SEG(K)%EXT_LIN_ACL(2)                    
         T3(1)                 = -T2_LCL(1)                       
         T3(3)                 = -T2_LCL(3)                        
        END IF
       ELSE
        SEG(J)%EXT_LIN_ACL(2) = D_0                                   
        T3(1)                 = D_0                                            
        T3(3)                 = D_0                                
       END IF
!C
       IF ( SEG(J)%ROT_PHI )  THEN                                
        CALL MAT31 ( SEG(J)%ROT_PHI, T3, SEG(J)%EXT_ANG_ACL )       
       ELSE                                                               
        SEG(J)%EXT_ANG_ACL = T3
       END IF
   20 CONTINUE                                                            
!C
      RETURN
      END 