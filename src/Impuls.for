      SUBROUTINE IMPULS ( I1, I2, I3 )                                    
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C        Arguments: I1 = 1 - IMPULS for PLELP.                           
!C                        3 - IMPULS for SEGSEG.                          
!C                        4 - IMPULS for VISPR or EJOINT                  
!C                   I2 = index of contacting segment or joint axis       
!C                   I3 = index of plane, segment or joint axis           
!C                                                                        
!C                                                                        
      USE  MODULE_STANDARD, ONLY: 
     &        V1, V2, V3,                              ! /CMATRX/
     &        NGRND, NQ, TIME, NJNT, NFLX, NSEG, NPRT, ! /CONTRL/
     &        KQ1, KQ2, KQTYPE, A13, A23, QQ,          ! /CSTRNT/
     &        V4,                                      ! /FLXBLE/
     &        MSEG, MPL, NTPL, NTSEG,                  ! /JBARTZ/
     &        NTAB,                                    ! /TABLES/
     &        R1I, R2I, TTI, CREST,                    ! /TEMPVI/
     &        SEG, JNT,                                ! structures
     &        INTEGER_STD, IREAL_HIGH, LUAOU,          ! parameters 
     &        I_0, I_1, I_2, I_3, I_4, D_0, D_2        ! parameters
!C
!C    ANG_ACCEL, ANG_VEL, DIR_COS,    EXT_ANG_ACL, EXT_LIN_ACL,   ! SEG%
!C    LIN_ACCEL, LIN_VEL, RECIP_MASS, RECIP_PHI                   ! SEG%
!C    PROX_SEG, JTYPE                                             ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &       I, I1, I2, I3, J, K1, K2, KQ, KQTEST, M1, M2, M3, NT
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  TEMP, DWR1, DWR2, DWR3, DWR4, VREL, DV,
     &                  TDV, TVREL, ALPHA
      DIMENSION         TEMP(3), DWR1(3), DWR2(3), DWR3(3), DWR4(3),
     &                  VREL(3), DV(3)                                    
!C
      INTENT ( IN )  I1, I2, I3
!C
!C
      IF  ( TIME .EQ. D_0 )  THEN
       RETURN
      END IF
!C                                                                        
!C    special setup for call to Subroutine DAUX                           
!C    Replace setup with U1,U2,V1,V2,V3 = 0.                              
!C    Assume other arrays from previous call to DAUX.                     
!C                                                                        
      CALL ELTIME ( I_1, 27_INTEGER_STD )                                               
!C
      CALL OUTPUT ( I_0 )                                              
!C
      KQTEST = I_0                                                     
      NT = I_0                                                         
      IF ( I1 .EQ. I_1 )  THEN 
       NT = NTPL (I2,I3)                                                  
      ELSE IF ( I1 .EQ. 3 )  THEN 
       NT = NTSEG(I2,I3)                                                  
      END IF
      IF ( NT .NE. I_0 )  THEN                                          
       KQ = -NTAB(NT+1)                                                   
      END IF
      IF ( KQ .GT. I_0 )  THEN                                       
       KQTYPE(KQ) = ABS ( KQTYPE(KQ) )                                    
       CALL DAUX ( I_0 )                                              
      END IF
!C
      IF ( NQ .GT. I_0 )  THEN                                       
       V3 = D_0                                 
      END IF
!C
      DO I=1,NGRND
       SEG(I)%EXT_LIN_ACL = D_0                                                
       SEG(I)%EXT_ANG_ACL = D_0
      END DO
!C
      IF ( NJNT .GT. I_0 )  THEN                                       
       V1 = D_0                                         
       V2 = D_0                                        
      END IF
!C
      IF ( NFLX .NE. I_0 )  THEN                                       
       V4 = D_0                                      
      END IF
!C                                                                        
!C    Replace calls to CONTACT and VISPR with single call                 
!C    at first contact if not constraint.                                 
!C                                                                        
      IF ( I1 .EQ. I_1 )  THEN                                          
       NT = NTPL(I2,I3)                                                   
       M1 = MPL(1,I2,I3)                                                  
       M2 = MPL(2,I2,I3)                                                  
       M3 = ABS ( MPL(3,I2,I3) )                                          
       CALL PLELP ( M2, M3, M1, I3, NT )                                  
       IF ( NTAB(NT+1) .LT. I_0 )  THEN
!C                                                                        
!C      Set up special U1, U2 for first contact of constraint.               
!C                                                                        
        KQ = -NTAB(NT+1)                                                    
        KQTEST = I_1                                                    
        KQTYPE(KQ) = -ABS ( KQTYPE(KQ) )                                    
        K1 = KQ1(KQ)                                                        
        K2 = KQ2(KQ)                                                        
        IF ( K1 .LE. NSEG )  THEN                                           
         CALL MAT31 ( A13(1,1,2*KQ-1), QQ(1,KQ), SEG(K1)%EXT_LIN_ACL )      
         CALL MAT31 ( A23(1,1,2*KQ-1), QQ(1,KQ), SEG(K1)%EXT_ANG_ACL )   
        END IF
        IF ( K2 .LE. NSEG )  THEN                                           
         CALL MAT31 ( A13(1,1,2*KQ  ), QQ(1,KQ), SEG(K2)%EXT_LIN_ACL )     
         CALL MAT31 ( A23(1,1,2*KQ  ), QQ(1,KQ), SEG(K2)%EXT_ANG_ACL )     
        END IF
       ELSE
        K1 = M2                                                            
        K2 = M1                                                            
       END IF
      ELSE IF ( I1 .EQ. I_3 )  THEN                                              
       NT = NTSEG(I2,I3)                                                  
       M1 = MSEG(1,I2,I3)                                                 
       M2 = MSEG(2,I2,I3)                                                 
       M3 = MSEG(3,I2,I3)                                                 
       CALL SEGSEG ( I3, M1, M2, M3, NT )                                 
       IF ( NTAB(NT+1) .LT. I_0 )  THEN
!C                                                                        
!C      Set up special U1, U2 for first contact of constraint.               
!C                                                                        
        KQ = -NTAB(NT+1)                                                    
        KQTEST = I_1                                                    
        KQTYPE(KQ) = -ABS ( KQTYPE(KQ) )                                    
        K1 = KQ1(KQ)                                                        
        K2 = KQ2(KQ)                                                        
        IF ( K1 .LE. NSEG )  THEN                                           
         CALL MAT31 ( A13(1,1,2*KQ-1), QQ(1,KQ), SEG(K1)%EXT_LIN_ACL )      
         CALL MAT31 ( A23(1,1,2*KQ-1), QQ(1,KQ), SEG(K1)%EXT_ANG_ACL )   
        END IF
        IF ( K2 .LE. NSEG )  THEN                                           
         CALL MAT31 ( A13(1,1,2*KQ  ), QQ(1,KQ), SEG(K2)%EXT_LIN_ACL )     
         CALL MAT31 ( A23(1,1,2*KQ  ), QQ(1,KQ), SEG(K2)%EXT_ANG_ACL )     
        END IF
       ELSE
        K1 = I3                                                            
        K2 = M2                                                            
       END IF
      ELSE IF ( I1 .EQ. I_4 )  THEN
!C                                                                        
!C     Recall VISPR for joint stop.                                        
!C                                                                        
       IF ( ABS ( JNT(I3)%JTYPE ) .NE. I_4 )  THEN                            
        CALL VISPR ( I2, I3 )                                              
        K1 = ABS ( JNT(I3)%PROX_SEG )                                      
       ELSE
        CALL EJOINT ( I2, I3 )                                             
        K1 = ABS ( JNT(I3)%PROX_SEG )                                     
       END IF
       K2 = I3 + I_1                                                      
      ELSE 
       WRITE ( LUAOU, 100 )  I1, I2, I3                                    
  100  FORMAT ( '0 Improper arguments to Subroutine IMPULS', /,           
     &          '  Arguments = ', 3I6, /,                                 
     &          '  Program terminated' )                                  
       STOP 33                                                            
      END IF 
!C                                                                        
!C    Final setup of external linear and angular accelerations.    
!C                                                                        
      DO  J=1,NGRND                                                       
       SEG(J)%EXT_LIN_ACL = SEG(J)%EXT_LIN_ACL * SEG(J)%RECIP_MASS                    
       SEG(J)%EXT_ANG_ACL = SEG(J)%EXT_ANG_ACL * SEG(J)%RECIP_PHI      
      END DO
      CALL DAUX ( I1 )                                                    
      IF ( KQTEST .EQ. I_1 )    KQTYPE(KQ) = ABS ( KQTYPE(KQ) )        
      IF ( NPRT(10) .NE. I_0 )  CALL PRINT ( 'PREIMP' )                
      IF ( I1 .GT. I_3 )  THEN                                        
       CALL DOT31 ( SEG(K1)%DIR_COS, SEG(K1)%ANG_VEL,   DWR1 )             
       CALL DOT31 ( SEG(K2)%DIR_COS, SEG(K2)%ANG_VEL,   DWR2 )              
       CALL DOT31 ( SEG(K1)%DIR_COS, SEG(K1)%ANG_ACCEL, DWR3 )               
       CALL DOT31 ( SEG(K2)%DIR_COS, SEG(K2)%ANG_ACCEL, DWR4 )             
       VREL = DWR1 - DWR2                                
       DV   = DWR3 - DWR4                            
       TVREL = DOT_PRODUCT ( TTI, VREL )        
       TDV   = DOT_PRODUCT ( TTI, DV   )                 
      ELSE
       IF ( NPRT(10) .NE. I_0 )  WRITE ( LUAOU, 110 )  R1I, R2I        
  110  FORMAT ( '0', /, ( 6G20.8 ) )                                      
       CALL CROSS ( SEG(K1)%ANG_VEL,   R1I(1), TEMP    )                 
       CALL DOT31 ( SEG(K1)%DIR_COS,   TEMP,   DWR1 )              
       CALL CROSS ( SEG(K2)%ANG_VEL,   R2I(1), TEMP    )               
       CALL DOT31 ( SEG(K2)%DIR_COS,   TEMP,   DWR2 )                
       CALL CROSS ( SEG(K1)%ANG_ACCEL, R1I(1), TEMP    )               
       CALL DOT31 ( SEG(K1)%DIR_COS,   TEMP,   DWR3 )              
       CALL CROSS ( SEG(K2)%ANG_ACCEL, R2I(1), TEMP    )              
       CALL DOT31 ( SEG(K2)%DIR_COS,   TEMP,   DWR4 )                
       VREL =   SEG(K1)%LIN_VEL   + DWR1 - SEG(K2)%LIN_VEL   - DWR2    
       DV   =   SEG(K1)%LIN_ACCEL + DWR3 - SEG(K2)%LIN_ACCEL - DWR4   
       TVREL   = DOT_PRODUCT ( TTI, VREL )         
       TDV     = DOT_PRODUCT ( TTI, DV )                     
      END IF
      ALPHA = D_0                                                       
!C                                                                        
!C    Note: CREST is supplied as (1+E)/2 where E is the classical         
!C    coefficient of restitution but with a range of -1 to +1.            
!C    CREST has a range of 0 to +1 where 0 (E=-1) represents no impulse.  
!C                                                                        
      IF ( TDV .NE. D_0 ) ALPHA = -D_2 * CREST * TVREL / TDV          
      IF ( NPRT(10) .NE. I_0 )  THEN 
       WRITE ( LUAOU, 110 )  DWR1, DWR2, DWR3, DWR4,  TTI, VREL, DV,       
     &                  TVREL, TDV, CREST, ALPHA                          
      END IF
      DO  J=1,NGRND                                                       
       SEG(J)%LIN_VEL = SEG(J)%LIN_VEL + ALPHA * SEG(J)%LIN_ACCEL    
       SEG(J)%ANG_VEL = SEG(J)%ANG_VEL + ALPHA * SEG(J)%ANG_ACCEL        
      END DO
      IF  ( NPRT(10) .NE. I_0 )  CALL OUTPUT ( I_1 )                    
      IF  ( NPRT( 3) .NE. I_0 )  CALL PRINT ( 'IMPULS' )              
!C
      CALL ELTIME ( I_2, 27_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
