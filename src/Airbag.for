      SUBROUTINE  AIRBAG                                                
!C                                                   Rev. V.3 12/15/2002 
!C
!C    AIRBAG routine called by Subroutine CONTCT to determine the inter-  
!C    action of the bag with reaction panels and body segments by use of  
!C    Subroutine BGG. The differential pressure,force and torque on the   
!C    bag is evaluated and the resulting force and torque on the body    
!C    segments are added to the U1 and U2 arrays.                        
!C                                                                       
!C
      USE  MODULE_STANDARD, ONLY:  
     &       PREVT, IFULL, PD, CYMOUT, PYMOUT, BAGPV, ! /ABDATA/
     &       CYMIN, SWITCH, CYK, VBAG, VOLBP,  SPRK,  ! /ABDATA/
     &       CMASS, BFB, ZDEP,                        ! /ABDATA/
     &       CYPV, CYPA, CYORFC,                      ! /CYDATA/
     &       G, GRAVTY,                               ! /CNSNTS/
     &       BD,                                      ! /CNTSRF/
     &       NBAG, NVEH, NPRT, TIME,                  ! /CONTRL/
     &       NBGSF, NPANEL, BAGSF,                    ! /FORCES/
     &       MNBAG, MBAG,                             ! /JBARTZ/
     &       FRB, TQB, FORCE, TORA,                   ! /AIRBAG_TEMPVS/
     &       TORQ, FRA, VOLP, VOL,                    ! /AIRBAG_TEMPVS/
     &       TMP, TMP1, DELF,                         ! /AIRBAG_TEMPVS/
     &       SEG,                                     ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU,          ! parameters
     &       D_0, D_1, D_2, D_3, I_0, I_1, I_2, I_5   ! parameters
!C
!C    ANG_ACCEL, ANG_VEL,  DIR_COS,   EXT_ANG_ACL, EXT_LIN_ACL,  ! SEG%
!C    LIN_ACCEL, LIN_DISP, PHI,       RECIP_PHI,   WEIGHT        ! SEG%
!C
      USE  MODULE_FLEXIBLE,  ONLY: YFB                ! /FXFRC/
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, JB, K, KBAG, KBGSF, KP, M
!C
      REAL  ( KIND = IREAL_HIGH )  DELT, FMASS, TMASS, XDD
!C
      CALL ELTIME ( I_1, 24_INTEGER_STD )                                               
!C
      DELT = TIME - PREVT                                                 
      NBGSF = I_0                                                      
      DO  20  J=1,NBAG                                                   
       IF  ( MNBAG(J) .EQ. I_0 )  CYCLE                                
       IF  ( IFULL(J) .LE. I_0 )  THEN                                  
        NBGSF = NBGSF + I_5 + NPANEL(J) + MNBAG(J)                     
        CYCLE
       END IF
       CALL AIRBGG ( J )                                                  
!C                                                                        
!C     Compute  CMOUT: mass flow out of bag                               
!C              BAGPV: undistorted bag volume                             
!C                                                                        
       IF  ( PD(J) .GT. CYPV(J) )  THEN
        CYMOUT(J) = PYMOUT(J) + DELT * CYORFC(J) * SQRT ( PD(J) )         
       END IF
       BAGPV(J) = CYPA(J) * ( ( CYMIN(J) - CYMOUT(J) ) 
     &                        * SWITCH(J) )**CYK(J)                       
!C                                                                        
!C     Bag is fully inflated, compute differential pressure               
!C                                                                        
       PD(J) = BAGPV(J) / ( VBAG(J) - VOLBP(J) )**CYK(J) - CYPA(J)        
       JB = NVEH + J                                                      
       KP = NPANEL(J)                                                     
       KBAG = MNBAG(J)                                                   
!C                                                                        
!C     Optional diagnostic output.                                         
!C                                                                        
       IF  ( NPRT(21) .NE. I_0 )  THEN
        WRITE ( LUAOU, 100 ) ( ( FRB(I,K), I=1,3 ), 
     &                       ( TQB(I,K), I=1,3 ), K=1,KBAG ),
     &                       ( FORCE(I,J), I=1,3 ),  
     &                       ( TORA(I,J), I=1,3 ), TORQ,
     &                      ( ( FRA(I,K), I=1,3 ), VOLP(K,J), K=1,KP ),     
     &                       ( VOL(K), K=1,KBAG ), VOLBP(J), CYMOUT(J),
     &                        BAGPV(J), PD(J)            
  100   FORMAT ( '0Airbag Contact', /, ( 1X, 9G14.6 ) )                            
       END IF
       IF  ( PD(J) .LT. D_0 )  THEN
        PD(J) = D_0                                  
       ELSE IF  ( PD(J) .EQ. D_0 ) THEN
        EXIT                                      
       END IF
!C                                                                       
!C     Set up BAGSF array for output routine                              
!C                                                                        
       KBGSF = NBGSF + I_5                                             
       DO  K=1,KP                                                         
        KBGSF = KBGSF + I_1                                           
        DO  I=1,3                                                         
         BAGSF(I,KBGSF) = PD(J) * FRA(I,K)                               
        END DO
       END DO
       DO  I=1,KBAG                                                      
        KBGSF = KBGSF + I_1                                             
        IF  ( VOL(I) .EQ. D_0 )  CYCLE                              
        M = MBAG(2,I,J)                                                   
!C                                                                        
!C      Final computations of force and torque on airbag                  
!C                                                                        
        DO  K=1,3                                                         
         FRB(K,I) = PD(J) * FRB(K,I)                                      
         BAGSF(K,KBGSF) = FRB(K,I)                                        
         SEG(M)%EXT_LIN_ACL(K) = SEG(M)%EXT_LIN_ACL(K) - FRB(K,I)       
         SEG(M)%EXT_ANG_ACL(K) = SEG(M)%EXT_ANG_ACL(K) 
     &                                   + PD(J) * TQB(K,I)     
        END DO
!C
!C      Add FRB to nodal forces for deformable body M.                   
!C
        CALL FXCAHW ( M, YFB(1,I), FRB(1,I), -D_1 )                     
       END DO                                                           
!C
       DO  K=1,3                                                         
        FORCE(K,J) = PD(J) * FORCE(K,J)                                   
        TORA (K,J) = PD(J) * TORA (K,J)                                  
       END DO
!C
       IF  ( VOLP(1,J) .EQ. D_0 )  THEN                             
!C                                                                       
!C      Airbag is not intersecting primary reaction panel.                 
!C      Compute artificial force and torque with a linear spring 
!C      function in an attempt to tie +X semiaxis endpoint of airbag 
!C      to deployment point on reaction panel.                            
!C                                                                       
        DO  K=1,3                                                        
         TMP(K) = BFB(K,1,J) + ZDEP(K,J)                                  
        END DO
        CALL DOT31 ( SEG(NVEH)%DIR_COS, TMP, TMP1 )                        
        DELF = TMP1 + SEG(NVEH)%LIN_DISP - SEG(JB)%LIN_DISP         
        DO  K=1,3                                                        
         TMP(K) = BD(K+3,JB)                                              
        END DO
        TMP(1) = TMP(1) + BD(1,JB)                                       
        CALL DOT31 ( SEG(JB)%DIR_COS, TMP, TMP1 )                     
        DO  K=1,3                                                         
         DELF(K) = SPRK(J) * ( DELF(K) - TMP1(K) )                       
         BAGSF(K,NBGSF+I_5) = DELF(K)                                       
         FORCE(K,J) = FORCE(K,J) + DELF(K)                               
        END DO
        CALL MAT31 ( SEG(JB)%DIR_COS, DELF, TMP1 )                       
        CALL CROSS ( TMP, TMP1, DELF )                                  
        DO  K=1,3                                                        
         TORA(K,J) = TORA(K,J) + DELF(K)                                
        END DO
       END IF
!C
       XDD = CYMIN(J) - CYMOUT(J) + SEG(JB)%WEIGHT                     
       FMASS = CMASS(J) * XDD / G                                         
       TMASS = CMASS(J) * ( XDD + SEG(JB)%WEIGHT * D_2 / D_3 ) / G       
       DO I=1,3
        TMP(I) = SEG(JB)%ANG_VEL(I) * SEG(JB)%PHI(I)                       
       END DO
       CALL CROSS ( SEG(JB)%ANG_VEL, TMP, TMP1 )                
       DO  I=1,3                                                         
        SEG(JB)%LIN_ACCEL(I) = FORCE(I,J) / FMASS + GRAVTY(I)              
        SEG(JB)%ANG_ACCEL(I) = ( TORA(I,J) / TMASS - TMP1(I) )
     &                          * SEG(JB)%RECIP_PHI(I)     
       END DO
       NBGSF = NBGSF + I_5 + NPANEL(J) + MNBAG(J)                      
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, 24_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                
