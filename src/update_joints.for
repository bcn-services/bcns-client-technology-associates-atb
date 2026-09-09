      SUBROUTINE UPDATE_JOINTS ( I )
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C    This subroutine was created from the part of Subroutine UPDATE
!C     in version V.1 that pertained to updating the joints.
!C
!C                                                                      
!C    Check for impulse on joint stops                             
!C     to be called if in joint stop ( JSTOP(1) = 1 ) this time step         
!C     but not in in joint stop ( JSTOP(2) = 0 ) at previous time.            
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:  
     &       HIR, IEULER,                                    ! /CEULER/
     &       WJ,                                             ! /CMATRX/
     &       NJNT, TIME,                                     ! /CONTRL/
     &       HT, IGLOB, VISC,                                ! /DESCRP/
     &       NTAB, TAB,                                      ! /TABLES/
     &       JSTOP,                                          ! /TEMPVI/
     &       SEG, JNT,                                       ! structures
     &       INTEGER_STD, IREAL_HIGH, LUAOU, D_0, D_1000,    ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_7          ! parameters 
!C
!C    DIR_COS                                 ! SEG%
!C    COMP_MAX, JFORCE, JTORQUE,              ! JNT%
!C    PROX_SEG, TENS_MAX, JTYPE,              ! JNT%
!C    PROX_HA, DSTL_HA, PROX_HB, DSTL_HB      ! JNT%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &      I, IPINJ, J, K, K3J, M, MT, NT, NT1
!C
      REAL  ( KIND = IREAL_HIGH )
     &       ABSTQM, FTEST, T1, T2_LCL, T3, TMSEC, TQM
!C
      REAL  ( KIND = IREAL_HIGH )  VECMAG, XDY
      EXTERNAL          VECMAG, XDY
!C
      INTENT ( OUT )  I
!C
      DO  K=1,NJNT                                                        
       IF ( JNT(K)%PROX_SEG .NE. I_0 )  THEN                                  
        IF ( ( ABS ( JNT(K)%JTYPE ) .EQ. I_4 ) .OR. 
     &       ( VISC(7,3*K-2) .NE. D_0 ) )  THEN                     
         DO  J=1,3                                                        
          K3J = I_3 * K - I_3 + J                                 
          IF ( ABS ( JNT(K)%JTYPE ) .NE. I_4 )  
     &          K3J = I_3 * K - I_2             
          IF ( ( ABS ( JNT(K)%JTYPE ) .NE. I_4 ) .OR. 
     &              ( VISC(7,K3J) .NE. D_0 ) )  THEN                   
           IF ( ( JSTOP(J,1,K) .EQ. I_1 ) .AND. 
     &          ( JSTOP(J,2,K) .EQ. I_0 ) )  THEN                      
            CALL IMPULS ( I_4, J, K )                                  
            I = -I_1                                                    
           END IF
          END IF
          JSTOP(J,2,K) = JSTOP(J,1,K)                                     
         END DO
        END IF
        IF ( IGLOB(K) .NE. I_0 )  THEN                                  
         NT = IGLOB(K)                                                   
         MT = NTAB(NT+5)                                                 
         NT1 = NTAB(NT+2)                                                
         NTAB(NT+2) = I_0                                             
         CALL UPDATE_FRC_DEF_CURVE ( NT )                                               
         NT = ABS ( NT )                                                  
         NTAB(NT+2) = NT1                                                 
         IF ( TAB(MT+3) .NE. D_0 )  THEN                                
          IF ( ( JSTOP(4,1,K) .EQ. I_1 ) .AND. 
     &         ( JSTOP(4,2,K) .EQ. I_0 ) )  THEN                      
           CALL IMPULS ( I_4, I_4, K )                            
           I = -I_1                                                  
          END IF
         END IF
        END IF
       END IF
       JSTOP(4,2,K) = JSTOP(4,1,K)                                        
      END DO
!C                                                                        
!C    Test to lock or unlock joints                                       
!C                                                                        
!C                                                                        
!C    Conditions to change sign of JTYPE(J)                            
!C                                                                        
!C                  pinned             unpinned                           
!C        locked (-1) !H.TQ! > T1    (-2) !TQ! > T1                       
!C                                                                        
!C     unlocked  (+1) !H.TQ! < T2    (+2) !TQ! < T2                       
!C                          OR                OR                          
!C                       WJ  < T3          WJ  < T3                       
!C                                                                        
      DO 20 J=1,NJNT                                                      
       IF ( ABS ( JNT(J)%JTYPE ) .EQ. I_4 )  CYCLE                               
!C
       IF ( JNT(J)%JTYPE .LT. I_0 )  THEN
        T1 = VISC(4,3*J-2)                                              
        IF ( T1 .EQ. D_0 )  CYCLE                                         
!C
        IF ( ( JNT(J)%JTYPE .GT. -I_1 )  .OR.                                      
     &     ( ( JNT(J)%JTYPE .GT. -I_6 )    .AND. 
     &       ( JNT(J)%JTYPE .LT. -I_1 ) ) )   THEN                
         TQM = VECMAG ( JNT(J)%JTORQUE )
         IF  ( TQM .GT. T1 )  THEN
          CALL DOT31 ( HIR(1,1,J), JNT(J)%JTORQUE, JNT(J)%PROX_HA ) 
         END IF        
        ELSE
         TQM = XDY ( JNT(J)%DSTL_HB, SEG(J+1)%DIR_COS, JNT(J)%JTORQUE )                           
         ABSTQM = ABS ( TQM )                                                 
         IF  ( ABSTQM .GT. T1 )   JNT(J)%PROX_HA(2) = TQM                         
         TQM = ABSTQM                                                    
        END IF                                                           
!C
        IF ( ( TQM - T1 ) .GT. D_0 )  THEN
         JNT(J)%JTYPE = -JNT(J)%JTYPE                                             
         TMSEC = D_1000 * TIME                                            
         IPINJ = -JNT(J)%JTYPE                                                 
         WRITE ( LUAOU, 100 )  TMSEC, J, IPINJ, JNT(J)%JTYPE                            
  100    FORMAT ( '0 At time =', F9.3, ' msec,   JTYPE(', I2,              
     &            ') has been changed from', I3, ' to', I3 )           
        END IF
!C
       ELSE IF ( JNT(J)%JTYPE .GT. I_0 )  THEN
        T2_LCL = VISC(5,3*J-2)                                             
        IF  ( JNT(J)%DSTL_HA(2) .EQ. D_0 )  THEN                                 
         JNT(J)%PROX_HA = D_0
        END IF
!C
        IF  ( T2_LCL .NE. D_0 )   THEN                                      
         IF ( ( JNT(J)%JTYPE .GE. I_2 ) .AND. 
     &        ( JNT(J)%JTYPE .LE. I_5 ) )                      
     &          TQM = VECMAG ( JNT(J)%JTORQUE )
         IF ( ( JNT(J)%JTYPE .EQ. I_1 ) .OR. 
     &        ( JNT(J)%JTYPE .EQ. I_6 )     .OR.
     &        ( JNT(J)%JTYPE .EQ. I_7 ) )                  
     &    TQM = ABS ( 
     &      XDY ( JNT(J)%DSTL_HB, SEG(J+1)%DIR_COS, JNT(J)%JTORQUE  ) )            
         IF ( ( TQM - T2_LCL ) .LT. D_0 )  THEN
          CALL IMPLS2 ( I_0, J, JNT(J)%DSTL_HB )                                   
          I = -I_1                                                         
          JNT(J)%JTYPE = -JNT(J)%JTYPE                                             
          TMSEC = D_1000 * TIME                                            
          IPINJ = -JNT(J)%JTYPE                                                 
          WRITE ( LUAOU, 103 )  TMSEC, J, IPINJ, JNT(J)%JTYPE                            
  103     FORMAT ( '0 At time =', F9.3, ' msec,   JTYPE(', I2,              
     &             ') has been changed from', I3, ' to', I3 )           
         END IF
         CYCLE
        END IF
!C
        T3 = VISC(6,3*J-2)                                                 
        IF ( ( T3 .EQ. D_0 )  .OR.                                          
     &       ( ( WJ(J) - T3 ) .GE. D_0 ) ) THEN
         CYCLE
        END IF       
!C
        CALL IMPLS2 ( I_0, J, JNT(J)%DSTL_HB )                                   
        I = -I_1                                                         
        JNT(J)%JTYPE = -JNT(J)%JTYPE                                             
        TMSEC = D_1000 * TIME                                            
        IPINJ = -JNT(J)%JTYPE                                                 
!C
!C      i.e. JTYPE(J) = 0.
!C
        WRITE ( LUAOU, 105 )  TMSEC, J, IPINJ, JNT(J)%JTYPE                            
  105   FORMAT ( '0 At time =', F9.3, ' msec,   JTYPE(', I2,              
     &           ') has been changed from', I3, ' to', I3 )           
       END IF    
   20 CONTINUE                                                            
!C                                                                       
!C    Test to lock or unlock Euler joints axes.                           
!C    Use same test as above but on each axis serarately.                 
!C                                                                        
      CALL UPDATE_EULER_JOINTS ( I )
!C
!C    Check if locked slip joints will release.
!C
      DO  J = 1,NJNT                                                        
       IF ( ABS ( JNT(J)%JTYPE ) .LE. I_4 )  CYCLE                              
       IF ( IEULER(J) .GE. I_0 )  CYCLE                                 
       IF ( ( JNT(J)%TENS_MAX .EQ. D_0 ) .AND. 
     &      ( JNT(J)%COMP_MAX .EQ. D_0 ) ) CYCLE            
       M = JNT(J)%PROX_SEG                                              
       FTEST = XDY ( HT(1,3,2*J-1), SEG(M)%DIR_COS, JNT(J)%JFORCE )             
       IF ( ( FTEST .GE. JNT(J)%TENS_MAX ) .AND. 
     &      ( FTEST .LE. JNT(J)%COMP_MAX ) ) CYCLE          
       IEULER(J) = I_0                                                   
       I = -I_1                                                         
       TMSEC = D_1000 * TIME                                    
       WRITE ( LUAOU, 115 )  TMSEC, J                                      
  115  FORMAT ( /, '0 At time =', F9.3, ' msec,  Joint ', I3,
     &          ' has been unlocked and allowed to slip.', / )              
      END DO                                                                
!C
      RETURN
      END