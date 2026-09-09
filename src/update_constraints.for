      SUBROUTINE  UPDATE_CONSTRAINTS ( I )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine updates the constraints, as defined by
!C     the D.5 cards.  It was created from Subroutine UPDATE.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       NPRT, NQ,                                              ! /CONTRL/
     &       CFQQ, HHT, HQQ, KQ1, KQ2, KQTYPE, QQ, RK1, RK2,        ! /CSTRNT/
     &        RQQ, SQQ, TQQ,                                        ! /CSTRNT/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,                        ! parameters
     &       D_0, I_0, I_1, I_3, I_4, I_7                           ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, II, J, K
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  QDOTQ, QN, QT, TEST_UP1 
      PARAMETER  ( TEST_UP1 = 0.9E0_IREAL_HIGH )
!C
      REAL  ( KIND = IREAL_HIGH )  XDY
      EXTERNAL          XDY
!C
      INTENT ( OUT )  I
!C
!C    F is the force on segment J+1, - F is on segment M.                  
!C                                                                        
      DO  K=1,NQ                                                         
       IF  ( KQTYPE(K) .LT. I_3 )  CYCLE                             
       IF  ( KQTYPE(K) .GT. I_4 )  CYCLE                             
!C
       IF  ( CFQQ(K) .LT. D_0 )  THEN
        KQTYPE(K) = -KQTYPE(K)                          
        CALL OUTPUT ( I_0 )                                            
        CALL SETUP2                                                      
        CALL DAUX ( K )                                               
        IF  ( NPRT(24) .NE. I_0 )  CALL OUTPUT ( I_1 )                  
        IF  ( NPRT( 3) .NE. I_0 )  CALL PRINT ( 'UPDTCT' )             
        I = -I_1                                                         
        CYCLE
       END IF
!C                                                                        
!C     Test if rolling constraint should be sliding and vice versa.      
!C                                                                       
       QN = -XDY ( TQQ(1,K), HHT(1,1,K), QQ(1,K) )                        
       IF ( NPRT(24) .NE. I_0 )  THEN
        WRITE ( LUAOU, 100 )   KQTYPE(K), KQ1(K), KQ2(K),            
     &                      ( RK1(II,K), II=1,3 ), 
     &                      ( RK2(II,K), II=1,3 ),           
     &                    ( ( HHT(II,J,K), J=1,3 ), II=1,3 ),                   
     &                      (  QQ(II,K), II=1,3 ),
     &                      ( TQQ(II,K), II=1,3 ),
     &                      ( RQQ(II,K), II=1,3 ),     
     &                      ( HQQ(II,K), II=1,3 ),
     &                        SQQ(K), CFQQ(K), QN                 
  100   FORMAT ( '0 Update roll-slide test.', /, ( 2X, 9G14.6 ) )                
       END IF
!C
       IF ( QN .LT. D_0 ) THEN
        KQTYPE(K) = -I_4                                              
        CALL OUTPUT ( I_0 )                                            
        CALL SETUP2                                                     
        CALL DAUX ( K )                                                  
        IF  ( NPRT(24) .NE. I_0 )  CALL OUTPUT ( I_1 )                  
        IF  ( NPRT( 3) .NE. I_0 )  CALL PRINT ( 'UPDTCT' )             
        I = -I_1                                                         
        CYCLE                                                        
       END IF
!C
       QDOTQ = QQ(1,K)**2 + QQ(2,K)**2 + QQ(3,K)**2                      
       QT = SQRT ( QDOTQ - QN**2 )                                       
       IF ( ( KQTYPE(K) .EQ. I_3 ) .AND.
     &      ( QT .LE. ( CFQQ(K) * QN ) ) ) CYCLE            
       IF ( ( KQTYPE(K) .EQ. I_4 ) .AND. 
     &      ( QT .GE. ( TEST_UP1 * CFQQ(K) * QN ) ) ) CYCLE              
       KQTYPE(K) = I_7 - KQTYPE(K)                                
       CALL OUTPUT ( I_0 )                                            
       CALL SETUP2                                                      
       CALL DAUX ( K )                                                   
       IF  ( NPRT(24) .NE. I_0 )  CALL OUTPUT ( I_1 )                  
       IF  ( NPRT( 3) .NE. I_0 )  CALL PRINT ( 'UPDTCT' )             
       I = -I_1                                                         
      END DO                                                             
!C
      RETURN
      END