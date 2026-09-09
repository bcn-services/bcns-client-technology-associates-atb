      SUBROUTINE  INPUT_FORCE_TORQUE
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the force / torque functions
!C     specified on the D.9 cards.  The argument, NFORCE is
!C     the number of force/torque functions specified on 
!C     Card D.1.
!C
!C    It is called only by: INPUT_DCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       NPG,                                   ! /CONTRL/
     &       NFVNT, NFVSEG, QFU, QFV, NFORCE,       ! /WINDFR/
     &       INTEGER_STD, IREAL_HIGH, LIN_FLAG,     ! parameters
     &       LUAIN, LUAOU, LULIN, I_1, I_2, I_3,    ! parameters
     &       AIN_CONVERT                            ! parameters
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &       NODFR, NODSD,        ! /FXFRC/
     &       IBODN, NFBOD         ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, IDYPR, J 
      DIMENSION  IDYPR(3)                                                 
!C
      REAL  ( KIND = IREAL_HIGH )
     &                 DE, P1_LCL, P2
      DIMENSION         DE(3,3), P1_LCL(3), P2(3)       
!C
      DATA IDYPR / I_3, I_2, I_1 /           
!C                                                                       
!C    Cards D.9  force and/or torque functions.                          
!C                                                                       
      WRITE  ( LUAOU, 100 ) NPG                                              
  100 FORMAT ( '1', 6X, 'Force and/or Torque Function Inputs', 
     &         81X, 'Page', I5, /
     &         120X, 'Cards D.9', //, 5X, 'No.', 5X,'Seg', 5X,'FCN', 
     &         13X, 'X', 9X, 'Y', 9X, 'Z', 13X, 'Yaw',  6X,
     &         'Pitch', 6X, 'Roll', // )                                
      NPG = NPG + I_1                                                 
!C
      DO  J=1,NFORCE                                                    
!C
!C     Check for comments.
!C
       CALL CHECK_COMMENT
!C
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  NFVSEG(J), NFVNT(J), P1_LCL, P2              
       ELSE
        READ  ( LUAIN, 105 )  NFVSEG(J), NFVNT(J), P1_LCL, P2              
  105   FORMAT ( 2I6, 6F10.0 )                                            
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 110 )  NFVSEG(J), NFVNT(J), P1_LCL, P2,
     &                          'Card D.9.a'              
  110    FORMAT ( 1X, 2( I6, 1X ), 6( E17.10, 1X ), 1X, A )                                            
        END IF
       END IF
!C
!C     Specify node number of the applied force for deformable bodies.  
!C
       DO  I=1,NFBOD                                                   
        IF ( IBODN(I) .EQ. NFVSEG(J) )  THEN 
         IF ( LIN_FLAG )  THEN
          READ ( LULIN, * )  NODFR(J)   
         ELSE
          READ ( LUAIN, 115 )  NODFR(J)   
  115     FORMAT ( 2I5 )                                                 
          IF ( AIN_CONVERT )  THEN
           WRITE ( LULIN, 120 )  NODFR(J), 'Card D.9.b'   
  120      FORMAT ( 1X, 2( I5, 1X ), 1X, A )                                                 
          END IF
         END IF
        END IF
       END DO
       WRITE  ( LUAOU, 125 )  J, NFVSEG(J), NFVNT(J), P1_LCL, P2      
  125  FORMAT ( 3I8, 6X, 3F10.3, 6X, 3F10.3 )                            
       CALL DRCYPR ( DE, P2, IDYPR )                                     
       DO  I=1,3                                                         
        QFU(I,J) = DE(1,I)                                               
       END DO
       CALL CROSS ( P1_LCL, QFU(1,J), QFV(1,J) )                         
      END DO
!C
      RETURN
      END
