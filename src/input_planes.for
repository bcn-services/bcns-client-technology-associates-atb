      SUBROUTINE INPUT_PLANES
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine reads in the data for the contact
!C     planes.
!C
!C    This subroutine is called only by INPUT_DCARDS.
!C
!C
      USE  MODULE_STANDARD,  ONLY:
     &       PL,                               ! /CNTSRF/
     &       NPL, NPG,                         ! /CONTRL/
     &       PLTTL,                            ! /TITLES/
     &       INTEGER_STD, IREAL_HIGH,          ! parameters
     &       LUAIN, LUAOU, LULIN, ICHAR_STD,   ! parameters
     &       I_0, I_1, I_7, D_0,               ! parameters
     &       AIN_CONVERT, LIN_FLAG             ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, IPAGE, J, JJ, L 
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  P1_LCL, P2, P3,  
     &                  S1_LCL, S2, S22, S23, S3, S33
      DIMENSION         P1_LCL(3), P2(3), P3(3)     
!C
      CHARACTER  ( LEN =  20, KIND = ICHAR_STD )  ATEMP20              
      CHARACTER  ( LEN =  22, KIND = ICHAR_STD )  ATEMP22              
!C
      IPAGE = I_0                                                    
!C
      DO 20 J=1,NPL                                                       
!C                                                                       
!C     Read and print Cards D.2.a, D.2.b, D.2.c, and D.2.d for the Jth plane.      
!C                                                                       
       CALL CHECK_COMMENT
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  JJ, PLTTL(J)
        READ ( LULIN, * )  P1_LCL 
        READ ( LULIN, * )  P2
        READ ( LULIN, * )  P3                 
       ELSE
        READ ( LUAIN, 100 ) JJ, PLTTL(J), P1_LCL, P2, P3                 
  100   FORMAT ( I4, 4X, A20, /, ( 3F12.0 ) )                           
        IF ( AIN_CONVERT )  THEN
         ATEMP20 = ADJUSTL ( PLTTL(J) )
         L = LEN_TRIM ( ATEMP20 )
         ATEMP22(1:L+2) = '"' // ATEMP20(1:L) // '"'
         WRITE ( LULIN, 105 ) JJ, ATEMP22(1:L+2), 'Card D.2.a'
  105    FORMAT ( 1X, I4, 1X, A, 2X, A )                           
         WRITE ( LULIN, 110 )  P1_LCL,  'Card D.2.b'                 
  110    FORMAT ( 1X, 3( F19.11, 1X ), 1X, A )                           
         WRITE ( LULIN, 115 )  P2, 'Card D.2.c'                 
  115    FORMAT ( 1X, 3( F19.11, 1X ), 1X, A )                           
         WRITE ( LULIN, 120 )  P3, 'Card D.2.d'                 
  120    FORMAT ( 1X, 3( F19.11, 1X ), 1X, A )                           
        END IF
       END IF
!C
       IF ( JJ .NE. J )  THEN
        WRITE  ( LUAOU, 125 )  JJ, J                
  125   FORMAT  ( ' Plane index input error: JJ = ', I4,
     &            1X, ' J = ', I4 )          
        STOP 10                                
       END IF
       IF       ( ( MOD ( J, I_7 ) .EQ. I_1 ) .AND. 
     &                                  ( IPAGE .EQ. I_0 ) )  THEN
        WRITE ( LUAOU, 130 )  IPAGE                                        
  130   FORMAT ( I1, ' Plane Inputs', 106X, 'Cards D.2' )                
       ELSE IF  ( ( MOD ( J, I_7 ) .EQ. I_1 ) 
     &                      .AND. ( IPAGE .EQ. I_1 ) )  THEN 
        WRITE ( LUAOU, 135 ) IPAGE, NPG                                     
  135   FORMAT ( I1, ' Plane Inputs', 109X, 'Page', I5, /,
     &           120X, 'Cards D.2' )                                       
        NPG = NPG + I_1                                                   
       END IF
       IPAGE = I_1                                                    
       WRITE  ( LUAOU, 140 )  J, PLTTL(J), P1_LCL, P2, P3                 
  140  FORMAT ( '0 Plane No.', I4, 4X, A20, //, 
     &          17X, 'X', 11X, 'Y', 11X, 'Z', /,                          
     &         '  Point 1 ' , 3F12.4, /,                                  
     &         '  Point 2 ' , 3F12.4, /,                                 
     &         '  Point 3 ' , 3F12.4 )                                    
!C                                                                        
!C     Program now assumes the finite plane is a parallelogram in shape   
!C     where the input points P1,P2,P3 are 3 of the corners such that     
!C     edge P1-P2 is less than 180 degrees clockwise (as viewed by the    
!C     occupant) from the edge P1-P3.                                     
!C                                                                        
!C     Set up PL array as required by Subroutine PLELP                    
!C                                                                        
!C         PL(1,J) = A0   Normal equation of Jth place                    
!C         PL(2,J) = B0     A0*X + B0*Y + C0*Z = D0                       
!C         PL(3,J) = C0                                                   
!C         PL(4,J) = D0                                                   
!C                                                                        
!C         PL(5,J)                                                        
!C         PL(6,J)        Point 1                                           
!C         PL(7,J)                                                        
!C                                                                        
!C         PL(8,J) =A1                                                    
!C         PL(9,J) =B1    Normal equation of 1st boundary plane           
!C         PL(10,J)=C1      A1*X + B1*Y + C1*Z = D1                      
!C         PL(11,J)=D1    and E1 is length of plane from boundary.        
!C         PL(12,J)=E1                                                    
!C                                                                       
!C         PL(13,J)=A2                                                    
!C         PL(14,J)=B2    Normal equation of 2nd boundary plane          
!C         PL(15,J)=C2      A2*X + B2*Y + C2*Z = D2                       
!C         PL(16,J)=D2    and E2 is length of plane from boundary.        
!C         PL(17,J)=E2                                                    
!C                                                                        
!C         PL(18,J)                                                         
!C         PL(19,J)       Point 2 - Point 1                                 
!C         PL(20,J)                                                         
!C                                                                          
!C         PL(21,J)                                                         
!C         PL(22,J)       Point 3 - Point 1                                 
!C         PL(23,J)                                                        
!C                                                                          
!C         PL(24,J)       Not currently used                                
       S22 = D_0                                                      
       S23 = D_0                                                        
       S33 = D_0                                                       
       DO  I =1,3                                                         
        P2(I)      = P2(I) - P1_LCL(I)                                    
        P3(I)      = P3(I) - P1_LCL(I)                                    
        PL(I+ 4,J) = P1_LCL(I)                                              
        PL(I+17,J) = P2(I)                                                  
        PL(I+20,J) = P3(I)                                                  
        S22 = S22 + P2(I) * P2(I)                                         
        S23 = S23 + P2(I) * P3(I)                                         
        S33 = S33 + P3(I) * P3(I)                                         
       END DO
       S2  = SQRT ( S22 )                                                 
       S3  = SQRT ( S33 )                                                 
       CALL CROSS ( P2, P3, PL(1,J) )                                    
       S1_LCL = D_0                                                
       DO  I=1,3                                                          
        S1_LCL = S1_LCL + PL(I,J)**2                                      
       END DO
       S1_LCL = SQRT ( S1_LCL )                                           
       DO  I=1,3                                                          
        PL(I,J)    = PL(I,J) / S1_LCL                                     
        PL(I+7 ,J) = ( S33 * P2(I) - S23 * P3(I) ) / ( S1_LCL * S3 )      
        PL(I+12,J) = ( S22 * P3(I) - S23 * P2(I) ) / ( S1_LCL * S2 )     
       END DO
       PL( 4,J) =    P1_LCL(1) * PL( 1,J)
     &             + P1_LCL(2) * PL( 2,J) 
     &             + P1_LCL(3) * PL( 3,J)                                 
       PL(11,J) =    P1_LCL(1) * PL( 8,J) 
     &             + P1_LCL(2) * PL( 9,J) 
     &             + P1_LCL(3) * PL(10,J)                                 
       PL(12,J) =        P2(1) * PL( 8,J)
     &             +     P2(2) * PL( 9,J)
     &             +     P2(3) * PL(10,J)                                 
       PL(16,J) =    P1_LCL(1) * PL(13,J) 
     &             + P1_LCL(2) * PL(14,J) 
     &             + P1_LCL(3) * PL(15,J)                                 
       PL(17,J) =        P3(1) * PL(13,J)
     &             +     P3(2) * PL(14,J)
     &             +     P3(3) * PL(15,J)                                 
   20 CONTINUE
!C
      RETURN
      END