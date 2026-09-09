      SUBROUTINE  INPUT_ELLIPSOIDS
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine controls the reading and printing of
!C    the input cards that describe the additional contact 
!C    ellipsoids.                                                                          
!C
!C    This subroutine is called only by INPUT_DCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       UNITL,                                 ! /CNSNTS/
     &       BD,                                    ! /CNTSRF/
     &       NGRND, NSEG, NVEH, NPG,                ! /CONTRL/
     &       MELL, NELP, P1S, P2S, P3S, P4S,        ! /XTRA/
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,  ! parameters
     &       LUAIN, LUAOU, MAXELP, LULIN, LIN_FLAG, ! parameters
     &       I_0, I_1, I_2, I_3, AIN_CONVERT,       ! parameters
     &       D_0, D_1 , D_2, TRUE, FALSE            ! parameters
!C
      USE  MODULE_WATER,  ONLY:
     &       DELP, NELPS                            ! /ELPDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, IDYPR, J, J1, J2, JMM, K, L, M, MM, N 
      DIMENSION  IDYPR(3)                                                
!C
      REAL  ( KIND = IREAL_HIGH )
     &                 DE, P1_LCL, P2, P3, P4, SUM1, SUM2
      DIMENSION        DE(3,3), P1_LCL(3), P2(3), P3(3), P4(3)         
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LP4              
!C
      DATA IDYPR / I_3, I_2, I_1 /           
!C                                                                        
!C    Read and print Cards D.5 for ellipsoid input, if any.               
!C     Note: NELP is the no. of ellipsoids to be supplied here, not the   
!C             no. of ellipsoids in the program, since the first NSEG     
!C            ellipsoids were supplied on Cards B.2 however               
!C            they may be replaced here if desired.                       
!C                                                                        
      WRITE ( LUAOU, 100 )   NPG, UNITL, UNITL                              
  100 FORMAT ( '1 Additional Ellipsoid Input', 95X, 'Page', I5, /, 120X,   
     &         'Cards D.5', /, 17X, 'Semiaxes (', A4, ')', 18X,
     &         'Offset (', A4, ')', 20X, 'Rotation (deg)', 15X,
     &         'Power', /, 3X, 'No.', 2( 8X, 'X', 8X, 'Y', 8X,
     &         ' Z', 6X ), 7X, 'Yaw', 7X, 'Pitch', 5X, 'Roll', // )       
      NPG = NPG + I_1                                                   
!C                                                                        
      NELPS = NSEG                                                      
!C                                                                       
      DO  MM=1,NELP                                                     
!C
!C     Check for comments.
!C
       CALL  CHECK_COMMENT
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  M, P1_LCL, P2, P3, P4                         
       ELSE
        READ ( LUAIN, 115 )  M, P1_LCL, P2, P3, P4                         
  115   FORMAT ( I6, 9F6.0, 3F4.0 )                                         
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 120 )  M, P1_LCL, P2, P3, P4, 'Card D.5'                         
  120    FORMAT ( 1X, I8, 1X, 12( F15.7, 1X ), 1X, A )                                         
        END IF
       END IF
!C
!C      Added for structured output file .SA1                           
!C
       MELL(MM) = M                                                     
       DO  JMM=1,3                                                      
        P1S(JMM,MM) = P1_LCL(JMM)                                       
        P2S(JMM,MM) = P2(JMM)                                           
        P3S(JMM,MM) = P3(JMM)                                           
        P4S(JMM,MM) = P4(JMM)                                           
       END DO                                                           
!C
!C     End addition for structured output file .SA1                     
!C
       IF ( M .GT. MAXELP )  STOP 63                                    
!C                                                                        
!C     Prevent extra ellipsoids from changing airbag ellipsoids           
!C                                                                        
       IF ( ( M .GT. NVEH) .AND. ( M .LT. NGRND ) )  THEN
        WRITE ( LUAOU, 125 )                                              
  125   FORMAT ( 3X, 'The extra contact ellipsoid number is the ',
     &           'same as an airbag ellipsoid' )                          
        STOP  64
       END IF
       WRITE ( LUAOU, 130 )  M, P1_LCL, P2, P3, P4                         
  130  FORMAT ( I6, 3( 3X, 3F9.3, 3X ), 3F6.0 )                           
       CALL DRCYPR ( DE, P3, IDYPR )                                      
!C                                                                       
       IF ( M .GT. ( NSEG + I_1 ) )   NELPS = NELPS + I_1           
       DO  J1=1,3                                                       
        DO  J2=1,3                                                       
         DELP(J1,J2,M) = DE(J1,J2)                               
        END DO
       END DO                                                            
!C                                                                       
       N = I_1                                                       
       LP4 = FALSE                                                   
       DO  J = 1,3                                                        
        IF ( P4(J) .GT. D_2 )   LP4 = TRUE                           
       END DO
       IF ( LP4 ) N = I_2                                                
       DO  I = 1,3                                                         
        BD(N  ,M) = P1_LCL(I)                                             
        BD(N+3,M) = P2(I)                                                  
        IF ( .NOT. LP4 )  THEN                                             
         DO  J=1,3                                                        
          SUM1 = D_0                                                  
          SUM2 = D_0                                                 
          DO  L=1,3                                                       
           SUM1 = SUM1 + ( DE(L,I) / P1_LCL(L)**2 * DE(L,J) )             
           SUM2 = SUM2 + ( DE(L,I) * P1_LCL(L)**2 * DE(L,J) )             
          END DO
          K = ( I_3 * I ) + J + I_3                               
          BD(K  ,M) = SUM1                                                
          BD(K+9,M) = SUM2                                                
         END DO
        END IF
        N = N + I_1                                                   
       END DO
       IF ( LP4 )  THEN                                                    
        BD(1,M) = -P4(1)                                                  
        N = 8                                                              
        DO  J = 1,3                                                        
         BD(J+19,M) = P4(J)                                               
         IF ( BD(J+19,M) .EQ. D_0 )   BD(J+19,M) = BD(20,M)              
         BD(J+16,M) = D_1 / BD(J+1,M)**2                                 
         DO  I = 1,3                                                       
          BD(N,M) = DE(I,J)                                                
          N = N + I_1                                                  
         END DO
        END DO
        BD(23,M) = D_0                                                
        IF ( BD(20,M) .NE. BD(21,M) )  BD(23,M) = D_1                   
        IF ( BD(21,M) .NE. BD(22,M) )  BD(23,M) = D_1                    
        IF ( BD(22,M) .NE. BD(20,M) )  BD(23,M) = D_1                      
       END IF
      END DO                                                            
!C
      RETURN
      END