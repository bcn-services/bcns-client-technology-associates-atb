      SUBROUTINE AIRBGG ( J )                                             
!C                                                   Rev. V.3 12/15/2002 
!C    Called by Subroutines AIRBAG and AIRBG3 to compute volumes of      
!C    Intersection between airbags and panels and segments.               
!C                                                                        
!C
!C
      uSE  MODULE_STANDARD,  ONLY:
     &       CYMIN, IFULL, SCALEX, AB, VOLBP,         ! /ABDATA/
     &       TV1, TV2, VSCS, B, BFB, DEPLOY, DPVCTR,  ! /ABDATA/
     &       NVEH, TIME,                              ! /CONTRL/ 
     &       BD,                                      ! /CNTSRF/
     &       CYTD, CYC, CYK, CYRHO, CYRHO0, CYT, CYT0,! /CYDATA/
     &       CYP, CYP0, CYV0, CYV, CYVMAX,            ! /CYDATA/
     &       NPANEL,                                  ! /FORCES/
     &       MNBAG, MBAG,                             ! /JBARTZ/
     &       TMP, FORCE, TORA, FRA,                   ! /AIRBAG_TEMPVS/
     &       TORQ, TQB, VOLP, FRB, VOL,               ! /AIRBAG_TEMPVS/
     &       SEG,                                     ! structures
     &       INTEGER_STD, IREAL_HIGH,                 ! parameters
     &       I_0, D_0, D_1, D_2                       ! parameters
!C
!C    ANG_VEL, DIR_COS, LIN_DISP, LIN_VEL    ! SEG%
!C
      USE  MODULE_FLEXIBLE,      ONLY: YFB            ! /FXFRC/
!C
      IMPLICIT  NONE
!C
!C    Local variables
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, JB, K, KBAG, KP, M, MM
!C
      REAL  ( KIND = IREAL_HIGH )  CYK1, Q, Q1, Q2, SAB, VOLB   
!C
      INTENT ( IN )   J
!C
      JB = NVEH + J                                                       
      VOLBP(J) = D_0                                                    
!C                                                                        
!C    Compute thermodynamic properties of airbag                          
!C        CYRHO  : density                                                
!C        CYT    : temperature                                            
!C        CYP    : pressure                                              
!C        CYMIN  : mass flow into bag                                     
!C        VBCALC : calculated volume                                      
!C                                                                        
      Q  = D_1                                                            
      Q1 = D_1                                                           
      Q2 = D_1                                                           
      IF  ( TIME .GT. CYTD(J) )  THEN                                     
       Q  = D_1 + CYC(J) * ( TIME - CYTD(J) )                             
       CYK1 = D_2 / ( CYK(J) - D_1 )                                     
       Q1 = D_1 / Q**CYK1                                               
       Q2 = D_1 / Q**( CYK(J) * CYK1 )                                   
      END IF
      CYRHO(J) = CYRHO0(J) * Q1                                           
      CYT(J)   = CYT0(J) / Q**2                                           
      CYP(J)   = CYP0(J) * Q2                                             
      CYMIN(J) = CYV0(J) * ( CYRHO0(J) - CYRHO(J) )                      
      CYV(J)    = CYVMAX(J) * ( D_1 - Q2 )                              
      IF  ( ( TIME .LT. CYTD(J) )  .OR.                                   
     &      ( BD(1,JB) .EQ. D_0 )  .OR.                                 
     &      ( TIME .LE. D_0 ) )   THEN                                   
       RETURN
      END IF
      VOLB = D_0                                                       
!C                                                                        
!C    Compute airbag ellipsoid matrix and zero bag force and torque.      
!C                                                                        
      IF  ( IFULL(J) .EQ. I_0 )   THEN                               
       SAB = SCALEX(J) * AB(1,J)                                          
       DO  I=1,3                                                          
        TMP(I) = DEPLOY(I,J) + SAB * DPVCTR(I,J)                          
       END DO
       CALL DOT31 ( SEG(NVEH)%DIR_COS, TMP, SEG(JB)%LIN_DISP )                
       SEG(JB)%LIN_DISP = SEG(JB)%LIN_DISP + SEG(NVEH)%LIN_DISP    
      END IF
      DO  I=1,3                                                          
       FORCE(I,J) = D_0                                                
       TORA (I,J) = D_0                                                
      END DO
!C                                                                        
!C    Compute force,torque and volume of intersection                     
!C    of airbag with reaction panel ellipsoids.                           
!C                                                                        
      KP = NPANEL(J)                                                     
      DO  K=1,KP                                                          
       CALL BGG ( BD(7,JB), SEG(JB)%LIN_DISP, SEG(JB)%DIR_COS, 
     &            BD(4,JB), SEG(JB)%LIN_VEL, SEG(JB)%ANG_VEL, B(1,K,J), 
     &            SEG(NVEH)%LIN_DISP,
     &            SEG(NVEH)%DIR_COS, BFB(1,K,J), SEG(NVEH)%LIN_VEL,  
     &            SEG(NVEH)%ANG_VEL, VSCS(J), IFULL(J), TV1(1,K,J),     
     &            FRA(1,K), TORQ, TQB, VOLP(K,J), YFB(1,I) )              
       VOLBP(J) = VOLBP(J) + VOLP(K,J)                                    
       DO  I=1,3                                                          
        FORCE(I,J) = FORCE(I,J) + FRA(I,K)                                
        TORA (I,J) = TORA (I,J) + TORQ(I)                                 
       END DO
      END DO
!C                                                                        
!C    Compute force,torque and volume of intersection                     
!C    of airbag with contacting segment ellipsoids.                       
!C                                                                        
      KBAG = MNBAG(J)                                                     
      DO  I=1,KBAG                                                        
       M  = MBAG(2,I,J)                                                   
       MM = MBAG(3,I,J)                                                   
       CALL BGG ( BD(7,JB), SEG(JB)%LIN_DISP, SEG(JB)%DIR_COS, 
     &            BD(4,JB), SEG(JB)%LIN_VEL, SEG(JB)%ANG_VEL, 
     &            BD(7,MM), SEG(M)%LIN_DISP,
     &            SEG(M)%DIR_COS, BD(4,MM), SEG(M)%LIN_VEL, 
     &            SEG(M)%ANG_VEL,        
     &            VSCS(J), IFULL(J), TV2(1,I,J), FRB(1,I), TORQ,
     &            TQB(1,I),VOL(I), YFB(1,I) )                           
       IF  ( VOL(I) .EQ. D_0 )  CYCLE                                 
       VOLB = VOLB + VOL(I)                                               
       DO  K=1,3                                                          
        FORCE(K,J) = FORCE(K,J) + FRB(K,I)                                
        TORA (K,J) = TORA (K,J) + TORQ(K)                                 
       END DO
      END DO                                                              
      VOLBP(J) = VOLBP(J) + VOLB                                          
!C
      RETURN                                                              
      END                                                                 
