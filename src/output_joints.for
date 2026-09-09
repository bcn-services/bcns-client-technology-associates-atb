      SUBROUTINE OUTPUT_JOINTS ( IDYPR, IDYPRT, SLIP,
     &                           YPR1, YPR2, YPR3 )
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine echoes the output related to the joint input
!C     parameters.
!C
      USE  MODULE_STANDARD, ONLY:
     &        ANG, ANGD, IEULER,                           ! /CEULER/
     &        RADIAN, UNITL, UNITM, UNITT,                 ! /CNSNTS/
     &        NJNT, NPG,  NPRT,                            ! /CONTRL/
     &        HT, SPRING, VISC,                            ! /DESCRP/  
     &        JNT,                                         ! structures
     &        INTEGER_STD, IREAL_HIGH, LOGICAL_STD,        ! parameters
     &        LUAOU, MAXJNT,                               ! parameters
     &        I_0, I_1, I_2, I_3, I_4, I_5, I_8, I_11, D_0 ! parameters 
!C
!C    CNTR_SYM, COMP_MAX, EULER, JNT_NAME, PROX_SEG, TENS_MAX,   ! JNT%
!C    DSTL_LOC, PROX_LOC, DSTL_CNST, PROX_CNST, JTYPE,           ! JNT%
!C    PROX_HA, DSTL_HA, PROX_HB, DSTL_HB                         ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:   IBODN, NFBOD, NODJ   ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER    ( KIND = INTEGER_STD ) 
     &           I, IDFEA, IDYPR, IDYPRT, IX, J, J1, J2, J3, JJ, K
      DIMENSION  IDYPR(6,MAXJNT)
!C
      REAL  ( KIND = IREAL_HIGH )  TMP1, TMP2, YPR1, YPR2, YPR3
      DIMENSION         TMP1(3,3), TMP2(3,3), YPR1(3,MAXJNT),
     &                  YPR2(3,MAXJNT), YPR3(3,MAXJNT)
!C
      LOGICAL    ( KIND = LOGICAL_STD )  SLIP                                             
!C
      INTENT  ( IN )  IDYPR, IDYPRT, SLIP, 
     &                YPR1, YPR2, YPR3
!C                                                                        
!C    Print Cards  B.3  for each joint.                                   
!C                                                                        
      IF ( IDYPRT .EQ. I_0 )  THEN
       WRITE ( LUAOU, 100 )  UNITL, UNITL                           
  100  FORMAT ( ///, 120X, 'Cards B.3', /,                                   
     &          3X, 'Joint', 15X, 'Location(', A4, ') - Seg(JNT)',       
     &          3X, 'Location(', A4, ') - SEG(J+1)',                      
     &          2X, 'Joint Axis(deg) - SEG(JNT)',                    
     &          2X, 'Joint Axis(deg) - SEG(J+1)', /,                     
     &          '  J SYM      JNT PIN',  
     &          2( 6X, 'X', 8X, 'Y', 8X, 'Z', 3X ),                
     &          2( 5X, 'Yaw', 5X, 'Pitch', 5X, 'Roll', 1X ), / )       
      ELSE IF ( IDYPRT .EQ. I_1 )   THEN
       WRITE ( LUAOU, 105 )  UNITL, UNITL                          
  105  FORMAT ( ///, 120X, 'Cards B.3', /,                                        
     &          3X, 'Joint', 15X, 'Location(', A4, ') - Seg(JNT)',                     
     &          3X, 'Location(', A4, ') - Seg(J+1)',                    
     &          2X, 'Joint Axis(deg) - Seg(JNT)',                   
     &          2X, 'Joint Axis(deg) - Seg(J+1)', /,                    
     &          '  J SYM      JNT PIN', 
     &          2( 6X, 'X', 8X, 'Y', 8X, 'Z', 3X ),               
     &          'ID1  Yaw ID2 Pitch ID3 Roll ',                        
     &          'ID4  Yaw ID5 Pitch ID6 Roll ', / )                     
      END IF
!C
      DO  J=1,NJNT                                                    
       IF ( IDYPRT .EQ. I_0 )  THEN                                                     

        WRITE ( LUAOU, 110 )  J, JNT(J)%JNT_NAME, 
     &                       JNT(J)%PROX_SEG, JNT(J)%JTYPE,
     &                       ( JNT(J)%PROX_LOC(I), I=1,3 ),   
     &                       ( JNT(J)%DSTL_LOC(I), I=1,3 ),
     &                       ( YPR1(I,J), I=1,3 ),
     &                       ( YPR2(I,J), I=1,3 )  
  110   FORMAT ( I3, 1X, A4, 5X, 2I3, 2( 1X, 3F9.3 ),
     &           2( 1X, 3F9.2 ) )              
       ELSE IF ( IDYPRT .EQ. I_1 )  THEN                                                    
        WRITE ( LUAOU, 115 )  J, JNT(J)%JNT_NAME, 
     &                        JNT(J)%PROX_SEG, JNT(J)%JTYPE,
     &                        ( JNT(J)%PROX_LOC(I), I=1,3 ), 
     &                        ( JNT(J)%DSTL_LOC(I), I=1,3 ),
     &                        ( IDYPR(I,J), YPR1(I,J), I=1,3 ),  
     &                        ( IDYPR(I+3,J), YPR2(I,J), I=1,3 )                        
  115   FORMAT ( I3, 1X, A4, 5X, 2I3, 2( 1X, 3F9.3 ),
     &           2( 1X, 3( 1X, I1, F7.2 ) ) )      
       END IF
       IDFEA = I_0
       DO  I=1,NFBOD
        IF ( IBODN(I) .EQ. JNT(J)%PROX_SEG )  THEN
         IDFEA = I_1
        END IF
        IF ( IBODN(I) .EQ. ( J + I_1 ) )  THEN
         IDFEA = IDFEA + I_2
        END IF
       END DO
       IF ( IDFEA .GT. I_0 )  THEN
        IF ( IDFEA .EQ. I_1 )  THEN
         WRITE ( LUAOU, 120 )  J, JNT(J)%PROX_SEG, ( J + I_1 )
  120    FORMAT ( 10X, 'Joint', I3, ' connects deformable segment',
     &          I3, ' with segment', I3 )
         WRITE ( LUAOU, 125 )  J, JNT(J)%PROX_SEG, NODJ(1,1,J), 
     &                         ( NODJ(IX,1,J), IX=2,3 )
  125    FORMAT ( 10X, 'Node number of the center of joint', I3,
     &            ' on deformable segment', I3, ':', 1X, I6, /,
     &            10X, 'Node numbers of the two adjacent points:',
     &            2( 3X, I6 ) )
        ELSE IF ( IDFEA .EQ. I_2 )  THEN
         WRITE ( LUAOU, 130 )  J, JNT(J)%PROX_SEG, ( J + I_1 )
  130    FORMAT ( 10X, 'Joint', I3, ' connects segment', I3,
     &            ' with deformable segment', I3 )
         WRITE ( LUAOU, 125 )  J, ( J + I_1 ), NODJ(1,2,J),
     &                         ( NODJ(IX,2,J), IX=2,3 )
        ELSE 
         WRITE ( LUAOU, 135 )  J, JNT(J)%PROX_SEG, ( J + I_1 )
  135    FORMAT ( 10X, 'Joint', I3, ' connects deformable segment',
     &            I3, ' with deformable segment', I3 )
         WRITE ( LUAOU, 125 )  J, JNT(J)%PROX_SEG, NODJ(1,1,J),
     &                         ( NODJ(IX,1,J), IX=2,3 )
         WRITE ( LUAOU, 125 )  J, ( J + I_1 ), NODJ(1,2,J), 
     &                         ( NODJ(IX,2,J), IX=2,3 )
        END IF
       END IF
       IF ( .NOT. JNT(J)%EULER )  CYCLE                                           
       IEULER(J) = I_8                                                     
       IF ( JNT(J)%JTYPE .EQ. I_4 )  CYCLE                                       
       IEULER(J) = I_11 + JNT(J)%JTYPE                                           
       JNT(J)%JTYPE = -I_4                                                      
      END DO                                                   
      IF ( SLIP )   THEN                                            
       WRITE ( LUAOU, 140 ) UNITM, UNITM                                       
  140  FORMAT ( //, '  Unlock Conditions for Slip Joints', /,              
     &          '    Joint    Tension    Compression', /,               
     &          14X, '(', A4, ')', 7X, '(', A4, ')', / )                     
       DO  J = 1,NJNT                                                     
        IF  ( JNT(J)%EULER )  CYCLE                                            
        IF  ( ABS ( JNT(J)%JTYPE ) .LT. I_5 )  CYCLE                             
        WRITE ( LUAOU, 145 )  J, JNT(J)%TENS_MAX, JNT(J)%COMP_MAX                    
  145   FORMAT ( 1X, I6, 4X, F10.3, 3X, F10.3 )                             
       END DO                                                       
      END IF
!C                                                                      
!C    Set up HT matrix from YPR1 & YPR2 input.                      
!C    HA is 3rd column & HB is 2nd column of HT.                        
!C    for a slip joint(JTYPE=7),HB is 3rd column of HT.                     
!C                                                                    
      IF  ( NPRT(23) .NE. I_0 )  THEN
       WRITE ( LUAOU, 150 ) NPG                       
  150  FORMAT ( '1 HT array as computed from YPR1 & YPR2 input.',
     &          77X, 'Page', I5 )                                            
       NPG = NPG + I_1                               
      END IF
      DO  J=1,NJNT                                                  
       JNT(J)%PROX_CNST = D_0
       JNT(J)%DSTL_CNST = D_0
       CALL DRCYPR ( TMP1, YPR1(1,J), IDYPR(1,J) )                       
       CALL DRCYPR ( TMP2, YPR2(1,J), IDYPR(4,J) )                       
       DO  I=1,3                                                        
        ANGD(I,J) = D_0                                                 
        JNT(J)%PROX_HA(I) = D_0                                               
        JNT(J)%DSTL_HA(I) = D_0
        K = I_2                                                             
        IF ( ABS ( JNT(J)%JTYPE ) .EQ. 7 )   K = I_3                             
        JNT(J)%PROX_HB(I) = TMP1(K,I)                                          
        JNT(J)%DSTL_HB(I) = TMP2(K,I)                                             
        DO  K=1,3                                                          
         HT(I,K,2*J-1) = TMP1(K,I)                                       
         HT(I,K,2*J  ) = TMP2(K,I)                                      
        END DO
        IF ( JNT(J)%EULER )  THEN                                              
         JNT(J)%CNTR_SYM(I) = YPR3(I,J) * RADIAN
         ANG(I,J) = ANG(I,J) * RADIAN - JNT(J)%CNTR_SYM(I)
        END IF
       END DO                                                          
       IF  ( NPRT(23) .NE. I_0 )  THEN  
        WRITE ( LUAOU, 155 )  J, JNT(J)%JNT_NAME,                                         
     &                        ( ( HT(I,K,2*J-1), K=1,3 ),
     &                          ( HT(I,K,2*J),   K=1,3 ), I=1,3 )         
  155   FORMAT ( '0', I4, 2X, A4, 3X, 3F12.6, 3X, 3F12.6, /,
     &           ( 14X, 3F12.6, 3X, 3F12.6 ) )  
       END IF
      END DO
!C                                                            
!C    Print Cards B.4 for each joint.                       
!C                                                                
      WRITE ( LUAOU, 160 )  NPG, UNITL, UNITM, UNITL, UNITM         
  160 FORMAT ( '1 Joint Torque Characteristics', 93X,             
     &         'Page', I5, /, 120X, 'Cards B.4', /,                 
     &         23X, 'Flexural Spring Characteristics',
     &         28X, 'Torsional Spring', ' Characteristics', //,         
     &         15X, 'Spring Coef. (', 2A4, '/deg**J)', 
     &          6X, 'Energy     Joint',   
     &          7X, 'Spring Coef. (', 2A4, '/deg**J)',
     &          6X, 'Energy     Joint', /, '  Joint ',
     &  2 ( 8X, 'Linear    Quadratic     Cubic    Dissipation  Stop ' ),  
     &   /, 8X, 2( 8X,'(J=1)', 7X, '(J=2)', 7X, '(J=3)', 
     &          7X, 'Coef.     (deg)' ), / )     
      NPG = NPG + I_1                                                     
!C
      DO  J=1,NJNT                                                  
       J1 = I_3 * J - I_2                                                    
       J2 = I_3 * J - I_1                                                
       J3 = I_3 * J                                                 
       WRITE ( LUAOU, 165 )  J, JNT(J)%JNT_NAME, 
     &                      ( ( SPRING(I,JJ), I=1,5 ), JJ=J1,J2 )     
  165  FORMAT ( I3, 1X, A4, 2( 3X, 3F12.3, 2F10.3 ) )                      
       IF ( JNT(J)%EULER )  WRITE ( LUAOU, 170 ) ( SPRING(I,J3), I=1,5 )                     
  170  FORMAT ( 11X, 3F12.3, 2F10.3 )                                      
      END DO
!C                                                                      
!C    Print Cards B.5 for each joint.                                   
!C                                                                      
      WRITE  ( LUAOU, 175 )  ( UNITL, UNITM, UNITT, I=1,2 ),
     &                       ( UNITL, UNITM, I=1,2 ), UNITT  
  175 FORMAT ( ///, 120X, 'Cards B.5', /, 38X,                           
     &         'Joint Viscous Characteristics and Lock-Unlock',
     &         ' Conditions', //, 14X, 'Viscous', 9X, 'Coulomb',
     &         7X, 'Full Friction', 5X, 'Max Torque for',  
     &         4X, 'Min Torque for', 4X, 'Min. Ang. Velocity',
     &         6X, 'Impulse', /, 2X, 'Joint', 5X, 'Coefficient',
     &         4X, 'Friction Coef. Angular Velocity',  
     &         4X, 'a Locked Joint', 4X, 'Unlocked Joint',
     &         4X, 'for Unlocked Joint', 4X, 'Restitution', /,           
     &         8X, '(', 3A4, '/DEG)  (', 2A4, ')', 6X, '(DEG/',
     &         A4,')', 10X, '(', 2A4, ')',  
     &         8X, '(', 2A4, ')', 10X, '(RAD/', A4, ')',
     &         8X,'Coefficient' / )          
      DO  J=1,NJNT                                                       
       J1 = I_3 * J - I_2                                                     
       J2 = I_3 * J - I_1                                                      
       J3 = I_3 * J                                                          
       WRITE ( LUAOU, 180 )  J, JNT(J)%JNT_NAME, ( VISC(I,J1), I=1,7 )                    
  180  FORMAT ( I3, 1X, A4, F13.3, 2F15.2, F22.2, F18.2, F20.2, F17.3 )    
       IF ( JNT(J)%EULER )  WRITE ( LUAOU, 185) 
     &                  ( ( VISC(I,JJ), I=1,7 ), JJ=J2,J3 )        
  185  FORMAT (      8X, F13.3, 2F15.2, F22.2, F18.2, F20.2, F17.3 )     
      END DO
!C                                                                        
!C     Change SPRING and VISC from deg to rad                             
!C                                                                        
      DO  I=1,NJNT                                                        
       J1 = I_3 * I - I_2                                           
       J2 = I_3 * I - I_1                                        
       IF ( JNT(I)%EULER ) J2 = I_3 * I                                      
       DO  J=J1,J2                                                        
        SPRING(1,J) = SPRING(1,J) / RADIAN                                
        SPRING(2,J) = SPRING(2,J) / RADIAN**2                             
        SPRING(3,J) = SPRING(3,J) / RADIAN**3                             
        SPRING(5,J) = SPRING(5,J) * RADIAN                                
       END DO                                                             
       IF ( .NOT. JNT(I)%EULER ) J2 = J1                               
       DO  J=J1,J2                                                        
        VISC  (1,J) = VISC  (1,J) / RADIAN                                
        VISC  (3,J) = VISC  (3,J) * RADIAN                                
       END DO
      END DO
!C
      RETURN
      END
      