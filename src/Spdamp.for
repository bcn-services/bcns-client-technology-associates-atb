      SUBROUTINE SPDAMP                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the spring and viscous force of a spring damper between    
!C    specified points on selected segments and adds the resulting        
!C    force and torque to the U1 and U2 arrays.                          
!C                                                                        
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NSD,                            ! /CONTRL/
     &       APSDM, APSDN, ASD, MSDM, MSDN,  ! /DAMPER/
     &       DAMP_FORCE,                     ! /FORCES/
     &       NTI,                            ! /TABLES/
     &       SEG,                            ! structures
     &       INTEGER_STD, IREAL_HIGH,        ! parameters
     &       D_0, I_0, I_1, I_2, I_3         ! parameters
!C
!C    ANG_VEL,  DIR_COS, EXT_ANG_ACL, EXT_LIN_ACL,  ! SEG% 
!C    LIN_DISP, LIN_VEL                             ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &                I, JF1, JF2, JF3, JF4, M, N
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  DD, DD0, DEL, DELM, DELN, DMV, DUNIT, DV,
     &                  FD, FS, T1, T2_LCL, T3, T4, T5_LCL, T6, T7,
     &                  T8, TM1, TM2, TM3, TM4, TOTF
!C
      DIMENSION    DD(3), DELM(3), DELN(3), DUNIT(3), DV(3),
     &             T1(3), T2_LCL(3), T3(3), T4(3),                        
     &             T5_LCL(3), T6(3), T7(3), T8(3),                        
     &             TM1(3), TM2(3), TM3(3), TM4(3), TOTF(3)              
!C
      REAL  ( KIND = IREAL_HIGH )  EVALFD, VECMAG
      EXTERNAL                     EVALFD, VECMAG
!C
      CALL ELTIME ( I_1, 32_INTEGER_STD )                                              
!C
      DO 90 I=1,NSD                                                       
       M = MSDM(I)                                                       
       N = MSDN(I)                                                        
!C                                                                       
!C     Compute vector and its magnitude between the specified points.     
!C                                                                        
!C     Revise spring-damper location points for deformables bodies      
!C     also calculate the modal velocity terms                          
!C
       CALL FSPDMP ( I, M, N, TM1, TM2, TOTF, I_0 )                  
       CALL DOT31 ( SEG(M)%DIR_COS, APSDM(1,I), DELM )                   
       CALL DOT31 ( SEG(N)%DIR_COS, APSDN(1,I), DELN )                
       DD = SEG(M)%LIN_DISP + DELM - SEG(N)%LIN_DISP - DELN       
       DEL = VECMAG ( DD )
       IF  ( DEL .LE. D_0 )   CYCLE                                    
!C                                                                        
!C     Compute relative velocity and its component on vector line.       
!C                                                                        
       CALL CROSS ( SEG(M)%ANG_VEL, APSDM(1,I), T1 )                     
       CALL CROSS ( SEG(N)%ANG_VEL, APSDN(1,I), T2_LCL )              
       CALL DOT31 ( SEG(M)%DIR_COS, T1,     T3  )                        
       CALL DOT31 ( SEG(N)%DIR_COS, T2_LCL, T4  )                         
       CALL DOT31 ( SEG(M)%DIR_COS, TM1,    TM3 )                      
       CALL DOT31 ( SEG(N)%DIR_COS, TM2,    TM4 )                 
       DUNIT = DD / DEL
       DV = SEG(M)%LIN_VEL + T3 - SEG(N)%LIN_VEL - T4 + TM3 - TM4
       DMV = DOT_PRODUCT ( DUNIT, DV )
!C                                                                        
!C     Compute spring and viscous force and the components               
!C     along the unit vector                                              
!C                                                                        
       FS = D_0                                                    
       FD = D_0                                                      
       IF  ( ASD(1,I) .GE. D_0 )  THEN                                    
        DD0 = DEL - ASD(1,I)                                              
        IF  ( ( DD0 .LE. D_0 ) .AND. ( ASD(2,I) .LE. D_0 ) )  THEN  
         DAMP_FORCE(1,I) = DEL                                     
         DAMP_FORCE(2,I) = FD + FS
         DAMP_FORCE(3,I) = FS
         DAMP_FORCE(4,I) = FD                               
         CYCLE
        END IF
        FS = DD0 * ( ABS ( ASD(2,I) ) + ABS ( DD0 ) * ASD(3,I) )          
        FD = DMV * ( ASD(4,I) + ABS ( DMV ) * ASD(5,I) )                  
       ELSE
        DD0 = DEL + ASD(1,I)                                               
        JF1 = ASD(2,I)                                                     
        IF  ( JF1 .NE. I_0 )  THEN                                    
         JF2 = NTI(JF1)                                                    
         IF  ( ( DD0 .GT. D_0 ) .OR. ( ASD(3,I) .EQ. D_0 ) )  THEN
          FS = EVALFD ( DD0, JF2, I_1 )                             
         END IF
        END IF
        JF3 = ASD(4,I)                                                     
        IF  ( JF3 .NE. I_0 )  THEN                                   
         JF4 = NTI(JF3)                                                    
         IF  ( ( DD0 .GT. D_0 ) .OR. ( ASD(3,I) .EQ. D_0 ) )   THEN
          FD = EVALFD ( DMV, JF4, I_1 )                                  
         END IF
        END IF
       END IF
!C
       TOTF = ( FS + FD ) * DUNIT                  
!C                                                                       
!C     And add the resulting force and torque to the U1 and U2 arrays.    
!C                                                                      
       CALL MAT31 ( SEG(M)%DIR_COS, TOTF,   T5_LCL )                
       CALL MAT31 ( SEG(N)%DIR_COS, TOTF,   T6     )                    
       CALL CROSS ( APSDM(1,I),     T5_LCL, T7     )                 
       CALL CROSS ( APSDN(1,I),     T6,     T8     )                 
!C
       SEG(M)%EXT_LIN_ACL = SEG(M)%EXT_LIN_ACL - TOTF                  
       SEG(N)%EXT_LIN_ACL = SEG(N)%EXT_LIN_ACL + TOTF                
       SEG(M)%EXT_ANG_ACL = SEG(M)%EXT_ANG_ACL - T7                    
       SEG(N)%EXT_ANG_ACL = SEG(N)%EXT_ANG_ACL + T8                  
!C
!C     Calculate nodal forces if M and/or N are deformable.              
!C
       CALL FSPDMP ( I, M, N, TM1, TM2, TOTF, I_1 )                 
         DAMP_FORCE(1,I) = DEL                                     
         DAMP_FORCE(2,I) = FD + FS
         DAMP_FORCE(3,I) = FS
         DAMP_FORCE(4,I) = FD                               
   90 CONTINUE                                                           
!C
      CALL ELTIME ( I_2, 32_INTEGER_STD )                                              
!C
      RETURN                                                             
      END                                                                 
      