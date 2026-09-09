      SUBROUTINE INPUT_PROJANG ( JTH, IYPR, YPR, FIRST )               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                      
!C    This subroutine reads in data from Card G.3.b for segment no. J     
!C    when IYPR(1,J) is negative.  It then computes the orientation       
!C    of the segments from the projections or projection angles.          
!C                                                                        
!C                                                                        
!C    Subroutines called by:  INPUT_ORIENT                              
!C                                                                        
!C    Subroutines called: CROSS, YPRDEG                                   
!C                                                                        
!C    Logical unit(s) read from/written to: 5, 6                          
!C                                                                        
!C    STOPS:  240, 241, 242, 243, 244, 245, 246                           
!C                                                                         
!C    Common block and passed variables altered:                          
!C             passed:  IYPR, YPR, FIRST                                  
!C           /CNSNTS/:  RADIAN                                            
!C           /TITLES/:  SEG                                               
!C           /SGMNTS/:  D                                                 
!C             passed:  JTH                                               
!C                                                                        
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &         RADIAN,                                 ! /CNSNTS/
     &         SEG,                                    ! structures
     &         INTEGER_STD, IREAL_HIGH,                ! parameters 
     &         LUAIN, LUAOU, MAXSEG,                   ! parameters
     &         I_0, I_1, I_2, I_3, I_4, I_6, D_0, D_1, ! parameters
     &         AIN_CONVERT, LULIN, LIN_FLAG            ! parameters
!C
!C    SEG%DIR_COS, SEG%NAME
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, II, IJ_LCL, IJ1, IJ2, IK, IT, IYPR, 
     &           J, JJ, JK, JTH, K, LK
      DIMENSION  IYPR(4,MAXSEG)
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  YPR, A, Z, CA1, CA2, DA1, DA2, FIRST,
     &                  RATIO, SA1, SA2, SGN, SQUM, SUM, TSTIPT, 
     &                  ZDOTII, ZDOTIJ 
      DIMENSION         YPR(3,MAXSEG), A(3,2), Z(3,3)                     
!C
      J = JTH                                                             
!C                                                                        
!C    Read in projection data for the jth segment from Cards G.3.b        
!C    and check for proper input data.                                    
!C                                                                        
      IF ( LIN_FLAG )   THEN
       READ  ( LULIN, * )  A, II, IK, JJ, JK                             
      ELSE
       READ  ( LUAIN, 100 )  A, II, IK, JJ, JK                             
  100  FORMAT ( 6F10.0, 4I3)                                               
       IF ( AIN_CONVERT )  THEN
        WRITE  ( LULIN, 103 )  A, II, IK, JJ, JK, 'Card G.3.b'                             
  103   FORMAT ( 1X, 6( F17.9, 1X ), 4( I3, 1X ), 1X, A )                                               
       END IF
      END IF
!C
      IF ( IK .EQ. JK ) THEN                                              
       WRITE ( LUAOU, 105 ) IK, JK, J                                    
  105  FORMAT ( /, 1X, 'IK = ', I4, ' and JK = ', I4,
     &          ' from Card G.3.b for segment number ', I4, '.', /,
     &          ' JK must be different from IK.', // )                    
       STOP ' STOP 240 in Subroutine INPUT_PROJANG '                    
      END IF                                                              
      IF ( ( IK .LT. I_1 ) .OR. ( IK .GT. I_3 ) )  THEN             
       WRITE ( LUAOU, 110 )  IK, J                                        
  110  FORMAT ( /, 1X, 'IK = ', I4, 
     &          ' from Card G.3.b for segment number ', I4, '.', /,  
     &          ' IK must be equal to 1, 2 or 3 only.', // )              
       STOP ' STOP 241 in Subroutine INPUT_PROJANG '                    
      END IF                                                              
      IF ( ( JK .LT. I_1 ) .OR. ( JK .GT. I_3 ) )  THEN            
       WRITE ( LUAOU, 115 )  JK, J                                       
  115  FORMAT ( /, 1X, 'JK = ', I4, 
     &          ' from Card G.3.b for segment number ', I4, '.', /,  
     &          ' JK must be equal to 1, 2 of 3 only.', // )              
       STOP ' STOP 242 in Subroutine INPUT_PROJANG '                    
      END IF                                                              
      IF ( II .GE. I_0 )  THEN                                       
       IF ( ( II .EQ. I_0 ) .OR. ( II .GT. I_3 ) )  THEN            
        WRITE ( LUAOU, 120 ) II, J                                        
  120   FORMAT ( /, 1X, 'II = ', I4,
     &           ' from Card G.3.b for segment number ', I4, '.', /,  
     &           ' II must be 1, 2 or 3 if projection angles',  
     &           ' are supplied.', // )                                  
        STOP ' STOP 243 in Subroutine INPUT_PROJANG '                    
       END IF                                                             
      END IF                                                              
      IF  ( JJ .GE. I_0 )  THEN                                        
       IF  ( ( JJ .EQ. I_0 ) .OR. ( JJ .GT. I_3 ) )  THEN           
        WRITE ( LUAOU, 125 )  JJ, J                                       
  125   FORMAT ( /, 1X, 'JJ = ', I4, 
     &           ' from Card G.3.b for segment number ', I4, '.', /,   
     &           ' JJ must be 1, 2 or 3 if projection angles',            
     &           ' are supplied.', // )                                   
        STOP ' STOP 244 in Subroutine INPROJ '                            
       END IF                                                             
      END IF                                                              
!C                                                                        
!C    Initialize IJ_LCL and LK to the primary axis.                       
!C                                                                        
      IJ_LCL = II                                                         
      LK     = IK                                                         
!C                                                                       
!C    Determine the primary and secondary axis vectors, either from      
!C    projection angles or directly as input.                             
!C                                                                        
      DO  20  K=1,2                                                       
!C                                                                        
!C     If II or JJ are positive, the values in A represent projection     
!C     angles.  Compute the corresponding components of the projection    
!C     vector.                                                            
!C                                                                        
       IF ( IJ_LCL .GT. I_0 )  THEN                                    
        DA1 = A(1,K) * RADIAN                                             
        DA2 = A(2,K) * RADIAN                                             
        SA1 = SIN ( DA1 )                                                 
        SA2 = SIN ( DA2 )                                                 
        CA1 = COS ( DA1 )                                                 
        CA2 = COS ( DA2 )                                                 
!C                                                                        
!C      Ensure that Sin(A1)*Cos(A2) is not equal to zero.                 
!C                                                                        
        TSTIPT = SA1 * CA2                                                
        IF ( TSTIPT .EQ. D_0 ) THEN                                     
         IF ( K .EQ. I_1 )  THEN                                        
          WRITE ( LUAOU, 130 )  J                                        
  130     FORMAT ( /, 1X, 'SIN(A1)*COS(A2) from Card G.3.b for segment',  
     &             ' number ', I4, ' equals 0 for the primary axis.',   
     &             /, ' This is not allowed.', // )                       
          STOP ' STOP 245 in Subroutine INPUT_PROJANG '                   
         ELSE                                                             
          WRITE ( LUAOU, 135 )  J                                         
  135     FORMAT ( /, 1X, 'SIN(A1)*COS(A2) from Card G.3.b for segment',  
     &             ' number ', I4, ' equals 0 for the secondary axis.',   
     &             /, ' This is not allowed.', // )                       
          STOP ' STOP 246 in Subroutine INPUT_PROJANG '              
         END IF                                                           
        END IF                                                            
        IJ1 = IJ_LCL + I_1                                              
        IJ2 = IJ_LCL + I_2                                              
        IF ( IJ1 .GT. I_3 )  IJ1 = IJ1 - I_3                      
        IF ( IJ2 .GT. I_3 )  IJ2 = IJ2 - I_3                     
        SGN = D_1                                                         
        IF ( ( SA1 .LT. D_0 ) .AND. ( CA2 .LT. D_0 ) )  SGN = -D_1      
!C                                                                        
!C       Compute the components of the projection vectors from the        
!C       projection angles.                                              
!C                                                                        
        Z(IJ_LCL, LK) = SGN * SA1 * CA2                                   
        Z(IJ1,    LK) = SGN * SA1 * SA2                                   
        Z(IJ2,    LK) = SGN * CA1 * CA2                                   
       ELSE                                                               
!C                                                                        
!C      If II or JJ are negative, the input values in A are the           
!C      components of the primary or secondary projection vectors.        
!C                                                                        
        DO  I=1,3                                                         
         Z(I,LK) = A(I,K)                                                 
        END DO
       END IF                                                             
!C                                                                        
!C     Set IJ_LCL and LK equal to the secondary axis quantities for the   
!C     second iteration.                                                  
!C                                                                        
       IJ_LCL = JJ                                                        
       LK     = JK                                                        
   20 CONTINUE                                                            
!C                                                                        
!C     Modify the secondary vector so that it is perpendicular to the     
!C     primary vector.                                                    
!C                                                                        
      ZDOTIJ = Z(1,IK) * Z(1,JK) + Z(2,IK) * Z(2,JK) + 
     &         Z(3,IK) * Z(3,JK)  
      ZDOTII = Z(1,IK) * Z(1,IK) + Z(2,IK) * Z(2,IK) + 
     &         Z(3,IK) * Z(3,IK)  
      RATIO = ZDOTIJ / ZDOTII                                             
      DO  I=1,3                                                           
       Z(I,JK) = Z(I,JK) - RATIO * Z(I,IK)                                
      END DO
!C                                                                        
!C     Compute the remaining principle axis from the "right-hand rule".   
!C                                                                       
      LK = I_6 - IK - JK                                             
      IT = MOD ( ( JK - IK + I_3 ), I_3 )                         
      IF ( IT .EQ. I_1 )  CALL CROSS ( Z(1,IK), Z(1,JK), Z(1,LK) )      
      IF ( IT .EQ. I_2 )  CALL CROSS ( Z(1,JK), Z(1,IK), Z(1,LK) )      
!C                                                                       
!C     Compute IYPR, normalize the axes vectors and construct the         
!C     direction cosine matrix.                                           
!C                                                                        
      DO  K=1,3                                                           
       IYPR(K,J) = I_4 - K                                         
       SUM = D_0                                                       
       DO  I=1,3                                                          
        SUM = SUM + Z(I,K)**2                                             
       END DO
       SQUM = SQRT ( SUM )                                                
       DO  I=1,3                                                          
        SEG(J)%DIR_COS(K,I) = Z(I,K) / SQUM                              
       END DO
      END DO
!C                                                                        
!C     Obtain the orientation angles from the direction cosine matrix,    
!C     then output the results.                                           
!C                                                                        
      CALL YPRDEG ( SEG(J)%DIR_COS, YPR(1,J) )                           
      IF ( FIRST .EQ. D_0 )   WRITE ( LUAOU, 140 )                      
  140 FORMAT ( '0 Initial angular rotations computed from Cards G.3.b',  
     &         //, '  Segment', 10X, 'Segment Primary Axis', 12X,         
     &         'Segment Secondary Axis',30X,'Angular Rotations (DEG)',    
     &         /, '  No. Seg', 9X, 'A1', 8X, 'A2', 8X, 'A3', 11X,
     &         'B1', 8X, 'B2', 8X, 'B3', 7X, 'II  IK  JJ  JK', 9X,
     &         'Yaw', 6X, 'Pitch', 5X, 'Roll', / )                       
      FIRST = D_1                                                     
      WRITE ( LUAOU, 145 )  J, SEG(J)%NAME, A, II, IK, JJ, JK,
     &                      ( YPR(I,J), I=1,3 )                           
  145 FORMAT ( I4, 1X, A4, 3X, 3F10.3, 3X, 3F10.3, 3X, 4I4, 3X, 3F10.3 ) 
!C
      RETURN                                                              
      END                                                                 
