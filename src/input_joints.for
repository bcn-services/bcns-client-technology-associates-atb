      SUBROUTINE INPUT_JOINTS ( IDYPR, IDYPRT, SLIP,
     &                          YPR1, YPR2, YPR3 )

!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the data for the joints.
!C
      USE  MODULE_STANDARD, ONLY:
     &        ANG, IEULER,                                 ! /CEULER/
     &        EPS,                                         ! /CNSTNS/
     &        NFLX, NJNT, NJNTF,                           ! /CONTRL/
     &        JOINTF, SPRING, VISC,                        ! /DESCRP/  
     &        NFLEX,                                       ! /FLXBLE/
     &        JNT,                                         ! structures
     &        INTEGER_STD, IREAL_HIGH, LOGICAL_STD,        ! parameters
     &        LUAIN, LUAOU, MAXJNT, FALSE, TRUE, LULIN,    ! parameters
     &        D_0, I_0, I_1, I_3, I_4, I_5,                ! parameters
     &        AIN_CONVERT, LIN_FLAG, ICHAR_STD             ! parameters
!C
!C    COMP_MAX, EULER, JNT_NAME, DSTL_LOC, PROX_LOC, PROX_SEG,    ! JNT% 
!C    JTYPE, TENS_MAX                                             ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:   IBODN, NFBOD, NODJ  ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &            I, ID1, ID4, IDYPR, IDYPRT, 
     &            II, IK, IL, IT, IX,
     &            J, JP1, K, KL, KNT, L, NFA
      DIMENSION  IDYPR(6,MAXJNT), KNT(MAXJNT) 
!C
      DOUBLE PRECISION  YPR1, YPR2, YPR3
      DIMENSION  YPR1(3,MAXJNT), YPR2(3,MAXJNT), YPR3(3,MAXJNT)       
!C
      CHARACTER  ( LEN =   4, KIND = ICHAR_STD )  ATEMP4
      CHARACTER  ( LEN =   6, KIND = ICHAR_STD )  ATEMP6
!C
      LOGICAL  ( KIND = LOGICAL_STD ) SLIP                                             
!C
      INTENT ( OUT )  IDYPR, IDYPRT, SLIP,
     &                YPR1, YPR2, YPR3
!C
      IDYPRT = I_0                                                       
!C                                                                   
!C    Input Cards  B.3  for each joint.                                   
!C                                                                       
      SLIP = FALSE                                                      
      DO  J=1,NJNT                                                    
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  JNT(J)%JNT_NAME, JNT(J)%PROX_SEG, 
     &                     JNT(J)%JTYPE,
     &                     ( JNT(J)%PROX_LOC(I), I=1,3 ),   
     &                     ( JNT(J)%DSTL_LOC(I), I=1,3 ),
     &                     IEULER(J), JNT(J)%TENS_MAX, JNT(J)%COMP_MAX    
        READ ( LULIN, * )  ( YPR1(I,J), I=1,3 ), ( YPR2(I,J), I=1,3 ),   
     &                     ( YPR3(I,J), I=1,3 ), ( IDYPR(I,J), I=1,6 )  
       ELSE
        READ ( LUAIN, 100 )  JNT(J)%JNT_NAME, JNT(J)%PROX_SEG, 
     &                       JNT(J)%JTYPE,
     &                       ( JNT(J)%PROX_LOC(I), I=1,3 ),   
     &                       ( JNT(J)%DSTL_LOC(I), I=1,3 ),
     &                       IEULER(J), JNT(J)%TENS_MAX, 
     &                       JNT(J)%COMP_MAX,    
     &                       ( YPR1(I,J), I=1,3 ), 
     &                       ( YPR2(I,J), I=1,3 ),   
     &                       ( YPR3(I,J), I=1,3 ), 
     &                       ( IDYPR(I,J), I=1,6 )  
  100   FORMAT ( A4, 2X, 2I4, 6F6.0, I4, 2F6.0, /, 14X, 9F6.0, 6I2 )   
        IF ( AIN_CONVERT )  THEN
         ATEMP4 = ADJUSTL ( JNT(J)%JNT_NAME )
         L = LEN_TRIM ( ATEMP4 )
         ATEMP6(1:L+2) = '"' // ATEMP4(1:L) // '"'
         WRITE ( LULIN, 105 )  ATEMP6(1:L+2), JNT(J)%PROX_SEG, 
     &                         JNT(J)%JTYPE,
     &                         ( JNT(J)%PROX_LOC(I), I=1,3 ),   
     &                         ( JNT(J)%DSTL_LOC(I), I=1,3 ),
     &                         IEULER(J), JNT(J)%TENS_MAX, 
     &                         JNT(J)%COMP_MAX, 'Card B.3.a'    
  105    FORMAT ( 1X, A, 1X, 2( I4, 1X ), 6( F15.7, 1X ), 
     &            I4, 1X, 2( F15.7, 1X ), 1X, A )
         WRITE ( LULIN, 110 )  ( YPR1(I,J), I=1,3 ), 
     &                         ( YPR2(I,J), I=1,3 ),  
     &                         ( YPR3(I,J), I=1,3 ), 
     &                         ( IDYPR(I,J), I=1,6 ), 'Card B.3.b'  
  110    FORMAT ( 1X, 9( F15.7, 1X ), 6( I2, 1X ), 1X, A )   
        END IF
       END IF
       DO  I=1,NFBOD
        IF ( ( IBODN(I) .EQ. JNT(J)%PROX_SEG ) .OR. 
     &       ( IBODN(I) .EQ. (J + I_1 ) ) )  THEN
         IF ( LIN_FLAG )  THEN
          READ ( LULIN, * )  ( ( NODJ(IK,IL,J), IK=1,3 ), IL=1,2 )                   
         ELSE
          READ ( LUAIN, 115 )  ( ( NODJ(IK,IL,J), IK=1,3 ), IL=1,2 )                   
  115     FORMAT ( 6I6 )                                                 
          IF ( AIN_CONVERT )  THEN
           WRITE ( LULIN, 120 )  ( ( NODJ(IK,IL,J), IK=1,3 ), IL=1,2 ),
     &                           'Card B.3.c'                   
  120      FORMAT ( 1X, 6( I6, 1X ), 1X, A )                                                 
          END IF
         END IF
         EXIT
        END IF
       END DO
!C
       ID1 = IDYPR(1,J)                                                  
       ID4 = IDYPR(4,J)                                                   
       JNT(J)%EULER = FALSE                                                  
       IF ( JNT(J)%JTYPE .EQ. I_4 )   JNT(J)%EULER = TRUE                     
       IF ( ( IEULER(J) .EQ. I_0 ) .AND. 
     &      ( JNT(J)%JTYPE .LE. -I_4 ) )  JNT(J)%EULER = TRUE           
       IF ( ( .NOT. JNT(J)%EULER ) .AND. 
     &      ( ABS ( JNT(J)%JTYPE ) .GE. I_5 ) )   SLIP = TRUE     
       IF ( ( ID1 .NE. I_0 ) .OR. ( ID4 .NE. I_0 ) ) 
     &        IDYPRT = I_1               
       DO  II=1,6                                                      
        IF ( ABS ( IDYPR(II,J) ) .GT. I_3 )  STOP 101                     
       END DO
       DO  I=1,3                                                        
        IF  ( ID1 .EQ. I_0 )   IDYPR(I  ,J) = I_4 - I                     
        IF  ( ID4 .EQ. I_0 )   IDYPR(I+3,J) = I_4 - I                       
       END DO
      END DO 
!C                                                                        
!C    Compute NFLX and NFLEX array from negative values of JNT(J).        
!C    NFLX will be number of constraint torques for flexible segments.    
!C    NFLEX(1, ) reference segment (lowest numbered segment of chain)     
!C    NFLEX(2, ) interior segment numbers                                 
!C    NFLEX(3, ) terminating segment (highest numbered segment in chain)  
!C    Values of NFLEX need not be sequential but must be ordered.         
!C    flexible segment must be simple chain, i.e., branching segments     
!C    cannot be attached to interior segments but may be attached to      
!C    reference or terminating segments.                                  
!C                                                                       
      DO  J=1,NJNT                                                      
       KNT(J) = JNT(J)%PROX_SEG                                                   
      END DO
      DO  J=1,NJNT                                                
       IF ( KNT(J) .GE. I_0 )  CYCLE                                           
       NFA = NFLX + I_1                                                       
       IT = J + I_1                                                          
       IF ( IT .LE. NJNT )  THEN                                            
        JP1 = J + I_1                                                          
        DO  L=JP1,NJNT                                                  
         IF ( ABS ( KNT(L) ) .NE. IT )  CYCLE                                    
         KL = KNT(L)                                                        
         KNT(L) = I_0                                                          
         IF ( KL .GT. I_0 )  EXIT                                              
         NFLX = NFLX + I_1                                                       
         NFLEX(1,NFLX) = ABS ( KNT(J) )                                     
         NFLEX(2,NFLX) = IT                                                  
         IT = L + I_1                                                         
        END DO                                                            
       END IF
       IF ( NFLX .LT. NFA )  THEN                                         
        WRITE ( LUAOU, 125 )                                              
  125   FORMAT ( '0Error in defining flexible segments, ',
     &           'only one negative JNT in string. Program terminated.') 
        STOP 3                                                              
       END IF
   20  DO  K=NFA,NFLX                                                    
        NFLEX(3,K) = IT                                                  
       END DO
      END DO                                                           
!C                                                                         
!C    Input Cards B.4 for each joint.                                   
!C                                                                         
      NJNTF = I_0                                                         
      JOINTF = I_0
      DO  J=1,NJNT                                                 
       IX = I_1                                                        
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )    ( SPRING(I,3*J-2), I=1,5 ),
     &                       ( SPRING(I,3*J-1), I=1,5 )    
       ELSE
        READ ( LUAIN, 130 )  ( SPRING(I,3*J-2), I=1,5 ),
     &                       ( SPRING(I,3*J-1), I=1,5 )    
  130   FORMAT ( 2( 4F6.0, F12.0 ) )                                           
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 135 )  ( SPRING(I,3*J-2), I=1,5 ),
     &                         ( SPRING(I,3*J-1), I=1,5 ), 
     &                         'Card B.4.a'    
  135    FORMAT ( 1X, 10( F19.11, 1X ), 1X, A )                                           
        END IF
       END IF
       IF ( JNT(J)%EULER )   THEN
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  ( SPRING(I,3*J), I=1,5 ), 
     &                      ( ANG(I,J), I=1,3 ) 
        ELSE
         READ ( LUAIN, 140 )  ( SPRING(I,3*J), I=1,5 ), 
     &                        ( ANG(I,J), I=1,3 ) 
  140    FORMAT ( 2( 4F6.0, F12.0 ) )                                           
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 145 )  ( SPRING(I,3*J), I=1,5 ), 
     &                          ( ANG(I,J), I=1,3 ), 'Card B.4.b' 
  145     FORMAT ( 1X, 8( F19.11, 1X ), 1X, A )                                           
         END IF
        END IF
        IX = I_0                                            
       END IF
       DO  K=2,IX,-1                                               
        IF ( SPRING(1,3*J-K) .LT. D_0 ) THEN                             
         NJNTF = I_1                                                   
         JOINTF(3-K,J) = INT ( ABS ( SPRING(1,3*J-K) ) )                
         DO  I=2,5                                                   
          SPRING(I,3*J-K) = D_0                                     
         END DO
        END IF                                                       
       END DO                                                      
      END DO                                                            
!C                                                                      
!C    Input Cards B.5 for each joint.                                
!C                                                                     
      DO  J=1,NJNT                                                      
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( VISC(I,3*J-2), I=1,7 )                                  
       ELSE
        READ ( LUAIN, 150 )  ( VISC(I,3*J-2), I=1,7 )                                  
  150   FORMAT ( 5F6.0, 18X, 2F6.0 )                                             
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 155 )  ( VISC(I,3*J-2), I=1,7 ), 'Card B.5.a'                                  
  155    FORMAT ( 1X, 7( F15.7, 1X ), 1X, A )                                             
        END IF
       END IF
       IF ( ( JNT(J)%PROX_SEG .GT. I_0 ) .AND. 
     &      ( VISC(3,3*J-2) .LE. EPS(9) ) ) THEN
        WRITE ( LUAOU, 160) VISC(3,3*J-2), J
  160   FORMAT ( 1X, ' Angular velocity of applying full Coulomb',
     &               ' friction must be greater than ', D8.2, 
     &               ' for joint ', I3, '.' )
        STOP 294
       END IF
       IF  ( .NOT. JNT(J)%EULER )   CYCLE                                           
!C
!C     Read the B.5.b card.
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( VISC(I,3*J-1), I=1,7 )                                  
       ELSE
        READ ( LUAIN, 165 )  ( VISC(I,3*J-1), I=1,7 )                                  
  165   FORMAT ( 5F6.0, 18X, 2F6.0 )                                             
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 170 )  ( VISC(I,3*J-1), I=1,7 ), 'Card B.5.b'                                  
  170    FORMAT ( 1X, 7( F15.7, 1X ), 1X, A )                                             
        END IF
       END IF
!C
!C     Read the B.5.c card.
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  ( VISC(I,3*J  ), I=1,7 )                                  
       ELSE
        READ ( LUAIN, 175 )  ( VISC(I,3*J  ), I=1,7 )                                  
  175   FORMAT ( 5F6.0, 18X, 2F6.0 )                                             
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 180 )  ( VISC(I,3*J), I=1,7 ), 'Card B.5.c'                                  
  180    FORMAT ( 1X, 7( F15.7, 1X ), 1X, A )                                             
        END IF
       END IF
!C
!C     Check if the relative angular velocity of the joint at which full
!C      Coulomb friction is to be applied is greater than 0.
!C
       IF ( ( VISC(3,3*J-1) .LE. EPS(9) ) .OR. 
     &      ( VISC(3,3*J)   .LE. EPS(9) ) ) THEN
        WRITE ( LUAOU, 185)
  185   FORMAT ( 1X, ' Angular velocity of applying full Coulomb',
     &               ' friction must be greater than ', D8.2, '.' )
        STOP 294
       END IF
      END DO                                                            
!C
      RETURN
      END
      